import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../logic/matching_engine.dart';
import '../model/match_flow_models.dart';
import 'training_word_card.dart';

typedef _FlowSnapshot = ({MatchSlotState flow, int error});

class MatchFlowBoard extends StatefulWidget {
  const MatchFlowBoard({
    super.key,
    required this.game,
    required this.cardHeight,
    required this.errors,
    required this.onSelect,
    required this.onBoardChanged,
    this.changes,
    this.pause,
    this.paused = false,
  });
  final MatchingEngine game;
  final double cardHeight;
  final Map<String, int> errors;
  final ValueChanged<String> onSelect;
  final VoidCallback onBoardChanged;
  final Listenable? changes;
  final ValueListenable<bool>? pause;
  final bool paused;
  @override
  State<MatchFlowBoard> createState() => _MatchFlowBoardState();
}

class _MatchFlowBoardState extends State<MatchFlowBoard> {
  final _slots = <MatchSlotId, ValueNotifier<_FlowSnapshot>>{};
  final _listeners = <MatchSlotId, VoidCallback>{};
  bool _noticePending = false;
  bool get _paused => widget.pause?.value ?? widget.paused;
  _FlowSnapshot _snapshot(MatchSlotId slot) => (
    flow: widget.game.matchFlow!.stateOf(slot).value,
    error: widget.errors[widget.game.cardAt(slot)?.id] ?? 0,
  );
  void _slotChanged(MatchSlotId slot) {
    final old = _slots[slot]!.value, next = _snapshot(slot);
    _slots[slot]!.value = next;
    if ((old.flow.content != next.flow.content ||
            old.flow.interactive != next.flow.interactive) &&
        !_noticePending) {
      _noticePending = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _noticePending = false;
        if (mounted && !_paused && !widget.game.isComplete) {
          widget.onBoardChanged();
        }
      });
    }
  }

  void _changed() {
    for (final slot in _slots.keys) {
      _slotChanged(slot);
    }
  }

  void _pauseChanged() => widget.game.matchFlow!.setPaused(_paused);
  @override
  void initState() {
    super.initState();
    final flow = widget.game.matchFlow!;
    flow.setPaused(_paused);
    for (final slot in flow.boardSlots) {
      _slots[slot] = ValueNotifier(_snapshot(slot));
      void callback() => _slotChanged(slot);
      _listeners[slot] = callback;
      flow.stateOf(slot).addListener(callback);
    }
    widget.changes?.addListener(_changed);
    widget.pause?.addListener(_pauseChanged);
  }

  @override
  void didUpdateWidget(MatchFlowBoard old) {
    super.didUpdateWidget(old);
    if (old.changes != widget.changes) {
      old.changes?.removeListener(_changed);
      widget.changes?.addListener(_changed);
    }
    if (old.pause != widget.pause) {
      old.pause?.removeListener(_pauseChanged);
      widget.pause?.addListener(_pauseChanged);
    }
    _pauseChanged();
    _changed();
  }

  @override
  void dispose() {
    widget.changes?.removeListener(_changed);
    widget.pause?.removeListener(_pauseChanged);
    for (final entry in _listeners.entries) {
      widget.game.matchFlow!.stateOf(entry.key).removeListener(entry.value);
    }
    for (final slot in _slots.values) {
      slot.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      for (var row = 0; row < widget.game.visiblePairCount; row++) ...[
        if (row > 0) const SizedBox(height: 10),
        SizedBox(
          height: widget.cardHeight,
          child: Row(
            children: [
              for (final left in [true, false]) ...[
                if (!left) const SizedBox(width: 10),
                Expanded(
                  child: _FlowSlot(
                    key: ValueKey('slot-${left ? 'left' : 'right'}-$row'),
                    slot: (left: left, row: row),
                    state: _slots[(left: left, row: row)]!,
                    game: widget.game,
                    onSelect: widget.onSelect,
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

class _FlowSlot extends StatelessWidget {
  const _FlowSlot({
    super.key,
    required this.slot,
    required this.state,
    required this.game,
    required this.onSelect,
  });
  final MatchSlotId slot;
  final ValueListenable<_FlowSnapshot> state;
  final MatchingEngine game;
  final ValueChanged<String> onSelect;
  @override
  Widget build(BuildContext context) => ValueListenableBuilder<_FlowSnapshot>(
    valueListenable: state,
    builder: (context, snapshot, _) {
      final card = game.cardAt(slot), flow = snapshot.flow;
      if (card == null) return const SizedBox.expand();
      return TrainingWordCard(
        key: ValueKey(card.id),
        text: card.text,
        selected: flow.selected,
        completed: flow.matched,
        enabled: flow.interactive,
        retainSuccess: true,
        errorRevision: snapshot.error,
        flowVisual: flow.visual,
        onPressed: () {
          final current = game.matchFlow!.stateOf(slot).value;
          if (identical(game.cardAt(slot), card) &&
              current.content.instance == flow.content.instance &&
              current.interactive &&
              game.isActive(card.id)) {
            onSelect(card.id);
          }
        },
      );
    },
  );
}
