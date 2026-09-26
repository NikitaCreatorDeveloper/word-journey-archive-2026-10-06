/// Monotonic elapsed-time clock. UI ticks only request a snapshot.
class SessionClock {
  factory SessionClock({required int limitSeconds, Duration Function()? now}) {
    if (limitSeconds <= 0) {
      throw ArgumentError.value(limitSeconds);
    }
    final watch = Stopwatch()..start();
    return SessionClock._(
      Duration(seconds: limitSeconds),
      now ?? () => watch.elapsed,
    );
  }
  SessionClock._(this.limit, this._now);
  final Duration limit;
  final Duration Function() _now;
  Duration _accumulated = Duration.zero;
  Duration? _startedAt;
  bool get isRunning => _startedAt != null;
  Duration get elapsed =>
      _accumulated +
      (_startedAt == null ? Duration.zero : _now() - _startedAt!);
  Duration get remaining => elapsed >= limit ? Duration.zero : limit - elapsed;
  int get remainingSeconds =>
      (remaining.inMicroseconds / Duration.microsecondsPerSecond).ceil();
  bool get isExpired => remaining == Duration.zero;
  void resume() {
    if (!isRunning && !isExpired) {
      _startedAt = _now();
    }
  }

  void pause() {
    _accumulated = elapsed;
    _startedAt = null;
  }
}
