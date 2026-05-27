import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';

class MediaPickResult {
  final String name;
  final String path;
  final Uint8List? bytes;
  final String type; // 'image', 'video', 'document'

  MediaPickResult({
    required this.name,
    required this.path,
    this.bytes,
    required this.type,
  });
}

class MediaHelper {
  static final ImagePicker _imagePicker = ImagePicker();

  /// Picks an image file using ImagePicker (highly optimized for mobile & web cameras)
  static Future<MediaPickResult?> pickImage({ImageSource source = ImageSource.gallery}) async {
    try {
      final XFile? file = await _imagePicker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (file != null) {
        final Uint8List bytes = await file.readAsBytes();
        return MediaPickResult(
          name: file.name,
          path: file.path,
          bytes: bytes,
          type: 'image',
        );
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
    }
    return null;
  }

  /// Picks arbitrary files (like images, videos, documents) using FilePicker
  static Future<MediaPickResult?> pickFile({
    FileType type = FileType.any,
    List<String>? allowedExtensions,
  }) async {
    try {
      final FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: type,
        allowedExtensions: allowedExtensions,
        withData: true, // Necessary on Web to read file bytes directly
      );

      if (result != null && result.files.isNotEmpty) {
        final PlatformFile file = result.files.first;
        
        String mediaType = 'document';
        final extension = file.extension?.toLowerCase() ?? '';
        if (['jpg', 'jpeg', 'png', 'gif', 'webp'].contains(extension)) {
          mediaType = 'image';
        } else if (['mp4', 'mov', 'avi', 'mkv'].contains(extension)) {
          mediaType = 'video';
        }

        return MediaPickResult(
          name: file.name,
          path: kIsWeb ? file.name : (file.path ?? file.name),
          bytes: file.bytes,
          type: mediaType,
        );
      }
    } catch (e) {
      debugPrint('Error picking file: $e');
    }
    return null;
  }

  /// Picks multiple files at once (great for importing entire folders of assets)
  static Future<List<MediaPickResult>> pickMultipleFiles({
    FileType type = FileType.any,
    List<String>? allowedExtensions,
  }) async {
    try {
      final FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: type,
        allowedExtensions: allowedExtensions,
        allowMultiple: true,
        withData: true, // Necessary on Web to read file bytes directly
      );

      if (result != null && result.files.isNotEmpty) {
        final List<MediaPickResult> pickedList = [];
        for (final file in result.files) {
          if (file.bytes != null) {
            String mediaType = 'document';
            final extension = file.extension?.toLowerCase() ?? '';
            if (['jpg', 'jpeg', 'png', 'gif', 'webp'].contains(extension)) {
              mediaType = 'image';
            } else if (['mp4', 'mov', 'avi', 'mkv'].contains(extension)) {
              mediaType = 'video';
            }

            pickedList.add(MediaPickResult(
              name: file.name,
              path: kIsWeb ? file.name : (file.path ?? file.name),
              bytes: file.bytes,
              type: mediaType,
            ));
          }
        }
        return pickedList;
      }
    } catch (e) {
      debugPrint('Error picking multiple files: $e');
    }
    return [];
  }

  /// Helper to trigger a simulated media pick for quick UI testing or when browser APIs are constrained
  static Future<MediaPickResult> pickMockMedia() async {
    await Future.delayed(const Duration(milliseconds: 600));
    final randomId = DateTime.now().millisecondsSinceEpoch % 1000;
    
    return MediaPickResult(
      name: 'simulated_capture_$randomId.jpg',
      path: 'virtual_assets/simulated_capture_$randomId.jpg',
      type: 'image',
      bytes: Uint8List(0),
    );
  }

  static IconData getGroupIcon(String category) {
    switch (category) {
      case 'Nature':
        return Icons.landscape;
      case 'Urban':
        return Icons.location_city;
      case 'People':
        return Icons.group;
      case 'Events':
        return Icons.celebration;
      case 'Objects':
        return Icons.category;
      default:
        return Icons.folder;
    }
  }
}
