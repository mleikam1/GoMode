import 'package:flutter_test/flutter_test.dart';
import 'package:gomode/features/saved/data/saved_local_storage.dart';
import 'package:gomode/features/saved/data/saved_repository.dart';
import 'package:gomode/features/saved/domain/saved_item.dart';

void main() {
  late _MemorySavedLocalStorage storage;
  late LocalSavedRepository repository;

  setUp(() {
    storage = _MemorySavedLocalStorage();
    repository = LocalSavedRepository(
      storage: storage,
      now: () => DateTime(2026, 7, 10, 12),
    );
  });

  test('demo seed appears on first launch', () async {
    await repository.initialize();

    final items = await repository.loadItems();

    expect(items, hasLength(4));
    expect(
      items.map((item) => item.title),
      containsAll([
        'Sunset & Sparkle',
        'Austin Weekend Reset',
        'Hill Country Scenic Drive',
        'Hidden Murals Hunt',
      ]),
    );
    expect(items.every((item) => item.type == SavedItemType.plan), isTrue);
  });

  test('demo seed is not restored after the user removes every item', () async {
    await repository.initialize();
    for (final item in await repository.loadItems()) {
      await repository.removeItem(item.id);
    }

    final restartedRepository = LocalSavedRepository(
      storage: storage,
      now: () => DateTime(2026, 7, 11, 12),
    );
    await restartedRepository.initialize();

    expect(await restartedRepository.loadItems(), isEmpty);
  });

  test('save and unsave persist through the repository', () async {
    await repository.initialize();
    final item = SavedItem(
      id: 'favorite-coffee-shop',
      type: SavedItemType.place,
      categoryLabel: 'Coffee',
      title: 'Neighborhood Coffee',
      description: 'A shaded patio with excellent espresso',
      savedAt: DateTime(2026, 7, 10, 12),
      status: SavedItemStatus.saved,
      visual: SavedItemVisual.place,
    );

    await repository.saveItem(item);
    expect(
      (await repository.loadItems()).map((candidate) => candidate.id),
      contains(item.id),
    );

    await repository.removeItem(item.id);
    expect(
      (await repository.loadItems()).map((candidate) => candidate.id),
      isNot(contains(item.id)),
    );
  });

  test('collection create persists a trimmed local name', () async {
    await repository.initialize();

    final collection = await repository.createCollection('  Austin Gems  ');

    expect(collection.name, 'Austin Gems');
    expect(await repository.loadCollections(), hasLength(1));
    expect((await repository.loadCollections()).single.name, 'Austin Gems');
  });
}

class _MemorySavedLocalStorage implements SavedLocalStorage {
  final Map<String, Object> values = {};

  @override
  Future<bool?> readBool(String key) async => values[key] as bool?;

  @override
  Future<String?> readString(String key) async => values[key] as String?;

  @override
  Future<void> writeBool(String key, bool value) async {
    values[key] = value;
  }

  @override
  Future<void> writeString(String key, String value) async {
    values[key] = value;
  }
}
