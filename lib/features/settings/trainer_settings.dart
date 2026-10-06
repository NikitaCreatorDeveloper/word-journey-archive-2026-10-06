import '../training/model/session_config.dart';

class TrainerSettings {
  TrainerSettings([Map<String, dynamic>? values])
    : values = {...defaults, ...?values};
  static const defaults = <String, dynamic>{
    'level': null,
    'dailyMinutes': 10,
    'newWords': 'normal',
    'reviewMode': 'match',
    'pairs': 4,
    'timer': 120,
    'mistakeChallenge': false,
    'sounds': true,
    'volume': 0.35,
    'haptics': true,
    'motion': 'calm',
    'pronunciation': true,
    'voice': null,
    'theme': 'system',
    'largeText': false,
  };
  final Map<String, dynamic> values;
  int get pairs => values['pairs'] as int;
  int get timer => values['timer'] as int;
  String get motion => values['motion'] as String;
  bool get sounds => values['sounds'] as bool;
  bool get haptics => values['haptics'] as bool;
  double get volume => (values['volume'] as num).toDouble();
  TrainerSettings withValue(String key, dynamic value) =>
      TrainerSettings({...values, key: value});
  SessionConfig sessionConfig(int pool, {int? visiblePairs}) => SessionConfig(
    visiblePairs: visiblePairs ?? pairs,
    wordPoolSize: pool,
    targetMatches: 60,
    maxMistakes: values['mistakeChallenge'] == true ? 5 : 0,
    enforceMistakeLimit: values['mistakeChallenge'] == true,
    timeLimitSeconds: timer == 0 ? null : timer,
    mode: timer == 0 ? SessionMode.practice : SessionMode.timed,
  );
  void validate() {
    if (values.keys.any((k) => !defaults.containsKey(k)) ||
        ![4, 5].contains(pairs) ||
        ![0, 60, 90, 120].contains(timer) ||
        ![0, 5, 10, 15].contains(values['dailyMinutes']) ||
        !['little', 'normal', 'more'].contains(values['newWords']) ||
        !['match', 'recall'].contains(values['reviewMode']) ||
        !['full', 'calm', 'minimal'].contains(motion) ||
        !['system', 'light', 'dark'].contains(values['theme']) ||
        volume < 0 ||
        volume > 1 ||
        !volume.isFinite ||
        ![null, 'a1', 'a2', 'b1', 'b2', 'c1'].contains(values['level'])) {
      throw const FormatException('Invalid settings');
    }
    for (final key in [
      'mistakeChallenge',
      'sounds',
      'haptics',
      'pronunciation',
      'largeText',
    ]) {
      if (values[key] is! bool) throw const FormatException('Invalid toggle');
    }
    if (values['voice'] != null && values['voice'] is! String) {
      throw const FormatException('Invalid voice');
    }
  }
}
