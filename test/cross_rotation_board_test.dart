import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:word_journey/app/app_theme.dart';
import 'package:word_journey/app/motion_preferences.dart';
import 'package:word_journey/features/training/logic/matching_engine.dart';
import 'package:word_journey/features/training/model/matching_card.dart';
import 'package:word_journey/features/training/widgets/training_board.dart';
import 'package:word_journey/features/training/widgets/training_word_card.dart';

import 'features/training/matching_engine_test.dart' as h;

Finder card(MatchingCard c) => find.byKey(ValueKey(c.id));
Finder slot(BoardSlot s) =>
    find.byKey(ValueKey('slot-${s.left ? 'left' : 'right'}-${s.row}'));

Future<ValueNotifier<int>> mountBoard(
  WidgetTester t,
  MatchingEngine g, {
  bool tickers = true,
  bool minimal = false,
  ValueNotifier<bool>? pause,
}) async {
  final changes = ValueNotifier(0);
  addTearDown(() async {
    await t.pumpWidget(const SizedBox());
    changes.dispose();
  });
  await t.pumpWidget(
    MaterialApp(
      theme: AppTheme.dark,
      home: Scaffold(
        body: Center(
          child: SizedBox(
            width: 350,
            child: LocalMotionScope(
              motion: minimal ? 'minimal' : 'full',
              child: TickerMode(
                enabled: tickers,
                child: TrainingBoard(
                  pause: pause,
                  game: g,
                  cardHeight: 60,
                  errors: const {},
                  changes: changes,
                  onSelect: (id) {
                    g.select(id);
                    changes.value++;
                  },
                  onBoardChanged: () => changes.value++,
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await t.pumpAndSettle();
  return changes;
}

Future<MatchingCard> solve(WidgetTester t, MatchingEngine g) async {
  final c = h.playable(g).first, mate = h.mate(g, h.playable(g).first);
  await t.tap(card(c));
  await t.pump();
  await t.tap(card(mate));
  await t.pump();
  return c;
}

double opacity(WidgetTester t, BoardSlot s) => t
    .widget<TrainingWordCard>(
      find.descendant(of: slot(s), matching: find.byType(TrainingWordCard)),
    )
    .surfaceOpacity
    .value;

void main() {
  testWidgets(
    'Crossed translations share glyph opacity/input and revoke old B surface fade',
    (t) async {
      final g = h.makeGame(visible: 5);
      await mountBoard(t, g);
      final a = await solve(t, g);
      final aSlot = g.slotIdOf(a.id)!;
      await t.pump(const Duration(milliseconds: 140));
      await t.pump();
      await t.pump(const Duration(milliseconds: 360));
      final beforeAcceleration = opacity(t, aSlot);
      final b = await solve(t, g),
          bSlot = g.slotIdOf(b.id)!,
          plan = g.transitions.single;
      expect(
        opacity(t, aSlot),
        beforeAcceleration,
        reason: 'Retarget from current opacity without a jump.',
      );
      await t.pump(const Duration(milliseconds: 660));
      await t.pump();
      for (final c in plan.incoming.values) {
        expect(t.widget<TrainingWordCard>(card(c)).enabled, isFalse);
      }
      for (var frame = 0; frame < 10; frame++) {
        await t.pump(const Duration(milliseconds: 16));
        for (final c in plan.incoming.values.where(
          (c) => c.language == CardLanguage.english,
        )) {
          final word = t.widget<TrainingWordCard>(card(c));
          final translation = t.widget<TrainingWordCard>(card(h.mate(g, c)));
          expect(word.textOpacity, same(translation.textOpacity));
          expect(word.enabled, translation.enabled);
        }
      }
      final newB = g.cardAt(bSlot)!;
      expect(t.widget<TrainingWordCard>(card(newB)).enabled, isTrue);
      expect(t.widget<TrainingWordCard>(card(newB)).completed, isFalse);
      expect(
        opacity(t, bSlot),
        1,
        reason: 'The new unmatched instance cannot continue old B fade-out.',
      );
      expect(
        t.widget<TrainingWordCard>(card(newB)).surfaceOpacity,
        isNot(
          same(
            t.widget<TrainingWordCard>(card(g.cardAt(aSlot)!)).surfaceOpacity,
          ),
        ),
      );
      await t.tap(card(newB));
      await t.pump();
      expect(g.selectedCardId, newB.id);
      final published = h.board(g);
      await t.pump(const Duration(seconds: 5));
      await t.pump();
      expect(
        h.board(g),
        published,
        reason: 'Old B decoration cannot reissue its words.',
      );
      expect(t.widget<TrainingWordCard>(card(newB)).enabled, isTrue);
      expect(t.widget<TrainingWordCard>(card(newB)).textOpacity.value, 1);
      expect(opacity(t, bSlot), 1);
      h.valid(g);
      expect(t.takeException(), isNull);
    },
  );

  testWidgets(
    'Pause freezes both surface and text; resume continues from the same opacity',
    (t) async {
      final g = h.makeGame(), pause = ValueNotifier(false);
      addTearDown(pause.dispose);
      await mountBoard(t, g, pause: pause);
      final a = await solve(t, g), aSlot = g.slotIdOf(a.id)!;
      await t.pump(const Duration(milliseconds: 140));
      await t.pump();
      await t.pump(const Duration(milliseconds: 1000));
      final before = h.board(g), surface = opacity(t, aSlot);
      final glyphs = t.widget<TrainingWordCard>(card(a)).textOpacity.value;
      pause.value = true;
      await t.pump(const Duration(seconds: 10));
      expect(h.board(g), before);
      expect(opacity(t, aSlot), surface);
      expect(t.widget<TrainingWordCard>(card(a)).textOpacity.value, glyphs);
      pause.value = false;
      await t.pump();
      expect(opacity(t, aSlot), surface);
      expect(t.widget<TrainingWordCard>(card(a)).textOpacity.value, glyphs);
      final active = h.playable(g).first;
      await t.tap(card(active));
      await t.pump();
      expect(g.selectedCardId, active.id);
      await t.pump(const Duration(milliseconds: 3260));
      await t.pump();
      expect(g.cards.any((c) => c.id == a.id), isFalse);
      await t.pump(const Duration(milliseconds: 600));
      h.valid(g);
      expect(t.takeException(), isNull);
    },
  );

  for (final visible in [4, 5]) {
    testWidgets(
      '$visible: success stays mint while A slowly fades, then fallback fills exactly A',
      (t) async {
        final g = h.makeGame(visible: visible);
        await mountBoard(t, g);
        final geometry = t.widget<Column>(
          find
              .descendant(
                of: find.byType(TrainingBoard),
                matching: find.byType(Column),
              )
              .first,
        );
        final before = h.board(g), a = await solve(t, g);
        final aSlot = before.keys.singleWhere((s) => before[s]?.id == a.id);
        final fixedCard = h.playable(g).first;
        final fixedWidget = t.widget<TrainingWordCard>(card(fixedCard));
        expect(
          t
              .widget<InkWell>(
                find.descendant(of: card(a), matching: find.byType(InkWell)),
              )
              .onTap,
          isNull,
        );
        await t.pump(const Duration(milliseconds: 139));
        expect(opacity(t, aSlot), 1);
        await t.pump(const Duration(milliseconds: 1));
        await t.pump();
        await t.pump(const Duration(milliseconds: 1275));
        expect(opacity(t, aSlot), inExclusiveRange(0, 1));
        final surface = t
            .widgetList<Material>(
              find.descendant(of: card(a), matching: find.byType(Material)),
            )
            .last;
        expect(surface.color, TrainerColors.dark.success);
        expect(t.widget<TrainingWordCard>(card(fixedCard)), same(fixedWidget));
        expect(
          t.widget<Column>(
            find
                .descendant(
                  of: find.byType(TrainingBoard),
                  matching: find.byType(Column),
                )
                .first,
          ),
          same(geometry),
        );
        expect(h.board(g), before);
        await t.pump(const Duration(milliseconds: 1275));
        expect(h.board(g), before);
        expect(g.isActive(a.id), isFalse);
        await t.pump(const Duration(milliseconds: 1709));
        expect(h.board(g), before);
        expect(g.isActive(a.id), isFalse);
        await t.pump(const Duration(milliseconds: 1));
        await t.pump();
        final aSlots = before.keys
            .where((s) => before[s]?.pairId == a.pairId)
            .toList();
        final incoming = aSlots.map((s) => g.cardAt(s)!).toList();
        expect(incoming.first.isPartnerOf(incoming.last), isTrue);
        expect(g.inactivePairCount, 0);
        expect(opacity(t, aSlot), closeTo(0, .00001));
        await t.pump(const Duration(milliseconds: 300));
        expect(opacity(t, aSlot), inExclusiveRange(0, 1));
        await t.pump(const Duration(milliseconds: 300));
        expect(opacity(t, aSlot), 1);
        h.valid(g);
        expect(t.takeException(), isNull);
      },
    );

    testWidgets(
      '$visible: A+B fade and refill only four matched slots; active widgets stay fixed',
      (t) async {
        final g = h.makeGame(visible: visible);
        await mountBoard(t, g);
        final a = await solve(t, g);
        await t.pump(const Duration(milliseconds: 140));
        await t.pump();
        await t.pump(const Duration(milliseconds: 150));
        final callbacks = {
          for (final c in g.cards)
            c.id: t.widget<TrainingWordCard>(card(c)).onPressed,
        };
        final b = await solve(t, g), transition = g.transitions.single;
        expect(transition.retiringPairIds, [a.pairId, b.pairId]);
        expect(transition.slots, hasLength(4));
        final fixed = {
          for (final c in g.cards.where((c) => !g.isMatched(c.id)))
            c: (
              slot: g.slotIdOf(c.id),
              widget: t.widget<TrainingWordCard>(card(c)),
              rect: t.getRect(card(c)),
            ),
        };
        final before = h.board(g);
        await t.pump(const Duration(milliseconds: 140));
        await t.pump();
        await t.pump(const Duration(milliseconds: 519));
        expect(h.board(g), before);
        await t.pump(const Duration(milliseconds: 1));
        await t.pump();
        expect(g.transitions, isEmpty);
        expect(g.inactivePairCount, 0);
        expect(g.activePairCount, visible);
        final incoming = transition.slots.map((s) => g.cardAt(s)!).toList();
        for (final id in transition.retiringPairIds) {
          final pairSlots = transition.outgoing.entries
              .where((entry) => entry.value.pairId == id)
              .map((entry) => g.cardAt(entry.key)!)
              .toList();
          expect(pairSlots.first.isPartnerOf(pairSlots.last), isFalse);
        }
        expect(incoming.every((c) => g.isActive(c.id)), isTrue);
        callbacks[a.id]!();
        callbacks[b.id]!();
        expect(g.selectedCardId, isNull);
        await t.pump(const Duration(milliseconds: 340));
        for (final entry in fixed.entries) {
          expect(g.slotIdOf(entry.key.id), entry.value.slot);
          expect(
            t.widget<TrainingWordCard>(card(entry.key)),
            same(entry.value.widget),
          );
          expect(t.getRect(card(entry.key)), entry.value.rect);
          expect(opacity(t, entry.value.slot!), 1);
        }
        await t.tap(card(fixed.keys.first));
        await t.pump();
        expect(g.selectedCardId, fixed.keys.first.id);
        expect(find.byType(AnimatedPositioned), findsNothing);
        h.valid(g);
        expect(t.takeException(), isNull);
      },
    );
  }

  testWidgets(
    'Rapid A→B→C→D accepts unrelated pairs and refills A+B then C+D',
    (t) async {
      final g = h.makeGame(visible: 5);
      await mountBoard(t, g);
      final a = await solve(t, g);
      await t.pump(const Duration(milliseconds: 140));
      final b = await solve(t, g), first = g.transitions.single;
      final c = await solve(t, g);
      expect(g.matchedCount, 3);
      expect(g.transitions.single.retiringPairIds, first.retiringPairIds);
      await t.pump(const Duration(milliseconds: 140));
      await t.pump(const Duration(milliseconds: 520));
      await t.pump();
      expect(g.cards.any((x) => x.pairId == a.pairId), isFalse);
      expect(g.cards.any((x) => x.pairId == b.pairId), isFalse);
      expect(g.transitions, isEmpty);
      expect(g.isMatched(c.id), isTrue);
      expect(g.inactivePairCount, 1);
      // Use an already visible untouched pair while A+B are still appearing.
      final untouched = h.playable(g).last;
      await t.tap(card(untouched));
      await t.pump();
      await t.tap(card(h.mate(g, untouched)));
      await t.pump();
      expect(g.matchedCount, 4);
      expect(g.transitions.single.retiringPairIds, [
        c.pairId,
        untouched.pairId,
      ]);
      await t.pump(const Duration(milliseconds: 140));
      await t.pump(const Duration(milliseconds: 520));
      await t.pump();
      expect(g.cards.any((x) => x.pairId == c.pairId), isFalse);
      expect(g.inactivePairCount, 0);
      h.valid(g);
    },
  );

  testWidgets(
    'Reduced motion and paused tickers cannot stall refill deadlines',
    (t) async {
      for (final minimal in [false, true]) {
        final g = h.makeGame();
        await mountBoard(t, g, tickers: false, minimal: minimal);
        final a = await solve(t, g);
        await t.pump(const Duration(milliseconds: 140));
        expect(
          t.widget<TrainingWordCard>(card(a)).textOpacity.value,
          greaterThan(0),
        );
        final b = await solve(t, g);
        await t.pump(const Duration(milliseconds: 520));
        await t.pump(const Duration(milliseconds: 340));
        await t.pump();
        expect(g.transitions, isEmpty);
        expect(g.inactivePairCount, 0);
        expect(g.cards.any((c) => c.id == b.id), isFalse);
        h.valid(g);
      }
    },
  );

  testWidgets(
    'Refill accepts readable cards; stale animation ticks cannot unlock a match',
    (t) async {
      final g = h.makeGame(visible: 5);
      await mountBoard(t, g);
      await solve(t, g);
      await t.pump(const Duration(milliseconds: 140));
      await solve(t, g);
      final transition = g.transitions.single;
      await t.pump(const Duration(milliseconds: 140));
      await t.pump(const Duration(milliseconds: 520));
      await t.pump();
      final incoming = transition.slots.map((s) => g.cardAt(s)!).first;
      final callback = t.widget<TrainingWordCard>(card(incoming)).onPressed;
      expect(t.widget<TrainingWordCard>(card(incoming)).enabled, isFalse);
      callback();
      expect(g.selectedCardId, isNull);
      await t.pump(const Duration(milliseconds: 170));
      expect(t.widget<TrainingWordCard>(card(incoming)).enabled, isTrue);
      callback();
      await t.pump();
      expect(g.selectedCardId, incoming.id);
      await t.tap(card(h.mate(g, incoming)));
      await t.pump();
      expect(g.matchedCount, 3);
      await t.pump(const Duration(milliseconds: 400));
      callback();
      expect(g.isMatched(incoming.id), isTrue);
      expect(g.selectedCardId, isNull);
      expect(t.widget<TrainingWordCard>(card(incoming)).enabled, isFalse);
      expect(g.matchedCount, 3);
      h.valid(g);
      expect(t.takeException(), isNull);
    },
  );

  testWidgets('Session end and disposal cancel all pending refill callbacks', (
    t,
  ) async {
    final g = h.makeGame();
    final changes = await mountBoard(t, g);
    await solve(t, g);
    await t.pump(const Duration(milliseconds: 140));
    await solve(t, g);
    final before = h.board(g);
    g.expireTimeLimit();
    changes.value++;
    await t.pump(const Duration(seconds: 2));
    expect(h.board(g), before);
    expect(g.transitions, isEmpty);
    await t.pumpWidget(const SizedBox());
    await t.pump(const Duration(seconds: 1));
    expect(t.binding.transientCallbackCount, 0);
    expect(t.takeException(), isNull);
  });
}
