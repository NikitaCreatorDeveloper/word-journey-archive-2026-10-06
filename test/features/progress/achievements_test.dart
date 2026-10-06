import 'package:flutter_test/flutter_test.dart';
import 'package:word_journey/features/progress/achievement_service.dart';
import 'package:word_journey/features/progress/practice_event.dart';
import 'package:word_journey/features/progress/trainer_data.dart';
import 'package:word_journey/features/progress/trainer_store.dart';

void main() {
  test('Match options shown today cannot advance independent recall', () {
    final at = DateTime.utc(2026, 10, 1, 12);
    final es = [
      PracticeEvent(
        id: 'show',
        sessionId: 'm',
        conceptId: 'w',
        kind: PracticeKind.exposure,
        at: at,
        answerShown: true,
      ),
      PracticeEvent(
        id: 'r',
        sessionId: 'r',
        conceptId: 'w',
        kind: PracticeKind.recallCorrect,
        at: at.add(const Duration(minutes: 1)),
      ),
    ];
    expect(WordProgress('w', es).mastery.independentRecallCorrect, 0);
    expect(
      WordProgress('w', es).hintedToday(at.add(const Duration(hours: 1))),
      isTrue,
    );
  });
  test('Rapid session restarts do not manufacture spaced successes', () {
    final at = DateTime.utc(2026, 10, 1, 12);
    final es = [
      for (var i = 0; i < 10; i++)
        PracticeEvent(
          id: '$i',
          sessionId: '$i',
          conceptId: 'w',
          kind: PracticeKind.matchCorrect,
          at: at.add(Duration(seconds: i)),
        ),
    ];
    expect(WordProgress('w', es).mastery.spacedCorrect, 1);
  });
  test('Historical consolidation and stable awards survive repeated imports; reset clears rank only', () async {
    final d = TrainerData(store: MemoryTrainerStore());
    await d.load();
    final at = DateTime.utc(2026, 10, 1, 12);
    await d.append([
      for (var i = 0; i < 5; i++)
        PracticeEvent(
          id: '$i',
          sessionId: 's1',
          conceptId: 'w',
          kind: PracticeKind.matchCorrect,
          at: at.add(Duration(seconds: i)),
          index: i * 4,
        ),
      PracticeEvent(
        id: 'later',
        sessionId: 's2',
        conceptId: 'w',
        kind: PracticeKind.matchCorrect,
        at: at.add(const Duration(days: 1, minutes: 1)),
      ),
    ]);
    await d.reconcileAchievements();
    await d.setFlag('w', favorite: true);
    expect(d.consolidatedCount, 1);
    expect(d.flags['w']!['firstConsolidatedAt'], isNotNull);
    final snapshot = await d.store!.read();
    await d.append([
      PracticeEvent(
        id: 'wrong',
        sessionId: 's2',
        conceptId: 'w',
        kind: PracticeKind.matchWrong,
        at: at.add(const Duration(days: 2)),
      ),
    ]);
    expect(d.consolidatedCount, 1);
    expect(d.progress['w']!.mastery.currentlyConsolidated, isFalse);
    snapshot.rows['awards']!.single['at'] = at.toIso8601String();
    await d.importData(snapshot);
    await d.importData(snapshot);
    expect(d.awards.where((a) => a['id'] == 'delayed-review'), hasLength(1));
    expect(d.consolidatedCount, 1);
    await d.resetProgress();
    expect(d.consolidatedCount, 0);
    expect(d.progress['w']!.favorite, isTrue);
    expect(d.awards, isEmpty);
    expect(rankNames[rankIndex(500)], 'Синтез');
    expect(rankNames[rankIndex(1000)], 'Лексикон');
  });
}
