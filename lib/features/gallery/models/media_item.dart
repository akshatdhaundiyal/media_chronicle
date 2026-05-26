import 'dart:typed_data';

class MediaItem {
  final String id;
  final String? url;            // Network URL (for mock assets)
  final Uint8List? bytes;      // Bytes (for local uploads / freshly picked files)
  final String title;
  final String type;           // 'image' or 'video'
  final DateTime date;

  MediaItem({
    required this.id,
    this.url,
    this.bytes,
    required this.title,
    required this.type,
    required this.date,
  });

  bool get isLocal => bytes != null;
}
