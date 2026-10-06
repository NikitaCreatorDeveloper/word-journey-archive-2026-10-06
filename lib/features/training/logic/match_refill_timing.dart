/// Shared tuning for feedback, waiting deadlines and local opacity animations.
class MatchRefillTiming {
  const MatchRefillTiming({
    this.slowTotalDuration = const Duration(milliseconds: 5000),
    this.acceleratedRemainingDuration = const Duration(milliseconds: 1000),
    this.successConfirmDuration = const Duration(milliseconds: 140),
    this.fallbackRefillFadeInDuration = const Duration(milliseconds: 600),
    this.fastFinalizeDuration = const Duration(milliseconds: 200),
    this.refillFadeInDuration = const Duration(milliseconds: 340),
  });

  static const standard = MatchRefillTiming();
  final Duration slowTotalDuration;
  final Duration acceleratedRemainingDuration;
  final Duration successConfirmDuration;
  Duration get slowMatchedFadeDuration =>
      slowTotalDuration - successConfirmDuration - fallbackRefillFadeInDuration;

  /// Measured from the accepted match, independently of the outgoing fade.
  Duration get fallbackDeadlineDuration =>
      slowTotalDuration - fallbackRefillFadeInDuration;
  final Duration fallbackRefillFadeInDuration;
  final Duration fastFinalizeDuration;
  final Duration refillFadeInDuration;
}
