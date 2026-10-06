import 'package:flutter_test/flutter_test.dart';
import 'package:word_journey/features/review/adaptive_word_scheduler.dart';
import 'package:word_journey/features/vocabulary/vocabulary_repository.dart';
import 'package:word_journey/features/progress/practice_event.dart';
import 'package:word_journey/features/settings/trainer_settings.dart';

void main() {
  test(
    'Thirty-concept pack cannot starve its last ten after twenty are known',
    () async {
      final r = await VocabularyRepository.load(),
          source = r.concepts.take(30).toList(),
          at = DateTime.utc(2026, 10, 1);
      final progress = {
        for (final c in source.take(20))
          c.id: WordProgress(c.id, [
            PracticeEvent(
              id: c.id,
              sessionId: 'prior',
              conceptId: c.id,
              kind: PracticeKind.matchCorrect,
              at: at,
            ),
          ]),
      };
      final seen = source.take(20).map((c) => c.id).toSet();
      for (var round = 0; round < 4; round++) {
        final words = CurriculumSelector().select(
          source,
          progress,
          TrainerSettings(),
          at.add(Duration(minutes: round)),
        );
        final introduced = words.where((c) => !seen.contains(c.id)).toList();
        expect(introduced.length, lessThanOrEqualTo(4));
        expect(words.length, lessThanOrEqualTo(20));
        for (final c in words) {
          seen.add(c.id);
          progress[c.id] = WordProgress(c.id, [
            PracticeEvent(
              id: '$round:${c.id}',
              sessionId: 'r$round',
              conceptId: c.id,
              kind: PracticeKind.matchCorrect,
              at: at.add(Duration(minutes: round)),
            ),
          ]);
        }
      }
      expect(seen, containsAll(source.map((c) => c.id)));
    },
  );
  test(
    'Unanswered exposures do not permanently monopolise introductory twelve',
    () async {
      final source = (await VocabularyRepository.load()).concepts
              .take(30)
              .toList(),
          at = DateTime.utc(2026, 10, 1);
      final progress = {
        for (final c in source.take(12))
          c.id: WordProgress(c.id, [
            PracticeEvent(
              id: c.id,
              sessionId: 'prior',
              conceptId: c.id,
              kind: PracticeKind.exposure,
              at: at,
            ),
          ]),
      };
      final words = CurriculumSelector().select(
        source,
        progress,
        TrainerSettings(),
        at,
      );
      expect(words, hasLength(12));
      expect(words.every((c) => !progress.containsKey(c.id)), true);
    },
  );
}
