import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:word_journey/app/app_theme.dart';
import 'package:word_journey/features/progress/trainer_data.dart';
import 'package:word_journey/features/progress/trainer_store.dart';
import 'package:word_journey/features/training/screens/training_setup_screen.dart';
import 'package:word_journey/features/training/screens/training_game_screen.dart';
import 'package:word_journey/features/training/widgets/pair_count_selector.dart';

void main() {
  for (final width in [320.0, 393.0]) {
    for (final scale in [1.0, 1.3, 1.5]) {
      for (final dark in [false, true]) {
        testWidgets('Premium setup $width / $scale dark=$dark', (t) async {
          t.view.devicePixelRatio = 1;
          t.view.physicalSize = Size(width, 850);
          addTearDown(t.view.reset);
          await t.pumpWidget(
            MaterialApp(
              theme: dark ? AppTheme.dark : AppTheme.light,
              builder: (c, child) => MediaQuery(
                data: MediaQuery.of(c)
                    .copyWith(textScaler: TextScaler.linear(scale)),
                child: child!,
              ),
              home: const TrainingSetupScreen(),
            ),
          );
          await t.pumpAndSettle();
          await t.ensureVisible(find.byKey(const ValueKey('pairs-5')));
          await t.pumpAndSettle();
          expect(find.byType(Radio<int>), findsNothing);
          expect(find.text('4 пары'), findsOneWidget);
          expect(find.text('5 пар'), findsOneWidget);
          expect(
            t.getSize(find.byKey(const ValueKey('pairs-5'))).height,
            greaterThanOrEqualTo(48),
          );
          await t.tap(find.byKey(const ValueKey('pairs-5')));
          await t.pumpAndSettle();
          expect(
            t.widget<PairCountSelector>(find.byType(PairCountSelector)).value,
            5,
          );
          expect(
            t.getRect(find.text('Начать тренировку')).bottom,
            lessThanOrEqualTo(850),
          );
          expect(t.takeException(), isNull);
        });
      }
    }
  }
  testWidgets(
    'Field choice persists and untimed mode uses real session config',
    (t) async {
      final d = TrainerData(store: MemoryTrainerStore());
      await d.load();
      // Use an independent MemoryStore, never the phone database.
      await t.pumpWidget(
        TrainerScope(
          data: d,
          child: MaterialApp(
            theme: AppTheme.dark,
            home: const TrainingSetupScreen(),
          ),
        ),
      );
      await t.pumpAndSettle();
      await t.ensureVisible(find.byKey(const ValueKey('pairs-5')));
      await t.pumpAndSettle();
      await t.tap(find.byKey(const ValueKey('pairs-5')));
      await t.pumpAndSettle();
      expect(d.settings.pairs, 5);
      await t.ensureVisible(find.byKey(const ValueKey('setup-untimed')));
      await t.pumpAndSettle();
      await t.tap(find.byKey(const ValueKey('setup-untimed')));
      await t.pumpAndSettle();
      expect(d.settings.timer, 0);
      await t.tap(find.text('Начать тренировку'));
      await t.pumpAndSettle();
      final game = t
          .widget<TrainingGameScreen>(find.byType(TrainingGameScreen))
          .game;
      expect(game.visiblePairCount, 5);
      expect(game.config.isTimed, isFalse);
      expect(game.totalPairCount, 60);
      await t.pumpWidget(const SizedBox());
      await d.flush();
      final reload = TrainerData(store: d.store);
      await reload.load();
      expect(reload.settings.pairs, 5);
      expect(reload.settings.timer, 0);
      reload.dispose();
      d.dispose();
    },
  );
}
