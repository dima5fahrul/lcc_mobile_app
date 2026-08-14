/// The Notifications panel and the biometric switch — `AccountPage.tsx:572-603`
/// and `:662-671`.
///
/// Two surfaces, one file, because they are the same three-part contract over
/// the same BLoC: a skeleton while `prefsQuery` is loading, an inline error
/// with a retry, and the switches once `prefs` exists.
///
/// ## `{prefsQuery.loading && …}` and `{prefsQuery.error && …}` are INDEPENDENT
///
/// `:572` and `:573` are two `&&` fragments, not an if/else. A refetch in
/// flight after a previous failure renders the skeleton **and** the error row
/// together. Reproduced literally; see `AccountPreferencesState.hasFailed`.
///
/// ## The switches do not move until the refetch lands
///
/// `checked={prefs.notifications[key]}` reads `prefsQuery.data`, and
/// `updatePrefs` writes to it only via `prefsQuery.refetch()`. So a tap sends a
/// `PUT`, waits, sends a `GET`, waits, and *then* the switch moves. That is
/// worse than an optimistic flip and it is what the shipped app does; porting
/// the flip would be an R-25-class improvement no fidelity tier can see.
library;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../presentation/theme/app_colors.dart';
import '../../../../presentation/theme/app_spacing.dart';
import '../../../../presentation/theme/app_typography.dart';
import '../../domain/entities/citizen_preferences.dart';
import '../bloc/account_preferences_bloc.dart';
import 'account_primitives.dart';

/// `:571-603` — the body of the Notifications row.
class NotificationsPanel extends StatelessWidget {
  const NotificationsPanel({
    super.key,
    required this.loading,
    required this.errorMessage,
    required this.preferences,
    required this.saveError,
    required this.onRetry,
    required this.onToggle,
  });

  final bool loading;
  final String? errorMessage;
  final CitizenPreferences? preferences;
  final String? saveError;
  final VoidCallback onRetry;
  final void Function(NotificationChannel channel, bool enabled) onToggle;

  @override
  Widget build(BuildContext context) {
    final CitizenPreferences? prefs = preferences;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        // `{prefsQuery.loading && <div className="h-20 … animate-pulse" />}`
        if (loading) const AccountSkeleton(height: 80),

        // `{prefsQuery.error && …}` — independent of the above, see the doc.
        if (errorMessage != null)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.gap8),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    // No local fallback string: the source renders
                    // `prefsQuery.error.message` bare (`:575`).
                    errorMessage!,
                    style: const TextStyle(
                      color: AppColors.dangerText,
                      fontSize: AppTypography.size12,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.gap12),
                AccountButton(
                  label: 'account.retry'.tr(),
                  secondary: true,
                  onPressed: onRetry,
                ),
              ],
            ),
          ),

        // `{prefs && …}` — `:581`.
        if (prefs != null) ...<Widget>[
          // The three, **in the source's order** (`:583-587`): in_app, email,
          // sms. Order is a Tier 1 assertion.
          _SwitchRow(
            label: 'account.inApp'.tr(),
            value: prefs.notifications.inApp,
            onChanged: (bool next) =>
                onToggle(NotificationChannel.inApp, next),
          ),
          const SizedBox(height: AppSpacing.gap12),
          _SwitchRow(
            label: 'account.emailNotif'.tr(),
            value: prefs.notifications.email,
            onChanged: (bool next) =>
                onToggle(NotificationChannel.email, next),
          ),
          const SizedBox(height: AppSpacing.gap12),
          _SwitchRow(
            label: 'account.smsNotif'.tr(),
            value: prefs.notifications.sms,
            onChanged: (bool next) => onToggle(NotificationChannel.sms, next),
          ),
          // `{savePrefs.error && …}` — `:599-601`.
          if (saveError != null)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.gap12),
              child: Text(
                saveError!,
                style: const TextStyle(
                  color: AppColors.dangerGlyph,
                  fontSize: AppTypography.size12,
                ),
              ),
            ),
        ],
      ],
    );
  }
}

/// `{prefs && <div className="flex items-center justify-between gap-4">…}` —
/// `:662-671`, the biometric switch inside the Security panel.
class BiometricSwitch extends StatelessWidget {
  const BiometricSwitch({
    super.key,
    required this.preferences,
    required this.onChanged,
  });

  final CitizenPreferences? preferences;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final CitizenPreferences? prefs = preferences;
    // `{prefs && …}` — absent, not disabled, before the first read.
    if (prefs == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.gap16),
      child: _SwitchRow(
        label: 'account.biometric'.tr(),
        value: prefs.biometricLogin,
        onChanged: onChanged,
      ),
    );
  }
}

/// `<div className="flex items-center justify-between gap-4">` with a
/// `text-sm text-gray-700` label and a [AccountToggle].
///
/// The label string is passed to the toggle's `aria-label` as well, which is
/// what the source does (`label={label}` at `:591`).
class _SwitchRow extends StatelessWidget {
  const _SwitchRow({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) => Row(
        children: <Widget>[
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.gray700,
                fontSize: AppTypography.size14,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.gap16),
          AccountToggle(value: value, label: label, onChanged: onChanged),
        ],
      );
}
