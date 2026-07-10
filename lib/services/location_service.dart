import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

import '../features/profile/application/profile_settings_controller.dart';
import '../features/profile/domain/profile_settings.dart';

const austinFallbackLocation = AppLocation(
  latitude: 30.2672,
  longitude: -97.7431,
  label: 'Austin, TX',
  isFallback: true,
  fallbackReason: LocationFallbackReason.unavailable,
);

final locationServiceProvider = Provider<LocationService>((ref) {
  return const GeolocatorLocationService();
});

final effectiveLocationProvider = FutureProvider<AppLocation>((ref) async {
  final settings = await ref.watch(profileSettingsProvider.future);
  if (settings.locationPreference == LocationPreference.defaultCity) {
    final city = settings.defaultCity;
    return AppLocation(
      latitude: city.latitude,
      longitude: city.longitude,
      label: city.label,
      isDefaultCity: true,
    );
  }
  return ref.watch(locationServiceProvider).currentOrFallback();
});

enum LocationFallbackReason {
  none,
  serviceDisabled,
  permissionDenied,
  permissionDeniedForever,
  unavailable,
}

class AppLocation {
  const AppLocation({
    required this.latitude,
    required this.longitude,
    required this.label,
    this.isFallback = false,
    this.isDefaultCity = false,
    this.fallbackReason = LocationFallbackReason.none,
  });

  final double latitude;
  final double longitude;
  final String label;
  final bool isFallback;
  final bool isDefaultCity;
  final LocationFallbackReason fallbackReason;

  bool get permissionDenied =>
      fallbackReason == LocationFallbackReason.permissionDenied ||
      fallbackReason == LocationFallbackReason.permissionDeniedForever;
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
        return const AppLocation(
          latitude: 30.2672,
          longitude: -97.7431,
          label: 'Austin, TX',
          isFallback: true,
          fallbackReason: LocationFallbackReason.serviceDisabled,
        );
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied) {
        return const AppLocation(
          latitude: 30.2672,
          longitude: -97.7431,
          label: 'Austin, TX',
          isFallback: true,
          fallbackReason: LocationFallbackReason.permissionDenied,
        );
      }
      if (permission == LocationPermission.deniedForever) {
        return const AppLocation(
          latitude: 30.2672,
          longitude: -97.7431,
          label: 'Austin, TX',
          isFallback: true,
          fallbackReason: LocationFallbackReason.permissionDeniedForever,
        );
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
      return const AppLocation(
        latitude: 30.2672,
        longitude: -97.7431,
        label: 'Austin, TX',
        isFallback: true,
        fallbackReason: LocationFallbackReason.unavailable,
      );
    }
  }
}
