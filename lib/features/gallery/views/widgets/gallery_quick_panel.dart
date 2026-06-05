import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:media_chronicle/core/constants/app_constants.dart';
import 'package:media_chronicle/state/app_state.dart';
import 'package:media_chronicle/features/gallery/providers/gallery_provider.dart';
import 'package:media_chronicle/features/settings/providers/settings_provider.dart';
import 'package:media_chronicle/features/gallery/models/media_item.dart';

class GalleryQuickPanel extends ConsumerWidget {
  const GalleryQuickPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final galleryState = ref.watch(galleryProvider);
    final settings = ref.watch(settingsProvider);
    final appState = ref.watch(appStateProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildBatchProgressHUD(context, galleryState.items),
        _buildCombinedQuickPanel(context, ref, settings, galleryState, appState),
      ],
    );
  }

  Widget _buildBatchProgressHUD(BuildContext context, List<MediaItem> items) {
    final analyzingItems = items.where((i) => i.isAnalyzing).toList();
    final analyzingCount = analyzingItems.length;
    if (analyzingCount == 0) return const SizedBox.shrink();

    final processedCount = items.where((i) => !i.isAnalyzing && (i.face != null || i.place != null)).toList().length;
    
    final double percent = (processedCount + analyzingCount) > 0 
        ? processedCount / (processedCount + analyzingCount)
        : 0.0;

    return Container(
      margin: const EdgeInsets.only(bottom: AppConstants.paddingMedium),
      padding: const EdgeInsets.all(AppConstants.paddingMedium),
      decoration: BoxDecoration(
        color: AppConstants.cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppConstants.secondary.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: AppConstants.secondary.withValues(alpha: 0.05),
            blurRadius: 10,
            spreadRadius: 1,
          )
        ]
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(AppConstants.secondary),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Local VLM Ingestion Active',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: AppConstants.textPrimary,
                    shadows: [
                      Shadow(
                        color: AppConstants.secondary.withValues(alpha: 0.3),
                        blurRadius: 6,
                      )
                    ]
                  ),
                ),
              ),
              Text(
                '$analyzingCount remaining in queue',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: AppConstants.accent,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: percent,
              minHeight: 5,
              backgroundColor: Colors.white10,
              valueColor: const AlwaysStoppedAnimation<Color>(AppConstants.secondary),
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Analyzing face, place, date and category metadata...',
                style: TextStyle(fontSize: 10.5, color: AppConstants.textMuted),
              ),
              Text(
                '${(percent * 100).toInt()}%',
                style: const TextStyle(fontSize: 11, color: AppConstants.textSecondary, fontWeight: FontWeight.bold),
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildCombinedQuickPanel(
    BuildContext context,
    WidgetRef ref,
    SettingsState settings,
    GalleryState galleryState,
    AppStateData appState,
  ) {
    final isLarge = MediaQuery.of(context).size.width > 900;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppConstants.cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppConstants.cardStroke),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          isLarge
              ? Row(
                  children: [
                    const Icon(Icons.folder_special, color: AppConstants.secondary, size: 16),
                    const SizedBox(width: 8),
                    const Text(
                      'Memory Folders & Albums',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppConstants.textPrimary),
                    ),
                    const Spacer(),
                    _buildVlmControls(context, ref, settings, galleryState),
                    const SizedBox(width: 16),
                    _buildCreateFolderButton(context, ref),
                  ],
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: const [
                            Icon(Icons.folder_special, color: AppConstants.secondary, size: 16),
                            SizedBox(width: 8),
                            Text(
                              'Memory Folders & Albums',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppConstants.textPrimary),
                            ),
                          ],
                        ),
                        _buildCreateFolderButton(context, ref),
                      ],
                    ),
                    const SizedBox(height: 8),
                    _buildVlmControls(context, ref, settings, galleryState),
                  ],
                ),
          const SizedBox(height: 12),
          
          SizedBox(
            height: 38,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              itemCount: galleryState.albums.length + 1,
              itemBuilder: (context, index) {
                if (index == 0) {
                  final isSelected = appState.activeAlbumId == null;
                  return Padding(
                    padding: const EdgeInsets.only(right: 16),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(8),
                      onTap: () => ref.read(appStateProvider.notifier).updateAlbumFilter(null),
                      child: Row(
                        children: [
                           Icon(
                             Icons.all_inbox_outlined,
                             color: isSelected ? AppConstants.secondary : AppConstants.textMuted,
                             size: 18,
                           ),
                           const SizedBox(width: 6),
                           Text(
                             'All Elements',
                             style: TextStyle(
                               fontSize: 12,
                               fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                               color: isSelected ? AppConstants.textPrimary : AppConstants.textSecondary,
                             ),
                           ),
                         ],
                       ),
                     ),
                   );
                 }

                 final album = galleryState.albums[index - 1];
                 final isSelected = appState.activeAlbumId == album.id;

                 return Padding(
                   padding: const EdgeInsets.only(right: 16),
                   child: InkWell(
                     borderRadius: BorderRadius.circular(8),
                     onTap: () => ref.read(appStateProvider.notifier).updateAlbumFilter(album.id),
                     onLongPress: () {
                       ref.read(galleryProvider.notifier).deleteAlbum(album.id);
                       if (appState.activeAlbumId == album.id) {
                         ref.read(appStateProvider.notifier).updateAlbumFilter(null);
                       }
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Album "${album.name}" deleted.')),
                      );
                    },
                    child: Row(
                      children: [
                        Icon(
                          Icons.folder_shared,
                          color: isSelected ? AppConstants.secondary : AppConstants.textMuted,
                          size: 18,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          album.name,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            color: isSelected ? AppConstants.textPrimary : AppConstants.textSecondary,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '(${album.itemIds.length})',
                          style: const TextStyle(fontSize: 10, color: AppConstants.textMuted),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVlmControls(BuildContext context, WidgetRef ref, SettingsState settings, GalleryState galleryState) {
    final models = galleryState.pulledModels.isNotEmpty
        ? galleryState.pulledModels
        : [settings.ollamaModel.isNotEmpty ? settings.ollamaModel : 'Auto-Detecting...'];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppConstants.cardSolidBg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppConstants.cardStroke),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.psychology, color: AppConstants.accent, size: 14),
          const SizedBox(width: 6),
          const Text(
            'VLM Active:',
            style: TextStyle(fontSize: 11, color: AppConstants.textSecondary),
          ),
          const SizedBox(width: 4),
          SizedBox(
            height: 24,
            child: FittedBox(
              fit: BoxFit.fill,
              child: Switch(
                value: settings.autoTagEnabled,
                activeThumbColor: AppConstants.accent,
                onChanged: (val) => ref.read(settingsProvider.notifier).toggleAutoTag(val),
              ),
            ),
          ),
          const SizedBox(width: 12),
          const Text(
            'Model:',
            style: TextStyle(fontSize: 11, color: AppConstants.textSecondary),
          ),
          const SizedBox(width: 6),
          Container(
            height: 24,
            padding: const EdgeInsets.symmetric(horizontal: 6),
            decoration: BoxDecoration(
              color: AppConstants.inputBg,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: AppConstants.cardStroke),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: models.contains(settings.ollamaModel) ? settings.ollamaModel : models.first,
                dropdownColor: AppConstants.inputBg,
                icon: const Icon(Icons.arrow_drop_down, size: 14),
                style: const TextStyle(fontSize: 10, color: AppConstants.textPrimary),
                onChanged: (newModel) {
                  if (newModel != null) {
                    ref.read(settingsProvider.notifier).updateOllamaModel(newModel);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('VLM Model target updated to $newModel')),
                    );
                  }
                },
                items: models.map((m) {
                  return DropdownMenuItem<String>(
                    value: m,
                    child: Text(m),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCreateFolderButton(BuildContext context, WidgetRef ref) {
    return TextButton.icon(
      onPressed: () => _showCreateAlbumDialog(context, ref),
      icon: const Icon(Icons.add_circle_outline, size: 13, color: AppConstants.secondary),
      label: const Text(
        'Create Folder',
        style: TextStyle(fontSize: 11, color: AppConstants.secondary, fontWeight: FontWeight.bold),
      ),
      style: TextButton.styleFrom(
        padding: EdgeInsets.zero,
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    );
  }

  void _showCreateAlbumDialog(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: AppConstants.dialogBg,
        title: Row(
          children: const [
            Icon(Icons.folder_open_outlined, color: AppConstants.secondary),
            SizedBox(width: 8),
            Text('Create Memory Folder'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Enter a visual title to catalog memory albums (e.g. Trips, Family, Nature, Holidays)',
              style: TextStyle(fontSize: 12.5, color: AppConstants.textSecondary),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              autofocus: true,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Folder Name',
                hintText: 'e.g. Summer 2026',
                labelStyle: const TextStyle(color: AppConstants.textSecondary),
                hintStyle: const TextStyle(color: AppConstants.textMuted),
                fillColor: AppConstants.inputBg,
                filled: true,
                enabledBorder: const OutlineInputBorder(
                  borderSide: BorderSide(color: AppConstants.cardStroke),
                ),
                focusedBorder: const OutlineInputBorder(
                  borderSide: BorderSide(color: AppConstants.primary),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Cancel', style: TextStyle(color: AppConstants.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () {
              final name = controller.text.trim();
              if (name.isNotEmpty) {
                ref.read(galleryProvider.notifier).createAlbum(name);
                Navigator.pop(dialogCtx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Folder "$name" created successfully!')),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppConstants.secondary),
            child: const Text('Create', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
