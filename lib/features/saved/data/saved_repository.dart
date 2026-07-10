import 'dart:convert';

import '../domain/saved_collection.dart';
import '../domain/saved_item.dart';
import 'saved_local_storage.dart';

abstract interface class SavedRepository {
  Future<void> initialize();

  Future<List<SavedItem>> loadItems();

  Future<List<SavedCollection>> loadCollections();

  Future<void> saveItem(SavedItem item);

  Future<void> removeItem(String itemId);

  Future<SavedCollection> createCollection(String name);
}

class LocalSavedRepository implements SavedRepository {
  LocalSavedRepository({required this.storage, DateTime Function()? now})
    : _now = now ?? DateTime.now;

  static const itemsKey = 'saved.items.v1';
  static const collectionsKey = 'saved.collections.v1';
  static const seedCompletedKey = 'saved.demo_seed_completed.v1';

  final SavedLocalStorage storage;
  final DateTime Function() _now;

  @override
  Future<void> initialize() async {
    if (await storage.readBool(seedCompletedKey) ?? false) {
      return;
    }

    final existingItems = await loadItems();
    if (existingItems.isEmpty) {
      await _writeItems(_demoItems(_now()));
    }
    await storage.writeBool(seedCompletedKey, true);
  }

  @override
  Future<List<SavedItem>> loadItems() async {
    final encoded = await storage.readString(itemsKey);
    if (encoded == null || encoded.isEmpty) {
      return [];
    }

    final decoded = jsonDecode(encoded) as List<Object?>;
    return decoded
        .cast<Map<String, Object?>>()
        .map(SavedItem.fromJson)
        .toList(growable: false);
  }

  @override
  Future<List<SavedCollection>> loadCollections() async {
    final encoded = await storage.readString(collectionsKey);
    if (encoded == null || encoded.isEmpty) {
      return [];
    }

    final decoded = jsonDecode(encoded) as List<Object?>;
    return decoded
        .cast<Map<String, Object?>>()
        .map(SavedCollection.fromJson)
        .toList(growable: false);
  }

  @override
  Future<void> saveItem(SavedItem item) async {
    final items = [...await loadItems()];
    final existingIndex = items.indexWhere(
      (candidate) => candidate.id == item.id,
    );
    if (existingIndex == -1) {
      items.insert(0, item);
    } else {
      items[existingIndex] = item;
    }
    await _writeItems(items);
  }

  @override
  Future<void> removeItem(String itemId) async {
    final items = [...await loadItems()]
      ..removeWhere((candidate) => candidate.id == itemId);
    await _writeItems(items);
  }

  @override
  Future<SavedCollection> createCollection(String name) async {
    final trimmedName = name.trim();
    if (trimmedName.isEmpty) {
      throw ArgumentError.value(
        name,
        'name',
        'Collection name cannot be empty',
      );
    }

    final createdAt = _now();
    final collection = SavedCollection(
      id: 'collection-${createdAt.microsecondsSinceEpoch}',
      name: trimmedName,
      createdAt: createdAt,
    );
    final collections = [...await loadCollections(), collection];
    await _writeCollections(collections);
    return collection;
  }

  Future<void> _writeItems(List<SavedItem> items) {
    return storage.writeString(
      itemsKey,
      jsonEncode(items.map((item) => item.toJson()).toList()),
    );
  }

  Future<void> _writeCollections(List<SavedCollection> collections) {
    return storage.writeString(
      collectionsKey,
      jsonEncode(collections.map((collection) => collection.toJson()).toList()),
    );
  }

  List<SavedItem> _demoItems(DateTime now) {
    return [
      SavedItem(
        id: 'demo-date-night',
        type: SavedItemType.plan,
        categoryLabel: 'Date Night',
        title: 'Sunset & Sparkle',
        description:
            'Romantic rooftop dinner and live music in Downtown Austin',
        savedAt: now.subtract(const Duration(days: 2)),
        status: SavedItemStatus.saved,
        visual: SavedItemVisual.dateNight,
        imageAsset: 'assets/images/saved/date_night.png',
        destinationPath: '/modes/date-night',
      ),
      SavedItem(
        id: 'demo-weekend-plan',
        type: SavedItemType.plan,
        categoryLabel: 'Weekend Plan',
        title: 'Austin Weekend Reset',
        description:
            'Parks, coffee shops, and local favorites for a perfect weekend',
        savedAt: DateTime(now.year, 5, 18),
        status: SavedItemStatus.inProgress,
        visual: SavedItemVisual.weekendPlan,
        imageAsset: 'assets/images/saved/weekend_plan.png',
        destinationPath: '/modes/weekend-plan/results',
      ),
      SavedItem(
        id: 'demo-road-trip',
        type: SavedItemType.plan,
        categoryLabel: 'Road Trip',
        title: 'Hill Country Scenic Drive',
        description: 'Best stops from Austin to Fredericksburg',
        savedAt: DateTime(now.year, 5, 10),
        status: SavedItemStatus.saved,
        visual: SavedItemVisual.roadTrip,
        imageAsset: 'assets/images/saved/road_trip.png',
        destinationPath: '/modes/road-trip-stops',
      ),
      SavedItem(
        id: 'demo-local-quest',
        type: SavedItemType.plan,
        categoryLabel: 'Local Quest',
        title: 'Hidden Murals Hunt',
        description: 'Find 10 hidden murals around East Austin',
        savedAt: DateTime(now.year, 5, 6),
        status: SavedItemStatus.inProgress,
        visual: SavedItemVisual.localQuest,
        imageAsset: 'assets/images/saved/local_quest.png',
        destinationPath: '/modes/local-quest/results',
        progressCompleted: 6,
        progressTotal: 10,
      ),
    ];
  }
}
