import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_constants.dart';
import '../../../state/app_state.dart';
import '../../settings/providers/settings_provider.dart';
import '../providers/gallery_provider.dart';
import '../providers/yolo_face_provider.dart';
import 'widgets/gallery_toolbar.dart';
import 'widgets/gallery_quick_panel.dart';
import 'widgets/gallery_category_filters.dart';
import 'widgets/gallery_tag_cloud.dart';
import 'widgets/gallery_card.dart';
import 'widgets/media_detail_dialog.dart';
import 'widgets/media_upload_dialog.dart';

/// A coordination screen for the Media Chronicle archive gallery.
///
/// This widget functions as the main shell orchestrating:
/// 1. Dynamic category filtering (via [AppState.activeGroupFilter]).
/// 2. Search integration (matching name, place, face tags, or dates).
/// 3. Multi-selection batch operations (move, copy, delete, VLM reprocessing).
/// 4. Layout-responsive grid rendering adapting dynamically between mobile and desktop configurations.
class GalleryScreen extends StatefulWidget {
  const GalleryScreen({super.key});

  @override
  State<GalleryScreen> createState() => _GalleryScreenState();
}

class _GalleryScreenState extends State<GalleryScreen> {
  /// Flag tracking whether the user is in batch selection mode.
  bool _isSelectionMode = false;

  /// Holds the unique IDs of all currently selected media elements.
  final Set<String> _selectedItemIds = {};

  @override
  Widget build(BuildContext context) {
    // Watch reactive providers to trigger a UI refresh upon data changes.
    final galleryProv = context.watch<GalleryProvider>();
    final appState = context.watch<AppState>();
    final settings = context.watch<SettingsProvider>();
    
    // Normalize the global search query to case-insensitive.
    final query = appState.searchQuery.toLowerCase();

    // Filter items dynamically based on global search, category, folder/album, AND active tag selections.
    // This consolidated filter path runs in O(n) time on every rebuild, guaranteeing clean visual states.
    final filteredItems = galleryProv.items.where((item) {
      // 1. Check search queries matching title, place tags, or face names.
      final matchesSearch = item.title.toLowerCase().contains(query) ||
          (item.place?.toLowerCase().contains(query) ?? false) ||
          (item.face?.toLowerCase().contains(query) ?? false);
          
      // 2. Check active category tabs (e.g. Nature, Family, Documents).
      final matchesCategory = appState.activeGroupFilter == 'All' || item.group == appState.activeGroupFilter;
      
      // 3. Check folder scope if a specific folder (album) is active in the sidebar panel.
      final matchesAlbum = appState.activeAlbumId == null || 
          galleryProv.albums.firstWhere((a) => a.id == appState.activeAlbumId).itemIds.contains(item.id);
          
      // 4. Check secondary tag cloud selections.
      final matchesTag = appState.activeTagFilter == null ||
          (item.face?.contains(appState.activeTagFilter!) ?? false) ||
          (item.place?.contains(appState.activeTagFilter!) ?? false) ||
          (item.dateClue?.contains(appState.activeTagFilter!) ?? false);

      return matchesSearch && matchesCategory && matchesAlbum && matchesTag;
    }).toList();

    return Padding(
      padding: const EdgeInsets.all(AppConstants.paddingLarge),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Render the toolbar which manages actions (Sync, Upload, batch triggers).
          GalleryToolbar(
            isSelectionMode: _isSelectionMode,
            selectedItemIds: _selectedItemIds,
            filteredItems: filteredItems,
            onSelectionModeCancel: () {
              // Gracefully clear all active selections.
              setState(() {
                _isSelectionMode = false;
                _selectedItemIds.clear();
              });
            },
            onSelectAll: () {
              // Toggle between selecting all matching elements and clearing selections.
              setState(() {
                if (_selectedItemIds.length == filteredItems.length) {
                  _selectedItemIds.clear();
                } else {
                  _selectedItemIds.addAll(filteredItems.map((item) => item.id));
                }
              });
            },
            onActionSelected: (action) {
              // Delegate selection command to the processor handler.
              _handleSelectionAction(context, action, galleryProv, appState, settings);
            },
            onUploadPressed: () => MediaUploadDialog.show(context),
            onSelectionModeStart: () {
              setState(() {
                _isSelectionMode = true;
              });
            },
          ),
          const SizedBox(height: AppConstants.paddingLarge),

          const GalleryQuickPanel(),
          const SizedBox(height: AppConstants.paddingMedium),

          const GalleryCategoryFilters(),
          const SizedBox(height: AppConstants.paddingSmall),

          const GalleryTagCloud(),
          const SizedBox(height: AppConstants.paddingMedium),

          // Render the Gallery Grid View responsive layout.
          // If no items match our active combination of filters, show a clean glassmorphic empty state.
          Expanded(
            child: filteredItems.isEmpty
                ? _buildEmptyState(context, appState)
                : LayoutBuilder(
                    builder: (context, constraints) {
                      // Dynamically compute grid column counts based on screen width.
                      // Matches standard desktop, tablet, and mobile breakpoints:
                      // - Width > 1200: 4 columns (Desktop Dashboard)
                      // - Width > 800:  3 columns (Tablet Landscape)
                      // - Default:       2 columns (Mobile/Compact panel)
                      int crossAxisCount = 2;
                      if (constraints.maxWidth > 1200) {
                        crossAxisCount = 4;
                      } else if (constraints.maxWidth > 800) {
                        crossAxisCount = 3;
                      }
                      
                      return GridView.builder(
                        physics: const BouncingScrollPhysics(),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: crossAxisCount,
                          crossAxisSpacing: AppConstants.paddingMedium,
                          mainAxisSpacing: AppConstants.paddingMedium,
                          childAspectRatio: 0.72, // Vertical premium aspect ratio to fit image + labels
                        ),
                        itemCount: filteredItems.length,
                        itemBuilder: (context, index) {
                          final item = filteredItems[index];
                          
                          // GalleryCard is highly optimized; it isolates image display and YOLO status badges.
                          return GalleryCard(
                            item: item,
                            isSelected: _selectedItemIds.contains(item.id),
                            isSelectionMode: _isSelectionMode,
                            onTap: _isSelectionMode
                                ? () {
                                    // In selection mode, tapping toggles the item's selection status.
                                    setState(() {
                                      if (_selectedItemIds.contains(item.id)) {
                                        _selectedItemIds.remove(item.id);
                                      } else {
                                        _selectedItemIds.add(item.id);
                                      }
                                    });
                                  }
                                : (item.isAnalyzing 
                                    ? null // Block interaction while VLM is actively processing.
                                    : () => MediaDetailDialog.show(context, item)), // Open premium Vision details
                            onLongPress: () {
                              // Long-pressing triggers selection mode and selects the long-pressed card.
                              setState(() {
                                _isSelectionMode = true;
                                _selectedItemIds.add(item.id);
                              });
                            },
                            onAddToAlbum: () => _showAddToAlbumDialog(context, galleryProv, item.id),
                            onDelete: () {
                              // Perform standard item removal.
                              context.read<GalleryProvider>().deleteMediaItem(item.id);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Media item catalog removed'),
                                  duration: Duration(seconds: 2),
                                ),
                              );
                            },
                          );
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  void _handleSelectionAction(
    BuildContext context,
    String action,
    GalleryProvider galleryProv,
    AppState appState,
    SettingsProvider settings,
  ) {
    if (_selectedItemIds.isEmpty) return;

    if (action == 'delete') {
      showDialog(
        context: context,
        builder: (dialogCtx) => AlertDialog(
          backgroundColor: AppConstants.dialogBg,
          title: const Text('Delete Selected Items?'),
          content: Text('Are you sure you want to permanently delete these ${_selectedItemIds.length} catalogued items? This will also remove them from all database sync tables.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: const Text('Cancel', style: TextStyle(color: AppConstants.textSecondary)),
            ),
            ElevatedButton(
              onPressed: () {
                for (final id in _selectedItemIds) {
                  galleryProv.deleteMediaItem(id);
                }
                setState(() {
                  _isSelectionMode = false;
                  _selectedItemIds.clear();
                });
                Navigator.pop(dialogCtx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Selected items deleted successfully!')),
                );
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
              child: const Text('Delete', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
    } else if (action == 'rerun') {
      setState(() {
        _isSelectionMode = false;
      });
      int reRunCount = 0;
      for (final id in _selectedItemIds) {
        final item = galleryProv.items.firstWhere((i) => i.id == id);
        
        final faces = context.read<YoloFaceProvider>().getFacesForMediaItem(item.id);
        final faceNames = faces
            .map((f) => f.name ?? (f.isIdentified ? 'John' : 'an unidentified person'))
            .join(', ');

        galleryProv.reRunVlm(
          item,
          ollamaUrl: settings.ollamaUrl,
          ollamaModel: settings.ollamaModel,
          preIdentifiedFaces: faceNames.isNotEmpty ? faceNames : null,
          onComplete: (completedItem) {
            // Re-run completed
          },
          onError: (err) {
            debugPrint('Re-run error for item ${item.title}: $err');
          },
        );
        reRunCount++;
      }
      _selectedItemIds.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Queued $reRunCount items sequentially for local VLM re-analysis!')),
      );
    } else if (action == 'move' || action == 'copy') {
      if (galleryProv.albums.isEmpty) {
        showDialog(
          context: context,
          builder: (dialogCtx) => AlertDialog(
            backgroundColor: AppConstants.dialogBg,
            title: const Text('No Folders Found'),
            content: const Text('Please create a memory folder first using the "Create Folder" button in the gallery panel.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogCtx),
                child: const Text('OK', style: TextStyle(color: AppConstants.accent)),
              ),
            ],
          ),
        );
        return;
      }

      showDialog(
        context: context,
        builder: (dialogCtx) => AlertDialog(
          backgroundColor: AppConstants.dialogBg,
          title: Text(action == 'move' ? 'Move Items to Folder' : 'Copy Items to Folder'),
          content: SizedBox(
            width: 300,
            height: 200,
            child: ListView.builder(
              itemCount: galleryProv.albums.length,
              itemBuilder: (c, idx) {
                final album = galleryProv.albums[idx];
                return ListTile(
                  leading: const Icon(Icons.folder_shared, color: AppConstants.secondary),
                  title: Text(album.name, style: const TextStyle(color: Colors.white)),
                  subtitle: Text('${album.itemIds.length} items', style: const TextStyle(color: AppConstants.textMuted, fontSize: 11)),
                  onTap: () {
                    for (final itemId in _selectedItemIds) {
                      galleryProv.addItemToAlbum(album.id, itemId);

                      if (action == 'move' && appState.activeAlbumId != null && appState.activeAlbumId != album.id) {
                        galleryProv.removeItemFromAlbum(appState.activeAlbumId!, itemId);
                      }
                    }
                    setState(() {
                      _isSelectionMode = false;
                      _selectedItemIds.clear();
                    });
                    Navigator.pop(dialogCtx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Selected items successfully ${action == "move" ? "moved" : "copied"} to folder "${album.name}"!')),
                    );
                  },
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: const Text('Cancel', style: TextStyle(color: AppConstants.textSecondary)),
            ),
          ],
        ),
      );
    }
  }

  void _showAddToAlbumDialog(BuildContext context, GalleryProvider galleryProv, String itemId) {
    if (galleryProv.albums.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No albums created yet! Create an album first using "Create Folder".')),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: AppConstants.dialogBg,
        title: const Text('Add Item to Memory Folder'),
        content: SizedBox(
          width: 300,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: galleryProv.albums.length,
            itemBuilder: (context, index) {
              final album = galleryProv.albums[index];
              final containsItem = album.itemIds.contains(itemId);

              return ListTile(
                leading: Icon(
                  Icons.folder,
                  color: containsItem ? AppConstants.secondary : AppConstants.textMuted,
                ),
                title: Text(album.name, style: const TextStyle(fontSize: 13, color: AppConstants.textPrimary)),
                trailing: containsItem
                    ? const Icon(Icons.check_circle, color: Colors.greenAccent, size: 18)
                    : const Icon(Icons.add, size: 18, color: AppConstants.textMuted),
                onTap: () {
                  if (containsItem) {
                    galleryProv.removeItemFromAlbum(album.id, itemId);
                    ScaffoldMessenger.of(dialogCtx).showSnackBar(
                      SnackBar(content: Text('Removed item from album "${album.name}".')),
                    );
                  } else {
                    galleryProv.addItemToAlbum(album.id, itemId);
                    ScaffoldMessenger.of(dialogCtx).showSnackBar(
                      SnackBar(content: Text('Added item to album "${album.name}".')),
                    );
                  }
                  Navigator.pop(dialogCtx);
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Close', style: TextStyle(color: AppConstants.textSecondary)),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, AppState appState) {
    return Center(
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          decoration: BoxDecoration(
            color: AppConstants.cardBg,
            borderRadius: BorderRadius.circular(AppConstants.borderRadius),
            border: Border.all(color: AppConstants.cardStroke),
          ),
          constraints: const BoxConstraints(maxWidth: 400),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.image_not_supported_outlined,
                size: 48,
                color: AppConstants.textMuted.withValues(alpha: 0.5),
              ),
              const SizedBox(height: 12),
              Text(
                'No Media Found',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              Text(
                'No items currently match the active filters, albums, or tag selections.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 13),
              ),
              const SizedBox(height: 16),
              TextButton.icon(
                onPressed: () => appState.clearAllFilters(),
                icon: const Icon(Icons.refresh, size: 16),
                label: const Text('Reset All Filters', style: TextStyle(fontSize: 12)),
                style: TextButton.styleFrom(
                  foregroundColor: AppConstants.accent,
                  minimumSize: Size.zero,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
