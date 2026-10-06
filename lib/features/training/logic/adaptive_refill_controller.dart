import 'dart:async';

import 'package:clock/clock.dart';

import 'match_refill_timing.dart';
import 'matching_engine.dart';

enum RefillPhase { active, success, matchedFading, fastFinalizing, refilling }

typedef RefillVisual = ({
  int revision,
  RefillPhase phase,
  double opacity,
  Duration duration,
  Duration? endAt,
  bool fromZero,
  bool scaleIn,
});

const activeRefillVisual = (
  revision: 0,
  phase: RefillPhase.active,
  opacity: 1.0,
  duration: Duration.zero,
  endAt: null,
  fromZero: false,
  scaleIn: false,
);

class _WaitingPair {
  _WaitingPair(
    this.token,
    this.confirmAt,
    this.returnAt,
    this.fadeIn,
    this.surface,
    this.text,
  ) : textOutAt = returnAt - fadeIn;
  final int token;
  final Duration confirmAt;
  Duration returnAt, fadeIn, textOutAt;
  bool accelerated = false;
  RefillVisual surface, text;
  Duration get surfaceOutAt => returnAt - fadeIn;
}

class _IncomingSurface {
  _IncomingSurface(
    this.cardId,
    this.sourcePairId,
    this.token,
    this.endAt,
    this.visual,
  );
  final String cardId, sourcePairId;
  final int token;
  final Duration endAt;
  final RefillVisual visual;
}

/// Independent return deadlines own content until its one atomic publication.
/// A published instance owns an incoming-only surface animation. An outgoing
/// match never grants its replacement permission to fade out again.
class AdaptiveRefillController {
  AdaptiveRefillController(
    this.game, {
    this.timing = MatchRefillTiming.standard,
    Duration Function()? now,
    this.onChanged,
  }) : _readClock = now ?? _clockSinceStart();

  final MatchingEngine game;
  final MatchRefillTiming timing;
  final Duration Function() _readClock;
  final void Function()? onChanged;
  final _waiting = <String, _WaitingPair>{};
  final _incoming = <String, ({Duration endAt, RefillVisual visual})>{};
  final _decorations = <BoardSlot, _IncomingSurface>{};
  Timer? _timer;
  Duration? _armedAt, _pausedAt;
  Duration _pausedFor = Duration.zero, _lastNow = Duration.zero;
  int _generation = 0, _revision = 0, _token = 0;
  bool _disposed = false, _synchronizing = false;

  static Duration Function() _clockSinceStart() {
    final start = clock.now();
    return () => clock.now().difference(start);
  }

  Duration get _now {
    final current = (_pausedAt ?? _readClock()) - _pausedFor;
    if (current > _lastNow) _lastNow = current;
    return _lastNow;
  }

  bool get paused => _pausedAt != null;
  Duration get elapsed => _now;
  Duration? get nextDeadline => _armedAt;
  bool get hasPendingTimer => _timer?.isActive ?? false;
  RefillPhase? phaseOf(String id) => _waiting[id]?.text.phase;
  Duration? returnDeadlineOf(String id) =>
      _waiting[id]?.returnAt ??
      _decorations.values.where((d) => d.sourcePairId == id).firstOrNull?.endAt;
  int? tokenOf(String id) =>
      _waiting[id]?.token ??
      _decorations.values.where((d) => d.sourcePairId == id).firstOrNull?.token;

  RefillVisual _remaining(RefillVisual visual) => (
    revision: visual.revision,
    phase: visual.phase,
    opacity: visual.opacity,
    duration: visual.endAt == null
        ? visual.duration
        : (visual.endAt! > _now ? visual.endAt! - _now : Duration.zero),
    endAt: visual.endAt,
    fromZero: visual.fromZero,
    scaleIn: visual.scaleIn,
  );

  RefillVisual visualFor(BoardSlot slot) {
    final card = game.cardAt(slot);
    if (card == null) return activeRefillVisual;
    final waiting = _waiting[card.pairId];
    if (waiting != null) return _remaining(waiting.surface);
    final decoration = _decorations[slot];
    return decoration?.cardId == card.id
        ? _remaining(decoration!.visual)
        : activeRefillVisual;
  }

  RefillVisual textVisualFor(BoardSlot slot) {
    final card = game.cardAt(slot);
    if (card == null) return activeRefillVisual;
    return _remaining(
      _waiting[card.pairId]?.text ??
          _incoming[card.pairId]?.visual ??
          activeRefillVisual,
    );
  }

  bool returningFromSuccess(BoardSlot slot) =>
      _decorations[slot]?.cardId == game.cardAt(slot)?.id;

  RefillVisual _visual(
    RefillPhase phase,
    Duration? endAt, {
    bool fromZero = false,
    bool scaleIn = false,
  }) => (
    revision: ++_revision,
    phase: phase,
    opacity:
        phase == RefillPhase.matchedFading ||
            phase == RefillPhase.fastFinalizing
        ? 0.0
        : 1.0,
    duration: endAt != null && endAt > _now ? endAt - _now : Duration.zero,
    endAt: endAt,
    fromZero: fromZero,
    scaleIn: scaleIn,
  );

  RefillVisual _target(RefillVisual old, RefillPhase phase, Duration endAt) =>
      old.phase == phase && old.endAt == endAt ? old : _visual(phase, endAt);

  void setPaused(bool value) {
    if (_disposed || value == paused) return;
    if (value) {
      synchronize();
      _pausedAt = _readClock();
      _cancelTimer();
    } else {
      final interval = _readClock() - _pausedAt!;
      if (interval > Duration.zero) _pausedFor += interval;
      _pausedAt = null;
      synchronize();
    }
    onChanged?.call();
  }

  bool _observeMatches(Duration now) {
    var changed = false;
    final matched = game.matchedPairIds;
    _waiting.removeWhere((id, _) => !matched.contains(id));
    for (final id in matched) {
      if (_waiting.containsKey(id)) continue;
      // Only a new accepted answer can shorten an outstanding return. Taps,
      // errors and animation callbacks cannot postpone or restart it.
      for (final previous in _waiting.values) {
        final candidate = now + timing.acceleratedRemainingDuration;
        if (candidate < previous.returnAt) {
          previous.returnAt = candidate;
          previous.fadeIn = timing.refillFadeInDuration;
          previous.accelerated = true;
        }
      }
      final end = now + timing.slowTotalDuration;
      _waiting[id] = _WaitingPair(
        ++_token,
        now + timing.successConfirmDuration,
        end,
        timing.fallbackRefillFadeInDuration,
        _visual(RefillPhase.success, null),
        _visual(RefillPhase.success, null),
      );
      _incoming.remove(id);
      changed = true;
    }
    return changed;
  }

  void _planText(Duration now) {
    for (final waiting in _waiting.values) {
      waiting.textOutAt = waiting.surfaceOutAt;
    }
    for (final plan in game.transitions.toList()) {
      if (plan.committed) continue;
      final groups = plan.retiringPairIds.map((id) => _waiting[id]!).toList();
      final reveal = groups
          .map((g) => g.surfaceOutAt)
          .reduce((a, b) => a < b ? a : b);
      final confirm = groups
          .map((g) => g.confirmAt)
          .reduce((a, b) => a > b ? a : b);
      if (plan.isCrossRefill &&
          reveal < confirm + timing.fastFinalizeDuration) {
        // Near the old deadline, keep its solo return instead of delaying it
        // or making the newer group's text blink through its confirmation.
        game.splitTransition(plan.token);
        continue;
      }
      for (final group in groups) {
        group.textOutAt = reveal;
      }
    }
    for (final entry in _waiting.entries) {
      final waiting = entry.value;
      if (now >= waiting.textOutAt &&
          game.queuedPairCount > 0 &&
          !game.transitions.any((t) => t.retiringPairIds.contains(entry.key))) {
        game.requestFallback(entry.key);
      }
    }
  }

  bool _advanceWaiting(Duration now) {
    var changed = false;
    for (final entry in _waiting.entries) {
      final waiting = entry.value;
      if (now < waiting.confirmAt) continue;
      game.settlePair(entry.key);
      final surfacePhase = waiting.accelerated
          ? RefillPhase.fastFinalizing
          : RefillPhase.matchedFading;
      final textPhase =
          waiting.accelerated || waiting.textOutAt < waiting.surfaceOutAt
          ? RefillPhase.fastFinalizing
          : RefillPhase.matchedFading;
      final surface = _target(
        waiting.surface,
        surfacePhase,
        waiting.surfaceOutAt,
      );
      final text = _target(waiting.text, textPhase, waiting.textOutAt);
      changed = changed || surface != waiting.surface || text != waiting.text;
      waiting.surface = surface;
      waiting.text = text;
    }
    return changed;
  }

  bool _publishDue(Duration now) {
    var changed = false;
    for (final plan in game.transitions.toList()) {
      if (plan.committed || !game.isTransitionReady(plan.token)) continue;
      final groups = {for (final id in plan.retiringPairIds) id: _waiting[id]!};
      final reveal = groups.values
          .map((g) => g.textOutAt)
          .reduce((a, b) => a < b ? a : b);
      if (now < reveal) continue;
      final plannedEnd = groups.values
          .map((g) => g.returnAt)
          .reduce((a, b) => a < b ? a : b);
      final appearance = plan.isCrossRefill
          ? timing.refillFadeInDuration
          : timing.fallbackRefillFadeInDuration;
      // If a held pointer or a suspended event loop delayed publication beyond
      // its return deadline, start a real fade-in instead of publishing at one.
      final end = plannedEnd > now ? plannedEnd : now + appearance;
      game.commitTransition(plan.token);
      if (!plan.committed) continue;
      game.completeTransition(plan.token);
      for (final entry in plan.incoming.entries) {
        final old = groups[plan.outgoing[entry.key]!.pairId]!;
        final surfaceEnd = old.returnAt > now ? old.returnAt : end;
        _decorations[entry.key] = _IncomingSurface(
          entry.value.id,
          plan.outgoing[entry.key]!.pairId,
          old.token,
          surfaceEnd,
          // Keep the independent return deadline, but revoke the old outgoing
          // fade immediately. The slot continues from its current opacity
          // towards one; only this new instance's own match may lower it.
          _visual(RefillPhase.refilling, surfaceEnd),
        );
        _incoming.putIfAbsent(
          entry.value.pairId,
          () => (
            endAt: end,
            visual: _visual(
              RefillPhase.refilling,
              end,
              fromZero: true,
              scaleIn: plan.isCrossRefill,
            ),
          ),
        );
      }
      for (final id in plan.retiringPairIds) {
        _waiting.remove(id);
      }
      changed = true;
    }
    return changed;
  }

  bool _advanceDecoration(Duration now) {
    var changed = false;
    for (final slot in _decorations.keys.toList()) {
      final d = _decorations[slot]!;
      if (game.cardAt(slot)?.id != d.cardId ||
          game.isMatched(d.cardId) ||
          now >= d.endAt) {
        _decorations.remove(slot);
        changed = true;
      }
    }
    for (final id in _incoming.keys.toList()) {
      if (now >= _incoming[id]!.endAt ||
          !game.cards.any((c) => c.pairId == id)) {
        _incoming.remove(id);
        changed = true;
      }
    }
    return changed;
  }

  void synchronize() {
    if (_disposed || _synchronizing) return;
    _synchronizing = true;
    try {
      final now = _now;
      if (game.isComplete) {
        final changed =
            _waiting.isNotEmpty ||
            _incoming.isNotEmpty ||
            _decorations.isNotEmpty;
        _waiting.clear();
        _incoming.clear();
        _decorations.clear();
        _cancelTimer();
        if (changed) onChanged?.call();
        return;
      }
      var changed = _observeMatches(now);
      while (true) {
        _planText(now);
        changed = _advanceWaiting(now) || changed;
        if (!_publishDue(now)) break;
        changed = true;
      }
      changed = _advanceDecoration(now) || changed;
      final future = <Duration>[
        for (final waiting in _waiting.values) ...[
          if (waiting.confirmAt > now) waiting.confirmAt,
          if (game.queuedPairCount > 0 && waiting.textOutAt > now)
            waiting.textOutAt,
        ],
        for (final d in _decorations.values) ...[if (d.endAt > now) d.endAt],
        for (final incoming in _incoming.values)
          if (incoming.endAt > now) incoming.endAt,
      ]..sort();
      _arm(future.firstOrNull, now);
      if (changed) onChanged?.call();
    } finally {
      _synchronizing = false;
    }
  }

  void _cancelTimer() {
    _timer?.cancel();
    _timer = null;
    _armedAt = null;
    _generation++;
  }

  void _arm(Duration? deadline, Duration now) {
    if (deadline == _armedAt && (_timer?.isActive ?? false)) return;
    _cancelTimer();
    if (deadline == null || paused) return;
    _armedAt = deadline;
    final generation = _generation;
    _timer = Timer(deadline > now ? deadline - now : Duration.zero, () {
      if (_disposed || paused || generation != _generation) return;
      _timer = null;
      _armedAt = null;
      if (deadline > _lastNow) _lastNow = deadline;
      synchronize();
    });
  }

  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _cancelTimer();
    _waiting.clear();
    _incoming.clear();
    _decorations.clear();
    game.cancelRefillPlans();
  }
}
