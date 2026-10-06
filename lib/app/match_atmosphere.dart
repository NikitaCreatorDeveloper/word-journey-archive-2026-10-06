import 'match_profile_controls.dart';

import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Static, bounded vector scenery. Never ticks or intercepts the playing field.
class MatchAtmosphere extends StatelessWidget {
  const MatchAtmosphere({super.key});
  @override
  Widget build(BuildContext context) =>
      Theme.of(context).brightness == Brightness.light
      ? const SizedBox.shrink()
      : LayoutBuilder(
          builder: (context, c) => Align(
            alignment: Alignment.bottomCenter,
            child: SizedBox(
              width: double.infinity,
              height: math.min(220.0, c.maxHeight * .3),
              child: const IgnorePointer(
                child: ExcludeSemantics(
                  child: RepaintBoundary(
                    child: CustomPaint(
                      painter: _NightLandscape(),
                      isComplex: true,
                      willChange: false,
                      child: SizedBox.expand(),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
}

void paintMatchLandscape(Canvas canvas, Size size) =>
    const _NightLandscape().paint(canvas, size);

class _NightLandscape extends CustomPainter {
  const _NightLandscape();
  @override
  void paint(Canvas c, Size size) {
    MatchProfileCounters.hit('landscape.paint');
    final h = size.height, w = size.width;
    c.save();
    final moon = Offset(w * .78, h * .26);
    c.drawCircle(
      moon,
      42,
      Paint()
        ..shader = RadialGradient(
          colors: const [Color(0x167A64C8), Color(0x007A64C8)],
        ).createShader(Rect.fromCircle(center: moon, radius: 42)),
    );
    c.drawCircle(moon, 19, Paint()..color = const Color(0x18CAB6FF));
    c.drawPath(
      Path()
        ..moveTo(0, h * .72)
        ..lineTo(w * .23, h * .34)
        ..lineTo(w * .48, h * .69)
        ..lineTo(w * .68, h * .46)
        ..lineTo(w, h * .74)
        ..lineTo(w, h)
        ..lineTo(0, h)
        ..close(),
      Paint()..color = const Color(0x234D4B8C),
    );
    c.drawPath(
      Path()
        ..moveTo(0, h * .88)
        ..lineTo(w * .34, h * .65)
        ..lineTo(w * .57, h * .83)
        ..lineTo(w * .83, h * .66)
        ..lineTo(w, h * .91)
        ..lineTo(w, h)
        ..lineTo(0, h)
        ..close(),
      Paint()..color = const Color(0x25333D75),
    );
    c.drawPath(
      Path()
        ..moveTo(w * .56, h * .7)
        ..cubicTo(w * .76, h * .76, w * .31, h * .84, w * .57, h)
        ..lineTo(w * .68, h)
        ..cubicTo(w * .37, h * .84, w * .85, h * .76, w * .56, h * .7)
        ..close(),
      Paint()..color = const Color(0x1D8B7AC2),
    );
    for (final side in [-1, 1]) {
      final x = side < 0 ? w * .055 : w * .95;
      c.drawPath(
        Path()
          ..moveTo(x, h)
          ..quadraticBezierTo(x - side * 9, h * .7, x - side * 5, h * .55),
        Paint()
          ..color = const Color(0x285F5A9E)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.4,
      );
      for (var j = 0; j < 3; j++) {
        final y = h * (.9 - j * .11), dx = side * (j.isEven ? 1 : -1) * 22;
        c.drawPath(
          Path()
            ..moveTo(x, y)
            ..quadraticBezierTo(x + dx, y - 2, x + dx, y - 25)
            ..quadraticBezierTo(x, y - 20, x, y)
            ..close(),
          Paint()..color = const Color(0x284E488D),
        );
      }
    }
    for (final p in [
      Offset(w * .1, h * .23),
      Offset(w * .39, h * .18),
      Offset(w * .63, h * .36),
      Offset(w * .91, h * .12),
    ]) {
      c.drawCircle(p, .9, Paint()..color = const Color(0x4AAFA6EF));
    }
    c.restore();
  }

  @override
  bool shouldRepaint(_NightLandscape old) => false;
}
