import 'dart:async';
import 'dart:math';

import '../model/matching_card.dart';
import '../model/session_config.dart';
import '../model/session_state.dart';
import '../model/session_result.dart';
import '../model/word_pair.dart';
import 'match_flow_controller.dart';

enum MatchFeedback { correct, incorrect }

/// A stable slot identity; replacing its content never changes its coordinate.
typedef BoardSlot = ({bool left, int row});

/// An immutable replacement plan. Only the engine chooses its words and slots.
class BoardTransition {
  BoardTransition._(
    this.token,
    List<String> retiringPairIds,
    Map<BoardSlot, MatchingCard> outgoing,
    Map<BoardSlot, MatchingCard> incoming,
  ) : retiringPairIds = List.unmodifiable(retiringPairIds),
      outgoing = Map.unmodifiable(outgoing),
      incoming = Map.unmodifiable(incoming);

  final int token;
  final List<String> retiringPairIds;
  bool get isCrossRefill => retiringPairIds.length == 2;
  final Map<BoardSlot, MatchingCard> outgoing;
  final Map<BoardSlot, MatchingCard> incoming;
  bool _committed = false;
  bool get committed => _committed;
  Set<BoardSlot> get slots => outgoing.keys.toSet();
}

/// Two accepted matches refill their four slots with two crossed concept pairs.
/// Active unmatched cards keep their objects and slot identities until matched.
class MatchingEngine {
  MatchingEngine._(
    this.wordPool,
    SessionConfig config,
    this._random,
    this._difficulty,
  ) : _left = List.filled(config.visiblePairs, null),
      _right = List.filled(config.visiblePairs, null),
      _state = SessionState(config: config);

  factory MatchingEngine.start({
    required List<WordPair> words,
    required SessionConfig config,
    Random? random,
    Map<String, int> priorities = const {},
  }) {
    if (words.length < config.wordPoolSize ||
        words.any(
          (w) =>
              w.id.isEmpty ||
              w.english.trim().isEmpty ||
              w.russian.trim().isEmpty,
        ) ||
        words.map((w) => w.id).toSet().length != words.length) {
      throw ArgumentError('The source must contain enough unique word IDs');
    }
    for (final labels in [
      words.map((w) => w.english.toLowerCase().trim()),
      words.map((w) => w.russian.toLowerCase().trim()),
    ]) {
      if (labels.toSet().length != labels.length) {
        throw ArgumentError(
          'Ambiguous visible answers; supply context or separate these concepts',
        );
      }
    }
    if (config.visiblePairs < 2 &&
        (!config.finishOnTarget ||
            config.targetMatches > config.visiblePairs)) {
      throw ArgumentError('Cross-refill requires at least two visible pairs');
    }
    final source = List<WordPair>.of(words)..shuffle(random ??= Random());
    return _create(
      List.unmodifiable(source.take(config.wordPoolSize)),
      config,
      random,
      Map.of(priorities),
    );
  }

  final List<WordPair> wordPool;
  final Random _random;
  final List<MatchingCard?> _left;
  final List<MatchingCard?> _right;
  final Set<String> _matched = {};
  final Set<String> _settled = {};
  final Map<int, String> _pointers = {};
  final Map<String, int> _uses = {};
  final Map<String, int> _difficulty;
  final Map<String, int> _lastMatchedAt = {};
  SessionState _state;
  SessionResult? _result;
  SessionResult? get result => _result;
  final Map<int, BoardTransition> _transitions = {};
  int _issued = 0;
  int _occurrence = 0;
  int _token = 0;
  MatchFlowController? _flow;
  MatchFlowController? get matchFlow => _flow;
  final Map<MatchInstance, MatchingCard> _flowCards = {};

  /// Production uses the exact scheduler proven in Match Flow Lab. The session
  /// still owns scoring, adaptive word choice, its deadline and persisted events.
  void enableMatchFlow({
    Duration Function()? now,
    bool autoSchedule = true,
    Timer Function(Duration, void Function())? timerFactory,
  }) {
    if (_flow != null) return;
    final concepts = {
      for (final w in wordPool) w.id: MatchConcept(w.id, w.english, w.russian),
    };
    final seed = <MatchSlotId, MatchConcept>{};
    for (var row = 0; row < visiblePairCount; row++) {
      for (final left in [true, false]) {
        final slot = (left: left, row: row),
            card = cardAt((left: left, row: row));
        if (card == null) continue;
        seed[slot] = concepts[card.conceptId]!;
        _flowCards[(slot: slot, generation: 1)] = card;
      }
    }
    _transitions.clear();
    _flow = MatchFlowController(
      pool: concepts.values.toList(),
      visiblePairs: visiblePairCount,
      maxIssuedPairs: config.finishOnTarget ? totalPairCount : null,
      initialBoard: seed,
      nextOccurrence: _occurrence,
      random: _random,
      now: now,
      autoSchedule: autoSchedule,
      timerFactory: timerFactory,
      errorFeedback: true,
      pickConcept: (occupied, recent) =>
          concepts[_pickWord(occupied, recent).id]!,
      onFrame: _syncMatchFlow,
    );
    _syncMatchFlow();
    if (isComplete) _flow!.stop();
    assert(debugValidate());
  }

  void _syncMatchFlow() {
    final flow = _flow!;
    final frame = flow.states;
    final present = <MatchInstance>{};
    _matched.clear();
    for (final state in frame.values) {
      final content = state.content, slot = content.slotId;
      present.add(content.instance);
      final card = content.isEmpty
          ? null
          : _flowCards.putIfAbsent(content.instance, () {
              final word = wordPool.singleWhere(
                (w) => w.id == content.conceptId,
              );
              return MatchingCard.fromWord(
                word,
                slot.left ? CardLanguage.english : CardLanguage.russian,
                occurrence: content.occurrence,
              );
            });
      (slot.left ? _left : _right)[slot.row] = card;
      if (state.matched && card != null) _matched.add(card.pairId);
    }
    _flowCards.removeWhere((ref, _) => !present.contains(ref));
    _issued = flow.issuedCount;
    final selected = flow.selected == null
        ? null
        : _flowCards[flow.selected]?.id;
    if (selectedCardId != selected) _update(selected: selected);
  }

  void disposeMatchFlow() => _flow?.dispose();

  SessionState get state => _state;
  SessionConfig get config => state.config;
  List<MatchingCard?> get leftCards => List.unmodifiable(_left);
  List<MatchingCard?> get rightCards => List.unmodifiable(_right);
  List<MatchingCard> get cards => List.unmodifiable([
    ..._left.whereType<MatchingCard>(),
    ..._right.whereType<MatchingCard>(),
  ]);
  List<BoardTransition> get transitions =>
      List.unmodifiable(_transitions.values);
  int get visiblePairCount => config.visiblePairs;
  int get totalPairCount => config.targetMatches;
  int get queuedPairCount => config.finishOnTarget
      ? totalPairCount - _issued
      : max(visiblePairCount, totalPairCount - _issued);
  int get activePairCount => _left
      .whereType<MatchingCard>()
      .where(
        (c) => _flow == null ? !_matched.contains(c.pairId) : isActive(c.id),
      )
      .length;
  int get availablePairCount => activePairCount;
  int get outstandingPairCount => activePairCount;
  int get inactivePairCount => _matched.length;
  List<String> get matchedPairIds => List.unmodifiable(_matched);
  int get matchedCount => state.matchedCount;
  int get errorCount => state.mistakes;
  double get progress => state.progress;
  bool get isComplete => _result != null || state.isComplete;
  String? get selectedCardId => state.selectedCardId;

  MatchingCard? _find(String? id) {
    for (final c in cards) {
      if (c.id == id) {
        return c;
      }
    }
    return null;
  }

  bool isMatched(String id) {
    final c = _find(id);
    return c != null && _matched.contains(c.pairId);
  }

  MatchingCard? cardAt(BoardSlot slot) =>
      (slot.left ? _left : _right)[slot.row];

  BoardSlot? slotIdOf(String cardId) {
    for (var row = 0; row < visiblePairCount; row++) {
      if (_left[row]?.id == cardId) return (left: true, row: row);
      if (_right[row]?.id == cardId) return (left: false, row: row);
    }
    return null;
  }

  bool isReplacingSlot(BoardSlot slot) =>
      _transitions.values.any((t) => t.slots.contains(slot));

  bool get transitionReady {
    return isTransitionReady(_transitions.values.firstOrNull?.token);
  }

  bool isTransitionReady(int? token) {
    final transition = _transitions[token];
    return transition != null &&
        transition.retiringPairIds.every(_settled.contains) &&
        !_pointers.values.any(
          (id) => transition.retiringPairIds.contains(_find(id)?.pairId),
        );
  }

  bool isActive(String id) {
    if (_flow case final flow?) {
      final slot = slotIdOf(id);
      return !isComplete &&
          slot != null &&
          flow.stateOf(slot).value.interactive;
    }
    return !isComplete &&
        _find(id) != null &&
        !isMatched(id) &&
        !_transitions.values.any(
          (t) => t.committed && t.slots.any((slot) => cardAt(slot)?.id == id),
        );
  }

  void holdPointer(int pointer, String id) {
    if (isActive(id)) {
      _pointers[pointer] = id;
      if (_flow == null) _scheduleRefill();
    }
  }

  void releasePointer(int pointer) {
    _pointers.remove(pointer);
    if (_flow == null) _scheduleRefill();
  }

  MatchFeedback? select(String id) {
    if (_flow case final flow?) {
      if (!isActive(id)) return null;
      final slot = slotIdOf(id)!, card = cardAt(slot)!;
      final first = _find(selectedCardId);
      final feedback = flow.select(
        slot,
        flow.stateOf(slot).value.content.generation,
      );
      if (feedback == FlowFeedback.incorrect) {
        _difficulty[first!.conceptId] = min(
          3,
          (_difficulty[first.conceptId] ?? 0) + 1,
        );
        _update(mistakes: errorCount + 1);
        return MatchFeedback.incorrect;
      }
      if (feedback != FlowFeedback.correct) return null;
      _update(matches: matchedCount + 1);
      _lastMatchedAt[card.conceptId] = matchedCount;
      _difficulty[card.conceptId] = max(
        0,
        (_difficulty[card.conceptId] ?? 0) - 1,
      );
      if (isComplete) flow.stop();
      assert(debugValidate());
      return MatchFeedback.correct;
    }
    if (!isActive(id)) {
      return null;
    }
    final card = _find(id)!;
    final first = _find(selectedCardId);
    if (selectedCardId == id) {
      _update();
      _scheduleRefill();
      return null;
    }
    if (first == null || first.language == card.language) {
      _update(selected: id);
      _scheduleRefill();
      return null;
    }
    if (!first.isPartnerOf(card)) {
      _difficulty[first.conceptId] = min(
        3,
        (_difficulty[first.conceptId] ?? 0) + 1,
      );
      _update(mistakes: errorCount + 1);
      _scheduleRefill();
      return MatchFeedback.incorrect;
    }
    _matched.add(card.pairId);
    _update(matches: matchedCount + 1);
    _lastMatchedAt[card.conceptId] = matchedCount;
    _difficulty[card.conceptId] = max(
      0,
      (_difficulty[card.conceptId] ?? 0) - 1,
    );
    // A newer accepted match wins over an uncommitted fallback. Its old token
    // can no longer write to the same slots, even at the deadline boundary.
    _transitions.removeWhere((_, t) => !t.isCrossRefill && !t.committed);
    if (isComplete) {
      _transitions.clear();
      _pointers.clear();
    } else {
      _scheduleRefill();
    }
    assert(debugValidate());
    return MatchFeedback.correct;
  }

  /// Acknowledges the short matched feedback, without a timer in game logic.
  /// Either half can acknowledge; old or repeated callbacks have no effect.
  void settlePair(String pairId) {
    if (_flow != null) return;
    if (!_matched.contains(pairId) || !_settled.add(pairId)) {
      return;
    }
    _scheduleRefill();
  }

  /// The only result-writing path. Later terminal events return the same snapshot.
  SessionResult endSession({
    required SessionEndReason reason,
    required Duration elapsedTime,
    required Duration? remainingTime,
  }) {
    if (_result case final result?) {
      return result;
    }
    // A goal already accepted before a timeout cannot be overwritten.
    final endReason = config.finishOnTarget && matchedCount >= totalPairCount
        ? SessionEndReason.targetReached
        : reason;
    assert(
      endReason != SessionEndReason.targetReached ||
          matchedCount >= totalPairCount,
    );
    _transitions.clear();
    _pointers.clear();
    _state = SessionState(
      config: config,
      matchedCount: matchedCount,
      mistakes: errorCount,
      timedOut: endReason == SessionEndReason.timeExpired,
      endReason: endReason,
    );
    _result = SessionResult(
      targetMatches: totalPairCount,
      completedMatches: matchedCount,
      wrongAttempts: errorCount,
      elapsedTime: elapsedTime,
      remainingTime: remainingTime,
      endReason: endReason,
    );
    _flow?.stop();
    assert(debugValidate());
    return _result!;
  }

  void expireTimeLimit() {
    if (!config.isTimed) return;
    endSession(
      reason: SessionEndReason.timeExpired,
      elapsedTime: Duration(seconds: config.timeLimitSeconds!),
      remainingTime: Duration.zero,
    );
  }

  void _update({int? matches, int? mistakes, String? selected}) {
    _state = SessionState(
      config: config,
      matchedCount: matches ?? matchedCount,
      mistakes: mistakes ?? errorCount,
      selectedCardId: selected,
      timedOut: state.timedOut,
      endReason: state.endReason,
    );
  }

  WordPair _pickWord(Set<String> occupied, Set<String> recent) {
    var choices = wordPool.where((w) => !occupied.contains(w.id)).toList();
    final alternatives = choices.where((w) => !recent.contains(w.id)).toList();
    if (alternatives.isNotEmpty) {
      choices = alternatives;
    }
    final cooled = choices
        .where(
          (w) =>
              !_lastMatchedAt.containsKey(w.id) ||
              matchedCount - _lastMatchedAt[w.id]! >= 3,
        )
        .toList();
    if (cooled.isNotEmpty) {
      choices = cooled; // finite small-pool fallback keeps pairs valid
    }
    final least = choices.map((w) => _uses[w.id] ?? 0).reduce(min);
    final hasPriority = choices.any((w) => (_difficulty[w.id] ?? 0) > 0);
    choices = choices
        .where((w) => (_uses[w.id] ?? 0) <= least + (hasPriority ? 1 : 0))
        .toList();
    final total = choices.fold<int>(
      0,
      (n, w) => n + 1 + (_difficulty[w.id] ?? 0),
    );
    var pick = _random.nextInt(total);
    var word = choices.last;
    for (final candidate in choices) {
      pick -= 1 + (_difficulty[candidate.id] ?? 0);
      if (pick < 0) {
        word = candidate;
        break;
      }
    }
    _uses[word.id] = (_uses[word.id] ?? 0) + 1;
    occupied.add(word.id);
    return word;
  }

  List<MatchingCard> _issue(Set<String> occupied, Set<String> recent) {
    final word = _pickWord(occupied, recent);
    final occurrence = _occurrence++;
    return [
      MatchingCard.fromWord(word, CardLanguage.english, occurrence: occurrence),
      MatchingCard.fromWord(word, CardLanguage.russian, occurrence: occurrence),
    ];
  }

  int get _refillBudget =>
      queuedPairCount -
      _transitions.values
          .where((t) => !t.committed)
          .fold<int>(0, (n, t) => n + t.retiringPairIds.length);

  void _scheduleRefill() {
    if (_flow != null || isComplete) return;
    final reserved = _transitions.values
        .expand((t) => t.retiringPairIds)
        .toSet();
    final waiting = _matched.where((id) => !reserved.contains(id)).toList();
    while (waiting.length >= 2 && _refillBudget >= 2) {
      _planCrossRefill(waiting.take(2).toList());
      waiting.removeRange(0, 2);
    }
  }

  Set<String> _occupiedExcept(List<String> retiring) => {
    for (final c in cards)
      if (!retiring.contains(c.pairId)) c.conceptId,
    for (final t in _transitions.values)
      for (final c in t.incoming.values) c.conceptId,
  };

  void _planCrossRefill(List<String> retiring) {
    final outgoing = <BoardSlot, MatchingCard>{
      for (var row = 0; row < visiblePairCount; row++) ...{
        if (_left[row] case final c? when retiring.contains(c.pairId))
          (left: true, row: row): c,
        if (_right[row] case final c? when retiring.contains(c.pairId))
          (left: false, row: row): c,
      },
    };
    BoardSlot slotOf(String pairId, bool left) => outgoing.keys.singleWhere(
      (slot) => slot.left == left && outgoing[slot]!.pairId == pairId,
    );
    final occupied = _occupiedExcept(retiring);
    final recent = outgoing.values.map((c) => c.conceptId).toSet();
    final x = _issue(occupied, recent), y = _issue(occupied, recent);
    final incoming = <BoardSlot, MatchingCard>{
      slotOf(retiring[0], true): x[0],
      slotOf(retiring[0], false): y[1],
      slotOf(retiring[1], true): y[0],
      slotOf(retiring[1], false): x[1],
    };
    // Only already matched slots enter the plan. No active source is reserved.
    final plan = BoardTransition._(++_token, retiring, outgoing, incoming);
    _transitions[plan.token] = plan;
    assert(debugValidate());
  }

  /// A slow waiting deadline may issue one complete pair in the same two slots.
  /// Cross-refill has priority. A finite session's last queued pair also uses
  /// this deadline path, without exceeding its target or touching active cards.
  bool requestFallback(String pairId) {
    if (_flow != null ||
        isComplete ||
        _refillBudget <= 0 ||
        !_matched.contains(pairId) ||
        _transitions.values.any((t) => t.retiringPairIds.contains(pairId))) {
      return false;
    }
    final outgoing = <BoardSlot, MatchingCard>{
      for (var row = 0; row < visiblePairCount; row++) ...{
        if (_left[row] case final c? when c.pairId == pairId)
          (left: true, row: row): c,
        if (_right[row] case final c? when c.pairId == pairId)
          (left: false, row: row): c,
      },
    };
    final occupied = _occupiedExcept([pairId]);
    final pair = _issue(
      occupied,
      outgoing.values.map((c) => c.conceptId).toSet(),
    );
    final incoming = <BoardSlot, MatchingCard>{
      for (final slot in outgoing.keys) slot: pair[slot.left ? 0 : 1],
    };
    final plan = BoardTransition._(++_token, [pairId], outgoing, incoming);
    _transitions[plan.token] = plan;
    assert(debugValidate());
    return true;
  }

  void cancelRefillPlans() {
    _flow?.stop();
    _transitions.clear();
    _pointers.clear();
  }

  /// A nearly finished return can keep its deadline by returning a complete
  /// pair, rather than rushing another group's confirmation into that swap.
  void splitTransition(int token) {
    if (_flow != null) return;
    final plan = _transitions[token];
    if (plan == null || plan.committed || !plan.isCrossRefill) return;
    _transitions.remove(token);
    for (final id in plan.retiringPairIds) {
      requestFallback(id);
    }
  }

  /// The neutral animation phase commits every changed slot in one publication.
  /// Reserved slots remain input-disabled until completeTransition.
  void commitTransition(int token) {
    if (_flow != null) return;
    final transition = _transitions[token];
    if (transition == null ||
        transition.token != token ||
        transition.committed ||
        !isTransitionReady(token) ||
        isComplete) {
      return;
    }
    if (!transition.outgoing.entries.every(
      (entry) =>
          identical(cardAt(entry.key), entry.value) &&
          _matched.contains(entry.value.pairId),
    )) {
      return;
    }
    _matched.removeAll(transition.retiringPairIds);
    _settled.removeAll(transition.retiringPairIds);
    for (final entry in transition.incoming.entries) {
      (entry.key.left ? _left : _right)[entry.key.row] = entry.value;
    }
    _issued += transition.retiringPairIds.length;
    transition._committed = true;
    assert(debugValidate());
  }

  /// Finishes the fade-in. Old tokens and callbacks after session end are inert.
  /// Nonvisual callers can commit and finish an entire ready refill at once.
  void completeTransition(int token) {
    if (_flow != null) return;
    final transition = _transitions[token];
    if (transition == null || transition.token != token || isComplete) return;
    if (!transition.committed) commitTransition(token);
    if (!transition.committed) return;
    _transitions.remove(token);
    _scheduleRefill();
    assert(debugValidate());
  }

  bool debugValidate() {
    if (_flow case final flow?) {
      assert(flow.debugValidate());
      assert(_transitions.isEmpty);
      assert(cards.map((c) => c.id).toSet().length == cards.length);
      assert(!config.finishOnTarget || _issued <= totalPairCount);
      assert(
        matchedCount >= 0 &&
            (!config.finishOnTarget || matchedCount <= totalPairCount),
      );
      assert(
        selectedCardId == null ||
            (_find(selectedCardId) != null && !isMatched(selectedCardId!)),
      );
      for (final c in cards.where((c) => isActive(c.id))) {
        assert(
          cards
                  .where(
                    (p) =>
                        p.isPartnerOf(c) &&
                        p.pairId == c.pairId &&
                        isActive(p.id),
                  )
                  .length ==
              1,
        );
      }
      return true;
    }
    final l = _left.whereType<MatchingCard>().toList();
    final r = _right.whereType<MatchingCard>().toList();
    assert(l.length == r.length);
    assert(l.map((c) => c.conceptId).toSet().length == l.length);
    assert(r.map((c) => c.conceptId).toSet().length == r.length);
    for (final c in l) {
      assert(
        r.where((other) => other.isPartnerOf(c)).length == 1,
        'Orphan or duplicate pair',
      );
    }
    assert(l.length <= visiblePairCount);
    assert(cards.map((c) => c.id).toSet().length == cards.length);
    assert(_matched.every((id) => l.any((c) => c.pairId == id)));
    assert(_settled.every(_matched.contains));
    assert(matchedCount + activePairCount == _issued);
    assert(!config.finishOnTarget || _issued <= totalPairCount);
    assert(selectedCardId == null || isActive(selectedCardId!));
    assert(
      matchedCount >= 0 &&
          (!config.finishOnTarget || matchedCount <= totalPairCount),
    );
    final reservedSlots = <BoardSlot>{};
    for (final transition in _transitions.values) {
      assert(
        transition.slots.every(reservedSlots.add),
        'A slot is reserved twice',
      );
      assert(!isComplete);
      assert(transition.slots.length == transition.retiringPairIds.length * 2);
      assert(transition.incoming.keys.toSet().containsAll(transition.slots));
      assert(transition.incoming.length == transition.outgoing.length);
      assert(
        transition.incoming.values.map((c) => c.id).toSet().length ==
            transition.slots.length,
      );
      assert(
        transition.incoming.values.map((c) => c.conceptId).toSet().length ==
            transition.retiringPairIds.length,
      );
      for (final c in transition.incoming.values) {
        assert(transition.incoming.values.where(c.isPartnerOf).length == 1);
        assert(!transition.outgoing.values.contains(c));
      }
      if (transition.isCrossRefill) {
        for (final pairId in transition.retiringPairIds) {
          final slots = transition.outgoing.entries
              .where((e) => e.value.pairId == pairId)
              .map((e) => e.key);
          assert(
            slots
                    .map((s) => transition.incoming[s]!.conceptId)
                    .toSet()
                    .length ==
                2,
          );
        }
      }
      if (transition.committed) {
        assert(
          transition.incoming.entries.every(
            (e) => identical(cardAt(e.key), e.value),
          ),
        );
        assert(
          transition.retiringPairIds.every((id) => !_matched.contains(id)),
        );
      } else {
        assert(transition.retiringPairIds.every(_matched.contains));
        assert(
          transition.outgoing.values.every((c) => _matched.contains(c.pairId)),
        );
        assert(
          transition.outgoing.entries.every(
            (e) => identical(cardAt(e.key), e.value),
          ),
        );
      }
    }
    return true;
  }

  MatchingEngine replay() =>
      _create(wordPool, config, _random, Map.of(_difficulty));
  static MatchingEngine _create(
    List<WordPair> pool,
    SessionConfig config,
    Random random,
    Map<String, int> priorities,
  ) {
    final g = MatchingEngine._(pool, config, random, priorities);
    final occupied = <String>{};
    for (
      var i = 0;
      i <
          min(
            config.visiblePairs,
            config.finishOnTarget ? config.targetMatches : config.visiblePairs,
          );
      i++
    ) {
      final pair = g._issue(occupied, {});
      g._left[i] = pair[0];
      g._right[i] = pair[1];
      g._issued++;
    }
    g._left.shuffle(random);
    g._right.shuffle(random);
    assert(g.debugValidate());
    return g;
  }
}
