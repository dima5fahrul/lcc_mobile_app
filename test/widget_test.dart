/// **AC-3** — the suite's skipped count must reach 0.
///
/// This file was `skip: true`. A permanently-skipped test is a hidden
/// NOT EVALUATED, so GOR-245 § 7.1 requires it to be un-skipped or replaced by
/// a real test. It is now a real test.
///
/// The skip reason was that `EasyLocalization` never settles headless: its
/// default `RootBundleAssetLoader` and `saveLocale: true` both reach for
/// platform channels, and `pumpAndSettle` runs inside a `FakeAsync` zone that
/// never lets the real event loop answer them. `test/helpers/app_test_harness.dart`
/// removes both — a synchronous `dart:io` loader over the very same
/// `assets/i18n/*.json`, and `saveLocale: false`, which is what `main.dart`
/// already sets because `StorageService` owns `lcc.lang`.
///
/// Scope kept deliberately narrow: this is the boot smoke test — the app
/// mounts, the localised shell renders, nothing throws. The behavioural
/// coverage lives where it belongs, in `test/app/app_flow_test.dart` (AC-6) and
/// `test/presentation/shell/` (AC-7).
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lcc_mobile_app/features/home/presentation/pages/home_page.dart';
import 'package:lcc_mobile_app/core/session/bloc/session_bloc.dart';
import 'package:lcc_mobile_app/presentation/shell/app_shell.dart';

import 'helpers/app_test_harness.dart';

void main() {
  tearDown(resetHarness);

  testWidgets('the assembled app mounts and renders the localised shell',
      (WidgetTester tester) async {
    final AppHarness harness = await bootHarness();

    await pumpAssembledApp(tester, harness);

    // One MaterialApp.router, one shell Scaffold, the home tab inside it.
    expect(find.byType(MaterialApp), findsOneWidget);
    expect(find.byType(AppShell), findsOneWidget);
    expect(find.byType(HomePage), findsOneWidget);
    expect(find.byType(NavigationBar), findsOneWidget);

    // The boot event dispatched by `App.initState` actually ran.
    expect(harness.sessionBloc.state.status, SessionStatus.unauthenticated);

    // Localisation is live: real strings from assets/i18n/en.json, not raw
    // keys. `layout.brand` reaching the screen as "layout.brand" would mean
    // the table never loaded.
    expect(find.text('LAO CITIZEN CENTER'), findsOneWidget);
    expect(find.text('layout.brand'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('it mounts in Lao just as well', (WidgetTester tester) async {
    final AppHarness harness = await bootHarness();

    await pumpAssembledApp(tester, harness, startLocale: const Locale('lo'));

    expect(find.byType(AppShell), findsOneWidget);
    expect(find.text('ໜ້າຫຼັກ'), findsWidgets);
    expect(
      Localizations.localeOf(tester.element(find.byType(AppShell))),
      const Locale('lo'),
    );
    expect(tester.takeException(), isNull);
  });
}
