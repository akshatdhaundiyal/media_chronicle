import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/constants/app_constants.dart';
import 'core/theme/app_theme.dart';
import 'features/gallery/providers/gallery_provider.dart';
import 'features/gallery/views/gallery_screen.dart';
import 'features/stories/providers/stories_provider.dart';
import 'features/stories/views/stories_screen.dart';
import 'features/settings/providers/settings_provider.dart';
import 'features/settings/views/settings_screen.dart';
import 'state/app_state.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppState()),
        ChangeNotifierProvider(create: (_) => GalleryProvider()),
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
        // Fallback or customizable adjustments for light/dark
        scaffoldBackgroundColor: const Color(0xFF0F0F1A),
      ),
      home: const DashboardShell(),
    );
  }
}

class DashboardShell extends StatelessWidget {
  const DashboardShell({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final settings = context.watch<SettingsProvider>();

    // Dynamic screen routing
    Widget activeScreen;
    switch (appState.currentTab) {
      case AppTab.stories:
        activeScreen = const StoriesScreen();
        break;
      case AppTab.gallery:
        activeScreen = const GalleryScreen();
        break;
      case AppTab.settings:
        activeScreen = const SettingsScreen();
        break;
    }

    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isLargeScreen = constraints.maxWidth > 800;

          return Stack(
            children: [
              // Deep visual background gradient
              Positioned.fill(
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: AppConstants.bgGradient,
                  ),
                ),
              ),
              // Aesthetic glowing ambient shapes (neon overlays)
              Positioned(
                top: -150,
                left: -100,
                child: Container(
                  width: 400,
                  height: 400,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppConstants.primary.withValues(alpha: 0.08),
                    // Simulated glow blur
                  ),
                ),
              ),
              Positioned(
                bottom: -150,
                right: -100,
                child: Container(
                  width: 500,
                  height: 500,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppConstants.secondary.withValues(alpha: 0.05),
                  ),
                ),
              ),

              // Main Layout Shell
              SafeArea(
                child: Row(
                  children: [
                    // Desktop Left Navigation Sidebar
                    if (isLargeScreen) _buildSidebar(context, appState, settings),

                    // Content Area & Top Header
                    Expanded(
                      child: Column(
                        children: [
                          _buildHeader(context, appState, settings, !isLargeScreen),
                          Expanded(
                            child: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 300),
                              child: activeScreen,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
      // Mobile Bottom Navigation Bar (for narrower displays)
      bottomNavigationBar: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth <= 800) {
            return _buildBottomNavBar(context, appState);
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildSidebar(BuildContext context, AppState appState, SettingsProvider settings) {
    return Container(
      width: 280,
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.2),
        border: const Border(
          right: BorderSide(color: AppConstants.cardStroke, width: 1),
        ),
      ),
      child: Column(
        children: [
          // Logo & Branding
          Padding(
            padding: const EdgeInsets.all(AppConstants.paddingLarge),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: AppConstants.primaryGradient,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.auto_stories,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    AppConstants.appName,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.5,
                      color: AppConstants.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(color: AppConstants.cardStroke),
          const SizedBox(height: 16),

          // Sidebar Navigation Items
          _buildSidebarNavItem(
            context: context,
            icon: Icons.edit_note_outlined,
            title: 'Memory Stories',
            tab: AppTab.stories,
            activeTab: appState.currentTab,
            onTap: () => appState.changeTab(AppTab.stories),
          ),
          _buildSidebarNavItem(
            context: context,
            icon: Icons.image_outlined,
            title: 'Media Gallery',
            tab: AppTab.gallery,
            activeTab: appState.currentTab,
            onTap: () => appState.changeTab(AppTab.gallery),
          ),
          _buildSidebarNavItem(
            context: context,
            icon: Icons.settings_suggest_outlined,
            title: 'Control Center',
            tab: AppTab.settings,
            activeTab: appState.currentTab,
            onTap: () => appState.changeTab(AppTab.settings),
          ),

          const Spacer(),

          // Storage quota quick display in sidebar
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppConstants.paddingMedium,
              vertical: AppConstants.paddingSmall,
            ),
            child: Container(
              padding: const EdgeInsets.all(AppConstants.paddingMedium),
              decoration: BoxDecoration(
                color: AppConstants.cardBg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppConstants.cardStroke),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Expanded(
                        child: Text(
                          'Local Storage',
                          style: TextStyle(fontSize: 11, color: AppConstants.textSecondary),
                        ),
                      ),
                      Text(
                        settings.storageLimit.split(' / ').first,
                        style: const TextStyle(fontSize: 11, color: AppConstants.accent, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: const LinearProgressIndicator(
                      value: 2.4 / 15.0,
                      minHeight: 4,
                      backgroundColor: Colors.white10,
                      valueColor: AlwaysStoppedAnimation<Color>(AppConstants.accent),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Logged in host user profile footer
          Container(
            padding: const EdgeInsets.all(AppConstants.paddingLarge),
            color: Colors.black12,
            child: Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundImage: NetworkImage(settings.profileImage),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        settings.username,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: AppConstants.textPrimary,
                        ),
                      ),
                      const Text(
                        'Cloud Sync Active',
                        style: TextStyle(fontSize: 10, color: Colors.greenAccent),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.logout, size: 16, color: AppConstants.textMuted),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Profile lock active. Sign out simulated!')),
                    );
                  },
                )
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebarNavItem({
    required BuildContext context,
    required IconData icon,
    required String title,
    required AppTab tab,
    required AppTab activeTab,
    required VoidCallback onTap,
  }) {
    final isActive = tab == activeTab;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Container(
        decoration: BoxDecoration(
          color: isActive ? AppConstants.primary.withValues(alpha: 0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isActive ? AppConstants.primary.withValues(alpha: 0.25) : Colors.transparent,
          ),
        ),
        child: ListTile(
          onTap: onTap,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          leading: Icon(
            icon,
            color: isActive ? AppConstants.primary : AppConstants.textSecondary,
          ),
          title: Text(
            title,
            style: TextStyle(
              color: isActive ? AppConstants.textPrimary : AppConstants.textSecondary,
              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
              fontSize: 14,
            ),
          ),
          trailing: isActive
              ? Container(
                  width: 4,
                  height: 16,
                  decoration: BoxDecoration(
                    color: AppConstants.primary,
                    borderRadius: BorderRadius.circular(2),
                  ),
                )
              : null,
        ),
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    AppState appState,
    SettingsProvider settings,
    bool showBurgerButton,
  ) {
    return Container(
      height: 70,
      padding: const EdgeInsets.symmetric(horizontal: AppConstants.paddingLarge),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.1),
        border: const Border(
          bottom: BorderSide(color: AppConstants.cardStroke, width: 1),
        ),
      ),
      child: Row(
        children: [
          // Drawer burger trigger on mobile
          if (showBurgerButton) ...[
            IconButton(
              icon: const Icon(Icons.menu),
              onPressed: () {
                Scaffold.of(context).openDrawer();
              },
            ),
            const SizedBox(width: 8),
          ],
          
          // Header title context
          if (!showBurgerButton)
            const Text(
              'Chronicle Workspace',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppConstants.textSecondary),
            )
          else
            const Text(
              AppConstants.appName,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppConstants.textPrimary),
            ),
            
          const Spacer(),

          // Search Field
          Container(
            width: 300,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E35),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppConstants.cardStroke),
            ),
            child: TextField(
              onChanged: (val) => appState.updateSearchQuery(val),
              style: const TextStyle(fontSize: 13, color: AppConstants.textPrimary),
              decoration: InputDecoration(
                hintText: 'Search stories, gallery items...',
                prefixIcon: const Icon(Icons.search, size: 16, color: AppConstants.textMuted),
                contentPadding: const EdgeInsets.symmetric(vertical: 8),
                fillColor: Colors.transparent,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavBar(BuildContext context, AppState appState) {
    return Container(
      decoration: const BoxDecoration(
        border: Border(
          top: BorderSide(color: AppConstants.cardStroke, width: 1),
        ),
      ),
      child: BottomNavigationBar(
        currentIndex: appState.currentTab.index,
        backgroundColor: const Color(0xFF0F0F1E),
        selectedItemColor: AppConstants.primary,
        unselectedItemColor: AppConstants.textSecondary,
        showUnselectedLabels: false,
        onTap: (index) {
          appState.changeTab(AppTab.values[index]);
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.edit_note_outlined),
            activeIcon: Icon(Icons.edit_note),
            label: 'Stories',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.image_outlined),
            activeIcon: Icon(Icons.image),
            label: 'Gallery',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings_suggest_outlined),
            activeIcon: Icon(Icons.settings_suggest),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
