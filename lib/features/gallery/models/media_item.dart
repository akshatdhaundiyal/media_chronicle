import 'dart:typed_data';
import 'dart:convert';
import 'package:crypto/crypto.dart' as crypto;
import 'detected_face.dart';

class MediaItem {
  final String id;
  final String? url;            // Network URL (for mock assets)
  final Uint8List? bytes;      // Bytes (for local uploads / freshly picked files)
  final String title;
  final String type;           // 'image' or 'video'
  final DateTime date;

  // Local Vision LLM metadata
  final String? face;
  final String? place;
  final String? dateClue;
  final String? group;
  final bool isAnalyzing;

  // Enriched Descriptions & Hash ID
  final String sha256;
  final String? shortDescription;
  final String? longDescription;
  final List<String> tags;

  // YOLO Detected Faces
  final List<DetectedFace> detectedFaces;

  MediaItem({
    required this.id,
    this.url,
    this.bytes,
    required this.title,
    required this.type,
    required this.date,
    this.face,
    this.place,
    this.dateClue,
    this.group,
    this.isAnalyzing = false,
    String? sha256,
    this.shortDescription,
    this.longDescription,
    this.tags = const [],
    this.detectedFaces = const [],
  }) : sha256 = sha256 ?? _calculateSha256(id, title, url, bytes);

  static String _calculateSha256(String id, String title, String? url, Uint8List? bytes) {
    if (bytes != null && bytes.isNotEmpty) {
      return crypto.sha256.convert(bytes).toString();
    } else {
      return crypto.sha256.convert(utf8.encode(title + (url ?? ''))).toString();
    }
  }

  bool get isLocal => bytes != null;

  MediaItem copyWith({
    String? id,
    String? url,
    Uint8List? bytes,
    String? title,
    String? type,
    DateTime? date,
    String? face,
    String? place,
    String? dateClue,
    String? group,
    bool? isAnalyzing,
    String? sha256,
    String? shortDescription,
    String? longDescription,
    List<String>? tags,
    List<DetectedFace>? detectedFaces,
  }) {
    return MediaItem(
      id: id ?? this.id,
      url: url ?? this.url,
      bytes: bytes ?? this.bytes,
      title: title ?? this.title,
      type: type ?? this.type,
      date: date ?? this.date,
      face: face ?? this.face,
      place: place ?? this.place,
      dateClue: dateClue ?? this.dateClue,
      group: group ?? this.group,
      isAnalyzing: isAnalyzing ?? this.isAnalyzing,
      sha256: sha256 ?? this.sha256,
      shortDescription: shortDescription ?? this.shortDescription,
      longDescription: longDescription ?? this.longDescription,
      tags: tags ?? this.tags,
      detectedFaces: detectedFaces ?? this.detectedFaces,
    );
  }
}
