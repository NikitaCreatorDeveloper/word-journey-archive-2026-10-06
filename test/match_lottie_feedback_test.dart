import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lottie/lottie.dart';
import 'package:word_journey/app/app_theme.dart';
import 'package:word_journey/app/motion_preferences.dart';
import 'package:word_journey/features/progress/trainer_data.dart';
import 'package:word_journey/features/progress/trainer_store.dart';
import 'package:word_journey/features/training/logic/matching_engine.dart';
import 'package:word_journey/features/training/model/matching_card.dart';
import 'package:word_journey/features/training/model/session_config.dart';
import 'package:word_journey/features/training/model/test_words.dart';
import 'package:word_journey/features/training/screens/training_game_screen.dart';
import 'package:word_journey/features/training/screens/training_result_screen.dart';
import 'package:word_journey/features/training/widgets/lightning_feedback.dart';
import 'package:word_journey/features/training/widgets/match_feedback_assets.dart';
import 'package:word_journey/features/training/widgets/match_feedback_overlay.dart';
import 'package:word_journey/features/training/widgets/safe_match_lottie.dart';

Future<MatchFeedbackAssets> prepared() async {
  final compositions = <String, LottieComposition>{};
  for (final kind in MatchDecoration.values) {
    compositions[kind.name] = await LottieComposition.fromByteData(
      await rootBundle.load('assets/lottie/${kind.name}.json'),
    );
  }
  final store = MatchFeedbackAssets(
    loader: (p) async => compositions[p.split('/').last.split('.').first]!,
  );
  await store.preload();
  return store;
}

Widget dock(
  MatchFeedbackController c, {
  String motion = 'full',
  bool reduced = false,
  ValueChanged<int>? onPeak,
}) => MaterialApp(
  theme: AppTheme.dark,
  home: MediaQuery(
    data: MediaQueryData(disableAnimations: reduced),
    child: LocalMotionScope(
      motion: motion,
      child: Scaffold(
        body: Center(
          child: MatchFeedbackReward(controller: c, onComboPeak: onPeak),
        ),
      ),
    ),
  ),
);

void main() {
  testWidgets(
    'Rapid combo replacement discards elapsed time and stale cleanup; preload is reused',
    (t) async {
      final ready = await prepared();
      final calls = <String>[];
      final assets = MatchFeedbackAssets(
        loader: (path) async {
          calls.add(path);
          return ready.composition(
            MatchDecoration.values.singleWhere(
              (k) => path.endsWith('${k.name}.json'),
            ),
          )!;
        },
      );
      final c = MatchFeedbackController(assets: assets);
      await c.prepare();
      await c.prepare();
      expect(calls, hasLength(4));
      final peaks = <int>[];
      await t.pumpWidget(dock(c, onPeak: peaks.add));
      MatchFeedbackEvent? previous;
      for (var count = 2; count <= 5; count++) {
        c.showCombo(count, revision: count);
        final current = c.reward.value!;
        expect(current.elapsed, Duration.zero);
        if (previous != null) {
          expect(current.token, isNot(previous.token));
          c.finishReward(previous.token);
          expect(c.reward.value, same(current));
        }
        await t.pump();
        await t.pump(const Duration(milliseconds: 110));
        expect(peaks.last, count);
        expect(find.text('Комбо x$count'), findsOneWidget);
        previous = current;
      }
      expect(peaks, [2, 3, 4, 5]);
      expect(calls, hasLength(4));
      c.resetStreak();
      await t.pumpAndSettle();
      expect(find.byType(SafeMatchLottie), findsNothing);
      expect(c.reward.value, isNull);
      await t.pumpWidget(const SizedBox());
      c.dispose();
      expect(t.binding.transientCallbackCount, 0);
      expect(t.takeException(), isNull);
    },
  );
  test('New small correct replaces old correct; result cancels all transient events', () {
    final c = MatchFeedbackController();
    c.showCorrect();
    final first = c.reward.value!;
    c.showCorrect();
    final next = c.reward.value!;
    expect(next.token, isNot(first.token));
    c.finishReward(first.token);
    expect(c.reward.value, same(next));
    c.showMilestone(30);
    c.stopTransient();
    expect(c.reward.value, isNull);
    expect(c.milestone.value, isNull);
    c.showMilestone(60);
    c.showVictory();
    final victory = c.reward.value!;
    c.stopTransient();
    expect(c.reward.value, same(victory));
    expect(c.milestone.value, isNull);
    c.dispose();
    expect(() => c.stopTransient(), returnsNormally);
  });
  testWidgets(
    'Milestones use real HUD bounds; Minimal consumes pulses without delayed playback',
    (t) async {
      final c = MatchFeedbackController(assets: await prepared());
      final anchor = GlobalKey();
      Widget show(String motion) => MaterialApp(
        home: LocalMotionScope(
          motion: motion,
          child: Scaffold(
            body: Center(
              child: SizedBox(
                width: 360,
                height: 260,
                child: MatchFeedbackOverlay(
                  controller: c,
                  progressAnchor: anchor,
                  targetMatches: 60,
                  child: Column(
                    children: [SizedBox(key: anchor, width: 300, height: 54)],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await t.pumpWidget(show('full'));
      for (final value in [20, 30, 60]) {
        c.showMilestone(value);
        await t.pump();
        expect(find.byType(SafeMatchLottie), findsOneWidget);
        final origin = t.getTopLeft(find.byKey(anchor));
        final at = t.getCenter(find.byType(SafeMatchLottie));
        expect(at.dx, closeTo(origin.dx + 270 * value / 60 + 15, .01));
        expect(at.dy, closeTo(origin.dy + 15, .01));
        await t.pumpAndSettle();
        expect(c.milestone.value, isNull);
      }
      await t.pumpWidget(show('minimal'));
      c.showMilestone(20);
      await t.pump();
      await t.pump();
      expect(c.milestone.value, isNull);
      expect(find.byType(SafeMatchLottie), findsNothing);
      await t.pumpWidget(show('full'));
      expect(find.byType(SafeMatchLottie), findsNothing);
      await t.pumpWidget(const SizedBox());
      c.dispose();
      expect(t.takeException(), isNull);
    },
  );
  test('Bounded visual events: correct never blocks combo, stale completion and victory priorities', () {
    final c = MatchFeedbackController();
    c.showCorrect();
    final old = c.reward.value!;
    c.showCombo(2, revision: 2);
    final combo = c.reward.value!;
    for (var i = 0; i < 100; i++) {
      c.showCorrect();
    }
    expect(c.reward.value, combo);
    c.showCombo(3, revision: 3);
    expect(c.reward.value!.token, isNot(combo.token));
    expect(c.reward.value!.count, 3);
    c.showCombo(5, revision: 5);
    final next = c.reward.value!;
    c.finishReward(old.token);
    c.finishReward(combo.token);
    expect(c.reward.value, next);
    c.showMilestone(60);
    c.showVictory();
    final victory = c.reward.value;
    c.showCombo(8);
    c.showCorrect();
    c.showMilestone(20);
    c.resetStreak();
    expect(c.reward.value, victory);
    expect(c.milestone.value!.count, 60);
    c.dispose();
    expect(() => c.finishReward(next.token), returnsNormally);
    expect(() => c.showCorrect(), returnsNormally);
  });
  test('Milestone replacement, completed combo epoch and independent victory handoff', () {
    final c = MatchFeedbackController();
    for (final value in [20, 30, 60]) {
      c.showMilestone(value);
      expect(c.milestone.value!.count, value);
    }
    final m = c.milestone.value!;
    c.showMilestone(7);
    expect(c.milestone.value, m);
    c.showCombo(2);
    final old = c.reward.value!..complete();
    c.showCombo(3);
    expect(c.reward.value!.token, isNot(old.token));
    c.finishReward(old.token);
    expect(c.reward.value!.count, 3);
    c.showVictory();
    c.reward.value!.recordElapsed(const Duration(milliseconds: 450));
    final seed = c.takeVictory()!;
    expect(c.reward.value, isNull);
    expect(c.milestone.value, isNull);
    expect(seed.elapsed.inMilliseconds, 450);
    c.dispose();
    expect(seed.kind, MatchDecoration.victory);
  });
  testWidgets(
    'Correct and dynamic combo use ready compositions, pass input and clean up',
    (t) async {
      final assets = await prepared(),
          c = MatchFeedbackController(assets: assets);
      final peaks = <int>[];
      await t.pumpWidget(dock(c, onPeak: peaks.add));
      final size = t.getSize(find.byType(MatchFeedbackReward));
      c.showCorrect(revision: 1);
      await t.pump();
      expect(find.byType(SafeMatchLottie), findsOneWidget);
      expect(find.text('Верно'), findsOneWidget);
      expect(
        t.widget<SafeMatchLottie>(find.byType(SafeMatchLottie)).composition,
        assets.composition(MatchDecoration.correct),
      );
      expect(
        find.ancestor(
          of: find.byType(SafeMatchLottie),
          matching: find.byWidgetPredicate(
            (w) => w is IgnorePointer && w.ignoring,
          ),
        ),
        findsWidgets,
      );
      c.showCombo(2, revision: 2);
      await t.pump();
      await t.pump(const Duration(milliseconds: 110));
      expect(peaks, [2]);
      c.showCombo(3, revision: 3);
      await t.pump();
      expect(find.text('Комбо x3'), findsOneWidget);
      c.showCombo(4, revision: 4);
      await t.pump();
      expect(find.text('Комбо x4'), findsOneWidget);
      c.showCombo(5, revision: 5);
      await t.pump();
      await t.pump(const Duration(milliseconds: 110));
      expect(peaks, [2, 5]);
      expect(t.getSize(find.byType(MatchFeedbackReward)), size);
      await t.pumpAndSettle();
      expect(find.byType(SafeMatchLottie), findsNothing);
      expect(c.reward.value, isNull);
      expect(t.binding.transientCallbackCount, 0);
      expect(t.takeException(), isNull);
      await t.pumpWidget(const SizedBox());
      c.dispose();
    },
  );
  for (final mode in ['full', 'calm', 'minimal', 'reduced']) {
    testWidgets('$mode motion chooses the appropriate renderer', (t) async {
      final assets = await prepared(),
          c = MatchFeedbackController(assets: assets);
      c.showCombo(2, revision: 2);
      await t.pumpWidget(
        dock(
          c,
          motion: mode == 'reduced' ? 'full' : mode,
          reduced: mode == 'reduced',
        ),
      );
      await t.pump(const Duration(milliseconds: 50));
      if (mode == 'minimal' || mode == 'reduced') {
        expect(find.byType(SafeMatchLottie), findsNothing);
        expect(find.byType(LightningFeedback), findsOneWidget);
      } else {
        expect(find.byType(SafeMatchLottie), findsOneWidget);
        expect(
          t.widget<SafeMatchLottie>(find.byType(SafeMatchLottie)).calm,
          mode == 'calm',
        );
      }
      expect(find.text('Комбо x2'), findsOneWidget);
      await t.pumpAndSettle();
      await t.pumpWidget(const SizedBox());
      c.dispose();
      expect(t.takeException(), isNull);
    });
  }
  testWidgets(
    'Minimal rapid captions reuse the original feedback state and one ticker',
    (t) async {
      final c = MatchFeedbackController(assets: await prepared());
      await t.pumpWidget(dock(c, motion: 'minimal'));
      c.showCombo(2, revision: 2);
      await t.pump();
      final state = t.state(find.byType(LightningFeedback));
      await t.pump(const Duration(milliseconds: 70));
      c.showCombo(3, revision: 3);
      await t.pump();
      expect(t.state(find.byType(LightningFeedback)), same(state));
      expect(find.text('Комбо x3'), findsOneWidget);
      expect(t.binding.transientCallbackCount, 1);
      await t.pumpAndSettle();
      expect(c.reward.value, isNull);
      expect(t.binding.transientCallbackCount, 0);
      c.showCorrect(revision: 4);
      await t.pump();
      expect(find.text('Верно'), findsOneWidget);
      await t.pumpAndSettle();
      expect(c.reward.value, isNull);
      await t.pumpWidget(const SizedBox());
      c.dispose();
    },
  );
  testWidgets(
    'Missing/invalid Lottie assets keep the existing lightweight feedback',
    (t) async {
      final assets = MatchFeedbackAssets(
        loader: (p) async => throw const FormatException('broken asset'),
      );
      await assets.preload();
      final c = MatchFeedbackController(assets: assets);
      c.showCombo(3, revision: 3);
      await t.pumpWidget(dock(c));
      expect(find.byType(LightningFeedback), findsOneWidget);
      expect(find.text('Комбо x3'), findsOneWidget);
      expect(find.byType(SafeMatchLottie), findsNothing);
      await t.pumpAndSettle();
      expect(t.takeException(), isNull);
      await t.pumpWidget(const SizedBox());
      c.dispose();
    },
  );
  testWidgets(
    'An exception in the vector draw is contained without a global error hook',
    (t) async {
      final assets = await prepared();
      final a = AnimationController(
        vsync: t,
        duration: const Duration(milliseconds: 433),
      );
      var failures = 0;
      await t.pumpWidget(
        MaterialApp(
          home: SizedBox(
            width: 64,
            height: 64,
            child: SafeMatchLottie(
              composition: assets.composition(MatchDecoration.correct)!,
              animation: a,
              draw: (drawable, canvas, rect) {
                throw StateError('render failure');
              },
              onFailure: () => failures++,
            ),
          ),
        ),
      );
      await t.pump();
      expect(failures, 1);
      expect(t.takeException(), isNull);
      a.forward();
      await t.pump(const Duration(milliseconds: 100));
      expect(failures, 1);
      await t.pumpWidget(const SizedBox());
      a.dispose();
      expect(t.binding.transientCallbackCount, 0);
    },
  );
  testWidgets(
    'Pause/resume freezes reward playback; disposal removes active tickers',
    (t) async {
      final c = MatchFeedbackController(assets: await prepared());
      c.showCombo(2, revision: 2);
      await t.pumpWidget(dock(c));
      await t.pump(const Duration(milliseconds: 150));
      final a = t
          .widget<SafeMatchLottie>(find.byType(SafeMatchLottie))
          .animation;
      final before = a.value;
      t.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      await t.pump(const Duration(seconds: 2));
      expect(a.value, before);
      t.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await t.pump();
      await t.pump(const Duration(milliseconds: 50));
      expect(a.value, greaterThan(before));
      expect(a.value, lessThan(1));
      await t.pumpWidget(const SizedBox());
      c.dispose();
      await t.pump(const Duration(seconds: 2));
      expect(t.binding.transientCallbackCount, 0);
      expect(t.takeException(), isNull);
    },
  );
  testWidgets('Victory continues from its handoff position then disappears', (
    t,
  ) async {
    final assets = await prepared();
    final c = MatchFeedbackController(assets: assets);
    c.showVictory();
    c.reward.value!.recordElapsed(const Duration(milliseconds: 450));
    final seed = c.takeVictory()!;
    c.dispose();
    await t.pumpWidget(
      MaterialApp(
        home: SizedBox(
          width: 112,
          height: 112,
          child: MatchVictoryFeedback(event: seed, assets: assets),
        ),
      ),
    );
    final a = t.widget<SafeMatchLottie>(find.byType(SafeMatchLottie)).animation;
    expect(a.value, closeTo(.5, .01));
    await t.pumpAndSettle();
    expect(find.byType(SafeMatchLottie), findsNothing);
    expect(t.binding.transientCallbackCount, 0);
    expect(t.takeException(), isNull);
  });
  for (final motion in ['full', 'minimal']) {
    testWidgets(
      'Real Match accepts rapid taps in $motion and retains result navigation',
      (t) async {
        await t.runAsync(() => MatchFeedbackAssets.shared.preload());
        final data = TrainerData(store: MemoryTrainerStore());
        await data.load();
        await data.saveSettings(data.settings.withValue('motion', motion));
        final g = MatchingEngine.start(
          words: testWords,
          random: Random(42),
          config: SessionConfig(
            visiblePairs: 5,
            wordPoolSize: 20,
            targetMatches: 2,
            maxMistakes: 0,
            mode: SessionMode.practice,
          ),
        );
        await t.pumpWidget(
          TrainerScope(
            data: data,
            child: MaterialApp(
              theme: AppTheme.dark,
              home: TrainingGameScreen(game: g),
            ),
          ),
        );
        await t.pumpAndSettle();
        for (var i = 0; i < 2; i++) {
          final a = g.leftCards.whereType<MatchingCard>().firstWhere(
            (c) => g.isActive(c.id),
          );
          final b = g.cards.singleWhere(
            (c) => c.pairId == a.pairId && c.id != a.id,
          );
          await t.tap(find.byKey(ValueKey(a.id)));
          await t.pump();
          await t.tap(find.byKey(ValueKey(b.id)));
          await t.pump();
          expect(g.matchedCount, i + 1);
          if (motion == 'full') {
            expect(find.byType(SafeMatchLottie), findsWidgets);
          } else {
            expect(find.byType(SafeMatchLottie), findsNothing);
            expect(find.byType(LightningFeedback), findsOneWidget);
          }
        }
        await t.pumpAndSettle();
        expect(find.byType(TrainingResultScreen), findsOneWidget);
        expect(t.takeException(), isNull);
        await t.pumpWidget(const SizedBox());
        await data.flush();
        data.dispose();
      },
    );
  }
}
