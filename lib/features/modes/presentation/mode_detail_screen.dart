import 'package:flutter/foundation.dart';
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
import '../domain/mode_flow_config.dart';
import 'mode_visuals.dart';

class ModeDetailScreen extends ConsumerStatefulWidget {
  const ModeDetailScreen({required this.modeId, super.key});

  final String modeId;

  @override
  ConsumerState<ModeDetailScreen> createState() => _ModeDetailScreenState();
}

class _ModeDetailScreenState extends ConsumerState<ModeDetailScreen> {
  final TextEditingController _inputController = TextEditingController();
  final Map<String, String> _selectedFilters = {};
  bool _showInputError = false;
  String? _initializedModeId;

  @override
  void didUpdateWidget(covariant ModeDetailScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.modeId != widget.modeId) {
      _inputController.clear();
      _selectedFilters.clear();
      _showInputError = false;
      _initializedModeId = null;
    }
  }

  @override
  void dispose() {
    _inputController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final catalog = ref.watch(modeCatalogProvider);
    final mode = catalog.findById(widget.modeId);
    if (mode == null) {
      return _UnknownModeScreen(modeId: widget.modeId);
    }

    final config = modeFlowConfigFor(mode);
    _initializeSelections(mode, config);

    return ColoredBox(
      color: AppColors.surface,
      child: CustomScrollView(
        key: ValueKey('mode-setup-${mode.id}'),
        slivers: [
          SliverToBoxAdapter(
            child: GradientHeader(
              compact: true,
              title: mode.title,
              subtitle: mode.shortSubtitle,
              leading: HeaderIconButton(
                icon: Icons.arrow_back_rounded,
                onTap: () => _goBackToModes(context),
              ),
              trailing: HeaderIconButton(
                icon: ModeCatalog.iconFor(mode.iconSemanticName),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(AppSpacing.page),
            sliver: SliverList.list(
              children: [
                _ModeHeroCard(mode: mode),
                const SizedBox(height: AppSpacing.xl),
                Text(
                  'Make it yours',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'A few quick choices are all we need.',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                if (config.requiresInput) ...[
                  const SizedBox(height: AppSpacing.lg),
                  _ModeTextInput(
                    controller: _inputController,
                    label: config.inputLabel!,
                    hint: config.inputHint,
                    helper: config.inputHelper,
                    errorText: _showInputError
                        ? 'Enter a location to continue.'
                        : null,
                    onChanged: (_) {
                      if (_showInputError) {
                        setState(() => _showInputError = false);
                      }
                    },
                  ),
                ],
                for (final filter in config.filters) ...[
                  const SizedBox(height: AppSpacing.lg),
                  _FilterSelector(
                    mode: mode,
                    filter: filter,
                    selected: _selectedFilters[filter.id]!,
                    onSelected: (value) {
                      setState(() => _selectedFilters[filter.id] = value);
                    },
                  ),
                ],
                if (config.caveat != null) ...[
                  const SizedBox(height: AppSpacing.lg),
                  _InfoNotice(
                    icon: mode.id == 'road-rescue'
                        ? Icons.health_and_safety_outlined
                        : Icons.info_outline_rounded,
                    message: config.caveat!,
                    color: mode.id == 'road-rescue'
                        ? AppColors.danger
                        : mode.accentColor,
                  ),
                ],
                const SizedBox(height: AppSpacing.xl),
                PrimaryGradientButton(
                  label: config.ctaLabel,
                  icon: config.ctaIcon,
                  onPressed: () => _openResults(mode, config),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'You can adjust these choices anytime.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                SizedBox(height: AppSpacing.bottomNavHeight + AppSpacing.xl),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _initializeSelections(DiscoveryMode mode, ModeFlowConfig config) {
    if (_initializedModeId == mode.id) {
      return;
    }
    _initializedModeId = mode.id;
    _selectedFilters
      ..clear()
      ..addEntries(
        config.filters.map(
          (filter) => MapEntry(filter.id, filter.options.first),
        ),
      );
  }

  void _openResults(DiscoveryMode mode, ModeFlowConfig config) {
    final input = _inputController.text.trim();
    if (config.requiresInput && input.isEmpty) {
      setState(() => _showInputError = true);
      return;
    }

    final parameters = <String, String>{..._selectedFilters};
    if (input.isNotEmpty) {
      parameters['location'] = input;
    }
    final destination = Uri(
      path: '/modes/${mode.id}/results',
      queryParameters: parameters,
    );
    context.go(destination.toString());
  }
}

void _goBackToModes(BuildContext context) {
  if (context.canPop()) {
    context.pop();
  } else {
    context.go('/modes');
  }
}

class _ModeHeroCard extends StatelessWidget {
  const _ModeHeroCard({required this.mode});

  final DiscoveryMode mode;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: mode.accentColor.withValues(alpha: 0.12),
        borderRadius: AppRadius.largeCard,
        border: Border.all(color: mode.accentColor.withValues(alpha: 0.28)),
        boxShadow: AppShadows.card,
      ),
      child: ClipRRect(
        borderRadius: AppRadius.largeCard,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              height: 190,
              child: modeIllustrationFor(mode, borderRadius: BorderRadius.zero),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SoftIconBadge(
                    icon: ModeCatalog.iconFor(mode.iconSemanticName),
                    color: mode.accentColor,
                    showShadow: false,
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          mode.longDescription,
                          style: Theme.of(context).textTheme.bodyLarge
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        if (kDebugMode) ...[
                          const SizedBox(height: AppSpacing.xs),
                          StatusPill(
                            label: 'Demo fallback',
                            color: mode.accentColor,
                            compact: true,
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ModeTextInput extends StatelessWidget {
  const _ModeTextInput({
    required this.controller,
    required this.label,
    required this.onChanged,
    this.hint,
    this.helper,
    this.errorText,
  });

  final TextEditingController controller;
  final String label;
  final String? hint;
  final String? helper;
  final String? errorText;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return TextField(
      key: const ValueKey('mode-location-input'),
      controller: controller,
      onChanged: onChanged,
      textInputAction: TextInputAction.done,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        helperText: helper,
        errorText: errorText,
        prefixIcon: const Icon(Icons.location_on_outlined),
        filled: true,
        fillColor: AppColors.surfaceRaised,
        border: OutlineInputBorder(
          borderRadius: AppRadius.card,
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppRadius.card,
          borderSide: const BorderSide(color: AppColors.border),
        ),
      ),
    );
  }
}

class _FilterSelector extends StatelessWidget {
  const _FilterSelector({
    required this.mode,
    required this.filter,
    required this.selected,
    required this.onSelected,
  });

  final DiscoveryMode mode;
  final ModeFilterDefinition filter;
  final String selected;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(filter.icon, color: mode.accentColor, size: 21),
            const SizedBox(width: AppSpacing.xs),
            Text(
              filter.label,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: AppSpacing.xs,
          runSpacing: AppSpacing.xs,
          children: [
            for (final option in filter.options)
              ChoiceChip(
                key: ValueKey('mode-filter-${filter.id}-$option'),
                label: Text(option),
                selected: selected == option,
                onSelected: (_) => onSelected(option),
                selectedColor: mode.accentColor.withValues(alpha: 0.18),
                side: BorderSide(
                  color: selected == option
                      ? mode.accentColor
                      : AppColors.border,
                ),
                labelStyle: TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: selected == option
                      ? FontWeight.w900
                      : FontWeight.w700,
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _InfoNotice extends StatelessWidget {
  const _InfoNotice({
    required this.icon,
    required this.message,
    required this.color,
  });

  final IconData icon;
  final String message;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: AppRadius.card,
        border: Border.all(color: color.withValues(alpha: 0.24)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              message,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

class _UnknownModeScreen extends StatelessWidget {
  const _UnknownModeScreen({required this.modeId});

  final String modeId;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.surface,
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: GradientHeader(
              compact: true,
              title: 'Mode not found',
              subtitle: 'No local catalog entry exists for "$modeId".',
              leading: HeaderIconButton(
                icon: Icons.arrow_back_rounded,
                onTap: () => _goBackToModes(context),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(AppSpacing.page),
            sliver: SliverToBoxAdapter(
              child: PrimaryGradientButton(
                label: 'Back to modes',
                icon: Icons.grid_view_rounded,
                onPressed: () => context.go('/modes'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
