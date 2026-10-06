import 'package:flutter/material.dart';

abstract final class AppColors {
  static const backgroundPrimary = Color(0xFF0A1025);
  static const backgroundSecondary = Color(0xFF101833);
  static const surface = Color(0xFF19213F);
  static const surfaceElevated = Color(0xFF222B50);
  static const accentPrimary = Color(0xFFBDAFFF);
  static const accentSecondary = Color(0xFF7863E8);
  static const textPrimary = Color(0xFFF5F3FF);
  static const textSecondary = Color(0xFFBCBDE0);
  static const success = Color(0xFF67E3CD);
  static const warning = Color(0xFFF2CE91);
  static const error = Color(0xFFEE959F);
  static const lightBackground = Color(0xFFF6F5FD);
  static const lightText = Color(0xFF232346);
  static const lightAccent = Color(0xFF5845BB);
}

abstract final class AppSpacing {
  static const xs = 4.0,
      sm = 8.0,
      md = 12.0,
      lg = 16.0,
      card = 20.0,
      page = 24.0,
      section = 32.0,
      hero = 40.0;
}

abstract final class AppRadius {
  static const control = 16.0, card = 20.0, hero = 24.0, pill = 32.0;
}

abstract final class AppTypography {
  static const screen = TextStyle(
    fontSize: 30,
    fontWeight: FontWeight.w700,
    letterSpacing: -.65,
  );
  static const section = TextStyle(
    fontSize: 21,
    fontWeight: FontWeight.w700,
    letterSpacing: -.35,
  );
  static const title = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    height: 1.25,
  );
  static const body = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 1.35,
  );
  static const meta = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.35,
  );
}

abstract final class AppMotion {
  static const curve = Curves.easeOutCubic;
  static const refillStartScale = .985;
  static const refillReadableOpacity = .65;
  static const press = Duration(milliseconds: 140);
  static const selection = Duration(milliseconds: 200);
  static const page = Duration(milliseconds: 260);
  static const feedback = Duration(milliseconds: 480);
}

abstract final class AppShadows {
  static List<BoxShadow> glow(Color color, {double strength = .18}) => [
    BoxShadow(
      color: color.withValues(alpha: strength),
      blurRadius: 12,
      spreadRadius: 0,
      offset: const Offset(0, 2),
    ),
  ];
}

abstract final class AppSurfaces {
  static bool dark(BuildContext c) => Theme.of(c).brightness == Brightness.dark;
  static LinearGradient card(BuildContext c) => LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: dark(c)
        ? const [Color(0xFF212C50), Color(0xFF151D38)]
        : const [Colors.white, Color(0xFFF4F2FD)],
  );
  static LinearGradient hero(BuildContext c) => LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: dark(c)
        ? const [Color(0xFF363D86), Color(0xFF3E3587), Color(0xFF141E40)]
        : const [Color(0xFFE6DFFF), Color(0xFFE2E7FF), Color(0xFFF4F2FD)],
  );
  static LinearGradient accent(BuildContext c) => LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: dark(c)
        ? const [Color(0xFFD2C4FF), Color(0xFFA493FA)]
        : const [Color(0xFF7460DD), Color(0xFF5440B2)],
  );
  static Color outline(BuildContext c) =>
      dark(c) ? const Color(0xFF5B609D) : const Color(0xFFCBC5EB);
}
