// Generated from tool/build_indigo_vectors.py. SVG and Canvas share geometry.
import 'package:flutter/material.dart';

class PremiumArt extends StatelessWidget {
  const PremiumArt(
    this.name, {
    super.key,
    this.width = 120,
    this.height = 120,
    this.cover = false,
  });
  final String name;
  final double width, height;
  final bool cover;
  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: RepaintBoundary(
      child: SizedBox(
        width: width,
        height: height,
        child: CustomPaint(
          painter: VectorArtPainter(name, cover: cover),
          isComplex: true,
          willChange: false,
        ),
      ),
    ),
  );
}

class _VectorLayer {
  _VectorLayer(this.path, this.fill, this.stroke, this.width, this.colors);
  final Path path;
  final Color? fill, stroke;
  final double width;
  final List<Color>? colors;
}

class VectorArtPainter extends CustomPainter {
  const VectorArtPainter(this.name, {this.cover = false});
  final bool cover;
  final String name;
  @override
  void paint(Canvas canvas, Size size) {
    final scene = _scenes[name];
    if (scene == null) return;
    final view = scene.$1;
    final xScale = size.width / view.width, yScale = size.height / view.height;
    final factor = cover
        ? (xScale > yScale ? xScale : yScale)
        : (xScale < yScale ? xScale : yScale);
    canvas.save();
    canvas.translate(
      (size.width - view.width * factor) / 2,
      (size.height - view.height * factor) / 2,
    );
    canvas.scale(factor);
    for (final layer in scene.$2) {
      if (layer.fill != null) {
        final paint = Paint()..color = layer.fill!;
        if (layer.colors != null) {
          paint.shader = LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: layer.colors!,
          ).createShader(layer.path.getBounds());
        }
        canvas.drawPath(layer.path, paint);
      }
      if (layer.stroke != null) {
        canvas.drawPath(
          layer.path,
          Paint()
            ..color = layer.stroke!
            ..style = PaintingStyle.stroke
            ..strokeWidth = layer.width
            ..strokeJoin = StrokeJoin.round
            ..strokeCap = StrokeCap.round,
        );
      }
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(VectorArtPainter old) =>
      old.name != name || old.cover != cover;
}

final _scenes = <String, (Size, List<_VectorLayer>)>{
  'illustrations/continue_landscape': (
    const Size(400, 280),
    [
      _VectorLayer(
        Path()
          ..moveTo(385.0000, 72.0000)
          ..cubicTo(385.0000, 110.6599, 353.6599, 142.0000, 315.0000, 142.0000)
          ..cubicTo(276.3401, 142.0000, 245.0000, 110.6599, 245.0000, 72.0000)
          ..cubicTo(245.0000, 33.3401, 276.3401, 2.0000, 315.0000, 2.0000)
          ..cubicTo(353.6599, 2.0000, 385.0000, 33.3401, 385.0000, 72.0000)
          ..close(),
        Color(0x1A8C69E5),
        null,
        1,
        null,
      ),
      _VectorLayer(
        Path()
          ..moveTo(363.0000, 72.0000)
          ..cubicTo(363.0000, 98.5097, 341.5097, 120.0000, 315.0000, 120.0000)
          ..cubicTo(288.4903, 120.0000, 267.0000, 98.5097, 267.0000, 72.0000)
          ..cubicTo(267.0000, 45.4903, 288.4903, 24.0000, 315.0000, 24.0000)
          ..cubicTo(341.5097, 24.0000, 363.0000, 45.4903, 363.0000, 72.0000)
          ..close(),
        Color(0x24BFA0FF),
        null,
        1,
        null,
      ),
      _VectorLayer(
        Path()
          ..moveTo(345.0000, 72.0000)
          ..cubicTo(345.0000, 88.5685, 331.5685, 102.0000, 315.0000, 102.0000)
          ..cubicTo(298.4315, 102.0000, 285.0000, 88.5685, 285.0000, 72.0000)
          ..cubicTo(285.0000, 55.4315, 298.4315, 42.0000, 315.0000, 42.0000)
          ..cubicTo(331.5685, 42.0000, 345.0000, 55.4315, 345.0000, 72.0000)
          ..close(),
        Color(0xFFD8BCFF),
        null,
        1,
        [Color(0xFFF4DFFF), Color(0xFFA28DEA)],
      ),
      _VectorLayer(
        Path()
          ..moveTo(0.0000, 195.0000)
          ..lineTo(122.0000, 93.0000)
          ..lineTo(245.0000, 187.0000)
          ..lineTo(350.0000, 126.0000)
          ..lineTo(400.0000, 164.0000)
          ..lineTo(400.0000, 280.0000)
          ..lineTo(0.0000, 280.0000)
          ..close(),
        Color(0xFF383B8A),
        null,
        1,
        [Color(0xFF7470CB), Color(0xFF252B67)],
      ),
      _VectorLayer(
        Path()
          ..moveTo(0.0000, 225.0000)
          ..lineTo(170.0000, 148.0000)
          ..lineTo(274.0000, 210.0000)
          ..lineTo(400.0000, 176.0000)
          ..lineTo(400.0000, 280.0000)
          ..lineTo(0.0000, 280.0000)
          ..close(),
        Color(0xFF272B63),
        null,
        1,
        [Color(0xFF4D4989), Color(0xFF171D43)],
      ),
      _VectorLayer(
        Path()
          ..moveTo(215.0000, 194.0000)
          ..cubicTo(254.0000, 193.0000, 267.0000, 205.0000, 235.0000, 215.0000)
          ..cubicTo(174.0000, 233.0000, 289.0000, 235.0000, 257.0000, 280.0000)
          ..lineTo(333.0000, 280.0000)
          ..cubicTo(351.0000, 236.0000, 225.0000, 225.0000, 263.0000, 215.0000)
          ..cubicTo(294.0000, 198.0000, 252.0000, 188.0000, 215.0000, 194.0000)
          ..close(),
        Color(0xFF7773BF),
        null,
        1,
        [Color(0xFF8982DA), Color(0xFF35385F)],
      ),
      _VectorLayer(
        Path()
          ..moveTo(0.0000, 266.0000)
          ..lineTo(82.0000, 212.0000)
          ..lineTo(159.0000, 258.0000)
          ..lineTo(187.0000, 280.0000)
          ..lineTo(0.0000, 280.0000)
          ..close(),
        Color(0xFF151F43),
        null,
        1,
        null,
      ),
      _VectorLayer(
        Path()
          ..moveTo(300.0000, 280.0000)
          ..lineTo(333.0000, 239.0000)
          ..lineTo(362.0000, 257.0000)
          ..lineTo(400.0000, 236.0000)
          ..lineTo(400.0000, 280.0000)
          ..close(),
        Color(0xFF172445),
        null,
        1,
        null,
      ),
      _VectorLayer(
        Path()
          ..moveTo(36.0000, 54.4000)
          ..lineTo(36.5148, 56.4852)
          ..lineTo(38.6000, 57.0000)
          ..lineTo(36.5148, 57.5148)
          ..lineTo(36.0000, 59.6000)
          ..lineTo(35.4852, 57.5148)
          ..lineTo(33.4000, 57.0000)
          ..lineTo(35.4852, 56.4852)
          ..close(),
        Color(0xAAC3BDFF),
        null,
        1,
        null,
      ),
      _VectorLayer(
        Path()
          ..moveTo(126.0000, 39.4000)
          ..lineTo(126.5148, 41.4852)
          ..lineTo(128.6000, 42.0000)
          ..lineTo(126.5148, 42.5148)
          ..lineTo(126.0000, 44.6000)
          ..lineTo(125.4852, 42.5148)
          ..lineTo(123.4000, 42.0000)
          ..lineTo(125.4852, 41.4852)
          ..close(),
        Color(0xAAC3BDFF),
        null,
        1,
        null,
      ),
      _VectorLayer(
        Path()
          ..moveTo(229.0000, 51.4000)
          ..lineTo(229.5148, 53.4852)
          ..lineTo(231.6000, 54.0000)
          ..lineTo(229.5148, 54.5148)
          ..lineTo(229.0000, 56.6000)
          ..lineTo(228.4852, 54.5148)
          ..lineTo(226.4000, 54.0000)
          ..lineTo(228.4852, 53.4852)
          ..close(),
        Color(0xAAC3BDFF),
        null,
        1,
        null,
      ),
      _VectorLayer(
        Path()
          ..moveTo(361.0000, 123.4000)
          ..lineTo(361.5148, 125.4852)
          ..lineTo(363.6000, 126.0000)
          ..lineTo(361.5148, 126.5148)
          ..lineTo(361.0000, 128.6000)
          ..lineTo(360.4852, 126.5148)
          ..lineTo(358.4000, 126.0000)
          ..lineTo(360.4852, 125.4852)
          ..close(),
        Color(0xAAC3BDFF),
        null,
        1,
        null,
      ),
      _VectorLayer(
        Path()
          ..moveTo(166.0000, 101.4000)
          ..lineTo(166.5148, 103.4852)
          ..lineTo(168.6000, 104.0000)
          ..lineTo(166.5148, 104.5148)
          ..lineTo(166.0000, 106.6000)
          ..lineTo(165.4852, 104.5148)
          ..lineTo(163.4000, 104.0000)
          ..lineTo(165.4852, 103.4852)
          ..close(),
        Color(0xAAC3BDFF),
        null,
        1,
        null,
      ),
      _VectorLayer(
        Path()
          ..moveTo(262.0000, 19.4000)
          ..lineTo(262.5148, 21.4852)
          ..lineTo(264.6000, 22.0000)
          ..lineTo(262.5148, 22.5148)
          ..lineTo(262.0000, 24.6000)
          ..lineTo(261.4852, 22.5148)
          ..lineTo(259.4000, 22.0000)
          ..lineTo(261.4852, 21.4852)
          ..close(),
        Color(0xAAC3BDFF),
        null,
        1,
        null,
      ),
      _VectorLayer(
        Path()
          ..moveTo(359.0000, 187.0000)
          ..cubicTo(345.0000, 196.0000, 347.0000, 218.0000, 359.0000, 225.0000)
          ..cubicTo(372.0000, 214.0000, 370.0000, 199.0000, 359.0000, 187.0000)
          ..close(),
        Color(0xFF18265B),
        null,
        1,
        null,
      ),
      _VectorLayer(
        Path()
          ..moveTo(359.0000, 208.0000)
          ..lineTo(359.0000, 249.0000),
        null,
        Color(0xFF36457B),
        2,
        null,
      ),
      _VectorLayer(
        Path()
          ..moveTo(377.0000, 200.0000)
          ..cubicTo(363.0000, 209.0000, 365.0000, 231.0000, 377.0000, 238.0000)
          ..cubicTo(390.0000, 227.0000, 388.0000, 212.0000, 377.0000, 200.0000)
          ..close(),
        Color(0xFF18265B),
        null,
        1,
        null,
      ),
      _VectorLayer(
        Path()
          ..moveTo(377.0000, 221.0000)
          ..lineTo(377.0000, 262.0000),
        null,
        Color(0xFF36457B),
        2,
        null,
      ),
      _VectorLayer(
        Path()
          ..moveTo(347.0000, 215.0000)
          ..cubicTo(333.0000, 224.0000, 335.0000, 246.0000, 347.0000, 253.0000)
          ..cubicTo(360.0000, 242.0000, 358.0000, 227.0000, 347.0000, 215.0000)
          ..close(),
        Color(0xFF18265B),
        null,
        1,
        null,
      ),
      _VectorLayer(
        Path()
          ..moveTo(347.0000, 236.0000)
          ..lineTo(347.0000, 277.0000),
        null,
        Color(0xFF36457B),
        2,
        null,
      ),
    ],
  ),
  'illustrations/review_plant': (
    const Size(400, 280),
    [
      _VectorLayer(
        Path()
          ..moveTo(385.0000, 72.0000)
          ..cubicTo(385.0000, 110.6599, 353.6599, 142.0000, 315.0000, 142.0000)
          ..cubicTo(276.3401, 142.0000, 245.0000, 110.6599, 245.0000, 72.0000)
          ..cubicTo(245.0000, 33.3401, 276.3401, 2.0000, 315.0000, 2.0000)
          ..cubicTo(353.6599, 2.0000, 385.0000, 33.3401, 385.0000, 72.0000)
          ..close(),
        Color(0x1A8C69E5),
        null,
        1,
        null,
      ),
      _VectorLayer(
        Path()
          ..moveTo(363.0000, 72.0000)
          ..cubicTo(363.0000, 98.5097, 341.5097, 120.0000, 315.0000, 120.0000)
          ..cubicTo(288.4903, 120.0000, 267.0000, 98.5097, 267.0000, 72.0000)
          ..cubicTo(267.0000, 45.4903, 288.4903, 24.0000, 315.0000, 24.0000)
          ..cubicTo(341.5097, 24.0000, 363.0000, 45.4903, 363.0000, 72.0000)
          ..close(),
        Color(0x24BFA0FF),
        null,
        1,
        null,
      ),
      _VectorLayer(
        Path()
          ..moveTo(345.0000, 72.0000)
          ..cubicTo(345.0000, 88.5685, 331.5685, 102.0000, 315.0000, 102.0000)
          ..cubicTo(298.4315, 102.0000, 285.0000, 88.5685, 285.0000, 72.0000)
          ..cubicTo(285.0000, 55.4315, 298.4315, 42.0000, 315.0000, 42.0000)
          ..cubicTo(331.5685, 42.0000, 345.0000, 55.4315, 345.0000, 72.0000)
          ..close(),
        Color(0xFFD8BCFF),
        null,
        1,
        [Color(0xFFF4DFFF), Color(0xFFA28DEA)],
      ),
      _VectorLayer(
        Path()
          ..moveTo(0.0000, 229.0000)
          ..lineTo(95.0000, 176.0000)
          ..lineTo(192.0000, 235.0000)
          ..lineTo(290.0000, 199.0000)
          ..lineTo(400.0000, 245.0000)
          ..lineTo(400.0000, 280.0000)
          ..lineTo(0.0000, 280.0000)
          ..close(),
        Color(0xFF343567),
        null,
        1,
        null,
      ),
      _VectorLayer(
        Path()
          ..moveTo(306.0000, 280.0000)
          ..cubicTo(311.0000, 217.0000, 309.0000, 161.0000, 334.0000, 102.0000),
        null,
        Color(0xFFA596EC),
        3,
        null,
      ),
      _VectorLayer(
        Path()
          ..moveTo(310.0000, 242.0000)
          ..cubicTo(272.0000, 234.0000, 258.0000, 199.0000, 268.0000, 179.0000)
          ..cubicTo(300.0000, 193.0000, 306.0000, 212.0000, 310.0000, 242.0000)
          ..close(),
        Color(0xFF51469B),
        null,
        1,
        [Color(0xFF7461C7), Color(0xFF2F316C)],
      ),
      _VectorLayer(
        Path()
          ..moveTo(310.0000, 242.0000)
          ..quadraticBezierTo(289.0000, 212.0000, 268.0000, 179.0000),
        null,
        Color(0xFF8E7AD9),
        1,
        null,
      ),
      _VectorLayer(
        Path()
          ..moveTo(314.0000, 219.0000)
          ..cubicTo(352.0000, 211.0000, 366.0000, 176.0000, 356.0000, 156.0000)
          ..cubicTo(324.0000, 170.0000, 318.0000, 189.0000, 314.0000, 219.0000)
          ..close(),
        Color(0xFF51469B),
        null,
        1,
        [Color(0xFF7461C7), Color(0xFF2F316C)],
      ),
      _VectorLayer(
        Path()
          ..moveTo(314.0000, 219.0000)
          ..quadraticBezierTo(335.0000, 189.0000, 356.0000, 156.0000),
        null,
        Color(0xFF8E7AD9),
        1,
        null,
      ),
      _VectorLayer(
        Path()
          ..moveTo(315.0000, 192.0000)
          ..cubicTo(277.0000, 184.0000, 263.0000, 149.0000, 273.0000, 129.0000)
          ..cubicTo(305.0000, 143.0000, 311.0000, 162.0000, 315.0000, 192.0000)
          ..close(),
        Color(0xFF51469B),
        null,
        1,
        [Color(0xFF7461C7), Color(0xFF2F316C)],
      ),
      _VectorLayer(
        Path()
          ..moveTo(315.0000, 192.0000)
          ..quadraticBezierTo(294.0000, 162.0000, 273.0000, 129.0000),
        null,
        Color(0xFF8E7AD9),
        1,
        null,
      ),
      _VectorLayer(
        Path()
          ..moveTo(322.0000, 166.0000)
          ..cubicTo(360.0000, 158.0000, 374.0000, 123.0000, 364.0000, 103.0000)
          ..cubicTo(332.0000, 117.0000, 326.0000, 136.0000, 322.0000, 166.0000)
          ..close(),
        Color(0xFF51469B),
        null,
        1,
        [Color(0xFF7461C7), Color(0xFF2F316C)],
      ),
      _VectorLayer(
        Path()
          ..moveTo(322.0000, 166.0000)
          ..quadraticBezierTo(343.0000, 136.0000, 364.0000, 103.0000),
        null,
        Color(0xFF8E7AD9),
        1,
        null,
      ),
      _VectorLayer(
        Path()
          ..moveTo(328.0000, 139.0000)
          ..cubicTo(290.0000, 131.0000, 276.0000, 96.0000, 286.0000, 76.0000)
          ..cubicTo(318.0000, 90.0000, 324.0000, 109.0000, 328.0000, 139.0000)
          ..close(),
        Color(0xFF51469B),
        null,
        1,
        [Color(0xFF7461C7), Color(0xFF2F316C)],
      ),
      _VectorLayer(
        Path()
          ..moveTo(328.0000, 139.0000)
          ..quadraticBezierTo(307.0000, 109.0000, 286.0000, 76.0000),
        null,
        Color(0xFF8E7AD9),
        1,
        null,
      ),
      _VectorLayer(
        Path()
          ..moveTo(36.0000, 51.0000)
          ..lineTo(36.5940, 53.4060)
          ..lineTo(39.0000, 54.0000)
          ..lineTo(36.5940, 54.5940)
          ..lineTo(36.0000, 57.0000)
          ..lineTo(35.4060, 54.5940)
          ..lineTo(33.0000, 54.0000)
          ..lineTo(35.4060, 53.4060)
          ..close(),
        Color(0xFFC9BDFF),
        null,
        1,
        null,
      ),
      _VectorLayer(
        Path()
          ..moveTo(179.0000, 77.0000)
          ..lineTo(179.5940, 79.4060)
          ..lineTo(182.0000, 80.0000)
          ..lineTo(179.5940, 80.5940)
          ..lineTo(179.0000, 83.0000)
          ..lineTo(178.4060, 80.5940)
          ..lineTo(176.0000, 80.0000)
          ..lineTo(178.4060, 79.4060)
          ..close(),
        Color(0xFFC9BDFF),
        null,
        1,
        null,
      ),
      _VectorLayer(
        Path()
          ..moveTo(255.0000, 25.0000)
          ..lineTo(255.5940, 27.4060)
          ..lineTo(258.0000, 28.0000)
          ..lineTo(255.5940, 28.5940)
          ..lineTo(255.0000, 31.0000)
          ..lineTo(254.4060, 28.5940)
          ..lineTo(252.0000, 28.0000)
          ..lineTo(254.4060, 27.4060)
          ..close(),
        Color(0xFFC9BDFF),
        null,
        1,
        null,
      ),
    ],
  ),
  'illustrations/empty_review_box': (
    const Size(320, 260),
    [
      _VectorLayer(
        Path()
          ..moveTo(255.0000, 126.0000)
          ..cubicTo(255.0000, 178.4671, 212.4671, 221.0000, 160.0000, 221.0000)
          ..cubicTo(107.5329, 221.0000, 65.0000, 178.4671, 65.0000, 126.0000)
          ..cubicTo(65.0000, 73.5329, 107.5329, 31.0000, 160.0000, 31.0000)
          ..cubicTo(212.4671, 31.0000, 255.0000, 73.5329, 255.0000, 126.0000)
          ..close(),
        Color(0x107661E5),
        null,
        1,
        null,
      ),
      _VectorLayer(
        Path()
          ..moveTo(221.0000, 126.0000)
          ..cubicTo(221.0000, 159.6894, 193.6894, 187.0000, 160.0000, 187.0000)
          ..cubicTo(126.3106, 187.0000, 99.0000, 159.6894, 99.0000, 126.0000)
          ..cubicTo(99.0000, 92.3106, 126.3106, 65.0000, 160.0000, 65.0000)
          ..cubicTo(193.6894, 65.0000, 221.0000, 92.3106, 221.0000, 126.0000)
          ..close(),
        Color(0x157661E5),
        null,
        1,
        null,
      ),
      _VectorLayer(
        Path()
          ..moveTo(34.0000, 226.0000)
          ..lineTo(98.0000, 194.0000)
          ..lineTo(164.0000, 218.0000)
          ..lineTo(233.0000, 186.0000)
          ..lineTo(320.0000, 233.0000)
          ..lineTo(320.0000, 260.0000)
          ..lineTo(0.0000, 260.0000)
          ..close(),
        Color(0x3343416A),
        null,
        1,
        null,
      ),
      _VectorLayer(
        Path()
          ..moveTo(96.0000, 128.0000)
          ..lineTo(160.0000, 155.0000)
          ..lineTo(160.0000, 218.0000)
          ..lineTo(96.0000, 187.0000)
          ..close(),
        Color(0xFF6552AE),
        null,
        1,
        [Color(0xFF8E76EA), Color(0xFF473C83)],
      ),
      _VectorLayer(
        Path()
          ..moveTo(160.0000, 155.0000)
          ..lineTo(224.0000, 128.0000)
          ..lineTo(224.0000, 187.0000)
          ..lineTo(160.0000, 218.0000)
          ..close(),
        Color(0xFF58468D),
        null,
        1,
        [Color(0xFF8470CB), Color(0xFF343262)],
      ),
      _VectorLayer(
        Path()
          ..moveTo(96.0000, 128.0000)
          ..lineTo(160.0000, 102.0000)
          ..lineTo(224.0000, 128.0000)
          ..lineTo(160.0000, 155.0000)
          ..close(),
        Color(0xFF433664),
        Color(0xFFCAB2FF),
        1.2,
        null,
      ),
      _VectorLayer(
        Path()
          ..moveTo(96.0000, 128.0000)
          ..lineTo(77.0000, 157.0000)
          ..lineTo(141.0000, 182.0000)
          ..lineTo(160.0000, 155.0000)
          ..close(),
        Color(0xFF9B87EB),
        null,
        1,
        [Color(0xFFB8A7FC), Color(0xFF7661C1)],
      ),
      _VectorLayer(
        Path()
          ..moveTo(160.0000, 155.0000)
          ..lineTo(182.0000, 181.0000)
          ..lineTo(245.0000, 152.0000)
          ..lineTo(224.0000, 128.0000)
          ..close(),
        Color(0xFF8D7AE1),
        null,
        1,
        [Color(0xFFC0AAFF), Color(0xFF7464BA)],
      ),
      _VectorLayer(
        Path()
          ..moveTo(96.0000, 128.0000)
          ..lineTo(116.0000, 94.0000)
          ..lineTo(160.0000, 102.0000)
          ..lineTo(160.0000, 155.0000)
          ..close(),
        Color(0xFF6D5FB8),
        Color(0xFFC6ABFF),
        1,
        null,
      ),
      _VectorLayer(
        Path()
          ..moveTo(160.0000, 102.0000)
          ..lineTo(203.0000, 95.0000)
          ..lineTo(224.0000, 128.0000)
          ..lineTo(160.0000, 155.0000)
          ..close(),
        Color(0xFF806FCD),
        Color(0xFFC6ABFF),
        1,
        null,
      ),
      _VectorLayer(
        Path()
          ..moveTo(72.0000, 98.0000)
          ..lineTo(72.9899, 102.0101)
          ..lineTo(77.0000, 103.0000)
          ..lineTo(72.9899, 103.9899)
          ..lineTo(72.0000, 108.0000)
          ..lineTo(71.0101, 103.9899)
          ..lineTo(67.0000, 103.0000)
          ..lineTo(71.0101, 102.0101)
          ..close(),
        Color(0xFFC5B9FF),
        null,
        1,
        null,
      ),
      _VectorLayer(
        Path()
          ..moveTo(243.0000, 83.0000)
          ..lineTo(244.1879, 87.8121)
          ..lineTo(249.0000, 89.0000)
          ..lineTo(244.1879, 90.1879)
          ..lineTo(243.0000, 95.0000)
          ..lineTo(241.8121, 90.1879)
          ..lineTo(237.0000, 89.0000)
          ..lineTo(241.8121, 87.8121)
          ..close(),
        Color(0xFFC5B9FF),
        null,
        1,
        null,
      ),
      _VectorLayer(
        Path()
          ..moveTo(263.0000, 153.0000)
          ..lineTo(263.5940, 155.4060)
          ..lineTo(266.0000, 156.0000)
          ..lineTo(263.5940, 156.5940)
          ..lineTo(263.0000, 159.0000)
          ..lineTo(262.4060, 156.5940)
          ..lineTo(260.0000, 156.0000)
          ..lineTo(262.4060, 155.4060)
          ..close(),
        Color(0xFFC5B9FF),
        null,
        1,
        null,
      ),
      _VectorLayer(
        Path()
          ..moveTo(127.0000, 66.0000)
          ..lineTo(127.5940, 68.4060)
          ..lineTo(130.0000, 69.0000)
          ..lineTo(127.5940, 69.5940)
          ..lineTo(127.0000, 72.0000)
          ..lineTo(126.4060, 69.5940)
          ..lineTo(124.0000, 69.0000)
          ..lineTo(126.4060, 68.4060)
          ..close(),
        Color(0xFFC5B9FF),
        null,
        1,
        null,
      ),
    ],
  ),
  'category_icons/daily': (
    const Size(64, 64),
    [
      _VectorLayer(
        Path()
          ..moveTo(18.0000, 1.0000)
          ..lineTo(46.0000, 1.0000)
          ..quadraticBezierTo(63.0000, 1.0000, 63.0000, 18.0000)
          ..lineTo(63.0000, 46.0000)
          ..quadraticBezierTo(63.0000, 63.0000, 46.0000, 63.0000)
          ..lineTo(18.0000, 63.0000)
          ..quadraticBezierTo(1.0000, 63.0000, 1.0000, 46.0000)
          ..lineTo(1.0000, 18.0000)
          ..quadraticBezierTo(1.0000, 1.0000, 18.0000, 1.0000)
          ..close(),
        Color(0xFF5441AC),
        null,
        1,
        [Color(0xFF6369D2), Color(0xFF303D80)],
      ),
      _VectorLayer(
        Path()
          ..moveTo(18.0000, 1.0000)
          ..lineTo(46.0000, 1.0000)
          ..quadraticBezierTo(63.0000, 1.0000, 63.0000, 18.0000)
          ..lineTo(63.0000, 46.0000)
          ..quadraticBezierTo(63.0000, 63.0000, 46.0000, 63.0000)
          ..lineTo(18.0000, 63.0000)
          ..quadraticBezierTo(1.0000, 63.0000, 1.0000, 46.0000)
          ..lineTo(1.0000, 18.0000)
          ..quadraticBezierTo(1.0000, 1.0000, 18.0000, 1.0000)
          ..close(),
        null,
        Color(0xFFA896E3),
        0.8,
        null,
      ),
      _VectorLayer(
        Path()
          ..moveTo(12.0000, 28.0000)
          ..lineTo(32.0000, 10.0000)
          ..lineTo(52.0000, 28.0000)
          ..lineTo(47.0000, 28.0000)
          ..lineTo(47.0000, 51.0000)
          ..lineTo(37.0000, 51.0000)
          ..lineTo(37.0000, 35.0000)
          ..lineTo(27.0000, 35.0000)
          ..lineTo(27.0000, 51.0000)
          ..lineTo(17.0000, 51.0000)
          ..lineTo(17.0000, 28.0000)
          ..close(),
        Color(0xFFE9E5FF),
        null,
        1,
        [Color(0xFFFFFFFF), Color(0xFFC2BAFF)],
      ),
    ],
  ),
  'category_icons/communication': (
    const Size(64, 64),
    [
      _VectorLayer(
        Path()
          ..moveTo(18.0000, 1.0000)
          ..lineTo(46.0000, 1.0000)
          ..quadraticBezierTo(63.0000, 1.0000, 63.0000, 18.0000)
          ..lineTo(63.0000, 46.0000)
          ..quadraticBezierTo(63.0000, 63.0000, 46.0000, 63.0000)
          ..lineTo(18.0000, 63.0000)
          ..quadraticBezierTo(1.0000, 63.0000, 1.0000, 46.0000)
          ..lineTo(1.0000, 18.0000)
          ..quadraticBezierTo(1.0000, 1.0000, 18.0000, 1.0000)
          ..close(),
        Color(0xFF5441AC),
        null,
        1,
        [Color(0xFFB9A5FF), Color(0xFF7661E5)],
      ),
      _VectorLayer(
        Path()
          ..moveTo(18.0000, 1.0000)
          ..lineTo(46.0000, 1.0000)
          ..quadraticBezierTo(63.0000, 1.0000, 63.0000, 18.0000)
          ..lineTo(63.0000, 46.0000)
          ..quadraticBezierTo(63.0000, 63.0000, 46.0000, 63.0000)
          ..lineTo(18.0000, 63.0000)
          ..quadraticBezierTo(1.0000, 63.0000, 1.0000, 46.0000)
          ..lineTo(1.0000, 18.0000)
          ..quadraticBezierTo(1.0000, 1.0000, 18.0000, 1.0000)
          ..close(),
        null,
        Color(0xFFA896E3),
        0.8,
        null,
      ),
      _VectorLayer(
        Path()
          ..moveTo(9.0000, 50.0000)
          ..cubicTo(9.0000, 27.0000, 34.0000, 27.0000, 34.0000, 50.0000)
          ..close()
          ..moveTo(32.0000, 36.0000)
          ..cubicTo(44.0000, 27.0000, 55.0000, 33.0000, 55.0000, 50.0000)
          ..lineTo(39.0000, 50.0000)
          ..close(),
        Color(0xFFE9E5FF),
        null,
        1,
        [Color(0xFFFFFFFF), Color(0xFFC2BAFF)],
      ),
      _VectorLayer(
        Path()
          ..moveTo(30.0000, 20.0000)
          ..cubicTo(30.0000, 24.9706, 25.9706, 29.0000, 21.0000, 29.0000)
          ..cubicTo(16.0294, 29.0000, 12.0000, 24.9706, 12.0000, 20.0000)
          ..cubicTo(12.0000, 15.0294, 16.0294, 11.0000, 21.0000, 11.0000)
          ..cubicTo(25.9706, 11.0000, 30.0000, 15.0294, 30.0000, 20.0000)
          ..close(),
        Color(0xFFF0EFFF),
        null,
        1,
        null,
      ),
      _VectorLayer(
        Path()
          ..moveTo(50.0000, 23.0000)
          ..cubicTo(50.0000, 26.8660, 46.8660, 30.0000, 43.0000, 30.0000)
          ..cubicTo(39.1340, 30.0000, 36.0000, 26.8660, 36.0000, 23.0000)
          ..cubicTo(36.0000, 19.1340, 39.1340, 16.0000, 43.0000, 16.0000)
          ..cubicTo(46.8660, 16.0000, 50.0000, 19.1340, 50.0000, 23.0000)
          ..close(),
        Color(0xFFD3CBFF),
        null,
        1,
        null,
      ),
    ],
  ),
  'category_icons/food': (
    const Size(64, 64),
    [
      _VectorLayer(
        Path()
          ..moveTo(18.0000, 1.0000)
          ..lineTo(46.0000, 1.0000)
          ..quadraticBezierTo(63.0000, 1.0000, 63.0000, 18.0000)
          ..lineTo(63.0000, 46.0000)
          ..quadraticBezierTo(63.0000, 63.0000, 46.0000, 63.0000)
          ..lineTo(18.0000, 63.0000)
          ..quadraticBezierTo(1.0000, 63.0000, 1.0000, 46.0000)
          ..lineTo(1.0000, 18.0000)
          ..quadraticBezierTo(1.0000, 1.0000, 18.0000, 1.0000)
          ..close(),
        Color(0xFF5441AC),
        null,
        1,
        [Color(0xFFB9A5FF), Color(0xFF7661E5)],
      ),
      _VectorLayer(
        Path()
          ..moveTo(18.0000, 1.0000)
          ..lineTo(46.0000, 1.0000)
          ..quadraticBezierTo(63.0000, 1.0000, 63.0000, 18.0000)
          ..lineTo(63.0000, 46.0000)
          ..quadraticBezierTo(63.0000, 63.0000, 46.0000, 63.0000)
          ..lineTo(18.0000, 63.0000)
          ..quadraticBezierTo(1.0000, 63.0000, 1.0000, 46.0000)
          ..lineTo(1.0000, 18.0000)
          ..quadraticBezierTo(1.0000, 1.0000, 18.0000, 1.0000)
          ..close(),
        null,
        Color(0xFFA896E3),
        0.8,
        null,
      ),
      _VectorLayer(
        Path()
          ..moveTo(14.0000, 13.0000)
          ..lineTo(14.0000, 29.0000)
          ..quadraticBezierTo(14.0000, 34.0000, 20.0000, 34.0000)
          ..lineTo(20.0000, 51.0000)
          ..lineTo(24.0000, 51.0000)
          ..lineTo(24.0000, 34.0000)
          ..quadraticBezierTo(30.0000, 34.0000, 30.0000, 29.0000)
          ..lineTo(30.0000, 13.0000)
          ..lineTo(26.0000, 13.0000)
          ..lineTo(26.0000, 27.0000)
          ..lineTo(24.0000, 27.0000)
          ..lineTo(24.0000, 13.0000)
          ..lineTo(20.0000, 13.0000)
          ..lineTo(20.0000, 27.0000)
          ..lineTo(18.0000, 27.0000)
          ..lineTo(18.0000, 13.0000)
          ..close()
          ..moveTo(43.0000, 13.0000)
          ..cubicTo(32.0000, 17.0000, 32.0000, 32.0000, 41.0000, 34.0000)
          ..lineTo(41.0000, 51.0000)
          ..lineTo(46.0000, 51.0000)
          ..lineTo(46.0000, 13.0000)
          ..close(),
        Color(0xFFE9E5FF),
        null,
        1,
        [Color(0xFFFFFFFF), Color(0xFFC2BAFF)],
      ),
    ],
  ),
  'category_icons/shopping': (
    const Size(64, 64),
    [
      _VectorLayer(
        Path()
          ..moveTo(18.0000, 1.0000)
          ..lineTo(46.0000, 1.0000)
          ..quadraticBezierTo(63.0000, 1.0000, 63.0000, 18.0000)
          ..lineTo(63.0000, 46.0000)
          ..quadraticBezierTo(63.0000, 63.0000, 46.0000, 63.0000)
          ..lineTo(18.0000, 63.0000)
          ..quadraticBezierTo(1.0000, 63.0000, 1.0000, 46.0000)
          ..lineTo(1.0000, 18.0000)
          ..quadraticBezierTo(1.0000, 1.0000, 18.0000, 1.0000)
          ..close(),
        Color(0xFF5441AC),
        null,
        1,
        [Color(0xFF6369D2), Color(0xFF303D80)],
      ),
      _VectorLayer(
        Path()
          ..moveTo(18.0000, 1.0000)
          ..lineTo(46.0000, 1.0000)
          ..quadraticBezierTo(63.0000, 1.0000, 63.0000, 18.0000)
          ..lineTo(63.0000, 46.0000)
          ..quadraticBezierTo(63.0000, 63.0000, 46.0000, 63.0000)
          ..lineTo(18.0000, 63.0000)
          ..quadraticBezierTo(1.0000, 63.0000, 1.0000, 46.0000)
          ..lineTo(1.0000, 18.0000)
          ..quadraticBezierTo(1.0000, 1.0000, 18.0000, 1.0000)
          ..close(),
        null,
        Color(0xFFA896E3),
        0.8,
        null,
      ),
      _VectorLayer(
        Path()
          ..moveTo(12.0000, 23.0000)
          ..lineTo(52.0000, 23.0000)
          ..lineTo(48.0000, 51.0000)
          ..lineTo(16.0000, 51.0000)
          ..close(),
        Color(0xFFE9E5FF),
        null,
        1,
        [Color(0xFFFFFFFF), Color(0xFFC2BAFF)],
      ),
      _VectorLayer(
        Path()
          ..moveTo(22.0000, 24.0000)
          ..lineTo(22.0000, 20.0000)
          ..cubicTo(22.0000, 7.0000, 42.0000, 7.0000, 42.0000, 20.0000)
          ..lineTo(42.0000, 24.0000),
        null,
        Color(0xFFE2DAFF),
        3,
        null,
      ),
    ],
  ),
  'category_icons/city': (
    const Size(64, 64),
    [
      _VectorLayer(
        Path()
          ..moveTo(18.0000, 1.0000)
          ..lineTo(46.0000, 1.0000)
          ..quadraticBezierTo(63.0000, 1.0000, 63.0000, 18.0000)
          ..lineTo(63.0000, 46.0000)
          ..quadraticBezierTo(63.0000, 63.0000, 46.0000, 63.0000)
          ..lineTo(18.0000, 63.0000)
          ..quadraticBezierTo(1.0000, 63.0000, 1.0000, 46.0000)
          ..lineTo(1.0000, 18.0000)
          ..quadraticBezierTo(1.0000, 1.0000, 18.0000, 1.0000)
          ..close(),
        Color(0xFF5441AC),
        null,
        1,
        [Color(0xFFB9A5FF), Color(0xFF7661E5)],
      ),
      _VectorLayer(
        Path()
          ..moveTo(18.0000, 1.0000)
          ..lineTo(46.0000, 1.0000)
          ..quadraticBezierTo(63.0000, 1.0000, 63.0000, 18.0000)
          ..lineTo(63.0000, 46.0000)
          ..quadraticBezierTo(63.0000, 63.0000, 46.0000, 63.0000)
          ..lineTo(18.0000, 63.0000)
          ..quadraticBezierTo(1.0000, 63.0000, 1.0000, 46.0000)
          ..lineTo(1.0000, 18.0000)
          ..quadraticBezierTo(1.0000, 1.0000, 18.0000, 1.0000)
          ..close(),
        null,
        Color(0xFFA896E3),
        0.8,
        null,
      ),
      _VectorLayer(
        Path()
          ..moveTo(10.0000, 52.0000)
          ..lineTo(10.0000, 26.0000)
          ..lineTo(22.0000, 26.0000)
          ..lineTo(22.0000, 12.0000)
          ..lineTo(42.0000, 12.0000)
          ..lineTo(42.0000, 31.0000)
          ..lineTo(54.0000, 31.0000)
          ..lineTo(54.0000, 52.0000)
          ..close(),
        Color(0xFFE9E5FF),
        null,
        1,
        [Color(0xFFFFFFFF), Color(0xFFC2BAFF)],
      ),
      _VectorLayer(
        Path()
          ..moveTo(28.5000, 22.0000)
          ..lineTo(30.5000, 22.0000)
          ..quadraticBezierTo(31.0000, 22.0000, 31.0000, 22.5000)
          ..lineTo(31.0000, 25.5000)
          ..quadraticBezierTo(31.0000, 26.0000, 30.5000, 26.0000)
          ..lineTo(28.5000, 26.0000)
          ..quadraticBezierTo(28.0000, 26.0000, 28.0000, 25.5000)
          ..lineTo(28.0000, 22.5000)
          ..quadraticBezierTo(28.0000, 22.0000, 28.5000, 22.0000)
          ..close(),
        Color(0xFF655BC1),
        null,
        1,
        null,
      ),
      _VectorLayer(
        Path()
          ..moveTo(36.5000, 22.0000)
          ..lineTo(38.5000, 22.0000)
          ..quadraticBezierTo(39.0000, 22.0000, 39.0000, 22.5000)
          ..lineTo(39.0000, 25.5000)
          ..quadraticBezierTo(39.0000, 26.0000, 38.5000, 26.0000)
          ..lineTo(36.5000, 26.0000)
          ..quadraticBezierTo(36.0000, 26.0000, 36.0000, 25.5000)
          ..lineTo(36.0000, 22.5000)
          ..quadraticBezierTo(36.0000, 22.0000, 36.5000, 22.0000)
          ..close(),
        Color(0xFF655BC1),
        null,
        1,
        null,
      ),
      _VectorLayer(
        Path()
          ..moveTo(28.5000, 31.0000)
          ..lineTo(30.5000, 31.0000)
          ..quadraticBezierTo(31.0000, 31.0000, 31.0000, 31.5000)
          ..lineTo(31.0000, 34.5000)
          ..quadraticBezierTo(31.0000, 35.0000, 30.5000, 35.0000)
          ..lineTo(28.5000, 35.0000)
          ..quadraticBezierTo(28.0000, 35.0000, 28.0000, 34.5000)
          ..lineTo(28.0000, 31.5000)
          ..quadraticBezierTo(28.0000, 31.0000, 28.5000, 31.0000)
          ..close(),
        Color(0xFF655BC1),
        null,
        1,
        null,
      ),
      _VectorLayer(
        Path()
          ..moveTo(36.5000, 31.0000)
          ..lineTo(38.5000, 31.0000)
          ..quadraticBezierTo(39.0000, 31.0000, 39.0000, 31.5000)
          ..lineTo(39.0000, 34.5000)
          ..quadraticBezierTo(39.0000, 35.0000, 38.5000, 35.0000)
          ..lineTo(36.5000, 35.0000)
          ..quadraticBezierTo(36.0000, 35.0000, 36.0000, 34.5000)
          ..lineTo(36.0000, 31.5000)
          ..quadraticBezierTo(36.0000, 31.0000, 36.5000, 31.0000)
          ..close(),
        Color(0xFF655BC1),
        null,
        1,
        null,
      ),
      _VectorLayer(
        Path()
          ..moveTo(28.5000, 41.0000)
          ..lineTo(30.5000, 41.0000)
          ..quadraticBezierTo(31.0000, 41.0000, 31.0000, 41.5000)
          ..lineTo(31.0000, 44.5000)
          ..quadraticBezierTo(31.0000, 45.0000, 30.5000, 45.0000)
          ..lineTo(28.5000, 45.0000)
          ..quadraticBezierTo(28.0000, 45.0000, 28.0000, 44.5000)
          ..lineTo(28.0000, 41.5000)
          ..quadraticBezierTo(28.0000, 41.0000, 28.5000, 41.0000)
          ..close(),
        Color(0xFF655BC1),
        null,
        1,
        null,
      ),
      _VectorLayer(
        Path()
          ..moveTo(36.5000, 41.0000)
          ..lineTo(38.5000, 41.0000)
          ..quadraticBezierTo(39.0000, 41.0000, 39.0000, 41.5000)
          ..lineTo(39.0000, 44.5000)
          ..quadraticBezierTo(39.0000, 45.0000, 38.5000, 45.0000)
          ..lineTo(36.5000, 45.0000)
          ..quadraticBezierTo(36.0000, 45.0000, 36.0000, 44.5000)
          ..lineTo(36.0000, 41.5000)
          ..quadraticBezierTo(36.0000, 41.0000, 36.5000, 41.0000)
          ..close(),
        Color(0xFF655BC1),
        null,
        1,
        null,
      ),
    ],
  ),
  'category_icons/travel': (
    const Size(64, 64),
    [
      _VectorLayer(
        Path()
          ..moveTo(18.0000, 1.0000)
          ..lineTo(46.0000, 1.0000)
          ..quadraticBezierTo(63.0000, 1.0000, 63.0000, 18.0000)
          ..lineTo(63.0000, 46.0000)
          ..quadraticBezierTo(63.0000, 63.0000, 46.0000, 63.0000)
          ..lineTo(18.0000, 63.0000)
          ..quadraticBezierTo(1.0000, 63.0000, 1.0000, 46.0000)
          ..lineTo(1.0000, 18.0000)
          ..quadraticBezierTo(1.0000, 1.0000, 18.0000, 1.0000)
          ..close(),
        Color(0xFF5441AC),
        null,
        1,
        [Color(0xFFB9A5FF), Color(0xFF7661E5)],
      ),
      _VectorLayer(
        Path()
          ..moveTo(18.0000, 1.0000)
          ..lineTo(46.0000, 1.0000)
          ..quadraticBezierTo(63.0000, 1.0000, 63.0000, 18.0000)
          ..lineTo(63.0000, 46.0000)
          ..quadraticBezierTo(63.0000, 63.0000, 46.0000, 63.0000)
          ..lineTo(18.0000, 63.0000)
          ..quadraticBezierTo(1.0000, 63.0000, 1.0000, 46.0000)
          ..lineTo(1.0000, 18.0000)
          ..quadraticBezierTo(1.0000, 1.0000, 18.0000, 1.0000)
          ..close(),
        null,
        Color(0xFFA896E3),
        0.8,
        null,
      ),
      _VectorLayer(
        Path()
          ..moveTo(30.0000, 10.0000)
          ..lineTo(35.0000, 10.0000)
          ..lineTo(37.0000, 29.0000)
          ..lineTo(53.0000, 38.0000)
          ..lineTo(53.0000, 43.0000)
          ..lineTo(37.0000, 37.0000)
          ..lineTo(36.0000, 49.0000)
          ..lineTo(43.0000, 53.0000)
          ..lineTo(43.0000, 56.0000)
          ..lineTo(32.0000, 52.0000)
          ..lineTo(21.0000, 56.0000)
          ..lineTo(21.0000, 53.0000)
          ..lineTo(28.0000, 49.0000)
          ..lineTo(27.0000, 37.0000)
          ..lineTo(11.0000, 43.0000)
          ..lineTo(11.0000, 38.0000)
          ..lineTo(28.0000, 29.0000)
          ..close(),
        Color(0xFFE9E5FF),
        null,
        1,
        [Color(0xFFFFFFFF), Color(0xFFC2BAFF)],
      ),
    ],
  ),
  'category_icons/work_study': (
    const Size(64, 64),
    [
      _VectorLayer(
        Path()
          ..moveTo(18.0000, 1.0000)
          ..lineTo(46.0000, 1.0000)
          ..quadraticBezierTo(63.0000, 1.0000, 63.0000, 18.0000)
          ..lineTo(63.0000, 46.0000)
          ..quadraticBezierTo(63.0000, 63.0000, 46.0000, 63.0000)
          ..lineTo(18.0000, 63.0000)
          ..quadraticBezierTo(1.0000, 63.0000, 1.0000, 46.0000)
          ..lineTo(1.0000, 18.0000)
          ..quadraticBezierTo(1.0000, 1.0000, 18.0000, 1.0000)
          ..close(),
        Color(0xFF5441AC),
        null,
        1,
        [Color(0xFF6369D2), Color(0xFF303D80)],
      ),
      _VectorLayer(
        Path()
          ..moveTo(18.0000, 1.0000)
          ..lineTo(46.0000, 1.0000)
          ..quadraticBezierTo(63.0000, 1.0000, 63.0000, 18.0000)
          ..lineTo(63.0000, 46.0000)
          ..quadraticBezierTo(63.0000, 63.0000, 46.0000, 63.0000)
          ..lineTo(18.0000, 63.0000)
          ..quadraticBezierTo(1.0000, 63.0000, 1.0000, 46.0000)
          ..lineTo(1.0000, 18.0000)
          ..quadraticBezierTo(1.0000, 1.0000, 18.0000, 1.0000)
          ..close(),
        null,
        Color(0xFFA896E3),
        0.8,
        null,
      ),
      _VectorLayer(
        Path()
          ..moveTo(13.0000, 17.0000)
          ..quadraticBezierTo(23.0000, 13.0000, 32.0000, 20.0000)
          ..quadraticBezierTo(42.0000, 13.0000, 51.0000, 17.0000)
          ..lineTo(51.0000, 48.0000)
          ..quadraticBezierTo(42.0000, 44.0000, 32.0000, 51.0000)
          ..quadraticBezierTo(23.0000, 44.0000, 13.0000, 48.0000)
          ..close(),
        Color(0xFFE9E5FF),
        null,
        1,
        [Color(0xFFFFFFFF), Color(0xFFC2BAFF)],
      ),
      _VectorLayer(
        Path()
          ..moveTo(32.0000, 20.0000)
          ..lineTo(32.0000, 51.0000),
        null,
        Color(0xFF6C5BC2),
        1.8,
        null,
      ),
    ],
  ),
  'category_icons/technology': (
    const Size(64, 64),
    [
      _VectorLayer(
        Path()
          ..moveTo(18.0000, 1.0000)
          ..lineTo(46.0000, 1.0000)
          ..quadraticBezierTo(63.0000, 1.0000, 63.0000, 18.0000)
          ..lineTo(63.0000, 46.0000)
          ..quadraticBezierTo(63.0000, 63.0000, 46.0000, 63.0000)
          ..lineTo(18.0000, 63.0000)
          ..quadraticBezierTo(1.0000, 63.0000, 1.0000, 46.0000)
          ..lineTo(1.0000, 18.0000)
          ..quadraticBezierTo(1.0000, 1.0000, 18.0000, 1.0000)
          ..close(),
        Color(0xFF5441AC),
        null,
        1,
        [Color(0xFFB9A5FF), Color(0xFF7661E5)],
      ),
      _VectorLayer(
        Path()
          ..moveTo(18.0000, 1.0000)
          ..lineTo(46.0000, 1.0000)
          ..quadraticBezierTo(63.0000, 1.0000, 63.0000, 18.0000)
          ..lineTo(63.0000, 46.0000)
          ..quadraticBezierTo(63.0000, 63.0000, 46.0000, 63.0000)
          ..lineTo(18.0000, 63.0000)
          ..quadraticBezierTo(1.0000, 63.0000, 1.0000, 46.0000)
          ..lineTo(1.0000, 18.0000)
          ..quadraticBezierTo(1.0000, 1.0000, 18.0000, 1.0000)
          ..close(),
        null,
        Color(0xFFA896E3),
        0.8,
        null,
      ),
      _VectorLayer(
        Path()
          ..moveTo(11.0000, 14.0000)
          ..lineTo(53.0000, 14.0000)
          ..lineTo(53.0000, 43.0000)
          ..lineTo(35.0000, 43.0000)
          ..lineTo(35.0000, 49.0000)
          ..lineTo(44.0000, 49.0000)
          ..lineTo(44.0000, 53.0000)
          ..lineTo(20.0000, 53.0000)
          ..lineTo(20.0000, 49.0000)
          ..lineTo(29.0000, 49.0000)
          ..lineTo(29.0000, 43.0000)
          ..lineTo(11.0000, 43.0000)
          ..close(),
        Color(0xFFE9E5FF),
        null,
        1,
        [Color(0xFFFFFFFF), Color(0xFFC2BAFF)],
      ),
      _VectorLayer(
        Path()
          ..moveTo(17.0000, 19.0000)
          ..lineTo(47.0000, 19.0000)
          ..quadraticBezierTo(48.0000, 19.0000, 48.0000, 20.0000)
          ..lineTo(48.0000, 36.0000)
          ..quadraticBezierTo(48.0000, 37.0000, 47.0000, 37.0000)
          ..lineTo(17.0000, 37.0000)
          ..quadraticBezierTo(16.0000, 37.0000, 16.0000, 36.0000)
          ..lineTo(16.0000, 20.0000)
          ..quadraticBezierTo(16.0000, 19.0000, 17.0000, 19.0000)
          ..close(),
        Color(0xFF49477D),
        null,
        1,
        null,
      ),
    ],
  ),
  'category_icons/nature': (
    const Size(64, 64),
    [
      _VectorLayer(
        Path()
          ..moveTo(18.0000, 1.0000)
          ..lineTo(46.0000, 1.0000)
          ..quadraticBezierTo(63.0000, 1.0000, 63.0000, 18.0000)
          ..lineTo(63.0000, 46.0000)
          ..quadraticBezierTo(63.0000, 63.0000, 46.0000, 63.0000)
          ..lineTo(18.0000, 63.0000)
          ..quadraticBezierTo(1.0000, 63.0000, 1.0000, 46.0000)
          ..lineTo(1.0000, 18.0000)
          ..quadraticBezierTo(1.0000, 1.0000, 18.0000, 1.0000)
          ..close(),
        Color(0xFF5441AC),
        null,
        1,
        [Color(0xFFB9A5FF), Color(0xFF7661E5)],
      ),
      _VectorLayer(
        Path()
          ..moveTo(18.0000, 1.0000)
          ..lineTo(46.0000, 1.0000)
          ..quadraticBezierTo(63.0000, 1.0000, 63.0000, 18.0000)
          ..lineTo(63.0000, 46.0000)
          ..quadraticBezierTo(63.0000, 63.0000, 46.0000, 63.0000)
          ..lineTo(18.0000, 63.0000)
          ..quadraticBezierTo(1.0000, 63.0000, 1.0000, 46.0000)
          ..lineTo(1.0000, 18.0000)
          ..quadraticBezierTo(1.0000, 1.0000, 18.0000, 1.0000)
          ..close(),
        null,
        Color(0xFFA896E3),
        0.8,
        null,
      ),
      _VectorLayer(
        Path()
          ..moveTo(16.0000, 48.0000)
          ..cubicTo(11.0000, 25.0000, 22.0000, 14.0000, 50.0000, 12.0000)
          ..cubicTo(51.0000, 39.0000, 38.0000, 50.0000, 16.0000, 48.0000)
          ..close(),
        Color(0xFFE9E5FF),
        null,
        1,
        [Color(0xFFFFFFFF), Color(0xFFC2BAFF)],
      ),
      _VectorLayer(
        Path()
          ..moveTo(17.0000, 48.0000)
          ..lineTo(40.0000, 23.0000),
        null,
        Color(0xFF7365BA),
        2.3,
        null,
      ),
    ],
  ),
  'category_icons/health': (
    const Size(64, 64),
    [
      _VectorLayer(
        Path()
          ..moveTo(18.0000, 1.0000)
          ..lineTo(46.0000, 1.0000)
          ..quadraticBezierTo(63.0000, 1.0000, 63.0000, 18.0000)
          ..lineTo(63.0000, 46.0000)
          ..quadraticBezierTo(63.0000, 63.0000, 46.0000, 63.0000)
          ..lineTo(18.0000, 63.0000)
          ..quadraticBezierTo(1.0000, 63.0000, 1.0000, 46.0000)
          ..lineTo(1.0000, 18.0000)
          ..quadraticBezierTo(1.0000, 1.0000, 18.0000, 1.0000)
          ..close(),
        Color(0xFF5441AC),
        null,
        1,
        [Color(0xFF6369D2), Color(0xFF303D80)],
      ),
      _VectorLayer(
        Path()
          ..moveTo(18.0000, 1.0000)
          ..lineTo(46.0000, 1.0000)
          ..quadraticBezierTo(63.0000, 1.0000, 63.0000, 18.0000)
          ..lineTo(63.0000, 46.0000)
          ..quadraticBezierTo(63.0000, 63.0000, 46.0000, 63.0000)
          ..lineTo(18.0000, 63.0000)
          ..quadraticBezierTo(1.0000, 63.0000, 1.0000, 46.0000)
          ..lineTo(1.0000, 18.0000)
          ..quadraticBezierTo(1.0000, 1.0000, 18.0000, 1.0000)
          ..close(),
        null,
        Color(0xFFA896E3),
        0.8,
        null,
      ),
      _VectorLayer(
        Path()
          ..moveTo(25.0000, 13.0000)
          ..lineTo(39.0000, 13.0000)
          ..lineTo(39.0000, 25.0000)
          ..lineTo(51.0000, 25.0000)
          ..lineTo(51.0000, 39.0000)
          ..lineTo(39.0000, 39.0000)
          ..lineTo(39.0000, 51.0000)
          ..lineTo(25.0000, 51.0000)
          ..lineTo(25.0000, 39.0000)
          ..lineTo(13.0000, 39.0000)
          ..lineTo(13.0000, 25.0000)
          ..lineTo(25.0000, 25.0000)
          ..close(),
        Color(0xFFE9E5FF),
        null,
        1,
        [Color(0xFFFFFFFF), Color(0xFFC2BAFF)],
      ),
    ],
  ),
  'category_icons/leisure': (
    const Size(64, 64),
    [
      _VectorLayer(
        Path()
          ..moveTo(18.0000, 1.0000)
          ..lineTo(46.0000, 1.0000)
          ..quadraticBezierTo(63.0000, 1.0000, 63.0000, 18.0000)
          ..lineTo(63.0000, 46.0000)
          ..quadraticBezierTo(63.0000, 63.0000, 46.0000, 63.0000)
          ..lineTo(18.0000, 63.0000)
          ..quadraticBezierTo(1.0000, 63.0000, 1.0000, 46.0000)
          ..lineTo(1.0000, 18.0000)
          ..quadraticBezierTo(1.0000, 1.0000, 18.0000, 1.0000)
          ..close(),
        Color(0xFF5441AC),
        null,
        1,
        [Color(0xFFB9A5FF), Color(0xFF7661E5)],
      ),
      _VectorLayer(
        Path()
          ..moveTo(18.0000, 1.0000)
          ..lineTo(46.0000, 1.0000)
          ..quadraticBezierTo(63.0000, 1.0000, 63.0000, 18.0000)
          ..lineTo(63.0000, 46.0000)
          ..quadraticBezierTo(63.0000, 63.0000, 46.0000, 63.0000)
          ..lineTo(18.0000, 63.0000)
          ..quadraticBezierTo(1.0000, 63.0000, 1.0000, 46.0000)
          ..lineTo(1.0000, 18.0000)
          ..quadraticBezierTo(1.0000, 1.0000, 18.0000, 1.0000)
          ..close(),
        null,
        Color(0xFFA896E3),
        0.8,
        null,
      ),
      _VectorLayer(
        Path()
          ..moveTo(14.0000, 17.0000)
          ..lineTo(14.0000, 41.0000)
          ..cubicTo(0.0000, 39.0000, 1.0000, 57.0000, 15.0000, 52.0000)
          ..quadraticBezierTo(21.0000, 50.0000, 21.0000, 44.0000)
          ..lineTo(21.0000, 23.0000)
          ..lineTo(46.0000, 17.0000)
          ..lineTo(46.0000, 35.0000)
          ..cubicTo(32.0000, 33.0000, 33.0000, 51.0000, 47.0000, 46.0000)
          ..quadraticBezierTo(53.0000, 44.0000, 53.0000, 38.0000)
          ..lineTo(53.0000, 9.0000)
          ..close(),
        Color(0xFFE9E5FF),
        null,
        1,
        [Color(0xFFFFFFFF), Color(0xFFC2BAFF)],
      ),
    ],
  ),
  'category_icons/thoughts': (
    const Size(64, 64),
    [
      _VectorLayer(
        Path()
          ..moveTo(18.0000, 1.0000)
          ..lineTo(46.0000, 1.0000)
          ..quadraticBezierTo(63.0000, 1.0000, 63.0000, 18.0000)
          ..lineTo(63.0000, 46.0000)
          ..quadraticBezierTo(63.0000, 63.0000, 46.0000, 63.0000)
          ..lineTo(18.0000, 63.0000)
          ..quadraticBezierTo(1.0000, 63.0000, 1.0000, 46.0000)
          ..lineTo(1.0000, 18.0000)
          ..quadraticBezierTo(1.0000, 1.0000, 18.0000, 1.0000)
          ..close(),
        Color(0xFF5441AC),
        null,
        1,
        [Color(0xFFB9A5FF), Color(0xFF7661E5)],
      ),
      _VectorLayer(
        Path()
          ..moveTo(18.0000, 1.0000)
          ..lineTo(46.0000, 1.0000)
          ..quadraticBezierTo(63.0000, 1.0000, 63.0000, 18.0000)
          ..lineTo(63.0000, 46.0000)
          ..quadraticBezierTo(63.0000, 63.0000, 46.0000, 63.0000)
          ..lineTo(18.0000, 63.0000)
          ..quadraticBezierTo(1.0000, 63.0000, 1.0000, 46.0000)
          ..lineTo(1.0000, 18.0000)
          ..quadraticBezierTo(1.0000, 1.0000, 18.0000, 1.0000)
          ..close(),
        null,
        Color(0xFFA896E3),
        0.8,
        null,
      ),
      _VectorLayer(
        Path()
          ..moveTo(16.0000, 41.0000)
          ..cubicTo(8.0000, 31.0000, 13.0000, 12.0000, 32.0000, 12.0000)
          ..cubicTo(50.0000, 12.0000, 56.0000, 30.0000, 47.0000, 40.0000)
          ..lineTo(42.0000, 46.0000)
          ..lineTo(22.0000, 46.0000)
          ..close(),
        Color(0xFFE9E5FF),
        null,
        1,
        [Color(0xFFFFFFFF), Color(0xFFC2BAFF)],
      ),
      _VectorLayer(
        Path()
          ..moveTo(24.0000, 50.0000)
          ..lineTo(40.0000, 50.0000)
          ..quadraticBezierTo(41.0000, 50.0000, 41.0000, 51.0000)
          ..lineTo(41.0000, 52.0000)
          ..quadraticBezierTo(41.0000, 53.0000, 40.0000, 53.0000)
          ..lineTo(24.0000, 53.0000)
          ..quadraticBezierTo(23.0000, 53.0000, 23.0000, 52.0000)
          ..lineTo(23.0000, 51.0000)
          ..quadraticBezierTo(23.0000, 50.0000, 24.0000, 50.0000)
          ..close(),
        Color(0xFFE2DAFF),
        null,
        1,
        null,
      ),
      _VectorLayer(
        Path()
          ..moveTo(28.0000, 55.0000)
          ..lineTo(36.0000, 55.0000)
          ..quadraticBezierTo(37.0000, 55.0000, 37.0000, 56.0000)
          ..lineTo(37.0000, 57.0000)
          ..quadraticBezierTo(37.0000, 58.0000, 36.0000, 58.0000)
          ..lineTo(28.0000, 58.0000)
          ..quadraticBezierTo(27.0000, 58.0000, 27.0000, 57.0000)
          ..lineTo(27.0000, 56.0000)
          ..quadraticBezierTo(27.0000, 55.0000, 28.0000, 55.0000)
          ..close(),
        Color(0xFFC2BAFF),
        null,
        1,
        null,
      ),
    ],
  ),
  'ranks/rank_start': (
    const Size(200, 200),
    [
      _VectorLayer(
        Path()
          ..moveTo(180.0000, 93.0000)
          ..cubicTo(180.0000, 137.1828, 144.1828, 173.0000, 100.0000, 173.0000)
          ..cubicTo(55.8172, 173.0000, 20.0000, 137.1828, 20.0000, 93.0000)
          ..cubicTo(20.0000, 48.8172, 55.8172, 13.0000, 100.0000, 13.0000)
          ..cubicTo(144.1828, 13.0000, 180.0000, 48.8172, 180.0000, 93.0000)
          ..close(),
        Color(0x12AE85FF),
        null,
        1,
        null,
      ),
      _VectorLayer(
        Path()
          ..moveTo(64.0000, 128.0000)
          ..lineTo(85.0000, 128.0000)
          ..lineTo(91.0000, 188.0000)
          ..lineTo(69.0000, 173.0000)
          ..close(),
        Color(0xFF8470DC),
        null,
        1,
        [Color(0xFFCCADFF), Color(0xFF6645B5)],
      ),
      _VectorLayer(
        Path()
          ..moveTo(85.0000, 128.0000)
          ..lineTo(106.0000, 128.0000)
          ..lineTo(112.0000, 190.0000)
          ..lineTo(91.0000, 188.0000)
          ..close(),
        Color(0xFFB195FC),
        null,
        1,
        [Color(0xFFB9A5FF), Color(0xFF7661E5)],
      ),
      _VectorLayer(
        Path()
          ..moveTo(106.0000, 128.0000)
          ..lineTo(127.0000, 128.0000)
          ..lineTo(131.0000, 173.0000)
          ..lineTo(112.0000, 190.0000)
          ..close(),
        Color(0xFF7351C0),
        null,
        1,
        [Color(0xFF6369D2), Color(0xFF303D80)],
      ),
      _VectorLayer(
        Path()
          ..moveTo(100.0000, 25.0000)
          ..lineTo(125.2748, 55.2123)
          ..lineTo(161.8187, 69.9139)
          ..lineTo(140.8954, 103.2877)
          ..lineTo(138.2060, 142.5861)
          ..lineTo(100.0000, 133.0000)
          ..lineTo(61.7940, 142.5861)
          ..lineTo(59.1046, 103.2877)
          ..lineTo(38.1813, 69.9139)
          ..lineTo(74.7252, 55.2123)
          ..close(),
        Color(0xFFD3B8FF),
        Color(0xFFF4DEFF),
        1.5,
        [Color(0xFFD3B8FF), Color(0xFF8D6BA1)],
      ),
      _VectorLayer(
        Path()
          ..moveTo(100.0000, 25.0000)
          ..lineTo(125.2748, 55.2123)
          ..lineTo(119.3969, 63.3024)
          ..lineTo(100.0000, 41.0000)
          ..close(),
        Color(0xFFD3B8FF),
        null,
        1,
        null,
      ),
      _VectorLayer(
        Path()
          ..moveTo(125.2748, 55.2123)
          ..lineTo(161.8187, 69.9139)
          ..lineTo(146.6018, 74.8582)
          ..lineTo(119.3969, 63.3024)
          ..close(),
        Color(0xFFE6DCFF),
        null,
        1,
        null,
      ),
      _VectorLayer(
        Path()
          ..moveTo(161.8187, 69.9139)
          ..lineTo(140.8954, 103.2877)
          ..lineTo(131.3849, 100.1976)
          ..lineTo(146.6018, 74.8582)
          ..close(),
        Color(0xFF6155A4),
        null,
        1,
        null,
      ),
      _VectorLayer(
        Path()
          ..moveTo(140.8954, 103.2877)
          ..lineTo(138.2060, 142.5861)
          ..lineTo(128.8015, 129.6418)
          ..lineTo(131.3849, 100.1976)
          ..close(),
        Color(0xFFD3B8FF),
        null,
        1,
        null,
      ),
      _VectorLayer(
        Path()
          ..moveTo(138.2060, 142.5861)
          ..lineTo(100.0000, 133.0000)
          ..lineTo(100.0000, 123.0000)
          ..lineTo(128.8015, 129.6418)
          ..close(),
        Color(0xFFE6DCFF),
        null,
        1,
        null,
      ),
      _VectorLayer(
        Path()
          ..moveTo(100.0000, 133.0000)
          ..lineTo(61.7940, 142.5861)
          ..lineTo(71.1985, 129.6418)
          ..lineTo(100.0000, 123.0000)
          ..close(),
        Color(0xFF6155A4),
        null,
        1,
        null,
      ),
      _VectorLayer(
        Path()
          ..moveTo(61.7940, 142.5861)
          ..lineTo(59.1046, 103.2877)
          ..lineTo(68.6151, 100.1976)
          ..lineTo(71.1985, 129.6418)
          ..close(),
        Color(0xFFD3B8FF),
        null,
        1,
        null,
      ),
      _VectorLayer(
        Path()
          ..moveTo(59.1046, 103.2877)
          ..lineTo(38.1813, 69.9139)
          ..lineTo(53.3982, 74.8582)
          ..lineTo(68.6151, 100.1976)
          ..close(),
        Color(0xFFE6DCFF),
        null,
        1,
        null,
      ),
      _VectorLayer(
        Path()
          ..moveTo(38.1813, 69.9139)
          ..lineTo(74.7252, 55.2123)
          ..lineTo(80.6031, 63.3024)
          ..lineTo(53.3982, 74.8582)
          ..close(),
        Color(0xFF6155A4),
        null,
        1,
        null,
      ),
      _VectorLayer(
        Path()
          ..moveTo(74.7252, 55.2123)
          ..lineTo(100.0000, 25.0000)
          ..lineTo(100.0000, 41.0000)
          ..lineTo(80.6031, 63.3024)
          ..close(),
        Color(0xFFD3B8FF),
        null,
        1,
        null,
      ),
      _VectorLayer(
        Path()
          ..moveTo(100.0000, 41.0000)
          ..lineTo(119.3969, 63.3024)
          ..lineTo(146.6018, 74.8582)
          ..lineTo(131.3849, 100.1976)
          ..lineTo(128.8015, 129.6418)
          ..lineTo(100.0000, 123.0000)
          ..lineTo(71.1985, 129.6418)
          ..lineTo(68.6151, 100.1976)
          ..lineTo(53.3982, 74.8582)
          ..lineTo(80.6031, 63.3024)
          ..close(),
        Color(0xFF252A59),
        Color(0xFFD3B8FF),
        1.8,
        [Color(0xFF333B6D), Color(0xFF111B3A)],
      ),
      _VectorLayer(
        Path()
          ..moveTo(100.0000, 65.0000)
          ..lineTo(104.7518, 84.2482)
          ..lineTo(124.0000, 89.0000)
          ..lineTo(104.7518, 93.7518)
          ..lineTo(100.0000, 113.0000)
          ..lineTo(95.2482, 93.7518)
          ..lineTo(76.0000, 89.0000)
          ..lineTo(95.2482, 84.2482)
          ..close(),
        Color(0xFFF2E8FF),
        null,
        1,
        null,
      ),
      _VectorLayer(
        Path()
          ..moveTo(31.0000, 35.0000)
          ..lineTo(31.7920, 38.2080)
          ..lineTo(35.0000, 39.0000)
          ..lineTo(31.7920, 39.7920)
          ..lineTo(31.0000, 43.0000)
          ..lineTo(30.2080, 39.7920)
          ..lineTo(27.0000, 39.0000)
          ..lineTo(30.2080, 38.2080)
          ..close(),
        Color(0xFFD3B8FF),
        null,
        1,
        null,
      ),
      _VectorLayer(
        Path()
          ..moveTo(167.0000, 39.0000)
          ..lineTo(167.7920, 42.2080)
          ..lineTo(171.0000, 43.0000)
          ..lineTo(167.7920, 43.7920)
          ..lineTo(167.0000, 47.0000)
          ..lineTo(166.2080, 43.7920)
          ..lineTo(163.0000, 43.0000)
          ..lineTo(166.2080, 42.2080)
          ..close(),
        Color(0xFFD3B8FF),
        null,
        1,
        null,
      ),
      _VectorLayer(
        Path()
          ..moveTo(157.0000, 163.0000)
          ..lineTo(157.7920, 166.2080)
          ..lineTo(161.0000, 167.0000)
          ..lineTo(157.7920, 167.7920)
          ..lineTo(157.0000, 171.0000)
          ..lineTo(156.2080, 167.7920)
          ..lineTo(153.0000, 167.0000)
          ..lineTo(156.2080, 166.2080)
          ..close(),
        Color(0xFFD3B8FF),
        null,
        1,
        null,
      ),
    ],
  ),
  'ranks/rank_spark': (
    const Size(200, 200),
    [
      _VectorLayer(
        Path()
          ..moveTo(180.0000, 93.0000)
          ..cubicTo(180.0000, 137.1828, 144.1828, 173.0000, 100.0000, 173.0000)
          ..cubicTo(55.8172, 173.0000, 20.0000, 137.1828, 20.0000, 93.0000)
          ..cubicTo(20.0000, 48.8172, 55.8172, 13.0000, 100.0000, 13.0000)
          ..cubicTo(144.1828, 13.0000, 180.0000, 48.8172, 180.0000, 93.0000)
          ..close(),
        Color(0x12AE85FF),
        null,
        1,
        null,
      ),
      _VectorLayer(
        Path()
          ..moveTo(64.0000, 128.0000)
          ..lineTo(85.0000, 128.0000)
          ..lineTo(91.0000, 188.0000)
          ..lineTo(69.0000, 173.0000)
          ..close(),
        Color(0xFF8470DC),
        null,
        1,
        [Color(0xFFCCADFF), Color(0xFF6645B5)],
      ),
      _VectorLayer(
        Path()
          ..moveTo(85.0000, 128.0000)
          ..lineTo(106.0000, 128.0000)
          ..lineTo(112.0000, 190.0000)
          ..lineTo(91.0000, 188.0000)
          ..close(),
        Color(0xFFB195FC),
        null,
        1,
        [Color(0xFFB9A5FF), Color(0xFF7661E5)],
      ),
      _VectorLayer(
        Path()
          ..moveTo(106.0000, 128.0000)
          ..lineTo(127.0000, 128.0000)
          ..lineTo(131.0000, 173.0000)
          ..lineTo(112.0000, 190.0000)
          ..close(),
        Color(0xFF7351C0),
        null,
        1,
        [Color(0xFF6369D2), Color(0xFF303D80)],
      ),
      _VectorLayer(
        Path()
          ..moveTo(43.0000, 143.0000)
          ..quadraticBezierTo(17.0000, 135.0000, 31.0000, 116.0000)
          ..quadraticBezierTo(44.0000, 126.0000, 43.0000, 143.0000)
          ..close(),
        Color(0xFFFFDA86),
        null,
        1,
        [Color(0xFFFFDA86), Color(0xFF806147)],
      ),
      _VectorLayer(
        Path()
          ..moveTo(40.0000, 128.0000)
          ..quadraticBezierTo(14.0000, 120.0000, 28.0000, 101.0000)
          ..quadraticBezierTo(41.0000, 111.0000, 40.0000, 128.0000)
          ..close(),
        Color(0xFFFFDA86),
        null,
        1,
        [Color(0xFFFFDA86), Color(0xFF806147)],
      ),
      _VectorLayer(
        Path()
          ..moveTo(37.0000, 113.0000)
          ..quadraticBezierTo(11.0000, 105.0000, 25.0000, 86.0000)
          ..quadraticBezierTo(38.0000, 96.0000, 37.0000, 113.0000)
          ..close(),
        Color(0xFFFFDA86),
        null,
        1,
        [Color(0xFFFFDA86), Color(0xFF806147)],
      ),
      _VectorLayer(
        Path()
          ..moveTo(34.0000, 98.0000)
          ..quadraticBezierTo(8.0000, 90.0000, 22.0000, 71.0000)
          ..quadraticBezierTo(35.0000, 81.0000, 34.0000, 98.0000)
          ..close(),
        Color(0xFFFFDA86),
        null,
        1,
        [Color(0xFFFFDA86), Color(0xFF806147)],
      ),
      _VectorLayer(
        Path()
          ..moveTo(31.0000, 83.0000)
          ..quadraticBezierTo(5.0000, 75.0000, 19.0000, 56.0000)
          ..quadraticBezierTo(32.0000, 66.0000, 31.0000, 83.0000)
          ..close(),
        Color(0xFFFFDA86),
        null,
        1,
        [Color(0xFFFFDA86), Color(0xFF806147)],
      ),
      _VectorLayer(
        Path()
          ..moveTo(157.0000, 143.0000)
          ..quadraticBezierTo(183.0000, 135.0000, 169.0000, 116.0000)
          ..quadraticBezierTo(156.0000, 126.0000, 157.0000, 143.0000)
          ..close(),
        Color(0xFFFFDA86),
        null,
        1,
        [Color(0xFFFFDA86), Color(0xFF806147)],
      ),
      _VectorLayer(
        Path()
          ..moveTo(160.0000, 128.0000)
          ..quadraticBezierTo(186.0000, 120.0000, 172.0000, 101.0000)
          ..quadraticBezierTo(159.0000, 111.0000, 160.0000, 128.0000)
          ..close(),
        Color(0xFFFFDA86),
        null,
        1,
        [Color(0xFFFFDA86), Color(0xFF806147)],
      ),
      _VectorLayer(
        Path()
          ..moveTo(163.0000, 113.0000)
          ..quadraticBezierTo(189.0000, 105.0000, 175.0000, 86.0000)
          ..quadraticBezierTo(162.0000, 96.0000, 163.0000, 113.0000)
          ..close(),
        Color(0xFFFFDA86),
        null,
        1,
        [Color(0xFFFFDA86), Color(0xFF806147)],
      ),
      _VectorLayer(
        Path()
          ..moveTo(166.0000, 98.0000)
          ..quadraticBezierTo(192.0000, 90.0000, 178.0000, 71.0000)
          ..quadraticBezierTo(165.0000, 81.0000, 166.0000, 98.0000)
          ..close(),
        Color(0xFFFFDA86),
        null,
        1,
        [Color(0xFFFFDA86), Color(0xFF806147)],
      ),
      _VectorLayer(
        Path()
          ..moveTo(169.0000, 83.0000)
          ..quadraticBezierTo(195.0000, 75.0000, 181.0000, 56.0000)
          ..quadraticBezierTo(168.0000, 66.0000, 169.0000, 83.0000)
          ..close(),
        Color(0xFFFFDA86),
        null,
        1,
        [Color(0xFFFFDA86), Color(0xFF806147)],
      ),
      _VectorLayer(
        Path()
          ..moveTo(100.0000, 25.0000)
          ..lineTo(125.2748, 55.2123)
          ..lineTo(161.8187, 69.9139)
          ..lineTo(140.8954, 103.2877)
          ..lineTo(138.2060, 142.5861)
          ..lineTo(100.0000, 133.0000)
          ..lineTo(61.7940, 142.5861)
          ..lineTo(59.1046, 103.2877)
          ..lineTo(38.1813, 69.9139)
          ..lineTo(74.7252, 55.2123)
          ..close(),
        Color(0xFFFFDA86),
        Color(0xFFF4DEFF),
        1.5,
        [Color(0xFFFFDA86), Color(0xFFAE753D)],
      ),
      _VectorLayer(
        Path()
          ..moveTo(100.0000, 25.0000)
          ..lineTo(125.2748, 55.2123)
          ..lineTo(119.3969, 63.3024)
          ..lineTo(100.0000, 41.0000)
          ..close(),
        Color(0xFFFFDA86),
        null,
        1,
        null,
      ),
      _VectorLayer(
        Path()
          ..moveTo(125.2748, 55.2123)
          ..lineTo(161.8187, 69.9139)
          ..lineTo(146.6018, 74.8582)
          ..lineTo(119.3969, 63.3024)
          ..close(),
        Color(0xFFFFF1CF),
        null,
        1,
        null,
      ),
      _VectorLayer(
        Path()
          ..moveTo(161.8187, 69.9139)
          ..lineTo(140.8954, 103.2877)
          ..lineTo(131.3849, 100.1976)
          ..lineTo(146.6018, 74.8582)
          ..close(),
        Color(0xFF9E682E),
        null,
        1,
        null,
      ),
      _VectorLayer(
        Path()
          ..moveTo(140.8954, 103.2877)
          ..lineTo(138.2060, 142.5861)
          ..lineTo(128.8015, 129.6418)
          ..lineTo(131.3849, 100.1976)
          ..close(),
        Color(0xFFFFDA86),
        null,
        1,
        null,
      ),
      _VectorLayer(
        Path()
          ..moveTo(138.2060, 142.5861)
          ..lineTo(100.0000, 133.0000)
          ..lineTo(100.0000, 123.0000)
          ..lineTo(128.8015, 129.6418)
          ..close(),
        Color(0xFFFFF1CF),
        null,
        1,
        null,
      ),
      _VectorLayer(
        Path()
          ..moveTo(100.0000, 133.0000)
          ..lineTo(61.7940, 142.5861)
          ..lineTo(71.1985, 129.6418)
          ..lineTo(100.0000, 123.0000)
          ..close(),
        Color(0xFF9E682E),
        null,
        1,
        null,
      ),
      _VectorLayer(
        Path()
          ..moveTo(61.7940, 142.5861)
          ..lineTo(59.1046, 103.2877)
          ..lineTo(68.6151, 100.1976)
          ..lineTo(71.1985, 129.6418)
          ..close(),
        Color(0xFFFFDA86),
        null,
        1,
        null,
      ),
      _VectorLayer(
        Path()
          ..moveTo(59.1046, 103.2877)
          ..lineTo(38.1813, 69.9139)
          ..lineTo(53.3982, 74.8582)
          ..lineTo(68.6151, 100.1976)
          ..close(),
        Color(0xFFFFF1CF),
        null,
        1,
        null,
      ),
      _VectorLayer(
        Path()
          ..moveTo(38.1813, 69.9139)
          ..lineTo(74.7252, 55.2123)
          ..lineTo(80.6031, 63.3024)
          ..lineTo(53.3982, 74.8582)
          ..close(),
        Color(0xFF9E682E),
        null,
        1,
        null,
      ),
      _VectorLayer(
        Path()
          ..moveTo(74.7252, 55.2123)
          ..lineTo(100.0000, 25.0000)
          ..lineTo(100.0000, 41.0000)
          ..lineTo(80.6031, 63.3024)
          ..close(),
        Color(0xFFFFDA86),
        null,
        1,
        null,
      ),
      _VectorLayer(
        Path()
          ..moveTo(100.0000, 41.0000)
          ..lineTo(119.3969, 63.3024)
          ..lineTo(146.6018, 74.8582)
          ..lineTo(131.3849, 100.1976)
          ..lineTo(128.8015, 129.6418)
          ..lineTo(100.0000, 123.0000)
          ..lineTo(71.1985, 129.6418)
          ..lineTo(68.6151, 100.1976)
          ..lineTo(53.3982, 74.8582)
          ..lineTo(80.6031, 63.3024)
          ..close(),
        Color(0xFF252A59),
        Color(0xFFFFDA86),
        1.8,
        [Color(0xFF333B6D), Color(0xFF111B3A)],
      ),
      _VectorLayer(
        Path()
          ..moveTo(100.0000, 65.0000)
          ..lineTo(104.7518, 84.2482)
          ..lineTo(124.0000, 89.0000)
          ..lineTo(104.7518, 93.7518)
          ..lineTo(100.0000, 113.0000)
          ..lineTo(95.2482, 93.7518)
          ..lineTo(76.0000, 89.0000)
          ..lineTo(95.2482, 84.2482)
          ..close(),
        Color(0xFFF2E8FF),
        null,
        1,
        null,
      ),
      _VectorLayer(
        Path()
          ..moveTo(31.0000, 35.0000)
          ..lineTo(31.7920, 38.2080)
          ..lineTo(35.0000, 39.0000)
          ..lineTo(31.7920, 39.7920)
          ..lineTo(31.0000, 43.0000)
          ..lineTo(30.2080, 39.7920)
          ..lineTo(27.0000, 39.0000)
          ..lineTo(30.2080, 38.2080)
          ..close(),
        Color(0xFFFFDA86),
        null,
        1,
        null,
      ),
      _VectorLayer(
        Path()
          ..moveTo(167.0000, 39.0000)
          ..lineTo(167.7920, 42.2080)
          ..lineTo(171.0000, 43.0000)
          ..lineTo(167.7920, 43.7920)
          ..lineTo(167.0000, 47.0000)
          ..lineTo(166.2080, 43.7920)
          ..lineTo(163.0000, 43.0000)
          ..lineTo(166.2080, 42.2080)
          ..close(),
        Color(0xFFFFDA86),
        null,
        1,
        null,
      ),
      _VectorLayer(
        Path()
          ..moveTo(157.0000, 163.0000)
          ..lineTo(157.7920, 166.2080)
          ..lineTo(161.0000, 167.0000)
          ..lineTo(157.7920, 167.7920)
          ..lineTo(157.0000, 171.0000)
          ..lineTo(156.2080, 167.7920)
          ..lineTo(153.0000, 167.0000)
          ..lineTo(156.2080, 166.2080)
          ..close(),
        Color(0xFFFFDA86),
        null,
        1,
        null,
      ),
    ],
  ),
  'ranks/rank_impulse': (
    const Size(200, 200),
    [
      _VectorLayer(
        Path()
          ..moveTo(180.0000, 93.0000)
          ..cubicTo(180.0000, 137.1828, 144.1828, 173.0000, 100.0000, 173.0000)
          ..cubicTo(55.8172, 173.0000, 20.0000, 137.1828, 20.0000, 93.0000)
          ..cubicTo(20.0000, 48.8172, 55.8172, 13.0000, 100.0000, 13.0000)
          ..cubicTo(144.1828, 13.0000, 180.0000, 48.8172, 180.0000, 93.0000)
          ..close(),
        Color(0x12AE85FF),
        null,
        1,
        null,
      ),
      _VectorLayer(
        Path()
          ..moveTo(64.0000, 128.0000)
          ..lineTo(85.0000, 128.0000)
          ..lineTo(91.0000, 188.0000)
          ..lineTo(69.0000, 173.0000)
          ..close(),
        Color(0xFF8470DC),
        null,
        1,
        [Color(0xFFCCADFF), Color(0xFF6645B5)],
      ),
      _VectorLayer(
        Path()
          ..moveTo(85.0000, 128.0000)
          ..lineTo(106.0000, 128.0000)
          ..lineTo(112.0000, 190.0000)
          ..lineTo(91.0000, 188.0000)
          ..close(),
        Color(0xFFB195FC),
        null,
        1,
        [Color(0xFFB9A5FF), Color(0xFF7661E5)],
      ),
      _VectorLayer(
        Path()
          ..moveTo(106.0000, 128.0000)
          ..lineTo(127.0000, 128.0000)
          ..lineTo(131.0000, 173.0000)
          ..lineTo(112.0000, 190.0000)
          ..close(),
        Color(0xFF7351C0),
        null,
        1,
        [Color(0xFF6369D2), Color(0xFF303D80)],
      ),
      _VectorLayer(
        Path()
          ..moveTo(43.0000, 143.0000)
          ..quadraticBezierTo(17.0000, 135.0000, 31.0000, 116.0000)
          ..quadraticBezierTo(44.0000, 126.0000, 43.0000, 143.0000)
          ..close(),
        Color(0xFFBCD7FF),
        null,
        1,
        [Color(0xFFBCD7FF), Color(0xFF806147)],
      ),
      _VectorLayer(
        Path()
          ..moveTo(40.0000, 128.0000)
          ..quadraticBezierTo(14.0000, 120.0000, 28.0000, 101.0000)
          ..quadraticBezierTo(41.0000, 111.0000, 40.0000, 128.0000)
          ..close(),
        Color(0xFFBCD7FF),
        null,
        1,
        [Color(0xFFBCD7FF), Color(0xFF806147)],
      ),
      _VectorLayer(
        Path()
          ..moveTo(37.0000, 113.0000)
          ..quadraticBezierTo(11.0000, 105.0000, 25.0000, 86.0000)
          ..quadraticBezierTo(38.0000, 96.0000, 37.0000, 113.0000)
          ..close(),
        Color(0xFFBCD7FF),
        null,
        1,
        [Color(0xFFBCD7FF), Color(0xFF806147)],
      ),
      _VectorLayer(
        Path()
          ..moveTo(34.0000, 98.0000)
          ..quadraticBezierTo(8.0000, 90.0000, 22.0000, 71.0000)
          ..quadraticBezierTo(35.0000, 81.0000, 34.0000, 98.0000)
          ..close(),
        Color(0xFFBCD7FF),
        null,
        1,
        [Color(0xFFBCD7FF), Color(0xFF806147)],
      ),
      _VectorLayer(
        Path()
          ..moveTo(31.0000, 83.0000)
          ..quadraticBezierTo(5.0000, 75.0000, 19.0000, 56.0000)
          ..quadraticBezierTo(32.0000, 66.0000, 31.0000, 83.0000)
          ..close(),
        Color(0xFFBCD7FF),
        null,
        1,
        [Color(0xFFBCD7FF), Color(0xFF806147)],
      ),
      _VectorLayer(
        Path()
          ..moveTo(157.0000, 143.0000)
          ..quadraticBezierTo(183.0000, 135.0000, 169.0000, 116.0000)
          ..quadraticBezierTo(156.0000, 126.0000, 157.0000, 143.0000)
          ..close(),
        Color(0xFFBCD7FF),
        null,
        1,
        [Color(0xFFBCD7FF), Color(0xFF806147)],
      ),
      _VectorLayer(
        Path()
          ..moveTo(160.0000, 128.0000)
          ..quadraticBezierTo(186.0000, 120.0000, 172.0000, 101.0000)
          ..quadraticBezierTo(159.0000, 111.0000, 160.0000, 128.0000)
          ..close(),
        Color(0xFFBCD7FF),
        null,
        1,
        [Color(0xFFBCD7FF), Color(0xFF806147)],
      ),
      _VectorLayer(
        Path()
          ..moveTo(163.0000, 113.0000)
          ..quadraticBezierTo(189.0000, 105.0000, 175.0000, 86.0000)
          ..quadraticBezierTo(162.0000, 96.0000, 163.0000, 113.0000)
          ..close(),
        Color(0xFFBCD7FF),
        null,
        1,
        [Color(0xFFBCD7FF), Color(0xFF806147)],
      ),
      _VectorLayer(
        Path()
          ..moveTo(166.0000, 98.0000)
          ..quadraticBezierTo(192.0000, 90.0000, 178.0000, 71.0000)
          ..quadraticBezierTo(165.0000, 81.0000, 166.0000, 98.0000)
          ..close(),
        Color(0xFFBCD7FF),
        null,
        1,
        [Color(0xFFBCD7FF), Color(0xFF806147)],
      ),
      _VectorLayer(
        Path()
          ..moveTo(169.0000, 83.0000)
          ..quadraticBezierTo(195.0000, 75.0000, 181.0000, 56.0000)
          ..quadraticBezierTo(168.0000, 66.0000, 169.0000, 83.0000)
          ..close(),
        Color(0xFFBCD7FF),
        null,
        1,
        [Color(0xFFBCD7FF), Color(0xFF806147)],
      ),
      _VectorLayer(
        Path()
          ..moveTo(100.0000, 25.0000)
          ..lineTo(125.2748, 55.2123)
          ..lineTo(161.8187, 69.9139)
          ..lineTo(140.8954, 103.2877)
          ..lineTo(138.2060, 142.5861)
          ..lineTo(100.0000, 133.0000)
          ..lineTo(61.7940, 142.5861)
          ..lineTo(59.1046, 103.2877)
          ..lineTo(38.1813, 69.9139)
          ..lineTo(74.7252, 55.2123)
          ..close(),
        Color(0xFFBCD7FF),
        Color(0xFFF4DEFF),
        1.5,
        [Color(0xFFBCD7FF), Color(0xFF8D6BA1)],
      ),
      _VectorLayer(
        Path()
          ..moveTo(100.0000, 25.0000)
          ..lineTo(125.2748, 55.2123)
          ..lineTo(119.3969, 63.3024)
          ..lineTo(100.0000, 41.0000)
          ..close(),
        Color(0xFFBCD7FF),
        null,
        1,
        null,
      ),
      _VectorLayer(
        Path()
          ..moveTo(125.2748, 55.2123)
          ..lineTo(161.8187, 69.9139)
          ..lineTo(146.6018, 74.8582)
          ..lineTo(119.3969, 63.3024)
          ..close(),
        Color(0xFFE6DCFF),
        null,
        1,
        null,
      ),
      _VectorLayer(
        Path()
          ..moveTo(161.8187, 69.9139)
          ..lineTo(140.8954, 103.2877)
          ..lineTo(131.3849, 100.1976)
          ..lineTo(146.6018, 74.8582)
          ..close(),
        Color(0xFF6155A4),
        null,
        1,
        null,
      ),
      _VectorLayer(
        Path()
          ..moveTo(140.8954, 103.2877)
          ..lineTo(138.2060, 142.5861)
          ..lineTo(128.8015, 129.6418)
          ..lineTo(131.3849, 100.1976)
          ..close(),
        Color(0xFFBCD7FF),
        null,
        1,
        null,
      ),
      _VectorLayer(
        Path()
          ..moveTo(138.2060, 142.5861)
          ..lineTo(100.0000, 133.0000)
          ..lineTo(100.0000, 123.0000)
          ..lineTo(128.8015, 129.6418)
          ..close(),
        Color(0xFFE6DCFF),
        null,
        1,
        null,
      ),
      _VectorLayer(
        Path()
          ..moveTo(100.0000, 133.0000)
          ..lineTo(61.7940, 142.5861)
          ..lineTo(71.1985, 129.6418)
          ..lineTo(100.0000, 123.0000)
          ..close(),
        Color(0xFF6155A4),
        null,
        1,
        null,
      ),
      _VectorLayer(
        Path()
          ..moveTo(61.7940, 142.5861)
          ..lineTo(59.1046, 103.2877)
          ..lineTo(68.6151, 100.1976)
          ..lineTo(71.1985, 129.6418)
          ..close(),
        Color(0xFFBCD7FF),
        null,
        1,
        null,
      ),
      _VectorLayer(
        Path()
          ..moveTo(59.1046, 103.2877)
          ..lineTo(38.1813, 69.9139)
          ..lineTo(53.3982, 74.8582)
          ..lineTo(68.6151, 100.1976)
          ..close(),
        Color(0xFFE6DCFF),
        null,
        1,
        null,
      ),
      _VectorLayer(
        Path()
          ..moveTo(38.1813, 69.9139)
          ..lineTo(74.7252, 55.2123)
          ..lineTo(80.6031, 63.3024)
          ..lineTo(53.3982, 74.8582)
          ..close(),
        Color(0xFF6155A4),
        null,
        1,
        null,
      ),
      _VectorLayer(
        Path()
          ..moveTo(74.7252, 55.2123)
          ..lineTo(100.0000, 25.0000)
          ..lineTo(100.0000, 41.0000)
          ..lineTo(80.6031, 63.3024)
          ..close(),
        Color(0xFFBCD7FF),
        null,
        1,
        null,
      ),
      _VectorLayer(
        Path()
          ..moveTo(100.0000, 41.0000)
          ..lineTo(119.3969, 63.3024)
          ..lineTo(146.6018, 74.8582)
          ..lineTo(131.3849, 100.1976)
          ..lineTo(128.8015, 129.6418)
          ..lineTo(100.0000, 123.0000)
          ..lineTo(71.1985, 129.6418)
          ..lineTo(68.6151, 100.1976)
          ..lineTo(53.3982, 74.8582)
          ..lineTo(80.6031, 63.3024)
          ..close(),
        Color(0xFF252A59),
        Color(0xFFBCD7FF),
        1.8,
        [Color(0xFF333B6D), Color(0xFF111B3A)],
      ),
      _VectorLayer(
        Path()
          ..moveTo(107.0000, 64.0000)
          ..lineTo(83.0000, 92.0000)
          ..lineTo(99.0000, 92.0000)
          ..lineTo(92.0000, 115.0000)
          ..lineTo(117.0000, 84.0000)
          ..lineTo(101.0000, 84.0000)
          ..close(),
        Color(0xFFF2E8FF),
        null,
        1,
        null,
      ),
      _VectorLayer(
        Path()
          ..moveTo(31.0000, 35.0000)
          ..lineTo(31.7920, 38.2080)
          ..lineTo(35.0000, 39.0000)
          ..lineTo(31.7920, 39.7920)
          ..lineTo(31.0000, 43.0000)
          ..lineTo(30.2080, 39.7920)
          ..lineTo(27.0000, 39.0000)
          ..lineTo(30.2080, 38.2080)
          ..close(),
        Color(0xFFBCD7FF),
        null,
        1,
        null,
      ),
      _VectorLayer(
        Path()
          ..moveTo(167.0000, 39.0000)
          ..lineTo(167.7920, 42.2080)
          ..lineTo(171.0000, 43.0000)
          ..lineTo(167.7920, 43.7920)
          ..lineTo(167.0000, 47.0000)
          ..lineTo(166.2080, 43.7920)
          ..lineTo(163.0000, 43.0000)
          ..lineTo(166.2080, 42.2080)
          ..close(),
        Color(0xFFBCD7FF),
        null,
        1,
        null,
      ),
      _VectorLayer(
        Path()
          ..moveTo(157.0000, 163.0000)
          ..lineTo(157.7920, 166.2080)
          ..lineTo(161.0000, 167.0000)
          ..lineTo(157.7920, 167.7920)
          ..lineTo(157.0000, 171.0000)
          ..lineTo(156.2080, 167.7920)
          ..lineTo(153.0000, 167.0000)
          ..lineTo(156.2080, 166.2080)
          ..close(),
        Color(0xFFBCD7FF),
        null,
        1,
        null,
      ),
    ],
  ),
  'ranks/rank_rhythm': (
    const Size(200, 200),
    [
      _VectorLayer(
        Path()
          ..moveTo(180.0000, 93.0000)
          ..cubicTo(180.0000, 137.1828, 144.1828, 173.0000, 100.0000, 173.0000)
          ..cubicTo(55.8172, 173.0000, 20.0000, 137.1828, 20.0000, 93.0000)
          ..cubicTo(20.0000, 48.8172, 55.8172, 13.0000, 100.0000, 13.0000)
          ..cubicTo(144.1828, 13.0000, 180.0000, 48.8172, 180.0000, 93.0000)
          ..close(),
        Color(0x12AE85FF),
        null,
        1,
        null,
      ),
      _VectorLayer(
        Path()
          ..moveTo(64.0000, 128.0000)
          ..lineTo(85.0000, 128.0000)
          ..lineTo(91.0000, 188.0000)
          ..lineTo(69.0000, 173.0000)
          ..close(),
        Color(0xFF8470DC),
        null,
        1,
        [Color(0xFFCCADFF), Color(0xFF6645B5)],
      ),
      _VectorLayer(
        Path()
          ..moveTo(85.0000, 128.0000)
          ..lineTo(106.0000, 128.0000)
          ..lineTo(112.0000, 190.0000)
          ..lineTo(91.0000, 188.0000)
          ..close(),
        Color(0xFFB195FC),
        null,
        1,
        [Color(0xFFB9A5FF), Color(0xFF7661E5)],
      ),
      _VectorLayer(
        Path()
          ..moveTo(106.0000, 128.0000)
          ..lineTo(127.0000, 128.0000)
          ..lineTo(131.0000, 173.0000)
          ..lineTo(112.0000, 190.0000)
          ..close(),
        Color(0xFF7351C0),
        null,
        1,
        [Color(0xFF6369D2), Color(0xFF303D80)],
      ),
      _VectorLayer(
        Path()
          ..moveTo(43.0000, 143.0000)
          ..quadraticBezierTo(17.0000, 135.0000, 31.0000, 116.0000)
          ..quadraticBezierTo(44.0000, 126.0000, 43.0000, 143.0000)
          ..close(),
        Color(0xFFB6B4FF),
        null,
        1,
        [Color(0xFFB6B4FF), Color(0xFF806147)],
      ),
      _VectorLayer(
        Path()
          ..moveTo(40.0000, 128.0000)
          ..quadraticBezierTo(14.0000, 120.0000, 28.0000, 101.0000)
          ..quadraticBezierTo(41.0000, 111.0000, 40.0000, 128.0000)
          ..close(),
        Color(0xFFB6B4FF),
        null,
        1,
        [Color(0xFFB6B4FF), Color(0xFF806147)],
      ),
      _VectorLayer(
        Path()
          ..moveTo(37.0000, 113.0000)
          ..quadraticBezierTo(11.0000, 105.0000, 25.0000, 86.0000)
          ..quadraticBezierTo(38.0000, 96.0000, 37.0000, 113.0000)
          ..close(),
        Color(0xFFB6B4FF),
        null,
        1,
        [Color(0xFFB6B4FF), Color(0xFF806147)],
      ),
      _VectorLayer(
        Path()
          ..moveTo(34.0000, 98.0000)
          ..quadraticBezierTo(8.0000, 90.0000, 22.0000, 71.0000)
          ..quadraticBezierTo(35.0000, 81.0000, 34.0000, 98.0000)
          ..close(),
        Color(0xFFB6B4FF),
        null,
        1,
        [Color(0xFFB6B4FF), Color(0xFF806147)],
      ),
      _VectorLayer(
        Path()
          ..moveTo(31.0000, 83.0000)
          ..quadraticBezierTo(5.0000, 75.0000, 19.0000, 56.0000)
          ..quadraticBezierTo(32.0000, 66.0000, 31.0000, 83.0000)
          ..close(),
        Color(0xFFB6B4FF),
        null,
        1,
        [Color(0xFFB6B4FF), Color(0xFF806147)],
      ),
      _VectorLayer(
        Path()
          ..moveTo(157.0000, 143.0000)
          ..quadraticBezierTo(183.0000, 135.0000, 169.0000, 116.0000)
          ..quadraticBezierTo(156.0000, 126.0000, 157.0000, 143.0000)
          ..close(),
        Color(0xFFB6B4FF),
        null,
        1,
        [Color(0xFFB6B4FF), Color(0xFF806147)],
      ),
      _VectorLayer(
        Path()
          ..moveTo(160.0000, 128.0000)
          ..quadraticBezierTo(186.0000, 120.0000, 172.0000, 101.0000)
          ..quadraticBezierTo(159.0000, 111.0000, 160.0000, 128.0000)
          ..close(),
        Color(0xFFB6B4FF),
        null,
        1,
        [Color(0xFFB6B4FF), Color(0xFF806147)],
      ),
      _VectorLayer(
        Path()
          ..moveTo(163.0000, 113.0000)
          ..quadraticBezierTo(189.0000, 105.0000, 175.0000, 86.0000)
          ..quadraticBezierTo(162.0000, 96.0000, 163.0000, 113.0000)
          ..close(),
        Color(0xFFB6B4FF),
        null,
        1,
        [Color(0xFFB6B4FF), Color(0xFF806147)],
      ),
      _VectorLayer(
        Path()
          ..moveTo(166.0000, 98.0000)
          ..quadraticBezierTo(192.0000, 90.0000, 178.0000, 71.0000)
          ..quadraticBezierTo(165.0000, 81.0000, 166.0000, 98.0000)
          ..close(),
        Color(0xFFB6B4FF),
        null,
        1,
        [Color(0xFFB6B4FF), Color(0xFF806147)],
      ),
      _VectorLayer(
        Path()
          ..moveTo(169.0000, 83.0000)
          ..quadraticBezierTo(195.0000, 75.0000, 181.0000, 56.0000)
          ..quadraticBezierTo(168.0000, 66.0000, 169.0000, 83.0000)
          ..close(),
        Color(0xFFB6B4FF),
        null,
        1,
        [Color(0xFFB6B4FF), Color(0xFF806147)],
      ),
      _VectorLayer(
        Path()
          ..moveTo(100.0000, 25.0000)
          ..lineTo(129.0000, 39.7705)
          ..lineTo(156.2917, 57.5000)
          ..lineTo(158.0000, 90.0000)
          ..lineTo(156.2917, 122.5000)
          ..lineTo(129.0000, 140.2295)
          ..lineTo(100.0000, 155.0000)
          ..lineTo(71.0000, 140.2295)
          ..lineTo(43.7083, 122.5000)
          ..lineTo(42.0000, 90.0000)
          ..lineTo(43.7083, 57.5000)
          ..lineTo(71.0000, 39.7705)
          ..close(),
        Color(0xFFB6B4FF),
        Color(0xFFF4DEFF),
        1.5,
        [Color(0xFFB6B4FF), Color(0xFF8D6BA1)],
      ),
      _VectorLayer(
        Path()
          ..moveTo(100.0000, 25.0000)
          ..lineTo(129.0000, 39.7705)
          ..lineTo(121.5000, 52.7609)
          ..lineTo(100.0000, 41.0000)
          ..close(),
        Color(0xFFB6B4FF),
        null,
        1,
        null,
      ),
      _VectorLayer(
        Path()
          ..moveTo(129.0000, 39.7705)
          ..lineTo(156.2917, 57.5000)
          ..lineTo(142.4352, 65.5000)
          ..lineTo(121.5000, 52.7609)
          ..close(),
        Color(0xFFE6DCFF),
        null,
        1,
        null,
      ),
      _VectorLayer(
        Path()
          ..moveTo(156.2917, 57.5000)
          ..lineTo(158.0000, 90.0000)
          ..lineTo(143.0000, 90.0000)
          ..lineTo(142.4352, 65.5000)
          ..close(),
        Color(0xFF6155A4),
        null,
        1,
        null,
      ),
      _VectorLayer(
        Path()
          ..moveTo(158.0000, 90.0000)
          ..lineTo(156.2917, 122.5000)
          ..lineTo(142.4352, 114.5000)
          ..lineTo(143.0000, 90.0000)
          ..close(),
        Color(0xFFB6B4FF),
        null,
        1,
        null,
      ),
      _VectorLayer(
        Path()
          ..moveTo(156.2917, 122.5000)
          ..lineTo(129.0000, 140.2295)
          ..lineTo(121.5000, 127.2391)
          ..lineTo(142.4352, 114.5000)
          ..close(),
        Color(0xFFE6DCFF),
        null,
        1,
        null,
      ),
      _VectorLayer(
        Path()
          ..moveTo(129.0000, 140.2295)
          ..lineTo(100.0000, 155.0000)
          ..lineTo(100.0000, 139.0000)
          ..lineTo(121.5000, 127.2391)
          ..close(),
        Color(0xFF6155A4),
        null,
        1,
        null,
      ),
      _VectorLayer(
        Path()
          ..moveTo(100.0000, 155.0000)
          ..lineTo(71.0000, 140.2295)
          ..lineTo(78.5000, 127.2391)
          ..lineTo(100.0000, 139.0000)
          ..close(),
        Color(0xFFB6B4FF),
        null,
        1,
        null,
      ),
      _VectorLayer(
        Path()
          ..moveTo(71.0000, 140.2295)
          ..lineTo(43.7083, 122.5000)
          ..lineTo(57.5648, 114.5000)
          ..lineTo(78.5000, 127.2391)
          ..close(),
        Color(0xFFE6DCFF),
        null,
        1,
        null,
      ),
      _VectorLayer(
        Path()
          ..moveTo(43.7083, 122.5000)
          ..lineTo(42.0000, 90.0000)
          ..lineTo(57.0000, 90.0000)
          ..lineTo(57.5648, 114.5000)
          ..close(),
        Color(0xFF6155A4),
        null,
        1,
        null,
      ),
      _VectorLayer(
        Path()
          ..moveTo(42.0000, 90.0000)
          ..lineTo(43.7083, 57.5000)
          ..lineTo(57.5648, 65.5000)
          ..lineTo(57.0000, 90.0000)
          ..close(),
        Color(0xFFB6B4FF),
        null,
        1,
        null,
      ),
      _VectorLayer(
        Path()
          ..moveTo(43.7083, 57.5000)
          ..lineTo(71.0000, 39.7705)
          ..lineTo(78.5000, 52.7609)
          ..lineTo(57.5648, 65.5000)
          ..close(),
        Color(0xFFE6DCFF),
        null,
        1,
        null,
      ),
      _VectorLayer(
        Path()
          ..moveTo(71.0000, 39.7705)
          ..lineTo(100.0000, 25.0000)
          ..lineTo(100.0000, 41.0000)
          ..lineTo(78.5000, 52.7609)
          ..close(),
        Color(0xFF6155A4),
        null,
        1,
        null,
      ),
      _VectorLayer(
        Path()
          ..moveTo(100.0000, 41.0000)
          ..lineTo(121.5000, 52.7609)
          ..lineTo(142.4352, 65.5000)
          ..lineTo(143.0000, 90.0000)
          ..lineTo(142.4352, 114.5000)
          ..lineTo(121.5000, 127.2391)
          ..lineTo(100.0000, 139.0000)
          ..lineTo(78.5000, 127.2391)
          ..lineTo(57.5648, 114.5000)
          ..lineTo(57.0000, 90.0000)
          ..lineTo(57.5648, 65.5000)
          ..lineTo(78.5000, 52.7609)
          ..close(),
        Color(0xFF252A59),
        Color(0xFFB6B4FF),
        1.8,
        [Color(0xFF333B6D), Color(0xFF111B3A)],
      ),
      _VectorLayer(
        Path()
          ..moveTo(84.0000, 92.0000)
          ..lineTo(86.0000, 92.0000)
          ..quadraticBezierTo(88.0000, 92.0000, 88.0000, 94.0000)
          ..lineTo(88.0000, 108.0000)
          ..quadraticBezierTo(88.0000, 110.0000, 86.0000, 110.0000)
          ..lineTo(84.0000, 110.0000)
          ..quadraticBezierTo(82.0000, 110.0000, 82.0000, 108.0000)
          ..lineTo(82.0000, 94.0000)
          ..quadraticBezierTo(82.0000, 92.0000, 84.0000, 92.0000)
          ..close(),
        Color(0xFFF2E8FF),
        null,
        1,
        null,
      ),
      _VectorLayer(
        Path()
          ..moveTo(96.0000, 80.0000)
          ..lineTo(98.0000, 80.0000)
          ..quadraticBezierTo(100.0000, 80.0000, 100.0000, 82.0000)
          ..lineTo(100.0000, 108.0000)
          ..quadraticBezierTo(100.0000, 110.0000, 98.0000, 110.0000)
          ..lineTo(96.0000, 110.0000)
          ..quadraticBezierTo(94.0000, 110.0000, 94.0000, 108.0000)
          ..lineTo(94.0000, 82.0000)
          ..quadraticBezierTo(94.0000, 80.0000, 96.0000, 80.0000)
          ..close(),
        Color(0xFFF2E8FF),
        null,
        1,
        null,
      ),
      _VectorLayer(
        Path()
          ..moveTo(108.0000, 68.0000)
          ..lineTo(110.0000, 68.0000)
          ..quadraticBezierTo(112.0000, 68.0000, 112.0000, 70.0000)
          ..lineTo(112.0000, 108.0000)
          ..quadraticBezierTo(112.0000, 110.0000, 110.0000, 110.0000)
          ..lineTo(108.0000, 110.0000)
          ..quadraticBezierTo(106.0000, 110.0000, 106.0000, 108.0000)
          ..lineTo(106.0000, 70.0000)
          ..quadraticBezierTo(106.0000, 68.0000, 108.0000, 68.0000)
          ..close(),
        Color(0xFFF2E8FF),
        null,
        1,
        null,
      ),
      _VectorLayer(
        Path()
          ..moveTo(31.0000, 35.0000)
          ..lineTo(31.7920, 38.2080)
          ..lineTo(35.0000, 39.0000)
          ..lineTo(31.7920, 39.7920)
          ..lineTo(31.0000, 43.0000)
          ..lineTo(30.2080, 39.7920)
          ..lineTo(27.0000, 39.0000)
          ..lineTo(30.2080, 38.2080)
          ..close(),
        Color(0xFFB6B4FF),
        null,
        1,
        null,
      ),
      _VectorLayer(
        Path()
          ..moveTo(167.0000, 39.0000)
          ..lineTo(167.7920, 42.2080)
          ..lineTo(171.0000, 43.0000)
          ..lineTo(167.7920, 43.7920)
          ..lineTo(167.0000, 47.0000)
          ..lineTo(166.2080, 43.7920)
          ..lineTo(163.0000, 43.0000)
          ..lineTo(166.2080, 42.2080)
          ..close(),
        Color(0xFFB6B4FF),
        null,
        1,
        null,
      ),
      _VectorLayer(
        Path()
          ..moveTo(157.0000, 163.0000)
          ..lineTo(157.7920, 166.2080)
          ..lineTo(161.0000, 167.0000)
          ..lineTo(157.7920, 167.7920)
          ..lineTo(157.0000, 171.0000)
          ..lineTo(156.2080, 167.7920)
          ..lineTo(153.0000, 167.0000)
          ..lineTo(156.2080, 166.2080)
          ..close(),
        Color(0xFFB6B4FF),
        null,
        1,
        null,
      ),
    ],
  ),
  'ranks/rank_focus': (
    const Size(200, 200),
    [
      _VectorLayer(
        Path()
          ..moveTo(180.0000, 93.0000)
          ..cubicTo(180.0000, 137.1828, 144.1828, 173.0000, 100.0000, 173.0000)
          ..cubicTo(55.8172, 173.0000, 20.0000, 137.1828, 20.0000, 93.0000)
          ..cubicTo(20.0000, 48.8172, 55.8172, 13.0000, 100.0000, 13.0000)
          ..cubicTo(144.1828, 13.0000, 180.0000, 48.8172, 180.0000, 93.0000)
          ..close(),
        Color(0x12AE85FF),
        null,
        1,
        null,
      ),
      _VectorLayer(
        Path()
          ..moveTo(64.0000, 128.0000)
          ..lineTo(85.0000, 128.0000)
          ..lineTo(91.0000, 188.0000)
          ..lineTo(69.0000, 173.0000)
          ..close(),
        Color(0xFF8470DC),
        null,
        1,
        [Color(0xFFCCADFF), Color(0xFF6645B5)],
      ),
      _VectorLayer(
        Path()
          ..moveTo(85.0000, 128.0000)
          ..lineTo(106.0000, 128.0000)
          ..lineTo(112.0000, 190.0000)
          ..lineTo(91.0000, 188.0000)
          ..close(),
        Color(0xFFB195FC),
        null,
        1,
        [Color(0xFFB9A5FF), Color(0xFF7661E5)],
      ),
      _VectorLayer(
        Path()
          ..moveTo(106.0000, 128.0000)
          ..lineTo(127.0000, 128.0000)
          ..lineTo(131.0000, 173.0000)
          ..lineTo(112.0000, 190.0000)
          ..close(),
        Color(0xFF7351C0),
        null,
        1,
        [Color(0xFF6369D2), Color(0xFF303D80)],
      ),
      _VectorLayer(
        Path()
          ..moveTo(43.0000, 143.0000)
          ..quadraticBezierTo(17.0000, 135.0000, 31.0000, 116.0000)
          ..quadraticBezierTo(44.0000, 126.0000, 43.0000, 143.0000)
          ..close(),
        Color(0xFF98ECD6),
        null,
        1,
        [Color(0xFF98ECD6), Color(0xFF806147)],
      ),
      _VectorLayer(
        Path()
          ..moveTo(40.0000, 128.0000)
          ..quadraticBezierTo(14.0000, 120.0000, 28.0000, 101.0000)
          ..quadraticBezierTo(41.0000, 111.0000, 40.0000, 128.0000)
          ..close(),
        Color(0xFF98ECD6),
        null,
        1,
        [Color(0xFF98ECD6), Color(0xFF806147)],
      ),
      _VectorLayer(
        Path()
          ..moveTo(37.0000, 113.0000)
          ..quadraticBezierTo(11.0000, 105.0000, 25.0000, 86.0000)
          ..quadraticBezierTo(38.0000, 96.0000, 37.0000, 113.0000)
          ..close(),
        Color(0xFF98ECD6),
        null,
        1,
        [Color(0xFF98ECD6), Color(0xFF806147)],
      ),
      _VectorLayer(
        Path()
          ..moveTo(34.0000, 98.0000)
          ..quadraticBezierTo(8.0000, 90.0000, 22.0000, 71.0000)
          ..quadraticBezierTo(35.0000, 81.0000, 34.0000, 98.0000)
          ..close(),
        Color(0xFF98ECD6),
        null,
        1,
        [Color(0xFF98ECD6), Color(0xFF806147)],
      ),
      _VectorLayer(
        Path()
          ..moveTo(31.0000, 83.0000)
          ..quadraticBezierTo(5.0000, 75.0000, 19.0000, 56.0000)
          ..quadraticBezierTo(32.0000, 66.0000, 31.0000, 83.0000)
          ..close(),
        Color(0xFF98ECD6),
        null,
        1,
        [Color(0xFF98ECD6), Color(0xFF806147)],
      ),
      _VectorLayer(
        Path()
          ..moveTo(157.0000, 143.0000)
          ..quadraticBezierTo(183.0000, 135.0000, 169.0000, 116.0000)
          ..quadraticBezierTo(156.0000, 126.0000, 157.0000, 143.0000)
          ..close(),
        Color(0xFF98ECD6),
        null,
        1,
        [Color(0xFF98ECD6), Color(0xFF806147)],
      ),
      _VectorLayer(
        Path()
          ..moveTo(160.0000, 128.0000)
          ..quadraticBezierTo(186.0000, 120.0000, 172.0000, 101.0000)
          ..quadraticBezierTo(159.0000, 111.0000, 160.0000, 128.0000)
          ..close(),
        Color(0xFF98ECD6),
        null,
        1,
        [Color(0xFF98ECD6), Color(0xFF806147)],
      ),
      _VectorLayer(
        Path()
          ..moveTo(163.0000, 113.0000)
          ..quadraticBezierTo(189.0000, 105.0000, 175.0000, 86.0000)
          ..quadraticBezierTo(162.0000, 96.0000, 163.0000, 113.0000)
          ..close(),
        Color(0xFF98ECD6),
        null,
        1,
        [Color(0xFF98ECD6), Color(0xFF806147)],
      ),
      _VectorLayer(
        Path()
          ..moveTo(166.0000, 98.0000)
          ..quadraticBezierTo(192.0000, 90.0000, 178.0000, 71.0000)
          ..quadraticBezierTo(165.0000, 81.0000, 166.0000, 98.0000)
          ..close(),
        Color(0xFF98ECD6),
        null,
        1,
        [Color(0xFF98ECD6), Color(0xFF806147)],
      ),
      _VectorLayer(
        Path()
          ..moveTo(169.0000, 83.0000)
          ..quadraticBezierTo(195.0000, 75.0000, 181.0000, 56.0000)
          ..quadraticBezierTo(168.0000, 66.0000, 169.0000, 83.0000)
          ..close(),
        Color(0xFF98ECD6),
        null,
        1,
        [Color(0xFF98ECD6), Color(0xFF806147)],
      ),
      _VectorLayer(
        Path()
          ..moveTo(100.0000, 25.0000)
          ..lineTo(129.0000, 39.7705)
          ..lineTo(156.2917, 57.5000)
          ..lineTo(158.0000, 90.0000)
          ..lineTo(156.2917, 122.5000)
          ..lineTo(129.0000, 140.2295)
          ..lineTo(100.0000, 155.0000)
          ..lineTo(71.0000, 140.2295)
          ..lineTo(43.7083, 122.5000)
          ..lineTo(42.0000, 90.0000)
          ..lineTo(43.7083, 57.5000)
          ..lineTo(71.0000, 39.7705)
          ..close(),
        Color(0xFF98ECD6),
        Color(0xFFF4DEFF),
        1.5,
        [Color(0xFF98ECD6), Color(0xFF8D6BA1)],
      ),
      _VectorLayer(
        Path()
          ..moveTo(100.0000, 25.0000)
          ..lineTo(129.0000, 39.7705)
          ..lineTo(121.5000, 52.7609)
          ..lineTo(100.0000, 41.0000)
          ..close(),
        Color(0xFF98ECD6),
        null,
        1,
        null,
      ),
      _VectorLayer(
        Path()
          ..moveTo(129.0000, 39.7705)
          ..lineTo(156.2917, 57.5000)
          ..lineTo(142.4352, 65.5000)
          ..lineTo(121.5000, 52.7609)
          ..close(),
        Color(0xFFE6DCFF),
        null,
        1,
        null,
      ),
      _VectorLayer(
        Path()
          ..moveTo(156.2917, 57.5000)
          ..lineTo(158.0000, 90.0000)
          ..lineTo(143.0000, 90.0000)
          ..lineTo(142.4352, 65.5000)
          ..close(),
        Color(0xFF6155A4),
        null,
        1,
        null,
      ),
      _VectorLayer(
        Path()
          ..moveTo(158.0000, 90.0000)
          ..lineTo(156.2917, 122.5000)
          ..lineTo(142.4352, 114.5000)
          ..lineTo(143.0000, 90.0000)
          ..close(),
        Color(0xFF98ECD6),
        null,
        1,
        null,
      ),
      _VectorLayer(
        Path()
          ..moveTo(156.2917, 122.5000)
          ..lineTo(129.0000, 140.2295)
          ..lineTo(121.5000, 127.2391)
          ..lineTo(142.4352, 114.5000)
          ..close(),
        Color(0xFFE6DCFF),
        null,
        1,
        null,
      ),
      _VectorLayer(
        Path()
          ..moveTo(129.0000, 140.2295)
          ..lineTo(100.0000, 155.0000)
          ..lineTo(100.0000, 139.0000)
          ..lineTo(121.5000, 127.2391)
          ..close(),
        Color(0xFF6155A4),
        null,
        1,
        null,
      ),
      _VectorLayer(
        Path()
          ..moveTo(100.0000, 155.0000)
          ..lineTo(71.0000, 140.2295)
          ..lineTo(78.5000, 127.2391)
          ..lineTo(100.0000, 139.0000)
          ..close(),
        Color(0xFF98ECD6),
        null,
        1,
        null,
      ),
      _VectorLayer(
        Path()
          ..moveTo(71.0000, 140.2295)
          ..lineTo(43.7083, 122.5000)
          ..lineTo(57.5648, 114.5000)
          ..lineTo(78.5000, 127.2391)
          ..close(),
        Color(0xFFE6DCFF),
        null,
        1,
        null,
      ),
      _VectorLayer(
        Path()
          ..moveTo(43.7083, 122.5000)
          ..lineTo(42.0000, 90.0000)
          ..lineTo(57.0000, 90.0000)
          ..lineTo(57.5648, 114.5000)
          ..close(),
        Color(0xFF6155A4),
        null,
        1,
        null,
      ),
      _VectorLayer(
        Path()
          ..moveTo(42.0000, 90.0000)
          ..lineTo(43.7083, 57.5000)
          ..lineTo(57.5648, 65.5000)
          ..lineTo(57.0000, 90.0000)
          ..close(),
        Color(0xFF98ECD6),
        null,
        1,
        null,
      ),
      _VectorLayer(
        Path()
          ..moveTo(43.7083, 57.5000)
          ..lineTo(71.0000, 39.7705)
          ..lineTo(78.5000, 52.7609)
          ..lineTo(57.5648, 65.5000)
          ..close(),
        Color(0xFFE6DCFF),
        null,
        1,
        null,
      ),
      _VectorLayer(
        Path()
          ..moveTo(71.0000, 39.7705)
          ..lineTo(100.0000, 25.0000)
          ..lineTo(100.0000, 41.0000)
          ..lineTo(78.5000, 52.7609)
          ..close(),
        Color(0xFF6155A4),
        null,
        1,
        null,
      ),
      _VectorLayer(
        Path()
          ..moveTo(100.0000, 41.0000)
          ..lineTo(121.5000, 52.7609)
          ..lineTo(142.4352, 65.5000)
          ..lineTo(143.0000, 90.0000)
          ..lineTo(142.4352, 114.5000)
          ..lineTo(121.5000, 127.2391)
          ..lineTo(100.0000, 139.0000)
          ..lineTo(78.5000, 127.2391)
          ..lineTo(57.5648, 114.5000)
          ..lineTo(57.0000, 90.0000)
          ..lineTo(57.5648, 65.5000)
          ..lineTo(78.5000, 52.7609)
          ..close(),
        Color(0xFF252A59),
        Color(0xFF98ECD6),
        1.8,
        [Color(0xFF333B6D), Color(0xFF111B3A)],
      ),
      _VectorLayer(
        Path()
          ..moveTo(124.0000, 90.0000)
          ..cubicTo(124.0000, 103.2548, 113.2548, 114.0000, 100.0000, 114.0000)
          ..cubicTo(86.7452, 114.0000, 76.0000, 103.2548, 76.0000, 90.0000)
          ..cubicTo(76.0000, 76.7452, 86.7452, 66.0000, 100.0000, 66.0000)
          ..cubicTo(113.2548, 66.0000, 124.0000, 76.7452, 124.0000, 90.0000)
          ..close(),
        null,
        Color(0xFFD6FFF0),
        2,
        null,
      ),
      _VectorLayer(
        Path()
          ..moveTo(111.0000, 90.0000)
          ..cubicTo(111.0000, 96.0751, 106.0751, 101.0000, 100.0000, 101.0000)
          ..cubicTo(93.9249, 101.0000, 89.0000, 96.0751, 89.0000, 90.0000)
          ..cubicTo(89.0000, 83.9249, 93.9249, 79.0000, 100.0000, 79.0000)
          ..cubicTo(106.0751, 79.0000, 111.0000, 83.9249, 111.0000, 90.0000)
          ..close(),
        null,
        Color(0xFFD6FFF0),
        3,
        null,
      ),
      _VectorLayer(
        Path()
          ..moveTo(103.0000, 90.0000)
          ..cubicTo(103.0000, 91.6569, 101.6569, 93.0000, 100.0000, 93.0000)
          ..cubicTo(98.3431, 93.0000, 97.0000, 91.6569, 97.0000, 90.0000)
          ..cubicTo(97.0000, 88.3431, 98.3431, 87.0000, 100.0000, 87.0000)
          ..cubicTo(101.6569, 87.0000, 103.0000, 88.3431, 103.0000, 90.0000)
          ..close(),
        Color(0xFFD6FFF0),
        null,
        1,
        null,
      ),
      _VectorLayer(
        Path()
          ..moveTo(31.0000, 35.0000)
          ..lineTo(31.7920, 38.2080)
          ..lineTo(35.0000, 39.0000)
          ..lineTo(31.7920, 39.7920)
          ..lineTo(31.0000, 43.0000)
          ..lineTo(30.2080, 39.7920)
          ..lineTo(27.0000, 39.0000)
          ..lineTo(30.2080, 38.2080)
          ..close(),
        Color(0xFF98ECD6),
        null,
        1,
        null,
      ),
      _VectorLayer(
        Path()
          ..moveTo(167.0000, 39.0000)
          ..lineTo(167.7920, 42.2080)
          ..lineTo(171.0000, 43.0000)
          ..lineTo(167.7920, 43.7920)
          ..lineTo(167.0000, 47.0000)
          ..lineTo(166.2080, 43.7920)
          ..lineTo(163.0000, 43.0000)
          ..lineTo(166.2080, 42.2080)
          ..close(),
        Color(0xFF98ECD6),
        null,
        1,
        null,
      ),
      _VectorLayer(
        Path()
          ..moveTo(157.0000, 163.0000)
          ..lineTo(157.7920, 166.2080)
          ..lineTo(161.0000, 167.0000)
          ..lineTo(157.7920, 167.7920)
          ..lineTo(157.0000, 171.0000)
          ..lineTo(156.2080, 167.7920)
          ..lineTo(153.0000, 167.0000)
          ..lineTo(156.2080, 166.2080)
          ..close(),
        Color(0xFF98ECD6),
        null,
        1,
        null,
      ),
    ],
  ),
  'ranks/rank_flow': (
    const Size(200, 200),
    [
      _VectorLayer(
        Path()
          ..moveTo(180.0000, 93.0000)
          ..cubicTo(180.0000, 137.1828, 144.1828, 173.0000, 100.0000, 173.0000)
          ..cubicTo(55.8172, 173.0000, 20.0000, 137.1828, 20.0000, 93.0000)
          ..cubicTo(20.0000, 48.8172, 55.8172, 13.0000, 100.0000, 13.0000)
          ..cubicTo(144.1828, 13.0000, 180.0000, 48.8172, 180.0000, 93.0000)
          ..close(),
        Color(0x12AE85FF),
        null,
        1,
        null,
      ),
      _VectorLayer(
        Path()
          ..moveTo(64.0000, 128.0000)
          ..lineTo(85.0000, 128.0000)
          ..lineTo(91.0000, 188.0000)
          ..lineTo(69.0000, 173.0000)
          ..close(),
        Color(0xFF8470DC),
        null,
        1,
        [Color(0xFFCCADFF), Color(0xFF6645B5)],
      ),
      _VectorLayer(
        Path()
          ..moveTo(85.0000, 128.0000)
          ..lineTo(106.0000, 128.0000)
          ..lineTo(112.0000, 190.0000)
          ..lineTo(91.0000, 188.0000)
          ..close(),
        Color(0xFFB195FC),
        null,
        1,
        [Color(0xFFB9A5FF), Color(0xFF7661E5)],
      ),
      _VectorLayer(
        Path()
          ..moveTo(106.0000, 128.0000)
          ..lineTo(127.0000, 128.0000)
          ..lineTo(131.0000, 173.0000)
          ..lineTo(112.0000, 190.0000)
          ..close(),
        Color(0xFF7351C0),
        null,
        1,
        [Color(0xFF6369D2), Color(0xFF303D80)],
      ),
      _VectorLayer(
        Path()
          ..moveTo(43.0000, 143.0000)
          ..quadraticBezierTo(17.0000, 135.0000, 31.0000, 116.0000)
          ..quadraticBezierTo(44.0000, 126.0000, 43.0000, 143.0000)
          ..close(),
        Color(0xFF9BC9FF),
        null,
        1,
        [Color(0xFF9BC9FF), Color(0xFF806147)],
      ),
      _VectorLayer(
        Path()
          ..moveTo(40.0000, 128.0000)
          ..quadraticBezierTo(14.0000, 120.0000, 28.0000, 101.0000)
          ..quadraticBezierTo(41.0000, 111.0000, 40.0000, 128.0000)
          ..close(),
        Color(0xFF9BC9FF),
        null,
        1,
        [Color(0xFF9BC9FF), Color(0xFF806147)],
      ),
      _VectorLayer(
        Path()
          ..moveTo(37.0000, 113.0000)
          ..quadraticBezierTo(11.0000, 105.0000, 25.0000, 86.0000)
          ..quadraticBezierTo(38.0000, 96.0000, 37.0000, 113.0000)
          ..close(),
        Color(0xFF9BC9FF),
        null,
        1,
        [Color(0xFF9BC9FF), Color(0xFF806147)],
      ),
      _VectorLayer(
        Path()
          ..moveTo(34.0000, 98.0000)
          ..quadraticBezierTo(8.0000, 90.0000, 22.0000, 71.0000)
          ..quadraticBezierTo(35.0000, 81.0000, 34.0000, 98.0000)
          ..close(),
        Color(0xFF9BC9FF),
        null,
        1,
        [Color(0xFF9BC9FF), Color(0xFF806147)],
      ),
      _VectorLayer(
        Path()
          ..moveTo(31.0000, 83.0000)
          ..quadraticBezierTo(5.0000, 75.0000, 19.0000, 56.0000)
          ..quadraticBezierTo(32.0000, 66.0000, 31.0000, 83.0000)
          ..close(),
        Color(0xFF9BC9FF),
        null,
        1,
        [Color(0xFF9BC9FF), Color(0xFF806147)],
      ),
      _VectorLayer(
        Path()
          ..moveTo(157.0000, 143.0000)
          ..quadraticBezierTo(183.0000, 135.0000, 169.0000, 116.0000)
          ..quadraticBezierTo(156.0000, 126.0000, 157.0000, 143.0000)
          ..close(),
        Color(0xFF9BC9FF),
        null,
        1,
        [Color(0xFF9BC9FF), Color(0xFF806147)],
      ),
      _VectorLayer(
        Path()
          ..moveTo(160.0000, 128.0000)
          ..quadraticBezierTo(186.0000, 120.0000, 172.0000, 101.0000)
          ..quadraticBezierTo(159.0000, 111.0000, 160.0000, 128.0000)
          ..close(),
        Color(0xFF9BC9FF),
        null,
        1,
        [Color(0xFF9BC9FF), Color(0xFF806147)],
      ),
      _VectorLayer(
        Path()
          ..moveTo(163.0000, 113.0000)
          ..quadraticBezierTo(189.0000, 105.0000, 175.0000, 86.0000)
          ..quadraticBezierTo(162.0000, 96.0000, 163.0000, 113.0000)
          ..close(),
        Color(0xFF9BC9FF),
        null,
        1,
        [Color(0xFF9BC9FF), Color(0xFF806147)],
      ),
      _VectorLayer(
        Path()
          ..moveTo(166.0000, 98.0000)
          ..quadraticBezierTo(192.0000, 90.0000, 178.0000, 71.0000)
          ..quadraticBezierTo(165.0000, 81.0000, 166.0000, 98.0000)
          ..close(),
        Color(0xFF9BC9FF),
        null,
        1,
        [Color(0xFF9BC9FF), Color(0xFF806147)],
      ),
      _VectorLayer(
        Path()
          ..moveTo(169.0000, 83.0000)
          ..quadraticBezierTo(195.0000, 75.0000, 181.0000, 56.0000)
          ..quadraticBezierTo(168.0000, 66.0000, 169.0000, 83.0000)
          ..close(),
        Color(0xFF9BC9FF),
        null,
        1,
        [Color(0xFF9BC9FF), Color(0xFF806147)],
      ),
      _VectorLayer(
        Path()
          ..moveTo(100.0000, 25.0000)
          ..lineTo(129.0000, 39.7705)
          ..lineTo(156.2917, 57.5000)
          ..lineTo(158.0000, 90.0000)
          ..lineTo(156.2917, 122.5000)
          ..lineTo(129.0000, 140.2295)
          ..lineTo(100.0000, 155.0000)
          ..lineTo(71.0000, 140.2295)
          ..lineTo(43.7083, 122.5000)
          ..lineTo(42.0000, 90.0000)
          ..lineTo(43.7083, 57.5000)
          ..lineTo(71.0000, 39.7705)
          ..close(),
        Color(0xFF9BC9FF),
        Color(0xFFF4DEFF),
        1.5,
        [Color(0xFF9BC9FF), Color(0xFF8D6BA1)],
      ),
      _VectorLayer(
        Path()
          ..moveTo(100.0000, 25.0000)
          ..lineTo(129.0000, 39.7705)
          ..lineTo(121.5000, 52.7609)
          ..lineTo(100.0000, 41.0000)
          ..close(),
        Color(0xFF9BC9FF),
        null,
        1,
        null,
      ),
      _VectorLayer(
        Path()
          ..moveTo(129.0000, 39.7705)
          ..lineTo(156.2917, 57.5000)
          ..lineTo(142.4352, 65.5000)
          ..lineTo(121.5000, 52.7609)
          ..close(),
        Color(0xFFE6DCFF),
        null,
        1,
        null,
      ),
      _VectorLayer(
        Path()
          ..moveTo(156.2917, 57.5000)
          ..lineTo(158.0000, 90.0000)
          ..lineTo(143.0000, 90.0000)
          ..lineTo(142.4352, 65.5000)
          ..close(),
        Color(0xFF6155A4),
        null,
        1,
        null,
      ),
      _VectorLayer(
        Path()
          ..moveTo(158.0000, 90.0000)
          ..lineTo(156.2917, 122.5000)
          ..lineTo(142.4352, 114.5000)
          ..lineTo(143.0000, 90.0000)
          ..close(),
        Color(0xFF9BC9FF),
        null,
        1,
        null,
      ),
      _VectorLayer(
        Path()
          ..moveTo(156.2917, 122.5000)
          ..lineTo(129.0000, 140.2295)
          ..lineTo(121.5000, 127.2391)
          ..lineTo(142.4352, 114.5000)
          ..close(),
        Color(0xFFE6DCFF),
        null,
        1,
        null,
      ),
      _VectorLayer(
        Path()
          ..moveTo(129.0000, 140.2295)
          ..lineTo(100.0000, 155.0000)
          ..lineTo(100.0000, 139.0000)
          ..lineTo(121.5000, 127.2391)
          ..close(),
        Color(0xFF6155A4),
        null,
        1,
        null,
      ),
      _VectorLayer(
        Path()
          ..moveTo(100.0000, 155.0000)
          ..lineTo(71.0000, 140.2295)
          ..lineTo(78.5000, 127.2391)
          ..lineTo(100.0000, 139.0000)
          ..close(),
        Color(0xFF9BC9FF),
        null,
        1,
        null,
      ),
      _VectorLayer(
        Path()
          ..moveTo(71.0000, 140.2295)
          ..lineTo(43.7083, 122.5000)
          ..lineTo(57.5648, 114.5000)
          ..lineTo(78.5000, 127.2391)
          ..close(),
        Color(0xFFE6DCFF),
        null,
        1,
        null,
      ),
      _VectorLayer(
        Path()
          ..moveTo(43.7083, 122.5000)
          ..lineTo(42.0000, 90.0000)
          ..lineTo(57.0000, 90.0000)
          ..lineTo(57.5648, 114.5000)
          ..close(),
        Color(0xFF6155A4),
        null,
        1,
        null,
      ),
      _VectorLayer(
        Path()
          ..moveTo(42.0000, 90.0000)
          ..lineTo(43.7083, 57.5000)
          ..lineTo(57.5648, 65.5000)
          ..lineTo(57.0000, 90.0000)
          ..close(),
        Color(0xFF9BC9FF),
        null,
        1,
        null,
      ),
      _VectorLayer(
        Path()
          ..moveTo(43.7083, 57.5000)
          ..lineTo(71.0000, 39.7705)
          ..lineTo(78.5000, 52.7609)
          ..lineTo(57.5648, 65.5000)
          ..close(),
        Color(0xFFE6DCFF),
        null,
        1,
        null,
      ),
      _VectorLayer(
        Path()
          ..moveTo(71.0000, 39.7705)
          ..lineTo(100.0000, 25.0000)
          ..lineTo(100.0000, 41.0000)
          ..lineTo(78.5000, 52.7609)
          ..close(),
        Color(0xFF6155A4),
        null,
        1,
        null,
      ),
      _VectorLayer(
        Path()
          ..moveTo(100.0000, 41.0000)
          ..lineTo(121.5000, 52.7609)
          ..lineTo(142.4352, 65.5000)
          ..lineTo(143.0000, 90.0000)
          ..lineTo(142.4352, 114.5000)
          ..lineTo(121.5000, 127.2391)
          ..lineTo(100.0000, 139.0000)
          ..lineTo(78.5000, 127.2391)
          ..lineTo(57.5648, 114.5000)
          ..lineTo(57.0000, 90.0000)
          ..lineTo(57.5648, 65.5000)
          ..lineTo(78.5000, 52.7609)
          ..close(),
        Color(0xFF252A59),
        Color(0xFF9BC9FF),
        1.8,
        [Color(0xFF333B6D), Color(0xFF111B3A)],
      ),
      _VectorLayer(
        Path()
          ..moveTo(78.0000, 78.0000)
          ..cubicTo(95.0000, 60.0000, 104.0000, 108.0000, 122.0000, 87.0000)
          ..moveTo(78.0000, 95.0000)
          ..cubicTo(95.0000, 77.0000, 104.0000, 125.0000, 122.0000, 104.0000),
        null,
        Color(0xFFD8EEFF),
        4,
        null,
      ),
      _VectorLayer(
        Path()
          ..moveTo(31.0000, 35.0000)
          ..lineTo(31.7920, 38.2080)
          ..lineTo(35.0000, 39.0000)
          ..lineTo(31.7920, 39.7920)
          ..lineTo(31.0000, 43.0000)
          ..lineTo(30.2080, 39.7920)
          ..lineTo(27.0000, 39.0000)
          ..lineTo(30.2080, 38.2080)
          ..close(),
        Color(0xFF9BC9FF),
        null,
        1,
        null,
      ),
      _VectorLayer(
        Path()
          ..moveTo(167.0000, 39.0000)
          ..lineTo(167.7920, 42.2080)
          ..lineTo(171.0000, 43.0000)
          ..lineTo(167.7920, 43.7920)
          ..lineTo(167.0000, 47.0000)
          ..lineTo(166.2080, 43.7920)
          ..lineTo(163.0000, 43.0000)
          ..lineTo(166.2080, 42.2080)
          ..close(),
        Color(0xFF9BC9FF),
        null,
        1,
        null,
      ),
      _VectorLayer(
        Path()
          ..moveTo(157.0000, 163.0000)
          ..lineTo(157.7920, 166.2080)
          ..lineTo(161.0000, 167.0000)
          ..lineTo(157.7920, 167.7920)
          ..lineTo(157.0000, 171.0000)
          ..lineTo(156.2080, 167.7920)
          ..lineTo(153.0000, 167.0000)
          ..lineTo(156.2080, 166.2080)
          ..close(),
        Color(0xFF9BC9FF),
        null,
        1,
        null,
      ),
    ],
  ),
  'ranks/rank_resonance': (
    const Size(200, 200),
    [
      _VectorLayer(
        Path()
          ..moveTo(180.0000, 93.0000)
          ..cubicTo(180.0000, 137.1828, 144.1828, 173.0000, 100.0000, 173.0000)
          ..cubicTo(55.8172, 173.0000, 20.0000, 137.1828, 20.0000, 93.0000)
          ..cubicTo(20.0000, 48.8172, 55.8172, 13.0000, 100.0000, 13.0000)
          ..cubicTo(144.1828, 13.0000, 180.0000, 48.8172, 180.0000, 93.0000)
          ..close(),
        Color(0x12AE85FF),
        null,
        1,
        null,
      ),
      _VectorLayer(
        Path()
          ..moveTo(64.0000, 128.0000)
          ..lineTo(85.0000, 128.0000)
          ..lineTo(91.0000, 188.0000)
          ..lineTo(69.0000, 173.0000)
          ..close(),
        Color(0xFF8470DC),
        null,
        1,
        [Color(0xFFCCADFF), Color(0xFF6645B5)],
      ),
      _VectorLayer(
        Path()
          ..moveTo(85.0000, 128.0000)
          ..lineTo(106.0000, 128.0000)
          ..lineTo(112.0000, 190.0000)
          ..lineTo(91.0000, 188.0000)
          ..close(),
        Color(0xFFB195FC),
        null,
        1,
        [Color(0xFFB9A5FF), Color(0xFF7661E5)],
      ),
      _VectorLayer(
        Path()
          ..moveTo(106.0000, 128.0000)
          ..lineTo(127.0000, 128.0000)
          ..lineTo(131.0000, 173.0000)
          ..lineTo(112.0000, 190.0000)
          ..close(),
        Color(0xFF7351C0),
        null,
        1,
        [Color(0xFF6369D2), Color(0xFF303D80)],
      ),
      _VectorLayer(
        Path()
          ..moveTo(43.0000, 143.0000)
          ..quadraticBezierTo(17.0000, 135.0000, 31.0000, 116.0000)
          ..quadraticBezierTo(44.0000, 126.0000, 43.0000, 143.0000)
          ..close(),
        Color(0xFFC6B8FF),
        null,
        1,
        [Color(0xFFC6B8FF), Color(0xFF806147)],
      ),
      _VectorLayer(
        Path()
          ..moveTo(40.0000, 128.0000)
          ..quadraticBezierTo(14.0000, 120.0000, 28.0000, 101.0000)
          ..quadraticBezierTo(41.0000, 111.0000, 40.0000, 128.0000)
          ..close(),
        Color(0xFFC6B8FF),
        null,
        1,
        [Color(0xFFC6B8FF), Color(0xFF806147)],
      ),
      _VectorLayer(
        Path()
          ..moveTo(37.0000, 113.0000)
          ..quadraticBezierTo(11.0000, 105.0000, 25.0000, 86.0000)
          ..quadraticBezierTo(38.0000, 96.0000, 37.0000, 113.0000)
          ..close(),
        Color(0xFFC6B8FF),
        null,
        1,
        [Color(0xFFC6B8FF), Color(0xFF806147)],
      ),
      _VectorLayer(
        Path()
          ..moveTo(34.0000, 98.0000)
          ..quadraticBezierTo(8.0000, 90.0000, 22.0000, 71.0000)
          ..quadraticBezierTo(35.0000, 81.0000, 34.0000, 98.0000)
          ..close(),
        Color(0xFFC6B8FF),
        null,
        1,
        [Color(0xFFC6B8FF), Color(0xFF806147)],
      ),
      _VectorLayer(
        Path()
          ..moveTo(31.0000, 83.0000)
          ..quadraticBezierTo(5.0000, 75.0000, 19.0000, 56.0000)
          ..quadraticBezierTo(32.0000, 66.0000, 31.0000, 83.0000)
          ..close(),
        Color(0xFFC6B8FF),
        null,
        1,
        [Color(0xFFC6B8FF), Color(0xFF806147)],
      ),
      _VectorLayer(
        Path()
          ..moveTo(157.0000, 143.0000)
          ..quadraticBezierTo(183.0000, 135.0000, 169.0000, 116.0000)
          ..quadraticBezierTo(156.0000, 126.0000, 157.0000, 143.0000)
          ..close(),
        Color(0xFFC6B8FF),
        null,
        1,
        [Color(0xFFC6B8FF), Color(0xFF806147)],
      ),
      _VectorLayer(
        Path()
          ..moveTo(160.0000, 128.0000)
          ..quadraticBezierTo(186.0000, 120.0000, 172.0000, 101.0000)
          ..quadraticBezierTo(159.0000, 111.0000, 160.0000, 128.0000)
          ..close(),
        Color(0xFFC6B8FF),
        null,
        1,
        [Color(0xFFC6B8FF), Color(0xFF806147)],
      ),
      _VectorLayer(
        Path()
          ..moveTo(163.0000, 113.0000)
          ..quadraticBezierTo(189.0000, 105.0000, 175.0000, 86.0000)
          ..quadraticBezierTo(162.0000, 96.0000, 163.0000, 113.0000)
          ..close(),
        Color(0xFFC6B8FF),
        null,
        1,
        [Color(0xFFC6B8FF), Color(0xFF806147)],
      ),
      _VectorLayer(
        Path()
          ..moveTo(166.0000, 98.0000)
          ..quadraticBezierTo(192.0000, 90.0000, 178.0000, 71.0000)
          ..quadraticBezierTo(165.0000, 81.0000, 166.0000, 98.0000)
          ..close(),
        Color(0xFFC6B8FF),
        null,
        1,
        [Color(0xFFC6B8FF), Color(0xFF806147)],
      ),
      _VectorLayer(
        Path()
          ..moveTo(169.0000, 83.0000)
          ..quadraticBezierTo(195.0000, 75.0000, 181.0000, 56.0000)
          ..quadraticBezierTo(168.0000, 66.0000, 169.0000, 83.0000)
          ..close(),
        Color(0xFFC6B8FF),
        null,
        1,
        [Color(0xFFC6B8FF), Color(0xFF806147)],
      ),
      _VectorLayer(
        Path()
          ..moveTo(100.0000, 25.0000)
          ..lineTo(129.0000, 39.7705)
          ..lineTo(156.2917, 57.5000)
          ..lineTo(158.0000, 90.0000)
          ..lineTo(156.2917, 122.5000)
          ..lineTo(129.0000, 140.2295)
          ..lineTo(100.0000, 155.0000)
          ..lineTo(71.0000, 140.2295)
          ..lineTo(43.7083, 122.5000)
          ..lineTo(42.0000, 90.0000)
          ..lineTo(43.7083, 57.5000)
          ..lineTo(71.0000, 39.7705)
          ..close(),
        Color(0xFFC6B8FF),
        Color(0xFFF4DEFF),
        1.5,
        [Color(0xFFC6B8FF), Color(0xFF8D6BA1)],
      ),
      _VectorLayer(
        Path()
          ..moveTo(100.0000, 25.0000)
          ..lineTo(129.0000, 39.7705)
          ..lineTo(121.5000, 52.7609)
          ..lineTo(100.0000, 41.0000)
          ..close(),
        Color(0xFFC6B8FF),
        null,
        1,
        null,
      ),
      _VectorLayer(
        Path()
          ..moveTo(129.0000, 39.7705)
          ..lineTo(156.2917, 57.5000)
          ..lineTo(142.4352, 65.5000)
          ..lineTo(121.5000, 52.7609)
          ..close(),
        Color(0xFFE6DCFF),
        null,
        1,
        null,
      ),
      _VectorLayer(
        Path()
          ..moveTo(156.2917, 57.5000)
          ..lineTo(158.0000, 90.0000)
          ..lineTo(143.0000, 90.0000)
          ..lineTo(142.4352, 65.5000)
          ..close(),
        Color(0xFF6155A4),
        null,
        1,
        null,
      ),
      _VectorLayer(
        Path()
          ..moveTo(158.0000, 90.0000)
          ..lineTo(156.2917, 122.5000)
          ..lineTo(142.4352, 114.5000)
          ..lineTo(143.0000, 90.0000)
          ..close(),
        Color(0xFFC6B8FF),
        null,
        1,
        null,
      ),
      _VectorLayer(
        Path()
          ..moveTo(156.2917, 122.5000)
          ..lineTo(129.0000, 140.2295)
          ..lineTo(121.5000, 127.2391)
          ..lineTo(142.4352, 114.5000)
          ..close(),
        Color(0xFFE6DCFF),
        null,
        1,
        null,
      ),
      _VectorLayer(
        Path()
          ..moveTo(129.0000, 140.2295)
          ..lineTo(100.0000, 155.0000)
          ..lineTo(100.0000, 139.0000)
          ..lineTo(121.5000, 127.2391)
          ..close(),
        Color(0xFF6155A4),
        null,
        1,
        null,
      ),
      _VectorLayer(
        Path()
          ..moveTo(100.0000, 155.0000)
          ..lineTo(71.0000, 140.2295)
          ..lineTo(78.5000, 127.2391)
          ..lineTo(100.0000, 139.0000)
          ..close(),
        Color(0xFFC6B8FF),
        null,
        1,
        null,
      ),
      _VectorLayer(
        Path()
          ..moveTo(71.0000, 140.2295)
          ..lineTo(43.7083, 122.5000)
          ..lineTo(57.5648, 114.5000)
          ..lineTo(78.5000, 127.2391)
          ..close(),
        Color(0xFFE6DCFF),
        null,
        1,
        null,
      ),
      _VectorLayer(
        Path()
          ..moveTo(43.7083, 122.5000)
          ..lineTo(42.0000, 90.0000)
          ..lineTo(57.0000, 90.0000)
          ..lineTo(57.5648, 114.5000)
          ..close(),
        Color(0xFF6155A4),
        null,
        1,
        null,
      ),
      _VectorLayer(
        Path()
          ..moveTo(42.0000, 90.0000)
          ..lineTo(43.7083, 57.5000)
          ..lineTo(57.5648, 65.5000)
          ..lineTo(57.0000, 90.0000)
          ..close(),
        Color(0xFFC6B8FF),
        null,
        1,
        null,
      ),
      _VectorLayer(
        Path()
          ..moveTo(43.7083, 57.5000)
          ..lineTo(71.0000, 39.7705)
          ..lineTo(78.5000, 52.7609)
          ..lineTo(57.5648, 65.5000)
          ..close(),
        Color(0xFFE6DCFF),
        null,
        1,
        null,
      ),
      _VectorLayer(
        Path()
          ..moveTo(71.0000, 39.7705)
          ..lineTo(100.0000, 25.0000)
          ..lineTo(100.0000, 41.0000)
          ..lineTo(78.5000, 52.7609)
          ..close(),
        Color(0xFF6155A4),
        null,
        1,
        null,
      ),
      _VectorLayer(
        Path()
          ..moveTo(100.0000, 41.0000)
          ..lineTo(121.5000, 52.7609)
          ..lineTo(142.4352, 65.5000)
          ..lineTo(143.0000, 90.0000)
          ..lineTo(142.4352, 114.5000)
          ..lineTo(121.5000, 127.2391)
          ..lineTo(100.0000, 139.0000)
          ..lineTo(78.5000, 127.2391)
          ..lineTo(57.5648, 114.5000)
          ..lineTo(57.0000, 90.0000)
          ..lineTo(57.5648, 65.5000)
          ..lineTo(78.5000, 52.7609)
          ..close(),
        Color(0xFF252A59),
        Color(0xFFC6B8FF),
        1.8,
        [Color(0xFF333B6D), Color(0xFF111B3A)],
      ),
      _VectorLayer(
        Path()
          ..moveTo(109.0000, 90.0000)
          ..cubicTo(109.0000, 94.9706, 104.9706, 99.0000, 100.0000, 99.0000)
          ..cubicTo(95.0294, 99.0000, 91.0000, 94.9706, 91.0000, 90.0000)
          ..cubicTo(91.0000, 85.0294, 95.0294, 81.0000, 100.0000, 81.0000)
          ..cubicTo(104.9706, 81.0000, 109.0000, 85.0294, 109.0000, 90.0000)
          ..close(),
        null,
        Color(0xFFECE6FF),
        2,
        null,
      ),
      _VectorLayer(
        Path()
          ..moveTo(117.0000, 90.0000)
          ..cubicTo(117.0000, 99.3888, 109.3888, 107.0000, 100.0000, 107.0000)
          ..cubicTo(90.6112, 107.0000, 83.0000, 99.3888, 83.0000, 90.0000)
          ..cubicTo(83.0000, 80.6112, 90.6112, 73.0000, 100.0000, 73.0000)
          ..cubicTo(109.3888, 73.0000, 117.0000, 80.6112, 117.0000, 90.0000)
          ..close(),
        null,
        Color(0xFFECE6FF),
        2,
        null,
      ),
      _VectorLayer(
        Path()
          ..moveTo(125.0000, 90.0000)
          ..cubicTo(125.0000, 103.8071, 113.8071, 115.0000, 100.0000, 115.0000)
          ..cubicTo(86.1929, 115.0000, 75.0000, 103.8071, 75.0000, 90.0000)
          ..cubicTo(75.0000, 76.1929, 86.1929, 65.0000, 100.0000, 65.0000)
          ..cubicTo(113.8071, 65.0000, 125.0000, 76.1929, 125.0000, 90.0000)
          ..close(),
        null,
        Color(0xFFECE6FF),
        2,
        null,
      ),
      _VectorLayer(
        Path()
          ..moveTo(31.0000, 35.0000)
          ..lineTo(31.7920, 38.2080)
          ..lineTo(35.0000, 39.0000)
          ..lineTo(31.7920, 39.7920)
          ..lineTo(31.0000, 43.0000)
          ..lineTo(30.2080, 39.7920)
          ..lineTo(27.0000, 39.0000)
          ..lineTo(30.2080, 38.2080)
          ..close(),
        Color(0xFFC6B8FF),
        null,
        1,
        null,
      ),
      _VectorLayer(
        Path()
          ..moveTo(167.0000, 39.0000)
          ..lineTo(167.7920, 42.2080)
          ..lineTo(171.0000, 43.0000)
          ..lineTo(167.7920, 43.7920)
          ..lineTo(167.0000, 47.0000)
          ..lineTo(166.2080, 43.7920)
          ..lineTo(163.0000, 43.0000)
          ..lineTo(166.2080, 42.2080)
          ..close(),
        Color(0xFFC6B8FF),
        null,
        1,
        null,
      ),
      _VectorLayer(
        Path()
          ..moveTo(157.0000, 163.0000)
          ..lineTo(157.7920, 166.2080)
          ..lineTo(161.0000, 167.0000)
          ..lineTo(157.7920, 167.7920)
          ..lineTo(157.0000, 171.0000)
          ..lineTo(156.2080, 167.7920)
          ..lineTo(153.0000, 167.0000)
          ..lineTo(156.2080, 166.2080)
          ..close(),
        Color(0xFFC6B8FF),
        null,
        1,
        null,
      ),
    ],
  ),
  'ranks/rank_spectrum': (
    const Size(200, 200),
    [
      _VectorLayer(
        Path()
          ..moveTo(180.0000, 93.0000)
          ..cubicTo(180.0000, 137.1828, 144.1828, 173.0000, 100.0000, 173.0000)
          ..cubicTo(55.8172, 173.0000, 20.0000, 137.1828, 20.0000, 93.0000)
          ..cubicTo(20.0000, 48.8172, 55.8172, 13.0000, 100.0000, 13.0000)
          ..cubicTo(144.1828, 13.0000, 180.0000, 48.8172, 180.0000, 93.0000)
          ..close(),
        Color(0x12AE85FF),
        null,
        1,
        null,
      ),
      _VectorLayer(
        Path()
          ..moveTo(64.0000, 128.0000)
          ..lineTo(85.0000, 128.0000)
          ..lineTo(91.0000, 188.0000)
          ..lineTo(69.0000, 173.0000)
          ..close(),
        Color(0xFF8470DC),
        null,
        1,
        [Color(0xFFCCADFF), Color(0xFF6645B5)],
      ),
      _VectorLayer(
        Path()
          ..moveTo(85.0000, 128.0000)
          ..lineTo(106.0000, 128.0000)
          ..lineTo(112.0000, 190.0000)
          ..lineTo(91.0000, 188.0000)
          ..close(),
        Color(0xFFB195FC),
        null,
        1,
        [Color(0xFFB9A5FF), Color(0xFF7661E5)],
      ),
      _VectorLayer(
        Path()
          ..moveTo(106.0000, 128.0000)
          ..lineTo(127.0000, 128.0000)
          ..lineTo(131.0000, 173.0000)
          ..lineTo(112.0000, 190.0000)
          ..close(),
        Color(0xFF7351C0),
        null,
        1,
        [Color(0xFF6369D2), Color(0xFF303D80)],
      ),
      _VectorLayer(
        Path()
          ..moveTo(43.0000, 143.0000)
          ..quadraticBezierTo(17.0000, 135.0000, 31.0000, 116.0000)
          ..quadraticBezierTo(44.0000, 126.0000, 43.0000, 143.0000)
          ..close(),
        Color(0xFFECA7EB),
        null,
        1,
        [Color(0xFFECA7EB), Color(0xFF806147)],
      ),
      _VectorLayer(
        Path()
          ..moveTo(40.0000, 128.0000)
          ..quadraticBezierTo(14.0000, 120.0000, 28.0000, 101.0000)
          ..quadraticBezierTo(41.0000, 111.0000, 40.0000, 128.0000)
          ..close(),
        Color(0xFFECA7EB),
        null,
        1,
        [Color(0xFFECA7EB), Color(0xFF806147)],
      ),
      _VectorLayer(
        Path()
          ..moveTo(37.0000, 113.0000)
          ..quadraticBezierTo(11.0000, 105.0000, 25.0000, 86.0000)
          ..quadraticBezierTo(38.0000, 96.0000, 37.0000, 113.0000)
          ..close(),
        Color(0xFFECA7EB),
        null,
        1,
        [Color(0xFFECA7EB), Color(0xFF806147)],
      ),
      _VectorLayer(
        Path()
          ..moveTo(34.0000, 98.0000)
          ..quadraticBezierTo(8.0000, 90.0000, 22.0000, 71.0000)
          ..quadraticBezierTo(35.0000, 81.0000, 34.0000, 98.0000)
          ..close(),
        Color(0xFFECA7EB),
        null,
        1,
        [Color(0xFFECA7EB), Color(0xFF806147)],
      ),
      _VectorLayer(
        Path()
          ..moveTo(31.0000, 83.0000)
          ..quadraticBezierTo(5.0000, 75.0000, 19.0000, 56.0000)
          ..quadraticBezierTo(32.0000, 66.0000, 31.0000, 83.0000)
          ..close(),
        Color(0xFFECA7EB),
        null,
        1,
        [Color(0xFFECA7EB), Color(0xFF806147)],
      ),
      _VectorLayer(
        Path()
          ..moveTo(157.0000, 143.0000)
          ..quadraticBezierTo(183.0000, 135.0000, 169.0000, 116.0000)
          ..quadraticBezierTo(156.0000, 126.0000, 157.0000, 143.0000)
          ..close(),
        Color(0xFFECA7EB),
        null,
        1,
        [Color(0xFFECA7EB), Color(0xFF806147)],
      ),
      _VectorLayer(
        Path()
          ..moveTo(160.0000, 128.0000)
          ..quadraticBezierTo(186.0000, 120.0000, 172.0000, 101.0000)
          ..quadraticBezierTo(159.0000, 111.0000, 160.0000, 128.0000)
          ..close(),
        Color(0xFFECA7EB),
        null,
        1,
        [Color(0xFFECA7EB), Color(0xFF806147)],
      ),
      _VectorLayer(
        Path()
          ..moveTo(163.0000, 113.0000)
          ..quadraticBezierTo(189.0000, 105.0000, 175.0000, 86.0000)
          ..quadraticBezierTo(162.0000, 96.0000, 163.0000, 113.0000)
          ..close(),
        Color(0xFFECA7EB),
        null,
        1,
        [Color(0xFFECA7EB), Color(0xFF806147)],
      ),
      _VectorLayer(
        Path()
          ..moveTo(166.0000, 98.0000)
          ..quadraticBezierTo(192.0000, 90.0000, 178.0000, 71.0000)
          ..quadraticBezierTo(165.0000, 81.0000, 166.0000, 98.0000)
          ..close(),
        Color(0xFFECA7EB),
        null,
        1,
        [Color(0xFFECA7EB), Color(0xFF806147)],
      ),
      _VectorLayer(
        Path()
          ..moveTo(169.0000, 83.0000)
          ..quadraticBezierTo(195.0000, 75.0000, 181.0000, 56.0000)
          ..quadraticBezierTo(168.0000, 66.0000, 169.0000, 83.0000)
          ..close(),
        Color(0xFFECA7EB),
        null,
        1,
        [Color(0xFFECA7EB), Color(0xFF806147)],
      ),
      _VectorLayer(
        Path()
          ..moveTo(100.0000, 25.0000)
          ..lineTo(122.1956, 36.4150)
          ..lineTo(145.9619, 44.0381)
          ..lineTo(153.5850, 67.8044)
          ..lineTo(165.0000, 90.0000)
          ..lineTo(153.5850, 112.1956)
          ..lineTo(145.9619, 135.9619)
          ..lineTo(122.1956, 143.5850)
          ..lineTo(100.0000, 155.0000)
          ..lineTo(77.8044, 143.5850)
          ..lineTo(54.0381, 135.9619)
          ..lineTo(46.4150, 112.1956)
          ..lineTo(35.0000, 90.0000)
          ..lineTo(46.4150, 67.8044)
          ..lineTo(54.0381, 44.0381)
          ..lineTo(77.8044, 36.4150)
          ..close(),
        Color(0xFFECA7EB),
        Color(0xFFF4DEFF),
        1.5,
        [Color(0xFFECA7EB), Color(0xFF8D6BA1)],
      ),
      _VectorLayer(
        Path()
          ..moveTo(100.0000, 25.0000)
          ..lineTo(122.1956, 36.4150)
          ..lineTo(116.4554, 50.2732)
          ..lineTo(100.0000, 41.0000)
          ..close(),
        Color(0xFFECA7EB),
        null,
        1,
        null,
      ),
      _VectorLayer(
        Path()
          ..moveTo(122.1956, 36.4150)
          ..lineTo(145.9619, 44.0381)
          ..lineTo(134.6482, 55.3518)
          ..lineTo(116.4554, 50.2732)
          ..close(),
        Color(0xFFE6DCFF),
        null,
        1,
        null,
      ),
      _VectorLayer(
        Path()
          ..moveTo(145.9619, 44.0381)
          ..lineTo(153.5850, 67.8044)
          ..lineTo(139.7268, 73.5446)
          ..lineTo(134.6482, 55.3518)
          ..close(),
        Color(0xFF6155A4),
        null,
        1,
        null,
      ),
      _VectorLayer(
        Path()
          ..moveTo(153.5850, 67.8044)
          ..lineTo(165.0000, 90.0000)
          ..lineTo(149.0000, 90.0000)
          ..lineTo(139.7268, 73.5446)
          ..close(),
        Color(0xFFECA7EB),
        null,
        1,
        null,
      ),
      _VectorLayer(
        Path()
          ..moveTo(165.0000, 90.0000)
          ..lineTo(153.5850, 112.1956)
          ..lineTo(139.7268, 106.4554)
          ..lineTo(149.0000, 90.0000)
          ..close(),
        Color(0xFFE6DCFF),
        null,
        1,
        null,
      ),
      _VectorLayer(
        Path()
          ..moveTo(153.5850, 112.1956)
          ..lineTo(145.9619, 135.9619)
          ..lineTo(134.6482, 124.6482)
          ..lineTo(139.7268, 106.4554)
          ..close(),
        Color(0xFF6155A4),
        null,
        1,
        null,
      ),
      _VectorLayer(
        Path()
          ..moveTo(145.9619, 135.9619)
          ..lineTo(122.1956, 143.5850)
          ..lineTo(116.4554, 129.7268)
          ..lineTo(134.6482, 124.6482)
          ..close(),
        Color(0xFFECA7EB),
        null,
        1,
        null,
      ),
      _VectorLayer(
        Path()
          ..moveTo(122.1956, 143.5850)
          ..lineTo(100.0000, 155.0000)
          ..lineTo(100.0000, 139.0000)
          ..lineTo(116.4554, 129.7268)
          ..close(),
        Color(0xFFE6DCFF),
        null,
        1,
        null,
      ),
      _VectorLayer(
        Path()
          ..moveTo(100.0000, 155.0000)
          ..lineTo(77.8044, 143.5850)
          ..lineTo(83.5446, 129.7268)
          ..lineTo(100.0000, 139.0000)
          ..close(),
        Color(0xFF6155A4),
        null,
        1,
        null,
      ),
      _VectorLayer(
        Path()
          ..moveTo(77.8044, 143.5850)
          ..lineTo(54.0381, 135.9619)
          ..lineTo(65.3518, 124.6482)
          ..lineTo(83.5446, 129.7268)
          ..close(),
        Color(0xFFECA7EB),
        null,
        1,
        null,
      ),
      _VectorLayer(
        Path()
          ..moveTo(54.0381, 135.9619)
          ..lineTo(46.4150, 112.1956)
          ..lineTo(60.2732, 106.4554)
          ..lineTo(65.3518, 124.6482)
          ..close(),
        Color(0xFFE6DCFF),
        null,
        1,
        null,
      ),
      _VectorLayer(
        Path()
          ..moveTo(46.4150, 112.1956)
          ..lineTo(35.0000, 90.0000)
          ..lineTo(51.0000, 90.0000)
          ..lineTo(60.2732, 106.4554)
          ..close(),
        Color(0xFF6155A4),
        null,
        1,
        null,
      ),
      _VectorLayer(
        Path()
          ..moveTo(35.0000, 90.0000)
          ..lineTo(46.4150, 67.8044)
          ..lineTo(60.2732, 73.5446)
          ..lineTo(51.0000, 90.0000)
          ..close(),
        Color(0xFFECA7EB),
        null,
        1,
        null,
      ),
      _VectorLayer(
        Path()
          ..moveTo(46.4150, 67.8044)
          ..lineTo(54.0381, 44.0381)
          ..lineTo(65.3518, 55.3518)
          ..lineTo(60.2732, 73.5446)
          ..close(),
        Color(0xFFE6DCFF),
        null,
        1,
        null,
      ),
      _VectorLayer(
        Path()
          ..moveTo(54.0381, 44.0381)
          ..lineTo(77.8044, 36.4150)
          ..lineTo(83.5446, 50.2732)
          ..lineTo(65.3518, 55.3518)
          ..close(),
        Color(0xFF6155A4),
        null,
        1,
        null,
      ),
      _VectorLayer(
        Path()
          ..moveTo(77.8044, 36.4150)
          ..lineTo(100.0000, 25.0000)
          ..lineTo(100.0000, 41.0000)
          ..lineTo(83.5446, 50.2732)
          ..close(),
        Color(0xFFECA7EB),
        null,
        1,
        null,
      ),
      _VectorLayer(
        Path()
          ..moveTo(100.0000, 41.0000)
          ..lineTo(116.4554, 50.2732)
          ..lineTo(134.6482, 55.3518)
          ..lineTo(139.7268, 73.5446)
          ..lineTo(149.0000, 90.0000)
          ..lineTo(139.7268, 106.4554)
          ..lineTo(134.6482, 124.6482)
          ..lineTo(116.4554, 129.7268)
          ..lineTo(100.0000, 139.0000)
          ..lineTo(83.5446, 129.7268)
          ..lineTo(65.3518, 124.6482)
          ..lineTo(60.2732, 106.4554)
          ..lineTo(51.0000, 90.0000)
          ..lineTo(60.2732, 73.5446)
          ..lineTo(65.3518, 55.3518)
          ..lineTo(83.5446, 50.2732)
          ..close(),
        Color(0xFF252A59),
        Color(0xFFECA7EB),
        1.8,
        [Color(0xFF333B6D), Color(0xFF111B3A)],
      ),
      _VectorLayer(
        Path()
          ..moveTo(78.0000, 108.0000)
          ..lineTo(91.0000, 72.0000)
          ..lineTo(97.0000, 72.0000)
          ..lineTo(84.0000, 108.0000)
          ..close(),
        Color(0xFFB7A2FF),
        null,
        1,
        null,
      ),
      _VectorLayer(
        Path()
          ..moveTo(85.0000, 108.0000)
          ..lineTo(94.0000, 72.0000)
          ..lineTo(100.0000, 72.0000)
          ..lineTo(91.0000, 108.0000)
          ..close(),
        Color(0xFFBAE2FF),
        null,
        1,
        null,
      ),
      _VectorLayer(
        Path()
          ..moveTo(92.0000, 108.0000)
          ..lineTo(97.0000, 72.0000)
          ..lineTo(103.0000, 72.0000)
          ..lineTo(98.0000, 108.0000)
          ..close(),
        Color(0xFF97E5DF),
        null,
        1,
        null,
      ),
      _VectorLayer(
        Path()
          ..moveTo(99.0000, 108.0000)
          ..lineTo(100.0000, 72.0000)
          ..lineTo(106.0000, 72.0000)
          ..lineTo(105.0000, 108.0000)
          ..close(),
        Color(0xFFEDBBFA),
        null,
        1,
        null,
      ),
      _VectorLayer(
        Path()
          ..moveTo(106.0000, 108.0000)
          ..lineTo(103.0000, 72.0000)
          ..lineTo(109.0000, 72.0000)
          ..lineTo(112.0000, 108.0000)
          ..close(),
        Color(0xFFFFDFA3),
        null,
        1,
        null,
      ),
      _VectorLayer(
        Path()
          ..moveTo(31.0000, 35.0000)
          ..lineTo(31.7920, 38.2080)
          ..lineTo(35.0000, 39.0000)
          ..lineTo(31.7920, 39.7920)
          ..lineTo(31.0000, 43.0000)
          ..lineTo(30.2080, 39.7920)
          ..lineTo(27.0000, 39.0000)
          ..lineTo(30.2080, 38.2080)
          ..close(),
        Color(0xFFECA7EB),
        null,
        1,
        null,
      ),
      _VectorLayer(
        Path()
          ..moveTo(167.0000, 39.0000)
          ..lineTo(167.7920, 42.2080)
          ..lineTo(171.0000, 43.0000)
          ..lineTo(167.7920, 43.7920)
          ..lineTo(167.0000, 47.0000)
          ..lineTo(166.2080, 43.7920)
          ..lineTo(163.0000, 43.0000)
          ..lineTo(166.2080, 42.2080)
          ..close(),
        Color(0xFFECA7EB),
        null,
        1,
        null,
      ),
      _VectorLayer(
        Path()
          ..moveTo(157.0000, 163.0000)
          ..lineTo(157.7920, 166.2080)
          ..lineTo(161.0000, 167.0000)
          ..lineTo(157.7920, 167.7920)
          ..lineTo(157.0000, 171.0000)
          ..lineTo(156.2080, 167.7920)
          ..lineTo(153.0000, 167.0000)
          ..lineTo(156.2080, 166.2080)
          ..close(),
        Color(0xFFECA7EB),
        null,
        1,
        null,
      ),
    ],
  ),
  'ranks/rank_synthesis': (
    const Size(200, 200),
    [
      _VectorLayer(
        Path()
          ..moveTo(180.0000, 93.0000)
          ..cubicTo(180.0000, 137.1828, 144.1828, 173.0000, 100.0000, 173.0000)
          ..cubicTo(55.8172, 173.0000, 20.0000, 137.1828, 20.0000, 93.0000)
          ..cubicTo(20.0000, 48.8172, 55.8172, 13.0000, 100.0000, 13.0000)
          ..cubicTo(144.1828, 13.0000, 180.0000, 48.8172, 180.0000, 93.0000)
          ..close(),
        Color(0x12AE85FF),
        null,
        1,
        null,
      ),
      _VectorLayer(
        Path()
          ..moveTo(64.0000, 128.0000)
          ..lineTo(85.0000, 128.0000)
          ..lineTo(91.0000, 188.0000)
          ..lineTo(69.0000, 173.0000)
          ..close(),
        Color(0xFF8470DC),
        null,
        1,
        [Color(0xFFCCADFF), Color(0xFF6645B5)],
      ),
      _VectorLayer(
        Path()
          ..moveTo(85.0000, 128.0000)
          ..lineTo(106.0000, 128.0000)
          ..lineTo(112.0000, 190.0000)
          ..lineTo(91.0000, 188.0000)
          ..close(),
        Color(0xFFB195FC),
        null,
        1,
        [Color(0xFFB9A5FF), Color(0xFF7661E5)],
      ),
      _VectorLayer(
        Path()
          ..moveTo(106.0000, 128.0000)
          ..lineTo(127.0000, 128.0000)
          ..lineTo(131.0000, 173.0000)
          ..lineTo(112.0000, 190.0000)
          ..close(),
        Color(0xFF7351C0),
        null,
        1,
        [Color(0xFF6369D2), Color(0xFF303D80)],
      ),
      _VectorLayer(
        Path()
          ..moveTo(43.0000, 143.0000)
          ..quadraticBezierTo(17.0000, 135.0000, 31.0000, 116.0000)
          ..quadraticBezierTo(44.0000, 126.0000, 43.0000, 143.0000)
          ..close(),
        Color(0xFFAFEBE6),
        null,
        1,
        [Color(0xFFAFEBE6), Color(0xFF806147)],
      ),
      _VectorLayer(
        Path()
          ..moveTo(40.0000, 128.0000)
          ..quadraticBezierTo(14.0000, 120.0000, 28.0000, 101.0000)
          ..quadraticBezierTo(41.0000, 111.0000, 40.0000, 128.0000)
          ..close(),
        Color(0xFFAFEBE6),
        null,
        1,
        [Color(0xFFAFEBE6), Color(0xFF806147)],
      ),
      _VectorLayer(
        Path()
          ..moveTo(37.0000, 113.0000)
          ..quadraticBezierTo(11.0000, 105.0000, 25.0000, 86.0000)
          ..quadraticBezierTo(38.0000, 96.0000, 37.0000, 113.0000)
          ..close(),
        Color(0xFFAFEBE6),
        null,
        1,
        [Color(0xFFAFEBE6), Color(0xFF806147)],
      ),
      _VectorLayer(
        Path()
          ..moveTo(34.0000, 98.0000)
          ..quadraticBezierTo(8.0000, 90.0000, 22.0000, 71.0000)
          ..quadraticBezierTo(35.0000, 81.0000, 34.0000, 98.0000)
          ..close(),
        Color(0xFFAFEBE6),
        null,
        1,
        [Color(0xFFAFEBE6), Color(0xFF806147)],
      ),
      _VectorLayer(
        Path()
          ..moveTo(31.0000, 83.0000)
          ..quadraticBezierTo(5.0000, 75.0000, 19.0000, 56.0000)
          ..quadraticBezierTo(32.0000, 66.0000, 31.0000, 83.0000)
          ..close(),
        Color(0xFFAFEBE6),
        null,
        1,
        [Color(0xFFAFEBE6), Color(0xFF806147)],
      ),
      _VectorLayer(
        Path()
          ..moveTo(157.0000, 143.0000)
          ..quadraticBezierTo(183.0000, 135.0000, 169.0000, 116.0000)
          ..quadraticBezierTo(156.0000, 126.0000, 157.0000, 143.0000)
          ..close(),
        Color(0xFFAFEBE6),
        null,
        1,
        [Color(0xFFAFEBE6), Color(0xFF806147)],
      ),
      _VectorLayer(
        Path()
          ..moveTo(160.0000, 128.0000)
          ..quadraticBezierTo(186.0000, 120.0000, 172.0000, 101.0000)
          ..quadraticBezierTo(159.0000, 111.0000, 160.0000, 128.0000)
          ..close(),
        Color(0xFFAFEBE6),
        null,
        1,
        [Color(0xFFAFEBE6), Color(0xFF806147)],
      ),
      _VectorLayer(
        Path()
          ..moveTo(163.0000, 113.0000)
          ..quadraticBezierTo(189.0000, 105.0000, 175.0000, 86.0000)
          ..quadraticBezierTo(162.0000, 96.0000, 163.0000, 113.0000)
          ..close(),
        Color(0xFFAFEBE6),
        null,
        1,
        [Color(0xFFAFEBE6), Color(0xFF806147)],
      ),
      _VectorLayer(
        Path()
          ..moveTo(166.0000, 98.0000)
          ..quadraticBezierTo(192.0000, 90.0000, 178.0000, 71.0000)
          ..quadraticBezierTo(165.0000, 81.0000, 166.0000, 98.0000)
          ..close(),
        Color(0xFFAFEBE6),
        null,
        1,
        [Color(0xFFAFEBE6), Color(0xFF806147)],
      ),
      _VectorLayer(
        Path()
          ..moveTo(169.0000, 83.0000)
          ..quadraticBezierTo(195.0000, 75.0000, 181.0000, 56.0000)
          ..quadraticBezierTo(168.0000, 66.0000, 169.0000, 83.0000)
          ..close(),
        Color(0xFFAFEBE6),
        null,
        1,
        [Color(0xFFAFEBE6), Color(0xFF806147)],
      ),
      _VectorLayer(
        Path()
          ..moveTo(100.0000, 25.0000)
          ..lineTo(122.1956, 36.4150)
          ..lineTo(145.9619, 44.0381)
          ..lineTo(153.5850, 67.8044)
          ..lineTo(165.0000, 90.0000)
          ..lineTo(153.5850, 112.1956)
          ..lineTo(145.9619, 135.9619)
          ..lineTo(122.1956, 143.5850)
          ..lineTo(100.0000, 155.0000)
          ..lineTo(77.8044, 143.5850)
          ..lineTo(54.0381, 135.9619)
          ..lineTo(46.4150, 112.1956)
          ..lineTo(35.0000, 90.0000)
          ..lineTo(46.4150, 67.8044)
          ..lineTo(54.0381, 44.0381)
          ..lineTo(77.8044, 36.4150)
          ..close(),
        Color(0xFFAFEBE6),
        Color(0xFFF4DEFF),
        1.5,
        [Color(0xFFAFEBE6), Color(0xFF8D6BA1)],
      ),
      _VectorLayer(
        Path()
          ..moveTo(100.0000, 25.0000)
          ..lineTo(122.1956, 36.4150)
          ..lineTo(116.4554, 50.2732)
          ..lineTo(100.0000, 41.0000)
          ..close(),
        Color(0xFFAFEBE6),
        null,
        1,
        null,
      ),
      _VectorLayer(
        Path()
          ..moveTo(122.1956, 36.4150)
          ..lineTo(145.9619, 44.0381)
          ..lineTo(134.6482, 55.3518)
          ..lineTo(116.4554, 50.2732)
          ..close(),
        Color(0xFFE6DCFF),
        null,
        1,
        null,
      ),
      _VectorLayer(
        Path()
          ..moveTo(145.9619, 44.0381)
          ..lineTo(153.5850, 67.8044)
          ..lineTo(139.7268, 73.5446)
          ..lineTo(134.6482, 55.3518)
          ..close(),
        Color(0xFF6155A4),
        null,
        1,
        null,
      ),
      _VectorLayer(
        Path()
          ..moveTo(153.5850, 67.8044)
          ..lineTo(165.0000, 90.0000)
          ..lineTo(149.0000, 90.0000)
          ..lineTo(139.7268, 73.5446)
          ..close(),
        Color(0xFFAFEBE6),
        null,
        1,
        null,
      ),
      _VectorLayer(
        Path()
          ..moveTo(165.0000, 90.0000)
          ..lineTo(153.5850, 112.1956)
          ..lineTo(139.7268, 106.4554)
          ..lineTo(149.0000, 90.0000)
          ..close(),
        Color(0xFFE6DCFF),
        null,
        1,
        null,
      ),
      _VectorLayer(
        Path()
          ..moveTo(153.5850, 112.1956)
          ..lineTo(145.9619, 135.9619)
          ..lineTo(134.6482, 124.6482)
          ..lineTo(139.7268, 106.4554)
          ..close(),
        Color(0xFF6155A4),
        null,
        1,
        null,
      ),
      _VectorLayer(
        Path()
          ..moveTo(145.9619, 135.9619)
          ..lineTo(122.1956, 143.5850)
          ..lineTo(116.4554, 129.7268)
          ..lineTo(134.6482, 124.6482)
          ..close(),
        Color(0xFFAFEBE6),
        null,
        1,
        null,
      ),
      _VectorLayer(
        Path()
          ..moveTo(122.1956, 143.5850)
          ..lineTo(100.0000, 155.0000)
          ..lineTo(100.0000, 139.0000)
          ..lineTo(116.4554, 129.7268)
          ..close(),
        Color(0xFFE6DCFF),
        null,
        1,
        null,
      ),
      _VectorLayer(
        Path()
          ..moveTo(100.0000, 155.0000)
          ..lineTo(77.8044, 143.5850)
          ..lineTo(83.5446, 129.7268)
          ..lineTo(100.0000, 139.0000)
          ..close(),
        Color(0xFF6155A4),
        null,
        1,
        null,
      ),
      _VectorLayer(
        Path()
          ..moveTo(77.8044, 143.5850)
          ..lineTo(54.0381, 135.9619)
          ..lineTo(65.3518, 124.6482)
          ..lineTo(83.5446, 129.7268)
          ..close(),
        Color(0xFFAFEBE6),
        null,
        1,
        null,
      ),
      _VectorLayer(
        Path()
          ..moveTo(54.0381, 135.9619)
          ..lineTo(46.4150, 112.1956)
          ..lineTo(60.2732, 106.4554)
          ..lineTo(65.3518, 124.6482)
          ..close(),
        Color(0xFFE6DCFF),
        null,
        1,
        null,
      ),
      _VectorLayer(
        Path()
          ..moveTo(46.4150, 112.1956)
          ..lineTo(35.0000, 90.0000)
          ..lineTo(51.0000, 90.0000)
          ..lineTo(60.2732, 106.4554)
          ..close(),
        Color(0xFF6155A4),
        null,
        1,
        null,
      ),
      _VectorLayer(
        Path()
          ..moveTo(35.0000, 90.0000)
          ..lineTo(46.4150, 67.8044)
          ..lineTo(60.2732, 73.5446)
          ..lineTo(51.0000, 90.0000)
          ..close(),
        Color(0xFFAFEBE6),
        null,
        1,
        null,
      ),
      _VectorLayer(
        Path()
          ..moveTo(46.4150, 67.8044)
          ..lineTo(54.0381, 44.0381)
          ..lineTo(65.3518, 55.3518)
          ..lineTo(60.2732, 73.5446)
          ..close(),
        Color(0xFFE6DCFF),
        null,
        1,
        null,
      ),
      _VectorLayer(
        Path()
          ..moveTo(54.0381, 44.0381)
          ..lineTo(77.8044, 36.4150)
          ..lineTo(83.5446, 50.2732)
          ..lineTo(65.3518, 55.3518)
          ..close(),
        Color(0xFF6155A4),
        null,
        1,
        null,
      ),
      _VectorLayer(
        Path()
          ..moveTo(77.8044, 36.4150)
          ..lineTo(100.0000, 25.0000)
          ..lineTo(100.0000, 41.0000)
          ..lineTo(83.5446, 50.2732)
          ..close(),
        Color(0xFFAFEBE6),
        null,
        1,
        null,
      ),
      _VectorLayer(
        Path()
          ..moveTo(100.0000, 41.0000)
          ..lineTo(116.4554, 50.2732)
          ..lineTo(134.6482, 55.3518)
          ..lineTo(139.7268, 73.5446)
          ..lineTo(149.0000, 90.0000)
          ..lineTo(139.7268, 106.4554)
          ..lineTo(134.6482, 124.6482)
          ..lineTo(116.4554, 129.7268)
          ..lineTo(100.0000, 139.0000)
          ..lineTo(83.5446, 129.7268)
          ..lineTo(65.3518, 124.6482)
          ..lineTo(60.2732, 106.4554)
          ..lineTo(51.0000, 90.0000)
          ..lineTo(60.2732, 73.5446)
          ..lineTo(65.3518, 55.3518)
          ..lineTo(83.5446, 50.2732)
          ..close(),
        Color(0xFF252A59),
        Color(0xFFAFEBE6),
        1.8,
        [Color(0xFF333B6D), Color(0xFF111B3A)],
      ),
      _VectorLayer(
        Path()
          ..moveTo(108.0000, 90.0000)
          ..cubicTo(108.0000, 99.9411, 99.9411, 108.0000, 90.0000, 108.0000)
          ..cubicTo(80.0589, 108.0000, 72.0000, 99.9411, 72.0000, 90.0000)
          ..cubicTo(72.0000, 80.0589, 80.0589, 72.0000, 90.0000, 72.0000)
          ..cubicTo(99.9411, 72.0000, 108.0000, 80.0589, 108.0000, 90.0000)
          ..close(),
        null,
        Color(0xFFD4FFF7),
        3,
        null,
      ),
      _VectorLayer(
        Path()
          ..moveTo(128.0000, 90.0000)
          ..cubicTo(128.0000, 99.9411, 119.9411, 108.0000, 110.0000, 108.0000)
          ..cubicTo(100.0589, 108.0000, 92.0000, 99.9411, 92.0000, 90.0000)
          ..cubicTo(92.0000, 80.0589, 100.0589, 72.0000, 110.0000, 72.0000)
          ..cubicTo(119.9411, 72.0000, 128.0000, 80.0589, 128.0000, 90.0000)
          ..close(),
        null,
        Color(0xFFD4FFF7),
        3,
        null,
      ),
      _VectorLayer(
        Path()
          ..moveTo(31.0000, 35.0000)
          ..lineTo(31.7920, 38.2080)
          ..lineTo(35.0000, 39.0000)
          ..lineTo(31.7920, 39.7920)
          ..lineTo(31.0000, 43.0000)
          ..lineTo(30.2080, 39.7920)
          ..lineTo(27.0000, 39.0000)
          ..lineTo(30.2080, 38.2080)
          ..close(),
        Color(0xFFAFEBE6),
        null,
        1,
        null,
      ),
      _VectorLayer(
        Path()
          ..moveTo(167.0000, 39.0000)
          ..lineTo(167.7920, 42.2080)
          ..lineTo(171.0000, 43.0000)
          ..lineTo(167.7920, 43.7920)
          ..lineTo(167.0000, 47.0000)
          ..lineTo(166.2080, 43.7920)
          ..lineTo(163.0000, 43.0000)
          ..lineTo(166.2080, 42.2080)
          ..close(),
        Color(0xFFAFEBE6),
        null,
        1,
        null,
      ),
      _VectorLayer(
        Path()
          ..moveTo(157.0000, 163.0000)
          ..lineTo(157.7920, 166.2080)
          ..lineTo(161.0000, 167.0000)
          ..lineTo(157.7920, 167.7920)
          ..lineTo(157.0000, 171.0000)
          ..lineTo(156.2080, 167.7920)
          ..lineTo(153.0000, 167.0000)
          ..lineTo(156.2080, 166.2080)
          ..close(),
        Color(0xFFAFEBE6),
        null,
        1,
        null,
      ),
    ],
  ),
  'ranks/rank_horizon': (
    const Size(200, 200),
    [
      _VectorLayer(
        Path()
          ..moveTo(180.0000, 93.0000)
          ..cubicTo(180.0000, 137.1828, 144.1828, 173.0000, 100.0000, 173.0000)
          ..cubicTo(55.8172, 173.0000, 20.0000, 137.1828, 20.0000, 93.0000)
          ..cubicTo(20.0000, 48.8172, 55.8172, 13.0000, 100.0000, 13.0000)
          ..cubicTo(144.1828, 13.0000, 180.0000, 48.8172, 180.0000, 93.0000)
          ..close(),
        Color(0x12AE85FF),
        null,
        1,
        null,
      ),
      _VectorLayer(
        Path()
          ..moveTo(64.0000, 128.0000)
          ..lineTo(85.0000, 128.0000)
          ..lineTo(91.0000, 188.0000)
          ..lineTo(69.0000, 173.0000)
          ..close(),
        Color(0xFF8470DC),
        null,
        1,
        [Color(0xFFCCADFF), Color(0xFF6645B5)],
      ),
      _VectorLayer(
        Path()
          ..moveTo(85.0000, 128.0000)
          ..lineTo(106.0000, 128.0000)
          ..lineTo(112.0000, 190.0000)
          ..lineTo(91.0000, 188.0000)
          ..close(),
        Color(0xFFB195FC),
        null,
        1,
        [Color(0xFFB9A5FF), Color(0xFF7661E5)],
      ),
      _VectorLayer(
        Path()
          ..moveTo(106.0000, 128.0000)
          ..lineTo(127.0000, 128.0000)
          ..lineTo(131.0000, 173.0000)
          ..lineTo(112.0000, 190.0000)
          ..close(),
        Color(0xFF7351C0),
        null,
        1,
        [Color(0xFF6369D2), Color(0xFF303D80)],
      ),
      _VectorLayer(
        Path()
          ..moveTo(43.0000, 143.0000)
          ..quadraticBezierTo(17.0000, 135.0000, 31.0000, 116.0000)
          ..quadraticBezierTo(44.0000, 126.0000, 43.0000, 143.0000)
          ..close(),
        Color(0xFFB4C3FF),
        null,
        1,
        [Color(0xFFB4C3FF), Color(0xFF806147)],
      ),
      _VectorLayer(
        Path()
          ..moveTo(40.0000, 128.0000)
          ..quadraticBezierTo(14.0000, 120.0000, 28.0000, 101.0000)
          ..quadraticBezierTo(41.0000, 111.0000, 40.0000, 128.0000)
          ..close(),
        Color(0xFFB4C3FF),
        null,
        1,
        [Color(0xFFB4C3FF), Color(0xFF806147)],
      ),
      _VectorLayer(
        Path()
          ..moveTo(37.0000, 113.0000)
          ..quadraticBezierTo(11.0000, 105.0000, 25.0000, 86.0000)
          ..quadraticBezierTo(38.0000, 96.0000, 37.0000, 113.0000)
          ..close(),
        Color(0xFFB4C3FF),
        null,
        1,
        [Color(0xFFB4C3FF), Color(0xFF806147)],
      ),
      _VectorLayer(
        Path()
          ..moveTo(34.0000, 98.0000)
          ..quadraticBezierTo(8.0000, 90.0000, 22.0000, 71.0000)
          ..quadraticBezierTo(35.0000, 81.0000, 34.0000, 98.0000)
          ..close(),
        Color(0xFFB4C3FF),
        null,
        1,
        [Color(0xFFB4C3FF), Color(0xFF806147)],
      ),
      _VectorLayer(
        Path()
          ..moveTo(31.0000, 83.0000)
          ..quadraticBezierTo(5.0000, 75.0000, 19.0000, 56.0000)
          ..quadraticBezierTo(32.0000, 66.0000, 31.0000, 83.0000)
          ..close(),
        Color(0xFFB4C3FF),
        null,
        1,
        [Color(0xFFB4C3FF), Color(0xFF806147)],
      ),
      _VectorLayer(
        Path()
          ..moveTo(157.0000, 143.0000)
          ..quadraticBezierTo(183.0000, 135.0000, 169.0000, 116.0000)
          ..quadraticBezierTo(156.0000, 126.0000, 157.0000, 143.0000)
          ..close(),
        Color(0xFFB4C3FF),
        null,
        1,
        [Color(0xFFB4C3FF), Color(0xFF806147)],
      ),
      _VectorLayer(
        Path()
          ..moveTo(160.0000, 128.0000)
          ..quadraticBezierTo(186.0000, 120.0000, 172.0000, 101.0000)
          ..quadraticBezierTo(159.0000, 111.0000, 160.0000, 128.0000)
          ..close(),
        Color(0xFFB4C3FF),
        null,
        1,
        [Color(0xFFB4C3FF), Color(0xFF806147)],
      ),
      _VectorLayer(
        Path()
          ..moveTo(163.0000, 113.0000)
          ..quadraticBezierTo(189.0000, 105.0000, 175.0000, 86.0000)
          ..quadraticBezierTo(162.0000, 96.0000, 163.0000, 113.0000)
          ..close(),
        Color(0xFFB4C3FF),
        null,
        1,
        [Color(0xFFB4C3FF), Color(0xFF806147)],
      ),
      _VectorLayer(
        Path()
          ..moveTo(166.0000, 98.0000)
          ..quadraticBezierTo(192.0000, 90.0000, 178.0000, 71.0000)
          ..quadraticBezierTo(165.0000, 81.0000, 166.0000, 98.0000)
          ..close(),
        Color(0xFFB4C3FF),
        null,
        1,
        [Color(0xFFB4C3FF), Color(0xFF806147)],
      ),
      _VectorLayer(
        Path()
          ..moveTo(169.0000, 83.0000)
          ..quadraticBezierTo(195.0000, 75.0000, 181.0000, 56.0000)
          ..quadraticBezierTo(168.0000, 66.0000, 169.0000, 83.0000)
          ..close(),
        Color(0xFFB4C3FF),
        null,
        1,
        [Color(0xFFB4C3FF), Color(0xFF806147)],
      ),
      _VectorLayer(
        Path()
          ..moveTo(100.0000, 25.0000)
          ..lineTo(122.1956, 36.4150)
          ..lineTo(145.9619, 44.0381)
          ..lineTo(153.5850, 67.8044)
          ..lineTo(165.0000, 90.0000)
          ..lineTo(153.5850, 112.1956)
          ..lineTo(145.9619, 135.9619)
          ..lineTo(122.1956, 143.5850)
          ..lineTo(100.0000, 155.0000)
          ..lineTo(77.8044, 143.5850)
          ..lineTo(54.0381, 135.9619)
          ..lineTo(46.4150, 112.1956)
          ..lineTo(35.0000, 90.0000)
          ..lineTo(46.4150, 67.8044)
          ..lineTo(54.0381, 44.0381)
          ..lineTo(77.8044, 36.4150)
          ..close(),
        Color(0xFFB4C3FF),
        Color(0xFFF4DEFF),
        1.5,
        [Color(0xFFB4C3FF), Color(0xFF8D6BA1)],
      ),
      _VectorLayer(
        Path()
          ..moveTo(100.0000, 25.0000)
          ..lineTo(122.1956, 36.4150)
          ..lineTo(116.4554, 50.2732)
          ..lineTo(100.0000, 41.0000)
          ..close(),
        Color(0xFFB4C3FF),
        null,
        1,
        null,
      ),
      _VectorLayer(
        Path()
          ..moveTo(122.1956, 36.4150)
          ..lineTo(145.9619, 44.0381)
          ..lineTo(134.6482, 55.3518)
          ..lineTo(116.4554, 50.2732)
          ..close(),
        Color(0xFFE6DCFF),
        null,
        1,
        null,
      ),
      _VectorLayer(
        Path()
          ..moveTo(145.9619, 44.0381)
          ..lineTo(153.5850, 67.8044)
          ..lineTo(139.7268, 73.5446)
          ..lineTo(134.6482, 55.3518)
          ..close(),
        Color(0xFF6155A4),
        null,
        1,
        null,
      ),
      _VectorLayer(
        Path()
          ..moveTo(153.5850, 67.8044)
          ..lineTo(165.0000, 90.0000)
          ..lineTo(149.0000, 90.0000)
          ..lineTo(139.7268, 73.5446)
          ..close(),
        Color(0xFFB4C3FF),
        null,
        1,
        null,
      ),
      _VectorLayer(
        Path()
          ..moveTo(165.0000, 90.0000)
          ..lineTo(153.5850, 112.1956)
          ..lineTo(139.7268, 106.4554)
          ..lineTo(149.0000, 90.0000)
          ..close(),
        Color(0xFFE6DCFF),
        null,
        1,
        null,
      ),
      _VectorLayer(
        Path()
          ..moveTo(153.5850, 112.1956)
          ..lineTo(145.9619, 135.9619)
          ..lineTo(134.6482, 124.6482)
          ..lineTo(139.7268, 106.4554)
          ..close(),
        Color(0xFF6155A4),
        null,
        1,
        null,
      ),
      _VectorLayer(
        Path()
          ..moveTo(145.9619, 135.9619)
          ..lineTo(122.1956, 143.5850)
          ..lineTo(116.4554, 129.7268)
          ..lineTo(134.6482, 124.6482)
          ..close(),
        Color(0xFFB4C3FF),
        null,
        1,
        null,
      ),
      _VectorLayer(
        Path()
          ..moveTo(122.1956, 143.5850)
          ..lineTo(100.0000, 155.0000)
          ..lineTo(100.0000, 139.0000)
          ..lineTo(116.4554, 129.7268)
          ..close(),
        Color(0xFFE6DCFF),
        null,
        1,
        null,
      ),
      _VectorLayer(
        Path()
          ..moveTo(100.0000, 155.0000)
          ..lineTo(77.8044, 143.5850)
          ..lineTo(83.5446, 129.7268)
          ..lineTo(100.0000, 139.0000)
          ..close(),
        Color(0xFF6155A4),
        null,
        1,
        null,
      ),
      _VectorLayer(
        Path()
          ..moveTo(77.8044, 143.5850)
          ..lineTo(54.0381, 135.9619)
          ..lineTo(65.3518, 124.6482)
          ..lineTo(83.5446, 129.7268)
          ..close(),
        Color(0xFFB4C3FF),
        null,
        1,
        null,
      ),
      _VectorLayer(
        Path()
          ..moveTo(54.0381, 135.9619)
          ..lineTo(46.4150, 112.1956)
          ..lineTo(60.2732, 106.4554)
          ..lineTo(65.3518, 124.6482)
          ..close(),
        Color(0xFFE6DCFF),
        null,
        1,
        null,
      ),
      _VectorLayer(
        Path()
          ..moveTo(46.4150, 112.1956)
          ..lineTo(35.0000, 90.0000)
          ..lineTo(51.0000, 90.0000)
          ..lineTo(60.2732, 106.4554)
          ..close(),
        Color(0xFF6155A4),
        null,
        1,
        null,
      ),
      _VectorLayer(
        Path()
          ..moveTo(35.0000, 90.0000)
          ..lineTo(46.4150, 67.8044)
          ..lineTo(60.2732, 73.5446)
          ..lineTo(51.0000, 90.0000)
          ..close(),
        Color(0xFFB4C3FF),
        null,
        1,
        null,
      ),
      _VectorLayer(
        Path()
          ..moveTo(46.4150, 67.8044)
          ..lineTo(54.0381, 44.0381)
          ..lineTo(65.3518, 55.3518)
          ..lineTo(60.2732, 73.5446)
          ..close(),
        Color(0xFFE6DCFF),
        null,
        1,
        null,
      ),
      _VectorLayer(
        Path()
          ..moveTo(54.0381, 44.0381)
          ..lineTo(77.8044, 36.4150)
          ..lineTo(83.5446, 50.2732)
          ..lineTo(65.3518, 55.3518)
          ..close(),
        Color(0xFF6155A4),
        null,
        1,
        null,
      ),
      _VectorLayer(
        Path()
          ..moveTo(77.8044, 36.4150)
          ..lineTo(100.0000, 25.0000)
          ..lineTo(100.0000, 41.0000)
          ..lineTo(83.5446, 50.2732)
          ..close(),
        Color(0xFFB4C3FF),
        null,
        1,
        null,
      ),
      _VectorLayer(
        Path()
          ..moveTo(100.0000, 41.0000)
          ..lineTo(116.4554, 50.2732)
          ..lineTo(134.6482, 55.3518)
          ..lineTo(139.7268, 73.5446)
          ..lineTo(149.0000, 90.0000)
          ..lineTo(139.7268, 106.4554)
          ..lineTo(134.6482, 124.6482)
          ..lineTo(116.4554, 129.7268)
          ..lineTo(100.0000, 139.0000)
          ..lineTo(83.5446, 129.7268)
          ..lineTo(65.3518, 124.6482)
          ..lineTo(60.2732, 106.4554)
          ..lineTo(51.0000, 90.0000)
          ..lineTo(60.2732, 73.5446)
          ..lineTo(65.3518, 55.3518)
          ..lineTo(83.5446, 50.2732)
          ..close(),
        Color(0xFF252A59),
        Color(0xFFB4C3FF),
        1.8,
        [Color(0xFF333B6D), Color(0xFF111B3A)],
      ),
      _VectorLayer(
        Path()
          ..moveTo(76.0000, 99.0000)
          ..quadraticBezierTo(100.0000, 60.0000, 124.0000, 99.0000),
        null,
        Color(0xFFE0E7FF),
        3,
        null,
      ),
      _VectorLayer(
        Path()
          ..moveTo(74.0000, 104.0000)
          ..lineTo(126.0000, 104.0000),
        null,
        Color(0xFFE0E7FF),
        3,
        null,
      ),
      _VectorLayer(
        Path()
          ..moveTo(31.0000, 35.0000)
          ..lineTo(31.7920, 38.2080)
          ..lineTo(35.0000, 39.0000)
          ..lineTo(31.7920, 39.7920)
          ..lineTo(31.0000, 43.0000)
          ..lineTo(30.2080, 39.7920)
          ..lineTo(27.0000, 39.0000)
          ..lineTo(30.2080, 38.2080)
          ..close(),
        Color(0xFFB4C3FF),
        null,
        1,
        null,
      ),
      _VectorLayer(
        Path()
          ..moveTo(167.0000, 39.0000)
          ..lineTo(167.7920, 42.2080)
          ..lineTo(171.0000, 43.0000)
          ..lineTo(167.7920, 43.7920)
          ..lineTo(167.0000, 47.0000)
          ..lineTo(166.2080, 43.7920)
          ..lineTo(163.0000, 43.0000)
          ..lineTo(166.2080, 42.2080)
          ..close(),
        Color(0xFFB4C3FF),
        null,
        1,
        null,
      ),
      _VectorLayer(
        Path()
          ..moveTo(157.0000, 163.0000)
          ..lineTo(157.7920, 166.2080)
          ..lineTo(161.0000, 167.0000)
          ..lineTo(157.7920, 167.7920)
          ..lineTo(157.0000, 171.0000)
          ..lineTo(156.2080, 167.7920)
          ..lineTo(153.0000, 167.0000)
          ..lineTo(156.2080, 166.2080)
          ..close(),
        Color(0xFFB4C3FF),
        null,
        1,
        null,
      ),
    ],
  ),
  'ranks/rank_lexicon': (
    const Size(200, 200),
    [
      _VectorLayer(
        Path()
          ..moveTo(180.0000, 93.0000)
          ..cubicTo(180.0000, 137.1828, 144.1828, 173.0000, 100.0000, 173.0000)
          ..cubicTo(55.8172, 173.0000, 20.0000, 137.1828, 20.0000, 93.0000)
          ..cubicTo(20.0000, 48.8172, 55.8172, 13.0000, 100.0000, 13.0000)
          ..cubicTo(144.1828, 13.0000, 180.0000, 48.8172, 180.0000, 93.0000)
          ..close(),
        Color(0x12AE85FF),
        null,
        1,
        null,
      ),
      _VectorLayer(
        Path()
          ..moveTo(64.0000, 128.0000)
          ..lineTo(85.0000, 128.0000)
          ..lineTo(91.0000, 188.0000)
          ..lineTo(69.0000, 173.0000)
          ..close(),
        Color(0xFF8470DC),
        null,
        1,
        [Color(0xFFCCADFF), Color(0xFF6645B5)],
      ),
      _VectorLayer(
        Path()
          ..moveTo(85.0000, 128.0000)
          ..lineTo(106.0000, 128.0000)
          ..lineTo(112.0000, 190.0000)
          ..lineTo(91.0000, 188.0000)
          ..close(),
        Color(0xFFB195FC),
        null,
        1,
        [Color(0xFFB9A5FF), Color(0xFF7661E5)],
      ),
      _VectorLayer(
        Path()
          ..moveTo(106.0000, 128.0000)
          ..lineTo(127.0000, 128.0000)
          ..lineTo(131.0000, 173.0000)
          ..lineTo(112.0000, 190.0000)
          ..close(),
        Color(0xFF7351C0),
        null,
        1,
        [Color(0xFF6369D2), Color(0xFF303D80)],
      ),
      _VectorLayer(
        Path()
          ..moveTo(43.0000, 143.0000)
          ..quadraticBezierTo(17.0000, 135.0000, 31.0000, 116.0000)
          ..quadraticBezierTo(44.0000, 126.0000, 43.0000, 143.0000)
          ..close(),
        Color(0xFFFFE2A6),
        null,
        1,
        [Color(0xFFFFE2A6), Color(0xFF806147)],
      ),
      _VectorLayer(
        Path()
          ..moveTo(40.0000, 128.0000)
          ..quadraticBezierTo(14.0000, 120.0000, 28.0000, 101.0000)
          ..quadraticBezierTo(41.0000, 111.0000, 40.0000, 128.0000)
          ..close(),
        Color(0xFFFFE2A6),
        null,
        1,
        [Color(0xFFFFE2A6), Color(0xFF806147)],
      ),
      _VectorLayer(
        Path()
          ..moveTo(37.0000, 113.0000)
          ..quadraticBezierTo(11.0000, 105.0000, 25.0000, 86.0000)
          ..quadraticBezierTo(38.0000, 96.0000, 37.0000, 113.0000)
          ..close(),
        Color(0xFFFFE2A6),
        null,
        1,
        [Color(0xFFFFE2A6), Color(0xFF806147)],
      ),
      _VectorLayer(
        Path()
          ..moveTo(34.0000, 98.0000)
          ..quadraticBezierTo(8.0000, 90.0000, 22.0000, 71.0000)
          ..quadraticBezierTo(35.0000, 81.0000, 34.0000, 98.0000)
          ..close(),
        Color(0xFFFFE2A6),
        null,
        1,
        [Color(0xFFFFE2A6), Color(0xFF806147)],
      ),
      _VectorLayer(
        Path()
          ..moveTo(31.0000, 83.0000)
          ..quadraticBezierTo(5.0000, 75.0000, 19.0000, 56.0000)
          ..quadraticBezierTo(32.0000, 66.0000, 31.0000, 83.0000)
          ..close(),
        Color(0xFFFFE2A6),
        null,
        1,
        [Color(0xFFFFE2A6), Color(0xFF806147)],
      ),
      _VectorLayer(
        Path()
          ..moveTo(157.0000, 143.0000)
          ..quadraticBezierTo(183.0000, 135.0000, 169.0000, 116.0000)
          ..quadraticBezierTo(156.0000, 126.0000, 157.0000, 143.0000)
          ..close(),
        Color(0xFFFFE2A6),
        null,
        1,
        [Color(0xFFFFE2A6), Color(0xFF806147)],
      ),
      _VectorLayer(
        Path()
          ..moveTo(160.0000, 128.0000)
          ..quadraticBezierTo(186.0000, 120.0000, 172.0000, 101.0000)
          ..quadraticBezierTo(159.0000, 111.0000, 160.0000, 128.0000)
          ..close(),
        Color(0xFFFFE2A6),
        null,
        1,
        [Color(0xFFFFE2A6), Color(0xFF806147)],
      ),
      _VectorLayer(
        Path()
          ..moveTo(163.0000, 113.0000)
          ..quadraticBezierTo(189.0000, 105.0000, 175.0000, 86.0000)
          ..quadraticBezierTo(162.0000, 96.0000, 163.0000, 113.0000)
          ..close(),
        Color(0xFFFFE2A6),
        null,
        1,
        [Color(0xFFFFE2A6), Color(0xFF806147)],
      ),
      _VectorLayer(
        Path()
          ..moveTo(166.0000, 98.0000)
          ..quadraticBezierTo(192.0000, 90.0000, 178.0000, 71.0000)
          ..quadraticBezierTo(165.0000, 81.0000, 166.0000, 98.0000)
          ..close(),
        Color(0xFFFFE2A6),
        null,
        1,
        [Color(0xFFFFE2A6), Color(0xFF806147)],
      ),
      _VectorLayer(
        Path()
          ..moveTo(169.0000, 83.0000)
          ..quadraticBezierTo(195.0000, 75.0000, 181.0000, 56.0000)
          ..quadraticBezierTo(168.0000, 66.0000, 169.0000, 83.0000)
          ..close(),
        Color(0xFFFFE2A6),
        null,
        1,
        [Color(0xFFFFE2A6), Color(0xFF806147)],
      ),
      _VectorLayer(
        Path()
          ..moveTo(100.0000, 25.0000)
          ..lineTo(122.1956, 36.4150)
          ..lineTo(145.9619, 44.0381)
          ..lineTo(153.5850, 67.8044)
          ..lineTo(165.0000, 90.0000)
          ..lineTo(153.5850, 112.1956)
          ..lineTo(145.9619, 135.9619)
          ..lineTo(122.1956, 143.5850)
          ..lineTo(100.0000, 155.0000)
          ..lineTo(77.8044, 143.5850)
          ..lineTo(54.0381, 135.9619)
          ..lineTo(46.4150, 112.1956)
          ..lineTo(35.0000, 90.0000)
          ..lineTo(46.4150, 67.8044)
          ..lineTo(54.0381, 44.0381)
          ..lineTo(77.8044, 36.4150)
          ..close(),
        Color(0xFFFFE2A6),
        Color(0xFFF4DEFF),
        1.5,
        [Color(0xFFFFE2A6), Color(0xFF8D6BA1)],
      ),
      _VectorLayer(
        Path()
          ..moveTo(100.0000, 25.0000)
          ..lineTo(122.1956, 36.4150)
          ..lineTo(116.4554, 50.2732)
          ..lineTo(100.0000, 41.0000)
          ..close(),
        Color(0xFFFFE2A6),
        null,
        1,
        null,
      ),
      _VectorLayer(
        Path()
          ..moveTo(122.1956, 36.4150)
          ..lineTo(145.9619, 44.0381)
          ..lineTo(134.6482, 55.3518)
          ..lineTo(116.4554, 50.2732)
          ..close(),
        Color(0xFFE6DCFF),
        null,
        1,
        null,
      ),
      _VectorLayer(
        Path()
          ..moveTo(145.9619, 44.0381)
          ..lineTo(153.5850, 67.8044)
          ..lineTo(139.7268, 73.5446)
          ..lineTo(134.6482, 55.3518)
          ..close(),
        Color(0xFF6155A4),
        null,
        1,
        null,
      ),
      _VectorLayer(
        Path()
          ..moveTo(153.5850, 67.8044)
          ..lineTo(165.0000, 90.0000)
          ..lineTo(149.0000, 90.0000)
          ..lineTo(139.7268, 73.5446)
          ..close(),
        Color(0xFFFFE2A6),
        null,
        1,
        null,
      ),
      _VectorLayer(
        Path()
          ..moveTo(165.0000, 90.0000)
          ..lineTo(153.5850, 112.1956)
          ..lineTo(139.7268, 106.4554)
          ..lineTo(149.0000, 90.0000)
          ..close(),
        Color(0xFFE6DCFF),
        null,
        1,
        null,
      ),
      _VectorLayer(
        Path()
          ..moveTo(153.5850, 112.1956)
          ..lineTo(145.9619, 135.9619)
          ..lineTo(134.6482, 124.6482)
          ..lineTo(139.7268, 106.4554)
          ..close(),
        Color(0xFF6155A4),
        null,
        1,
        null,
      ),
      _VectorLayer(
        Path()
          ..moveTo(145.9619, 135.9619)
          ..lineTo(122.1956, 143.5850)
          ..lineTo(116.4554, 129.7268)
          ..lineTo(134.6482, 124.6482)
          ..close(),
        Color(0xFFFFE2A6),
        null,
        1,
        null,
      ),
      _VectorLayer(
        Path()
          ..moveTo(122.1956, 143.5850)
          ..lineTo(100.0000, 155.0000)
          ..lineTo(100.0000, 139.0000)
          ..lineTo(116.4554, 129.7268)
          ..close(),
        Color(0xFFE6DCFF),
        null,
        1,
        null,
      ),
      _VectorLayer(
        Path()
          ..moveTo(100.0000, 155.0000)
          ..lineTo(77.8044, 143.5850)
          ..lineTo(83.5446, 129.7268)
          ..lineTo(100.0000, 139.0000)
          ..close(),
        Color(0xFF6155A4),
        null,
        1,
        null,
      ),
      _VectorLayer(
        Path()
          ..moveTo(77.8044, 143.5850)
          ..lineTo(54.0381, 135.9619)
          ..lineTo(65.3518, 124.6482)
          ..lineTo(83.5446, 129.7268)
          ..close(),
        Color(0xFFFFE2A6),
        null,
        1,
        null,
      ),
      _VectorLayer(
        Path()
          ..moveTo(54.0381, 135.9619)
          ..lineTo(46.4150, 112.1956)
          ..lineTo(60.2732, 106.4554)
          ..lineTo(65.3518, 124.6482)
          ..close(),
        Color(0xFFE6DCFF),
        null,
        1,
        null,
      ),
      _VectorLayer(
        Path()
          ..moveTo(46.4150, 112.1956)
          ..lineTo(35.0000, 90.0000)
          ..lineTo(51.0000, 90.0000)
          ..lineTo(60.2732, 106.4554)
          ..close(),
        Color(0xFF6155A4),
        null,
        1,
        null,
      ),
      _VectorLayer(
        Path()
          ..moveTo(35.0000, 90.0000)
          ..lineTo(46.4150, 67.8044)
          ..lineTo(60.2732, 73.5446)
          ..lineTo(51.0000, 90.0000)
          ..close(),
        Color(0xFFFFE2A6),
        null,
        1,
        null,
      ),
      _VectorLayer(
        Path()
          ..moveTo(46.4150, 67.8044)
          ..lineTo(54.0381, 44.0381)
          ..lineTo(65.3518, 55.3518)
          ..lineTo(60.2732, 73.5446)
          ..close(),
        Color(0xFFE6DCFF),
        null,
        1,
        null,
      ),
      _VectorLayer(
        Path()
          ..moveTo(54.0381, 44.0381)
          ..lineTo(77.8044, 36.4150)
          ..lineTo(83.5446, 50.2732)
          ..lineTo(65.3518, 55.3518)
          ..close(),
        Color(0xFF6155A4),
        null,
        1,
        null,
      ),
      _VectorLayer(
        Path()
          ..moveTo(77.8044, 36.4150)
          ..lineTo(100.0000, 25.0000)
          ..lineTo(100.0000, 41.0000)
          ..lineTo(83.5446, 50.2732)
          ..close(),
        Color(0xFFFFE2A6),
        null,
        1,
        null,
      ),
      _VectorLayer(
        Path()
          ..moveTo(100.0000, 41.0000)
          ..lineTo(116.4554, 50.2732)
          ..lineTo(134.6482, 55.3518)
          ..lineTo(139.7268, 73.5446)
          ..lineTo(149.0000, 90.0000)
          ..lineTo(139.7268, 106.4554)
          ..lineTo(134.6482, 124.6482)
          ..lineTo(116.4554, 129.7268)
          ..lineTo(100.0000, 139.0000)
          ..lineTo(83.5446, 129.7268)
          ..lineTo(65.3518, 124.6482)
          ..lineTo(60.2732, 106.4554)
          ..lineTo(51.0000, 90.0000)
          ..lineTo(60.2732, 73.5446)
          ..lineTo(65.3518, 55.3518)
          ..lineTo(83.5446, 50.2732)
          ..close(),
        Color(0xFF252A59),
        Color(0xFFFFE2A6),
        1.8,
        [Color(0xFF333B6D), Color(0xFF111B3A)],
      ),
      _VectorLayer(
        Path()
          ..moveTo(77.0000, 73.0000)
          ..quadraticBezierTo(90.0000, 70.0000, 100.0000, 77.0000)
          ..quadraticBezierTo(113.0000, 70.0000, 123.0000, 73.0000)
          ..lineTo(123.0000, 106.0000)
          ..quadraticBezierTo(112.0000, 103.0000, 100.0000, 111.0000)
          ..quadraticBezierTo(88.0000, 103.0000, 77.0000, 106.0000)
          ..close()
          ..moveTo(100.0000, 77.0000)
          ..lineTo(100.0000, 111.0000),
        null,
        Color(0xFFFFF1CB),
        3,
        null,
      ),
      _VectorLayer(
        Path()
          ..moveTo(31.0000, 35.0000)
          ..lineTo(31.7920, 38.2080)
          ..lineTo(35.0000, 39.0000)
          ..lineTo(31.7920, 39.7920)
          ..lineTo(31.0000, 43.0000)
          ..lineTo(30.2080, 39.7920)
          ..lineTo(27.0000, 39.0000)
          ..lineTo(30.2080, 38.2080)
          ..close(),
        Color(0xFFFFE2A6),
        null,
        1,
        null,
      ),
      _VectorLayer(
        Path()
          ..moveTo(167.0000, 39.0000)
          ..lineTo(167.7920, 42.2080)
          ..lineTo(171.0000, 43.0000)
          ..lineTo(167.7920, 43.7920)
          ..lineTo(167.0000, 47.0000)
          ..lineTo(166.2080, 43.7920)
          ..lineTo(163.0000, 43.0000)
          ..lineTo(166.2080, 42.2080)
          ..close(),
        Color(0xFFFFE2A6),
        null,
        1,
        null,
      ),
      _VectorLayer(
        Path()
          ..moveTo(157.0000, 163.0000)
          ..lineTo(157.7920, 166.2080)
          ..lineTo(161.0000, 167.0000)
          ..lineTo(157.7920, 167.7920)
          ..lineTo(157.0000, 171.0000)
          ..lineTo(156.2080, 167.7920)
          ..lineTo(153.0000, 167.0000)
          ..lineTo(156.2080, 166.2080)
          ..close(),
        Color(0xFFFFE2A6),
        null,
        1,
        null,
      ),
    ],
  ),
};
