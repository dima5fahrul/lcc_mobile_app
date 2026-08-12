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
    expect(harness.store.keys, <String>[StorageKeys.lang]);
  });

  // ── DEFECT D-3 ─────────────────────────────────────────────────────────────
  //
  // `LanguageToggle` re-renders because it reads `Localizations.localeOf`,
  // i.e. it *depends* on the inherited widget that changes. Everything else in
  // the shell renders through `'key'.tr()`, which is a context-free lookup
  // against the global `Localization.instance` and creates no dependency.
  //
  // Flutter's `Localizations` loads its delegates asynchronously. The rebuild
  // triggered by the new locale runs BEFORE easy_localization's delegate has
  // swapped the global table; when the delegate finishes and `Localizations`
  // calls `setState`, its child widget is the identical instance from that
  // earlier rebuild, so the element tree is skipped entirely. Net effect: the
  // global lookup is already Lao while the rendered text is still English.
  //
  // The citizen sees the toggle chip change and nothing else — until the next
  // unrelated rebuild (any navigation) repaints the app in the new language.
  //
  // These tests pin the observed behaviour so it cannot regress unnoticed and
  // so the fix has an obvious landing site. They are expected to be rewritten
  // into positive assertions once `lib/` is corrected.
  group('DEFECT D-3 — .tr() text does not re-render on a locale switch', () {
    testWidgets('nav labels and page text stay English after flipping to Lao',
        (WidgetTester tester) async {
      final AppHarness harness = await bootHarness();
      await pumpAssembledApp(tester, harness);
      expect(find.text('Home'), findsWidgets);

      await tester.tap(find.byType(LanguageToggle));
      await tester.pumpAndSettle();

      // The global table IS Lao …
      expect(Lang.fromCode(harness.store[StorageKeys.lang]), Lang.lo);
      expect(find.text(loLabel), findsOneWidget);
      // … but nothing built from `.tr()` has re-rendered.
      expect(find.text('Home'), findsWidgets,
          reason: 'expected the Lao label ໜ້າຫຼັກ');
      expect(find.text('ໜ້າຫຼັກ'), findsNothing);
    });

    testWidgets('an unrelated rebuild — any navigation — repaints it in Lao',
        (WidgetTester tester) async {
      final AppHarness harness = await bootHarness();
      await pumpAssembledApp(tester, harness);

      await tester.tap(find.byType(LanguageToggle));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Wallet').last);
      await tester.pumpAndSettle();

      expect(find.text('ໜ້າຫຼັກ'), findsWidgets);
      expect(find.text('Home'), findsNothing);
    });
  });
}
