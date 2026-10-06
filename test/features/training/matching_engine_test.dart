import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:word_journey/features/training/logic/matching_engine.dart';
import 'package:word_journey/features/training/model/matching_card.dart';
import 'package:word_journey/features/training/model/session_config.dart';
import 'package:word_journey/features/training/model/test_words.dart';
import 'package:word_journey/features/training/model/word_pair.dart';

MatchingEngine makeGame({
  int visible = 4,
  int pool = 20,
  int target = 60,
  int seed = 42,
}) => MatchingEngine.start(
  words: testWords,
  random: Random(seed),
  config: SessionConfig(
    visiblePairs: visible,
    wordPoolSize: pool,
    targetMatches: target,
    maxMistakes: 5,
    timeLimitSeconds: 1,
    finishOnTarget: true,
    mode: SessionMode.timed,
  ),
);
MatchingCard mate(MatchingEngine g, MatchingCard c) => g.cards.singleWhere(
  (other) => other.pairId == c.pairId && other.id != c.id,
);
List<MatchingCard> playable(MatchingEngine g) => g.leftCards
    .whereType<MatchingCard>()
    .where((c) => g.isActive(c.id) && g.isActive(mate(g, c).id))
    .toList();
Map<BoardSlot, MatchingCard?> board(MatchingEngine g) => {
  for (var i = 0; i < g.visiblePairCount; i++) ...{
    (left: true, row: i): g.leftCards[i],
    (left: false, row: i): g.rightCards[i],
  },
};
Map<String, BoardSlot> unmatchedSlots(MatchingEngine g) => {
  for (final c in g.cards)
    if (!g.isMatched(c.id)) c.id: g.slotIdOf(c.id)!,
};
void expectStationary(MatchingEngine g, Map<String, BoardSlot> slots) {
  for (final entry in slots.entries) {
    expect(
      g.slotIdOf(entry.key),
      entry.value,
      reason: 'Unmatched card ${entry.key} must retain its slotId',
    );
  }
}

void valid(MatchingEngine g) {
  expect(g.debugValidate(), isTrue);
  final l = g.leftCards.whereType<MatchingCard>().toList();
  final r = g.rightCards.whereType<MatchingCard>().toList();
  expect(l.map((c) => c.conceptId).toSet(), r.map((c) => c.conceptId).toSet());
  expect(l.map((c) => c.conceptId).toSet().length, l.length);
  expect(r.map((c) => c.conceptId).toSet().length, r.length);
  for (final c in g.cards) {
    expect(g.isMatched(c.id), g.isMatched(mate(g, c).id));
  }
  expect(
    g.matchedCount + g.activePairCount + g.queuedPairCount,
    g.totalPairCount,
  );
}

void requestFinalFallback(MatchingEngine g) {
  // Nonvisual tests explicitly request the deadline fallback for a finite
  // session's final queued pair. Production owns its timer.
  if (g.queuedPairCount == 1 &&
      g.matchedPairIds.length >= 2 &&
      g.transitions.isEmpty) {
    expect(g.requestFallback(g.matchedPairIds.first), isTrue);
  }
}

void settle(MatchingEngine g) {
  for (final c in g.cards.toList()) {
    if (g.isMatched(c.id)) {
      g.settlePair(c.pairId);
    }
  }
  var iterations = 0;
  requestFinalFallback(g);
  while (g.transitions.isNotEmpty) {
    expect(++iterations, lessThan(20));
    final ready = g.transitions
        .where((t) => t.committed || g.isTransitionReady(t.token))
        .firstOrNull;
    if (ready == null) break;
    g.completeTransition(ready.token);
    valid(g);
  }
}

void match(MatchingEngine g, MatchingCard c) {
  final other = mate(g, c);
  if (g.selectedCardId case final id?) {
    g.select(id);
  }
  g.select(c.id);
  expect(g.select(other.id), MatchFeedback.correct);
  valid(g);
}

void main() {
  for (final visible in [4, 5]) {
    test(
      '$visible complete, unique initial pairs with independently shuffled columns',
      () {
        final layouts = <String>{};
        for (var seed = 0; seed < 20; seed++) {
          final g = makeGame(visible: visible, seed: seed);
          valid(g);
          expect(g.cards, hasLength(visible * 2));
          layouts.add(
            g.rightCards
                .map(
                  (c) => g.leftCards.indexWhere((l) => l?.pairId == c?.pairId),
                )
                .join(','),
          );
        }
        expect(layouts.length, greaterThan(3));
      },
    );
    for (final target in [30, 60, 100, 160, 1105]) {
      test(
        '$visible slots / $target matches: full pairs, exact progress and varied orders',
        () {
          for (var order = 0; order < 3; order++) {
            final g = makeGame(visible: visible, target: target, seed: order);
            final random = Random(order);
            final uses = <String, int>{};
            for (var count = 1; count <= target; count++) {
              final options = playable(g);
              expect(options, isNotEmpty);
              final c = order == 0
                  ? options.first
                  : order == 1
                  ? options.last
                  : options[random.nextInt(options.length)];
              uses.update(c.conceptId, (v) => v + 1, ifAbsent: () => 1);
              final oldIds = [c.id, mate(g, c).id];
              final before = board(g);
              match(g, c);
              expect(board(g), before);
              for (final id in oldIds) {
                expect(g.isMatched(id), isTrue);
                expect(g.isActive(id), isFalse);
                expect(g.select(id), isNull);
              }
              expect(g.matchedCount, count);
              expect(g.progress, count / target);
              expect(g.isComplete, count == target);
              settle(g);
              valid(g);
            }
            expect(g.activePairCount, 0);
            expect(g.cards.every((c) => g.isMatched(c.id)), isTrue);
            expect(g.progress, 1);
            expect(uses.values.any((v) => v > 1), isTrue);
          }
        },
      );
    }
    test(
      '$visible constrained unique word pool safely repeats across batches',
      () {
        final g = makeGame(visible: visible, pool: visible, target: 80);
        while (!g.isComplete) {
          match(g, playable(g).first);
          settle(g);
        }
        expect(g.progress, 1);
      },
    );
  }
  test(
    'One matched pair stays inactive indefinitely, without a replacement',
    () {
      final g = makeGame();
      final before = board(g);
      final c = playable(g).first;
      match(g, c);
      settle(g);
      expect(g.inactivePairCount, 1);
      expect(g.transitions, isEmpty);
      expect(board(g), before);
      for (var i = 0; i < 50; i++) {
        g.select(c.id);
        g.select(mate(g, c).id);
        g.settlePair(c.pairId);
      }
      expect(g.matchedCount, 1);
      expect(board(g), before);
    },
  );
  test('Active selected/held cards stay fixed throughout refresh', () {
    final g = makeGame(visible: 5);
    final first = playable(g).first;
    match(g, first);
    final second = playable(g).first;
    match(g, second);
    final selected = playable(g).first;
    final held = playable(g).last;
    final before = board(g);
    g.select(selected.id);
    g.holdPointer(9, held.id);
    settle(g);
    expect(g.selectedCardId, selected.id);
    for (final s in before.keys.where(
      (s) =>
          before[s]?.pairId == selected.pairId ||
          before[s]?.pairId == held.pairId,
    )) {
      expect(board(g)[s], same(before[s]));
    }
    g.releasePointer(9);
  });
  test(
    'No connection repeats more than twice across refreshed generations',
    () {
      final g = makeGame(target: 160);
      final history = <int, (String, int, int)>{};
      void inspect() {
        for (var i = 0; i < g.visiblePairCount; i++) {
          final c = g.leftCards[i];
          if (c == null) {
            continue;
          }
          final old = history[i];
          final right = g.rightCards.indexWhere((r) => r?.pairId == c.pairId);
          if (old?.$1 == c.id && old?.$2 == right) {
            continue;
          }
          final streak = old?.$2 == right ? old!.$3 + 1 : 1;
          expect(streak, lessThanOrEqualTo(2));
          history[i] = (c.id, right, streak);
        }
      }

      inspect();
      while (!g.isComplete) {
        match(g, playable(g).first);
        settle(g);
        inspect();
      }
    },
  );
  test('Repeating the original gesture pattern cannot mechanically finish a session', () {
    final g = makeGame(target: 160);
    final mapping = [
      for (final l in g.leftCards)
        g.rightCards.indexWhere((r) => r?.pairId == l?.pairId),
    ];
    for (var pass = 0; pass < 50; pass++) {
      for (var row = 0; row < mapping.length; row++) {
        if (g.selectedCardId case final selected?) {
          g.select(selected);
        }
        final l = g.leftCards[row];
        final r = g.rightCards[mapping[row]];
        if (l != null && r != null) {
          g.select(l.id);
          g.select(r.id);
        }
        settle(g);
      }
    }
    expect(g.errorCount, greaterThan(0));
    expect(g.isComplete, isFalse);
  });
  test(
    'Rapid taps, out-of-order settlements and stale batch callbacks are safe',
    () {
      final g = makeGame(visible: 5, target: 160);
      final random = Random(4);
      final staleCards = <MatchingCard>[];
      final tokens = <int>[];
      var steps = 0;
      while (!g.isComplete) {
        expect(++steps, lessThan(500));
        final active = playable(g);
        if (active.isNotEmpty) {
          final c = active[random.nextInt(active.length)];
          staleCards.addAll([c, mate(g, c)]);
          match(g, c);
        }
        for (final c in staleCards.toList()..shuffle(random)) {
          expect(g.select(c.id), isNull);
          g.settlePair(c.pairId);
        }
        requestFinalFallback(g);
        tokens.addAll(g.transitions.map((t) => t.token));
        for (final token in tokens.toList()..shuffle(random)) {
          g.completeTransition(token);
          valid(g);
        }
      }
      settle(g);
      final before = board(g);
      for (final token in tokens) {
        g.completeTransition(token);
      }
      expect(board(g), before);
      expect(g.matchedCount, 160);
    },
  );
  test('Deselect, same-column transfer, wrong answers and inert limits', () {
    final g = makeGame();
    final l = playable(g);
    g.select(l[0].id);
    g.select(l[0].id);
    expect(g.selectedCardId, isNull);
    g.select(l[0].id);
    g.select(l[1].id);
    expect(g.selectedCardId, l[1].id);
    g.select(l[1].id);
    final before = board(g);
    for (var i = 0; i < 12; i++) {
      g.select(l[0].id);
      expect(g.select(mate(g, l[1]).id), MatchFeedback.incorrect);
      expect(g.selectedCardId, isNull);
    }
    expect(g.errorCount, 12);
    expect(g.config.timeLimitSeconds, 1);
    expect(g.isComplete, isFalse);
    expect(board(g), before);
  });
  test(
    'Targets smaller than a board and final single refill finish exactly',
    () {
      for (final visible in [4, 5]) {
        for (var target = 1; target <= 24; target++) {
          final g = makeGame(visible: visible, target: target);
          while (!g.isComplete) {
            match(g, playable(g).first);
            settle(g);
          }
          expect(g.matchedCount, target);
          expect(g.activePairCount, 0);
        }
      }
    },
  );
  test('Replay resets state and keeps config/pool', () {
    final g = makeGame();
    match(g, playable(g).first);
    final next = g.replay();
    expect(next.config, same(g.config));
    expect(next.wordPool, g.wordPool);
    expect(next.matchedCount, 0);
    expect(next.inactivePairCount, 0);
    expect(next.transitions, isEmpty);
    valid(next);
  });
  test('Public views and transition plans are immutable', () {
    final g = makeGame();
    expect(() => g.cards.clear(), throwsUnsupportedError);
    expect(() => g.leftCards.clear(), throwsUnsupportedError);
    expect(() => g.wordPool.clear(), throwsUnsupportedError);
    match(g, playable(g).first);
    match(g, playable(g).first);
    for (final c in g.cards) {
      g.settlePair(c.pairId);
    }
    expect(() => g.transitions.clear(), throwsUnsupportedError);
    expect(() => g.transitions.single.outgoing.clear(), throwsUnsupportedError);
  });
  test('Invalid sources fail before starting', () {
    for (final words in [
      <WordPair>[],
      [...testWords, testWords.first],
      [...testWords, const WordPair(id: '', english: 'x', russian: 'y')],
    ]) {
      expect(
        () => MatchingEngine.start(words: words, config: makeGame().config),
        throwsArgumentError,
      );
    }
  });
}
