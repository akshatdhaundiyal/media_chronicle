class DetectedFace {
  final String id;
  final String mediaItemId;
  final String? mediaItemSha256;
  
  // Bounding box as relative coordinates (percentage 0.0 - 1.0 of parent container)
  final double x;
  final double y;
  final double width;
  final double height;
  
  final String? name;
  final List<double> embedding; // Representing extracted vector features from YOLO layer
  final bool isIdentified;
  final String? ageVariant; // Dynamic age tier of the face (e.g. childhood, teenage, adult)

  DetectedFace({
    required this.id,
    required this.mediaItemId,
    this.mediaItemSha256,
    required this.x,
    required this.y,
    required this.width,
    required this.height,
    this.name,
    required List<double> embedding,
    this.isIdentified = false,
    this.ageVariant,
  }) : embedding = List.unmodifiable(embedding);

  DetectedFace copyWith({
    String? name,
    bool? isIdentified,
    String? ageVariant,
    List<double>? embedding,
  }) {
    return DetectedFace(
      id: id,
      mediaItemId: mediaItemId,
      mediaItemSha256: mediaItemSha256,
      x: x,
      y: y,
      width: width,
      height: height,
      name: name ?? this.name,
      embedding: embedding ?? this.embedding,
      isIdentified: isIdentified ?? this.isIdentified,
      ageVariant: ageVariant ?? this.ageVariant,
    );
  }
}
