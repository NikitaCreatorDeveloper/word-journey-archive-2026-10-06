import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:word_journey/app/word_journey_app.dart';
import 'package:word_journey/features/training/logic/matching_engine.dart';
import 'package:word_journey/features/training/screens/training_game_screen.dart';
import 'package:word_journey/features/training/screens/training_result_screen.dart';
import 'package:word_journey/features/world/data/travel_content.dart';
import 'package:word_journey/features/world/model/world_content.dart';
import 'package:word_journey/features/world/screens/world_screens.dart';

import '../training/training_flow_test.dart' as flow;
import '../training/session_clock_test.dart' as clocks;

Future<void> openCafe(WidgetTester tester) async {
  addTearDown(() => tester.pumpWidget(const SizedBox.shrink()));
  await tester.pumpWidget(const WordJourneyApp());
  await tester.pumpAndSettle();
  await flow.tapVisible(tester, find.byKey(const ValueKey('atlas-marker-uk')));
  await tester.pumpAndSettle();
  expect(find.byType(CountryScreen), findsOneWidget);
  await flow.tapVisible(
    tester,
    find.byKey(const ValueKey('atlas-marker-london')),
  );
  await tester.pumpAndSettle();
  expect(find.byType(DestinationScreen), findsOneWidget);
  await flow.tapVisible(
    tester,
    find.byKey(const ValueKey('atlas-marker-london-cafe')),
  );
  await tester.pumpAndSettle();
  expect(find.byType(SituationScreen), findsOneWidget);
}

void main() {
  test(
    'Content resolves the complete World → UK → London → Café graph by ID',
    () {
      final c = travelContent;
      expect(c.world.countryIds, ['uk']);
      for (final countryId in c.world.countryIds) {
        final country = c.country(countryId);
        for (final destinationId in country.destinationIds) {
          final destination = c.destination(destinationId);
          expect(destination.countryId, country.id);
          for (final situationId in destination.situationIds) {
            final situation = c.situation(situationId);
            expect(situation.destinationId, destination.id);
            expect(c.wordsForPack(situation.wordPackId), hasLength(36));
            final config = c.sessionConfig(situation.id, visiblePairs: 5);
            expect(config.targetMatches, 60);
            expect(config.timeLimitSeconds, 120);
            expect(config.visiblePairs, 5);
          }
        }
      }
    },
  );

  test('36 unique café concepts, split into 3 semantic groups, have unique translations', () {
    final p = travelContent.wordPack('cafe-basics');
    expect(p.sections.map((s) => s.id), [
      'food-drinks',
      'ordering',
      'payment-requests',
    ]);
    expect(p.conceptIds.toSet(), hasLength(36));
    final words = travelContent.wordsForPack(p.id);
    expect(words.map((w) => w.english).toSet(), hasLength(36));
    expect(words.map((w) => w.russian).toSet(), hasLength(36));
    expect(() => words.clear(), throwsUnsupportedError);
    expect(() => p.conceptIds.clear(), throwsUnsupportedError);
  });

  test('All positions are normalized; invalid coordinates fail in debug', () {
    for (final position in [
      ...travelContent.countries.map((c) => c.mapPosition),
      ...travelContent.destinations.map((d) => d.mapPosition),
      ...travelContent.situations.map((s) => s.mapPosition),
    ]) {
      expect(position.x, inInclusiveRange(0, 1));
      expect(position.y, inInclusiveRange(0, 1));
    }
    expect(() => MapPosition(-.1, .5), throwsAssertionError);
    expect(() => MapPosition(.5, 1.1), throwsAssertionError);
  });

  for (final visible in [4, 5]) {
    test(
      'Café pool supports a complete 60-match round with $visible visible pairs',
      () {
        final words = travelContent.wordsForPack('cafe-basics');
        final game = MatchingEngine.start(
          words: words,
          random: Random(16),
          config: travelContent.sessionConfig(
            'london-cafe',
            visiblePairs: visible,
          ),
        );
        expect(game.wordPool, hasLength(20));
        expect(game.wordPool.every(words.contains), isTrue);
        while (!game.isComplete) {
          clocks.solve(game);
          clocks.drain(game);
          expect(game.debugValidate(), isTrue);
        }
        expect(game.matchedCount, 60);
      },
    );
  }

  testWidgets(
    'Map responds to pinch/pan; back restores world transform and selected tab',
    (tester) async {
      await tester.pumpWidget(const WordJourneyApp());
      await tester.pumpAndSettle();
      final viewerFinder = find.byKey(const ValueKey('atlas-viewer-world'));
      final viewer = tester.widget<InteractiveViewer>(viewerFinder);
      expect(viewer.transformationController!.value, Matrix4.identity());
      final center = tester.getCenter(viewerFinder);
      final left = await tester.startGesture(
        center - const Offset(40, 0),
        pointer: 1,
      );
      final right = await tester.startGesture(
        center + const Offset(40, 0),
        pointer: 2,
      );
      await left.moveTo(center - const Offset(75, 0));
      await right.moveTo(center + const Offset(75, 0));
      await tester.pump();
      await left.moveTo(center - const Offset(100, 0));
      await right.moveTo(center + const Offset(100, 0));
      await tester.pump();
      await left.up();
      await right.up();
      await tester.pumpAndSettle();
      expect(
        viewer.transformationController!.value.getMaxScaleOnAxis(),
        greaterThan(1),
      );
      await tester.drag(viewerFinder, const Offset(20, 30));
      await tester.pumpAndSettle();
      final transform = viewer.transformationController!.value.clone();
      await flow.tapVisible(tester, find.byKey(const ValueKey('open-uk')));
      await tester.pumpAndSettle();
      expect(find.byType(CountryScreen), findsOneWidget);
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<InteractiveViewer>(viewerFinder)
            .transformationController!
            .value,
        transform,
      );
      expect(
        tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex,
        0,
      );
      await flow.tapVisible(tester, find.byTooltip('Показать карту целиком'));
      await tester.pumpAndSettle();
      expect(viewer.transformationController!.value, Matrix4.identity());
    },
  );

  testWidgets(
    'World → UK → London → Café launches the common engine; back preserves café settings',
    (tester) async {
      await openCafe(tester);
      expect(find.text('36 понятий'), findsOneWidget);
      await flow.tapVisible(tester, find.text('5'));
      await flow.tapVisible(tester, find.byKey(const ValueKey('start-cafe')));
      await tester.pumpAndSettle();
      final game = flow.currentGame(tester);
      expect(find.byType(TrainingGameScreen), findsOneWidget);
      expect(game.visiblePairCount, 5);
      expect(game.totalPairCount, 60);
      final conceptIds = travelContent.wordPack('cafe-basics').conceptIds;
      expect(game.wordPool.every((w) => conceptIds.contains(w.id)), isTrue);
      expect(game.cards.every((c) => conceptIds.contains(c.conceptId)), isTrue);
      await tester.tap(find.byTooltip('Выйти из тренировки'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Выйти'));
      await tester.pumpAndSettle();
      expect(find.byType(SituationScreen), findsOneWidget);
      expect(
        tester
            .widget<SegmentedButton<int>>(find.byType(SegmentedButton<int>))
            .selected,
        {5},
      );
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.byType(DestinationScreen), findsOneWidget);
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.byType(CountryScreen), findsOneWidget);
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.byType(WorldScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Café win, replay and result-back keep the café pool and return to its setup',
    (tester) async {
      await openCafe(tester);
      await flow.tapVisible(tester, find.byKey(const ValueKey('start-cafe')));
      await tester.pumpAndSettle();
      final game = flow.currentGame(tester);
      await flow.finishSession(tester, game);
      expect(find.byType(TrainingResultScreen), findsOneWidget);
      expect(find.text('60 / 60'), findsOneWidget);
      await flow.tapVisible(tester, find.text('Ещё раз'));
      await tester.pumpAndSettle();
      final next = flow.currentGame(tester);
      expect(next.wordPool, game.wordPool);
      expect(next.progress, 0);
      await flow.finishSession(tester, next);
      await flow.tapVisible(tester, find.text('К настройке'));
      await tester.pumpAndSettle();
      expect(find.byType(SituationScreen), findsOneWidget);
    },
  );

  for (final brightness in Brightness.values) {
    testWidgets('Atlas path fits small screens and large text in $brightness', (
      tester,
    ) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(320, 568);
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      tester.platformDispatcher.platformBrightnessTestValue = brightness;
      addTearDown(tester.view.reset);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
      await openCafe(tester);
      await flow.tapVisible(tester, find.byKey(const ValueKey('start-cafe')));
      await tester.pumpAndSettle();
      expect(find.byType(TrainingGameScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
