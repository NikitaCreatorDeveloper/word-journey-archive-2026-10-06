import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:word_journey/features/training/logic/session_clock.dart';
import 'package:word_journey/features/training/logic/training_session.dart';
import 'package:word_journey/features/training/model/session_result.dart';
import 'package:word_journey/features/training/screens/training_result_screen.dart';
import 'package:word_journey/features/training/widgets/training_word_card.dart';

import 'matching_engine_test.dart' as engine;
import 'session_clock_test.dart' as clock_tests;

class Fixture {
  Fixture({int count = 4}) {
    session = TrainingSession(
      clock_tests.timed(target: 30, count: count),
      clock: SessionClock(limitSeconds: 120, now: () => now),
    )..resume();
  }
  Duration now = Duration.zero;
  late final TrainingSession session;
  void solve({bool drain = true}) {
    final game = session.game;
    final first = engine.playable(game).first;
    session.select(first.id);
    session.select(engine.mate(game, first).id);
    if (drain) clock_tests.drain(game);
  }

  void reach(int count) {
    while (session.game.matchedCount < count) {
      solve();
    }
  }
}

void main() {
  for (final count in [4, 5]) {
    test(
      '$count visible: 29 stays active; 30 wins early and freezes result/clock',
      () {
        final f = Fixture(count: count);
        final s = f.session;
        f.reach(29);
        expect(s.result, isNull);
        expect(s.game.isComplete, isFalse);
        expect(s.game.progress, 29 / 30);
        f.now = const Duration(seconds: 74);
        f.solve();
        final r = s.result!;
        expect(r.targetMatches, 30);
        expect(r.completedMatches, 30);
        expect(r.correctMatches, 30);
        expect(r.wrongAttempts, 0);
        expect(r.elapsedTime, const Duration(seconds: 74));
        expect(r.remainingTime, const Duration(seconds: 46));
        expect(r.targetReached, isTrue);
        expect(r.endReason, SessionEndReason.targetReached);
        expect(s.clock.isRunning, isFalse);
        expect(s.game.progress, 1);
        f.now += const Duration(hours: 1);
        for (var i = 0; i < 20; i++) {
          s.tick();
          s.pause();
          s.resume();
          s.endSession(SessionEndReason.timeExpired);
          s.endSession(SessionEndReason.userExited);
          for (final c in s.game.cards) {
            expect(s.select(c.id), isNull);
            expect(s.game.select(c.id), isNull);
            s.game.settlePair(c.pairId);
          }
        }
        expect(s.result, same(r));
        expect(s.clock.elapsed, const Duration(seconds: 74));
        expect(s.game.matchedCount, 30);
      },
    );

    test('$count visible: timeout at 24 preserves actual score and errors', () {
      final f = Fixture(count: count);
      final s = f.session;
      final first = engine.playable(s.game).first;
      s.select(first.id);
      s.select(
        s.game.rightCards.firstWhere((c) => c!.pairId != first.pairId)!.id,
      );
      f.reach(24);
      s.select(engine.playable(s.game).first.id);
      f.now = const Duration(seconds: 125); // missed UI ticks
      s.tick();
      final r = s.result!;
      expect(r.completedMatches, 24);
      expect(r.correctMatches, 24);
      expect(r.wrongAttempts, 1);
      expect(r.targetMatches, 30);
      expect(r.elapsedTime, const Duration(seconds: 120));
      expect(r.remainingTime, Duration.zero);
      expect(r.targetReached, isFalse);
      expect(r.endReason, SessionEndReason.timeExpired);
      expect(s.game.progress, .8);
      expect(s.game.selectedCardId, isNull);
      expect(s.clock.isRunning, isFalse);
      for (final c in s.game.cards) {
        s.select(c.id);
      }
      expect(s.result, same(r));
      expect(s.game.errorCount, 1);
    });

    for (final timerFirst in [false, true]) {
      test(
        '$count visible: deadline and final tap, timerFirst=$timerFirst',
        () {
          final f = Fixture(count: count);
          final s = f.session;
          f.reach(29);
          final first = engine.playable(s.game).first;
          final other = engine.mate(s.game, first);
          s.select(first.id);
          f.now = const Duration(seconds: 120);
          if (timerFirst) s.tick();
          s.select(other.id);
          s.select(other.id);
          s.tick();
          final r = s.result!;
          expect(r.endReason, SessionEndReason.timeExpired);
          expect(r.completedMatches, 29);
          expect(r.wrongAttempts, 0);
          expect(s.endSession(SessionEndReason.userExited), same(r));
        },
      );
    }

    test(
      '$count visible: winning tap just before deadline cannot become timeout',
      () {
        final f = Fixture(count: count);
        f.reach(29);
        f.now = const Duration(microseconds: 119999999);
        f.solve();
        f.now = const Duration(seconds: 120);
        f.session.tick();
        expect(f.session.result!.endReason, SessionEndReason.targetReached);
        expect(
          f.session.result!.remainingTime,
          const Duration(microseconds: 1),
        );
      },
    );

    test(
      '$count visible: finish near last batch tolerates duplicate animation callbacks',
      () {
        final f = Fixture(count: count);
        final tokens = <int>[];
        while (f.session.result == null) {
          f.solve(drain: false);
          for (final c in f.session.game.cards) {
            f.session.game.settlePair(c.pairId);
          }
          for (final t in f.session.game.transitions) {
            tokens.add(t.token);
            f.session.game.completeTransition(t.token);
          }
          expect(f.session.game.debugValidate(), isTrue);
        }
        final r = f.session.result;
        for (final token in tokens.reversed) {
          f.session.game.completeTransition(token);
          f.session.tick();
        }
        expect(f.session.result, same(r));
        expect(r!.completedMatches, 30);
        expect(f.session.game.debugValidate(), isTrue);
      },
    );
  }

  test('Repeated pause/resume near deadline excludes all background time', () {
    final f = Fixture();
    f.now = const Duration(milliseconds: 119500);
    f.session.pause();
    f.session.pause();
    f.now += const Duration(hours: 3);
    expect(f.session.select(f.session.game.cards.first.id), isNull);
    f.session.resume();
    f.session.resume();
    expect(f.session.result, isNull);
    f.now += const Duration(milliseconds: 499);
    f.session.tick();
    expect(f.session.result, isNull);
    f.now += const Duration(milliseconds: 1);
    f.session.pause();
    expect(f.session.result!.endReason, SessionEndReason.timeExpired);
    expect(f.session.result!.elapsedTime, const Duration(seconds: 120));
  });

  test(
    'Exit is finalized once, clears selection and stops both state and clock',
    () {
      final f = Fixture();
      f.reach(7);
      f.now = const Duration(seconds: 11);
      f.session.select(engine.playable(f.session.game).first.id);
      f.session.pause();
      f.now += const Duration(minutes: 10); // confirmation dialog
      final r = f.session.endSession(SessionEndReason.userExited);
      expect(r.endReason, SessionEndReason.userExited);
      expect(r.targetReached, isFalse);
      expect(r.completedMatches, 7);
      expect(r.elapsedTime, const Duration(seconds: 11));
      expect(r.remainingTime, const Duration(seconds: 109));
      expect(f.session.game.state.isComplete, isTrue);
      expect(f.session.game.selectedCardId, isNull);
      f.session.resume();
      expect(f.session.clock.isRunning, isFalse);
      expect(f.session.endSession(SessionEndReason.timeExpired), same(r));
    },
  );

  test('Exit exactly at deadline resolves to timeout', () {
    final f = Fixture()..now = const Duration(seconds: 120);
    expect(
      f.session.endSession(SessionEndReason.userExited).endReason,
      SessionEndReason.timeExpired,
    );
  });

  test('Replay starts with a fresh result, clock, score and board', () {
    final f = Fixture()..reach(30);
    final replay = TrainingSession(
      f.session.game.replay(),
      clock: SessionClock(limitSeconds: 120, now: () => f.now),
    )..resume();
    expect(replay.result, isNull);
    expect(replay.game.matchedCount, 0);
    expect(replay.game.errorCount, 0);
    expect(replay.game.progress, 0);
    expect(replay.game.selectedCardId, isNull);
    expect(replay.clock.remainingSeconds, 120);
    expect(replay.game.config, same(f.session.game.config));
  });

  testWidgets(
    '30th tap freezes immediately, X is ignored, result shows 1:14 and 30/30',
    (tester) async {
      var now = Duration.zero;
      final g = clock_tests.timed(target: 30);
      while (g.matchedCount < 29) {
        clock_tests.solve(g);
        clock_tests.drain(g);
      }
      final clock = SessionClock(limitSeconds: 120, now: () => now);
      await clock_tests.show(tester, g, clock);
      final c = engine.playable(g).first;
      final other = engine.mate(g, c);
      final firstTap = tester
          .widget<TrainingWordCard>(find.byKey(ValueKey(c.id)))
          .onPressed;
      final lastTap = tester
          .widget<TrainingWordCard>(find.byKey(ValueKey(other.id)))
          .onPressed;
      now = const Duration(seconds: 74);
      firstTap();
      lastTap();
      final r = g.result!;
      expect(r.endReason, SessionEndReason.targetReached);
      expect(clock.isRunning, isFalse);
      firstTap();
      lastTap();
      await tester.tap(find.byTooltip('Выйти из тренировки'));
      await tester.pump();
      expect(find.text('Выйти из тренировки?'), findsNothing);
      expect(find.byType(TrainingResultScreen), findsNothing);
      now = const Duration(seconds: 200);
      await tester.pumpAndSettle();
      expect(find.byType(TrainingResultScreen), findsOneWidget);
      expect(find.text('Уровень пройден'), findsOneWidget);
      expect(find.text('30 / 30'), findsOneWidget);
      expect(find.text('Время: 1:14'), findsOneWidget);
      expect(find.text('Ошибки: 0'), findsOneWidget);
      expect(g.result, same(r));
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Lifecycle repeats at 0:00 and X navigate to one timeout result',
    (tester) async {
      var now = Duration.zero;
      final g = clock_tests.timed(target: 30);
      await clock_tests.show(
        tester,
        g,
        SessionClock(limitSeconds: 120, now: () => now),
      );
      now = const Duration(seconds: 120);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      await tester.pump();
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      now += const Duration(minutes: 5);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump();
      await tester.tap(find.byTooltip('Выйти из тренировки'));
      await tester.pumpAndSettle();
      expect(find.byType(TrainingResultScreen), findsOneWidget);
      expect(find.text('Время вышло'), findsOneWidget);
      expect(find.text('0 / 30'), findsOneWidget);
      expect(g.result!.elapsedTime, const Duration(seconds: 120));
      expect(g.errorCount, 0);
      expect(tester.takeException(), isNull);
    },
  );
}
