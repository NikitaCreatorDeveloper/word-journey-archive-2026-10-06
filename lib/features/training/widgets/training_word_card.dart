import '../../../app/match_profile_controls.dart';

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../app/app_theme.dart';
import '../../../app/motion_preferences.dart';
import '../../../app/design_tokens.dart';
import '../logic/match_refill_timing.dart';
import '../model/match_flow_models.dart';
import 'match_flow_tile.dart';

class TrainingWordCard extends StatefulWidget {
  const TrainingWordCard({
    super.key,
    required this.text,
    required this.selected,
    required this.onPressed,
    this.errorRevision = 0,
    this.completed = false,
    this.enabled = true,
    this.retainSuccess = false,
    this.returningFromSuccess = false,
    this.surfaceOpacity = const AlwaysStoppedAnimation(1),
    this.textOpacity = const AlwaysStoppedAnimation(1),
    this.onSettled,
    this.flowVisual,
  });
  final String text;
  final bool selected;
  final int errorRevision;
  final bool completed;
  final bool enabled;
  final bool retainSuccess;
  final bool returningFromSuccess;
  final Animation<double> surfaceOpacity;
  final Animation<double> textOpacity;
  final VoidCallback onPressed;
  final VoidCallback? onSettled;
  final CardTransitionVisual? flowVisual;

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
  Timer? _accentTimer;
  bool _accent = false;
  void _acceptCorrect() {
    _accent = true;
    _accentTimer?.cancel();
    if (widget.retainSuccess) return;
    _accentTimer = Timer(MatchRefillTiming.standard.successConfirmDuration, () {
      if (!mounted) return;
      setState(() => _accent = false);
      widget.onSettled
          ?.call(); // Optional observer; never used by TrainingBoard.
    });
  }

  bool _pressed = false;
  _CardAppearance? _lastProfileAppearance;
  int _lastProfileError = 0;
  (bool, double, double)? _lastFlowResponse;

  @override
  void initState() {
    super.initState();
    if (widget.flowVisual == null && widget.completed) {
      _acceptCorrect();
    }
  }

  @override
  void didUpdateWidget(TrainingWordCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.flowVisual != null) return;
    if (widget.completed && !oldWidget.completed) {
      _acceptCorrect();
    }
    if (widget.errorRevision != oldWidget.errorRevision) {
      _errorAnimation.forward(from: 0);
    } else if (widget.selected && !oldWidget.selected || widget.completed) {
      _errorAnimation.value = 1;
    }
  }

  @override
  void dispose() {
    if (widget.flowVisual == null) _errorAnimation.dispose();
    _accentTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    MatchProfileCounters.hit('card.build');
    if (widget.flowVisual case final visual?) {
      if (matchProfileEnabled) {
        final response = (
          widget.selected,
          visual.successTint,
          visual.errorTint,
        );
        if (_lastFlowResponse != null &&
            _lastFlowResponse != response &&
            widget.key is ValueKey<String>) {
          MatchProfileCounters.visualResponse(
            (widget.key as ValueKey<String>).value,
          );
        }
        _lastFlowResponse = response;
      }
      return MatchFlowTile(
        text: widget.text,
        visual: visual,
        selected: widget.selected,
        enabled: widget.enabled,
        onPressed: widget.onPressed,
      );
    }
    final theme = Theme.of(context);
    final atlas = TrainerColors.of(context);
    final minimal = motionOf(context) == 'minimal';
    final successAccent = _accent || widget.retainSuccess;
    _errorAnimation.duration = motionDuration(
      context,
      const Duration(milliseconds: 100),
      calmMs: 70,
    );
    final foreground = widget.completed
        ? (successAccent
              ? atlas.onSuccess
              : theme.colorScheme.onSurface.withValues(alpha: .6))
        : widget.selected
        ? atlas.onSelected
        : theme.colorScheme.onSurface;
    final appearance = _CardAppearance(
      fill: widget.completed
          ? (successAccent ? atlas.success : atlas.card)
          : widget.selected
          ? atlas.selected
          : atlas.card,
      outline: widget.completed && successAccent
          ? (theme.brightness == Brightness.dark
                ? AppColors.success
                : const Color(0xFF328B79))
          : widget.selected
          ? theme.colorScheme.primary
          : atlas.cardOutline.withValues(alpha: .7),
      foreground: foreground,
      width: widget.completed && successAccent
          ? 1.6
          : widget.selected
          ? 1.5
          : AppTokens.cardBorderWidth,
    );
    return LayoutBuilder(
      builder: (context, constraints) {
        final label = Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppTokens.cardHorizontalPadding,
            vertical: AppTokens.cardVerticalPadding,
          ),
          child: Center(
            child: Text(
              widget.text,
              textAlign: TextAlign.center,
              softWrap: true,
              style: trainingWordStyle(
                widget.text,
                constraints.maxWidth - 2 * AppTokens.cardHorizontalPadding,
                MediaQuery.textScalerOf(context),
              ),
            ),
          ),
        );

        return TweenAnimationBuilder<_CardAppearance>(
          tween: _CardAppearanceTween(
            begin: widget.returningFromSuccess
                ? _CardAppearance(
                    fill: atlas.success,
                    outline: theme.brightness == Brightness.dark
                        ? AppColors.success
                        : const Color(0xFF328B79),
                    foreground: foreground,
                    width: 1.6,
                  )
                : appearance,
            end: appearance,
          ),
          duration: motionDuration(context, AppMotion.selection, calmMs: 160),
          curve: AppMotion.curve,
          child: label,
          builder: (context, appearance, label) {
            if (matchProfileEnabled) {
              final key = widget.key;
              if (key is ValueKey<String> &&
                  _lastProfileAppearance != null &&
                  _lastProfileAppearance != appearance) {
                MatchProfileCounters.visualResponse(key.value);
              }
              _lastProfileAppearance = appearance;
            }
            // One local tween keeps fill, border and text in sync. Existing paint
            // boundaries stay in place; untouched cards have no animation ticks.
            final surface = matchPaintBoundary(
              'surface',
              child: Material(
                // The outer appearance tween owns all visible color changes.
                animationDuration: Duration.zero,
                color: appearance.fill,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppTokens.cardRadius),
                  side: BorderSide(
                    color: appearance.outline,
                    width: appearance.width,
                  ),
                ),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (MatchProfileScope.of(context).cardDecoration)
                      Positioned(
                        top: 1,
                        left: 12,
                        right: 12,
                        height: 7,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.white.withValues(
                                  alpha: theme.brightness == Brightness.dark
                                      ? .035
                                      : .08,
                                ),
                                Colors.transparent,
                              ],
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            );
            final glyphs = matchPaintBoundary(
              'glyph',
              child: DefaultTextStyle.merge(
                style: TextStyle(color: appearance.foreground),
                child: label!,
              ),
            );
            return Material(
              type: MaterialType.transparency,
              child: InkWell(
                onTap: widget.completed || !widget.enabled
                    ? null
                    : widget.onPressed,
                onHighlightChanged: (pressed) {
                  if (_pressed != pressed) setState(() => _pressed = pressed);
                },
                enableFeedback: false,
                splashFactory: NoSplash.splashFactory,
                overlayColor: const WidgetStatePropertyAll(Colors.transparent),
                borderRadius: BorderRadius.circular(AppTokens.cardRadius),
                child: AnimatedBuilder(
                  animation: _errorAnimation,
                  child: FadeTransition(
                    opacity: widget.surfaceOpacity,
                    child: surface,
                  ),
                  builder: (context, child) {
                    final phase = _errorAnimation.value;
                    final error =
                        _errorAnimation.isAnimating &&
                        !widget.selected &&
                        !widget.completed;
                    if (matchProfileEnabled &&
                        error &&
                        _lastProfileError != widget.errorRevision) {
                      final key = widget.key;
                      if (key is ValueKey<String>) {
                        MatchProfileCounters.visualResponse(key.value);
                      }
                      _lastProfileError = widget.errorRevision;
                    }
                    final shake = error && !minimal
                        ? math.sin(phase * math.pi * 4) *
                              (1 - phase) *
                              AppTokens.wrongOffset
                        : 0.0;
                    return Semantics(
                      button: true,
                      selected: widget.selected,
                      enabled: !widget.completed && widget.enabled,
                      value: widget.completed
                          ? 'Сопоставлено'
                          : widget.selected
                          ? 'Выбрано'
                          : error
                          ? 'Не совпало'
                          : null,
                      child: Stack(
                        fit: StackFit.expand,
                        clipBehavior: Clip.none,
                        children: [
                          Transform.translate(
                            offset: Offset(shake, 0),
                            child: AnimatedScale(
                              scale:
                                  _pressed &&
                                      !widget.completed &&
                                      !minimal &&
                                      MatchProfileScope.of(context).cardScale
                                  ? AppTokens.pressScale
                                  : 1,
                              duration: motionDuration(
                                context,
                                AppTokens.pressDuration,
                                calmMs: 70,
                              ),
                              curve: AppMotion.curve,
                              child: CustomPaint(
                                foregroundPainter: error
                                    ? _WrongCardTint(
                                        atlas.error,
                                        (1 - phase) *
                                            AppTokens.wrongTintStrength,
                                      )
                                    : null,
                                child: child,
                              ),
                            ),
                          ),
                          FadeTransition(
                            opacity: widget.textOpacity,
                            child: glyphs,
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _CardAppearance {
  const _CardAppearance({
    required this.fill,
    required this.outline,
    required this.foreground,
    required this.width,
  });
  final Color fill, outline, foreground;
  final double width;
  @override
  bool operator ==(Object other) =>
      other is _CardAppearance &&
      fill == other.fill &&
      outline == other.outline &&
      foreground == other.foreground &&
      width == other.width;
  @override
  int get hashCode => Object.hash(fill, outline, foreground, width);
}

class _CardAppearanceTween extends Tween<_CardAppearance> {
  _CardAppearanceTween({required super.begin, required super.end});
  @override
  _CardAppearance lerp(double t) => _CardAppearance(
    fill: Color.lerp(begin!.fill, end!.fill, t)!,
    outline: Color.lerp(begin!.outline, end!.outline, t)!,
    foreground: Color.lerp(begin!.foreground, end!.foreground, t)!,
    width: begin!.width + (end!.width - begin!.width) * t,
  );
}

class _WrongCardTint extends CustomPainter {
  const _WrongCardTint(this.color, this.alpha);
  final Color color;
  final double alpha;
  @override
  void paint(Canvas canvas, Size size) {
    final rect = RRect.fromRectAndRadius(
      Offset.zero & size,
      const Radius.circular(AppTokens.cardRadius),
    );
    canvas.drawRRect(rect, Paint()..color = color.withValues(alpha: alpha));
    canvas.drawRRect(
      rect.deflate(.8),
      Paint()
        ..color = AppColors.error
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6,
    );
  }

  @override
  bool shouldRepaint(_WrongCardTint old) =>
      old.alpha != alpha || old.color != color;
}
