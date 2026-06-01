import 'package:flutter/material.dart';
import '../../../core/constants/app_constants.dart';
import 'widgets/profile_card.dart';
import 'widgets/llm_card.dart';
import 'widgets/yolo_config_card.dart';
import 'widgets/postgres_sync_card.dart';
import 'widgets/storage_card.dart';
import 'widgets/toggle_card.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppConstants.paddingLarge),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Control Center',
            style: Theme.of(context).textTheme.displayMedium,
          ),
          const SizedBox(height: 4),
          Text(
            'Adjust workspace variables and synchronize local storage archives',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: AppConstants.paddingExtraLarge),
          Expanded(
            child: ListView(
              physics: const BouncingScrollPhysics(),
              children: const [
                ProfileCard(),
                SizedBox(height: AppConstants.paddingLarge),
                LlmCard(),
                SizedBox(height: AppConstants.paddingLarge),
                YoloConfigCard(),
                SizedBox(height: AppConstants.paddingLarge),
                PostgresSyncCard(),
                SizedBox(height: AppConstants.paddingLarge),
                StorageCard(),
                SizedBox(height: AppConstants.paddingLarge),
                ToggleCard(),
              ],
            ),
          )
        ],
      ),
    );
  }
}
