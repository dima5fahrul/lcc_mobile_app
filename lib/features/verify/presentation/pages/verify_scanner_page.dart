/// `VerifyScannerPage` — the camera half of verification (§ QR codes and deep
/// links), Task 5.
///
/// Mounted from the entry page's Scan button via a plain
/// `Navigator.push(MaterialPageRoute(...))` — a coordinator ruling, not an
/// oversight: Task 7 owns the route table this round, and a scanner that is
/// entered only from one button needs no deep-link entry point of its own, so
/// no `GoRoute` is added for it.
///
/// Every detected barcode's `rawValue` runs through the SAME
/// `certificateCodeFromScanned` gate the typed entry page (Task 4) uses,
/// before anything leaves this widget — that gate, not a host allow-list or a
/// format check written twice, is rules 1-3 of § QR codes and deep links:
///
/// * a recognised code → this page pops itself (so the page beneath it is the
///   entry page, never a second scanner), and `context.go('/verify/<code>')`
///   is called **from the entry page's own location** — i.e. after the pop,
///   not before it. `GoRouter.go` replaces the matched-route stack (every
///   navigation in this app does — `app_back_policy.dart`'s own library doc),
///   but the app's `AppBackPolicy`/`BackVisitStack` (GOR-269) records the
///   `/verify` → `/verify/<code>` step as an ordinary forward visit and hands
///   it straight back on the next Back press, with no route-table parent
///   relationship required. That is what makes "Back returns to the entry
///   page" true here without a second `push()` anywhere in this file — this
///   app's navigation law (`back_policy_guard_test.dart`'s
///   `GOR-269-AC-17`) is `.go()` only, and the visit stack is the mechanism
///   that makes `.go()` sufficient for a flow that *feels* like a push.
/// * anything else (rule 3) → an in-page banner reads
///   `verify.notCertificateQr`, the camera keeps running (no `pop`, no
///   `stop()`, nothing re-subscribed), and — the entire point of the gate —
///   NOTHING is sent anywhere. No bloc, no repository, no `ApiClient` is
///   reachable from this file; a scanned Wi-Fi password or phone number never
///   has anywhere to go.
///
/// A `_handled` latch guards the one navigation: `MobileScannerController`'s
/// own `detectionTimeoutMs` already debounces repeat reads of the identical
/// code, but nothing stops a second, slightly different detection event from
/// arriving before the first `pop` + `go` has finished, and a second
/// navigation mid-transition is the failure this latch exists to prevent.
library;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../../presentation/icons/lucide_icon.dart';
import '../../../../presentation/theme/app_colors.dart';
import '../../../../presentation/theme/app_spacing.dart';
import '../../../../presentation/theme/app_typography.dart';
import '../../../../utils/routes/app_name_routes.dart';
import '../../domain/code_extraction.dart';

class VerifyScannerPage extends StatefulWidget {
  const VerifyScannerPage({super.key, this.controller});

  /// Injectable for tests only. Production callers always omit this and get a
  /// real, autostarting [MobileScannerController] that this page owns and
  /// disposes.
  ///
  /// `verify_scanner_page_test.dart` passes a `FakeMobileScannerController`
  /// that overrides `barcodes` with a stream the test can feed, with
  /// `autoStart: false` so nothing here ever reaches a camera platform
  /// channel in a widget test.
  final MobileScannerController? controller;

  @override
  State<VerifyScannerPage> createState() => _VerifyScannerPageState();
}

class _VerifyScannerPageState extends State<VerifyScannerPage> {
  late final MobileScannerController _controller;

  /// True only when this page created [_controller] itself — a controller the
  /// caller supplied is the caller's to dispose, exactly as `VerifyResultPage`
  /// never closes a bloc it did not create.
  late final bool _ownsController;

  /// Set the moment a recognised code starts the pop-then-go — guards against
  /// a second detection event (a different frame of the same code, or a
  /// second barcode in frame) firing a second navigation while the first is
  /// still in flight.
  bool _handled = false;

  /// True while the last detection failed rule 3 — renders the banner. There
  /// is no timer clearing it: the NEXT detection event (recognised or not)
  /// is this banner's only exit, which keeps "keep scanning" literal rather
  /// than racing a `Timer` against the camera's own detection cadence.
  bool _showInvalid = false;

  @override
  void initState() {
    super.initState();
    _ownsController = widget.controller == null;
    _controller = widget.controller ?? MobileScannerController();
  }

  @override
  void dispose() {
    if (_ownsController) {
      // Fire-and-forget, exactly as `MobileScanner`'s own `_disposeController`
      // treats this call: the widget is already leaving the tree, and
      // `dispose()` returning a Future nobody can await here is the method's
      // own contract, not a corner this file cuts.
      _controller.dispose();
    }
    super.dispose();
  }

  void _handleDetect(BarcodeCapture capture) {
    if (_handled) return;

    final List<Barcode> barcodes = capture.barcodes;
    final String? raw = barcodes.isEmpty ? null : barcodes.first.rawValue;
    if (raw == null) {
      // A decodable barcode with no text — e.g. a binary-payload QR — or a
      // capture the platform reported with no barcode at all is rule 3's
      // "anything else" exactly as much as a wa.me URL is: not a
      // certificate code, and the citizen gets the SAME banner rather than
      // silence. (Fix round 1 — this branch used to return with no
      // feedback, "keep scanning" without ever saying why there was
      // nothing to navigate to.)
      if (!_showInvalid) setState(() => _showInvalid = true);
      return;
    }

    // The SAME gate `VerifyCodeEntryPage._submit` runs typed text through —
    // rules 1-3 of § QR codes and deep links. Rule 3's `null` means send
    // nothing: this function returns before any bloc, repository or
    // `ApiClient` is anywhere in reach.
    final String? code = certificateCodeFromScanned(raw);
    if (code == null) {
      if (!_showInvalid) setState(() => _showInvalid = true);
      return; // Keep scanning — the camera subscription is untouched.
    }

    _handled = true;
    // The router is resolved BEFORE the pop, not after: `Navigator.pop`
    // starts removing this page from the tree, and reaching for `context`'s
    // ancestors a statement later is the kind of thing that only works by
    // the grace of pop's removal being deferred to the next frame. Resolving
    // first makes the ordering not matter.
    final GoRouter router = GoRouter.of(context);
    Navigator.of(context).pop(); // Leave the scanner — back lands on entry.
    router.go('${AppNameRoutes.verify}/$code');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.black,
      appBar: AppBar(
        backgroundColor: AppColors.black,
        foregroundColor: AppColors.white,
        elevation: 0,
        title: Text('verify.entry.scan'.tr(context: context)),
      ),
      body: Stack(
        children: <Widget>[
          Positioned.fill(
            child: MobileScanner(
              controller: _controller,
              onDetect: _handleDetect,
            ),
          ),
          if (_showInvalid)
            Positioned(
              left: AppSpacing.gap16,
              right: AppSpacing.gap16,
              bottom: AppSpacing.gap32,
              child: Material(
                color: AppColors.gray900,
                borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.gap12),
                  child: Row(
                    children: <Widget>[
                      const LucideIcon(
                        name: 'AlertTriangle',
                        color: AppColors.white,
                      ),
                      SizedBox(width: AppSpacing.gap8),
                      Expanded(
                        child: Text(
                          'verify.notCertificateQr'.tr(context: context),
                          style: TextStyle(
                            fontFamily: AppTypography.fontFamily,
                            fontFamilyFallback:
                                AppTypography.fontFamilyFallback,
                            fontSize: AppTypography.size14,
                            color: AppColors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
