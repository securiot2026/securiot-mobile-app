import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Material 3 theme translating the shared SecurIoT brand world (palette,
/// Roboto type scale, 8pt spacing) into native idioms for this surface.
class AppTheme {
  const AppTheme._();

  static ThemeData light() {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.accent,
      brightness: Brightness.light,
      surface: AppColors.surface,
      primary: AppColors.accent,
      onPrimary: Colors.white,
      error: AppColors.destructive,
    );

    const fontFamily = 'Roboto';

    final textTheme = const TextTheme(
      bodyLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.w400, height: 1.5),
      bodyMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w400, height: 1.5),
      labelLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.w400, height: 1.5),
      labelMedium: TextStyle(fontSize: 14, fontWeight: FontWeight.w400, height: 1.5),
      titleLarge: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, height: 1.2),
      titleMedium: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, height: 1.2),
      headlineSmall: TextStyle(fontSize: 28, fontWeight: FontWeight.w600, height: 1.2),
    ).apply(fontFamily: fontFamily, bodyColor: AppColors.ink, displayColor: AppColors.ink);

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.surface,
      fontFamily: fontFamily,
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.ink,
        foregroundColor: Colors.white,
        elevation: 0,
        titleTextStyle: textTheme.titleLarge?.copyWith(color: Colors.white),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.ink,
        indicatorColor: AppColors.accent.withValues(alpha: 0.24),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return TextStyle(
            fontSize: 12,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
            color: selected ? AppColors.accent : Colors.white70,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(color: selected ? AppColors.accent : Colors.white70);
        }),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.accent,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(48),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle: textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: AppColors.ink.withValues(alpha: 0.2)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.accent, width: 2),
        ),
      ),
      cardTheme: const CardThemeData(
        color: Colors.white,
        elevation: 1,
        margin: EdgeInsets.zero,
      ),
      dividerTheme: DividerThemeData(color: AppColors.ink.withValues(alpha: 0.08)),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.ink,
        contentTextStyle: const TextStyle(color: Colors.white),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
