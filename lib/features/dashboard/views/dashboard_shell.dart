import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_constants.dart';
import '../../../state/app_state.dart';
import '../../gallery/providers/gallery_provider.dart';
import '../../gallery/views/gallery_screen.dart';
import '../../stories/views/stories_screen.dart';
import '../../settings/providers/settings_provider.dart';
import '../../settings/views/settings_screen.dart';
import '../../explorer/views/explorer_screen.dart';
import '../../gallery/providers/yolo_face_provider.dart';
import '../../gallery/views/yolo_face_screen.dart';

/// The master responsive layout shell orchestrating sidebar navigation and routing.
///
/// **Design Decisions**:
/// 1. **Stateful Lifecycle Stability**: Converted to a `StatefulWidget` so that background Ollama pollers
///    and model auto-selection operations execute strictly once upon component instantiation.
/// 2. **Post-Frame Callback Injection**: Uses `WidgetsBinding.instance.addPostFrameCallback` inside `initState`
///    to cleanly access [BuildContext] and read providers without interrupting the initial paint pass.
/// 3. **Dynamic Model Auto-Selection**: Checks the pulled models from Ollama and maps active settings to
///    a matching variant automatically if the baseline model tag is missing (preventing VLM offline exceptions).
class DashboardShell extends StatefulWidget {
  const DashboardShell({super.key});

  @override
  State<DashboardShell> createState() => _DashboardShellState();
}

class _DashboardShellState extends State<DashboardShell> {
  GalleryProvider? _galleryProv;

  @override
  void initState() {
    super.initState();
    
    // Core Initialization: Executes safely AFTER the first layout paint pass.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      
      // Access provider references safely using context.read.
      _galleryProv = context.read<GalleryProvider>();
      final settings = context.read<SettingsProvider>();
      
      // Spawns the background Ollama status polling timers.
      _galleryProv?.startLlmPoller(settings.ollamaUrl);

      // Register a listener so that as soon as the background poller returns
      // the list of pulled models, we dynamically select a valid available model!
      _galleryProv?.addListener(_autoSelectModelListener);
    });
  }

  @override
  void dispose() {
    // Unregister the listener safely using the stored provider reference
    _galleryProv?.removeListener(_autoSelectModelListener);
    super.dispose();
  }

  /// Reactive listener that checks VLM availability and dynamically maps selected
  /// models to direct suffix matches or installed vision/first available fallbacks.
  void _autoSelectModelListener() {
    if (!mounted) return;

    final galleryProv = context.read<GalleryProvider>();
    final settings = context.read<SettingsProvider>();

    if (galleryProv.isLlmAvailable && galleryProv.pulledModels.isNotEmpty) {
      final currentModel = settings.ollamaModel;
      if (!galleryProv.pulledModels.contains(currentModel)) {
        // 1. Search for direct suffix matches (e.g. "gemma4:latest" or case variations)
        final matchingVariant = galleryProv.pulledModels.firstWhere(
          (model) => model.toLowerCase().startsWith('${currentModel.toLowerCase()}:') ||
                     model.toLowerCase() == currentModel.toLowerCase(),
          orElse: () => '',
        );

        if (matchingVariant.isNotEmpty) {
          settings.updateOllamaModel(matchingVariant);
          debugPrint('Auto-Selected VLM model variant: $matchingVariant (Target model $currentModel resolved successfully)');
        } else {
          // 2. Fall back to a known vision/multimodal model if present in the pulled list
          final visionModel = galleryProv.pulledModels.firstWhere(
            (model) => model.toLowerCase().contains('gemma') ||
                       model.toLowerCase().contains('llava') ||
                       model.toLowerCase().contains('pali') ||
                       model.toLowerCase().contains('vision'),
            orElse: () => '',
          );

          if (visionModel.isNotEmpty) {
            settings.updateOllamaModel(visionModel);
            debugPrint('Auto-Selected installed vision model: $visionModel (Target model $currentModel was not found)');
          } else {
            // 3. Fall back to the first available model in the list
            final fallbackModel = galleryProv.pulledModels.first;
            settings.updateOllamaModel(fallbackModel);
            debugPrint('Auto-Selected first available model: $fallbackModel (Target model $currentModel was not found)');
          }
        }
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();

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
class Sidebar extends StatelessWidget {
  const Sidebar({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final settings = context.watch<SettingsProvider>();

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
            onTap: () => appState.changeTab(AppTab.stories),
          ),
          SidebarNavItem(
            icon: Icons.image_outlined,
            title: 'Media Gallery',
            tab: AppTab.gallery,
            activeTab: appState.currentTab,
            onTap: () => appState.changeTab(AppTab.gallery),
          ),
          SidebarNavItem(
            icon: Icons.folder_open_outlined,
            title: 'Workspace Files',
            tab: AppTab.explorer,
            activeTab: appState.currentTab,
            onTap: () => appState.changeTab(AppTab.explorer),
          ),
          SidebarNavItem(
            icon: Icons.settings_suggest_outlined,
            title: 'Control Center',
            tab: AppTab.settings,
            activeTab: appState.currentTab,
            onTap: () => appState.changeTab(AppTab.settings),
          ),
          SidebarNavItem(
            icon: Icons.psychology_outlined,
            title: 'YOLO Face Hub',
            tab: AppTab.yolo,
            activeTab: appState.currentTab,
            onTap: () => appState.changeTab(AppTab.yolo),
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
class DashboardHeader extends StatelessWidget {
  final bool showBurgerButton;

  const DashboardHeader({
    super.key,
    required this.showBurgerButton,
  });

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();

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
              onChanged: (val) => appState.updateSearchQuery(val),
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
class ModelStatusIndicators extends StatelessWidget {
  const ModelStatusIndicators({super.key});

  @override
  Widget build(BuildContext context) {
    final galleryProv = context.watch<GalleryProvider>();
    final yoloProv = context.watch<YoloFaceProvider>();

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
            isOnline: galleryProv.isLlmAvailable,
            icon: Icons.psychology_outlined,
            onlineColor: Colors.greenAccent,
            offlineColor: Colors.redAccent,
            tooltip: galleryProv.isLlmAvailable 
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
            isOnline: yoloProv.isYoloAvailable,
            icon: Icons.face_unlock_outlined,
            onlineColor: Colors.greenAccent,
            offlineColor: Colors.redAccent,
            tooltip: yoloProv.isYoloAvailable
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
class BottomNavBar extends StatelessWidget {
  const BottomNavBar({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();

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
