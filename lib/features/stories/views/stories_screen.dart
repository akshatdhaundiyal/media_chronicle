import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_constants.dart';
import '../../../state/app_state.dart';
import '../../gallery/providers/gallery_provider.dart';
import '../../gallery/models/media_item.dart';
import '../models/story_item.dart';
import '../providers/stories_provider.dart';

class StoriesScreen extends StatelessWidget {
  const StoriesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final storiesProv = context.watch<StoriesProvider>();
    final appState = context.watch<AppState>();
    final query = appState.searchQuery.toLowerCase();

    final filteredStories = storiesProv.stories.where((story) {
      return story.title.toLowerCase().contains(query) ||
          story.description.toLowerCase().contains(query);
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
                    'Chronological Stories',
                    style: Theme.of(context).textTheme.displayMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${filteredStories.length} memory narratives curated',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
              ElevatedButton.icon(
                onPressed: () => _showCreateStoryDialog(context),
                icon: const Icon(Icons.add_circle_outline),
                label: const Text('Create Story'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppConstants.secondary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 4,
                  shadowColor: AppConstants.secondary.withValues(alpha: 0.3),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppConstants.paddingLarge),
          Expanded(
            child: filteredStories.isEmpty
                ? _buildEmptyState(context)
                : LayoutBuilder(
                    builder: (context, constraints) {
                      int crossAxisCount = 1;
                      double childAspectRatio = 3.2;
                      if (constraints.maxWidth > 1000) {
                        crossAxisCount = 2;
                        childAspectRatio = 1.6; // Slightly deeper aspect ratio for media stack circles
                      } else if (constraints.maxWidth > 650) {
                        childAspectRatio = 1.4;
                      }

                      return GridView.builder(
                        physics: const BouncingScrollPhysics(),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: crossAxisCount,
                          crossAxisSpacing: AppConstants.paddingLarge,
                          mainAxisSpacing: AppConstants.paddingLarge,
                          childAspectRatio: childAspectRatio,
                        ),
                        itemCount: filteredStories.length,
                        itemBuilder: (context, index) {
                          final story = filteredStories[index];
                          return _buildStoryCard(context, story);
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
              Icons.auto_stories_outlined,
              size: 64,
              color: AppConstants.textMuted.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'No Stories Written',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Capture your chronicles in rich narratives. Combine multi-media with descriptions.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            TextButton.icon(
              onPressed: () => _showCreateStoryDialog(context),
              icon: const Icon(Icons.edit_note_outlined),
              label: const Text('Draft a Story'),
              style: TextButton.styleFrom(
                foregroundColor: AppConstants.secondary,
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildStoryCard(BuildContext context, StoryItem story) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        border: Border.all(color: AppConstants.cardStroke),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 15,
            offset: const Offset(0, 8),
          )
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _showStoryDetail(context, story),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Background Cover Image
            story.isLocal
                ? Image.memory(story.coverBytes!, fit: BoxFit.cover)
                : Image.network(
                    story.coverUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (c, o, s) => Container(color: const Color(0xFF1E1E35)),
                  ),
            // Gradient overlay
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.black.withValues(alpha: 0.85),
                    Colors.black.withValues(alpha: 0.2),
                    Colors.black.withValues(alpha: 0.75),
                  ],
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                ),
              ),
            ),
            // Narrative details
            Padding(
              padding: const EdgeInsets.all(AppConstants.paddingLarge),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppConstants.primary.withValues(alpha: 0.75),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.white24),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.calendar_today, size: 10, color: Colors.white),
                            const SizedBox(width: 4),
                            Text(
                              '${story.date.day}/${story.date.month}/${story.date.year}',
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_sweep_outlined, color: Colors.redAccent, size: 20),
                        onPressed: () {
                          context.read<StoriesProvider>().deleteStory(story.id);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Chronicle story deleted')),
                          );
                        },
                      ),
                    ],
                  ),
                  const Spacer(),
                  Text(
                    story.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      shadows: [
                        Shadow(
                          color: Colors.black54,
                          blurRadius: 4,
                          offset: Offset(0, 2),
                        )
                      ],
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    story.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppConstants.textSecondary,
                      height: 1.4,
                    ),
                  ),

                  // Mini circle stack row of associated media items
                  if (story.mediaItems.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        SizedBox(
                          height: 24,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: story.mediaItems.length.clamp(0, 3),
                            itemBuilder: (context, idx) {
                              final item = story.mediaItems[idx];
                              return Padding(
                                padding: const EdgeInsets.only(right: 6),
                                child: Container(
                                  width: 24,
                                  height: 24,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.white, width: 1),
                                    image: DecorationImage(
                                      fit: BoxFit.cover,
                                      image: item.isLocal
                                          ? MemoryImage(item.bytes!)
                                          : NetworkImage(item.url!) as ImageProvider,
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        if (story.mediaItems.length > 3) ...[
                          const SizedBox(width: 4),
                          Text(
                            '+${story.mediaItems.length - 3} photos',
                            style: const TextStyle(fontSize: 11, color: AppConstants.textMuted, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ],
                    ),
                  ]
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCreateStoryDialog(BuildContext context) {
    final titleController = TextEditingController();
    final descController = TextEditingController();
    final selectedMedia = <MediaItem>[];

    showDialog(
      context: context,
      builder: (dialogCtx) {
        final galleryProv = dialogCtx.watch<GalleryProvider>();
        final galleryItems = galleryProv.items;

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
          content: StatefulBuilder(
            builder: (context, setState) {
              return SizedBox(
                width: 500,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: titleController,
                      decoration: const InputDecoration(
                        labelText: 'Story Title',
                        hintText: 'Enter a creative title...',
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: descController,
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
                                final isSelected = selectedMedia.contains(item);

                                return Padding(
                                  padding: const EdgeInsets.only(right: 10),
                                  child: InkWell(
                                    onTap: () {
                                      setState(() {
                                        if (isSelected) {
                                          selectedMedia.remove(item);
                                        } else {
                                          selectedMedia.add(item);
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
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: const Text('Cancel', style: TextStyle(color: AppConstants.textSecondary)),
            ),
            ElevatedButton(
              onPressed: () {
                if (titleController.text.trim().isEmpty) return;
                
                final coverUrl = selectedMedia.isNotEmpty && !selectedMedia.first.isLocal
                    ? selectedMedia.first.url
                    : 'https://images.unsplash.com/photo-1464822759023-fed622ff2c3b?q=80&w=600&auto=format&fit=crop';
                final coverBytes = selectedMedia.isNotEmpty && selectedMedia.first.isLocal
                    ? selectedMedia.first.bytes
                    : null;

                final newStory = StoryItem(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  title: titleController.text,
                  description: descController.text,
                  date: DateTime.now(),
                  coverUrl: coverUrl,
                  coverBytes: coverBytes,
                  mediaItems: List<MediaItem>.from(selectedMedia),
                );
                
                dialogCtx.read<StoriesProvider>().addStory(newStory);
                Navigator.pop(dialogCtx);
                
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
      },
    );
  }

  void _showStoryDetail(BuildContext context, StoryItem story) {
    showDialog(
      context: context,
      builder: (dialogCtx) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF0F0F1E).withValues(alpha: 0.95),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppConstants.cardStroke),
          ),
          constraints: const BoxConstraints(maxWidth: 800, maxHeight: 700),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Large Cover Backdrop Header
              Expanded(
                flex: 4,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    story.isLocal
                        ? Image.memory(story.coverBytes!, fit: BoxFit.cover)
                        : Image.network(story.coverUrl!, fit: BoxFit.cover),
                    Container(
                      color: Colors.black45,
                    ),
                    Positioned(
                      top: 16,
                      right: 16,
                      child: CircleAvatar(
                        backgroundColor: Colors.black54,
                        child: IconButton(
                          icon: const Icon(Icons.close, color: Colors.white),
                          onPressed: () => Navigator.pop(dialogCtx),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 16,
                      left: 16,
                      right: 16,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppConstants.primary,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '${story.date.day}/${story.date.month}/${story.date.year}',
                              style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            story.title,
                            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                        ],
                      ),
                    )
                  ],
                ),
              ),
              
              // Narrative description text & associated media grid
              Expanded(
                flex: 5,
                child: Padding(
                  padding: const EdgeInsets.all(AppConstants.paddingLarge),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'THE CHRONICLE NARRATIVE',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: AppConstants.textMuted,
                          letterSpacing: 1.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Expanded(
                        flex: 3,
                        child: SingleChildScrollView(
                          physics: const BouncingScrollPhysics(),
                          child: Text(
                            story.description,
                            style: const TextStyle(fontSize: 13, color: AppConstants.textSecondary, height: 1.6),
                          ),
                        ),
                      ),
                      
                      if (story.mediaItems.isNotEmpty) ...[
                        const Divider(color: AppConstants.cardStroke, height: 24),
                        const Text(
                          'ASSOCIATED JOURNAL GALLERY',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: AppConstants.textMuted,
                            letterSpacing: 1.5,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Expanded(
                          flex: 4,
                          child: GridView.builder(
                            physics: const BouncingScrollPhysics(),
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 5,
                              crossAxisSpacing: 8,
                              mainAxisSpacing: 8,
                              childAspectRatio: 1.0,
                            ),
                            itemCount: story.mediaItems.length,
                            itemBuilder: (context, idx) {
                              final item = story.mediaItems[idx];
                              return ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: item.isLocal
                                    ? Image.memory(item.bytes!, fit: BoxFit.cover)
                                    : Image.network(item.url!, fit: BoxFit.cover),
                              );
                            },
                          ),
                        )
                      ]
                    ],
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
