import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../gallery/models/media_item.dart';
import '../../../gallery/providers/gallery_provider.dart';
import '../../models/story_item.dart';
import '../../providers/stories_provider.dart';

class CreateStoryDialog extends ConsumerStatefulWidget {
  const CreateStoryDialog({super.key});

  static void show(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogCtx) => const CreateStoryDialog(),
    );
  }

  @override
  ConsumerState<CreateStoryDialog> createState() => _CreateStoryDialogState();
}

class _CreateStoryDialogState extends ConsumerState<CreateStoryDialog> {
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _selectedMedia = <MediaItem>[];

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final galleryState = ref.watch(galleryProvider);
    final galleryItems = galleryState.items;

    return AlertDialog(
      backgroundColor: AppConstants.dialogBg,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: const [
          Icon(Icons.edit_note, color: AppConstants.secondary),
          SizedBox(width: 8),
          Text('Draft Story Chronicle'),
        ],
      ),
      content: SizedBox(
        width: 500,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Story Title',
                hintText: 'Enter a creative title...',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _descController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Chronicle Body / Description',
                hintText: 'Describe the memory or trip in detail...',
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'ASSOCIATE GALLERY MEDIA',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: AppConstants.textMuted,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 8),
            galleryItems.isEmpty
                ? const Text(
                    'No media catalogued. Upload gallery photos first.',
                    style: TextStyle(fontSize: 11, color: AppConstants.textMuted),
                  )
                : SizedBox(
                    height: 64,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      itemCount: galleryItems.length,
                      itemBuilder: (context, index) {
                        final item = galleryItems[index];
                        final isSelected = _selectedMedia.contains(item);

                        return Padding(
                          padding: const EdgeInsets.only(right: 10),
                          child: InkWell(
                            onTap: () {
                              setState(() {
                                if (isSelected) {
                                  _selectedMedia.remove(item);
                                } else {
                                  _selectedMedia.add(item);
                                }
                              });
                            },
                            borderRadius: BorderRadius.circular(8),
                            child: Stack(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Container(
                                    width: 64,
                                    height: 64,
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                        color: isSelected ? AppConstants.secondary : AppConstants.cardStroke,
                                        width: isSelected ? 2 : 1,
                                      ),
                                    ),
                                    child: item.isLocal
                                        ? Image.memory(item.bytes!, fit: BoxFit.cover)
                                        : Image.network(item.url!, fit: BoxFit.cover),
                                  ),
                                ),
                                if (isSelected)
                                  Positioned(
                                    top: 4,
                                    right: 4,
                                    child: const Icon(
                                      Icons.check_circle,
                                      color: AppConstants.secondary,
                                      size: 16,
                                    ),
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
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel', style: TextStyle(color: AppConstants.textSecondary)),
        ),
        ElevatedButton(
          onPressed: () {
            if (_titleController.text.trim().isEmpty) return;
            
            final coverUrl = _selectedMedia.isNotEmpty && !_selectedMedia.first.isLocal
                ? _selectedMedia.first.url
                : 'https://images.unsplash.com/photo-1464822759023-fed622ff2c3b?q=80&w=600&auto=format&fit=crop';
            final coverBytes = _selectedMedia.isNotEmpty && _selectedMedia.first.isLocal
                ? _selectedMedia.first.bytes
                : null;

            final newStory = StoryItem(
              id: DateTime.now().millisecondsSinceEpoch.toString(),
              title: _titleController.text,
              description: _descController.text,
              date: DateTime.now(),
              coverUrl: coverUrl,
              coverBytes: coverBytes,
              mediaItems: List<MediaItem>.from(_selectedMedia),
            );
            
            ref.read(storiesProvider.notifier).addStory(newStory);
            Navigator.pop(context);
            
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Chronicle draft saved with associated media!')),
            );
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppConstants.secondary,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          child: const Text('Publish Story', style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }
}
