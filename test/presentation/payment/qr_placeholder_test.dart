/// `QrPlaceholder` — the 20×20 constant bitmap (`PaymentSection.tsx:130-161`,
/// specs.md § 6.10, `B6-DIV-3`).
///
/// ## What is actually being defended here
///
/// This widget's whole correctness claim is *"it is a faithful transcription of
/// a decorative constant, and it stays one."* Both halves need a test, and they
/// need different kinds of test:
///
/// 1. **The transcription** — [kQrPattern] is 20 rows of 20 cells, values in
///    `{0,1}`, matching the source array. A bitmap that silently lost a row
///    would still render, just wrongly, so shape is asserted on the constant
///    rather than inferred from a screenshot.
/// 2. **The non-improvement** — the four things § 6.10 forbids (an encoder, a
///    payload parameter, hiding on empty payload, a warning label) are all
///    *absences*, and an absence is exactly what rots when a later reader
///    "fixes" the widget. `B6-AC-48` names the payload parameter specifically.
///
/// A port that is better than the web is a divergence no fidelity tier can see.
/// These tests are what make that divergence loud instead of silent.
library;

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lcc_mobile_app/presentation/payment/qr_placeholder.dart';
import 'package:lcc_mobile_app/presentation/theme/app_colors.dart';

void main() {
  group('B6-DIV-3 — the bitmap is a transcribed constant', () {
    test('20 rows of 20 cells', () {
      expect(kQrPattern, hasLength(20), reason: '`PaymentSection.tsx:132-151`');
      for (int y = 0; y < kQrPattern.length; y++) {
        expect(
          kQrPattern[y],
          hasLength(20),
          reason: 'row $y is not 20 cells wide; the `viewBox` is `0 0 20 20`',
        );
      }
    });

    test('every cell is 0 or 1', () {
      for (int y = 0; y < kQrPattern.length; y++) {
        for (int x = 0; x < kQrPattern[y].length; x++) {
          expect(
            kQrPattern[y][x],
            anyOf(0, 1),
            reason:
                'cell ($x,$y) is ${kQrPattern[y][x]}; the source pushes '
                'only truthy 1s into `cells`',
          );
        }
      }
    });

    test('the pattern is not blank, and not solid', () {
      // A transcription that silently became all-zero or all-one would still
      // satisfy the shape assertions above and render a plain white or plain
      // dark square. Both are wrong, and both look plausible in a screenshot.
      final int ink = kQrPattern
          .expand((List<int> r) => r)
          .where((int c) => c == 1)
          .length;
      expect(ink, greaterThan(0), reason: 'the bitmap has no ink at all');
      expect(ink, lessThan(400), reason: 'the bitmap is solid ink');
    });

    // A 7×7 finder ring, expressed as a predicate over an arbitrary grid rather
    // than as bare `expect`s against [kQrPattern]. Two reasons:
    //
    //  * the same predicate can be pointed at a deliberately-corrupted local
    //    fixture, which is how the test below proves it is *able* to fail — an
    //    assertion that has never been red is not evidence;
    //  * it cannot be satisfied by mutating `lib/`, which is shared with two
    //    other batches running concurrently.
    bool isFinderAt(List<List<int>> g, int ox, int oy) {
      if (oy + 7 > g.length || ox + 7 > g[oy].length) return false;
      for (int i = 0; i < 7; i++) {
        if (g[oy][ox + i] != 1) return false; // top edge
        if (g[oy + 6][ox + i] != 1) return false; // bottom edge
        if (g[oy + i][ox] != 1) return false; // left edge
        if (g[oy + i][ox + 6] != 1) return false; // right edge
      }
      return g[oy + 1][ox + 1] == 0 && g[oy + 5][ox + 5] == 0;
    }

    test('the two complete finder squares are present', () {
      // The structural feature a careless re-transcription loses first. Only
      // the top two corners carry a *complete* ring — see the test below for
      // the third, which the source truncates.
      expect(
        isFinderAt(kQrPattern, 0, 0),
        isTrue,
        reason: 'top-left finder, `PaymentSection.tsx:132-138`',
      );
      expect(
        isFinderAt(kQrPattern, 13, 0),
        isTrue,
        reason: 'top-right finder, `PaymentSection.tsx:132-138` cols 13-19',
      );
    });

    test('the finder predicate can fail — corrupted fixture is rejected', () {
      // The Capability Rule: the assertion above is only evidence if it is
      // capable of being red. Proven against a local copy, never by mutating
      // `lib/` — `qr_placeholder.dart` is shared with the batches building
      // alongside this one.
      final List<List<int>> corrupted = kQrPattern
          .map((List<int> r) => List<int>.of(r))
          .toList();
      corrupted[3][0] = 0; // punch a hole in the top-left finder's left edge
      expect(
        isFinderAt(corrupted, 0, 0),
        isFalse,
        reason: 'a broken ring must be detected, or the check above is vacuous',
      );
    });

    test('the bottom-left finder is TRUNCATED — the source is not a real QR', () {
      // Measured, not assumed. The bottom band of dark cells in column 0 starts
      // at row 14, and the grid is only 20 rows tall, so rows 14-19 give it
      // **six** rows where a finder needs seven. `isFinderAt` is therefore
      // false at every candidate origin down the left edge.
      //
      // This is not a transcription defect — the Dart array is byte-identical
      // to `PaymentSection.tsx:132-151`, verified cell for cell. It is a
      // property of the *source*: the decorative bitmap has two finders and a
      // clipped third, which is one more reason it can never be scanned. It is
      // therefore direct evidence for `B6-DIV-3`, and porting it faithfully
      // (rather than "correcting" the corner into a real finder) is the whole
      // point of § 6.10.
      expect(
        kQrPattern[13][0],
        0,
        reason: 'row 13 col 0 is clear; the band starts at row 14',
      );
      expect(
        <int>[for (int y = 14; y < 20; y++) kQrPattern[y][0]],
        everyElement(1),
        reason: 'rows 14-19 of column 0 are the truncated 6-row band',
      );
      for (int oy = 12; oy + 7 <= 20; oy++) {
        expect(
          isFinderAt(kQrPattern, 0, oy),
          isFalse,
          reason: 'no complete bottom-left finder can exist at origin 0,$oy',
        );
      }
    });
  });

  group('B6-AC-48 / § 6.10 — the forbidden improvements are absent', () {
    test('the constructor takes no payload parameter', () {
      // The source's `QRCode()` takes no arguments. If someone adds a
      // `payload:` here, this file stops compiling — which is the point: the
      // divergence is enforced at the type level, not by a comment.
      const QrPlaceholder unsized = QrPlaceholder();
      const QrPlaceholder sized = QrPlaceholder(size: 160);
      expect(unsized.size, isNull);
      expect(sized.size, 160);
    });

    testWidgets('it renders with no payload and never hides itself', (
      WidgetTester tester,
    ) async {
      // `:391` renders the panel on `instruction.qr_payload || chosen?.kind ===
      // "qr"`, so a QR-kind method with **no payload at all** still shows this
      // bitmap. Hiding it when there is nothing to encode would be the honest
      // thing to do and is explicitly forbidden as a silent improvement.
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: Center(child: QrPlaceholder(size: 160))),
        ),
      );
      await tester.pump();

      expect(find.byType(QrPlaceholder), findsOneWidget);
      expect(find.byType(CustomPaint), findsWidgets);
      expect(tester.takeException(), isNull);
    });

    testWidgets('it carries no semantics — no invented affordance', (
      WidgetTester tester,
    ) async {
      // The source's `<svg>` has no `role`, no `aria-label`, no `<title>`, so a
      // screen reader reads nothing. Announcing "QR code" would tell a blind
      // user there is something scannable here. There is not.
      // Disposed explicitly at the end of the body, not via `addTearDown`:
      // the framework's end-of-test handle verification runs *before* tear-
      // downs, so a deferred dispose fails the test the moment the assertions
      // below start passing.
      final SemanticsHandle handle = tester.ensureSemantics();

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: Center(child: QrPlaceholder(size: 160))),
        ),
      );
      await tester.pump();

      // Scoped to this widget's own subtree. An unscoped `findsOneWidget` also
      // matches Flutter's `ModalBarrier`/`BlockSemantics` in the Navigator
      // overlay — measured, two matches — which made the assertion fail for a
      // reason that had nothing to do with the QR.
      expect(
        find.descendant(
          of: find.byType(QrPlaceholder),
          matching: find.byType(ExcludeSemantics),
        ),
        findsOneWidget,
      );

      final SemanticsNode root = tester.getSemantics(find.byType(MaterialApp));
      final List<String> labels = <String>[];
      void walk(SemanticsNode n) {
        final String l = n.label;
        if (l.isNotEmpty) labels.add(l);
        n.visitChildren((SemanticsNode c) {
          walk(c);
          return true;
        });
      }

      walk(root);
      expect(
        labels.where(
          (String l) => l.toLowerCase().contains('qr') || l.contains('code'),
        ),
        isEmpty,
        reason: 'the bitmap announced itself; the source announces nothing',
      );

      handle.dispose();
    });
  });

  group('rendering — crisp edges over the whole box', () {
    testWidgets('the unsized form fills its parent', (
      WidgetTester tester,
    ) async {
      // `className="w-full h-full"` on the `<svg>` (`:154`).
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(width: 200, height: 200, child: QrPlaceholder()),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(tester.getSize(find.byType(QrPlaceholder)), const Size(200, 200));
    });

    testWidgets('the sized form takes exactly that side length', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: Center(child: QrPlaceholder(size: 96))),
        ),
      );
      await tester.pump();

      expect(tester.getSize(find.byType(QrPlaceholder)), const Size(96, 96));
    });

    test('the ink is the source hex, not pure black', () {
      // `fill="#1a1a1a"`, lower-case in `PaymentSection.tsx:158`. The
      // case-sensitivity of that literal is what made the fifth escalated
      // colour look absent to a `grep "1A1A1A"`. Tier 2 compares by equality,
      // not tolerance, so one step off black matters.
      expect(AppColors.qrCellInk, const Color(0xFF1A1A1A));
      expect(
        AppColors.qrCellInk,
        isNot(const Color(0xFF000000)),
        reason: 'the source is #1a1a1a; pure black is a Tier 2 mismatch',
      );
    });
  });
}
