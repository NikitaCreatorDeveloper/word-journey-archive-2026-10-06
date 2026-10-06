import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../app/design_tokens.dart';
import '../../../app/match_profile_controls.dart';
import '../../../app/motion_preferences.dart';
import 'lightning_feedback.dart';
import 'match_feedback_assets.dart';
import 'match_feedback_controller.dart';
import 'safe_match_lottie.dart';

export 'match_feedback_controller.dart';

bool matchLottieEnabled(BuildContext context) =>
    !const bool.fromEnvironment('MATCH_LEGACY_FEEDBACK') &&
    MatchProfileScope.of(context).lottie;

/// The child (playing field/HUD) never rebuilds from decorative animation ticks.
/// A local HUD pulse reads its real progress-track bounds only on a milestone.
class MatchFeedbackOverlay extends StatefulWidget {
  const MatchFeedbackOverlay({
    super.key,
    required this.controller,
    required this.progressAnchor,
    required this.targetMatches,
    required this.child,
  });
  final MatchFeedbackController controller;
  final GlobalKey progressAnchor;
  final int targetMatches;
  final Widget child;
  @override
  State<MatchFeedbackOverlay> createState() => _MatchFeedbackOverlayState();
}

class _MatchFeedbackOverlayState extends State<MatchFeedbackOverlay> {
  final _space = GlobalKey();
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (matchLottieEnabled(context) && motionOf(context) != 'minimal') {
      unawaited(widget.controller.prepare());
    }
  }

  @override
  Widget build(BuildContext context) {
    if (motionOf(context) == 'minimal') {
      return ValueListenableBuilder<MatchFeedbackEvent?>(
        valueListenable: widget.controller.milestone,
        child: widget.child,
        builder: (_, event, child) {
          if (event != null) {
            WidgetsBinding.instance.addPostFrameCallback(
              (_) => widget.controller.finishMilestone(event.token),
            );
          }
          return child!;
        },
      );
    }
    if (!matchLottieEnabled(context)) return widget.child;
    return RepaintBoundary(
      child: Stack(
        key: _space,
        fit: StackFit.expand,
        clipBehavior: Clip.none,
        children: [
          widget.child,
          ValueListenableBuilder<MatchFeedbackEvent?>(
            valueListenable: widget.controller.milestone,
            builder: (context, event, _) {
              if (event == null) {
                return const SizedBox.shrink();
              }
              if (motionOf(context) == 'minimal') {
                WidgetsBinding.instance.addPostFrameCallback(
                  (_) => widget.controller.finishMilestone(event.token),
                );
                return const SizedBox.shrink();
              }
              final anchor = widget.progressAnchor.currentContext
                  ?.findRenderObject();
              final space = _space.currentContext?.findRenderObject();
              if (anchor is! RenderBox ||
                  space is! RenderBox ||
                  !anchor.hasSize ||
                  !space.hasSize) {
                return const SizedBox.shrink();
              }
              final origin = space.globalToLocal(
                anchor.localToGlobal(Offset.zero),
              );
              final diameter = anchor.size.width < 140 ? 24.0 : 30.0;
              final x =
                  origin.dx +
                  (anchor.size.width - diameter) *
                      event.count /
                      widget.targetMatches +
                  diameter / 2;
              return Positioned(
                left: x - 28,
                top: origin.dy + diameter / 2 - 28,
                child: IgnorePointer(
                  child: ExcludeSemantics(
                    child: SizedBox(
                      width: 56,
                      height: 56,
                      child: _DecorationPlayback(
                        key: ValueKey(event.token),
                        event: event,
                        assets: widget.controller.assets,
                        onComplete: () =>
                            widget.controller.finishMilestone(event.token),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

/// A permanently reserved reward dock; decoration never overlays card labels.
class MatchFeedbackReward extends StatelessWidget {
  const MatchFeedbackReward({
    super.key,
    required this.controller,
    this.onComboPeak,
    this.compact = false,
  });
  final MatchFeedbackController controller;
  final ValueChanged<int>? onComboPeak;
  final bool compact;
  int get combo => controller.reward.value?.kind == MatchDecoration.correct
      ? 1
      : controller.reward.value?.count ?? 0;
  @override
  Widget build(BuildContext context) {
    final base = DefaultTextStyle.of(context).style;
    final scaler = MediaQuery.textScalerOf(context);
    final graphic = compact ? 36.0 : 64.0;
    final textWidth = 226 - graphic - 8;
    double height(String text, double font, double width) {
      final p = TextPainter(
        text: TextSpan(
          text: text,
          style: base.merge(
            TextStyle(
              fontSize: font,
              height: 1.15,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        textDirection: TextDirection.ltr,
        textScaler: scaler,
      )..layout(maxWidth: width);
      final value = p.height;
      p.dispose();
      return value;
    }

    final reserved = math.max(
      compact ? 56.0 : 78.0,
      height('Отлично!', compact ? 15 : 19, textWidth) +
          height('Комбо x60', compact ? 12 : 14, textWidth - 20) +
          13,
    );
    return SizedBox(
      width: 226,
      height: reserved,
      child: RepaintBoundary(
        child: IgnorePointer(
          child: ExcludeSemantics(
            child: ValueListenableBuilder<MatchFeedbackEvent?>(
              valueListenable: controller.reward,
              builder: (context, event, _) =>
                  motionOf(context) == 'minimal' &&
                      event?.kind != MatchDecoration.victory
                  ? LightningFeedback(
                      revision: event == null
                          ? 0
                          : (event.rewardRevision > 0
                                ? event.rewardRevision
                                : event.token),
                      combo: event == null
                          ? 0
                          : event.kind == MatchDecoration.correct
                          ? 1
                          : event.count,
                      compact: compact,
                      onPeak: onComboPeak,
                      onFinished: event == null
                          ? null
                          : () => controller.finishReward(event.token),
                    )
                  : event == null
                  ? const SizedBox.shrink()
                  : _DecorationPlayback(
                      key: ValueKey(event.token),
                      event: event,
                      assets: controller.assets,
                      onComplete: () => controller.finishReward(event.token),
                      onPeak: onComboPeak,
                      compact: compact,
                      dock: true,
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Continue just the remaining victory decoration across the unchanged route
/// transition. This seed is independent of the disposed game controller.
class MatchVictoryFeedback extends StatefulWidget {
  const MatchVictoryFeedback({super.key, required this.event, this.assets});
  final MatchFeedbackEvent event;
  final MatchFeedbackAssets? assets;
  @override
  State<MatchVictoryFeedback> createState() => _MatchVictoryFeedbackState();
}

class _MatchVictoryFeedbackState extends State<MatchVictoryFeedback> {
  bool _done = false;
  @override
  Widget build(BuildContext context) => _done
      ? const SizedBox.shrink()
      : IgnorePointer(
          child: ExcludeSemantics(
            child: _DecorationPlayback(
              event: widget.event,
              assets: widget.assets ?? MatchFeedbackAssets.shared,
              onComplete: () {
                if (mounted) setState(() => _done = true);
              },
            ),
          ),
        );
}

class _DecorationPlayback extends StatefulWidget {
  const _DecorationPlayback({
    super.key,
    required this.event,
    required this.assets,
    required this.onComplete,
    this.onPeak,
    this.compact = false,
    this.dock = false,
  });
  final MatchFeedbackEvent event;
  final MatchFeedbackAssets assets;
  final VoidCallback onComplete;
  final ValueChanged<int>? onPeak;
  final bool compact, dock;
  @override
  State<_DecorationPlayback> createState() => _DecorationPlaybackState();
}

class _DecorationPlaybackState extends State<_DecorationPlayback>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  AnimationController? _animation;
  bool _foreground = true,
      _enabled = true,
      _useLottie = false,
      _failed = false,
      _sent = false,
      _ending = false;
  String? _mode;
  void _tick() {
    final a = _animation;
    if (a == null) return;
    widget.event.recordElapsed(a.duration! * a.value);
    if (!_sent &&
        widget.event.kind == MatchDecoration.combo &&
        widget.event.elapsed >= const Duration(milliseconds: 100)) {
      _sent = true;
      widget.onPeak?.call(widget.event.rewardRevision);
    }
  }

  void _complete() {
    if (_ending) return;
    _ending = true;
    final token = widget.event.token;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted &&
          widget.event.token == token &&
          _animation?.isCompleted == true) {
        widget.onComplete();
      }
    });
  }

  @override
  void initState() {
    super.initState();
    if (widget.event.kind != MatchDecoration.milestone) {
      MatchProfileCounters.feedback(
        widget.event.kind.name,
        math.max(
          0,
          (widget.assets
                      .composition(widget.event.kind)
                      ?.duration
                      .inMilliseconds ??
                  650) -
              widget.event.elapsed.inMilliseconds,
        ),
      );
    }
    WidgetsBinding.instance.addObserver(this);
    _foreground =
        WidgetsBinding.instance.lifecycleState == null ||
        WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final mode = motionOf(context);
    _enabled = TickerMode.valuesOf(context).enabled;
    if (_mode != mode) {
      _mode = mode;
      _useLottie =
          mode != 'minimal' &&
          !_failed &&
          widget.assets.composition(widget.event.kind) != null;
      final duration = _useLottie
          ? widget.assets.composition(widget.event.kind)!.duration
          : Duration(
              milliseconds: mode == 'minimal'
                  ? 180
                  : mode == 'calm'
                  ? 540
                  : 650,
            );
      if (_animation == null) {
        final start =
            (widget.event.elapsed.inMicroseconds / duration.inMicroseconds)
                .clamp(0.0, 1.0);
        _animation =
            AnimationController(vsync: this, duration: duration, value: start)
              ..addListener(_tick)
              ..addStatusListener((s) {
                if (s == AnimationStatus.completed) {
                  widget.event.complete();
                  _complete();
                }
              });
      } else {
        _animation!.duration = duration;
      }
    }
    _syncActivity();
  }

  void _syncActivity() {
    final a = _animation;
    if (a == null) return;
    if (!_enabled || !_foreground) {
      a.stop(canceled: false);
    } else if (a.isCompleted) {
      _complete();
    } else if (!a.isAnimating) {
      a.forward();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    _syncActivity();
  }

  void _fallback() {
    if (!mounted || _failed) return;
    setState(() {
      _failed = true;
      _useLottie = false;
      _animation!.duration = Duration(
        milliseconds: _mode == 'minimal'
            ? 180
            : _mode == 'calm'
            ? 540
            : 650,
      );
      _animation!.forward(from: 0);
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _animation?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    MatchProfileCounters.hit('feedback.build');
    final event = widget.event, a = _animation!;
    if (!_useLottie &&
        [MatchDecoration.correct, MatchDecoration.combo].contains(event.kind)) {
      return LightningFeedback(
        revision: event.rewardRevision > 0 ? event.rewardRevision : event.token,
        combo: event.kind == MatchDecoration.correct ? 1 : event.count,
        compact: widget.compact,
        onPeak: (revision) {
          if (!_sent) {
            _sent = true;
            widget.onPeak?.call(revision);
          }
        },
      );
    }
    final graphic = RepaintBoundary(
      child: _useLottie
          ? SafeMatchLottie(
              composition: widget.assets.composition(event.kind)!,
              animation: a,
              onFailure: _fallback,
              calm: _mode == 'calm',
            )
          : FadeTransition(
              opacity: a.drive(const _FeedbackEnvelope()),
              child: Icon(
                event.kind == MatchDecoration.milestone
                    ? Icons.auto_awesome_outlined
                    : Icons.check_circle_outline_rounded,
                color: AppColors.accentPrimary,
                size: 32,
              ),
            ),
    );
    if (!widget.dock) return graphic;
    final gold = AppSurfaces.dark(context)
        ? AppColors.warning
        : const Color(0xFF85541C);
    final caption = event.kind == MatchDecoration.combo
        ? Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Отлично!',
                style: TextStyle(
                  fontSize: widget.compact ? 15 : 19,
                  height: 1.15,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 5),
              DecoratedBox(
                decoration: BoxDecoration(
                  color: gold.withValues(alpha: .10),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: gold.withValues(alpha: .7),
                    width: .8,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  child: Text(
                    'Комбо x${event.count}',
                    style: TextStyle(
                      fontSize: widget.compact ? 12 : 14,
                      height: 1.15,
                      fontWeight: FontWeight.w600,
                      color: gold,
                    ),
                  ),
                ),
              ),
            ],
          )
        : Text(
            event.kind == MatchDecoration.victory
                ? '${event.count} / ${event.count}'
                : 'Верно',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          );
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: widget.compact ? 36 : 64,
          height: widget.compact ? 46 : 72,
          child: graphic,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: FadeTransition(
            opacity: a.drive(const _FeedbackEnvelope()),
            child: RepaintBoundary(child: caption),
          ),
        ),
      ],
    );
  }
}

class _FeedbackEnvelope extends Animatable<double> {
  const _FeedbackEnvelope();
  @override
  double transform(double value) => value < .15
      ? AppMotion.curve.transform((value / .15).clamp(0.0, 1.0))
      : value > .64
      ? 1 - AppMotion.curve.transform(((value - .64) / .36).clamp(0.0, 1.0))
      : 1.0;
}
