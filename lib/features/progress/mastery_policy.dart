import 'dart:math';

import 'practice_event.dart';

String practiceDay(DateTime at) =>
    at.toLocal().toIso8601String().substring(0, 10);

class SkillSchedule {
  int stage = 0;
  DateTime? dueAt, firstEligibleAt, lastEligibleAt, lastAdvanceAt;
  bool needsReview = false;
  int eligibleChecks = 0;
  void answer(
    PracticeEvent e, {
    required bool correct,
    required bool independent,
  }) {
    if (!correct) {
      stage = max(0, stage - 1);
      final shortened = e.at.add(const Duration(days: 1));
      dueAt = dueAt == null || dueAt!.isAfter(shortened) ? shortened : dueAt;
      needsReview = true;
      return;
    }
    if (dueAt == null) {
      dueAt = e.at.add(const Duration(days: 1));
      return;
    }
    if (!e.at.isBefore(dueAt!) &&
        independent &&
        (lastAdvanceAt == null ||
            practiceDay(lastAdvanceAt!) != practiceDay(e.at))) {
      stage = min(MasteryPolicy.intervals.length - 1, stage + 1);
      dueAt = e.at.add(Duration(days: MasteryPolicy.intervals[stage]));
      lastEligibleAt = e.at;
      firstEligibleAt ??= e.at;
      lastAdvanceAt = e.at;
      eligibleChecks++;
      needsReview = false;
    } else if (!e.at.isBefore(dueAt!) && !independent) {
      dueAt = e.at.add(const Duration(days: 1));
    }
  }
}

class MasterySummary {
  MasterySummary(
    this.recognition,
    this.recall,
    this.spacedCorrect,
    this.firstConsolidatedAt,
    this.currentlyConsolidated,
    this.independentRecallCorrect,
  );
  final SkillSchedule recognition, recall;
  final int spacedCorrect, independentRecallCorrect;
  final DateTime? firstConsolidatedAt;
  final bool currentlyConsolidated;
  String get label => currentlyConsolidated
      ? 'Подтверждено позже'
      : spacedCorrect >= 3
      ? 'Узнаю'
      : spacedCorrect > 0
      ? 'Тренирую'
      : 'Новое';
}

/// Transparent product heuristic, not a calibrated probability or FSRS.
class MasteryPolicy {
  static const intervals = [1, 3, 7, 14, 30, 60];
  static MasterySummary evaluate(List<PracticeEvent> events) {
    final recognition = SkillSchedule(), recall = SkillSchedule();
    final hintedDays = <String>{};
    final shownDays = <String>{};
    PracticeEvent? lastSpaced;
    final sessions = <String, DateTime>{};
    final evaluated = <bool>[];
    int spaced = 0, matches = 0, independentRecall = 0;
    DateTime? first;
    bool lastMatchCorrect = false;
    bool meets() {
      final recent = evaluated.reversed.take(5).toList();
      final dates = sessions.values.toList()..sort();
      return matches >= 5 &&
          dates.length >= 2 &&
          dates.last.difference(dates.first) >= const Duration(hours: 24) &&
          recognition.eligibleChecks > 0 &&
          recent.length == 5 &&
          recent.where((v) => v).length >= 4 &&
          lastMatchCorrect;
    }

    for (final e in events) {
      if (e.kind == PracticeKind.hint) {
        hintedDays.add(practiceDay(e.at));
        continue;
      }
      if (e.kind == PracticeKind.exposure) {
        if (e.answerShown) shownDays.add(practiceDay(e.at));
        recall.dueAt ??= e.at.add(const Duration(days: 1));
        continue;
      }
      final independent =
          e.independent && !hintedDays.contains(practiceDay(e.at));
      switch (e.kind) {
        case PracticeKind.matchCorrect:
          matches++;
          lastMatchCorrect = true;
          final old = lastSpaced;
          final spacedAttempt =
              old == null ||
              (old.sessionId == e.sessionId
                  ? e.index - old.index >= 4
                  : e.index >= 4 ||
                        e.at.difference(old.at) >= const Duration(minutes: 5));
          shownDays.add(practiceDay(e.at));
          if (spacedAttempt) {
            spaced++;
            lastSpaced = e;
            sessions.putIfAbsent(e.sessionId, () => e.at);
            evaluated.add(true);
          }
          recognition.answer(
            e,
            correct: true,
            independent: independent && spacedAttempt,
          );
        case PracticeKind.matchWrong:
          lastMatchCorrect = false;
          evaluated.add(false);
          recognition.answer(e, correct: false, independent: independent);
        case PracticeKind.recallCorrect:
          final recalled =
              independent && !shownDays.contains(practiceDay(e.at));
          if (recalled) independentRecall++;
          recall.answer(e, correct: true, independent: recalled);
        case PracticeKind.recallWrong:
          recall.answer(e, correct: false, independent: independent);
        case PracticeKind.exposure:
        case PracticeKind.hint:
          break;
      }
      if (first == null && meets()) first = e.at;
    }
    return MasterySummary(
      recognition,
      recall,
      spaced,
      first,
      meets(),
      independentRecall,
    );
  }
}
