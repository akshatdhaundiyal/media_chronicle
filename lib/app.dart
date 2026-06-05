import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:media_chronicle/core/constants/app_constants.dart';
import 'package:media_chronicle/core/theme/app_theme.dart';
import 'package:media_chronicle/features/dashboard/views/dashboard_shell.dart';
import 'package:media_chronicle/features/settings/providers/settings_provider.dart';

class App extends ConsumerWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);

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
