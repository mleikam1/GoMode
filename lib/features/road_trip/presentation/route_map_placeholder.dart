import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_spacing.dart';
import '../domain/route_plan.dart';

class RouteMapPlaceholder extends StatelessWidget {
  const RouteMapPlaceholder({
    required this.plan,
    required this.onOpenFullMap,
    super.key,
  });

  final RoutePlan plan;
  final VoidCallback onOpenFullMap;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey('route-map-placeholder'),
      constraints: const BoxConstraints(minHeight: 430),
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surfaceRaised,
        borderRadius: AppRadius.largeCard,
        border: Border.all(color: AppColors.border),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.xl),
            decoration: BoxDecoration(
              color: AppColors.surfaceTint,
              borderRadius: AppRadius.xlBorder,
            ),
            child: Column(
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    shape: BoxShape.circle,
                    boxShadow: AppShadows.soft,
                  ),
                  child: const Icon(
                    Icons.map_rounded,
                    color: AppColors.primaryBlue,
                    size: 38,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'Route map preview',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 4),
                Text(
                  plan.routeSubtitle,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                _RouteEndpoints(summary: plan.summary),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          for (var index = 0; index < plan.stops.length; index++) ...[
            Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: AppColors.primaryBlue.withValues(alpha: 0.10),
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '${index + 1}',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: AppColors.primaryBlue,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    plan.stops[index].title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                Text(
                  plan.stops[index].detourTime == null
                      ? 'Not computed'
                      : '+${plan.stops[index].detourTime!.inMinutes} min',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.lavender,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            if (index != plan.stops.length - 1)
              const SizedBox(height: AppSpacing.sm),
          ],
          const SizedBox(height: AppSpacing.lg),
          OutlinedButton.icon(
            onPressed: onOpenFullMap,
            icon: const Icon(Icons.open_in_new_rounded),
            label: const Text('Open full map'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primaryBlue,
              minimumSize: const Size.fromHeight(48),
              side: const BorderSide(color: AppColors.borderStrong),
              shape: const StadiumBorder(),
              textStyle: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900),
            ),
          ),
        ],
      ),
    );
  }
}

class _RouteEndpoints extends StatelessWidget {
  const _RouteEndpoints({required this.summary});

  final RouteSummary summary;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.trip_origin_rounded, color: AppColors.teal, size: 20),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            summary.origin,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelMedium,
          ),
        ),
        Expanded(
          child: Container(
            height: 2,
            margin: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
            color: AppColors.primaryBlue.withValues(alpha: 0.28),
          ),
        ),
        const Icon(Icons.location_on_rounded, color: AppColors.coral, size: 22),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            summary.destination,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.end,
            style: Theme.of(context).textTheme.labelMedium,
          ),
        ),
      ],
    );
  }
}
