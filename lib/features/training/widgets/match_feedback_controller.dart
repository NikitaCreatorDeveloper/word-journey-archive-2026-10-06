import 'package:flutter/foundation.dart';

import 'match_feedback_assets.dart';

/// A playback epoch is independent of a changing Flutter combo caption.
class MatchFeedbackEvent {
  MatchFeedbackEvent({
    required this.kind,
    required this.token,
    this.count = 0,
    this.rewardRevision = 0,
    this.elapsed = Duration.zero,
  });
  final MatchDecoration kind;
  final int token, count, rewardRevision;
  Duration elapsed;
  bool _completed = false;
  bool get completed => _completed;
  void complete() {
    _completed = true;
  }

  void recordElapsed(Duration value) {
    if (value > elapsed) elapsed = value;
  }
}

/// Bounded visual mailbox: one reward and one local HUD pulse, never a FIFO.
/// It knows nothing about the matching engine, persistence, audio or navigation.
class MatchFeedbackController {
  MatchFeedbackController({MatchFeedbackAssets? assets})
    : assets = assets ?? MatchFeedbackAssets.shared;
  final MatchFeedbackAssets assets;
  final reward = ValueNotifier<MatchFeedbackEvent?>(null);
  final milestone = ValueNotifier<MatchFeedbackEvent?>(null);
  int _serial = 0;
  bool _disposed = false;
  bool get disposed => _disposed;
  Future<void> prepare() => assets.preload();
  void showCorrect({int revision = 0}) {
    if (_disposed ||
        reward.value?.kind == MatchDecoration.combo ||
        reward.value?.kind == MatchDecoration.victory) {
      return;
    }
    reward.value = MatchFeedbackEvent(
      kind: MatchDecoration.correct,
      token: ++_serial,
      rewardRevision: revision,
    );
  }

  void showCombo(int count, {int revision = 0}) {
    if (_disposed ||
        count < 2 ||
        reward.value?.kind == MatchDecoration.victory) {
      return;
    }
    reward.value = MatchFeedbackEvent(
      kind: MatchDecoration.combo,
      token: ++_serial,
      count: count,
      rewardRevision: revision,
    );
  }

  void showMilestone(int value) {
    if (_disposed ||
        reward.value?.kind == MatchDecoration.victory ||
        ![20, 30, 60].contains(value)) {
      return;
    }
    milestone.value = MatchFeedbackEvent(
      kind: MatchDecoration.milestone,
      token: ++_serial,
      count: value,
    );
  }

  void showVictory({int count = 60}) {
    if (_disposed) return;
    reward.value = MatchFeedbackEvent(
      kind: MatchDecoration.victory,
      token: ++_serial,
      count: count,
    );
  }

  void resetStreak() {
    if (!_disposed && reward.value?.kind != MatchDecoration.victory) {
      reward.value = null;
    }
  }

  void finishReward(int token) {
    if (!_disposed && reward.value?.token == token) reward.value = null;
  }

  void finishMilestone(int token) {
    if (!_disposed && milestone.value?.token == token) milestone.value = null;
  }

  void stopTransient() {
    if (_disposed) return;
    milestone.value = null;
    if (reward.value?.kind != MatchDecoration.victory) reward.value = null;
  }

  MatchFeedbackEvent? takeVictory() {
    if (_disposed || reward.value?.kind != MatchDecoration.victory) return null;
    stopTransient();
    final event = reward.value!;
    final seed = MatchFeedbackEvent(
      kind: event.kind,
      token: event.token,
      count: event.count,
      elapsed: event.elapsed,
    );
    reward.value = null;
    return seed;
  }

  void dispose() {
    if (_disposed) return;
    _disposed = true;
    reward.dispose();
    milestone.dispose();
  }
}
