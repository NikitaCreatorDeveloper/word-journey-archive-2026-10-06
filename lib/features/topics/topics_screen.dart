import 'package:flutter/material.dart';

import '../training/screens/training_setup_screen.dart';

class TopicsScreen extends StatelessWidget {
  const TopicsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: FilledButton(
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const TrainingSetupScreen(),
              ),
            );
          },
          child: const Text('Тестовая тренировка'),
        ),
      ),
    );
  }
}
