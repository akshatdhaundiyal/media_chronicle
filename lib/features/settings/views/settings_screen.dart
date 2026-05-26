import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_constants.dart';
import '../providers/settings_provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settingsProv = context.watch<SettingsProvider>();

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
              children: [
                _buildProfileCard(context, settingsProv),
                const SizedBox(height: AppConstants.paddingLarge),
                _buildStorageCard(context, settingsProv),
                const SizedBox(height: AppConstants.paddingLarge),
                _buildToggleCard(context, settingsProv),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildProfileCard(BuildContext context, SettingsProvider provider) {
    final controller = TextEditingController(text: provider.username);
    
    return Container(
      padding: const EdgeInsets.all(AppConstants.paddingLarge),
      decoration: BoxDecoration(
        color: AppConstants.cardBg,
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        border: Border.all(color: AppConstants.cardStroke),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 36,
            backgroundImage: NetworkImage(provider.profileImage),
          ),
          const SizedBox(width: AppConstants.paddingLarge),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Chronicle Host',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppConstants.accent,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  provider.username,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppConstants.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Active Local Session',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppConstants.textMuted,
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () {
              showDialog(
                context: context,
                builder: (dialogCtx) => AlertDialog(
                  backgroundColor: const Color(0xFF1E1E38),
                  title: const Text('Update Host Profile'),
                  content: TextField(
                    controller: controller,
                    decoration: const InputDecoration(labelText: 'Display Name'),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(dialogCtx),
                      child: const Text('Cancel', style: TextStyle(color: AppConstants.textSecondary)),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        provider.updateUsername(controller.text);
                        Navigator.pop(dialogCtx);
                      },
                      style: ElevatedButton.styleFrom(backgroundColor: AppConstants.accent),
                      child: const Text('Save', style: TextStyle(color: Colors.white)),
                    ),
                  ],
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white10,
              foregroundColor: AppConstants.textPrimary,
              elevation: 0,
            ),
            child: const Text('Edit Name'),
          ),
        ],
      ),
    );
  }

  Widget _buildStorageCard(BuildContext context, SettingsProvider provider) {
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
            child: const LinearProgressIndicator(
              value: 2.4 / 15.0,
              minHeight: 8,
              backgroundColor: Colors.white10,
              valueColor: AlwaysStoppedAnimation<Color>(AppConstants.accent),
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
                  provider.simulateStorageIncrease(100);
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

  Widget _buildToggleCard(BuildContext context, SettingsProvider provider) {
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
            onChanged: (val) => provider.toggleDarkMode(val),
          ),
          const Divider(),
          SwitchListTile(
            title: const Text('Enable System Audio/Notifiers'),
            subtitle: const Text('Send audio confirmations on media pick/scaffold'),
            value: provider.enableNotifications,
            activeThumbColor: AppConstants.primary,
            onChanged: (val) => provider.toggleNotifications(val),
          ),
          const Divider(),
          ListTile(
            title: const Text('Preferred Layout'),
            subtitle: const Text('Toggle default media presentation'),
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
