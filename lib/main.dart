import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/constants/app_constants.dart';
import 'core/theme/app_theme.dart';
import 'features/dashboard/views/dashboard_shell.dart';
import 'features/gallery/providers/gallery_provider.dart';
import 'features/stories/providers/stories_provider.dart';
import 'features/settings/providers/settings_provider.dart';
import 'features/gallery/providers/yolo_face_provider.dart';
import 'core/utils/postgres_sync_service.dart';
import 'state/app_state.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppState()),
        ChangeNotifierProvider(create: (_) => GalleryProvider()),
        ChangeNotifierProvider(create: (_) => YoloFaceProvider()),
        ChangeNotifierProvider(create: (_) => PostgresSyncService()),
        ChangeNotifierProvider(create: (_) => StoriesProvider()),
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();

    return MaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: settings.darkMode ? AppTheme.darkTheme : AppTheme.darkTheme.copyWith(
        scaffoldBackgroundColor: const Color(0xFF0F0F1A),
      ),
      home: const DashboardShell(),
    );
  }
}
