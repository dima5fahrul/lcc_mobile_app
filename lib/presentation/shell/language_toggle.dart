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
/// ## R-24 — the flags, resolved
///
/// `LanguageToggle.tsx:14-53` hand-draws a UK and a Lao flag in inline SVG.
/// GOR-245's asset scope had no room for them and `Icons.translate` stood in.
/// **B2a ships `flutter_svg`, which is the condition § VII.4 / SSD § 10.3
/// attached R-24 to**, so the stand-in is gone: `assets/icons/flags/{uk,lao}.svg`
/// are transcriptions of those two `<svg>` blocks, element for element.
///
/// They are SVG assets rather than a `CustomPainter` pair on purpose — a
/// transcription can be checked against the source line by line, where a
/// subtle geometry error inside a painter is invisible in review.
///
/// The flags are `aria-hidden` in the source. They stay unannounced here: the
/// accessible name is the visible `EN` / `ລາວ` label plus the `Switch to …`
/// tooltip, and an [ExcludeSemantics] makes that structural rather than
/// incidental.
///
/// ## Deliberate omissions from the React source — R-25, now CLOSED by B8a
///
/// - **`me.updateProfile({preferred_lang})`.** The React toggle also mirrors
///   the choice onto the citizen's account so it follows them to another
///   device. That is a `PATCH /me/profile` call; GOR-245 § 6 declares *no API
///   change* and § 4.3 makes a new API constant an escalation, so the
///   server-side mirror is deferred to the batch that wires `me.profile`
///   writes. The React source already treats the network write as best-effort
///   ("the UI must never wait on the network to change language"), so P0
///   behaviour is the local-first half of the same design, not a regression.
///
///   **— omitted at P0, SHIPPED at B8a. B8a is that batch and the omission is
///   closed**: see [_toggle] below and `SessionMirrorLanguage` in
///   `lib/core/session/bloc/session_bloc.dart`. The paragraph above is left
///   **verbatim** rather than rewritten in place, because `B2-AC-25` asserts
///   its opening sentence by string and because the P0 rationale is worth
///   keeping legible next to the thing that superseded it.
///
///   This section is kept rather than deleted (B2-AC-25 made keeping it a
///   requirement, B8-AC-22 makes rewriting-not-deleting one) because it is the
///   only in-code record of *why* the write exists and of the fact that P0
///   shipped without it. A future faithful-port dispatch that finds no note
///   here has no way to tell a deliberate omission from a missed line.
///
///   The port keeps the source's best-effort posture exactly: local first,
///   authenticated only, failure swallowed.
///
///   **Nothing else is omitted.** This heading is now a list of one closed
///   item; the next batch to omit something adds to it.
///
/// ## R-25's mechanism, and why it is an event rather than a parameter
///
/// This widget lives in `lib/presentation/shell/`, where it may not resolve
/// from a locator (G-L5), may not import `features/*/data/**` (G-L1) and may
/// not import `features/*/presentation/**` (G-L7). The established way to give
/// it a dependency is constructor threading — `app_routes.dart` →
/// `AppShell(storage:)` → `AppTopBar(storage:)` → `LanguageToggle(storage:)`,
/// which is how [storage] arrives.
///
/// **B8a deliberately does not extend that chain.** Adding a second parameter
/// means editing `app_shell.dart:76`'s `const AppTopBar()` — the exact line
/// B10's concurrent D-3 work must change — so instead the toggle dispatches an
/// event on the app-wide `SessionBloc`, which is already provided above
/// `MaterialApp.router` and reachable from any widget by context.
/// `BlocProvider.of<SessionBloc>(context)` is a **context read, not a locator
/// read**, which is the distinction G-L5 draws (`account_page.dart` has done
/// the same since P0).
///
/// Three further reasons, from specs.md § 6.4: `SessionBloc` already owns the
/// profile, so routing the write through it is the closer analogue of the
/// web's `useSession`; it adds no second `lib/core/` BLoC (`ssd.md` § 4.5's
/// closed list of one is unchanged, this modifies the existing entry); and
/// `core/session/bloc/**` → `features/session/domain/**` is the single
/// whitelisted `core → features` edge, so the use case is legally reachable.
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
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../core/session/bloc/session_bloc.dart';
import '../../core/storage/storage_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

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

    // R-25's sink, resolved here for the same reason: after the awaits below
    // this method must not touch `context`. `maybeOf`, not `of`, because a
    // widget test may pump the top bar without a session in the tree — the
    // shell is session-agnostic by design (`app_shell.dart`'s own note) and a
    // hard `of` would turn that into a crash.
    final SessionBloc? session = _sessionOf(context);

    // Null only when there is no EasyLocalization ancestor — impossible in the
    // running app (see `main.dart`), and harmless in a test that only wants to
    // assert the persistence side.
    await localization?.setLocale(next);
    await storage.saveLang(next.languageCode);

    // ── R-25 ────────────────────────────────────────────────────────────────
    //
    // **Strictly after the two awaits above**, which is the ported ordering:
    // `toggle()` runs unconditionally at `LanguageToggle.tsx:70`, and only then
    // does `:71` fire the mirror. The locale has changed and `lcc.lang` is
    // written before a single byte goes out, so a dead network cannot stop a
    // citizen changing language (B8-AC-19).
    //
    // No `await`, no `.then`, no error handling **here**: the authenticated
    // gate and the swallowed failure both live in the handler, which is where a
    // spy can see them (B8-AC-20, B8-AC-21). `add` is fire-and-forget by
    // construction, which is `void me.updateProfile(…).catch(…)` exactly.
    session?.add(SessionEvent.mirrorLanguage(next.languageCode));
  }

  /// `BlocProvider.of<SessionBloc>(context)` with the not-in-tree case answered
  /// rather than thrown.
  ///
  /// A **context read**, not a locator read — the distinction G-L5 draws, and
  /// the reason this compiles under a guard that forbids `injection<T>()` in
  /// any `presentation/` file.
  static SessionBloc? _sessionOf(BuildContext context) {
    try {
      return BlocProvider.of<SessionBloc>(context);
    } on FlutterError {
      // `BlocProvider.of` throws a `FlutterError` when no provider is found.
      // Swallowed so the toggle keeps working in a tree without a session —
      // which is also the signed-out shell before boot completes.
      return null;
    }
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
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        child: Semantics(
          button: true,
          label: tooltip,
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.gap10,
              vertical: AppSpacing.gap8,
            ),
            decoration: BoxDecoration(
              color: AppColors.white.withValues(alpha: 0.15),
              border: Border.all(
                color: AppColors.white.withValues(alpha: 0.2),
              ),
              borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                _Flag(isEnglish: isEnglish),
                const SizedBox(width: AppSpacing.gap6),
                Text(
                  label,
                  style: const TextStyle(
                    color: AppColors.white,
                    fontSize: AppTypography.size12,
                    fontWeight: AppTypography.medium,
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

/// The flag disc — **R-24**.
///
/// `LanguageToggle.tsx:76-83`: a `w-5 h-5` circle, `overflow-hidden`, with a
/// `ring-1 ring-white/40` hairline, showing the flag of the language currently
/// in effect (`lang === "en" ? <UkFlag/> : <LaoFlag/>`).
///
/// Both SVGs already clip themselves to a circle, exactly as the source's do —
/// `<clipPath><circle r="30"/></clipPath>` over a 60-unit viewBox. The
/// [ClipOval] here reproduces the CSS `overflow-hidden` on the wrapper, which
/// is what keeps the ring flush with the artwork.
class _Flag extends StatelessWidget {
  const _Flag({required this.isEnglish});

  final bool isEnglish;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: Container(
        width: AppSpacing.flagSize,
        height: AppSpacing.flagSize,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: AppColors.white.withValues(alpha: 0.4),
          ),
        ),
        child: ClipOval(
          child: SvgPicture.asset(
            isEnglish ? kUkFlagAsset : kLaoFlagAsset,
            width: AppSpacing.flagSize,
            height: AppSpacing.flagSize,
          ),
        ),
      ),
    );
  }
}

/// `LanguageToggle.tsx:14-37` — hand-transcribed, not generated by
/// `tool/generate_lucide_svgs.mjs`. These are not lucide icons.
const String kUkFlagAsset = 'assets/icons/flags/uk.svg';

/// `LanguageToggle.tsx:39-53`.
const String kLaoFlagAsset = 'assets/icons/flags/lao.svg';
