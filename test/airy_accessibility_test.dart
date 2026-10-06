import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:word_journey/app/app_theme.dart';
import 'package:word_journey/features/profile/cefr_profile.dart';
import 'package:word_journey/features/progress/trainer_data.dart';
import 'package:word_journey/features/progress/trainer_store.dart';
import 'package:word_journey/features/topics/categories_screen.dart';
import 'package:word_journey/features/training/screens/training_setup_screen.dart';
import 'package:word_journey/features/review/review_screen.dart';
import 'package:word_journey/features/progress/progress_screen.dart';
import 'package:word_journey/features/settings/settings_screen.dart';
import 'package:word_journey/features/vocabulary/vocabulary_repository.dart';

void main() {
  for (final dark in [false, true]) {
    testWidgets('Visible Airy controls meet Android 48dp targets, dark=$dark', (
      t,
    ) async {
      t.view.devicePixelRatio = 1;
      t.view.physicalSize = const Size(393, 850);
      addTearDown(t.view.reset);
      final semantics = t.ensureSemantics();
      final data = TrainerData(store: MemoryTrainerStore());
      await data.load();
      final profile = CefrProfile(TrainerLevelStore(data));
      await profile.load();
      final r = await VocabularyRepository.load();
      for (final page in [
        const Scaffold(body: CategoriesScreen()),
        CategoryScreen(repository: r, category: r.categories.first),
        TrainingSetupScreen(pack: r.packs.first, words: r.words(r.packs.first)),
        const Scaffold(body: ReviewScreen()),
        const Scaffold(body: ProgressScreen()),
        const SettingsScreen(),
      ]) {
        await t.pumpWidget(
          TrainerScope(
            data: data,
            child: ProfileScope(
              profile: profile,
              child: MaterialApp(
                theme: dark ? AppTheme.dark : AppTheme.light,
                home: page,
              ),
            ),
          ),
        );
        await t.pumpAndSettle();
        await expectLater(t, meetsGuideline(androidTapTargetGuideline));
      }
      await t.pumpWidget(const SizedBox());
      semantics.dispose();
      profile.dispose();
      data.dispose();
    });
  }
}
