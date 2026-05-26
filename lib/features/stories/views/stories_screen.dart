import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_constants.dart';
import '../../../state/app_state.dart';
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
                      // Desktop split-row list layout, or neat dual-column grid
                      int crossAxisCount = 1;
                      double childAspectRatio = 3.2;
                      if (constraints.maxWidth > 1000) {
                        crossAxisCount = 2;
                        childAspectRatio = 1.8;
                      } else if (constraints.maxWidth > 650) {
                        childAspectRatio = 1.5;
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
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Background Image
          story.isLocal
              ? Image.memory(story.coverBytes!, fit: BoxFit.cover)
              : Image.network(
                  story.coverUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (c, o, s) => Container(color: const Color(0xFF1E1E35)),
                ),
          // Gradient Overlay
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
          // Narrative Content
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
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showCreateStoryDialog(BuildContext context) {
    final titleController = TextEditingController();
    final descController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: const Color(0xFF16162D),
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
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Chronicle Body / Description',
                  hintText: 'Describe the memory or trip in detail...',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Cancel', style: TextStyle(color: AppConstants.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () {
              if (titleController.text.trim().isEmpty) return;
              
              final newStory = StoryItem(
                id: DateTime.now().millisecondsSinceEpoch.toString(),
                title: titleController.text,
                description: descController.text,
                date: DateTime.now(),
                coverUrl: 'https://images.unsplash.com/photo-1464822759023-fed622ff2c3b?q=80&w=600&auto=format&fit=crop', // Beautiful mountain pass mockup
              );
              
              context.read<StoriesProvider>().addStory(newStory);
              Navigator.pop(dialogCtx);
              
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Chronicle draft saved!')),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppConstants.secondary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Publish Story', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
