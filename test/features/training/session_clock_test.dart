import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:word_journey/app/app_theme.dart';
import 'package:word_journey/features/training/logic/session_clock.dart';
import 'package:word_journey/features/training/logic/matching_engine.dart';
import 'package:word_journey/features/training/model/session_config.dart';
import 'package:word_journey/features/training/model/test_words.dart';
import 'package:word_journey/features/training/screens/training_game_screen.dart';
import 'package:word_journey/features/training/screens/training_result_screen.dart';
import 'package:word_journey/features/training/widgets/training_word_card.dart';
import 'package:word_journey/features/training/widgets/training_progress_header.dart';

import 'matching_engine_test.dart' as engine;

MatchingEngine timed({
  int seconds = 120,
  int target = 60,
  int count = 4,
  bool? finish,
}) => MatchingEngine.start(
  words: testWords,
  random: Random(42),
  config: SessionConfig(
    visiblePairs: count,
    wordPoolSize: 20,
    targetMatches: target,
    maxMistakes: 5,
    mode: SessionMode.timed,
    timeLimitSeconds: seconds,
    finishOnTarget: finish,
  ),
);

Future<void> show(
  WidgetTester tester,
  MatchingEngine g,
  SessionClock clock, {
  Brightness brightness = Brightness.dark,
}) async {
  addTearDown(() => tester.pumpWidget(const SizedBox.shrink()));
  await tester.pumpWidget(
    MaterialApp(
      theme: brightness == Brightness.dark ? AppTheme.dark : AppTheme.light,
      home: TrainingGameScreen(game: g, clock: clock),
    ),
  );
  await tester.pumpAndSettle();
}

void solve(MatchingEngine g) {
  final c = engine.playable(g).first;
  g.select(c.id);
  g.select(engine.mate(g, c).id);
}

void drain(MatchingEngine g) {
  for (final c in g.cards) {
    if (g.isMatched(c.id)) {
      g.settlePair(c.pairId);
    }
  }
  engine.requestFinalFallback(g);
  for (final t in g.transitions) {
    g.completeTransition(t.token);
  }
}

void main() {
  test('Clock starts at 120, derives remaining time from elapsed including missed ticks', () {
    var now = Duration.zero;
    final c = SessionClock(limitSeconds: 120, now: () => now);
    expect(c.remainingSeconds, 120);
    c.resume();
    now = const Duration(milliseconds: 999);
    expect(c.remainingSeconds, 120);
    now = const Duration(seconds: 1);
    expect(c.remainingSeconds, 119);
    now = const Duration(milliseconds: 37700);
    expect(c.remainingSeconds, 83);
    now = const Duration(seconds: 125);
    expect(c.remainingSeconds, 0);
    expect(c.isExpired, isTrue);
  });
  test('Clock pause/resume preserves fractional elapsed and never spends background time', () {
    var now = Duration.zero;
    final c = SessionClock(limitSeconds: 120, now: () => now)..resume();
    now = const Duration(milliseconds: 17400);
    c.pause();
    c.pause();
    now += const Duration(minutes: 10);
    expect(c.remainingSeconds, 103);
    c.resume();
    c.resume();
    now += const Duration(milliseconds: 5600);
    expect(c.remainingSeconds, 97);
    expect(c.elapsed, const Duration(seconds: 23));
  });
  test('Expired clock cannot restart and invalid limits fail', () {
    var now = Duration.zero;
    final c = SessionClock(limitSeconds: 1, now: () => now)..resume();
    now = const Duration(seconds: 3);
    c.pause();
    c.resume();
    expect(c.isRunning, isFalse);
    expect(c.remaining, Duration.zero);
    expect(() => SessionClock(limitSeconds: 0), throwsArgumentError);
  });
  test('Explicit legacy endless config can still continue beyond its progress goal', () {
    final g = timed(target: 3, finish: false);
    expect(g.cards, hasLength(8));
    for (var i = 0; i < 100; i++) {
      solve(g);
      drain(g);
      expect(g.debugValidate(), isTrue);
      expect(g.isComplete, isFalse);
      expect(g.progress, ((i + 1) / 3).clamp(0.0, 1.0));
    }
    expect(g.matchedCount, 100);
    g.expireTimeLimit();
    expect(g.isComplete, isTrue);
    expect(g.state.timedOut, isTrue);
    expect(g.progress, 1);
  });
  test('Config can explicitly finish on goal in a timed session', () {
    final g = timed(target: 2, finish: true);
    solve(g);
    solve(g);
    expect(g.isComplete, isTrue);
    expect(g.state.timedOut, isFalse);
  });
  test(
    'Timeout clears selection, preserves mistakes and ignores all later taps',
    () {
      final g = timed();
      final c = engine.playable(g).first;
      g.select(c.id);
      g.expireTimeLimit();
      expect(g.selectedCardId, isNull);
      for (final card in g.cards) {
        expect(g.select(card.id), isNull);
      }
      expect(g.matchedCount, 0);
      expect(g.errorCount, 0);
    },
  );
  test('Timeout cancels a pending rotation without new scoring or cards', () {
    final g = timed();
    solve(g);
    solve(g);
    for (final c in g.cards) {
      g.settlePair(c.pairId);
    }
    final t = g.transitions.single;
    final before = engine.board(g);
    g.expireTimeLimit();
    g.completeTransition(t.token);
    expect(engine.board(g), before);
    for (var i = 0; i < 10; i++) {
      g.completeTransition(t.token);
      for (final c in g.cards) {
        g.select(c.id);
        g.settlePair(c.pairId);
      }
    }
    expect(engine.board(g), before);
    expect(g.matchedCount, 2);
    expect(g.errorCount, 0);
    expect(g.debugValidate(), isTrue);
  });
  testWidgets(
    'HUD shows 2:00 then 1:59 from monotonic time; custom progress capsule',
    (tester) async {
      var now = Duration.zero;
      final g = timed();
      await show(tester, g, SessionClock(limitSeconds: 120, now: () => now));
      expect(find.text('2:00'), findsOneWidget);
      expect(find.byType(CapsuleProgress), findsOneWidget);
      expect(find.byType(LinearProgressIndicator), findsNothing);
      now = const Duration(seconds: 1);
      await tester.pump(const Duration(milliseconds: 101));
      expect(find.text('1:59'), findsOneWidget);
    },
  );
  testWidgets(
    'Lifecycle pauses timer and input, then resumes without lost seconds',
    (tester) async {
      var now = Duration.zero;
      final g = timed();
      await show(tester, g, SessionClock(limitSeconds: 120, now: () => now));
      now = const Duration(seconds: 3);
      await tester.pump(const Duration(milliseconds: 101));
      expect(find.text('1:57'), findsOneWidget);
      final c = g.cards.first;
      final tap = tester
          .widget<TrainingWordCard>(find.byKey(ValueKey(c.id)))
          .onPressed;
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      await tester.pump();
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      await tester.pump();
      now += const Duration(minutes: 10);
      await tester.pump(const Duration(seconds: 1));
      expect(find.text('Пауза'), findsOneWidget);
      tap();
      expect(g.selectedCardId, isNull);
      expect(find.text('1:57'), findsOneWidget);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump();
      now += const Duration(seconds: 2);
      await tester.pump(const Duration(milliseconds: 101));
      expect(find.text('1:55'), findsOneWidget);
      expect(find.text('Пауза'), findsNothing);
    },
  );
  testWidgets(
    'Timeout reaches 0:00, rejects a tap between ticks, then shows actual results',
    (tester) async {
      var now = Duration.zero;
      final g = timed();
      await show(tester, g, SessionClock(limitSeconds: 120, now: () => now));
      final c = g.cards.first;
      final tap = tester
          .widget<TrainingWordCard>(find.byKey(ValueKey(c.id)))
          .onPressed;
      now = const Duration(seconds: 120);
      tap();
      await tester.pump();
      expect(find.text('0:00'), findsOneWidget);
      expect(g.isComplete, isTrue);
      expect(g.matchedCount, 0);
      expect(g.errorCount, 0);
      expect(find.byType(TrainingResultScreen), findsNothing);
      await tester.pumpAndSettle();
      expect(find.text('Время вышло'), findsOneWidget);
      expect(find.text('0 / 60'), findsOneWidget);
      expect(find.text('Ошибки: 0'), findsOneWidget);
    },
  );
  testWidgets(
    'Timeout freezes staged refill and rejects stale widget callbacks',
    (tester) async {
      var now = Duration.zero;
      final g = timed();
      await show(tester, g, SessionClock(limitSeconds: 120, now: () => now));
      final stale = <VoidCallback>[];
      for (var i = 0; i < 2; i++) {
        final c = engine.playable(g).first;
        final other = engine.mate(g, c);
        for (final card in [c, other]) {
          stale.add(
            tester
                .widget<TrainingWordCard>(find.byKey(ValueKey(card.id)))
                .onPressed,
          );
        }
        await tester.tap(find.byKey(ValueKey(c.id)));
        await tester.pump();
        await tester.tap(find.byKey(ValueKey(other.id)));
        await tester.pump();
      }
      await tester.pump();
      final flow = g.matchFlow!;
      expect(flow.hasPendingTimer, isTrue);
      now = const Duration(seconds: 120);
      await tester.pump(const Duration(milliseconds: 101));
      expect(g.state.timedOut, isTrue);
      expect(flow.stopped, isTrue);
      expect(flow.hasPendingTimer, isFalse);
      final stopped = flow.states, cards = g.cards;
      await tester.pumpAndSettle();
      expect(g.transitions, isEmpty);
      expect(g.debugValidate(), isTrue);
      expect(find.text('2 / 60'), findsOneWidget);
      for (final callback in stale) {
        callback();
      }
      await tester.pump(const Duration(seconds: 20));
      flow.synchronize();
      expect(flow.states, stopped);
      expect(g.cards, cards);
      expect(g.matchedCount, 2);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'Last 20 seconds get a quiet accent without changing timer layout',
    (tester) async {
      var now = Duration.zero;
      final g = timed();
      await show(tester, g, SessionClock(limitSeconds: 120, now: () => now));
      final regular = tester
          .widget<Text>(find.byKey(const ValueKey('session-timer')))
          .style!
          .color;
      now = const Duration(seconds: 100);
      await tester.pump(const Duration(milliseconds: 101));
      expect(find.text('0:20'), findsOneWidget);
      final urgent = tester
          .widget<Text>(find.byKey(const ValueKey('session-timer')))
          .style!
          .color;
      expect(urgent, isNot(regular));
      expect(tester.takeException(), isNull);
    },
  );
  for (final brightness in Brightness.values) {
    for (final count in [4, 5]) {
      testWidgets(
        'HUD and $count pairs fit $brightness with large text and narrow landscape',
        (tester) async {
          tester.view.devicePixelRatio = 1;
          tester.view.physicalSize = const Size(568, 320);
          tester.platformDispatcher.textScaleFactorTestValue = 2;
          addTearDown(tester.view.reset);
          addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
          final g = timed(count: count);
          await show(
            tester,
            g,
            SessionClock(limitSeconds: 120, now: () => Duration.zero),
            brightness: brightness,
          );
          expect(find.text('2:00'), findsOneWidget);
          expect(find.byTooltip('Выйти из тренировки'), findsOneWidget);
          expect(tester.takeException(), isNull);
        },
      );
    }
  }
}
