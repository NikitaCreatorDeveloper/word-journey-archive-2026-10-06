import 'session_result.dart';
import 'session_config.dart';

/// Immutable snapshot of session counters and selection.
class SessionState {
  const SessionState({
    required this.config,
    this.matchedCount = 0,
    this.mistakes = 0,
    this.selectedCardId,
    this.timedOut = false,
    this.endReason,
  });

  final SessionConfig config;
  final int matchedCount;
  final int mistakes;
  final String? selectedCardId;
  final bool timedOut;
  final SessionEndReason? endReason;

  double get progress => (matchedCount / config.targetMatches).clamp(0.0, 1.0);
  bool get isComplete =>
      endReason != null ||
      timedOut ||
      (config.finishOnTarget && matchedCount >= config.targetMatches);
}
