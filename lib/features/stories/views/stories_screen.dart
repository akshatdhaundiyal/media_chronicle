import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_constants.dart';
import '../../../state/app_state.dart';
import '../providers/stories_provider.dart';
import 'widgets/create_story_dialog.dart';
import 'widgets/stories_empty_state.dart';
import 'widgets/story_card.dart';
import 'widgets/story_detail_dialog.dart';

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
                onPressed: () => CreateStoryDialog.show(context),
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
                ? StoriesEmptyState(onCreatePressed: () => CreateStoryDialog.show(context))
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
                          return StoryCard(
                            story: story,
                            onTap: () => StoryDetailDialog.show(context, story),
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
}
