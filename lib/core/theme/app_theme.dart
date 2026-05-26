import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/app_constants.dart';

class AppTheme {
  static ThemeData get darkTheme {
    final baseTheme = ThemeData.dark();
    
    return baseTheme.copyWith(
      scaffoldBackgroundColor: AppConstants.background,
      primaryColor: AppConstants.primary,
      cardColor: const Color(0xFF16162A),
      dividerColor: AppConstants.cardStroke,
      
      colorScheme: const ColorScheme.dark(
        primary: AppConstants.primary,
        secondary: AppConstants.secondary,
        surface: Color(0xFF121224),
        error: Colors.redAccent,
      ),

      textTheme: GoogleFonts.outfitTextTheme(baseTheme.textTheme).copyWith(
        displayLarge: GoogleFonts.outfit(
          color: AppConstants.textPrimary,
          fontSize: 32,
          fontWeight: FontWeight.bold,
          letterSpacing: -0.5,
        ),
        displayMedium: GoogleFonts.outfit(
          color: AppConstants.textPrimary,
          fontSize: 24,
          fontWeight: FontWeight.w700,
        ),
        bodyLarge: GoogleFonts.outfit(
          color: AppConstants.textPrimary,
          fontSize: 16,
          fontWeight: FontWeight.normal,
        ),
        bodyMedium: GoogleFonts.outfit(
          color: AppConstants.textSecondary,
          fontSize: 14,
          height: 1.5,
        ),
        labelLarge: GoogleFonts.outfit(
          color: AppConstants.textPrimary,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),

      iconTheme: const IconThemeData(
        color: AppConstants.textPrimary,
        size: 20,
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF1E1E38),
        hintStyle: GoogleFonts.outfit(color: AppConstants.textMuted, fontSize: 14),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppConstants.cardStroke),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppConstants.cardStroke),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppConstants.primary, width: 1.5),
        ),
      ),

      scrollbarTheme: ScrollbarThemeData(
        thumbColor: WidgetStateProperty.all(AppConstants.primary.withValues(alpha: 0.3)),
        radius: const Radius.circular(8),
      ),
    );
  }
}
