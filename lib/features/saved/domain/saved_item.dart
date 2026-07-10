enum SavedItemType { plan, place, route, quest }

extension SavedItemTypeLabel on SavedItemType {
  String get label => switch (this) {
    SavedItemType.plan => 'Plans',
    SavedItemType.place => 'Places',
    SavedItemType.route => 'Routes',
    SavedItemType.quest => 'Quests',
  };
}

enum SavedItemStatus { saved, inProgress }

extension SavedItemStatusLabel on SavedItemStatus {
  String get label => switch (this) {
    SavedItemStatus.saved => 'Saved',
    SavedItemStatus.inProgress => 'In Progress',
  };
}

enum SavedItemVisual { dateNight, weekendPlan, roadTrip, localQuest, place }

class SavedItem {
  const SavedItem({
    required this.id,
    required this.type,
    required this.categoryLabel,
    required this.title,
    required this.description,
    required this.savedAt,
    required this.status,
    required this.visual,
    this.imageAsset,
    this.destinationPath,
    this.progressCompleted,
    this.progressTotal,
    this.latitude,
    this.longitude,
    this.rating,
    this.address,
    this.openNow,
    this.googleMapsUri,
    this.websiteUri,
    this.phoneNumber,
  });

  final String id;
  final SavedItemType type;
  final String categoryLabel;
  final String title;
  final String description;
  final DateTime savedAt;
  final SavedItemStatus status;
  final SavedItemVisual visual;
  final String? imageAsset;
  final String? destinationPath;
  final int? progressCompleted;
  final int? progressTotal;
  final double? latitude;
  final double? longitude;
  final double? rating;
  final String? address;
  final bool? openNow;
  final String? googleMapsUri;
  final String? websiteUri;
  final String? phoneNumber;

  bool get hasLocation => latitude != null && longitude != null;

  double? get progress {
    final completed = progressCompleted;
    final total = progressTotal;
    if (completed == null || total == null || total <= 0) {
      return null;
    }
    return (completed / total).clamp(0, 1);
  }

  Map<String, Object?> toJson() => {
    'id': id,
    'type': type.name,
    'categoryLabel': categoryLabel,
    'title': title,
    'description': description,
    'savedAt': savedAt.toIso8601String(),
    'status': status.name,
    'visual': visual.name,
    'imageAsset': imageAsset,
    'destinationPath': destinationPath,
    'progressCompleted': progressCompleted,
    'progressTotal': progressTotal,
    'latitude': latitude,
    'longitude': longitude,
    'rating': rating,
    'address': address,
    'openNow': openNow,
    'googleMapsUri': googleMapsUri,
    'websiteUri': websiteUri,
    'phoneNumber': phoneNumber,
  };

  factory SavedItem.fromJson(Map<String, Object?> json) {
    return SavedItem(
      id: json['id']! as String,
      type: SavedItemType.values.byName(json['type']! as String),
      categoryLabel: json['categoryLabel']! as String,
      title: json['title']! as String,
      description: json['description']! as String,
      savedAt: DateTime.parse(json['savedAt']! as String),
      status: SavedItemStatus.values.byName(json['status']! as String),
      visual: SavedItemVisual.values.byName(json['visual']! as String),
      imageAsset: json['imageAsset'] as String?,
      destinationPath: json['destinationPath'] as String?,
      progressCompleted: json['progressCompleted'] as int?,
      progressTotal: json['progressTotal'] as int?,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      rating: (json['rating'] as num?)?.toDouble(),
      address: json['address'] as String?,
      openNow: json['openNow'] as bool?,
      googleMapsUri: json['googleMapsUri'] as String?,
      websiteUri: json['websiteUri'] as String?,
      phoneNumber: json['phoneNumber'] as String?,
    );
  }
}
