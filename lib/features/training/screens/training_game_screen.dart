import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../app/app_theme.dart';
import '../logic/matching_engine.dart';
import '../logic/session_clock.dart';
import '../widgets/training_board.dart';
import '../widgets/training_progress_header.dart';
import 'training_result_screen.dart';

class TrainingGameScreen extends StatefulWidget {
  const TrainingGameScreen({super.key, required this.game, this.clock});
  final MatchingEngine game;
  final SessionClock? clock;
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
  SessionClock? _clock;
  Timer? _pulse;
  int? _shownSeconds;
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
    if (widget.game.config.isTimed) {
      _clock =
          widget.clock ??
          SessionClock(limitSeconds: widget.game.config.timeLimitSeconds!);
      if (_foreground) {
        _clock!.resume();
      }
      _shownSeconds = _clock!.remainingSeconds;
      _pulse = Timer.periodic(
        AppTokens.clockRefreshInterval,
        (_) => _syncClock(),
      );
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    _updateClockActivity();
    if (mounted) {
      setState(() {});
    }
  }

  void _updateClockActivity() {
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
      _clock?.pause();
    } else {
      _clock?.resume();
    }
    if (!_paused) {
      _syncClock();
    }
  }

  void _syncClock() {
    if (!mounted || _showingResult || _paused) {
      return;
    }
    if (_clock?.isExpired == true) {
      widget.game.expireTimeLimit();
    }
    final remaining = _clock?.remainingSeconds;
    if (_shownSeconds != remaining) {
      setState(() => _shownSeconds = remaining);
    }
    _tryFinish();
  }

  void _tryFinish() {
    if (!mounted || _paused || _finishing || !widget.game.isComplete) {
      return;
    }
    _finishing = true;
    _clock?.pause();
    // Let any local exit / gap / entry already in flight settle before results.
    _finish.forward(from: 0);
    setState(() {});
  }

  Future<void> _requestExit() async {
    if (_confirmingExit || _showingResult) {
      return;
    }
    _confirmingExit = true;
    _updateClockActivity();
    setState(() {});
    final leave = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Выйти из тренировки?'),
        content: const Text('Текущий результат не сохранится.'),
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
      _allowExit = true;
      Navigator.of(context).pop();
    } else {
      _updateClockActivity();
      setState(() {});
    }
  }

  void _select(String cardId) {
    _syncClock(); // A tap between UI ticks must still respect the real deadline.
    final game = widget.game;
    if (_paused || _finishing || _showingResult || !game.isActive(cardId)) {
      return;
    }
    final firstId = game.selectedCardId;
    final feedback = game.select(cardId);
    setState(() {
      if (feedback == MatchFeedback.incorrect) {
        final revision = ++_errorRevision;
        _errors[firstId!] = revision;
        _errors[cardId] = revision;
      } else if (feedback == MatchFeedback.correct) {
        _errors.remove(firstId);
        _errors.remove(cardId);
      }
    });
    _tryFinish();
  }

  void _showResult() {
    if (!mounted ||
        _paused ||
        _showingResult ||
        ModalRoute.of(context)?.isCurrent != true) {
      return;
    }
    _showingResult = true;
    _pulse?.cancel();
    final completed = widget.game;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder<void>(
        transitionDuration: AppTokens.feedbackDuration,
        reverseTransitionDuration: AppTokens.feedbackDuration,
        pageBuilder: (resultContext, animation, secondaryAnimation) =>
            TrainingResultScreen(
              pairCount: completed.matchedCount,
              errorCount: completed.errorCount,
              timedOut: completed.state.timedOut,
              onPlayAgain: () {
                final next = completed.replay();
                Navigator.of(resultContext).pushReplacement(
                  MaterialPageRoute<void>(
                    builder: (_) => TrainingGameScreen(game: next),
                  ),
                );
              },
              onBackToSetup: () => Navigator.of(resultContext).pop(),
            ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) =>
            FadeTransition(opacity: animation, child: child),
      ),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pulse?.cancel();
    _clock?.pause();
    _finish.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final game = widget.game;
    final theme = Theme.of(context);
    final atlas = AtlasColors.of(context);
    return PopScope(
      canPop: _allowExit,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          _requestExit();
        }
      },
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: theme.brightness == Brightness.dark
            ? SystemUiOverlayStyle.light
            : SystemUiOverlayStyle.dark,
        child: Scaffold(
          body: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [theme.colorScheme.surface, atlas.backgroundEnd],
              ),
            ),
            child: SafeArea(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: AppTokens.boardMaxWidth,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(AppTokens.spaceLg),
                    child: Column(
                      children: [
                        TrainingProgressHeader(
                          progress: game.progress,
                          seconds: _shownSeconds,
                          onExit: _requestExit,
                          onSettled: _tryFinish,
                        ),
                        const SizedBox(height: AppTokens.spaceLg),
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
                                              (game.visiblePairCount - 1) *
                                                  AppTokens.boardGap) /
                                          game.visiblePairCount;
                                      final upperHeight = math.min(
                                        AppTokens.cardMaxHeight,
                                        AppTokens.boardContentHeight /
                                            game.visiblePairCount,
                                      );
                                      final height = math.max(
                                        fitHeight.clamp(
                                          AppTokens.cardMinHeight,
                                          upperHeight,
                                        ),
                                        MediaQuery.textScalerOf(context)
                                                    .scale(AppTokens.wordSize) *
                                                AppTokens.wordLineHeight +
                                            AppTokens.cardVerticalPadding * 2,
                                      );
                                      return Center(
                                        child: SingleChildScrollView(
                                          clipBehavior: Clip.none,
                                          child: TrainingBoard(
                                            key: ObjectKey(game),
                                            game: game,
                                            cardHeight: height,
                                            errors: _errors,
                                            onSelect: _select,
                                            onBoardChanged: () {
                                              if (mounted) {
                                                setState(() {});
                                              }
                                            },
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
                                    color: theme.colorScheme.surface.withValues(
                                      alpha: AppTokens.pauseOpacity,
                                    ),
                                    child: Center(
                                      child: Text(
                                        'Пауза',
                                        style: theme.textTheme.titleLarge,
                                      ),
                                    ),
                                  ),
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
          ),
        ),
      ),
    );
  }
}
