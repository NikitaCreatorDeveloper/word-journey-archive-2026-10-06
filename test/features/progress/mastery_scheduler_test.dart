import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:word_journey/features/progress/practice_event.dart';
import 'package:word_journey/features/progress/mastery_policy.dart';
import 'package:word_journey/features/review/adaptive_word_scheduler.dart';
import 'package:word_journey/features/review/recall_screen.dart';
import 'package:word_journey/features/settings/trainer_settings.dart';
import 'package:word_journey/features/vocabulary/vocabulary_repository.dart';
import 'package:word_journey/features/training/logic/matching_engine.dart';
import 'package:word_journey/features/training/model/session_config.dart';
import 'package:word_journey/features/training/model/test_words.dart';

import '../training/matching_engine_test.dart' as board;
import '../training/session_clock_test.dart' as clock;

PracticeEvent event(
  String id,
  PracticeKind kind,
  DateTime at, {
  String session = 's1',
  int index = 0,
}) => PracticeEvent(
  id: id,
  sessionId: session,
  conceptId: 'word',
  kind: kind,
  at: at,
  index: index,
);
void main() {
  test(
    'Many same-day repeats do not confer delayed mastery or ladder steps',
    () {
      final day = DateTime.utc(2026, 10, 1, 12);
      final es = [
        for (var i = 0; i < 30; i++)
          event(
            '$i',
            PracticeKind.matchCorrect,
            day.add(Duration(seconds: i)),
            index: i * 4,
          ),
      ];
      final p = WordProgress('word', es);
      expect(p.mastery.label, 'Узнаю');
      expect(p.firstConsolidatedAt, isNull);
      expect(p.recognitionStage, 0);
      expect(p.recallCorrect, 0);
    },
  );
  test(
    '24-hour due success before a hint consolidates once and one step per day',
    () {
      final day = DateTime.utc(2026, 10, 1, 12);
      final es = [
        for (var i = 0; i < 5; i++)
          event(
            '$i',
            PracticeKind.matchCorrect,
            day.add(Duration(seconds: i)),
            index: i * 4,
          ),
        event(
          'due',
          PracticeKind.matchCorrect,
          day.add(const Duration(days: 1, minutes: 1)),
          session: 's2',
        ),
      ];
      final p = WordProgress('word', es);
      expect(p.firstConsolidatedAt, es.last.at);
      expect(p.recognitionStage, 1);
      final more = WordProgress('word', [
        ...es,
        event(
          'early',
          PracticeKind.matchCorrect,
          day.add(const Duration(days: 1, minutes: 2)),
          session: 's3',
        ),
      ]);
      expect(more.recognitionStage, 1);
      expect(more.firstConsolidatedAt, p.firstConsolidatedAt);
      expect(more.recognitionDueAt, p.recognitionDueAt);
    },
  );
  test('Hinted due response is training; recognition/recall schedules are independent', () {
    final day = DateTime.utc(2026, 10, 1, 12);
    final es = [
      for (var i = 0; i < 5; i++)
        event(
          '$i',
          PracticeKind.matchCorrect,
          day.add(Duration(seconds: i)),
          index: i * 4,
        ),
      event('hint', PracticeKind.hint, day.add(const Duration(days: 1))),
      event(
        'due',
        PracticeKind.matchCorrect,
        day.add(const Duration(days: 1, minutes: 1)),
        session: 's2',
      ),
      event(
        'recall',
        PracticeKind.recallCorrect,
        day.add(const Duration(days: 2)),
        session: 'r',
      ),
    ];
    final p = WordProgress('word', es);
    expect(p.firstConsolidatedAt, isNull);
    expect(p.recognitionStage, 0);
    expect(p.recallCorrect, 1);
    expect(MasteryPolicy.intervals, [1, 3, 7, 14, 30, 60]);
  });
  test('Exact normalized variants; no fuzzy acceptance', () async {
    final r = await VocabularyRepository.load();
    final c = r.concepts.firstWhere((c) => c.english == 'biscuit');
    expect(acceptedRecall(c, ' Cookie! '), isTrue);
    expect(acceptedRecall(c, 'cookies'), isFalse);
    expect(acceptedRecall(c, 'coookie'), isFalse);
  });
  test('Curriculum new-word budget and review collision filter never invent other-level IDs', () async {
    final r = await VocabularyRepository.load();
    final pack = r.packs.first;
    final words = r.words(pack), now = DateTime.utc(2026, 10, 1);
    final history = {
      for (final c in words.take(6))
        c.id: WordProgress(c.id, [
          PracticeEvent(
            id: c.id,
            sessionId: 's',
            conceptId: c.id,
            kind: PracticeKind.matchCorrect,
            at: now,
          ),
        ]),
    };
    final selected = CurriculumSelector().select(
      words,
      history,
      TrainerSettings().withValue('newWords', 'little'),
      now,
    );
    expect(selected.where((c) => !history.containsKey(c.id)), hasLength(2));
    expect(selected.every((c) => c.cefrLevel == pack.level), isTrue);
    expect(
      AdaptiveWordScheduler().compatible([words.first, words.first]),
      hasLength(1),
    );
  });
  test(
    'Long weighted random rounds remain paired, terminate and cover the pool',
    () {
      for (final visible in [4, 5]) {
        for (var seed = 0; seed < 20; seed++) {
          final g = MatchingEngine.start(
            words: testWords,
            random: Random(seed),
            priorities: {testWords.first.id: 3},
            config: SessionConfig(
              visiblePairs: visible,
              wordPoolSize: 12,
              targetMatches: 121,
              maxMistakes: 0,
              mode: SessionMode.practice,
            ),
          );
          final seen = <String>{};
          for (var i = 0; i < 121; i++) {
            final a = board.playable(g).first;
            seen.add(a.conceptId);
            g.select(a.id);
            g.select(board.mate(g, a).id);
            clock.drain(g);
            expect(g.debugValidate(), isTrue);
          }
          expect(seen, hasLength(12));
          expect(g.matchedCount, 121);
        }
      }
    },
  );
}
