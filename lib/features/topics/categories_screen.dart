import 'package:flutter/material.dart';

import '../../app/airy_components.dart';
import '../../app/premium_components.dart';
import '../../app/category_illustration.dart';
import '../profile/cefr_profile.dart';
import '../vocabulary/vocabulary_repository.dart';
import '../training/screens/training_setup_screen.dart';
import '../progress/trainer_data.dart';
import 'personal_collections_screen.dart';

class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key, this.onReview});
  final VoidCallback? onReview;
  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  final _catalog = VocabularyRepository.load();
  String _query = '';
  final _entered = <String>{};
  @override
  Widget build(BuildContext context) => FutureBuilder<VocabularyRepository>(
    future: _catalog,
    builder: (context, s) {
      if (s.hasError) return const Center(child: Text('Ошибка библиотеки'));
      final r = s.data;
      if (r == null) return const Center(child: CircularProgressIndicator());
      final level = ProfileScope.levelOf(context),
          data = TrainerScope.maybeOf(context);
      final packs = r.packs.where((p) => p.level == level).toList();
      final lead =
          packs.where((p) => p.id == data?.lastPackId).firstOrNull ??
          packs
              .where(
                (p) => p.conceptIds.any(
                  (id) => (data?.progress[id]?.exposures ?? 0) == 0,
                ),
              )
              .firstOrNull ??
          packs.first;
      final continued =
          lead.id == data?.lastPackId ||
          lead.conceptIds.any((id) => (data?.progress[id]?.exposures ?? 0) > 0);
      final due =
          data?.progress.values
              .where(
                (p) => p.isDue(data.now()) || p.isDue(data.now(), recall: true),
              )
              .length ??
          0;
      final cats = r.categories
          .where((c) => r.packsFor(c.id, level).isNotEmpty)
          .toList();
      final found = _query.isEmpty
          ? <VocabularyPack>[]
          : r.search(_query, level);
      final columns =
          MediaQuery.sizeOf(context).width >= 390 &&
              MediaQuery.textScalerOf(context).scale(16) <= 18
          ? 2
          : 1;
      final inset = pageInset(context);
      return AiryBackground(
        child: CustomScrollView(
          key: const PageStorageKey('categories-scroll'),
          slivers: [
            SliverPadding(
              padding: EdgeInsets.fromLTRB(inset, 8, inset, 0),
              sliver: SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const LevelStrip(),
                    if (ProfileScope.maybeOf(context)?.error case final error?)
                      Text(error),
                    const SizedBox(height: 12),
                    TextField(
                      textInputAction: TextInputAction.search,
                      decoration: const InputDecoration(
                        hintText: 'Набор или слово...',
                        prefixIcon: Icon(Icons.search),
                      ),
                      onChanged: (v) =>
                          setState(() => _query = v.trim().toLowerCase()),
                    ),
                    const SizedBox(height: 24),
                    if (_query.isEmpty) ...[
                      EntryReveal(
                        child: PremiumHero(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                continued
                                    ? 'Продолжить набор'
                                    : 'Начать знакомство',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                              const SizedBox(height: 8),
                              ConstrainedBox(
                                constraints: BoxConstraints(
                                  maxWidth:
                                      MediaQuery.textScalerOf(context)
                                              .scale(16) >
                                          20
                                      ? double.infinity
                                      : MediaQuery.sizeOf(context).width * .63,
                                ),
                                child: Text(
                                  lead.title,
                                  style: const TextStyle(
                                    fontSize: 20,
                                    height: 1.25,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                '${level.shortLabel} · ${lead.conceptIds.length} понятий · ${lead.conceptIds.where((id) => (data?.progress[id]?.exposures ?? 0) > 0).length} встречено',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                              const SizedBox(height: 18),
                              PremiumButton(
                                onPressed: () => openPack(context, r, lead),
                                label: continued
                                    ? 'Продолжить'
                                    : 'Открыть набор',
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (due > 0)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: TextButton.icon(
                            style: TextButton.styleFrom(
                              textStyle: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            onPressed: widget.onReview,
                            icon: const Icon(Icons.replay),
                            label: Text('Пора повторить: $due понятий'),
                          ),
                        ),
                      if (due == 0 &&
                          data != null &&
                          (data.settings.values['dailyMinutes'] as int) > 0)
                        Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: Text(
                            'Цель на день: ${data.settings.values['dailyMinutes']} мин · без спешки',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ),
                      Padding(
                        padding: const EdgeInsets.only(top: 24, bottom: 12),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Каталог ситуаций',
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                            ),
                            TextButton(
                              onPressed: () => Navigator.push(
                                context,
                                AiryPageRoute<void>(
                                  builder: (_) =>
                                      CategoryDirectoryScreen(repository: r),
                                ),
                              ),
                              child: const Text('Все ›'),
                            ),
                          ],
                        ),
                      ),
                    ] else
                      SectionHeader(
                        'Найдено: ${found.length}',
                        help: 'Только ${level.shortLabel} · наборы и значения',
                      ),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: EdgeInsets.symmetric(horizontal: inset),
              sliver: SliverList.builder(
                itemCount: _query.isEmpty
                    ? (cats.length / columns).ceil()
                    : found.length,
                itemBuilder: (context, index) {
                  if (_query.isNotEmpty) {
                    final p = found[index];
                    final hit = r
                        .words(p)
                        .where(
                          (c) => '${c.english} ${c.russian}'
                              .toLowerCase()
                              .contains(_query),
                        )
                        .firstOrNull;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: PackRow(
                        repository: r,
                        pack: p,
                        help: hit == null
                            ? p.goal
                            : '${hit.english} — ${hit.russian}',
                      ),
                    );
                  }
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        for (var j = 0; j < columns; j++) ...[
                          if (j > 0) const SizedBox(width: 12),
                          if (index * columns + j < cats.length)
                            Expanded(
                              child: EntryReveal(
                                enabled:
                                    index < 2 &&
                                    _entered.add(cats[index * columns + j].id),
                                child: _CategoryCard(
                                  repository: r,
                                  category: cats[index * columns + j],
                                ),
                              ),
                            )
                          else
                            const Expanded(child: SizedBox()),
                        ],
                      ],
                    ),
                  );
                },
              ),
            ),
            if (_query.isNotEmpty && found.isEmpty)
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Column(
                    children: [
                      CategoryGlyph(symbol: 'thoughts'),
                      SizedBox(height: 12),
                      Text(
                        'Ничего не найдено на этом уровне. Попробуйте другое слово или смените CEFR.',
                      ),
                    ],
                  ),
                ),
              ),
            SliverPadding(
              padding: EdgeInsets.fromLTRB(inset, 12, inset, 32),
              sliver: SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (data != null)
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final e in {
                            'core': 'Самое нужное',
                            'favorite': 'Избранное',
                            'custom': 'Мои слова',
                          }.entries)
                            ActionChip(
                              label: Text(e.value),
                              onPressed: () => Navigator.push(
                                context,
                                AiryPageRoute<void>(
                                  builder: (_) =>
                                      PersonalCollectionsScreen(filter: e.key),
                                ),
                              ),
                            ),
                        ],
                      ),
                    const SizedBox(height: 16),
                    const Text(
                      'Авторская программа. CEFR значений — редакторская оценка, не сертификат.',
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    },
  );
}

class _CategoryCard extends StatelessWidget {
  const _CategoryCard({required this.repository, required this.category});
  final VocabularyRepository repository;
  final VocabularyCategory category;
  @override
  Widget build(BuildContext context) {
    final packs = repository.packsFor(
      category.id,
      ProfileScope.levelOf(context),
    );
    final d = TrainerScope.maybeOf(context),
        ids = packs.expand((p) => p.conceptIds).toSet();
    final count = ids
        .where((id) => d?.progress[id]?.firstConsolidatedAt != null)
        .length;
    return SurfaceCard(
      onTap: () => Navigator.push(
        context,
        AiryPageRoute<void>(
          builder: (_) =>
              CategoryScreen(repository: repository, category: category),
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CategoryGlyph(symbol: category.symbol, size: 48),
          const SizedBox(height: 12),
          Text(category.title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(
            "${packs.length} ${russianPlural(packs.length, 'набор', 'набора', 'наборов')}",
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: ids.isEmpty ? 0 : count / ids.length,
            minHeight: 3,
            borderRadius: BorderRadius.circular(3),
          ),
          const SizedBox(height: 6),
          Text(
            '$count / ${ids.length}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

class CategoryScreen extends StatelessWidget {
  const CategoryScreen({
    super.key,
    required this.repository,
    required this.category,
  });
  final VocabularyRepository repository;
  final VocabularyCategory category;
  @override
  Widget build(BuildContext context) {
    final level = ProfileScope.levelOf(context),
        packs = repository.packsFor(category.id, level);
    return Scaffold(
      appBar: AppBar(title: const Text('Наборы')),
      body: SafeArea(
        top: false,
        child: AiryBackground(
          child: CustomScrollView(
            key: PageStorageKey('packs-${category.id}'),
            slivers: [
              SliverPadding(
                padding: EdgeInsets.all(pageInset(context)),
                sliver: SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const LevelStrip(),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          CategoryGlyph(symbol: category.symbol, size: 48),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  category.title,
                                  style: Theme.of(context).textTheme.titleLarge,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Практика для конкретных разговоров · ${level.shortLabel}',
                                  style: Theme.of(context).textTheme.bodyLarge,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              SliverPadding(
                padding: EdgeInsets.symmetric(horizontal: pageInset(context)),
                sliver: SliverList.builder(
                  itemCount: packs.length,
                  itemBuilder: (context, i) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: PackRow(repository: repository, pack: packs[i]),
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 32)),
            ],
          ),
        ),
      ),
    );
  }
}

class PackRow extends StatelessWidget {
  const PackRow({
    super.key,
    required this.repository,
    required this.pack,
    this.help,
  });
  final VocabularyRepository repository;
  final VocabularyPack pack;
  final String? help;
  @override
  Widget build(BuildContext context) {
    final d = TrainerScope.maybeOf(context),
        seen = pack.conceptIds
            .where((id) => (d?.progress[id]?.exposures ?? 0) > 0)
            .length;
    return SurfaceCard(
      onTap: () => openPack(context, repository, pack),
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CategoryGlyph(
            symbol: repository.categories
                .firstWhere((c) => c.id == pack.categoryId)
                .symbol,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  pack.title,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 6),
                Text(
                  '${pack.level.shortLabel} · ${pack.conceptIds.length} слов и выражений',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                if ((help ?? pack.goal).isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    help ?? pack.goal,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
                const SizedBox(height: 8),
                Text(
                  '$seen / ${pack.conceptIds.length} встречено',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

void openPack(BuildContext context, VocabularyRepository r, VocabularyPack p) =>
    Navigator.push(
      context,
      AiryPageRoute<void>(
        builder: (_) => TrainingSetupScreen(pack: p, words: r.words(p)),
      ),
    );

class CategoryDirectoryScreen extends StatelessWidget {
  const CategoryDirectoryScreen({super.key, required this.repository});
  final VocabularyRepository repository;
  @override
  Widget build(BuildContext context) {
    final level = ProfileScope.levelOf(context),
        cats = repository.categories
            .where((c) => repository.packsFor(c.id, level).isNotEmpty)
            .toList();
    return Scaffold(
      appBar: AppBar(title: const Text('Все категории')),
      body: SafeArea(
        top: false,
        child: AiryBackground(
          child: ListView(
            padding: EdgeInsets.all(pageInset(context)),
            children: [
              const LevelStrip(),
              const SizedBox(height: 24),
              for (final cat in cats)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: SurfaceCard(
                    onTap: () => Navigator.push(
                      context,
                      AiryPageRoute<void>(
                        builder: (_) => CategoryScreen(
                          repository: repository,
                          category: cat,
                        ),
                      ),
                    ),
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        CategoryGlyph(symbol: cat.symbol, size: 48),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                cat.title,
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              Text(
                                "${repository.packsFor(cat.id, level).length} ${russianPlural(repository.packsFor(cat.id, level).length, 'набор', 'набора', 'наборов')} · ${level.shortLabel}",
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
