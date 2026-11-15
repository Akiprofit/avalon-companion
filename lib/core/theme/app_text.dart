
import 'package:material_ui/material_ui.dart';

import 'app_colors.dart';

/// Typography tokens — master plan §3.3.
///
/// Cinzel is display only (titles, role names, victory text).
/// Inter is every other piece of text.
///
/// Both families ship as variable fonts, so each style pins the weight axis
/// explicitly with [FontVariation]; that keeps the rendering identical on every
/// Android build rather than depending on the engine's default instance.
abstract final class AppText {
  static const display = TextStyle(
    fontFamily: 'Cinzel',
    fontFamilyFallback: ['serif'],
    fontSize: 44,
    height: 1.1,
    fontWeight: FontWeight.w600,
    fontVariations: [FontVariation('wght', 600)],
    letterSpacing: 3,
    color: AppColors.parchment,
  );

  static const screenTitle = TextStyle(
    fontFamily: 'Cinzel',
    fontFamilyFallback: ['serif'],
    fontSize: 22,
    height: 1.2,
    fontWeight: FontWeight.w600,
    fontVariations: [FontVariation('wght', 600)],
    letterSpacing: 1.5,
    color: AppColors.parchment,
  );

  static const sectionTitle = TextStyle(
    fontFamily: 'Cinzel',
    fontFamilyFallback: ['serif'],
    fontSize: 14,
    height: 1.3,
    fontWeight: FontWeight.w600,
    fontVariations: [FontVariation('wght', 600)],
    letterSpacing: 1.2,
    color: AppColors.gold,
  );

  static const body = TextStyle(
    fontFamily: 'Inter',
    fontFamilyFallback: ['sans-serif'],
    fontSize: 15,
    height: 1.45,
    fontWeight: FontWeight.w400,
    fontVariations: [FontVariation('wght', 400)],
    color: AppColors.parchment,
  );

  static const bodyStrong = TextStyle(
    fontFamily: 'Inter',
    fontFamilyFallback: ['sans-serif'],
    fontSize: 15,
    height: 1.45,
    fontWeight: FontWeight.w600,
    fontVariations: [FontVariation('wght', 600)],
    color: AppColors.parchment,
  );

  static const caption = TextStyle(
    fontFamily: 'Inter',
    fontFamilyFallback: ['sans-serif'],
    fontSize: 12.5,
    height: 1.4,
    fontWeight: FontWeight.w400,
    fontVariations: [FontVariation('wght', 400)],
    color: AppColors.mutedText,
  );

  static const numeral = TextStyle(
    fontFamily: 'Inter',
    fontFamilyFallback: ['sans-serif'],
    fontSize: 20,
    height: 1.0,
    fontWeight: FontWeight.w600,
    fontVariations: [FontVariation('wght', 600)],
    fontFeatures: [FontFeature.tabularFigures()],
    color: AppColors.parchment,
  );

  static const button = TextStyle(
    fontFamily: 'Inter',
    fontFamilyFallback: ['sans-serif'],
    fontSize: 15,
    height: 1.2,
    fontWeight: FontWeight.w600,
    fontVariations: [FontVariation('wght', 600)],
    letterSpacing: 0.4,
  );

  /// Narration text is read from across a table, so it is deliberately large.
  static const narration = TextStyle(
    fontFamily: 'Inter',
    fontFamilyFallback: ['sans-serif'],
    fontSize: 24,
    height: 1.4,
    fontWeight: FontWeight.w400,
    fontVariations: [FontVariation('wght', 400)],
    color: AppColors.parchment,
  );

  static TextTheme toTextTheme() => const TextTheme(
    displayLarge: display,
    displayMedium: display,
    headlineLarge: screenTitle,
    headlineMedium: screenTitle,
    headlineSmall: screenTitle,
    titleLarge: sectionTitle,
    titleMedium: bodyStrong,
    bodyLarge: body,
    bodyMedium: body,
    bodySmall: caption,
    labelLarge: button,
    labelSmall: caption,
  );
}
