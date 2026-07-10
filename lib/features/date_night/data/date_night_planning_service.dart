import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/backend_models.dart';
import '../../../data/repositories/places_repository.dart';
import '../../../services/location_service.dart';
import '../domain/date_night_preferences.dart';
import '../domain/generated_plan.dart';

final dateNightPlanningServiceProvider = Provider<DateNightPlanningService>((
  ref,
) {
  return BackendDateNightPlanningService(
    ref.watch(placesRepositoryProvider),
    ref.watch(locationServiceProvider),
  );
});

abstract interface class DateNightPlanningService {
  Future<GeneratedPlan> generatePlan(DateNightPreferences preferences);
}

class LocalDateNightPlanGenerator implements DateNightPlanningService {
  const LocalDateNightPlanGenerator();

  @override
  Future<GeneratedPlan> generatePlan(DateNightPreferences preferences) async {
    return generateDemoDateNightPlan(preferences);
  }
}

class BackendDateNightPlanningService implements DateNightPlanningService {
  const BackendDateNightPlanningService(this._places, this._location);

  final PlacesRepository _places;
  final LocationService _location;

  @override
  Future<GeneratedPlan> generatePlan(DateNightPreferences preferences) async {
    final location = await _location.currentOrFallback();
    final dinnerFuture = _places.searchPlaces(
      latitude: location.latitude,
      longitude: location.longitude,
      modeId: 'date-night-dinner',
      query: _dinnerQuery(preferences),
      category: 'restaurant',
      openNow: preferences.openNow,
      maxResults: 3,
    );
    final activityFuture = _places.searchPlaces(
      latitude: location.latitude,
      longitude: location.longitude,
      modeId: 'date-night-activity',
      query: _activityQuery(preferences),
      category: 'tourist_attraction',
      openNow: preferences.openNow,
      maxResults: 3,
    );
    final treatFuture = _places.searchPlaces(
      latitude: location.latitude,
      longitude: location.longitude,
      modeId: 'date-night-treat',
      query: _treatQuery(preferences),
      openNow: preferences.openNow,
      maxResults: 3,
    );

    final allResults = await Future.wait([
      dinnerFuture,
      activityFuture,
      treatFuture,
    ]);
    final dinnerResults = allResults[0];
    final activityResults = allResults[1];
    final treatResults = allResults[2];
    if (allResults.any((result) => result.isDemo || result.places.isEmpty)) {
      return generateDemoDateNightPlan(
        preferences,
        fallbackMessage: allResults
            .map((result) => result.fallbackMessage)
            .whereType<String>()
            .firstOrNull,
      );
    }

    final dinner = dinnerResults.places.first;
    final activity = _firstUnique(activityResults.places, {dinner.id});
    final treat = _firstUnique(treatResults.places, {dinner.id, activity.id});
    final timing = _timingFor(preferences);
    final locationLabel = location.isFallback
        ? '${location.label} · location fallback'
        : location.label;

    return GeneratedPlan(
      id: 'date-night-live-${timing.start.millisecondsSinceEpoch}',
      title: 'Date Night',
      location: locationLabel,
      startTime: timing.start,
      isDemo: false,
      steps: [
        _placeStep(
          place: dinner,
          id: 'dinner',
          type: PlanStepType.dinner,
          label: 'Dinner',
          start: timing.start,
          end: timing.dinnerEnd,
          description: 'A restaurant match balanced for your budget and vibe.',
        ),
        _placeStep(
          place: activity,
          id: 'activity',
          type: PlanStepType.activity,
          label: 'Activity',
          start: timing.activityStart,
          end: timing.activityEnd,
          description: 'A nearby activity that keeps the evening varied.',
        ),
        _placeStep(
          place: treat,
          id: 'dessert',
          type: PlanStepType.dessertOrDrink,
          label: 'Dessert or drink',
          start: timing.treatStart,
          end: timing.treatEnd,
          description:
              'A relaxed dessert or drinks option to finish the night.',
        ),
      ],
    );
  }
}

String _dinnerQuery(DateNightPreferences preferences) {
  final budget = switch (preferences.budget) {
    DateNightBudget.twentyFive => 'affordable',
    DateNightBudget.fifty => 'moderately priced',
    DateNightBudget.oneHundredPlus => 'fine dining',
  };
  return '$budget ${preferences.vibe.label.toLowerCase()} date night restaurant';
}

String _activityQuery(DateNightPreferences preferences) {
  final setting = switch ((preferences.indoor, preferences.outdoor)) {
    (true, false) => 'indoor',
    (false, true) => 'outdoor',
    _ => 'indoor or outdoor',
  };
  return '$setting ${preferences.vibe.label.toLowerCase()} date night activity';
}

String _treatQuery(DateNightPreferences preferences) {
  return preferences.budget == DateNightBudget.twentyFive
      ? 'dessert shop for date night'
      : 'dessert shop or cocktail bar for date night';
}

PlaceSummary _firstUnique(List<PlaceSummary> places, Set<String> usedIds) {
  return places.firstWhere(
    (place) => place.id.isEmpty || !usedIds.contains(place.id),
    orElse: () => places.first,
  );
}

PlanStep _placeStep({
  required PlaceSummary place,
  required String id,
  required PlanStepType type,
  required String label,
  required DateTime start,
  required DateTime end,
  required String description,
}) {
  return PlanStep(
    id: place.id.isEmpty ? id : place.id,
    type: type,
    label: label,
    placeName: place.name,
    description: place.address.isEmpty
        ? description
        : '$description ${place.address}',
    startTime: start,
    endTime: end,
    mapQuery: place.address.isEmpty
        ? place.name
        : '${place.name}, ${place.address}',
  );
}

GeneratedPlan generateDemoDateNightPlan(
  DateNightPreferences preferences, {
  DateTime? now,
  String? fallbackMessage,
}) {
  final timing = _timingFor(preferences, now: now);

  final activity = switch (preferences.vibe) {
    DateNightVibe.romantic => (
      'Boardwalk Moonlight Stroll',
      'A relaxed walk with skyline views and a photo stop.',
    ),
    DateNightVibe.fun => (
      'Retro Arcade Social',
      'Share a few games and keep the night playful.',
    ),
    DateNightVibe.casual => (
      'South Congress Browse',
      'Wander local shops and take the evening at your own pace.',
    ),
  };

  return GeneratedPlan(
    id: 'date-night-${timing.start.millisecondsSinceEpoch}',
    title: 'Date Night',
    location: 'Austin, TX',
    startTime: timing.start,
    isDemo: true,
    fallbackMessage:
        fallbackMessage ??
        'Showing a local demo plan while live places are unavailable.',
    steps: [
      PlanStep(
        id: 'dinner',
        type: PlanStepType.dinner,
        label: 'Dinner',
        placeName: 'Juniper & Rye',
        description: 'A cozy neighborhood table with shareable plates.',
        startTime: timing.start,
        endTime: timing.dinnerEnd,
        mapQuery: 'Juniper & Rye Austin TX',
      ),
      PlanStep(
        id: 'activity',
        type: PlanStepType.activity,
        label: 'Activity',
        placeName: activity.$1,
        description: activity.$2,
        startTime: timing.activityStart,
        endTime: timing.activityEnd,
        mapQuery: '${activity.$1} Austin TX',
      ),
      PlanStep(
        id: 'dessert',
        type: PlanStepType.dessertOrDrink,
        label: 'Dessert or drink',
        placeName: 'Luna Sweets & Sips',
        description: 'Split a warm dessert or toast with a nightcap.',
        startTime: timing.treatStart,
        endTime: timing.treatEnd,
        mapQuery: 'Luna Sweets and Sips Austin TX',
      ),
    ],
  );
}

_PlanTiming _timingFor(DateNightPreferences preferences, {DateTime? now}) {
  final current = now ?? DateTime.now();
  final start = DateTime(current.year, current.month, current.day, 19);
  final dinnerMinutes = switch (preferences.duration) {
    DateNightDuration.oneHour => 25,
    DateNightDuration.twoHours => 50,
    DateNightDuration.allEvening => 75,
  };
  final activityMinutes = switch (preferences.duration) {
    DateNightDuration.oneHour => 20,
    DateNightDuration.twoHours => 45,
    DateNightDuration.allEvening => 90,
  };
  final treatMinutes = switch (preferences.duration) {
    DateNightDuration.oneHour => 15,
    DateNightDuration.twoHours => 25,
    DateNightDuration.allEvening => 45,
  };
  final dinnerEnd = start.add(Duration(minutes: dinnerMinutes));
  final activityStart = dinnerEnd.add(const Duration(minutes: 10));
  final activityEnd = activityStart.add(Duration(minutes: activityMinutes));
  final treatStart = activityEnd.add(const Duration(minutes: 10));
  return (
    start: start,
    dinnerEnd: dinnerEnd,
    activityStart: activityStart,
    activityEnd: activityEnd,
    treatStart: treatStart,
    treatEnd: treatStart.add(Duration(minutes: treatMinutes)),
  );
}

typedef _PlanTiming = ({
  DateTime start,
  DateTime dinnerEnd,
  DateTime activityStart,
  DateTime activityEnd,
  DateTime treatStart,
  DateTime treatEnd,
});
