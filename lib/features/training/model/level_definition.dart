import 'session_config.dart';

class LevelDefinition {
  const LevelDefinition({
    required this.id,
    required this.title,
    required this.visiblePairs,
    required this.wordPoolSize,
    required this.targetMatches,
    required this.maxMistakes,
    required this.mode,
    this.timeLimitSeconds,
    this.finishOnTarget,
  });

  final String id;
  final String title;
  final int visiblePairs;
  final int wordPoolSize;
  final int targetMatches;
  final int maxMistakes;
  final int? timeLimitSeconds;
  final SessionMode mode;
  final bool? finishOnTarget;

  SessionConfig toSessionConfig({int? visiblePairs}) => SessionConfig(
    visiblePairs: visiblePairs ?? this.visiblePairs,
    wordPoolSize: wordPoolSize,
    targetMatches: targetMatches,
    maxMistakes: maxMistakes,
    timeLimitSeconds: timeLimitSeconds,
    mode: mode,
    finishOnTarget: finishOnTarget,
  );
}
