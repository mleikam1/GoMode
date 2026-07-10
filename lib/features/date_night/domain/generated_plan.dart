enum PlanStepType { dinner, activity, dessertOrDrink }

class PlanStep {
  const PlanStep({
    required this.id,
    required this.type,
    required this.label,
    required this.placeName,
    required this.description,
    required this.startTime,
    required this.endTime,
    required this.mapQuery,
  });

  final String id;
  final PlanStepType type;
  final String label;
  final String placeName;
  final String description;
  final DateTime startTime;
  final DateTime endTime;
  final String mapQuery;
}

class GeneratedPlan {
  const GeneratedPlan({
    required this.id,
    required this.title,
    required this.location,
    required this.startTime,
    required this.steps,
    required this.isDemo,
  });

  final String id;
  final String title;
  final String location;
  final DateTime startTime;
  final List<PlanStep> steps;
  final bool isDemo;
}
