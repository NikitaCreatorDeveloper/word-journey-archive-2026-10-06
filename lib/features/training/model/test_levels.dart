import 'level_definition.dart';
import 'session_config.dart';

// Temporary fixtures; these do not enable timed gameplay or a level selector.
const testLevels = [
  LevelDefinition(
    id: 'level-1',
    title: 'Level 1',
    visiblePairs: 3,
    wordPoolSize: 12,
    targetMatches: 30,
    timeLimitSeconds: 120,
    maxMistakes: 5,
    mode: SessionMode.timed,
  ),
  LevelDefinition(
    id: 'level-4',
    title: 'Level 4',
    visiblePairs: 4,
    wordPoolSize: 18,
    targetMatches: 60,
    timeLimitSeconds: 120,
    maxMistakes: 5,
    mode: SessionMode.timed,
  ),
  LevelDefinition(
    id: 'level-8',
    title: 'Level 8',
    visiblePairs: 5,
    wordPoolSize: 26,
    targetMatches: 100,
    timeLimitSeconds: 120,
    maxMistakes: 5,
    mode: SessionMode.timed,
  ),
  LevelDefinition(
    id: 'extreme',
    title: 'Extreme',
    visiblePairs: 5,
    wordPoolSize: 40,
    targetMatches: 160,
    timeLimitSeconds: 105,
    maxMistakes: 5,
    mode: SessionMode.checkpoint,
  ),
];
