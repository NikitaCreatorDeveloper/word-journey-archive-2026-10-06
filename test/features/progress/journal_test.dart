import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:word_journey/features/progress/trainer_data.dart';
import 'package:word_journey/features/progress/trainer_store.dart';
import 'package:word_journey/features/progress/session_journal.dart';
import 'package:word_journey/features/progress/practice_event.dart';
import 'package:word_journey/features/training/logic/matching_engine.dart';
import 'package:word_journey/features/training/logic/training_session.dart';
import 'package:word_journey/features/training/model/session_config.dart';
import 'package:word_journey/features/training/model/session_result.dart';
import 'package:word_journey/features/training/model/test_words.dart';

MatchingEngine createGame({bool challenge = false}) => MatchingEngine.start(
  words: testWords,
  random: Random(8),
  config: SessionConfig(
    visiblePairs: 4,
    wordPoolSize: 12,
    targetMatches: 60,
    maxMistakes: 5,
    enforceMistakeLimit: challenge,
    mode: SessionMode.practice,
  ),
);
void main() {
  test('Exposure is per pair occurrence, wrong belongs to first choice, answer callback is idempotent', () async {
    final data = TrainerData(store: MemoryTrainerStore());
    await data.load();
    final game = createGame();
    final j = SessionJournal(data, game)
      ..exposeBoard()
      ..exposeBoard();
    await data.flush();
    expect(
      data.events.where((e) => e.kind == PracticeKind.exposure),
      hasLength(4),
    );
    final a = game.leftCards.first!,
        bad = game.rightCards.firstWhere((c) => c!.conceptId != a.conceptId)!;
    game.select(a.id);
    final wrong = game.select(bad.id)!;
    j.answer(wrong, a.id, bad.id, Duration.zero);
    await data.flush();
    expect(data.progress[a.conceptId]!.wrongAttempts, 1);
    expect(data.progress[bad.conceptId]!.wrongAttempts, 0);
    final b = game.rightCards.firstWhere((c) => c!.conceptId == a.conceptId)!;
    game.select(a.id);
    final correct = game.select(b.id)!;
    j.answer(correct, a.id, b.id, Duration.zero);
    j.answer(correct, a.id, b.id, Duration.zero);
    await data.flush();
    expect(data.progress[a.conceptId]!.matchCorrect, 1);
    expect(j.bestCombo, 1);
    final result = game.endSession(
      reason: SessionEndReason.userExited,
      elapsedTime: Duration.zero,
      remainingTime: null,
    );
    await j.finish(result);
    await j.finish(result);
    expect(data.sessions, hasLength(1));
    expect(data.sessions.single['completed'], isFalse);
    data.dispose();
  });
  test('Optional fifth error ends once; normal mode remains unlimited', () {
    for (final challenge in [false, true]) {
      final game = createGame(challenge: challenge);
      final s = TrainingSession(game)..resume();
      final a = game.leftCards.first!,
          b = game.rightCards.firstWhere((c) => c!.conceptId != a.conceptId)!;
      for (var i = 0; i < 5; i++) {
        s.select(a.id);
        s.select(b.id);
      }
      if (challenge) {
        final result = s.result!;
        expect(result.endReason, SessionEndReason.mistakeLimit);
        expect(s.select(a.id), isNull);
        expect(s.endSession(SessionEndReason.userExited), same(result));
        expect(game.errorCount, 5);
      } else {
        expect(s.result, isNull);
        s.select(a.id);
        s.select(b.id);
        expect(game.errorCount, 6);
      }
    }
  });
}
