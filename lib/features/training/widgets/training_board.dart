import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

import '../../../app/app_theme.dart';

import '../../../app/design_tokens.dart';
import '../../../app/match_profile_controls.dart';
import '../../../app/motion_preferences.dart';
import '../logic/adaptive_refill_controller.dart';
import '../logic/match_refill_timing.dart';
import '../logic/matching_engine.dart';
import '../model/matching_card.dart';
import 'training_word_card.dart';
import 'match_flow_board.dart';

typedef _SlotSnapshot = ({
  MatchingCard? card,
  bool correct,
  bool selected,
  bool enabled,
  bool paused,
  bool returningFromSuccess,
  int error,
  RefillVisual visual,
  Animation<double> textOpacity,
});

class TrainingBoard extends StatelessWidget {
  const TrainingBoard({
    super.key,
    required this.game,
    required this.cardHeight,
    required this.errors,
    required this.onSelect,
    required this.onBoardChanged,
    this.changes,
    this.paused = false,
    this.pause,
    this.refillTiming = MatchRefillTiming.standard,
  });
  final MatchingEngine game;
  final Listenable? changes;
  final double cardHeight;
  final Map<String, int> errors;
  final ValueChanged<String> onSelect;
  final VoidCallback onBoardChanged;
  final bool paused;
  final ValueListenable<bool>? pause;
  final MatchRefillTiming refillTiming;
  @override
  Widget build(BuildContext context) {
    MatchProfileCounters.hit('board.build');
    if (game.matchFlow != null) {
      return MatchFlowBoard(
        game: game,
        cardHeight: cardHeight,
        errors: errors,
        onSelect: onSelect,
        onBoardChanged: onBoardChanged,
        changes: changes,
        paused: paused,
        pause: pause,
      );
    }
    return _LegacyTrainingBoard(
      game: game,
      cardHeight: cardHeight,
      errors: errors,
      onSelect: onSelect,
      onBoardChanged: onBoardChanged,
      changes: changes,
      paused: paused,
      pause: pause,
      refillTiming: refillTiming,
    );
  }
}

class _LegacyTrainingBoard extends StatefulWidget {
  const _LegacyTrainingBoard({
    required this.game,
    required this.cardHeight,
    required this.errors,
    required this.onSelect,
    required this.onBoardChanged,
    this.changes,
    this.paused = false,
    this.pause,
    this.refillTiming = MatchRefillTiming.standard,
  });
  final MatchingEngine game;
  final Listenable? changes;
  final double cardHeight;
  final Map<String, int> errors;
  final ValueChanged<String> onSelect;
  final VoidCallback onBoardChanged;
  final bool paused;
  final ValueListenable<bool>? pause;
  final MatchRefillTiming refillTiming;
  @override
  State<_LegacyTrainingBoard> createState() => _LegacyBoardState();
}

// A concept's two sides share one glyph animation and one input gate.
// Independent surface animations never determine whether text is playable.
class _PairFade {
  _PairFade(TickerProvider vsync)
    : opacity = AnimationController(vsync: vsync, value: 1);
  final AnimationController opacity;
  RefillVisual? applied;
  bool appearing = false;
  bool get readable =>
      !appearing || opacity.value >= AppMotion.refillReadableOpacity;
  void apply(
    RefillVisual visual, {
    required bool paused,
    required bool minimal,
    required bool tickers,
    bool force = false,
  }) {
    final previous = applied;
    final changed = previous?.revision != visual.revision;
    if (!changed && !force) return;
    applied = visual;
    if (paused) {
      opacity.stop();
      return;
    }
    if (changed && visual.fromZero) {
      appearing = true;
      opacity.value = 0;
    }
    if (minimal || !tickers) {
      opacity.value = visual.phase == RefillPhase.matchedFading
          ? .45
          : visual.opacity;
      return;
    }
    if (!force &&
        previous?.phase == RefillPhase.refilling &&
        visual.phase == RefillPhase.active &&
        opacity.isAnimating) {
      return;
    }
    opacity.animateTo(
      visual.opacity,
      duration: visual.phase == RefillPhase.success
          ? AppMotion.selection
          : visual.duration,
      curve: visual.phase == RefillPhase.matchedFading
          ? Curves.easeInOut
          : AppMotion.curve,
    );
  }
}

class _LegacyBoardState extends State<_LegacyTrainingBoard>
    with TickerProviderStateMixin {
  final _slots = <BoardSlot, ValueNotifier<_SlotSnapshot>>{};
  final _texts = <String, _PairFade>{};
  late AdaptiveRefillController _refills;
  bool _initializingSlots = false,
      _minimal = false,
      _tickers = true,
      _publishing = false;
  MatchingEngine get game => widget.game;
  bool get _paused => widget.pause?.value ?? widget.paused;
  void _initializeSlots() {
    _initializingSlots = true;
    _refills = AdaptiveRefillController(
      game,
      timing: widget.refillTiming,
      onChanged: _refillsChanged,
    );
    _refills.setPaused(_paused);
    _refills.synchronize();
    _syncTexts();
    for (var row = 0; row < game.visiblePairCount; row++) {
      for (final left in [true, false]) {
        final slot = (left: left, row: row);
        _slots[slot] = ValueNotifier(_snapshot(slot));
      }
    }
    _initializingSlots = false;
  }

  void _syncTexts({bool force = false}) {
    final present = <String>{};
    for (final card in game.cards) {
      if (!present.add(card.pairId)) continue;
      final fade = _texts.putIfAbsent(card.pairId, () {
        final value = _PairFade(this);
        value.opacity.addListener(() {
          if (value.appearing && value.readable) {
            value.appearing = false;
            if (!_publishing) _publishSlots();
          }
        });
        return value;
      });
      fade.apply(
        _refills.textVisualFor(game.slotIdOf(card.id)!),
        paused: _paused,
        minimal: _minimal,
        tickers: _tickers,
        force: force,
      );
    }
    for (final id in _texts.keys.toList()) {
      if (!present.contains(id)) _texts.remove(id)!.opacity.dispose();
    }
  }

  _SlotSnapshot _snapshot(BoardSlot slot) {
    final card = game.cardAt(slot), fade = _texts[game.cardAt(slot)?.pairId];
    final nextVisual = _refills.visualFor(slot), previous = _slots[slot]?.value;
    // A tap changes remaining time, but does not restart an unchanged revision.
    final visual =
        previous != null &&
            identical(previous.card, card) &&
            previous.paused == _paused &&
            previous.visual.revision == nextVisual.revision
        ? previous.visual
        : nextVisual;
    return (
      card: card,
      correct: card != null && game.isMatched(card.id),
      selected: card != null && card.id == game.selectedCardId,
      enabled:
          !_paused &&
          card != null &&
          game.isActive(card.id) &&
          (fade?.readable ?? true),
      paused: _paused,
      returningFromSuccess: _refills.returningFromSuccess(slot),
      error: widget.errors[card?.id] ?? 0,
      visual: visual,
      textOpacity: fade?.opacity ?? const AlwaysStoppedAnimation(1),
    );
  }

  void _publishSlots({bool force = false}) {
    if (_publishing) return;
    _publishing = true;
    try {
      _syncTexts(force: force);
      for (final entry in _slots.entries) {
        entry.value.value = _snapshot(entry.key);
      }
    } finally {
      _publishing = false;
    }
  }

  void _changed() {
    if (!mounted) return;
    _refills.synchronize();
    _publishSlots();
  }

  void _refillsChanged() {
    if (!mounted || _initializingSlots) return;
    _publishSlots();
    widget.onBoardChanged();
  }

  void _pointerEnd(int pointer) {
    final currentGame = game;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || game != currentGame) return;
      game.releasePointer(pointer);
      _changed();
      widget.onBoardChanged();
    });
  }

  @override
  void initState() {
    super.initState();
    _initializeSlots();
    widget.changes?.addListener(_changed);
    widget.pause?.addListener(_pauseChanged);
  }

  void _pauseChanged() {
    _refills.setPaused(_paused);
    _publishSlots(force: true);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final minimal = motionOf(context) == 'minimal',
        tickers = TickerMode.valuesOf(context).enabled;
    final changed = minimal != _minimal || tickers != _tickers;
    _minimal = minimal;
    _tickers = tickers;
    if (changed) _publishSlots(force: true);
  }

  void _disposeSlots() {
    _refills.dispose();
    for (final fade in _texts.values) {
      fade.opacity.dispose();
    }
    _texts.clear();
    for (final slot in _slots.values) {
      slot.dispose();
    }
    _slots.clear();
  }

  @override
  void didUpdateWidget(_LegacyTrainingBoard old) {
    super.didUpdateWidget(old);
    if (old.changes != widget.changes) {
      old.changes?.removeListener(_changed);
      widget.changes?.addListener(_changed);
    }
    if (old.pause != widget.pause) {
      old.pause?.removeListener(_pauseChanged);
      widget.pause?.addListener(_pauseChanged);
    }
    if (old.game != game || old.refillTiming != widget.refillTiming) {
      _disposeSlots();
      _initializeSlots();
    }
    if (old.paused != widget.paused || old.pause != widget.pause) {
      _pauseChanged();
    }
    _changed();
  }

  @override
  void dispose() {
    widget.changes?.removeListener(_changed);
    widget.pause?.removeListener(_pauseChanged);
    _disposeSlots();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    MatchProfileCounters.hit('board.build');
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var row = 0; row < game.visiblePairCount; row++) ...[
          if (row > 0) const SizedBox(height: AppTokens.boardGap),
          SizedBox(
            height: widget.cardHeight,
            child: Row(
              children: [
                for (final left in [true, false]) ...[
                  if (!left) const SizedBox(width: AppTokens.boardGap),
                  Expanded(
                    child: _TrainingSlot(
                      key: ValueKey('slot-${left ? 'left' : 'right'}-$row'),
                      slot: (left: left, row: row),
                      state: _slots[(left: left, row: row)]!,
                      game: game,
                      onSelect: widget.onSelect,
                      onPointerEnd: _pointerEnd,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _TrainingSlot extends StatefulWidget {
  const _TrainingSlot({
    super.key,
    required this.slot,
    required this.state,
    required this.game,
    required this.onSelect,
    required this.onPointerEnd,
  });
  final BoardSlot slot;
  final ValueListenable<_SlotSnapshot> state;
  final MatchingEngine game;
  final ValueChanged<String> onSelect;
  final ValueChanged<int> onPointerEnd;
  @override
  State<_TrainingSlot> createState() => _TrainingSlotState();
}

class _TrainingSlotState extends State<_TrainingSlot>
    with SingleTickerProviderStateMixin {
  late _SlotSnapshot _snapshot;
  late final _surfaceOpacity = AnimationController(vsync: this, value: 1);
  bool _minimal = false, _tickersEnabled = true;
  RefillVisual? _appliedVisual;
  @override
  void initState() {
    super.initState();
    _snapshot = widget.state.value;
    widget.state.addListener(_changed);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final minimal = motionOf(context) == 'minimal',
        tickers = TickerMode.valuesOf(context).enabled;
    final changed = minimal != _minimal || tickers != _tickersEnabled;
    _minimal = minimal;
    _tickersEnabled = tickers;
    _animate(_snapshot.visual, force: changed);
  }

  void _animate(RefillVisual visual, {bool force = false}) {
    final previous = _appliedVisual,
        changed = _appliedVisual?.revision != visual.revision;
    if (!changed && !force) return;
    _appliedVisual = visual;
    if (_snapshot.paused) {
      _surfaceOpacity.stop();
      return;
    }
    if (_minimal || !_tickersEnabled) {
      _surfaceOpacity.value = visual.phase == RefillPhase.matchedFading
          ? .45
          : visual.opacity;
      return;
    }
    if (!force &&
        previous?.phase == RefillPhase.refilling &&
        visual.phase == RefillPhase.active &&
        _surfaceOpacity.isAnimating) {
      return;
    }
    _surfaceOpacity.animateTo(
      visual.opacity,
      duration: visual.phase == RefillPhase.success
          ? AppMotion.selection
          : visual.duration,
      curve: visual.phase == RefillPhase.matchedFading
          ? Curves.easeInOut
          : AppMotion.curve,
    );
  }

  void _changed() {
    final next = widget.state.value, old = _snapshot;
    _snapshot = next;
    if (!identical(old.card, next.card)) {
      // A persistent slot must not keep ticking the outgoing instance's fade.
      // Preserve its current value for continuity, then apply the new owner.
      _surfaceOpacity.stop();
      _appliedVisual = null;
    }
    _animate(next.visual, force: old.paused != next.paused);
    setState(() {});
  }

  @override
  void didUpdateWidget(_TrainingSlot old) {
    super.didUpdateWidget(old);
    if (old.state != widget.state) {
      old.state.removeListener(_changed);
      widget.state.addListener(_changed);
      _snapshot = widget.state.value;
      _animate(_snapshot.visual, force: true);
    }
  }

  @override
  void dispose() {
    widget.state.removeListener(_changed);
    _surfaceOpacity.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final snapshot = _snapshot, card = _snapshot.card;
    return IgnorePointer(
      ignoring: !snapshot.enabled,
      child: card == null
          ? const SizedBox.expand()
          : Listener(
              onPointerDown: (e) => widget.game.holdPointer(e.pointer, card.id),
              onPointerUp: (e) => widget.onPointerEnd(e.pointer),
              onPointerCancel: (e) => widget.onPointerEnd(e.pointer),
              child: matchPaintBoundary(
                'card',
                child: TrainingWordCard(
                  key: ValueKey(card.id),
                  text: card.text,
                  selected: snapshot.selected,
                  completed: snapshot.correct,
                  enabled: snapshot.enabled,
                  retainSuccess: snapshot.correct,
                  returningFromSuccess: snapshot.returningFromSuccess,
                  surfaceOpacity: _surfaceOpacity,
                  textOpacity: snapshot.textOpacity,
                  errorRevision: snapshot.error,
                  onPressed: () {
                    if (identical(widget.game.cardAt(widget.slot), card) &&
                        widget.state.value.enabled &&
                        widget.game.isActive(card.id)) {
                      widget.onSelect(card.id);
                    }
                  },
                ),
              ),
            ),
    );
  }
}
