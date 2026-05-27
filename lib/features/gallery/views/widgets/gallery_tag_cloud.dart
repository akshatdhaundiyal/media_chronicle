import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../state/app_state.dart';
import '../../providers/gallery_provider.dart';

class GalleryTagCloud extends StatelessWidget {
  const GalleryTagCloud({super.key});

  @override
  Widget build(BuildContext context) {
    final galleryProv = context.watch<GalleryProvider>();
    final appState = context.watch<AppState>();

    final uniqueTags = <String>{};
    for (var item in galleryProv.items) {
      if (item.face != null && item.face != 'none' && !item.face!.contains('none')) {
        uniqueTags.add(item.face!.split(',').first.trim());
      }
      if (item.place != null && item.place != 'unknown') {
        uniqueTags.add(item.place!.trim());
      }
      if (item.dateClue != null && item.dateClue != 'unknown') {
        uniqueTags.add(item.dateClue!.trim());
      }
    }

    final tagsList = uniqueTags.take(8).toList();

    if (tagsList.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: 32,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: tagsList.length + 1,
        itemBuilder: (context, index) {
          if (index == 0) {
            final isFiltering = appState.activeTagFilter != null;
            if (!isFiltering) return const SizedBox.shrink();
            
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ActionChip(
                backgroundColor: Colors.redAccent.withValues(alpha: 0.15),
                side: const BorderSide(color: Colors.redAccent, width: 0.5),
                label: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(Icons.clear, size: 10, color: Colors.redAccent),
                    SizedBox(width: 4),
                    Text('Reset Tags Filter', style: TextStyle(fontSize: 10, color: Colors.redAccent, fontWeight: FontWeight.bold)),
                  ],
                ),
                onPressed: () => appState.updateTagFilter(null),
              ),
            );
          }

          final tag = tagsList[index - 1];
          final isSelected = appState.activeTagFilter == tag;

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              selectedColor: AppConstants.accent.withValues(alpha: 0.2),
              backgroundColor: AppConstants.cardBg,
              side: BorderSide(color: isSelected ? AppConstants.accent : AppConstants.cardStroke),
              label: Text(
                '# $tag',
                style: TextStyle(
                  fontSize: 10,
                  color: isSelected ? AppConstants.textPrimary : AppConstants.textSecondary,
                ),
              ),
              selected: isSelected,
              onSelected: (val) {
                appState.updateTagFilter(val ? tag : null);
              },
            ),
          );
        },
      ),
    );
  }
}
