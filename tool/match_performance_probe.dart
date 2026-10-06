// A/B production-screen probe: synthetic MemoryStore, no learner writes.
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:word_journey/app/app_theme.dart';
import 'package:word_journey/features/training/widgets/match_feedback_assets.dart';
import 'package:word_journey/app/match_profile_controls.dart';
import 'package:word_journey/features/profile/cefr_level.dart';
import 'package:word_journey/features/progress/trainer_data.dart';
import 'package:word_journey/features/progress/trainer_store.dart';
import 'package:word_journey/features/progress/practice_event.dart';
import 'package:word_journey/features/settings/audio_feedback_service.dart';
import 'package:word_journey/features/vocabulary/vocabulary_repository.dart';
import 'package:word_journey/features/review/adaptive_word_scheduler.dart';
import 'package:word_journey/features/training/logic/matching_engine.dart';
import 'package:word_journey/features/training/model/matching_card.dart';
import 'package:word_journey/features/training/model/session_config.dart';
import 'package:word_journey/features/training/screens/training_game_screen.dart';
import 'package:word_journey/features/training/widgets/training_word_card.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final repo = await VocabularyRepository.load();
  AudioFeedbackService.shared.preload();
  runApp(PerformanceProbe(repo: repo));
}

class PerformanceProbe extends StatefulWidget {
  const PerformanceProbe({super.key, required this.repo});
  final VocabularyRepository repo;
  @override
  State<PerformanceProbe> createState() => _PerformanceProbeState();
}

class _PerformanceProbeState extends State<PerformanceProbe> {
  TrainerData? data;
  MatchingEngine? game;
  MatchProfileOptions options = const MatchProfileOptions();
  List<FrameTiming> frames = [];
  final _lookups = <int>[];
  bool measuring = false;
  bool soundsEnabled = true;
  static const hapticsEnabled = bool.fromEnvironment('MATCH_PROFILE_HAPTICS');
  static const quiet = bool.fromEnvironment('MATCH_QUIET_REFILL');
  String label = 'warming';
  String untouchedLabel = '';
  void reportState(String state, {String? error}) {
    File('${Directory.systemTemp.path}/wj-unmatched-state.json')
        .writeAsStringSync(
          jsonEncode({'state': state, 'scenario': label, 'error': error}),
        );
  }

  void timings(List<FrameTiming> values) {
    if (measuring) frames.addAll(values);
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addTimingsCallback(timings);
    WidgetsBinding.instance.addPostFrameCallback((_) => run());
  }

  Future<void> start(
    String name, {
    MatchProfileOptions controls = const MatchProfileOptions(),
    String motion = 'full',
    bool sounds = true,
  }) async {
    soundsEnabled = sounds;
    final next = TrainerData(store: MemoryTrainerStore());
    await next.load();
    final words = widget.repo.words(widget.repo.packs.first).take(12).toList();
    await next.append([
      for (var i = 0; i < 12; i++)
        PracticeEvent(
          id: 'probe-exposure-$i',
          sessionId: 'probe',
          conceptId: words[i].id,
          kind: PracticeKind.exposure,
          at: DateTime.utc(2026, 9, 29),
        ),
      for (var i = 0; i < 5; i++)
        PracticeEvent(
          id: 'probe-answer-$i',
          sessionId: 'probe',
          conceptId: words[i].id,
          kind: PracticeKind.matchCorrect,
          at: DateTime.utc(2026, 9, 30),
        ),
    ]);
    await next.saveSettings(
      next.settings
          .withValue('motion', motion)
          .withValue('haptics', hapticsEnabled)
          .withValue('sounds', sounds),
    );
    final source = AdaptiveWordScheduler().compatible(
      widget.repo.concepts.where((c) => c.cefrLevel == CefrLevel.c1),
    );
    final previous = data;
    if (!mounted) return;
    setState(() {
      data = next;
      label = name;
      untouchedLabel = '';
      options = controls;
      game = MatchingEngine.start(
        words: source.map((c) => c.toWordPair()).toList(),
        random: Random(26),
        config: SessionConfig(
          visiblePairs: 5,
          wordPoolSize: 20,
          targetMatches: 60,
          maxMistakes: 0,
          timeLimitSeconds: 120,
          mode: SessionMode.timed,
        ),
      );
    });
    await Future<void>.delayed(const Duration(milliseconds: 1800));
    if (previous != null) {
      await previous.flush();
      previous.dispose();
    }
    if (quiet) {
      reportState('running');
    } else {
      debugPrint('WJ_PROBE_SCREEN:$name');
    }
    await Future<void>.delayed(const Duration(milliseconds: 300));
  }

  bool tap(String id) {
    final lookup = Stopwatch()..start();
    TrainingWordCard? card;
    bool available = false;
    void visit(Element e) {
      if (e.widget is TrainingWordCard && e.widget.key == ValueKey(id)) {
        card = e.widget as TrainingWordCard;
        available = card!.enabled && !card!.completed;
        e.visitAncestorElements((a) {
          if (a.widget is IgnorePointer &&
              (a.widget as IgnorePointer).ignoring) {
            available = false;
            return false;
          }
          return true;
        });
      }
      e.visitChildElements(visit);
    }

    context.visitChildElements(visit);
    if (measuring) _lookups.add(lookup.elapsedMicroseconds);
    if (available) card?.onPressed();
    return available && card != null;
  }

  Future<void> solve({String? exceptPairId}) async {
    final g = game!;
    final a = g.leftCards
        .whereType<MatchingCard>()
        .where((c) => g.isActive(c.id) && c.pairId != exceptPairId)
        .firstOrNull;
    if (a == null) return;
    final b = g.cards.singleWhere((c) => c.pairId == a.pairId && c.id != a.id);
    if (tap(a.id)) {
      // Sequential diagnostics allow both real feedback frames to render.
      if (const bool.fromEnvironment('MATCH_SEQUENTIAL_REFILL')) {
        await Future<void>.delayed(const Duration(milliseconds: 70));
      }
      tap(b.id);
    }
  }

  Future<bool> mistake() async {
    final g = game!;
    final before = g.errorCount;
    final a = g.leftCards
        .whereType<MatchingCard>()
        .where((c) => g.isActive(c.id))
        .firstOrNull;
    if (a == null) return false;
    final b = g.rightCards
        .whereType<MatchingCard>()
        .where((c) => g.isActive(c.id) && c.pairId != a.pairId)
        .firstOrNull;
    if (b == null) return false;
    if (tap(a.id)) {
      if (const bool.fromEnvironment('MATCH_SEQUENTIAL_REFILL')) {
        await Future<void>.delayed(const Duration(milliseconds: 70));
      }
      tap(b.id);
    }
    return g.errorCount > before;
  }

  void begin() {
    frames = [];
    _lookups.clear();
    MatchProfileCounters.reset();
    measuring = true;
  }

  void emit(String name, {int? attempted}) {
    measuring = false;
    double percentile(List<int> values, double q) {
      if (values.isEmpty) return 0;
      values.sort();
      return values[((values.length - 1) * q).ceil()] / 1000;
    }

    final ui = frames.map((f) => f.buildDuration.inMicroseconds).toList(),
        raster = frames.map((f) => f.rasterDuration.inMicroseconds).toList();
    final effectMetrics = <String, dynamic>{};
    for (final kind in [
      'correct',
      'combo',
      'milestone',
      'victory',
      'victory-dock',
      'victory-result',
    ]) {
      final windows = MatchProfileCounters.feedbackWindows.where(
        (w) => w.$1 == kind,
      );
      final sample = frames.where((f) {
        final at = f.timestampInMicroseconds(FramePhase.buildStart);
        return windows.any((w) => at >= w.$2 && at <= w.$2 + w.$3);
      }).toList();
      final u = sample.map((f) => f.buildDuration.inMicroseconds).toList();
      final r = sample.map((f) => f.rasterDuration.inMicroseconds).toList();
      effectMetrics[kind] = {
        'frames': sample.length,
        'starts': windows.length,
        'uiP95Ms': percentile(u, .95),
        'rasterP95Ms': percentile(r, .95),
        'rasterP99Ms': percentile(List.of(r), .99),
        'over16_67ms': sample
            .where(
              (f) =>
                  max(
                    f.buildDuration.inMicroseconds,
                    f.rasterDuration.inMicroseconds,
                  ) >
                  16667,
            )
            .length,
      };
    }
    final payload = base64Encode(
      utf8.encode(
        jsonEncode({
          'scenario': name,
          'feedbackBackend': options.lottie ? 'lottie' : 'custompaint',
          'lottieReadyCount': MatchDecoration.values
              .where((k) => MatchFeedbackAssets.shared.composition(k) != null)
              .length,
          'lottieFailureCount': MatchFeedbackAssets.shared.failures.length,
          'feedbackWindows': effectMetrics,
          'soundsEnabled': soundsEnabled,
          'hapticsEnabled': hapticsEnabled,
          'harnessLookupP95Ms': percentile(List.of(_lookups), .95),
          'frames': frames.length,
          'matches': game!.matchedCount,
          'mistakes': game!.errorCount,
          'attemptedPairs': attempted,
          'uiP50Ms': percentile(ui, .5),
          'uiP95Ms': percentile(ui, .95),
          'uiP99Ms': percentile(ui, .99),
          'rasterP50Ms': percentile(raster, .5),
          'rasterP95Ms': percentile(raster, .95),
          'rasterP99Ms': percentile(raster, .99),
          'over8_33ms': frames
              .where(
                (f) =>
                    max(
                      f.buildDuration.inMicroseconds,
                      f.rasterDuration.inMicroseconds,
                    ) >
                    8333,
              )
              .length,
          'over16_67ms': frames
              .where(
                (f) =>
                    max(
                      f.buildDuration.inMicroseconds,
                      f.rasterDuration.inMicroseconds,
                    ) >
                    16667,
              )
              .length,
          ...MatchProfileCounters.snapshot(),
        }),
      ),
    );
    final parts = (payload.length / 700).ceil();
    if (quiet) {
      File('${Directory.systemTemp.path}/wj-unmatched-$name.json')
          .writeAsStringSync(utf8.decode(base64Decode(payload)));
      return;
    }
    for (var i = 0; i < parts; i++) {
      debugPrint(
        'WJ_PROBE_PART:$name:$i/$parts:${payload.substring(i * 700, min((i + 1) * 700, payload.length))}',
      );
    }
  }

  Future<void> rapid(
    String name, {
    MatchProfileOptions controls = const MatchProfileOptions(),
    String motion = 'full',
    bool sounds = true,
  }) async {
    await start(name, controls: controls, motion: motion, sounds: sounds);
    begin();
    final watch = Stopwatch()..start();
    final errors = <int>{};
    var attempts = 0;
    while (game!.matchedCount < 60 &&
        watch.elapsed < const Duration(seconds: 50)) {
      if ([7, 23, 41].contains(game!.matchedCount) &&
          !errors.contains(game!.matchedCount)) {
        if (await mistake()) errors.add(game!.matchedCount);
      } else {
        await solve();
        attempts++;
      }
      await Future<void>.delayed(const Duration(milliseconds: 170));
    }
    await Future<void>.delayed(const Duration(milliseconds: 1150));
    emit(name, attempted: attempts);
    if (game!.matchedCount != 60 || game!.errorCount < 3) {
      throw StateError('Full scenario must reach 60 matches and three errors');
    }
  }

  Future<void> window(String name, Future<void> Function() action) async {
    debugPrint('WJ_PROBE_SCREEN:$name');
    await Future<void>.delayed(const Duration(milliseconds: 300));
    begin();
    await action();
    await Future<void>.delayed(const Duration(milliseconds: 1150));
    emit(name);
  }

  Future<void> run() async {
    try {
      if (quiet) reportState('warming');
      await Future<void>.delayed(const Duration(seconds: 2));
      if (quiet) {
        await rapid('sequential-fast-full-c1');
        await start('sequential-slow-full-c1');
        begin();
        for (var i = 0; i < 12; i++) {
          await solve();
          await Future<void>.delayed(const Duration(milliseconds: 5200));
        }
        emit('sequential-slow-full-c1', attempted: 12);
        if (game!.matchedCount != 12) {
          throw StateError('Slow scenario missed input');
        }
        // Recording and assertions run after metrics on isolated MemoryStore.
        await start('video-untouched-x');
        final g = game!;
        final x = g.leftCards.whereType<MatchingCard>().last;
        final translation = g.cards.singleWhere(
          (c) => c.pairId == x.pairId && c.id != x.id,
        );
        final fixed = {
          x: g.slotIdOf(x.id)!,
          translation: g.slotIdOf(translation.id)!,
        };
        setState(() => untouchedLabel = 'X: ${x.text} / ${translation.text}');
        var samples = 0;
        Future<void> checkFor(int ms) async {
          final watch = Stopwatch()..start();
          while (watch.elapsedMilliseconds < ms) {
            for (final entry in fixed.entries) {
              final c = entry.key;
              if (!identical(g.cardAt(entry.value), c) || !g.isActive(c.id)) {
                throw StateError('Untouched X content changed');
              }
              TrainingWordCard? current;
              void visit(Element e) {
                if (e.widget is TrainingWordCard &&
                    e.widget.key == ValueKey(c.id)) {
                  current = e.widget as TrainingWordCard;
                }
                e.visitChildElements(visit);
              }

              if (!mounted) throw StateError('Probe disposed');
              context.visitChildElements(visit);
              if (current == null ||
                  !current!.enabled ||
                  current!.completed ||
                  current!.text != c.text ||
                  (current!.flowVisual?.textOpacity ??
                          current!.textOpacity.value) !=
                      1 ||
                  (current!.flowVisual?.surfaceOpacity ??
                          current!.surfaceOpacity.value) !=
                      1) {
                throw StateError('Untouched X lost visibility or input');
              }
            }
            samples++;
            await Future<void>.delayed(const Duration(milliseconds: 16));
          }
        }

        await checkFor(1200);
        await solve(exceptPairId: x.pairId);
        await checkFor(430);
        await solve(exceptPairId: x.pairId);
        await checkFor(6000);
        await solve(exceptPairId: x.pairId);
        await checkFor(5200);
        await solve(exceptPairId: x.pairId);
        await checkFor(430);
        await solve(exceptPairId: x.pairId);
        await checkFor(3500);
        File('${Directory.systemTemp.path}/wj-unmatched-untouched.json')
            .writeAsStringSync(
              jsonEncode({
                'samples': samples,
                'matchedOtherPairs': g.matchedCount,
                'preserved': true,
                'cards': [
                  for (final entry in fixed.entries)
                    {
                      'id': entry.key.id,
                      'conceptId': entry.key.conceptId,
                      'text': entry.key.text,
                      'left': entry.value.left,
                      'row': entry.value.row,
                    },
                ],
                'inputMethod':
                    'production widget callbacks; no physical touch injection',
              }),
            );
        reportState('complete');
        return;
      }
      if (const bool.fromEnvironment('MATCH_SEQUENTIAL_REFILL')) {
        await rapid('sequential-fast-full-c1');
        await start('sequential-slow-full-c1');
        begin();
        for (var i = 0; i < 12; i++) {
          await solve();
          await Future<void>.delayed(const Duration(milliseconds: 5200));
          debugPrint('WJ_SEQ_SLOW_PROGRESS:${game!.matchedCount}/12');
        }
        emit('sequential-slow-full-c1', attempted: 12);
        if (game!.matchedCount != 12) {
          throw StateError('Slow scenario missed input');
        }
        // Video capture starts only after metrics, so screenrecord does not
        // contaminate the measured frame and response distributions.
        await start('video-a-alone');
        await Future<void>.delayed(const Duration(seconds: 1));
        await solve();
        await Future<void>.delayed(const Duration(seconds: 10));
        await start('video-a-b-500ms');
        await Future<void>.delayed(const Duration(seconds: 1));
        await solve();
        await Future<void>.delayed(const Duration(milliseconds: 430));
        await solve();
        await Future<void>.delayed(const Duration(seconds: 10));
        await start('video-rapid-a-b-c-d');
        await Future<void>.delayed(const Duration(seconds: 1));
        for (var i = 0; i < 4; i++) {
          await solve();
          await Future<void>.delayed(const Duration(milliseconds: 110));
        }
        await Future<void>.delayed(const Duration(seconds: 10));
        debugPrint('WJ_PROBE_DONE:sequential');
        return;
      }
      if (const bool.fromEnvironment('MATCH_LOTTIE_AB')) {
        await rapid(
          'A-custompaint-full-c1',
          controls: const MatchProfileOptions(lottie: false),
        );
        await rapid('B-lottie-full-c1');
        await rapid(
          'A-custompaint-repeat-c1',
          controls: const MatchProfileOptions(lottie: false),
        );
        await rapid('B-lottie-repeat-c1');
        await rapid('B-lottie-calm-c1', motion: 'calm');
        await rapid(
          'A-custompaint-minimal-c1',
          controls: const MatchProfileOptions(lottie: false),
          motion: 'minimal',
        );
        await rapid('B-lottie-minimal-c1', motion: 'minimal');
      } else if (const bool.fromEnvironment('MATCH_AB')) {
        await rapid('F-full-c1');
        await rapid(
          'A-no-ambient-c1',
        ); // Current atmospheric layers already have no animation.
        await rapid(
          'B-no-combo-c1',
          controls: const MatchProfileOptions(lightning: false),
        );
        await rapid(
          'D-no-card-decoration-c1',
          controls: const MatchProfileOptions(cardDecoration: false),
        );
        await rapid(
          'E-no-particles-c1',
          controls: const MatchProfileOptions(particles: false),
        );
        await rapid(
          'D2-no-card-scale-c1',
          controls: const MatchProfileOptions(cardScale: false),
        );
        await rapid(
          'A2-flat-background-c1',
          controls: const MatchProfileOptions(background: false),
        );
        await rapid('F-full-repeat-c1');
      } else {
        await rapid('match-5-full-c1');
        await rapid('match-5-full-repeat-c1');
        await rapid('sound-off-full-c1', sounds: false);
        await rapid('match-5-calm-c1', motion: 'calm');
        await rapid('match-5-minimal-c1', motion: 'minimal');
      }
      await start('idle-match-c1');
      begin();
      await Future<void>.delayed(const Duration(seconds: 5));
      emit('idle-match-c1');
      await window('correct-card-c1', solve);
      await window('combo-lightning-c1', solve);
      await window('batch-refill-c1', () async {
        await solve();
        await Future<void>.delayed(const Duration(milliseconds: 100));
        await solve();
      });
      while (game!.matchedCount < 19) {
        await solve();
        await Future<void>.delayed(const Duration(milliseconds: 250));
      }
      await Future<void>.delayed(const Duration(milliseconds: 800));
      await window('milestone-20-c1', solve);
      debugPrint('WJ_PROBE_DONE:performance');
    } catch (e, s) {
      if (quiet) {
        reportState('failed', error: '$e\n$s');
        return;
      }
      debugPrint('WJ_PROBE_FAILED:$e\n$s');
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeTimingsCallback(timings);
    data?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => data == null
      ? const MaterialApp(home: Scaffold())
      : TrainerScope(
          data: data!,
          child: MatchProfileScope(
            options: options,
            child: MaterialApp(
              debugShowCheckedModeBanner: false,
              theme: AppTheme.dark,
              home: Column(
                children: [
                  Expanded(
                    child: Navigator(
                      key: ObjectKey(game),
                      onGenerateRoute: (_) => MaterialPageRoute<void>(
                        builder: (_) => TrainingGameScreen(game: game!),
                      ),
                    ),
                  ),
                  Material(
                    color: Color(0xFF222C45),
                    child: SafeArea(
                      top: false,
                      child: Padding(
                        padding: EdgeInsets.all(4),
                        child: Text(
                          untouchedLabel.isEmpty
                              ? 'PROFILE · отдельные тестовые данные'
                              : untouchedLabel,
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFF756FFF),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
}
