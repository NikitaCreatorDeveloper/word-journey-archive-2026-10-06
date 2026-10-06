import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:word_journey/app/app_theme.dart';
import 'package:word_journey/features/training/logic/matching_engine.dart';
import 'package:word_journey/features/training/logic/session_clock.dart';
import 'package:word_journey/features/training/logic/training_session.dart';
import 'package:word_journey/features/training/model/matching_card.dart';
import 'package:word_journey/features/training/model/match_flow_models.dart';
import 'package:word_journey/features/training/model/session_config.dart';
import 'package:word_journey/features/training/model/session_result.dart';
import 'package:word_journey/features/training/model/test_words.dart';
import 'package:word_journey/features/training/screens/training_game_screen.dart';
import 'package:word_journey/features/training/widgets/match_flow_tile.dart';
import 'package:word_journey/features/training/widgets/training_word_card.dart';

class RealFlow {
  RealFlow({int pairs = 5, int target = 60, int pool = 12, int? seconds}) {
    game = MatchingEngine.start(
      words: testWords,
      random: Random(41),
      config: SessionConfig(
        visiblePairs: pairs,
        wordPoolSize: pool,
        targetMatches: target,
        maxMistakes: 5,
        mode: seconds == null ? SessionMode.practice : SessionMode.timed,
        timeLimitSeconds: seconds,
      ),
    );
    game.enableMatchFlow(now: () => now, autoSchedule: false);
    session = TrainingSession(
      game,
      clock: SessionClock(limitSeconds: seconds, now: () => now),
    )..resume();
    addTearDown(game.disposeMatchFlow);
  }
  Duration now = Duration.zero;
  late final MatchingEngine game;
  late final TrainingSession session;
  List<MatchingCard> get available => game.leftCards
      .whereType<MatchingCard>()
      .where((c) => game.isActive(c.id))
      .toList();
  MatchingCard partner(MatchingCard c) =>
      game.cards.singleWhere((p) => p.pairId == c.pairId && p.id != c.id);
  void solve([MatchingCard? card]) {
    final a = card ?? available.first,
        b = partner(a),
        count = game.matchedCount;
    session.select(a.id);
    expect(session.select(b.id), MatchFeedback.correct);
    expect(game.matchedCount, count + 1);
    expect(game.debugValidate(), isTrue);
  }

  void advance(int ms) {
    now += Duration(milliseconds: ms);
    session.tick();
    game.matchFlow!.synchronize();
    expect(game.debugValidate(), isTrue);
  }
}

void main() {
  for (final pairs in [4, 5]) {
    test(
      '$pairs: real catalog follows A→B→C with A visible and B still fading',
      () {
        final h = RealFlow(pairs: pairs), g = h.game;
        final a = h.available.first, aSlot = g.slotIdOf(a.id)!;
        h.solve(a);
        h.advance(500);
        final b = h.available.first, bSlot = g.slotIdOf(b.id)!;
        h.solve(b);
        h.advance(1000);
        final newA = g.cardAt(aSlot)!;
        expect(newA.conceptId.startsWith('lab-'), isFalse);
        expect(newA.id, isNot(a.id));
        expect(g.matchFlow!.stateOf(aSlot).value.visual.textOpacity, 1);
        expect(
          g.matchFlow!.stateOf(aSlot).value.visual.state,
          MatchVisualState.waitingPartner,
        );
        expect(g.isActive(newA.id), isFalse);
        expect(g.cardAt(bSlot), same(b));
        expect(g.isMatched(b.id), isTrue);
        expect(h.available, hasLength(pairs - 2));
        expect(g.select(newA.id), isNull);
        expect(g.selectedCardId, isNull);
        final before = g.matchFlow!.stateOf(bSlot).value.visual.textOpacity;
        h.solve();
        expect(g.matchFlow!.stateOf(bSlot).value.visual.textOpacity, before);
        expect(g.matchFlow!.deadlineOf(2), const Duration(milliseconds: 2500));
        h.advance(720);
        expect(g.cardAt(aSlot), same(newA));
        expect(g.isActive(newA.id), isTrue);
        final mate = h.partner(newA);
        expect(g.isActive(mate.id), isTrue);
        expect(
          g.matchFlow!.stateOf(g.slotIdOf(mate.id)!).value.visual.textOpacity,
          greaterThanOrEqualTo(.6),
        );
        h.solve(newA);
        expect(g.matchedCount, 4);
      },
    );

    test(
      '$pairs: finite 60/60, odd remaining capacity and stale input are safe',
      () {
        for (final target in [pairs, pairs + 1, 17, 60]) {
          final h = RealFlow(pairs: pairs, target: target);
          final old = <String>[];
          while (!h.game.isComplete) {
            while (h.available.isEmpty) {
              h.advance(1000);
            }
            final c = h.available.first;
            old.add(c.id);
            h.solve(c);
            h.advance([170, 500, 250, 1200, 5200][old.length % 5]);
            expect(h.game.matchFlow!.issuedCount, lessThanOrEqualTo(target));
            for (final id in old.where(
              (id) => !h.game.cards.any((c) => c.id == id),
            )) {
              expect(h.game.select(id), isNull);
            }
          }
          expect(h.game.matchedCount, target);
          expect(h.game.result!.endReason, SessionEndReason.targetReached);
          expect(h.game.matchFlow!.hasPendingTimer, isFalse);
          final stopped = h.game.matchFlow!.states;
          h.advance(20000);
          expect(h.game.matchFlow!.states, stopped);
          expect(h.available, isEmpty);
        }
      },
    );

    test('$pairs: minimum personal pool never duplicates visible concepts', () {
      final h = RealFlow(pairs: pairs, pool: pairs, target: 31);
      while (!h.game.isComplete) {
        while (h.available.isEmpty) {
          h.advance(1000);
        }
        h.solve();
        h.advance(170);
      }
      expect(h.game.matchedCount, 31);
      expect(h.game.matchFlow!.issuedCount, 31);
    });

    test(
      '$pairs: untouched and selected X survives refills, errors and pause',
      () {
        final h = RealFlow(pairs: pairs),
            x = h.available.last,
            mate = h.partner(x);
        final xSlot = h.game.slotIdOf(x.id)!,
            mateSlot = h.game.slotIdOf(mate.id)!;
        var notifications = 0;
        h.game.matchFlow!.stateOf(xSlot).addListener(() => notifications++);
        h.game.matchFlow!.stateOf(mateSlot).addListener(() => notifications++);
        for (var i = 0; i < 20; i++) {
          var candidates = h.available.where((c) => c.id != x.id).toList();
          while (candidates.isEmpty) {
            h.advance(1000);
            candidates = h.available.where((c) => c.id != x.id).toList();
          }
          h.solve(candidates.first);
          h.advance([170, 500, 1200, 5200][i % 4]);
          expect(h.game.cardAt(xSlot), same(x));
          expect(h.game.cardAt(mateSlot), same(mate));
          expect(h.game.isActive(x.id), isTrue);
        }
        expect(notifications, 0);
        h.session.select(x.id);
        h.game.matchFlow!.setPaused(true);
        final frozen = h.game.matchFlow!.states;
        h.advance(10000);
        expect(h.game.matchFlow!.states, frozen);
        h.game.matchFlow!.setPaused(false);
        h.advance(7000);
        expect(h.game.selectedCardId, x.id);
        expect(h.game.cardAt(mateSlot), same(mate));
        expect(h.game.isActive(x.id), isTrue);
        expect(h.session.select(mate.id), MatchFeedback.correct);
      },
    );
  }

  test(
    'Exact session timeout stops pending flow and cannot reset the result',
    () {
      final h = RealFlow(seconds: 3);
      h.solve();
      h.advance(500);
      h.solve();
      h.advance(2499);
      expect(h.game.result, isNull);
      h.advance(1);
      final result = h.game.result;
      expect(result!.endReason, SessionEndReason.timeExpired);
      expect(result.completedMatches, 2);
      expect(h.game.matchFlow!.stopped, isTrue);
      final stopped = h.game.matchFlow!.states;
      h.advance(20000);
      expect(h.game.result, same(result));
      expect(h.game.matchFlow!.states, stopped);
    },
  );

  testWidgets(
    'Production uses the exact Lab font and tiles with no debug overlay',
    (t) async {
      t.view.physicalSize = const Size(393, 873);
      t.view.devicePixelRatio = 1;
      addTearDown(t.view.reset);
      final h = RealFlow();
      await t.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: TrainingGameScreen(game: h.game),
        ),
      );
      await t.pump();
      expect(find.byType(MatchFlowTile), findsNWidgets(10));
      for (final card in h.game.cards) {
        final finder = find.byKey(ValueKey(card.id));
        final text = t.widget<Text>(
          find.descendant(of: finder, matching: find.byType(Text)),
        );
        expect(text.style!.fontSize, 20);
        expect(text.style!.fontWeight, FontWeight.w600);
        expect(text.style!.height, 1.15);
        expect(t.getRect(finder).height, inInclusiveRange(64, 104));
        expect(
          find.descendant(of: finder, matching: find.byType(Opacity)),
          findsNothing,
        );
        expect(
          find.descendant(of: finder, matching: find.byType(FadeTransition)),
          findsNothing,
        );
      }
      expect(find.textContaining(' · g'), findsNothing);
      final a = h.available.first, aSlot = h.game.slotIdOf(a.id)!;
      final stale = t
          .widget<TrainingWordCard>(find.byKey(ValueKey(a.id)))
          .onPressed;
      h.solve(a);
      h.advance(500);
      h.solve();
      h.advance(1000);
      await t.pump();
      stale();
      expect(h.game.matchedCount, 2);
      final newA = h.game.cardAt(aSlot)!;
      expect(
        t.widget<TrainingWordCard>(find.byKey(ValueKey(newA.id))).enabled,
        isFalse,
      );
      final bCount = h.game.matchedCount;
      final third = h.available.first, thirdMate = h.partner(third);
      await t.tap(find.byKey(ValueKey(third.id)));
      await t.pump();
      await t.tap(find.byKey(ValueKey(thirdMate.id)));
      await t.pump();
      expect(h.game.matchedCount, bCount + 1);
      await t.pumpWidget(const SizedBox());
      expect(t.takeException(), isNull);
    },
  );
}
