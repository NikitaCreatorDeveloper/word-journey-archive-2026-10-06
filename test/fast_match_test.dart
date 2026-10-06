import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:word_journey/app/app_theme.dart';
import 'package:word_journey/features/training/logic/matching_engine.dart';
import 'package:word_journey/features/training/model/session_config.dart';
import 'package:word_journey/features/training/model/test_words.dart';
import 'package:word_journey/features/training/widgets/training_board.dart';
import 'package:word_journey/features/training/widgets/training_word_card.dart';

void main() {
  testWidgets('Four-slot refill remains input-ready with disabled tickers', (
    t,
  ) async {
    final g = MatchingEngine.start(
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
    final changes = ValueNotifier(0);
    void select(String id) {
      g.select(id);
      changes.value++;
    }

    await t.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 350,
              child: TickerMode(
                enabled: false,
                child: TrainingBoard(
                  game: g,
                  cardHeight: 60,
                  errors: const {},
                  changes: changes,
                  onSelect: select,
                  onBoardChanged: () => changes.value++,
                ),
              ),
            ),
          ),
        ),
      ),
    );
    final board = find.byType(TrainingBoard);
    expect(
      find.descendant(of: board, matching: find.byType(Opacity)),
      findsNothing,
    );
    final first = g.leftCards.first!,
        partner = g.cards.singleWhere(
          (c) => c.pairId == first.pairId && c.id != first.id,
        );
    final stale = t
        .widget<TrainingWordCard>(find.byKey(ValueKey(first.id)))
        .onPressed;
    await t.tap(find.byKey(ValueKey(first.id)));
    await t.pump();
    await t.tap(find.byKey(ValueKey(partner.id)));
    await t.pump();
    expect(g.matchedCount, 1);
    expect(
      t.widget<TrainingWordCard>(find.byKey(ValueKey(first.id))).completed,
      isTrue,
    );
    final next = g.leftCards.firstWhere((c) => c != null && g.isActive(c.id))!;
    final mate = g.cards.singleWhere(
      (c) => c.pairId == next.pairId && c.id != next.id,
    );
    await t.tap(find.byKey(ValueKey(next.id)));
    await t.pump();
    await t.tap(find.byKey(ValueKey(mate.id)));
    await t.pump();
    expect(g.matchedCount, 2);
    await t.pump(const Duration(milliseconds: 100));
    await t.pump(const Duration(milliseconds: 900));
    await t.pump();
    expect(g.transitions, isEmpty);
    expect(g.cards.any((c) => c.id == first.id), isFalse);
    final incoming = g.leftCards.first!;
    await t.tap(find.byKey(ValueKey(incoming.id)));
    await t.pump();
    expect(g.selectedCardId, incoming.id);
    stale();
    expect(g.matchedCount, 2);
    expect(g.selectedCardId, incoming.id);
    expect(g.debugValidate(), isTrue);
    await t.pumpWidget(const SizedBox());
    changes.dispose();
    await t.pump(const Duration(seconds: 1));
    expect(t.takeException(), isNull);
    expect(t.binding.transientCallbackCount, 0);
  });
}
