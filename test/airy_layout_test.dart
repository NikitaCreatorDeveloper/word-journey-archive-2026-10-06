import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:word_journey/app/app_theme.dart';
import 'package:word_journey/features/profile/cefr_profile.dart';
import 'package:word_journey/features/progress/trainer_data.dart';
import 'package:word_journey/features/progress/trainer_store.dart';
import 'package:word_journey/features/topics/categories_screen.dart';
import 'package:word_journey/features/training/screens/training_setup_screen.dart';
import 'package:word_journey/features/settings/settings_screen.dart';
import 'package:word_journey/features/review/review_screen.dart';
import 'package:word_journey/features/progress/progress_screen.dart';
import 'package:word_journey/features/vocabulary/vocabulary_repository.dart';
import 'package:word_journey/features/profile/cefr_level.dart';

void main() {
  for (final width in [320.0, 393.0]) {
    for (final scale in [1.0, 1.3, 1.5, 1.6, 2.0]) {
      for (final dark in [false, true]) {
        testWidgets('Airy C1 pages at $width / $scale / dark=$dark', (t) async {
          t.view.devicePixelRatio = 1;
          t.view.physicalSize = Size(width, 800);
          addTearDown(t.view.reset);
          final r = await VocabularyRepository.load(),
              d = TrainerData(store: MemoryTrainerStore());
          await d.load();
          await d.saveSettings(d.settings.withValue('level', 'c1'));
          final profile = CefrProfile(TrainerLevelStore(d));
          await profile.load();
          Future<void> show(Widget page) async {
            await t.pumpWidget(
              TrainerScope(
                data: d,
                child: ProfileScope(
                  profile: profile,
                  child: MaterialApp(
                    theme: dark ? AppTheme.dark : AppTheme.light,
                    builder: (c, child) => MediaQuery(
                      data: MediaQuery.of(c)
                          .copyWith(textScaler: TextScaler.linear(scale)),
                      child: child!,
                    ),
                    home: page,
                  ),
                ),
              ),
            );
            await t.pumpAndSettle();
            expect(t.takeException(), isNull);
          }

          await show(const Scaffold(body: CategoriesScreen()));
          await show(
            CategoryScreen(repository: r, category: r.categories.first),
          );
          final p = r.packs.firstWhere((p) => p.level == CefrLevel.c1),
              words = r.words(
                r.packs.firstWhere((p) => p.level == CefrLevel.c1),
              );
          await show(TrainingSetupScreen(pack: p, words: words));
          expect(
            find.textContaining('${words.length} понятий в наборе'),
            findsOneWidget,
          );
          await t.ensureVisible(
            find.text('Посмотреть все слова · ${words.length}'),
          );
          await t.pumpAndSettle();
          await t.tap(find.text('Посмотреть все слова · ${words.length}'));
          await t.pumpAndSettle();
          await t.scrollUntilVisible(
            find.text(words.last.english),
            250,
            maxScrolls: 80,
          );
          await t.pumpAndSettle();
          expect(find.text(words.last.russian), findsOneWidget);
          expect(
            t
                .getRect(find.widgetWithText(FilledButton, 'Начать тренировку'))
                .bottom,
            lessThanOrEqualTo(800),
          );
          expect(t.takeException(), isNull);
          expect(find.byType(FittedBox), findsNothing);
          await show(const Scaffold(body: ReviewScreen()));
          await show(const Scaffold(body: ProgressScreen()));
          await show(const SettingsScreen());
          expect(d.settings.pairs, 4);
          expect(d.settings.timer, 120);
          await t.pumpWidget(const SizedBox());
          await d.flush();
          profile.dispose();
          d.dispose();
        });
      }
    }
  }
  test('Palette contrast on actual composed surfaces remains readable', () {
    double contrast(Color a, Color b) {
      final x = a.computeLuminance(), y = b.computeLuminance();
      return ((x > y ? x : y) + .05) / ((x > y ? y : x) + .05);
    }

    for (final theme in [AppTheme.light, AppTheme.dark]) {
      final c = theme.extension<TrainerColors>()!;
      final surface = Color.alphaBlend(
        c.card.withValues(alpha: .92),
        theme.colorScheme.surface,
      );
      expect(
        contrast(theme.colorScheme.onSurface, surface),
        greaterThanOrEqualTo(4.5),
      );
      expect(contrast(c.onSelected, c.selected), greaterThanOrEqualTo(4.5));
      expect(contrast(c.onSuccess, c.success), greaterThanOrEqualTo(4.5));
      expect(
        contrast(theme.colorScheme.onSurface, Color.lerp(c.card, c.error, .4)!),
        greaterThanOrEqualTo(4.5),
      );
    }
  });
}
