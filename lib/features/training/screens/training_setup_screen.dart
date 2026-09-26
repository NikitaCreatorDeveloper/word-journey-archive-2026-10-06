import 'package:flutter/material.dart';

import '../logic/matching_engine.dart';
import '../model/test_words.dart';
import '../model/session_config.dart';
import 'training_game_screen.dart';

class TrainingSetupScreen extends StatefulWidget {
  const TrainingSetupScreen({super.key});

  @override
  State<TrainingSetupScreen> createState() => _TrainingSetupScreenState();
}

class _TrainingSetupScreenState extends State<TrainingSetupScreen> {
  int _pairCount = 4;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Настройка тренировки')),
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
                    'Количество пар на поле',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 24),
                  SegmentedButton<int>(
                    segments: const [
                      ButtonSegment(value: 4, label: Text('4')),
                      ButtonSegment(value: 5, label: Text('5')),
                    ],
                    selected: {_pairCount},
                    showSelectedIcon: false,
                    onSelectionChanged: (values) {
                      setState(() => _pairCount = values.single);
                    },
                  ),
                  const SizedBox(height: 32),
                  FilledButton(
                    onPressed: () {
                      final game = MatchingEngine.start(
                        words: testWords,
                        config: SessionConfig(
                          visiblePairs: _pairCount,
                          wordPoolSize: 20,
                          targetMatches: 60,
                          maxMistakes: 5,
                          mode: SessionMode.timed,
                          timeLimitSeconds: 120,
                        ),
                      );
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => TrainingGameScreen(game: game),
                        ),
                      );
                    },
                    child: const Text('Начать'),
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
