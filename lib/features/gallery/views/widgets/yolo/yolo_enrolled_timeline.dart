import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/constants/app_constants.dart';
import '../../../models/detected_face.dart';
import '../../../models/media_item.dart';
import '../../../providers/gallery_provider.dart';
import '../../../providers/yolo_face_provider.dart';

/// Renders the chronological progress of variations mapped to enrolled identities.
/// Features a vertical scroller of identities containing nested horizontal timeline scrollers.
class YoloEnrolledTimeline extends ConsumerWidget {
  const YoloEnrolledTimeline({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Observe state updates reactively to paint new enrollment tags as they are added.
    final yoloState = ref.watch(yoloFaceProvider);
    final galleryState = ref.watch(galleryProvider);
    final names = yoloState.enrolledNames;

    return Container(
      padding: const EdgeInsets.all(AppConstants.paddingLarge),
      decoration: BoxDecoration(
        color: AppConstants.cardBg,
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        border: Border.all(color: AppConstants.cardStroke),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.history_toggle_off, color: AppConstants.secondary),
              SizedBox(width: 8),
              Text(
                'Identities chronological Age/Growth Timeline',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Display placeholder description if no identities are labeled yet
          names.isEmpty
              ? Container(
                  height: 120,
                  alignment: Alignment.center,
                  child: const Text(
                    'No identities enrolled yet. Label unidentified faces to begin.',
                    style: TextStyle(color: AppConstants.textMuted),
                  ),
                )
              : ListView.builder(
                  shrinkWrap: true, // Let the list size wrap its children tightly
                  physics: const NeverScrollableScrollPhysics(), // Delegate scroll boundaries to parent SingleChildScrollView
                  itemCount: names.length,
                  itemBuilder: (context, idx) {
                    final name = names[idx];
                    
                    // Filter detected face nodes corresponding to this specific identity
                    final facesForName = yoloState.detectedFaces
                        .where((f) => f.isIdentified && f.name == name)
                        .toList();

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (idx > 0) const Divider(height: 24, color: Colors.white10),
                        
                        // Identity title label and count badge
                        Row(
                          children: [
                            Text(
                              name,
                              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppConstants.accent.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '${facesForName.length} variations',
                                style: const TextStyle(
                                  fontSize: 9.5,
                                  color: AppConstants.accent,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        
                        // Nested horizontal timeline grid exhibiting individual face variations chronologically
                        SizedBox(
                          height: 110,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            physics: const BouncingScrollPhysics(),
                            itemCount: facesForName.length,
                            itemBuilder: (context, fIdx) {
                              final face = facesForName[fIdx];
                              final mediaItem = galleryState.items.firstWhere((i) => i.id == face.mediaItemId);

                              return Padding(
                                padding: const EdgeInsets.only(right: 12.0),
                                child: Container(
                                  width: 130,
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.black26,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: Colors.white10),
                                  ),
                                  child: Column(
                                    children: [
                                      // Render cropped thumbnail of the YOLO classification bounds
                                      _buildCroppedFaceWidget(mediaItem, face, size: 50),
                                      const SizedBox(height: 6),
                                      
                                      // Display age progression variant annotation label
                                      Text(
                                        face.ageVariant ?? 'Age Progression',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(
                                          fontSize: 10.5,
                                          color: AppConstants.textSecondary,
                                          fontWeight: FontWeight.w500,
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
                    );
                  },
                ),
        ],
      ),
    );
  }

  /// Extracts the facial segment from raw image data on the fly.
  /// Binds the FittedBox alignment to fractional bounding coordinate spaces
  /// to crop and scale the face thumbnail seamlessly without quality loss.
  Widget _buildCroppedFaceWidget(MediaItem item, DetectedFace face, {required double size}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: SizedBox(
        width: size,
        height: size,
        child: FittedBox(
          fit: BoxFit.none,
          alignment: Alignment(
            -1.0 + 2.0 * face.x + face.width,
            -1.0 + 2.0 * face.y + face.height,
          ),
          child: SizedBox(
            width: size / face.width,
            height: size / face.height,
            child: item.isLocal
                ? Image.memory(item.bytes!, fit: BoxFit.fill)
                : Image.network(item.url!, fit: BoxFit.fill),
          ),
        ),
      ),
    );
  }
}
