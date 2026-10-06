import 'package:flutter_test/flutter_test.dart';
import 'package:word_journey/features/progress/achievement_service.dart';
import 'package:word_journey/features/progress/practice_event.dart';

void main() {
  test('Full pack needs every concept answered; awards stay idempotent after expansion', () {
    final ids = List.generate(20, (i) => 'w$i'), at = DateTime.utc(2026, 10, 1);
    final events = [
      for (var i = 0; i < 20; i++)
        PracticeEvent(
          id: '$i',
          sessionId: 's',
          conceptId: ids[i],
          kind: PracticeKind.matchCorrect,
          at: at.add(Duration(seconds: i)),
        ),
    ];
    List<Map<String, dynamic>> pending(
      List<PracticeEvent> es,
      List<Map<String, dynamic>> awards,
    ) => AchievementService.pending(
      events: es,
      sessions: [],
      progress: {},
      awards: awards,
      packs: {'p': ids},
    );
    expect(
      pending(events.take(19).toList(), []).any((a) => a['id'] == 'full-pack'),
      false,
    );
    final earned = pending(events, []);
    expect(earned.where((a) => a['id'] == 'full-pack'), hasLength(1));
    expect(pending(events, earned), isEmpty);
    ids.add('new-concept');
    expect(pending(events, earned), isEmpty);
  });
  test('Immediate correction is not a return; another session is, once', () {
    final at = DateTime.utc(2026, 10, 1);
    PracticeEvent event(
      String id,
      String session,
      PracticeKind kind,
      int minutes,
    ) => PracticeEvent(
      id: id,
      sessionId: session,
      conceptId: 'word',
      kind: kind,
      at: at.add(Duration(minutes: minutes)),
    );
    final events = [
      event('w', 'first', PracticeKind.matchWrong, 0),
      event('c', 'first', PracticeKind.matchCorrect, 1),
    ];
    List<Map<String, dynamic>> pending(List<Map<String, dynamic>> awards) =>
        AchievementService.pending(
          events: events,
          sessions: [],
          progress: {},
          awards: awards,
        );
    expect(pending([]).any((a) => a['id'] == 'return-to-error'), false);
    events.add(event('return', 'second', PracticeKind.recallCorrect, 10));
    final earned = pending([]);
    expect(earned.where((a) => a['id'] == 'return-to-error'), hasLength(1));
    expect(pending(earned), isEmpty);
  });
  test(
    'Rank reward counts unique historic confirmation, never raw answers',
    () {
      final at = DateTime.utc(2026, 10, 1);
      final progress = {
        for (var i = 0; i < 10; i++)
          'w$i': WordProgress(
            'w$i',
            [],
            firstConsolidatedOverride: at.add(Duration(days: i)),
          ),
      };
      final awards = AchievementService.pending(
        events: [],
        sessions: [],
        progress: progress,
        awards: [],
      );
      expect(awards.single['id'], 'new-rank');
      expect(
        AchievementService.pending(
          events: [],
          sessions: [],
          progress: progress,
          awards: awards,
        ),
        isEmpty,
      );
    },
  );
}
