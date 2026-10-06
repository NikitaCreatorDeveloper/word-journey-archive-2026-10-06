import '../training/logic/matching_engine.dart';
import '../training/model/session_result.dart';
import 'practice_event.dart';
import 'trainer_data.dart';

class SessionJournal {
  SessionJournal(this.data, this.game, {this.packId})
    : id = newSessionId(),
      started = data.now().toUtc(),
      known = data.progress.values
          .where((p) => p.exposures > 0)
          .map((p) => p.conceptId)
          .toSet(),
      consolidatedBefore = data.consolidatedCount,
      awardsBefore = data.awards.map((a) => a['id'] as String).toSet();
  final TrainerData data;
  final MatchingEngine game;
  final String id;
  final String? packId;
  final DateTime started;
  final Set<String> known;
  final int consolidatedBefore;
  final Set<String> awardsBefore;
  final Map<String, PracticeEvent> pending = {};
  final Set<String> _exposed = {};
  final Set<String> presented = {};
  final Set<String> correctlyMatched = {};
  final Set<String> _answeredPairs = {};
  int _wrongSequence = 0;
  int combo = 0;
  int bestCombo = 0;
  Duration? firstTap;
  bool _finished = false;
  Map<String, dynamic>? _terminal;
  int get newConcepts => presented.difference(known).length;
  void exposeBoard() {
    final es = <PracticeEvent>[];
    for (final card in game.leftCards) {
      if (card != null && game.isActive(card.id) && _exposed.add(card.pairId)) {
        presented.add(card.conceptId);
        es.add(
          PracticeEvent(
            id: '$id:expose:${card.pairId}',
            sessionId: id,
            conceptId: card.conceptId,
            kind: PracticeKind.exposure,
            at: data.now().toUtc(),
            index: game.matchedCount,
            answerShown: true,
          ),
        );
      }
    }
    _send(es);
  }

  void answer(
    MatchFeedback feedback,
    String first,
    String second,
    Duration elapsed,
  ) {
    if (_finished) return;
    final cards = game.cards;
    final a = cards.firstWhere((c) => c.id == first),
        b = cards.firstWhere((c) => c.id == second);
    final correct = feedback == MatchFeedback.correct;
    if (correct && !_answeredPairs.add(a.pairId)) return;
    if (correct) {
      combo++;
      bestCombo = combo > bestCombo ? combo : bestCombo;
      correctlyMatched.add(a.conceptId);
    } else {
      combo = 0;
    }
    _send([
      PracticeEvent(
        id: correct ? '$id:match:${a.pairId}' : '$id:wrong:${_wrongSequence++}',
        sessionId: id,
        conceptId: a.conceptId,
        kind: correct ? PracticeKind.matchCorrect : PracticeKind.matchWrong,
        otherConceptId: correct ? null : b.conceptId,
        at: data.now().toUtc(),
        index: game.matchedCount,
        latencyMs: firstTap == null
            ? null
            : (elapsed - firstTap!).inMilliseconds.clamp(0, 1 << 31),
      ),
    ]);
    firstTap = null;
  }

  void _send(List<PracticeEvent> es) {
    if (es.isEmpty) return;
    for (final e in es) {
      pending[e.id] = e;
    }
    data.append(es).then((_) {
      for (final e in es) {
        pending.remove(e.id);
      }
    }, onError: (Object _, StackTrace _) {});
  }

  Future<bool> retry() async {
    try {
      if (pending.isNotEmpty) {
        final es = pending.values.toList();
        await data.append(es);
        for (final e in es) {
          pending.remove(e.id);
        }
      }
      if (_terminal != null) {
        await data.saveSession(_terminal!);
        await data.reconcileAchievements();
      }
      if (data.hasPendingEvents) await data.append([]);
      await data.flush();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> finish(SessionResult result) async {
    if (!_finished) {
      _finished = true;
      _terminal = {
        'id': id,
        'mode': 'match',
        'packId': packId,
        'at': started.toIso8601String(),
        'finishedAt': data.now().toUtc().toIso8601String(),
        'completed': result.targetReached,
        'endReason': result.endReason.name,
        'correct': result.completedMatches,
        'target': game.config.targetMatches,
        'wrong': result.wrongAttempts,
        'elapsedMs': result.elapsedTime.inMilliseconds,
        'unique': correctlyMatched.length,
        'newConcepts': newConcepts,
        'presented': presented.length,
        'bestCombo': bestCombo,
      };
    }
    return retry();
  }
}
