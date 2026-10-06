import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:word_journey/app/app_theme.dart';
import 'package:word_journey/features/progress/practice_event.dart';
import 'package:word_journey/features/progress/trainer_data.dart';
import 'package:word_journey/features/progress/trainer_store.dart';
import 'package:word_journey/features/training/logic/matching_engine.dart';
import 'package:word_journey/features/training/logic/session_clock.dart';
import 'package:word_journey/features/training/model/session_config.dart';
import 'package:word_journey/features/training/model/test_words.dart';
import 'package:word_journey/features/training/screens/training_game_screen.dart';
import 'package:word_journey/features/training/widgets/lightning_feedback.dart';
import 'package:word_journey/features/training/widgets/training_progress_header.dart';
import 'package:word_journey/features/training/widgets/training_word_card.dart';

MatchingEngine game() => MatchingEngine.start(
  words: testWords,
  random: Random(42),
  config: SessionConfig(
    visiblePairs: 5,
    wordPoolSize: 20,
    targetMatches: 60,
    maxMistakes: 0,
    timeLimitSeconds: 120,
    mode: SessionMode.timed,
  ),
);

void main() {
  testWidgets(
    'Pause freezes refill and does not mark unseen words as exposed',
    (t) async {
      final data = TrainerData(store: MemoryTrainerStore());
      await data.load();
      final g = game();
      await t.pumpWidget(
        TrainerScope(
          data: data,
          child: MaterialApp(
            theme: AppTheme.dark,
            home: TrainingGameScreen(game: g),
          ),
        ),
      );
      await t.pumpAndSettle();
      int exposures() =>
          data.events.where((e) => e.kind == PracticeKind.exposure).length;
      final initial = exposures();
      for (var i = 0; i < 2; i++) {
        final a = g.leftCards.firstWhere((c) => c != null && g.isActive(c.id))!;
        final b = g.cards.singleWhere(
          (c) => c.pairId == a.pairId && c.id != a.id,
        );
        await t.tap(find.byKey(ValueKey(a.id)));
        await t.pump();
        await t.tap(find.byKey(ValueKey(b.id)));
        await t.pump();
      }
      expect(g.matchedCount, 2);
      t.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      final flow = g.matchFlow!, frozen = g.matchFlow!.states;
      final elapsed = flow.elapsed;
      await t.pump(const Duration(milliseconds: 6000));
      await t.pump();
      expect(g.inactivePairCount, 2);
      expect(flow.states, frozen);
      expect(flow.elapsed, elapsed);
      expect(flow.hasPendingTimer, isFalse);
      expect(exposures(), initial);
      t.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await t.pump();
      expect(exposures(), initial);
      t.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await t.pump();
      await t.pump(const Duration(milliseconds: 1000));
      await t.pump();
      // A is visible first but its translations are still in B's slow cycle.
      expect(g.inactivePairCount, 1);
      expect(exposures(), initial);
      await t.pump(const Duration(milliseconds: 3100));
      await t.pump();
      expect(g.inactivePairCount, 0);
      expect(exposures(), initial + 2);
      await t.pumpWidget(const SizedBox());
      await data.flush();
      data.dispose();
      expect(t.takeException(), isNull);
    },
  );
  testWidgets(
    'Selection is immediate while its local appearance tween settles',
    (t) async {
      Future<void> show(bool selected) => t.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark,
          home: Scaffold(
            body: SizedBox(
              width: 170,
              height: 60,
              child: TrainingWordCard(
                text: 'impeccable',
                selected: selected,
                onPressed: () {},
              ),
            ),
          ),
        ),
      );
      await show(false);
      await t.pumpAndSettle();
      await show(true);
      await t.pump();
      expect(t.binding.transientCallbackCount, greaterThan(0));
      expect(
        t.widget<TrainingWordCard>(find.byType(TrainingWordCard)).selected,
        isTrue,
      );
      await t.pumpAndSettle();
      expect(t.binding.transientCallbackCount, 0);
      expect(t.takeException(), isNull);
    },
  );
  testWidgets(
    'Timer and journal preserve the board; a selection preserves unrelated cards and HUD',
    (t) async {
      final data = TrainerData(store: MemoryTrainerStore());
      await data.load();
      final g = game();
      var now = Duration.zero;
      await t.pumpWidget(
        TrainerScope(
          data: data,
          child: MaterialApp(
            theme: AppTheme.dark,
            home: TrainingGameScreen(
              game: g,
              clock: SessionClock(limitSeconds: 120, now: () => now),
            ),
          ),
        ),
      );
      await t.pumpAndSettle();
      final hud = t.widget<TrainingProgressHeader>(
        find.byType(TrainingProgressHeader),
      );
      Map<Key?, TrainingWordCard> cards() => {
        for (final w in t.widgetList<TrainingWordCard>(
          find.byType(TrainingWordCard),
        ))
          w.key: w,
      };
      final before = cards();
      now = const Duration(seconds: 1);
      await t.pump(const Duration(milliseconds: 101));
      expect(find.text('1:59'), findsOneWidget);
      expect(
        identical(
          hud,
          t.widget<TrainingProgressHeader>(find.byType(TrainingProgressHeader)),
        ),
        isTrue,
      );
      for (final key in before.keys) {
        expect(identical(before[key], cards()[key]), isTrue);
      }
      await data.append([
        PracticeEvent(
          id: 'independent-journal-notification',
          sessionId: 'other',
          conceptId: 'other',
          kind: PracticeKind.exposure,
          at: DateTime.utc(2026, 10, 2),
        ),
      ]);
      await t.pump();
      for (final key in before.keys) {
        expect(identical(before[key], cards()[key]), isTrue);
      }
      final first = g.leftCards.first!;
      await t.tap(find.byKey(ValueKey(first.id)));
      await t.pump();
      await t.pump();
      expect(g.selectedCardId, first.id);
      expect(
        identical(
          hud,
          t.widget<TrainingProgressHeader>(find.byType(TrainingProgressHeader)),
        ),
        isTrue,
      );
      for (final key in before.keys.where((key) => key != ValueKey(first.id))) {
        expect(identical(before[key], cards()[key]), isTrue);
      }
      await data.saveSettings(data.settings.withValue('motion', 'minimal'));
      await t.pumpAndSettle();
      expect(t.takeException(), isNull);
      await t.pumpWidget(const SizedBox());
      await data.flush();
      data.dispose();
    },
  );

  testWidgets('A journal loaded after Match mounts still records answers', (
    t,
  ) async {
    final data = TrainerData(store: MemoryTrainerStore());
    final g = game();
    await t.pumpWidget(
      TrainerScope(
        data: data,
        child: MaterialApp(
          theme: AppTheme.dark,
          home: TrainingGameScreen(game: g),
        ),
      ),
    );
    await data.load();
    await t.pumpAndSettle();
    final a = g.leftCards.first!,
        b = g.cards.singleWhere((c) => c.id != a.id && c.pairId == a.pairId);
    await t.tap(find.byKey(ValueKey(a.id)));
    await t.pump();
    await t.tap(find.byKey(ValueKey(b.id)));
    await t.pumpAndSettle();
    await data.flush();
    expect(g.matchedCount, 1);
    expect(
      data.events.where((e) => e.kind == PracticeKind.matchCorrect),
      hasLength(1),
    );
    await t.pumpWidget(const SizedBox());
    data.dispose();
  });

  testWidgets(
    'A disposed combo pulse cannot remove the next pulse; reset removes overlay and tickers',
    (t) async {
      final peaks = <int>[];
      Future<void> show(int revision, int combo) => t.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark,
          home: Scaffold(
            body: LightningFeedback(
              revision: revision,
              combo: combo,
              onPeak: peaks.add,
            ),
          ),
        ),
      );
      await show(2, 2);
      await t.pump(const Duration(milliseconds: 660));
      for (final fade in t.widgetList<FadeTransition>(
        find.descendant(
          of: find.byType(LightningFeedback),
          matching: find.byType(FadeTransition),
        ),
      )) {
        expect(
          fade.opacity.value,
          0,
          reason: 'A completed envelope must not flash at opacity one.',
        );
      }
      await t.pump();
      expect(
        find.descendant(
          of: find.byType(LightningFeedback),
          matching: find.byType(CustomPaint),
        ),
        findsNothing,
      );
      await show(5, 5);
      await t.pump(const Duration(milliseconds: 110));
      expect(find.text('Комбо x5'), findsOneWidget);
      expect(peaks.where((r) => r == 5), hasLength(1));
      await show(6, 0);
      await t.pump(const Duration(seconds: 1));
      await t.pump();
      expect(find.text('Комбо x5'), findsNothing);
      expect(
        find.descendant(
          of: find.byType(LightningFeedback),
          matching: find.byType(CustomPaint),
        ),
        findsNothing,
      );
      expect(t.binding.transientCallbackCount, 0);
      expect(t.takeException(), isNull);
    },
  );

  testWidgets('Minimal combo uses a short caption without a decorative bolt', (
    t,
  ) async {
    final data = TrainerData(store: MemoryTrainerStore());
    await data.load();
    await data.saveSettings(data.settings.withValue('motion', 'minimal'));
    await t.pumpWidget(
      TrainerScope(
        data: data,
        child: MaterialApp(
          theme: AppTheme.dark,
          home: const Scaffold(body: LightningFeedback(revision: 2, combo: 2)),
        ),
      ),
    );
    await t.pump(const Duration(milliseconds: 40));
    expect(find.text('Комбо x2'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(LightningFeedback),
        matching: find.byType(CustomPaint),
      ),
      findsNothing,
    );
    await t.pumpAndSettle();
    expect(t.binding.transientCallbackCount, 0);
    await t.pumpWidget(const SizedBox());
    data.dispose();
  });
}
