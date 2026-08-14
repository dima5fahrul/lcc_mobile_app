/// The Language panel — `AccountPage.tsx:614-635`, and **R-25's second
/// mirror**.
///
/// ```tsx
/// onClick={() => { setLang(code); updatePrefs({ language: code }); }}
/// ```
///
/// Two writes, one tap, and they go to **different endpoints with different
/// field names** (specs.md § 2.2 Finding H):
///
/// | Surface | Call | Endpoint | Field |
/// |---|---|---|---|
/// | The top-bar `LanguageToggle` | `me.updateProfile({preferred_lang})` | `PATCH /me/profile` | `preferred_lang` |
/// | **This row** | `updatePrefs({language: code})` | `PUT /me/preferences` | `language` |
///
/// R-25 as written names only the first. **B8 ports both** and B8-AC-18
/// asserts they stay distinct — collapsing them into one call is the tidying
/// that would silently drop one of the two server fields the shipped app
/// maintains.
///
/// `setLang(code)` is the **local** half and it is this widget's, because it
/// needs a `BuildContext` for `EasyLocalization`. It runs first, matching the
/// source's statement order and the local-first posture the top-bar toggle also
/// keeps.
///
/// ## The active branch reads `prefs?.language ?? lang`, not `lang`
///
/// `:616`. So before the first successful `GET /me/preferences` the highlight
/// follows the reader's locale, and afterwards it follows the **server's**
/// record — which can disagree, and visibly does for one frame after a tap
/// (the switch does not move until the refetch lands; see
/// `preferences_panel.dart`). That is the measured behaviour.
///
/// ## The two labels are NOT i18n keys
///
/// `{code === "lo" ? "ລາວ" : "English"}` (`:631`) — a language's endonym is the
/// same in every locale, and routing it through `.tr()` would let a
/// mistranslation hide the option from the only people who need it. The same
/// ruling `language_toggle.dart` already records for `EN` / `ລາວ`.
library;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../i18n/i18n.dart';
import '../../../../presentation/theme/app_colors.dart';
import '../../../../presentation/theme/app_spacing.dart';
import '../../../../presentation/theme/app_typography.dart';
import '../../domain/entities/citizen_preferences.dart';

class LanguagePanel extends StatelessWidget {
  const LanguagePanel({
    super.key,
    required this.preferences,
    required this.onSelected,
  });

  final CitizenPreferences? preferences;

  /// Dispatches `AccountLanguageSelected`. The **local** `setLang` happens here
  /// first; see the library doc.
  final ValueChanged<String> onSelected;

  /// `(["lo", "en"] as const)` — `:615`. **Lao first**, which is the source's
  /// order and is a Tier 1 assertion.
  static const List<String> codes = <String>['lo', 'en'];

  /// The endonyms, not i18n keys. See the library doc.
  static String labelFor(String code) => code == 'lo' ? 'ລາວ' : 'English';

  @override
  Widget build(BuildContext context) {
    // `prefs?.language ?? lang` — `:616`.
    final String active = (preferences?.language.isNotEmpty ?? false)
        ? preferences!.language
        : Localizations.localeOf(context).languageCode;

    return Row(
      children: <Widget>[
        for (final String code in codes) ...<Widget>[
          if (code != codes.first) const SizedBox(width: AppSpacing.gap8),
          Expanded(
            child: _LanguageButton(
              code: code,
              active: active == code,
              onTap: () => _select(context, code),
            ),
          ),
        ],
      ],
    );
  }

  Future<void> _select(BuildContext context, String code) async {
    // `setLang(code)` — `:621`. Local first, exactly as in the top bar.
    //
    // Resolved before the await so nothing reads `context` across an
    // asynchronous gap. `EasyLocalization.of` returns a library-private
    // provider type, so the local is inferred.
    final localization = EasyLocalization.of(context);
    await localization?.setLocale(Lang.fromCode(code).toLocale());

    // `updatePrefs({ language: code })` — `:622`. The BLoC owns the merge, the
    // `PUT` and the refetch.
    onSelected(code);
  }
}

/// `flex-1 py-2.5 rounded-xl border text-sm font-medium` with the three-value
/// active/inactive triple at `:625-629`.
class _LanguageButton extends StatelessWidget {
  const _LanguageButton({
    required this.code,
    required this.active,
    required this.onTap,
  });

  final String code;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: active ? AppColors.primarySoft : AppColors.white,
      borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.gap10),
          decoration: BoxDecoration(
            border: Border.all(
              color: active ? AppColors.primary : AppColors.gray200,
            ),
            borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
          ),
          child: Center(
            child: Text(
              LanguagePanel.labelFor(code),
              style: TextStyle(
                color: active ? AppColors.primary : AppColors.muted,
                fontSize: AppTypography.size14,
                fontWeight: AppTypography.medium,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
