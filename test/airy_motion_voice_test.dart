import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:word_journey/app/app_theme.dart';
import 'package:word_journey/features/progress/trainer_data.dart';
import 'package:word_journey/features/progress/trainer_store.dart';
import 'package:word_journey/features/settings/settings_screen.dart';
import 'package:word_journey/features/training/screens/training_setup_screen.dart';
import 'package:word_journey/features/training/widgets/training_progress_header.dart';
import 'package:word_journey/features/vocabulary/vocabulary_repository.dart';

void main() {
  testWidgets('System reduced motion also stops milestone marker animation', (
    t,
  ) async {
    await t.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(disableAnimations: true),
          child: child!,
        ),
        home: const Scaffold(
          body: MilestoneMarker(milestone: 20, completed: true, diameter: 24),
        ),
      ),
    );
    expect(
      t.widget<AnimatedScale>(find.byType(AnimatedScale)).duration,
      const Duration(milliseconds: 1),
    );
    expect(
      t.widget<AnimatedContainer>(find.byType(AnimatedContainer)).duration,
      const Duration(milliseconds: 1),
    );
    await t.pumpAndSettle();
    expect(t.binding.transientCallbackCount, 0);
  });
  testWidgets(
    'Overview reports unavailable offline voice on a false platform response',
    (t) async {
      final data = TrainerData(store: MemoryTrainerStore());
      await data.load();
      t.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        personalPlatform,
        (call) async => false,
      );
      addTearDown(
        () => t.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          personalPlatform,
          null,
        ),
      );
      final r = await VocabularyRepository.load(), pack = r.packs.first;
      await t.pumpWidget(
        TrainerScope(
          data: data,
          child: MaterialApp(
            theme: AppTheme.light,
            home: TrainingSetupScreen(pack: pack, words: r.words(pack)),
          ),
        ),
      );
      await t.pumpAndSettle();
      await t.ensureVisible(
        find.text('Посмотреть все слова · ${pack.conceptIds.length}'),
      );
      await t.pumpAndSettle();
      await t.tap(
        find.text('Посмотреть все слова · ${pack.conceptIds.length}'),
      );
      await t.pumpAndSettle();
      await t.scrollUntilVisible(find.text(r.words(pack).first.english), 200);
      await t.pumpAndSettle();
      await t.ensureVisible(find.byTooltip('Произнести офлайн').first);
      await t.pumpAndSettle();
      await t.tap(find.byTooltip('Произнести офлайн').first);
      await t.pumpAndSettle();
      expect(find.text('Офлайн-голос недоступен.'), findsOneWidget);
      await t.pumpWidget(const SizedBox());
      await data.flush();
      data.dispose();
    },
  );
}
