import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../data/models/discovery_mode.dart';
import '../../../data/models/backend_models.dart';
import '../../../data/repositories/places_repository.dart';
import '../../../data/services/mode_catalog.dart';
import '../../../services/location_service.dart';
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
  Timer? _autocompleteDebounce;
  String? _autocompleteSessionToken;
  List<AutocompleteSuggestion> _autocompleteSuggestions = const [];
  bool _autocompleteLoading = false;
  int _autocompleteRequestId = 0;

  @override
  void didUpdateWidget(covariant ModeDetailScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.modeId != widget.modeId) {
      _inputController.clear();
      _selectedFilters.clear();
      _showInputError = false;
      _initializedModeId = null;
      _resetAutocomplete();
    }
  }

  @override
  void dispose() {
    _autocompleteDebounce?.cancel();
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
                    loading: _autocompleteLoading,
                    suggestions: _autocompleteSuggestions,
                    onSuggestionSelected: _selectAutocompleteSuggestion,
                    onChanged: (value) {
                      if (_showInputError) {
                        setState(() => _showInputError = false);
                      }
                      _scheduleAutocomplete(value);
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

  void _scheduleAutocomplete(String value) {
    _autocompleteDebounce?.cancel();
    final requestId = ++_autocompleteRequestId;
    final text = value.trim();
    if (text.length < 3) {
      if (_autocompleteSuggestions.isNotEmpty || _autocompleteLoading) {
        setState(() {
          _autocompleteSuggestions = const [];
          _autocompleteLoading = false;
        });
      }
      _autocompleteSessionToken = null;
      return;
    }

    _autocompleteSessionToken ??=
        'gomode-${DateTime.now().microsecondsSinceEpoch}-$requestId';
    _autocompleteDebounce = Timer(const Duration(milliseconds: 350), () async {
      if (!mounted || requestId != _autocompleteRequestId) {
        return;
      }
      setState(() => _autocompleteLoading = true);
      try {
        final location = await ref
            .read(locationServiceProvider)
            .currentOrFallback();
        final result = await ref
            .read(placesRepositoryProvider)
            .autocomplete(
              text: text,
              sessionToken: _autocompleteSessionToken!,
              latitude: location.latitude,
              longitude: location.longitude,
              radiusMeters: 16000,
            );
        if (!mounted ||
            requestId != _autocompleteRequestId ||
            _inputController.text.trim() != text) {
          return;
        }
        setState(() {
          _autocompleteSuggestions = result.isDemo
              ? const []
              : result.suggestions.take(5).toList();
          _autocompleteLoading = false;
        });
      } catch (_) {
        if (mounted && requestId == _autocompleteRequestId) {
          setState(() {
            _autocompleteSuggestions = const [];
            _autocompleteLoading = false;
          });
        }
      }
    });
  }

  Future<void> _selectAutocompleteSuggestion(
    AutocompleteSuggestion suggestion,
  ) async {
    _autocompleteDebounce?.cancel();
    final token = _autocompleteSessionToken;
    final requestId = ++_autocompleteRequestId;
    setState(() {
      _inputController.text = suggestion.fullText;
      _autocompleteSuggestions = const [];
      _autocompleteLoading = true;
    });
    try {
      if (token != null) {
        final details = await ref
            .read(placesRepositoryProvider)
            .placeDetails(suggestion.placeId, sessionToken: token);
        if (mounted && requestId == _autocompleteRequestId) {
          _inputController.text = details.place.address.isEmpty
              ? suggestion.fullText
              : details.place.address;
        }
      }
    } catch (_) {
      // The selected prediction text is still a useful address input.
    } finally {
      if (mounted && requestId == _autocompleteRequestId) {
        setState(() => _autocompleteLoading = false);
      }
      _autocompleteSessionToken = null;
    }
  }

  void _resetAutocomplete() {
    _autocompleteDebounce?.cancel();
    _autocompleteRequestId++;
    _autocompleteSessionToken = null;
    _autocompleteSuggestions = const [];
    _autocompleteLoading = false;
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
    required this.loading,
    required this.suggestions,
    required this.onSuggestionSelected,
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
  final bool loading;
  final List<AutocompleteSuggestion> suggestions;
  final ValueChanged<AutocompleteSuggestion> onSuggestionSelected;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextField(
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
            suffixIcon: loading
                ? const Padding(
                    padding: EdgeInsets.all(14),
                    child: SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : null,
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
        ),
        if (suggestions.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.xs),
          Material(
            key: const ValueKey('mode-location-suggestions'),
            color: AppColors.surfaceRaised,
            borderRadius: AppRadius.card,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: AppRadius.card,
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: [
                  for (var index = 0; index < suggestions.length; index++)
                    ListTile(
                      key: ValueKey('mode-location-suggestion-$index'),
                      dense: true,
                      leading: const Icon(Icons.place_outlined),
                      title: Text(
                        suggestions[index].primaryText ??
                            suggestions[index].fullText,
                      ),
                      subtitle: suggestions[index].secondaryText == null
                          ? null
                          : Text(suggestions[index].secondaryText!),
                      onTap: () => onSuggestionSelected(suggestions[index]),
                    ),
                ],
              ),
            ),
          ),
        ],
      ],
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
