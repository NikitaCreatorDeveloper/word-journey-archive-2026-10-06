import 'package:flutter/material.dart';

import '../../../app/app_theme.dart';
import '../model/match_levels.dart';

class TrainingProgressHeader extends StatelessWidget {
  const TrainingProgressHeader({
    super.key,
    required this.progress,
    required this.onSettled,
    required this.onExit,
    this.seconds,
    this.targetMatches = 60,
  });
  final double progress;
  final VoidCallback onSettled;
  final VoidCallback onExit;
  final int? seconds;
  final int targetMatches;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final urgent = seconds != null && seconds! <= AppTokens.timerWarningSeconds;
    final color = urgent
        ? theme.brightness == Brightness.dark
              ? AppTokens.timerWarningDark
              : AppTokens.timerWarningLight
        : theme.colorScheme.onSurface;
    final exit = IconButton(
      onPressed: onExit,
      tooltip: 'Выйти из тренировки',
      icon: const Icon(Icons.close_rounded, size: AppTokens.hudIconSize),
    );
    final progressTrack = TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: progress),
      duration: AppTokens.progressDuration,
      curve: Curves.easeOutCubic,
      onEnd: onSettled,
      builder: (context, value, child) => MilestoneProgress(
        value: value,
        completedProgress: progress,
        targetMatches: targetMatches,
      ),
    );
    final timer = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (seconds case final value?) ...[
          Icon(
            Icons.schedule_rounded,
            size: AppTokens.hudIconSize,
            color: color,
          ),
          const SizedBox(width: AppTokens.spaceXs),
          Semantics(
            label: 'Осталось времени',
            child: Text(
              '${value ~/ 60}:${(value % 60).toString().padLeft(2, '0')}',
              key: const ValueKey('session-timer'),
              style: TextStyle(
                fontSize: AppTokens.timerFontSize,
                fontWeight: urgent ? FontWeight.w600 : FontWeight.w500,
                fontFeatures: const [FontFeature.tabularFigures()],
                color: color,
              ),
            ),
          ),
        ],
      ],
    );
    return LayoutBuilder(
      builder: (context, constraints) {
        final largeText =
            MediaQuery.textScalerOf(context).scale(AppTokens.timerFontSize) >
            24;
        if (constraints.maxWidth < 300 ||
            (largeText && constraints.maxWidth < 440)) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(children: [exit, const Spacer(), timer]),
              progressTrack,
            ],
          );
        }
        return Row(
          children: [
            exit,
            const SizedBox(width: AppTokens.spaceSm),
            Expanded(child: progressTrack),
            if (seconds != null) ...[
              const SizedBox(width: AppTokens.spaceLg),
              timer,
            ],
          ],
        );
      },
    );
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
        height: AppTokens.progressHeight,
        child: ColoredBox(
          color: AtlasColors.of(context).cardOutline,
          child: Align(
            alignment: Alignment.centerLeft,
            child: FractionallySizedBox(
              widthFactor: value,
              child: ColoredBox(
                color: Theme.of(context).colorScheme.primary,
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
  });
  final double value;
  final double completedProgress;
  final int targetMatches;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 32,
    child: LayoutBuilder(
      builder: (context, constraints) {
        final diameter = constraints.maxWidth < 140 ? 18.0 : 24.0;
        final width = (constraints.maxWidth - diameter).clamp(
          0.0,
          double.infinity,
        );
        return Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            Padding(
              padding: EdgeInsets.symmetric(horizontal: diameter / 2),
              child: CapsuleProgress(value: value),
            ),
            for (final milestone in matchMilestones.where(
              (m) => m <= targetMatches,
            ))
              Positioned(
                left: width * milestone / targetMatches,
                child: MilestoneMarker(
                  key: ValueKey('milestone-$milestone'),
                  milestone: milestone,
                  completed: completedProgress >= milestone / targetMatches,
                  diameter: diameter,
                ),
              ),
          ],
        );
      },
    ),
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
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      label: 'Отметка $milestone',
      value: completed ? 'Достигнута' : 'Впереди',
      child: AnimatedScale(
        scale: completed ? 1 : .94,
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: diameter,
          height: diameter,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: completed ? scheme.primary : scheme.surface,
            border: Border.all(
              color: completed ? scheme.primary : scheme.outlineVariant,
            ),
          ),
          child: ExcludeSemantics(
            child: Text(
              '$milestone',
              textScaler: TextScaler.noScaling,
              style: TextStyle(
                fontSize: diameter < 24 ? 9 : 10,
                fontWeight: FontWeight.w600,
                color: completed ? scheme.onPrimary : scheme.onSurfaceVariant,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
