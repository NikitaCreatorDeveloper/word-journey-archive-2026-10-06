import 'package:flutter/material.dart';

import '../model/session_result.dart';

class TrainingResultScreen extends StatelessWidget {
  const TrainingResultScreen({
    super.key,
    required this.result,
    required this.onPlayAgain,
    required this.onBackToSetup,
  });

  final SessionResult result;
  final VoidCallback onPlayAgain;
  final VoidCallback onBackToSetup;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final seconds = result.elapsedTime.inSeconds;
    final time =
        '${seconds ~/ 60}:${(seconds % 60).toString().padLeft(2, '0')}';
    return Scaffold(
      appBar: AppBar(title: const Text('Результат')),
      body: SafeArea(
        top: false,
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    switch (result.endReason) {
                      SessionEndReason.targetReached => 'Уровень пройден',
                      SessionEndReason.timeExpired => 'Время вышло',
                      SessionEndReason.userExited => 'Тренировка завершена',
                    },
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    '${result.completedMatches} / ${result.targetMatches}',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.displaySmall?.copyWith(
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                  const SizedBox(height: 24),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainer,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          if (result.targetReached) ...[
                            Text(
                              'Время: $time',
                              style: theme.textTheme.titleMedium,
                            ),
                            const SizedBox(height: 8),
                          ],
                          Text(
                            'Ошибки: ${result.wrongAttempts}',
                            style: theme.textTheme.titleMedium,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  FilledButton(
                    onPressed: onPlayAgain,
                    child: const Text('Ещё раз'),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton(
                    onPressed: onBackToSetup,
                    child: const Text('К настройке'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
