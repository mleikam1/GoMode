import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/saved_local_storage.dart';
import '../data/saved_repository.dart';
import '../domain/saved_collection.dart';
import '../domain/saved_item.dart';

final savedLocalStorageProvider = Provider<SavedLocalStorage>((ref) {
  return const SharedPreferencesSavedLocalStorage();
});

final savedRepositoryProvider = Provider<SavedRepository>((ref) {
  return LocalSavedRepository(storage: ref.watch(savedLocalStorageProvider));
});

final savedLibraryProvider =
    AsyncNotifierProvider<SavedLibraryController, SavedLibraryState>(
      SavedLibraryController.new,
    );

class SavedLibraryState {
  const SavedLibraryState({
    required this.items,
    required this.collections,
    this.selectedType = SavedItemType.plan,
  });

  final List<SavedItem> items;
  final List<SavedCollection> collections;
  final SavedItemType selectedType;

  List<SavedItem> get filteredItems =>
      items.where((item) => item.type == selectedType).toList(growable: false);

  bool contains(String itemId) => items.any((item) => item.id == itemId);

  SavedLibraryState copyWith({
    List<SavedItem>? items,
    List<SavedCollection>? collections,
    SavedItemType? selectedType,
  }) {
    return SavedLibraryState(
      items: items ?? this.items,
      collections: collections ?? this.collections,
      selectedType: selectedType ?? this.selectedType,
    );
  }
}

class SavedLibraryController extends AsyncNotifier<SavedLibraryState> {
  SavedRepository get _repository => ref.read(savedRepositoryProvider);

  @override
  Future<SavedLibraryState> build() async {
    await _repository.initialize();
    final results = await Future.wait<Object>([
      _repository.loadItems(),
      _repository.loadCollections(),
    ]);
    return SavedLibraryState(
      items: results[0] as List<SavedItem>,
      collections: results[1] as List<SavedCollection>,
    );
  }

  void selectType(SavedItemType type) {
    final current = state.requireValue;
    state = AsyncData(current.copyWith(selectedType: type));
  }

  Future<void> toggleItem(SavedItem item) async {
    final current = state.requireValue;
    if (current.contains(item.id)) {
      await removeItem(item.id);
    } else {
      await saveItem(item);
    }
  }

  Future<void> saveItem(SavedItem item) async {
    final current = state.requireValue;
    final items = [
      item,
      ...current.items.where((candidate) => candidate.id != item.id),
    ];
    state = AsyncData(current.copyWith(items: items));
    try {
      await _repository.saveItem(item);
    } catch (error, stackTrace) {
      state = AsyncData(current);
      Error.throwWithStackTrace(error, stackTrace);
    }
  }

  Future<void> removeItem(String itemId) async {
    final current = state.requireValue;
    final items = current.items
        .where((candidate) => candidate.id != itemId)
        .toList(growable: false);
    state = AsyncData(current.copyWith(items: items));
    try {
      await _repository.removeItem(itemId);
    } catch (error, stackTrace) {
      state = AsyncData(current);
      Error.throwWithStackTrace(error, stackTrace);
    }
  }

  Future<SavedCollection> createCollection(String name) async {
    final current = state.requireValue;
    final collection = await _repository.createCollection(name);
    state = AsyncData(
      current.copyWith(collections: [...current.collections, collection]),
    );
    return collection;
  }
}
