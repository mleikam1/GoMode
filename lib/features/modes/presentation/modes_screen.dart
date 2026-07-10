import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../data/models/discovery_mode.dart';
import '../../../data/services/mode_catalog.dart';
import '../../../shared/widgets/shared_widgets.dart';
import 'mode_visuals.dart';

class ModesScreen extends ConsumerStatefulWidget {
  const ModesScreen({super.key});

  @override
  ConsumerState<ModesScreen> createState() => _ModesScreenState();
}

class _ModesScreenState extends ConsumerState<ModesScreen> {
  late final TextEditingController _searchController;
  late final PageController _topModesController;

  _QuickFilter? _selectedFilter = _QuickFilter.popular;
  ModeCategory? _focusedCategory;
  String _query = '';
  int _topModePage = 0;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _topModesController = PageController(viewportFraction: 0.54);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _topModesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final catalog = ref.watch(modeCatalogProvider);
    final visibleModes = _visibleModes(catalog);
    final visibleModeIds = visibleModes.map((mode) => mode.id).toSet();
    final featuredModes = catalog.featuredModes
        .where((mode) => visibleModeIds.contains(mode.id))
        .toList();
    final visibleCategories = catalog.latestDiscoveryCategories.where((
      category,
    ) {
      if (_focusedCategory != null && category != _focusedCategory) {
        return false;
      }
      return catalog
          .latestByCategory(category)
          .any((mode) => visibleModeIds.contains(mode.id));
    }).toList();
    final compactPhone =
        MediaQuery.sizeOf(context).width < AppBreakpoints.compactPhone;

    return ColoredBox(
      color: AppColors.surface,
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: GradientHeader(
              compact: compactPhone,
              title: 'Modes',
              subtitle: 'Choose what you want to do',
              bottom: _ModesHeaderControls(
                searchController: _searchController,
                selectedFilter: _selectedFilter,
                onSearchChanged: _setQuery,
                onFilterSelected: _selectFilter,
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.lg)),
          if (visibleModes.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: _NoModesFound(query: _query),
            )
          else ...[
            if (featuredModes.isNotEmpty) ...[
              SliverToBoxAdapter(
                child: _TopModesCarousel(
                  controller: _topModesController,
                  currentPage: _topModePage.clamp(0, featuredModes.length - 1),
                  modes: featuredModes,
                  onPageChanged: (page) {
                    setState(() {
                      _topModePage = page;
                    });
                  },
                  onSeeAllTap: () => _selectFilter(_QuickFilter.popular),
                  onModeTap: _openMode,
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xl)),
            ],
            for (final category in visibleCategories) ...[
              SliverToBoxAdapter(
                child: _ModeCategorySection(
                  title: category.label,
                  modes: catalog
                      .latestByCategory(category)
                      .where((mode) => visibleModeIds.contains(mode.id))
                      .toList(),
                  onSeeAllTap: () => _focusCategory(category),
                  onModeTap: _openMode,
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.lg)),
            ],
          ],
          SliverToBoxAdapter(
            child: SizedBox(
              height: AppSpacing.bottomNavHeight + AppSpacing.xxl,
            ),
          ),
        ],
      ),
    );
  }

  List<DiscoveryMode> _visibleModes(ModeCatalog catalog) {
    return catalog.latestDiscoverableModes.where((mode) {
      if (_focusedCategory != null && mode.category != _focusedCategory) {
        return false;
      }
      return _matchesQuery(mode) && _matchesFilter(mode);
    }).toList();
  }

  bool _matchesQuery(DiscoveryMode mode) {
    final query = _query.trim().toLowerCase();
    if (query.isEmpty) {
      return true;
    }

    return mode.title.toLowerCase().contains(query) ||
        mode.category.label.toLowerCase().contains(query) ||
        mode.shortSubtitle.toLowerCase().contains(query);
  }

  bool _matchesFilter(DiscoveryMode mode) {
    return switch (_selectedFilter) {
      null || _QuickFilter.popular => true,
      _QuickFilter.nearby =>
        mode.queryStrategyType == ModeQueryStrategyType.nearbyPlaces ||
            mode.queryStrategyType == ModeQueryStrategyType.textSearch,
      _QuickFilter.family => mode.category == ModeCategory.familyPets,
      _QuickFilter.road => mode.category == ModeCategory.road,
      _QuickFilter.health => mode.category == ModeCategory.healthOutdoors,
    };
  }

  void _setQuery(String value) {
    setState(() {
      _query = value;
      _topModePage = 0;
    });
    _jumpTopModesToStart();
  }

  void _selectFilter(_QuickFilter filter) {
    setState(() {
      _selectedFilter = filter;
      _focusedCategory = null;
      _topModePage = 0;
    });
    _jumpTopModesToStart();
  }

  void _focusCategory(ModeCategory category) {
    setState(() {
      _selectedFilter = null;
      _focusedCategory = category;
      _topModePage = 0;
    });
    _jumpTopModesToStart();
  }

  void _jumpTopModesToStart() {
    if (_topModesController.hasClients) {
      _topModesController.jumpToPage(0);
    }
  }

  void _openMode(DiscoveryMode mode) {
    context.go('/modes/${mode.id}');
  }
}

enum _QuickFilter { popular, nearby, family, road, health }

class _QuickFilterSpec {
  const _QuickFilterSpec({
    required this.filter,
    required this.label,
    required this.icon,
    required this.color,
  });

  final _QuickFilter filter;
  final String label;
  final IconData icon;
  final Color color;
}

const _quickFilters = <_QuickFilterSpec>[
  _QuickFilterSpec(
    filter: _QuickFilter.popular,
    label: 'Popular',
    icon: Icons.star_border_rounded,
    color: AppColors.primaryBlue,
  ),
  _QuickFilterSpec(
    filter: _QuickFilter.nearby,
    label: 'Nearby',
    icon: Icons.location_on_outlined,
    color: AppColors.primaryBlue,
  ),
  _QuickFilterSpec(
    filter: _QuickFilter.family,
    label: 'Family',
    icon: Icons.family_restroom_rounded,
    color: AppColors.teal,
  ),
  _QuickFilterSpec(
    filter: _QuickFilter.road,
    label: 'Road',
    icon: Icons.directions_car_rounded,
    color: AppColors.lavender,
  ),
  _QuickFilterSpec(
    filter: _QuickFilter.health,
    label: 'Health',
    icon: Icons.monitor_heart_rounded,
    color: AppColors.coral,
  ),
];

class _ModesHeaderControls extends StatelessWidget {
  const _ModesHeaderControls({
    required this.searchController,
    required this.selectedFilter,
    required this.onSearchChanged,
    required this.onFilterSelected,
  });

  final TextEditingController searchController;
  final _QuickFilter? selectedFilter;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<_QuickFilter> onFilterSelected;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppSearchBar(
          key: const ValueKey('modes-search-field'),
          controller: searchController,
          hintText: 'Search modes',
          onChanged: onSearchChanged,
          onDark: true,
        ),
        const SizedBox(height: AppSpacing.md),
        SingleChildScrollView(
          clipBehavior: Clip.none,
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (var index = 0; index < _quickFilters.length; index++) ...[
                FilterChipPill(
                  key: ValueKey(
                    'modes-filter-${_quickFilters[index].label.toLowerCase()}',
                  ),
                  label: _quickFilters[index].label,
                  icon: _quickFilters[index].icon,
                  color: _quickFilters[index].color,
                  compact: true,
                  selected: selectedFilter == _quickFilters[index].filter,
                  onDark: true,
                  onTap: () => onFilterSelected(_quickFilters[index].filter),
                ),
                if (index != _quickFilters.length - 1)
                  const SizedBox(width: AppSpacing.sm),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _TopModesCarousel extends StatelessWidget {
  const _TopModesCarousel({
    required this.controller,
    required this.currentPage,
    required this.modes,
    required this.onPageChanged,
    required this.onSeeAllTap,
    required this.onModeTap,
  });

  final PageController controller;
  final int currentPage;
  final List<DiscoveryMode> modes;
  final ValueChanged<int> onPageChanged;
  final VoidCallback onSeeAllTap;
  final ValueChanged<DiscoveryMode> onModeTap;

  @override
  Widget build(BuildContext context) {
    return ResponsiveContent(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(title: 'Top modes', onActionTap: onSeeAllTap),
          const SizedBox(height: AppSpacing.sm),
          SizedBox(
            height: 178,
            child: PageView.builder(
              controller: controller,
              clipBehavior: Clip.none,
              padEnds: false,
              onPageChanged: onPageChanged,
              itemCount: modes.length,
              itemBuilder: (context, index) {
                final mode = modes[index];
                return Padding(
                  padding: EdgeInsets.only(
                    left: index == 0 ? AppSpacing.page : AppSpacing.xs,
                    right: AppSpacing.xs,
                  ),
                  child: _FeaturedDiscoveryModeCard(
                    key: ValueKey('featured-mode-card-${mode.id}'),
                    mode: mode,
                    onTap: () => onModeTap(mode),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Padding(
            padding: const EdgeInsets.only(left: AppSpacing.page),
            child: _PaginationDots(
              count: modes.length,
              activeIndex: currentPage,
            ),
          ),
        ],
      ),
    );
  }
}

class _ModeCategorySection extends StatelessWidget {
  const _ModeCategorySection({
    required this.title,
    required this.modes,
    required this.onSeeAllTap,
    required this.onModeTap,
  });

  final String title;
  final List<DiscoveryMode> modes;
  final VoidCallback onSeeAllTap;
  final ValueChanged<DiscoveryMode> onModeTap;

  @override
  Widget build(BuildContext context) {
    return ResponsiveContent(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final contentWidth = constraints.maxWidth - AppSpacing.page * 2;
          final visibleCards =
              constraints.maxWidth < AppBreakpoints.compactPhone
              ? 2.05
              : constraints.maxWidth < AppBreakpoints.tablet
              ? 2.75
              : 3.2;
          final rawCardWidth =
              (contentWidth - AppSpacing.sm * (visibleCards - 1)) /
              visibleCards;
          final cardWidth = rawCardWidth.clamp(142.0, 236.0);

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SectionHeader(title: title, onActionTap: onSeeAllTap),
              const SizedBox(height: AppSpacing.sm),
              SizedBox(
                height: 122,
                child: ListView.separated(
                  clipBehavior: Clip.none,
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.page,
                  ),
                  itemBuilder: (context, index) {
                    final mode = modes[index];
                    return _CategoryDiscoveryModeCard(
                      key: ValueKey('category-mode-card-${mode.id}'),
                      mode: mode,
                      width: cardWidth.toDouble(),
                      onTap: () => onModeTap(mode),
                    );
                  },
                  separatorBuilder: (context, index) =>
                      const SizedBox(width: AppSpacing.sm),
                  itemCount: modes.length,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.onActionTap});

  final String title;
  final VoidCallback onActionTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.page),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w900,
                height: 1.05,
              ),
            ),
          ),
          TextButton.icon(
            onPressed: onActionTap,
            iconAlignment: IconAlignment.end,
            icon: const Icon(Icons.chevron_right_rounded, size: 22),
            label: const Text('See all'),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.primaryBlue,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
              textStyle: Theme.of(
                context,
              ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w900),
            ),
          ),
        ],
      ),
    );
  }
}

class _FeaturedDiscoveryModeCard extends StatelessWidget {
  const _FeaturedDiscoveryModeCard({
    required this.mode,
    required this.onTap,
    super.key,
  });

  final DiscoveryMode mode;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: _cardSemanticLabel(mode),
      child: PressScale(
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: AppRadius.xlBorder,
            onTap: onTap,
            child: Ink(
              decoration: BoxDecoration(
                color: AppColors.surfaceRaised,
                borderRadius: AppRadius.xlBorder,
                border: Border.all(
                  color: AppColors.white.withValues(alpha: 0.8),
                ),
                boxShadow: AppShadows.card,
              ),
              child: ClipRRect(
                borderRadius: AppRadius.xlBorder,
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: modeIllustrationFor(
                        mode,
                        borderRadius: BorderRadius.zero,
                      ),
                    ),
                    Positioned.fill(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              AppColors.white.withValues(alpha: 0.94),
                              AppColors.white.withValues(alpha: 0.60),
                              AppColors.white.withValues(alpha: 0.12),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              SoftIconBadge(
                                icon: ModeCatalog.iconFor(
                                  mode.iconSemanticName,
                                ),
                                color: mode.accentColor,
                                size: 58,
                                iconSize: 31,
                              ),
                              const Spacer(),
                              _CircleArrow(color: mode.accentColor),
                            ],
                          ),
                          const Spacer(),
                          Text(
                            mode.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(
                                  color: AppColors.textPrimary,
                                  fontWeight: FontWeight.w900,
                                  height: 1.05,
                                ),
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            mode.shortSubtitle,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  color: AppColors.navy800,
                                  fontWeight: FontWeight.w700,
                                  height: 1.16,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CategoryDiscoveryModeCard extends StatelessWidget {
  const _CategoryDiscoveryModeCard({
    required this.mode,
    required this.width,
    required this.onTap,
    super.key,
  });

  final DiscoveryMode mode;
  final double width;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Semantics(
        button: true,
        label: _cardSemanticLabel(mode),
        child: PressScale(
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: AppRadius.card,
              onTap: onTap,
              child: Ink(
                decoration: BoxDecoration(
                  color: AppColors.surfaceRaised,
                  borderRadius: AppRadius.card,
                  border: Border.all(color: AppColors.border),
                  boxShadow: AppShadows.soft,
                ),
                child: ClipRRect(
                  borderRadius: AppRadius.card,
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: CustomPaint(
                          painter: _CategoryCardPainter(mode.accentColor),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(AppSpacing.sm),
                        child: Row(
                          children: [
                            SoftIconBadge(
                              icon: ModeCatalog.iconFor(mode.iconSemanticName),
                              color: mode.accentColor,
                              size: 54,
                              iconSize: 28,
                              showShadow: false,
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Expanded(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    mode.title,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleSmall
                                        ?.copyWith(
                                          color: AppColors.textPrimary,
                                          fontWeight: FontWeight.w900,
                                          height: 1.05,
                                        ),
                                  ),
                                  const SizedBox(height: AppSpacing.xs),
                                  Text(
                                    mode.shortSubtitle,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: Theme.of(context).textTheme.bodySmall
                                        ?.copyWith(
                                          color: AppColors.navy800,
                                          height: 1.16,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PaginationDots extends StatelessWidget {
  const _PaginationDots({required this.count, required this.activeIndex});

  final int count;
  final int activeIndex;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Carousel page ${activeIndex + 1} of $count',
      child: ExcludeSemantics(
        child: Row(
          children: [
            for (var index = 0; index < count; index++)
              AnimatedContainer(
                duration: MediaQuery.disableAnimationsOf(context)
                    ? Duration.zero
                    : const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                width: index == activeIndex ? 20 : 9,
                height: 9,
                margin: const EdgeInsets.only(right: AppSpacing.xs),
                decoration: BoxDecoration(
                  color: index == activeIndex
                      ? AppColors.primaryBlue
                      : AppColors.borderStrong,
                  borderRadius: AppRadius.chip,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _CircleArrow extends StatelessWidget {
  const _CircleArrow({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: AppColors.white.withValues(alpha: 0.86),
        shape: BoxShape.circle,
        boxShadow: AppShadows.soft,
      ),
      child: Icon(Icons.chevron_right_rounded, color: color, size: 31),
    );
  }
}

class _CategoryCardPainter extends CustomPainter {
  const _CategoryCardPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final wash = Paint()..color = color.withValues(alpha: 0.08);
    canvas.drawPath(
      Path()
        ..moveTo(size.width * 0.12, size.height)
        ..quadraticBezierTo(
          size.width * 0.45,
          size.height * 0.54,
          size.width * 0.76,
          size.height * 0.90,
        )
        ..quadraticBezierTo(
          size.width * 0.92,
          size.height * 1.08,
          size.width,
          size.height * 0.72,
        )
        ..lineTo(size.width, size.height)
        ..close(),
      wash,
    );

    final orb = Paint()..color = color.withValues(alpha: 0.10);
    canvas.drawCircle(
      Offset(size.width * 0.86, size.height * 0.22),
      size.height * 0.34,
      orb,
    );
  }

  @override
  bool shouldRepaint(covariant _CategoryCardPainter oldDelegate) {
    return oldDelegate.color != color;
  }
}

class _NoModesFound extends StatelessWidget {
  const _NoModesFound({required this.query});

  final String query;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.page),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SoftIconBadge(
            icon: Icons.search_off_rounded,
            color: AppColors.primaryBlue,
            size: 64,
            iconSize: 32,
            showShadow: false,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'No modes found',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            query.trim().isEmpty
                ? 'Try another filter.'
                : 'Try a broader search or another filter.',
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

String _cardSemanticLabel(DiscoveryMode mode) {
  return '${mode.title}, ${mode.category.label}. ${mode.shortSubtitle}';
}
