import 'package:flutter/material.dart';

import '../../../app/app_theme.dart';

/// A small original architectural vignette, painted natively with the atlas palette.
class CafeArtwork extends StatelessWidget {
  const CafeArtwork({super.key});
  @override
  Widget build(BuildContext context) => CustomPaint(
    painter: _CafePainter(
      AtlasColors.of(context),
      Theme.of(context).colorScheme.primary,
    ),
    child: const SizedBox.expand(),
  );
}

class _CafePainter extends CustomPainter {
  const _CafePainter(this.colors, this.accent);
  final AtlasColors colors;
  final Color accent;
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = colors.selected);
    canvas.save();
    canvas.scale(size.width / 400, size.height / 240);
    final ink = Paint()..color = accent.withValues(alpha: .45);
    final soft = Paint()..color = colors.card;
    final outline = Paint()
      ..color = accent.withValues(alpha: .45)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawCircle(
      const Offset(334, 49),
      28,
      Paint()..color = accent.withValues(alpha: .12),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(62, 50, 250, 157),
        const Radius.circular(8),
      ),
      soft,
    );
    canvas.drawRect(
      const Rect.fromLTWH(81, 76, 108, 96),
      Paint()..color = colors.backgroundEnd,
    );
    canvas.drawRect(
      const Rect.fromLTWH(207, 76, 83, 131),
      Paint()..color = colors.backgroundEnd,
    );
    canvas.drawLine(const Offset(135, 76), const Offset(135, 172), outline);
    canvas.drawLine(const Offset(81, 124), const Offset(189, 124), outline);
    canvas.drawLine(const Offset(248, 76), const Offset(248, 207), outline);
    final awning = Path()
      ..moveTo(58, 50)
      ..lineTo(317, 50)
      ..lineTo(335, 76)
      ..lineTo(41, 76)
      ..close();
    canvas.drawPath(awning, ink);
    canvas.drawLine(const Offset(28, 208), const Offset(370, 208), outline);
    canvas.drawOval(const Rect.fromLTWH(89, 184, 98, 13), ink);
    canvas.drawLine(const Offset(138, 197), const Offset(138, 225), outline);
    canvas.drawLine(const Offset(114, 225), const Offset(162, 225), outline);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(123, 165, 25, 20),
        const Radius.circular(5),
      ),
      soft,
    );
    canvas.drawArc(
      const Rect.fromLTWH(141, 168, 15, 12),
      -1.5,
      3,
      false,
      outline,
    );
    canvas.drawLine(const Offset(130, 152), const Offset(132, 145), outline);
    canvas.drawLine(const Offset(141, 155), const Offset(143, 148), outline);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(316, 168, 24, 40),
        const Radius.circular(4),
      ),
      ink,
    );
    canvas.drawOval(const Rect.fromLTWH(298, 125, 29, 58), ink);
    canvas.drawOval(const Rect.fromLTWH(326, 118, 28, 64), ink);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _CafePainter old) =>
      old.colors != colors || old.accent != accent;
}
