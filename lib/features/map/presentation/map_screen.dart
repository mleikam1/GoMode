import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../data/models/backend_models.dart';
import '../../../data/models/discovery_mode.dart';
import '../../../data/repositories/places_repository.dart';
import '../../../data/services/mode_catalog.dart';
import '../../../services/location_service.dart';
import '../../../services/runtime_config.dart';
import '../../../shared/widgets/shared_widgets.dart';
import '../../profile/application/profile_settings_controller.dart';
import '../../profile/domain/profile_settings.dart';
import '../../road_trip/data/road_trip_route_service.dart';
import '../../road_trip/domain/route_plan.dart';
import '../../saved/application/saved_library_controller.dart';
import '../../saved/domain/saved_item.dart';

typedef MapSearchRequest = ({
  String modeId,
  double latitude,
  double longitude,
  int radiusMeters,
});

final mapPlacesProvider = FutureProvider.autoDispose
    .family<PlaceSearchResult, MapSearchRequest>((ref, request) {
      return ref
          .watch(placesRepositoryProvider)
          .searchPlaces(
            latitude: request.latitude,
            longitude: request.longitude,
            modeId: request.modeId,
            query: request.modeId == 'open-now'
                ? 'popular places nearby'
                : null,
            radiusMeters: request.radiusMeters,
            openNow: request.modeId == 'open-now',
            maxResults: 10,
          );
    });

final mapRoutePlanProvider = FutureProvider<RoutePlan>((ref) {
  return ref.watch(roadTripRouteServiceProvider).loadRoutePlan();
});

class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key});

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen> {
  String _selectedModeId = 'open-now';
  bool _showRoute = false;

  @override
  Widget build(BuildContext context) {
    final catalog = ref.watch(modeCatalogProvider);
    final modes = _mapFilters(catalog);
    final location = ref.watch(effectiveLocationProvider);
    final settings = ref.watch(profileSettingsProvider).value;
    final route = ref.watch(mapRoutePlanProvider);
    final library = ref.watch(savedLibraryProvider);
    final currentLocation = location.asData?.value;
    final search = currentLocation == null
        ? const AsyncLoading<PlaceSearchResult>()
        : ref.watch(
            mapPlacesProvider((
              modeId: _selectedModeId,
              latitude: currentLocation.latitude,
              longitude: currentLocation.longitude,
              radiusMeters: (settings?.distanceMiles ?? 10) * 1609,
            )),
          );
    final nearbyPlaces = search.value?.places ?? const <PlaceSummary>[];
    final pins = _buildPins(
      nearbyPlaces: nearbyPlaces,
      savedItems: library.value?.items ?? const <SavedItem>[],
      route: route.value,
      showRoute: _showRoute,
    );

    return ColoredBox(
      key: const ValueKey('map-screen'),
      color: AppColors.surface,
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: GradientHeader(
              compact: true,
              title: 'Map',
              subtitle: 'Nearby ideas, saved places, and routes in one view.',
              bottom: _LocationSummary(location: location),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(AppSpacing.page),
            sliver: SliverList.list(
              children: [
                _ModeFilters(
                  modes: modes,
                  selectedModeId: _selectedModeId,
                  showRoute: _showRoute,
                  onSelected: (modeId) {
                    setState(() {
                      _selectedModeId = modeId;
                      _showRoute = false;
                    });
                  },
                  onRouteSelected: () {
                    setState(() => _showRoute = !_showRoute);
                  },
                ),
                const SizedBox(height: AppSpacing.md),
                if (currentLocation != null &&
                    (currentLocation.isFallback ||
                        currentLocation.isDefaultCity)) ...[
                  _LocationNotice(
                    location: currentLocation,
                    onUseCurrentLocation: _useCurrentLocation,
                  ),
                  const SizedBox(height: AppSpacing.md),
                ],
                _MapCanvas(
                  location: location,
                  pins: pins,
                  route: route.value,
                  showRoute: _showRoute,
                  loading: search.isLoading || (_showRoute && route.isLoading),
                  onLocate: _useCurrentLocation,
                  onOpenPlace: _openPlaceDetails,
                ),
                if (search.hasError) ...[
                  const SizedBox(height: AppSpacing.md),
                  _InlineNotice(
                    icon: Icons.cloud_off_rounded,
                    message:
                        'Nearby results could not refresh. Saved places and route data are still available.',
                    actionLabel: 'Try again',
                    onAction: () => ref.invalidate(mapPlacesProvider),
                  ),
                ] else if (search.value?.isDemo ?? false) ...[
                  const SizedBox(height: AppSpacing.md),
                  const _InlineNotice(
                    icon: Icons.auto_awesome_rounded,
                    message:
                        'Showing polished demo places while the live backend is unavailable.',
                  ),
                ],
                const SizedBox(height: AppSpacing.xl),
                _MapLegend(
                  nearbyCount: nearbyPlaces.length,
                  savedCount: pins
                      .where((pin) => pin.source == _PinSource.saved)
                      .length,
                  routeCount: _showRoute
                      ? pins
                            .where((pin) => pin.source == _PinSource.route)
                            .length
                      : 0,
                ),
                const SizedBox(height: AppSpacing.xl),
                Text(
                  _showRoute ? 'Road trip route' : 'Nearby places',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                if (_showRoute)
                  route.when(
                    loading: () => const _MapListLoading(),
                    error: (error, stackTrace) => const _EmptyMapList(
                      message: 'Route preview is temporarily unavailable.',
                    ),
                    data: (plan) => _RoutePreviewCard(
                      plan: plan,
                      onOpenStop: (stop) =>
                          _openPlaceDetails(_MapPinData.fromRouteStop(stop)),
                    ),
                  )
                else
                  search.when(
                    loading: () => const _MapListLoading(),
                    error: (error, stackTrace) => const _EmptyMapList(
                      message: 'No nearby places to show yet.',
                    ),
                    data: (result) => result.places.isEmpty
                        ? const _EmptyMapList(
                            message:
                                'No places matched this mode. Try another filter.',
                          )
                        : Column(
                            children: [
                              for (final place in result.places.take(5))
                                _PlaceResultRow(
                                  pin: _MapPinData.fromPlace(place),
                                  onTap: _openPlaceDetails,
                                ),
                            ],
                          ),
                  ),
                SizedBox(height: AppSpacing.bottomNavHeight + AppSpacing.xl),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _useCurrentLocation() async {
    final settings = ref.read(profileSettingsProvider).value;
    if (settings?.locationPreference == LocationPreference.defaultCity) {
      await ref
          .read(profileSettingsProvider.notifier)
          .setLocationPreference(LocationPreference.currentLocation);
    }
    ref.invalidate(effectiveLocationProvider);
  }

  void _openPlaceDetails(_MapPinData pin) {
    unawaited(
      showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => _PlaceDetailsSheet(pin: pin),
      ),
    );
  }
}

List<DiscoveryMode> _mapFilters(ModeCatalog catalog) {
  const preferredIds = [
    'open-now',
    'patio-finder',
    'kids-bored-button',
    'dog-friendly-spots',
  ];
  return [for (final id in preferredIds) ?catalog.findById(id)];
}

List<_MapPinData> _buildPins({
  required List<PlaceSummary> nearbyPlaces,
  required List<SavedItem> savedItems,
  required RoutePlan? route,
  required bool showRoute,
}) {
  final pins = <String, _MapPinData>{
    for (final place in nearbyPlaces)
      if (place.location != null) place.id: _MapPinData.fromPlace(place),
  };
  for (final item in savedItems) {
    if (item.type == SavedItemType.place && item.hasLocation) {
      pins[item.id] = _MapPinData.fromSavedItem(item);
    }
  }
  if (showRoute && route != null) {
    for (final stop in route.stops) {
      if (stop.latitude != null && stop.longitude != null) {
        pins['route-${stop.id}'] = _MapPinData.fromRouteStop(stop);
      }
    }
  }
  return pins.values.toList(growable: false);
}

class _ModeFilters extends StatelessWidget {
  const _ModeFilters({
    required this.modes,
    required this.selectedModeId,
    required this.showRoute,
    required this.onSelected,
    required this.onRouteSelected,
  });

  final List<DiscoveryMode> modes;
  final String selectedModeId;
  final bool showRoute;
  final ValueChanged<String> onSelected;
  final VoidCallback onRouteSelected;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final mode in modes) ...[
            FilterChipPill(
              label: mode.title,
              icon: ModeCatalog.iconFor(mode.iconSemanticName),
              color: mode.accentColor,
              selected: !showRoute && selectedModeId == mode.id,
              onTap: () => onSelected(mode.id),
            ),
            const SizedBox(width: AppSpacing.xs),
          ],
          FilterChipPill(
            key: const ValueKey('map-road-trip-filter'),
            label: 'Road trip',
            icon: Icons.route_rounded,
            color: AppColors.lavender,
            selected: showRoute,
            onTap: onRouteSelected,
          ),
        ],
      ),
    );
  }
}

class _LocationSummary extends StatelessWidget {
  const _LocationSummary({required this.location});

  final AsyncValue<AppLocation> location;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          location.value?.isDefaultCity ?? false
              ? Icons.location_city_rounded
              : Icons.my_location_rounded,
          color: AppColors.primaryBlueLight,
        ),
        const SizedBox(width: AppSpacing.xs),
        Expanded(
          child: Text(
            location.when(
              data: (value) => value.label,
              error: (error, stackTrace) => 'Location unavailable',
              loading: () => 'Finding your location…',
            ),
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: AppColors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }
}

class _LocationNotice extends StatelessWidget {
  const _LocationNotice({
    required this.location,
    required this.onUseCurrentLocation,
  });

  final AppLocation location;
  final VoidCallback onUseCurrentLocation;

  @override
  Widget build(BuildContext context) {
    final permissionDenied = location.permissionDenied;
    final serviceDisabled =
        location.fallbackReason == LocationFallbackReason.serviceDisabled;
    final message = permissionDenied
        ? 'Location permission is off. GoMode uses location only to find nearby results; Austin is shown instead.'
        : serviceDisabled
        ? 'Location services are off. Turn them on for nearby results, or keep using Austin.'
        : location.isDefaultCity
        ? 'Using ${location.label}. You can switch to current location at any time.'
        : 'Current location is unavailable, so nearby results use Austin.';

    return _InlineNotice(
      key: const ValueKey('map-location-notice'),
      icon: permissionDenied
          ? Icons.location_disabled_rounded
          : Icons.location_city_rounded,
      message: message,
      actionLabel: permissionDenied || serviceDisabled
          ? 'Settings'
          : 'Use current',
      onAction: permissionDenied
          ? () => unawaited(Geolocator.openAppSettings())
          : serviceDisabled
          ? () => unawaited(Geolocator.openLocationSettings())
          : onUseCurrentLocation,
    );
  }
}

class _MapCanvas extends StatelessWidget {
  const _MapCanvas({
    required this.location,
    required this.pins,
    required this.route,
    required this.showRoute,
    required this.loading,
    required this.onLocate,
    required this.onOpenPlace,
  });

  final AsyncValue<AppLocation> location;
  final List<_MapPinData> pins;
  final RoutePlan? route;
  final bool showRoute;
  final bool loading;
  final VoidCallback onLocate;
  final ValueChanged<_MapPinData> onOpenPlace;

  @override
  Widget build(BuildContext context) {
    final current = location.value ?? austinFallbackLocation;
    return Container(
      key: const ValueKey('map-canvas'),
      height: 440,
      decoration: BoxDecoration(
        color: AppColors.surfaceRaised,
        borderRadius: AppRadius.heroCard,
        border: Border.all(color: AppColors.border),
        boxShadow: AppShadows.card,
      ),
      child: ClipRRect(
        borderRadius: AppRadius.heroCard,
        child: Stack(
          children: [
            Positioned.fill(
              child: googleMapsWidgetEnabled
                  ? _GoogleMapCanvas(
                      location: current,
                      pins: pins,
                      route: route,
                      showRoute: showRoute,
                      onOpenPlace: onOpenPlace,
                    )
                  : _PlaceholderMapCanvas(
                      pins: pins,
                      showRoute: showRoute,
                      onOpenPlace: onOpenPlace,
                    ),
            ),
            Positioned(
              top: AppSpacing.md,
              left: AppSpacing.md,
              right: AppSpacing.md,
              child: Row(
                children: [
                  Expanded(
                    child: _MapOverlayPill(
                      icon: current.isDefaultCity
                          ? Icons.location_city_rounded
                          : current.isFallback
                          ? Icons.location_disabled_rounded
                          : Icons.my_location_rounded,
                      label: current.isFallback
                          ? '${current.label} fallback'
                          : current.label,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Material(
                    color: AppColors.white,
                    shape: const CircleBorder(),
                    elevation: 2,
                    child: IconButton(
                      key: const ValueKey('map-use-current-location'),
                      tooltip: 'Use current location',
                      onPressed: onLocate,
                      icon: const Icon(Icons.my_location_rounded),
                      color: AppColors.primaryBlue,
                    ),
                  ),
                ],
              ),
            ),
            if (loading)
              const Positioned(
                top: 82,
                right: AppSpacing.md,
                child: _LoadingMapBadge(),
              ),
            if (!googleMapsWidgetEnabled && kDebugMode)
              const Positioned(
                left: AppSpacing.md,
                right: AppSpacing.md,
                bottom: AppSpacing.md,
                child: _MapSetupNote(),
              ),
          ],
        ),
      ),
    );
  }
}

class _GoogleMapCanvas extends StatelessWidget {
  const _GoogleMapCanvas({
    required this.location,
    required this.pins,
    required this.route,
    required this.showRoute,
    required this.onOpenPlace,
  });

  final AppLocation location;
  final List<_MapPinData> pins;
  final RoutePlan? route;
  final bool showRoute;
  final ValueChanged<_MapPinData> onOpenPlace;

  @override
  Widget build(BuildContext context) {
    final routePoints = _routePoints(route);
    return GoogleMap(
      key: const ValueKey('google-map-widget'),
      initialCameraPosition: CameraPosition(
        target: showRoute
            ? const LatLng(29.86, -98.08)
            : LatLng(location.latitude, location.longitude),
        zoom: showRoute ? 8.2 : 12.5,
      ),
      myLocationButtonEnabled: false,
      myLocationEnabled: !location.isFallback && !location.isDefaultCity,
      mapToolbarEnabled: false,
      zoomControlsEnabled: false,
      compassEnabled: true,
      markers: {
        for (final pin in pins)
          Marker(
            markerId: MarkerId(pin.markerId),
            position: LatLng(pin.latitude, pin.longitude),
            icon: BitmapDescriptor.defaultMarkerWithHue(pin.markerHue),
            infoWindow: InfoWindow(title: pin.title, snippet: pin.address),
            onTap: () => onOpenPlace(pin),
          ),
      },
      polylines: showRoute && routePoints.length > 1
          ? {
              Polyline(
                polylineId: const PolylineId('road-trip-preview'),
                points: routePoints,
                color: AppColors.primaryBlue,
                width: 6,
              ),
            }
          : const {},
    );
  }
}

List<LatLng> _routePoints(RoutePlan? route) {
  if (route == null) {
    return const [];
  }
  return [
    const LatLng(30.2672, -97.7431),
    for (final stop in route.stops)
      if (stop.latitude != null && stop.longitude != null)
        LatLng(stop.latitude!, stop.longitude!),
    const LatLng(29.4241, -98.4936),
  ];
}

class _PlaceholderMapCanvas extends StatelessWidget {
  const _PlaceholderMapCanvas({
    required this.pins,
    required this.showRoute,
    required this.onOpenPlace,
  });

  final List<_MapPinData> pins;
  final bool showRoute;
  final ValueChanged<_MapPinData> onOpenPlace;

  @override
  Widget build(BuildContext context) {
    const positions = [
      Alignment(-0.58, -0.22),
      Alignment(0.18, -0.46),
      Alignment(0.58, 0.04),
      Alignment(-0.12, 0.33),
      Alignment(0.70, 0.46),
      Alignment(-0.67, 0.54),
    ];
    return Stack(
      key: const ValueKey('map-placeholder'),
      children: [
        Positioned.fill(
          child: CustomPaint(painter: _MapPainter(showRoute: showRoute)),
        ),
        for (var index = 0; index < pins.take(positions.length).length; index++)
          Align(
            alignment: positions[index],
            child: _MapPinButton(
              pin: pins[index],
              onTap: () => onOpenPlace(pins[index]),
            ),
          ),
      ],
    );
  }
}

class _MapPainter extends CustomPainter {
  const _MapPainter({required this.showRoute});

  final bool showRoute;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = const Color(0xFFEFF4FF),
    );
    final parkPaint = Paint()..color = AppColors.green.withValues(alpha: 0.16);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width * 0.25, size.height * 0.31),
        width: size.width * 0.52,
        height: size.height * 0.30,
      ),
      parkPaint,
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width * 0.80, size.height * 0.72),
        width: size.width * 0.44,
        height: size.height * 0.28,
      ),
      parkPaint,
    );

    final roadPaint = Paint()
      ..color = AppColors.white
      ..strokeWidth = 24
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final roadLinePaint = Paint()
      ..color = AppColors.borderStrong
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final roads = [
      Path()
        ..moveTo(-20, size.height * 0.23)
        ..cubicTo(
          size.width * 0.24,
          size.height * 0.12,
          size.width * 0.44,
          size.height * 0.48,
          size.width + 20,
          size.height * 0.36,
        ),
      Path()
        ..moveTo(size.width * 0.10, size.height + 20)
        ..cubicTo(
          size.width * 0.30,
          size.height * 0.72,
          size.width * 0.42,
          size.height * 0.34,
          size.width * 0.68,
          -20,
        ),
      Path()
        ..moveTo(-10, size.height * 0.80)
        ..quadraticBezierTo(
          size.width * 0.46,
          size.height * 0.62,
          size.width + 10,
          size.height * 0.88,
        ),
    ];
    for (final road in roads) {
      canvas
        ..drawPath(road, roadPaint)
        ..drawPath(road, roadLinePaint);
    }
    if (showRoute) {
      final routePath = Path()
        ..moveTo(size.width * 0.18, size.height * 0.18)
        ..cubicTo(
          size.width * 0.34,
          size.height * 0.38,
          size.width * 0.55,
          size.height * 0.50,
          size.width * 0.82,
          size.height * 0.76,
        );
      canvas.drawPath(
        routePath,
        Paint()
          ..color = AppColors.primaryBlue
          ..strokeWidth = 6
          ..strokeCap = StrokeCap.round
          ..style = PaintingStyle.stroke,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _MapPainter oldDelegate) {
    return oldDelegate.showRoute != showRoute;
  }
}

class _MapPinButton extends StatelessWidget {
  const _MapPinButton({required this.pin, required this.onTap});

  final _MapPinData pin;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Open ${pin.title}',
      child: Material(
        key: ValueKey('map-pin-${pin.markerId}'),
        color: AppColors.white,
        elevation: 5,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: SizedBox(
            width: 42,
            height: 42,
            child: Icon(pin.icon, color: pin.color, size: 23),
          ),
        ),
      ),
    );
  }
}

class _MapOverlayPill extends StatelessWidget {
  const _MapOverlayPill({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: AppRadius.chip,
        boxShadow: AppShadows.soft,
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primaryBlue, size: 21),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900),
            ),
          ),
        ],
      ),
    );
  }
}

class _LoadingMapBadge extends StatelessWidget {
  const _LoadingMapBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: const BoxDecoration(
        color: AppColors.white,
        shape: BoxShape.circle,
      ),
      child: const SizedBox.square(
        dimension: 20,
        child: CircularProgressIndicator(strokeWidth: 2.5),
      ),
    );
  }
}

class _MapSetupNote extends StatelessWidget {
  const _MapSetupNote();

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey('map-debug-setup-note'),
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.navy900.withValues(alpha: 0.92),
        borderRadius: AppRadius.card,
      ),
      child: Row(
        children: [
          const Icon(Icons.code_rounded, color: AppColors.primaryBlueLight),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              'Map placeholder · configure native Maps SDK keys, then enable GOMODE_MAPS_WIDGET_ENABLED.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InlineNotice extends StatelessWidget {
  const _InlineNotice({
    required this.icon,
    required this.message,
    this.actionLabel,
    this.onAction,
    super.key,
  });

  final IconData icon;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.amber.withValues(alpha: 0.10),
        borderRadius: AppRadius.largeCard,
        border: Border.all(color: AppColors.amber.withValues(alpha: 0.28)),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.warning),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              message,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          if (actionLabel != null)
            TextButton(onPressed: onAction, child: Text(actionLabel!)),
        ],
      ),
    );
  }
}

class _MapLegend extends StatelessWidget {
  const _MapLegend({
    required this.nearbyCount,
    required this.savedCount,
    required this.routeCount,
  });

  final int nearbyCount;
  final int savedCount;
  final int routeCount;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _LegendItem(
            icon: Icons.place_rounded,
            label: 'Nearby',
            value: nearbyCount,
            color: AppColors.primaryBlue,
          ),
        ),
        const SizedBox(width: AppSpacing.xs),
        Expanded(
          child: _LegendItem(
            icon: Icons.favorite_rounded,
            label: 'Saved',
            value: savedCount,
            color: AppColors.coral,
          ),
        ),
        const SizedBox(width: AppSpacing.xs),
        Expanded(
          child: _LegendItem(
            icon: Icons.route_rounded,
            label: 'Route',
            value: routeCount,
            color: AppColors.lavender,
          ),
        ),
      ],
    );
  }
}

class _LegendItem extends StatelessWidget {
  const _LegendItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final int value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: AppRadius.card,
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 3),
          Text(
            '$value',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.w900,
            ),
          ),
          Text(label, style: Theme.of(context).textTheme.labelSmall),
        ],
      ),
    );
  }
}

class _PlaceResultRow extends StatelessWidget {
  const _PlaceResultRow({required this.pin, required this.onTap});

  final _MapPinData pin;
  final ValueChanged<_MapPinData> onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Material(
        color: AppColors.white,
        borderRadius: AppRadius.largeCard,
        child: InkWell(
          borderRadius: AppRadius.largeCard,
          onTap: () => onTap(pin),
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              borderRadius: AppRadius.largeCard,
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                SoftIconBadge(
                  icon: pin.icon,
                  color: pin.color,
                  showShadow: false,
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        pin.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        pin.address,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                if (pin.rating != null) ...[
                  const Icon(
                    Icons.star_rounded,
                    color: AppColors.amber,
                    size: 18,
                  ),
                  Text(pin.rating!.toStringAsFixed(1)),
                ],
                const SizedBox(width: AppSpacing.xs),
                const Icon(Icons.chevron_right_rounded),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RoutePreviewCard extends StatelessWidget {
  const _RoutePreviewCard({required this.plan, required this.onOpenStop});

  final RoutePlan plan;
  final ValueChanged<RouteStop> onOpenStop;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: AppRadius.largeCard,
        border: Border.all(color: AppColors.border),
        boxShadow: AppShadows.soft,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const SoftIconBadge(
                icon: Icons.route_rounded,
                color: AppColors.lavender,
                showShadow: false,
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      plan.routeSubtitle,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      '${plan.summary.totalDistanceMiles} mi · ${plan.summary.estimatedDriveTime.inHours} hr ${plan.summary.estimatedDriveTime.inMinutes.remainder(60)} min',
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          for (var index = 0; index < plan.stops.length; index++)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: CircleAvatar(
                backgroundColor: AppColors.primaryBlue.withValues(alpha: 0.10),
                foregroundColor: AppColors.primaryBlue,
                child: Text('${index + 1}'),
              ),
              title: Text(
                plan.stops[index].title,
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
              subtitle: Text(plan.stops[index].locationLabel),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () => onOpenStop(plan.stops[index]),
            ),
        ],
      ),
    );
  }
}

class _MapListLoading extends StatelessWidget {
  const _MapListLoading();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(AppSpacing.xl),
      child: Center(child: CircularProgressIndicator()),
    );
  }
}

class _EmptyMapList extends StatelessWidget {
  const _EmptyMapList({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: AppRadius.largeCard,
        border: Border.all(color: AppColors.border),
      ),
      child: Text(message, textAlign: TextAlign.center),
    );
  }
}

enum _PinSource { nearby, saved, route }

class _MapPinData {
  const _MapPinData({
    required this.markerId,
    required this.title,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.source,
    this.rating,
    this.openNow,
    this.googleMapsUri,
    this.websiteUri,
    this.phoneNumber,
    this.lookupDetails = false,
    this.hasCoordinates = true,
  });

  final String markerId;
  final String title;
  final String address;
  final double latitude;
  final double longitude;
  final _PinSource source;
  final double? rating;
  final bool? openNow;
  final Uri? googleMapsUri;
  final Uri? websiteUri;
  final String? phoneNumber;
  final bool lookupDetails;
  final bool hasCoordinates;

  IconData get icon => switch (source) {
    _PinSource.nearby => Icons.place_rounded,
    _PinSource.saved => Icons.favorite_rounded,
    _PinSource.route => Icons.route_rounded,
  };

  Color get color => switch (source) {
    _PinSource.nearby => AppColors.primaryBlue,
    _PinSource.saved => AppColors.coral,
    _PinSource.route => AppColors.lavender,
  };

  double get markerHue => switch (source) {
    _PinSource.nearby => BitmapDescriptor.hueAzure,
    _PinSource.saved => BitmapDescriptor.hueRose,
    _PinSource.route => BitmapDescriptor.hueViolet,
  };

  factory _MapPinData.fromPlace(PlaceSummary place) {
    final point = place.location ?? const GeoPoint(latitude: 0, longitude: 0);
    return _MapPinData(
      markerId: place.id,
      title: place.name,
      address: place.address.isEmpty ? 'Address unavailable' : place.address,
      latitude: point.latitude,
      longitude: point.longitude,
      source: _PinSource.nearby,
      rating: place.rating,
      openNow: place.openNow,
      googleMapsUri: place.googleMapsUri,
      websiteUri: place.websiteUri,
      phoneNumber: place.phoneNumber,
      lookupDetails: place.id.isNotEmpty,
      hasCoordinates: place.location != null,
    );
  }

  factory _MapPinData.fromSavedItem(SavedItem item) {
    return _MapPinData(
      markerId: item.id,
      title: item.title,
      address: item.address ?? item.description,
      latitude: item.latitude!,
      longitude: item.longitude!,
      source: _PinSource.saved,
      rating: item.rating,
      openNow: item.openNow,
      googleMapsUri: _optionalUri(item.googleMapsUri),
      websiteUri: _optionalUri(item.websiteUri),
      phoneNumber: item.phoneNumber,
      hasCoordinates: item.hasLocation,
    );
  }

  factory _MapPinData.fromRouteStop(RouteStop stop) {
    return _MapPinData(
      markerId: stop.id,
      title: stop.title,
      address: stop.locationLabel,
      latitude: stop.latitude ?? 0,
      longitude: stop.longitude ?? 0,
      source: _PinSource.route,
      rating: stop.rating,
      openNow: stop.openNow,
      googleMapsUri: _optionalUri(stop.googleMapsUri),
      hasCoordinates: stop.latitude != null && stop.longitude != null,
    );
  }

  _MapPinData copyWithDetails(PlaceSummary place) {
    return _MapPinData(
      markerId: markerId,
      title: place.name,
      address: place.address.isEmpty ? address : place.address,
      latitude: place.location?.latitude ?? latitude,
      longitude: place.location?.longitude ?? longitude,
      source: source,
      rating: place.rating ?? rating,
      openNow: place.openNow ?? openNow,
      googleMapsUri: place.googleMapsUri ?? googleMapsUri,
      websiteUri: place.websiteUri ?? websiteUri,
      phoneNumber: place.phoneNumber ?? phoneNumber,
      hasCoordinates: place.location != null || hasCoordinates,
    );
  }
}

class _PlaceDetailsSheet extends ConsumerStatefulWidget {
  const _PlaceDetailsSheet({required this.pin});

  final _MapPinData pin;

  @override
  ConsumerState<_PlaceDetailsSheet> createState() => _PlaceDetailsSheetState();
}

class _PlaceDetailsSheetState extends ConsumerState<_PlaceDetailsSheet> {
  late Future<_MapPinData> _details;

  @override
  void initState() {
    super.initState();
    _details = _loadDetails();
  }

  Future<_MapPinData> _loadDetails() async {
    if (!widget.pin.lookupDetails) {
      return widget.pin;
    }
    try {
      final result = await ref
          .read(placesRepositoryProvider)
          .placeDetails(widget.pin.markerId);
      return widget.pin.copyWithDetails(result.place);
    } catch (_) {
      return widget.pin;
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_MapPinData>(
      future: _details,
      initialData: widget.pin,
      builder: (context, snapshot) {
        final pin = snapshot.data ?? widget.pin;
        final library = ref.watch(savedLibraryProvider);
        final saved = library.value?.contains(pin.markerId) ?? false;
        return Container(
          key: const ValueKey('place-details-sheet'),
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height * 0.86,
          ),
          padding: EdgeInsets.fromLTRB(
            AppSpacing.page,
            AppSpacing.sm,
            AppSpacing.page,
            MediaQuery.paddingOf(context).bottom + AppSpacing.xl,
          ),
          decoration: const BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(AppRadius.xxxl),
            ),
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 44,
                    height: 5,
                    decoration: BoxDecoration(
                      color: AppColors.borderStrong,
                      borderRadius: AppRadius.chip,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SoftIconBadge(
                      icon: pin.icon,
                      color: pin.color,
                      size: 58,
                      showShadow: false,
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            pin.title,
                            style: Theme.of(context).textTheme.headlineSmall
                                ?.copyWith(fontWeight: FontWeight.w900),
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Wrap(
                            spacing: AppSpacing.xs,
                            runSpacing: AppSpacing.xs,
                            children: [
                              if (pin.rating != null)
                                StatusPill(
                                  label: '★ ${pin.rating!.toStringAsFixed(1)}',
                                  color: AppColors.amber,
                                ),
                              StatusPill(
                                label: switch (pin.openNow) {
                                  true => 'Open now',
                                  false => 'Closed now',
                                  null => 'Hours unverified',
                                },
                                color: pin.openNow == true
                                    ? AppColors.success
                                    : AppColors.textMuted,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                _DetailLine(
                  icon: Icons.location_on_outlined,
                  text: pin.address,
                ),
                const SizedBox(height: AppSpacing.lg),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        key: const ValueKey('place-details-save'),
                        onPressed: library.isLoading
                            ? null
                            : () => _toggleSaved(pin, saved),
                        icon: Icon(
                          saved
                              ? Icons.favorite_rounded
                              : Icons.favorite_border_rounded,
                        ),
                        label: Text(saved ? 'Saved' : 'Save'),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: FilledButton.icon(
                        key: const ValueKey('place-details-navigate'),
                        onPressed: () => _launch(_navigationUri(pin)),
                        icon: const Icon(Icons.navigation_rounded),
                        label: const Text('Navigate'),
                      ),
                    ),
                  ],
                ),
                if (pin.websiteUri != null || pin.phoneNumber != null) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Row(
                    children: [
                      if (pin.websiteUri != null)
                        Expanded(
                          child: TextButton.icon(
                            onPressed: () => _launch(pin.websiteUri!),
                            icon: const Icon(Icons.language_rounded),
                            label: const Text('Website'),
                          ),
                        ),
                      if (pin.websiteUri != null && pin.phoneNumber != null)
                        const SizedBox(width: AppSpacing.sm),
                      if (pin.phoneNumber != null)
                        Expanded(
                          child: TextButton.icon(
                            onPressed: () => _launch(
                              Uri(scheme: 'tel', path: pin.phoneNumber),
                            ),
                            icon: const Icon(Icons.call_rounded),
                            label: const Text('Call'),
                          ),
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _toggleSaved(_MapPinData pin, bool saved) async {
    await ref.read(savedLibraryProvider.future);
    if (saved) {
      await ref.read(savedLibraryProvider.notifier).removeItem(pin.markerId);
      return;
    }
    await ref
        .read(savedLibraryProvider.notifier)
        .saveItem(
          SavedItem(
            id: pin.markerId,
            type: SavedItemType.place,
            categoryLabel: 'Map place',
            title: pin.title,
            description: pin.address,
            savedAt: DateTime.now(),
            status: SavedItemStatus.saved,
            visual: SavedItemVisual.place,
            destinationPath: '/map',
            latitude: pin.hasCoordinates ? pin.latitude : null,
            longitude: pin.hasCoordinates ? pin.longitude : null,
            rating: pin.rating,
            address: pin.address,
            openNow: pin.openNow,
            googleMapsUri: pin.googleMapsUri?.toString(),
            websiteUri: pin.websiteUri?.toString(),
            phoneNumber: pin.phoneNumber,
          ),
        );
  }
}

class _DetailLine extends StatelessWidget {
  const _DetailLine({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: AppColors.primaryBlue),
        const SizedBox(width: AppSpacing.sm),
        Expanded(child: Text(text)),
      ],
    );
  }
}

Uri _navigationUri(_MapPinData pin) {
  return pin.googleMapsUri ??
      Uri.https('www.google.com', '/maps/search/', {
        'api': '1',
        'query': pin.hasCoordinates
            ? '${pin.latitude},${pin.longitude}'
            : '${pin.title}, ${pin.address}',
      });
}

Future<void> _launch(Uri uri) async {
  if (!uri.hasScheme || (uri.host.isEmpty && uri.scheme != 'tel')) {
    return;
  }
  await launchUrl(uri, mode: LaunchMode.externalApplication);
}

Uri? _optionalUri(String? value) {
  if (value == null || value.trim().isEmpty) {
    return null;
  }
  final uri = Uri.tryParse(value);
  return uri?.hasScheme ?? false ? uri : null;
}
