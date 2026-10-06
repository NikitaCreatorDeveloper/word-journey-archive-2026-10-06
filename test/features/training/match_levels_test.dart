import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:word_journey/app/app_theme.dart';
import 'package:word_journey/features/training/widgets/pair_count_selector.dart';
import 'package:word_journey/features/training/logic/matching_engine.dart';
import 'package:word_journey/features/training/logic/session_clock.dart';
import 'package:word_journey/features/training/logic/training_session.dart';
import 'package:word_journey/features/training/model/match_levels.dart';
import 'package:word_journey/features/training/model/session_result.dart';
import 'package:word_journey/features/training/model/test_words.dart';
import 'package:word_journey/features/training/widgets/training_progress_header.dart';

import 'matching_engine_test.dart' as board;
import 'session_clock_test.dart' as clocks;
import 'training_flow_test.dart' as flow;

void main() {
  test(
    'One standard 60-match deadline session and ordered 20/30/60 milestones',
    () {
      expect(matchMilestones, [20, 30, 60]);
      for (final visible in [4, 5]) {
        final c = standardMatchLevel.toSessionConfig(visiblePairs: visible);
        expect(c.targetMatches, 60);
        expect(c.timeLimitSeconds, 120);
        expect(c.visiblePairs, visible);
        expect(c.finishOnTarget, isTrue);
      }
    },
  );

  for (final count in [4, 5]) {
    test(
      '$count visible: 20 and 30 continue; exactly 60 wins before deadline',
      () {
        var now = Duration.zero;
        final g = MatchingEngine.start(
          words: testWords,
          random: Random(42),
          config: standardMatchLevel.toSessionConfig(visiblePairs: count),
        );
        final s = TrainingSession(
          g,
          clock: SessionClock(limitSeconds: 120, now: () => now),
        )..resume();
        for (var i = 1; i <= 60; i++) {
          now = Duration(seconds: i);
          final first = board.playable(g).first;
          s.select(first.id);
          s.select(board.mate(g, first).id);
          clocks.drain(g);
          expect(g.progress, i / 60);
          if (i < 60) {
            expect(s.result, isNull);
            expect(g.isComplete, isFalse);
            expect(s.clock.isRunning, isTrue);
          }
        }
        expect(s.result!.endReason, SessionEndReason.targetReached);
        expect(s.result!.completedMatches, 60);
        expect(s.result!.remainingTime, const Duration(seconds: 60));
        expect(s.clock.isRunning, isFalse);
        expect(g.progress, 1);
      },
    );
    test(
      '$count visible: timeout before 60 keeps actual score and clean replay',
      () {
        var now = Duration.zero;
        final g = MatchingEngine.start(
          words: testWords,
          random: Random(42),
          config: standardMatchLevel.toSessionConfig(visiblePairs: count),
        );
        final s = TrainingSession(
          g,
          clock: SessionClock(limitSeconds: 120, now: () => now),
        )..resume();
        for (var i = 0; i < 34; i++) {
          final first = board.playable(g).first;
          s.select(first.id);
          s.select(board.mate(g, first).id);
          clocks.drain(g);
        }
        now = const Duration(seconds: 120);
        s.tick();
        expect(s.result!.completedMatches, 34);
        expect(s.result!.targetMatches, 60);
        expect(s.result!.wrongAttempts, 0);
        expect(s.result!.endReason, SessionEndReason.timeExpired);
        final replay = g.replay();
        expect(replay.config, same(g.config));
        expect(replay.progress, 0);
        expect(replay.result, isNull);
      },
    );
  }

  testWidgets('Setup has only 4/5 board choice and starts 60/120', (
    tester,
  ) async {
    await flow.openTraining(tester, 5);
    final g = flow.currentGame(tester);
    expect(g.totalPairCount, 60);
    expect(g.config.timeLimitSeconds, 120);
    expect(g.visiblePairCount, 5);
    await tester.tap(find.byTooltip('Выйти из тренировки'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Выйти'));
    await tester.pumpAndSettle();
    expect(find.byType(SegmentedButton<String>), findsNothing);
    expect(find.byType(PairCountSelector), findsOneWidget);
    for (final text in ['20', '40', '60']) {
      expect(find.text(text), findsNothing);
    }
  });

  testWidgets('Milestone markers activate independently and stay completed', (
    tester,
  ) async {
    for (final matched in [0, 19, 20, 29, 30, 59, 60]) {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark,
          home: Scaffold(
            body: TrainingProgressHeader(
              progress: matched / 60,
              targetMatches: 60,
              seconds: 120,
              onSettled: () {},
              onExit: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      for (final value in matchMilestones) {
        final marker = tester.widget<MilestoneMarker>(
          find.byKey(ValueKey('milestone-$value')),
        );
        expect(marker.completed, matched >= value);
        expect(find.text('$value'), findsOneWidget);
      }
      expect(
        tester.widget<CapsuleProgress>(find.byType(CapsuleProgress)).value,
        matched / 60,
      );
      expect(tester.takeException(), isNull);
    }
  });
  testWidgets(
    'Milestone labels do not overlap on a narrow screen with large text',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(320, 568);
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.view.reset);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Padding(
              padding: const EdgeInsets.all(20),
              child: TrainingProgressHeader(
                progress: .5,
                seconds: 120,
                onSettled: () {},
                onExit: () {},
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final rects = [
        for (final m in matchMilestones)
          tester.getRect(find.byKey(ValueKey('milestone-$m'))),
      ];
      for (var i = 1; i < rects.length; i++) {
        expect(rects[i - 1].right, lessThan(rects[i].left));
      }
      expect(tester.takeException(), isNull);
    },
  );
}
