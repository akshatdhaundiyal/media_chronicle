import 'package:flutter/material.dart';
import '../../../../core/constants/app_constants.dart';
import '../../models/story_item.dart';

class StoryDetailDialog extends StatelessWidget {
  final StoryItem story;

  const StoryDetailDialog({super.key, required this.story});

  static void show(BuildContext context, StoryItem story) {
    showDialog(
      context: context,
      builder: (dialogCtx) => StoryDetailDialog(story: story),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
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
                        onPressed: () => Navigator.pop(context),
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
    );
  }
}
