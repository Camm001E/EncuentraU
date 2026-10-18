import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_sizes.dart';
import 'app_semantic_colors.dart';

abstract final class AppTheme {
  static ThemeData get light {
    const scheme = ColorScheme.light(
      primary: AppColors.primary,
      onPrimary: AppColors.surface,
      primaryContainer: AppColors.greenSurface,
      onPrimaryContainer: AppColors.primary,
      secondary: AppColors.textPrimary,
      onSecondary: AppColors.surface,
      secondaryContainer: AppColors.peachSurface,
      onSecondaryContainer: AppColors.textPrimary,
      tertiary: AppColors.textPrimary,
      onTertiary: AppColors.surface,
      tertiaryContainer: AppColors.lavenderSurface,
      onTertiaryContainer: AppColors.textPrimary,
      surface: AppColors.surface,
      onSurface: AppColors.textPrimary,
      onSurfaceVariant: AppColors.textSecondary,
      surfaceContainerLowest: AppColors.surface,
      surfaceContainerLow: AppColors.background,
      surfaceContainer: AppColors.greenSurface,
      surfaceContainerHigh: AppColors.greenSurface,
      surfaceContainerHighest: AppColors.border,
      outline: AppColors.textSecondary,
      outlineVariant: AppColors.border,
      error: AppColors.error,
      onError: AppColors.surface,
      errorContainer: AppColors.errorBackground,
      onErrorContainer: AppColors.textPrimary,
      inverseSurface: AppColors.textPrimary,
      onInverseSurface: AppColors.surface,
      inversePrimary: AppColors.sage,
      shadow: AppColors.textPrimary,
      scrim: AppColors.textPrimary,
      surfaceTint: AppColors.surface,
    );
    final base = ThemeData(
        useMaterial3: true,
        colorScheme: scheme,
        scaffoldBackgroundColor: AppColors.background,
        extensions: const [AppSemanticColors.light]);
    final text = base.textTheme
        .apply(bodyColor: scheme.onSurface, displayColor: scheme.onSurface);
    final shape = RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSizes.radiusLarge));
    return base.copyWith(
      textTheme: text.copyWith(
        headlineLarge: text.headlineLarge?.copyWith(
            fontWeight: FontWeight.w800,
            letterSpacing: AppSizes.titleLetterSpacing),
        headlineMedium: text.headlineMedium?.copyWith(
            fontWeight: FontWeight.w800,
            letterSpacing: AppSizes.titleLetterSpacing),
        headlineSmall:
            text.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
        titleLarge: text.titleLarge?.copyWith(fontWeight: FontWeight.w700),
        titleMedium: text.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        bodyLarge: text.bodyLarge?.copyWith(height: 1.5),
        bodyMedium: text.bodyMedium?.copyWith(height: 1.45),
      ),
      appBarTheme: AppBarTheme(
          centerTitle: false,
          backgroundColor: AppColors.background,
          foregroundColor: scheme.onSurface,
          elevation: 0,
          scrolledUnderElevation: 0,
          titleTextStyle:
              text.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
      cardTheme: CardThemeData(
          elevation: 0,
          margin: EdgeInsets.zero,
          color: scheme.surface,
          shape:
              shape.copyWith(side: BorderSide(color: scheme.outlineVariant))),
      inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: scheme.surface,
          contentPadding: const EdgeInsets.all(AppSizes.spacingMedium),
          labelStyle: TextStyle(color: scheme.onSurfaceVariant),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSizes.radiusSmall)),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
              borderSide: BorderSide(color: scheme.outline)),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
              borderSide: BorderSide(
                  color: scheme.primary, width: AppSizes.strokeWidth))),
      filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
              minimumSize:
                  const Size(AppSizes.touchTarget, AppSizes.touchTarget),
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSizes.buttonHorizontalPadding,
                  vertical: AppSizes.spacingMedium),
              shape: shape)),
      outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
              minimumSize:
                  const Size(AppSizes.touchTarget, AppSizes.touchTarget),
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSizes.buttonHorizontalPadding,
                  vertical: AppSizes.spacingMedium),
              side: BorderSide(color: scheme.outlineVariant),
              shape: shape)),
      textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
              minimumSize:
                  const Size(AppSizes.touchTarget, AppSizes.touchTarget))),
      iconButtonTheme: IconButtonThemeData(
          style: IconButton.styleFrom(
              minimumSize:
                  const Size(AppSizes.touchTarget, AppSizes.touchTarget))),
      navigationBarTheme: NavigationBarThemeData(
          backgroundColor: scheme.surface,
          indicatorColor: scheme.primaryContainer,
          elevation: 0,
          labelTextStyle: WidgetStatePropertyAll(
              text.labelMedium?.copyWith(fontWeight: FontWeight.w600))),
      navigationRailTheme: NavigationRailThemeData(
          backgroundColor: scheme.surface,
          indicatorColor: scheme.primaryContainer,
          selectedIconTheme: IconThemeData(color: scheme.primary),
          selectedLabelTextStyle:
              text.labelLarge?.copyWith(color: scheme.primary)),
      chipTheme: ChipThemeData(
          side: BorderSide.none,
          backgroundColor: scheme.surface,
          selectedColor: scheme.primaryContainer,
          labelStyle: TextStyle(color: scheme.onSurface),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSizes.radiusSmall)),
          padding: const EdgeInsets.all(AppSizes.spacingSmall)),
      snackBarTheme: SnackBarThemeData(
          behavior: SnackBarBehavior.floating,
          backgroundColor: scheme.inverseSurface,
          contentTextStyle: TextStyle(color: scheme.onInverseSurface),
          shape: shape),
      dividerTheme:
          DividerThemeData(color: scheme.outlineVariant, thickness: 1),
      progressIndicatorTheme: ProgressIndicatorThemeData(
          color: scheme.primary, linearTrackColor: scheme.outlineVariant),
    );
  }
}
