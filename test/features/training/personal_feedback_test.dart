import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:word_journey/app/app_theme.dart';
import 'package:word_journey/features/settings/audio_feedback_service.dart';
import 'package:word_journey/features/settings/trainer_settings.dart';
import 'package:word_journey/features/progress/trainer_data.dart';
import 'package:word_journey/features/progress/trainer_store.dart';
import 'package:word_journey/features/review/recall_screen.dart';
import 'package:word_journey/features/review/adaptive_word_scheduler.dart';
import 'package:word_journey/features/vocabulary/vocabulary_repository.dart';
import 'package:word_journey/features/training/logic/matching_engine.dart';
import 'package:word_journey/features/training/model/session_config.dart';
import 'package:word_journey/features/training/screens/training_game_screen.dart';
import 'package:word_journey/features/training/screens/training_setup_screen.dart';
import 'package:word_journey/features/training/widgets/training_word_card.dart';

void main() {
  testWidgets(
    'Excluding a word refreshes a cached collection before the next Match',
    (tester) async {
      final d = TrainerData(store: MemoryTrainerStore());
      await d.load();
      final words = (await VocabularyRepository.load()).concepts
          .take(4)
          .toList();
      await tester.pumpWidget(
        TrainerScope(
          data: d,
          child: MaterialApp(
            theme: AppTheme.light,
            home: TrainingSetupScreen(
              words: words,
              collectionTitle: 'Проверка',
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<FilledButton>(
              find.widgetWithText(FilledButton, 'Начать тренировку'),
            )
            .onPressed,
        isNotNull,
      );
      await d.setFlag(words.first.id, excluded: true);
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<FilledButton>(
              find.widgetWithText(FilledButton, 'Начать тренировку'),
            )
            .onPressed,
        isNull,
      );
      await tester.pumpWidget(const SizedBox());
      d.dispose();
    },
  );
  test('Muted/zero volume is silent; repeated feedback bounded; missing engine harmless', () async {
    final calls = <String>[];
    final audio = AudioFeedbackService(
      invoke: (m, a) async {
        calls.add(m);
      },
    );
    final s = TrainerSettings().withValue('haptics', false);
    audio.feedback('correct', s.withValue('sounds', false));
    audio.feedback('wrong', s.withValue('volume', 0.0));
    expect(calls, isEmpty);
    audio.preload();
    audio.preload();
    audio.feedback('correct', s);
    audio.feedback('correct', s);
    expect(calls, ['preloadSounds', 'playSound']);
    AudioFeedbackService(
      invoke: (m, a) async {
        throw StateError('absent');
      },
    ).feedback('wrong', s);
    await Future<void>.delayed(Duration.zero);
  });
  testWidgets(
    'Recall conceals English until answer and accepts keyboard submit only once',
    (tester) async {
      final d = TrainerData(store: MemoryTrainerStore());
      await d.load();
      final word = (await VocabularyRepository.load()).concepts.first;
      await tester.pumpWidget(
        TrainerScope(
          data: d,
          child: MaterialApp(
            theme: AppTheme.light,
            home: RecallScreen(words: [word]),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text(word.english), findsNothing);
      await tester.enterText(
        find.byKey(const ValueKey('recall-input')),
        word.acceptedVariants.first,
      );
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();
      expect(find.text(word.english), findsOneWidget);
      expect(d.progress[word.id]!.recallCorrect, 1);
      await tester.tap(find.text('Завершить'));
      await tester.pumpAndSettle();
      expect(d.sessions.single['mode'], 'recall');
      expect(d.sessions.single['completed'], true);
      await tester.pumpWidget(const SizedBox());
      d.dispose();
    },
  );
  testWidgets(
    'Long C1 labels at 2x text in dark minimal motion stay readable with common height',
    (tester) async {
      tester.view.physicalSize = const Size(360, 720);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final r = await VocabularyRepository.load();
      final words = AdaptiveWordScheduler().compatible(
        r.concepts.where((c) => c.cefrLevel?.id == 'c1').toList(),
      );
      final d = TrainerData(store: MemoryTrainerStore());
      await d.load();
      await d.saveSettings(d.settings.withValue('motion', 'minimal'));
      final g = MatchingEngine.start(
        words: words.map((c) => c.toWordPair()).toList(),
        random: Random(6),
        config: SessionConfig(
          visiblePairs: 5,
          wordPoolSize: 20,
          targetMatches: 60,
          maxMistakes: 0,
          mode: SessionMode.practice,
        ),
      );
      await tester.pumpWidget(
        TrainerScope(
          data: d,
          child: MaterialApp(
            theme: AppTheme.dark,
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context)
                  .copyWith(textScaler: const TextScaler.linear(2)),
              child: child!,
            ),
            home: TrainingGameScreen(game: g),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final cards = find.byType(TrainingWordCard);
      expect(cards, findsNWidgets(10));
      final heights = [
        for (var i = 0; i < 10; i++) tester.getSize(cards.at(i)).height,
      ];
      expect(heights.toSet(), hasLength(1));
      expect(find.byType(FittedBox), findsNothing);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      await d.flush();
      d.dispose();
    },
  );
}
