import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:material_ui/material_ui.dart';

import 'app_colors.dart';
import 'app_metrics.dart';
import 'app_page_transitions.dart';
import 'app_text.dart';

/// Dark-only theme assembly. There is no light theme in scope.
abstract final class AppTheme {
  static ThemeData dark() {
    const scheme = ColorScheme.dark(
      primary: AppColors.gold,
      onPrimary: AppColors.onGold,
      secondary: AppColors.mutedGold,
      onSecondary: AppColors.parchment,
      surface: AppColors.surface,
      onSurface: AppColors.parchment,
      error: AppColors.danger,
      onError: AppColors.parchment,
      outline: AppColors.divider,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColors.background,
      canvasColor: AppColors.background,
      dividerColor: AppColors.divider,
      fontFamily: 'Inter',
      textTheme: AppText.toTextTheme(),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
        foregroundColor: AppColors.parchment,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: AppText.sectionTitle,
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.divider,
        thickness: 1,
        space: 1,
      ),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Radii.card),
          side: const BorderSide(color: AppColors.divider),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: Space.md,
          vertical: Space.sm,
        ),
        hintStyle: AppText.caption,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Radii.input),
          borderSide: const BorderSide(color: AppColors.divider),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Radii.input),
          borderSide: const BorderSide(color: AppColors.divider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Radii.input),
          borderSide: const BorderSide(color: AppColors.gold, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Radii.input),
          borderSide: const BorderSide(color: AppColors.danger),
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? AppColors.onGold
              : AppColors.mutedText,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? AppColors.gold
              : AppColors.surfaceRaised,
        ),
        trackOutlineColor: const WidgetStatePropertyAll(AppColors.divider),
      ),
      sliderTheme: const SliderThemeData(
        activeTrackColor: AppColors.gold,
        inactiveTrackColor: AppColors.surfaceRaised,
        thumbColor: AppColors.gold,
        overlayColor: AppColors.goldOverlay,
      ),
      snackBarTheme: const SnackBarThemeData(
        backgroundColor: AppColors.surfaceRaised,
        contentTextStyle: AppText.body,
        behavior: SnackBarBehavior.floating,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Radii.sheet),
          side: const BorderSide(color: AppColors.divider),
        ),
        titleTextStyle: AppText.screenTitle,
        contentTextStyle: AppText.body,
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: CinematicPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        },
      ),
    );
  }
}
