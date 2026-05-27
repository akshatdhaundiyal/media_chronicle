import 'package:flutter/material.dart';

class AppConstants {
  static const String appName = 'Media Chronicle';

  // Core Harmonious Palette (Dark Glassmorphism Focus)
  static const Color background = Color(0xFF0F0F1A);
  static const Color cardBg = Color(0x15FFFFFF);
  static const Color cardStroke = Color(0x1BFFFFFF);
  
  static const Color primary = Color(0xFF8B5CF6); // Vibrant Indigo / Violet
  static const Color primaryGlow = Color(0x408B5CF6);
  static const Color secondary = Color(0xFFEC4899); // Electric Pink / Rose
  static const Color accent = Color(0xFF06B6D4); // Cyan / Ocean Splash

  // Unified visual style colors
  static const Color dialogBg = Color(0xFF1E1E38);
  static const Color inputBg = Color(0xFF1E1E35);
  static const Color cardSolidBg = Color(0xFF16162A);
  static const Color terminalBg = Color(0xFF070710);

  static const Color textPrimary = Color(0xFFF3F4F6);
  static const Color textSecondary = Color(0xFF9CA3AF);
  static const Color textMuted = Color(0xFF6B7280);

  // Gradient Overlays
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, secondary],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient glassGradient = LinearGradient(
    colors: [
      Color(0x1CFFFFFF),
      Color(0x08FFFFFF),
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient bgGradient = LinearGradient(
    colors: [
      Color(0xFF0B0B14),
      Color(0xFF14132B),
      Color(0xFF0F0B1E),
    ],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  // Layout Spacers
  static const double borderRadius = 16.0;
  static const double paddingSmall = 8.0;
  static const double paddingMedium = 16.0;
  static const double paddingLarge = 24.0;
  static const double paddingExtraLarge = 32.0;

  // Mock initial stories
  static const List<Map<String, String>> initialMockStories = [];

  // Mock initial gallery assets
  static const List<Map<String, dynamic>> initialMockGallery = [];
}
