import 'package:flutter/material.dart';

import '../features/profile/cefr_profile.dart';
import '../features/profile/level_selector_screen.dart';
import 'app_shell.dart';
import 'app_theme.dart';
import '../features/progress/trainer_data.dart';
import '../features/settings/audio_feedback_service.dart';
import '../features/vocabulary/vocabulary_repository.dart';

class WordJourneyApp extends StatefulWidget {
  const WordJourneyApp({super.key, this.profile});
  final CefrProfile? profile;
  @override
  State<WordJourneyApp> createState() => _WordJourneyAppState();
}

class _WordJourneyAppState extends State<WordJourneyApp>
    with WidgetsBindingObserver {
  late final CefrProfile _profile =
      widget.profile ?? CefrProfile(TrainerLevelStore(_data));
  late final TrainerData _data = TrainerData();
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _load();
    AudioFeedbackService.shared.preload();
  }

  Future<void> _load() async {
    await _data.load();
    try {
      await VocabularyRepository.load();
      await _data.reconcileAchievements();
    } catch (_) {
      /* The catalog screen exposes its loading error. */
    }
    if (!_profile.loaded) await _profile.load();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    if (widget.profile == null) _profile.dispose();
    _data.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _data.refreshTime();
  }

  @override
  Widget build(BuildContext context) => TrainerScope(
    data: _data,
    child: ProfileScope(
      profile: _profile,
      child: AnimatedBuilder(
        animation: _data,
        builder: (context, _) => MaterialApp(
          title: 'Word Journey',
          debugShowCheckedModeBanner: false,
          themeMode: switch (_data.settings.values['theme']) {
            'light' => ThemeMode.light,
            'dark' => ThemeMode.dark,
            _ => ThemeMode.system,
          },
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          builder: (context, child) {
            final media = MediaQuery.of(context);
            return MediaQuery(
              data: media.copyWith(
                textScaler: media.textScaler.clamp(
                  minScaleFactor: _data.settings.values['largeText'] == true
                      ? 1.2
                      : 1.0,
                ),
              ),
              child: child!,
            );
          },
          home: AnimatedBuilder(
            animation: _profile,
            builder: (context, _) {
              if (!_profile.loaded) {
                return Scaffold(
                  body: SafeArea(
                    child: Center(
                      child: _profile.error == null
                          ? const CircularProgressIndicator()
                          : Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  _profile.error!,
                                  textAlign: TextAlign.center,
                                ),
                                TextButton(
                                  onPressed: _profile.load,
                                  child: const Text('Повторить'),
                                ),
                              ],
                            ),
                    ),
                  ),
                );
              }
              return _profile.level == null
                  ? const LevelSelectorScreen()
                  : const AppShell();
            },
          ),
        ),
      ),
    ),
  );
}
