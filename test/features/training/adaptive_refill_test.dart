import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:word_journey/features/training/logic/adaptive_refill_controller.dart';
import 'package:word_journey/features/training/logic/matching_engine.dart';
import 'package:word_journey/features/training/model/matching_card.dart';
import 'package:word_journey/features/training/model/session_result.dart';

import 'matching_engine_test.dart' as h;
import 'cross_rotation_test.dart' show checkPlan;

class Fixture {
  Fixture({int visible = 4, int target = 60})
    : game = h.makeGame(visible: visible, target: target) {
    controller = AdaptiveRefillController(game, now: () => now);
    addTearDown(controller.dispose);
  }
  final MatchingEngine game;
  late final AdaptiveRefillController controller;
  Duration now = Duration.zero;
  MatchingCard match([MatchingCard? chosen]) {
    final card = chosen ?? h.playable(game).first, before = h.board(game);
    h.match(game, card);
    expect(h.board(game), before);
    controller.synchronize();
    return card;
  }

  void advance(int milliseconds) {
    final fixed = h.unmatchedSlots(game);
    final destination = now + Duration(milliseconds: milliseconds);
    while (true) {
      final deadline = controller.nextDeadline;
      if (deadline == null) break;
      final due = now + deadline - controller.elapsed;
      if (due > destination) break;
      now = due;
      controller.synchronize();
    }
    now = destination;
    controller.synchronize();
    h.expectStationary(game, fixed);
    h.valid(game);
  }
}

void main() {
  for (final visible in [4, 5]) {
    test(
      '$visible: A immediately disables only itself and confirms before its calm fade',
      () {
        final f = Fixture(visible: visible),
            before = h.board(f.game),
            a = f.match();
        expect(f.game.isActive(a.id), isFalse);
        expect(f.controller.phaseOf(a.pairId), RefillPhase.success);
        f.advance(139);
        expect(f.controller.phaseOf(a.pairId), RefillPhase.success);
        f.advance(1);
        expect(f.controller.phaseOf(a.pairId), RefillPhase.matchedFading);
        expect(h.board(f.game), before);
        expect(f.controller.nextDeadline, const Duration(milliseconds: 4400));
        expect(
          f.controller.visualFor(f.game.slotIdOf(a.id)!).duration,
          const Duration(milliseconds: 4260),
        );
        for (final slot in h.unmatchedSlots(f.game).values) {
          expect(f.controller.visualFor(slot), activeRefillVisual);
          expect(f.game.isActive(f.game.cardAt(slot)!.id), isTrue);
        }
      },
    );

    test(
      '$visible: solo fallback includes the 600 ms appearance in its five-second total',
      () {
        final f = Fixture(visible: visible),
            before = h.board(f.game),
            a = f.match();
        final slots = before.keys
            .where((s) => before[s]?.pairId == a.pairId)
            .toList();
        f.advance(1000);
        expect(h.board(f.game), before);
        f.advance(3399);
        expect(h.board(f.game), before);
        expect(f.game.isActive(a.id), isFalse);
        f.advance(1);
        final incoming = slots.map((s) => f.game.cardAt(s)!).toList();
        expect(incoming.first.isPartnerOf(incoming.last), isTrue);
        expect(incoming.every((c) => f.game.isActive(c.id)), isTrue);
        expect(f.game.inactivePairCount, 0);
        for (final slot in slots) {
          expect(f.controller.visualFor(slot).phase, RefillPhase.refilling);
          expect(
            f.controller.textVisualFor(slot).duration,
            const Duration(milliseconds: 600),
          );
          expect(f.controller.textVisualFor(slot).scaleIn, isFalse);
        }
        for (final slot in before.keys.where((s) => !slots.contains(s))) {
          expect(f.game.cardAt(slot), same(before[slot]));
          expect(f.controller.visualFor(slot), activeRefillVisual);
        }
        final after = h.board(f.game);
        f.advance(599);
        expect(
          f.controller.visualFor(slots.first).phase,
          RefillPhase.refilling,
        );
        f.advance(1);
        expect(f.controller.visualFor(slots.first).phase, RefillPhase.active);
        f.advance(5000);
        expect(h.board(f.game), after);
        expect(f.controller.hasPendingTimer, isFalse);
      },
    );

    test(
      '$visible: B at 500 ms accelerates A to 1500, while B keeps its own 5500 deadline',
      () {
        final f = Fixture(visible: visible), a = f.match();
        final aSlot = f.game.slotIdOf(a.id)!;
        f.advance(500);
        final b = f.match(),
            bSlot = f.game.slotIdOf(b.id)!,
            plan = f.game.transitions.single;
        checkPlan(f.game, plan);
        expect(plan.retiringPairIds, [a.pairId, b.pairId]);
        expect(
          f.controller.returnDeadlineOf(a.pairId),
          const Duration(milliseconds: 1500),
        );
        expect(
          f.controller.returnDeadlineOf(b.pairId),
          const Duration(milliseconds: 5500),
        );
        final before = h.board(f.game);
        f.advance(139);
        expect(f.controller.phaseOf(b.pairId), RefillPhase.success);
        f.advance(1);
        expect(
          f.controller.visualFor(aSlot).duration,
          const Duration(milliseconds: 520),
        );
        expect(f.controller.visualFor(bSlot).phase, RefillPhase.matchedFading);
        expect(
          f.controller.visualFor(bSlot).duration,
          const Duration(milliseconds: 4260),
        );
        expect(
          f.controller.textVisualFor(bSlot).duration,
          const Duration(milliseconds: 520),
        );
        f.advance(519);
        expect(h.board(f.game), before);
        f.advance(1);
        expect(f.game.inactivePairCount, 0);
        for (final slot in plan.slots) {
          expect(f.game.cardAt(slot), same(plan.incoming[slot]));
          expect(f.controller.textVisualFor(slot).phase, RefillPhase.refilling);
          expect(
            f.controller.textVisualFor(slot).duration,
            const Duration(milliseconds: 340),
          );
        }
        final after = h.board(f.game);
        f.advance(340);
        expect(f.controller.visualFor(aSlot).phase, RefillPhase.active);
        expect(f.controller.visualFor(bSlot).phase, RefillPhase.refilling);
        expect(f.controller.visualFor(bSlot).opacity, 1);
        expect(
          f.controller.returnDeadlineOf(b.pairId),
          const Duration(milliseconds: 5500),
        );
        expect(f.controller.textVisualFor(bSlot).phase, RefillPhase.active);
        f.advance(4000);
        expect(h.board(f.game), after);
        expect(f.controller.hasPendingTimer, isFalse);
      },
    );

    test(
      '$visible: A→B→C→D has independent return tokens without reissuing published words',
      () {
        final f = Fixture(visible: visible);
        for (var batch = 0; batch < 12; batch++) {
          final a = f.match();
          expect(f.game.transitions, isEmpty);
          f.advance(140);
          final b = f.match(), plan = f.game.transitions.single;
          expect(plan.retiringPairIds, [a.pairId, b.pairId]);
          expect(
            f.controller.tokenOf(a.pairId),
            isNot(f.controller.tokenOf(b.pairId)),
          );
          f.advance(1000);
          expect(f.game.inactivePairCount, 0);
          expect(f.controller.phaseOf(a.pairId), isNull);
          expect(f.controller.phaseOf(b.pairId), isNull);
        }
      },
    );

    test(
      '$visible: late B cannot postpone A and unsafe cross planning returns full pairs',
      () {
        for (final when in [3999, 4200, 4350, 4399]) {
          final f = Fixture(visible: visible), a = f.match();
          f.advance(when);
          final b = f.match();
          final deadline = f.controller.returnDeadlineOf(a.pairId)!;
          expect(
            deadline,
            lessThanOrEqualTo(const Duration(milliseconds: 5000)),
          );
          expect(deadline, Duration(milliseconds: min(5000, when + 1000)));
          f.advance(5000 - when);
          expect(f.game.cards.any((c) => c.id == a.id), isFalse);
          h.valid(f.game);
          f.advance(when);
          expect(f.game.cards.any((c) => c.id == b.id), isFalse);
        }
      },
    );

    test(
      '$visible: 1200+ mixed replacements preserve unmatched slotIds, full partners and exact quota',
      () {
        final f = Fixture(visible: visible, target: 2410),
            random = Random(visible);
        var steps = 0;
        while (!f.game.isComplete) {
          expect(++steps, lessThan(15000));
          final available = h.playable(f.game);
          if (available.length > 1 && random.nextInt(7) == 0) {
            f.game.select(available.first.id);
            expect(
              f.game.select(h.mate(f.game, available.last).id),
              MatchFeedback.incorrect,
            );
            f.controller.synchronize();
          }
          if (available.isNotEmpty) {
            f.match(available[random.nextInt(available.length)]);
          }
          if (f.game.isComplete) break;
          f.advance(
            [5, 70, 200, 500, 950, 1700, 4999, 5000][random.nextInt(8)],
          );
          final slots = f.game.transitions.expand((t) => t.slots).toList();
          expect(slots.toSet().length, slots.length);
        }
        expect(f.game.matchedCount, 2410);
        expect(
          f.game.matchedCount + f.game.activePairCount - visible,
          greaterThan(1200),
        );
        expect(f.controller.hasPendingTimer, isFalse);
        expect(f.game.transitions, isEmpty);
      },
    );
  }

  test('Errors and repeated taps do not restart A fade or change its deadline/token', () {
    final f = Fixture(), a = f.match();
    f.advance(200);
    final slot = f.game.slotIdOf(a.id)!,
        visual = f.controller.visualFor(f.game.slotIdOf(a.id)!);
    final token = f.controller.tokenOf(a.pairId);
    final active = h.playable(f.game);
    for (var i = 0; i < 8; i++) {
      f.game.select(active.first.id);
      expect(
        f.game.select(h.mate(f.game, active.last).id),
        MatchFeedback.incorrect,
      );
      f.controller.synchronize();
      f.advance(20);
      expect(f.controller.visualFor(slot).revision, visual.revision);
      expect(f.controller.tokenOf(a.pairId), token);
      expect(
        f.controller.returnDeadlineOf(a.pairId),
        const Duration(milliseconds: 5000),
      );
    }
    f.advance(4039);
    expect(f.game.isMatched(a.id), isTrue);
    f.advance(1);
    expect(f.game.cards.any((c) => c.id == a.id), isFalse);
  });

  test('Rapid B still gives both answers their own confirmation', () {
    final f = Fixture(), a = f.match();
    f.advance(5);
    final b = f.match();
    f.advance(134);
    expect(f.controller.phaseOf(a.pairId), RefillPhase.success);
    expect(f.controller.phaseOf(b.pairId), RefillPhase.success);
    f.advance(1);
    expect(f.controller.phaseOf(a.pairId), RefillPhase.fastFinalizing);
    expect(f.controller.phaseOf(b.pairId), RefillPhase.success);
    f.advance(5);
    expect(f.controller.phaseOf(b.pairId), RefillPhase.fastFinalizing);
    f.advance(519);
    expect(f.game.cards.any((c) => c.id == a.id), isTrue);
    f.advance(1);
    expect(f.game.inactivePairCount, 0);
  });

  test('Race at the publication deadline is safe in either event order', () {
    for (final timerFirst in [false, true]) {
      final f = Fixture(), a = f.match();
      f.advance(140);
      final b = h.playable(f.game).first;
      if (timerFirst) {
        f.advance(4260);
      } else {
        f.now = const Duration(milliseconds: 4400);
      }
      f.match(b);
      f.advance(600);
      expect(f.game.cards.any((c) => c.id == a.id), isFalse);
      expect(f.game.isMatched(b.id), isTrue);
      expect(f.game.matchedCount, 2);
      final after = h.board(f.game);
      f.advance(1000);
      expect(h.board(f.game), after);
    }
  });

  test('A newer match invalidates an unpublished fallback; old tokens cannot write either generation', () {
    final f = Fixture(), a = f.match();
    f.advance(140);
    expect(f.game.requestFallback(a.pairId), isTrue);
    final token = f.game.transitions.single.token;
    f.match();
    expect(f.game.transitions.single.isCrossRefill, isTrue);
    final before = h.board(f.game);
    f.game.completeTransition(token);
    expect(h.board(f.game), before);
    f.advance(1000);
    final after = h.board(f.game);
    f.game.commitTransition(token);
    f.game.completeTransition(token);
    expect(h.board(f.game), after);
  });

  test('A held pointer does not make independent C+D wait behind A+B', () {
    final f = Fixture(visible: 5);
    // Hold a real card in this fixture before accepting its match.
    final held = h.playable(f.game).first;
    f.game.holdPointer(7, held.id);
    f.match(held);
    f.advance(10);
    f.match();
    final ab = f.game.transitions.single;
    f.advance(10);
    f.match();
    f.advance(10);
    f.match();
    final cd = f.game.transitions.last;
    expect(cd.token, isNot(ab.token));
    expect(cd.slots.intersection(ab.slots), isEmpty);
    f.advance(1000);
    expect(f.game.transitions.map((t) => t.token), [ab.token]);
    expect(f.game.cardAt(cd.slots.first), same(cd.incoming[cd.slots.first]));
    f.game.releasePointer(7);
    f.controller.synchronize();
    expect(f.game.transitions, isEmpty);
    expect(f.game.cards.any((c) => c.id == held.id), isFalse);
    expect(
      f.controller.textVisualFor(ab.slots.first).duration,
      const Duration(milliseconds: 340),
    );
  });

  test('Pause freezes deadlines and generation; resume uses only remaining foreground time', () {
    final f = Fixture(), a = f.match();
    f.advance(500);
    f.match();
    f.advance(300);
    final before = h.board(f.game), slot = f.game.slotIdOf(a.id)!;
    final remaining = f.controller.textVisualFor(slot).duration;
    f.controller.setPaused(true);
    f.advance(10000);
    expect(h.board(f.game), before);
    expect(f.controller.textVisualFor(slot).duration, remaining);
    expect(f.controller.hasPendingTimer, isFalse);
    f.controller.setPaused(false);
    f.advance(359);
    expect(h.board(f.game), before);
    f.advance(1);
    expect(f.game.cards.any((c) => c.id == a.id), isFalse);
    f.advance(340);
    expect(f.controller.visualFor(slot).phase, RefillPhase.active);
  });

  test('Last single queued pair safely returns without exceeding the session target', () {
    final f = Fixture(visible: 5, target: 8);
    f.match();
    f.match();
    f.advance(1000);
    expect(f.game.queuedPairCount, 1);
    final a = f.match();
    f.match();
    expect(f.game.transitions, isEmpty);
    f.advance(659);
    expect(f.game.isMatched(a.id), isTrue);
    f.advance(1);
    expect(f.game.queuedPairCount, 0);
    while (!f.game.isComplete) {
      f.match();
    }
    expect(f.game.matchedCount, 8);
    expect(f.controller.hasPendingTimer, isFalse);
  });

  test('Session end cancels slow, accelerated and surface-only callbacks', () {
    for (final stage in [0, 1, 2]) {
      final f = Fixture();
      f.match();
      f.advance(140);
      if (stage > 0) f.match();
      if (stage == 2) f.advance(1000);
      final before = h.board(f.game);
      f.game.endSession(
        reason: SessionEndReason.userExited,
        elapsedTime: f.now,
        remainingTime: Duration.zero,
      );
      f.controller.synchronize();
      f.advance(10000);
      expect(h.board(f.game), before);
      expect(f.controller.hasPendingTimer, isFalse);
      expect(f.game.transitions, isEmpty);
    }
  });

  test('Target reached cancels all refill sources immediately', () {
    final f = Fixture(target: 2);
    f.match();
    f.advance(140);
    f.match();
    final before = h.board(f.game);
    f.advance(10000);
    expect(f.game.isComplete, isTrue);
    expect(h.board(f.game), before);
    expect(f.controller.hasPendingTimer, isFalse);
  });
}
