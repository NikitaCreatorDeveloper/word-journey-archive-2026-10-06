import 'dart:math';

import '../model/matching_card.dart';
import '../model/session_config.dart';
import '../model/session_state.dart';
import '../model/word_pair.dart';

enum MatchFeedback { correct, incorrect }

typedef BoardSlot = ({bool left, int row});

/// An immutable replacement plan. Only the engine chooses its words and slots.
class BoardTransition {
  BoardTransition._(
    this.token,
    Map<BoardSlot, MatchingCard> outgoing,
    Map<BoardSlot, MatchingCard?> incoming,
  ) : outgoing = Map.unmodifiable(outgoing),
      _incoming = Map.unmodifiable(incoming);
  final int token;
  final Map<BoardSlot, MatchingCard> outgoing;
  final Map<BoardSlot, MatchingCard?> _incoming;
  Set<BoardSlot> get slots => outgoing.keys.toSet();
}

/// Correct pairs stay on the board until a settled batch can replace them.
/// Every published board contains complete, unique concept pairs.
class MatchingEngine {
  MatchingEngine._(this.wordPool, SessionConfig config, this._random)
    : _left = List.filled(config.visiblePairs, null),
      _right = List.filled(config.visiblePairs, null),
      _state = SessionState(config: config);

  factory MatchingEngine.start({
    required List<WordPair> words,
    required SessionConfig config,
    Random? random,
  }) {
    if (words.length < config.wordPoolSize ||
        words.any((w) => w.id.isEmpty) ||
        words.map((w) => w.id).toSet().length != words.length) {
      throw ArgumentError('The source must contain enough unique word IDs');
    }
    final source = List<WordPair>.of(words)..shuffle(random ??= Random());
    return _create(
      List.unmodifiable(source.take(config.wordPoolSize)),
      config,
      random,
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
  final Map<int, ({int right, int streak})> _positionHistory = {};
  SessionState _state;
  BoardTransition? _batch;
  int _issued = 0;
  int _occurrence = 0;
  int _token = 0;

  SessionState get state => _state;
  SessionConfig get config => state.config;
  List<MatchingCard?> get leftCards => List.unmodifiable(_left);
  List<MatchingCard?> get rightCards => List.unmodifiable(_right);
  List<MatchingCard> get cards => List.unmodifiable([
    ..._left.whereType<MatchingCard>(),
    ..._right.whereType<MatchingCard>(),
  ]);
  List<BoardTransition> get transitions => List.unmodifiable([?_batch]);
  int get visiblePairCount => config.visiblePairs;
  int get totalPairCount => config.targetMatches;
  int get queuedPairCount => config.finishOnTarget
      ? totalPairCount - _issued
      : max(visiblePairCount, totalPairCount - _issued);
  int get activePairCount => _left
      .whereType<MatchingCard>()
      .where((c) => !_matched.contains(c.pairId))
      .length;
  int get availablePairCount => activePairCount;
  int get outstandingPairCount => activePairCount;
  int get inactivePairCount => _matched.length;
  int get matchedCount => state.matchedCount;
  int get errorCount => state.mistakes;
  double get progress => state.progress;
  bool get isComplete => state.isComplete;
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

  bool isActive(String id) =>
      !isComplete && _find(id) != null && !isMatched(id);
  void holdPointer(int pointer, String id) {
    if (isActive(id)) {
      _pointers[pointer] = id;
    }
  }

  void releasePointer(int pointer) {
    _pointers.remove(pointer);
    _scheduleBatch();
  }

  MatchFeedback? select(String id) {
    if (!isActive(id)) {
      return null;
    }
    final card = _find(id)!;
    final first = _find(selectedCardId);
    if (selectedCardId == id) {
      _update();
      return null;
    }
    if (first == null || first.language == card.language) {
      _update(selected: id);
      return null;
    }
    if (first.pairId != card.pairId) {
      _update(mistakes: errorCount + 1);
      return MatchFeedback.incorrect;
    }
    _matched.add(card.pairId);
    _update(matches: matchedCount + 1);
    assert(debugValidate());
    return MatchFeedback.correct;
  }

  /// Acknowledges the short matched feedback, without a timer in game logic.
  /// Either half can acknowledge; old or repeated callbacks have no effect.
  void settlePair(String pairId) {
    if (!_matched.contains(pairId) || !_settled.add(pairId)) {
      return;
    }
    _scheduleBatch();
  }

  void expireTimeLimit() {
    if (!config.isTimed || isComplete) {
      return;
    }
    _state = SessionState(
      config: config,
      matchedCount: matchedCount,
      mistakes: errorCount,
      timedOut: true,
    );
    assert(debugValidate());
  }

  void _update({int? matches, int? mistakes, String? selected}) {
    _state = SessionState(
      config: config,
      matchedCount: matches ?? matchedCount,
      mistakes: mistakes ?? errorCount,
      selectedCardId: selected,
      timedOut: state.timedOut,
    );
  }

  List<MatchingCard> _issue(Set<String> occupied, Set<String> recent) {
    var choices = wordPool.where((w) => !occupied.contains(w.id)).toList();
    final alternatives = choices.where((w) => !recent.contains(w.id)).toList();
    if (alternatives.isNotEmpty) {
      choices = alternatives;
    }
    final least = choices.map((w) => _uses[w.id] ?? 0).reduce(min);
    choices = choices.where((w) => (_uses[w.id] ?? 0) == least).toList();
    final word = choices[_random.nextInt(choices.length)];
    _uses[word.id] = least + 1;
    occupied.add(word.id);
    final occurrence = _occurrence++;
    return [
      MatchingCard.fromWord(word, CardLanguage.english, occurrence: occurrence),
      MatchingCard.fromWord(word, CardLanguage.russian, occurrence: occurrence),
    ];
  }

  void _scheduleBatch() {
    if (_batch != null || queuedPairCount == 0 || isComplete) {
      return;
    }
    final heldPairs = {
      for (final id in _pointers.values)
        if (_find(id) case final c?) c.pairId,
    };
    final eligible = _matched
        .where((id) => _settled.contains(id) && !heldPairs.contains(id))
        .toList();
    // Normally two; a last odd batch of three avoids an obvious single refill.
    final count = min(visiblePairCount, queuedPairCount == 3 ? 3 : 2);
    if (eligible.length < count) {
      return;
    }
    final retiring = eligible.take(count).toSet();
    final outgoing = <BoardSlot, MatchingCard>{
      for (var row = 0; row < visiblePairCount; row++) ...{
        if (_left[row] case final c? when retiring.contains(c.pairId))
          (left: true, row: row): c,
        if (_right[row] case final c? when retiring.contains(c.pairId))
          (left: false, row: row): c,
      },
    };
    final leftSlots = outgoing.keys.where((s) => s.left).toList()
      ..shuffle(_random);
    final rightSlots = outgoing.keys.where((s) => !s.left).toList()
      ..shuffle(_random);
    final newCount = min(count, queuedPairCount);
    final occupied = cards
        .where((c) => !retiring.contains(c.pairId))
        .map((c) => c.conceptId)
        .toSet();
    final recent = outgoing.values.map((c) => c.conceptId).toSet();
    final pairs = [for (var i = 0; i < newCount; i++) _issue(occupied, recent)];
    final chosenLeft = leftSlots.take(newCount).toList();
    final permutations = _permutations(rightSlots).toList()..shuffle(_random);
    // Random layouts remain random, but no slot connection can repeat forever.
    // With 2+ incoming pairs there is always a permutation avoiding a third repeat.
    final chosenRight = permutations.firstWhere(
      (rows) => List.generate(newCount, (i) => i).every((i) {
        final old = _positionHistory[chosenLeft[i].row];
        return old == null || old.right != rows[i].row || old.streak < 2;
      }),
      orElse: () =>
          permutations.first, // finite one-pair tail / one-slot config
    );
    final incoming = <BoardSlot, MatchingCard?>{
      for (final s in outgoing.keys) s: null,
    };
    for (var i = 0; i < newCount; i++) {
      incoming[chosenLeft[i]] = pairs[i][0];
      incoming[chosenRight[i]] = pairs[i][1];
    }
    _batch = BoardTransition._(++_token, outgoing, incoming);
    assert(debugValidate());
  }

  Iterable<List<BoardSlot>> _permutations(List<BoardSlot> slots) sync* {
    if (slots.isEmpty) {
      yield [];
      return;
    }
    for (final slot in slots) {
      for (final tail in _permutations(
        slots.where((s) => s != slot).toList(),
      )) {
        yield [slot, ...tail];
      }
    }
  }

  /// Atomic swap after the batch fade-out. Stale tokens cannot affect later batches.
  void completeTransition(int token) {
    final batch = _batch;
    if (batch == null || batch.token != token) {
      return;
    }
    for (final c in batch.outgoing.values) {
      _matched.remove(c.pairId);
      _settled.remove(c.pairId);
    }
    for (final entry in batch._incoming.entries) {
      (entry.key.left ? _left : _right)[entry.key.row] = entry.value;
    }
    _issued += batch._incoming.entries
        .where((e) => e.key.left && e.value != null)
        .length;
    for (final entry in batch._incoming.entries.where(
      (e) => e.key.left && e.value != null,
    )) {
      _recordPosition(entry.key.row);
    }
    _batch = null;
    assert(debugValidate());
    _scheduleBatch();
  }

  void _recordPosition(int leftRow) {
    final rightRow = _right.indexWhere(
      (c) => c?.pairId == _left[leftRow]!.pairId,
    );
    final old = _positionHistory[leftRow];
    _positionHistory[leftRow] = (
      right: rightRow,
      streak: old?.right == rightRow ? old!.streak + 1 : 1,
    );
  }

  bool debugValidate() {
    final l = _left.whereType<MatchingCard>().toList();
    final r = _right.whereType<MatchingCard>().toList();
    assert(l.length == r.length);
    assert(l.map((c) => c.conceptId).toSet().length == l.length);
    assert(r.map((c) => c.conceptId).toSet().length == r.length);
    for (final c in l) {
      assert(
        r
                .where(
                  (other) =>
                      other.conceptId == c.conceptId &&
                      other.pairId == c.pairId,
                )
                .length ==
            1,
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
    if (_batch case final batch?) {
      assert(batch.outgoing.values.every((c) => _settled.contains(c.pairId)));
      assert(
        batch.outgoing.entries.every(
          (e) => identical((e.key.left ? _left : _right)[e.key.row], e.value),
        ),
      );
    }
    return true;
  }

  MatchingEngine replay() => _create(wordPool, config, _random);
  static MatchingEngine _create(
    List<WordPair> pool,
    SessionConfig config,
    Random random,
  ) {
    final g = MatchingEngine._(pool, config, random);
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
    for (var i = 0; i < g._left.length; i++) {
      if (g._left[i] != null) {
        g._recordPosition(i);
      }
    }
    assert(g.debugValidate());
    return g;
  }
}
