import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_constants.dart';
import '../models/detected_face.dart';
import '../models/media_item.dart';
import '../providers/gallery_provider.dart';
import '../providers/yolo_face_provider.dart';
import 'widgets/face_labeling_dialog.dart';

class YoloFaceScreen extends StatefulWidget {
  const YoloFaceScreen({super.key});

  @override
  State<YoloFaceScreen> createState() => _YoloFaceScreenState();
}

class _YoloFaceScreenState extends State<YoloFaceScreen> {
  final ScrollController _terminalScrollController = ScrollController();
  DetectedFace? _selectedEmbeddingFace;

  @override
  void dispose() {
    _terminalScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final yoloProv = context.watch<YoloFaceProvider>();
    final galleryProv = context.watch<GalleryProvider>();

    // Autoscroll training logs terminal
    if (yoloProv.isTraining) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_terminalScrollController.hasClients) {
          _terminalScrollController.jumpTo(_terminalScrollController.position.maxScrollExtent);
        }
      });
    }

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.paddingLarge),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Page Title
            _buildPageHeader(yoloProv),
            const SizedBox(height: AppConstants.paddingLarge),

            // Top Panel: Metrics & Live Retraining Terminal
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 3,
                  child: _buildModelMetricsHUD(context, yoloProv),
                ),
                const SizedBox(width: AppConstants.paddingMedium),
                Expanded(
                  flex: 4,
                  child: _buildTerminalLogsConsole(context, yoloProv),
                ),
              ],
            ),
            const SizedBox(height: AppConstants.paddingLarge),

            // Middle Panel: Embeddings 2D Cluster Visualization
            _buildEmbeddingsClusterCard(context, yoloProv, galleryProv),
            const SizedBox(height: AppConstants.paddingLarge),

            // Bottom Panel: Labeled chronological variants & Unknown queue
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 4,
                  child: _buildChronologicalIdentitiesCard(context, yoloProv, galleryProv),
                ),
                const SizedBox(width: AppConstants.paddingMedium),
                Expanded(
                  flex: 3,
                  child: _buildUnidentifiedFacesQueueCard(context, yoloProv, galleryProv),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPageHeader(YoloFaceProvider yoloProv) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'YOLO Face Identification Hub',
              style: Theme.of(context).textTheme.displayMedium,
            ),
            const SizedBox(height: 4),
            const Text(
              'Online active learning, edge model retraining, and face variations cataloguing',
              style: TextStyle(color: AppConstants.textSecondary, fontSize: 13),
            ),
          ],
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: yoloProv.isTraining
                ? AppConstants.secondary.withValues(alpha: 0.15)
                : Colors.greenAccent.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: yoloProv.isTraining ? AppConstants.secondary : Colors.greenAccent,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: yoloProv.isTraining ? AppConstants.secondary : Colors.greenAccent,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                yoloProv.isTraining ? 'RETRAINING ACTIVE' : 'ENGINE ONLINE',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: yoloProv.isTraining ? AppConstants.secondary : Colors.greenAccent,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildModelMetricsHUD(BuildContext context, YoloFaceProvider yoloProv) {
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: const [
                  Icon(Icons.dashboard_customize_outlined, color: AppConstants.primary),
                  SizedBox(width: 8),
                  Text(
                    'Retraining Weights HUD',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.refresh, size: 18, color: AppConstants.textMuted),
                tooltip: 'Manually Reset Model Weights',
                onPressed: yoloProv.isTraining ? null : () => yoloProv.retrainModel(),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildMetricProgressBar('Model Map Accuracy', yoloProv.currentAccuracy, Colors.greenAccent),
          const SizedBox(height: 14),
          _buildMetricProgressBar('Fine-Tuning SGD Loss', yoloProv.currentLoss, AppConstants.secondary, inverse: true),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildMiniMetricCard('Enrolled Identities', '${yoloProv.enrolledNames.length} Labeled'),
              _buildMiniMetricCard('Epochs Trained', '${yoloProv.isTraining ? yoloProv.currentEpoch : 45} / 15'),
            ],
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: yoloProv.isTraining ? null : () => yoloProv.retrainModel(),
            icon: const Icon(Icons.model_training, size: 16),
            label: Text(yoloProv.isTraining ? 'Training Face Maps...' : 'Trigger Model Retrain'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppConstants.primary,
              foregroundColor: Colors.white,
              minimumSize: const Size.fromHeight(48),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricProgressBar(String title, double val, Color color, {bool inverse = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: const TextStyle(fontSize: 12, color: AppConstants.textSecondary)),
            Text(
              '${(val * 100).toStringAsFixed(1)}%',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: val.clamp(0.0, 1.0),
            minHeight: 5,
            backgroundColor: Colors.white10,
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }

  Widget _buildMiniMetricCard(String title, String val) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 11, color: AppConstants.textMuted)),
        const SizedBox(height: 4),
        Text(
          val,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
        ),
      ],
    );
  }

  Widget _buildTerminalLogsConsole(BuildContext context, YoloFaceProvider yoloProv) {
    return Container(
      height: 250,
      padding: const EdgeInsets.all(AppConstants.paddingMedium),
      decoration: BoxDecoration(
        color: AppConstants.terminalBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: const [
                  Icon(Icons.terminal_outlined, color: Colors.amberAccent, size: 14),
                  SizedBox(width: 8),
                  Text(
                    'Training Backpropagation Terminal',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppConstants.textSecondary, fontFamily: 'monospace'),
                  ),
                ],
              ),
              if (yoloProv.isTraining)
                const SizedBox(
                  width: 10,
                  height: 10,
                  child: CircularProgressIndicator(strokeWidth: 1.5, valueColor: AlwaysStoppedAnimation(Colors.amberAccent)),
                ),
            ],
          ),
          const Divider(color: Colors.white10),
          Expanded(
            child: ListView.builder(
              controller: _terminalScrollController,
              itemCount: yoloProv.trainingLogs.length,
              itemBuilder: (context, index) {
                final log = yoloProv.trainingLogs[index];
                Color textColor = AppConstants.textSecondary;
                if (log.contains('SUCCESS')) textColor = Colors.greenAccent;
                if (log.contains('completed') || log.contains('synced')) textColor = AppConstants.accent;
                if (log.contains('Epoch')) textColor = Colors.amberAccent;

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2.0),
                  child: Text(
                    log,
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 11.5,
                      color: textColor,
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

  Widget _buildEmbeddingsClusterCard(BuildContext context, YoloFaceProvider yoloProv, GalleryProvider galleryProv) {
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
                        // Dotted grid overlay
                        Positioned.fill(
                          child: GridPaper(
                            color: Colors.white.withValues(alpha: 0.02),
                            divisions: 2,
                            subdivisions: 1,
                            interval: 50,
                          ),
                        ),
                        
                        // Render cluster vector points
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final w = constraints.maxWidth;
                            final h = constraints.maxHeight;

                            return Stack(
                              children: [
                                // Cluster pathway lines for chronological developments
                                ...yoloProv.enrolledNames.map((name) {
                                  final faces = yoloProv.detectedFaces
                                      .where((f) => f.isIdentified && f.name == name)
                                      .toList();

                                  if (faces.length < 2) return const SizedBox.shrink();
                                  
                                  // Connect them chronologically by distance or order
                                  return CustomPaint(
                                    size: Size(w, h),
                                    painter: ClusterPathPainter(faces, w, h),
                                  );
                                }),

                                // Points
                                ...yoloProv.detectedFaces.map((face) {
                                  final double xVal = face.embedding[0];
                                  final double yVal = face.embedding[1];
                                  
                                  // Map from 0-100 coordinate space to pixel space
                                  final left = (xVal / 100.0) * w;
                                  final top = (yVal / 100.0) * h;

                                  final isSelected = _selectedEmbeddingFace?.id == face.id;
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
              Expanded(
                flex: 3,
                child: _buildSelectedEmbeddingPreview(yoloProv, galleryProv),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSelectedEmbeddingPreview(YoloFaceProvider yoloProv, GalleryProvider galleryProv) {
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
    final mediaItem = galleryProv.items.firstWhere((i) => i.id == face.mediaItemId);
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
          if (!face.isIdentified)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: ElevatedButton(
                onPressed: () => _handleFaceLabeling(context, yoloProv, face),
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

  Widget _buildChronologicalIdentitiesCard(BuildContext context, YoloFaceProvider yoloProv, GalleryProvider galleryProv) {
    final names = yoloProv.enrolledNames;

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
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: names.length,
                  itemBuilder: (context, idx) {
                    final name = names[idx];
                    final facesForName = yoloProv.detectedFaces
                        .where((f) => f.isIdentified && f.name == name)
                        .toList();

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (idx > 0) const Divider(height: 24, color: Colors.white10),
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
                                style: const TextStyle(fontSize: 9.5, color: AppConstants.accent, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                          height: 110,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            physics: const BouncingScrollPhysics(),
                            itemCount: facesForName.length,
                            itemBuilder: (context, fIdx) {
                              final face = facesForName[fIdx];
                              final mediaItem = galleryProv.items.firstWhere((i) => i.id == face.mediaItemId);

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
                                      _buildCroppedFaceWidget(mediaItem, face, size: 50),
                                      const SizedBox(height: 6),
                                      Text(
                                        face.ageVariant ?? 'Age Progression',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(fontSize: 10.5, color: AppConstants.textSecondary, fontWeight: FontWeight.w500),
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

  Widget _buildUnidentifiedFacesQueueCard(BuildContext context, YoloFaceProvider yoloProv, GalleryProvider galleryProv) {
    final unIdentified = yoloProv.unidentifiedFaces;

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
                      final mediaItem = galleryProv.items.firstWhere((i) => i.id == face.mediaItemId);

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
                              _buildCroppedFaceWidget(mediaItem, face, size: 64),
                              const SizedBox(height: 10),
                              const Text(
                                'Detected Face',
                                style: TextStyle(fontSize: 11.5, color: AppConstants.textSecondary, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Vector ID: ${face.id.substring(0, min(8, face.id.length))}',
                                style: const TextStyle(fontSize: 9.5, color: AppConstants.textMuted),
                              ),
                              const Spacer(),
                              ElevatedButton(
                                onPressed: () => _handleFaceLabeling(context, yoloProv, face),
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

  void _handleFaceLabeling(
    BuildContext context,
    YoloFaceProvider yoloFaceProv,
    DetectedFace face,
  ) {
    final galleryProv = context.read<GalleryProvider>();
    final mediaItem = galleryProv.items.firstWhere((i) => i.id == face.mediaItemId);
    final parentSha256 = mediaItem.sha256;

    FaceLabelingDialog.show(context, face, parentSha256);
  }
}

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
    
    // Sort faces chronologically or by embedding distance to draw path
    // For John/Sarah, sort by x embedding position
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

    // Draw dashed/dotted connection pathway representing face aging progression
    canvas.drawPath(path, paint);
  }

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
