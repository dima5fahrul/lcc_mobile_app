/// The payment QR — **a constant 20×20 bitmap that encodes nothing**.
///
/// `PaymentSection.tsx:130-161`. Ported as the decorative constant it is
/// (specs.md § 6.10, `B6-DIV-3`), transcribed cell for cell.
///
/// ## What the source actually does, stated plainly
///
/// `QRCode()` takes **no arguments**. It builds a hardcoded 20×20 array of
/// 0/1, pushes every 1 into a `cells` list, and draws each as a 1×1 `<rect>`
/// over a white 20×20 background. It is drawn beneath the copy
/// *"Secured by Lao National Payment System"* (`payment.qrSecured`), above a
/// real fee amount, and — when a live payment carries one — above
/// `instruction.qr_payload`, **which it does not encode**. `:391` renders the
/// panel on `instruction.qr_payload || chosen?.kind === "qr"`, so a QR-kind
/// method with no payload at all still shows this bitmap and nothing else.
///
/// ## What is explicitly forbidden here (§ 6.10)
///
/// * adding `qr_flutter` or any encoder — also a `pubspec.yaml` edit, which
///   § 4.1 forbids outright;
/// * deriving the pattern from `instruction.qr_payload`;
/// * hiding the QR when there is no payload;
/// * adding a warning label.
///
/// Each is a silent improvement over the source. A port that is *better* than
/// the web is a divergence no fidelity tier can see, which is worse than a
/// faithful defect that is written down. It is written down: security-review
/// item 4 and **FU-6**, which escalate the product question — a non-functional
/// QR under a national-payment-system claim over a real fee is a decision
/// nobody has taken, only inherited.
///
/// ## Rendering
///
/// `shapeRendering="crispEdges"` disables anti-aliasing in SVG; the Flutter
/// equivalent is a [Paint] with `isAntiAlias: false` over integer-aligned
/// rects, which is what [_QrPainter] does. Cells are painted in
/// [AppColors.qrCellInk] (`#1a1a1a`, lower-case in the source), never
/// [AppColors.black] — the source is one step off pure black and a Tier 2
/// comparison is an equality, not a tolerance.
library;

import 'package:flutter/widgets.dart';

import '../theme/app_colors.dart';

/// The 20 rows of `PaymentSection.tsx:132-151`, transcribed verbatim.
///
/// Kept as a top-level constant rather than a field so a test can assert its
/// shape (20×20) and its cell count without building a widget — a bitmap that
/// silently lost a row would still render, just wrongly.
const List<List<int>> kQrPattern = <List<int>>[
  <int>[1, 1, 1, 1, 1, 1, 1, 0, 1, 0, 0, 1, 0, 1, 1, 1, 1, 1, 1, 1],
  <int>[1, 0, 0, 0, 0, 0, 1, 0, 0, 1, 1, 0, 0, 1, 0, 0, 0, 0, 0, 1],
  <int>[1, 0, 1, 1, 1, 0, 1, 0, 1, 0, 1, 1, 0, 1, 0, 1, 1, 1, 0, 1],
  <int>[1, 0, 1, 1, 1, 0, 1, 0, 0, 1, 0, 1, 0, 1, 0, 1, 1, 1, 0, 1],
  <int>[1, 0, 1, 1, 1, 0, 1, 0, 1, 1, 1, 0, 1, 1, 0, 1, 1, 1, 0, 1],
  <int>[1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 1, 1, 0, 1, 0, 0, 0, 0, 0, 1],
  <int>[1, 1, 1, 1, 1, 1, 1, 0, 1, 0, 1, 0, 1, 1, 1, 1, 1, 1, 1, 1],
  <int>[0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0],
  <int>[1, 0, 1, 1, 0, 1, 1, 0, 0, 1, 1, 0, 1, 1, 0, 1, 1, 0, 1, 0],
  <int>[0, 1, 0, 1, 1, 0, 0, 1, 1, 0, 1, 1, 0, 1, 1, 0, 0, 1, 1, 1],
  <int>[1, 1, 0, 0, 1, 0, 1, 0, 1, 1, 0, 0, 1, 0, 1, 1, 0, 0, 1, 0],
  <int>[0, 0, 1, 0, 0, 1, 0, 1, 0, 1, 1, 0, 0, 1, 0, 0, 1, 0, 0, 1],
  <int>[1, 0, 1, 1, 1, 0, 1, 0, 1, 0, 0, 1, 1, 0, 1, 0, 1, 1, 1, 0],
  <int>[0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 0, 1, 0, 1, 0, 0, 0, 0, 0, 1],
  <int>[1, 1, 1, 1, 1, 1, 1, 0, 0, 0, 1, 0, 1, 1, 1, 1, 1, 1, 1, 1],
  <int>[1, 0, 0, 0, 0, 0, 1, 0, 1, 1, 0, 1, 0, 1, 0, 0, 0, 0, 0, 1],
  <int>[1, 0, 1, 1, 1, 0, 1, 0, 0, 1, 1, 0, 1, 1, 0, 1, 1, 1, 0, 1],
  <int>[1, 0, 1, 1, 1, 0, 1, 1, 1, 0, 1, 1, 0, 0, 0, 1, 1, 1, 0, 0],
  <int>[1, 0, 0, 0, 0, 0, 1, 0, 0, 1, 0, 0, 1, 1, 0, 0, 0, 0, 0, 1],
  <int>[1, 1, 1, 1, 1, 1, 1, 0, 1, 0, 1, 1, 0, 1, 1, 1, 1, 1, 1, 1],
];

/// The decorative QR. **Takes no payload parameter, because the source's does
/// not** (`B6-AC-48`).
class QrPlaceholder extends StatelessWidget {
  const QrPlaceholder({super.key, this.size});

  /// The side length. `null` fills the parent, matching `className="w-full
  /// h-full"` on the `` <svg> `` element (`:154`).
  final double? size;

  @override
  Widget build(BuildContext context) {
    final Widget painted = CustomPaint(
      painter: const _QrPainter(),
      // Excluded from the semantics tree: the source's `<svg>` carries no
      // `role`, no `aria-label` and no `<title>`, so a screen reader reads
      // nothing here. Announcing "QR code" would be inventing an affordance the
      // bitmap does not have.
      child: const SizedBox.expand(),
    );

    if (size == null) return ExcludeSemantics(child: painted);
    return ExcludeSemantics(
      child: SizedBox(width: size, height: size, child: painted),
    );
  }
}

class _QrPainter extends CustomPainter {
  const _QrPainter();

  @override
  void paint(Canvas canvas, Size size) {
    // `<rect width="20" height="20" fill="white" />` — `:156`.
    final Paint background = Paint()
      ..color = AppColors.white
      ..isAntiAlias = false;
    canvas.drawRect(Offset.zero & size, background);

    final Paint ink = Paint()
      ..color = AppColors.qrCellInk
      ..isAntiAlias = false;

    // `viewBox="0 0 20 20"` scaled to the box. Cell edges are computed from the
    // *scaled* grid rather than from a rounded cell width so 20 cells always
    // tile the full box exactly — a per-cell rounding would leave a hairline
    // seam at some widths, which `crispEdges` never does.
    final double cw = size.width / 20.0;
    final double ch = size.height / 20.0;

    for (int y = 0; y < kQrPattern.length; y++) {
      final List<int> row = kQrPattern[y];
      for (int x = 0; x < row.length; x++) {
        if (row[x] == 0) continue;
        canvas.drawRect(
          Rect.fromLTRB(x * cw, y * ch, (x + 1) * cw, (y + 1) * ch),
          ink,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _QrPainter oldDelegate) => false;
}
