import 'practice_event.dart';
import 'mastery_policy.dart';

const rankThresholds = [0, 10, 20, 30, 50, 100, 200, 350, 500, 750, 1000];
const rankNames = [
  'Старт',
  'Искра',
  'Импульс',
  'Ритм',
  'Фокус',
  'Поток',
  'Резонанс',
  'Спектр',
  'Синтез',
  'Горизонт',
  'Лексикон',
];
int rankIndex(int count) => rankThresholds.lastIndexWhere((n) => count >= n);
const achievementDefinitions = <String, (String, String)>{
  'first-session': ('Первый шаг', 'Завершить первую тренировку'),
  'ten-seen': ('Знакомство', 'Встретить 10 разных слов'),
  'combo-ten': ('Точный ритм', 'Соединить 10 пар подряд'),
  'clean-sixty': ('Чистый раунд', '60 совпадений без ошибки'),
  'delayed-review': (
    'Память во времени',
    'Успешно повторить по наступившему сроку',
  ),
  'recall-ten': ('Своими силами', 'Вспомнить 10 разных слов без подсказки'),
  'four-days': ('Регулярность', 'Заниматься 4 дня в одной неделе'),
  'full-pack': (
    'Весь набор',
    'Ответить верно по каждому понятию набора; это практика, не окончательное знание',
  ),
  'return-to-error': (
    'Возвращение',
    'Вернуться к слову с ошибкой в другой тренировке и ответить верно',
  ),
  'new-rank': (
    'Новый горизонт',
    'Достичь первого нового ранга: 10 разных подтверждённых понятий',
  ),
};

class AchievementService {
  static List<Map<String, dynamic>> pending({
    required List<PracticeEvent> events,
    required List<Map<String, dynamic>> sessions,
    required Map<String, WordProgress> progress,
    required List<Map<String, dynamic>> awards,
    Map<String, List<String>> packs = const {},
  }) {
    final earned = <String, DateTime>{};
    void give(String id, DateTime at) => earned.putIfAbsent(id, () => at);
    for (final s in sessions) {
      final at = DateTime.parse(
        s['finishedAt'] as String? ?? s['at'] as String,
      );
      if (s['completed'] == true) give('first-session', at);
      if (s['mode'] == 'match' &&
          s['completed'] == true &&
          s['correct'] == 60 &&
          s['wrong'] == 0) {
        give('clean-sixty', at);
      }
    }
    final seen = <String>{}, recalls = <String>{};
    final shown = <String>{};
    final streaks = <String, int>{};
    final weeks = <String, Set<String>>{};
    final errors = <String, PracticeEvent>{};
    final firstCorrect = <String, DateTime>{};
    for (final e in events) {
      if (e.kind == PracticeKind.matchWrong ||
          e.kind == PracticeKind.recallWrong) {
        errors[e.conceptId] = e;
      }
      if (e.kind == PracticeKind.matchCorrect ||
          e.kind == PracticeKind.recallCorrect) {
        firstCorrect.putIfAbsent(e.conceptId, () => e.at);
        final wrong = errors[e.conceptId];
        if (wrong != null &&
            wrong.sessionId != e.sessionId &&
            e.at.isAfter(wrong.at)) {
          give('return-to-error', e.at);
        }
      }
      final shownKey = '${e.conceptId}:${practiceDay(e.at)}';
      if (e.kind == PracticeKind.hint ||
          e.answerShown ||
          e.kind == PracticeKind.matchCorrect) {
        shown.add(shownKey);
      }
      if (e.kind == PracticeKind.exposure) {
        seen.add(e.conceptId);
        if (seen.length >= 10) give('ten-seen', e.at);
      }
      if (e.kind == PracticeKind.matchCorrect) {
        streaks[e.sessionId] = (streaks[e.sessionId] ?? 0) + 1;
        if (streaks[e.sessionId]! >= 10) give('combo-ten', e.at);
      } else if (e.kind == PracticeKind.matchWrong) {
        streaks[e.sessionId] = 0;
      }
      if (e.kind == PracticeKind.recallCorrect &&
          e.independent &&
          !shown.contains(shownKey)) {
        recalls.add(e.conceptId);
        if (recalls.length >= 10) give('recall-ten', e.at);
      }
      if (e.kind == PracticeKind.exposure || e.kind == PracticeKind.hint) {
        continue;
      }
      final local = e.at.toLocal();
      final monday = DateTime(
        local.year,
        local.month,
        local.day,
      ).subtract(Duration(days: local.weekday - 1));
      final days = weeks.putIfAbsent(practiceDay(monday), () => {});
      days.add(practiceDay(e.at));
      if (days.length >= 4) give('four-days', e.at);
    }
    for (final p in progress.values) {
      for (final at in [
        p.mastery.recognition.firstEligibleAt,
        p.mastery.recall.firstEligibleAt,
      ]) {
        if (at != null) give('delayed-review', at);
      }
    }
    for (final ids in packs.values) {
      if (ids.length >= 20 && ids.every(firstCorrect.containsKey)) {
        final times = ids.map((id) => firstCorrect[id]!).toList()..sort();
        give('full-pack', times.last);
      }
    }
    final confirmed =
        progress.values
            .map((p) => p.firstConsolidatedAt)
            .whereType<DateTime>()
            .toList()
          ..sort();
    if (confirmed.length >= rankThresholds[1]) {
      give('new-rank', confirmed[rankThresholds[1] - 1]);
    }
    final existing = awards.map((a) => a['id']).toSet();
    return [
      for (final a in earned.entries)
        if (!existing.contains(a.key))
          {'id': a.key, 'at': a.value.toUtc().toIso8601String()},
    ];
  }
}
