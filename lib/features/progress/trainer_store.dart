import 'dart:convert';

import 'package:sqflite/sqflite.dart';

const dataTables = ['events', 'sessions', 'flags', 'custom', 'awards'];

class TrainerSnapshot {
  TrainerSnapshot({
    Map<String, dynamic>? settings,
    Map<String, List<Map<String, dynamic>>>? rows,
  }) : settings = settings ?? {},
       rows = {for (final t in dataTables) t: rows?[t] ?? []};
  final Map<String, dynamic> settings;
  final Map<String, List<Map<String, dynamic>>> rows;
}

abstract interface class TrainerStore {
  Future<TrainerSnapshot> read();
  Future<void> write(
    String table,
    List<Map<String, dynamic>> rows, {
    bool replace = false,
  });
  Future<void> settings(Map<String, dynamic> settings);
  Future<void> importSnapshot(TrainerSnapshot snapshot);
  Future<void> resetProgress();
  Future<void> milestones(
    List<Map<String, dynamic>> flags,
    List<Map<String, dynamic>> awards,
  );
  Future<void> close();
}

class SqliteTrainerStore implements TrainerStore {
  SqliteTrainerStore(this.db);
  final Database db;
  static Future<SqliteTrainerStore> open({
    DatabaseFactory? factory,
    String? path,
  }) async {
    final f = factory ?? databaseFactory;
    final db = await f.openDatabase(
      path ?? '${await f.getDatabasesPath()}/personal-trainer.db',
      options: OpenDatabaseOptions(
        version: 1,
        onCreate: (db, version) async {
          for (final t in dataTables) {
            await db.execute(
              'CREATE TABLE $t (id TEXT PRIMARY KEY NOT NULL, payload TEXT NOT NULL)',
            );
          }
          await db.execute(
            'CREATE TABLE settings (id INTEGER PRIMARY KEY CHECK(id=1), payload TEXT NOT NULL)',
          );
        },
        onConfigure: (db) async {
          await db.execute('PRAGMA foreign_keys = ON');
        },
      ),
    );
    return SqliteTrainerStore(db);
  }

  @override
  Future<TrainerSnapshot> read() async {
    final result = <String, List<Map<String, dynamic>>>{};
    for (final t in dataTables) {
      result[t] = (await db.query(t))
          .map(
            (r) => jsonDecode(r['payload'] as String) as Map<String, dynamic>,
          )
          .toList();
    }
    final settings = await db.query('settings');
    return TrainerSnapshot(
      settings: settings.isEmpty
          ? {}
          : jsonDecode(settings.single['payload'] as String)
                as Map<String, dynamic>,
      rows: result,
    );
  }

  Future<void> _rows(
    DatabaseExecutor tx,
    String table,
    List<Map<String, dynamic>> rows,
    bool replace,
  ) async {
    if (!dataTables.contains(table)) throw ArgumentError('Unknown table');
    for (final row in rows) {
      final old = await tx.query(
        table,
        where: 'id = ?',
        whereArgs: [row['id']],
      );
      if (old.isNotEmpty && !replace) {
        if (table == 'awards') continue;
        if (!_same(jsonDecode(old.single['payload'] as String), row)) {
          throw const FormatException('ID conflict');
        }
        continue;
      }
      if (table == 'flags' && old.isNotEmpty) {
        final oldFlag =
            jsonDecode(old.single['payload'] as String) as Map<String, dynamic>;
        if (oldFlag['firstConsolidatedAt'] != null) {
          row['firstConsolidatedAt'] = oldFlag['firstConsolidatedAt'];
        }
      }
      await tx.insert(table, {
        'id': row['id'],
        'payload': jsonEncode(row),
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    }
  }

  @override
  Future<void> write(
    String table,
    List<Map<String, dynamic>> rows, {
    bool replace = false,
  }) => db.transaction((tx) => _rows(tx, table, rows, replace));
  @override
  Future<void> settings(Map<String, dynamic> settings) =>
      db.transaction((tx) async {
        await tx.insert('settings', {
          'id': 1,
          'payload': jsonEncode(settings),
        }, conflictAlgorithm: ConflictAlgorithm.replace);
      });
  @override
  Future<void> importSnapshot(TrainerSnapshot snapshot) =>
      db.transaction((tx) async {
        for (final t in dataTables) {
          await _rows(tx, t, snapshot.rows[t]!, t == 'flags');
        }
        await tx.insert('settings', {
          'id': 1,
          'payload': jsonEncode(snapshot.settings),
        }, conflictAlgorithm: ConflictAlgorithm.replace);
      });
  @override
  Future<void> milestones(
    List<Map<String, dynamic>> flags,
    List<Map<String, dynamic>> awards,
  ) => db.transaction((tx) async {
    await _rows(tx, 'flags', flags, true);
    await _rows(tx, 'awards', awards, false);
  });
  @override
  Future<void> resetProgress() => db.transaction((tx) async {
    for (final t in ['events', 'sessions', 'awards']) {
      await tx.delete(t);
    }
    for (final r in await tx.query('flags')) {
      final row = jsonDecode(r['payload'] as String) as Map<String, dynamic>;
      row.remove('firstConsolidatedAt');
      await tx.update(
        'flags',
        {'payload': jsonEncode(row)},
        where: 'id = ?',
        whereArgs: [row['id']],
      );
    }
  });
  @override
  Future<void> close() => db.close();
}

bool _same(dynamic a, dynamic b) {
  if (a is Map && b is Map) {
    return a.length == b.length &&
        a.keys.every((k) => b.containsKey(k) && _same(a[k], b[k]));
  }
  if (a is List && b is List) {
    return a.length == b.length &&
        List.generate(a.length, (i) => i).every((i) => _same(a[i], b[i]));
  }
  return a == b;
}

/// Test double only; production always opens SQLite.
class MemoryTrainerStore implements TrainerStore {
  TrainerSnapshot value = TrainerSnapshot();
  @override
  Future<TrainerSnapshot> read() async => TrainerSnapshot(
    settings: Map.from(value.settings),
    rows: {
      for (final t in dataTables)
        t: value.rows[t]!.map((r) => Map<String, dynamic>.from(r)).toList(),
    },
  );
  void _merge(
    TrainerSnapshot target,
    String table,
    List<Map<String, dynamic>> rows,
    bool replace,
  ) {
    for (final r in rows) {
      final old = target.rows[table]!
          .where((a) => a['id'] == r['id'])
          .firstOrNull;
      if (old != null) {
        if (table == 'awards' && !replace) continue;
        if (!replace && !_same(old, r)) {
          throw const FormatException('ID conflict');
        }
        if (!replace) continue;
        if (table == 'flags' && old['firstConsolidatedAt'] != null) {
          r['firstConsolidatedAt'] = old['firstConsolidatedAt'];
        }
        target.rows[table]!.remove(old);
      }
      target.rows[table]!.add(Map.from(r));
    }
  }

  @override
  Future<void> write(
    String table,
    List<Map<String, dynamic>> rows, {
    bool replace = false,
  }) async {
    final copy = await read();
    _merge(copy, table, rows, replace);
    value = copy;
  }

  @override
  Future<void> settings(Map<String, dynamic> settings) async {
    value = TrainerSnapshot(settings: Map.from(settings), rows: value.rows);
  }

  @override
  Future<void> importSnapshot(TrainerSnapshot snapshot) async {
    final copy = await read();
    for (final t in dataTables) {
      _merge(copy, t, snapshot.rows[t]!, t == 'flags');
    }
    value = TrainerSnapshot(
      settings: Map.from(snapshot.settings),
      rows: copy.rows,
    );
  }

  @override
  Future<void> milestones(
    List<Map<String, dynamic>> flags,
    List<Map<String, dynamic>> awards,
  ) async {
    final copy = await read();
    _merge(copy, 'flags', flags, true);
    _merge(copy, 'awards', awards, false);
    value = copy;
  }

  @override
  Future<void> resetProgress() async {
    for (final t in ['events', 'sessions', 'awards']) {
      value.rows[t]!.clear();
    }
    for (final row in value.rows['flags']!) {
      row.remove('firstConsolidatedAt');
    }
  }

  @override
  Future<void> close() async {}
}
