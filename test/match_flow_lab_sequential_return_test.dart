import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:word_journey/features/match_flow_lab/match_flow_controller.dart';

import 'match_flow_lab_controller_test.dart' show LabHarness;
import 'match_flow_lab_widget_test.dart'
    show mount, solve, frames, input, label;

void main() {
  test('A→B does not return two playable replacement pairs at A deadline', () {
    final h = LabHarness();
    h.solve();
    h.advance(500);
    h.solve();
    h.advance(1000);

    final playableReplacements = h.available.where(
      (s) => s.content.generation > 1,
    );
    expect(playableReplacements, isEmpty);
    expect(h.available, hasLength(3));
  });

  test(
    'A returns first with crossed values while B keeps its own outgoing cycle',
    () {
      final h = LabHarness(), a = h.available.first, aMate = h.partner(a);
      h.solve(a);
      h.advance(500);
      final b = h.available.first, bMate = h.partner(b);
      final groupB = h.solve(b);
      h.advance(1000);
      for (final original in [a, aMate]) {
        final fresh = h.flow.states[original.content.slotId]!;
        expect(fresh.content.generation, 2);
        expect(fresh.visual.textOpacity, 1);
        expect(fresh.visual.state, LabVisualState.waitingPartner);
        expect(fresh.interactive, isFalse);
        expect(
          h.flow.select(fresh.content.slotId, fresh.content.generation),
          LabFeedback.ignored,
        );
      }
      expect(
        h.flow.states[a.content.slotId]!.content.conceptId,
        isNot(h.flow.states[aMate.content.slotId]!.content.conceptId),
      );
      for (final original in [b, bMate]) {
        final outgoing = h.flow.states[original.content.slotId]!;
        expect(outgoing.content, same(original.content));
        expect(outgoing.matched, isTrue);
        expect(outgoing.visual.state, LabVisualState.fading);
        expect(outgoing.visual.textOpacity, inExclusiveRange(0, 1));
        expect(outgoing.interactive, isFalse);
      }
      expect(h.flow.deadlineOf(groupB), const Duration(milliseconds: 5500));
      final before = h.flow.states[b.content.slotId]!.visual;
      final groupC = h.solve();
      final after = h.flow.states[b.content.slotId]!.visual;
      expect(after.textOpacity, before.textOpacity);
      expect(after.surfaceOpacity, before.surfaceOpacity);
      expect(h.flow.deadlineOf(groupB), const Duration(milliseconds: 2500));
      expect(h.flow.deadlineOf(groupC), const Duration(milliseconds: 6500));
      h.advance(600);
      expect(h.flow.states[b.content.slotId]!.content.generation, 2);
      expect(h.flow.states[b.content.slotId]!.visual.textOpacity, 0);
      expect(h.flow.states[a.content.slotId]!.interactive, isFalse);
      h.advance(120);
      for (final original in [a, aMate, b, bMate]) {
        final fresh = h.flow.states[original.content.slotId]!;
        expect(fresh.interactive, isTrue);
        expect(h.partner(fresh).interactive, isTrue);
        expect(h.partner(fresh).visual.textOpacity, greaterThanOrEqualTo(.6));
      }
      expect(h.flow.states[b.content.slotId]!.visual.textOpacity, lessThan(1));
    },
  );

  test('Without C, A stays visible and unchanged through B publication and all old deadlines', () {
    final h = LabHarness(), a = h.available.first, aMate = h.partner(a);
    final fixed = h.available.last, fixedMate = h.partner(fixed);
    h.solve(a);
    h.advance(500);
    final b = h.available.first;
    h.solve(b);
    h.advance(1000);
    final incomingA = [
      h.flow.states[a.content.slotId]!,
      h.flow.states[aMate.content.slotId]!,
    ];
    var opened = false;
    for (var frame = 0; frame < 330; frame++) {
      h.advance(16);
      for (final initial in incomingA) {
        final current = h.flow.states[initial.content.slotId]!;
        expect(current.content, same(initial.content));
        expect(current.visual.textOpacity, 1);
        final partner = h.partnerIfPresent(current);
        expect(current.interactive, partner?.interactive ?? false);
        if (current.interactive) {
          expect(partner!.visual.textOpacity, greaterThanOrEqualTo(.6));
          opened = true;
        } else {
          expect(opened, isFalse);
        }
      }
      if (h.now.inMilliseconds < 3100) {
        expect(h.flow.states[b.content.slotId]!.content, same(b.content));
      }
      expect(h.flow.states[fixed.content.slotId], same(fixed));
      expect(h.flow.states[fixedMate.content.slotId], same(fixedMate));
    }
    expect(opened, isTrue);
    expect(h.available, hasLength(5));
  });

  testWidgets(
    'A shows new words first, B fades old words, and C unlocks the waiting partners',
    (t) async {
      final h = LabHarness();
      await mount(t, h);
      final a = h.available.first;
      final oldTap = input(t, a.content.slotId).onTap!;
      await solve(t, h, a);
      await frames(t, h, 500);
      final b = h.available.first, bMate = h.partner(b);
      await solve(t, h, b);
      await frames(t, h, 1000);
      final freshA = h.flow.states[a.content.slotId]!;
      expect(t.widget<Text>(label(a.content.slotId)).data, freshA.content.text);
      expect(t.widget<Text>(label(a.content.slotId)).style!.color!.a, 1);
      expect(input(t, a.content.slotId).onTap, isNull);
      for (final oldB in [b, bMate]) {
        expect(
          t.widget<Text>(label(oldB.content.slotId)).data,
          oldB.content.text,
        );
        expect(
          t.widget<Text>(label(oldB.content.slotId)).style!.color!.a,
          inExclusiveRange(0, 1),
        );
        expect(input(t, oldB.content.slotId).onTap, isNull);
      }
      oldTap();
      await t.pump();
      expect(h.flow.selected, isNull);
      final c = h.available.first;
      expect(c.content.generation, 1);
      expect(input(t, c.content.slotId).onTap, isNotNull);
      await solve(t, h, c);
      await frames(
        t,
        h,
        720,
        check: () {
          expect(
            h.flow.states[a.content.slotId]!.content,
            same(freshA.content),
          );
          expect(t.widget<Text>(label(a.content.slotId)).style!.color!.a, 1);
          final p = h.partnerIfPresent(h.flow.states[a.content.slotId]!);
          expect(
            input(t, a.content.slotId).onTap != null,
            p?.interactive ?? false,
          );
          if (p?.interactive ?? false) {
            expect(
              t.widget<Text>(label(p!.content.slotId)).style!.color!.a,
              greaterThanOrEqualTo(.6),
            );
          }
        },
      );
      expect(input(t, a.content.slotId).onTap, isNotNull);
      await solve(t, h, h.flow.states[a.content.slotId]!);
      expect(h.flow.matchedCount, 4);
    },
  );
}
