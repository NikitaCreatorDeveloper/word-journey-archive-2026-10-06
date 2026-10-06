import 'package:flutter/material.dart';

import '../features/progress/trainer_data.dart';

/// A Match snapshots only the motion preference, so journal notifications never
/// invalidate cards, HUD or effects. Other screens keep the existing scope.
class LocalMotionScope extends InheritedWidget {
  const LocalMotionScope({
    super.key,
    required this.motion,
    required super.child,
  });
  final String motion;
  @override
  bool updateShouldNotify(LocalMotionScope old) => old.motion != motion;
}

String motionOf(BuildContext context) => MediaQuery.disableAnimationsOf(context)
    ? 'minimal'
    : context.dependOnInheritedWidgetOfExactType<LocalMotionScope>()?.motion ??
          TrainerScope.maybeOf(context)?.settings.motion ??
          'full';
Duration motionDuration(
  BuildContext context,
  Duration full, {
  int calmMs = 120,
}) => switch (motionOf(context)) {
  'minimal' => const Duration(milliseconds: 1),
  'calm' => Duration(milliseconds: calmMs),
  _ => full,
};
