import 'dart:async';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:word_journey/features/match_flow_lab/match_flow_controller.dart';

class LabHarness {
  LabHarness({List<LabConcept>? pool}) {
    flow = MatchFlowController(now: () => now, pool: pool, autoSchedule: false);
    addTearDown(flow.dispose);
  }
  Duration now = Duration.zero;
  late final MatchFlowController flow;
  List<LabSlotState> get available => flow.states.values
      .where((s) => s.content.slotId.left && s.interactive)
      .toList();
  LabSlotState? partnerIfPresent(LabSlotState state) => flow.states.values
      .where(
        (s) =>
            s.content.conceptId == state.content.conceptId &&
            s.content.slotId.left != state.content.slotId.left,
      )
      .singleOrNull;
  LabSlotState partner(LabSlotState state) => partnerIfPresent(state)!;
  int solve([LabSlotState? chosen]) {
    final first = chosen ?? available.first;
    final other = partner(first);
    expect(
      flow.select(first.content.slotId, first.content.generation),
      LabFeedback.selected,
    );
    expect(
      flow.select(other.content.slotId, other.content.generation),
      LabFeedback.correct,
    );
    return flow.latestCycleId;
  }

  void advance(int ms) {
    now += Duration(milliseconds: ms);
    flow.synchronize();
    expect(flow.debugValidate(), isTrue);
  }
}

class CapturedTimer implements Timer {
  CapturedTimer(this.callback);
  final void Function() callback;
  bool cancelled = false;
  @override
  void cancel() => cancelled = true;
  @override
  bool get isActive => !cancelled;
  @override
  int get tick => 0;
}

void main() {
  test('Repeated concept IDs retain distinct generations and never accept stale input', () {
    final h = LabHarness(pool: labConceptPool.take(7).toList());
    final seen = <LabInstance>[];
    for (var step = 0; step < 160; step++) {
      while (h.available.isEmpty) {
        h.advance(1000);
      }
      final current = h.available.first;
      seen.add(current.content.instance);
      h.solve(current);
      h.advance(step.isEven ? 170 : 1000);
      for (final old in seen.where(
        (ref) => h.flow.states[ref.slot]!.content.generation != ref.generation,
      )) {
        expect(h.flow.select(old.slot, old.generation), LabFeedback.ignored);
      }
    }
    expect(h.flow.matchedCount, 160);
  });

  test(
    'Lab uses 36 unique concepts and exactly five complete shuffled pairs',
    () {
      final h = LabHarness();
      expect(labConceptPool, hasLength(36));
      expect(labConceptPool.map((c) => c.id).toSet(), hasLength(36));
      expect(h.flow.states, hasLength(10));
      for (final s in h.flow.states.values) {
        expect(s.content.generation, 1);
        expect(s.interactive, isTrue);
        expect(s.visual.textOpacity, 1);
        expect(s.visual.surfaceOpacity, 1);
        expect(h.partner(s).interactive, isTrue);
      }
      expect(h.flow.hasPendingTimer, isFalse);
    },
  );

  test(
    'A success is immediate/blocked and its entire slow cycle ends at 5000 ms',
    () {
      final h = LabHarness(), a = h.available.first;
      final mate = h.partner(a), group = h.solve(a);
      for (final old in [a, mate]) {
        final s = h.flow.states[old.content.slotId]!;
        expect(s.visual.state, LabVisualState.success);
        expect(s.interactive, isFalse);
        expect(s.visual.textOpacity, 1);
        expect(
          h.flow.select(old.content.slotId, old.content.generation),
          LabFeedback.ignored,
        );
      }
      expect(h.flow.deadlineOf(group), const Duration(milliseconds: 5000));
      h.advance(149);
      expect(
        h.flow.states[a.content.slotId]!.visual.state,
        LabVisualState.success,
      );
      h.advance(1);
      expect(
        h.flow.states[a.content.slotId]!.visual.state,
        LabVisualState.fading,
      );
      h.advance(1200);
      final mid = h.flow.states[a.content.slotId]!;
      expect(mid.content, same(a.content));
      expect(mid.visual.textOpacity, inExclusiveRange(0, 1));
      h.advance(1249);
      expect(h.flow.states[a.content.slotId]!.content, same(a.content));
      h.advance(1);
      final newA = h.flow.states[a.content.slotId]!;
      final newMate = h.flow.states[mate.content.slotId]!;
      expect(newA.content.generation, 2);
      expect(newA.content.conceptId, newMate.content.conceptId);
      expect(newA.visual.textOpacity, 0);
      expect(newA.interactive, isFalse);
      h.advance(2399);
      expect(h.flow.deadlineOf(group), const Duration(milliseconds: 5000));
      h.advance(1);
      for (final old in [a, mate]) {
        final s = h.flow.states[old.content.slotId]!;
        expect(s.visual.textOpacity, 1);
        expect(s.visual.surfaceOpacity, 1);
        expect(s.visual.successTint, 0);
        expect(s.interactive, isTrue);
      }
      expect(h.flow.deadlineOf(group), isNull);
    },
  );

  test(
    'B at 500 ms retimes A continuously to 1500 while B owns deadline 5500',
    () {
      final h = LabHarness(), a = h.available.first, groupA = h.solve(a);
      h.advance(500);
      final before = h.flow.states[a.content.slotId]!.visual;
      final b = h.available.first, groupB = h.solve(b);
      final after = h.flow.states[a.content.slotId]!.visual;
      expect(after.textOpacity, before.textOpacity);
      expect(after.surfaceOpacity, before.surfaceOpacity);
      expect(h.flow.deadlineOf(groupA), const Duration(milliseconds: 1500));
      expect(h.flow.deadlineOf(groupB), const Duration(milliseconds: 5500));
      expect(
        h.flow.states[b.content.slotId]!.visual.state,
        LabVisualState.success,
      );
      h.advance(599);
      expect(h.flow.states[a.content.slotId]!.content, same(a.content));
      h.advance(1);
      expect(h.flow.states[a.content.slotId]!.content.generation, 2);
      h.advance(400);
      expect(h.flow.states[a.content.slotId]!.visual.textOpacity, 1);
      expect(h.flow.states[a.content.slotId]!.visual.surfaceOpacity, 1);
      expect(h.flow.deadlineOf(groupA), isNull);
      expect(h.flow.deadlineOf(groupB), const Duration(milliseconds: 5500));
    },
  );

  test('A→B→C→D accelerates only the immediately preceding pending cycle', () {
    final h = LabHarness(), a = h.solve();
    h.advance(500);
    final b = h.solve();
    h.advance(250);
    final c = h.solve();
    h.advance(250);
    final d = h.solve();
    expect(h.flow.deadlineOf(a), const Duration(milliseconds: 1500));
    expect(h.flow.deadlineOf(b), const Duration(milliseconds: 1750));
    expect(h.flow.deadlineOf(c), const Duration(milliseconds: 2000));
    expect(h.flow.deadlineOf(d), const Duration(milliseconds: 6000));
    h.advance(500);
    expect(h.flow.deadlineOf(a), isNull);
    h.advance(500);
    expect(h.flow.deadlineOf(b), isNull);
    expect(h.flow.deadlineOf(c), isNull);
    expect(h.flow.deadlineOf(d), const Duration(milliseconds: 6000));
  });

  test(
    'Late B never extends A and never recrosses already published content',
    () {
      for (final at in [2599, 2600, 3000, 4400, 4900, 4999]) {
        final h = LabHarness(),
            a = h.available.first,
            b = h.available[1],
            id = h.solve(a);
        h.advance(at);
        final before = h.flow.states[a.content.slotId]!;
        h.solve(b);
        final after = h.flow.states[a.content.slotId]!;
        expect(after.visual.textOpacity, before.visual.textOpacity);
        expect(after.visual.surfaceOpacity, before.visual.surfaceOpacity);
        expect(h.flow.deadlineOf(id)!.inMilliseconds, min(5000, at + 1000));
        if (before.content.generation == 2) {
          expect(after.content, same(before.content));
        }
        h.advance(min(5000, at + 1000) - at);
        expect(h.flow.deadlineOf(id), isNull);
        expect(
          h.flow.states[a.content.slotId]!.interactive,
          before.content.generation == 2,
        );
      }
    },
  );

  test(
    'Unmatched X is stable across 120 mixed fast/slow matches and generations',
    () {
      final h = LabHarness(), x = h.available.last;
      final fixed = [x, h.partner(x)];
      final random = Random(74);
      var notifications = 0;
      for (final s in fixed) {
        h.flow.stateOf(s.content.slotId).addListener(() => notifications++);
      }
      for (var i = 0; i < 120; i++) {
        final eligible = h.available
            .where((s) => s.content.conceptId != x.content.conceptId)
            .toList();
        if (eligible.isEmpty) {
          h.advance(1000);
          i--;
          continue;
        }
        h.solve(eligible.first);
        h.advance([170, 500, 1200, 5200][random.nextInt(4)]);
        for (final original in fixed) {
          final s = h.flow.states[original.content.slotId]!;
          expect(s, same(original));
          expect(s.content, same(original.content));
          expect(s.visual.textOpacity, 1);
          expect(s.visual.surfaceOpacity, 1);
          expect(s.interactive, isTrue);
        }
      }
      expect(notifications, 0);
    },
  );

  test(
    'Cross values in A wait for B and both partners become playable together',
    () {
      final h = LabHarness(), a = h.available.first, aMate = h.partner(a);
      h.solve(a);
      h.advance(500);
      h.solve();
      h.advance(600);
      final newA = h.flow.states[a.content.slotId]!;
      expect(
        newA.content.conceptId,
        isNot(h.flow.states[aMate.content.slotId]!.content.conceptId),
      );
      var acceptedAt = -1;
      for (var ms = 0; ms <= 4400; ms += 4) {
        h.advance(4);
        for (final s in h.flow.states.values) {
          final partner = h.partnerIfPresent(s);
          if (partner == null) {
            expect(s.interactive, isFalse);
          } else {
            expect(s.interactive, partner.interactive);
            if (s.interactive) {
              expect(partner.visual.textOpacity, greaterThanOrEqualTo(.6));
            }
          }
        }
        final s = h.flow.states[a.content.slotId]!;
        if (s.interactive && acceptedAt < 0) acceptedAt = ms;
      }
      expect(acceptedAt, inInclusiveRange(2600, 2700));
    },
  );

  test('Every notification observes atomically updated partner generations and input', () {
    final h = LabHarness();
    for (final slot in MatchFlowController.slots) {
      h.flow.stateOf(slot).addListener(() {
        for (final s in h.flow.states.values) {
          final p = h.partnerIfPresent(s);
          expect(s.interactive, p?.interactive ?? false);
          if (s.interactive) {
            expect(s.visual.textOpacity, greaterThanOrEqualTo(.6));
            expect(p!.visual.textOpacity, greaterThanOrEqualTo(.6));
          }
        }
      });
    }
    h.solve();
    h.advance(500);
    h.solve();
    for (var i = 0; i < 100; i++) {
      h.advance(16);
    }
  });

  test('New words stay visible/playable after every old A/B deadline', () {
    final h = LabHarness();
    h.solve();
    h.advance(500);
    h.solve();
    h.advance(5000);
    final published = h.flow.states;
    final surfaces = {
      for (final s in published.values)
        s.content.slotId: s.visual.surfaceOpacity,
    };
    for (var ms = 0; ms < 6000; ms += 16) {
      h.advance(16);
      for (final old in published.values) {
        final s = h.flow.states[old.content.slotId]!;
        expect(s.content, same(old.content));
        expect(s.visual.textOpacity, 1);
        expect(s.interactive, isTrue);
        expect(
          s.visual.surfaceOpacity,
          greaterThanOrEqualTo(surfaces[s.content.slotId]!),
        );
        surfaces[s.content.slotId] = s.visual.surfaceOpacity;
      }
    }
  });

  test('Wrong answer does not accelerate A or alter its fade endpoint', () {
    final h = LabHarness(), a = h.solve();
    h.advance(500);
    final candidates = h.available;
    h.flow.select(
      candidates.first.content.slotId,
      candidates.first.content.generation,
    );
    final wrong = h.partner(candidates.last);
    expect(
      h.flow.select(wrong.content.slotId, wrong.content.generation),
      LabFeedback.incorrect,
    );
    expect(h.flow.deadlineOf(a), const Duration(milliseconds: 5000));
    expect(h.flow.matchedCount, 1);
  });

  test('Selected X and its translation survive another pair fallback', () {
    final h = LabHarness();
    h.solve();
    final x = h.available.last, p = h.partner(x);
    h.flow.select(x.content.slotId, x.content.generation);
    h.advance(6000);
    expect(h.flow.selected, x.content.instance);
    expect(h.flow.states[x.content.slotId]!.content, same(x.content));
    expect(h.flow.states[p.content.slotId]!, same(p));
    expect(h.flow.states[x.content.slotId]!.interactive, isTrue);
  });

  test(
    'Rapid taps accept newly readable cards before decoration completes',
    () {
      final h = LabHarness();
      h.solve();
      h.advance(500);
      h.solve();
      h.advance(1000);
      h.solve();
      h.advance(720);
      final newCard = h.available.firstWhere((s) => s.content.generation == 2);
      expect(
        min(newCard.visual.textOpacity, h.partner(newCard).visual.textOpacity),
        lessThan(1),
      );
      expect(h.partner(newCard).interactive, isTrue);
      final id = h.solve(newCard);
      expect(h.flow.matchedCount, 4);
      expect(h.flow.deadlineOf(id), const Duration(milliseconds: 7220));
      expect(
        h.flow.select(newCard.content.slotId, newCard.content.generation),
        LabFeedback.ignored,
      );
    },
  );

  test('Old generation tap callbacks cannot select replacement contents', () {
    final h = LabHarness(), old = h.available.first;
    h.solve(old);
    h.advance(500);
    h.solve();
    h.advance(6000);
    final before = h.flow.states;
    expect(
      h.flow.select(old.content.slotId, old.content.generation),
      LabFeedback.ignored,
    );
    expect(h.flow.states, before);
    expect(h.flow.selected, isNull);
  });

  test('One scheduler cancels old callbacks on new generation and dispose', () {
    var now = Duration.zero;
    final timers = <CapturedTimer>[];
    final flow = MatchFlowController(
      now: () => now,
      timerFactory: (_, callback) {
        final timer = CapturedTimer(callback);
        timers.add(timer);
        return timer;
      },
    );
    addTearDown(flow.dispose);
    final first = flow.states.values.first;
    final partner = flow.states.values.singleWhere(
      (s) => s.content.conceptId == first.content.conceptId && s != first,
    );
    flow.select(first.content.slotId, 1);
    flow.select(partner.content.slotId, 1);
    final oldCallback = timers.last.callback;
    now = const Duration(milliseconds: 5000);
    flow.synchronize();
    final after = flow.states;
    oldCallback();
    expect(flow.states, after);
    expect(timers.where((t) => t.isActive).length, lessThanOrEqualTo(1));
    flow.dispose();
    for (final timer in timers) {
      timer.callback();
    }
    expect(flow.states, after);
    expect(timers.any((t) => t.isActive), isFalse);
  });

  test(
    'Pause freezes visual state and resume keeps remaining monotonic deadlines',
    () {
      final h = LabHarness();
      h.solve();
      h.advance(500);
      h.solve();
      h.advance(300);
      h.flow.setPaused(true);
      final before = h.flow.states;
      h.advance(10000);
      expect(h.flow.states, before);
      h.flow.setPaused(false);
      h.advance(700);
      expect(h.flow.elapsed, const Duration(milliseconds: 1500));
      expect(h.available, hasLength(3));
      final first = h.flow.states.values.first;
      expect(first.visual.textOpacity, 1);
      expect(first.visual.state, LabVisualState.waitingPartner);
      expect(first.interactive, isFalse);
      h.advance(4000);
      expect(h.available, hasLength(5));
    },
  );
}
