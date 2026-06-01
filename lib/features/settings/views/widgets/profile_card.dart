import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_constants.dart';
import '../../providers/settings_provider.dart';

class ProfileCard extends StatelessWidget {
  const ProfileCard({super.key});

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
                const Text(
                  'Paragraph Chronicle Host',
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
              final controller = TextEditingController(text: provider.username);
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
                      onPressed: () {
                        controller.dispose();
                        Navigator.pop(dialogCtx);
                      },
                      child: const Text('Cancel', style: TextStyle(color: AppConstants.textSecondary)),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        provider.updateUsername(controller.text);
                        controller.dispose();
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
}
