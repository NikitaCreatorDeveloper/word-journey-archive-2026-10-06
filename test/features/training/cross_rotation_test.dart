import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:word_journey/features/training/logic/matching_engine.dart';
import 'package:word_journey/features/training/model/matching_card.dart';
import 'package:word_journey/features/training/model/session_result.dart';
import 'package:word_journey/features/training/model/word_pair.dart';

import 'matching_engine_test.dart' as h;

void checkPlan(MatchingEngine g, BoardTransition transition) {
  expect(transition.isCrossRefill, isTrue);
  expect(transition.retiringPairIds, hasLength(2));
  expect(transition.slots, hasLength(4));
  expect(transition.outgoing.values.every((c) => g.isMatched(c.id)), isTrue);
  expect(transition.incoming.keys.toSet(), transition.slots);
  expect(transition.incoming.values.toSet(), hasLength(4));
  expect(
    transition.incoming.values.map((c) => c.conceptId).toSet(),
    hasLength(2),
  );
  for (final id in transition.retiringPairIds) {
    final incoming = transition.outgoing.entries
        .where((entry) => entry.value.pairId == id)
        .map((entry) => transition.incoming[entry.key]!)
        .toList();
    expect(incoming, hasLength(2));
    expect(incoming.first.isPartnerOf(incoming.last), isFalse);
  }
  final projected = {...h.board(g), ...transition.incoming};
  for (final c in projected.values.whereType<MatchingCard>()) {
    expect(
      projected.values.whereType<MatchingCard>().where(c.isPartnerOf),
      hasLength(1),
    );
  }
  for (final left in [true, false]) {
    final column = projected.entries.where((entry) => entry.key.left == left);
    expect(
      column.map((entry) => entry.value!.conceptId).toSet(),
      hasLength(g.visiblePairCount),
    );
  }
}

void main() {
  test(
    'Answers use conceptId and language, independently of occurrence IDs',
    () {
      const word = WordPair(id: 'park', english: 'park', russian: 'парк');
      final english = MatchingCard.fromWord(
        word,
        CardLanguage.english,
        occurrence: 1,
      );
      final russian = MatchingCard.fromWord(
        word,
        CardLanguage.russian,
        occurrence: 99,
      );
      expect(english.pairId, isNot(russian.pairId));
      expect(english.isPartnerOf(russian), isTrue);
      expect(english.isPartnerOf(english), isFalse);
    },
  );

  for (final visible in [4, 5]) {
    test(
      '$visible: A waits; A+B and C+D refill only their four matched slots',
      () {
        final g = h.makeGame(visible: visible);
        for (var batch = 0; batch < 12; batch++) {
          final beforeA = h.board(g), a = h.playable(g).first;
          h.match(g, a);
          h.settle(g);
          expect(h.board(g), beforeA);
          expect(g.inactivePairCount, 1);
          expect(g.transitions, isEmpty);
          final b = h.playable(g).first;
          h.match(g, b);
          final transition = g.transitions.single;
          expect(transition.retiringPairIds, [a.pairId, b.pairId]);
          checkPlan(g, transition);
          final fixedSlots = h.unmatchedSlots(g), before = h.board(g);
          h.settle(g);
          h.expectStationary(g, fixedSlots);
          for (final slot in before.keys) {
            if (transition.slots.contains(slot)) {
              expect(g.cardAt(slot), same(transition.incoming[slot]));
            } else {
              expect(g.cardAt(slot), same(before[slot]));
            }
          }
          expect(g.inactivePairCount, 0);
          expect(g.activePairCount, visible);
          expect(g.transitions, isEmpty);
          h.valid(g);
        }
      },
    );

    test(
      '$visible: 1200+ four-slot refills preserve every unmatched slotId and partner',
      () {
        final g = h.makeGame(visible: visible, target: 2410);
        final random = Random(visible);
        var batches = 0;
        while (!g.isComplete) {
          final options = h.playable(g), before = h.board(g);
          h.match(g, options[random.nextInt(options.length)]);
          expect(h.board(g), before);
          final fixedSlots = h.unmatchedSlots(g);
          if (g.transitions.firstOrNull case final transition?) {
            checkPlan(g, transition);
            for (final id in transition.retiringPairIds) {
              g.settlePair(id);
            }
            g.commitTransition(transition.token);
            h.expectStationary(g, fixedSlots);
            h.valid(g);
            g.completeTransition(transition.token);
            h.expectStationary(g, fixedSlots);
            batches++;
          }
          h.settle(g);
          h.expectStationary(g, fixedSlots);
        }
        expect(batches, greaterThan(1200));
        expect(g.matchedCount, 2410);
        expect(g.transitions, isEmpty);
      },
    );
  }

  test('Both pairs must settle; active input never invalidates or enters the batch', () {
    final g = h.makeGame(visible: 5);
    final a = h.playable(g).first;
    h.match(g, a);
    final b = h.playable(g).first;
    h.match(g, b);
    final transition = g.transitions.single;
    final fixed = h.unmatchedSlots(g), active = h.playable(g);
    g.select(active.first.id);
    g.holdPointer(10, active.last.id);
    expect(g.transitions.single, same(transition));
    g.settlePair(a.pairId);
    expect(g.transitionReady, isFalse);
    g.completeTransition(transition.token);
    expect(transition.committed, isFalse);
    g.settlePair(b.pairId);
    expect(g.transitionReady, isTrue);
    g.commitTransition(transition.token);
    h.expectStationary(g, fixed);
    expect(g.selectedCardId, active.first.id);
    for (final incoming in transition.incoming.values) {
      expect(g.isActive(incoming.id), isFalse);
    }
    for (final id in fixed.keys) {
      expect(g.isActive(id), isTrue);
    }
    g.completeTransition(transition.token);
    final beforeStale = h.board(g);
    g.commitTransition(transition.token);
    g.completeTransition(transition.token);
    expect(h.board(g), beforeStale);
    expect(g.inactivePairCount, 0);
    g.releasePointer(10);
    h.valid(g);
  });

  test('Rapid matches under held pointers can consume every pair without donors or deadlock', () {
    final g = h.makeGame(visible: 5);
    final held = g.cards.toList();
    for (var i = 0; i < held.length; i++) {
      g.holdPointer(100 + i, held[i].id);
    }
    for (var i = 0; i < 5; i++) {
      h.match(g, h.playable(g).first);
    }
    final before = h.board(g);
    h.settle(g);
    expect(g.matchedCount, 5);
    expect(g.activePairCount, 0);
    expect(g.transitionReady, isFalse);
    expect(h.board(g), before);
    for (var i = 0; i < held.length; i++) {
      g.releasePointer(100 + i);
    }
    h.settle(g);
    expect(g.inactivePairCount, 1);
    expect(g.activePairCount, 4);
    while (!g.isComplete) {
      h.match(g, h.playable(g).first);
      h.settle(g);
    }
    expect(g.matchedCount, g.totalPairCount);
  });

  test('Session end cancels uncommitted four-slot refill and rejects stale callbacks', () {
    for (final reason in [
      SessionEndReason.timeExpired,
      SessionEndReason.userExited,
    ]) {
      final g = h.makeGame();
      h.match(g, h.playable(g).first);
      h.settle(g);
      h.match(g, h.playable(g).first);
      final token = g.transitions.single.token, before = h.board(g);
      g.endSession(
        reason: reason,
        elapsedTime: Duration.zero,
        remainingTime: Duration.zero,
      );
      g.commitTransition(token);
      g.completeTransition(token);
      h.settle(g);
      expect(h.board(g), before);
      expect(g.transitions, isEmpty);
      expect(g.inactivePairCount, 2);
    }
  });

  test('Session end during fade-in retains the committed four-slot board', () {
    final g = h.makeGame();
    h.match(g, h.playable(g).first);
    h.settle(g);
    final b = h.playable(g).first;
    h.match(g, b);
    g.settlePair(b.pairId);
    final token = g.transitions.single.token;
    g.commitTransition(token);
    final before = h.board(g);
    g.expireTimeLimit();
    g.completeTransition(token);
    expect(h.board(g), before);
    expect(g.transitions, isEmpty);
    h.valid(g);
  });
}
