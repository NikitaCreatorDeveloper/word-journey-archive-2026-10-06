import 'dart:async';

import 'package:flutter/services.dart';

import 'trainer_settings.dart';

typedef FeedbackInvoke = Future<void> Function(
  String method,
  Map<String, dynamic>? args,
);

class AudioFeedbackService {
  AudioFeedbackService({FeedbackInvoke? invoke}) : _invoke = invoke ?? _native;
  final FeedbackInvoke _invoke;
  static Future<void> _native(String method, Map<String, dynamic>? args) async {
    await const MethodChannel('com.wordjourney.app/personal')
        .invokeMethod<dynamic>(method, args);
  }

  static final shared = AudioFeedbackService();
  bool _preloaded = false;
  String? _lastSound;
  int _lastAt = 0;
  final Stopwatch _clock = Stopwatch()..start();
  void _send(String method, [Map<String, dynamic>? args]) {
    unawaited(_invoke(method, args).catchError((Object _) {}));
  }

  void preload() {
    if (_preloaded) return;
    _preloaded = true;
    _send('preloadSounds');
  }

  void stop() => _send('stopSounds');
  void feedback(String name, TrainerSettings settings) {
    if (settings.haptics && name != 'select') {
      unawaited(
        (name == 'wrong'
                ? HapticFeedback.lightImpact()
                : HapticFeedback.selectionClick())
            .catchError((Object _) {}),
      );
    }
    if (!settings.sounds || settings.volume <= 0) return;
    final now = _clock.elapsedMilliseconds;
    if (_lastSound == name && now - _lastAt < (name == 'select' ? 45 : 65)) {
      return;
    }
    _lastAt = now;
    _lastSound = name;
    _send('playSound', {'name': name, 'volume': settings.volume});
  }
}
