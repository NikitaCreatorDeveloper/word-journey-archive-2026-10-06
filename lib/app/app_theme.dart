import 'package:flutter/material.dart';

import 'design_tokens.dart';

abstract final class AppTokens {
  static const spaceXs = 4.0;
  static const spaceSm = 8.0;
  static const spaceMd = 12.0;
  static const spaceLg = 16.0;
  static const spaceXl = 24.0;
  static const spaceXxl = 32.0;
  static const cardRadius = 16.0;
  static const controlRadius = 16.0;
  static const wordSize = 20.0;
  static const wordMinSize = 18.0;
  static const boardMaxWidth = 560.0;
  static const pressDuration = Duration(milliseconds: 140);
  static const feedbackDuration = Duration(milliseconds: 140);
  static const boardGap = 10.0;
  static const batchGapDuration = Duration(milliseconds: 50);
  static const incomingTapOpacity = .75;
  static const incomingScale = .985;
  static const pressScale = .985;
  static const correctScaleAmplitude = .015;
  static const wrongOffset = 1.5;
  static const wrongTintStrength = .4;
  static const cardMinHeight = 54.0;
  static const cardMaxHeight = 64.0;
  static const boardContentHeight = 300.0;
  static const cardHorizontalPadding = 8.0;
  static const cardVerticalPadding = 6.0;
  static const wordMaxSize = 26.0;
  static const wordWeight = FontWeight.w600;
  static const wordLetterSpacing = -.5;
  static const cardBorderWidth = .8;
  static const selectedBorderOpacity = .45;
  static const wordHeightRatio = .5;
  static const wordLineHeight = 1.1;
  static const timerFontSize = 18.0;
  static const hudIconSize = 20.0;
  static const progressHeight = 5.0;
  static const timerWarningSeconds = 20;
  static const timerWarningDark = Color(0xFFE0B986);
  static const timerWarningLight = Color(0xFF885B2F);
  static const pauseOpacity = .9;
  static const clockRefreshInterval = Duration(milliseconds: 100);
  static const sessionFinishDuration = Duration(milliseconds: 620);
  static const matchedSettleDuration = Duration(milliseconds: 150);
  static const batchExitDuration = Duration(milliseconds: 180);
  static const batchEntryDuration = Duration(milliseconds: 320);
  static const progressDuration = Duration(milliseconds: 320);
}

final _wordSizeCache = <(String, double, double), double>{};
TextStyle trainingWordStyle(String text, double maxWidth, TextScaler scaler) {
  final key = (text, maxWidth, scaler.scale(AppTokens.wordSize));
  var size = _wordSizeCache[key];
  if (size == null) {
    final painter = TextPainter(
      textDirection: TextDirection.ltr,
      textScaler: scaler,
    );
    var longest = 0.0;
    for (final word in text.split(RegExp(r'\s+'))) {
      painter.text = TextSpan(
        text: word,
        style: const TextStyle(
          fontSize: AppTokens.wordSize,
          fontWeight: AppTokens.wordWeight,
          letterSpacing: AppTokens.wordLetterSpacing,
        ),
      );
      painter.layout();
      if (painter.width > longest) longest = painter.width;
    }
    painter.dispose();
    size = longest > maxWidth && longest > 0
        ? (AppTokens.wordSize * maxWidth / longest)
              .clamp(AppTokens.wordMinSize, AppTokens.wordSize)
              .toDouble()
        : AppTokens.wordSize;
    if (_wordSizeCache.length >= 256) _wordSizeCache.clear();
    _wordSizeCache[key] = size;
  }
  return TextStyle(
    fontSize: size,
    height: AppTokens.wordLineHeight,
    fontWeight: AppTokens.wordWeight,
    letterSpacing: AppTokens.wordLetterSpacing,
  );
}

/// Surfaces and semantic colors shared by training and personal trainer screens.
@immutable
class TrainerColors extends ThemeExtension<TrainerColors> {
  const TrainerColors({
    required this.backgroundEnd,
    required this.card,
    required this.cardOutline,
    required this.selected,
    required this.onSelected,
    required this.success,
    required this.onSuccess,
    required this.error,
    required this.onError,
    required this.shadow,
  });

  final Color backgroundEnd;
  final Color card;
  final Color cardOutline;
  final Color selected;
  final Color onSelected;
  final Color success;
  final Color onSuccess;
  final Color error;
  final Color onError;
  final Color shadow;

  static TrainerColors of(BuildContext context) =>
      Theme.of(context).extension<TrainerColors>() ??
      (Theme.of(context).brightness == Brightness.dark ? dark : light);

  static const light = TrainerColors(
    backgroundEnd: Color(0xFFEDF0FC),
    card: Color(0xFFFFFEFA),
    cardOutline: Color(0xFFDEE3F0),
    selected: Color(0xFFDDDFFF),
    onSelected: Color(0xFF343183),
    success: Color(0xFFCFF1E9),
    onSuccess: Color(0xFF145E53),
    error: Color(0xFFF4DCD5),
    onError: Color(0xFF853E32),
    shadow: Color(0x0E233B35),
  );
  static const dark = TrainerColors(
    backgroundEnd: AppColors.backgroundSecondary,
    card: AppColors.surface,
    cardOutline: Color(0xFF565C91),
    selected: Color(0xFF353164),
    onSelected: AppColors.textPrimary,
    success: Color(0xFF153C3B),
    onSuccess: Color(0xFFC3FFF0),
    error: Color(0xFF643445),
    onError: Color(0xFFFFE7ED),
    shadow: Color(0x2205090B),
  );

  List<BoxShadow> get cardShadows => [
    BoxShadow(color: shadow, blurRadius: 6, offset: const Offset(0, 1)),
  ];

  @override
  TrainerColors copyWith({
    Color? backgroundEnd,
    Color? card,
    Color? cardOutline,
    Color? selected,
    Color? onSelected,
    Color? success,
    Color? onSuccess,
    Color? error,
    Color? onError,
    Color? shadow,
  }) => TrainerColors(
    backgroundEnd: backgroundEnd ?? this.backgroundEnd,
    card: card ?? this.card,
    cardOutline: cardOutline ?? this.cardOutline,
    selected: selected ?? this.selected,
    onSelected: onSelected ?? this.onSelected,
    success: success ?? this.success,
    onSuccess: onSuccess ?? this.onSuccess,
    error: error ?? this.error,
    onError: onError ?? this.onError,
    shadow: shadow ?? this.shadow,
  );

  @override
  TrainerColors lerp(covariant TrainerColors? other, double t) {
    if (other == null) return this;
    return TrainerColors(
      backgroundEnd: Color.lerp(backgroundEnd, other.backgroundEnd, t)!,
      card: Color.lerp(card, other.card, t)!,
      cardOutline: Color.lerp(cardOutline, other.cardOutline, t)!,
      selected: Color.lerp(selected, other.selected, t)!,
      onSelected: Color.lerp(onSelected, other.onSelected, t)!,
      success: Color.lerp(success, other.success, t)!,
      onSuccess: Color.lerp(onSuccess, other.onSuccess, t)!,
      error: Color.lerp(error, other.error, t)!,
      onError: Color.lerp(onError, other.onError, t)!,
      shadow: Color.lerp(shadow, other.shadow, t)!,
    );
  }
}

abstract final class AppTheme {
  static final light = _build(Brightness.light);
  static final dark = _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final atlas = isDark ? TrainerColors.dark : TrainerColors.light;
    final scheme =
        ColorScheme.fromSeed(
          seedColor: AppColors.lightAccent,
          brightness: brightness,
        ).copyWith(
          primary: isDark ? AppColors.accentPrimary : AppColors.lightAccent,
          onPrimary: isDark ? const Color(0xFF201746) : const Color(0xFFFFFFFF),
          surface: isDark
              ? AppColors.backgroundPrimary
              : AppColors.lightBackground,
          onSurface: isDark ? AppColors.textPrimary : AppColors.lightText,
          primaryContainer: atlas.selected,
          onPrimaryContainer: atlas.onSelected,
          errorContainer: atlas.error,
          onErrorContainer: atlas.onError,
          outlineVariant: atlas.cardOutline,
          onSurfaceVariant: isDark
              ? AppColors.textSecondary
              : const Color(0xFF565574),
          outline: isDark ? const Color(0xFF8E91BC) : const Color(0xFF77728E),
        );
    final base = ThemeData(useMaterial3: true, colorScheme: scheme);
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppTokens.controlRadius),
    );
    return base.copyWith(
      extensions: [atlas],
      scaffoldBackgroundColor: scheme.surface,
      textTheme: base.textTheme.copyWith(
        headlineMedium: base.textTheme.headlineMedium?.copyWith(
          fontSize: 30,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.65,
        ),
        titleLarge: base.textTheme.titleLarge?.copyWith(
          fontSize: 21,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.4,
        ),
        labelLarge: base.textTheme.labelLarge?.copyWith(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          letterSpacing: 0,
        ),
        titleMedium: base.textTheme.titleMedium?.copyWith(
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
        bodyLarge: base.textTheme.bodyLarge?.copyWith(
          fontSize: 16,
          height: 1.35,
        ),
        bodyMedium: base.textTheme.bodyMedium?.copyWith(
          fontSize: 16,
          height: 1.35,
        ),
        bodySmall: base.textTheme.bodySmall?.copyWith(
          fontSize: 14,
          height: 1.35,
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleTextStyle: TextStyle(
          color: scheme.onSurface,
          fontSize: 28,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.4,
        ),
      ),
      cardTheme: CardThemeData(
        color: atlas.card,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      ),
      listTileTheme: const ListTileThemeData(
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        minVerticalPadding: 12,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: atlas.card.withValues(alpha: .75),
        contentPadding: const EdgeInsets.all(16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: BorderSide(color: atlas.cardOutline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: BorderSide(
            color: isDark ? const Color(0xFF8E89C6) : const Color(0xFFB4AAD9),
            width: .9,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: BorderSide(color: scheme.primary, width: 1.6),
        ),
      ),
      chipTheme: base.chipTheme.copyWith(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        side: BorderSide.none,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(48, 54),
          shape: shape,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(48, 54),
          shape: shape,
          side: BorderSide(color: atlas.cardOutline),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        ),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          padding: const WidgetStatePropertyAll(
            EdgeInsets.symmetric(vertical: 16),
          ),
          side: WidgetStatePropertyAll(BorderSide(color: atlas.cardOutline)),
          shape: WidgetStatePropertyAll(shape),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: scheme.surface,
        indicatorColor: Colors.transparent,
        height: 78,
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => TextStyle(
            fontSize: 13,
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w600
                : FontWeight.w400,
            color: states.contains(WidgetState.selected)
                ? scheme.onSurface
                : scheme.onSurfaceVariant,
          ),
        ),
        elevation: 0,
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: scheme.primary,
        linearTrackColor: atlas.cardOutline,
      ),
    );
  }
}
