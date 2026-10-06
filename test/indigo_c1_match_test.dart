import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:word_journey/app/app_theme.dart';
import 'package:word_journey/features/profile/cefr_level.dart';
import 'package:word_journey/features/review/adaptive_word_scheduler.dart';
import 'package:word_journey/features/training/logic/matching_engine.dart';
import 'package:word_journey/features/training/model/session_config.dart';
import 'package:word_journey/features/training/screens/training_game_screen.dart';
import 'package:word_journey/features/training/widgets/training_word_card.dart';
import 'package:word_journey/features/vocabulary/vocabulary_repository.dart';

void main() {
  for (final width in [320.0, 393.0]) {
    for (final pairs in [4, 5]) {
      for (final scale in [1.0, 1.3, 1.5]) {
        for (final dark in [false, true]) {
          testWidgets('Longest C1 Match $width/$pairs/$scale dark=$dark', (
            t,
          ) async {
            t.view.devicePixelRatio = 1;
            t.view.physicalSize = Size(width, 873);
            addTearDown(t.view.reset);
            final r = await VocabularyRepository.load();
            final concepts =
                r.concepts.where((c) => c.cefrLevel == CefrLevel.c1).toList()
                  ..sort(
                    (a, b) => b.russian.length.compareTo(a.russian.length),
                  );
            final compatible = AdaptiveWordScheduler().compatible(concepts);
            final g = MatchingEngine.start(
              words: compatible.map((c) => c.toWordPair()).toList(),
              config: SessionConfig(
                visiblePairs: pairs,
                wordPoolSize: 20,
                targetMatches: 60,
                maxMistakes: 5,
                timeLimitSeconds: 120,
                mode: SessionMode.timed,
              ),
              random: Random(31),
            );
            await t.pumpWidget(
              MaterialApp(
                theme: dark ? AppTheme.dark : AppTheme.light,
                builder: (c, child) => MediaQuery(
                  data: MediaQuery.of(c)
                      .copyWith(textScaler: TextScaler.linear(scale)),
                  child: child!,
                ),
                home: TrainingGameScreen(game: g),
              ),
            );
            await t.pumpAndSettle();
            expect(t.takeException(), isNull);
            expect(find.byType(FittedBox), findsNothing);
            expect(find.byType(TrainingWordCard), findsNWidgets(pairs * 2));
            final card = g.leftCards.first!;
            final mate = g.cards.firstWhere(
              (c) => c.pairId == card.pairId && c.id != card.id,
            );
            for (final c in [card, mate]) {
              final f = find.byKey(ValueKey(c.id));
              await t.ensureVisible(f);
              await t.pump();
              await t.tap(f);
              await t.pump();
            }
            expect(g.matchedCount, 1);
            await t.pumpAndSettle();
            expect(t.takeException(), isNull);
            await t.pumpWidget(const SizedBox());
          });
        }
      }
    }
  }
}
