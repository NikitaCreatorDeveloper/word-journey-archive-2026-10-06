import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'cefr_level.dart';

abstract interface class LevelStore {
  Future<CefrLevel?> read();
  Future<void> write(CefrLevel level);
}

class PreferencesLevelStore implements LevelStore {
  static const key = 'word_journey.cefr_level';
  @override
  Future<CefrLevel?> read() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.reload();
    return CefrLevel.fromId(prefs.getString(key));
  }

  @override
  Future<void> write(CefrLevel level) async {
    final prefs = await SharedPreferences.getInstance();
    if (!await prefs.setString(key, level.id)) {
      throw StateError('CEFR preference was not saved');
    }
  }
}

class CefrProfile extends ChangeNotifier {
  CefrProfile(this.store);
  final LevelStore store;
  CefrLevel? level;
  bool loaded = false;
  bool saving = false;
  String? error;
  bool _disposed = false;
  void _changed() {
    if (!_disposed) notifyListeners();
  }

  Future<void> load() async {
    error = null;
    try {
      level = await store.read();
      loaded = true;
    } catch (_) {
      error = 'Не удалось загрузить уровень. Попробуйте ещё раз.';
    }
    _changed();
  }

  Future<bool> choose(CefrLevel value) async {
    if (saving) return false;
    saving = true;
    error = null;
    _changed();
    try {
      await store.write(value);
      level = value;
      loaded = true;
      return true;
    } catch (_) {
      error = 'Не удалось сохранить уровень. Попробуйте ещё раз.';
      return false;
    } finally {
      saving = false;
      _changed();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}

class ProfileScope extends InheritedNotifier<CefrProfile> {
  const ProfileScope({
    super.key,
    required CefrProfile profile,
    required super.child,
  }) : super(notifier: profile);
  static CefrProfile? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<ProfileScope>()?.notifier;
  static CefrProfile of(BuildContext context) => maybeOf(context)!;
  static CefrLevel levelOf(BuildContext context) =>
      maybeOf(context)?.level ?? CefrLevel.a1;
}
