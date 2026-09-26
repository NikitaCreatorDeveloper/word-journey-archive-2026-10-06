import 'package:flutter/material.dart';

import '../../../app/app_theme.dart';
import '../logic/matching_engine.dart';
import '../model/matching_card.dart';
import 'training_word_card.dart';

class TrainingBoard extends StatelessWidget {
  const TrainingBoard({
    super.key,
    required this.game,
    required this.cardHeight,
    required this.errors,
    required this.onSelect,
    required this.onBoardChanged,
  });
  final MatchingEngine game;
  final double cardHeight;
  final Map<String, int> errors;
  final ValueChanged<String> onSelect;
  final VoidCallback onBoardChanged;

  @override
  Widget build(BuildContext context) {
    final left = game.leftCards;
    final right = game.rightCards;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var row = 0; row < game.visiblePairCount; row++) ...[
          if (row > 0) const SizedBox(height: AppTokens.boardGap),
          SizedBox(
            height: cardHeight,
            child: Row(
              children: [
                for (final isLeft in [true, false]) ...[
                  if (!isLeft) const SizedBox(width: AppTokens.boardGap),
                  Expanded(
                    child: _slot((
                      left: isLeft,
                      row: row,
                    ), isLeft ? left[row] : right[row]),
                  ),
                ],
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _slot(BoardSlot slot, MatchingCard? card) {
    BoardTransition? transition;
    for (final t in game.transitions) {
      if (t.slots.contains(slot)) {
        transition = t;
        break;
      }
    }
    return _CardSlot(
      key: ValueKey('slot-${slot.left ? 'left' : 'right'}-${slot.row}'),
      card: card,
      outgoing: transition?.outgoing[slot],
      token: transition?.token,
      correct: card != null && game.isMatched(card.id),
      selectedId: game.selectedCardId,
      errors: errors,
      onSelect: onSelect,
      onSettled: (pairId) {
        game.settlePair(pairId);
        onBoardChanged();
      },
      onTransitionEnd: (token) {
        game.completeTransition(token);
        onBoardChanged();
      },
      onPointerDown: (pointer, id) => game.holdPointer(pointer, id),
      onPointerEnd: (pointer) {
        game.releasePointer(pointer);
        onBoardChanged();
      },
    );
  }
}

/// Settled slots fade in place. The exit acknowledgement swaps the whole batch
/// atomically in the engine; entry never delays input or future matches.
class _CardSlot extends StatefulWidget {
  const _CardSlot({
    super.key,
    required this.card,
    required this.outgoing,
    required this.token,
    required this.correct,
    required this.selectedId,
    required this.errors,
    required this.onSelect,
    required this.onTransitionEnd,
    required this.onSettled,
    required this.onPointerDown,
    required this.onPointerEnd,
  });
  final MatchingCard? card;
  final MatchingCard? outgoing;
  final int? token;
  final bool correct;
  final String? selectedId;
  final Map<String, int> errors;
  final ValueChanged<String> onSelect;
  final ValueChanged<int> onTransitionEnd;
  final ValueChanged<String> onSettled;
  final void Function(int, String) onPointerDown;
  final ValueChanged<int> onPointerEnd;
  @override
  State<_CardSlot> createState() => _CardSlotState();
}

class _CardSlotState extends State<_CardSlot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animation = AnimationController(
    vsync: this,
    value: 1,
  )..addStatusListener(_status);
  double _exitStart = 1;
  int? _runningToken;

  @override
  void initState() {
    super.initState();
    if (widget.token != null) {
      _exit();
    }
  }

  void _status(AnimationStatus status) {
    final token = _runningToken;
    if (status == AnimationStatus.completed && token != null) {
      _runningToken = null;
      widget.onTransitionEnd(token);
    }
  }

  void _endPointer(int pointer) {
    setState(() {});
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        widget.onPointerEnd(pointer);
      }
    });
  }

  void _exit() {
    _runningToken = widget.token;
    _animation.duration =
        AppTokens.batchExitDuration + AppTokens.batchGapDuration;
    _animation.forward(from: 0);
  }

  @override
  void didUpdateWidget(_CardSlot oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.token != widget.token && widget.token != null) {
      _exitStart = oldWidget.token == null
          ? Curves.easeOutCubic.transform(_animation.value)
          : 1;
      _exit();
    } else if (oldWidget.token != widget.token ||
        oldWidget.card?.id != widget.card?.id) {
      _runningToken = null;
      _animation.duration = AppTokens.batchEntryDuration;
      _animation.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _animation.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _animation,
    builder: (context, child) {
      final exiting = widget.token != null;
      final card = exiting ? widget.outgoing : widget.card;
      if (card == null) {
        return const SizedBox.expand();
      }
      final exitFraction =
          (_animation.value *
                  (AppTokens.batchExitDuration + AppTokens.batchGapDuration)
                      .inMicroseconds /
                  AppTokens.batchExitDuration.inMicroseconds)
              .clamp(0.0, 1.0);
      final opacity = exiting
          ? _exitStart * (1 - Curves.easeOutCubic.transform(exitFraction))
          : Curves.easeOutCubic.transform(_animation.value);
      return ExcludeSemantics(
        excluding: exiting || opacity < AppTokens.incomingTapOpacity,
        child: IgnorePointer(
          ignoring: exiting || opacity < AppTokens.incomingTapOpacity,
          child: Listener(
            onPointerDown: (event) =>
                widget.onPointerDown(event.pointer, card.id),
            onPointerUp: (event) => _endPointer(event.pointer),
            onPointerCancel: (event) => _endPointer(event.pointer),
            child: Opacity(
              opacity: opacity,
              child: Transform.scale(
                scale:
                    AppTokens.incomingScale +
                    (1 - AppTokens.incomingScale) * opacity,
                child: TrainingWordCard(
                  key: ValueKey(card.id),
                  text: card.text,
                  selected: !exiting && widget.selectedId == card.id,
                  completed: widget.correct,
                  onSettled: () => widget.onSettled(card.pairId),
                  errorRevision: widget.errors[card.id] ?? 0,
                  onPressed: () {
                    if (widget.token == null &&
                        Curves.easeOutCubic.transform(_animation.value) >=
                            AppTokens.incomingTapOpacity &&
                        widget.card?.id == card.id) {
                      widget.onSelect(card.id);
                    }
                  },
                ),
              ),
            ),
          ),
        ),
      );
    },
  );
}
