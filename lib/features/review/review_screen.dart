import 'package:flutter/material.dart';

import '../../app/airy_components.dart';
import '../../app/premium_components.dart';
import '../../app/premium_art.dart';

import '../progress/trainer_data.dart';
import '../vocabulary/vocabulary_repository.dart';
import '../vocabulary/word_detail_screen.dart';
import '../training/screens/training_setup_screen.dart';
import 'adaptive_word_scheduler.dart';
import 'recall_screen.dart';

class ReviewScreen extends StatefulWidget {
  const ReviewScreen({super.key});
  @override
  State<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends State<ReviewScreen> {
  String _filter = 'due';
  bool? _recall;
  @override
  Widget build(BuildContext context) {
    final data = TrainerScope.of(context), r = VocabularyRepository.current;
    final now = data.now().toUtc();
    final all = [...?r?.concepts, ...data.custom];
    final known = all
        .where(
          (c) =>
              data.progress[c.id]?.excluded != true &&
              (data.progress[c.id]?.exposures ?? 0) > 0,
        )
        .toList();
    final modeRecall =
        _recall ?? (data.settings.values['reviewMode'] == 'recall');
    final due = known
        .where((c) => data.progress[c.id]!.isDue(now, recall: modeRecall))
        .toList();
    final filtered = switch (_filter) {
      'errors' => known.where((c) => data.progress[c.id]!.needsReview).toList(),
      'training' =>
        known
            .where((c) => data.progress[c.id]!.firstConsolidatedAt == null)
            .toList(),
      'favorite' =>
        all
            .where(
              (c) =>
                  data.flags[c.id]?['favorite'] == true &&
                  data.flags[c.id]?['excluded'] != true,
            )
            .toList(),
      _ => due,
    };
    final scheduler = AdaptiveWordScheduler();
    final ordered = scheduler.order(
      filtered,
      data.progress,
      now,
      recall: modeRecall,
    );
    final selected = scheduler.compatible(ordered);
    final short = selected.length < data.settings.pairs;
    return AiryBackground(
      child: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: EdgeInsets.all(pageInset(context)),
            sliver: SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  EntryReveal(
                    child: PremiumHero(
                      art: 'illustrations/review_plant',
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.primary
                                      .withValues(alpha: .15),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  Icons.calendar_month_outlined,
                                  color: Theme.of(context).colorScheme.primary,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  due.isEmpty
                                      ? 'Повторение сейчас не требуется'
                                      : "Сегодня пора повторить ${due.length} ${russianPlural(due.length, 'понятие', 'понятия', 'понятий')}",
                                  style: const TextStyle(
                                    fontSize: 19,
                                    height: 1.25,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'Регулярное повторение помогает надолго запомнить слова.',
                            style: TextStyle(fontSize: 14, height: 1.4),
                          ),
                          const SizedBox(height: 18),
                          PremiumButton(
                            onPressed: selected.isEmpty
                                ? null
                                : () => Navigator.push(
                                    context,
                                    AiryPageRoute<void>(
                                      builder: (_) => modeRecall || short
                                          ? RecallScreen(
                                              words: ordered.take(20).toList(),
                                            )
                                          : TrainingSetupScreen(
                                              words: selected,
                                              collectionTitle: 'Повторение',
                                            ),
                                    ),
                                  ),
                            label: selected.isNotEmpty && (modeRecall || short)
                                ? 'Проверить память · ${ordered.take(20).length}'
                                : _filter == 'due'
                                ? 'Начать повторение'
                                : 'Повторить выбранное',
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final columns =
                          constraints.maxWidth >= 330 &&
                              MediaQuery.textScalerOf(context).scale(14) <= 15
                          ? 2
                          : 1;
                      final width =
                          (constraints.maxWidth - (columns - 1) * 8) / columns;
                      return Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final e in {
                            'due': ('Пора повторить', Icons.replay),
                            'errors': (
                              'Последние ошибки',
                              Icons.cancel_outlined,
                            ),
                            'training': (
                              'Ещё закрепляем',
                              Icons.layers_outlined,
                            ),
                            'favorite': (
                              'Избранное',
                              Icons.star_outline_rounded,
                            ),
                          }.entries)
                            SizedBox(
                              width: width,
                              child: Semantics(
                                selected: _filter == e.key,
                                child: PremiumChoice(
                                  key: ValueKey('review-filter-${e.key}'),
                                  label: e.value.$1,
                                  icon: e.value.$2,
                                  selected: _filter == e.key,
                                  onPressed: () =>
                                      setState(() => _filter = e.key),
                                ),
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  SurfaceCard(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    child: SwitchListTile.adaptive(
                      key: const ValueKey('recall-toggle'),
                      contentPadding: EdgeInsets.zero,
                      secondary: Icon(
                        Icons.psychology_outlined,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      title: const Text('Вспомнить без вариантов'),
                      value: modeRecall,
                      onChanged: (v) => setState(() => _recall = v),
                    ),
                  ),
                  if (short && selected.isNotEmpty)
                    const Padding(
                      padding: EdgeInsets.only(top: 10),
                      child: Text(
                        'Для поля нужно 4 или 5 пар. Маленькую очередь проверяем спокойно без вариантов.',
                      ),
                    ),
                  const SizedBox(height: 24),
                  if (filtered.isEmpty)
                    const SurfaceCard(
                      child: Column(
                        children: [
                          PremiumArt(
                            'illustrations/empty_review_box',
                            width: 200,
                            height: 160,
                          ),
                          SizedBox(height: 16),
                          Text(
                            'Сейчас здесь нет слов для повторения.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          SizedBox(height: 12),
                          Text(
                            'Начните набор в «Категориях» или выберите другой фильтр.',
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: EdgeInsets.symmetric(horizontal: pageInset(context)),
            sliver: SliverList.builder(
              itemCount: ordered.length,
              itemBuilder: (context, i) {
                final c = ordered[i];
                return ListTile(
                  title: Text(c.labelRu),
                  subtitle: Text(
                    '${data.progress[c.id]?.mastery.label ?? 'Новое'} · ${c.cefrLevel?.shortLabel ?? 'CEFR не указан'}',
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.push(
                    context,
                    AiryPageRoute<void>(
                      builder: (_) => WordDetailScreen(concept: c),
                    ),
                  ),
                );
              },
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 32)),
        ],
      ),
    );
  }
}
