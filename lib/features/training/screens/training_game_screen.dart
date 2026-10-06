import '../../../app/match_profile_controls.dart';

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../app/app_theme.dart';
import '../../../app/motion_preferences.dart';
import '../../settings/audio_feedback_service.dart';
import '../widgets/lightning_feedback.dart';
import '../widgets/match_feedback_overlay.dart';
import '../logic/matching_engine.dart';
import '../logic/session_clock.dart';
import '../logic/training_session.dart';
import '../model/session_result.dart';
import '../widgets/training_board.dart';
import '../widgets/match_flow_tile.dart';
import '../widgets/training_progress_header.dart';
import 'training_result_screen.dart';
import '../../progress/trainer_data.dart';
import '../../progress/session_journal.dart';

class TrainingGameScreen extends StatefulWidget {
  const TrainingGameScreen({
    super.key,
    required this.game,
    this.clock,
    this.packId,
  });
  final MatchingEngine game;
  final SessionClock? clock;
  final String? packId;
  @override
  State<TrainingGameScreen> createState() => _TrainingGameScreenState();
}

class _TrainingGameScreenState extends State<TrainingGameScreen>
    with WidgetsBindingObserver, SingleTickerProviderStateMixin {
  final Map<String, int> _errors = {};
  int _errorRevision = 0;
  bool _showingResult = false;
  bool _finishing = false;
  bool _allowExit = false;
  bool _confirmingExit = false;
  bool _foreground = true;
  bool get _paused => !_foreground || _confirmingExit;
  late final TrainingSession _session;
  Timer? _pulse;
  int? _shownSeconds;
  final _boardChanges = ValueNotifier<int>(0);
  final _refillPaused = ValueNotifier<bool>(false);
  final _progress = ValueNotifier<double>(0);
  final _seconds = ValueNotifier<int?>(null);
  final _reward = ValueNotifier<(int, int)>((0, 0));
  final _feedback = MatchFeedbackController();
  final _progressAnchor = GlobalKey();
  TrainerData? _data;
  String _motion = 'full';
  bool get _lottieFeedback =>
      matchLottieEnabled(context) &&
      _motion != 'minimal' &&
      !MediaQuery.disableAnimationsOf(context);
  String? _saveError;
  void _ensureJournal() {
    if (_journal == null && _data?.loaded == true) {
      _journal = SessionJournal(_data!, widget.game, packId: widget.packId);
      if (!_paused) _journal!.exposeBoard();
    }
  }

  void _preferencesChanged() {
    _ensureJournal();
    final motion = _data?.settings.motion ?? 'full', error = _data?.error;
    if (mounted && (_motion != motion || _saveError != error)) {
      setState(() {
        _motion = motion;
        _saveError = error;
      });
    }
  }

  void _boardChanged() {
    _boardChanges.value++;
    // Newly published words count as seen only when the learner can see them.
    if (!_paused) _journal?.exposeBoard();
  }

  SessionJournal? _journal;
  int _combo = 0, _sparkRevision = 0;
  int? _rewardRevision;
  double? _measuredWidth, _measuredScale, _measuredHeight;
  double _labelHeight(double width) {
    final scaler = MediaQuery.textScalerOf(context);
    if (_measuredWidth == width && _measuredScale == scaler.scale(20)) {
      return _measuredHeight!;
    }
    var height = MatchFlowTile.minHeight;
    for (final w in widget.game.wordPool) {
      for (final label in [w.english, w.russian]) {
        final text =
            TextPainter(
              text: TextSpan(
                text: label,
                style: Theme.of(context).textTheme.bodyMedium
                    ?.merge(MatchFlowTile.wordStyle),
              ),
              textDirection: TextDirection.ltr,
              textScaler: scaler,
            )..layout(
              maxWidth: math.max(
                1,
                (width - AppTokens.boardGap) / 2 -
                    2 * AppTokens.cardHorizontalPadding,
              ),
            );
        height = math.max(height, text.height.ceilToDouble() + 24);
        text.dispose();
      }
    }
    _measuredWidth = width;
    _measuredScale = scaler.scale(20);
    _measuredHeight = height;
    return height;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final data = context
        .getInheritedWidgetOfExactType<TrainerScope>()
        ?.notifier;
    if (data != _data) {
      _data?.removeListener(_preferencesChanged);
      _data = data;
      _motion = data?.settings.motion ?? 'full';
      _saveError = data?.error;
      data?.addListener(_preferencesChanged);
    }
    _ensureJournal();
  }

  late final AnimationController _finish =
      AnimationController(
        vsync: this,
        duration: AppTokens.sessionFinishDuration,
      )..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          _showResult();
        }
      });

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _foreground =
        WidgetsBinding.instance.lifecycleState == null ||
        WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed;
    _refillPaused.value = _paused;
    _session = TrainingSession(widget.game, clock: widget.clock);
    widget.game.enableMatchFlow();
    widget.game.matchFlow!.setPaused(_paused);
    _progress.value = widget.game.progress;
    if (_foreground) _session.resume();
    if (widget.game.config.isTimed) {
      _shownSeconds = _session.clock.remainingSeconds;
      _seconds.value = _shownSeconds;
      _pulse = Timer.periodic(
        AppTokens.clockRefreshInterval,
        (_) => _syncClock(),
      );
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    if (!_foreground) AudioFeedbackService.shared.stop();
    _updateClockActivity();
    if (mounted) {
      setState(() {});
    }
  }

  void _updateClockActivity() {
    // Freeze refill synchronously with the lifecycle event, before the next
    // frame can rebuild a muted board or fire an already armed timer.
    _refillPaused.value = _paused;
    if (_paused && _finishing) {
      _finish.stop(canceled: false);
    }
    if (!_paused && _finishing) {
      if (_finish.isCompleted) {
        _showResult();
      } else {
        _finish.forward();
      }
    }
    if (_paused || _finishing) {
      _session.pause();
    } else {
      _session.resume();
      _journal?.exposeBoard();
    }
    if (!_paused) {
      _syncClock();
    }
  }

  void _syncClock() {
    if (!mounted || _showingResult || _paused) {
      return;
    }
    _session.tick();
    final remaining = widget.game.config.isTimed
        ? _session.clock.remainingSeconds
        : null;
    if (_shownSeconds != remaining) {
      _shownSeconds = remaining;
      _seconds.value = remaining;
    }
    _tryFinish();
  }

  void _tryFinish() {
    _session.tick();
    if (!mounted || _paused || _finishing || _session.result == null) {
      return;
    }
    _finishing = true;
    if (_session.result!.targetReached && !_lottieFeedback) {
      MatchProfileCounters.feedback('victory', 900);
    }
    if (_session.result!.targetReached && _lottieFeedback) {
      _feedback.showVictory(count: widget.game.matchedCount);
    }
    final settings = _data?.settings;
    if (settings != null) {
      AudioFeedbackService.shared.feedback('finish', settings);
    }
    _finish.duration =
        MediaQuery.disableAnimationsOf(context) || _motion == 'minimal'
        ? const Duration(milliseconds: 1)
        : _motion == 'calm'
        ? const Duration(milliseconds: 300)
        : AppTokens.sessionFinishDuration;
    if (_session.result!.targetReached) {
      MatchProfileCounters.feedback(
        'victory-dock',
        _finish.duration!.inMilliseconds,
      );
    }
    _journal?.finish(_session.result!);
    _session.pause();
    // Retain a brief victory dock; board input never waits for decoration.
    _finish.forward(from: 0);
    setState(() {});
  }

  Future<void> _requestExit() async {
    _syncClock();
    if (_confirmingExit ||
        _showingResult ||
        _finishing ||
        _session.result != null) {
      return;
    }
    // Freeze at the dialog boundary too: the deadline may pass after _syncClock.
    _session.pause();
    if (_session.result != null) {
      _tryFinish();
      return;
    }
    _confirmingExit = true;
    _updateClockActivity();
    setState(() {});
    final leave = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Выйти из тренировки?'),
        content: const Text(
          'Учтём выполненные ответы. Незаконченный раунд не считается победой.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Продолжить'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Выйти'),
          ),
        ],
      ),
    );
    if (!mounted) {
      return;
    }
    _confirmingExit = false;
    if (leave == true) {
      _session.endSession(SessionEndReason.userExited);
      await _journal?.finish(_session.result!);
      if (!mounted) return;
      _allowExit = true;
      Navigator.of(context).pop();
    } else {
      _updateClockActivity();
      setState(() {});
    }
  }

  void _select(String cardId) {
    final profileStart = MatchProfileCounters.tapStart();
    _syncClock(); // A tap between UI ticks must still respect the real deadline.
    final game = widget.game;
    if (_paused || _finishing || _showingResult || !game.isActive(cardId)) {
      return;
    }
    final firstId = game.selectedCardId;
    final feedback = _session.select(cardId);

    if (feedback == MatchFeedback.incorrect) {
      _combo = 0;
      _rewardRevision = null;
      final revision = ++_errorRevision;
      _errors[firstId!] = revision;
      _errors[cardId] = revision;
    } else if (feedback == MatchFeedback.correct) {
      _combo++;
      _sparkRevision++;
      _rewardRevision =
          [2, 5, 10, 20].contains(_combo) &&
              ![20, 30, 60].contains(game.matchedCount)
          ? _sparkRevision
          : null;
      _errors.remove(firstId);
      _errors.remove(cardId);
    }
    MatchProfileCounters.accepted(
      profileStart,
      visualCards: [cardId, ?firstId],
    );
    _boardChanges.value++;
    _progress.value = game.progress;
    _reward.value = (_sparkRevision, _combo);
    if (feedback != null && firstId != null) {
      _journal?.answer(feedback, firstId, cardId, _session.clock.elapsed);
    } else if (game.selectedCardId != null) {
      _journal?.firstTap = _session.clock.elapsed;
    } else {
      _journal?.firstTap = null;
    }
    if (feedback == MatchFeedback.correct &&
        [20, 30, 60].contains(game.matchedCount)) {
      MatchProfileCounters.feedback('milestone', 450);
    }
    if (_lottieFeedback && MatchProfileScope.of(context).lightning) {
      if (feedback == MatchFeedback.incorrect) {
        _feedback.resetStreak();
      } else if (feedback == MatchFeedback.correct) {
        _feedback.showCorrect(revision: _sparkRevision);
        if (_combo >= 2) _feedback.showCombo(_combo, revision: _sparkRevision);
        _feedback.showMilestone(game.matchedCount);
      }
    }
    final settings = _data?.settings;
    // The final milestone uses the immediate finish feedback in _tryFinish.
    if (settings != null &&
        !(feedback == MatchFeedback.correct && game.isComplete)) {
      final sound = feedback == MatchFeedback.incorrect
          ? 'wrong'
          : feedback == MatchFeedback.correct
          ? ([20, 30].contains(game.matchedCount) ? 'milestone' : 'correct')
          : 'select';
      AudioFeedbackService.shared.feedback(sound, settings);
    }
    _tryFinish();
  }

  void _onComboPeak(int revision) {
    if (!mounted ||
        _paused ||
        _finishing ||
        _showingResult ||
        _rewardRevision != revision ||
        revision != _sparkRevision) {
      return;
    }
    _rewardRevision = null;
    final settings = _data?.settings;
    if (settings != null) {
      AudioFeedbackService.shared.feedback('combo', settings);
    }
  }

  void _showResult() {
    if (!mounted ||
        _paused ||
        _showingResult ||
        ModalRoute.of(context)?.isCurrent != true) {
      return;
    }
    _showingResult = true;
    if (_session.result!.targetReached) {
      MatchProfileCounters.feedback(
        'victory-result',
        math.max(0, 900 - _finish.duration!.inMilliseconds),
      );
    }
    final victory = _lottieFeedback ? _feedback.takeVictory() : null;
    _feedback.stopTransient();
    _reward.value = (0, 0);
    _pulse?.cancel();
    final completed = widget.game;
    // Full-screen alpha blending exceeded the 120 Hz raster budget on POCO.
    // The local victory continues independently; navigation publishes Result
    // immediately after the existing finish dock, without a screen-sized layer.
    const resultTransition = Duration.zero;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder<void>(
        transitionDuration: resultTransition,
        reverseTransitionDuration: resultTransition,
        pageBuilder: (resultContext, animation, secondaryAnimation) =>
            TrainingResultScreen(
              victoryFeedback: victory == null
                  ? null
                  : MatchVictoryFeedback(event: victory),
              result: _session.result!,
              journal: _journal,
              onPlayAgain: () {
                final next = completed.replay();
                Navigator.of(resultContext).pushReplacement(
                  MaterialPageRoute<void>(
                    builder: (_) =>
                        TrainingGameScreen(game: next, packId: widget.packId),
                  ),
                );
              },
              onBackToSetup: () => Navigator.of(resultContext).pop(),
            ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) =>
            child,
      ),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pulse?.cancel();
    _session.pause();
    AudioFeedbackService.shared.stop();
    widget.game.disposeMatchFlow();
    _finish.dispose();
    _data?.removeListener(_preferencesChanged);
    _boardChanges.dispose();
    _refillPaused.dispose();
    _progress.dispose();
    _seconds.dispose();
    _reward.dispose();
    _feedback.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    MatchProfileCounters.hit('game.build');
    final saveError = _saveError;
    final game = widget.game;
    final theme = AppTheme.dark;
    final scrollReward =
        MediaQuery.sizeOf(context).height < 600 ||
        MediaQuery.textScalerOf(context).scale(16) > 24;
    Widget reward() => TickerMode(
      enabled: !_paused,
      child: Align(
        alignment: Alignment.centerRight,
        child: _lottieFeedback
            ? MatchFeedbackReward(
                controller: _feedback,
                onComboPeak: _onComboPeak,
                compact: MediaQuery.sizeOf(context).height < 440,
              )
            : ValueListenableBuilder<(int, int)>(
                valueListenable: _reward,
                builder: (context, value, _) => LightningFeedback(
                  revision: MatchProfileScope.of(context).lightning
                      ? value.$1
                      : 0,
                  combo: MatchProfileScope.of(context).lightning ? value.$2 : 0,
                  onPeak: _onComboPeak,
                  compact: MediaQuery.sizeOf(context).height < 440,
                ),
              ),
      ),
    );
    return LocalMotionScope(
      motion: _motion,
      child: PopScope(
        canPop: _allowExit,
        onPopInvokedWithResult: (didPop, result) {
          if (!didPop) {
            _requestExit();
          }
        },
        child: AnnotatedRegion<SystemUiOverlayStyle>(
          value: SystemUiOverlayStyle.light,
          child: Theme(
            data: AppTheme.dark,
            child: Scaffold(
              backgroundColor: MatchFlowTile.background,
              body: ColoredBox(
                color: MatchFlowTile.background,
                child: SafeArea(
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(
                        maxWidth: MatchFlowTile.boardWidth,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(14, 8, 14, 16),
                        child: TickerMode(
                          enabled: !_paused,
                          child: MatchFeedbackOverlay(
                            controller: _feedback,
                            progressAnchor: _progressAnchor,
                            targetMatches: game.totalPairCount,
                            child: Column(
                              children: [
                                RepaintBoundary(
                                  child: TrainingProgressHeader(
                                    progressAnchor: _progressAnchor,
                                    progress: game.progress,
                                    acceptedProgress: _progress,
                                    targetMatches: game.totalPairCount,
                                    seconds: _shownSeconds,
                                    clock: _seconds,
                                    onExit: _requestExit,
                                    onSettled: _tryFinish,
                                  ),
                                ),
                                const SizedBox(height: AppTokens.spaceLg),
                                if (saveError != null)
                                  Wrap(
                                    alignment: WrapAlignment.center,
                                    children: [
                                      Text(
                                        'Есть несохранённые ответы',
                                        style: TextStyle(
                                          color: theme.colorScheme.error,
                                        ),
                                      ),
                                      TextButton(
                                        onPressed: () => _journal?.retry(),
                                        child: const Text(
                                          'Повторить сохранение',
                                        ),
                                      ),
                                    ],
                                  ),
                                Expanded(
                                  child: Stack(
                                    children: [
                                      TickerMode(
                                        enabled: !_paused,
                                        child: AbsorbPointer(
                                          absorbing: _paused || _finishing,
                                          child: LayoutBuilder(
                                            builder: (context, constraints) {
                                              final fitHeight =
                                                  (constraints.maxHeight -
                                                      (game.visiblePairCount -
                                                              1) *
                                                          AppTokens.boardGap) /
                                                  game.visiblePairCount;
                                              final height = math.max(
                                                fitHeight.clamp(
                                                  MatchFlowTile.minHeight,
                                                  MatchFlowTile.maxHeight,
                                                ),
                                                _labelHeight(
                                                  constraints.maxWidth,
                                                ),
                                              );
                                              return Center(
                                                child: SingleChildScrollView(
                                                  clipBehavior: Clip.none,
                                                  child: Column(
                                                    mainAxisSize:
                                                        MainAxisSize.min,
                                                    children: [
                                                      TrainingBoard(
                                                        pause: _refillPaused,
                                                        key: ObjectKey(game),
                                                        game: game,

                                                        cardHeight: height,
                                                        errors: _errors,
                                                        onSelect: _select,
                                                        changes: _boardChanges,
                                                        onBoardChanged:
                                                            _boardChanged,
                                                      ),
                                                      if (scrollReward)
                                                        reward(),
                                                    ],
                                                  ),
                                                ),
                                              );
                                            },
                                          ),
                                        ),
                                      ),
                                      if (_paused)
                                        Positioned.fill(
                                          child: ColoredBox(
                                            color: theme.colorScheme.surface
                                                .withValues(
                                                  alpha: AppTokens.pauseOpacity,
                                                ),
                                            child: Center(
                                              child: Text(
                                                'Пауза',
                                                style:
                                                    theme.textTheme.titleLarge,
                                              ),
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                                if (!scrollReward) reward(),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
