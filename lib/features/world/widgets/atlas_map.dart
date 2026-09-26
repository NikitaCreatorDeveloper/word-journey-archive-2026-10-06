import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../app/app_theme.dart';
import '../model/world_content.dart';

enum AtlasScene { world, country, city }

class AtlasStop {
  const AtlasStop({
    required this.id,
    required this.label,
    required this.position,
    required this.onTap,
  });
  final String id;
  final String label;
  final MapPosition position;
  final VoidCallback onTap;
}

/// All locations are normalized in the illustrated atlas, independent of device pixels.
class AtlasMap extends StatefulWidget {
  const AtlasMap({super.key, required this.scene, required this.stops});
  final AtlasScene scene;
  final List<AtlasStop> stops;
  @override
  State<AtlasMap> createState() => _AtlasMapState();
}

class _AtlasMapState extends State<AtlasMap>
    with SingleTickerProviderStateMixin {
  final _transform = TransformationController();
  late final _reset = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 320),
  );
  Animation<Matrix4>? _resetValue;
  String? _selected;

  @override
  void initState() {
    super.initState();
    _reset.addListener(() {
      if (_resetValue case final animation?) _transform.value = animation.value;
    });
  }

  void _resetView() {
    _resetValue = Matrix4Tween(
      begin: _transform.value.clone(),
      end: Matrix4.identity(),
    ).animate(CurvedAnimation(parent: _reset, curve: Curves.easeOutCubic));
    _reset.forward(from: 0);
  }

  @override
  void dispose() {
    _reset.dispose();
    _transform.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = AtlasColors.of(context);
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: ColoredBox(
        color: colors.backgroundEnd,
        child: Stack(
          children: [
            LayoutBuilder(
              builder: (context, constraints) {
                final size = Size(constraints.maxWidth, constraints.maxHeight);
                final rect = atlasRect(size, widget.scene);
                return InteractiveViewer(
                  key: ValueKey('atlas-viewer-${widget.scene.name}'),
                  transformationController: _transform,
                  minScale: 1,
                  maxScale: 4,
                  boundaryMargin: const EdgeInsets.all(140),
                  onInteractionStart: (_) => _reset.stop(),
                  child: SizedBox.fromSize(
                    size: size,
                    child: TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: 1),
                      duration: const Duration(milliseconds: 850),
                      curve: Curves.easeOutCubic,
                      builder: (context, reveal, _) => Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Positioned.fill(
                            child: CustomPaint(
                              painter: AtlasPainter(
                                scene: widget.scene,
                                colors: colors,
                                accent: Theme.of(context).colorScheme.primary,
                                reveal: reveal,
                                fontFamily: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.fontFamily,
                              ),
                            ),
                          ),
                          for (final stop in widget.stops)
                            Positioned(
                              left:
                                  rect.left + rect.width * stop.position.x - 72,
                              top:
                                  rect.top + rect.height * stop.position.y - 22,
                              width: 144,
                              child: Opacity(
                                opacity: reveal,
                                child: Semantics(
                                  button: true,
                                  label: stop.label,
                                  child: InkWell(
                                    key: ValueKey('atlas-marker-${stop.id}'),
                                    borderRadius: BorderRadius.circular(16),
                                    onTap: () {
                                      setState(() => _selected = stop.id);
                                      stop.onTap();
                                    },
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 8,
                                      ),
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          AnimatedContainer(
                                            duration: const Duration(
                                              milliseconds: 180,
                                            ),
                                            width: 28,
                                            height: 28,
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .primary,
                                              border: Border.all(
                                                color: colors.card,
                                                width: _selected == stop.id
                                                    ? 6
                                                    : 4,
                                              ),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: colors.shadow,
                                                  blurRadius: 12,
                                                ),
                                              ],
                                            ),
                                            child: Icon(
                                              Icons.circle,
                                              size: 6,
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .onPrimary,
                                            ),
                                          ),
                                          const SizedBox(height: 6),
                                          DecoratedBox(
                                            decoration: BoxDecoration(
                                              color: colors.card,
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                              border: Border.all(
                                                color: colors.cardOutline,
                                              ),
                                            ),
                                            child: Padding(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 9,
                                                    vertical: 7,
                                                  ),
                                              child: Text(
                                                stop.label,
                                                textAlign: TextAlign.center,
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .labelMedium
                                                    ?.copyWith(
                                                      fontWeight:
                                                          FontWeight.w600,
                                                    ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
            Positioned(
              right: 10,
              top: 10,
              child: IconButton.filledTonal(
                onPressed: _resetView,
                tooltip: 'Показать карту целиком',
                icon: const Icon(Icons.center_focus_strong_rounded, size: 20),
              ),
            ),
            Positioned(
              left: 16,
              bottom: 16,
              child: IgnorePointer(
                child: Text(
                  widget.scene == AtlasScene.world
                      ? 'WORLD / 01'
                      : widget.scene == AtlasScene.country
                      ? 'UNITED KINGDOM / 01'
                      : 'LONDON / 01',
                  style: TextStyle(
                    fontSize: 10,
                    letterSpacing: 2,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Rect atlasRect(Size size, AtlasScene scene) {
  final ratio = scene == AtlasScene.world
      ? 1.65
      : scene == AtlasScene.country
      ? .8
      : 1.15;
  final width = math.min(size.width - 28, (size.height - 76) * ratio);
  final height = width / ratio;
  return Rect.fromLTWH(
    (size.width - width) / 2,
    (size.height - height) / 2,
    width,
    height,
  );
}

/// Original schematic artwork: no map tiles, geographic SDK or external assets.
class AtlasPainter extends CustomPainter {
  AtlasPainter({
    required this.scene,
    required this.colors,
    required this.accent,
    required this.reveal,
    this.fontFamily,
  });
  final AtlasScene scene;
  final AtlasColors colors;
  final Color accent;
  final double reveal;
  final String? fontFamily;

  @override
  void paint(Canvas canvas, Size size) {
    final grid = Paint()
      ..color = colors.cardOutline.withValues(alpha: .35)
      ..strokeWidth = .6;
    for (double x = 18; x < size.width; x += 32) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), grid);
    }
    for (double y = 18; y < size.height; y += 32) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }
    final rect = atlasRect(size, scene);
    canvas.save();
    canvas.translate(rect.left, rect.top);
    canvas.scale(rect.width / 1000, rect.height / 600);
    if (scene == AtlasScene.world) {
      _world(canvas);
    } else if (scene == AtlasScene.country) {
      _country(canvas);
    } else {
      _city(canvas);
    }
    canvas.restore();
    // Small compass etched into the atlas.
    final center = Offset(27, 35);
    final ink = Paint()
      ..color = accent.withValues(alpha: .65)
      ..strokeWidth = 1;
    canvas.drawLine(
      center - const Offset(0, 10),
      center + const Offset(0, 10),
      ink,
    );
    canvas.drawLine(
      center - const Offset(6, 0),
      center + const Offset(6, 0),
      ink,
    );
    canvas.drawCircle(center, 2, ink);
  }

  void _land(Canvas c, List<Offset> points, {bool highlight = false}) {
    final p = Path()..addPolygon(points, true);
    c.drawPath(p.shift(const Offset(0, 5)), Paint()..color = colors.shadow);
    c.drawPath(
      p,
      Paint()
        ..color = highlight
            ? colors.selected
            : Color.lerp(
                colors.card,
                accent,
                colors.card.computeLuminance() < .1 ? .13 : .28,
              )!,
    );
    c.drawPath(
      p,
      Paint()
        ..color = Color.lerp(colors.cardOutline, accent, .18)!
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }

  void _world(Canvas c) {
    _land(c, const [
      Offset(55, 115),
      Offset(110, 80),
      Offset(175, 62),
      Offset(224, 85),
      Offset(278, 73),
      Offset(335, 115),
      Offset(305, 160),
      Offset(259, 183),
      Offset(238, 226),
      Offset(199, 246),
      Offset(214, 286),
      Offset(187, 297),
      Offset(148, 252),
      Offset(125, 220),
      Offset(109, 169),
      Offset(61, 158),
      Offset(36, 140),
    ]);
    _land(c, const [
      Offset(280, 28),
      Offset(351, 34),
      Offset(370, 67),
      Offset(342, 117),
      Offset(307, 106),
      Offset(284, 69),
    ]);
    _land(c, const [
      Offset(219, 296),
      Offset(260, 309),
      Offset(287, 332),
      Offset(320, 354),
      Offset(306, 404),
      Offset(279, 433),
      Offset(260, 489),
      Offset(240, 541),
      Offset(222, 517),
      Offset(221, 452),
      Offset(199, 395),
      Offset(200, 343),
    ]);
    _land(c, const [
      Offset(486, 182),
      Offset(511, 167),
      Offset(517, 135),
      Offset(542, 119),
      Offset(553, 82),
      Offset(575, 69),
      Offset(568, 125),
      Offset(548, 162),
      Offset(583, 175),
      Offset(613, 157),
      Offset(657, 130),
      Offset(715, 86),
      Offset(801, 80),
      Offset(869, 114),
      Offset(931, 141),
      Offset(947, 184),
      Offset(902, 205),
      Offset(878, 251),
      Offset(835, 270),
      Offset(814, 317),
      Offset(793, 350),
      Offset(772, 306),
      Offset(741, 280),
      Offset(718, 328),
      Offset(696, 333),
      Offset(675, 267),
      Offset(637, 241),
      Offset(606, 254),
      Offset(576, 224),
      Offset(555, 219),
      Offset(551, 240),
      Offset(528, 209),
      Offset(516, 230),
      Offset(484, 222),
    ]);
    _land(c, const [
      Offset(480, 239),
      Offset(534, 238),
      Offset(577, 271),
      Offset(597, 316),
      Offset(579, 359),
      Offset(558, 427),
      Offset(526, 447),
      Offset(501, 402),
      Offset(489, 358),
      Offset(455, 319),
      Offset(446, 275),
    ]);
    _land(c, const [
      Offset(589, 392),
      Offset(601, 379),
      Offset(606, 416),
      Offset(593, 445),
      Offset(584, 431),
    ]);
    _land(c, const [
      Offset(791, 424),
      Offset(838, 402),
      Offset(869, 412),
      Offset(889, 396),
      Offset(918, 442),
      Offset(915, 485),
      Offset(881, 512),
      Offset(854, 489),
      Offset(802, 491),
      Offset(779, 464),
    ]);
    _land(c, const [
      Offset(955, 494),
      Offset(962, 520),
      Offset(945, 546),
      Offset(937, 534),
    ]);
    _land(c, const [
      Offset(890, 247),
      Offset(902, 228),
      Offset(899, 268),
      Offset(884, 286),
    ]);
    _land(c, const [
      Offset(763, 367),
      Offset(799, 368),
      Offset(817, 382),
      Offset(778, 383),
    ]);
    _land(c, const [
      Offset(464, 139),
      Offset(480, 131),
      Offset(479, 153),
      Offset(488, 173),
      Offset(471, 181),
      Offset(463, 164),
    ], highlight: true);
    _land(c, const [
      Offset(447, 157),
      Offset(459, 151),
      Offset(456, 178),
      Offset(443, 176),
    ]);
    _label(c, 'PACIFIC', const Offset(70, 375), 18);
    _label(c, 'ATLANTIC', const Offset(333, 270), 18);
    _label(c, 'INDIAN OCEAN', const Offset(621, 466), 16);
    _route(
      c,
      Path()
        ..moveTo(355, 350)
        ..quadraticBezierTo(363, 188, 475, 162),
    );
  }

  void _country(Canvas c) {
    _land(c, const [
      Offset(460, 35),
      Offset(561, 19),
      Offset(617, 58),
      Offset(553, 94),
      Offset(594, 126),
      Offset(549, 168),
      Offset(571, 213),
      Offset(610, 246),
      Offset(600, 287),
      Offset(655, 310),
      Offset(680, 354),
      Offset(714, 391),
      Offset(727, 439),
      Offset(690, 471),
      Offset(632, 487),
      Offset(565, 478),
      Offset(510, 499),
      Offset(440, 508),
      Offset(397, 489),
      Offset(453, 461),
      Offset(433, 422),
      Offset(472, 392),
      Offset(456, 363),
      Offset(494, 322),
      Offset(512, 285),
      Offset(480, 250),
      Offset(464, 204),
      Offset(431, 177),
      Offset(461, 139),
      Offset(420, 101),
      Offset(451, 78),
    ], highlight: true);
    _land(c, const [
      Offset(273, 238),
      Offset(335, 215),
      Offset(382, 258),
      Offset(356, 303),
      Offset(377, 347),
      Offset(321, 379),
      Offset(260, 358),
      Offset(240, 312),
    ]);
    _label(c, 'NORTH SEA', const Offset(738, 190), 19);
    _label(c, 'ATLANTIC', const Offset(110, 445), 18);
    _route(
      c,
      Path()
        ..moveTo(507, 151)
        ..cubicTo(684, 235, 439, 355, 640, 456),
    );
    for (final p in [const Offset(507, 151), const Offset(550, 300)]) {
      c.drawCircle(p, 5, Paint()..color = accent.withValues(alpha: .65));
    }
  }

  void _city(Canvas c) {
    final blocks = Paint()..color = Color.lerp(colors.card, accent, .06)!;
    for (var row = 0; row < 5; row++) {
      for (var col = 0; col < 6; col++) {
        final x = 30.0 + col * 162;
        final y = 30.0 + row * 108;
        c.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(x, y, 132, 78),
            const Radius.circular(12),
          ),
          blocks,
        );
      }
    }
    final river = Path()
      ..moveTo(-20, 420)
      ..cubicTo(200, 180, 340, 520, 590, 397)
      ..cubicTo(760, 300, 808, 492, 1040, 322);
    c.drawPath(
      river,
      Paint()
        ..color = Color.lerp(colors.cardOutline, accent, .18)!
        ..style = PaintingStyle.stroke
        ..strokeWidth = 54,
    );
    c.drawPath(
      river,
      Paint()
        ..color = colors.backgroundEnd
        ..style = PaintingStyle.stroke
        ..strokeWidth = 46,
    );
    _label(c, 'THAMES', const Offset(699, 441), 18);
    _route(
      c,
      Path()
        ..moveTo(235, 431)
        ..cubicTo(215, 246, 370, 218, 520, 288),
    );
    // Quiet architectural silhouettes around the walking route.
    final ink = Paint()..color = accent.withValues(alpha: .25);
    c.drawRect(const Rect.fromLTWH(716, 134, 30, 154), ink);
    c.drawPath(
      Path()
        ..moveTo(708, 134)
        ..lineTo(731, 92)
        ..lineTo(754, 134)
        ..close(),
      ink,
    );
    c.drawCircle(const Offset(731, 156), 9, Paint()..color = colors.card);
    c.drawRect(const Rect.fromLTWH(665, 233, 144, 55), ink);
  }

  void _route(Canvas c, Path path) {
    final metric = path.computeMetrics().first;
    final paint = Paint()
      ..color = accent.withValues(alpha: .65)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;
    for (double d = 0; d < metric.length * reveal; d += 13) {
      c.drawPath(
        metric.extractPath(d, math.min(d + 6, metric.length * reveal)),
        paint,
      );
    }
  }

  void _label(Canvas c, String text, Offset position, double fontSize) {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: accent.withValues(alpha: .45),
          fontSize: fontSize,
          fontFamily: fontFamily,
          letterSpacing: 3,
          fontWeight: FontWeight.w400,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    painter.paint(c, position);
  }

  @override
  bool shouldRepaint(covariant AtlasPainter old) =>
      old.scene != scene ||
      old.colors != colors ||
      old.accent != accent ||
      old.reveal != reveal ||
      old.fontFamily != fontFamily;
}
