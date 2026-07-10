import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

const austinFallbackLocation = AppLocation(
  latitude: 30.2672,
  longitude: -97.7431,
  label: 'Austin, TX',
  isFallback: true,
);

final locationServiceProvider = Provider<LocationService>((ref) {
  return const GeolocatorLocationService();
});

final effectiveLocationProvider = FutureProvider<AppLocation>((ref) {
  return ref.watch(locationServiceProvider).currentOrFallback();
});

class AppLocation {
  const AppLocation({
    required this.latitude,
    required this.longitude,
    required this.label,
    this.isFallback = false,
  });

  final double latitude;
  final double longitude;
  final String label;
  final bool isFallback;
}

abstract interface class LocationService {
  Future<AppLocation> currentOrFallback();
}

class GeolocatorLocationService implements LocationService {
  const GeolocatorLocationService();

  @override
  Future<AppLocation> currentOrFallback() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return austinFallbackLocation;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return austinFallbackLocation;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 8),
        ),
      );
      return AppLocation(
        latitude: position.latitude,
        longitude: position.longitude,
        label: 'Current location',
      );
    } catch (_) {
      return austinFallbackLocation;
    }
  }
}
