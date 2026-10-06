import 'dart:developer' as dev;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

// All diagnostic switches and counters compile away in ordinary builds.
const matchProfileEnabled = bool.fromEnvironment('MATCH_PROFILE_CONTROLS');

class MatchProfileOptions {
  const MatchProfileOptions({
    this.lightning = true,
    this.cardDecoration = true,
    this.particles = true,
    this.background = true,
    this.cardScale = true,
    this.lottie = true,
  });
  final bool lightning,
      cardDecoration,
      particles,
      background,
      cardScale,
      lottie;
}

class MatchProfileScope extends InheritedWidget {
  const MatchProfileScope({
    super.key,
    required this.options,
    required super.child,
  });
  final MatchProfileOptions options;
  static MatchProfileOptions of(BuildContext context) => !matchProfileEnabled
      ? const MatchProfileOptions()
      : context
                .dependOnInheritedWidgetOfExactType<MatchProfileScope>()
                ?.options ??
            const MatchProfileOptions();
  @override
  bool updateShouldNotify(MatchProfileScope old) => old.options != options;
}

class MatchProfileCounters {
  static final counts = <String, int>{};
  static final stateLatency = <int>[], frameLatency = <int>[];
  static final firstVisualLatency = <int>[];
  static final _pendingVisual = <String, (int, int)>{};
  static int _event = 0, _generation = 0;
  static final feedbackWindows = <(String, int, int)>[];
  static void feedback(String kind, int durationMs) {
    if (matchProfileEnabled) {
      feedbackWindows.add((kind, dev.Timeline.now, durationMs * 1000));
    }
  }

  static void hit(String name) {
    if (matchProfileEnabled) {
      counts.update(name, (n) => n + 1, ifAbsent: () => 1);
    }
  }

  static int tapStart() => matchProfileEnabled ? dev.Timeline.now : 0;
  static void accepted(int start, {Iterable<String> visualCards = const []}) {
    if (!matchProfileEnabled) return;
    stateLatency.add(dev.Timeline.now - start);
    final event = ++_event, generation = _generation;
    for (final id in visualCards) {
      _pendingVisual[id] = (event, start);
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (generation == _generation) frameLatency.add(dev.Timeline.now - start);
    });
  }

  // Called only after a visible color/error change, not the tween's initial
  // unchanged frame. Post-frame measures submission on the physical device;
  // touch dispatch and display scanout are outside this callback measurement.
  static void visualResponse(String id) {
    if (!matchProfileEnabled) return;
    final pending = _pendingVisual[id];
    if (pending == null) return;
    final generation = _generation;
    _pendingVisual.removeWhere((_, value) => value.$1 == pending.$1);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (generation == _generation) {
        firstVisualLatency.add(dev.Timeline.now - pending.$2);
      }
    });
  }

  static void reset() {
    counts.clear();
    stateLatency.clear();
    frameLatency.clear();
    firstVisualLatency.clear();
    _pendingVisual.clear();
    _generation++;
    feedbackWindows.clear();
  }

  static Map<String, dynamic> snapshot() {
    double p(List<int> values, double q) {
      final v = [...values]..sort();
      return v.isEmpty ? 0 : v[((v.length - 1) * q).ceil()] / 1000;
    }

    return {
      'hotspots': Map.of(counts),
      'tapToStateP50Ms': p(stateLatency, .5),
      'tapToStateP95Ms': p(stateLatency, .95),
      'tapToPostFrameP50Ms': p(frameLatency, .5),
      'tapToPostFrameP95Ms': p(frameLatency, .95),
      'acceptedTapSamples': stateLatency.length,
      'callbackToFirstVisualFrameP50Ms': p(firstVisualLatency, .5),
      'callbackToFirstVisualFrameP95Ms': p(firstVisualLatency, .95),
      'firstVisualSamples': firstVisualLatency.length,
    };
  }
}

Widget matchPaintBoundary(String role, {Key? key, required Widget child}) =>
    matchProfileEnabled
    ? _TrackedBoundary(key: key, role: role, child: child)
    : RepaintBoundary(key: key, child: child);

class _TrackedBoundary extends SingleChildRenderObjectWidget {
  const _TrackedBoundary({super.key, required this.role, required super.child});
  final String role;
  @override
  RenderObject createRenderObject(BuildContext context) =>
      _TrackedRenderBoundary(role);
  @override
  void updateRenderObject(
    BuildContext context,
    _TrackedRenderBoundary renderObject,
  ) {
    renderObject.role = role;
  }
}

class _TrackedRenderBoundary extends RenderRepaintBoundary {
  _TrackedRenderBoundary(this.role);
  String role;
  @override
  void paint(PaintingContext context, Offset offset) {
    MatchProfileCounters.hit('$role.paint');
    super.paint(context, offset);
  }
}
