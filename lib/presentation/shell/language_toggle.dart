/// EN ⇄ ລາວ switch shown on every branded surface.
///
/// Port of `lcc-app/src/app/components/LanguageToggle.tsx`.
///
/// ## What was ported
///
/// - `toggle()` (`lang === "en" ? "lo" : "en"`) → [_toggle].
/// - The visible label is the language's own name — `"EN"` / `"ລາວ"` — exactly
///   as in the React source. These two strings are deliberately NOT i18n keys:
///   a language's endonym is the same in every locale, and routing it through
///   `.tr()` would let a mistranslation hide the option from the only people
///   who need it.
/// - The tooltip carries the fuller wording and IS translated —
///   `layout.switchToLao` / `layout.switchToEnglish`, the same two keys the
///   React `title` attribute uses.
/// - The chip styling (translucent white fill + hairline border on the brand
///   bar) mirrors `bg-white/15 border-white/20 rounded-xl`.
///
/// ## Deliberate omissions from the React source
///
/// - **The SVG flags.** `LanguageToggle.tsx` hand-draws a UK and a Lao flag in
///   inline SVG. Reproducing them would mean either a `CustomPainter` pair or
///   new image assets; GOR-245 § 3.1 scopes new assets to `assets/i18n/*.json`
///   only, so a decorative flag is out of scope. `Icons.translate` stands in —
///   it was `aria-hidden` in the source, i.e. carried no meaning the label does
///   not already carry.
/// - **`me.updateProfile({preferred_lang})`.** The React toggle also mirrors
///   the choice onto the citizen's account so it follows them to another
///   device. That is a `PATCH /me/profile` call; GOR-245 § 6 declares *no API
///   change* and § 4.3 makes a new API constant an escalation, so the
///   server-side mirror is deferred to the batch that wires `me.profile`
///   writes. The React source already treats the network write as best-effort
///   ("the UI must never wait on the network to change language"), so P0
///   behaviour is the local-first half of the same design, not a regression.
///
/// ## Persistence
///
/// `easy_localization`'s own `saveLocale` is switched **off** in `main.dart`;
/// the language lives in [StorageService] under the `lcc.lang` key, which
/// GOR-245 § 4.2 freezes. `main.dart` reads it back at boot and hands it to
/// `EasyLocalization(startLocale: …)`. Keeping one writer avoids the split
/// brain where easy_localization's `SharedPreferences` copy and `lcc.lang`
/// disagree after an upgrade.
library;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../core/storage/storage_service.dart';

class LanguageToggle extends StatelessWidget {
  const LanguageToggle({super.key, required this.storage});

  /// The persistence sink for the chosen language.
  ///
  /// **Required, and never resolved from a locator here** (CR-1). The SSD's
  /// § 6.4 seam is "route builders and `main.dart` may resolve from a locator;
  /// no widget may" — so the `ShellRoute` builder in
  /// `lib/utils/routes/app_routes.dart` calls `injection<StorageService>()`
  /// once and threads the result down through `AppShell` → `AppTopBar` → here.
  ///
  /// This used to be `StorageService?` with a
  /// `storage ?? injection<StorageService>()` fallback inside the tap handler,
  /// i.e. a global-locator read from inside a widget with a test-only
  /// constructor seam bolted on beside it. Making the parameter required
  /// deletes the fallback branch: there is now exactly one way the dependency
  /// arrives, the same way in the app and in a test, and `G-L5`
  /// (`test/architecture/layering_test.dart`) fails the build if the locator
  /// read ever comes back.
  final StorageService storage;

  static const Locale _en = Locale('en');
  static const Locale _lo = Locale('lo');

  /// The locale currently on screen.
  ///
  /// Read through `Localizations.localeOf`, **not** `easy_localization`'s
  /// `context.locale`. The latter is `EasyLocalization.of(context)!.locale` —
  /// a bare null-check that throws `Null check operator used on a null value`
  /// the moment this widget is built without an `EasyLocalization` ancestor.
  /// `MaterialApp` always installs a `Localizations`, and `main.dart` feeds it
  /// `locale: context.locale`, so the two values agree in the running app —
  /// but only this one survives a widget test that pumps the shell without
  /// standing the whole localisation stack up first. Given the one existing
  /// widget test in this repo is permanently skipped *because* that stack
  /// stalls headless, a chrome widget that cannot be pumped without it is a
  /// real defect, not a theoretical one.
  static bool _isEnglish(BuildContext context) =>
      Localizations.localeOf(context).languageCode == _en.languageCode;

  Future<void> _toggle(BuildContext context) async {
    final Locale next = _isEnglish(context) ? _lo : _en;

    // Resolved before the first await, so nothing reads `context` across an
    // asynchronous gap.
    //
    // Type left inferred: `EasyLocalization.of` returns a library-private
    // provider type that cannot be named from here.
    final localization = EasyLocalization.of(context);

    // Null only when there is no EasyLocalization ancestor — impossible in the
    // running app (see `main.dart`), and harmless in a test that only wants to
    // assert the persistence side.
    await localization?.setLocale(next);
    await storage.saveLang(next.languageCode);
  }

  @override
  Widget build(BuildContext context) {
    final bool isEnglish = _isEnglish(context);
    final String label = isEnglish ? 'EN' : 'ລາວ';
    final String tooltip =
        (isEnglish ? 'layout.switchToLao' : 'layout.switchToEnglish').tr();

    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: () => _toggle(context),
        borderRadius: BorderRadius.circular(12),
        child: Semantics(
          button: true,
          label: tooltip,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                const Icon(Icons.translate, size: 16, color: Colors.white),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
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
