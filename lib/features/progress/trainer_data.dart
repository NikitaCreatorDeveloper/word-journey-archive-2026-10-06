import 'dart:math';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../profile/cefr_level.dart';
import '../profile/cefr_profile.dart';
import '../settings/trainer_settings.dart';
import '../vocabulary/vocabulary_concept.dart';
import '../vocabulary/vocabulary_repository.dart';
import 'practice_event.dart';
import 'achievement_service.dart';
import 'trainer_store.dart';

String newSessionId() =>
    '${DateTime.now().toUtc().microsecondsSinceEpoch}-${Random.secure().nextInt(1 << 32)}';

class TrainerData extends ChangeNotifier {
  TrainerData({this.store, this.now = DateTime.now});
  static Future<TrainerStore> Function()? testStoreFactory;
  TrainerStore? store;
  final DateTime Function() now;
  TrainerSettings settings = TrainerSettings();
  List<PracticeEvent> events = [];
  List<Map<String, dynamic>> sessions = [], awards = [];
  Map<String, Map<String, dynamic>> flags = {};
  List<VocabularyConcept> custom = [];
  Map<String, WordProgress> progress = {};
  Set<String> _eventIds = {};
  final _pendingEvents = <String, PracticeEvent>{};
  bool loaded = false;
  String? error;
  Future<void> _queue = Future.value();
  bool _disposed = false;
  Future<void> load() async {
    try {
      store ??= await (testStoreFactory?.call() ?? SqliteTrainerStore.open());
      final s = await store!.read();
      if (s.settings.isEmpty) {
        final prefs = await SharedPreferences.getInstance();
        s.settings['level'] = CefrLevel.fromId(
          prefs.getString(PreferencesLevelStore.key),
        )?.id;
        await store!.settings(TrainerSettings(s.settings).values);
      }
      _apply(s);
      await _milestones();
      _apply(await store!.read());
      loaded = true;
      error = null;
      _changed();
    } catch (e) {
      error = 'Не удалось открыть локальные данные: $e';
      _changed();
    }
  }

  void _apply(TrainerSnapshot s) {
    settings = TrainerSettings(s.settings);
    settings.validate();
    final ordered =
        s.rows['events']!
            .asMap()
            .entries
            .map((e) => (event: PracticeEvent.fromJson(e.value), order: e.key))
            .toList()
          ..sort((a, b) {
            final n = a.event.at.compareTo(b.event.at);
            return n == 0 ? a.order.compareTo(b.order) : n;
          });
    events = ordered.map((e) => e.event).toList();
    _eventIds = events.map((e) => e.id).toSet();
    sessions = s.rows['sessions']!
      ..sort(
        (a, b) =>
            DateTime.parse(a['at'] as String)
                .compareTo(DateTime.parse(b['at'] as String)),
      );
    awards = s.rows['awards']!;
    flags = {for (final row in s.rows['flags']!) row['id'] as String: row};
    custom = s.rows['custom']!.map(VocabularyConcept.fromJson).toList();
    _aggregate();
  }

  void _aggregate() {
    final grouped = <String, List<PracticeEvent>>{};
    for (final e in events) {
      (grouped[e.conceptId] ??= []).add(e);
    }
    progress = {
      for (final id in {...grouped.keys, ...flags.keys})
        id: WordProgress(
          id,
          grouped[id] ?? [],
          favorite: flags[id]?['favorite'] == true,
          excluded: flags[id]?['excluded'] == true,
          firstConsolidatedOverride: DateTime.tryParse(
            flags[id]?['firstConsolidatedAt'] as String? ?? '',
          ),
        ),
    };
  }

  void _changed() {
    if (!_disposed) notifyListeners();
  }

  void refreshTime() => _changed();

  Future<void> _write(
    Future<void> Function() action, {
    void Function()? onSaved,
  }) {
    final result = _queue.catchError((Object _) {}).then((_) async {
      try {
        await action();
        if (onSaved != null) {
          onSaved();
        } else {
          _apply(await store!.read());
        }
        error = _pendingEvents.isEmpty
            ? null
            : 'Есть несохранённые ответы. Повторите сохранение.';
        _changed();
      } catch (e) {
        error = 'Изменения ещё не сохранены: $e';
        _changed();
        rethrow;
      }
    });
    _queue = result;
    return result;
  }

  Future<void> append(List<PracticeEvent> es) {
    for (final e in es) {
      _pendingEvents[e.id] = e;
    }
    late List<PracticeEvent> saved;
    return _write(
      () {
        saved = _pendingEvents.values.toList();
        return store!.write('events', saved.map((e) => e.toJson()).toList());
      },
      onSaved: () {
        for (final e in saved) {
          _pendingEvents.remove(e.id);
        }
        final fresh = saved.where((e) => _eventIds.add(e.id)).toList();
        events.addAll(fresh);
        for (final id in fresh.map((e) => e.conceptId).toSet()) {
          final old = progress[id];
          progress[id] = WordProgress(
            id,
            [...?old?.events, ...fresh.where((e) => e.conceptId == id)],
            favorite: flags[id]?['favorite'] == true,
            excluded: flags[id]?['excluded'] == true,
            firstConsolidatedOverride: DateTime.tryParse(
              flags[id]?['firstConsolidatedAt'] as String? ?? '',
            ),
          );
        }
      },
    );
  }

  Future<void> saveSession(Map<String, dynamic> session) => _write(
    () => store!.write('sessions', [session]),
    onSaved: () {
      if (!sessions.any((s) => s['id'] == session['id'])) sessions.add(session);
    },
  );
  Future<void> saveSettings(TrainerSettings next) {
    next.validate();
    return _write(() => store!.settings(next.values));
  }

  Future<void> setFlag(String id, {bool? favorite, bool? excluded}) => _write(
    () => store!.write('flags', [
      {
        ...?flags[id],
        'id': id,
        'favorite': favorite ?? flags[id]?['favorite'] ?? false,
        'excluded': excluded ?? flags[id]?['excluded'] ?? false,
      },
    ], replace: true),
  );
  Future<void> addCustom(VocabularyConcept c) =>
      _write(() => store!.write('custom', [c.toJson()]));
  Future<void> importData(TrainerSnapshot snapshot) async {
    await _write(() => store!.importSnapshot(snapshot));
    await reconcileAchievements();
  }

  int get consolidatedCount =>
      progress.values.where((p) => p.firstConsolidatedAt != null).length;
  Future<void> reconcileAchievements() => _write(_milestones);
  Future<void> _milestones() async {
    final updates = <Map<String, dynamic>>[];
    for (final p in progress.values) {
      if (p.firstConsolidatedAt != null &&
          flags[p.conceptId]?['firstConsolidatedAt'] == null) {
        updates.add({
          'favorite': false,
          'excluded': false,
          ...?flags[p.conceptId],
          'id': p.conceptId,
          'firstConsolidatedAt': p.firstConsolidatedAt!.toIso8601String(),
        });
      }
    }
    final earned = AchievementService.pending(
      events: events,
      sessions: sessions,
      progress: progress,
      awards: awards,
      packs: {
        for (final p
            in VocabularyRepository.current?.packs ?? <VocabularyPack>[])
          p.id: p.conceptIds,
      },
    );
    if (updates.isNotEmpty || earned.isNotEmpty) {
      await store!.milestones(updates, earned);
    }
  }

  Future<void> resetProgress() => _write(() async {
    await store!.resetProgress();
    _pendingEvents.clear();
  });
  bool get hasPendingEvents => _pendingEvents.isNotEmpty;
  Future<void> flush() => _queue;
  List<PracticeEvent> sessionEvents(String id) =>
      events.where((e) => e.sessionId == id).toList();
  String? get lastPackId =>
      sessions.where((s) => s['packId'] != null).lastOrNull?['packId']
          as String?;
  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}

class TrainerLevelStore implements LevelStore {
  TrainerLevelStore(this.data);
  final TrainerData data;
  @override
  Future<CefrLevel?> read() async {
    if (!data.loaded) await data.load();
    if (!data.loaded) throw StateError(data.error ?? 'Local data unavailable');
    return CefrLevel.fromId(data.settings.values['level'] as String?);
  }

  @override
  Future<void> write(CefrLevel level) =>
      data.saveSettings(data.settings.withValue('level', level.id));
}

class TrainerScope extends InheritedNotifier<TrainerData> {
  const TrainerScope({
    super.key,
    required TrainerData data,
    required super.child,
  }) : super(notifier: data);
  static TrainerData? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<TrainerScope>()?.notifier;
  static TrainerData of(BuildContext context) => maybeOf(context)!;
}
