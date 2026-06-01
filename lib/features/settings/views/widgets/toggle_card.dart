import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_constants.dart';
import '../../providers/settings_provider.dart';

class ToggleCard extends StatelessWidget {
  const ToggleCard({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SettingsProvider>();

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
          const Text(
            'General Switches',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppConstants.textPrimary,
            ),
          ),
          const SizedBox(height: AppConstants.paddingSmall),
          SwitchListTile(
            title: const Text('Vibrant Dark Aesthetics'),
            subtitle: const Text('Toggle high-contrast premium twilight styles'),
            value: provider.darkMode,
            activeThumbColor: AppConstants.primary,
            contentPadding: EdgeInsets.zero,
            onChanged: (val) => provider.toggleDarkMode(val),
          ),
          const Divider(),
          SwitchListTile(
            title: const Text('Enable System Audio/Notifiers'),
            subtitle: const Text('Send audio confirmations on media pick/scaffold'),
            value: provider.enableNotifications,
            activeThumbColor: AppConstants.primary,
            contentPadding: EdgeInsets.zero,
            onChanged: (val) => provider.toggleNotifications(val),
          ),
          const Divider(),
          ListTile(
            title: const Text('Preferred Layout'),
            subtitle: const Text('Toggle default media presentation'),
            contentPadding: EdgeInsets.zero,
            trailing: IconButton(
              icon: Icon(
                provider.gridMode ? Icons.grid_view : Icons.view_list,
                color: AppConstants.primary,
              ),
              onPressed: () => provider.toggleLayoutMode(),
            ),
          )
        ],
      ),
    );
  }
}
