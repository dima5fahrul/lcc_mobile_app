/// **AC-7, second half** — the EN ⇄ ລາວ toggle.
///
/// AC-7 asks for three things: the toggle flips EN↔LO, the visible label
/// changes, and the choice persists across a remount. All three are asserted
/// below against the assembled app with a real `EasyLocalization` (see
/// `app_test_harness.dart` for how the headless stall is avoided).
///
/// The last group records **defect D-3**, found by these tests: everything
/// rendered through `'key'.tr()` — the bottom-nav labels, the top-bar brand,
/// the page bodies — keeps the *previous* language until some unrelated
/// rebuild happens. Reported, not patched: the fix is in `lib/`, which this
/// dispatch does not own.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lcc_mobile_app/core/storage/storage_keys.dart';
import 'package:lcc_mobile_app/i18n/i18n.dart';
import 'package:lcc_mobile_app/presentation/shell/language_toggle.dart';

import '../../helpers/app_test_harness.dart';

void main() {
  tearDown(resetHarness);

  /// The label the toggle shows for the *current* language — its endonym,
  /// deliberately not an i18n key (a mistranslation must not be able to hide
  /// the option from the people who need it).
  const String enLabel = 'EN';
  const String loLabel = 'ລາວ';

  testWidgets('shows EN when the app is in English', (WidgetTester tester) async {
    final AppHarness harness = await bootHarness();
    await pumpAssembledApp(tester, harness);

    expect(find.byType(LanguageToggle), findsOneWidget);
    expect(find.text(enLabel), findsOneWidget);
    expect(find.text(loLabel), findsNothing);
  });

  testWidgets('shows ລາວ when the app is in Lao', (WidgetTester tester) async {
    final AppHarness harness = await bootHarness();
    await pumpAssembledApp(tester, harness, startLocale: const Locale('lo'));

    expect(find.text(loLabel), findsOneWidget);
    expect(find.text(enLabel), findsNothing);
  });

  testWidgets('tapping it flips EN → LO: the label changes and lcc.lang is '
      'written', (WidgetTester tester) async {
    final AppHarness harness = await bootHarness();
    await pumpAssembledApp(tester, harness);

    await tester.tap(find.byType(LanguageToggle));
    await tester.pumpAndSettle();

    expect(find.text(loLabel), findsOneWidget);
    expect(find.text(enLabel), findsNothing);
    expect(harness.store[StorageKeys.lang], 'lo');
  });

  testWidgets('tapping it again flips LO → EN', (WidgetTester tester) async {
    final AppHarness harness = await bootHarness();
    await pumpAssembledApp(tester, harness, startLocale: const Locale('lo'));

    await tester.tap(find.byType(LanguageToggle));
    await tester.pumpAndSettle();

    expect(find.text(enLabel), findsOneWidget);
    expect(harness.store[StorageKeys.lang], 'en');
  });

  testWidgets('the choice survives a remount, read back the way main.dart '
      'reads it', (WidgetTester tester) async {
    final AppHarness harness = await bootHarness();
    await pumpAssembledApp(tester, harness);

    await tester.tap(find.byType(LanguageToggle));
    await tester.pumpAndSettle();
    expect(harness.store[StorageKeys.lang], 'lo');

    // Tear the tree down and boot again from persisted state — the same
    // `Lang.fromCode(await storage.getLang()).toLocale()` line `main.dart`
    // runs. `saveLocale` is off, so easy_localization contributes nothing
    // here: if `lcc.lang` were not honoured, this would come back English.
    await tester.pumpWidget(const SizedBox.shrink());
    final Locale restored =
        Lang.fromCode(await harness.storage.getLang()).toLocale();
    await pumpAssembledApp(tester, harness, startLocale: restored);

    expect(restored, const Locale('lo'));
    expect(find.text(loLabel), findsOneWidget);
    // …and the rest of the chrome is Lao too, because this is a fresh mount.
    expect(find.text('ໜ້າຫຼັກ'), findsWidgets);
  });

  testWidgets('writes lcc.lang, not easy_localization s own store',
      (WidgetTester tester) async {
    final AppHarness harness = await bootHarness();
    await pumpAssembledApp(tester, harness);

    await tester.tap(find.byType(LanguageToggle));
    await tester.pumpAndSettle();

    // One writer, one key (GOR-245 § 4.2 freezes `lcc.lang`). If
    // `saveLocale` were ever switched back on, the SharedPreferences copy and
    // this one could disagree after an upgrade.
    //
    // **B10 narrowed this from "the store holds exactly one key" to "the
    // language is written under exactly one key".** The original form asserted
    // the whole store, which made it a gate on every *other* key any batch
    // might add: B10 adds `lcc.onboarding_seen` and `lcc.tutorial_seen`
    // (§ 6.11), and the harness now seeds them the way `e2e/smoke.mjs`:91-96
    // seeds their `localStorage` twins. Neither has anything to do with
    // language, and neither can desynchronise `lcc.lang`. The property this
    // test is named for — one writer, one key — is asserted directly instead.
    expect(
      harness.store.keys.where((String k) => k.contains('lang')),
      <String>[StorageKeys.lang],
      reason: 'exactly one language key, and it is `lcc.lang`',
    );
    expect(
      harness.store.keys.any((String k) => k.contains('locale')),
      isFalse,
      reason: 'easy_localization writes `locale` when `saveLocale` is on. It '
          'is off, and this is what would notice it being switched back.',
    );
  });

  // ── DEFECT D-3 — CLOSED for these strings by B10 ───────────────────────────
  //
  // This group used to pin the **defect**: it asserted that flipping to Lao
  // left the nav labels in English, and that only a later navigation repainted
  // them. Its own comment said what to do next — *"They are expected to be
  // rewritten into positive assertions once `lib/` is corrected."* B10 § 6.7 is
  // that correction, so they are rewritten here rather than deleted, because a
  // reader coming from the old comment needs to find out what happened.
  //
  // **The cause was not what this file's original note said.** That note (and
  // `ssd.md`:775-778) blamed `const` subtrees over `.tr()`. Measured in B10
  // § 6.6.3: a `const` widget calling `.tr(context: context)` refreshes, a
  // NON-const one calling bare `.tr()` goes stale, and commit `d22cd98` had
  // already removed the `const` from both sites the theory blames while the
  // defect survived. The real mechanism is that `.tr()` without `context:`
  // reads `Localization.instance`, a global, and registers no
  // `InheritedWidget` dependency (`public.dart`:39-44). The rest of that note
  // — the async delegate load, the identical `child` instance,
  // `framework.dart`:4014 — was right.
  //
  // **D-3 is closed for the nine strings B10 measured and OPEN, guarded and
  // enumerated, for the ~300 that remain** (`B10-AC-59`, GG-2). G-L8 plus
  // `test/architecture/tr_allowlist.yaml` is the containment. The full
  // capability suite lives in `d3_language_repaint_test.dart`; the two below
  // are the ones this file already owned.
  group('D-3 — .tr() text DOES now re-render on a locale switch', () {
    testWidgets('nav labels repaint to Lao immediately, with no navigation',
        (WidgetTester tester) async {
      final AppHarness harness = await bootHarness();
      await pumpAssembledApp(tester, harness);
      expect(find.text('Home'), findsWidgets);

      await tester.tap(find.byType(LanguageToggle));
      await tester.pumpAndSettle();

      expect(Lang.fromCode(harness.store[StorageKeys.lang]), Lang.lo);
      expect(find.text(loLabel), findsOneWidget);

      expect(find.text('ໜ້າຫຼັກ'), findsWidgets,
          reason: 'D-3 is fixed: `app_bottom_nav.dart` now passes `context:`');
      expect(find.text('Home'), findsNothing,
          reason: 'and the English label is gone, not merely joined');
    });

    testWidgets('and a navigation afterwards keeps it Lao — the old '
        '"repaints on the next rebuild" path is now a no-op',
        (WidgetTester tester) async {
      // Retained deliberately. The pre-B10 behaviour was "stale until you
      // navigate", so a fix that somehow only worked *on* navigation would
      // pass the test above only if the toggle itself triggered one — and
      // `d3_language_repaint_test.dart`'s `B10-AC-19` proves it does not.
      // This asserts the other side: navigating does not undo the repaint.
      final AppHarness harness = await bootHarness();
      await pumpAssembledApp(tester, harness);

      await tester.tap(find.byType(LanguageToggle));
      await tester.pumpAndSettle();

      await tester.tap(find.text('ກະເປົາເງິນ').last);
      await tester.pumpAndSettle();

      expect(find.text('ໜ້າຫຼັກ'), findsWidgets);
      expect(find.text('Home'), findsNothing);
    });
  });
}
