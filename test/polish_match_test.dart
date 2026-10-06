import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:word_journey/app/app_theme.dart';
import 'package:word_journey/features/progress/trainer_data.dart';
import 'package:word_journey/features/progress/trainer_store.dart';
import 'package:word_journey/features/training/logic/matching_engine.dart';
import 'package:word_journey/features/training/model/matching_card.dart';
import 'package:word_journey/features/training/model/session_config.dart';
import 'package:word_journey/features/training/model/test_words.dart';
import 'package:word_journey/features/training/screens/training_game_screen.dart';
import 'package:word_journey/features/training/widgets/lightning_feedback.dart';
import 'package:word_journey/features/training/widgets/match_feedback_overlay.dart';
import 'package:word_journey/features/training/widgets/training_progress_header.dart';

MatchingEngine createGame() => MatchingEngine.start(
  words: testWords,
  random: Random(42),
  config: SessionConfig(
    visiblePairs: 5,
    wordPoolSize: 20,
    targetMatches: 60,
    maxMistakes: 0,
    mode: SessionMode.practice,
  ),
);
MatchingCard mate(MatchingEngine g, MatchingCard a) =>
    g.cards.singleWhere((b) => b.pairId == a.pairId && b.id != a.id);
Future<void> answer(WidgetTester t, MatchingEngine g) async {
  final a = g.leftCards.whereType<MatchingCard>().firstWhere(
    (c) => g.isActive(c.id),
  );
  await t.tap(find.byKey(ValueKey(a.id)));
  await t.pump();
  await t.tap(find.byKey(ValueKey(mate(g, a).id)));
  await t.pump();
  await t.pump();
}

Future<void> showGame(WidgetTester t, MatchingEngine g) async {
  t.view.devicePixelRatio = 1;
  t.view.physicalSize = const Size(393, 850);
  addTearDown(t.view.reset);
  await t.pumpWidget(
    MaterialApp(
      theme: AppTheme.dark,
      home: TrainingGameScreen(game: g),
    ),
  );
  await t.pumpAndSettle();
}

void main() {
  testWidgets('Correct, combo and milestone sounds have one clear priority', (
    t,
  ) async {
    final sounds = <String>[];
    const channel = MethodChannel('com.wordjourney.app/personal');
    t.binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, (
      call,
    ) async {
      if (call.method == 'playSound') {
        sounds.add((call.arguments as Map)['name'] as String);
      }
      return null;
    });
    addTearDown(
      () => t.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        channel,
        null,
      ),
    );
    final d = TrainerData(store: MemoryTrainerStore());
    await d.load();
    await d.saveSettings(
      d.settings
          .withValue('motion', 'full')
          .withValue('sounds', true)
          .withValue('haptics', false),
    );
    final g = createGame();
    await t.pumpWidget(
      TrainerScope(
        data: d,
        child: MaterialApp(
          theme: AppTheme.dark,
          home: TrainingGameScreen(game: g),
        ),
      ),
    );
    await t.pumpAndSettle();
    await answer(t, g);
    expect(sounds.last, 'correct');
    await t.pumpAndSettle();
    await answer(t, g);
    expect(sounds.last, 'correct');
    await t.pump(const Duration(milliseconds: 110));
    expect(sounds.last, 'combo');
    await t.pumpAndSettle();
    while (g.matchedCount < 19) {
      await answer(t, g);
      await t.pumpAndSettle();
    }
    final before20 = sounds.length;
    await answer(t, g);
    await t.pumpAndSettle();
    expect(sounds.skip(before20).where((s) => s != 'select').toList(), [
      'milestone',
    ]);
    while (g.matchedCount < 59) {
      await answer(t, g);
      await t.pumpAndSettle();
    }
    final before60 = sounds.length;
    await answer(t, g);
    await t.pumpAndSettle();
    expect(sounds.skip(before60).where((s) => s != 'select').toList(), [
      'finish',
    ]);
    await t.pumpWidget(const SizedBox());
    await d.flush();
    d.dispose();
  });
  testWidgets('Rapid correct pairs accept input; combo counts and resets', (
    t,
  ) async {
    final g = createGame();
    await showGame(t, g);
    await answer(t, g);
    expect(g.matchedCount, 1);
    expect(
      t.widget<MatchFeedbackReward>(find.byType(MatchFeedbackReward)).combo,
      1,
    );
    await t.pump(const Duration(milliseconds: 100));
    // A second pair accepts real taps while the reward is still visible.
    await answer(t, g);
    expect(g.matchedCount, 2);
    expect(
      t.widget<MatchFeedbackReward>(find.byType(MatchFeedbackReward)).combo,
      2,
    );
    expect(find.text('Отлично!'), findsOneWidget);
    expect(find.text('Комбо x2'), findsOneWidget);
    final a = g.leftCards.whereType<MatchingCard>().firstWhere(
      (c) => g.isActive(c.id),
    );
    final b = g.rightCards.whereType<MatchingCard>().firstWhere(
      (c) => g.isActive(c.id) && c.pairId != a.pairId,
    );
    await t.tap(find.byKey(ValueKey(a.id)));
    await t.pump();
    await t.tap(find.byKey(ValueKey(b.id)));
    await t.pump();
    await t.pump();
    expect(g.errorCount, 1);
    expect(g.matchedCount, 2);
    expect(
      t.widget<MatchFeedbackReward>(find.byType(MatchFeedbackReward)).combo,
      0,
    );
    expect(find.text('Комбо x2'), findsNothing);
    await t.pumpAndSettle();
    expect(t.binding.transientCallbackCount, 0);
    expect(t.takeException(), isNull);
  });
  testWidgets('Wrong pair leaves every card playable', (t) async {
    final g = createGame();
    await showGame(t, g);
    final a = g.leftCards.first!,
        b = g.rightCards.firstWhere((c) => c!.pairId != a.pairId)!;
    await t.tap(find.byKey(ValueKey(a.id)));
    await t.pump();
    await t.tap(find.byKey(ValueKey(b.id)));
    await t.pump();
    await t.pump();
    expect(g.errorCount, 1);
    await t.pumpAndSettle();
    expect(t.takeException(), isNull);
  });
  testWidgets('Minimal motion feedback finishes and leaves no tickers', (
    t,
  ) async {
    final d = TrainerData(store: MemoryTrainerStore());
    await d.load();
    await d.saveSettings(d.settings.withValue('motion', 'minimal'));
    final g = createGame();
    await t.pumpWidget(
      TrainerScope(
        data: d,
        child: MaterialApp(
          theme: AppTheme.dark,
          home: TrainingGameScreen(game: g),
        ),
      ),
    );
    await t.pumpAndSettle();
    await answer(t, g);
    await t.pump(const Duration(milliseconds: 190));
    await t.pump();
    await t.pumpAndSettle();
    expect(t.binding.transientCallbackCount, 0);
    await t.pumpWidget(const SizedBox());
    await d.flush();
    d.dispose();
  });
  testWidgets(
    'Reward peak fires once at lightning peak and reward area is stable',
    (t) async {
      final peaks = <int>[];
      await t.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark,
          home: Scaffold(
            body: LightningFeedback(revision: 7, combo: 2, onPeak: peaks.add),
          ),
        ),
      );
      final size = t.getSize(find.byType(LightningFeedback));
      expect(peaks, isEmpty);
      await t.pump(const Duration(milliseconds: 110));
      expect(peaks, [7]);
      await t.pump(const Duration(milliseconds: 550));
      expect(peaks, [7]);
      expect(t.getSize(find.byType(LightningFeedback)), size);
      expect(t.binding.transientCallbackCount, 0);
    },
  );
  testWidgets('Fast streak replaces its pulse; each current peak fires once', (
    t,
  ) async {
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
    await t.pump(const Duration(milliseconds: 110));
    expect(peaks, [2]);
    await show(3, 3);
    expect(find.text('Комбо x3'), findsOneWidget);
    await t.pump(const Duration(milliseconds: 660));
    expect(t.binding.transientCallbackCount, 0);
    expect(peaks, [2, 3]);
    await show(5, 5);
    await t.pump(const Duration(milliseconds: 110));
    expect(peaks, [2, 3, 5]);
    await show(6, 0);
    await t.pumpAndSettle();
    expect(find.text('Отлично!'), findsNothing);
    expect(t.binding.transientCallbackCount, 0);
  });
  testWidgets('Milestone acceptance is immediate and presentation settles', (
    t,
  ) async {
    await t.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: Scaffold(
          body: TrainingProgressHeader(
            progress: 19 / 60,
            onSettled: () {},
            onExit: () {},
          ),
        ),
      ),
    );
    await t.pumpAndSettle();
    expect(
      t
          .widget<MilestoneMarker>(find.byKey(const ValueKey('milestone-20')))
          .completed,
      isFalse,
    );
    await t.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: Scaffold(
          body: TrainingProgressHeader(
            progress: 20 / 60,
            onSettled: () {},
            onExit: () {},
          ),
        ),
      ),
    );
    expect(
      t
          .widget<MilestoneMarker>(find.byKey(const ValueKey('milestone-20')))
          .completed,
      isTrue,
    );
    expect(
      t
          .widget<MilestoneMarker>(find.byKey(const ValueKey('milestone-30')))
          .completed,
      isFalse,
    );
    await t.pumpAndSettle();
    expect(t.binding.transientCallbackCount, 0);
  });
}
