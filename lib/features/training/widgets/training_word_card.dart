import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../app/app_theme.dart';

class TrainingWordCard extends StatefulWidget {
  const TrainingWordCard({
    super.key,
    required this.text,
    required this.selected,
    required this.onPressed,
    this.errorRevision = 0,
    this.completed = false,
    this.onSettled,
  });
  final String text;
  final bool selected;
  final int errorRevision;
  final bool completed;
  final VoidCallback onPressed;
  final VoidCallback? onSettled;

  @override
  State<TrainingWordCard> createState() => _TrainingWordCardState();
}

class _TrainingWordCardState extends State<TrainingWordCard>
    with TickerProviderStateMixin {
  late final AnimationController _errorAnimation = AnimationController(
    vsync: this,
    duration: AppTokens.feedbackDuration,
    value: 1,
  );
  late final AnimationController _settleAnimation =
      AnimationController(
        vsync: this,
        duration: AppTokens.matchedSettleDuration,
        value: 1,
      )..addStatusListener((status) {
        if (status == AnimationStatus.completed && widget.completed) {
          widget.onSettled?.call();
        }
      });
  bool _pressed = false;

  @override
  void initState() {
    super.initState();
    if (widget.completed) {
      _settleAnimation.forward(from: 0);
    }
  }

  @override
  void didUpdateWidget(TrainingWordCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.completed && !oldWidget.completed) {
      _settleAnimation.forward(from: 0);
    }
    if (widget.errorRevision != oldWidget.errorRevision) {
      _errorAnimation.forward(from: 0);
    } else if (widget.selected && !oldWidget.selected || widget.completed) {
      _errorAnimation.value = 1;
    }
  }

  @override
  void dispose() {
    _errorAnimation.dispose();
    _settleAnimation.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final atlas = AtlasColors.of(context);
    return LayoutBuilder(
      builder: (context, constraints) => AnimatedBuilder(
        animation: Listenable.merge([_errorAnimation, _settleAnimation]),
        builder: (context, child) {
          final phase = _errorAnimation.value;
          final error =
              _errorAnimation.isAnimating &&
              !widget.selected &&
              !widget.completed;
          final baseColor = widget.completed
              ? Color.lerp(
                  atlas.card,
                  atlas.success,
                  Curves.easeOutCubic.transform(_settleAnimation.value),
                )!
              : widget.selected
              ? atlas.selected
              : atlas.card;
          final background = error
              ? Color.lerp(
                  baseColor,
                  atlas.error,
                  (1 - phase) * AppTokens.wrongTintStrength,
                )!
              : baseColor;
          final foreground = widget.completed
              ? atlas.onSuccess
              : error
              ? atlas.onError
              : widget.selected
              ? atlas.onSelected
              : theme.colorScheme.onSurface;
          final shake = error
              ? math.sin(phase * math.pi * 4) *
                    (1 - phase) *
                    AppTokens.wrongOffset
              : 0.0;
          return Transform.scale(
            scale: widget.completed
                ? 1 +
                      AppTokens.correctScaleAmplitude *
                          math.sin(_settleAnimation.value * math.pi)
                : 1,
            child: Transform.translate(
              offset: Offset(shake, 0),
              child: AnimatedScale(
                scale: _pressed && !widget.completed ? AppTokens.pressScale : 1,
                duration: AppTokens.pressDuration,
                curve: Curves.easeOut,
                child: Semantics(
                  button: true,
                  selected: widget.selected,
                  enabled: !widget.completed,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(AppTokens.cardRadius),
                      boxShadow: atlas.cardShadows,
                    ),
                    child: Material(
                      color: background,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          AppTokens.cardRadius,
                        ),
                        side: BorderSide(
                          color: widget.selected
                              ? theme.colorScheme.primary.withValues(
                                  alpha: AppTokens.selectedBorderOpacity,
                                )
                              : atlas.cardOutline,
                          width: AppTokens.cardBorderWidth,
                        ),
                      ),
                      child: InkWell(
                        onTap: widget.completed ? null : widget.onPressed,
                        onHighlightChanged: (pressed) {
                          if (_pressed != pressed) {
                            setState(() => _pressed = pressed);
                          }
                        },
                        enableFeedback: false,
                        splashFactory: NoSplash.splashFactory,
                        overlayColor: const WidgetStatePropertyAll(
                          Colors.transparent,
                        ),
                        borderRadius: BorderRadius.circular(
                          AppTokens.cardRadius,
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppTokens.cardHorizontalPadding,
                            vertical: AppTokens.cardVerticalPadding,
                          ),
                          child: Center(
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                widget.text,
                                textAlign: TextAlign.center,
                                maxLines: 1,
                                style: TextStyle(
                                  fontSize:
                                      ((constraints.maxHeight -
                                                  AppTokens
                                                          .cardVerticalPadding *
                                                      2) *
                                              AppTokens.wordHeightRatio)
                                          .clamp(
                                            AppTokens.wordSize,
                                            AppTokens.wordMaxSize,
                                          ),
                                  height: AppTokens.wordLineHeight,
                                  fontWeight: AppTokens.wordWeight,
                                  letterSpacing: AppTokens.wordLetterSpacing,
                                  color: foreground,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
