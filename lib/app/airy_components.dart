import 'match_profile_controls.dart';

import 'package:flutter/material.dart';

import '../features/profile/cefr_level.dart';
import '../features/profile/cefr_profile.dart';
import 'motion_preferences.dart';
import 'design_tokens.dart';
import 'premium_components.dart';

double pageInset(BuildContext context) =>
    MediaQuery.sizeOf(context).width < 360 ? 16 : 24;

class AiryPageRoute<T> extends MaterialPageRoute<T> {
  AiryPageRoute({required super.builder});
  @override
  Duration get transitionDuration => AppMotion.page;
  @override
  Duration get reverseTransitionDuration => const Duration(milliseconds: 220);
  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) => motionOf(context) == 'minimal'
      ? child
      : FadeTransition(
          opacity: CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
          ),
          child: SlideTransition(
            position:
                Tween<Offset>(
                  begin: const Offset(0, .015),
                  end: Offset.zero,
                ).animate(
                  CurvedAnimation(
                    parent: animation,
                    curve: Curves.easeOutCubic,
                  ),
                ),
            child: child,
          ),
        );
}

class EntryReveal extends StatelessWidget {
  const EntryReveal({super.key, required this.child, this.enabled = true});
  final Widget child;
  final bool enabled;
  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
    tween: Tween(
      begin: enabled && motionOf(context) != 'minimal' ? 0 : 1,
      end: 1,
    ),
    duration: motionDuration(
      context,
      const Duration(milliseconds: 280),
      calmMs: 160,
    ),
    curve: Curves.easeOutCubic,
    child: RepaintBoundary(child: child),
    builder: (_, v, child) => Opacity(opacity: v, child: child),
  );
}

class AiryBackground extends StatelessWidget {
  const AiryBackground({super.key, required this.child, this.match = false});
  final bool match;
  final Widget child;
  @override
  Widget build(BuildContext context) => Stack(
    fit: StackFit.expand,
    children: [
      if (!match || MatchProfileScope.of(context).background)
        Positioned.fill(child: AtmosphericLayer(match: match)),

      child,
    ],
  );
}

class SectionHeader extends StatelessWidget {
  const SectionHeader(this.title, {super.key, this.help});
  final String title;
  final String? help;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 24, bottom: 12),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleLarge),
        if (help != null) ...[
          const SizedBox(height: 6),
          Text(help!, style: Theme.of(context).textTheme.bodySmall),
        ],
      ],
    ),
  );
}

/// A finite press effect. No ticker runs on static or hidden catalog cards.
class SurfaceCard extends StatefulWidget {
  const SurfaceCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(20),
    this.accent = false,
  });
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsets padding;
  final bool accent;
  @override
  State<SurfaceCard> createState() => _SurfaceCardState();
}

class _SurfaceCardState extends State<SurfaceCard> {
  bool pressed = false;
  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: pressed && motionOf(context) != 'minimal' ? .985 : 1,
      duration: motionDuration(context, AppMotion.press, calmMs: 120),
      child: RepaintBoundary(
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: widget.accent
                ? AppSurfaces.hero(context)
                : AppSurfaces.card(context),
            borderRadius: BorderRadius.circular(AppRadius.card),
            border: Border.all(
              color: AppSurfaces.outline(context).withValues(alpha: .8),
              width: .8,
            ),
          ),
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(AppRadius.card),
            child: InkWell(
              borderRadius: BorderRadius.circular(AppRadius.card),
              onTap: widget.onTap,
              onHighlightChanged: (v) {
                if (mounted && pressed != v) setState(() => pressed = v);
              },
              child: Padding(padding: widget.padding, child: widget.child),
            ),
          ),
        ),
      ),
    );
  }
}

class LevelStrip extends StatelessWidget {
  const LevelStrip({super.key});
  @override
  Widget build(BuildContext context) {
    final profile = ProfileScope.maybeOf(context),
        selected = ProfileScope.levelOf(context);
    return SizedBox(
      height: MediaQuery.textScalerOf(context).scale(16) + 32,
      child: LayoutBuilder(
        builder: (context, c) {
          final width = (c.maxWidth - 32) / 5;
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final l in CefrLevel.values)
                  Padding(
                    padding: EdgeInsets.only(right: l == CefrLevel.c1 ? 0 : 8),
                    child: SizedBox(
                      width: width < 48 ? 48 : width,
                      child: Semantics(
                        selected: selected == l,
                        button: true,
                        label: 'Уровень ${l.shortLabel}',
                        child: AnimatedContainer(
                          duration: motionDuration(
                            context,
                            const Duration(milliseconds: 180),
                            calmMs: 140,
                          ),
                          decoration: BoxDecoration(
                            gradient: selected == l
                                ? AppSurfaces.accent(context)
                                : AppSurfaces.card(context),
                            border: Border.all(
                              color: AppSurfaces.outline(context)
                                  .withValues(alpha: .6),
                            ),
                            boxShadow: selected == l
                                ? AppShadows.glow(
                                    AppColors.accentSecondary,
                                    strength: .2,
                                  )
                                : null,
                            borderRadius: BorderRadius.circular(AppRadius.pill),
                          ),
                          child: TextButton(
                            style: TextButton.styleFrom(
                              foregroundColor: selected == l
                                  ? Theme.of(context).colorScheme.onPrimary
                                  : Theme.of(context).colorScheme.onSurface,
                              minimumSize: const Size(48, 48),
                              padding: EdgeInsets.zero,
                            ),
                            onPressed: profile == null || profile.saving
                                ? null
                                : () => profile.choose(l),
                            child: Text(l.shortLabel),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

String russianPlural(int count, String one, String few, String many) {
  final n = count.abs() % 100;
  if (n >= 11 && n <= 14) return many;
  return switch (n % 10) {
    1 => one,
    2 || 3 || 4 => few,
    _ => many,
  };
}
