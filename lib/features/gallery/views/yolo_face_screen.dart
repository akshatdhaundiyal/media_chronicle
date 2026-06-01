import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_constants.dart';
import '../providers/yolo_face_provider.dart';
import 'widgets/yolo/yolo_embeddings_map.dart';
import 'widgets/yolo/yolo_enrolled_timeline.dart';
import 'widgets/yolo/yolo_retraining_terminal.dart';
import 'widgets/yolo/yolo_unidentified_queue.dart';

class YoloFaceScreen extends StatelessWidget {
  const YoloFaceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final yoloProv = context.watch<YoloFaceProvider>();

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.paddingLarge),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Page Title
            _buildPageHeader(context, yoloProv),
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
                const Expanded(
                  flex: 4,
                  child: YoloRetrainingTerminal(),
                ),
              ],
            ),
            const SizedBox(height: AppConstants.paddingLarge),

            // Middle Panel: Embeddings 2D Cluster Visualization
            const YoloEmbeddingsMap(),
            const SizedBox(height: AppConstants.paddingLarge),

            // Bottom Panel: Labeled chronological variants & Unknown queue
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Expanded(
                  flex: 4,
                  child: YoloEnrolledTimeline(),
                ),
                SizedBox(width: AppConstants.paddingMedium),
                Expanded(
                  flex: 3,
                  child: YoloUnidentifiedQueue(),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPageHeader(BuildContext context, YoloFaceProvider yoloProv) {
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
}
