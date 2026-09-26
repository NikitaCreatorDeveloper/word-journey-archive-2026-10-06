import 'package:flutter_test/flutter_test.dart';
import 'package:word_journey/features/training/model/level_definition.dart';
import 'package:word_journey/features/training/model/session_config.dart';
import 'package:word_journey/features/training/model/session_state.dart';
import 'package:word_journey/features/training/model/test_levels.dart';

SessionConfig config({
  int visible = 4,
  int pool = 20,
  int target = 60,
  int mistakes = 5,
  int? seconds,
  SessionMode mode = SessionMode.practice,
}) => SessionConfig(
  visiblePairs: visible,
  wordPoolSize: pool,
  targetMatches: target,
  maxMistakes: mistakes,
  timeLimitSeconds: seconds,
  mode: mode,
);

void main() {
  test('SessionConfig keeps pool, target, limits and mode independently', () {
    final value = config(seconds: 120, mode: SessionMode.checkpoint);
    expect(value.visiblePairs, 4);
    expect(value.wordPoolSize, 20);
    expect(value.targetMatches, 60);
    expect(value.maxMistakes, 5);
    expect(value.timeLimitSeconds, 120);
    expect(value.mode, SessionMode.checkpoint);
    expect(config().timeLimitSeconds, isNull);
  });

  test('Configuration rejects impossible or nonpositive inputs at runtime', () {
    for (final invalid in <SessionConfig Function()>[
      () => config(visible: 0),
      () => config(visible: -1),
      () => config(pool: 3),
      () => config(pool: 0),
      () => config(target: 0),
      () => config(target: -1),
      () => config(mistakes: -1),
      () => config(seconds: 0),
      () => config(seconds: -1),
    ]) {
      expect(invalid, throwsArgumentError);
    }
  });

  test('Visible pair count is not restricted to UI choices or target size', () {
    expect(config(visible: 6).visiblePairs, 6);
    expect(config(visible: 1, pool: 1, target: 30).wordPoolSize, 1);
    expect(config(target: 1).targetMatches, 1);
    expect(config(mistakes: 0).maxMistakes, 0);
  });

  final expectedLevels = [
    ('level-1', 'Level 1', 3, 12, 30, 120, SessionMode.timed),
    ('level-4', 'Level 4', 4, 18, 60, 120, SessionMode.timed),
    ('level-8', 'Level 8', 5, 26, 100, 120, SessionMode.timed),
    ('extreme', 'Extreme', 5, 40, 160, 105, SessionMode.checkpoint),
  ];
  for (var index = 0; index < expectedLevels.length; index++) {
    final expected = expectedLevels[index];
    test('${expected.$2} converts every field to SessionConfig', () {
      final level = testLevels[index];
      final value = level.toSessionConfig();
      expect(level.id, expected.$1);
      expect(level.title, expected.$2);
      expect(value.visiblePairs, expected.$3);
      expect(value.wordPoolSize, expected.$4);
      expect(value.targetMatches, expected.$5);
      expect(value.timeLimitSeconds, expected.$6);
      expect(value.mode, expected.$7);
      expect(value.maxMistakes, 5);
    });
  }

  test('Level conversion supports practice with no time limit', () {
    const level = LevelDefinition(
      id: 'practice',
      title: 'Practice',
      visiblePairs: 4,
      wordPoolSize: 8,
      targetMatches: 50,
      maxMistakes: 5,
      mode: SessionMode.practice,
    );
    expect(level.toSessionConfig().timeLimitSeconds, isNull);
    expect(level.toSessionConfig().mode, SessionMode.practice);
  });

  test('SessionState uses target progress and ignores limit metadata', () {
    final value = config(seconds: 1);
    final state = SessionState(config: value, matchedCount: 30, mistakes: 8);
    expect(state.progress, .5);
    expect(state.isComplete, isFalse);
    expect(state.config.maxMistakes, 5);
    expect(state.mistakes, 8);
    expect(SessionState(config: value, matchedCount: 60).isComplete, isTrue);
  });
}
