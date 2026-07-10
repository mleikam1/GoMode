import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/date_night_preferences.dart';
import '../domain/generated_plan.dart';

final dateNightPlanningServiceProvider = Provider<DateNightPlanningService>((
  ref,
) {
  // Swap this provider for a Google-backed implementation when the planning
  // endpoint is available. The setup screen always calls this contract.
  return const LocalDateNightPlanGenerator();
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

GeneratedPlan generateDemoDateNightPlan(
  DateNightPreferences preferences, {
  DateTime? now,
}) {
  final current = now ?? DateTime.now();
  final startTime = DateTime(current.year, current.month, current.day, 19);

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

  final dinnerEnd = startTime.add(Duration(minutes: dinnerMinutes));
  final activityStart = dinnerEnd.add(const Duration(minutes: 10));
  final activityEnd = activityStart.add(Duration(minutes: activityMinutes));
  final treatStart = activityEnd.add(const Duration(minutes: 10));
  final treatEnd = treatStart.add(Duration(minutes: treatMinutes));

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
    id: 'date-night-${current.millisecondsSinceEpoch}',
    title: 'Date Night',
    location: 'Austin, TX',
    startTime: startTime,
    isDemo: true,
    steps: [
      PlanStep(
        id: 'dinner',
        type: PlanStepType.dinner,
        label: 'Dinner',
        placeName: 'Juniper & Rye',
        description: 'A cozy neighborhood table with shareable plates.',
        startTime: startTime,
        endTime: dinnerEnd,
        mapQuery: 'Juniper & Rye Austin TX',
      ),
      PlanStep(
        id: 'activity',
        type: PlanStepType.activity,
        label: 'Activity',
        placeName: activity.$1,
        description: activity.$2,
        startTime: activityStart,
        endTime: activityEnd,
        mapQuery: '${activity.$1} Austin TX',
      ),
      PlanStep(
        id: 'dessert',
        type: PlanStepType.dessertOrDrink,
        label: 'Dessert or drink',
        placeName: 'Luna Sweets & Sips',
        description: 'Split a warm dessert or toast with a nightcap.',
        startTime: treatStart,
        endTime: treatEnd,
        mapQuery: 'Luna Sweets and Sips Austin TX',
      ),
    ],
  );
}
