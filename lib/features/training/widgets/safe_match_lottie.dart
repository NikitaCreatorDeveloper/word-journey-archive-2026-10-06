import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:lottie/lottie.dart';

import '../../../app/match_profile_controls.dart';

typedef MatchLottieDraw = void Function(
  LottieDrawable drawable,
  Canvas canvas,
  Rect rect,
);

/// Uses Lottie's public vector renderer. Errors are caught at construction,
/// progress and paint, without replacing the app-wide Flutter error handler.
/// Finite drawing-command pictures are local to this playback and disposed with
/// it; only the artwork's 30/60 fps frames repaint on a 120 Hz display.
class SafeMatchLottie extends LeafRenderObjectWidget {
  const SafeMatchLottie({
    super.key,
    required this.composition,
    required this.animation,
    required this.onFailure,
    this.calm = false,
    this.draw,
  });
  final LottieComposition composition;
  final Animation<double> animation;
  final VoidCallback onFailure;
  final bool calm;
  final MatchLottieDraw? draw;
  @override
  RenderBox createRenderObject(BuildContext context) =>
      _SafeMatchLottieRender(composition, animation, calm, onFailure, draw);
  @override
  void updateRenderObject(
    BuildContext context,
    covariant RenderBox renderObject,
  ) {
    (renderObject as _SafeMatchLottieRender).update(
      composition,
      animation,
      calm,
      onFailure,
      draw,
    );
  }
}

class _SafeMatchLottieRender extends RenderBox {
  _SafeMatchLottieRender(
    this._composition,
    this._animation,
    this._calm,
    this._onFailure,
    this._draw,
  ) {
    _prepare();
  }
  LottieComposition _composition;
  Animation<double> _animation;
  bool _calm, _failed = false;
  VoidCallback _onFailure;
  MatchLottieDraw? _draw;
  LottieDrawable? _drawable;
  final _pictures = <double, ui.Picture>{};
  Size? _recordedSize;
  void _clearPictures() {
    for (final picture in _pictures.values) {
      picture.dispose();
    }
    _pictures.clear();
  }

  void _fail() {
    if (_failed) return;
    _failed = true;
    final callback = _onFailure;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      callback();
    });
  }

  void _prepare() {
    _clearPictures();
    _failed = false;
    try {
      final drawable = LottieDrawable(
        _composition,
        frameRate: FrameRate.composition,
      );
      // Set delegates after construction; use standard editable layer names.
      if (_calm) {
        drawable.delegates = LottieDelegates(
          values: [
            ValueDelegate.opacity(['particles'], value: 0),
            ValueDelegate.opacity(['energy-trail'], value: 0),
            ValueDelegate.opacity(['peak-ring'], value: 0),
          ],
        );
      }
      drawable.isApplyingOpacityToLayersEnabled = false;
      drawable.setProgress(_animation.value);
      _drawable = drawable;
    } catch (_) {
      _drawable = null;
      _fail();
    }
  }

  void update(
    LottieComposition composition,
    Animation<double> animation,
    bool calm,
    VoidCallback onFailure,
    MatchLottieDraw? draw,
  ) {
    final changed =
        _composition != composition || _calm != calm || _draw != draw;
    if (_animation != animation) {
      if (attached) _animation.removeListener(_tick);
      _animation = animation;
      if (attached) _animation.addListener(_tick);
    }
    _onFailure = onFailure;
    _composition = composition;
    _calm = calm;
    _draw = draw;
    if (changed) _prepare();
    _tick();
  }

  void _tick() {
    if (_failed) return;
    try {
      if (_drawable?.setProgress(_animation.value) == true) markNeedsPaint();
    } catch (_) {
      _fail();
    }
  }

  @override
  void attach(PipelineOwner owner) {
    super.attach(owner);
    _animation.addListener(_tick);
  }

  @override
  void detach() {
    _animation.removeListener(_tick);
    super.detach();
  }

  @override
  Size computeDryLayout(BoxConstraints constraints) =>
      constraints.constrain(const Size(64, 64));
  @override
  void performLayout() {
    size = computeDryLayout(constraints);
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    if (_failed || _drawable == null) return;
    MatchProfileCounters.hit('lottie.paint');
    try {
      if (_recordedSize != size) {
        _clearPictures();
        _recordedSize = size;
      }
      final frame = _drawable!.progress;
      var picture = _pictures[frame];
      if (picture == null) {
        final recorder = ui.PictureRecorder();
        try {
          final canvas = Canvas(recorder);
          if (_draw != null) {
            _draw!(_drawable!, canvas, Offset.zero & size);
          } else {
            _drawable!.draw(canvas, Offset.zero & size, fit: BoxFit.contain);
          }
          picture = recorder.endRecording();
        } catch (_) {
          // End/dispose even an interrupted recording before selecting fallback.
          recorder.endRecording().dispose();
          rethrow;
        }
        _pictures[frame] = picture;
      }
      final canvas = context.canvas;
      canvas.save();
      try {
        canvas.translate(offset.dx, offset.dy);
        canvas.drawPicture(picture);
      } finally {
        canvas.restore();
      }
    } catch (_) {
      _fail();
    }
  }

  @override
  void dispose() {
    _clearPictures();
    _drawable = null;
    super.dispose();
  }
}
