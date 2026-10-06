import 'dart:io';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:word_journey/features/progress/trainer_store.dart';
import 'package:word_journey/features/progress/trainer_data.dart';
import 'package:word_journey/features/progress/practice_event.dart';
import 'package:word_journey/features/progress/backup_service.dart';
import 'package:word_journey/features/settings/trainer_settings.dart';
import 'package:word_journey/features/vocabulary/vocabulary_repository.dart';

void main() {
  test('A failed hint is retried with the next answer before independent mastery is computed', () async {
    final store = _FlakyStore();
    final d = TrainerData(store: store);
    await d.load();
    final at = DateTime.utc(2026, 10, 1, 12);
    store.failNext = true;
    await expectLater(
      d.append([
        PracticeEvent(
          id: 'hint',
          sessionId: 's',
          conceptId: 'w',
          kind: PracticeKind.hint,
          at: at,
        ),
      ]),
      throwsStateError,
    );
    expect(d.error, isNotNull);
    await d.append([
      PracticeEvent(
        id: 'answer',
        sessionId: 's',
        conceptId: 'w',
        kind: PracticeKind.recallCorrect,
        at: at.add(const Duration(seconds: 1)),
      ),
    ]);
    expect(d.events, hasLength(2));
    expect(d.progress['w']!.mastery.independentRecallCorrect, 0);
    expect(d.error, isNull);
    store.failNext = true;
    await expectLater(
      d.append([
        PracticeEvent(
          id: 'pending',
          sessionId: 's',
          conceptId: 'w',
          kind: PracticeKind.matchCorrect,
          at: at,
        ),
      ]),
      throwsStateError,
    );
    await d.resetProgress();
    await d.append([]);
    expect(d.events, isEmpty);
    expect(d.hasPendingEvents, isFalse);
  });
  test('SQLite keeps first consolidation on merge and removes it only on explicit reset', () async {
    sqfliteFfiInit();
    final store = await SqliteTrainerStore.open(
      factory: databaseFactoryFfi,
      path: inMemoryDatabasePath,
    );
    const first = '2026-10-01T12:00:00.000Z';
    await store.milestones(
      [
        {
          'id': 'w',
          'favorite': true,
          'excluded': false,
          'firstConsolidatedAt': first,
        },
      ],
      [
        {'id': 'first-session', 'at': first},
      ],
    );
    await store.importSnapshot(
      TrainerSnapshot(
        settings: TrainerSettings().values,
        rows: {
          'flags': [
            {'id': 'w', 'favorite': true, 'excluded': false},
          ],
          'awards': [
            {'id': 'first-session', 'at': '2026-10-02T12:00:00.000Z'},
          ],
        },
      ),
    );
    expect(
      (await store.read()).rows['flags']!.single['firstConsolidatedAt'],
      first,
    );
    expect((await store.read()).rows['awards'], hasLength(1));
    await store.resetProgress();
    expect(
      (await store.read()).rows['flags']!.single['firstConsolidatedAt'],
      isNull,
    );
    expect((await store.read()).rows['flags']!.single['favorite'], isTrue);
    await store.close();
  });
  test('SQLite append, duplicate callback, flags/settings survive reopening the actual file', () async {
    sqfliteFfiInit();
    final dir = await Directory.systemTemp.createTemp('wj-sqlite-');
    final path = '${dir.path}/history.db';
    var store = await SqliteTrainerStore.open(
      factory: databaseFactoryFfi,
      path: path,
    );
    var data = TrainerData(store: store);
    await data.load();
    final e = PracticeEvent(
      id: 's:answer:1',
      sessionId: 's',
      conceptId: 'cafe.a1.coffee.drink',
      kind: PracticeKind.matchWrong,
      otherConceptId: 'cafe.a1.tea.drink',
      at: DateTime.utc(2026, 10, 1),
    );
    await data.append([e]);
    await data.append([e]);
    await data.setFlag(e.conceptId, favorite: true);
    await data.saveSettings(data.settings.withValue('pairs', 5));
    expect(data.progress[e.conceptId]!.wrongAttempts, 1);
    expect(data.progress[e.otherConceptId], isNull);
    data.dispose();
    await store.close();
    store = await SqliteTrainerStore.open(
      factory: databaseFactoryFfi,
      path: path,
    );
    data = TrainerData(store: store);
    await data.load();
    expect(data.progress[e.conceptId]!.wrongAttempts, 1);
    expect(data.progress[e.conceptId]!.favorite, isTrue);
    expect(data.settings.pairs, 5);
    data.dispose();
    await store.close();
    await dir.delete(recursive: true);
  });
  test('Atomic import rolls back earlier rows/settings on ID conflict; repeated import deduplicates', () async {
    sqfliteFfiInit();
    final store = await SqliteTrainerStore.open(
      factory: databaseFactoryFfi,
      path: inMemoryDatabasePath,
    );
    final data = TrainerData(store: store);
    await data.load();
    final e = PracticeEvent(
      id: 'same',
      sessionId: 's',
      conceptId: 'word',
      kind: PracticeKind.matchCorrect,
      at: DateTime.utc(2026, 10, 1),
    );
    await data.append([e]);
    final snap = await store.read();
    await data.importData(snap);
    await data.importData(snap);
    expect(data.events, hasLength(1));
    final corrupt = TrainerSnapshot(
      settings: TrainerSettings().withValue('pairs', 5).values,
      rows: {
        'events': [
          e.toJson()..['id'] = 'new',
          e.toJson()..['kind'] = 'matchWrong',
        ],
      },
    );
    expect(() => data.importData(corrupt), throwsFormatException);
    await data.flush().catchError((Object _) {});
    expect((await store.read()).rows['events'], hasLength(1));
    expect((await store.read()).settings['pairs'], 4);
    data.dispose();
    await store.close();
  });
  test('Backup preview rejects damaged files, duplicate IDs and invalid settings before applying', () async {
    final r = await VocabularyRepository.load();
    final s = TrainerSnapshot(settings: TrainerSettings().values);
    final text = BackupService.encode(s);
    expect(BackupService.validate(text, r.byId.keys.toSet()).events, 0);
    for (final change in ['version', 'settings', 'records']) {
      final j = jsonDecode(text) as Map<String, dynamic>;
      if (change == 'version') j['version'] = 99;
      if (change == 'settings') j['settings']['pairs'] = 3;
      if (change == 'records') {
        j['flags'] = [
          {'id': 'x', 'favorite': true, 'excluded': false},
          {'id': 'x', 'favorite': false, 'excluded': false},
        ];
      }
      expect(
        () => BackupService.validate(jsonEncode(j), r.byId.keys.toSet()),
        throwsFormatException,
      );
    }
    expect(
      () => BackupService.validate('{broken', r.byId.keys.toSet()),
      throwsFormatException,
    );
  });
}

class _FlakyStore extends MemoryTrainerStore {
  bool failNext = false;
  @override
  Future<void> write(
    String table,
    List<Map<String, dynamic>> rows, {
    bool replace = false,
  }) async {
    if (failNext) {
      failNext = false;
      throw StateError('Temporary write failure');
    }
    return super.write(table, rows, replace: replace);
  }
}
