import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

enum ModeCategory {
  goOut('Go Out'),
  familyPets('Family & Pets'),
  road('Road'),
  healthOutdoors('Health & Outdoors'),
  homeLife('Home & Life'),
  game('Game');

  const ModeCategory(this.label);

  final String label;
}

enum ModeQueryStrategyType {
  nearbyPlaces,
  textSearch,
  routeSearch,
  environmental,
  solar,
  gameQuest,
  genericPlanGenerator,
}

class ModeDefaultFilter {
  const ModeDefaultFilter({
    required this.id,
    required this.label,
    required this.value,
  });

  final String id;
  final String label;
  final String value;
}

class ModeDemoResult {
  const ModeDemoResult({
    required this.title,
    required this.subtitle,
    required this.detail,
    required this.distanceLabel,
    required this.imageSemanticName,
    required this.tags,
  });

  final String title;
  final String subtitle;
  final String detail;
  final String distanceLabel;
  final String imageSemanticName;
  final List<String> tags;
}

class DiscoveryMode {
  const DiscoveryMode({
    required this.id,
    required this.title,
    required this.shortSubtitle,
    required this.longDescription,
    required this.category,
    required this.iconSemanticName,
    required this.accentColor,
    required this.defaultFilters,
    required this.queryStrategyType,
    required this.hasCustomScreen,
    required this.supportsMapResults,
    required this.supportsSaving,
    required this.demoResults,
  });

  final String id;
  final String title;
  final String shortSubtitle;
  final String longDescription;
  final ModeCategory category;
  final String iconSemanticName;
  final Color accentColor;
  final List<ModeDefaultFilter> defaultFilters;
  final ModeQueryStrategyType queryStrategyType;
  final bool hasCustomScreen;
  final bool supportsMapResults;
  final bool supportsSaving;
  final List<ModeDemoResult> demoResults;

  String get description => shortSubtitle;
}

const discoveryModes = <DiscoveryMode>[
  DiscoveryMode(
    id: 'date-night',
    title: 'Date Night',
    shortSubtitle: 'Romantic ideas without the planning spiral.',
    longDescription:
        'Build a polished night out around food, drinks, views, and a tiny surprise that feels intentional.',
    category: ModeCategory.goOut,
    iconSemanticName: 'favorite',
    accentColor: AppColors.coral,
    defaultFilters: [
      ModeDefaultFilter(id: 'mood', label: 'Mood', value: 'Cozy'),
      ModeDefaultFilter(id: 'budget', label: 'Budget', value: r'$$'),
      ModeDefaultFilter(id: 'time', label: 'Time', value: 'Tonight'),
    ],
    queryStrategyType: ModeQueryStrategyType.genericPlanGenerator,
    hasCustomScreen: true,
    supportsMapResults: true,
    supportsSaving: true,
    demoResults: [
      ModeDemoResult(
        title: 'Juneberry Table',
        subtitle: 'Candlelit dinner with a walkable dessert stop',
        detail: 'Reserve the patio, then stroll two blocks for gelato.',
        distanceLabel: '1.4 mi',
        imageSemanticName: 'date-night',
        tags: ['Dinner', 'Patio', 'Dessert nearby'],
      ),
      ModeDemoResult(
        title: 'Skyline Mini Date',
        subtitle: 'Sunset overlook, mocktails, and late jazz',
        detail: 'Low-pressure route with three easy stops after work.',
        distanceLabel: '3.2 mi',
        imageSemanticName: 'date-night',
        tags: ['Views', 'Music', 'Tonight'],
      ),
    ],
  ),
  DiscoveryMode(
    id: 'weekend-plan',
    title: 'Weekend Plan',
    shortSubtitle: 'Turn an open day into a real itinerary.',
    longDescription:
        'Balance food, outdoors, events, and downtime into a plan that fits the forecast and your energy.',
    category: ModeCategory.goOut,
    iconSemanticName: 'calendar',
    accentColor: AppColors.teal,
    defaultFilters: [
      ModeDefaultFilter(id: 'day', label: 'Day', value: 'Saturday'),
      ModeDefaultFilter(id: 'pace', label: 'Pace', value: 'Easy'),
      ModeDefaultFilter(id: 'group', label: 'Group', value: '2-4 people'),
    ],
    queryStrategyType: ModeQueryStrategyType.genericPlanGenerator,
    hasCustomScreen: false,
    supportsMapResults: true,
    supportsSaving: true,
    demoResults: [
      ModeDemoResult(
        title: 'Greenbelt to Good Tacos',
        subtitle: 'Trail time, coffee, and a late lunch',
        detail: 'A flexible half-day plan that keeps driving light.',
        distanceLabel: '4 stops',
        imageSemanticName: 'weekend',
        tags: ['Outdoors', 'Lunch', 'Half day'],
      ),
      ModeDemoResult(
        title: 'Market Morning Loop',
        subtitle: 'Farmers market, bookstore, and shaded patio',
        detail: 'Best before noon, with an optional museum add-on.',
        distanceLabel: '2.1 mi',
        imageSemanticName: 'weekend',
        tags: ['Morning', 'Walkable', 'Shaded'],
      ),
    ],
  ),
  DiscoveryMode(
    id: 'food-wheel',
    title: 'Food Wheel',
    shortSubtitle: 'Spin past dinner indecision.',
    longDescription:
        'Use quick constraints like cuisine, distance, and vibe to pick a food move when everyone is stuck.',
    category: ModeCategory.goOut,
    iconSemanticName: 'lunch_dining',
    accentColor: AppColors.amber,
    defaultFilters: [
      ModeDefaultFilter(
        id: 'distance',
        label: 'Distance',
        value: 'Within 15 min',
      ),
      ModeDefaultFilter(id: 'open', label: 'Open', value: 'Open now'),
      ModeDefaultFilter(id: 'format', label: 'Format', value: 'Casual'),
    ],
    queryStrategyType: ModeQueryStrategyType.nearbyPlaces,
    hasCustomScreen: true,
    supportsMapResults: true,
    supportsSaving: true,
    demoResults: [
      ModeDemoResult(
        title: 'Koko Noodle Bar',
        subtitle: 'Fast ramen with a strong late-night score',
        detail: 'Wheel pick for warm, quick, and under 20 minutes.',
        distanceLabel: '0.9 mi',
        imageSemanticName: 'food',
        tags: ['Ramen', 'Fast', 'Open now'],
      ),
      ModeDemoResult(
        title: 'Mesa Verde Tacos',
        subtitle: 'Counter-service tacos with picnic tables',
        detail: 'Good group fallback when nobody wants reservations.',
        distanceLabel: '1.7 mi',
        imageSemanticName: 'food',
        tags: ['Tacos', 'Casual', 'Group'],
      ),
    ],
  ),
  DiscoveryMode(
    id: 'patio-finder',
    title: 'Patio Finder',
    shortSubtitle: 'Outdoor tables that match the weather.',
    longDescription:
        'Find patios with the right shade, noise level, food format, and weather fit for right now.',
    category: ModeCategory.goOut,
    iconSemanticName: 'deck',
    accentColor: AppColors.green,
    defaultFilters: [
      ModeDefaultFilter(id: 'shade', label: 'Shade', value: 'Some shade'),
      ModeDefaultFilter(id: 'noise', label: 'Noise', value: 'Conversation'),
      ModeDefaultFilter(id: 'party', label: 'Party', value: '2 people'),
    ],
    queryStrategyType: ModeQueryStrategyType.nearbyPlaces,
    hasCustomScreen: false,
    supportsMapResults: true,
    supportsSaving: true,
    demoResults: [
      ModeDemoResult(
        title: 'Cedar & Shade',
        subtitle: 'Tree-covered patio with counter ordering',
        detail: 'Best for breezy evenings and easy meetups.',
        distanceLabel: '1.1 mi',
        imageSemanticName: 'patio',
        tags: ['Shade', 'Counter service', 'Dogs ok'],
      ),
      ModeDemoResult(
        title: 'The Courtyard Room',
        subtitle: 'Reservation-friendly courtyard with heaters',
        detail: 'A safer pick when the forecast gets uncertain.',
        distanceLabel: '2.6 mi',
        imageSemanticName: 'patio',
        tags: ['Reservations', 'Heaters', 'Quiet'],
      ),
    ],
  ),
  DiscoveryMode(
    id: 'cheap-date',
    title: 'Cheap Date',
    shortSubtitle: 'Low-cost plans that still feel thoughtful.',
    longDescription:
        'Pair free or inexpensive stops into a charming date that does not feel like a compromise.',
    category: ModeCategory.goOut,
    iconSemanticName: 'savings',
    accentColor: AppColors.coral,
    defaultFilters: [
      ModeDefaultFilter(id: 'budget', label: 'Budget', value: r'Under $40'),
      ModeDefaultFilter(id: 'transport', label: 'Transport', value: 'Walkable'),
      ModeDefaultFilter(id: 'duration', label: 'Duration', value: '2 hours'),
    ],
    queryStrategyType: ModeQueryStrategyType.textSearch,
    hasCustomScreen: false,
    supportsMapResults: true,
    supportsSaving: true,
    demoResults: [
      ModeDemoResult(
        title: 'Bookshop + Picnic Sodas',
        subtitle: 'Browse, pick a prompt, then sit outside',
        detail: 'Cute, cheap, and easy to bail or extend.',
        distanceLabel: r'$24 est.',
        imageSemanticName: 'date-night',
        tags: ['Low cost', 'Walkable', 'Conversation'],
      ),
      ModeDemoResult(
        title: 'Sunset Stair Loop',
        subtitle: 'Scenic walk with a shared pastry stop',
        detail: 'A gentle route with one reliable treat stop.',
        distanceLabel: r'$18 est.',
        imageSemanticName: 'weekend',
        tags: ['Free stop', 'Views', 'Dessert'],
      ),
    ],
  ),
  DiscoveryMode(
    id: 'food-challenge',
    title: 'Food Challenge',
    shortSubtitle: 'Make dinner into a tiny competition.',
    longDescription:
        'Create playful food missions around neighborhoods, cuisines, budgets, or mystery ratings.',
    category: ModeCategory.goOut,
    iconSemanticName: 'emoji_events',
    accentColor: AppColors.lavender,
    defaultFilters: [
      ModeDefaultFilter(id: 'rounds', label: 'Rounds', value: '3 stops'),
      ModeDefaultFilter(id: 'theme', label: 'Theme', value: 'Best bite'),
      ModeDefaultFilter(id: 'radius', label: 'Radius', value: '2 mi'),
    ],
    queryStrategyType: ModeQueryStrategyType.gameQuest,
    hasCustomScreen: false,
    supportsMapResults: true,
    supportsSaving: true,
    demoResults: [
      ModeDemoResult(
        title: 'Three Taco Tiebreaker',
        subtitle: 'Rate salsa, tortilla, and overall joy',
        detail: 'A low-stakes route with scoring prompts included.',
        distanceLabel: '3 stops',
        imageSemanticName: 'food',
        tags: ['Challenge', 'Tacos', 'Scorecard'],
      ),
      ModeDemoResult(
        title: 'Dessert Draft',
        subtitle: 'Each person drafts one sweet stop',
        detail: 'Winner picks the next neighborhood.',
        distanceLabel: '2.8 mi',
        imageSemanticName: 'food',
        tags: ['Dessert', 'Group', 'Game'],
      ),
    ],
  ),
  DiscoveryMode(
    id: 'kids-bored-button',
    title: 'Kids Bored Button',
    shortSubtitle: 'Fast family ideas when the day gets restless.',
    longDescription:
        'Surface kid-friendly activities by age, weather, nap windows, and how much energy needs burning.',
    category: ModeCategory.familyPets,
    iconSemanticName: 'family_restroom',
    accentColor: AppColors.green,
    defaultFilters: [
      ModeDefaultFilter(id: 'age', label: 'Age', value: '4-10'),
      ModeDefaultFilter(id: 'energy', label: 'Energy', value: 'High'),
      ModeDefaultFilter(id: 'weather', label: 'Weather', value: 'Any'),
    ],
    queryStrategyType: ModeQueryStrategyType.genericPlanGenerator,
    hasCustomScreen: false,
    supportsMapResults: true,
    supportsSaving: true,
    demoResults: [
      ModeDemoResult(
        title: 'Splash Pad Sprint',
        subtitle: 'Water play, snack stop, and shaded reset',
        detail: 'Built for a 90-minute energy burn.',
        distanceLabel: '12 min',
        imageSemanticName: 'family',
        tags: ['Kids', 'Outdoor', 'Snack'],
      ),
      ModeDemoResult(
        title: 'Library Quest Cards',
        subtitle: 'Indoor scavenger hunt with a treat nearby',
        detail: 'A calm plan for hot or stormy afternoons.',
        distanceLabel: '1.9 mi',
        imageSemanticName: 'family',
        tags: ['Indoor', 'Free', 'Rain safe'],
      ),
    ],
  ),
  DiscoveryMode(
    id: 'rainy-day-ideas',
    title: 'Rainy Day Ideas',
    shortSubtitle: 'Indoor plans that do not feel like settling.',
    longDescription:
        'Find museums, cozy cafes, arcades, classes, shops, and covered routes when the weather turns.',
    category: ModeCategory.familyPets,
    iconSemanticName: 'umbrella',
    accentColor: AppColors.primaryBlue,
    defaultFilters: [
      ModeDefaultFilter(id: 'indoor', label: 'Indoor', value: 'Required'),
      ModeDefaultFilter(id: 'drive', label: 'Drive', value: 'Under 20 min'),
      ModeDefaultFilter(id: 'crowd', label: 'Crowd', value: 'Low effort'),
    ],
    queryStrategyType: ModeQueryStrategyType.textSearch,
    hasCustomScreen: false,
    supportsMapResults: true,
    supportsSaving: true,
    demoResults: [
      ModeDemoResult(
        title: 'Museum + Cocoa Loop',
        subtitle: 'Dry parking, short walk, warm finish',
        detail: 'A simple route with low exposure to the weather.',
        distanceLabel: '2 stops',
        imageSemanticName: 'rain',
        tags: ['Indoor', 'Museum', 'Cozy'],
      ),
      ModeDemoResult(
        title: 'Covered Market Wander',
        subtitle: 'Food hall, records, and a dessert counter',
        detail: 'Good for groups because everyone can split up.',
        distanceLabel: '18 min',
        imageSemanticName: 'rain',
        tags: ['Covered', 'Food', 'Shopping'],
      ),
    ],
  ),
  DiscoveryMode(
    id: 'dog-friendly-spots',
    title: 'Dog-Friendly Spots',
    shortSubtitle: 'Places where the leash is welcome.',
    longDescription:
        'Find parks, patios, trails, shops, and service stops that work well with a dog in tow.',
    category: ModeCategory.familyPets,
    iconSemanticName: 'pets',
    accentColor: AppColors.amber,
    defaultFilters: [
      ModeDefaultFilter(id: 'patio', label: 'Patio', value: 'Dog friendly'),
      ModeDefaultFilter(id: 'water', label: 'Water', value: 'Bowls likely'),
      ModeDefaultFilter(id: 'walk', label: 'Walk', value: 'Nearby'),
    ],
    queryStrategyType: ModeQueryStrategyType.nearbyPlaces,
    hasCustomScreen: false,
    supportsMapResults: true,
    supportsSaving: true,
    demoResults: [
      ModeDemoResult(
        title: 'Barkyard Coffee',
        subtitle: 'Fenced side patio with shade and water bowls',
        detail: 'Easy morning stop before the pavement gets hot.',
        distanceLabel: '0.8 mi',
        imageSemanticName: 'dog',
        tags: ['Patio', 'Shade', 'Water bowls'],
      ),
      ModeDemoResult(
        title: 'Creekside Trailhead',
        subtitle: 'Wide path with a nearby pet shop',
        detail: 'Good loop for errands and a longer walk.',
        distanceLabel: '2.4 mi',
        imageSemanticName: 'dog',
        tags: ['Trail', 'Errand', 'Leashed'],
      ),
    ],
  ),
  DiscoveryMode(
    id: 'road-trip-stops',
    title: 'Road Trip Stops',
    shortSubtitle: 'Better breaks along the route.',
    longDescription:
        'Discover worthwhile food, views, bathrooms, parks, and oddball detours without wrecking the drive.',
    category: ModeCategory.road,
    iconSemanticName: 'directions_car',
    accentColor: AppColors.lavender,
    defaultFilters: [
      ModeDefaultFilter(id: 'detour', label: 'Detour', value: 'Under 12 min'),
      ModeDefaultFilter(id: 'stopType', label: 'Stop', value: 'Food + stretch'),
      ModeDefaultFilter(id: 'route', label: 'Route', value: 'Along the way'),
    ],
    queryStrategyType: ModeQueryStrategyType.routeSearch,
    hasCustomScreen: true,
    supportsMapResults: true,
    supportsSaving: true,
    demoResults: [
      ModeDemoResult(
        title: 'Prairie Vista Stop',
        subtitle: 'Scenic overlook with coffee 4 minutes off route',
        detail: 'A better reset than a gas station shoulder.',
        distanceLabel: '+8 min',
        imageSemanticName: 'road-trip',
        tags: ['Scenic', 'Coffee', 'Bathrooms'],
      ),
      ModeDemoResult(
        title: 'Exit 214 Food Hall',
        subtitle: 'Clean bathrooms, fast food variety, shaded tables',
        detail: 'High-confidence group stop with minimal detour.',
        distanceLabel: '+6 min',
        imageSemanticName: 'road-trip',
        tags: ['Food', 'Family', 'Quick'],
      ),
    ],
  ),
  DiscoveryMode(
    id: 'ev-charge-chill',
    title: 'EV Charge & Chill',
    shortSubtitle: 'Charging stops with something to do.',
    longDescription:
        'Pair charger availability with cafes, groceries, parks, or errands so charging time becomes useful time.',
    category: ModeCategory.road,
    iconSemanticName: 'ev_station',
    accentColor: AppColors.teal,
    defaultFilters: [
      ModeDefaultFilter(id: 'charger', label: 'Charger', value: 'Fast'),
      ModeDefaultFilter(id: 'walk', label: 'Walk', value: 'Under 5 min'),
      ModeDefaultFilter(id: 'activity', label: 'Activity', value: 'Cafe'),
    ],
    queryStrategyType: ModeQueryStrategyType.routeSearch,
    hasCustomScreen: false,
    supportsMapResults: true,
    supportsSaving: true,
    demoResults: [
      ModeDemoResult(
        title: 'North Loop Charge + Coffee',
        subtitle: 'Fast chargers behind a bakery and grocery',
        detail: 'A practical 35-minute stop with indoor seating.',
        distanceLabel: '6 stalls',
        imageSemanticName: 'ev',
        tags: ['Fast charge', 'Coffee', 'Groceries'],
      ),
      ModeDemoResult(
        title: 'Civic Center Chargers',
        subtitle: 'Park, restrooms, and playground nearby',
        detail: 'Good for families who need an actual break.',
        distanceLabel: '4 stalls',
        imageSemanticName: 'ev',
        tags: ['Park', 'Restrooms', 'Family'],
      ),
    ],
  ),
  DiscoveryMode(
    id: 'road-rescue',
    title: 'Road Rescue',
    shortSubtitle: 'Help when the trip goes sideways.',
    longDescription:
        'Find nearby repair, tires, towing, pharmacies, bathrooms, hotels, and essentials based on the problem.',
    category: ModeCategory.road,
    iconSemanticName: 'car_repair',
    accentColor: AppColors.warning,
    defaultFilters: [
      ModeDefaultFilter(id: 'need', label: 'Need', value: 'Repair'),
      ModeDefaultFilter(id: 'urgency', label: 'Urgency', value: 'Open now'),
      ModeDefaultFilter(id: 'distance', label: 'Distance', value: 'Closest'),
    ],
    queryStrategyType: ModeQueryStrategyType.routeSearch,
    hasCustomScreen: false,
    supportsMapResults: true,
    supportsSaving: false,
    demoResults: [
      ModeDemoResult(
        title: 'Oak Ridge Tire & Auto',
        subtitle: 'Open late with tow partner listed',
        detail: 'Priority pick for tire pressure and quick diagnostics.',
        distanceLabel: '7 min',
        imageSemanticName: 'road-rescue',
        tags: ['Open now', 'Tires', 'Tow'],
      ),
      ModeDemoResult(
        title: 'Travel Stop Essentials',
        subtitle: 'Restrooms, pharmacy shelf, basic tools',
        detail: 'A fast fallback for medicine, chargers, or supplies.',
        distanceLabel: '11 min',
        imageSemanticName: 'road-rescue',
        tags: ['Restrooms', 'Supplies', 'Fuel'],
      ),
    ],
  ),
  DiscoveryMode(
    id: 'open-now',
    title: 'Open Now',
    shortSubtitle: 'Useful places that are actually available.',
    longDescription:
        'Filter nearby options by current hours, late-night confidence, distance, and task type.',
    category: ModeCategory.goOut,
    iconSemanticName: 'schedule',
    accentColor: AppColors.primaryBlue,
    defaultFilters: [
      ModeDefaultFilter(id: 'hours', label: 'Hours', value: 'Open now'),
      ModeDefaultFilter(id: 'distance', label: 'Distance', value: 'Nearby'),
      ModeDefaultFilter(id: 'confidence', label: 'Confidence', value: 'High'),
    ],
    queryStrategyType: ModeQueryStrategyType.nearbyPlaces,
    hasCustomScreen: false,
    supportsMapResults: true,
    supportsSaving: true,
    demoResults: [
      ModeDemoResult(
        title: 'Late Counter Cafe',
        subtitle: 'Reliable hours and quick seating',
        detail: 'Good default when most kitchens are closing.',
        distanceLabel: '0.6 mi',
        imageSemanticName: 'open-now',
        tags: ['Open now', 'Food', 'Casual'],
      ),
      ModeDemoResult(
        title: '24th Street Market',
        subtitle: 'Essentials, snacks, and household basics',
        detail: 'Useful errand stop with strong hours confidence.',
        distanceLabel: '1.2 mi',
        imageSemanticName: 'open-now',
        tags: ['Errands', 'Late', 'Essentials'],
      ),
    ],
  ),
  DiscoveryMode(
    id: 'allergy-map',
    title: 'Allergy Map',
    shortSubtitle: 'Find easier places to breathe today.',
    longDescription:
        'Blend pollen, wind, trees, indoor options, and timing to suggest lower-allergy plans nearby.',
    category: ModeCategory.healthOutdoors,
    iconSemanticName: 'local_florist',
    accentColor: AppColors.amber,
    defaultFilters: [
      ModeDefaultFilter(id: 'allergen', label: 'Allergen', value: 'Pollen'),
      ModeDefaultFilter(id: 'exposure', label: 'Exposure', value: 'Lower'),
      ModeDefaultFilter(id: 'activity', label: 'Activity', value: 'Walk'),
    ],
    queryStrategyType: ModeQueryStrategyType.environmental,
    hasCustomScreen: false,
    supportsMapResults: true,
    supportsSaving: true,
    demoResults: [
      ModeDemoResult(
        title: 'River Path Low Pollen Window',
        subtitle: 'Better after 6 PM with south wind',
        detail: 'A gentler outdoor route based on demo conditions.',
        distanceLabel: '2.0 mi',
        imageSemanticName: 'allergy',
        tags: ['Lower pollen', 'Evening', 'Walk'],
      ),
      ModeDemoResult(
        title: 'Indoor Garden Cafe',
        subtitle: 'Planty atmosphere without the outdoor exposure',
        detail: 'A safer social option on high pollen afternoons.',
        distanceLabel: '1.5 mi',
        imageSemanticName: 'allergy',
        tags: ['Indoor', 'Cafe', 'Low exposure'],
      ),
    ],
  ),
  DiscoveryMode(
    id: 'clean-air-planner',
    title: 'Clean Air Planner',
    shortSubtitle: 'Plan around heat, smoke, and air quality.',
    longDescription:
        'Use AQI, temperature, shade, indoor backups, and timing to recommend healthier outings.',
    category: ModeCategory.healthOutdoors,
    iconSemanticName: 'air',
    accentColor: AppColors.teal,
    defaultFilters: [
      ModeDefaultFilter(id: 'aqi', label: 'AQI', value: 'Moderate or better'),
      ModeDefaultFilter(id: 'heat', label: 'Heat', value: 'Avoid peak'),
      ModeDefaultFilter(id: 'backup', label: 'Backup', value: 'Indoor nearby'),
    ],
    queryStrategyType: ModeQueryStrategyType.environmental,
    hasCustomScreen: false,
    supportsMapResults: true,
    supportsSaving: true,
    demoResults: [
      ModeDemoResult(
        title: 'Morning Shade Route',
        subtitle: 'Park loop with indoor backup two blocks away',
        detail: 'Demo plan tuned for heat and moderate AQI.',
        distanceLabel: '8 AM best',
        imageSemanticName: 'air',
        tags: ['Shade', 'AQI aware', 'Backup'],
      ),
      ModeDemoResult(
        title: 'Clean Air Museum Slot',
        subtitle: 'Indoor plan near a transit stop',
        detail: 'A low-exposure fallback for smoky afternoons.',
        distanceLabel: '14 min',
        imageSemanticName: 'air',
        tags: ['Indoor', 'Transit', 'Low exposure'],
      ),
    ],
  ),
  DiscoveryMode(
    id: 'solar-checker',
    title: 'Solar Checker',
    shortSubtitle: 'See whether a roof looks solar-ready.',
    longDescription:
        'Preview solar potential using address context, roof exposure, shade hints, and local planning assumptions.',
    category: ModeCategory.homeLife,
    iconSemanticName: 'wb_sunny',
    accentColor: AppColors.amber,
    defaultFilters: [
      ModeDefaultFilter(id: 'roof', label: 'Roof', value: 'South/west'),
      ModeDefaultFilter(id: 'shade', label: 'Shade', value: 'Estimate'),
      ModeDefaultFilter(id: 'bill', label: 'Bill', value: 'Optional'),
    ],
    queryStrategyType: ModeQueryStrategyType.solar,
    hasCustomScreen: false,
    supportsMapResults: false,
    supportsSaving: true,
    demoResults: [
      ModeDemoResult(
        title: 'South Roof Opportunity',
        subtitle: 'Strong afternoon exposure in demo estimate',
        detail: 'Sample insight for the future Solar API integration.',
        distanceLabel: 'High fit',
        imageSemanticName: 'solar',
        tags: ['Roof', 'Shade', 'Estimate'],
      ),
      ModeDemoResult(
        title: 'Tree Shade Tradeoff',
        subtitle: 'Moderate potential with summer shade risk',
        detail: 'Shows how recommendations can explain uncertainty.',
        distanceLabel: 'Medium fit',
        imageSemanticName: 'solar',
        tags: ['Shade', 'Trees', 'Review'],
      ),
    ],
  ),
  DiscoveryMode(
    id: 'neighborhood-check',
    title: 'Neighborhood Check',
    shortSubtitle: 'Understand a place before you go deep.',
    longDescription:
        'Compare nearby essentials, commute clues, parks, food, services, and daily-life signals.',
    category: ModeCategory.homeLife,
    iconSemanticName: 'location_city',
    accentColor: AppColors.primaryBlue,
    defaultFilters: [
      ModeDefaultFilter(
        id: 'essentials',
        label: 'Essentials',
        value: 'Groceries',
      ),
      ModeDefaultFilter(id: 'commute', label: 'Commute', value: 'Preview'),
      ModeDefaultFilter(
        id: 'walkability',
        label: 'Walkability',
        value: 'Local',
      ),
    ],
    queryStrategyType: ModeQueryStrategyType.textSearch,
    hasCustomScreen: false,
    supportsMapResults: true,
    supportsSaving: true,
    demoResults: [
      ModeDemoResult(
        title: 'Mueller Daily-Life Snapshot',
        subtitle: 'Groceries, parks, coffee, and errands nearby',
        detail: 'Demo summary of what a practical neighborhood scan can show.',
        distanceLabel: '12 signals',
        imageSemanticName: 'neighborhood',
        tags: ['Parks', 'Groceries', 'Walkable'],
      ),
      ModeDemoResult(
        title: 'South Lamar Tradeoffs',
        subtitle: 'Food density with commute variability',
        detail: 'Highlights the everyday pros and cons at a glance.',
        distanceLabel: '9 signals',
        imageSemanticName: 'neighborhood',
        tags: ['Food', 'Commute', 'Transit'],
      ),
    ],
  ),
  DiscoveryMode(
    id: 'where-should-i-live',
    title: 'Where Should I Live?',
    shortSubtitle: 'Match neighborhoods to your real routines.',
    longDescription:
        'Turn preferences, commute, budget, lifestyle, and must-haves into a shortlist of areas to explore.',
    category: ModeCategory.homeLife,
    iconSemanticName: 'home_work',
    accentColor: AppColors.lavender,
    defaultFilters: [
      ModeDefaultFilter(id: 'budget', label: 'Budget', value: 'Set later'),
      ModeDefaultFilter(id: 'commute', label: 'Commute', value: 'Key factor'),
      ModeDefaultFilter(id: 'lifestyle', label: 'Lifestyle', value: 'Balanced'),
    ],
    queryStrategyType: ModeQueryStrategyType.genericPlanGenerator,
    hasCustomScreen: false,
    supportsMapResults: true,
    supportsSaving: true,
    demoResults: [
      ModeDemoResult(
        title: 'Creative + Walkable Shortlist',
        subtitle: 'Three neighborhoods with strong third places',
        detail: 'Demo output for lifestyle-based ranking.',
        distanceLabel: '3 areas',
        imageSemanticName: 'home-life',
        tags: ['Walkable', 'Coffee', 'Budget fit'],
      ),
      ModeDemoResult(
        title: 'Quiet Commute Match',
        subtitle: 'Lower-noise areas with practical errands',
        detail: 'Balances routine needs with calm evenings.',
        distanceLabel: '4 areas',
        imageSemanticName: 'home-life',
        tags: ['Quiet', 'Commute', 'Errands'],
      ),
    ],
  ),
  DiscoveryMode(
    id: 'local-quest',
    title: 'Local Quest',
    shortSubtitle: 'A playful mission around town.',
    longDescription:
        'Generate a local scavenger-style quest with clues, stops, points, and optional team play.',
    category: ModeCategory.game,
    iconSemanticName: 'explore',
    accentColor: AppColors.amber,
    defaultFilters: [
      ModeDefaultFilter(id: 'time', label: 'Time', value: '60 min'),
      ModeDefaultFilter(id: 'difficulty', label: 'Difficulty', value: 'Easy'),
      ModeDefaultFilter(id: 'team', label: 'Team', value: 'Any'),
    ],
    queryStrategyType: ModeQueryStrategyType.gameQuest,
    hasCustomScreen: true,
    supportsMapResults: true,
    supportsSaving: true,
    demoResults: [
      ModeDemoResult(
        title: 'Mural Clue Sprint',
        subtitle: 'Find three murals and decode a final cafe clue',
        detail: 'A one-hour quest built for a walkable district.',
        distanceLabel: '60 min',
        imageSemanticName: 'quest',
        tags: ['Clues', 'Walking', 'Points'],
      ),
      ModeDemoResult(
        title: 'Park Badge Run',
        subtitle: 'Collect tiny wins across trail, bridge, and snack stop',
        detail: 'Designed for groups who want a light game layer.',
        distanceLabel: '4 stops',
        imageSemanticName: 'quest',
        tags: ['Game', 'Outdoors', 'Team'],
      ),
    ],
  ),
  DiscoveryMode(
    id: 'tourist-mode',
    title: 'Tourist Mode',
    shortSubtitle: 'See your city like you just arrived.',
    longDescription:
        'Create a first-timer route with iconic stops, local favorites, photos, food, and easy pacing.',
    category: ModeCategory.goOut,
    iconSemanticName: 'camera_alt',
    accentColor: AppColors.coral,
    defaultFilters: [
      ModeDefaultFilter(id: 'duration', label: 'Duration', value: 'Half day'),
      ModeDefaultFilter(id: 'style', label: 'Style', value: 'Iconic + local'),
      ModeDefaultFilter(id: 'pace', label: 'Pace', value: 'Walkable'),
    ],
    queryStrategyType: ModeQueryStrategyType.genericPlanGenerator,
    hasCustomScreen: false,
    supportsMapResults: true,
    supportsSaving: true,
    demoResults: [
      ModeDemoResult(
        title: 'First-Timer Photo Loop',
        subtitle: 'Landmark, local bite, record shop, skyline view',
        detail: 'A polished route for visitors or staycation energy.',
        distanceLabel: '4 stops',
        imageSemanticName: 'tourist',
        tags: ['Photos', 'Food', 'Landmarks'],
      ),
      ModeDemoResult(
        title: 'Local Classic Sampler',
        subtitle: 'Two favorites and one overlooked stop',
        detail: 'Feels touristy in the best possible way.',
        distanceLabel: '3.5 mi',
        imageSemanticName: 'tourist',
        tags: ['Classic', 'Local', 'Half day'],
      ),
    ],
  ),
];
