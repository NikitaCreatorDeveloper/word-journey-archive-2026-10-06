import 'dart:async';
import 'dart:math';

import 'package:clock/clock.dart' as clock_source;
import 'package:flutter/foundation.dart';

import '../model/match_flow_models.dart';
export '../model/match_flow_models.dart';

class _SlotValue extends ChangeNotifier
    implements ValueListenable<MatchSlotState> {
  _SlotValue(this._value);
  MatchSlotState _value;
  @override
  MatchSlotState get value => _value;
  bool stage(MatchSlotState next) {
    if (_value == next) return false;
    _value = next;
    return true;
  }

  void publish() => notifyListeners();
}

// Sampled from monotonic time: retiming continues from the current value.
class _Segment {
  _Segment(this.start, this.end, this.from, this.to, {this.outgoing = false});
  final Duration start, end;
  final double from, to;
  final bool outgoing;
  double at(Duration now) {
    if (now <= start) return from;
    if (now >= end) return to;
    final t = (now - start).inMicroseconds / (end - start).inMicroseconds;
    final eased = outgoing
        ? (t < .5 ? 4 * t * t * t : 1 - pow(-2 * t + 2, 3) / 2)
        : 1 - pow(1 - t, 3);
    return (from + (to - from) * eased).toDouble();
  }

  _Segment until(Duration deadline, Duration now) => deadline == end
      ? this
      : _Segment(
          now < start ? start : now,
          deadline,
          at(now),
          to,
          outgoing: outgoing,
        );
  bool moving(Duration now) => from != to && now < end;
}

class _TextFlow {
  _TextFlow(this.instances, this.segment);
  final List<MatchInstance> instances;
  _Segment segment;
}

class _VisualOwner {
  _VisualOwner(this.instance, this.text, this.surface, this.tint)
    : error = _Segment(Duration.zero, Duration.zero, 0, 0);
  final MatchInstance instance;
  _TextFlow text;
  _Segment surface, tint, error;
}

class _MatchedCycle {
  _MatchedCycle(this.id, this.instances, this.correctAt)
    : deadline = correctAt + MatchFlowController.slowCycle;
  final int id;
  final List<MatchInstance> instances;
  final Duration correctAt;
  Duration deadline;
  Duration get confirmAt => correctAt + MatchFlowController.confirmation;
  Duration get appearanceAt =>
      deadline -
      (accelerated
          ? MatchFlowController.fastAppearance
          : MatchFlowController.slowAppearance);
  bool accelerated = false, published = false;
  List<MatchInstance> decorated = [];
  int? planId;
}

class _Plan {
  _Plan(this.id, this.groups, this.values, this.occurrences);
  final int id;
  final List<_MatchedCycle> groups;
  final Map<MatchSlotId, MatchConcept> values;
  final Map<String, int> occurrences;
  bool issued = false;
  int get pairCount => occurrences.length;
  Iterable<_MatchedCycle> get pending => groups.where((g) => !g.published);
  Iterable<MatchInstance> get outgoing => pending.expand((g) => g.instances);
  Duration get swapAt =>
      pending.map((g) => g.appearanceAt).reduce((a, b) => a < b ? a : b);
  bool get cross => groups.length == 2;
}

/// Shared by the approved lab and production; permissions belong to an instance.
/// One timer samples every local animation and deadline. Widgets never schedule
/// transitions, and an already published generation can only fade in.
class MatchFlowController {
  MatchFlowController({
    required List<MatchConcept> pool,
    Duration Function()? now,
    Random? random,
    this.visiblePairs = 5,
    this.maxIssuedPairs,
    Map<MatchSlotId, MatchConcept>? initialBoard,
    int nextOccurrence = 0,
    this.pickConcept,
    this.onFrame,
    this.errorFeedback = false,
    this.autoSchedule = true,
    Timer Function(Duration, void Function())? timerFactory,
  }) : _pool = List.unmodifiable(pool),
       _clock = now ?? _monotonicClock(),
       _random = random ?? Random(43),
       _timerFactory = timerFactory ?? Timer.new {
    if (visiblePairs < 1 ||
        _pool.length < visiblePairs ||
        (maxIssuedPairs != null && maxIssuedPairs! < 1) ||
        _pool.map((c) => c.id).toSet().length != _pool.length ||
        _pool.any(
          (c) => c.id.isEmpty || c.english.isEmpty || c.russian.isEmpty,
        )) {
      throw ArgumentError('Flow needs enough unique concepts for its board');
    }
    _origin = _clock();
    _occurrence = nextOccurrence;
    final initial = [..._pool]..shuffle(_random);
    final count = min(visiblePairs, maxIssuedPairs ?? visiblePairs);
    final left = initial.take(count).toList()..shuffle(_random);
    final right = initial.take(count).toList()..shuffle(_random);
    final seed =
        initialBoard ??
        {
          for (final slot in boardSlots)
            if (slot.row < count) slot: (slot.left ? left : right)[slot.row],
        };
    final initialOccurrences = <String, int>{};
    for (final slot in boardSlots) {
      final concept = seed[slot] ?? _emptyConcept;
      _contents[slot] = MatchCardContent(
        slot,
        1,
        concept,
        occurrence: concept.id.isEmpty
            ? -1
            : initialOccurrences.putIfAbsent(concept.id, () => _occurrence++),
      );
    }
    _issuedCount = initialOccurrences.length;
    final concepts = {
      for (final c in _contents.values)
        if (!c.isEmpty) c.conceptId: c.concept,
    };
    for (final concept in concepts.values) {
      final pair = _contents.values
          .where((c) => c.conceptId == concept.id)
          .toList();
      final text = _TextFlow(
        pair.map((c) => c.instance).toList(),
        _constant(1),
      );
      for (final c in pair) {
        _visuals[c.slotId] = _VisualOwner(
          c.instance,
          text,
          _constant(1),
          _constant(0),
        );
      }
    }
    for (final slot in boardSlots) {
      if (_contents[slot]!.isEmpty) {
        final ref = _contents[slot]!.instance;
        _visuals[slot] = _VisualOwner(
          ref,
          _TextFlow([ref], _constant(0)),
          _constant(0),
          _constant(0),
        );
      }
      _states[slot] = _SlotValue(_snapshot(slot, Duration.zero));
    }
    assert(debugValidate());
  }

  static const slowCycle = Duration(milliseconds: 5000),
      confirmation = Duration(milliseconds: 150),
      slowAppearance = Duration(milliseconds: 2400),
      acceleratedRemaining = Duration(milliseconds: 1000),
      fastAppearance = Duration(milliseconds: 400);
  static const readableOpacity = .6;
  static List<MatchSlotId> slotsFor(int count) =>
      List<MatchSlotId>.unmodifiable([
        for (var row = 0; row < count; row++) ...[
          (left: true, row: row),
          (left: false, row: row),
        ],
      ]);
  late final boardSlots = slotsFor(visiblePairs);
  static const _emptyConcept = MatchConcept('', '', '');
  final int visiblePairs;
  final int? maxIssuedPairs;
  final MatchConcept Function(Set<String>, Set<String>)? pickConcept;
  final VoidCallback? onFrame;
  final bool errorFeedback;
  final List<MatchConcept> _pool;
  final Duration Function() _clock;
  final Random _random;
  final bool autoSchedule;
  final Timer Function(Duration, void Function()) _timerFactory;
  final _contents = <MatchSlotId, MatchCardContent>{};
  final _visuals = <MatchSlotId, _VisualOwner>{};
  final _states = <MatchSlotId, _SlotValue>{};
  final _matched = <MatchInstance>{};
  final _cycles = <int, _MatchedCycle>{};
  final _plans = <int, _Plan>{};
  MatchInstance? _selected;
  late final Duration _origin;
  Duration _lastNow = Duration.zero, _pausedFor = Duration.zero;
  Duration? _pausedAt;
  Duration? _stoppedAt;
  Timer? _timer;
  int _timerEpoch = 0, _cycleId = 0, _planId = 0;
  int _occurrence = 0, _issuedCount = 0;
  bool _disposed = false, _stopped = false;
  int get issuedCount => _issuedCount;
  bool get stopped => _stopped;
  int get _remainingCapacity => maxIssuedPairs == null
      ? 1 << 30
      : maxIssuedPairs! -
            _issuedCount -
            _plans.values
                .where((p) => !p.issued)
                .fold<int>(0, (n, p) => n + p.pairCount);
  int get matchedCount => _cycleId;
  int get latestCycleId => _cycleId;
  bool get paused => _pausedAt != null;
  bool get hasPendingTimer => _timer?.isActive ?? false;
  MatchInstance? get selected => _selected;
  Duration get elapsed => _now;
  Duration? deadlineOf(int cycle) => _cycles[cycle]?.deadline;
  ValueListenable<MatchSlotState> stateOf(MatchSlotId slot) => _states[slot]!;
  Map<MatchSlotId, MatchSlotState> get states => Map.unmodifiable({
    for (final slot in boardSlots) slot: _states[slot]!.value,
  });
  static Duration Function() _monotonicClock() {
    final source = clock_source.clock;
    final watch = identical(source, const clock_source.Clock())
        ? Stopwatch()
        : source.stopwatch();
    watch.start();
    return () => watch.elapsed;
  }

  static _Segment _constant(double value) =>
      _Segment(Duration.zero, Duration.zero, value, value);
  Duration get _now {
    final sampled =
        (_stoppedAt ?? _pausedAt ?? _clock()) - _origin - _pausedFor;
    if (sampled > _lastNow) _lastNow = sampled;
    return _lastNow;
  }

  bool _owns(MatchInstance instance) =>
      _contents[instance.slot]?.generation == instance.generation;
  _VisualOwner _visual(MatchInstance instance) {
    final visual = _visuals[instance.slot]!;
    assert(visual.instance == instance);
    return visual;
  }

  MatchSlotState _snapshot(MatchSlotId slot, Duration now) {
    final c = _contents[slot]!, visual = _visual(c.instance);
    final matched = _matched.contains(c.instance),
        opacity = visual.text.segment.at(now);
    final readable =
        !c.isEmpty &&
        visual.text.instances.every(
          (ref) =>
              _owns(ref) &&
              !_matched.contains(ref) &&
              _visual(ref).text.segment.at(now) >= readableOpacity,
        );
    final cycle = matched
        ? _cycles.values.singleWhere((g) => g.instances.contains(c.instance))
        : null;
    return MatchSlotState(
      content: c,
      matched: matched,
      selected: _selected == c.instance,
      interactive: !_stopped && !paused && !matched && readable,
      visual: CardTransitionVisual(
        textOpacity: opacity,
        surfaceOpacity: visual.surface.at(now),
        successTint: visual.tint.at(now),
        errorTint: visual.error.at(now),
        state: c.isEmpty
            ? MatchVisualState.empty
            : matched
            ? (now < cycle!.confirmAt
                  ? MatchVisualState.success
                  : MatchVisualState.fading)
            : (readable
                  ? MatchVisualState.active
                  : opacity >= readableOpacity
                  ? MatchVisualState.waitingPartner
                  : MatchVisualState.appearing),
      ),
    );
  }

  FlowFeedback select(MatchSlotId slot, int generation) {
    if (_disposed || _stopped || paused) return FlowFeedback.ignored;
    synchronize();
    final card = _contents[slot]!;
    if (card.generation != generation || !_states[slot]!.value.interactive) {
      return FlowFeedback.ignored;
    }
    final ref = card.instance;
    if (_selected == ref) {
      _selected = null;
      _publish(_now);
      return FlowFeedback.deselected;
    }
    final first = _selected == null ? null : _contents[_selected!.slot];
    if (first == null || first.slotId.left == slot.left) {
      _selected = ref;
      _publish(_now);
      return FlowFeedback.selected;
    }
    _selected = null;
    if (first.conceptId != card.conceptId) {
      if (errorFeedback) {
        for (final instance in [first.instance, ref]) {
          _visual(instance).error = _Segment(
            _now,
            _now + const Duration(milliseconds: 220),
            1,
            0,
          );
        }
      }
      _publish(_now);
      _arm(_now);
      return FlowFeedback.incorrect;
    }
    final now = _now;
    final previous = _cycles.values.where((g) => g.deadline > now).lastOrNull;
    final cycle = _MatchedCycle(++_cycleId, [first.instance, ref], now);
    _cycles[cycle.id] = cycle;
    _matched.addAll(cycle.instances);
    final text = _TextFlow(
      cycle.instances,
      _Segment(
        cycle.confirmAt,
        cycle.deadline - slowAppearance,
        1,
        0,
        outgoing: true,
      ),
    );
    for (final instance in cycle.instances) {
      final visual = _visual(instance);
      visual.text = text;
      visual.surface = _Segment(
        cycle.confirmAt,
        cycle.deadline - slowAppearance,
        visual.surface.at(now),
        0,
        outgoing: true,
      );
      visual.tint = _constant(1);
    }
    if (previous != null) _accelerate(previous, now);
    if (previous != null &&
        !previous.published &&
        _plans[previous.planId]?.cross == false &&
        previous.instances.every(
          (ref) => _owns(ref) && _matched.contains(ref),
        ) &&
        _canCross(previous, cycle)) {
      _plans.remove(previous.planId);
      _createPlan([previous, cycle], now);
    } else {
      _createPlan([cycle], now);
    }
    synchronize();
    return FlowFeedback.correct;
  }

  void _accelerate(_MatchedCycle cycle, Duration now) {
    final candidate = now + acceleratedRemaining;
    if (candidate >= cycle.deadline) return;
    cycle.deadline = candidate;
    cycle.accelerated = true;
    if (!cycle.published) {
      final plan = _plans[cycle.planId];
      if (plan != null) _retimePlan(plan, now);
      return;
    }
    // Published words are untouchable. Only finish their incoming decoration;
    // a newer answer cannot restart their outgoing state or move their content.
    for (final ref in cycle.decorated) {
      if (!_owns(ref) || _matched.contains(ref)) continue;
      final visual = _visual(ref);
      visual.surface = visual.surface.until(cycle.deadline, now);
      visual.tint = visual.tint.until(cycle.deadline, now);
      if (visual.text.segment.end > cycle.deadline) {
        visual.text.segment = visual.text.segment.until(cycle.deadline, now);
      }
    }
  }

  Set<String> _occupiedFor(List<_MatchedCycle> groups, {int? excludePlan}) {
    final retiring = groups.expand((g) => g.instances).toList();
    return <String>{
      for (final c in _contents.values)
        if (!c.isEmpty && !retiring.contains(c.instance)) c.conceptId,
      for (final plan in _plans.values)
        if (plan.id != excludePlan)
          ...plan.values.values.where((c) => c.id.isNotEmpty).map((c) => c.id),
      // Later groups keep their outgoing text after the first group returns.
      // Reusing their old concept early would duplicate a visible card.
      for (final group in groups.skip(1))
        for (final ref in group.instances) _contents[ref.slot]!.conceptId,
    };
  }

  bool _canCross(_MatchedCycle previous, _MatchedCycle current) {
    final old = _plans[previous.planId]!;
    if (_remainingCapacity + old.pairCount < 2) return false;
    final occupied = _occupiedFor([previous, current], excludePlan: old.id);
    return _pool.where((c) => !occupied.contains(c.id)).length >= 2;
  }

  void _createPlan(List<_MatchedCycle> groups, Duration now) {
    final retiring = groups.expand((g) => g.instances).toList();
    final occupied = _occupiedFor(groups);
    final recent = retiring
        .map((ref) => _contents[ref.slot]!.conceptId)
        .toSet();
    MatchConcept issue() {
      if (pickConcept case final pick?) {
        final chosen = pick(Set.of(occupied), Set.of(recent));
        if (occupied.contains(chosen.id) ||
            !_pool.any((c) => c.id == chosen.id)) {
          throw StateError(
            'The word scheduler issued an occupied or unknown concept',
          );
        }
        occupied.add(chosen.id);
        return chosen;
      }
      var available = _pool.where((c) => !occupied.contains(c.id)).toList();
      final fresh = available.where((c) => !recent.contains(c.id)).toList();
      if (fresh.isNotEmpty) available = fresh;
      final chosen = available[_random.nextInt(available.length)];
      occupied.add(chosen.id);
      return chosen;
    }

    MatchSlotId slotOf(_MatchedCycle g, bool left) =>
        g.instances.singleWhere((ref) => ref.slot.left == left).slot;
    final x = _remainingCapacity > 0 ? issue() : _emptyConcept;
    final values = <MatchSlotId, MatchConcept>{};
    if (groups.length == 2) {
      final y = issue();
      values.addAll({
        slotOf(groups[0], true): x,
        slotOf(groups[0], false): y,
        slotOf(groups[1], true): y,
        slotOf(groups[1], false): x,
      });
    } else {
      values.addAll({for (final ref in retiring) ref.slot: x});
    }
    final occurrences = <String, int>{};
    for (final value in values.values) {
      if (value.id.isNotEmpty) {
        occurrences.putIfAbsent(value.id, () => _occurrence++);
      }
    }
    final plan = _Plan(++_planId, groups, values, occurrences);
    _plans[plan.id] = plan;
    for (final group in groups) {
      group.planId = plan.id;
    }
    _retimePlan(plan, now);
  }

  void _retimePlan(_Plan plan, Duration now) {
    for (final group in plan.pending) {
      // Every outgoing curve belongs to these exact matched instances. Retiming
      // samples its current value, and an unchanged endpoint keeps its curve.
      for (final ref in group.instances) {
        if (!_owns(ref) || !_matched.contains(ref)) continue;
        final visual = _visual(ref);
        visual.text.segment = visual.text.segment.until(
          group.appearanceAt,
          now,
        );
        visual.surface = visual.surface.until(group.appearanceAt, now);
      }
    }
  }

  void _commit(_Plan plan, _MatchedCycle group) {
    if (!group.instances.every((ref) => _owns(ref) && _matched.contains(ref))) {
      return;
    }
    final start = group.appearanceAt;
    final values = {
      for (final ref in group.instances) ref.slot: plan.values[ref.slot]!,
    };
    final before = {
      for (final ref in group.instances)
        ref.slot: (
          surface: _visual(ref).surface.at(start),
          tint: _visual(ref).tint.at(start),
        ),
    };
    // Each matched group publishes on its own clock. Publishing A must not
    // retire B's text or turn B's five-second cycle into A's fast appearance.
    for (final entry in values.entries) {
      _contents[entry.key] = MatchCardContent(
        entry.key,
        _contents[entry.key]!.generation + 1,
        entry.value,
        occurrence: plan.occurrences[entry.value.id] ?? -1,
      );
    }
    if (!plan.issued) {
      _issuedCount += plan.pairCount;
      plan.issued = true;
    }
    _matched.removeAll(group.instances);
    for (final entry in values.entries) {
      final content = _contents[entry.key]!;
      final text = content.isEmpty
          ? _TextFlow([content.instance], _constant(0))
          : _TextFlow(
              plan.groups
                  .expand((g) => g.instances)
                  .where(
                    (ref) => plan.values[ref.slot]!.id == content.conceptId,
                  )
                  .map(
                    (ref) => (slot: ref.slot, generation: ref.generation + 1),
                  )
                  .toList(),
              _Segment(start, group.deadline, 0, 1),
            );
      _visuals[entry.key] = _VisualOwner(
        content.instance,
        text,
        content.isEmpty
            ? _constant(0)
            : _Segment(start, group.deadline, before[entry.key]!.surface, 1),
        content.isEmpty
            ? _constant(0)
            : _Segment(start, group.deadline, before[entry.key]!.tint, 0),
      );
    }
    group.published = true;
    group.decorated = group.instances
        .map((ref) => _contents[ref.slot]!.instance)
        .toList();
    if (plan.pending.isEmpty) _plans.remove(plan.id);
  }

  void _publish(Duration now) {
    final next = {for (final slot in boardSlots) slot: _snapshot(slot, now)};
    // Compute the complete frame before notifying any widget. Input opens for
    // both partners together, even when A and B publish on different clocks.
    final changed = [
      for (final slot in boardSlots)
        if (_states[slot]!.stage(next[slot]!)) _states[slot]!,
    ];
    if (changed.isNotEmpty) onFrame?.call();
    for (final state in changed) {
      state.publish();
    }
  }

  void synchronize() {
    if (_disposed || _stopped) return;
    final now = _now;
    if (!paused) {
      final due = _plans.values.where((p) => p.swapAt <= now).toList()
        ..sort((a, b) => a.swapAt.compareTo(b.swapAt));
      for (final plan in due) {
        for (final group in plan.pending.toList()) {
          if (group.appearanceAt <= now) _commit(plan, group);
        }
      }
      _cycles.removeWhere((_, g) => g.published && now >= g.deadline);
    }
    _publish(now);
    assert(debugValidate());
    _arm(now);
  }

  void _cancelTimer() {
    _timer?.cancel();
    _timer = null;
    _timerEpoch++;
  }

  void _arm(Duration now) {
    _cancelTimer();
    if (!autoSchedule || paused || _disposed || _stopped) return;
    final events = <Duration>[
      for (final plan in _plans.values)
        if (plan.swapAt > now) plan.swapAt,
      for (final group in _cycles.values) ...[
        if (group.confirmAt > now) group.confirmAt,
        if (group.deadline > now) group.deadline,
      ],
      for (final v in _visuals.values)
        for (final s in [v.text.segment, v.surface, v.tint, v.error])
          if (s.moving(now)) now + const Duration(milliseconds: 16),
    ]..sort();
    if (events.isEmpty) return;
    final epoch = _timerEpoch;
    _timer = _timerFactory(events.first - now, () {
      if (_disposed || _stopped || paused || epoch != _timerEpoch) return;
      _timer = null;
      synchronize();
    });
  }

  void setPaused(bool value) {
    if (_disposed || _stopped || value == paused) return;
    if (value) {
      synchronize();
      _pausedAt = _clock();
      _cancelTimer();
    } else {
      _pausedFor += _clock() - _pausedAt!;
      _pausedAt = null;
    }
    synchronize();
  }

  bool debugValidate() {
    if (_disposed) return true;
    final left = _contents.values
            .where((c) => c.slotId.left && !c.isEmpty)
            .toList(),
        right = _contents.values
            .where((c) => !c.slotId.left && !c.isEmpty)
            .toList();
    assert(left.length == right.length && left.length <= visiblePairs);
    assert(left.map((c) => c.conceptId).toSet().length == left.length);
    assert(right.map((c) => c.conceptId).toSet().length == right.length);
    assert(maxIssuedPairs == null || _issuedCount <= maxIssuedPairs!);
    for (final card in [...left, ...right]) {
      final partner = (card.slotId.left ? right : left)
          .where((c) => c.conceptId == card.conceptId)
          .singleOrNull;
      if (partner == null) {
        // A crossed replacement can be visible while its future partner still
        // belongs to B's outgoing generation. It cannot receive input yet.
        assert(!_states[card.slotId]!.value.interactive);
        assert(!_matched.contains(card.instance));
        final future = _visual(card.instance).text.instances
            .singleWhere((ref) => ref.slot.left != card.slotId.left);
        assert(
          _stopped ||
              _plans.values.any(
                (plan) =>
                    plan.values[future.slot]?.id == card.conceptId &&
                    plan.outgoing.any(
                      (ref) =>
                          ref.slot == future.slot &&
                          ref.generation + 1 == future.generation,
                    ),
              ),
        );
        continue;
      }
      assert(
        _matched.contains(card.instance) == _matched.contains(partner.instance),
      );
      final l = _states[card.slotId]!.value, r = _states[partner.slotId]!.value;
      assert(l.interactive == r.interactive);
      assert(
        !l.interactive ||
            (l.visual.textOpacity >= readableOpacity &&
                r.visual.textOpacity >= readableOpacity),
      );
    }
    assert(_matched.every(_owns));
    assert(
      _selected == null || (_owns(_selected!) && !_matched.contains(_selected)),
    );
    final reserved = <MatchInstance>{};
    for (final plan in _plans.values) {
      assert(
        plan.outgoing.every(
          (ref) => _owns(ref) && _matched.contains(ref) && reserved.add(ref),
        ),
      );
      assert(plan.values.length == plan.groups.length * 2);
    }
    for (final visual in _visuals.values) {
      assert(_owns(visual.instance));
    }
    return true;
  }

  /// Terminal events freeze visuals, reject input and invalidate every callback.
  void stop() {
    if (_disposed || _stopped) return;
    final now = _now;
    _stoppedAt = _pausedAt ?? _clock();
    _stopped = true;
    _selected = null;
    _plans.clear();
    _cancelTimer();
    _publish(now);
  }

  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _cancelTimer();
    for (final state in _states.values) {
      state.dispose();
    }
    _plans.clear();
    _cycles.clear();
  }
}
