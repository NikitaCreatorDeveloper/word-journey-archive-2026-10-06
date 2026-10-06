import '../profile/cefr_level.dart';
import '../training/model/word_pair.dart';

enum PartOfSpeech {
  noun,
  verb,
  adjective,
  adverb,
  phrase,
  interjection,
  phrasalVerb,
}

class VocabularyConcept {
  const VocabularyConcept({
    required this.id,
    required this.english,
    required this.russian,
    required this.cefrLevel,
    required this.partOfSpeech,
    required this.senseKey,
    this.lemma = '',
    this.matchLabelEn = '',
    this.matchLabelRu = '',
    this.exampleEn = '',
    this.exampleRu = '',
    this.tags = const [],
    this.situationTags = const [],
    this.acceptedVariants = const [],
    this.curriculumPriority = 'useful',
    this.provenance = const {},
  });
  final String id,
      english,
      russian,
      lemma,
      senseKey,
      matchLabelEn,
      matchLabelRu,
      exampleEn,
      exampleRu,
      curriculumPriority;
  final CefrLevel? cefrLevel;
  final PartOfSpeech partOfSpeech;
  final List<String> tags, situationTags, acceptedVariants;
  final Map<String, dynamic> provenance;
  String get labelEn => matchLabelEn.isEmpty ? english : matchLabelEn;
  String get labelRu => matchLabelRu.isEmpty ? russian : matchLabelRu;
  WordPair toWordPair() => WordPair(id: id, english: labelEn, russian: labelRu);
  factory VocabularyConcept.fromJson(Map<String, dynamic> j) =>
      VocabularyConcept(
        id: j['id'] as String,
        english: j['english'] as String,
        russian: j['russian'] as String,
        cefrLevel: CefrLevel.fromId(j['cefrLevel'] as String?),
        partOfSpeech: PartOfSpeech.values.byName(j['partOfSpeech'] as String),
        senseKey: j['senseKey'] as String,
        lemma: j['lemma'] as String,
        matchLabelEn: j['matchLabelEn'] as String,
        matchLabelRu: j['matchLabelRu'] as String,
        exampleEn: j['exampleEn'] as String,
        exampleRu: j['exampleRu'] as String,
        tags: List<String>.from(j['categoryTags'] as List),
        situationTags: List<String>.from(j['situationTags'] as List),
        acceptedVariants: List<String>.from(j['acceptedVariants'] as List),
        curriculumPriority: j['curriculumPriority'] as String,
        provenance: Map<String, dynamic>.from(j['provenance'] as Map),
      );
  Map<String, dynamic> toJson() => {
    'id': id,
    'english': english,
    'russian': russian,
    'cefrLevel': cefrLevel?.id,
    'partOfSpeech': partOfSpeech.name,
    'senseKey': senseKey,
    'lemma': lemma,
    'matchLabelEn': labelEn,
    'matchLabelRu': labelRu,
    'exampleEn': exampleEn,
    'exampleRu': exampleRu,
    'categoryTags': tags,
    'situationTags': situationTags,
    'acceptedVariants': acceptedVariants,
    'curriculumPriority': curriculumPriority,
    'provenance': provenance,
  };
}
