import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../app/app_theme.dart';
import '../../training/logic/matching_engine.dart';
import '../../training/screens/training_game_screen.dart';
import '../data/travel_content.dart';
import '../model/world_content.dart';
import '../widgets/atlas_map.dart';
import '../widgets/cafe_artwork.dart';

void openAtlasPage(BuildContext context, Widget page) {
  Navigator.of(context).push(
    PageRouteBuilder<void>(
      transitionDuration: const Duration(milliseconds: 320),
      reverseTransitionDuration: const Duration(milliseconds: 260),
      pageBuilder: (context, animation, secondary) => page,
      transitionsBuilder: (context, animation, secondary, child) {
        final curved = animation.drive(CurveTween(curve: Curves.easeOutCubic));
        return FadeTransition(
          opacity: curved,
          child: SlideTransition(
            position: Tween(
              begin: const Offset(.025, 0),
              end: Offset.zero,
            ).animate(curved),
            child: child,
          ),
        );
      },
    ),
  );
}

class WorldScreen extends StatelessWidget {
  const WorldScreen({super.key, this.content = travelContent});
  final WorldContent content;
  @override
  Widget build(BuildContext context) {
    final country = content.country(content.world.countryIds.first);
    void openCountry() => openAtlasPage(
      context,
      CountryScreen(countryId: country.id, content: content),
    );
    return AtlasChapter(
      eyebrow: 'ВАШ ПУТЕВОЙ АТЛАС',
      title: content.world.name,
      description: 'Новые места. Слова для настоящих встреч.',
      map: AtlasMap(
        key: const ValueKey('world-atlas'),
        scene: AtlasScene.world,
        stops: [
          for (final id in content.world.countryIds)
            AtlasStop(
              id: id,
              label: content.country(id).name,
              position: content.country(id).mapPosition,
              onTap: () => openAtlasPage(
                context,
                CountryScreen(countryId: id, content: content),
              ),
            ),
        ],
      ),
      footer: AtlasPlaceLink(
        key: const ValueKey('open-uk'),
        eyebrow: 'ПЕРВЫЙ МАРШРУТ',
        title: country.name,
        subtitle: 'Лондон · Кафе',
        onTap: openCountry,
      ),
    );
  }
}

class CountryScreen extends StatelessWidget {
  const CountryScreen({
    super.key,
    required this.countryId,
    this.content = travelContent,
  });
  final String countryId;
  final WorldContent content;
  @override
  Widget build(BuildContext context) {
    final country = content.country(countryId);
    final destination = content.destination(country.destinationIds.first);
    void openDestination() => openAtlasPage(
      context,
      DestinationScreen(destinationId: destination.id, content: content),
    );
    return Scaffold(
      appBar: AppBar(title: Text(country.name)),
      body: SafeArea(
        top: false,
        child: AtlasChapter(
          eyebrow: country.englishName.toUpperCase(),
          title: 'Начните с Лондона',
          description: 'Один город. Первые разговоры. Ваш маршрут.',
          map: AtlasMap(
            scene: AtlasScene.country,
            stops: [
              for (final id in country.destinationIds)
                AtlasStop(
                  id: id,
                  label: content.destination(id).name,
                  position: content.destination(id).mapPosition,
                  onTap: () => openAtlasPage(
                    context,
                    DestinationScreen(destinationId: id, content: content),
                  ),
                ),
            ],
          ),
          footer: AtlasPlaceLink(
            key: const ValueKey('open-london'),
            eyebrow: 'ГОРОД / 01',
            title: destination.name,
            subtitle: destination.englishName,
            onTap: openDestination,
          ),
        ),
      ),
    );
  }
}

class DestinationScreen extends StatelessWidget {
  const DestinationScreen({
    super.key,
    required this.destinationId,
    this.content = travelContent,
  });
  final String destinationId;
  final WorldContent content;
  @override
  Widget build(BuildContext context) {
    final destination = content.destination(destinationId);
    final situation = content.situation(destination.situationIds.first);
    void openSituation() => openAtlasPage(
      context,
      SituationScreen(situationId: situation.id, content: content),
    );
    return Scaffold(
      appBar: AppBar(title: Text(destination.name)),
      body: SafeArea(
        top: false,
        child: AtlasChapter(
          eyebrow: destination.englishName.toUpperCase(),
          title: 'В ритме города',
          description: 'Загляните в кафе и сделайте первый заказ.',
          map: AtlasMap(
            scene: AtlasScene.city,
            stops: [
              for (final id in destination.situationIds)
                AtlasStop(
                  id: id,
                  label: content.situation(id).name,
                  position: content.situation(id).mapPosition,
                  onTap: () => openAtlasPage(
                    context,
                    SituationScreen(situationId: id, content: content),
                  ),
                ),
            ],
          ),
          footer: Material(
            color: AtlasColors.of(context).card,
            borderRadius: BorderRadius.circular(20),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              key: const ValueKey('open-cafe'),
              onTap: openSituation,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 140, child: CafeArtwork()),
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'ПЕРВАЯ ОСТАНОВКА',
                          style: Theme.of(context).textTheme.labelSmall,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          situation.englishName,
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Кофе, завтрак и несколько новых слов.',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class SituationScreen extends StatefulWidget {
  const SituationScreen({
    super.key,
    required this.situationId,
    this.content = travelContent,
  });
  final String situationId;
  final WorldContent content;
  @override
  State<SituationScreen> createState() => _SituationScreenState();
}

class _SituationScreenState extends State<SituationScreen> {
  int _visiblePairs = 4;
  @override
  Widget build(BuildContext context) {
    final situation = widget.content.situation(widget.situationId);
    final pack = widget.content.wordPack(situation.wordPackId);
    final config = widget.content.sessionConfig(
      situation.id,
      visiblePairs: _visiblePairs,
    );
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(situation.name)),
      body: SafeArea(
        top: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const ClipRRect(
                    borderRadius: BorderRadius.all(Radius.circular(24)),
                    child: AspectRatio(aspectRatio: 1.65, child: CafeArtwork()),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    situation.englishName,
                    style: theme.textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    situation.description,
                    style: theme.textTheme.bodyLarge?.copyWith(height: 1.5),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    '${pack.conceptIds.length} понятий',
                    key: const ValueKey('pack-concept-count'),
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final section in pack.sections)
                        DecoratedBox(
                          decoration: BoxDecoration(
                            color: AtlasColors.of(context).selected,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            child: Text(
                              section.title,
                              style: theme.textTheme.labelMedium,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Text(
                    '${config.targetMatches} совпадений · ${config.timeLimitSeconds! ~/ 60}:00',
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Количество пар на поле',
                    style: theme.textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 12),
                  SegmentedButton<int>(
                    segments: const [
                      ButtonSegment(value: 4, label: Text('4')),
                      ButtonSegment(value: 5, label: Text('5')),
                    ],
                    selected: {_visiblePairs},
                    showSelectedIcon: false,
                    onSelectionChanged: (values) =>
                        setState(() => _visiblePairs = values.single),
                  ),
                  const SizedBox(height: 24),
                  FilledButton(
                    key: const ValueKey('start-cafe'),
                    onPressed: () {
                      final game = MatchingEngine.start(
                        words: widget.content.wordsForPack(
                          situation.wordPackId,
                        ),
                        config: config,
                      );
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => TrainingGameScreen(game: game),
                        ),
                      );
                    },
                    child: const Text('Начать'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class AtlasChapter extends StatelessWidget {
  const AtlasChapter({
    super.key,
    required this.eyebrow,
    required this.title,
    required this.description,
    required this.map,
    required this.footer,
  });
  final String eyebrow;
  final String title;
  final String description;
  final Widget map;
  final Widget footer;
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final theme = Theme.of(context);
      final mapHeight = math.max(
        330.0,
        math.min(600.0, constraints.maxHeight - 270),
      );
      return SingleChildScrollView(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    eyebrow,
                    style: theme.textTheme.labelSmall?.copyWith(
                      letterSpacing: 1.8,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(title, style: theme.textTheme.headlineMedium),
                  const SizedBox(height: 8),
                  Text(description, style: theme.textTheme.bodyMedium),
                  const SizedBox(height: 22),
                  SizedBox(height: mapHeight, child: map),
                  const SizedBox(height: 16),
                  footer,
                ],
              ),
            ),
          ),
        ),
      );
    },
  );
}

class AtlasPlaceLink extends StatelessWidget {
  const AtlasPlaceLink({
    super.key,
    required this.eyebrow,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });
  final String eyebrow;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Material(
    color: AtlasColors.of(context).card,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(20),
      side: BorderSide(color: AtlasColors.of(context).cardOutline),
    ),
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    eyebrow,
                    style: Theme.of(context).textTheme.labelSmall
                        ?.copyWith(letterSpacing: 1.4),
                  ),
                  const SizedBox(height: 8),
                  Text(title, style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 4),
                  Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
                ],
              ),
            ),
            const SizedBox(width: 12),
            const Icon(Icons.arrow_forward_rounded, size: 22),
          ],
        ),
      ),
    ),
  );
}
