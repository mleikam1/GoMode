import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/primary_gradient_button.dart';
import '../../../services/api_client.dart';
import '../data/date_night_planning_service.dart';
import '../domain/date_night_preferences.dart';

class DateNightSetupScreen extends ConsumerStatefulWidget {
  const DateNightSetupScreen({super.key});

  @override
  ConsumerState<DateNightSetupScreen> createState() =>
      _DateNightSetupScreenState();
}

class _DateNightSetupScreenState extends ConsumerState<DateNightSetupScreen> {
  DateNightPreferences _preferences = const DateNightPreferences.defaults();
  bool _isFavorite = true;
  bool _isGenerating = false;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.surface,
      child: CustomScrollView(
        key: const ValueKey('date-night-setup-scroll'),
        slivers: [
          SliverToBoxAdapter(
            child: _DateNightHeader(
              favorite: _isFavorite,
              onBack: _goBack,
              onFavorite: () {
                setState(() => _isFavorite = !_isFavorite);
              },
            ),
          ),
          SliverToBoxAdapter(
            child: Transform.translate(
              offset: const Offset(0, -22),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 15),
                child: _PlanningSurface(
                  preferences: _preferences,
                  isGenerating: _isGenerating,
                  onBudgetChanged: (budget) {
                    setState(() {
                      _preferences = _preferences.copyWith(budget: budget);
                    });
                  },
                  onVibeChanged: (vibe) {
                    setState(() {
                      _preferences = _preferences.copyWith(vibe: vibe);
                    });
                  },
                  onDurationChanged: (duration) {
                    setState(() {
                      _preferences = _preferences.copyWith(duration: duration);
                    });
                  },
                  onIndoorChanged: (value) {
                    setState(() {
                      _preferences = _preferences.copyWith(indoor: value);
                    });
                  },
                  onOutdoorChanged: (value) {
                    setState(() {
                      _preferences = _preferences.copyWith(outdoor: value);
                    });
                  },
                  onOpenNowChanged: (value) {
                    setState(() {
                      _preferences = _preferences.copyWith(openNow: value);
                    });
                  },
                  onGenerate: _generatePlan,
                ),
              ),
            ),
          ),
          const SliverToBoxAdapter(
            child: SizedBox(height: AppSpacing.bottomNavHeight + 16),
          ),
        ],
      ),
    );
  }

  void _goBack() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/modes');
    }
  }

  Future<void> _generatePlan() async {
    if (_isGenerating) {
      return;
    }

    setState(() => _isGenerating = true);
    try {
      final plan = await ref
          .read(dateNightPlanningServiceProvider)
          .generatePlan(_preferences);
      if (!mounted) {
        return;
      }
      await context.push('/modes/date-night/plan', extra: plan);
    } catch (error) {
      if (mounted) {
        final message = error is BackendException
            ? error.userMessage
            : 'Could not create a plan right now. Please try again.';
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(message)));
      }
    } finally {
      if (mounted) {
        setState(() => _isGenerating = false);
      }
    }
  }
}

class _DateNightHeader extends StatelessWidget {
  const _DateNightHeader({
    required this.favorite,
    required this.onBack,
    required this.onFavorite,
  });

  final bool favorite;
  final VoidCallback onBack;
  final VoidCallback onFavorite;

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
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 36),
          child: Column(
            children: [
              SizedBox(
                height: 52,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: _RoundHeaderButton(
                        tooltip: 'Back',
                        icon: Icons.arrow_back_rounded,
                        onTap: onBack,
                      ),
                    ),
                    Text(
                      'Date Night',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(
                            color: AppColors.white,
                            fontWeight: FontWeight.w900,
                          ),
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: _RoundHeaderButton(
                        tooltip: favorite
                            ? 'Remove from favorites'
                            : 'Add to favorites',
                        icon: favorite
                            ? Icons.favorite_rounded
                            : Icons.favorite_border_rounded,
                        iconColor: AppColors.coral,
                        onTap: onFavorite,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              const _DateNightHero(),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoundHeaderButton extends StatelessWidget {
  const _RoundHeaderButton({
    required this.tooltip,
    required this.icon,
    required this.onTap,
    this.iconColor = AppColors.white,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback onTap;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: AppColors.white.withValues(alpha: 0.08),
        shape: CircleBorder(
          side: BorderSide(color: AppColors.white.withValues(alpha: 0.16)),
        ),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: SizedBox(
            width: 48,
            height: 48,
            child: Icon(icon, color: iconColor, size: 27),
          ),
        ),
      ),
    );
  }
}

class _DateNightHero extends StatelessWidget {
  const _DateNightHero();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 184,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: const Color(0xFFFFEDF3),
        borderRadius: AppRadius.largeCard,
        boxShadow: AppShadows.glowCoral,
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'assets/images/date_night_hero.png',
            fit: BoxFit.cover,
            alignment: Alignment.center,
          ),
          Positioned(
            left: 18,
            top: 18,
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: const Color(0xFFFFCFDE).withValues(alpha: 0.94),
                shape: BoxShape.circle,
                boxShadow: AppShadows.soft,
              ),
              child: const Icon(
                Icons.favorite_border_rounded,
                color: Color(0xFFD90D51),
                size: 28,
              ),
            ),
          ),
          Positioned(
            left: 20,
            right: 138,
            bottom: 18,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Date Night',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w900,
                    height: 1,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Romantic spots and fun ideas for a perfect night together.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textPrimary.withValues(alpha: 0.84),
                    fontWeight: FontWeight.w600,
                    height: 1.28,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PlanningSurface extends StatelessWidget {
  const _PlanningSurface({
    required this.preferences,
    required this.isGenerating,
    required this.onBudgetChanged,
    required this.onVibeChanged,
    required this.onDurationChanged,
    required this.onIndoorChanged,
    required this.onOutdoorChanged,
    required this.onOpenNowChanged,
    required this.onGenerate,
  });

  final DateNightPreferences preferences;
  final bool isGenerating;
  final ValueChanged<DateNightBudget> onBudgetChanged;
  final ValueChanged<DateNightVibe> onVibeChanged;
  final ValueChanged<DateNightDuration> onDurationChanged;
  final ValueChanged<bool> onIndoorChanged;
  final ValueChanged<bool> onOutdoorChanged;
  final ValueChanged<bool> onOpenNowChanged;
  final VoidCallback onGenerate;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 18, 14, 16),
      decoration: BoxDecoration(
        color: AppColors.surfaceRaised,
        borderRadius: AppRadius.largeCard,
        border: Border.all(color: AppColors.border.withValues(alpha: 0.62)),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _ControlSection<DateNightBudget>(
            title: 'Budget',
            icon: Icons.sell_outlined,
            values: DateNightBudget.values,
            selected: preferences.budget,
            labelFor: (value) => value.label,
            keyPrefix: 'budget',
            onSelected: onBudgetChanged,
          ),
          const SizedBox(height: 8),
          _ControlSection<DateNightVibe>(
            title: 'Vibe',
            icon: Icons.favorite_border_rounded,
            values: DateNightVibe.values,
            selected: preferences.vibe,
            labelFor: (value) => value.label,
            iconFor: (value) => switch (value) {
              DateNightVibe.romantic => Icons.favorite_border_rounded,
              DateNightVibe.fun => Icons.sentiment_satisfied_alt_rounded,
              DateNightVibe.casual => Icons.local_cafe_outlined,
            },
            keyPrefix: 'vibe',
            onSelected: onVibeChanged,
          ),
          const SizedBox(height: 8),
          _ControlSection<DateNightDuration>(
            title: 'Time',
            icon: Icons.schedule_rounded,
            values: DateNightDuration.values,
            selected: preferences.duration,
            labelFor: (value) => value.label,
            keyPrefix: 'time',
            onSelected: onDurationChanged,
          ),
          const SizedBox(height: 8),
          _TogglePanel(
            preferences: preferences,
            onIndoorChanged: onIndoorChanged,
            onOutdoorChanged: onOutdoorChanged,
            onOpenNowChanged: onOpenNowChanged,
          ),
          const SizedBox(height: 8),
          const _TonightPlanPreview(),
          const SizedBox(height: 8),
          PrimaryGradientButton(
            key: const ValueKey('generate-date-night-button'),
            label: isGenerating
                ? 'Creating your night...'
                : 'Generate My Night',
            icon: Icons.auto_awesome_rounded,
            height: 48,
            onPressed: isGenerating ? null : onGenerate,
          ),
        ],
      ),
    );
  }
}

class _ControlSection<T extends Enum> extends StatelessWidget {
  const _ControlSection({
    required this.title,
    required this.icon,
    required this.values,
    required this.selected,
    required this.labelFor,
    required this.keyPrefix,
    required this.onSelected,
    this.iconFor,
  });

  final String title;
  final IconData icon;
  final List<T> values;
  final T selected;
  final String Function(T value) labelFor;
  final IconData Function(T value)? iconFor;
  final String keyPrefix;
  final ValueChanged<T> onSelected;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionLabel(icon: icon, label: title),
        const SizedBox(height: 6),
        Row(
          children: [
            for (var index = 0; index < values.length; index++) ...[
              Expanded(
                child: _ChoicePill(
                  key: ValueKey(
                    '$keyPrefix-${values[index].name}-'
                    '${values[index] == selected ? 'selected' : 'unselected'}',
                  ),
                  label: labelFor(values[index]),
                  icon: iconFor?.call(values[index]),
                  selected: values[index] == selected,
                  onTap: () => onSelected(values[index]),
                ),
              ),
              if (index != values.length - 1) const SizedBox(width: 10),
            ],
          ],
        ),
      ],
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: AppColors.coral, size: 22),
        const SizedBox(width: 10),
        Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
        ),
      ],
    );
  }
}

class _ChoicePill extends StatelessWidget {
  const _ChoicePill({
    required this.label,
    required this.selected,
    required this.onTap,
    super.key,
    this.icon,
  });

  final String label;
  final IconData? icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: AppRadius.chip,
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            height: 34,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              color: selected
                  ? AppColors.coral.withValues(alpha: 0.09)
                  : AppColors.white,
              borderRadius: AppRadius.chip,
              border: Border.all(
                color: selected ? AppColors.coral : AppColors.borderStrong,
                width: selected ? 1.4 : 1,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (icon != null) ...[
                  Icon(
                    icon,
                    color: selected ? AppColors.coral : AppColors.textPrimary,
                    size: 19,
                  ),
                  const SizedBox(width: 5),
                ],
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: selected ? AppColors.coral : AppColors.textPrimary,
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
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

class _TogglePanel extends StatelessWidget {
  const _TogglePanel({
    required this.preferences,
    required this.onIndoorChanged,
    required this.onOutdoorChanged,
    required this.onOpenNowChanged,
  });

  final DateNightPreferences preferences;
  final ValueChanged<bool> onIndoorChanged;
  final ValueChanged<bool> onOutdoorChanged;
  final ValueChanged<bool> onOpenNowChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: AppRadius.card,
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: _CompactToggle(
              key: const ValueKey('toggle-indoor'),
              label: 'Indoor',
              icon: Icons.home_outlined,
              iconColor: AppColors.primaryBlue,
              value: preferences.indoor,
              onChanged: onIndoorChanged,
            ),
          ),
          const _ToggleDivider(),
          Expanded(
            child: _CompactToggle(
              key: const ValueKey('toggle-outdoor'),
              label: 'Outdoor',
              icon: Icons.park_outlined,
              iconColor: AppColors.success,
              value: preferences.outdoor,
              onChanged: onOutdoorChanged,
            ),
          ),
          const _ToggleDivider(),
          Expanded(
            child: _CompactToggle(
              key: const ValueKey('toggle-open-now'),
              label: 'Open Now',
              icon: Icons.storefront_outlined,
              iconColor: AppColors.navy800,
              value: preferences.openNow,
              onChanged: onOpenNowChanged,
            ),
          ),
        ],
      ),
    );
  }
}

class _ToggleDivider extends StatelessWidget {
  const _ToggleDivider();

  @override
  Widget build(BuildContext context) {
    return Container(width: 1, height: 38, color: AppColors.border);
  }
}

class _CompactToggle extends StatelessWidget {
  const _CompactToggle({
    required this.label,
    required this.icon,
    required this.iconColor,
    required this.value,
    required this.onChanged,
    super.key,
  });

  final String label;
  final IconData icon;
  final Color iconColor;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 3),
      child: Row(
        children: [
          Icon(icon, color: iconColor, size: 16),
          const SizedBox(width: 2),
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                fontSize: 10.5,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          SizedBox(
            width: 29,
            height: 23,
            child: FittedBox(
              fit: BoxFit.fill,
              child: Switch(value: value, onChanged: onChanged),
            ),
          ),
        ],
      ),
    );
  }
}

class _TonightPlanPreview extends StatelessWidget {
  const _TonightPlanPreview();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: AppColors.coral.withValues(alpha: 0.065),
        borderRadius: AppRadius.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionLabel(
            icon: Icons.auto_awesome_rounded,
            label: "Tonight's plan",
          ),
          const SizedBox(height: 4),
          Container(
            height: 54,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: AppRadius.mdBorder,
              border: Border.all(color: AppColors.border),
            ),
            child: const Row(
              children: [
                Expanded(
                  child: _PreviewStep(
                    icon: Icons.restaurant_rounded,
                    title: 'Dinner',
                    subtitle: 'Romantic spot',
                  ),
                ),
                _PreviewDivider(),
                Expanded(
                  child: _PreviewStep(
                    icon: Icons.photo_camera_outlined,
                    title: 'Activity',
                    subtitle: 'Fun together',
                  ),
                ),
                _PreviewDivider(),
                Expanded(
                  child: _PreviewStep(
                    icon: Icons.cake_outlined,
                    title: 'Dessert',
                    subtitle: 'Sweet treat',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(
                Icons.location_on_outlined,
                color: AppColors.coral,
                size: 20,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Austin, TX',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 2,
                child: Text(
                  'Starting around 7:00 PM',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.right,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.coral,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PreviewDivider extends StatelessWidget {
  const _PreviewDivider();

  @override
  Widget build(BuildContext context) {
    return Container(width: 1, height: 48, color: AppColors.border);
  }
}

class _PreviewStep extends StatelessWidget {
  const _PreviewStep({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: const Color(0xFFFFD8E4),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: AppColors.coral, size: 17),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(fontSize: 10.5, height: 1.08),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
