enum StopCategory { food, coffee, gas, bathrooms, scenic }

extension StopCategoryLabel on StopCategory {
  String get label => switch (this) {
    StopCategory.food => 'Food',
    StopCategory.coffee => 'Coffee',
    StopCategory.gas => 'Gas',
    StopCategory.bathrooms => 'Bathrooms',
    StopCategory.scenic => 'Scenic',
  };
}

class RouteSummary {
  const RouteSummary({
    required this.origin,
    required this.destination,
    required this.totalDistanceMiles,
    required this.estimatedDriveTime,
    required this.progress,
  });

  final String origin;
  final String destination;
  final int totalDistanceMiles;
  final Duration estimatedDriveTime;
  final double progress;
}

class RouteStop {
  const RouteStop({
    required this.id,
    required this.title,
    required this.locationLabel,
    required this.imageAsset,
    required this.categories,
    this.rating,
    this.reviewCount,
    this.distanceOffRouteMiles,
    this.detourTime,
    this.openNow,
  });

  final String id;
  final String title;
  final double? rating;
  final int? reviewCount;
  final double? distanceOffRouteMiles;
  final Duration? detourTime;
  final bool? openNow;
  final String locationLabel;
  final String imageAsset;
  final Set<StopCategory> categories;

  String get savedDescription {
    final ratingDescription = rating == null
        ? 'Rating unverified'
        : '${rating!.toStringAsFixed(1)} stars';
    return '$locationLabel · $ratingDescription';
  }
}

class RoutePlan {
  const RoutePlan({
    required this.id,
    required this.routeSubtitle,
    required this.summary,
    required this.stops,
    this.isDemo = false,
    this.strategy,
  });

  final String id;
  final String routeSubtitle;
  final RouteSummary summary;
  final List<RouteStop> stops;
  final bool isDemo;
  final String? strategy;
}
