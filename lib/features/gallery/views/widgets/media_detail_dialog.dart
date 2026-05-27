import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_constants.dart';
import '../../models/media_item.dart';
import '../../providers/yolo_face_provider.dart';
import 'face_labeling_dialog.dart';

class MediaDetailDialog extends StatelessWidget {
  final MediaItem item;

  const MediaDetailDialog({
    super.key,
    required this.item,
  });

  static void show(BuildContext context, MediaItem item) {
    showDialog(
      context: context,
      builder: (context) => MediaDetailDialog(item: item),
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
        constraints: const BoxConstraints(maxWidth: 800, maxHeight: 600),
        clipBehavior: Clip.antiAlias,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final boxWidth = constraints.maxWidth;
                  final boxHeight = constraints.maxHeight;

                  return Stack(
                    alignment: Alignment.center,
                    children: [
                      Positioned.fill(
                        child: item.isLocal
                            ? Image.memory(item.bytes!, fit: BoxFit.contain)
                            : Image.network(item.url!, fit: BoxFit.contain),
                      ),
                      
                      // Dimming layer for aesthetic face detection effect
                      Positioned.fill(
                        child: Container(
                          color: Colors.black.withValues(alpha: 0.25),
                        ),
                      ),

                      // Face Bounding Box Overlays
                      Consumer<YoloFaceProvider>(
                        builder: (context, yoloFaceProv, child) {
                          final faces = yoloFaceProv.getFacesForMediaItem(item.id);

                          return Stack(
                            children: faces.map((face) {
                              final left = face.x * boxWidth;
                              final top = face.y * boxHeight;
                              final width = face.width * boxWidth;
                              final height = face.height * boxHeight;

                              final isIdentified = face.isIdentified;
                              final borderAccentColor = isIdentified
                                  ? AppConstants.accent // Cyan
                                  : AppConstants.secondary; // Pink

                              return Positioned(
                                left: left,
                                top: top,
                                width: width,
                                height: height,
                                child: GestureDetector(
                                  onTap: () {
                                    FaceLabelingDialog.show(context, face, item.sha256);
                                  },
                                  child: Container(
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                        color: borderAccentColor,
                                        width: 2.5,
                                      ),
                                      borderRadius: BorderRadius.circular(8),
                                      boxShadow: [
                                        BoxShadow(
                                          color: borderAccentColor.withValues(alpha: 0.3),
                                          blurRadius: 8,
                                          spreadRadius: 1,
                                        ),
                                      ],
                                    ),
                                    child: Stack(
                                      clipBehavior: Clip.none,
                                      children: [
                                        Positioned(
                                          top: -24,
                                          left: -2,
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                            decoration: BoxDecoration(
                                              color: borderAccentColor,
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(
                                                  isIdentified ? Icons.face : Icons.help_outline,
                                                  size: 10,
                                                  color: Colors.white,
                                                ),
                                                const SizedBox(width: 4),
                                                Text(
                                                  isIdentified
                                                      ? '${face.name} (${face.ageVariant ?? 'Verified'})'
                                                      : 'Unrecognized - Tap to label',
                                                  style: const TextStyle(
                                                    fontSize: 9.5,
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.white,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          );
                        },
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
                    ],
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppConstants.paddingLarge),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              item.title,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            if (item.shortDescription != null) ...[
                              const SizedBox(height: 4),
                              Text(
                                item.shortDescription!,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: AppConstants.accent,
                                ),
                              ),
                            ],
                            const SizedBox(height: 4),
                            Text(
                              'SHA-256 HASH: ${item.sha256}',
                              style: const TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 10,
                                color: AppConstants.textMuted,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Recorded on ${item.date.toLocal()}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppConstants.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        item.type.toUpperCase(),
                        style: const TextStyle(
                          color: AppConstants.accent,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ],
                  ),
                  if (item.longDescription != null) ...[
                    const SizedBox(height: 14),
                    const Text(
                      'SCENE DETAIL & COMPOSITION NARRATIVE',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: AppConstants.textMuted,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      item.longDescription!,
                      style: const TextStyle(
                        fontSize: 12,
                        height: 1.5,
                        color: AppConstants.textSecondary,
                      ),
                    ),
                  ],
                  if (item.tags.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: item.tags.map((tag) {
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.white10,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.white12),
                          ),
                          child: Text(
                            '# $tag',
                            style: const TextStyle(fontSize: 10, color: AppConstants.textSecondary),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                  if (item.face != null) ...[
                    const SizedBox(height: 16),
                    const Text(
                      'AI VLM ANALYTICAL DESCRIPTORS',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: AppConstants.textMuted,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _buildDetailChip(Icons.face_unlock_outlined, 'Face: ${item.face}', AppConstants.primary),
                        _buildDetailChip(Icons.location_on_outlined, 'Place: ${item.place}', AppConstants.accent),
                        _buildDetailChip(Icons.wb_sunny_outlined, 'Time: ${item.dateClue}', AppConstants.secondary),
                        _buildDetailChip(Icons.folder_open_outlined, 'Group: ${item.group}', Colors.greenAccent),
                      ],
                    ),
                  ],
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildDetailChip(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              fontSize: 11,
              color: color.withValues(alpha: 0.9),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
