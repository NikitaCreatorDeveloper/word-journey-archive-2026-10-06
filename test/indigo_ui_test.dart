import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:word_journey/app/app_shell.dart';
import 'package:word_journey/app/app_theme.dart';
import 'package:word_journey/app/design_tokens.dart';
import 'package:word_journey/app/reward_presentation.dart';
import 'package:word_journey/features/profile/cefr_level.dart';
import 'package:word_journey/features/profile/cefr_profile.dart';
import 'package:word_journey/features/progress/practice_event.dart';
import 'package:word_journey/features/progress/progress_screen.dart';
import 'package:word_journey/features/progress/trainer_data.dart';
import 'package:word_journey/features/progress/trainer_store.dart';
import 'package:word_journey/features/review/review_screen.dart';
import 'package:word_journey/features/topics/categories_screen.dart';
import 'package:word_journey/features/training/screens/training_setup_screen.dart';
import 'package:word_journey/features/training/widgets/lightning_feedback.dart';
import 'package:word_journey/features/vocabulary/vocabulary_repository.dart';

void main() {
  late TrainerData d;
  late CefrProfile profile;
  late VocabularyRepository r;
  Future<void> initialize() async {
    r = await VocabularyRepository.load();
    d = TrainerData(
      store: MemoryTrainerStore(),
      now: () => DateTime(2026, 10, 2, 12),
    );
    await d.load();
    await d.saveSettings(d.settings.withValue('level', 'a1'));
    profile = CefrProfile(TrainerLevelStore(d));
    await profile.load();
  }

  tearDown(() {
    profile.dispose();
    d.dispose();
  });
  Future<void> show(
    WidgetTester t,
    Widget page, {
    bool dark = true,
    double scale = 1,
  }) async {
    t.view.devicePixelRatio = 1;
    t.view.physicalSize = const Size(393, 900);
    addTearDown(t.view.reset);
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
  }

  testWidgets('Continue hero uses saved pack and opens that complete set', (
    t,
  ) async {
    await initialize();
    final pack = r.packs.where((p) => p.level == CefrLevel.a1).elementAt(2);
    await d.saveSession({
      'id': 'last',
      'packId': pack.id,
      'at': DateTime(2026, 10, 1).toUtc().toIso8601String(),
      'mode': 'match',
      'correct': 5,
      'wrong': 0,
      'elapsedMs': 1000,
      'completed': false,
    });
    await show(t, const AppShell());
    expect(find.text(pack.title), findsOneWidget);
    expect(find.text('Продолжить набор'), findsOneWidget);
    await t.tap(find.text('Продолжить'));
    await t.pumpAndSettle();
    expect(
      t.widget<TrainingSetupScreen>(find.byType(TrainingSetupScreen)).pack?.id,
      pack.id,
    );
    expect(d.events, isEmpty);
    expect(d.settings.pairs, 4);
    expect(d.settings.timer, 120);
  });
  testWidgets(
    'CEFR pills search actual selected level in English and Russian',
    (t) async {
      await initialize();
      await show(t, const AppShell());
      await t.tap(find.text('C1'));
      await t.pumpAndSettle();
      expect(profile.level, CefrLevel.c1);
      final word = r.concepts.firstWhere((c) => c.cefrLevel == CefrLevel.c1);
      for (final text in [word.english, word.russian]) {
        await t.enterText(find.byType(TextField), text);
        await t.pumpAndSettle();
        expect(
          find.textContaining('${word.english} — ${word.russian}'),
          findsWidgets,
        );
        expect(find.textContaining('Только C1'), findsOneWidget);
      }
      expect(d.settings.values['level'], 'c1');
    },
  );
  testWidgets('Bottom navigation preserves live search state', (t) async {
    await initialize();
    await show(t, const AppShell());
    await t.enterText(find.byType(TextField), 'coffee');
    await t.pumpAndSettle();
    await t.tap(find.byType(NavigationDestination).at(1));
    await t.pumpAndSettle();
    await t.tap(find.byType(NavigationDestination).at(0));
    await t.pumpAndSettle();
    expect(
      t.widget<EditableText>(find.byType(EditableText)).controller.text,
      'coffee',
    );
    expect(find.textContaining('Найдено:'), findsOneWidget);
    expect(t.takeException(), isNull);
  });
  testWidgets('All categories route reaches the complete existing catalog', (
    t,
  ) async {
    await initialize();
    await show(t, const AppShell());
    await t.ensureVisible(find.text('Все ›'));
    await t.pumpAndSettle();
    await t.tap(find.text('Все ›'));
    await t.pumpAndSettle();
    expect(find.text('Все категории'), findsOneWidget);
    await t.scrollUntilVisible(
      find.text(r.categories.last.title),
      300,
      maxScrolls: 30,
      scrollable: find.descendant(
        of: find.byType(CategoryDirectoryScreen),
        matching: find.byWidgetPredicate(
          (w) => w is Scrollable && w.axisDirection == AxisDirection.down,
        ),
      ),
    );
    await t.pumpAndSettle();
    expect(find.text(r.categories.last.title), findsOneWidget);
    expect(t.takeException(), isNull);
  });
  testWidgets('Review filters form two accessible columns at phone size', (
    t,
  ) async {
    await initialize();
    await show(t, const Scaffold(body: ReviewScreen()));
    final due = t.getRect(find.byKey(const ValueKey('review-filter-due')));
    final errors = t.getRect(
      find.byKey(const ValueKey('review-filter-errors')),
    );
    final training = t.getRect(
      find.byKey(const ValueKey('review-filter-training')),
    );
    expect(due.top, errors.top);
    expect(errors.left, greaterThan(due.right));
    expect(training.top, greaterThan(due.bottom));
    expect(due.height, greaterThanOrEqualTo(48));
    expect(t.takeException(), isNull);
  });
  testWidgets(
    'Review favorite filter and recall toggle use real compatible queue',
    (t) async {
      await initialize();
      final words = r.words(r.packs.first).take(5).toList();
      for (final w in words) {
        await d.setFlag(w.id, favorite: true);
      }
      await show(t, const Scaffold(body: ReviewScreen()));
      await t.ensureVisible(
        find.byKey(const ValueKey('review-filter-favorite')),
      );
      await t.pumpAndSettle();
      await t.tap(find.byKey(const ValueKey('review-filter-favorite')));
      await t.pumpAndSettle();
      expect(find.text('Повторить выбранное'), findsOneWidget);
      await t.ensureVisible(find.byKey(const ValueKey('recall-toggle')));
      await t.pumpAndSettle();
      await t.tap(find.byType(Switch));
      await t.pumpAndSettle();
      expect(find.text('Проверить память · 5'), findsOneWidget);
      expect(d.events, isEmpty);
      expect(d.settings.values['reviewMode'], 'match');
    },
  );
  testWidgets('Rank, word metrics and weekly activity derive from events', (
    t,
  ) async {
    await initialize();
    final words = r.concepts.take(12).toList();
    for (var i = 0; i < words.length; i++) {
      await d.append([
        PracticeEvent(
          id: 'e$i',
          sessionId: 's',
          conceptId: words[i].id,
          kind: PracticeKind.exposure,
          at: DateTime(2026, 9, 28),
        ),
      ]);
    }
    final store = d.store!;
    await store.write('flags', [
      for (final w in words.take(10))
        {
          'id': w.id,
          'favorite': false,
          'excluded': false,
          'firstConsolidatedAt': DateTime(
            2026,
            9,
            30,
          ).toUtc().toIso8601String(),
        },
    ]);
    await d.load();
    await d.append([
      PracticeEvent(
        id: 'a',
        sessionId: 'a',
        conceptId: words.first.id,
        kind: PracticeKind.matchCorrect,
        at: DateTime(2026, 9, 28),
      ),
      PracticeEvent(
        id: 'b',
        sessionId: 'b',
        conceptId: words.first.id,
        kind: PracticeKind.matchWrong,
        at: DateTime(2026, 9, 30),
      ),
      PracticeEvent(
        id: 'hint',
        sessionId: 'b',
        conceptId: words.first.id,
        kind: PracticeKind.hint,
        at: DateTime(2026, 9, 30),
      ),
    ]);
    await show(t, const Scaffold(body: ProgressScreen()));
    expect(find.text('Искра'), findsOneWidget);
    expect(find.text('10 / 20'), findsOneWidget);
    expect(
      t.widget<Text>(find.byKey(const ValueKey('metric-count-seen'))).data,
      '12',
    );
    await t.scrollUntilVisible(find.text('2 ответа'), 200);
    await t.pumpAndSettle();
    expect(find.text('2 активных дня'), findsOneWidget);
    await t.scrollUntilVisible(find.byKey(const ValueKey('metric-seen')), -200);
    await t.pumpAndSettle();
    await t.tap(find.byKey(const ValueKey('metric-seen')));
    await t.pumpAndSettle();
    expect(find.byType(MetricWordsScreen), findsOneWidget);
    expect(find.text(words.first.english), findsOneWidget);
  });
  for (final mode in ['full', 'calm', 'minimal']) {
    testWidgets('Lightning feedback $mode ends without writing progress', (
      t,
    ) async {
      await initialize();
      await d.saveSettings(d.settings.withValue('motion', mode));
      await show(
        t,
        const Scaffold(
          body: Center(child: LightningFeedback(revision: 1, combo: 2)),
        ),
      );
      expect(find.text('Комбо x2'), findsNothing);
      expect(t.binding.transientCallbackCount, 0);
      expect(d.events, isEmpty);
    });
  }
  test(
    'Premium text and gradients retain 4.5 contrast at each endpoint',
    () async {
      await initialize();
      double contrast(Color a, Color b) {
        final x = a.computeLuminance(), y = b.computeLuminance();
        return ((x > y ? x : y) + .05) / ((x > y ? y : x) + .05);
      }

      for (final bg in [
        AppColors.backgroundPrimary,
        AppColors.surface,
        AppColors.surfaceElevated,
      ]) {
        expect(contrast(AppColors.textPrimary, bg), greaterThanOrEqualTo(4.5));
        expect(
          contrast(AppColors.textSecondary, bg),
          greaterThanOrEqualTo(4.5),
        );
      }
      for (final bg in [const Color(0xFFD2C4FF), const Color(0xFFA493FA)]) {
        expect(
          contrast(const Color(0xFF201746), bg),
          greaterThanOrEqualTo(4.5),
        );
      }
      for (final bg in [const Color(0xFF7460DD), const Color(0xFF5440B2)]) {
        expect(contrast(Colors.white, bg), greaterThanOrEqualTo(4.5));
      }
      // Include the brightest possible illustrated pixel behind hero metadata.
      final moon = Color.alphaBlend(
        Colors.white.withValues(alpha: .7),
        const Color(0xFF3E3587),
      );
      for (final scrim in [const Color(0xDD303675), const Color(0xDD202B55)]) {
        expect(
          contrast(AppColors.textSecondary, Color.alphaBlend(scrim, moon)),
          greaterThanOrEqualTo(4.5),
        );
      }
      expect(RankBadge.assets.toSet(), hasLength(11));
    },
  );
}
