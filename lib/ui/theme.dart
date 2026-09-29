import 'package:flutter/material.dart';

/// Brand colors from the design spec (`docs/design.md`); the only place in
/// the app where color values are defined.
abstract final class BrandColors {
  static const forestGreen = Color(0xFF173B2A);
  static const botanicalGreen = Color(0xFF244A36);
  static const sage = Color(0xFFA8B59A);
  static const lightSage = Color(0xFFC9D2BC);
  static const cream = Color(0xFFF5F0E4);
  static const warmBeige = Color(0xFFE8DECC);
  static const terracotta = Color(0xFFB8785C);
  static const ink = Color(0xFF2B2B2B);

  static const nightForest = Color(0xFF13201A);
  static const nightCard = Color(0xFF1E2E25);
  static const lightTerracotta = Color(0xFFD9A080);
}

/// The light theme: cream background, forest green for headings and
/// important buttons, beige cards.
final ThemeData lightTheme = _buildTheme(
  ColorScheme.fromSeed(seedColor: BrandColors.forestGreen).copyWith(
    primary: BrandColors.forestGreen,
    onPrimary: BrandColors.cream,
    secondary: BrandColors.botanicalGreen,
    onSecondary: BrandColors.cream,
    secondaryContainer: BrandColors.sage,
    onSecondaryContainer: BrandColors.forestGreen,
    tertiary: BrandColors.terracotta,
    onTertiary: BrandColors.ink,
    surface: BrandColors.cream,
    onSurface: BrandColors.ink,
    surfaceContainer: BrandColors.warmBeige,
  ),
  cardColor: BrandColors.warmBeige,
);

/// The dark theme: very dark forest green instead of black, sage buttons and
/// cream text.
final ThemeData darkTheme = _buildTheme(
  ColorScheme.fromSeed(
    seedColor: BrandColors.forestGreen,
    brightness: Brightness.dark,
  ).copyWith(
    primary: BrandColors.sage,
    onPrimary: BrandColors.nightForest,
    secondary: BrandColors.lightSage,
    onSecondary: BrandColors.nightForest,
    secondaryContainer: BrandColors.botanicalGreen,
    onSecondaryContainer: BrandColors.cream,
    tertiary: BrandColors.lightTerracotta,
    onTertiary: BrandColors.nightForest,
    surface: BrandColors.nightForest,
    onSurface: BrandColors.cream,
    surfaceContainer: BrandColors.nightCard,
  ),
  cardColor: BrandColors.nightCard,
);

ThemeData _buildTheme(ColorScheme scheme, {required Color cardColor}) {
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: scheme.surface,
    textTheme: _textTheme(scheme),
    appBarTheme: AppBarTheme(
      backgroundColor: scheme.surface,
      foregroundColor: scheme.primary,
      elevation: 0,
      scrolledUnderElevation: 0,
    ),
    cardTheme: CardThemeData(
      color: cardColor,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        shape: const StadiumBorder(),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        shape: const StadiumBorder(),
        foregroundColor: scheme.primary,
        side: BorderSide(color: scheme.primary),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      ),
    ),
    chipTheme: const ChipThemeData(
      shape: StadiumBorder(),
      side: BorderSide.none,
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      showDragHandle: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
    ),
  );
}

/// Playfair Display for headings, Inter for body text and labels, following
/// the sizes of the design spec.
TextTheme _textTheme(ColorScheme scheme) {
  TextStyle heading(double size, int weight) =>
      _style('PlayfairDisplay', size, weight, scheme.primary);
  TextStyle body(double size, int weight) =>
      _style('Inter', size, weight, scheme.onSurface);

  return TextTheme(
    displayLarge: heading(48, 600),
    displayMedium: heading(40, 600),
    displaySmall: heading(34, 600),
    headlineLarge: heading(32, 600),
    headlineMedium: heading(28, 600),
    headlineSmall: heading(24, 600),
    titleLarge: heading(22, 500),
    titleMedium: body(16, 600),
    titleSmall: body(14, 600),
    bodyLarge: body(16, 400),
    bodyMedium: body(14, 400),
    bodySmall: body(12, 400),
    labelLarge: body(14, 600),
    labelMedium: body(12, 500),
    labelSmall: body(11, 500),
  );
}

TextStyle _style(String family, double size, int weight, Color color) {
  return TextStyle(
    fontFamily: family,
    fontSize: size,
    fontWeight: FontWeight.values[weight ~/ 100 - 1],
    fontVariations: [FontVariation('wght', weight.toDouble())],
    color: color,
  );
}
