import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:word_journey/features/training/logic/adaptive_refill_controller.dart';
import 'package:word_journey/features/training/logic/matching_engine.dart';
import 'package:word_journey/features/training/model/matching_card.dart';
import 'package:word_journey/features/training/model/session_result.dart';
import 'package:word_journey/features/training/widgets/training_word_card.dart';

import 'cross_rotation_board_test.dart' as w;
import 'features/training/adaptive_refill_test.dart' as a;
import 'features/training/matching_engine_test.dart' as h;

TrainingWordCard view(WidgetTester t, MatchingCard c) =>
    t.widget<TrainingWordCard>(w.card(c));

void expectInstance(MatchingEngine g, MatchingCard c, BoardSlot slot) {
  expect(g.cardAt(slot), same(c));
  expect(g.cardAt(slot)!.text, c.text);
  expect(g.cardAt(slot)!.conceptId, c.conceptId);
  expect(g.isActive(c.id), isTrue);
  expect(g.isMatched(c.id), isFalse);
}

void expectPlayable(WidgetTester t, MatchingCard c) {
  final card = view(t, c);
  expect(card.text, c.text);
  expect(card.completed, isFalse);
  expect(card.enabled, isTrue);
  expect(card.textOpacity.value, greaterThanOrEqualTo(.65));
  expect(
    t
        .widget<InkWell>(
          find.descendant(of: w.card(c), matching: find.byType(InkWell)),
        )
        .onTap,
    isNotNull,
  );
  final text = find.descendant(of: w.card(c), matching: find.text(c.text));
  expect(text, findsOneWidget);
  var effectiveOpacity = 1.0;
  t.element(text).visitAncestorElements((element) {
    final widget = element.widget;
    if (widget is FadeTransition) effectiveOpacity *= widget.opacity.value;
    if (widget is Opacity) effectiveOpacity *= widget.opacity;
    if (widget is IgnorePointer) expect(widget.ignoring, isFalse);
    return true;
  });
  expect(effectiveOpacity, greaterThanOrEqualTo(.65));
}

// Guards every rendered frame, including frames before/after publication,
// rather than waiting until timers and decorative animations have all settled.
class FrameGuard {
  FrameGuard(this.t, this.g);
  final WidgetTester t;
  final MatchingEngine g;
  final ready = <String>{};
  final surfaces = <String, double>{};

  Future<void> advance(
    int ms, {
    VoidCallback? check,
    bool paused = false,
  }) async {
    for (var remaining = ms; remaining > 0;) {
      final dt = remaining > 16 ? 16 : remaining;
      final untouched = {
        for (final c in g.cards.where((c) => g.isActive(c.id)))
          c: (slot: g.slotIdOf(c.id)!, rect: t.getRect(w.card(c))),
      };
      await t.pump(Duration(milliseconds: dt));
      remaining -= dt;
      for (final entry in untouched.entries) {
        expectInstance(g, entry.key, entry.value.slot);
        expect(t.getRect(w.card(entry.key)), entry.value.rect);
      }
      for (final c in g.cards.where((c) => g.isActive(c.id))) {
        final word = view(t, c), partner = view(t, h.mate(g, c));
        expect(word.textOpacity, same(partner.textOpacity));
        expect(word.enabled, partner.enabled);
        if (paused) {
          expect(word.enabled, isFalse);
          continue;
        }
        if (word.enabled) ready.add(c.id);
        if (!ready.contains(c.id)) continue;
        expectPlayable(t, c);
        final previous = surfaces[c.id];
        if (previous != null) {
          expect(word.surfaceOpacity.value, greaterThanOrEqualTo(previous));
        }
        surfaces[c.id] = word.surfaceOpacity.value;
      }
      h.valid(g);
      check?.call();
    }
    expect(t.takeException(), isNull);
  }

  Future<void> solveExcept(MatchingCard fixed) async {
    MatchingCard? available() => h
        .playable(g)
        .where((c) => c.pairId != fixed.pairId && view(t, c).enabled)
        .firstOrNull;
    for (var waited = 0; available() == null && waited < 6000; waited += 16) {
      await advance(16);
    }
    final c = available()!;
    final previous = g.matchedCount;
    await t.tap(w.card(c));
    await t.pump();
    await t.tap(w.card(h.mate(g, c)));
    await t.pump();
    expect(g.matchedCount, previous + 1);
  }
}

void main() {
  for (final visible in [4, 5]) {
    test(
      '$visible: a repeated concept receives a fresh instance with no old hide permission',
      () {
        final g = h.makeGame(visible: visible, pool: visible);
        var now = Duration.zero;
        final controller = AdaptiveRefillController(g, now: () => now);
        addTearDown(controller.dispose);
        h.match(g, h.playable(g).first);
        controller.synchronize();
        now = const Duration(milliseconds: 500);
        h.match(g, h.playable(g).first);
        controller.synchronize();
        final plan = g.transitions.single;
        final outgoing = plan.outgoing.values.toList();
        now = const Duration(milliseconds: 1500);
        controller.synchronize();
        final after = h.board(g);
        for (final entry in plan.incoming.entries) {
          expect(
            outgoing.any((c) => c.conceptId == entry.value.conceptId),
            isTrue,
          );
          expect(outgoing.any((c) => c.id == entry.value.id), isFalse);
          expectInstance(g, entry.value, entry.key);
          expect(controller.visualFor(entry.key).opacity, 1);
        }
        for (final old in outgoing) {
          g.settlePair(old.pairId);
          g.select(old.id);
        }
        g.commitTransition(plan.token);
        g.completeTransition(plan.token);
        now = const Duration(seconds: 15);
        controller.synchronize();
        expect(h.board(g), after);
        for (final entry in plan.incoming.entries) {
          expectInstance(g, entry.value, entry.key);
          expect(controller.visualFor(entry.key), activeRefillVisual);
        }
        h.valid(g);
      },
    );

    testWidgets(
      '$visible: reaching 60/60 cancels pending fades and stale callbacks',
      (t) async {
        final g = h.makeGame(visible: visible);
        final changes = await w.mountBoard(t, g);
        final guard = FrameGuard(t, g);
        final stale = <VoidCallback>[];
        var ticks = 0;
        while (!g.isComplete && ticks++ < 1500) {
          final active = h
              .playable(g)
              .where((c) => view(t, c).enabled)
              .firstOrNull;
          if (active != null) {
            stale.add(view(t, active).onPressed);
            await t.tap(w.card(active));
            await t.pump();
            await t.tap(w.card(h.mate(g, active)));
            await t.pump();
          }
          await guard.advance(170);
        }
        expect(g.matchedCount, 60);
        final result = g.endSession(
          reason: SessionEndReason.targetReached,
          elapsedTime: Duration(milliseconds: ticks * 170),
          remainingTime: Duration.zero,
        );
        changes.value++;
        final before = h.board(g);
        for (final callback in stale) {
          callback();
        }
        await guard.advance(10000);
        expect(h.board(g), before);
        expect(g.result, same(result));
        expect(g.result!.completedMatches, 60);
        expect(g.transitions, isEmpty);
        await t.pumpWidget(const SizedBox());
        await t.pump(const Duration(seconds: 1));
        expect(t.binding.transientCallbackCount, 0);
        expect(t.takeException(), isNull);
      },
    );

    test(
      '$visible: engine keeps untouched X through mixed tempo, errors and old tokens',
      () {
        final f = a.Fixture(visible: visible, target: 160);
        final x = h.playable(f.game).last, translation = h.mate(f.game, x);
        final fixed = {
          x: f.game.slotIdOf(x.id)!,
          translation: f.game.slotIdOf(translation.id)!,
        };
        final stale = <BoardTransition>[];
        for (var cycle = 0; cycle < 16; cycle++) {
          final c = h.playable(f.game).firstWhere((c) => c.pairId != x.pairId);
          f.match(c);
          f.advance(500);
          final available = h
              .playable(f.game)
              .where((c) => c.pairId != x.pairId)
              .toList();
          f.game.select(available.first.id);
          expect(f.game.select(translation.id), MatchFeedback.incorrect);
          f.controller.synchronize();
          f.match(available.first);
          stale.addAll(f.game.transitions);
          // Selection changes only on input, never on another pair's refill.
          f.game.select(x.id);
          f.advance(cycle.isEven ? 1000 : 5500);
          for (final plan in stale) {
            f.game.commitTransition(plan.token);
            f.game.completeTransition(plan.token);
            for (final id in plan.retiringPairIds) {
              f.game.settlePair(id);
            }
          }
          f.controller.synchronize();
          expect(f.game.selectedCardId, x.id);
          for (final entry in fixed.entries) {
            expectInstance(f.game, entry.key, entry.value);
            expect(f.controller.visualFor(entry.value), activeRefillVisual);
            expect(f.controller.textVisualFor(entry.value), activeRefillVisual);
          }
        }
        f.advance(12000);
        for (final entry in fixed.entries) {
          expectInstance(f.game, entry.key, entry.value);
        }
      },
    );

    testWidgets(
      '$visible: untouched X stays visible and tappable in every mixed-tempo frame',
      (t) async {
        final g = h.makeGame(visible: visible, target: 160);
        await w.mountBoard(t, g);
        final guard = FrameGuard(t, g);
        final x = h.playable(g).last, translation = h.mate(g, x);
        final fixed = {
          x: (
            slot: g.slotIdOf(x.id)!,
            rect: t.getRect(w.card(x)),
            widget: view(t, x),
          ),
          translation: (
            slot: g.slotIdOf(translation.id)!,
            rect: t.getRect(w.card(translation)),
            widget: view(t, translation),
          ),
        };
        void checkX() {
          for (final entry in fixed.entries) {
            expectInstance(g, entry.key, entry.value.slot);
            expectPlayable(t, entry.key);
            expect(view(t, entry.key), same(entry.value.widget));
            expect(t.getRect(w.card(entry.key)), entry.value.rect);
            expect(view(t, entry.key).textOpacity.value, 1);
            expect(view(t, entry.key).surfaceOpacity.value, 1);
          }
        }

        for (var cycle = 0; cycle < 3; cycle++) {
          await guard.solveExcept(x);
          await guard.advance(500, check: checkX);
          await guard.solveExcept(x);
          await guard.advance(1200, check: checkX);
          final wrong = h
              .playable(g)
              .where((c) => c.pairId != x.pairId)
              .toList();
          final errors = g.errorCount;
          await t.tap(w.card(wrong.first));
          await t.pump();
          await t.tap(w.card(h.mate(g, wrong.last)));
          await t.pump();
          expect(g.errorCount, errors + 1);
          await guard.advance(300, check: checkX);
          await guard.solveExcept(x);
          await guard.advance(5200, check: checkX);
        }
        await guard.advance(6000, check: checkX);
        // Both sides still accept real widget-test gestures after many refills.
        await t.tap(w.card(x));
        await t.pump();
        expect(g.selectedCardId, x.id);
        await t.tap(w.card(translation));
        await t.pump();
        expect(g.isMatched(x.id), isTrue);
      },
    );

    testWidgets(
      '$visible: selected new word survives foreign refill, pause and old deadlines',
      (t) async {
        final g = h.makeGame(visible: visible), pause = ValueNotifier(false);
        addTearDown(pause.dispose);
        await w.mountBoard(t, g, pause: pause);
        final guard = FrameGuard(t, g);
        await w.solve(t, g);
        await guard.advance(500);
        final b = await w.solve(t, g), bSlot = g.slotIdOf(b.id)!;
        await guard.advance(1000);
        final selected = g.cardAt(bSlot)!, partner = h.mate(g, selected);
        // Schedule an unrelated solo fallback before selecting the new instance.
        await guard.solveExcept(selected);
        await t.tap(w.card(selected));
        await t.pump();
        final fixed = {
          selected: g.slotIdOf(selected.id)!,
          partner: g.slotIdOf(partner.id)!,
        };
        void checkSelection() {
          expect(g.selectedCardId, selected.id);
          expect(view(t, selected).selected, isTrue);
          for (final entry in fixed.entries) {
            expectInstance(g, entry.key, entry.value);
            expectPlayable(t, entry.key);
          }
        }

        await guard.advance(700, check: checkSelection);
        final surface = view(t, selected).surfaceOpacity.value,
            glyph = view(t, selected).textOpacity.value,
            before = h.board(g);
        pause.value = true;
        await guard.advance(10000, paused: true);
        expect(h.board(g), before);
        expect(g.selectedCardId, selected.id);
        expect(view(t, selected).surfaceOpacity.value, surface);
        expect(view(t, selected).textOpacity.value, glyph);
        pause.value = false;
        await t.pump();
        await guard.advance(10000, check: checkSelection);
        await t.tap(w.card(partner));
        await t.pump();
        expect(g.isMatched(selected.id), isTrue);
      },
    );

    testWidgets(
      '$visible: fallback/acceleration boundary and rapid A→B→C→D preserve each active instance',
      (t) async {
        final g = h.makeGame(visible: visible, target: 160);
        final changes = await w.mountBoard(t, g);
        final guard = FrameGuard(t, g), x = h.playable(g).last;
        for (final at in [3999, 4399, 4400, 4401]) {
          await guard.solveExcept(x);
          await guard.advance(at);
          await guard.solveExcept(x);
          await guard.advance(6000);
          expectPlayable(t, x);
        }
        for (var i = 0; i < 4; i++) {
          await guard.solveExcept(x);
          await guard.advance(170);
        }
        await guard.advance(6000);
        expectPlayable(t, x);
        final before = h.board(g), matched = g.matchedCount;
        final stale = view(t, x).onPressed;
        g.expireTimeLimit();
        changes.value++;
        stale(); // Stale input after a terminal session is inert.
        await guard.advance(6000);
        expect(h.board(g), before);
        expect(g.matchedCount, matched);
        expect(g.result!.endReason, SessionEndReason.timeExpired);
        expect(g.transitions, isEmpty);
      },
    );

    test('$visible: new instances cannot inherit B outgoing fade permission', () {
      final f = a.Fixture(visible: visible);
      final oldA = f.match();
      f.advance(500);
      final oldB = f.match(), plan = f.game.transitions.single;
      expect(
        f.controller.returnDeadlineOf(oldA.pairId),
        const Duration(milliseconds: 1500),
      );
      expect(
        f.controller.returnDeadlineOf(oldB.pairId),
        const Duration(milliseconds: 5500),
      );
      f.advance(1000);
      final published = h.board(f.game);
      for (final entry in plan.incoming.entries) {
        expectInstance(f.game, entry.value, entry.key);
        expect(f.controller.textVisualFor(entry.key), activeRefillVisual);
        expect(
          f.controller.visualFor(entry.key).opacity,
          1,
          reason:
              'Only the correctly matched outgoing instance may target opacity zero; ${entry.value.id} has never been matched.',
        );
      }
      f.advance(10000);
      f.game.commitTransition(plan.token);
      f.game.completeTransition(plan.token);
      f.game.settlePair(oldA.pairId);
      f.game.settlePair(oldB.pairId);
      f.controller.synchronize();
      expect(h.board(f.game), published);
      for (final entry in plan.incoming.entries) {
        expectInstance(f.game, entry.value, entry.key);
      }
      expect(f.controller.hasPendingTimer, isFalse);
    });

    testWidgets(
      '$visible: new untouched cards never fade out at old B deadline',
      (t) async {
        final g = h.makeGame(visible: visible);
        await w.mountBoard(t, g);
        await w.solve(t, g);
        await t.pump(const Duration(milliseconds: 140));
        await t.pump();
        await t.pump(const Duration(milliseconds: 360));
        final oldB = await w.solve(t, g);
        final oldBSlot = g.slotIdOf(oldB.id)!;
        final plan = g.transitions.single;
        await t.pump(const Duration(milliseconds: 140));
        await t.pump();
        await t.pump(const Duration(milliseconds: 520));
        await t.pump();
        await t.pump(const Duration(milliseconds: 340));
        await t.pump();
        final published = h.board(g);
        final c = g.cardAt(oldBSlot)!;
        final surfaceAtActivation = view(t, c).surfaceOpacity.value;
        expectPlayable(t, c);
        // Advance real intermediate frames: jumping directly to the timer skips
        // the fade-out frame because the same pump starts the later fade-in.
        for (var frame = 0; frame < 250; frame++) {
          await t.pump(const Duration(milliseconds: 16));
          expect(h.board(g), published);
          for (final entry in plan.incoming.entries) {
            expectInstance(g, entry.value, entry.key);
            expectPlayable(t, entry.value);
          }
          expect(
            view(t, c).surfaceOpacity.value,
            greaterThanOrEqualTo(surfaceAtActivation),
            reason:
                'A visible, interactive new instance must not disappear under old B animation: activation=$surfaceAtActivation, frame=$frame, opacity=${view(t, c).surfaceOpacity.value}.',
          );
        }
        await t.pump(const Duration(seconds: 10));
        expect(h.board(g), published);
        h.valid(g);
        expect(t.takeException(), isNull);
      },
    );
  }
}
