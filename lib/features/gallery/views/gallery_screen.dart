import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/media_helper.dart';
import '../../../state/app_state.dart';
import '../models/media_item.dart';
import 'package:file_picker/file_picker.dart';
import '../providers/gallery_provider.dart';

class GalleryScreen extends StatelessWidget {
  const GalleryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final galleryProv = context.watch<GalleryProvider>();
    final appState = context.watch<AppState>();
    final query = appState.searchQuery.toLowerCase();

    // Filter items based on global search query
    final filteredItems = galleryProv.items.where((item) {
      return item.title.toLowerCase().contains(query);
    }).toList();

    return Padding(
      padding: const EdgeInsets.all(AppConstants.paddingLarge),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Gallery Archive',
                    style: Theme.of(context).textTheme.displayMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${filteredItems.length} media items catalogued',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
              ElevatedButton.icon(
                onPressed: () => _handleMediaUpload(context),
                icon: const Icon(Icons.add_a_photo_outlined),
                label: const Text('Add Media'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppConstants.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 4,
                  shadowColor: AppConstants.primaryGlow,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppConstants.paddingLarge),
          Expanded(
            child: filteredItems.isEmpty
                ? _buildEmptyState(context)
                : LayoutBuilder(
                    builder: (context, constraints) {
                      // Dynamically adjust column count
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
                          childAspectRatio: 0.85,
                        ),
                        itemCount: filteredItems.length,
                        itemBuilder: (context, index) {
                          final item = filteredItems[index];
                          return _buildGalleryCard(context, item);
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(AppConstants.paddingExtraLarge),
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
              size: 64,
              color: AppConstants.textMuted.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'No Media Found',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Add physical images or run simulated pickers to populate your custom gallery archive.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            TextButton.icon(
              onPressed: () => _handleMediaUpload(context),
              icon: const Icon(Icons.upload_file),
              label: const Text('Upload First Item'),
              style: TextButton.styleFrom(
                foregroundColor: AppConstants.accent,
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildGalleryCard(BuildContext context, MediaItem item) {
    return Container(
      decoration: BoxDecoration(
        color: AppConstants.cardBg,
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        border: Border.all(color: AppConstants.cardStroke),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _showMediaDetail(context, item),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  item.isLocal
                      ? Image.memory(
                          item.bytes!,
                          fit: BoxFit.cover,
                        )
                      : Image.network(
                          item.url!,
                          fit: BoxFit.cover,
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Container(
                              color: const Color(0xFF1E1E35),
                              child: const Center(
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(AppConstants.primary),
                                ),
                              ),
                            );
                          },
                          errorBuilder: (c, o, s) => Container(
                            color: const Color(0xFF1E1E35),
                            child: const Icon(Icons.broken_image, color: AppConstants.textMuted),
                          ),
                        ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white10),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            item.type == 'video' ? Icons.play_arrow : Icons.image,
                            size: 12,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            item.type.toUpperCase(),
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppConstants.paddingMedium),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppConstants.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Added ${item.date.day}/${item.date.month}/${item.date.year}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppConstants.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 18),
                    onPressed: () {
                      context.read<GalleryProvider>().deleteMediaItem(item.id);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Media item catalog removed'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    },
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleMediaUpload(BuildContext context) async {
    // Offer options for real or mock file pick to enhance local web dev
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E38),
        title: const Text('Add Media Asset'),
        content: const Text(
          'Choose whether to browse your local device files or simulate a camera capture upload for UI testing.',
        ),
        actions: [
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogCtx);
              await MediaHelper.pickMockMedia();
              final newItem = MediaItem(
                id: DateTime.now().millisecondsSinceEpoch.toString(),
                title: 'Simulated Shot',
                url: 'https://images.unsplash.com/photo-1542291026-7eec264c27ff?q=80&w=600&auto=format&fit=crop', // Stunning sneaker red glow mockup
                type: 'image',
                date: DateTime.now(),
              );
              if (context.mounted) {
                context.read<GalleryProvider>().addMediaItem(newItem);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Simulated shot added to Gallery!')),
                );
              }
            },
            child: const Text('Simulate Capture', style: TextStyle(color: AppConstants.accent)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(dialogCtx);
              final result = await MediaHelper.pickFile(type: FileType.image);
              if (result != null && result.bytes != null) {
                final newItem = MediaItem(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  bytes: result.bytes,
                  title: result.name,
                  type: result.type,
                  date: DateTime.now(),
                );
                if (context.mounted) {
                  context.read<GalleryProvider>().addMediaItem(newItem);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('File "${result.name}" added successfully!')),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppConstants.primary),
            child: const Text('Browse Files', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showMediaDetail(BuildContext context, MediaItem item) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF0F0F1E).withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppConstants.cardStroke),
          ),
          constraints: const BoxConstraints(maxWidth: 800, maxHeight: 600),
          clipBehavior: Clip.antiAlias,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    item.isLocal
                        ? Image.memory(item.bytes!, fit: BoxFit.contain)
                        : Image.network(item.url!, fit: BoxFit.contain),
                    Positioned(
                      top: 16,
                      right: 16,
                      child: CircleAvatar(
                        backgroundColor: Colors.black54,
                        child: IconButton(
                          icon: const Icon(Icons.close, color: Colors.white),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(AppConstants.paddingLarge),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            item.title,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Recorded on ${item.date.toLocal()}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppConstants.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      item.type.toUpperCase(),
                      style: const TextStyle(
                        color: AppConstants.accent,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
