class SavedCollection {
  const SavedCollection({
    required this.id,
    required this.name,
    required this.createdAt,
    this.savedItemIds = const [],
  });

  final String id;
  final String name;
  final DateTime createdAt;
  final List<String> savedItemIds;

  Map<String, Object?> toJson() => {
    'id': id,
    'name': name,
    'createdAt': createdAt.toIso8601String(),
    'savedItemIds': savedItemIds,
  };

  factory SavedCollection.fromJson(Map<String, Object?> json) {
    return SavedCollection(
      id: json['id']! as String,
      name: json['name']! as String,
      createdAt: DateTime.parse(json['createdAt']! as String),
      savedItemIds: (json['savedItemIds'] as List<Object?>? ?? const [])
          .cast<String>(),
    );
  }
}
