import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_spacing.dart';
import '../../monetization/presentation/sponsored_card.dart';
import '../../../shared/widgets/app_motion.dart';
import '../domain/route_plan.dart';

class RouteResultsList extends StatelessWidget {
  const RouteResultsList({
    required this.stops,
    required this.savedStopIds,
    required this.onSave,
    required this.onFavorite,
    required this.onNavigate,
    super.key,
  });

  final List<RouteStop> stops;
  final Set<String> savedStopIds;
  final ValueChanged<RouteStop> onSave;
  final ValueChanged<RouteStop> onFavorite;
  final ValueChanged<RouteStop> onNavigate;

  @override
  Widget build(BuildContext context) {
    if (stops.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(AppSpacing.xl),
        decoration: BoxDecoration(
          color: AppColors.surfaceRaised,
          borderRadius: AppRadius.largeCard,
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          children: [
            const Icon(
              Icons.filter_alt_off_rounded,
              color: AppColors.textMuted,
              size: 38,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'No stops match these filters',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        for (var index = 0; index < stops.length; index++) ...[
          _RouteStopCard(
            stop: stops[index],
            saved: savedStopIds.contains(stops[index].id),
            onSave: () => onSave(stops[index]),
            onFavorite: () => onFavorite(stops[index]),
            onNavigate: () => onNavigate(stops[index]),
          ),
          if (index == 0)
            const SponsoredCard(
              placementId: 'road-trip-results',
              topSpacing: AppSpacing.sm,
            ),
          if (index != stops.length - 1) const SizedBox(height: AppSpacing.xs),
        ],
      ],
    );
  }
}

class _RouteStopCard extends StatelessWidget {
  const _RouteStopCard({
    required this.stop,
    required this.saved,
    required this.onSave,
    required this.onFavorite,
    required this.onNavigate,
  });

  final RouteStop stop;
  final bool saved;
  final VoidCallback onSave;
  final VoidCallback onFavorite;
  final VoidCallback onNavigate;

  @override
  Widget build(BuildContext context) {
    return PressScale(
      child: Container(
        key: ValueKey('route-stop-${stop.id}'),
        height: 132,
        padding: const EdgeInsets.all(9),
        decoration: BoxDecoration(
          color: AppColors.surfaceRaised,
          borderRadius: AppRadius.largeCard,
          border: Border.all(color: AppColors.border.withValues(alpha: 0.72)),
          boxShadow: AppShadows.soft,
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final imageWidth = constraints.maxWidth >= 410 ? 143.0 : 112.0;
            final cacheWidth =
                (imageWidth * MediaQuery.devicePixelRatioOf(context)).ceil();
            return Row(
              children: [
                SizedBox(
                  width: imageWidth,
                  height: double.infinity,
                  child: ClipRRect(
                    borderRadius: AppRadius.mdBorder,
                    child: Transform.scale(
                      scale: stop.id == 'bucees-new-braunfels' ? 1.25 : 1,
                      alignment: Alignment.bottomCenter,
                      child: Image.asset(
                        stop.imageAsset,
                        fit: BoxFit.cover,
                        cacheWidth: cacheWidth,
                        filterQuality: FilterQuality.medium,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        height: 27,
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                stop.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(
                                      fontWeight: FontWeight.w900,
                                      fontSize: 17,
                                    ),
                              ),
                            ),
                            SizedBox(
                              width: 34,
                              height: 34,
                              child: IconButton(
                                key: ValueKey('favorite-stop-${stop.id}'),
                                tooltip: saved
                                    ? 'Remove ${stop.title} from saved stops'
                                    : 'Save ${stop.title}',
                                onPressed: onFavorite,
                                padding: EdgeInsets.zero,
                                iconSize: 22,
                                color: saved
                                    ? AppColors.coral
                                    : AppColors.textSecondary,
                                icon: Icon(
                                  saved
                                      ? Icons.favorite_rounded
                                      : Icons.favorite_border_rounded,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      _RatingRow(stop: stop),
                      const SizedBox(height: 1),
                      Text(
                        '${_distanceLabel(stop.distanceOffRouteMiles)}  •  ${stop.locationLabel}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                          fontSize: 11.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          _InfoPill(
                            icon: Icons.schedule_rounded,
                            label: stop.detourTime == null
                                ? 'Detour not computed'
                                : '${stop.detourTime!.inMinutes} min detour',
                            color: AppColors.lavender,
                          ),
                          const SizedBox(width: 6),
                          _InfoPill(
                            icon: switch (stop.openNow) {
                              true => Icons.check_circle_rounded,
                              false => Icons.cancel_rounded,
                              null => Icons.help_outline_rounded,
                            },
                            label: switch (stop.openNow) {
                              true => 'Open now',
                              false => 'Closed now',
                              null => 'Hours unverified',
                            },
                            color: switch (stop.openNow) {
                              true => AppColors.success,
                              false => AppColors.coral,
                              null => AppColors.textMuted,
                            },
                          ),
                        ],
                      ),
                      const Spacer(),
                      Row(
                        children: [
                          Expanded(
                            child: _StopActionButton(
                              key: ValueKey('save-stop-${stop.id}'),
                              label: saved ? 'Saved' : 'Save',
                              icon: saved
                                  ? Icons.bookmark_rounded
                                  : Icons.bookmark_border_rounded,
                              onTap: onSave,
                            ),
                          ),
                          const SizedBox(width: 7),
                          Expanded(
                            child: _StopActionButton(
                              key: ValueKey('navigate-stop-${stop.id}'),
                              label: 'Navigate',
                              icon: Icons.navigation_rounded,
                              onTap: onNavigate,
                              filled: true,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _RatingRow extends StatelessWidget {
  const _RatingRow({required this.stop});

  final RouteStop stop;

  @override
  Widget build(BuildContext context) {
    final rating = stop.rating;
    if (rating == null) {
      return Row(
        children: [
          const Icon(
            Icons.star_outline_rounded,
            size: 14,
            color: AppColors.textMuted,
          ),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              stop.reviewCount == null
                  ? 'Rating & reviews unverified'
                  : 'Rating unverified (${_formatCount(stop.reviewCount!)} reviews)',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: AppColors.textMuted,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      );
    }
    return Row(
      children: [
        for (var index = 0; index < 5; index++)
          Icon(_starIcon(rating, index), size: 14, color: AppColors.amber),
        const SizedBox(width: 5),
        Text(
          rating.toStringAsFixed(1),
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(width: 5),
        Flexible(
          child: Text(
            stop.reviewCount == null
                ? '(reviews unverified)'
                : '(${_formatCount(stop.reviewCount!)})',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: AppColors.textMuted,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

String _distanceLabel(double? distanceOffRouteMiles) {
  return distanceOffRouteMiles == null
      ? 'Distance off route not computed'
      : '${distanceOffRouteMiles.toStringAsFixed(1)} mi off route';
}

IconData _starIcon(double rating, int index) {
  final remaining = rating - index;
  if (remaining >= 0.75) {
    return Icons.star_rounded;
  }
  if (remaining >= 0.25) {
    return Icons.star_half_rounded;
  }
  return Icons.star_border_rounded;
}

class _InfoPill extends StatelessWidget {
  const _InfoPill({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Flexible(
      child: Container(
        height: 22,
        padding: const EdgeInsets.symmetric(horizontal: 7),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: AppRadius.chip,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: color),
            const SizedBox(width: 3),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: color,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StopActionButton extends StatelessWidget {
  const _StopActionButton({
    required this.label,
    required this.icon,
    required this.onTap,
    super.key,
    this.filled = false,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final foreground = filled ? AppColors.white : AppColors.primaryBlue;
    return Material(
      color: filled ? AppColors.primaryBlue : Colors.transparent,
      shape: StadiumBorder(
        side: BorderSide(
          color: filled ? AppColors.primaryBlue : AppColors.primaryBlue,
        ),
      ),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: onTap,
        child: SizedBox(
          height: 27,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: foreground, size: 16),
              const SizedBox(width: 5),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: foreground,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String _formatCount(int count) {
  final value = count.toString();
  if (value.length <= 3) {
    return value;
  }

  return '${value.substring(0, value.length - 3)},${value.substring(value.length - 3)}';
}
