import 'package:flutter/material.dart';

import 'premium_art.dart';

class CategoryGlyph extends StatelessWidget {
  const CategoryGlyph({super.key, required this.symbol, this.size = 56});
  final String symbol;
  final double size;
  static const names = {
    'home': 'daily',
    'people': 'communication',
    'food': 'food',
    'money': 'shopping',
    'city': 'city',
    'trip': 'travel',
    'work': 'work_study',
    'tech': 'technology',
    'nature': 'nature',
    'health': 'health',
    'culture': 'leisure',
    'thoughts': 'thoughts',
  };
  @override
  Widget build(BuildContext context) => PremiumArt(
    'category_icons/${names[symbol] ?? 'thoughts'}',
    width: size,
    height: size,
  );
}
