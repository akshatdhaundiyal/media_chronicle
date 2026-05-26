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
  static const List<Map<String, String>> initialMockStories = [
    {
      'id': '1',
      'title': 'Weekend Retreat in the Woods',
      'description': 'A visual journal of our summer cabin getaway. Tall pines, morning fog, and fireside talks under starry skies.',
      'date': 'May 12, 2026',
      'coverUrl': 'https://images.unsplash.com/photo-1510312305653-8ed496efae75?q=80&w=600&auto=format&fit=crop',
    },
    {
      'id': '2',
      'title': 'Neon Streets of Tokyo',
      'description': 'Exploring Shibuya and Akihabara at midnight. Rain reflection, giant billboards, and cozy ramen alleyways.',
      'date': 'April 28, 2026',
      'coverUrl': 'https://images.unsplash.com/photo-1503899036084-c55cdd92da26?q=80&w=600&auto=format&fit=crop',
    },
    {
      'id': '3',
      'title': 'Coastal Cliffs & Ocean Spray',
      'description': 'Driving along Highway 1. Dramatic drops, violent waves hitting black rocks, and endless deep blue views.',
      'date': 'March 15, 2026',
      'coverUrl': 'https://images.unsplash.com/photo-1471922694854-ff1b63b20054?q=80&w=600&auto=format&fit=crop',
    },
  ];

  // Mock initial gallery assets
  static const List<Map<String, dynamic>> initialMockGallery = [
    {
      'id': 'g1',
      'url': 'https://images.unsplash.com/photo-1470071459604-3b5ec3a7fe05?q=80&w=600&auto=format&fit=crop',
      'title': 'Misty Alpine Meadows',
      'type': 'image',
      'date': 'May 24, 2026',
    },
    {
      'id': 'g2',
      'url': 'https://images.unsplash.com/photo-1447752875215-b2761acb3c5d?q=80&w=600&auto=format&fit=crop',
      'title': 'Golden Autumn Canopy',
      'type': 'image',
      'date': 'May 20, 2026',
    },
    {
      'id': 'g3',
      'url': 'https://images.unsplash.com/photo-1472214222555-d404758b1c42?q=80&w=600&auto=format&fit=crop',
      'title': 'Canyon Horizon Warmth',
      'type': 'image',
      'date': 'May 15, 2026',
    },
    {
      'id': 'g4',
      'url': 'https://images.unsplash.com/photo-1500485035595-cbe6f645feb1?q=80&w=600&auto=format&fit=crop',
      'title': 'Glacial Rivers from Above',
      'type': 'image',
      'date': 'May 10, 2026',
    },
    {
      'id': 'g5',
      'url': 'https://images.unsplash.com/photo-1475924156734-496f6cac6ec1?q=80&w=600&auto=format&fit=crop',
      'title': 'Sunset Tide Pools',
      'type': 'image',
      'date': 'May 05, 2026',
    },
    {
      'id': 'g6',
      'url': 'https://images.unsplash.com/photo-1469474968028-56623f02e42e?q=80&w=600&auto=format&fit=crop',
      'title': 'Valley Trails',
      'type': 'image',
      'date': 'May 01, 2026',
    },
  ];
}
