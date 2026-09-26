import 'level_definition.dart';
import 'session_config.dart';

/// One standard round. Milestones are feedback, never separate levels.
const standardMatchLevel = LevelDefinition(
  id: 'standard-match',
  title: 'Тренировка',
  visiblePairs: 4,
  wordPoolSize: 20,
  targetMatches: 60,
  timeLimitSeconds: 120,
  maxMistakes: 5,
  mode: SessionMode.timed,
  finishOnTarget: true,
);

const matchMilestones = [20, 30, 60];
