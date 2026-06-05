import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/constants/app_constants.dart';
import '../../../models/detected_face.dart';
import '../../../models/media_item.dart';
import '../../../providers/gallery_provider.dart';
import '../../../providers/yolo_face_provider.dart';
import '../face_labeling_dialog.dart';

/// Renders the scrollable horizontal queue of unrecognized face bounds pending manual labeling.
/// Enables on-demand identity ingestion and immediate model weight backpropagation.
class YoloUnidentifiedQueue extends ConsumerWidget {
  const YoloUnidentifiedQueue({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch for YOLO face detections updates and gallery files.
    final yoloState = ref.watch(yoloFaceProvider);
    final galleryState = ref.watch(galleryProvider);
    final unIdentified = yoloState.unidentifiedFaces;

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
          // Header scroller titles and dynamic count badges
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: const [
                  Icon(Icons.face_retouching_off_outlined, color: AppConstants.secondary),
                  SizedBox(width: 8),
                  Text(
                    'Active Labeling Queue',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ],
              ),
              if (unIdentified.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppConstants.secondary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${unIdentified.length} pending',
                    style: const TextStyle(fontSize: 10, color: AppConstants.secondary, fontWeight: FontWeight.bold),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Display celebration status vector graphic if all face captures have been catalogued
          unIdentified.isEmpty
              ? Container(
                  height: 200,
                  alignment: Alignment.center,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(Icons.check_circle_outline, color: Colors.greenAccent, size: 36),
                      SizedBox(height: 12),
                      Text(
                        'Ingestion Workspace Synced!',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'All detected faces have been successfully labeled and maps updated.',
                        style: TextStyle(fontSize: 11, color: AppConstants.textMuted),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                )
              : SizedBox(
                  height: 200,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    itemCount: unIdentified.length,
                    itemBuilder: (context, index) {
                      final face = unIdentified[index];
                      final mediaItem = galleryState.items.firstWhere((i) => i.id == face.mediaItemId);

                      return Padding(
                        padding: const EdgeInsets.only(right: 16.0),
                        child: Container(
                          width: 140,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.black26,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppConstants.cardStroke),
                          ),
                          child: Column(
                            children: [
                              // Cropped head segment thumbnail
                              _buildCroppedFaceWidget(mediaItem, face, size: 64),
                              const SizedBox(height: 10),
                              const Text(
                                'Detected Face',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  color: AppConstants.textSecondary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              
                              // Display abbreviated vector ID securely without range overflow crashes
                              Text(
                                'Vector ID: ${face.id.substring(0, min(8, face.id.length))}',
                                style: const TextStyle(fontSize: 9.5, color: AppConstants.textMuted),
                              ),
                              const Spacer(),
                              
                              // Tap handler to trigger the overlay naming prompt
                              ElevatedButton(
                                onPressed: () => _handleFaceLabeling(context, ref, yoloState, face),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppConstants.accent,
                                  minimumSize: const Size.fromHeight(32),
                                  padding: EdgeInsets.zero,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                                child: const Text('Identify', style: TextStyle(color: Colors.white, fontSize: 11.5)),
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
  }

  /// Extracts the face bounding box dynamically from raw media buffers.
  /// Shifts coordinate bounds based on FittedBox alignments.
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

  /// Launch face annotation dialog context safely.
  /// Reads providers synchronously before pushing dialog scopes to safeguard against
  /// unmounted context execution errors.
  void _handleFaceLabeling(
    BuildContext context,
    WidgetRef ref,
    YoloFaceState yoloState,
    DetectedFace face,
  ) {
    final galleryState = ref.read(galleryProvider);
    final mediaItem = galleryState.items.firstWhere((i) => i.id == face.mediaItemId);
    final parentSha256 = mediaItem.sha256;

    FaceLabelingDialog.show(context, face, parentSha256);
  }
}
