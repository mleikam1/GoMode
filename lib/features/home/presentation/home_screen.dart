import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../../data/models/discovery_mode.dart';
import '../../../data/repositories/discovery_repository.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final modes = ref.watch(discoveryRepositoryProvider).getModes();
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text(AppConstants.appName)),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
              sliver: SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppConstants.appName,
                      style: textTheme.displaySmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      AppConstants.tagline,
                      style: textTheme.titleMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 28),
                    Text(
                      AppConstants.primaryQuestion,
                      style: textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              sliver: SliverLayoutBuilder(
                builder: (context, constraints) {
                  if (constraints.crossAxisExtent <= 0) {
                    return const SliverToBoxAdapter(child: SizedBox.shrink());
                  }

                  return SliverGrid.builder(
                    itemCount: modes.length,
                    gridDelegate:
                        const SliverGridDelegateWithMaxCrossAxisExtent(
                          maxCrossAxisExtent: 260,
                          mainAxisExtent: 124,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                        ),
                    itemBuilder: (context, index) =>
                        _ModeTile(mode: modes[index]),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ModeTile extends StatelessWidget {
  const _ModeTile({required this.mode});

  final DiscoveryMode mode;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {},
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(_iconForMode(mode.id), color: colorScheme.primary),
              const Spacer(),
              Text(
                mode.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                mode.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

IconData _iconForMode(String id) {
  return switch (id) {
    'date-night' => Icons.favorite_border,
    'weekend' => Icons.calendar_month_outlined,
    'food-wheel' => Icons.restaurant_menu_outlined,
    'road-trip' => Icons.route_outlined,
    'family' => Icons.family_restroom_outlined,
    'pets' => Icons.pets_outlined,
    'health-outdoors' => Icons.forest_outlined,
    'home-life' => Icons.home_work_outlined,
    'local-games' => Icons.sports_esports_outlined,
    'coffee' => Icons.coffee_outlined,
    'happy-hour' => Icons.local_bar_outlined,
    'live-music' => Icons.music_note_outlined,
    'arts-culture' => Icons.palette_outlined,
    'shopping' => Icons.shopping_bag_outlined,
    'rainy-day' => Icons.umbrella_outlined,
    'solo' => Icons.self_improvement_outlined,
    'friends' => Icons.groups_outlined,
    'budget' => Icons.savings_outlined,
    'special-occasion' => Icons.celebration_outlined,
    'surprise-me' => Icons.auto_awesome_outlined,
    _ => Icons.explore_outlined,
  };
}
