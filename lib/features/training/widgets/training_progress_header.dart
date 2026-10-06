import '../../../app/match_profile_controls.dart';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

import '../../../app/app_theme.dart';
import '../../../app/motion_preferences.dart';
import '../../../app/design_tokens.dart';
import '../model/match_levels.dart';

class TrainingProgressHeader extends StatelessWidget {
  const TrainingProgressHeader({
    super.key,
    required this.progress,
    required this.onSettled,
    required this.onExit,
    this.seconds,
    this.clock,
    this.acceptedProgress,
    this.targetMatches = 60,
    this.progressAnchor,
  });
  final double progress;
  final VoidCallback onSettled;
  final VoidCallback onExit;
  final int? seconds;
  final ValueListenable<int?>? clock;
  final ValueListenable<double>? acceptedProgress;
  final int targetMatches;
  final GlobalKey? progressAnchor;
  @override
  Widget build(BuildContext context) {
    MatchProfileCounters.hit('hud.build');
    final theme = Theme.of(context);
    final exit = DecoratedBox(
      decoration: BoxDecoration(
        gradient: AppSurfaces.card(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppSurfaces.outline(context).withValues(alpha: .35),
        ),
      ),
      child: IconButton(
        onPressed: onExit,
        tooltip: 'Выйти из тренировки',
        icon: const Icon(Icons.close_rounded, size: 22),
      ),
    );
    Widget track(double progress) => TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: progress),
      duration: motionDuration(context, AppTokens.progressDuration),
      curve: Curves.easeOutCubic,
      onEnd: onSettled,
      child: RepaintBoundary(
        child: _MilestoneMarkers(
          completedProgress: progress,
          targetMatches: targetMatches,
        ),
      ),
      builder: (context, value, child) => MilestoneProgress(
        value: value,
        completedProgress: progress,
        targetMatches: targetMatches,
        markers: child,
      ),
    );
    final progressTrack = RepaintBoundary(
      key: progressAnchor,
      child: acceptedProgress == null
          ? track(progress)
          : ValueListenableBuilder<double>(
              valueListenable: acceptedProgress!,
              builder: (_, value, _) => track(value),
            ),
    );
    final timer = RepaintBoundary(
      child: clock == null
          ? _MatchTimer(seconds)
          : ValueListenableBuilder<int?>(
              valueListenable: clock!,
              builder: (_, value, _) => _MatchTimer(value),
            ),
    );
    if (MediaQuery.sizeOf(context).height < 440) {
      return Row(
        children: [
          exit,
          const SizedBox(width: 8),
          Expanded(child: progressTrack),
          if (seconds != null) ...[const SizedBox(width: 12), timer],
        ],
      );
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            exit,
            const SizedBox(width: 12),
            Expanded(child: Text('Матч', style: theme.textTheme.titleLarge)),
            if (seconds != null) timer,
          ],
        ),
        const SizedBox(height: 16),
        progressTrack,
      ],
    );
  }
}

class _MatchTimer extends StatelessWidget {
  const _MatchTimer(this.seconds);
  final int? seconds;
  @override
  Widget build(BuildContext context) {
    MatchProfileCounters.hit('timer.build');
    final theme = Theme.of(context);
    final urgent = seconds != null && seconds! <= AppTokens.timerWarningSeconds;
    final color = urgent
        ? theme.brightness == Brightness.dark
              ? AppTokens.timerWarningDark
              : AppTokens.timerWarningLight
        : theme.colorScheme.onSurface;
    final timer = seconds == null
        ? const SizedBox()
        : Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              gradient: AppSurfaces.card(context),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppSurfaces.outline(context).withValues(alpha: .4),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.timer_outlined, size: 22, color: color),
                const SizedBox(width: 6),
                Semantics(
                  label: 'Осталось времени',
                  child: Text(
                    '${seconds! ~/ 60}:${(seconds! % 60).toString().padLeft(2, '0')}',
                    key: const ValueKey('session-timer'),
                    style: TextStyle(
                      fontSize: AppTokens.timerFontSize,
                      fontWeight: FontWeight.w600,
                      fontFeatures: const [FontFeature.tabularFigures()],
                      color: color,
                    ),
                  ),
                ),
              ],
            ),
          );
    return timer;
  }
}

/// A quiet, custom capsule without Material's default stop marker or ornament.
class CapsuleProgress extends StatelessWidget {
  const CapsuleProgress({super.key, required this.value});
  final double value;
  @override
  Widget build(BuildContext context) => Semantics(
    label: 'Прогресс тренировки',
    value: '${(value * 100).round()}%',
    child: ClipRRect(
      borderRadius: BorderRadius.circular(AppTokens.progressHeight),
      child: SizedBox(
        height: 8,
        child: ColoredBox(
          color: TrainerColors.of(context).cardOutline,
          child: Align(
            alignment: Alignment.centerLeft,
            child: FractionallySizedBox(
              widthFactor: value,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: AppSurfaces.accent(context),
                ),
                child: const SizedBox.expand(),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

/// Markers use the accepted score, while the underlying line animates independently.
class MilestoneProgress extends StatelessWidget {
  const MilestoneProgress({
    super.key,
    required this.value,
    required this.completedProgress,
    required this.targetMatches,
    this.markers,
  });
  final double value;
  final double completedProgress;
  final int targetMatches;
  final Widget? markers;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 54,
    child: LayoutBuilder(
      builder: (context, constraints) {
        final diameter = constraints.maxWidth < 140 ? 24.0 : 30.0;
        return Stack(
          alignment: Alignment.topCenter,
          clipBehavior: Clip.none,
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(diameter / 2, 12, diameter / 2, 0),
              child: CapsuleProgress(value: value),
            ),
            Positioned.fill(
              child:
                  markers ??
                  _MilestoneMarkers(
                    completedProgress: completedProgress,
                    targetMatches: targetMatches,
                  ),
            ),
          ],
        );
      },
    ),
  );
}

class _MilestoneMarkers extends StatefulWidget {
  const _MilestoneMarkers({
    required this.completedProgress,
    required this.targetMatches,
  });
  final double completedProgress;
  final int targetMatches;
  @override
  State<_MilestoneMarkers> createState() => _MilestoneMarkersState();
}

class _MilestoneMarkersState extends State<_MilestoneMarkers> {
  final _markers = <int, (bool, double, Widget)>{};
  Widget _marker(int milestone, double diameter) {
    final complete =
        widget.completedProgress >= milestone / widget.targetMatches;
    final old = _markers[milestone];
    if (old != null && old.$1 == complete && old.$2 == diameter) return old.$3;
    final result = RepaintBoundary(
      child: MilestoneMarker(
        key: ValueKey('milestone-$milestone'),
        milestone: milestone,
        completed: complete,
        diameter: diameter,
      ),
    );
    _markers[milestone] = (complete, diameter, result);
    return result;
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final diameter = constraints.maxWidth < 140 ? 24.0 : 30.0;
      final width = (constraints.maxWidth - diameter).clamp(
        0.0,
        double.infinity,
      );
      return Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          for (final milestone in matchMilestones.where(
            (m) => m <= widget.targetMatches,
          ))
            Positioned(
              left: width * milestone / widget.targetMatches,
              top: 0,
              child: _marker(milestone, diameter),
            ),
        ],
      );
    },
  );
}

class MilestoneMarker extends StatelessWidget {
  const MilestoneMarker({
    super.key,
    required this.milestone,
    required this.completed,
    required this.diameter,
  });
  final int milestone;
  final bool completed;
  final double diameter;

  @override
  Widget build(BuildContext context) {
    MatchProfileCounters.hit('milestone.$milestone.build');
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      label: 'Отметка $milestone',
      value: completed ? 'Достигнута' : 'Впереди',
      child: AnimatedScale(
        scale: completed ? 1 : .94,
        duration: motionDuration(context, const Duration(milliseconds: 300)),
        curve: Curves.easeOutCubic,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TweenAnimationBuilder<double>(
              key: ValueKey('glow-$milestone-$completed'),
              tween: Tween(
                begin: completed && motionOf(context) != 'minimal' ? 1 : 0,
                end: 0,
              ),
              duration: motionDuration(
                context,
                const Duration(milliseconds: 260),
                calmMs: 180,
              ),
              builder: (context, v, child) => CustomPaint(
                painter: _MarkerHalo(scheme.primary, v),
                child: child,
              ),
              child: AnimatedContainer(
                duration: motionDuration(
                  context,
                  const Duration(milliseconds: 180),
                ),
                width: diameter,
                height: diameter,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: completed ? AppSurfaces.accent(context) : null,
                  color: completed ? null : scheme.surface,
                  border: Border.all(
                    color: completed ? scheme.primary : scheme.outlineVariant,
                    width: 1.4,
                  ),
                ),
                child: ExcludeSemantics(
                  child: Icon(
                    Icons.auto_awesome_outlined,
                    size: diameter * .52,
                    color: completed
                        ? scheme.onPrimary
                        : scheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 5),
            ExcludeSemantics(
              child: Text(
                '$milestone',
                textScaler: TextScaler.noScaling,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: scheme.onSurface,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MarkerHalo extends CustomPainter {
  const _MarkerHalo(this.color, this.value);
  final Color color;
  final double value;
  @override
  void paint(Canvas canvas, Size size) {
    if (value <= 0) return;
    canvas.drawCircle(
      size.center(Offset.zero),
      size.shortestSide / 2 + 3 * value,
      Paint()
        ..color = color.withValues(alpha: .25 * value)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3 * value,
    );
  }

  @override
  bool shouldRepaint(_MarkerHalo old) =>
      old.value != value || old.color != color;
}
