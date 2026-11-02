import 'package:flutter/material.dart';

class MeloColors {
  // Dark Theme Tokens (Default)
  static const Color darkBgBase = Color(0xFF081012);
  static const Color darkSurface1 = Color(0xFF0E1A1D);
  static const Color darkSurface2 = Color(0xFF142529);
  static const Color darkSurface3 = Color(0xFF1B3237);

  // Teal Accents (Strictly curated, never plain green)
  static const Color primaryTeal = Color(0xFF14B8A6);
  static const Color tealLight = Color(0xFF5EEAD4);
  static const Color tealDeep = Color(0xFF0F766E);
  static const Color tealGlow = Color(0x3314B8A6);
  static const Color tealGlowSoft = Color(0x1A14B8A6);

  // Dark Text Tokens
  static const Color darkTextPrimary = Color(0xFFEAF6F5);
  static const Color darkTextSecondary = Color(0xFF8FA9AB);
  static const Color darkTextMuted = Color(0xFF5B7476);
  static const Color darkBorder = Color(0x14FFFFFF); // 8% white

  // Light Theme Tokens
  static const Color lightBgBase = Color(0xFFF3F7F7);
  static const Color lightSurface1 = Color(0xFFE5EDED);
  static const Color lightSurface2 = Color(0xFFD6E2E2);
  static const Color lightSurface3 = Color(0xFFC7D7D7);
  static const Color lightTextPrimary = Color(0xFF0A1719);
  static const Color lightTextSecondary = Color(0xFF436063);
  static const Color lightTextMuted = Color(0xFF759194);
  static const Color lightBorder = Color(0x1A0F766E);

  // Accents / Status
  static const Color favoriteRed = Color(0xFFFF5376);
  static const Color activeGreen = Color(0xFF2DD4BF);
  static const Color warningAmber = Color(0xFFFBBF24);
}

class MeloTheme {
  static ThemeData darkTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: MeloColors.darkBgBase,
      primaryColor: MeloColors.primaryTeal,
      colorScheme: const ColorScheme.dark(
        primary: MeloColors.primaryTeal,
        secondary: MeloColors.tealLight,
        surface: MeloColors.darkSurface1,
        surfaceContainerHighest: MeloColors.darkSurface2,
        onSurface: MeloColors.darkTextPrimary,
        onPrimary: MeloColors.darkBgBase,
        onSecondaryContainer: MeloColors.tealLight,
      ),
      fontFamily: 'Segoe UI',
      cardColor: MeloColors.darkSurface1,
      dividerColor: MeloColors.darkBorder,
      sliderTheme: const SliderThemeData(
        activeTrackColor: MeloColors.primaryTeal,
        inactiveTrackColor: Color(0x3314B8A6),
        thumbColor: MeloColors.tealLight,
        overlayColor: Color(0x2914B8A6),
        trackHeight: 3.0,
        thumbShape: RoundSliderThumbShape(enabledThumbRadius: 6.0),
      ),
      scrollbarTheme: ScrollbarThemeData(
        thumbColor: WidgetStateProperty.all(const Color(0x3314B8A6)),
        radius: const Radius.circular(8),
        thickness: WidgetStateProperty.all(5),
      ),
    );
  }

  static ThemeData lightTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: MeloColors.lightBgBase,
      primaryColor: MeloColors.tealDeep,
      colorScheme: const ColorScheme.light(
        primary: MeloColors.tealDeep,
        secondary: MeloColors.primaryTeal,
        surface: MeloColors.lightSurface1,
        surfaceContainerHighest: MeloColors.lightSurface2,
        onSurface: MeloColors.lightTextPrimary,
        onPrimary: Colors.white,
      ),
      fontFamily: 'Segoe UI',
      cardColor: MeloColors.lightSurface1,
      dividerColor: MeloColors.lightBorder,
      sliderTheme: const SliderThemeData(
        activeTrackColor: MeloColors.tealDeep,
        inactiveTrackColor: Color(0x2A0F766E),
        thumbColor: MeloColors.tealDeep,
        overlayColor: Color(0x200F766E),
        trackHeight: 3.0,
        thumbShape: RoundSliderThumbShape(enabledThumbRadius: 6.0),
      ),
      scrollbarTheme: ScrollbarThemeData(
        thumbColor: WidgetStateProperty.all(const Color(0x330F766E)),
        radius: const Radius.circular(8),
        thickness: WidgetStateProperty.all(5),
      ),
    );
  }
}
