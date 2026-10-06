import 'mastery_policy.dart';

enum PracticeKind {
  exposure,
  matchCorrect,
  matchWrong,
  recallCorrect,
  recallWrong,
  hint,
}

class PracticeEvent {
  const PracticeEvent({
    required this.id,
    required this.sessionId,
    required this.conceptId,
    required this.kind,
    required this.at,
    this.otherConceptId,
    this.index = 0,
    this.latencyMs,
    this.independent = true,
    this.answerShown = false,
  });
  final String id, sessionId, conceptId;
  final PracticeKind kind;
  final DateTime at;
  final String? otherConceptId;
  final int index;
  final int? latencyMs;
  final bool independent;
  final bool answerShown;
  Map<String, dynamic> toJson() => {
    'id': id,
    'sessionId': sessionId,
    'conceptId': conceptId,
    'kind': kind.name,
    'at': at.toUtc().toIso8601String(),
    'otherConceptId': otherConceptId,
    'index': index,
    'latencyMs': latencyMs,
    'independent': independent,
    'answerShown': answerShown,
  };
  factory PracticeEvent.fromJson(Map<String, dynamic> j) {
    final e = PracticeEvent(
      id: j['id'] as String,
      sessionId: j['sessionId'] as String,
      conceptId: j['conceptId'] as String,
      kind: PracticeKind.values.byName(j['kind'] as String),
      at: DateTime.parse(j['at'] as String).toUtc(),
      otherConceptId: j['otherConceptId'] as String?,
      index: j['index'] as int,
      latencyMs: j['latencyMs'] as int?,
      independent: j['independent'] as bool,
      answerShown: j['answerShown'] as bool? ?? j['kind'] == 'exposure',
    );
    if (e.id.isEmpty ||
        e.sessionId.isEmpty ||
        e.conceptId.isEmpty ||
        e.index < 0 ||
        (e.latencyMs ?? 0) < 0) {
      throw const FormatException('Invalid practice event');
    }
    return e;
  }
}

class WordProgress {
  WordProgress(
    this.conceptId,
    List<PracticeEvent> events, {
    this.favorite = false,
    this.excluded = false,
    this.firstConsolidatedOverride,
  }) : events = List.unmodifiable(events);
  final String conceptId;
  final List<PracticeEvent> events;
  final bool favorite, excluded;
  final DateTime? firstConsolidatedOverride;
  late final MasterySummary mastery = MasteryPolicy.evaluate(events);
  int get recognitionStage => mastery.recognition.stage;
  int get recallStage => mastery.recall.stage;
  DateTime? get recognitionDueAt => mastery.recognition.dueAt;
  DateTime? get recallDueAt => mastery.recall.dueAt;
  DateTime? get firstConsolidatedAt =>
      firstConsolidatedOverride ?? mastery.firstConsolidatedAt;
  DateTime? get lastEligibleReviewAt {
    final a = mastery.recognition.lastEligibleAt,
        b = mastery.recall.lastEligibleAt;
    return a == null
        ? b
        : b == null
        ? a
        : (a.isAfter(b) ? a : b);
  }

  bool get needsReview =>
      mastery.recognition.needsReview || mastery.recall.needsReview;
  bool isDue(DateTime now, {bool recall = false}) {
    final due = recall ? recallDueAt : recognitionDueAt;
    return !excluded && due != null && !now.toUtc().isBefore(due);
  }

  bool hintedToday(DateTime now) => events.any(
    (e) =>
        (e.kind == PracticeKind.hint ||
            e.answerShown ||
            e.kind == PracticeKind.matchCorrect) &&
        !e.at.isAfter(now.toUtc()) &&
        practiceDay(e.at) == practiceDay(now),
  );
  int count(PracticeKind k) => events.where((e) => e.kind == k).length;
  int get exposures => count(PracticeKind.exposure);
  int get matchCorrect => count(PracticeKind.matchCorrect);
  int get wrongAttempts => count(PracticeKind.matchWrong);
  int get recallCorrect => count(PracticeKind.recallCorrect);
  int get recallWrong => count(PracticeKind.recallWrong);
  DateTime? get firstSeenAt => events.isEmpty ? null : events.first.at;
  DateTime? get lastSeenAt => events.isEmpty ? null : events.last.at;
  DateTime? lastOf(Set<PracticeKind> kinds) {
    final es = events.where((e) => kinds.contains(e.kind));
    return es.isEmpty ? null : es.last.at;
  }

  DateTime? get lastCorrectAt =>
      lastOf({PracticeKind.matchCorrect, PracticeKind.recallCorrect});
  DateTime? get lastWrongAt =>
      lastOf({PracticeKind.matchWrong, PracticeKind.recallWrong});
  Set<String> get distinctPracticeDays => events
      .where(
        (e) => e.kind != PracticeKind.hint && e.kind != PracticeKind.exposure,
      )
      .map((e) => e.at.toLocal().toIso8601String().substring(0, 10))
      .toSet();
  int get currentCorrectStreak {
    var streak = 0;
    for (final e in events.reversed) {
      if (e.kind == PracticeKind.matchWrong ||
          e.kind == PracticeKind.recallWrong) {
        break;
      }
      if (e.kind == PracticeKind.matchCorrect ||
          e.kind == PracticeKind.recallCorrect) {
        streak++;
      }
    }
    return streak;
  }
}
