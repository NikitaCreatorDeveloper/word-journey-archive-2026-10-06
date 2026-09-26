import 'word_pair.dart';

enum CardLanguage { english, russian }

class MatchingCard {
  MatchingCard.fromWord(WordPair word, this.language, {required int occurrence})
    : id = '${language.name}:$occurrence:${word.id}',
      pairId = '$occurrence:${word.id}',
      wordId = word.id,
      text = language == CardLanguage.english ? word.english : word.russian;

  // A returning word gets fresh IDs, so taps from an outgoing card stay stale.
  final String id;
  final String pairId;
  final String wordId;
  String get conceptId => wordId;
  final String text;
  final CardLanguage language;
}
