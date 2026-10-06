import '../../../app/match_profile_controls.dart';

import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' show VertexMode, Vertices, Shader;

import 'package:flutter/material.dart';

import '../../../app/design_tokens.dart';
import '../../../app/motion_preferences.dart';

class LightningFeedback extends StatefulWidget {
  const LightningFeedback({
    super.key,
    required this.revision,
    required this.combo,
    this.onPeak,
    this.onFinished,
    this.compact = false,
  });
  final int revision, combo;
  final ValueChanged<int>? onPeak;
  final VoidCallback? onFinished;
  final bool compact;
  @override
  State<LightningFeedback> createState() => _LightningFeedbackState();
}

class _LightningFeedbackState extends State<LightningFeedback>
    with TickerProviderStateMixin {
  AnimationController? _active;
  AnimationController get _motion => _active!;
  _BoltGeometry? _geometry;
  _BoltGeometry get _bolt => _geometry!;
  int _durationMs = 650;
  void _start() {
    MatchProfileCounters.feedback(
      widget.combo >= 2 ? 'combo' : 'correct',
      _durationMs,
    );
    _active ??=
        AnimationController(
            vsync: this,
            duration: Duration(milliseconds: _durationMs),
          )
          ..addListener(_peak)
          ..addStatusListener((status) {
            if (status != AnimationStatus.completed) return;
            final completed = _active;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted &&
                  identical(_active, completed) &&
                  completed!.isCompleted) {
                setState(_clear);
                widget.onFinished?.call();
              }
            });
          });
    _geometry ??= _BoltGeometry();
    sent = false;
    _motion.forward(from: 0);
  }

  void _clear() {
    _active?.dispose();
    _active = null;
    _geometry?.dispose();
    _geometry = null;
  }

  bool sent = false;
  (TextStyle, double, bool)? _layoutKey;
  double _height = 78;
  void _peak() {
    if (!sent && widget.combo >= 2 && _motion.value >= .155) {
      sent = true;
      widget.onPeak?.call(widget.revision);
    }
  }

  @override
  void initState() {
    super.initState();
    if (widget.revision > 0 && widget.combo > 0) _start();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _durationMs = motionOf(context) == 'minimal'
        ? 180
        : motionOf(context) == 'calm'
        ? 540
        : 650;
    _active?.duration = Duration(milliseconds: _durationMs);
  }

  @override
  void didUpdateWidget(LightningFeedback old) {
    super.didUpdateWidget(old);
    if (widget.combo == 0) {
      _clear();
    } else if (old.revision != widget.revision) {
      // A new answer replaces the pulse; reuse just this one controller.
      _start();
    }
  }

  @override
  void dispose() {
    _clear();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    MatchProfileCounters.hit('combo.build');
    final dark = AppSurfaces.dark(context),
        minimal = motionOf(context) == 'minimal';
    final gold = dark ? AppColors.warning : const Color(0xFF85541C);
    final titleSize = widget.compact ? 15.0 : 19.0,
        capsuleSize = widget.compact ? 12.0 : 14.0;
    final scaler = MediaQuery.textScalerOf(context);
    final base = DefaultTextStyle.of(context).style;
    final layoutKey = (base, scaler.scale(16), widget.compact);
    if (_layoutKey != layoutKey) {
      double height(String text, double size, double width) {
        final p = TextPainter(
          text: TextSpan(
            text: text,
            style: base.merge(
              TextStyle(
                fontSize: size,
                height: 1.15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          textDirection: TextDirection.ltr,
          textScaler: scaler,
        )..layout(maxWidth: width);
        final result = p.height;
        p.dispose();
        return result;
      }

      final textWidth = 226.0 - (widget.compact ? 32 : 46) - 8;
      // Reserve the largest caption once, so streak changes never move the field.
      _height = math.max(
        widget.compact ? 56 : 78,
        height('Отлично!', titleSize, textWidth) +
            height('Комбо x60', capsuleSize, textWidth - 20) +
            13,
      );
      _layoutKey = layoutKey;
    }
    final active = _active;
    if (active == null) return SizedBox(width: 226, height: _height);
    final envelope = active.drive(const _RewardEnvelope());
    final caption = widget.combo >= 2
        ? Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Отлично!',
                style: TextStyle(
                  fontSize: titleSize,
                  height: 1.15,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 5),
              DecoratedBox(
                decoration: BoxDecoration(
                  color: gold.withValues(alpha: .10),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: gold.withValues(alpha: .7),
                    width: .8,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  child: Text(
                    'Комбо x${widget.combo}',
                    style: TextStyle(
                      fontSize: capsuleSize,
                      height: 1.15,
                      fontWeight: FontWeight.w600,
                      color: gold,
                    ),
                  ),
                ),
              ),
            ],
          )
        : Text(
            'Верно',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          );
    final fadeCaption = FadeTransition(
      opacity: envelope,
      child: RepaintBoundary(child: caption),
    );
    return SizedBox(
      width: 226,
      height: _height,
      child: IgnorePointer(
        child: ExcludeSemantics(
          child: Align(
            alignment: Alignment.centerRight,
            child: RepaintBoundary(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (widget.combo >= 2 && !minimal)
                    SizedBox(
                      width: widget.compact ? 32 : 46,
                      height: widget.compact ? 46 : 64,
                      child: RepaintBoundary(
                        child: CustomPaint(
                          painter: _BoltPainter(
                            _bolt,
                            gold,
                            widget.combo,
                            motionOf(context) == 'full' &&
                                MatchProfileScope.of(context).particles,
                            active,
                          ),
                        ),
                      ),
                    )
                  else
                    FadeTransition(
                      opacity: envelope,
                      child: RepaintBoundary(
                        child: Icon(
                          Icons.check_circle_outline_rounded,
                          size: 24,
                          color: widget.combo >= 2
                              ? gold
                              : dark
                              ? AppColors.success
                              : const Color(0xFF258C7B),
                        ),
                      ),
                    ),
                  const SizedBox(width: 8),
                  Flexible(child: fadeCaption),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BoltPainter extends CustomPainter {
  _BoltPainter(
    this.geometry,
    this.gold,
    this.combo,
    this.sparks,
    this.animation,
  ) : super(repaint: animation);
  final _BoltGeometry geometry;
  final Color gold;
  final int combo;
  final bool sparks;
  final Animation<double> animation;
  @override
  void paint(Canvas c, Size s) {
    MatchProfileCounters.hit('bolt.paint');
    final v = animation.value;
    final opacity = const _RewardEnvelope().transform(v);
    final scale = v < .155
        ? .85 + .2 * Curves.easeOutCubic.transform(v / .155)
        : v < .49
        ? 1.05 - .05 * Curves.easeOutCubic.transform((v - .155) / .335)
        : 1.0;
    if (opacity <= 0) return;
    c.save();
    c.scale(s.width / 46, s.height / 64);
    c.translate(23, 32);
    c.scale(scale);
    c.translate(-23, -32);
    if (sparks) {
      c.drawVertices(
        geometry.glow,
        BlendMode.src,
        Paint()
          ..color = AppColors.accentSecondary.withValues(alpha: .15 * opacity),
      );
    }
    c.drawVertices(
      geometry.fill,
      BlendMode.src,
      Paint()
        ..shader = geometry.shader(gold)
        ..color = Colors.white.withValues(alpha: opacity),
    );
    c.drawVertices(
      geometry.outline,
      BlendMode.src,
      Paint()..color = gold.withValues(alpha: opacity),
    );
    if (sparks) {
      for (final p in geometry.sparks.take(combo >= 5 ? 5 : 3)) {
        c.drawLine(
          p - const Offset(0, 2),
          p + const Offset(0, 2),
          Paint()
            ..color = gold.withValues(alpha: opacity)
            ..strokeWidth = 1,
        );
        c.drawLine(
          p - const Offset(2, 0),
          p + const Offset(2, 0),
          Paint()
            ..color = gold.withValues(alpha: opacity)
            ..strokeWidth = 1,
        );
      }
    }
    c.restore();
  }

  @override
  bool shouldRepaint(_BoltPainter old) =>
      old.combo != combo ||
      old.gold != gold ||
      old.sparks != sparks ||
      old.animation != animation ||
      old.geometry != geometry;
}

// Four triangles form the concave vector bolt. Small edge strips provide the
// outline and glow without tessellating stroked paths on every animation frame.
class _BoltGeometry {
  final _shaders = <Color, Shader>{};
  Shader shader(Color gold) => _shaders.putIfAbsent(
    gold,
    () => LinearGradient(
      colors: [const Color(0xFFFFE9A8), gold],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ).createShader(const Rect.fromLTWH(10, 7, 30, 50)),
  );

  static const points = [
    Offset(29, 7),
    Offset(10, 35),
    Offset(24, 35),
    Offset(19, 57),
    Offset(40, 27),
    Offset(27, 27),
  ];
  final sparks = List<Offset>.generate(5, (i) {
    final angle = i * math.pi * 2 / 5;
    return Offset(25 + 21 * math.cos(angle), 32 + 25 * math.sin(angle));
  });
  final fill = Vertices.raw(
    VertexMode.triangles,
    Float32List.fromList([
      for (final i in [0, 1, 2, 0, 2, 5, 2, 3, 4, 2, 4, 5]) ...[
        points[i].dx,
        points[i].dy,
      ],
    ]),
  );
  final glow = edge(7), outline = edge(1.1);
  static Vertices edge(double width) {
    final positions = <double>[];
    for (var i = 0; i <= points.length; i++) {
      final at = i % points.length;
      final before =
          points[at] - points[(at + points.length - 1) % points.length];
      final after = points[(at + 1) % points.length] - points[at];
      final n1 = Offset(-before.dy, before.dx) / before.distance;
      final n2 = Offset(-after.dy, after.dx) / after.distance;
      var n = n1 + n2;
      n = n / n.distance;
      final extent = (width / 2 / (n.dx * n1.dx + n.dy * n1.dy).abs()).clamp(
        width / 2,
        width * .9,
      );
      final a = points[at] + n * extent, b = points[at] - n * extent;
      positions.addAll([a.dx, a.dy, b.dx, b.dy]);
    }
    return Vertices.raw(
      VertexMode.triangleStrip,
      Float32List.fromList(positions),
    );
  }

  void dispose() {
    fill.dispose();
    glow.dispose();
    outline.dispose();
  }
}

class _RewardEnvelope extends Animatable<double> {
  const _RewardEnvelope();
  @override
  double transform(double v) =>
      (v < .15
              ? v / .15
              : v > .5
              ? (1 - v) * 2
              : 1.0)
          .clamp(0.0, 1.0);
}
