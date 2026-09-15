import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

/// Material 3 theme translating the shared SecurIoT dark brand world
/// (7-token palette, Sora / Schibsted Grotesk / Martian Mono type system,
/// 8pt spacing) into native idioms for this surface.
class AppTheme {
  const AppTheme._();

  static ThemeData dark() {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.marca,
      brightness: Brightness.dark,
      surface: AppColors.noche,
      primary: AppColors.marca,
      // marca is a bright, saturated teal: white/texto text on it fails
      // WCAG contrast (computed ~1.9:1), so buttons use noche foreground.
      onPrimary: AppColors.noche,
      error: AppColors.alerta,
      onError: AppColors.noche,
    );

    final baseTextTheme = GoogleFonts.schibstedGroteskTextTheme(
      ThemeData(brightness: Brightness.dark).textTheme,
    );

    final textTheme = baseTextTheme.copyWith(
      // Display / heading roles: Sora 700.
      headlineSmall: GoogleFonts.sora(fontSize: 28, fontWeight: FontWeight.w700, height: 1.2, color: AppColors.texto),
      headlineMedium: GoogleFonts.sora(fontSize: 24, fontWeight: FontWeight.w700, height: 1.2, color: AppColors.texto),
      titleLarge: GoogleFonts.sora(fontSize: 20, fontWeight: FontWeight.w700, height: 1.2, color: AppColors.texto),
      titleMedium: GoogleFonts.sora(fontSize: 20, fontWeight: FontWeight.w700, height: 1.2, color: AppColors.texto),
      // Body / label roles: Schibsted Grotesk 400.
      bodyLarge: GoogleFonts.schibstedGrotesk(fontSize: 16, fontWeight: FontWeight.w400, height: 1.5, color: AppColors.texto),
      bodyMedium: GoogleFonts.schibstedGrotesk(fontSize: 16, fontWeight: FontWeight.w400, height: 1.5, color: AppColors.texto),
      bodySmall: GoogleFonts.schibstedGrotesk(fontSize: 14, fontWeight: FontWeight.w400, height: 1.5, color: AppColors.textoMute),
      labelLarge: GoogleFonts.schibstedGrotesk(fontSize: 14, fontWeight: FontWeight.w400, height: 1.5, color: AppColors.texto),
      labelMedium: GoogleFonts.schibstedGrotesk(fontSize: 14, fontWeight: FontWeight.w400, height: 1.5, color: AppColors.texto),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.noche,
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.noche,
        foregroundColor: AppColors.texto,
        elevation: 0,
        titleTextStyle: textTheme.titleLarge,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.surfaceCard,
        indicatorColor: AppColors.marca.withValues(alpha: 0.24),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return GoogleFonts.schibstedGrotesk(
            fontSize: 12,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
            color: selected ? AppColors.marca : AppColors.textoMute,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(color: selected ? AppColors.marca : AppColors.textoMute);
        }),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.marca,
          foregroundColor: AppColors.noche,
          disabledBackgroundColor: AppColors.marca.withValues(alpha: 0.4),
          disabledForegroundColor: AppColors.noche.withValues(alpha: 0.6),
          minimumSize: const Size.fromHeight(48),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle: GoogleFonts.schibstedGrotesk(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.texto,
          side: const BorderSide(color: AppColors.marca),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: AppColors.marca),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceCard,
        labelStyle: const TextStyle(color: AppColors.textoMute),
        hintStyle: const TextStyle(color: AppColors.textoMute),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: AppColors.texto.withValues(alpha: 0.16)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: AppColors.texto.withValues(alpha: 0.16)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.marca, width: 2),
        ),
      ),
      cardTheme: const CardThemeData(
        color: AppColors.surfaceCard,
        elevation: 1,
        margin: EdgeInsets.zero,
      ),
      iconTheme: const IconThemeData(color: AppColors.texto),
      dividerTheme: DividerThemeData(color: AppColors.texto.withValues(alpha: 0.08)),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.surfaceCard,
        contentTextStyle: const TextStyle(color: AppColors.texto),
        behavior: SnackBarBehavior.floating,
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(color: AppColors.marca),
    );
  }

  /// Martian Mono "data" role (zone status lines, timestamps, device IDs) —
  /// a scannable-data typeface distinct from the Sora/Schibsted Grotesk
  /// scale, per DESIGN.md. Applied at call sites that render raw readings
  /// rather than prose.
  static TextStyle dataText({Color color = AppColors.textoMute, FontWeight weight = FontWeight.w400}) {
    return GoogleFonts.martianMono(fontSize: 15, fontWeight: weight, height: 1.5, color: color);
  }
}
