import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:media_chronicle/core/constants/app_constants.dart';
import 'package:media_chronicle/features/settings/providers/settings_provider.dart';

class StorageCard extends ConsumerWidget {
  const StorageCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = ref.watch(settingsProvider);

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
                  Icon(Icons.cloud_queue, color: AppConstants.accent),
                  SizedBox(width: 8),
                  Text(
                    'Workspace Cloud Quota',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppConstants.textPrimary,
                    ),
                  ),
                ],
              ),
              Text(
                provider.storageLimit,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppConstants.accent,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppConstants.paddingMedium),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: provider.storageUsedGB / provider.storageTotalGB,
              minHeight: 8,
              backgroundColor: Colors.white10,
              valueColor: const AlwaysStoppedAnimation<Color>(AppConstants.accent),
            ),
          ),
          const SizedBox(height: AppConstants.paddingMedium),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Automatic sync active',
                style: TextStyle(fontSize: 12, color: AppConstants.textMuted),
              ),
              TextButton(
                onPressed: () {
                  ref.read(settingsProvider.notifier).simulateStorageIncrease(100);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Synchronized cloud database space!')),
                  );
                },
                child: const Text('Sync Now', style: TextStyle(color: AppConstants.accent)),
              )
            ],
          ),
        ],
      ),
    );
  }
}
