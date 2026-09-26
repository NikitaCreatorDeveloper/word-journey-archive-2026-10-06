import 'package:flutter/material.dart';

class TrainingResultScreen extends StatelessWidget {
  const TrainingResultScreen({
    super.key,
    required this.pairCount,
    required this.errorCount,
    required this.onPlayAgain,
    required this.onBackToSetup,
    this.timedOut = false,
  });

  final bool timedOut;
  final int pairCount;
  final int errorCount;
  final VoidCallback onPlayAgain;
  final VoidCallback onBackToSetup;

  @override
  Widget build(BuildContext context) {
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
                    timedOut ? 'Время вышло' : 'Тренировка завершена',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Количество пар: $pairCount',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Количество ошибок: $errorCount',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  FilledButton(
                    onPressed: onPlayAgain,
                    child: const Text('Ещё раз'),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton(
                    onPressed: onBackToSetup,
                    child: const Text('Назад к настройке'),
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
