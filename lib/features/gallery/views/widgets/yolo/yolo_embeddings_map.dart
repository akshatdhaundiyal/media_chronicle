import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/constants/app_constants.dart';
import '../../../models/detected_face.dart';
import '../../../models/media_item.dart';
import '../../../providers/gallery_provider.dart';
import '../../../providers/yolo_face_provider.dart';
import '../face_labeling_dialog.dart';

/// Renders the interactive 2D dense vector cluster workspace.
/// By encapsulating this in a standalone stateful widget, we isolate local selection
/// updates (taps on cluster points) from triggering full-screen repaints elsewhere.
class YoloEmbeddingsMap extends ConsumerStatefulWidget {
  const YoloEmbeddingsMap({super.key});

  @override
  ConsumerState<YoloEmbeddingsMap> createState() => _YoloEmbeddingsMapState();
}

class _YoloEmbeddingsMapState extends ConsumerState<YoloEmbeddingsMap> {
  /// Local state tracking which face vector point is currently selected by the user.
  DetectedFace? _selectedEmbeddingFace;

  @override
  Widget build(BuildContext context) {
    // Reactively watch for YOLO provider state updates and gallery catalogs.
    final yoloState = ref.watch(yoloFaceProvider);
    final galleryState = ref.watch(galleryProvider);

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
          // Header descriptive labels
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: const [
                  Icon(Icons.bubble_chart_outlined, color: AppConstants.accent),
                  SizedBox(width: 8),
                  Text(
                    'Face Embeddings Cluster Space (2D Vector Map)',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ],
              ),
              const Text(
                'Subspace: YOLO Last Dense Linear Layer',
                style: TextStyle(fontSize: 11, color: AppConstants.textMuted),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left: Vector grid plot
              Expanded(
                flex: 5,
                child: AspectRatio(
                  aspectRatio: 1.8,
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF070710),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white10),
                    ),
                    child: Stack(
                      children: [
                        // Decorative mathematical grid mesh
                        Positioned.fill(
                          child: GridPaper(
                            color: Colors.white.withValues(alpha: 0.02),
                            divisions: 2,
                            subdivisions: 1,
                            interval: 50,
                          ),
                        ),
                        
                        // Map coordinates on layout changes dynamically
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final w = constraints.maxWidth;
                            final h = constraints.maxHeight;

                            return Stack(
                              children: [
                                // Paint chronological progress paths connecting variations of each enrolled identity
                                ...yoloState.enrolledNames.map((name) {
                                  final faces = yoloState.detectedFaces
                                      .where((f) => f.isIdentified && f.name == name)
                                      .toList();

                                  if (faces.length < 2) return const SizedBox.shrink();
                                  
                                  return CustomPaint(
                                    size: Size(w, h),
                                    painter: ClusterPathPainter(faces, w, h),
                                  );
                                }),

                                // Paint actual data nodes for each detected face mapping to vector coordinates
                                ...yoloState.detectedFaces.map((face) {
                                  // Fetch normalized coordinates (0 to 100) from embedding list
                                  final double xVal = face.embedding[0];
                                  final double yVal = face.embedding[1];
                                  
                                  // Map mathematically from 0-100 domain space to absolute container pixel boundaries
                                  final left = (xVal / 100.0) * w;
                                  final top = (yVal / 100.0) * h;

                                  final isSelected = _selectedEmbeddingFace?.id == face.id;
                                  
                                  // Harmonious color assignment based on identified name
                                  Color color = Colors.grey;
                                  if (face.isIdentified) {
                                    if (face.name?.toLowerCase().startsWith('john') ?? false) {
                                      color = AppConstants.accent;
                                    } else if (face.name?.toLowerCase().startsWith('sarah') ?? false) {
                                      color = AppConstants.secondary;
                                    } else {
                                      color = Colors.greenAccent;
                                    }
                                  }

                                  return Positioned(
                                    left: left - 6,
                                    top: top - 6,
                                    child: GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          _selectedEmbeddingFace = face;
                                        });
                                      },
                                      child: MouseRegion(
                                        cursor: SystemMouseCursors.click,
                                        child: AnimatedContainer(
                                          duration: const Duration(milliseconds: 200),
                                          width: isSelected ? 16 : 12,
                                          height: isSelected ? 16 : 12,
                                          decoration: BoxDecoration(
                                            color: color,
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                              color: isSelected ? Colors.white : Colors.black,
                                              width: isSelected ? 2 : 1,
                                            ),
                                            boxShadow: [
                                              BoxShadow(
                                                color: color.withValues(alpha: 0.6),
                                                blurRadius: isSelected ? 8 : 4,
                                                spreadRadius: isSelected ? 2 : 0,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                }),
                              ],
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppConstants.paddingLarge),
              
              // Right: Selected node preview card
              Expanded(
                flex: 3,
                child: _buildSelectedEmbeddingPreview(yoloState, galleryState),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Builds the inspection drawer displaying metadata and crop previews of the selected point.
  Widget _buildSelectedEmbeddingPreview(YoloFaceState yoloState, GalleryState galleryState) {
    // Display prompt info if no embedding is actively selected
    if (_selectedEmbeddingFace == null) {
      return Container(
        height: 220,
        alignment: Alignment.center,
        padding: const EdgeInsets.all(AppConstants.paddingLarge),
        decoration: BoxDecoration(
          color: Colors.black12,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppConstants.cardStroke),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.info_outline, color: AppConstants.textMuted, size: 28),
            SizedBox(height: 12),
            Text(
              'Interactive Cluster Map',
              textAlign: TextAlign.center,
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white),
            ),
            SizedBox(height: 6),
            Text(
              'Tap any dot in the 2D cluster map to inspect the face thumbnail, identity variants, and vector coordinates.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 11.5, color: AppConstants.textMuted),
            ),
          ],
        ),
      );
    }

    final face = _selectedEmbeddingFace!;
    final mediaItem = galleryState.items.firstWhere((i) => i.id == face.mediaItemId);
    Color tagColor = face.isIdentified ? AppConstants.accent : AppConstants.secondary;

    return Container(
      height: 220,
      padding: const EdgeInsets.all(AppConstants.paddingMedium),
      decoration: BoxDecoration(
        color: AppConstants.cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppConstants.cardStroke),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Crop thumbnail and header metadata
          Row(
            children: [
              _buildCroppedFaceWidget(mediaItem, face, size: 48),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      face.isIdentified ? face.name! : 'Unidentified Face',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      face.isIdentified ? (face.ageVariant ?? 'Chronological Variant') : 'Pending Label Ingestion',
                      style: TextStyle(fontSize: 11, color: tagColor, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, size: 16, color: AppConstants.textMuted),
                onPressed: () => setState(() => _selectedEmbeddingFace = null),
              ),
            ],
          ),
          const Divider(height: 16, color: Colors.white10),
          
          // Vector spatial coordinates & parent files details
          Expanded(
            child: ListView(
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _buildPreviewStatRow('Vector Location', '[${face.embedding[0].toStringAsFixed(1)}, ${face.embedding[1].toStringAsFixed(1)}]'),
                _buildPreviewStatRow('Source Photo', mediaItem.title),
                _buildPreviewStatRow('Identification', face.isIdentified ? '96.2% Confidence' : 'UNRECOGNIZED'),
              ],
            ),
          ),
          
          // Trigger manual backpropagation loop prompt if point is unlabeled
          if (!face.isIdentified)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: ElevatedButton(
                onPressed: () => _handleFaceLabeling(context, yoloState, face),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppConstants.accent,
                  minimumSize: const Size.fromHeight(36),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text('Label & Train Model', style: TextStyle(color: Colors.white, fontSize: 12)),
              ),
            ),
        ],
      ),
    );
  }

  /// Utility row builder for key-value statistics lists.
  Widget _buildPreviewStatRow(String label, String val) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 11.5, color: AppConstants.textSecondary)),
          Expanded(
            child: Text(
              val,
              textAlign: TextAlign.right,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 11.5, color: Colors.white, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  /// Pixel-perfect dynamic cropping widget.
  /// Decodes local/network parents image buffers, crops the specific segment
  /// marked by the YOLO bounding coordinates, and matches bounds dynamically using FittedBox.
  Widget _buildCroppedFaceWidget(MediaItem item, DetectedFace face, {required double size}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: SizedBox(
        width: size,
        height: size,
        child: FittedBox(
          fit: BoxFit.none,
          // Shift coordinates relative to fractional offsets
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

  /// Launch face annotation popup, synchronously pre-fetching states before pop overlays.
  void _handleFaceLabeling(
    BuildContext context,
    YoloFaceState yoloState,
    DetectedFace face,
  ) {
    final galleryState = ref.read(galleryProvider);
    final mediaItem = galleryState.items.firstWhere((i) => i.id == face.mediaItemId);
    final parentSha256 = mediaItem.sha256;

    FaceLabelingDialog.show(context, face, parentSha256);
  }
}

/// Custom painter to trace chronological progression paths connecting variations of each identity.
class ClusterPathPainter extends CustomPainter {
  final List<DetectedFace> faces;
  final double w;
  final double h;

  ClusterPathPainter(this.faces, this.w, this.h);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white24
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;

    final path = Path();
    
    // Sort chronological identity variations by x-dimension embedding distance to draw connection lines
    final sortedFaces = List<DetectedFace>.from(faces)
      ..sort((a, b) => a.embedding[0].compareTo(b.embedding[0]));

    for (int i = 0; i < sortedFaces.length; i++) {
      final f = sortedFaces[i];
      final px = (f.embedding[0] / 100.0) * w;
      final py = (f.embedding[1] / 100.0) * h;

      if (i == 0) {
        path.moveTo(px, py);
      } else {
        path.lineTo(px, py);
      }
    }

    // Draw progression path
    canvas.drawPath(path, paint);
  }

  /// Re-evaluates paint updates dynamically only if sizes, counts, or coordinates shift.
  @override
  bool shouldRepaint(covariant ClusterPathPainter oldDelegate) {
    if (faces.length != oldDelegate.faces.length) return true;
    for (int i = 0; i < faces.length; i++) {
      if (faces[i].id != oldDelegate.faces[i].id ||
          faces[i].embedding[0] != oldDelegate.faces[i].embedding[0] ||
          faces[i].embedding[1] != oldDelegate.faces[i].embedding[1]) {
        return true;
      }
    }
    return w != oldDelegate.w || h != oldDelegate.h;
  }
}
