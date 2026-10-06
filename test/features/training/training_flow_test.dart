import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:word_journey/app/app_theme.dart';
import 'package:word_journey/features/training/widgets/pair_count_selector.dart';
import 'package:word_journey/features/training/logic/matching_engine.dart';
import 'package:word_journey/features/training/model/matching_card.dart';
import 'package:word_journey/features/training/model/match_flow_models.dart';
import 'package:word_journey/features/training/model/session_config.dart';
import 'package:word_journey/features/training/model/test_words.dart';
import 'package:word_journey/features/training/screens/training_game_screen.dart';
import 'package:word_journey/features/training/screens/training_setup_screen.dart';
import 'package:word_journey/features/training/widgets/training_word_card.dart';
import 'package:word_journey/features/training/widgets/training_progress_header.dart';

Finder cardFinder(MatchingCard c) => find.byKey(ValueKey(c.id));
MatchingCard partner(MatchingEngine g, MatchingCard c) => g.cards.singleWhere(
  (other) => other.pairId == c.pairId && other.id != c.id,
);
List<MatchingCard> playable(MatchingEngine g) => g.leftCards
    .whereType<MatchingCard>()
    .where((c) => g.isActive(c.id) && g.isActive(partner(g, c).id))
    .toList();
MatchingEngine currentGame(WidgetTester tester) =>
    tester.widget<TrainingGameScreen>(find.byType(TrainingGameScreen)).game;
double shownProgress(WidgetTester tester) =>
    tester.widget<CapsuleProgress>(find.byType(CapsuleProgress)).value;
MatchingEngine seededGame({int count = 4, int target = 30, int? time}) =>
    MatchingEngine.start(
      words: testWords,
      random: Random(42),
      config: SessionConfig(
        visiblePairs: count,
        wordPoolSize: 20,
        targetMatches: target,
        maxMistakes: 5,
        timeLimitSeconds: time,
        mode: time == null ? SessionMode.practice : SessionMode.timed,
      ),
    );
Future<void> showGame(WidgetTester tester, MatchingEngine game) =>
    tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        home: TrainingGameScreen(game: game),
      ),
    );
Future<void> tapVisible(WidgetTester tester, Finder finder) async {
  if (finder.evaluate().isEmpty) {
    await tester.scrollUntilVisible(
      finder,
      100,
      scrollable: find.byType(Scrollable).first,
    );
  }
  await Scrollable.ensureVisible(tester.element(finder), alignment: .5);
  await tester.pump();
  await tester.tap(finder);
  await tester.pump();
}

Future<void> openTraining(WidgetTester tester, int count) async {
  addTearDown(() => tester.pumpWidget(const SizedBox.shrink()));
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      home: const TrainingSetupScreen(),
    ),
  );
  await tester.pumpAndSettle();
  expect(
    tester.widget<PairCountSelector>(find.byType(PairCountSelector)).value,
    4,
  );
  await tapVisible(tester, find.byKey(ValueKey('pairs-$count')));
  expect(
    tester.widget<PairCountSelector>(find.byType(PairCountSelector)).value,
    count,
  );
  await tapVisible(tester, find.text('Начать тренировку'));
  await tester.pumpAndSettle();
  expect(currentGame(tester).visiblePairCount, count);
}

Future<void> solveOne(WidgetTester tester, MatchingEngine game) async {
  if (game.selectedCardId case final id?) {
    await tapVisible(tester, find.byKey(ValueKey(id)));
  }
  final first = playable(game).first;
  final other = partner(game, first);
  await tapVisible(tester, cardFinder(first));
  await tapVisible(tester, cardFinder(other));
}

Future<void> finishSession(WidgetTester tester, MatchingEngine game) async {
  await tester.pumpAndSettle();
  while (game.matchedCount < game.totalPairCount) {
    final before = game.matchedCount;
    await solveOne(tester, game);
    expect(game.matchedCount, before + 1);
    expect(game.debugValidate(), isTrue);
    await tester.pumpAndSettle();
  }
  expect(game.isComplete, isTrue);
  expect(game.result?.targetReached, isTrue);
}

void main() {
  testWidgets('Setup offers only four and five pairs; four is the default', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(theme: AppTheme.light, home: const TrainingSetupScreen()),
    );
    await tester.pumpAndSettle();
    final choices = tester.widget<PairCountSelector>(
      find.byType(PairCountSelector),
    );
    expect(find.byKey(const ValueKey('pairs-4')), findsOneWidget);
    expect(find.byKey(const ValueKey('pairs-5')), findsOneWidget);
    expect(choices.value, 4);
    expect(find.text('3'), findsNothing);
  });
  for (final count in [4, 5]) {
    testWidgets('$count pairs complete a session, replay and return to setup', (
      tester,
    ) async {
      await openTraining(tester, count);
      final g = currentGame(tester);
      expect(g.wordPool, hasLength(12));
      expect(find.byType(TrainingWordCard), findsNWidgets(count * 2));
      expect(find.byType(TrainingProgressHeader), findsOneWidget);
      expect(find.text('English'), findsNothing);
      expect(find.text('Русский'), findsNothing);
      await finishSession(tester, g);
      expect(find.text('60 / 60'), findsOneWidget);
      await tapVisible(tester, find.text('Ещё раз'));
      await tester.pumpAndSettle();
      final replay = currentGame(tester);
      expect(replay, isNot(same(g)));
      expect(replay.visiblePairCount, count);
      expect(replay.inactivePairCount, 0);
      expect(shownProgress(tester), 0);
      await finishSession(tester, replay);
      await tapVisible(tester, find.text('К настройке'));
      await tester.pumpAndSettle();
      expect(find.byType(TrainingSetupScreen), findsOneWidget);
      expect(
        tester.widget<PairCountSelector>(find.byType(PairCountSelector)).value,
        count,
      );
      expect(tester.takeException(), isNull);
    });
  }
  testWidgets(
    'Correct state is instant, has no bounce and cannot count twice',
    (tester) async {
      final g = seededGame();
      await showGame(tester, g);
      await tester.pumpAndSettle();
      final first = playable(g).first;
      final other = partner(g, first);
      final position = tester.getRect(cardFinder(first));
      await solveOne(tester, g);
      expect(g.matchedCount, 1);
      expect(
        tester.widget<TrainingWordCard>(cardFinder(first)).completed,
        isTrue,
      );
      expect(
        tester.widget<TrainingWordCard>(cardFinder(other)).completed,
        isTrue,
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 75));
      final scales = tester
          .widgetList<Transform>(
            find.descendant(
              of: cardFinder(first),
              matching: find.byType(Transform),
            ),
          )
          .map((w) => w.transform.entry(0, 0));
      expect(scales.every((s) => s <= 1), isTrue);
      expect(tester.getRect(cardFinder(first)), position);
      final gesture = tester.widget<GestureDetector>(
        find.descendant(
          of: cardFinder(first),
          matching: find.byType(GestureDetector),
        ),
      );
      expect(gesture.onTap, isNull);
      final visual = tester
          .widget<TrainingWordCard>(cardFinder(first))
          .flowVisual!;
      expect(visual.successTint, 1);
      expect(visual.textOpacity, 1);
      await tester.tap(cardFinder(first), warnIfMissed: false);
      await tester.tap(cardFinder(other), warnIfMissed: false);
      expect(g.matchedCount, 1);
      await tester.pump(const Duration(milliseconds: 5000));
      await tester.pumpAndSettle();
      expect(g.cards.any((c) => c.id == first.id), isFalse);
      expect(g.transitions, isEmpty);
      expect(g.selectedCardId, isNull);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'A returns first, B waits for C, and untouched slots stay fixed',
    (tester) async {
      final g = seededGame(count: 5);
      await showGame(tester, g);
      await tester.pumpAndSettle();
      final a = playable(g).first, aMate = partner(g, a);
      final aSlot = g.slotIdOf(a.id)!, aMateSlot = g.slotIdOf(aMate.id)!;
      await solveOne(tester, g);
      await tester.pump(const Duration(milliseconds: 500));
      final b = playable(g).first, bMate = partner(g, b);
      final bSlot = g.slotIdOf(b.id)!, bMateSlot = g.slotIdOf(bMate.id)!;
      await solveOne(tester, g);
      expect(g.inactivePairCount, 2);
      final flow = g.matchFlow!;
      final fixed = {
        for (final c in g.cards.where((c) => ![a, aMate, b, bMate].contains(c)))
          c: (
            rect: tester.getRect(cardFinder(c)),
            widget: tester.widget<TrainingWordCard>(cardFinder(c)),
          ),
      };
      await tester.pump(const Duration(milliseconds: 850));
      final incoming = g.cardAt(aSlot)!, incomingOther = g.cardAt(aMateSlot)!;
      expect(incoming.id, isNot(a.id));
      expect(incoming.conceptId, isNot(incomingOther.conceptId));
      expect(
        flow.stateOf(aSlot).value.visual.textOpacity,
        inExclusiveRange(0, 1),
      );
      expect(g.cardAt(bSlot), same(b));
      expect(g.cardAt(bMateSlot), same(bMate));
      expect(g.isMatched(b.id), isTrue);
      await tester.pump(const Duration(milliseconds: 150));
      expect(flow.stateOf(aSlot).value.visual.textOpacity, 1);
      expect(
        flow.stateOf(aSlot).value.visual.state,
        MatchVisualState.waitingPartner,
      );
      expect(g.isActive(incoming.id), isFalse);
      await tester.tap(cardFinder(incoming), warnIfMissed: false);
      await tester.pump();
      expect(g.selectedCardId, isNull);
      for (final entry in fixed.entries) {
        expect(tester.getRect(cardFinder(entry.key)), entry.value.rect);
        expect(
          tester.widget<TrainingWordCard>(cardFinder(entry.key)),
          same(entry.value.widget),
        );
      }
      final bOpacity = flow.stateOf(bSlot).value.visual.textOpacity;
      final third = playable(g).first;
      fixed.remove(third);
      fixed.remove(partner(g, third));
      await solveOne(tester, g);
      expect(g.matchedCount, 3);
      expect(flow.stateOf(bSlot).value.visual.textOpacity, bOpacity);
      await tester.pump(const Duration(milliseconds: 720));
      final mate = partner(g, incoming);
      expect(g.isActive(incoming.id), isTrue);
      expect(g.isActive(mate.id), isTrue);
      expect(
        flow.stateOf(g.slotIdOf(mate.id)!).value.visual.textOpacity,
        greaterThanOrEqualTo(.6),
      );
      await tapVisible(tester, cardFinder(incoming));
      expect(g.selectedCardId, incoming.id);
      await tester.pump(const Duration(milliseconds: 4000));
      expect(g.cardAt(aSlot), same(incoming));
      expect(g.isActive(incoming.id), isTrue);
      expect(g.selectedCardId, incoming.id);
      for (final entry in fixed.entries) {
        expect(g.cards.contains(entry.key), isTrue);
        expect(tester.getRect(cardFinder(entry.key)), entry.value.rect);
        expect(
          tester.widget<TrainingWordCard>(cardFinder(entry.key)),
          same(entry.value.widget),
        );
      }
      await tester.pumpAndSettle();
      expect(g.debugValidate(), isTrue);
      expect(find.byType(AnimatedPositioned), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Fast taps and old widget callbacks do not count inactive pairs twice',
    (tester) async {
      final g = seededGame();
      await showGame(tester, g);
      await tester.pumpAndSettle();
      final first = playable(g).first;
      final other = partner(g, first);
      final oldFirst = tester
          .widget<TrainingWordCard>(cardFinder(first))
          .onPressed;
      final oldSecond = tester
          .widget<TrainingWordCard>(cardFinder(other))
          .onPressed;
      await solveOne(tester, g);
      await solveOne(tester, g);
      await solveOne(tester, g);
      expect(g.matchedCount, 3);
      oldFirst();
      oldSecond();
      expect(g.matchedCount, 3);
      await tester.pumpAndSettle();
      oldFirst();
      oldSecond();
      expect(g.matchedCount, 3);
      await finishSession(tester, g);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'Held and selected active cards retain their positions through a batch',
    (tester) async {
      final g = seededGame(count: 5);
      await showGame(tester, g);
      await tester.pumpAndSettle();
      await solveOne(tester, g);
      await tester.pumpAndSettle();
      await solveOne(tester, g);
      final selected = playable(g).first;
      final heldCard = playable(g).last;
      final positions = {
        for (final c in [selected, heldCard])
          c.id: tester.getRect(cardFinder(c)),
      };
      await tapVisible(tester, cardFinder(selected));
      final pointer = await tester.startGesture(
        tester.getCenter(cardFinder(heldCard)),
        pointer: 21,
      );
      await tester.pumpAndSettle();
      expect(g.selectedCardId, selected.id);
      for (final c in [selected, heldCard]) {
        expect(tester.getRect(cardFinder(c)), positions[c.id]);
      }
      await pointer.cancel();
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'Progress is immediate in state and smoothly rendered over 320 ms',
    (tester) async {
      final g = seededGame();
      await showGame(tester, g);
      await tester.pumpAndSettle();
      await solveOne(tester, g);
      expect(g.progress, 1 / 30);
      expect(shownProgress(tester), 0);
      await tester.pump(const Duration(milliseconds: 100));
      expect(shownProgress(tester), inExclusiveRange(0, 1 / 30));
      await tester.pump(const Duration(milliseconds: 221));
      expect(shownProgress(tester), closeTo(1 / 30, .00001));
      await tester.pumpAndSettle();
    },
  );
  testWidgets(
    'Wrong feedback keeps play available without an on-board error count',
    (tester) async {
      final g = seededGame();
      await showGame(tester, g);
      await tester.pumpAndSettle();
      final left = playable(g);
      await tapVisible(tester, cardFinder(left.first));
      await tapVisible(tester, cardFinder(partner(g, left.last)));
      expect(g.errorCount, 1);
      expect(g.selectedCardId, isNull);
      expect(find.textContaining('Ошиб'), findsNothing);
      await solveOne(tester, g);
      expect(g.matchedCount, 1);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('Exit pauses play and asks before returning to setup', (
    tester,
  ) async {
    await openTraining(tester, 4);
    await solveOne(tester, currentGame(tester));
    await tester.tap(find.byTooltip('Выйти из тренировки'));
    await tester.pumpAndSettle();
    expect(find.text('Выйти из тренировки?'), findsOneWidget);
    await tester.tap(find.text('Продолжить'));
    await tester.pumpAndSettle();
    expect(find.byType(TrainingGameScreen), findsOneWidget);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    await tester.tap(find.text('Выйти'));
    await tester.pumpAndSettle();
    expect(find.byType(TrainingSetupScreen), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  for (final count in [4, 5]) {
    testWidgets(
      '$count Lab tiles keep their typography and SafeArea in either app theme',
      (tester) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = const Size(393, 873);
        tester.view.padding = const FakeViewPadding(top: 24, bottom: 24);
        tester.view.viewPadding = const FakeViewPadding(top: 24, bottom: 24);
        addTearDown(tester.view.reset);
        addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
        await openTraining(tester, count);
        final g = currentGame(tester);
        for (final brightness in Brightness.values) {
          tester.platformDispatcher.platformBrightnessTestValue = brightness;
          await tester.pumpAndSettle();
          expect(currentGame(tester), same(g));
          for (final c in g.cards) {
            final rect = tester.getRect(cardFinder(c));
            expect(rect.height, inInclusiveRange(64, 104));
            expect(rect.top, greaterThan(24));
            expect(rect.bottom, lessThan(849));
            expect(tester.widget<Text>(find.text(c.text)).style!.fontSize, 20);
          }
          await solveOne(tester, g);
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
        }
      },
    );
  }
  for (final size in [const Size(320, 568), const Size(568, 320)]) {
    testWidgets(
      'Large text and insets fit $size throughout a complete session',
      (tester) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = size;
        tester.view.padding = const FakeViewPadding(top: 24, bottom: 34);
        tester.view.viewPadding = const FakeViewPadding(top: 24, bottom: 34);
        tester.platformDispatcher.textScaleFactorTestValue = 2;
        addTearDown(tester.view.reset);
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        await openTraining(tester, 5);
        await finishSession(tester, currentGame(tester));
        expect(find.text('60 / 60'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  }
}
