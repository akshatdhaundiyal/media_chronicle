import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_constants.dart';
import '../../providers/settings_provider.dart';
import '../../../gallery/providers/yolo_face_provider.dart';

class YoloConfigCard extends ConsumerWidget {
  const YoloConfigCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final yoloState = ref.watch(yoloFaceProvider);
    final settingsProv = ref.watch(settingsProvider);

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
              Icon(Icons.face_outlined, color: AppConstants.secondary),
              SizedBox(width: 8),
              Text(
                'YOLO v8 Production Classifier (best.pt)',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppConstants.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Simulate whether the custom-trained production edge weights (best.tflite / best.pt) are successfully loaded into active application memory.',
            style: TextStyle(fontSize: 12, color: AppConstants.textSecondary),
          ),
          const SizedBox(height: 16),
          SwitchListTile(
            title: const Text('Edge Weights Loaded', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
            subtitle: Text(
              yoloState.isYoloAvailable 
                  ? 'Processor active - Bounding box overlays online'
                  : 'Processor offline - Face identification paused',
              style: const TextStyle(fontSize: 11, color: AppConstants.textMuted),
            ),
            value: yoloState.isYoloAvailable,
            activeThumbColor: AppConstants.secondary,
            contentPadding: EdgeInsets.zero,
            onChanged: (val) => ref.read(yoloFaceProvider.notifier).setYoloAvailable(val),
          ),
          const Divider(),
          SwitchListTile(
            title: const Text('Independent YOLO Processing', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
            subtitle: const Text(
              'Process face detection immediately on image pick, without waiting for VLM auto-tagging to complete.',
              style: TextStyle(fontSize: 11, color: AppConstants.textMuted),
            ),
            value: settingsProv.yoloIndependent,
            activeThumbColor: AppConstants.secondary,
            contentPadding: EdgeInsets.zero,
            onChanged: (val) => ref.read(settingsProvider.notifier).toggleYoloIndependent(val),
          ),
        ],
      ),
    );
  }
}
