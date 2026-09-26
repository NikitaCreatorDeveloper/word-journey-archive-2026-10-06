import 'package:flutter/material.dart';

abstract final class AppTokens {
  static const spaceXs = 4.0;
  static const spaceSm = 8.0;
  static const spaceMd = 12.0;
  static const spaceLg = 20.0;
  static const spaceXl = 28.0;
  static const spaceXxl = 40.0;
  static const cardRadius = 12.0;
  static const controlRadius = 16.0;
  static const wordSize = 20.0;
  static const boardMaxWidth = 560.0;
  static const pressDuration = Duration(milliseconds: 80);
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
  static const cardHorizontalPadding = 16.0;
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

/// Surfaces and semantic colors shared by training and future atlas screens.
@immutable
class AtlasColors extends ThemeExtension<AtlasColors> {
  const AtlasColors({
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

  static AtlasColors of(BuildContext context) =>
      Theme.of(context).extension<AtlasColors>() ??
      (Theme.of(context).brightness == Brightness.dark ? dark : light);

  static const light = AtlasColors(
    backgroundEnd: Color(0xFFEAF0EB),
    card: Color(0xFFFFFEFA),
    cardOutline: Color(0xFFE1E7DF),
    selected: Color(0xFFD6E9DF),
    onSelected: Color(0xFF214F44),
    success: Color(0xFFE4EAE7),
    onSuccess: Color(0xFF52665C),
    error: Color(0xFFF4DCD5),
    onError: Color(0xFF853E32),
    shadow: Color(0x0E233B35),
  );
  static const dark = AtlasColors(
    backgroundEnd: Color(0xFF151E27),
    card: Color(0xFF202A35),
    cardOutline: Color(0xFF34404C),
    selected: Color(0xFF253F4A),
    onSelected: Color(0xFFD7EDF0),
    success: Color(0xFF192A28),
    onSuccess: Color(0xFF9EB6AE),
    error: Color(0xFF643D39),
    onError: Color(0xFFFFE1D8),
    shadow: Color(0x2205090B),
  );

  List<BoxShadow> get cardShadows => [
    BoxShadow(color: shadow, blurRadius: 6, offset: const Offset(0, 1)),
  ];

  @override
  AtlasColors copyWith({
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
  }) => AtlasColors(
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
  AtlasColors lerp(covariant AtlasColors? other, double t) {
    if (other == null) return this;
    return AtlasColors(
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
    final atlas = isDark ? AtlasColors.dark : AtlasColors.light;
    final scheme =
        ColorScheme.fromSeed(
          seedColor: const Color(0xFF376F64),
          brightness: brightness,
        ).copyWith(
          primary: isDark ? const Color(0xFFACD7C5) : const Color(0xFF285F53),
          onPrimary: isDark ? const Color(0xFF173D32) : const Color(0xFFFFFFFF),
          surface: isDark ? const Color(0xFF111820) : const Color(0xFFF5F3EE),
          onSurface: isDark ? const Color(0xFFE7EFEB) : const Color(0xFF243A35),
          primaryContainer: atlas.selected,
          onPrimaryContainer: atlas.onSelected,
          errorContainer: atlas.error,
          onErrorContainer: atlas.onError,
          outlineVariant: atlas.cardOutline,
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
          fontWeight: FontWeight.w600,
          letterSpacing: -0.7,
        ),
        titleLarge: base.textTheme.titleLarge?.copyWith(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.4,
        ),
        labelLarge: base.textTheme.labelLarge?.copyWith(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          letterSpacing: 0,
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleTextStyle: TextStyle(
          color: scheme.onSurface,
          fontSize: 24,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.4,
        ),
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
        indicatorColor: atlas.selected,
        elevation: 0,
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: scheme.primary,
        linearTrackColor: atlas.cardOutline,
      ),
    );
  }
}
