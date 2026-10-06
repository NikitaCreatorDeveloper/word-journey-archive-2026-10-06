import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:word_journey/features/match_flow_lab/match_flow_controller.dart';
import 'package:word_journey/features/match_flow_lab/match_flow_lab_screen.dart';

import 'match_flow_lab_controller_test.dart' show LabHarness;

Finder slot(LabSlotId id) =>
    find.byKey(ValueKey('lab-slot-${labSlotLabel(id)}'));
Finder label(LabSlotId id) =>
    find.byKey(ValueKey('lab-text-${labSlotLabel(id)}'));
GestureDetector input(WidgetTester t, LabSlotId id) =>
    t.widget<GestureDetector>(
      find.descendant(of: slot(id), matching: find.byType(GestureDetector)),
    );

Future<void> mount(WidgetTester t, LabHarness h) async {
  await t.pumpWidget(MaterialApp(home: MatchFlowLabScreen(controller: h.flow)));
  addTearDown(() async {
    await t.pumpWidget(const SizedBox());
  });
}

Future<void> solve(WidgetTester t, LabHarness h, LabSlotState first) async {
  final p = h.partner(first), count = h.flow.matchedCount;
  await t.tap(slot(first.content.slotId));
  await t.pump();
  await t.tap(slot(p.content.slotId));
  await t.pump();
  expect(h.flow.matchedCount, count + 1);
}

Future<void> frames(
  WidgetTester t,
  LabHarness h,
  int ms, {
  VoidCallback? check,
}) async {
  while (ms > 0) {
    final step = ms > 16 ? 16 : ms;
    h.advance(step);
    await t.pump(Duration(milliseconds: step));
    ms -= step;
    check?.call();
  }
  expect(t.takeException(), isNull);
}

void main() {
  testWidgets(
    'Lab has only ten cards, a switchable generation overlay and no session HUD',
    (t) async {
      final h = LabHarness();
      await mount(t, h);
      expect(find.text('MATCH FLOW LAB'), findsOneWidget);
      expect(find.byType(RepaintBoundary), findsWidgets);
      for (final id in MatchFlowController.slots) {
        expect(slot(id), findsOneWidget);
        // MaterialApp's Navigator has route fades; lab cards paint alpha
        // directly and must not introduce opacity/saveLayer wrappers.
        for (final type in [FadeTransition, AnimatedOpacity, Opacity]) {
          expect(
            find.descendant(of: slot(id), matching: find.byType(type)),
            findsNothing,
          );
        }
        expect(find.text('${labSlotLabel(id)} · g1 · active'), findsOneWidget);
        expect(input(t, id).onTap, isNotNull);
      }
      final before = h.flow.states;
      await t.tap(find.byKey(const ValueKey('lab-overlay-toggle')));
      await t.pump();
      for (final id in MatchFlowController.slots) {
        expect(
          find.byKey(ValueKey('lab-debug-${labSlotLabel(id)}')),
          findsNothing,
        );
      }
      expect(h.flow.states, before);
      await t.tap(find.byKey(const ValueKey('lab-overlay-toggle')));
      await t.pump();
      expect(find.text('L1 · g1 · active'), findsOneWidget);
    },
  );

  testWidgets(
    'A blocks instantly and fallback text smoothly appears within its total five seconds',
    (t) async {
      final h = LabHarness();
      await mount(t, h);
      final a = h.available.first, id = a.content.slotId;
      await solve(t, h, a);
      expect(input(t, id).onTap, isNull);
      expect(find.text('${labSlotLabel(id)} · g1 · success'), findsOneWidget);
      await frames(t, h, 2592);
      expect(t.widget<Text>(label(id)).data, a.content.text);
      await frames(t, h, 16);
      final incoming = h.flow.states[id]!;
      expect(incoming.content.generation, 2);
      expect(t.widget<Text>(label(id)).data, incoming.content.text);
      expect(
        t.widget<Text>(label(id)).style!.color!.a,
        inExclusiveRange(0, .6),
      );
      expect(input(t, id).onTap, isNull);
      await frames(t, h, 2392);
      expect(t.widget<Text>(label(id)).style!.color!.a, 1);
      expect(input(t, id).onTap, isNotNull);
    },
  );

  testWidgets(
    'Cross partners become readable/clickable together in intermediate frames',
    (t) async {
      final h = LabHarness();
      await mount(t, h);
      final a = h.available.first;
      await solve(t, h, a);
      await frames(t, h, 500);
      final b = h.available.first;
      final bBefore = b.content;
      final opacityBefore = t
          .widget<Text>(label(a.content.slotId))
          .style!
          .color!
          .a;
      await solve(t, h, b);
      expect(
        t.widget<Text>(label(a.content.slotId)).style!.color!.a,
        opacityBefore,
      );
      await frames(t, h, 600);
      await frames(t, h, 400);
      expect(h.flow.states[b.content.slotId]!.content, same(bBefore));
      expect(input(t, a.content.slotId).onTap, isNull);
      expect(input(t, b.content.slotId).onTap, isNull);
      expect(t.widget<Text>(label(a.content.slotId)).style!.color!.a, 1);
      await solve(t, h, h.available.first);
      await frames(t, h, 600);
      var readableBeforeDeadline = false;
      await frames(
        t,
        h,
        400,
        check: () {
          for (final s in h.flow.states.values) {
            final p = h.partnerIfPresent(s);
            final word = t.widget<Text>(label(s.content.slotId));
            if (p == null) {
              expect(input(t, s.content.slotId).onTap, isNull);
              continue;
            }
            final translation = t.widget<Text>(label(p.content.slotId));
            expect(
              input(t, s.content.slotId).onTap != null,
              input(t, p.content.slotId).onTap != null,
            );
            if (s.interactive) {
              expect(word.style!.color!.a, greaterThanOrEqualTo(.6));
              expect(translation.style!.color!.a, greaterThanOrEqualTo(.6));
            }
            if (s.content.generation == 2 &&
                s.interactive &&
                h.now.inMilliseconds < 2500) {
              readableBeforeDeadline = true;
            }
          }
        },
      );
      expect(readableBeforeDeadline, isTrue);
      final fresh = h.available.firstWhere((s) => s.content.generation == 2);
      await solve(t, h, fresh);
      expect(h.flow.matchedCount, 4);
    },
  );

  testWidgets(
    'Unmatched X retains its text/widget/position/alpha/input through rapid and slow refills',
    (t) async {
      final h = LabHarness();
      await mount(t, h);
      final x = h.available.last, mate = h.partner(x);
      final fixed = [x, mate];
      final widgets = {
        for (final s in fixed)
          s.content.slotId: t.widget<Text>(label(s.content.slotId)),
      };
      final rects = {
        for (final s in fixed)
          s.content.slotId: t.getRect(slot(s.content.slotId)),
      };
      void checkX() {
        for (final original in fixed) {
          final id = original.content.slotId;
          expect(h.flow.states[id], same(original));
          expect(t.widget<Text>(label(id)), same(widgets[id]));
          expect(t.getRect(slot(id)), rects[id]);
          expect(t.widget<Text>(label(id)).style!.color!.a, 1);
          expect(input(t, id).onTap, isNotNull);
        }
      }

      for (final delay in [170, 170, 170, 1500, 5200, 500, 6000]) {
        var candidates = h.available
            .where((s) => s.content.conceptId != x.content.conceptId)
            .toList();
        while (candidates.isEmpty) {
          await frames(t, h, 1000, check: checkX);
          candidates = h.available
              .where((s) => s.content.conceptId != x.content.conceptId)
              .toList();
        }
        await solve(t, h, candidates.first);
        await frames(t, h, delay, check: checkX);
      }
      await t.tap(slot(x.content.slotId));
      await t.pump();
      expect(h.flow.selected, x.content.instance);
      await t.tap(slot(mate.content.slotId));
      await t.pump();
      expect(h.flow.states[x.content.slotId]!.matched, isTrue);
    },
  );

  testWidgets(
    'Old tap callback and old decorative deadlines cannot change selected new content',
    (t) async {
      final h = LabHarness();
      await mount(t, h);
      final a = h.available.first;
      final stale = input(t, a.content.slotId).onTap!;
      await solve(t, h, a);
      await frames(t, h, 500);
      await solve(t, h, h.available.first);
      await frames(t, h, 1000);
      await solve(t, h, h.available.first);
      await frames(t, h, 1000);
      final fresh = h.flow.states[a.content.slotId]!;
      final p = h.partner(fresh);
      stale();
      await t.pump();
      expect(h.flow.selected, isNull);
      await t.tap(slot(fresh.content.slotId));
      await t.pump();
      final before = h.flow.states;
      await frames(
        t,
        h,
        6000,
        check: () {
          expect(h.flow.selected, fresh.content.instance);
          expect(
            h.flow.states[fresh.content.slotId]!.content,
            same(fresh.content),
          );
          expect(h.flow.states[p.content.slotId]!.content, same(p.content));
          expect(
            t.widget<Text>(label(fresh.content.slotId)).style!.color!.a,
            1,
          );
          expect(input(t, fresh.content.slotId).onTap, isNotNull);
          expect(input(t, p.content.slotId).onTap, isNotNull);
        },
      );
      // C was correctly matched and may refill on its own clock. Every
      // unmatched instance, including the selected new A, must stay intact.
      for (final entry in before.entries.where((e) => !e.value.matched)) {
        expect(h.flow.states[entry.key]!.content, same(entry.value.content));
      }
    },
  );

  testWidgets(
    'Lab fits a 320×600 screen and uses only its isolated controller',
    (t) async {
      t.view.physicalSize = const Size(320, 600);
      t.view.devicePixelRatio = 1;
      addTearDown(t.view.resetPhysicalSize);
      addTearDown(t.view.resetDevicePixelRatio);
      final h = LabHarness();
      await mount(t, h);
      expect(t.takeException(), isNull);
      for (final id in MatchFlowController.slots) {
        expect(t.getRect(slot(id)).bottom, lessThanOrEqualTo(600));
      }
    },
  );
}
