import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
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
            'Choose whether to browse your local device files or simulate a camera capture upload for UI testing.',
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
            Navigator.pop(context);
            await MediaHelper.pickMockMedia();
            final newItem = MediaItem(
              id: DateTime.now().millisecondsSinceEpoch.toString(),
              title: 'Simulated Shot',
              url: 'https://images.unsplash.com/photo-1542291026-7eec264c27ff?q=80&w=600&auto=format&fit=crop',
              type: 'image',
              date: DateTime.now(),
            );
            if (context.mounted) {
              String? preIdentifiedFaces;
              if (!settings.yoloIndependent) {
                final faces = context.read<YoloFaceProvider>().runYoloDetection(
                  newItem,
                  onError: (err) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(err),
                          backgroundColor: Colors.redAccent,
                        ),
                      );
                    }
                  },
                );
                if (faces.isNotEmpty) {
                  preIdentifiedFaces = faces
                      .map((f) => f.name ?? (f.isIdentified ? 'John' : 'an unidentified person'))
                      .join(', ');
                }
              } else {
                context.read<YoloFaceProvider>().runYoloDetection(
                  newItem,
                  onError: (err) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(err),
                          backgroundColor: Colors.redAccent,
                        ),
                      );
                    }
                  },
                );
              }
              context.read<GalleryProvider>().addMediaItem(
                newItem,
                ollamaUrl: settings.ollamaUrl,
                ollamaModel: settings.ollamaModel,
                autoTag: settings.autoTagEnabled,
                preIdentifiedFaces: preIdentifiedFaces,
                onAnalyzeComplete: (item) {
                  // YOLO already ran, do nothing
                },
                onAnalyzeError: (err) {
                  if (context.mounted) {
                    _showVlmOfflineDialog(context, err);
                  }
                },
              );
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Simulated shot added to Gallery!')),
              );
            }
          },
          child: const Text('Simulate Capture', style: TextStyle(color: AppConstants.accent)),
        ),
        ElevatedButton(
          onPressed: () async {
            Navigator.pop(context);
            final results = await MediaHelper.pickMultipleFiles(type: FileType.image);
            if (results.isNotEmpty) {
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
                  if (context.mounted) {
                    String? preIdentifiedFaces;
                    if (!settings.yoloIndependent) {
                      final faces = context.read<YoloFaceProvider>().runYoloDetection(
                        newItem,
                        onError: (err) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(err),
                                backgroundColor: Colors.redAccent,
                              ),
                            );
                          }
                        },
                      );
                      if (faces.isNotEmpty) {
                        preIdentifiedFaces = faces
                            .map((f) => f.name ?? (f.isIdentified ? 'John' : 'an unidentified person'))
                            .join(', ');
                      }
                    } else {
                      context.read<YoloFaceProvider>().runYoloDetection(
                        newItem,
                        onError: (err) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(err),
                                backgroundColor: Colors.redAccent,
                              ),
                            );
                          }
                        },
                      );
                    }
                    context.read<GalleryProvider>().addMediaItem(
                      newItem,
                      ollamaUrl: settings.ollamaUrl,
                      ollamaModel: settings.ollamaModel,
                      autoTag: settings.autoTagEnabled,
                      preIdentifiedFaces: preIdentifiedFaces,
                      onAnalyzeComplete: (item) {
                        // YOLO already ran, do nothing
                      },
                      onAnalyzeError: (err) {
                        if (context.mounted) {
                          _showVlmOfflineDialog(context, err);
                        }
                      },
                    );
                  }
                }
              }
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Imported ${results.length} files successfully!')),
                );
              }
            }
          },
          style: ElevatedButton.styleFrom(backgroundColor: AppConstants.primary),
          child: const Text('Browse Files', style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }

  void _showVlmOfflineDialog(BuildContext context, String errorMessage) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: AppConstants.dialogBg,
        title: Row(
          children: const [
            Icon(Icons.warning_amber_rounded, color: Colors.redAccent),
            SizedBox(width: 8),
            Text('VLM Model Offline'),
          ],
        ),
        content: Text(
          errorMessage,
          style: const TextStyle(color: Colors.white, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            style: TextButton.styleFrom(foregroundColor: AppConstants.accent),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
