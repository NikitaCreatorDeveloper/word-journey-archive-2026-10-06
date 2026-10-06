import '../model/session_result.dart';
import 'matching_engine.dart';
import 'session_clock.dart';

/// Coordinates the board and its monotonic deadline without depending on Flutter.
class TrainingSession {
  TrainingSession(this.game, {SessionClock? clock})
    : clock =
          clock ??
          SessionClock(
            limitSeconds: game.config.isTimed
                ? game.config.timeLimitSeconds
                : null,
          );

  final MatchingEngine game;
  final SessionClock clock;
  SessionResult? get result => game.result;

  void resume() {
    if (result != null) {
      clock.pause();
      return;
    }
    tick();
    if (result == null) clock.resume();
  }

  void pause() {
    clock.pause();
    tick();
  }

  void tick() {
    if (result != null) {
      clock.pause();
      return;
    }
    if (game.config.finishOnTarget &&
        game.matchedCount >= game.totalPairCount) {
      endSession(SessionEndReason.targetReached);
    } else if (clock.isExpired) {
      endSession(SessionEndReason.timeExpired);
    }
  }

  MatchFeedback? select(String id) {
    // Capture the event's active elapsed time once. The exact deadline loses.
    if (result != null || !clock.isRunning) return null;
    final elapsed = clock.elapsed;
    if (clock.limit != null && elapsed >= clock.limit!) {
      endSession(SessionEndReason.timeExpired, elapsed: elapsed);
      return null;
    }
    final feedback = game.select(id);
    if (game.config.enforceMistakeLimit &&
        game.config.maxMistakes > 0 &&
        game.errorCount >= game.config.maxMistakes) {
      endSession(SessionEndReason.mistakeLimit, elapsed: elapsed);
    }
    if (game.config.finishOnTarget &&
        game.matchedCount >= game.totalPairCount) {
      endSession(SessionEndReason.targetReached, elapsed: elapsed);
    }
    return feedback;
  }

  SessionResult endSession(SessionEndReason reason, {Duration? elapsed}) {
    if (result case final existing?) return existing;
    clock.pause();
    final activeTime = elapsed ?? clock.elapsed;
    final limit = clock.limit;
    final bounded = limit != null && activeTime > limit ? limit : activeTime;
    // Exit at/past the deadline is a timeout, not a lost race to the X button.
    final resolved =
        limit != null &&
            activeTime >= limit &&
            game.matchedCount < game.totalPairCount
        ? SessionEndReason.timeExpired
        : reason;
    return game.endSession(
      reason: resolved,
      elapsedTime: bounded,
      remainingTime: limit == null ? null : limit - bounded,
    );
  }
}
