import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../features/saved/application/saved_library_controller.dart';
import '../../../features/saved/domain/saved_item.dart';
import '../../../features/monetization/domain/monetization_models.dart';
import '../../../features/monetization/presentation/rewarded_unlock_button.dart';
import '../../../shared/widgets/primary_gradient_button.dart';
import '../data/generated_plan_store.dart';
import '../domain/generated_plan.dart';

class DateNightPlanScreen extends ConsumerStatefulWidget {
  const DateNightPlanScreen({required this.plan, super.key});

  final GeneratedPlan plan;

  @override
  ConsumerState<DateNightPlanScreen> createState() =>
      _DateNightPlanScreenState();
}

class _DateNightPlanScreenState extends ConsumerState<DateNightPlanScreen> {
  bool _isSaving = false;
  bool _legacySaved = false;

  @override
  void initState() {
    super.initState();
    _legacySaved = ref
        .read(generatedPlanStoreProvider)
        .contains(widget.plan.id);
  }

  @override
  Widget build(BuildContext context) {
    final library = ref.watch(savedLibraryProvider);
    final saved = library.maybeWhen(
      data: (value) => _legacySaved || value.contains(_savedItemId),
      orElse: () => _legacySaved,
    );
    return ColoredBox(
      color: AppColors.surface,
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: _PlanHeader(onBack: _goBack)),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.page,
              AppSpacing.page,
              AppSpacing.page,
              0,
            ),
            sliver: SliverList.list(
              children: [
                _PlanSummary(plan: widget.plan),
                const SizedBox(height: AppSpacing.xl),
                Text(
                  'Your evening',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: AppSpacing.sm),
                for (var index = 0; index < widget.plan.steps.length; index++)
                  _PlanStepCard(
                    step: widget.plan.steps[index],
                    index: index,
                    isLast: index == widget.plan.steps.length - 1,
                  ),
                const SizedBox(height: AppSpacing.xs),
                PrimaryGradientButton(
                  key: const ValueKey('save-generated-plan-button'),
                  label: saved
                      ? 'Saved'
                      : _isSaving
                      ? 'Saving...'
                      : 'Save Plan',
                  icon: saved
                      ? Icons.bookmark_added_rounded
                      : Icons.bookmark_add_outlined,
                  foregroundColor: _isSaving
                      ? AppColors.textSecondary
                      : AppColors.white,
                  onPressed: _isSaving ? null : () => _togglePlan(saved),
                ),
                const SizedBox(height: AppSpacing.sm),
                OutlinedButton.icon(
                  key: const ValueKey('open-plan-map-button'),
                  onPressed: () => context.go('/map'),
                  icon: const Icon(Icons.map_outlined),
                  label: const Text('Open Map'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primaryBlue,
                    minimumSize: const Size.fromHeight(54),
                    side: const BorderSide(color: AppColors.borderStrong),
                    shape: const StadiumBorder(),
                    textStyle: Theme.of(context).textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w900),
                  ),
                ),
                const RewardedUnlockButton(
                  unlock: RewardedUnlock.extraDateNightPlan(),
                ),
                const SizedBox(
                  height: AppSpacing.bottomNavHeight + AppSpacing.xl,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _goBack() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/modes/date-night');
    }
  }

  String get _savedItemId => 'date-night-plan-${widget.plan.id}';

  SavedItem get _savedItem => SavedItem(
    id: _savedItemId,
    type: SavedItemType.plan,
    categoryLabel: 'Date Night',
    title: widget.plan.title,
    description:
        'Dinner, an activity, and a sweet finish in ${widget.plan.location}',
    savedAt: DateTime.now(),
    status: SavedItemStatus.saved,
    visual: SavedItemVisual.dateNight,
    imageAsset: 'assets/images/saved/date_night.png',
    destinationPath: '/modes/date-night',
  );

  Future<void> _togglePlan(bool saved) async {
    setState(() => _isSaving = true);
    if (!saved) {
      await ref.read(generatedPlanStoreProvider).save(widget.plan);
    }
    if (!mounted) {
      return;
    }

    setState(() {
      _isSaving = false;
      _legacySaved = !saved;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          saved
              ? 'Date Night plan removed from saved.'
              : 'Date Night plan saved locally.',
        ),
      ),
    );

    await ref.read(savedLibraryProvider.future);
    if (saved) {
      await ref.read(savedLibraryProvider.notifier).removeItem(_savedItemId);
    } else {
      await ref.read(savedLibraryProvider.notifier).saveItem(_savedItem);
    }
  }
}

class _PlanHeader extends StatelessWidget {
  const _PlanHeader({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: AppColors.headerGradient,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(AppRadius.xxl),
          bottomRight: Radius.circular(AppRadius.xxl),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
          child: SizedBox(
            height: 52,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: Material(
                    color: AppColors.white.withValues(alpha: 0.08),
                    shape: CircleBorder(
                      side: BorderSide(
                        color: AppColors.white.withValues(alpha: 0.16),
                      ),
                    ),
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: onBack,
                      child: const SizedBox(
                        width: 48,
                        height: 48,
                        child: Icon(
                          Icons.arrow_back_rounded,
                          color: AppColors.white,
                        ),
                      ),
                    ),
                  ),
                ),
                Text(
                  "Tonight's Plan",
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: AppColors.white,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PlanSummary extends StatelessWidget {
  const _PlanSummary({required this.plan});

  final GeneratedPlan plan;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: AppColors.pinkGradient,
        borderRadius: AppRadius.largeCard,
        boxShadow: AppShadows.glowCoral,
      ),
      child: Row(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: AppColors.white.withValues(alpha: 0.72),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.favorite_rounded,
              color: AppColors.coral,
              size: 30,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Your Date Night',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 5),
                Text(
                  '${plan.location}  ·  Starts ${formatPlanTime(plan.startTime)}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textPrimary.withValues(alpha: 0.76),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (plan.isDemo) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.white.withValues(alpha: 0.72),
                      borderRadius: AppRadius.chip,
                    ),
                    child: Text(
                      'Demo fallback',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppColors.coral,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PlanStepCard extends StatelessWidget {
  const _PlanStepCard({
    required this.step,
    required this.index,
    required this.isLast,
  });

  final PlanStep step;
  final int index;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? AppSpacing.sm : AppSpacing.md),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.surfaceRaised,
          borderRadius: AppRadius.card,
          border: Border.all(color: AppColors.border),
          boxShadow: AppShadows.soft,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: AppColors.coral.withValues(alpha: 0.11),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _iconFor(step.type),
                color: AppColors.coral,
                size: 26,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${index + 1}. ${step.label}',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: AppColors.coral,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${formatPlanTime(step.startTime)}–${formatPlanTime(step.endTime)}',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: AppColors.textMuted,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    step.placeName,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(step.description),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

IconData _iconFor(PlanStepType type) {
  return switch (type) {
    PlanStepType.dinner => Icons.restaurant_rounded,
    PlanStepType.activity => Icons.local_activity_outlined,
    PlanStepType.dessertOrDrink => Icons.local_cafe_outlined,
  };
}

String formatPlanTime(DateTime time) {
  final hour = time.hour % 12 == 0 ? 12 : time.hour % 12;
  final minute = time.minute.toString().padLeft(2, '0');
  final suffix = time.hour >= 12 ? 'PM' : 'AM';
  return '$hour:$minute $suffix';
}
