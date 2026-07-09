import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_radius.dart';

abstract final class AppTheme {
  static ThemeData light() {
    final colorScheme =
        ColorScheme.fromSeed(
          seedColor: AppColors.primaryBlue,
          brightness: Brightness.light,
        ).copyWith(
          primary: AppColors.primaryBlue,
          onPrimary: AppColors.white,
          secondary: AppColors.teal,
          onSecondary: AppColors.white,
          tertiary: AppColors.coral,
          onTertiary: AppColors.white,
          surface: AppColors.surface,
          onSurface: AppColors.textPrimary,
          surfaceContainerHighest: AppColors.surfaceRaised,
          outline: AppColors.border,
          outlineVariant: AppColors.borderStrong,
        );

    return _themeFrom(colorScheme);
  }

  static ThemeData dark() {
    final colorScheme =
        ColorScheme.fromSeed(
          seedColor: AppColors.primaryBlueLight,
          brightness: Brightness.dark,
        ).copyWith(
          primary: AppColors.primaryBlueLight,
          onPrimary: AppColors.navy950,
          secondary: AppColors.teal,
          onSecondary: AppColors.navy950,
          tertiary: AppColors.coral,
          onTertiary: AppColors.navy950,
          surface: AppColors.navy950,
          onSurface: AppColors.white,
          surfaceContainerHighest: AppColors.navy900,
          outline: AppColors.navy700,
          outlineVariant: AppColors.navy800,
        );

    return _themeFrom(colorScheme);
  }

  static ThemeData _themeFrom(ColorScheme colorScheme) {
    final isDark = colorScheme.brightness == Brightness.dark;
    final base = ThemeData(
      useMaterial3: true,
      brightness: colorScheme.brightness,
      colorScheme: colorScheme,
    );

    return base.copyWith(
      scaffoldBackgroundColor: colorScheme.surface,
      textTheme: _textTheme(base.textTheme, isDark),
      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: colorScheme.onSurface,
        surfaceTintColor: Colors.transparent,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        margin: EdgeInsets.zero,
        color: colorScheme.surfaceContainerHighest,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.card),
      ),
      chipTheme: base.chipTheme.copyWith(
        backgroundColor: AppColors.white,
        selectedColor: AppColors.primaryBlue,
        side: BorderSide(color: colorScheme.outline),
        shape: const StadiumBorder(),
        labelStyle: base.textTheme.labelLarge?.copyWith(
          fontWeight: FontWeight.w700,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.white.withValues(alpha: isDark ? 0.08 : 0.94),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.pill),
          borderSide: BorderSide(color: colorScheme.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.pill),
          borderSide: BorderSide(color: colorScheme.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.pill),
          borderSide: const BorderSide(color: AppColors.primaryBlue, width: 2),
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        selectedItemColor: AppColors.primaryBlue,
        unselectedItemColor: AppColors.textMuted,
        type: BottomNavigationBarType.fixed,
        backgroundColor: AppColors.white,
        elevation: 0,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.white,
        surfaceTintColor: Colors.transparent,
        indicatorColor: AppColors.primaryBlue.withValues(alpha: 0.12),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return base.textTheme.labelMedium?.copyWith(
            color: selected ? AppColors.primaryBlue : AppColors.textMuted,
            fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
          );
        }),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.all(AppColors.white),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.coral;
          }
          return AppColors.borderStrong;
        }),
      ),
    );
  }

  static TextTheme _textTheme(TextTheme base, bool isDark) {
    final color = isDark ? AppColors.white : AppColors.textPrimary;
    final muted = isDark
        ? AppColors.white.withValues(alpha: 0.72)
        : AppColors.textSecondary;

    return base.copyWith(
      displayLarge: base.displayLarge?.copyWith(
        color: color,
        fontWeight: FontWeight.w900,
        letterSpacing: 0,
      ),
      displayMedium: base.displayMedium?.copyWith(
        color: color,
        fontWeight: FontWeight.w900,
        letterSpacing: 0,
      ),
      displaySmall: base.displaySmall?.copyWith(
        color: color,
        fontWeight: FontWeight.w900,
        letterSpacing: 0,
      ),
      headlineLarge: base.headlineLarge?.copyWith(
        color: color,
        fontWeight: FontWeight.w900,
        letterSpacing: 0,
      ),
      headlineMedium: base.headlineMedium?.copyWith(
        color: color,
        fontWeight: FontWeight.w800,
        letterSpacing: 0,
      ),
      headlineSmall: base.headlineSmall?.copyWith(
        color: color,
        fontWeight: FontWeight.w800,
        letterSpacing: 0,
      ),
      titleLarge: base.titleLarge?.copyWith(
        color: color,
        fontWeight: FontWeight.w800,
        letterSpacing: 0,
      ),
      titleMedium: base.titleMedium?.copyWith(
        color: color,
        fontWeight: FontWeight.w700,
        letterSpacing: 0,
      ),
      titleSmall: base.titleSmall?.copyWith(
        color: color,
        fontWeight: FontWeight.w700,
        letterSpacing: 0,
      ),
      bodyLarge: base.bodyLarge?.copyWith(
        color: muted,
        fontWeight: FontWeight.w500,
        letterSpacing: 0,
      ),
      bodyMedium: base.bodyMedium?.copyWith(
        color: muted,
        fontWeight: FontWeight.w500,
        letterSpacing: 0,
      ),
      bodySmall: base.bodySmall?.copyWith(
        color: muted,
        fontWeight: FontWeight.w500,
        letterSpacing: 0,
      ),
      labelLarge: base.labelLarge?.copyWith(
        color: color,
        fontWeight: FontWeight.w800,
        letterSpacing: 0,
      ),
      labelMedium: base.labelMedium?.copyWith(
        color: color,
        fontWeight: FontWeight.w700,
        letterSpacing: 0,
      ),
      labelSmall: base.labelSmall?.copyWith(
        color: muted,
        fontWeight: FontWeight.w700,
        letterSpacing: 0,
      ),
    );
  }
}
