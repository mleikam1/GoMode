import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/discovery_mode.dart';

final discoveryRepositoryProvider = Provider<DiscoveryRepository>((ref) {
  return const DiscoveryRepository();
});

class DiscoveryRepository {
  const DiscoveryRepository();

  List<DiscoveryMode> getModes() => discoveryModes;
}
