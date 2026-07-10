import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../data/monetization_service.dart';
import '../domain/monetization_feature_flags.dart';
import '../domain/monetization_models.dart';

class LeadCaptureForm extends ConsumerStatefulWidget {
  const LeadCaptureForm({required this.type, super.key});

  final LeadCaptureType type;

  @override
  ConsumerState<LeadCaptureForm> createState() => _LeadCaptureFormState();
}

class _LeadCaptureFormState extends ConsumerState<LeadCaptureForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _postalCodeController = TextEditingController();
  bool _privacyConsent = false;
  bool _showConsentError = false;
  bool _submitting = false;
  String? _statusMessage;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _postalCodeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final flags = ref.watch(monetizationFeatureFlagsProvider);
    final service = ref.watch(monetizationServiceProvider);
    if (!flags.leadFormsEnabled || (service.isMock && !kDebugMode)) {
      return const SizedBox.shrink();
    }

    return Container(
      key: ValueKey('lead-capture-form-${widget.type.name}'),
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surfaceRaised,
        borderRadius: AppRadius.largeCard,
        border: Border.all(color: AppColors.border),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Stay updated about ${widget.type.label}',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              service.leadCaptureConfigured
                  ? 'Share only the details needed for this request.'
                  : 'Preview only. Nothing is sent or stored until secure storage and reviewed privacy language are configured.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: service.leadCaptureConfigured
                    ? AppColors.textSecondary
                    : AppColors.warning,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            TextFormField(
              key: const ValueKey('lead-name-field'),
              controller: _nameController,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(labelText: 'Name'),
              validator: (value) => value == null || value.trim().isEmpty
                  ? 'Enter your name.'
                  : null,
            ),
            const SizedBox(height: AppSpacing.sm),
            TextFormField(
              key: const ValueKey('lead-email-field'),
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(labelText: 'Email'),
              validator: _validateEmail,
            ),
            const SizedBox(height: AppSpacing.sm),
            TextFormField(
              key: const ValueKey('lead-postal-code-field'),
              controller: _postalCodeController,
              keyboardType: TextInputType.streetAddress,
              textInputAction: TextInputAction.done,
              decoration: const InputDecoration(labelText: 'Postal code'),
              validator: (value) => value == null || value.trim().length < 3
                  ? 'Enter a valid postal code.'
                  : null,
            ),
            const SizedBox(height: AppSpacing.xs),
            Material(
              color: Colors.transparent,
              child: CheckboxListTile(
                key: const ValueKey('lead-privacy-consent'),
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                value: _privacyConsent,
                onChanged: (value) {
                  setState(() {
                    _privacyConsent = value ?? false;
                    _showConsentError = false;
                  });
                },
                title: const Text(
                  'I agree to be contacted about this request and accept the privacy notice.',
                ),
                subtitle: _showConsentError
                    ? const Text(
                        'Consent is required.',
                        style: TextStyle(color: AppColors.danger),
                      )
                    : null,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            FilledButton.icon(
              key: const ValueKey('lead-submit-button'),
              onPressed: _submitting ? null : _submit,
              icon: const Icon(Icons.send_rounded),
              label: Text(_submitting ? 'Sending…' : 'Request follow-up'),
            ),
            if (_statusMessage != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                _statusMessage!,
                key: const ValueKey('lead-capture-status'),
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String? _validateEmail(String? value) {
    final email = value?.trim() ?? '';
    if (email.isEmpty) {
      return 'Enter your email.';
    }
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
      return 'Enter a valid email.';
    }
    return null;
  }

  Future<void> _submit() async {
    final valid = _formKey.currentState?.validate() ?? false;
    if (!valid || !_privacyConsent) {
      setState(() => _showConsentError = !_privacyConsent);
      return;
    }

    final service = ref.read(monetizationServiceProvider);
    if (!service.leadCaptureConfigured) {
      setState(() {
        _statusMessage =
            'Lead capture is not configured. Nothing was sent or stored.';
      });
      return;
    }

    setState(() => _submitting = true);
    final result = await service.submitLeadCapture(
      LeadCapture(
        type: widget.type,
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        postalCode: _postalCodeController.text.trim(),
        privacyConsent: _privacyConsent,
      ),
    );
    if (!mounted) {
      return;
    }
    setState(() {
      _submitting = false;
      _statusMessage = switch (result) {
        LeadCaptureSubmissionResult.accepted => 'Request received.',
        LeadCaptureSubmissionResult.rejected =>
          'The request could not be accepted.',
        LeadCaptureSubmissionResult.unavailable =>
          'Lead capture is unavailable. Nothing was stored.',
      };
    });
  }
}
