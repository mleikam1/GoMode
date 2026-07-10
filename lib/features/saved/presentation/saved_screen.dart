import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/gradient_header.dart';
import '../../../shared/widgets/soft_icon_badge.dart';
import '../application/saved_library_controller.dart';
import '../domain/saved_collection.dart';
import '../domain/saved_item.dart';

class SavedScreen extends ConsumerWidget {
  const SavedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final library = ref.watch(savedLibraryProvider);
    final selectedType = library.maybeWhen(
      data: (value) => value.selectedType,
      orElse: () => SavedItemType.plan,
    );
    final bodyTop = MediaQuery.paddingOf(context).top + 196;

    return ColoredBox(
      color: AppColors.surface,
      child: SingleChildScrollView(
        key: const ValueKey('saved-screen-scroll-view'),
        padding: const EdgeInsets.only(
          bottom: AppSpacing.bottomNavHeight + AppSpacing.lg,
        ),
        child: Stack(
          children: [
            GradientHeader(
              compact: true,
              dense: true,
              showWordmark: true,
              locationLabel: 'Austin, TX',
              title: 'Saved',
              subtitle: 'Your plans, places, and routes',
              trailing: const HeaderIconButton(
                icon: Icons.notifications_none_rounded,
                showDot: true,
                size: 36,
                iconSize: 21,
              ),
              bottom: _SavedTabs(
                selectedType: selectedType,
                onSelected: (type) {
                  library.whenData((_) {
                    ref.read(savedLibraryProvider.notifier).selectType(type);
                  });
                },
              ),
            ),
            Padding(
              padding: EdgeInsets.only(top: bodyTop),
              child: library.when(
                loading: () => const _SavedLoadingState(),
                error: (error, stackTrace) => _SavedErrorState(
                  onRetry: () => ref.invalidate(savedLibraryProvider),
                ),
                data: (value) => _SavedContent(library: value),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SavedTabs extends StatelessWidget {
  const _SavedTabs({required this.selectedType, required this.onSelected});

  final SavedItemType selectedType;
  final ValueChanged<SavedItemType> onSelected;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var index = 0; index < SavedItemType.values.length; index++) ...[
          Expanded(
            child: _SavedTab(
              type: SavedItemType.values[index],
              selected: selectedType == SavedItemType.values[index],
              onTap: () => onSelected(SavedItemType.values[index]),
            ),
          ),
          if (index != SavedItemType.values.length - 1)
            const SizedBox(width: 7),
        ],
      ],
    );
  }
}

class _SavedTab extends StatelessWidget {
  const _SavedTab({
    required this.type,
    required this.selected,
    required this.onTap,
  });

  final SavedItemType type;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final accent = _accentForType(type);
    return Semantics(
      button: true,
      selected: selected,
      child: Material(
        key: ValueKey('saved-tab-${type.name}'),
        color: Colors.transparent,
        shape: const StadiumBorder(),
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: onTap,
          child: Ink(
            height: 36,
            decoration: BoxDecoration(
              color: selected ? null : AppColors.white.withValues(alpha: 0.06),
              gradient: selected ? AppColors.activeBlueGradient : null,
              borderRadius: AppRadius.chip,
              border: Border.all(
                color: selected
                    ? AppColors.primaryBlueLight
                    : AppColors.white.withValues(alpha: 0.22),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  _iconForType(type),
                  color: selected ? AppColors.white : accent,
                  size: 19,
                ),
                const SizedBox(width: 5),
                Flexible(
                  child: Text(
                    type.label,
                    maxLines: 1,
                    overflow: TextOverflow.fade,
                    softWrap: false,
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: AppColors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 13,
                    ),
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

class _SavedContent extends ConsumerWidget {
  const _SavedContent({required this.library});

  final SavedLibraryState library;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.page),
      child: Column(
        children: [
          if (library.filteredItems.isEmpty)
            _SavedItemsEmptyState(type: library.selectedType)
          else
            for (
              var index = 0;
              index < library.filteredItems.length;
              index++
            ) ...[
              _SavedItemCard(item: library.filteredItems[index]),
              if (index != library.filteredItems.length - 1)
                const SizedBox(height: 6),
            ],
          const SizedBox(height: 10),
          _CollectionsSection(collections: library.collections),
        ],
      ),
    );
  }
}

class _SavedItemCard extends ConsumerWidget {
  const _SavedItemCard({required this.item});

  final SavedItem item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accent = _accentForVisual(item.visual);
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 400;
        final cardHeight = wide ? 110.0 : 124.0;
        final imageWidth = wide ? 119.0 : 102.0;

        return Material(
          key: ValueKey('saved-item-${item.id}'),
          color: Colors.transparent,
          child: InkWell(
            borderRadius: AppRadius.largeCard,
            onTap: item.destinationPath == null
                ? null
                : () => context.go(item.destinationPath!),
            child: Ink(
              height: cardHeight,
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: AppColors.surfaceRaised,
                borderRadius: AppRadius.largeCard,
                border: Border.all(color: AppColors.white),
                boxShadow: AppShadows.soft,
              ),
              child: Row(
                children: [
                  SizedBox(
                    width: imageWidth,
                    height: double.infinity,
                    child: _SavedThumbnail(item: item),
                  ),
                  const SizedBox(width: 13),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          height: 18,
                          child: Row(
                            children: [
                              Icon(
                                _iconForVisual(item.visual),
                                color: accent,
                                size: 15,
                              ),
                              const SizedBox(width: 5),
                              Expanded(
                                child: Text(
                                  item.categoryLabel.toUpperCase(),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context).textTheme.labelSmall
                                      ?.copyWith(
                                        color: accent,
                                        fontWeight: FontWeight.w900,
                                        fontSize: 11,
                                      ),
                                ),
                              ),
                              PopupMenuButton<String>(
                                key: ValueKey('saved-menu-${item.id}'),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints.tightFor(
                                  width: 28,
                                  height: 28,
                                ),
                                tooltip: 'Saved item options',
                                color: AppColors.surfaceRaised,
                                icon: const Icon(
                                  Icons.more_horiz_rounded,
                                  color: AppColors.textMuted,
                                  size: 20,
                                ),
                                onSelected: (_) {
                                  ref
                                      .read(savedLibraryProvider.notifier)
                                      .removeItem(item.id);
                                },
                                itemBuilder: (context) => const [
                                  PopupMenuItem(
                                    value: 'remove',
                                    child: Text('Remove from saved'),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Text(
                          item.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w900,
                                fontSize: wide ? 16.5 : 15.5,
                                height: 1.08,
                              ),
                        ),
                        const SizedBox(height: 2),
                        Expanded(
                          child: Text(
                            item.description,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: AppColors.textSecondary,
                                  fontSize: wide ? 12.5 : 12,
                                  height: 1.18,
                                ),
                          ),
                        ),
                        Row(
                          children: [
                            Expanded(
                              child: _SavedMetadata(item: item, accent: accent),
                            ),
                            const SizedBox(width: 7),
                            _SavedStatusBadge(item: item, accent: accent),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _SavedThumbnail extends StatelessWidget {
  const _SavedThumbnail({required this.item});

  final SavedItem item;

  @override
  Widget build(BuildContext context) {
    final asset = item.imageAsset ?? _assetForVisual(item.visual);
    return ClipRRect(
      borderRadius: AppRadius.mdBorder,
      child: Image.asset(
        asset,
        fit: BoxFit.cover,
        alignment: item.visual == SavedItemVisual.dateNight
            ? Alignment.center
            : Alignment.center,
        errorBuilder: (context, error, stackTrace) => ColoredBox(
          color: _accentForVisual(item.visual).withValues(alpha: 0.12),
          child: Icon(
            _iconForVisual(item.visual),
            color: _accentForVisual(item.visual),
            size: 38,
          ),
        ),
      ),
    );
  }
}

class _SavedMetadata extends StatelessWidget {
  const _SavedMetadata({required this.item, required this.accent});

  final SavedItem item;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final progress = item.progress;
    final label = progress == null
        ? _formatSavedDate(item.savedAt)
        : '${item.progressCompleted} of ${item.progressTotal} completed';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Icon(
              progress == null
                  ? Icons.calendar_today_outlined
                  : Icons.emoji_events_outlined,
              color: progress == null ? AppColors.textMuted : accent,
              size: 14,
            ),
            const SizedBox(width: 5),
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                  fontSize: 11.5,
                ),
              ),
            ),
          ],
        ),
        if (progress != null) ...[
          const SizedBox(height: 3),
          ClipRRect(
            borderRadius: AppRadius.chip,
            child: LinearProgressIndicator(
              key: ValueKey('saved-progress-${item.id}'),
              value: progress,
              minHeight: 4,
              color: accent,
              backgroundColor: AppColors.border,
            ),
          ),
        ],
      ],
    );
  }
}

class _SavedStatusBadge extends StatelessWidget {
  const _SavedStatusBadge({required this.item, required this.accent});

  final SavedItem item;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.12),
        borderRadius: AppRadius.chip,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            item.status == SavedItemStatus.saved
                ? Icons.check_circle_rounded
                : item.visual == SavedItemVisual.localQuest
                ? Icons.star_rounded
                : Icons.play_arrow_rounded,
            color: accent,
            size: 17,
          ),
          const SizedBox(width: 5),
          Text(
            item.status.label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: accent,
              fontWeight: FontWeight.w900,
              fontSize: 11.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _SavedItemsEmptyState extends StatelessWidget {
  const _SavedItemsEmptyState({required this.type});

  final SavedItemType type;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: ValueKey('saved-empty-${type.name}'),
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.xl,
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceRaised,
        borderRadius: AppRadius.largeCard,
        border: Border.all(color: AppColors.border),
        boxShadow: AppShadows.soft,
      ),
      child: Column(
        children: [
          SoftIconBadge(
            icon: _iconForType(type),
            color: _accentForType(type),
            showShadow: false,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'No saved ${type.label.toLowerCase()} yet',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 4),
          Text(
            'Save something you love and it will appear here.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: AppSpacing.md),
          OutlinedButton.icon(
            onPressed: () => context.go('/modes'),
            icon: const Icon(Icons.explore_outlined),
            label: const Text('Explore modes'),
          ),
        ],
      ),
    );
  }
}

class _CollectionsSection extends ConsumerWidget {
  const _CollectionsSection({required this.collections});

  final List<SavedCollection> collections;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Collections',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w900,
                fontSize: 18,
              ),
            ),
            const Spacer(),
            if (collections.isNotEmpty)
              TextButton(onPressed: () {}, child: const Text('View all')),
          ],
        ),
        const SizedBox(height: 4),
        if (collections.isEmpty)
          _EmptyCollectionsCard(onCreate: () => _createCollection(context, ref))
        else
          Column(
            children: [
              for (final collection in collections) ...[
                _CollectionCard(collection: collection),
                const SizedBox(height: AppSpacing.xs),
              ],
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  key: const ValueKey('create-collection-button'),
                  onPressed: () => _createCollection(context, ref),
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Create collection'),
                ),
              ),
            ],
          ),
      ],
    );
  }

  Future<void> _createCollection(BuildContext context, WidgetRef ref) async {
    final name = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        var canCreate = false;
        var collectionName = '';
        return StatefulBuilder(
          builder: (context, setDialogState) => AlertDialog(
            title: const Text('Create collection'),
            content: TextField(
              key: const ValueKey('collection-name-field'),
              autofocus: true,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Collection name',
                hintText: 'Austin favorites',
              ),
              onChanged: (value) {
                collectionName = value;
                setDialogState(() => canCreate = value.trim().isNotEmpty);
              },
              onSubmitted: canCreate
                  ? (value) => Navigator.of(dialogContext).pop(value)
                  : null,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text('Cancel'),
              ),
              FilledButton(
                key: const ValueKey('confirm-create-collection-button'),
                onPressed: canCreate
                    ? () => Navigator.of(dialogContext).pop(collectionName)
                    : null,
                child: const Text('Create'),
              ),
            ],
          ),
        );
      },
    );

    if (name == null || !context.mounted) {
      return;
    }
    final collection = await ref
        .read(savedLibraryProvider.notifier)
        .createCollection(name);
    if (!context.mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${collection.name} collection created.')),
    );
  }
}

class _EmptyCollectionsCard extends StatelessWidget {
  const _EmptyCollectionsCard({required this.onCreate});

  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 405;
        return Container(
          key: const ValueKey('collections-empty-state'),
          width: double.infinity,
          padding: EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: wide ? 4.5 : AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            color: AppColors.surfaceRaised.withValues(alpha: 0.92),
            borderRadius: AppRadius.largeCard,
            border: Border.all(color: AppColors.borderStrong),
          ),
          child: wide
              ? Row(
                  children: [
                    const _CollectionFolderIcon(size: 48),
                    const SizedBox(width: AppSpacing.md),
                    const Expanded(child: _EmptyCollectionCopy()),
                    const SizedBox(width: AppSpacing.sm),
                    _CreateCollectionButton(onCreate: onCreate),
                  ],
                )
              : Column(
                  children: [
                    const Row(
                      children: [
                        _CollectionFolderIcon(),
                        SizedBox(width: AppSpacing.md),
                        Expanded(child: _EmptyCollectionCopy()),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    SizedBox(
                      width: double.infinity,
                      child: _CreateCollectionButton(onCreate: onCreate),
                    ),
                  ],
                ),
        );
      },
    );
  }
}

class _EmptyCollectionCopy extends StatelessWidget {
  const _EmptyCollectionCopy();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'No collections yet',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w900,
            fontSize: 15,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          'Create collections to organize your favorite plans and places.',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(fontSize: 11.5, height: 1.2),
        ),
      ],
    );
  }
}

class _CreateCollectionButton extends StatelessWidget {
  const _CreateCollectionButton({required this.onCreate});

  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      key: const ValueKey('create-collection-button'),
      onPressed: onCreate,
      icon: const Icon(Icons.add_rounded, size: 16),
      label: const Text('Create collection'),
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.primaryBlue,
        side: const BorderSide(color: AppColors.primaryBlue),
        visualDensity: VisualDensity.compact,
        textStyle: Theme.of(context).textTheme.labelSmall?.copyWith(
          fontWeight: FontWeight.w800,
          fontSize: 11.5,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      ),
    );
  }
}

class _CollectionFolderIcon extends StatelessWidget {
  const _CollectionFolderIcon({this.size = 58});

  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: AppColors.lavender.withValues(alpha: 0.10),
              shape: BoxShape.circle,
            ),
          ),
          Icon(
            Icons.folder_rounded,
            color: AppColors.lavender,
            size: size * 0.76,
          ),
          Positioned(
            top: size * 0.43,
            child: Icon(
              Icons.favorite_rounded,
              color: AppColors.white,
              size: size * 0.29,
            ),
          ),
        ],
      ),
    );
  }
}

class _CollectionCard extends StatelessWidget {
  const _CollectionCard({required this.collection});

  final SavedCollection collection;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: ValueKey('saved-collection-${collection.id}'),
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceRaised,
        borderRadius: AppRadius.card,
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          const Icon(Icons.folder_rounded, color: AppColors.lavender, size: 32),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  collection.name,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  '${collection.savedItemIds.length} items',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SavedLoadingState extends StatelessWidget {
  const _SavedLoadingState();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: 260,
      child: Center(child: CircularProgressIndicator()),
    );
  }
}

class _SavedErrorState extends StatelessWidget {
  const _SavedErrorState({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.page),
      child: Center(
        child: Column(
          children: [
            const Icon(
              Icons.cloud_off_rounded,
              color: AppColors.textMuted,
              size: 42,
            ),
            const SizedBox(height: AppSpacing.sm),
            const Text('Saved items could not be loaded.'),
            TextButton(onPressed: onRetry, child: const Text('Try again')),
          ],
        ),
      ),
    );
  }
}

IconData _iconForType(SavedItemType type) => switch (type) {
  SavedItemType.plan => Icons.calendar_month_rounded,
  SavedItemType.place => Icons.location_on_rounded,
  SavedItemType.route => Icons.directions_car_rounded,
  SavedItemType.quest => Icons.local_activity_rounded,
};

Color _accentForType(SavedItemType type) => switch (type) {
  SavedItemType.plan => AppColors.primaryBlue,
  SavedItemType.place => AppColors.coral,
  SavedItemType.route => AppColors.lavender,
  SavedItemType.quest => AppColors.green,
};

IconData _iconForVisual(SavedItemVisual visual) => switch (visual) {
  SavedItemVisual.dateNight => Icons.favorite_border_rounded,
  SavedItemVisual.weekendPlan => Icons.calendar_today_rounded,
  SavedItemVisual.roadTrip => Icons.directions_car_rounded,
  SavedItemVisual.localQuest => Icons.local_activity_rounded,
  SavedItemVisual.place => Icons.location_on_rounded,
};

Color _accentForVisual(SavedItemVisual visual) => switch (visual) {
  SavedItemVisual.dateNight => AppColors.coral,
  SavedItemVisual.weekendPlan => AppColors.teal,
  SavedItemVisual.roadTrip => AppColors.lavender,
  SavedItemVisual.localQuest => AppColors.warning,
  SavedItemVisual.place => AppColors.primaryBlue,
};

String _assetForVisual(SavedItemVisual visual) => switch (visual) {
  SavedItemVisual.dateNight => 'assets/images/saved/date_night.png',
  SavedItemVisual.weekendPlan => 'assets/images/saved/weekend_plan.png',
  SavedItemVisual.roadTrip => 'assets/images/saved/road_trip.png',
  SavedItemVisual.localQuest => 'assets/images/saved/local_quest.png',
  SavedItemVisual.place => 'assets/images/saved/weekend_plan.png',
};

String _formatSavedDate(DateTime value) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final savedDay = DateTime(value.year, value.month, value.day);
  final difference = today.difference(savedDay).inDays;
  if (difference == 0) {
    return 'Saved today';
  }
  if (difference == 1) {
    return 'Saved yesterday';
  }
  if (difference > 1 && difference <= 7) {
    return 'Saved $difference days ago';
  }

  const months = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];
  return 'Saved on ${months[value.month - 1]} ${value.day}';
}
