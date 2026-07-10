import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../data/services/mode_catalog.dart';
import '../../../services/api_client.dart';
import '../../../services/app_data_maintenance_service.dart';
import '../../../services/runtime_config.dart';
import '../../../shared/widgets/shared_widgets.dart';
import '../../saved/application/saved_library_controller.dart';
import '../application/profile_settings_controller.dart';
import '../domain/profile_settings.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  Future<_ApiHealthResult>? _healthCheck;

  @override
  Widget build(BuildContext context) {
    final catalog = ref.watch(modeCatalogProvider);
    final settings = ref.watch(profileSettingsProvider);
    final currentSettings = settings.value;
    final cityLabel = currentSettings == null
        ? 'Loading preferences…'
        : currentSettings.locationPreference ==
              LocationPreference.currentLocation
        ? 'Current location'
        : currentSettings.defaultCity.label;

    return ColoredBox(
      key: const ValueKey('profile-screen'),
      color: AppColors.surface,
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: GradientHeader(
              compact: true,
              title: 'Profile',
              subtitle: 'Preferences for smarter local picks.',
              bottom: Row(
                children: [
                  const SoftIconBadge(
                    icon: Icons.person_rounded,
                    color: AppColors.white,
                    backgroundColor: AppColors.primaryBlue,
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Your GoMode',
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(
                                color: AppColors.white,
                                fontWeight: FontWeight.w900,
                              ),
                        ),
                        Text(
                          cityLabel,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: AppColors.white.withValues(alpha: 0.72),
                              ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(AppSpacing.page),
            sliver: SliverList.list(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _ProfileMetric(
                        label: 'Modes',
                        value: '${catalog.modes.length}',
                        color: AppColors.primaryBlue,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: _ProfileMetric(
                        label: 'Map ready',
                        value: '${catalog.mapModes.length}',
                        color: AppColors.teal,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: _ProfileMetric(
                        label: 'Local first',
                        value: '100%',
                        color: AppColors.coral,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xl),
                settings.when(
                  loading: () => const _SettingsLoading(),
                  error: (error, stackTrace) => _SettingsError(
                    onRetry: () => ref.invalidate(profileSettingsProvider),
                  ),
                  data: _SettingsContent.new,
                ),
                const SizedBox(height: AppSpacing.xl),
                const _SectionTitle(
                  icon: Icons.apps_rounded,
                  title: 'App',
                  subtitle: 'Data, legal, and app controls',
                ),
                const SizedBox(height: AppSpacing.sm),
                _SettingsCard(
                  children: [
                    const _ActionRow(
                      icon: Icons.notifications_none_rounded,
                      color: AppColors.lavender,
                      title: 'Notifications',
                      subtitle: 'Reminders and saved-plan alerts',
                      statusLabel: 'Coming soon',
                    ),
                    _ActionRow(
                      key: const ValueKey('open-privacy-screen'),
                      icon: Icons.privacy_tip_outlined,
                      color: AppColors.teal,
                      title: 'Privacy',
                      subtitle: 'How location and saved items are handled',
                      onTap: () => context.push('/privacy'),
                    ),
                    _ActionRow(
                      key: const ValueKey('open-terms-screen'),
                      icon: Icons.description_outlined,
                      color: AppColors.amber,
                      title: 'Terms',
                      subtitle: 'MVP terms and important limitations',
                      onTap: () => context.push('/terms'),
                    ),
                    _ActionRow(
                      key: const ValueKey('clear-cache-button'),
                      icon: Icons.cleaning_services_outlined,
                      color: AppColors.primaryBlue,
                      title: 'Clear cache',
                      subtitle: 'Remove cached API responses',
                      onTap: _clearCache,
                    ),
                    _ActionRow(
                      key: const ValueKey('reset-demo-data-button'),
                      icon: Icons.restart_alt_rounded,
                      color: AppColors.coral,
                      title: 'Reset demo data',
                      subtitle: 'Restore sample saved plans and route choices',
                      destructive: true,
                      onTap: _confirmResetDemoData,
                    ),
                  ],
                ),
                if (kDebugMode) ...[
                  const SizedBox(height: AppSpacing.xl),
                  const _SectionTitle(
                    icon: Icons.developer_mode_rounded,
                    title: 'Developer',
                    subtitle: 'Safe runtime diagnostics — no secrets',
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  _DeveloperCard(
                    healthCheck: _healthCheck,
                    onRunChecks: _runHealthChecks,
                    onOpenDesignDebug: () => context.push('/debug/design'),
                  ),
                ],
                SizedBox(height: AppSpacing.bottomNavHeight + AppSpacing.xl),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _clearCache() async {
    final count = await ref
        .read(appDataMaintenanceServiceProvider)
        .clearBackendCache();
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Cache cleared · $count local entries removed.')),
    );
  }

  Future<void> _confirmResetDemoData() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset demo data?'),
        content: const Text(
          'This restores the sample saved plans and clears road-trip save choices. Your profile preferences stay the same.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            key: const ValueKey('confirm-reset-demo-data'),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Reset'),
          ),
        ],
      ),
    );
    if (confirmed != true) {
      return;
    }
    await ref.read(appDataMaintenanceServiceProvider).resetDemoData();
    ref.invalidate(savedLibraryProvider);
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Demo data restored.')));
  }

  void _runHealthChecks() {
    setState(() {
      _healthCheck = _checkBackend(ref.read(backendApiClientProvider));
    });
  }
}

class _SettingsContent extends ConsumerWidget {
  const _SettingsContent(this.settings);

  final ProfileSettings settings;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(profileSettingsProvider.notifier);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _SectionTitle(
          icon: Icons.location_on_outlined,
          title: 'Location preference',
          subtitle: 'Choose how GoMode centers nearby results',
        ),
        const SizedBox(height: AppSpacing.sm),
        _SettingsCard(
          children: [
            _ChoiceRow(
              key: const ValueKey('location-current'),
              icon: Icons.my_location_rounded,
              title: LocationPreference.currentLocation.label,
              subtitle: 'Ask for while-in-use permission when needed',
              selected:
                  settings.locationPreference ==
                  LocationPreference.currentLocation,
              onTap: () => controller.setLocationPreference(
                LocationPreference.currentLocation,
              ),
            ),
            _ChoiceRow(
              key: const ValueKey('location-default-city'),
              icon: Icons.location_city_rounded,
              title: LocationPreference.defaultCity.label,
              subtitle: 'Search near a city without device location',
              selected:
                  settings.locationPreference == LocationPreference.defaultCity,
              onTap: () => controller.setLocationPreference(
                LocationPreference.defaultCity,
              ),
            ),
            if (settings.locationPreference == LocationPreference.defaultCity)
              _DefaultCityPicker(settings: settings),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        const _PrivacyHint(),
        const SizedBox(height: AppSpacing.xl),
        const _SectionTitle(
          icon: Icons.tune_rounded,
          title: 'Preferences',
          subtitle: 'Defaults applied when a mode supports them',
        ),
        const SizedBox(height: AppSpacing.sm),
        _SettingsCard(
          children: [
            _OptionRow<BudgetPreference>(
              title: 'Budget default',
              icon: Icons.payments_outlined,
              values: BudgetPreference.values,
              selected: settings.budget,
              labelFor: (value) => value.label,
              keyFor: (value) => 'profile-budget-${value.name}',
              onSelected: controller.setBudget,
            ),
            _OptionRow<int>(
              title: 'Distance default',
              icon: Icons.near_me_outlined,
              values: const [2, 5, 10, 25],
              selected: settings.distanceMiles,
              labelFor: (value) => '$value mi',
              keyFor: (value) => 'profile-distance-$value',
              onSelected: controller.setDistance,
            ),
            _OptionRow<SettingPreference>(
              title: 'Indoor / outdoor',
              icon: Icons.wb_sunny_outlined,
              values: SettingPreference.values,
              selected: settings.setting,
              labelFor: (value) => value.label,
              keyFor: (value) => 'profile-setting-${value.name}',
              onSelected: controller.setSetting,
            ),
            _SwitchRow(
              key: const ValueKey('profile-family-filter'),
              icon: Icons.family_restroom_rounded,
              title: 'Family-friendly filter',
              subtitle: 'Prioritize places that work for families',
              value: settings.familyFriendly,
              onChanged: controller.setFamilyFriendly,
            ),
            _SwitchRow(
              key: const ValueKey('profile-pet-filter'),
              icon: Icons.pets_rounded,
              title: 'Pet-friendly filter',
              subtitle: 'Prioritize pet-friendly leads when supported',
              value: settings.petFriendly,
              onChanged: controller.setPetFriendly,
            ),
            _SwitchRow(
              key: const ValueKey('profile-accessibility-filter'),
              icon: Icons.accessible_forward_rounded,
              title: 'Accessibility preference',
              subtitle: 'Prioritize accessible options when data is available',
              value: settings.accessibilityPreferred,
              onChanged: controller.setAccessibilityPreferred,
            ),
          ],
        ),
      ],
    );
  }
}

class _DefaultCityPicker extends StatelessWidget {
  const _DefaultCityPicker({required this.settings});

  final ProfileSettings settings;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.xs,
        AppSpacing.md,
        AppSpacing.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Default city',
            style: Theme.of(
              context,
            ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: AppSpacing.xs),
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: [
              for (final city in defaultCities)
                Consumer(
                  builder: (context, ref, child) => ChoiceChip(
                    key: ValueKey('profile-city-${city.id}'),
                    label: Text(city.label),
                    selected: city.id == settings.defaultCityId,
                    onSelected: (_) => ref
                        .read(profileSettingsProvider.notifier)
                        .setDefaultCity(city.id),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PrivacyHint extends StatelessWidget {
  const _PrivacyHint();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.teal.withValues(alpha: 0.09),
        borderRadius: AppRadius.largeCard,
        border: Border.all(color: AppColors.teal.withValues(alpha: 0.24)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.shield_outlined, color: AppColors.teal),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              'Location is used to find nearby results while you use GoMode. Choose a default city to browse without sharing device location.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OptionRow<T> extends StatelessWidget {
  const _OptionRow({
    required this.title,
    required this.icon,
    required this.values,
    required this.selected,
    required this.labelFor,
    required this.keyFor,
    required this.onSelected,
  });

  final String title;
  final IconData icon;
  final List<T> values;
  final T selected;
  final String Function(T) labelFor;
  final String Function(T) keyFor;
  final ValueChanged<T> onSelected;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.primaryBlue, size: 21),
              const SizedBox(width: AppSpacing.xs),
              Text(
                title,
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: [
              for (final value in values)
                ChoiceChip(
                  key: ValueKey(keyFor(value)),
                  label: Text(labelFor(value)),
                  selected: value == selected,
                  onSelected: (_) => onSelected(value),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ChoiceRow extends StatelessWidget {
  const _ChoiceRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
    super.key,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              Icon(icon, color: AppColors.teal),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: selected ? AppColors.primaryBlue : AppColors.white,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: selected
                        ? AppColors.primaryBlue
                        : AppColors.borderStrong,
                    width: 2,
                  ),
                ),
                child: selected
                    ? const Icon(
                        Icons.check_rounded,
                        color: AppColors.white,
                        size: 17,
                      )
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SwitchRow extends StatelessWidget {
  const _SwitchRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
    super.key,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: SwitchListTile.adaptive(
        secondary: Icon(icon, color: AppColors.primaryBlue),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
        subtitle: Text(subtitle),
        value: value,
        onChanged: onChanged,
        contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  const _SettingsCard({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: AppRadius.largeCard,
        border: Border.all(color: AppColors.border),
        boxShadow: AppShadows.soft,
      ),
      child: Column(
        children: [
          for (var index = 0; index < children.length; index++) ...[
            children[index],
            if (index != children.length - 1)
              const Divider(
                height: 1,
                indent: AppSpacing.md,
                endIndent: AppSpacing.md,
              ),
          ],
        ],
      ),
    );
  }
}

class _ActionRow extends StatelessWidget {
  const _ActionRow({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    this.onTap,
    this.statusLabel,
    this.destructive = false,
    super.key,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  final String? statusLabel;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              SoftIconBadge(
                icon: icon,
                color: color,
                size: 46,
                iconSize: 23,
                showShadow: false,
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: destructive ? AppColors.danger : null,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              if (statusLabel != null)
                StatusPill(label: statusLabel!, color: color)
              else
                const Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.textMuted,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DeveloperCard extends ConsumerWidget {
  const _DeveloperCard({
    required this.healthCheck,
    required this.onRunChecks,
    required this.onOpenDesignDebug,
  });

  final Future<_ApiHealthResult>? healthCheck;
  final VoidCallback onRunChecks;
  final VoidCallback onOpenDesignDebug;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final backendConfigured = ref.watch(backendApiClientProvider).isConfigured;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.navy900,
        borderRadius: AppRadius.largeCard,
        boxShadow: AppShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _DiagnosticRow(
            label: 'Backend configured?',
            value: backendConfigured ? 'Yes' : 'No',
            healthy: backendConfigured,
          ),
          _DiagnosticRow(
            label: 'Active project ID',
            value: firebaseProjectId.isEmpty
                ? 'Not provided'
                : firebaseProjectId,
            healthy: firebaseProjectId.isNotEmpty,
          ),
          _DiagnosticRow(
            label: 'Demo fallback',
            value: backendConfigured ? 'Standby' : 'Active',
            healthy: true,
          ),
          _DiagnosticRow(
            label: 'Google map widget',
            value: googleMapsWidgetEnabled ? 'Enabled' : 'Placeholder',
            healthy: true,
          ),
          const SizedBox(height: AppSpacing.sm),
          if (healthCheck != null)
            FutureBuilder<_ApiHealthResult>(
              future: healthCheck,
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const LinearProgressIndicator();
                }
                final result = snapshot.requireData;
                return _DiagnosticRow(
                  label: 'Places API health',
                  value: result.message,
                  healthy: result.healthy,
                );
              },
            ),
          const SizedBox(height: AppSpacing.sm),
          OutlinedButton.icon(
            key: const ValueKey('run-api-health-checks'),
            onPressed: onRunChecks,
            icon: const Icon(Icons.monitor_heart_outlined),
            label: const Text('Run API health checks'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.white,
              side: BorderSide(color: AppColors.white.withValues(alpha: 0.28)),
            ),
          ),
          TextButton.icon(
            onPressed: onOpenDesignDebug,
            icon: const Icon(Icons.palette_outlined),
            label: const Text('Open design debug'),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.primaryBlueLight,
            ),
          ),
        ],
      ),
    );
  }
}

class _DiagnosticRow extends StatelessWidget {
  const _DiagnosticRow({
    required this.label,
    required this.value,
    required this.healthy,
  });

  final String label;
  final String value;
  final bool healthy;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Icon(
            healthy ? Icons.check_circle_rounded : Icons.info_rounded,
            color: healthy ? AppColors.teal : AppColors.amber,
            size: 18,
          ),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.white.withValues(alpha: 0.72),
              ),
            ),
          ),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.white,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: AppColors.primaryBlue),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
              ),
              Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
      ],
    );
  }
}

class _ProfileMetric extends StatelessWidget {
  const _ProfileMetric({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceRaised,
        borderRadius: AppRadius.card,
        border: Border.all(color: AppColors.border),
        boxShadow: AppShadows.soft,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            maxLines: 1,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w900,
            ),
          ),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelSmall,
          ),
        ],
      ),
    );
  }
}

class _SettingsLoading extends StatelessWidget {
  const _SettingsLoading();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: 180,
      child: Center(child: CircularProgressIndicator()),
    );
  }
}

class _SettingsError extends StatelessWidget {
  const _SettingsError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return _SettingsCard(
      children: [
        Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            children: [
              const Text('Preferences could not be loaded.'),
              TextButton(onPressed: onRetry, child: const Text('Try again')),
            ],
          ),
        ),
      ],
    );
  }
}

class _ApiHealthResult {
  const _ApiHealthResult({required this.healthy, required this.message});

  final bool healthy;
  final String message;
}

Future<_ApiHealthResult> _checkBackend(BackendApiClient client) async {
  if (!client.isConfigured) {
    return const _ApiHealthResult(
      healthy: false,
      message: 'Skipped · backend not configured',
    );
  }
  try {
    final result = await client.call('searchPlaces', {
      'latitude': 30.2672,
      'longitude': -97.7431,
      'modeId': 'developer-health-check',
      'query': 'coffee',
      'radius': 1000,
      'openNow': false,
      'maxResults': 1,
    });
    final places = result['places'];
    return _ApiHealthResult(
      healthy: places is List,
      message: places is List ? 'Healthy' : 'Unexpected response',
    );
  } catch (error) {
    return _ApiHealthResult(
      healthy: false,
      message: error is BackendException ? error.kind.name : 'Failed',
    );
  }
}
