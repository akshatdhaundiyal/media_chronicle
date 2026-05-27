import 'package:flutter/material.dart';
import '../../../../core/constants/app_constants.dart';
import '../../models/media_item.dart';

class GalleryToolbar extends StatelessWidget {
  final bool isSelectionMode;
  final Set<String> selectedItemIds;
  final List<MediaItem> filteredItems;
  final VoidCallback onSelectionModeCancel;
  final VoidCallback onSelectAll;
  final Function(String) onActionSelected;
  final VoidCallback onUploadPressed;
  final VoidCallback onSelectionModeStart;

  const GalleryToolbar({
    super.key,
    required this.isSelectionMode,
    required this.selectedItemIds,
    required this.filteredItems,
    required this.onSelectionModeCancel,
    required this.onSelectAll,
    required this.onActionSelected,
    required this.onUploadPressed,
    required this.onSelectionModeStart,
  });

  @override
  Widget build(BuildContext context) {
    if (isSelectionMode) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppConstants.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppConstants.primary.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.close, color: Colors.white),
              tooltip: 'Cancel Selection',
              onPressed: onSelectionModeCancel,
            ),
            const SizedBox(width: 8),
            Text(
              '${selectedItemIds.length} items selected',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppConstants.textPrimary,
              ),
            ),
            const Spacer(),
            IconButton(
              icon: Icon(
                selectedItemIds.length == filteredItems.length
                    ? Icons.deselect
                    : Icons.select_all,
                color: AppConstants.accent,
              ),
              tooltip: selectedItemIds.length == filteredItems.length
                  ? 'Deselect All'
                  : 'Select All',
              onPressed: onSelectAll,
            ),
            const SizedBox(width: 12),
            PopupMenuButton<String>(
              color: AppConstants.dialogBg,
              onSelected: onActionSelected,
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'move',
                  child: ListTile(
                    leading: Icon(Icons.drive_file_move_outlined, color: Colors.amberAccent, size: 18),
                    title: Text('Move to Folder', style: TextStyle(color: Colors.white, fontSize: 13)),
                  ),
                ),
                const PopupMenuItem(
                  value: 'copy',
                  child: ListTile(
                    leading: Icon(Icons.file_copy_outlined, color: Colors.blueAccent, size: 18),
                    title: Text('Copy to Folder', style: TextStyle(color: Colors.white, fontSize: 13)),
                  ),
                ),
                const PopupMenuItem(
                  value: 'rerun',
                  child: ListTile(
                    leading: Icon(Icons.auto_awesome, color: Colors.greenAccent, size: 18),
                    title: Text('Re-run VLM Analysis', style: TextStyle(color: Colors.white, fontSize: 13)),
                  ),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: ListTile(
                    leading: Icon(Icons.delete_outline, color: Colors.redAccent, size: 18),
                    title: Text('Delete Selected', style: TextStyle(color: Colors.white, fontSize: 13)),
                  ),
                ),
              ],
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  gradient: AppConstants.primaryGradient,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Text('Actions', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                    SizedBox(width: 4),
                    Icon(Icons.arrow_drop_down, color: Colors.white, size: 16),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Gallery Archive',
              style: Theme.of(context).textTheme.displayMedium,
            ),
            const SizedBox(height: 4),
            Text(
              '${filteredItems.length} media items catalogued',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
        Row(
          children: [
            if (filteredItems.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: TextButton.icon(
                  onPressed: onSelectionModeStart,
                  icon: const Icon(Icons.checklist, size: 16, color: AppConstants.accent),
                  label: const Text('Select Items', style: TextStyle(color: AppConstants.accent, fontSize: 13, fontWeight: FontWeight.bold)),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    side: const BorderSide(color: AppConstants.accent, width: 0.5),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),
            ElevatedButton.icon(
              onPressed: onUploadPressed,
              icon: const Icon(Icons.cloud_upload_outlined, size: 16),
              label: const Text('Upload Media', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                backgroundColor: AppConstants.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
