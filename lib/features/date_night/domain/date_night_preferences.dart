enum DateNightBudget {
  twentyFive(r'$25'),
  fifty(r'$50'),
  oneHundredPlus(r'$100+');

  const DateNightBudget(this.label);

  final String label;
}

enum DateNightVibe {
  romantic('Romantic'),
  fun('Fun'),
  casual('Casual');

  const DateNightVibe(this.label);

  final String label;
}

enum DateNightDuration {
  oneHour('1 hr'),
  twoHours('2 hrs'),
  allEvening('All evening');

  const DateNightDuration(this.label);

  final String label;
}

class DateNightPreferences {
  const DateNightPreferences({
    required this.budget,
    required this.vibe,
    required this.duration,
    required this.indoor,
    required this.outdoor,
    required this.openNow,
  });

  const DateNightPreferences.defaults()
    : budget = DateNightBudget.fifty,
      vibe = DateNightVibe.romantic,
      duration = DateNightDuration.twoHours,
      indoor = true,
      outdoor = true,
      openNow = true;

  final DateNightBudget budget;
  final DateNightVibe vibe;
  final DateNightDuration duration;
  final bool indoor;
  final bool outdoor;
  final bool openNow;

  DateNightPreferences copyWith({
    DateNightBudget? budget,
    DateNightVibe? vibe,
    DateNightDuration? duration,
    bool? indoor,
    bool? outdoor,
    bool? openNow,
  }) {
    return DateNightPreferences(
      budget: budget ?? this.budget,
      vibe: vibe ?? this.vibe,
      duration: duration ?? this.duration,
      indoor: indoor ?? this.indoor,
      outdoor: outdoor ?? this.outdoor,
      openNow: openNow ?? this.openNow,
    );
  }
}
