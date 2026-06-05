import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:media_chronicle/core/constants/app_constants.dart';
import 'package:media_chronicle/state/app_state.dart';
import 'package:media_chronicle/features/gallery/providers/gallery_provider.dart';
import 'package:media_chronicle/features/gallery/views/gallery_screen.dart';
import 'package:media_chronicle/features/stories/views/stories_screen.dart';
import 'package:media_chronicle/features/settings/providers/settings_provider.dart';
import 'package:media_chronicle/features/settings/views/settings_screen.dart';
import 'package:media_chronicle/features/explorer/views/explorer_screen.dart';
import 'package:media_chronicle/features/gallery/providers/yolo_face_provider.dart';
import 'package:media_chronicle/features/gallery/views/yolo_face_screen.dart';

/// The master responsive layout shell orchestrating sidebar navigation and routing.
///
/// **Design Decisions**:
/// 1. **Stateful Lifecycle Stability**: Converted to a `StatefulWidget` so that background Ollama pollers
///    and model auto-selection operations execute strictly once upon component instantiation.
/// 2. **Post-Frame Callback Injection**: Uses `WidgetsBinding.instance.addPostFrameCallback` inside `initState`
///    to cleanly access [BuildContext] and read providers without interrupting the initial paint pass.
/// 3. **Dynamic Model Auto-Selection**: Checks the pulled models from Ollama and maps active settings to
///    a matching variant automatically if the baseline model tag is missing (preventing VLM offline exceptions).
class DashboardShell extends ConsumerWidget {
  const DashboardShell({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Spawns the background Ollama status polling and auto-selects a model variant declaratively
    ref.listen<GalleryState>(galleryProvider, (previous, next) {
      if (next.isLlmAvailable && next.pulledModels.isNotEmpty) {
        final settings = ref.read(settingsProvider);
        final currentModel = settings.ollamaModel;
        if (!next.pulledModels.contains(currentModel)) {
          // 1. Search for direct suffix matches (e.g. "gemma4:latest" or case variations)
          final matchingVariant = next.pulledModels.firstWhere(
            (model) => model.toLowerCase().startsWith('${currentModel.toLowerCase()}:') ||
                       model.toLowerCase() == currentModel.toLowerCase(),
            orElse: () => '',
          );

          if (matchingVariant.isNotEmpty) {
            ref.read(settingsProvider.notifier).updateOllamaModel(matchingVariant);
            debugPrint('Auto-Selected installed vision model: $matchingVariant (Target model $currentModel was not found)');
          } else {
            // 3. Fall back to the first available model in the list
            final fallbackModel = next.pulledModels.first;
            ref.read(settingsProvider.notifier).updateOllamaModel(fallbackModel);
            debugPrint('Auto-Selected first available model: $fallbackModel (Target model $currentModel was not found)');
          }
        }
      }
    });

    final appState = ref.watch(appStateProvider);

    // Dynamic screen routing including Files Explorer
    Widget activeScreen;
    switch (appState.currentTab) {
      case AppTab.stories:
        activeScreen = const StoriesScreen();
        break;
      case AppTab.gallery:
        activeScreen = const GalleryScreen();
        break;
      case AppTab.explorer:
        activeScreen = const ExplorerScreen();
        break;
      case AppTab.settings:
        activeScreen = const SettingsScreen();
        break;
      case AppTab.yolo:
        activeScreen = const YoloFaceScreen();
        break;
    }

    return Scaffold(
      body: Stack(
        children: [
          // Deep visual background gradient
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: AppConstants.bgGradient,
              ),
            ),
          ),
          // Aesthetic glowing ambient shapes
          Positioned(
            top: -150,
            left: -100,
            child: Container(
              width: 400,
              height: 400,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppConstants.primary.withValues(alpha: 0.08),
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
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isLargeScreen = constraints.maxWidth > 800;

                return Row(
                  children: [
                    // Desktop Left Sidebar Navigation (Vue-like sidebar component)
                    if (isLargeScreen) const Sidebar(),

                    // Content Area & Top Header
                    Expanded(
                      child: Column(
                        children: [
                          DashboardHeader(showBurgerButton: !isLargeScreen),
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
                );
              },
            ),
          ),
        ],
      ),
      // Mobile Bottom Navigation Bar (for narrower displays)
      bottomNavigationBar: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth <= 800) {
            return const BottomNavBar();
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }
}

/// Sidebar component rendering logo, user profile, navigations and quotas.
class Sidebar extends ConsumerWidget {
  const Sidebar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appState = ref.watch(appStateProvider);
    final settings = ref.watch(settingsProvider);

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

          // Sidebar Navigation Items (Vue-like sub-components)
          SidebarNavItem(
            icon: Icons.edit_note_outlined,
            title: 'Memory Stories',
            tab: AppTab.stories,
            activeTab: appState.currentTab,
            onTap: () => ref.read(appStateProvider.notifier).changeTab(AppTab.stories),
          ),
          SidebarNavItem(
            icon: Icons.image_outlined,
            title: 'Media Gallery',
            tab: AppTab.gallery,
            activeTab: appState.currentTab,
            onTap: () => ref.read(appStateProvider.notifier).changeTab(AppTab.gallery),
          ),
          SidebarNavItem(
            icon: Icons.folder_open_outlined,
            title: 'Workspace Files',
            tab: AppTab.explorer,
            activeTab: appState.currentTab,
            onTap: () => ref.read(appStateProvider.notifier).changeTab(AppTab.explorer),
          ),
          SidebarNavItem(
            icon: Icons.settings_suggest_outlined,
            title: 'Control Center',
            tab: AppTab.settings,
            activeTab: appState.currentTab,
            onTap: () => ref.read(appStateProvider.notifier).changeTab(AppTab.settings),
          ),
          SidebarNavItem(
            icon: Icons.psychology_outlined,
            title: 'YOLO Face Hub',
            tab: AppTab.yolo,
            activeTab: appState.currentTab,
            onTap: () => ref.read(appStateProvider.notifier).changeTab(AppTab.yolo),
          ),

          const Spacer(),

          // Storage quota display
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
                    child: LinearProgressIndicator(
                      value: settings.storageUsedGB / settings.storageTotalGB,
                      minHeight: 4,
                      backgroundColor: Colors.white10,
                      valueColor: const AlwaysStoppedAnimation<Color>(AppConstants.accent),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Logged in user profile footer
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
}

/// Navigation lists for the left sidebar frame.
class SidebarNavItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final AppTab tab;
  final AppTab activeTab;
  final VoidCallback onTap;

  const SidebarNavItem({
    super.key,
    required this.icon,
    required this.title,
    required this.tab,
    required this.activeTab,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
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
}

/// Top workspace search header component.
class DashboardHeader extends ConsumerWidget {
  final bool showBurgerButton;

  const DashboardHeader({
    super.key,
    required this.showBurgerButton,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
          if (showBurgerButton) ...[
            IconButton(
              icon: const Icon(Icons.menu),
              onPressed: () {
                Scaffold.of(context).openDrawer();
              },
            ),
            const SizedBox(width: 8),
          ],
          
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

          const ModelStatusIndicators(),
          const SizedBox(width: AppConstants.paddingLarge),

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
              onChanged: (val) => ref.read(appStateProvider.notifier).updateSearchQuery(val),
              style: const TextStyle(fontSize: 13, color: AppConstants.textPrimary),
              decoration: const InputDecoration(
                hintText: 'Search stories, gallery items...',
                prefixIcon: Icon(Icons.search, size: 16, color: AppConstants.textMuted),
                contentPadding: EdgeInsets.symmetric(vertical: 8),
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
}

/// Modular VLM and YOLO health indicators.
class ModelStatusIndicators extends ConsumerWidget {
  const ModelStatusIndicators({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final galleryState = ref.watch(galleryProvider);
    final yoloState = ref.watch(yoloFaceProvider);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E35).withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppConstants.cardStroke),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          StatusDot(
            label: 'VLM',
            isOnline: galleryState.isLlmAvailable,
            icon: Icons.psychology_outlined,
            onlineColor: Colors.greenAccent,
            offlineColor: Colors.redAccent,
            tooltip: galleryState.isLlmAvailable 
                ? 'Local Vision LLM (gemma4) is ONLINE' 
                : 'Local Vision LLM (Ollama) is OFFLINE',
          ),
          
          Container(
            height: 14,
            width: 1,
            color: Colors.white24,
            margin: const EdgeInsets.symmetric(horizontal: 12),
          ),
          
          StatusDot(
            label: 'YOLO',
            isOnline: yoloState.isYoloAvailable,
            icon: Icons.face_unlock_outlined,
            onlineColor: Colors.greenAccent,
            offlineColor: Colors.redAccent,
            tooltip: yoloState.isYoloAvailable
                ? 'YOLO Face Detector is ONLINE'
                : 'YOLO Face Detector is OFFLINE',
          ),
        ],
      ),
    );
  }
}

/// Small visual dot displaying status colors and glowing highlights.
class StatusDot extends StatelessWidget {
  final String label;
  final bool isOnline;
  final IconData icon;
  final Color onlineColor;
  final Color offlineColor;
  final String tooltip;

  const StatusDot({
    super.key,
    required this.label,
    required this.isOnline,
    required this.icon,
    required this.onlineColor,
    required this.offlineColor,
    required this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    final color = isOnline ? onlineColor : offlineColor;
    return Tooltip(
      message: tooltip,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white70),
          ),
          const SizedBox(width: 6),
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color,
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.6),
                  blurRadius: 4,
                  spreadRadius: 1,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Mobile Bottom navigation bar.
class BottomNavBar extends ConsumerWidget {
  const BottomNavBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appState = ref.watch(appStateProvider);

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
        type: BottomNavigationBarType.fixed,
        onTap: (index) {
          ref.read(appStateProvider.notifier).changeTab(AppTab.values[index]);
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
            icon: Icon(Icons.folder_open_outlined),
            activeIcon: Icon(Icons.folder_open),
            label: 'Files',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings_suggest_outlined),
            activeIcon: Icon(Icons.settings_suggest),
            label: 'Settings',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.psychology_outlined),
            activeIcon: Icon(Icons.psychology),
            label: 'YOLO',
          ),
        ],
      ),
    );
  }
}
