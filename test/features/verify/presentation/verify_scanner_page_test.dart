/// `VerifyScannerPage` — Task 5's camera half of verification.
///
/// No real camera, anywhere: [FakeMobileScannerController] overrides
/// `barcodes` with a stream this file controls, constructed with
/// `autoStart: false` so nothing here ever calls `start()`, and
/// [_NoopMobileScannerPlatform] replaces `MobileScannerPlatform.instance` for
/// the one platform call that survives `autoStart: false` regardless — see
/// that class's own doc for what was actually MEASURED hanging without it.
/// What IS real is everything downstream of a detection: the SAME
/// `certificateCodeFromScanned` gate production uses, the pop, and the
/// `GoRouter` navigation — this file drives all three through the actual
/// `VerifyScannerPage` widget, not a hand-rolled stand-in for it.
///
/// `VerifyScannerPage` is PUSHED (a plain `Navigator.push`, mirroring the
/// entry page's Scan button exactly) on top of a private two-route
/// `GoRouter` — `/verify` (the entry stub it pops back to) and
/// `/verify/:code` (a stub that renders the resolved code), so a real
/// navigation to a real destination is what each assertion measures, not
/// merely that a handler ran.
///
/// `wrapWithLocalization` is NOT imported from `test/helpers/app_test_harness
/// .dart` here, unlike `verify_result_page_test.dart` — that file's top-level
/// `import 'package:lcc_mobile_app/main.dart'` pulls in the whole app's route
/// table transitively, including `verify_file_check_page.dart`, a file Task 7
/// is concurrently editing (untracked, mid-batch) and which does not compile
/// at every intermediate commit. This file's own subject is three widgets
/// deep (`VerifyScannerPage` → `MobileScanner`/`EasyLocalization`), so it
/// copies the same two small pieces the harness defines (headless-safe
/// `EasyLocalization`, `JsonFileAssetLoader`) rather than take a compile-time
/// dependency on a route table it never navigates through.
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:lcc_mobile_app/features/verify/presentation/pages/verify_scanner_page.dart';
import 'package:lcc_mobile_app/utils/routes/app_name_routes.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

/// Reads `assets/i18n/{lang}.json` straight off disk with `dart:io`.
///
/// A byte-for-byte copy of `app_test_harness.dart`'s loader of the same name,
/// for the reason stated there: `flutter test` runs with the package root as
/// its working directory, so this is the SAME file `rootBundle` loads in the
/// shipped app, and the synchronous read is load-bearing inside
/// `testWidgets`' `FakeAsync` zone — an `await file.readAsString()` would
/// leave `EasyLocalization` pending forever and every finder would come back
/// empty while `pumpAndSettle` reported success.
class _JsonFileAssetLoader extends AssetLoader {
  const _JsonFileAssetLoader();

  static final Map<String, Map<String, dynamic>> _cache =
      <String, Map<String, dynamic>>{};

  @override
  Future<Map<String, dynamic>?> load(String path, Locale locale) async {
    final String key = '$path/${locale.languageCode}';
    return _cache.putIfAbsent(
      key,
      () => json.decode(File('$key.json').readAsStringSync())
          as Map<String, dynamic>,
    );
  }
}

/// Wraps [child] in a headless-safe `EasyLocalization` — `saveLocale: false`
/// keeps `SharedPreferences`, a platform channel with no responder here, out
/// of the boot entirely.
Widget _wrapWithLocalization(Widget child) {
  return EasyLocalization(
    supportedLocales: const <Locale>[Locale('en'), Locale('lo')],
    path: 'assets/i18n',
    assetLoader: const _JsonFileAssetLoader(),
    fallbackLocale: const Locale('lo'),
    startLocale: const Locale('en'),
    saveLocale: false,
    child: child,
  );
}

/// Stub rendered at `/verify` — the entry page's stand-in, so the scanner has
/// something underneath it in the SAME `Navigator` to pop back to.
const String kEntryStub = 'ENTRY-STUB';

/// Replaces `MobileScannerPlatform.instance` for the one platform call
/// `autoStart: false` does NOT prevent.
///
/// `_MobileScannerState._initializeController()` runs, unconditionally in
/// `kDebugMode` (true under `flutter test`): `if (MobileScannerPlatform
/// .instance case final MethodChannelMobileScanner implementation) { try {
/// await implementation.stop(force: true); } on Exception catch (_) {} }` —
/// a hot-restart guard, nothing to do with `autoStart`. **Measured, not
/// inferred**: left as the real `MethodChannelMobileScanner`, that call
/// reaches an actual `MethodChannel.invokeMethod` with no native platform on
/// the other end, and inside a `testWidgets` `FakeAsync` zone with no timer
/// this file ever advances, the awaited Future never resolves and the test
/// hangs — not throws, HANGS — until the outer test runner's own timeout
/// kills it. A debug run confirmed this directly, including that the broad
/// `on Exception catch` it is written to be caught by never gets a chance to
/// run, because the Future it would catch from never completes at all.
///
/// Substituting a platform instance that is simply not a
/// `MethodChannelMobileScanner` makes that pattern match fail, so the branch
/// — and its platform call — never runs. `dispose()` is the only method this
/// file's path reaches afterwards (via [FakeMobileScannerController]
/// disposing through to `MobileScannerController.dispose()`, since this
/// controller's `_platformSessionOwner` is always null — `start()` is never
/// called), so it is the only override needed; every other member keeps the
/// base class's `throw UnimplementedError(...)`, which is fine because
/// nothing here calls them.
class _NoopMobileScannerPlatform extends MobileScannerPlatform {
  @override
  Future<void> dispose() async {}
}

/// A controller the test can feed a detection through.
///
/// `MobileScannerController.barcodes` reads a PRIVATE `StreamController`
/// (`_barcodesController`, `mobile_scanner_controller.dart`); there is no
/// production API that pushes a value into it from outside, because nothing
/// outside the plugin's own platform channel is meant to. Overriding the
/// getter is what lets this file simulate "the camera detected something"
/// without the camera.
///
/// `autoStart: false` keeps `value.isInitialized` at its construction
/// default, so `MobileScanner.build()` takes the placeholder branch and
/// `start()` — which WOULD reach `MobileScannerPlatform.instance.start(...)`
/// — is never called. It is necessary but not sufficient on its own; see
/// [_NoopMobileScannerPlatform] for the one platform call it does not
/// prevent.
class FakeMobileScannerController extends MobileScannerController {
  FakeMobileScannerController() : super(autoStart: false);

  final StreamController<BarcodeCapture> _fakeBarcodes =
      StreamController<BarcodeCapture>.broadcast();

  @override
  Stream<BarcodeCapture> get barcodes => _fakeBarcodes.stream;

  /// Simulates one camera frame's detection, exactly as the real
  /// `onDetect` wiring would deliver it.
  void emit(BarcodeCapture capture) => _fakeBarcodes.add(capture);

  @override
  Future<void> dispose() async {
    await _fakeBarcodes.close();
    await super.dispose();
  }
}

/// Pumps a `/verify` entry stub, then PUSHES [VerifyScannerPage] on top of it
/// — the same shape the entry page's Scan button produces in production.
Future<FakeMobileScannerController> pumpScanner(WidgetTester tester) async {
  final FakeMobileScannerController controller = FakeMobileScannerController();
  addTearDown(controller.dispose);

  await tester.pumpWidget(
    _wrapWithLocalization(
      Builder(
        builder: (BuildContext context) => MaterialApp.router(
          localizationsDelegates: context.localizationDelegates,
          supportedLocales: context.supportedLocales,
          locale: context.locale,
          routerConfig: GoRouter(
            initialLocation: AppNameRoutes.verify,
            routes: <RouteBase>[
              GoRoute(
                path: AppNameRoutes.verify,
                builder: (_, __) => const Scaffold(body: Text(kEntryStub)),
              ),
              GoRoute(
                path: AppNameRoutes.verifyResult,
                builder: (_, GoRouterState state) => Scaffold(
                  body: Text('RESULT:${state.pathParameters['code']}'),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();

  final BuildContext entryContext = tester.element(find.text(kEntryStub));
  unawaited(
    Navigator.of(entryContext).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => VerifyScannerPage(controller: controller),
      ),
    ),
  );
  await tester.pumpAndSettle();

  return controller;
}

void main() {
  late final MobileScannerPlatform realPlatform;

  setUpAll(() {
    realPlatform = MobileScannerPlatform.instance;
  });

  setUp(() {
    MobileScannerPlatform.instance = _NoopMobileScannerPlatform();
  });

  tearDown(() {
    // Restored rather than left swapped: this file's own process may run
    // other test files' suites in the same VM, and a stale fake platform
    // left in place would make a LATER file's genuine plugin assumptions
    // (if any existed) silently false.
    MobileScannerPlatform.instance = realPlatform;
  });

  testWidgets(
    'a /v/<code> URL barcode navigates to the result route, popping the '
    'scanner so the entry stub is gone, not merely covered',
    (WidgetTester tester) async {
      final FakeMobileScannerController controller =
          await pumpScanner(tester);

      controller.emit(
        const BarcodeCapture(
          barcodes: <Barcode>[
            Barcode(rawValue: 'https://portal.gov.la/v/RES-7Q4K-19XD'),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.text('RESULT:RES-7Q4K-19XD'),
        findsOneWidget,
        reason: 'the code extracted from the /v/ path reached the result '
            'route the router actually resolved',
      );
      expect(find.text(kEntryStub), findsNothing,
          reason: 'go_router replaced the base stack with the result route');
      expect(find.byType(VerifyScannerPage), findsNothing,
          reason: 'the scanner popped itself — Back from here lands on the '
              'entry page\'s go_router location, not back on the camera');
    },
  );

  testWidgets(
    'a wa.me phone-path barcode shows the banner and sends nothing — rule 3',
    (WidgetTester tester) async {
      final FakeMobileScannerController controller =
          await pumpScanner(tester);

      controller.emit(
        const BarcodeCapture(
          barcodes: <Barcode>[
            Barcode(rawValue: 'https://wa.me/8562055512345'),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.text('This QR code is not a certificate code'),
        findsOneWidget,
        reason: 'verify.notCertificateQr — the guide names wa.me/<phone> as '
            'exactly the non-certificate case rule 3 covers',
      );
      expect(find.byType(VerifyScannerPage), findsOneWidget,
          reason: '"keep scanning" — an invalid read does not pop the '
              'scanner');
      expect(find.textContaining('RESULT:'), findsNothing,
          reason: 'no navigation happened, so nothing reached the result '
              'route');
    },
  );

  testWidgets(
    'a decodable barcode with a null rawValue (fix round 1) shows the '
    'banner too — silence is not an acceptable answer to rule 3',
    (WidgetTester tester) async {
      final FakeMobileScannerController controller =
          await pumpScanner(tester);

      // A binary-payload QR, or any other barcode the platform decoded as a
      // symbol but could not render as text — `rawValue` is `null`, not an
      // empty string. Before fix round 1, `_handleDetect` returned here
      // with no `setState` at all: the camera kept scanning, which is
      // correct, but the citizen got no feedback for the frame, which is
      // not — rule 3 says "show 'This QR code is not a certificate code'",
      // not "say nothing when there is nothing to parse".
      controller.emit(
        const BarcodeCapture(barcodes: <Barcode>[Barcode(rawValue: null)]),
      );
      await tester.pumpAndSettle();

      expect(
        find.text('This QR code is not a certificate code'),
        findsOneWidget,
        reason: 'a null rawValue is rule 3\'s "anything else" exactly as '
            'much as a wa.me URL is',
      );
      expect(find.byType(VerifyScannerPage), findsOneWidget,
          reason: 'keep scanning');
      expect(find.textContaining('RESULT:'), findsNothing,
          reason: 'nothing was sent anywhere — there was nothing to send');
    },
  );

  testWidgets(
    'a bare code with no scheme also navigates — rule 2, not only rule 1',
    (WidgetTester tester) async {
      final FakeMobileScannerController controller =
          await pumpScanner(tester);

      controller.emit(
        const BarcodeCapture(
          barcodes: <Barcode>[Barcode(rawValue: 'RES-7Q4K-19XD')],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('RESULT:RES-7Q4K-19XD'), findsOneWidget);
    },
  );

  testWidgets(
    'the handled latch — a second detection arriving before the first '
    'transition settles is ignored, not navigated a second time',
    (WidgetTester tester) async {
      final FakeMobileScannerController controller =
          await pumpScanner(tester);

      controller.emit(
        const BarcodeCapture(
          barcodes: <Barcode>[Barcode(rawValue: 'RES-7Q4K-19XD')],
        ),
      );
      // A second, DIFFERENT code, delivered before pumpAndSettle lets the
      // first transition finish — the shape of two rapid repeat frames the
      // brief's latch requirement names.
      controller.emit(
        const BarcodeCapture(
          barcodes: <Barcode>[Barcode(rawValue: 'RES-0000-0000')],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('RESULT:RES-7Q4K-19XD'), findsOneWidget,
          reason: 'the first detection navigated');
      expect(find.text('RESULT:RES-0000-0000'), findsNothing,
          reason: 'the latch ignored the second — exactly one navigation '
              'per scanner visit');
    },
  );

  // ── Review M-1, 2026-10-22 — the parser's answer reaches the route whole ──

  testWidgets(
    'a code containing a path delimiter survives the hand-off — the router '
    'gets the code the parser returned, not a prefix of it',
    (WidgetTester tester) async {
      final FakeMobileScannerController controller =
          await pumpScanner(tester);

      // Rule 1 returns the `/v/` segment percent-DECODED, so this QR yields
      // the code `RES?a=b`. Interpolated raw into `/verify/<code>` the router
      // read it as the path `/verify/RES` plus a query, and the app verified
      // `RES` — a code nobody scanned, silently.
      controller.emit(
        const BarcodeCapture(
          barcodes: <Barcode>[
            Barcode(rawValue: 'https://portal.gov.la/v/RES%3Fa%3Db'),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('RESULT:RES?a=b'), findsOneWidget,
          reason: '`state.pathParameters` decodes what `Uri.encodeComponent` '
              'wrote, so the round trip is lossless');
      expect(find.text('RESULT:RES'), findsNothing,
          reason: 'the truncation is the defect');
    },
  );
}
