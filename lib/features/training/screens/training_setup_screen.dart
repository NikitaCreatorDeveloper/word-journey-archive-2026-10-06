import 'package:flutter/material.dart';

import '../../../app/airy_components.dart';
import '../../../app/premium_components.dart';
import '../widgets/pair_count_selector.dart';
import '../../../app/motion_preferences.dart';
import '../../../app/category_illustration.dart';
import '../../profile/cefr_profile.dart';
import '../../vocabulary/vocabulary_concept.dart';
import '../../vocabulary/vocabulary_repository.dart';
import '../logic/matching_engine.dart';
import '../../progress/trainer_data.dart';
import '../../progress/practice_event.dart';
import '../../progress/mastery_policy.dart';
import '../../settings/trainer_settings.dart';
import '../../settings/settings_screen.dart';
import '../../review/adaptive_word_scheduler.dart';
import '../../vocabulary/word_detail_screen.dart';
import '../../review/recall_screen.dart';
import 'training_game_screen.dart';

class TrainingSetupScreen extends StatefulWidget {
  const TrainingSetupScreen({
    super.key,
    this.pack,
    this.words,
    this.collectionTitle,
  });
  final VocabularyPack? pack;
  final List<VocabularyConcept>? words;
  final String? collectionTitle;
  @override
  State<TrainingSetupScreen> createState() => _TrainingSetupScreenState();
}

class _TrainingSetupScreenState extends State<TrainingSetupScreen> {
  int _pairCount = 4;
  int? _timerOverride;
  int _preferredTimer = 120;
  bool _initialized = false, _overview = false;
  final _overviewLogged = <String>{};
  final _overviewAnchor = GlobalKey();
  final String _overviewId = newSessionId();
  List<VocabularyConcept>? _selectedWords;
  late final _catalog = VocabularyRepository.load();
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _pairCount = TrainerScope.maybeOf(context)?.settings.pairs ?? 4;
      _initialized = true;
    }
  }

  void _logOverview(List<VocabularyConcept> source, TrainerData? data) {
    if (data == null) return;
    final day = practiceDay(data.now());
    data
        .append([
          for (final c in source)
            if (_overviewLogged.add('$day:${c.id}'))
              PracticeEvent(
                id: '$_overviewId:hint:$day:${c.id}',
                sessionId: _overviewId,
                conceptId: c.id,
                kind: PracticeKind.hint,
                at: data.now().toUtc(),
              ),
        ])
        .catchError((Object _) {});
  }

  void _start(
    List<VocabularyConcept> words,
    VocabularyPack pack,
    TrainerSettings settings,
    TrainerData? data,
  ) {
    final game = MatchingEngine.start(
      words: words.map((c) => c.toWordPair()).toList(),
      config: settings.sessionConfig(
        words.length.clamp(_pairCount, 20),
        visiblePairs: _pairCount,
      ),
      priorities: AdaptiveWordScheduler().priorities(
        words,
        data?.progress ?? {},
      ),
    );
    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) => TrainingGameScreen(
          game: game,
          packId: widget.collectionTitle == null ? pack.id : null,
        ),
      ),
    ).then((_) {
      if (mounted) setState(() => _selectedWords = null);
    });
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<VocabularyRepository>(
    future: _catalog,
    builder: (context, s) {
      if (!s.hasData) {
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      }
      final r = s.data!,
          pack =
              widget.pack ??
              s.data!.packs.firstWhere(
                (p) => p.level == ProfileScope.levelOf(context),
              );
      final source = widget.words ?? r.words(pack),
          data = TrainerScope.maybeOf(context);
      final storedSettings = data?.settings ?? TrainerSettings();
      final settings = storedSettings.withValue(
        'timer',
        _timerOverride ?? storedSettings.timer,
      );
      if (settings.timer > 0) _preferredTimer = settings.timer;
      if (_selectedWords?.any((c) => data?.progress[c.id]?.excluded == true) ==
          true) {
        _selectedWords = null;
      }
      _selectedWords ??= widget.collectionTitle != null
          ? AdaptiveWordScheduler().compatible(
              source.where((c) => data?.progress[c.id]?.excluded != true),
            )
          : CurriculumSelector().select(
              source,
              data?.progress ?? {},
              settings.withValue('pairs', _pairCount),
              data?.now().toUtc() ?? DateTime.now().toUtc(),
            );
      final words = _selectedWords!, inset = pageInset(context);
      final symbol = r.categories
          .firstWhere((c) => c.id == pack.categoryId)
          .symbol;
      final size = MediaQuery.sizeOf(context);
      final scrollFooter =
          size.height < 440 ||
          (size.height < 650 &&
              MediaQuery.textScalerOf(context).scale(16) > 25.6);
      final footer = Material(
        color: Theme.of(context).colorScheme.surface,
        child: SafeArea(
          top: false,
          child: Padding(
            padding: EdgeInsets.fromLTRB(inset, 12, inset, 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                PremiumButton(
                  onPressed: words.length < _pairCount
                      ? null
                      : () => _start(words, pack, settings, data),
                  label: 'Начать тренировку',
                ),
                if (MediaQuery.sizeOf(context).height >= 440) ...[
                  const SizedBox(height: 8),
                  Text(
                    '60 совпадений · ${settings.timer == 0 ? 'без времени' : 'до ${settings.timer} секунд'} · ${pack.level.shortLabel}',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ],
            ),
          ),
        ),
      );
      return Scaffold(
        appBar: AppBar(
          toolbarHeight: MediaQuery.textScalerOf(context).scale(20) > 26
              ? MediaQuery.textScalerOf(context).scale(20) * 2.3 + 16
              : kToolbarHeight,
          title: const Text(
            'Настройка тренировки',
            maxLines: 2,
            softWrap: true,
            style: TextStyle(
              fontSize: 20,
              height: 1.15,
              fontWeight: FontWeight.w600,
            ),
          ),
          actions: [
            IconButton(
              tooltip: 'Настройки',
              icon: const Icon(Icons.settings_outlined),
              onPressed: () async {
                await Navigator.push(
                  context,
                  AiryPageRoute<void>(builder: (_) => const SettingsScreen()),
                );
                if (!mounted) return;
                setState(() {
                  _timerOverride = null;
                  _pairCount = data?.settings.pairs ?? _pairCount;
                  _selectedWords = null;
                });
              },
            ),
          ],
        ),
        bottomNavigationBar: scrollFooter ? null : footer,
        body: SafeArea(
          top: false,
          bottom: false,
          child: AiryBackground(
            child: CustomScrollView(
              slivers: [
                SliverPadding(
                  padding: EdgeInsets.fromLTRB(inset, 16, inset, 0),
                  sliver: SliverToBoxAdapter(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          widget.collectionTitle ?? pack.title,
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            CategoryGlyph(symbol: symbol),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Text(
                                '${pack.level.shortLabel} · ${source.map((c) => c.id).toSet().length} понятий в наборе',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                            ),
                          ],
                        ),
                        if (pack.goal.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 16),
                            child: Text(pack.goal),
                          ),
                        const SizedBox(height: 24),
                        Text(
                          'В этой тренировке — ${words.length} понятий. Цель — 60 совпадений. ${settings.timer == 0 ? 'Без таймера.' : 'До ${settings.timer} секунд.'}',
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Остальные слова появятся в следующих тренировках. Один раунд не означает, что набор выучен.',
                        ),
                        const SizedBox(height: 24),
                        PairCountSelector(
                          value: _pairCount,
                          onChanged: (v) {
                            setState(() {
                              _pairCount = v;
                              _selectedWords = null;
                            });
                            data
                                ?.saveSettings(
                                  storedSettings.withValue('pairs', v),
                                )
                                .catchError((Object _) {});
                          },
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'Режим',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            for (final timed in [true, false])
                              PremiumChoice(
                                key: ValueKey(
                                  timed ? 'setup-timed' : 'setup-untimed',
                                ),
                                label: timed ? 'С таймером' : 'Без времени',
                                icon: timed
                                    ? Icons.timer_outlined
                                    : Icons.all_inclusive_rounded,
                                selected: timed == (settings.timer > 0),
                                onPressed: () {
                                  final next = timed ? _preferredTimer : 0;
                                  setState(() => _timerOverride = next);
                                  data
                                      ?.saveSettings(
                                        storedSettings.withValue('timer', next),
                                      )
                                      .catchError((Object _) {});
                                },
                              ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        OutlinedButton.icon(
                          onPressed: () {
                            setState(() => _overview = !_overview);
                            if (_overview) {
                              _logOverview(source, data);
                              WidgetsBinding.instance.addPostFrameCallback((_) {
                                final anchor = _overviewAnchor.currentContext;
                                if (mounted && _overview && anchor != null) {
                                  Scrollable.ensureVisible(
                                    anchor,
                                    duration: motionDuration(
                                      context,
                                      const Duration(milliseconds: 240),
                                      calmMs: 160,
                                    ),
                                    curve: Curves.easeOutCubic,
                                  );
                                }
                              });
                            }
                          },
                          icon: Icon(
                            _overview
                                ? Icons.expand_less
                                : Icons.menu_book_outlined,
                          ),
                          label: Text(
                            _overview
                                ? 'Скрыть обзор слов'
                                : 'Посмотреть все слова · ${source.length}',
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextButton(
                          onPressed: words.isEmpty
                              ? null
                              : () => Navigator.push(
                                  context,
                                  MaterialPageRoute<void>(
                                    builder: (_) => RecallScreen(words: words),
                                  ),
                                ),
                          child: const Text('Вспомнить без вариантов'),
                        ),
                        if (words.length < _pairCount)
                          const Text(
                            'Очередь меньше поля. Выберите 4 пары или самостоятельное вспоминание.',
                          ),
                        if (_overview)
                          SectionHeader(
                            'Обзор слов',
                            key: _overviewAnchor,
                            help: 'Просмотр перевода и примера помогает познакомиться, но не считается знанием.',
                          ),
                      ],
                    ),
                  ),
                ),
                if (_overview)
                  SliverPadding(
                    padding: EdgeInsets.symmetric(horizontal: inset),
                    sliver: SliverList.builder(
                      itemCount: source.length,
                      itemBuilder: (context, i) =>
                          _OverviewWord(concept: source[i]),
                    ),
                  ),
                if (scrollFooter) SliverToBoxAdapter(child: footer),
                const SliverToBoxAdapter(child: SizedBox(height: 32)),
              ],
            ),
          ),
        ),
      );
    },
  );
}

class _OverviewWord extends StatefulWidget {
  const _OverviewWord({required this.concept});
  final VocabularyConcept concept;
  @override
  State<_OverviewWord> createState() => _OverviewWordState();
}

class _OverviewWordState extends State<_OverviewWord> {
  bool expanded = false;
  @override
  Widget build(BuildContext context) {
    final c = widget.concept, d = TrainerScope.maybeOf(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      c.english,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 6),
                    Text(c.russian),
                  ],
                ),
              ),
              if (d != null)
                IconButton(
                  tooltip: 'Избранное',
                  icon: Icon(
                    d.flags[c.id]?['favorite'] == true
                        ? Icons.star
                        : Icons.star_border,
                  ),
                  onPressed: () => d
                      .setFlag(
                        c.id,
                        favorite: d.flags[c.id]?['favorite'] != true,
                      )
                      .catchError((Object _) {}),
                ),
            ],
          ),
          Wrap(
            spacing: 4,
            children: [
              TextButton(
                onPressed: () => setState(() => expanded = !expanded),
                child: Text(expanded ? 'Скрыть пример' : 'Пример'),
              ),
              if (d != null && d.settings.values['pronunciation'] == true)
                IconButton(
                  tooltip: 'Произнести офлайн',
                  icon: const Icon(Icons.volume_up_outlined),
                  onPressed: () async {
                    try {
                      final spoken = await personalPlatform.invokeMethod<bool>(
                        'speak',
                        {
                          'text': c.english,
                          'voice': d.settings.values['voice'],
                        },
                      );
                      if (spoken != true) {
                        throw StateError('Offline voice unavailable');
                      }
                    } catch (_) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Офлайн-голос недоступен.'),
                          ),
                        );
                      }
                    }
                  },
                ),
              if (d != null)
                TextButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute<void>(
                      builder: (_) => WordDetailScreen(concept: c),
                    ),
                  ),
                  child: const Text('Прогресс'),
                ),
            ],
          ),
          if (expanded) ...[
            Text(c.exampleEn),
            const SizedBox(height: 6),
            Text(c.exampleRu),
          ],
          const SizedBox(height: 8),
          const Divider(height: 1),
        ],
      ),
    );
  }
}
