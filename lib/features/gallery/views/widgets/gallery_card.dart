import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/utils/media_helper.dart';
import '../../models/media_item.dart';
import '../../models/detected_face.dart';
import '../../providers/yolo_face_provider.dart';

class GalleryCard extends StatelessWidget {
  final MediaItem item;
  final bool isSelected;
  final bool isSelectionMode;
  final VoidCallback? onTap;
  final VoidCallback onLongPress;
  final VoidCallback onAddToAlbum;
  final VoidCallback onDelete;

  const GalleryCard({
    super.key,
    required this.item,
    required this.isSelected,
    required this.isSelectionMode,
    this.onTap,
    required this.onLongPress,
    required this.onAddToAlbum,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppConstants.cardBg,
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        border: Border.all(
          color: isSelected ? AppConstants.primary : AppConstants.cardStroke,
          width: isSelected ? 2.0 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: isSelected ? AppConstants.primary.withValues(alpha: 0.15) : Colors.black.withValues(alpha: 0.15),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
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
                              color: AppConstants.inputBg,
                              child: const Center(
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(AppConstants.primary),
                                ),
                              ),
                            );
                          },
                          errorBuilder: (c, o, s) => Container(
                            color: AppConstants.inputBg,
                            child: const Icon(Icons.broken_image, color: AppConstants.textMuted),
                          ),
                        ),
                  if (isSelected)
                    Positioned.fill(
                      child: Container(
                        color: AppConstants.primary.withValues(alpha: 0.25),
                        child: const Center(
                           child: Icon(
                            Icons.check_circle,
                            color: Colors.white,
                            size: 40,
                            shadows: [
                              Shadow(
                                color: AppConstants.primary,
                                blurRadius: 12,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                  if (item.group != null && !item.isAnalyzing)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppConstants.primary.withValues(alpha: 0.85),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.white24),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(MediaHelper.getGroupIcon(item.group!), size: 10, color: Colors.white),
                            const SizedBox(width: 4),
                            Text(
                              item.group!,
                              style: const TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
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
                            size: 10,
                            color: Colors.white,
                          ),
                        ],
                      ),
                    ),
                  ),

                  if (item.isAnalyzing)
                    Container(
                      color: Colors.black.withValues(alpha: 0.75),
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(AppConstants.accent),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'VLM Reading Image...',
                              style: TextStyle(
                                color: AppConstants.accent,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                                shadows: [
                                  Shadow(
                                    color: AppConstants.accent.withValues(alpha: 0.4),
                                    blurRadius: 8,
                                  )
                                ],
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          item.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppConstants.textPrimary,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add_to_photos_outlined, color: AppConstants.textMuted, size: 16),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: onAddToAlbum,
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 16),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: onDelete,
                      )
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Added ${item.date.day}/${item.date.month}/${item.date.year}',
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppConstants.textMuted,
                    ),
                  ),

                  if (!item.isAnalyzing && item.face != null) ...[
                    const SizedBox(height: 8),
                    _buildLlmCapsuleBadge(Icons.face_unlock_outlined, 'Face: ${item.face}', AppConstants.primary),
                    const SizedBox(height: 4),
                    _buildLlmCapsuleBadge(Icons.location_on_outlined, 'Place: ${item.place}', AppConstants.accent),
                    const SizedBox(height: 4),
                    _buildLlmCapsuleBadge(Icons.wb_sunny_outlined, 'Time: ${item.dateClue}', AppConstants.secondary),
                  ],
                  
                  // YOLO Face status badges (CRITICAL: Optimized via Selector!)
                  //
                  // Rationale: Using context.watch<YoloFaceProvider>() would cause EVERY card on screen to rebuild
                  // whenever any face is labeled/analyzed. By using Selector and filtering for faces matching
                  // the current item.id, only the specific card whose face data actually changes is rebuilt.
                  // This brings general update performance from O(N) to O(1) complexity.
                  if (!item.isAnalyzing) ...[
                    Selector<YoloFaceProvider, List<DetectedFace>>(
                      selector: (context, provider) => provider.getFacesForMediaItem(item.id),
                      shouldRebuild: (oldList, newList) => !listEquals(oldList, newList),
                      builder: (context, itemFaces, child) {
                        if (itemFaces.isNotEmpty) {
                          final hasUnidentified = itemFaces.any((f) => !f.isIdentified);
                          return Padding(
                            padding: const EdgeInsets.only(top: 4.0),
                            child: _buildLlmCapsuleBadge(
                              hasUnidentified ? Icons.warning_amber_rounded : Icons.psychology_outlined,
                              hasUnidentified
                                  ? 'YOLO: ${itemFaces.length} Faces (Label Required)'
                                  : 'YOLO: ${itemFaces.length} Faces Recognized',
                              hasUnidentified ? AppConstants.secondary : Colors.greenAccent,
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      },
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

  Widget _buildLlmCapsuleBadge(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.15)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: color),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 10,
                color: color.withValues(alpha: 0.85),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
