import 'dart:typed_data';
import '../../gallery/models/media_item.dart';

class StoryItem {
  final String id;
  final String title;
  final String description;
  final DateTime date;
  final String? coverUrl;
  final Uint8List? coverBytes;
  final List<MediaItem> mediaItems;

  StoryItem({
    required this.id,
    required this.title,
    required this.description,
    required this.date,
    this.coverUrl,
    this.coverBytes,
    this.mediaItems = const [],
  });

  bool get isLocal => coverBytes != null;
}
