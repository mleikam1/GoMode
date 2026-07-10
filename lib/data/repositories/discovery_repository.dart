import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/discovery_mode.dart';
import '../services/mode_catalog.dart';

final discoveryRepositoryProvider = Provider<DiscoveryRepository>((ref) {
  return DiscoveryRepository(ref.watch(modeCatalogProvider));
});

class DiscoveryRepository {
  const DiscoveryRepository(this._catalog);

  final ModeCatalog _catalog;

  List<DiscoveryMode> getModes() => _catalog.modes;
}
