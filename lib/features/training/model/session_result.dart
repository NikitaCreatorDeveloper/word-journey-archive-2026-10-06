enum SessionEndReason { targetReached, timeExpired, userExited, mistakeLimit }

/// Frozen once by the engine, independent of routes and animation callbacks.
class SessionResult {
  const SessionResult({
    required this.targetMatches,
    required this.completedMatches,
    required this.wrongAttempts,
    required this.elapsedTime,
    required this.remainingTime,
    required this.endReason,
  });

  final int targetMatches;
  final int completedMatches;
  int get correctMatches => completedMatches;
  final int wrongAttempts;
  final Duration elapsedTime;

  /// Null for a session without a deadline.
  final Duration? remainingTime;
  final SessionEndReason endReason;
  bool get targetReached => endReason == SessionEndReason.targetReached;
}
