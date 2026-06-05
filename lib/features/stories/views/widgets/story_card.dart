import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_constants.dart';
import '../../models/story_item.dart';
import '../../providers/stories_provider.dart';

class StoryCard extends ConsumerWidget {
  final StoryItem story;
  final VoidCallback onTap;

  const StoryCard({
    super.key,
    required this.story,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
        onTap: onTap,
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
                          ref.read(storiesProvider.notifier).deleteStory(story.id);
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
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppConstants.textMuted,
                              fontWeight: FontWeight.bold,
                            ),
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
}
