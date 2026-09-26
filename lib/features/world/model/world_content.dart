import '../../training/model/level_definition.dart';
import '../../training/model/session_config.dart';
import '../../training/model/word_pair.dart';

class MapPosition {
  const MapPosition(this.x, this.y)
    : assert(x >= 0 && x <= 1),
      assert(y >= 0 && y <= 1);
  final double x;
  final double y;
}

class WorldDefinition {
  const WorldDefinition({
    required this.id,
    required this.name,
    required this.countryIds,
  });
  final String id;
  final String name;
  final List<String> countryIds;
}

class CountryDefinition {
  const CountryDefinition({
    required this.id,
    required this.name,
    required this.englishName,
    required this.mapPosition,
    required this.destinationIds,
  });
  final String id;
  final String name;
  final String englishName;
  final MapPosition mapPosition;
  final List<String> destinationIds;
}

class DestinationDefinition {
  const DestinationDefinition({
    required this.id,
    required this.countryId,
    required this.name,
    required this.englishName,
    required this.mapPosition,
    required this.situationIds,
  });
  final String id;
  final String countryId;
  final String name;
  final String englishName;
  final MapPosition mapPosition;
  final List<String> situationIds;
}

class SituationDefinition {
  const SituationDefinition({
    required this.id,
    required this.destinationId,
    required this.name,
    required this.englishName,
    required this.description,
    required this.mapPosition,
    required this.wordPackId,
    required this.sessionLevelId,
  });
  final String id;
  final String destinationId;
  final String name;
  final String englishName;
  final String description;
  final MapPosition mapPosition;
  final String wordPackId;
  final String sessionLevelId;
}

class WordPackSection {
  const WordPackSection({
    required this.id,
    required this.title,
    required this.conceptIds,
  });
  final String id;
  final String title;
  final List<String> conceptIds;
}

class WordPackDefinition {
  const WordPackDefinition({required this.id, required this.sections});
  final String id;
  final List<WordPackSection> sections;
  List<String> get conceptIds =>
      List.unmodifiable(sections.expand((section) => section.conceptIds));
}

/// Local content graph. Screens resolve IDs; they never own or duplicate word data.
class WorldContent {
  const WorldContent({
    required this.world,
    required this.countries,
    required this.destinations,
    required this.situations,
    required this.wordPacks,
    required this.concepts,
    required this.sessionLevels,
  });
  final WorldDefinition world;
  final List<CountryDefinition> countries;
  final List<DestinationDefinition> destinations;
  final List<SituationDefinition> situations;
  final List<WordPackDefinition> wordPacks;
  final List<WordPair> concepts;
  final List<LevelDefinition> sessionLevels;

  CountryDefinition country(String id) =>
      countries.singleWhere((c) => c.id == id);
  DestinationDefinition destination(String id) =>
      destinations.singleWhere((d) => d.id == id);
  SituationDefinition situation(String id) =>
      situations.singleWhere((s) => s.id == id);
  WordPackDefinition wordPack(String id) =>
      wordPacks.singleWhere((p) => p.id == id);
  List<WordPair> wordsForPack(String id) => List.unmodifiable([
    for (final conceptId in wordPack(id).conceptIds)
      concepts.singleWhere((c) => c.id == conceptId),
  ]);
  SessionConfig sessionConfig(String situationId, {required int visiblePairs}) {
    final situation = this.situation(situationId);
    return sessionLevels
        .singleWhere((l) => l.id == situation.sessionLevelId)
        .toSessionConfig(visiblePairs: visiblePairs);
  }
}
