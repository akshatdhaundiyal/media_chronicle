class Album {
  final String id;
  final String name;
  final List<String> itemIds; // Stores media item IDs associated with this folder

  Album({
    required this.id,
    required this.name,
    required this.itemIds,
  });

  Album copyWith({
    String? id,
    String? name,
    List<String>? itemIds,
  }) {
    return Album(
      id: id ?? this.id,
      name: name ?? this.name,
      itemIds: itemIds ?? this.itemIds,
    );
  }
}
