import 'package:flutter/material.dart';

import '../../../app/design_tokens.dart';
import '../../../app/motion_preferences.dart';

class PairCountSelector extends StatelessWidget {
  const PairCountSelector({
    super.key,
    required this.value,
    required this.onChanged,
  }) : assert(value == 4 || value == 5);
  final int value;
  final ValueChanged<int> onChanged;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Text('Размер поля', style: Theme.of(context).textTheme.titleLarge),
      const SizedBox(height: 6),
      Text(
        'Выберите темп тренировки',
        style: Theme.of(context).textTheme.bodySmall,
      ),
      const SizedBox(height: 16),
      LayoutBuilder(
        builder: (context, c) {
          final wide =
              c.maxWidth >= 280 &&
              MediaQuery.textScalerOf(context).scale(14) <= 18.2;
          final items = [
            for (final count in [4, 5])
              _PairOption(
                count: count,
                selected: value == count,
                onTap: () => onChanged(count),
              ),
          ];
          return wide
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: items[0]),
                    const SizedBox(width: 12),
                    Expanded(child: items[1]),
                  ],
                )
              : Column(
                  children: [items[0], const SizedBox(height: 12), items[1]],
                );
        },
      ),
    ],
  );
}

class _PairOption extends StatefulWidget {
  const _PairOption({
    required this.count,
    required this.selected,
    required this.onTap,
  });
  final int count;
  final bool selected;
  final VoidCallback onTap;
  @override
  State<_PairOption> createState() => _PairOptionState();
}

class _PairOptionState extends State<_PairOption> {
  bool pressed = false;
  @override
  Widget build(BuildContext context) {
    final dark = AppSurfaces.dark(context),
        scheme = Theme.of(context).colorScheme;
    return Semantics(
      button: true,
      selected: widget.selected,
      label:
          '${widget.count == 4 ? '4 пары' : '5 пар'}. ${widget.count == 4 ? 'Спокойнее' : 'Интенсивнее'}',
      child: AnimatedScale(
        scale: pressed && motionOf(context) != 'minimal' ? .985 : 1,
        duration: motionDuration(context, AppMotion.press),
        child: AnimatedContainer(
          duration: motionDuration(context, AppMotion.selection),
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: widget.selected
                ? LinearGradient(
                    colors: dark
                        ? const [Color(0xFF493F8D), Color(0xFF252D57)]
                        : const [Color(0xFFE7DFFF), Color(0xFFDCDDF8)],
                  )
                : AppSurfaces.card(context),
            borderRadius: BorderRadius.circular(AppRadius.card),
            boxShadow: widget.selected
                ? [
                    BoxShadow(
                      color: scheme.primary.withValues(alpha: dark ? .10 : .06),
                      blurRadius: 10,
                      spreadRadius: 1,
                    ),
                  ]
                : null,
            border: Border.all(
              color: widget.selected
                  ? scheme.primary
                  : AppSurfaces.outline(context),
              width: widget.selected ? 1.5 : .8,
            ),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: widget.onTap,
              onHighlightChanged: (v) => setState(() => pressed = v),
              borderRadius: BorderRadius.circular(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ConstrainedBox(
                    key: ValueKey('pairs-${widget.count}'),
                    constraints: const BoxConstraints(minHeight: 48),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            widget.count == 4 ? '4 пары' : '5 пар',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        if (widget.selected)
                          Icon(
                            Icons.check_circle_rounded,
                            size: 22,
                            color: scheme.primary,
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    widget.count == 4 ? 'Спокойнее' : 'Интенсивнее',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 18),
                  Center(
                    child: ExcludeSemantics(
                      child: RepaintBoundary(
                        child: SizedBox(
                          width: 90,
                          height: 68,
                          child: CustomPaint(
                            painter: _PairPreview(
                              widget.count,
                              scheme.primary,
                              dark,
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
        ),
      ),
    );
  }
}

class _PairPreview extends CustomPainter {
  const _PairPreview(this.count, this.accent, this.dark);
  final int count;
  final Color accent;
  final bool dark;
  @override
  void paint(Canvas c, Size s) {
    final row = (s.height - 4 * (count - 1)) / count;
    for (var i = 0; i < count; i++) {
      for (final x in [0.0, s.width * .57]) {
        final r = RRect.fromRectAndRadius(
          Rect.fromLTWH(x, i * (row + 4), s.width * .43, row),
          const Radius.circular(3),
        );
        c.drawRRect(
          r,
          Paint()..color = accent.withValues(alpha: dark ? .22 : .12),
        );
        c.drawRRect(
          r,
          Paint()
            ..color = accent.withValues(alpha: .45)
            ..style = PaintingStyle.stroke
            ..strokeWidth = .7,
        );
      }
    }
    c.drawLine(
      Offset(s.width * .43, row / 2),
      Offset(s.width * .57, row / 2),
      Paint()
        ..color = dark ? AppColors.success : const Color(0xFF328B79)
        ..strokeWidth = 1.4,
    );
  }

  @override
  bool shouldRepaint(_PairPreview old) =>
      old.count != count || old.accent != accent || old.dark != dark;
}
