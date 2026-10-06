import 'match_profile_controls.dart';

import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'design_tokens.dart';
import 'motion_preferences.dart';
import 'premium_art.dart';
import 'match_atmosphere.dart';

class AtmosphericLayer extends StatelessWidget {
  const AtmosphericLayer({super.key, this.match = false});
  final bool match;
  @override
  Widget build(BuildContext context) => IgnorePointer(
    child: ExcludeSemantics(
      child: RepaintBoundary(
        child: CustomPaint(
          painter: _AtmospherePainter(AppSurfaces.dark(context), match: match),
          isComplex: true,
          willChange: false,
          child: const SizedBox.expand(),
        ),
      ),
    ),
  );
}

class _AtmospherePainter extends CustomPainter {
  const _AtmospherePainter(this.dark, {this.match = false});
  final bool match;
  final bool dark;
  @override
  void paint(Canvas canvas, Size s) {
    MatchProfileCounters.hit('background.paint');
    final rect = Offset.zero & s;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: dark
              ? const [
                  AppColors.backgroundPrimary,
                  Color(0xFF18234A),
                  Color(0xFF0D142D),
                ]
              : const [
                  AppColors.lightBackground,
                  Color(0xFFEEEBFC),
                  Color(0xFFF6F7FD),
                ],
        ).createShader(rect),
    );
    for (final glow in [
      (Offset(s.width * .82, s.height * .15), s.width * .58),
      (Offset(s.width * .08, s.height * .72), s.width * .42),
    ]) {
      canvas.drawCircle(
        glow.$1,
        glow.$2,
        Paint()
          ..shader = RadialGradient(
            colors: dark
                ? const [Color(0x257866D8), Color(0x007866D8)]
                : const [Color(0x12B3A2ED), Color(0x00B3A2ED)],
          ).createShader(Rect.fromCircle(center: glow.$1, radius: glow.$2)),
      );
    }
    if (!dark) return;
    final random = math.Random(49);
    for (var i = 0; i < 40; i++) {
      final x = random.nextDouble() * s.width,
          y = random.nextDouble() * s.height;
      canvas.drawCircle(
        Offset(x, y),
        i % 5 == 0 ? 1.05 : .55,
        Paint()
          ..color = AppColors.accentPrimary.withValues(
            alpha: i % 5 == 0 ? .22 : .12,
          ),
      );
    }
    if (match) {
      final height = math.min(220.0, s.height * .3);
      canvas.save();
      canvas.translate(0, s.height - height);
      paintMatchLandscape(canvas, Size(s.width, height));
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_AtmospherePainter old) =>
      old.dark != dark || old.match != match;
}

/// Static gradients provide depth without filtering the scrolling background.
class PremiumHero extends StatelessWidget {
  const PremiumHero({
    super.key,
    required this.child,
    this.art = 'illustrations/continue_landscape',
    this.padding = const EdgeInsets.all(20),
  });
  final Widget child;
  final String art;
  final EdgeInsets padding;
  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      gradient: AppSurfaces.hero(context),
      borderRadius: BorderRadius.circular(AppRadius.hero),
      border: Border.all(color: AppSurfaces.outline(context), width: .9),
    ),
    child: ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.hero),
      child: Stack(
        children: [
          Positioned.fill(
            child: IgnorePointer(
              child: Opacity(
                opacity: AppSurfaces.dark(context) ? .7 : .3,
                child: PremiumArt(art, cover: true),
              ),
            ),
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: AppSurfaces.dark(context)
                      ? const [
                          Color(0xDD303675),
                          Color(0xDD202B55),
                          Color(0xDD202B55),
                        ]
                      : const [
                          Color(0xEEE7E2FA),
                          Color(0x80E7E2FA),
                          Colors.transparent,
                        ],
                  stops: const [0, .55, 1],
                ),
              ),
            ),
          ),
          Padding(padding: padding, child: child),
        ],
      ),
    ),
  );
}

class PremiumButton extends StatelessWidget {
  const PremiumButton({
    super.key,
    required this.onPressed,
    required this.label,
    this.icon = Icons.arrow_forward_rounded,
  });
  final VoidCallback? onPressed;
  final String label;
  final IconData icon;
  @override
  Widget build(BuildContext context) => _PressScale(
    enabled: onPressed != null,
    child: DecoratedBox(
      decoration: BoxDecoration(
        gradient: onPressed == null ? null : AppSurfaces.accent(context),
        color: onPressed == null
            ? Theme.of(context).colorScheme.onSurface.withValues(alpha: .08)
            : null,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        boxShadow: onPressed == null
            ? null
            : AppShadows.glow(AppColors.accentSecondary, strength: .16),
      ),
      child: FilledButton(
        style: FilledButton.styleFrom(
          backgroundColor: Colors.transparent,
          disabledBackgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          foregroundColor: Theme.of(context).colorScheme.onPrimary,
          minimumSize: const Size(48, 48),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          shape: const StadiumBorder(),
        ),
        onPressed: onPressed,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Flexible(child: Text(label, textAlign: TextAlign.center)),
            const SizedBox(width: 12),
            Icon(icon, size: 22),
          ],
        ),
      ),
    ),
  );
}

class PremiumChoice extends StatelessWidget {
  const PremiumChoice({
    super.key,
    required this.label,
    required this.selected,
    required this.onPressed,
    required this.icon,
  });
  final String label;
  final bool selected;
  final VoidCallback onPressed;
  final IconData icon;
  @override
  Widget build(BuildContext context) => AnimatedContainer(
    duration: motionDuration(context, AppMotion.selection, calmMs: 160),
    curve: Curves.easeOutCubic,
    decoration: BoxDecoration(
      gradient: selected
          ? AppSurfaces.accent(context)
          : AppSurfaces.card(context),
      borderRadius: BorderRadius.circular(AppRadius.pill),
      border: Border.all(color: AppSurfaces.outline(context)),
    ),
    child: TextButton.icon(
      style: TextButton.styleFrom(
        foregroundColor: selected
            ? Theme.of(context).colorScheme.onPrimary
            : Theme.of(context).colorScheme.onSurface,
        minimumSize: const Size(48, 48),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
      ),
      onPressed: onPressed,
      icon: Icon(selected ? Icons.check_rounded : icon, size: 18),
      label: Text(label),
    ),
  );
}

class _PressScale extends StatefulWidget {
  const _PressScale({required this.child, required this.enabled});
  final Widget child;
  final bool enabled;
  @override
  State<_PressScale> createState() => _PressScaleState();
}

class _PressScaleState extends State<_PressScale> {
  bool pressed = false;
  void change(bool value) {
    if (widget.enabled && pressed != value) setState(() => pressed = value);
  }

  @override
  Widget build(BuildContext context) => Listener(
    onPointerDown: (_) => change(true),
    onPointerUp: (_) => change(false),
    onPointerCancel: (_) => change(false),
    child: AnimatedScale(
      scale: pressed && motionOf(context) != 'minimal' ? .985 : 1,
      duration: motionDuration(context, AppMotion.press, calmMs: 120),
      curve: Curves.easeOutCubic,
      child: widget.child,
    ),
  );
}
