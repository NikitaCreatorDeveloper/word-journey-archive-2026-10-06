import 'package:flutter/material.dart';

import 'motion_preferences.dart';
import 'airy_components.dart';
import 'premium_art.dart';

class RankBadge extends StatelessWidget {
  const RankBadge({super.key, this.rank = 0, this.size = 56});
  final int rank;
  final double size;
  static const assets = [
    'start',
    'spark',
    'impulse',
    'rhythm',
    'focus',
    'flow',
    'resonance',
    'spectrum',
    'synthesis',
    'horizon',
    'lexicon',
  ];
  @override
  Widget build(BuildContext context) => PremiumArt(
    'ranks/rank_${assets[rank.clamp(0, 10)]}',
    width: size,
    height: size,
  );
}

/// Finite, decorative presentation. Award writes happen before this widget.
class RewardPresentation extends StatelessWidget {
  const RewardPresentation({
    super.key,
    required this.title,
    required this.detail,
    this.rank = 0,
  });
  final String title, detail;
  final int rank;
  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
    tween: Tween(begin: motionOf(context) == 'minimal' ? 1 : .94, end: 1),
    duration: motionDuration(
      context,
      const Duration(milliseconds: 720),
      calmMs: 360,
    ),
    curve: Curves.easeOutCubic,
    child: SurfaceCard(
      accent: true,
      child: Column(
        children: [
          IgnorePointer(child: RankBadge(rank: rank, size: 72)),
          const SizedBox(height: 12),
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(detail, textAlign: TextAlign.center),
        ],
      ),
    ),
    builder: (_, value, child) => Transform.scale(scale: value, child: child),
  );
}
