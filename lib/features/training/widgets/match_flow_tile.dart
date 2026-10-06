import 'package:flutter/material.dart';

import '../model/match_flow_models.dart';

/// The same lightweight tile is painted in Match Flow Lab and the real board.
class MatchFlowTile extends StatelessWidget {
  const MatchFlowTile({
    super.key,
    required this.text,
    required this.visual,
    required this.selected,
    required this.enabled,
    required this.onPressed,
    this.textKey,
    this.debugLabel,
    this.maxLines,
  });
  static const background = Color(0xFF111827);
  static const minHeight = 64.0, maxHeight = 104.0, boardWidth = 540.0;
  static const wordStyle = TextStyle(
    fontSize: 20,
    height: 1.15,
    fontWeight: FontWeight.w600,
  );
  final String text;
  final CardTransitionVisual visual;
  final bool selected, enabled;
  final VoidCallback onPressed;
  final Key? textKey;
  final Widget? debugLabel;
  final int? maxLines;

  @override
  Widget build(BuildContext context) {
    final base = selected ? const Color(0xFF4C4786) : const Color(0xFF202C41);
    var fill = Color.lerp(base, const Color(0xFF247F6E), visual.successTint)!;
    var border = Color.lerp(
      selected ? const Color(0xFFA8A1FF) : const Color(0xFF536079),
      const Color(0xFF75DFC2),
      visual.successTint,
    )!;
    fill = Color.lerp(fill, const Color(0xFF804653), visual.errorTint * .55)!;
    border = Color.lerp(border, const Color(0xFFEF9BA5), visual.errorTint)!;
    return RepaintBoundary(
      child: Semantics(
        button: true,
        enabled: enabled,
        selected: selected,
        label: text,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: enabled ? onPressed : null,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: fill.withValues(alpha: visual.surfaceOpacity),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: border.withValues(alpha: visual.surfaceOpacity),
                width: selected ? 1.8 : 1,
              ),
            ),
            child: Column(
              children: [
                Expanded(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Text(
                        text,
                        key: textKey,
                        textAlign: TextAlign.center,
                        maxLines: maxLines,
                        style: wordStyle.copyWith(
                          color: const Color(0xFFF4F5FF)
                              .withValues(alpha: visual.textOpacity),
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 20, child: debugLabel),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
