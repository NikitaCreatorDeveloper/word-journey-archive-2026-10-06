enum SessionMode { practice, timed, checkpoint }

/// Shared input for training launched from any part of the app.
/// A deadline limits the time to reach the goal; mistake limits remain metadata.
class SessionConfig {
  SessionConfig({
    required this.visiblePairs,
    required this.wordPoolSize,
    required this.targetMatches,
    required this.maxMistakes,
    required this.mode,
    this.timeLimitSeconds,
    bool? finishOnTarget,
  }) : finishOnTarget = finishOnTarget ?? true {
    if (visiblePairs < 1) {
      throw ArgumentError.value(
        visiblePairs,
        'visiblePairs',
        'Must be positive',
      );
    }
    if (wordPoolSize < visiblePairs) {
      throw ArgumentError.value(
        wordPoolSize,
        'wordPoolSize',
        'Must cover all visible pairs',
      );
    }
    if (targetMatches < 1) {
      throw ArgumentError.value(
        targetMatches,
        'targetMatches',
        'Must be positive',
      );
    }
    if (maxMistakes < 0) {
      throw ArgumentError.value(
        maxMistakes,
        'maxMistakes',
        'Cannot be negative',
      );
    }
    if (timeLimitSeconds != null && timeLimitSeconds! <= 0) {
      throw ArgumentError.value(
        timeLimitSeconds,
        'timeLimitSeconds',
        'Must be positive or null',
      );
    }
  }

  final int visiblePairs;
  final int wordPoolSize;
  final int targetMatches;
  final int maxMistakes;
  final int? timeLimitSeconds;
  final SessionMode mode;
  final bool finishOnTarget;
  bool get isTimed => mode == SessionMode.timed && timeLimitSeconds != null;
}
