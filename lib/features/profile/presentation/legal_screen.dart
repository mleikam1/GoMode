import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/shared_widgets.dart';

class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return _LegalScreen(
      key: const ValueKey('privacy-screen'),
      title: 'Privacy',
      subtitle: 'Plain-language privacy notes for the current MVP.',
      sections: const [
        _LegalSection(
          icon: Icons.location_on_outlined,
          title: 'Location',
          body:
              'GoMode uses your location to find nearby results and center map suggestions. Location is requested only while you use the app. You can choose a default city instead.',
        ),
        _LegalSection(
          icon: Icons.key_outlined,
          title: 'API keys',
          body:
              'Google service API keys are kept server-side. Mobile map display keys, when enabled, are platform-restricted and are not used for backend data access.',
        ),
        _LegalSection(
          icon: Icons.bookmark_outline_rounded,
          title: 'Saved items',
          body:
              'Saved places, plans, routes, collections, and preferences stay on this device unless a future cloud-sync feature is added and you choose to use it.',
        ),
        _LegalSection(
          icon: Icons.handshake_outlined,
          title: 'Personal data',
          body:
              'GoMode does not sell personal data in the current MVP. If the product or data practices change, this notice must be updated before release.',
        ),
      ],
    );
  }
}

class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return _LegalScreen(
      key: const ValueKey('terms-screen'),
      title: 'Terms',
      subtitle: 'Important limitations for the GoMode MVP.',
      sections: const [
        _LegalSection(
          icon: Icons.explore_outlined,
          title: 'Planning assistance',
          body:
              'GoMode provides planning suggestions, not guarantees. Verify hours, prices, availability, accessibility, pet policies, and route conditions with the venue or service provider.',
        ),
        _LegalSection(
          icon: Icons.warning_amber_rounded,
          title: 'Safety',
          body:
              'Do not interact with GoMode while driving. Follow traffic laws, official emergency guidance, posted rules, and personal medical advice.',
        ),
        _LegalSection(
          icon: Icons.science_outlined,
          title: 'Demo data',
          body:
              'Some screens use clearly identified demo fallback data when live services are not configured or temporarily unavailable.',
        ),
      ],
    );
  }
}

class _LegalScreen extends StatelessWidget {
  const _LegalScreen({
    required this.title,
    required this.subtitle,
    required this.sections,
    super.key,
  });

  final String title;
  final String subtitle;
  final List<_LegalSection> sections;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: GradientHeader(
              compact: true,
              title: title,
              subtitle: subtitle,
              leading: HeaderIconButton(
                icon: Icons.arrow_back_rounded,
                onTap: () {
                  if (context.canPop()) {
                    context.pop();
                  } else {
                    context.go('/profile');
                  }
                },
              ),
              trailing: const SizedBox.square(dimension: 46),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(AppSpacing.page),
            sliver: SliverList.list(
              children: [
                for (final section in sections) ...[
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: AppRadius.largeCard,
                      border: Border.all(color: AppColors.border),
                      boxShadow: AppShadows.soft,
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SoftIconBadge(
                          icon: section.icon,
                          color: AppColors.primaryBlue,
                          showShadow: false,
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                section.title,
                                style: Theme.of(context).textTheme.titleLarge
                                    ?.copyWith(fontWeight: FontWeight.w900),
                              ),
                              const SizedBox(height: AppSpacing.xs),
                              Text(
                                section.body,
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(
                                      color: AppColors.textSecondary,
                                      height: 1.45,
                                    ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                ],
                const SizedBox(height: AppSpacing.xl),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LegalSection {
  const _LegalSection({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;
}
