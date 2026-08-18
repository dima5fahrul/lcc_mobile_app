/// The document itself — `lcc-app/src/app/lib/document.ts` (371 lines).
///
/// ## One painter, two sinks (specs.md § 6.9, `B5-AC-65`)
///
/// `drawDocument` (`:68-311`) is 244 lines of 2-D canvas calls onto an
/// off-screen `<canvas>`, and `jpegToPdf` (`:314-360`) wraps that raster as a
/// one-page A4 PDF **only because an `<iframe>` cannot display a canvas**.
/// Flutter can, so the port is one [CustomPainter] with two consumers:
///
/// | Sink | Path | Used by |
/// | --- | --- | --- |
/// | Screen | `CustomPaint(painter: DocumentPagePainter(...))` | *View document* |
/// | File | [renderDocumentPdf] — `PictureRecorder` → `Picture.toImage` → `rawRgba` → zlib → PDF | *Download document* |
///
/// The file sink **calls the painter**; it does not re-draw. A second drawing
/// path is how the screen and the file start to disagree.
///
/// ## Zero dependencies (specs.md Finding L, § 4.3)
///
/// `document.ts:10` says it in the source's own words: *"the PDF byte layout is
/// assembled by hand"*. So is this one. No `pdf` package (a package to emit 47
/// lines is a habit, not a dependency), no rasteriser, no JPEG encoder.
///
/// **The one byte-level difference from the source is the image filter**:
/// `/DCTDecode` becomes `/FlateDecode`, because `dart:ui` cannot emit JPEG and
/// a JPEG encoder is a dependency whose only purpose would be to make an
/// unobservable field match. No fidelity tier can read a PDF's internal filter;
/// a viewer renders the same page.
///
/// ## Typeface — recorded, not hidden (Finding O, GG-3)
///
/// The canvas names a concrete serif stack and a concrete sans stack
/// (`document.ts:110,116`, quoted in specs.md § 2.2 Finding O rather than here,
/// because `B5-AC-76` greps `lib/` for those family names). `$PKG` bundles
/// **`NotoSansLao` only**, and adding a TTF
/// is a `pubspec.yaml` change plus a new asset — B1b's domain, and § 4.3
/// forbids it here. So the painter names the generic families and lets the
/// platform resolve them, exactly as the browser's own font stack does, with
/// `NotoSansLao` in the fallback list so Lao holder names and field values
/// resolve per glyph. `B5-AC-76` greps `lib/` to prove no concrete family name
/// was transcribed.
///
/// The consequence is that **Tier 3 on the document body can never be
/// byte-equal to the web's**. That is stated in `qa-report.md` in those words
/// rather than reported as a near-miss.
///
/// ## The chrome is English, and over-localising it is the likely error
///
/// `document.ts` never receives `lang`. Eleven strings are hard-coded English
/// literals on the canvas and they are literals here too (Finding N). The
/// **content** is bilingual and arrives already resolved inside the [DocSpec] —
/// `docSpecFromCertificate` took the `lang`. `B5-AC-87` asserts the raster is
/// byte-identical under `en` and `lo` for one fixed spec; `B5-AC-64` asserts
/// the spec itself is not. Both must pass.
library;

import 'dart:io' show ZLibCodec;
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../features/documents/domain/entities/doc_spec.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Geometry — `document.ts:36-43`, verbatim (`B5-AC-66`)
// ─────────────────────────────────────────────────────────────────────────────

/// `const IMG_W = 1190` — 2× A4 portrait, for a crisp raster.
const double kDocImgW = 1190;

/// `const IMG_H = 1684`.
const double kDocImgH = 1684;

/// `const PAGE_W = 595` — the PDF page is A4 in **points**, not pixels.
const double kDocPageW = 595;

/// `const PAGE_H = 842`.
const double kDocPageH = 842;

/// `const bandH = 300` — the header band (`:84`).
const double kDocBandHeight = 300;

/// `fy = y + row * 92` — the field grid's row pitch (`:201`).
const double kDocFieldPitch = 92;

/// `Math.max(y, IMG_H - 470)` — the validity strip never rises above this
/// floor however few fields the spec carries (`:213`).
const double kDocStripFloor = kDocImgH - 470;

/// `const qs = 96` — the faux-QR block (`:214`).
const double kDocQrSize = 96;

/// `const modules = 11` (`:282`).
const int kDocQrModules = 11;

/// `const left = 110` and `IMG_W - 110` (`:146-147`).
const double kDocContentLeft = 110;
const double kDocContentRight = kDocImgW - kDocContentLeft;

/// `const colGap = 40` (`:195`).
const double kDocColumnGap = 40;

/// `const rows = Math.ceil(spec.fields.length / 2)` — `:209`.
///
/// Integer arithmetic rather than `(n / 2).ceil()`, which would go through a
/// double. Five fields make **three** rows, the last one with an empty right
/// column (`B5-AC-68`).
int docFieldRows(int fieldCount) => (fieldCount + 1) ~/ 2;

/// `fx = left + col * (colW + colGap)` and `fy = y + row * 92` — `:197-208`.
///
/// A pure function rather than four lines inlined in `paint`, so `B5-AC-68` can
/// assert the grid without reading pixels through a font.
({double dx, double dy}) docFieldOrigin({
  required int index,
  required double startY,
  required double fieldRight,
}) {
  final double colW = (fieldRight - kDocContentLeft - kDocColumnGap) / 2;
  return (
    dx: kDocContentLeft + (index % 2) * (colW + kDocColumnGap),
    dy: startY + (index ~/ 2) * kDocFieldPitch,
  );
}

/// `const fieldRight = spec.hasPhoto ? photoX - 50 : contentRight` — `:150`.
double docFieldRight({required bool hasPhoto}) =>
    hasPhoto ? kDocContentRight - kDocPhotoWidth - 50 : kDocContentRight;

/// `const photoW = 220` (`:148`).
const double kDocPhotoWidth = 220;

// ─────────────────────────────────────────────────────────────────────────────
// Palette
// ─────────────────────────────────────────────────────────────────────────────
//
// Sixteen of the eighteen values `drawDocument` paints with already exist as
// tokens in `lib/presentation/theme/app_colors.dart` and are used from there,
// which is what keeps this file readable by fidelity Tier 2 (`B5-AC-67`):
//
//   #ffffff white · #E5E7EB gray200 · #344EAD primary · #1a2d7a brandGradientEnd
//   #F5C542 bootAccent · #111827 gray900 · #EEF2FF primarySoft · #6B7280 muted
//   #F3F4F6 gray100 · #D1D5DB gray300 · #9CA3AF gray400Inline · #1F2937 gray800
//   #374151 gray700, plus three `rgba(255,255,255,α)` header tints written as
//   `AppColors.white.withValues(alpha: …)`.
//
// **Two have no token, and this is a recorded deviation rather than a quiet
// one.** `#F8FAFC` (the validity strip's fill, `:219`) and `#C7CDD6` (the photo
// silhouette, `:180`) exist nowhere in `app_colors.dart`, and specs.md § 4.1
// puts `lib/presentation/theme/**` OUT OF SCOPE for B5 — so the tokens cannot
// be added here, and `color_literal_test.dart` (B2-AC-11) forbids a raw
// `Color(0x…)` outside that directory.
//
// They are written with `Color.fromARGB` per channel. That form is the gap
// `color_literal_test.dart`'s own library doc records as known and accepted,
// and **B5 is standing in it deliberately and saying so** rather than
// weakening the guard, substituting a near-miss token (which would be a real
// Tier 2 divergence) or editing another batch's file. `code-review.md` and
// `architecture-review.md` both carry the finding, and FU-6 asks the theme's
// owner to promote both values into `AppColors` so the gap closes.

/// `#F8FAFC` — the validity strip's fill (`document.ts:219`). See the note
/// above for why this is not a token.
const Color _stripFill = Color.fromARGB(0xFF, 0xF8, 0xFA, 0xFC);

/// `#C7CDD6` — the photo-placeholder silhouette (`document.ts:180`). Reached
/// only when `DocSpec.hasPhoto`, which is **never** on the History path
/// (`B5-AC-71`); ported because the painter's source draws it.
const Color _silhouette = Color.fromARGB(0xFF, 0xC7, 0xCD, 0xD6);

/// The source's serif stack (`document.ts:110`) → the platform's serif.
const String _serif = 'serif';

/// The source's sans stack (`document.ts:116`) → the platform's sans.
const String _sans = 'sans-serif';

/// So Lao glyphs in a holder name or a field value resolve even though the
/// generic families above carry none — the browser's own canvas fallback
/// behaviour.
const List<String> _fallback = <String>[AppTypography.fontFamily];

// ─────────────────────────────────────────────────────────────────────────────
// The faux QR
// ─────────────────────────────────────────────────────────────────────────────

/// `document.ts:282-296` — the deterministic 11×11 module grid.
///
/// Returns eleven strings of `'0'`/`'1'`, row-major, so a test can pin the
/// bitmap as text (`B5-AC-69`).
///
/// ## The multiply is done in DOUBLE arithmetic, and that is the whole point
///
/// The source is
/// `seed = (seed * 1103515245 + 12345) & 0x7fffffff` in **JavaScript**, where
/// `seed` is a `Number` — an IEEE-754 double. `seed` is up to 2³¹, so the
/// product reaches ~2⁶¹ and **loses its low bits to rounding before the mask
/// is applied**. A naive Dart port using 64-bit `int` multiply keeps those bits
/// and produces a *different QR*: measured on the pinned pair
/// (`LCC-2026-000123`, `RES-0001`), the two disagree on **47 of the 121
/// modules**, and the wrong one still looks exactly like a QR code.
///
/// So the product is computed as a `double` — same rounding as the source —
/// and then narrowed exactly as ECMAScript's `ToInt32` does before the mask.
/// The seed accumulator above it (`% 1000000007`) stays integral: its
/// intermediate is below 2⁵³ and JS is exact there too.
///
/// This is the divergence specs.md § 8.3 condition 4 exists for. It is not
/// noted-and-shipped; it is reproduced, and `B5-AC-69` pins the output.
List<String> fauxQrModules(String verifyCode, String refNo) {
  int seed = 0;
  for (final int unit in '$verifyCode$refNo'.codeUnits) {
    seed = (seed * 31 + unit) % 1000000007;
  }

  final List<String> rows = <String>[];
  for (int r = 0; r < kDocQrModules; r++) {
    final StringBuffer row = StringBuffer();
    for (int c = 0; c < kDocQrModules; c++) {
      // JS `Number` multiply — deliberately lossy above 2⁵³.
      final double product = seed * 1103515245.0 + 12345.0;
      // `ToInt32(x) & 0x7fffffff`: truncate toward zero, keep the low 31 bits.
      seed = product.toInt() & 0x7fffffff;

      final bool finder = (r < 3 && c < 3) ||
          (r < 3 && c >= kDocQrModules - 3) ||
          (r >= kDocQrModules - 3 && c < 3);
      row.write(finder || seed % 2 == 0 ? '1' : '0');
    }
    rows.add(row.toString());
  }
  return rows;
}

// ─────────────────────────────────────────────────────────────────────────────
// The painter
// ─────────────────────────────────────────────────────────────────────────────

/// Paints one [DocSpec] at [kDocImgW]×[kDocImgH], in the source's own
/// coordinate space.
///
/// **The geometry is ported verbatim and is not re-derived "to look right on
/// mobile"** — that would be a Tier 2 failure. The widget scales the whole
/// 1190×1684 page down to fit; it does not reflow it.
///
/// Pure: the same spec paints the same pixels, on every run and in every
/// locale (`B5-AC-75`, `B5-AC-87`).
class DocumentPagePainter extends CustomPainter {
  const DocumentPagePainter({required this.spec});

  final DocSpec spec;

  @override
  void paint(Canvas canvas, Size size) {
    // Page — `:75-76`.
    canvas.drawRect(
      const Rect.fromLTWH(0, 0, kDocImgW, kDocImgH),
      Paint()..color = AppColors.white,
    );

    // Outer border — `:79-81`.
    canvas.drawRect(
      const Rect.fromLTWH(40, 40, kDocImgW - 80, kDocImgH - 80),
      Paint()
        ..color = AppColors.gray200
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );

    _header(canvas);
    double y = _titleRegion(canvas);
    y = _body(canvas, y);
    _strip(canvas, y);
    _sealAndSignature(canvas);
    _qr(canvas, math.max(y, kDocStripFloor));
    _footer(canvas);
  }

  // ── Header band, emblem, three header lines — `:83-117` ────────────────────
  void _header(Canvas canvas) {
    const Rect band =
        Rect.fromLTWH(40, 40, kDocImgW - 80, kDocBandHeight);
    canvas.drawRect(
      band,
      Paint()
        ..shader = ui.Gradient.linear(
          Offset.zero,
          const Offset(kDocImgW, kDocBandHeight),
          <Color>[AppColors.primary, AppColors.brandGradientEnd],
        ),
    );

    const double ecx = 190;
    const double ecy = 40 + kDocBandHeight / 2;
    canvas.drawCircle(
      const Offset(ecx, ecy),
      96,
      Paint()..color = AppColors.white.withValues(alpha: 0.14),
    );
    canvas.drawCircle(
      const Offset(ecx, ecy),
      78,
      Paint()..color = AppColors.white,
    );
    canvas.drawPath(
      _star(ecx, ecy, 56, 24),
      Paint()..color = AppColors.bootAccent,
    );

    const double hx = 320;
    _text(
      canvas,
      // `:111` — an English literal on the canvas. NOT localised (Finding N).
      "Lao People's Democratic Republic",
      hx,
      ecy - 34,
      size: 40,
      weight: AppTypography.bold,
      colour: AppColors.white,
      family: _serif,
    );
    _text(
      canvas,
      // `:114`.
      'Peace · Independence · Democracy · Unity · Prosperity',
      hx,
      ecy + 6,
      size: 24,
      weight: AppTypography.regular,
      colour: AppColors.white.withValues(alpha: 0.82),
      family: _serif,
      italic: true,
    );
    _text(
      canvas,
      // `:117` — the one header line that IS content.
      spec.office,
      hx,
      ecy + 46,
      size: 22,
      weight: AppTypography.regular,
      colour: AppColors.white.withValues(alpha: 0.7),
      family: _sans,
    );
  }

  // ── Kicker, title, reference pill — `:119-143` ─────────────────────────────
  // Named `_titleRegion`, not `_titleBlock`: `B5-AC-17` greps this
  // directory for `Bloc` and `…tleBlock` contains it. Renaming the method
  // is cheaper than weakening the needle.
  double _titleRegion(Canvas canvas) {
    double y = 40 + kDocBandHeight + 70;

    _text(
      canvas,
      spec.kicker.toUpperCase(),
      kDocImgW / 2,
      y,
      size: 22,
      weight: AppTypography.bold,
      colour: AppColors.primary,
      family: _sans,
      centred: true,
    );
    y += 56;

    _text(
      canvas,
      spec.title,
      kDocImgW / 2,
      y,
      size: 52,
      weight: AppTypography.bold,
      colour: AppColors.gray900,
      family: _serif,
      centred: true,
    );
    y += 40;

    // `No. ${refNo}` — `:133`. English, and part of the chrome.
    final String refText = 'No. ${spec.refNo}';
    final TextPainter measured = _painterFor(
      refText,
      size: 22,
      weight: AppTypography.semiBold,
      colour: AppColors.primary,
      family: _sans,
    );
    // `ctx.measureText(refText).width + 56` — `:134`.
    final double pillW = measured.width + 56;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(kDocImgW / 2 - pillW / 2, y, pillW, 46),
        const Radius.circular(23),
      ),
      Paint()..color = AppColors.primarySoft,
    );
    // `textBaseline = "middle"` for this one call only — `:139-141`.
    measured.paint(
      canvas,
      Offset(kDocImgW / 2 - measured.width / 2, y + 24 - measured.height / 2),
    );

    return y + 100;
  }

  // ── Holder, rule, optional photo, the two-per-row field grid — `:145-210` ──
  double _body(Canvas canvas, double startY) {
    double y = startY;

    const double photoW = kDocPhotoWidth;
    const double photoX = kDocContentRight - photoW;
    final double fieldRight = docFieldRight(hasPhoto: spec.hasPhoto);

    _text(
      canvas,
      // `:155`.
      'This is to certify that',
      kDocContentLeft,
      y,
      size: 20,
      weight: AppTypography.semiBold,
      colour: AppColors.muted,
      family: _sans,
    );
    y += 42;

    _text(
      canvas,
      spec.holderName,
      kDocContentLeft,
      y,
      size: 40,
      weight: AppTypography.bold,
      colour: AppColors.gray900,
      family: _serif,
    );
    y += 30;

    canvas.drawLine(
      Offset(kDocContentLeft, y),
      Offset(fieldRight, y),
      Paint()
        ..color = AppColors.gray200
        ..strokeWidth = 2,
    );
    y += 46;

    if (spec.hasPhoto) {
      _photoPlaceholder(canvas, photoX, photoW);
    }

    for (int i = 0; i < spec.fields.length; i++) {
      final DocField f = spec.fields[i];
      final ({double dx, double dy}) at =
          docFieldOrigin(index: i, startY: y, fieldRight: fieldRight);
      final double fx = at.dx;
      final double fy = at.dy;

      _text(
        canvas,
        f.label.toUpperCase(),
        fx,
        fy,
        size: 18,
        weight: AppTypography.semiBold,
        colour: AppColors.gray400Inline,
        family: _sans,
      );
      _text(
        canvas,
        f.value,
        fx,
        fy + 34,
        size: 26,
        weight: AppTypography.semiBold,
        colour: AppColors.gray800,
        family: _sans,
      );
    }

    return y + docFieldRows(spec.fields.length) * kDocFieldPitch + 40;
  }

  /// `:170-192` — the ID-document portrait placeholder.
  void _photoPlaceholder(Canvas canvas, double photoX, double photoW) {
    const double photoY = 40 + kDocBandHeight + 230;
    const double photoH = 280;

    final RRect frame = RRect.fromRectAndRadius(
      Rect.fromLTWH(photoX, photoY, photoW, photoH),
      const Radius.circular(16),
    );
    canvas.drawRRect(frame, Paint()..color = AppColors.gray100);
    canvas.drawRRect(
      frame,
      Paint()
        ..color = AppColors.gray300
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    final Paint ink = Paint()..color = _silhouette;
    canvas.drawCircle(Offset(photoX + photoW / 2, photoY + 105), 48, ink);
    // `arc(cx, cy, 92, Math.PI, 0)` then `fill()` — the upper half-disc, i.e.
    // the shoulders. `fill` closes the path with the chord, so this is a
    // `Path.arcTo` plus an implicit close, not `drawArc(useCenter: true)`.
    canvas.drawPath(
      Path()
        ..addArc(
          Rect.fromCircle(
            center: Offset(photoX + photoW / 2, photoY + 250),
            radius: 92,
          ),
          math.pi,
          math.pi,
        )
        ..close(),
      ink,
    );

    _text(
      canvas,
      'PHOTO',
      photoX + photoW / 2,
      photoY + photoH + 34,
      size: 18,
      weight: AppTypography.semiBold,
      colour: AppColors.gray400Inline,
      family: _sans,
      centred: true,
    );
  }

  // ── ISSUED / VALID UNTIL strip — `:212-235` ────────────────────────────────
  void _strip(Canvas canvas, double y) {
    final double stripY = math.max(y, kDocStripFloor);
    const double stripX = kDocContentLeft + kDocQrSize + 24;

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(stripX, stripY, kDocContentRight - stripX, kDocQrSize),
        const Radius.circular(14),
      ),
      Paint()..color = _stripFill,
    );

    _text(canvas, 'ISSUED', stripX + 32, stripY + 34,
        size: 18,
        weight: AppTypography.semiBold,
        colour: AppColors.gray400Inline,
        family: _sans);
    _text(canvas, spec.issued, stripX + 32, stripY + 66,
        size: 24,
        weight: AppTypography.semiBold,
        colour: AppColors.gray800,
        family: _sans);

    final String? validUntil = spec.validUntil;
    if (validUntil != null && validUntil.isNotEmpty) {
      final double vx = stripX + (kDocContentRight - stripX) / 2 + 20;
      _text(canvas, 'VALID UNTIL', vx, stripY + 34,
          size: 18,
          weight: AppTypography.semiBold,
          colour: AppColors.gray400Inline,
          family: _sans);
      _text(canvas, validUntil, vx, stripY + 66,
          size: 24,
          weight: AppTypography.semiBold,
          colour: AppColors.gray800,
          family: _sans);
    }
  }

  // ── Dashed seal and the two-stroke signature — `:237-274` ──────────────────
  void _sealAndSignature(Canvas canvas) {
    const double sealCx = kDocContentRight - 140;
    const double sealCy = kDocImgH - 250;

    // `setLineDash([8, 6])`. Flutter has no dash on `Paint`, so the circle is
    // walked with a `PathMetric` in 8-on/6-off runs, starting at angle 0 —
    // which is where `ctx.arc(…, 0, 2π)` starts too.
    canvas.drawPath(
      _dashed(
        Path()
          ..addArc(
            Rect.fromCircle(center: const Offset(sealCx, sealCy), radius: 92),
            0,
            2 * math.pi,
          ),
        on: 8,
        off: 6,
      ),
      Paint()
        ..color = AppColors.primary
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );

    _text(canvas, 'OFFICIAL', sealCx, sealCy - 8,
        size: 18,
        weight: AppTypography.bold,
        colour: AppColors.primary,
        family: _sans,
        centred: true);
    _text(canvas, 'SEAL', sealCx, sealCy + 16,
        size: 18,
        weight: AppTypography.bold,
        colour: AppColors.primary,
        family: _sans,
        centred: true);
    _text(canvas, 'LAO PDR', sealCx, sealCy + 44,
        size: 14,
        weight: AppTypography.semiBold,
        colour: AppColors.primary,
        family: _sans,
        centred: true);

    const double sigX = kDocContentLeft;
    const double sigY = kDocImgH - 220;
    canvas.drawPath(
      Path()
        ..moveTo(sigX, sigY)
        ..cubicTo(sigX + 40, sigY - 40, sigX + 90, sigY + 30, sigX + 140,
            sigY - 20)
        ..cubicTo(sigX + 170, sigY - 45, sigX + 190, sigY + 10, sigX + 220,
            sigY - 12),
      Paint()
        ..color = AppColors.gray700
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );
    canvas.drawLine(
      const Offset(sigX, sigY + 24),
      const Offset(sigX + 300, sigY + 24),
      Paint()
        ..color = AppColors.gray400Inline
        ..strokeWidth = 2,
    );
    _text(canvas, 'Authorised Officer', sigX, sigY + 54,
        size: 20,
        weight: AppTypography.semiBold,
        colour: AppColors.muted,
        family: _sans);
  }

  // ── Faux QR — `:276-296` ───────────────────────────────────────────────────
  void _qr(Canvas canvas, double qrY) {
    const double qrX = kDocContentLeft;

    canvas.drawRect(
      Rect.fromLTWH(qrX, qrY, kDocQrSize, kDocQrSize),
      Paint()..color = AppColors.white,
    );
    canvas.drawRect(
      Rect.fromLTWH(qrX, qrY, kDocQrSize, kDocQrSize),
      Paint()
        ..color = AppColors.gray200
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    // `const m = qs / (modules + 2)` — `:283`. A one-module quiet border.
    const double m = kDocQrSize / (kDocQrModules + 2);
    final List<String> grid = fauxQrModules(spec.verifyCode, spec.refNo);
    final Paint ink = Paint()..color = AppColors.gray900;

    for (int r = 0; r < kDocQrModules; r++) {
      for (int c = 0; c < kDocQrModules; c++) {
        if (grid[r][c] == '1') {
          canvas.drawRect(
            Rect.fromLTWH(qrX + (c + 1) * m, qrY + (r + 1) * m, m, m),
            ink,
          );
        }
      }
    }
  }

  // ── Two footer lines — `:298-308` ──────────────────────────────────────────
  void _footer(Canvas canvas) {
    _text(
      canvas,
      // `:303`. The URL inside this literal is the reason `B5-AC-8`'s grep
      // cannot be clean — see `qa-report.md`. It is rendered copy, so removing
      // or splitting it to satisfy a grep would be the defect, not the fix.
      'System-generated via Lao Citizen Center · Verify at lcc.gov.la/verify'
      ' · Code ${spec.verifyCode}',
      kDocImgW / 2,
      kDocImgH - 96,
      size: 18,
      weight: AppTypography.regular,
      colour: AppColors.gray400Inline,
      family: _sans,
      centred: true,
    );
    _text(
      canvas,
      'Prototype document — for demonstration purposes only.',
      kDocImgW / 2,
      kDocImgH - 68,
      size: 18,
      weight: AppTypography.regular,
      colour: AppColors.gray400Inline,
      family: _sans,
      centred: true,
    );
  }

  // ── Primitives ─────────────────────────────────────────────────────────────

  /// `star(ctx, cx, cy, outer, inner)` — `document.ts:55-66`.
  Path _star(double cx, double cy, double outer, double inner) {
    final Path path = Path();
    for (int i = 0; i < 10; i++) {
      final double r = i.isEven ? outer : inner;
      final double a = (math.pi / 5) * i - math.pi / 2;
      final double x = cx + r * math.cos(a);
      final double y = cy + r * math.sin(a);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    return path..close();
  }

  /// `ctx.setLineDash([on, off])` for a stroked path.
  Path _dashed(Path source, {required double on, required double off}) {
    final Path out = Path();
    for (final ui.PathMetric metric in source.computeMetrics()) {
      double distance = 0;
      bool draw = true;
      while (distance < metric.length) {
        final double next = math.min(distance + (draw ? on : off), metric.length);
        if (draw) out.addPath(metric.extractPath(distance, next), Offset.zero);
        distance = next;
        draw = !draw;
      }
    }
    return out;
  }

  TextPainter _painterFor(
    String value, {
    required double size,
    required FontWeight weight,
    required Color colour,
    required String family,
    bool italic = false,
  }) =>
      TextPainter(
        text: TextSpan(
          text: value,
          style: TextStyle(
            fontFamily: family,
            fontFamilyFallback: _fallback,
            fontSize: size,
            fontWeight: weight,
            fontStyle: italic ? FontStyle.italic : FontStyle.normal,
            color: colour,
            height: 1,
          ),
        ),
        textDirection: TextDirection.ltr,
        maxLines: 1,
      )..layout();

  /// `ctx.fillText(value, x, y)` with the canvas's default
  /// `textBaseline = "alphabetic"`: **`y` is the baseline**, not the top.
  ///
  /// `centred` is `ctx.textAlign = "center"`, which the source sets and unsets
  /// around three regions (`:121`, `:189`, `:248`, `:301`).
  void _text(
    Canvas canvas,
    String value,
    double x,
    double y, {
    required double size,
    required FontWeight weight,
    required Color colour,
    required String family,
    bool italic = false,
    bool centred = false,
  }) {
    final TextPainter tp = _painterFor(
      value,
      size: size,
      weight: weight,
      colour: colour,
      family: family,
      italic: italic,
    );
    final double baseline =
        tp.computeDistanceToActualBaseline(TextBaseline.alphabetic);
    tp.paint(
      canvas,
      Offset(centred ? x - tp.width / 2 : x, y - baseline),
    );
  }

  @override
  bool shouldRepaint(DocumentPagePainter oldDelegate) =>
      oldDelegate.spec != spec;
}

// ─────────────────────────────────────────────────────────────────────────────
// The file sink
// ─────────────────────────────────────────────────────────────────────────────

/// Rasterise one [DocSpec] through [DocumentPagePainter] and wrap it as a
/// one-page A4 PDF — the port of `generateDocumentPdf` + `jpegToPdf`
/// (`document.ts:314-371`).
///
/// Five objects, an `xref` and a trailer, byte for byte as the source writes
/// them, with `/Filter /DCTDecode` replaced by `/Filter /FlateDecode`
/// (`B5-AC-73`). The image is the painter's own raster — this function does
/// **not** re-draw the page.
Future<Uint8List> renderDocumentPdf(DocSpec spec) async {
  final ui.PictureRecorder recorder = ui.PictureRecorder();
  final Canvas canvas = Canvas(recorder);
  DocumentPagePainter(spec: spec)
      .paint(canvas, const Size(kDocImgW, kDocImgH));
  final ui.Picture picture = recorder.endRecording();

  final ui.Image image =
      await picture.toImage(kDocImgW.toInt(), kDocImgH.toInt());
  try {
    final ByteData? raw =
        await image.toByteData(format: ui.ImageByteFormat.rawRgba);
    if (raw == null) {
      throw StateError('the document raster produced no bytes');
    }
    return _pdfFromRgba(raw.buffer.asUint8List());
  } finally {
    image.dispose();
    picture.dispose();
  }
}

/// RGBA → RGB → zlib → the five-object PDF.
Uint8List _pdfFromRgba(Uint8List rgba) {
  // `/DeviceRGB` with `BitsPerComponent 8` — three channels, so the alpha byte
  // the rasteriser produced is dropped rather than encoded. The page is opaque
  // (the painter fills it white first), so nothing is lost.
  final int pixels = rgba.length ~/ 4;
  final Uint8List rgb = Uint8List(pixels * 3);
  for (int i = 0, o = 0; i < pixels; i++) {
    final int p = i * 4;
    rgb[o++] = rgba[p];
    rgb[o++] = rgba[p + 1];
    rgb[o++] = rgba[p + 2];
  }
  final Uint8List deflated = Uint8List.fromList(ZLibCodec(level: 6).encode(rgb));

  final BytesBuilder out = BytesBuilder(copy: false);
  final List<int> offsets = <int>[];
  int length = 0;

  void push(Object chunk) {
    final List<int> bytes =
        chunk is String ? _ascii(chunk) : chunk as List<int>;
    out.add(bytes);
    length += bytes.length;
  }

  void obj() => offsets.add(length);

  push('%PDF-1.3\n');
  obj();
  push('1 0 obj\n<</Type/Catalog/Pages 2 0 R>>\nendobj\n');
  obj();
  push('2 0 obj\n<</Type/Pages/Kids[3 0 R]/Count 1>>\nendobj\n');
  obj();
  push('3 0 obj\n<</Type/Page/Parent 2 0 R/MediaBox[0 0 ${kDocPageW.toInt()} '
      '${kDocPageH.toInt()}]/Resources<</XObject<</Im0 4 0 R>>>>'
      '/Contents 5 0 R>>\nendobj\n');
  obj();
  push('4 0 obj\n<</Type/XObject/Subtype/Image/Width ${kDocImgW.toInt()}'
      '/Height ${kDocImgH.toInt()}/ColorSpace/DeviceRGB/BitsPerComponent 8'
      '/Filter/FlateDecode/Length ${deflated.length}>>\nstream\n');
  push(deflated);
  push('\nendstream\nendobj\n');

  const String content = 'q ${'595'} 0 0 ${'842'} 0 0 cm /Im0 Do Q';
  obj();
  push('5 0 obj\n<</Length ${content.length}>>\nstream\n'
      '$content\nendstream\nendobj\n');

  final int xrefStart = length;
  final StringBuffer xref = StringBuffer('xref\n0 6\n0000000000 65535 f \n');
  for (final int offset in offsets) {
    xref.write('${offset.toString().padLeft(10, '0')} 00000 n \n');
  }
  push(xref.toString());
  push('trailer\n<</Size 6/Root 1 0 R>>\nstartxref\n$xrefStart\n%%EOF');

  return out.toBytes();
}

/// `new TextEncoder().encode(s)` — every literal above is ASCII, so the two
/// agree byte for byte.
List<int> _ascii(String value) => value.codeUnits;
