import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/utils/media_helper.dart';
import '../../models/media_item.dart';
import '../../providers/gallery_provider.dart';
import '../../providers/yolo_face_provider.dart';
import '../../../settings/providers/settings_provider.dart';

class MediaUploadDialog extends StatelessWidget {
  const MediaUploadDialog({super.key});

  static void show(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const MediaUploadDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.read<SettingsProvider>();

    return AlertDialog(
      backgroundColor: AppConstants.dialogBg,
      title: Row(
        children: const [
          Icon(Icons.add_to_photos_outlined, color: AppConstants.accent),
          SizedBox(width: 8),
          Text('Add Media Asset'),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Capture a new image using your system camera or browse your local files to import memories into the archive.',
            style: TextStyle(color: AppConstants.textSecondary, fontSize: 13),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.black12,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppConstants.cardStroke),
            ),
            child: Row(
              children: [
                const Icon(Icons.psychology, size: 16, color: AppConstants.accent),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    settings.autoTagEnabled
                        ? 'Gemma 4 VLM Autotag active (${settings.ollamaModel})'
                        : 'VLM Auto-Tagging Disabled',
                    style: const TextStyle(fontSize: 11, color: AppConstants.textSecondary),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel', style: TextStyle(color: AppConstants.textSecondary)),
        ),
        TextButton(
          onPressed: () async {
            final galleryProv = Provider.of<GalleryProvider>(context, listen: false);
            final yoloProv = Provider.of<YoloFaceProvider>(context, listen: false);
            final settingsProv = Provider.of<SettingsProvider>(context, listen: false);
            final messenger = ScaffoldMessenger.of(context);
            final navigator = Navigator.of(context);

            final result = await MediaHelper.pickImage(source: ImageSource.camera);
            if (result != null && result.bytes != null) {
              navigator.pop();
              final newItem = MediaItem(
                id: DateTime.now().millisecondsSinceEpoch.toString(),
                bytes: result.bytes,
                title: result.name,
                type: result.type,
                date: DateTime.now(),
              );

              String? preIdentifiedFaces;
              if (!settingsProv.yoloIndependent) {
                final faces = yoloProv.runYoloDetection(
                  newItem,
                  onError: (err) {
                    messenger.showSnackBar(
                      SnackBar(
                        content: Text(err),
                        backgroundColor: Colors.redAccent,
                      ),
                    );
                  },
                );
                if (faces.isNotEmpty) {
                  preIdentifiedFaces = faces
                      .map((f) => f.name ?? (f.isIdentified ? 'John' : 'an unidentified person'))
                      .join(', ');
                }
              } else {
                yoloProv.runYoloDetection(
                  newItem,
                  onError: (err) {
                    messenger.showSnackBar(
                      SnackBar(
                        content: Text(err),
                        backgroundColor: Colors.redAccent,
                      ),
                    );
                  },
                );
              }
              galleryProv.addMediaItem(
                newItem,
                ollamaUrl: settingsProv.ollamaUrl,
                ollamaModel: settingsProv.ollamaModel,
                autoTag: settingsProv.autoTagEnabled,
                preIdentifiedFaces: preIdentifiedFaces,
                onAnalyzeComplete: (item) {
                  // YOLO already ran, do nothing
                },
                onAnalyzeError: (err) {
                  messenger.showSnackBar(
                    SnackBar(
                      content: Text(err),
                      backgroundColor: Colors.orangeAccent,
                      duration: const Duration(seconds: 5),
                    ),
                  );
                },
              );
              messenger.showSnackBar(
                const SnackBar(content: Text('Camera snapshot added to Gallery!')),
              );
            }
          },
          child: const Text('Use Camera', style: TextStyle(color: AppConstants.accent)),
        ),
        ElevatedButton(
          onPressed: () async {
            final galleryProv = Provider.of<GalleryProvider>(context, listen: false);
            final yoloProv = Provider.of<YoloFaceProvider>(context, listen: false);
            final settingsProv = Provider.of<SettingsProvider>(context, listen: false);
            final messenger = ScaffoldMessenger.of(context);
            final navigator = Navigator.of(context);

            final results = await MediaHelper.pickMultipleFiles(type: FileType.image);
            if (results.isNotEmpty) {
              navigator.pop();
              int addedCount = 0;
              for (final result in results) {
                if (result.bytes != null) {
                  final newItem = MediaItem(
                    id: '${DateTime.now().millisecondsSinceEpoch}_${addedCount++}',
                    bytes: result.bytes,
                    title: result.name,
                    type: result.type,
                    date: DateTime.now(),
                  );
                  String? preIdentifiedFaces;
                  if (!settingsProv.yoloIndependent) {
                    final faces = yoloProv.runYoloDetection(
                      newItem,
                      onError: (err) {
                        messenger.showSnackBar(
                          SnackBar(
                            content: Text(err),
                            backgroundColor: Colors.redAccent,
                          ),
                        );
                      },
                    );
                    if (faces.isNotEmpty) {
                      preIdentifiedFaces = faces
                          .map((f) => f.name ?? (f.isIdentified ? 'John' : 'an unidentified person'))
                          .join(', ');
                    }
                  } else {
                    yoloProv.runYoloDetection(
                      newItem,
                      onError: (err) {
                        messenger.showSnackBar(
                          SnackBar(
                            content: Text(err),
                            backgroundColor: Colors.redAccent,
                          ),
                        );
                      },
                    );
                  }
                  galleryProv.addMediaItem(
                    newItem,
                    ollamaUrl: settingsProv.ollamaUrl,
                    ollamaModel: settingsProv.ollamaModel,
                    autoTag: settingsProv.autoTagEnabled,
                    preIdentifiedFaces: preIdentifiedFaces,
                    onAnalyzeComplete: (item) {
                      // YOLO already ran, do nothing
                    },
                    onAnalyzeError: (err) {
                      messenger.showSnackBar(
                        SnackBar(
                          content: Text(err),
                          backgroundColor: Colors.orangeAccent,
                          duration: const Duration(seconds: 5),
                        ),
                      );
                    },
                  );
                }
              }
              messenger.showSnackBar(
                SnackBar(content: Text('Imported ${results.length} files successfully!')),
              );
            } else {
              messenger.showSnackBar(
                const SnackBar(
                  content: Text('Import failed: No files selected or files could not be read.'),
                  backgroundColor: Colors.orangeAccent,
                ),
              );
            }
          },
          style: ElevatedButton.styleFrom(backgroundColor: AppConstants.primary),
          child: const Text('Browse Files', style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }
}
