import 'session_config.dart';

/// Immutable snapshot of session counters and selection.
class SessionState {
  const SessionState({
    required this.config,
    this.matchedCount = 0,
    this.mistakes = 0,
    this.selectedCardId,
    this.timedOut = false,
  });

  final SessionConfig config;
  final int matchedCount;
  final int mistakes;
  final String? selectedCardId;
  final bool timedOut;

  double get progress => (matchedCount / config.targetMatches).clamp(0.0, 1.0);
  bool get isComplete =>
      timedOut ||
      (config.finishOnTarget && matchedCount >= config.targetMatches);
}
