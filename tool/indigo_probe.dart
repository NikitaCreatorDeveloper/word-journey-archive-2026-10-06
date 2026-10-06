// Reproducible on-device rendering probe. No input injection or learner writes.
import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:word_journey/app/app_shell.dart';
import 'package:word_journey/app/app_theme.dart';
import 'package:word_journey/app/airy_components.dart';
import 'package:word_journey/app/premium_components.dart';
import 'package:word_journey/features/progress/practice_event.dart';
import 'package:word_journey/app/reward_presentation.dart';
import 'package:word_journey/features/profile/cefr_level.dart';
import 'package:word_journey/features/profile/cefr_profile.dart';
import 'package:word_journey/features/progress/trainer_data.dart';
import 'package:word_journey/features/progress/trainer_store.dart';
import 'package:word_journey/features/settings/audio_feedback_service.dart';
import 'package:word_journey/features/settings/settings_screen.dart';
import 'package:word_journey/features/topics/categories_screen.dart';
import 'package:word_journey/features/training/screens/training_setup_screen.dart';
import 'package:word_journey/features/training/screens/training_result_screen.dart';
import 'package:word_journey/features/training/model/session_result.dart';
import 'package:word_journey/features/training/logic/matching_engine.dart';
import 'package:word_journey/features/training/model/session_config.dart';
import 'package:word_journey/features/training/widgets/training_board.dart';
import 'package:word_journey/features/training/widgets/training_progress_header.dart';
import 'package:word_journey/features/training/widgets/lightning_feedback.dart';
import 'package:word_journey/features/review/recall_screen.dart';
import 'package:word_journey/features/review/adaptive_word_scheduler.dart';
import 'package:word_journey/features/vocabulary/vocabulary_repository.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final coldClock = Stopwatch()..start();
  final data = TrainerData(store: MemoryTrainerStore());
  await data.load();
  final repo = await VocabularyRepository.load();
  debugPrint(
    'WJ_PROBE_COLD:catalogAndMemoryLoadMs=${coldClock.elapsedMilliseconds}',
  );
  // Synthetic journal in the isolated MemoryStore; never writes the learner DB.
  final now = DateTime.now().toUtc();
  final seedWords = repo.words(repo.packs.first).take(12).toList();
  await data.append([
    for (var i = 0; i < seedWords.length; i++)
      PracticeEvent(
        id: 'probe-exposure-$i',
        sessionId: 'probe',
        conceptId: seedWords[i].id,
        kind: PracticeKind.exposure,
        at: now.subtract(const Duration(days: 3)),
      ),
    for (var i = 0; i < 5; i++)
      PracticeEvent(
        id: 'probe-answer-$i',
        sessionId: 'probe',
        conceptId: seedWords[i].id,
        kind: PracticeKind.matchCorrect,
        at: now.subtract(const Duration(days: 2)),
      ),
  ]);
  await data.store!.write('flags', [
    for (final word in seedWords.take(10))
      {
        'id': word.id,
        'favorite': false,
        'excluded': false,
        'firstConsolidatedAt': now
            .subtract(const Duration(days: 2))
            .toIso8601String(),
      },
  ]);
  await data.load();
  await data.saveSession({
    'id': 'probe',
    'packId': repo.packs.first.id,
    'mode': 'match',
    'correct': 5,
    'wrong': 0,
    'elapsedMs': 15000,
    'completed': false,
    'at': now.subtract(const Duration(days: 2)).toIso8601String(),
  });
  final profile = CefrProfile(_ProbeLevelStore());
  await profile.load();
  AudioFeedbackService.shared.preload();
  runApp(
    TrainerScope(
      data: data,
      child: ProfileScope(
        profile: profile,
        child: Probe(
          data: data,
          repo: repo,
          uiOnly: const bool.fromEnvironment('INDIGO_UI_ONLY'),
        ),
      ),
    ),
  );
}

class _ProbeLevelStore implements LevelStore {
  @override
  Future<CefrLevel?> read() async => CefrLevel.a1;
  @override
  Future<void> write(CefrLevel level) async {}
}

class Probe extends StatefulWidget {
  const Probe({
    super.key,
    required this.data,
    required this.repo,
    this.uiOnly = false,
  });
  final bool uiOnly;
  final TrainerData data;
  final VocabularyRepository repo;
  @override
  State<Probe> createState() => _ProbeState();
}

class _ProbeState extends State<Probe> {
  final _navigator = GlobalKey<NavigatorState>();
  String phase = 'starting';
  bool dark = false;
  MatchingEngine? game;
  List<FrameTiming> frames = [];
  bool measuring = false;
  final summaries = <Map<String, dynamic>>[];
  int combo = 0;
  double? _labelHeight;
  void timings(List<FrameTiming> values) {
    if (measuring) frames.addAll(values);
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addTimingsCallback(timings);
    WidgetsBinding.instance.addPostFrameCallback((_) => runProbe());
  }

  Future<void> show(String label, {bool night = false}) async {
    await ProfileScope.maybeOf(context)!
        .choose(label.contains('c1') ? CefrLevel.c1 : CefrLevel.a1);
    setState(() {
      phase = label;
      dark = night;
      game = null;
    });
    await Future<void>.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;
    if (label.startsWith('review-empty')) {
      void findFilter(Element e) {
        if (e.widget is PremiumChoice &&
            e.widget.key == const ValueKey('review-filter-errors')) {
          (e.widget as PremiumChoice).onPressed();
        }
        e.visitChildElements(findFilter);
      }

      context.visitChildElements(findFilter);
      await Future<void>.delayed(const Duration(milliseconds: 300));
    }
    debugPrint('WJ_PROBE_SCREEN:$label');
    await Future<void>.delayed(const Duration(seconds: 3));
  }

  Future<void> runProbe() async {
    await Future<void>.delayed(const Duration(seconds: 2));
    if (!widget.uiOnly) {
      for (final night in [false, true]) {
        for (final screen in [
          'categories',
          'packs',
          'pack',
          'pack-c1',
          'result',
          'review',
          'review-empty',
          'progress',
          'settings',
          'recall',
        ]) {
          await show('$screen-${night ? 'dark' : 'light'}', night: night);
          if (screen == 'pack') {
            VoidCallback? open;
            void findOverview(Element e) {
              if (e.widget is OutlinedButton) {
                var matches = false;
                void text(Element child) {
                  if (child.widget is Text &&
                      ((child.widget as Text).data ?? '').startsWith(
                        'Посмотреть все слова',
                      )) {
                    matches = true;
                  }
                  child.visitChildElements(text);
                }

                e.visitChildElements(text);
                if (matches) open = (e.widget as OutlinedButton).onPressed;
              }
              e.visitChildElements(findOverview);
            }

            if (!mounted) return;
            context.visitChildElements(findOverview);
            if (open == null) {
              throw StateError('Production overview control not found');
            }
            open!();
            await Future<void>.delayed(const Duration(milliseconds: 600));
            debugPrint(
              'WJ_PROBE_SCREEN:pack-overview-${night ? 'dark' : 'light'}',
            );
            await Future<void>.delayed(const Duration(seconds: 3));
          }
        }
      }
      final lightWords = AdaptiveWordScheduler().compatible(
        widget.repo.concepts.where((c) => c.cefrLevel == CefrLevel.c1),
      );
      setState(() {
        phase = 'match-light-c1';
        dark = false;
        combo = 0;
        _labelHeight = null;
        game = MatchingEngine.start(
          words: lightWords.map((c) => c.toWordPair()).toList(),
          config: SessionConfig(
            visiblePairs: 5,
            wordPoolSize: 20,
            targetMatches: 60,
            maxMistakes: 0,
            mode: SessionMode.practice,
          ),
          random: Random(26),
        );
      });
      await Future<void>.delayed(const Duration(milliseconds: 600));
      debugPrint('WJ_PROBE_SCREEN:match-light-c1');
      await Future<void>.delayed(const Duration(seconds: 3));
      for (final spec in [
        (4, 'calm', 'a1'),
        (5, 'full', 'c1'),
        (5, 'calm', 'c1'),
        (5, 'minimal', 'c1'),
        (4, 'full', 'c1'),
        (5, 'calm', 'a1'),
      ]) {
        await widget.data.saveSettings(
          widget.data.settings
              .withValue('motion', spec.$2)
              .withValue('haptics', false),
        );
        final words = AdaptiveWordScheduler().compatible(
          widget.repo.concepts.where((c) => c.cefrLevel!.id == spec.$3),
        );
        final current = MatchingEngine.start(
          words: words.map((c) => c.toWordPair()).toList(),
          config: SessionConfig(
            visiblePairs: spec.$1,
            wordPoolSize: 20,
            targetMatches: 60,
            maxMistakes: 0,
            mode: SessionMode.practice,
          ),
          random: Random(26),
        );
        setState(() {
          game = current;
          _labelHeight = null;
          combo = 0;
          phase = 'match-${spec.$1}-${spec.$2}-${spec.$3}';
          dark = true;
        });
        await Future<void>.delayed(const Duration(seconds: 1));
        frames = [];
        measuring = true;
        debugPrint('WJ_PROBE_SCREEN:$phase');
        final clock = Stopwatch()..start();
        while (current.matchedCount < 60 &&
            clock.elapsed < const Duration(seconds: 30)) {
          final card = current.leftCards
              .whereType<dynamic>()
              .where((c) => current.isActive(c.id as String))
              .firstOrNull;
          if (card != null) {
            final mate = current.cards.firstWhere(
              (c) => c.pairId == card.pairId && c.id != card.id,
            );
            current.select(card.id as String);
            current.select(mate.id);
            combo++;
            AudioFeedbackService.shared.feedback(
              [5, 10, 20].contains(combo)
                  ? 'combo'
                  : [20, 30, 60].contains(current.matchedCount)
                  ? 'milestone'
                  : 'correct',
              widget.data.settings,
            );
            setState(() {});
          }
          await Future<void>.delayed(const Duration(milliseconds: 170));
        }
        await Future<void>.delayed(const Duration(seconds: 1));
        measuring = false;
        final ui =
            frames.map((f) => f.buildDuration.inMicroseconds / 1000).toList()
              ..sort();
        final raster =
            frames.map((f) => f.rasterDuration.inMicroseconds / 1000).toList()
              ..sort();
        double percentile(List<double> values, double p) =>
            values.isEmpty ? 0 : values[(p * (values.length - 1)).round()];
        final summary = {
          'scenario': phase,
          'frames': frames.length,
          'matches': current.matchedCount,
          'elapsedMs': clock.elapsedMilliseconds,
          'uiP50Ms': percentile(ui, .5),
          'uiP95Ms': percentile(ui, .95),
          'uiP99Ms': percentile(ui, .99),
          'rasterP50Ms': percentile(raster, .5),
          'rasterP95Ms': percentile(raster, .95),
          'rasterP99Ms': percentile(raster, .99),
          'over16_67ms': frames
              .where(
                (f) =>
                    f.buildDuration.inMicroseconds > 16667 ||
                    f.rasterDuration.inMicroseconds > 16667,
              )
              .length,
          'over8_33ms': frames
              .where(
                (f) =>
                    f.buildDuration.inMicroseconds > 8333 ||
                    f.rasterDuration.inMicroseconds > 8333,
              )
              .length,
        };
        summaries.add(summary);
        debugPrint('WJ_PROBE_METRIC:${jsonEncode(summary)}');
      }
    }
    await widget.data.saveSettings(
      widget.data.settings.withValue('motion', 'full'),
    );
    await uiProbe('scroll-categories', () async {
      final scroll = findVertical();
      if (scroll == null || scroll.position.maxScrollExtent <= 0) {
        throw StateError('Real category overflow required');
      }
      for (var i = 0; i < 6; i++) {
        await scroll.position.animateTo(
          i.isEven ? scroll.position.maxScrollExtent : 0,
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeInOut,
        );
      }
    });
    await uiProbe('switch-cefr', () async {
      final selection = ProfileScope.maybeOf(context)!;
      for (final level in [...CefrLevel.values, ...CefrLevel.values]) {
        await selection.choose(level);
        await Future<void>.delayed(const Duration(milliseconds: 220));
      }
    });
    await uiProbe('first-search', () async {
      TextField? search;
      void visit(Element e) {
        if (e.widget is TickerMode && !(e.widget as TickerMode).enabled) return;
        if (e.widget is TextField) search = e.widget as TextField;
        e.visitChildElements(visit);
      }

      context.visitChildElements(visit);
      if (search == null) throw StateError('Production search required');
      search!.onChanged!('coffee');
      await Future<void>.delayed(const Duration(milliseconds: 400));
    });
    await uiProbe('category-c1', () async {
      VoidCallback? open;
      void visit(Element e) {
        if (e.widget is TickerMode && !(e.widget as TickerMode).enabled) return;
        if (e.widget is SurfaceCard) {
          var match = false;
          void check(Element child) {
            if (child.widget is Text &&
                (child.widget as Text).data ==
                    widget.repo.categories.first.title) {
              match = true;
            }
            child.visitChildElements(check);
          }

          e.visitChildElements(check);
          if (match) open = (e.widget as SurfaceCard).onTap;
        }
        e.visitChildElements(visit);
      }

      context.visitChildElements(visit);
      if (open == null) {
        throw StateError('Production C1 category control required');
      }
      open!();
      await Future<void>.delayed(const Duration(milliseconds: 650));
      debugPrint('WJ_PROBE_SCREEN:category-c1-open');
      final scroll = findVertical();
      if (scroll != null) {
        await scroll.position.animateTo(
          scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeOutCubic,
        );
      }
    });
    await widget.data.saveSettings(
      widget.data.settings.withValue('motion', 'full'),
    );
    _navigator.currentState!.pop();
    await Future<void>.delayed(const Duration(milliseconds: 350));
    await uiProbe('progress-screen', () async {
      await Future<void>.delayed(const Duration(milliseconds: 700));
      debugPrint('WJ_PROBE_SCREEN:progress-entered');
      final scroll = findVertical();
      if (scroll != null) {
        await scroll.position.animateTo(
          scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 800),
          curve: Curves.easeInOut,
        );
      }
    });
    await uiProbe('correct-effect', () async {
      await Future<void>.delayed(const Duration(milliseconds: 650));
    });
    await uiProbe('scroll-packs', () async {
      final scroll = findVertical();
      if (scroll == null || scroll.position.maxScrollExtent <= 0) {
        throw StateError('Scroll benchmark needs real overflow');
      }
      debugPrint('WJ_PROBE_SCROLL_EXTENT:${scroll.position.maxScrollExtent}');
      for (var i = 0; i < 6; i++) {
        await scroll.position.animateTo(
          i.isEven ? scroll.position.maxScrollExtent : 0,
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeInOut,
        );
      }
    });
    await uiProbe('search-categories', () async {
      TextField? search;
      void visit(Element e) {
        if (e.widget is TextField) search = e.widget as TextField;
        e.visitChildElements(visit);
      }

      context.visitChildElements(visit);
      for (final query in [
        'c',
        'co',
        'cof',
        'coff',
        'coffe',
        'coffee',
        'ко',
        'коф',
        'кофе',
        '',
      ]) {
        search?.onChanged?.call(query);
        await Future<void>.delayed(const Duration(milliseconds: 180));
      }
    });
    await widget.data.saveSettings(
      widget.data.settings.withValue('motion', 'full'),
    );
    await uiProbe('reward', () async {
      await Future<void>.delayed(const Duration(seconds: 2));
    });
    final voices = await personalPlatform
        .invokeListMethod<dynamic>('voices')
        .timeout(const Duration(seconds: 10), onTimeout: () => []);
    debugPrint(
      'WJ_PROBE_VOICES:${jsonEncode({'count': voices?.length ?? 0, 'examples': voices?.take(2).toList() ?? []})}',
    );
    debugPrint('WJ_PROBE_DONE:${jsonEncode(summaries)}');
    await show('done', night: true);
  }

  ScrollableState? findVertical() {
    ScrollableState? result;
    void visit(Element e) {
      if (e.widget is TickerMode && !(e.widget as TickerMode).enabled) return;
      if (e is StatefulElement &&
          e.state is ScrollableState &&
          (e.widget as Scrollable).axisDirection == AxisDirection.down) {
        result ??= e.state as ScrollableState;
      }
      e.visitChildElements(visit);
    }

    context.visitChildElements(visit);
    return result;
  }

  Future<void> uiProbe(String label, Future<void> Function() action) async {
    // A reward must be measured while it enters, before its finite tween ends.
    await show(
      ['reward', 'progress-screen', 'correct-effect'].contains(label)
          ? 'reward-preparation'
          : label,
      night: true,
    );
    frames = [];
    measuring = true;
    final watch = Stopwatch()..start();
    if (['reward', 'progress-screen', 'correct-effect'].contains(label)) {
      setState(() => phase = label);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        debugPrint('WJ_PROBE_SCREEN:$label');
      });
    }
    await action();
    await Future<void>.delayed(const Duration(milliseconds: 500));
    measuring = false;
    final ui = frames.map((f) => f.buildDuration.inMicroseconds / 1000).toList()
          ..sort(),
        raster =
            frames.map((f) => f.rasterDuration.inMicroseconds / 1000).toList()
              ..sort();
    double percentile(List<double> xs, double p) =>
        xs.isEmpty ? 0 : xs[(p * (xs.length - 1)).round()];
    final m = {
      'scenario': label,
      'frames': frames.length,
      'valid': frames.isNotEmpty,
      'elapsedMs': watch.elapsedMilliseconds,
      'uiP50Ms': percentile(ui, .5),
      'uiP95Ms': percentile(ui, .95),
      'uiP99Ms': percentile(ui, .99),
      'rasterP50Ms': percentile(raster, .5),
      'rasterP95Ms': percentile(raster, .95),
      'rasterP99Ms': percentile(raster, .99),
      'over8_33ms': frames
          .where(
            (f) =>
                f.buildDuration.inMicroseconds > 8333 ||
                f.rasterDuration.inMicroseconds > 8333,
          )
          .length,
      'over16_67ms': frames
          .where(
            (f) =>
                f.buildDuration.inMicroseconds > 16667 ||
                f.rasterDuration.inMicroseconds > 16667,
          )
          .length,
    };
    summaries.add(m);
    debugPrint('WJ_PROBE_METRIC:${jsonEncode(m)}');
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeTimingsCallback(timings);
    super.dispose();
  }

  Widget page() {
    if (game case final g?) {
      return Scaffold(
        body: AiryBackground(
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  TrainingProgressHeader(
                    seconds: 120,
                    progress: g.progress,
                    onSettled: () {},
                    onExit: () {},
                  ),
                  LightningFeedback(revision: g.matchedCount, combo: combo),
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        var height = 54.0;
                        if (_labelHeight == null) {
                          for (final word in g.wordPool) {
                            for (final label in [word.english, word.russian]) {
                              final text =
                                  TextPainter(
                                    text: TextSpan(
                                      text: label,
                                      style: trainingWordStyle(
                                        label,
                                        (constraints.maxWidth -
                                                    AppTokens.boardGap) /
                                                2 -
                                            2 * AppTokens.cardHorizontalPadding,
                                        MediaQuery.textScalerOf(context),
                                      ),
                                    ),
                                    textDirection: TextDirection.ltr,
                                    textScaler: MediaQuery.textScalerOf(
                                      context,
                                    ),
                                  )..layout(
                                    maxWidth:
                                        (constraints.maxWidth -
                                                AppTokens.boardGap) /
                                            2 -
                                        2 * AppTokens.cardHorizontalPadding,
                                  );
                              height = max(height, text.height + 12);
                              text.dispose();
                            }
                          }
                        }
                        _labelHeight ??= height;
                        height = _labelHeight!;
                        return Center(
                          child: SingleChildScrollView(
                            child: TrainingBoard(
                              key: ObjectKey(g),
                              game: g,
                              cardHeight: height,
                              errors: const {},
                              onSelect: (_) {},
                              onBoardChanged: () {
                                if (mounted) setState(() {});
                              },
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }
    if (phase == 'correct-effect') {
      return const Scaffold(
        body: AiryBackground(
          child: Center(child: LightningFeedback(revision: 1, combo: 2)),
        ),
      );
    }
    if (phase == 'reward') {
      return const Scaffold(
        body: SafeArea(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: RewardPresentation(
              title: 'Весь набор',
              detail: 'Ответили верно по каждому понятию. Следующий шаг — вернуться к словам по сроку.',
            ),
          ),
        ),
      );
    }
    if (phase == 'scroll-packs') {
      return CategoryScreen(
        repository: widget.repo,
        category: widget.repo.categories.firstWhere((c) => c.id == 'food'),
      );
    }
    if (phase.startsWith('packs')) {
      return CategoryScreen(
        repository: widget.repo,
        category: widget.repo.categories.first,
      );
    }
    if (phase.startsWith('pack')) {
      final pack = phase.startsWith('pack-c1')
          ? widget.repo.packs.firstWhere((p) => p.level == CefrLevel.c1)
          : widget.repo.packs.first;
      return TrainingSetupScreen(
        key: ValueKey(phase),
        pack: pack,
        words: widget.repo.words(pack),
      );
    }
    if (phase.startsWith('result')) {
      return TrainingResultScreen(
        result: const SessionResult(
          targetMatches: 60,
          completedMatches: 60,
          wrongAttempts: 2,
          elapsedTime: Duration(seconds: 93),
          remainingTime: Duration(seconds: 27),
          endReason: SessionEndReason.targetReached,
        ),
        onPlayAgain: () {},
        onBackToSetup: () {},
      );
    }
    if (phase.startsWith('settings')) {
      return const SettingsScreen();
    }
    if (phase.startsWith('recall')) {
      return RecallScreen(words: widget.repo.concepts.take(4).toList());
    }
    return AppShell(
      key: ValueKey(phase),
      initialIndex: phase.startsWith('review')
          ? 1
          : phase.startsWith('progress')
          ? 2
          : 0,
    );
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
    navigatorKey: _navigator,
    debugShowCheckedModeBanner: false,
    theme: dark ? AppTheme.dark : AppTheme.light,
    home: Column(
      children: [
        Expanded(child: page()),
        Material(
          color: dark ? const Color(0xFF222C45) : const Color(0xFFDADFFE),
          child: const SafeArea(
            top: false,
            child: Padding(
              padding: EdgeInsets.all(4),
              child: Text(
                'PROFILE · отдельные тестовые данные',
                style: TextStyle(fontSize: 11, color: Color(0xFF756FFF)),
              ),
            ),
          ),
        ),
      ],
    ),
  );
}
