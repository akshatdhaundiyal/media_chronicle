import 'package:flutter/material.dart';
import '../../../../core/constants/app_constants.dart';

class StoriesEmptyState extends StatelessWidget {
  final VoidCallback onCreatePressed;

  const StoriesEmptyState({super.key, required this.onCreatePressed});

  @override
  Widget build(BuildContext context) {
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
              onPressed: onCreatePressed,
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
}
