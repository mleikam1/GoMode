import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/generated_plan.dart';

final generatedPlanStoreProvider = Provider<GeneratedPlanStore>((ref) {
  return InMemoryGeneratedPlanStore();
});

abstract interface class GeneratedPlanStore {
  Future<void> save(GeneratedPlan plan);

  bool contains(String planId);
}

class InMemoryGeneratedPlanStore implements GeneratedPlanStore {
  final Map<String, GeneratedPlan> _plans = {};

  @override
  bool contains(String planId) => _plans.containsKey(planId);

  @override
  Future<void> save(GeneratedPlan plan) async {
    _plans[plan.id] = plan;
  }
}
