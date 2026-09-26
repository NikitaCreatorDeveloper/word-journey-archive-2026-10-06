import 'package:flutter/material.dart';

import '../../../app/app_theme.dart';

class TrainingProgressHeader extends StatelessWidget {
  const TrainingProgressHeader({
    super.key,
    required this.progress,
    required this.onSettled,
    required this.onExit,
    this.seconds,
  });
  final double progress;
  final VoidCallback onSettled;
  final VoidCallback onExit;
  final int? seconds;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final urgent = seconds != null && seconds! <= AppTokens.timerWarningSeconds;
    final color = urgent
        ? theme.brightness == Brightness.dark
              ? AppTokens.timerWarningDark
              : AppTokens.timerWarningLight
        : theme.colorScheme.onSurface;
    return Row(
      children: [
        IconButton(
          onPressed: onExit,
          tooltip: 'Выйти из тренировки',
          icon: const Icon(Icons.close_rounded, size: AppTokens.hudIconSize),
        ),
        const SizedBox(width: AppTokens.spaceSm),
        Expanded(
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: progress),
            duration: AppTokens.progressDuration,
            curve: Curves.easeOutCubic,
            onEnd: onSettled,
            builder: (context, value, child) => CapsuleProgress(value: value),
          ),
        ),
        if (seconds case final value?) ...[
          const SizedBox(width: AppTokens.spaceLg),
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
