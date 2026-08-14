/// **B8-AC-17's local half — the one this batch shipped implemented but
/// unasserted.**
///
/// `tier0_account_payload_test.dart` gates the *payload* half of B8-AC-17: the
/// Language row `PUT`s the whole merged preferences object to
/// `/me/preferences` under the field `language`, and it is a different request
/// from the top bar's `PATCH /me/profile` `preferred_lang` mirror
/// (specs.md § 2.2 Finding H).
///
/// But B8-AC-17 has a second clause — *"and additionally changes the local
/// locale"* — and coverage measured `language_panel.dart` at **5.6 %**: no test
/// drove `_select` at all. `setLocale` was implemented (`:101`) and nothing
/// proved it ran. Under `FACTORY-RULES.md`'s Capability Rule that is evidence
/// for the wiring, not for the criterion.
///
/// ## The rival is the point, not decoration
///
/// A test that taps the row and asserts `onSelected('lo')` fired would pass
/// against a panel that **only** dispatches and never touches the locale —
/// which is exactly the plausible wrong port, because the BLoC round-trip
/// refetches preferences and the highlight would eventually move anyway
/// (`:616` reads `prefs?.language ?? lang`). The citizen would tap "ລາວ", see
/// the pill highlight, and watch every other string on the page stay English
/// until the next app launch.
///
/// So [_DispatchOnlyPanel] implements that wrong port, and the two are pumped
/// through the same harness and compared. The rival test failing would mean the
/// discriminator stopped discriminating, which is reported rather than passed
/// over — the pattern `tier0_account_payload_test.dart` uses for the dirty-diff
/// and the shallow spread.
library;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lcc_mobile_app/features/account/domain/entities/citizen_preferences.dart';
import 'package:lcc_mobile_app/features/account/presentation/widgets/language_panel.dart';

import '../account_test_helper.dart';

/// **WRONG ON PURPOSE** — the dispatch-only port described in the library doc.
///
/// Identical to [LanguagePanel] except that `_select` omits the `setLocale`
/// call, so the server write happens and the app stays in the old language.
class _DispatchOnlyPanel extends StatelessWidget {
  const _DispatchOnlyPanel({required this.onSelected});

  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) => Row(
        children: <Widget>[
          for (final String code in LanguagePanel.codes)
            Expanded(
              child: TextButton(
                onPressed: () => onSelected(code),
                child: Text(LanguagePanel.labelFor(code)),
              ),
            ),
        ],
      );
}

/// The locale the pumped subtree is actually rendering in.
///
/// Read off `Localizations`, not off the `EasyLocalization` controller, because
/// that is what every `.tr()` in the page resolves against — the thing the
/// citizen sees.
String localeOf(WidgetTester tester, Finder descendantOf) =>
    Localizations.localeOf(tester.element(descendantOf)).languageCode;

void main() {
  /// `language: 'en'` so the panel starts with English active and the tap under
  /// test is a real change rather than a no-op.
  CitizenPreferences prefsInEnglish() => tPreferences(language: 'en');

  group('B8-AC-17 — the Language row changes the LOCAL locale, not just the '
      'server record', () {
    testWidgets('tapping ລາວ switches the app to Lao AND dispatches the write',
        (WidgetTester tester) async {
      final List<String> dispatched = <String>[];

      await pumpAccountWidget(
        tester,
        LanguagePanel(
          preferences: prefsInEnglish(),
          onSelected: dispatched.add,
        ),
      );

      expect(localeOf(tester, find.byType(LanguagePanel)), 'en',
          reason: 'precondition — the panel starts in English');

      await tester.tap(find.text('ລາວ'));
      await tester.pumpAndSettle();

      // The local half — `setLang(code)` at `AccountPage.tsx:621`, ported at
      // `language_panel.dart:101`.
      expect(
        localeOf(tester, find.byType(LanguagePanel)),
        'lo',
        reason: 'B8-AC-17: the row must change the locale locally. Without it '
            'the citizen taps ລາວ, the pill highlights, and every other '
            'string on the page stays English until the next launch.',
      );

      // …and the server half still fired. Both, from one tap — `:621-622`.
      expect(dispatched, <String>['lo']);
    });

    testWidgets('the DISPATCH-ONLY rival leaves the locale in English — so the '
        'assertion above is not vacuous', (WidgetTester tester) async {
      final List<String> dispatched = <String>[];

      await pumpAccountWidget(
        tester,
        _DispatchOnlyPanel(onSelected: dispatched.add),
      );

      await tester.tap(find.text('ລາວ'));
      await tester.pumpAndSettle();

      // The rival dispatches identically…
      expect(dispatched, <String>['lo'],
          reason: 'if this ever fails the rival stopped being a faithful '
              'counter-implementation and the comparison below means nothing');

      // …and that is the whole trap: a test asserting only the line above
      // passes for both implementations.
      expect(
        localeOf(tester, find.byType(_DispatchOnlyPanel)),
        'en',
        reason: 'the rival must NOT change the locale — that is what makes it '
            'a discriminator',
      );
    });

    testWidgets('local-first: the locale is ALREADY changed by the time the '
        'dispatch runs', (WidgetTester tester) async {
      // `setLang(code)` precedes `updatePrefs(...)` at `:621-622`, and
      // `language_panel.dart:101` `await`s it before `:105` calls
      // `onSelected`. So a failed or slow PUT can never strand the UI in the
      // old language — the posture R-25 ports for the top bar too.
      //
      // **Measured on the EasyLocalization controller, not on
      // `Localizations.localeOf`.** That distinction cost a red run and is
      // worth recording: `localeOf` reads the *rebuilt* `Localizations`
      // inherited widget, which lags `setLocale` by a frame, so it reports the
      // OLD locale inside a callback that genuinely ran after the change. The
      // controller is the thing `setLocale` mutates synchronously, and it is
      // what the ordering claim is actually about.
      String? localeWhenDispatched;

      await pumpAccountWidget(
        tester,
        Builder(
          builder: (BuildContext inner) => LanguagePanel(
            preferences: prefsInEnglish(),
            onSelected: (_) => localeWhenDispatched =
                EasyLocalization.of(inner)?.locale.languageCode,
          ),
        ),
      );

      await tester.tap(find.text('ລາວ'));
      await tester.pumpAndSettle();

      expect(localeWhenDispatched, 'lo',
          reason: 'if this reads "en" the two statements were swapped and the '
              'network write would gate the language change');
    });
  });

  group('B8-AC-17 — the active branch reads the SERVER record, not the locale',
      () {
    testWidgets('`prefs.language` wins over the rendered locale (`:616`)',
        (WidgetTester tester) async {
      // Rendered in English, but the server says Lao. `:616` is
      // `prefs?.language ?? lang`, so Lao is the highlighted pill. A port that
      // read the locale instead would look identical in every test where the
      // two agree — which is every test that does not do this.
      await pumpAccountWidget(
        tester,
        LanguagePanel(
          preferences: tPreferences(language: 'lo'),
          onSelected: (_) {},
        ),
      );

      expect(localeOf(tester, find.byType(LanguagePanel)), 'en');

      final Text lao = tester.widget<Text>(find.text('ລາວ'));
      final Text english = tester.widget<Text>(find.text('English'));

      expect(lao.style!.color, isNot(english.style!.color),
          reason: 'exactly one pill is active, and with prefs.language == "lo" '
              'it is the Lao one even though the app is rendering English');
    });

    testWidgets('the two labels are endonyms, identical in both locales',
        (WidgetTester tester) async {
      // `{code === "lo" ? "ລາວ" : "English"}` (`:631`) — literals, not `.tr()`
      // keys. Pumped in Lao to prove the strings do not move.
      await pumpAccountWidget(
        tester,
        LanguagePanel(preferences: prefsInEnglish(), onSelected: (_) {}),
        locale: const Locale('lo'),
      );

      expect(find.text('ລາວ'), findsOneWidget);
      expect(find.text('English'), findsOneWidget);
    });

    test('Lao is FIRST — the source order, and a Tier 1 assertion (`:615`)',
        () {
      expect(LanguagePanel.codes, <String>['lo', 'en']);
      expect(LanguagePanel.labelFor('lo'), 'ລາວ');
      expect(LanguagePanel.labelFor('en'), 'English');
      // Anything that is not "lo" renders the English endonym, matching the
      // ternary rather than a lookup that could return null for a third code.
      expect(LanguagePanel.labelFor('fr'), 'English');
    });
  });
}
