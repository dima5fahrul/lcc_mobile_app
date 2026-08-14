/// **The My Documents card — B8-AC-26, B8-AC-27, B8-AC-28, B8-AC-29.**
///
/// The block specs.md § 2.2 Finding B rescued from omission: 99 of the source
/// page's 749 lines, absent from `roadmap.md` § B8's endpoint list and from the
/// dispatch.
///
/// ## GG-2, stated here rather than only in the report
///
/// `/me/documents` has **never been called for the live test citizen**. Every
/// state below is gated against a fixture, which is what B8-AC-28 asks for; the
/// **populated** state's behaviour against real data is NOT EVALUATED, and this
/// file is not evidence about it. Given `/me/digital-id` and `/me/family-book`
/// both 404 for that account an empty list is *likely* and is not established.
library;

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lcc_mobile_app/features/account/domain/entities/citizen_document.dart';
import 'package:lcc_mobile_app/features/account/presentation/widgets/account_date.dart';
import 'package:lcc_mobile_app/features/account/presentation/widgets/account_primitives.dart';
import 'package:lcc_mobile_app/features/account/presentation/widgets/documents_card.dart';
import 'package:lcc_mobile_app/features/session/domain/entities/bilingual.dart';
import 'package:lcc_mobile_app/i18n/i18n.dart';

import '../account_test_helper.dart';

void main() {
  Future<void> pump(
    WidgetTester tester, {
    bool loading = false,
    bool failed = false,
    String? errorMessage,
    List<CitizenDocument> documents = const <CitizenDocument>[],
    Locale locale = const Locale('en'),
  }) =>
      pumpAccountWidget(
        tester,
        DocumentsCard(
          loading: loading,
          failed: failed,
          errorMessage: errorMessage,
          documents: documents,
          onRetry: () {},
        ),
        locale: locale,
      );

  // ── B8-AC-28 — all four list states ───────────────────────────────────────

  group('B8-AC-28 — the four mandatory list states (ssd.md § 7.3)', () {
    testWidgets('loading — exactly THREE skeleton rows, and no copy',
        (WidgetTester tester) async {
      await pump(tester, loading: true);

      // `{[0, 1, 2].map(...)}` — three, not one and not "some". A different
      // count changes what a citizen sees and no other tier would notice.
      expect(find.byType(AccountSkeleton), findsNWidgets(3));
      expect(find.textContaining('Loading'), findsNothing);
      expect(find.textContaining('No documents'), findsNothing);
    });

    testWidgets('error — the API message WINS over the local string, with a '
        'retry', (WidgetTester tester) async {
      await pump(
        tester,
        failed: true,
        errorMessage: 'the registry is unreachable',
      );

      expect(find.text('the registry is unreachable'), findsOneWidget);
      expect(
        find.text('We could not load your documents.'),
        findsNothing,
        reason: '`docsQuery.error.message || c("docsError")` — `:409`. Getting '
            'the precedence backwards hides every server explanation behind '
            'one generic sentence.',
      );
      expect(find.text('Try again'), findsOneWidget);
    });

    testWidgets('error with NO message falls back to the local string',
        (WidgetTester tester) async {
      await pump(tester, failed: true, errorMessage: '');

      expect(find.text('We could not load your documents.'), findsOneWidget);
      expect(find.text('Try again'), findsOneWidget);
    });

    testWidgets('empty — the sentence, and no rows',
        (WidgetTester tester) async {
      await pump(tester);

      expect(
        find.text('No documents are linked to your account yet.'),
        findsOneWidget,
      );
      expect(find.byType(DocumentRow), findsNothing);
    });

    testWidgets('populated — rows render, with a divider between but not after '
        'the last', (WidgetTester tester) async {
      await pump(tester, documents: <CitizenDocument>[
        tDocument(id: 'a', number: 'ID-0000-0001'),
        tDocument(
          id: 'b',
          number: 'RC-0000-0002',
          title: const Bilingual(
            en: 'Resident Certificate',
            lo: 'ໃບຢັ້ງຢືນທີ່ຢູ່ອາໄສ',
          ),
        ),
      ]);

      expect(find.byType(DocumentRow), findsNWidgets(2));
      expect(find.text('National ID Card'), findsOneWidget);
      expect(find.text('Resident Certificate'), findsOneWidget);
      expect(find.text('ID-0000-0001'), findsOneWidget);

      final List<DocumentRow> rows =
          tester.widgetList<DocumentRow>(find.byType(DocumentRow)).toList();
      expect(rows[0].divider, isTrue);
      expect(rows[1].divider, isFalse);
    });
  });

  // ── B8-AC-26 — the three-state badge ──────────────────────────────────────

  group('B8-AC-26 — the status badge maps three ways and never crashes', () {
    testWidgets('valid → the `account` namespace\'s "Verified"',
        (WidgetTester tester) async {
      await pump(tester, documents: <CitizenDocument>[
        tDocument(status: DocumentStatus.valid),
      ]);
      expect(find.text('Verified'), findsOneWidget);
    });

    testWidgets('expired → COPY\'s "Expired"', (WidgetTester tester) async {
      await pump(tester, documents: <CitizenDocument>[
        tDocument(status: DocumentStatus.expired),
      ]);
      expect(find.text('Expired'), findsOneWidget);
    });

    testWidgets('missing → COPY\'s "Not on file"',
        (WidgetTester tester) async {
      await pump(tester, documents: <CitizenDocument>[
        tDocument(status: DocumentStatus.missing),
      ]);
      expect(find.text('Not on file'), findsOneWidget);
    });

    testWidgets('an UNKNOWN status renders "Not on file" and does not crash',
        (WidgetTester tester) async {
      // `DocumentStatus.parse` maps anything outside the union to `unknown`,
      // and `unknown` renders as `missing` — which is exactly what the
      // source's final `else` already does for an unrecognised string
      // (`:302`). The API may add a fourth value; a crash is not an acceptable
      // response to that.
      expect(DocumentStatus.parse('revoked'), DocumentStatus.unknown);
      expect(DocumentStatus.parse(''), DocumentStatus.unknown);

      await pump(tester, documents: <CitizenDocument>[
        tDocument(status: DocumentStatus.unknown),
      ]);
      expect(tester.takeException(), isNull);
      expect(find.text('Not on file'), findsOneWidget);
    });
  });

  // ── B8-AC-27 — formatDate, all three branches ─────────────────────────────

  group('B8-AC-27 — `formatDate` ports all THREE branches', () {
    test('empty → the em dash', () {
      expect(formatAccountDate(null, Lang.en), '—');
      expect(formatAccountDate('', Lang.en), '—');
    });

    test('unparseable → the RAW STRING, echoed back', () {
      // `if (Number.isNaN(d.getTime())) return value;` — `:83`. Not an accident
      // and not a fallback to the em dash: a citizen whose record carries a
      // malformed date sees the malformed date, which is how anyone finds out.
      expect(formatAccountDate('not-a-date', Lang.en), 'not-a-date');
      expect(formatAccountDate('31/12/2026', Lang.en), '31/12/2026');

      // ── The case that caught a real defect ────────────────────────────────
      //
      // `DateTime.tryParse("2026-13-45")` does NOT return null: Dart accepts
      // the syntax and overflows the components to 2027-02-14. JavaScript's
      // `new Date` rejects it. Before `account_date.dart` grew its range
      // check, this rendered "14 Feb 2027" — a confident, wrong,
      // plausible-looking date on a citizen's document, which nobody would
      // ever have noticed. Kept as the regression.
      expect(DateTime.tryParse('2026-13-45'), isNotNull,
          reason: 'the precondition: if Dart ever starts rejecting this, the '
              'assertion below stops testing the range check');
      expect(formatAccountDate('2026-13-45', Lang.en), '2026-13-45');
      expect(formatAccountDate('2026-02-30', Lang.en), '2026-02-30');
      expect(formatAccountDate('2026-00-10', Lang.en), '2026-00-10');
    });

    test('valid → 2-digit day, short month, numeric year', () {
      // `{day:"2-digit", month:"short", year:"numeric"}` under `en-GB`.
      expect(formatAccountDate('2026-08-14T00:00:00Z', Lang.en), '14 Aug 2026');
      // A single-digit day must be zero-padded — that is what `2-digit` means
      // and what distinguishes it from `numeric`.
      expect(formatAccountDate('2026-01-05T00:00:00Z', Lang.en), '05 Jan 2026');
    });

    test('the Lao locale produces a DIFFERENT string, and its exact glyphs are '
        'NOT EVALUATED against the web', () {
      final String lao = formatAccountDate('2026-08-14T00:00:00Z', Lang.lo);
      final String en = formatAccountDate('2026-08-14T00:00:00Z', Lang.en);

      // What can be asserted: the locale reaches the formatter at all. What
      // cannot: that `package:intl`'s CLDR month abbreviation for `lo` matches
      // the browser's ICU one at the pinned commit. There is no Tier 3
      // reference for this page (specs.md § 2.2 Finding C), so the Lao glyph
      // sequence is recorded NOT EVALUATED rather than asserted from this
      // machine's data. See `account_date.dart`.
      expect(lao, isNot(en));
      expect(lao, contains('2026'));
    });
  });

  // ── The date LINE's conditional ───────────────────────────────────────────

  group('the date line is a three-part conditional, not a flattened one', () {
    testWidgets('absent when neither date is present',
        (WidgetTester tester) async {
      await pump(tester, documents: <CitizenDocument>[tDocument()]);
      expect(find.textContaining('Valid until'), findsNothing);
      expect(find.textContaining('Issued'), findsNothing);
    });

    testWidgets('`expires_at` present → the "Valid until:" label and THAT date',
        (WidgetTester tester) async {
      await pump(tester, documents: <CitizenDocument>[
        tDocument(
          issuedAt: '2020-01-01T00:00:00Z',
          expiresAt: '2030-06-30T00:00:00Z',
        ),
      ]);
      expect(find.textContaining('Valid until:'), findsOneWidget);
      expect(find.textContaining('30 Jun 2030'), findsOneWidget);
      expect(find.textContaining('01 Jan 2020'), findsNothing);
    });

    testWidgets('only `issued_at` → the "Issued:" label and that date',
        (WidgetTester tester) async {
      await pump(tester, documents: <CitizenDocument>[
        tDocument(issuedAt: '2020-01-01T00:00:00Z'),
      ]);
      expect(find.textContaining('Issued:'), findsOneWidget);
      expect(find.textContaining('01 Jan 2020'), findsOneWidget);
    });
  });

  // ── B8-AC-29 — the FU-2 deferral is visible and renders NO dead button ────

  group('B8-AC-29 — View / Download are deferred, visibly and inertly', () {
    testWidgets('an OPENABLE document still renders `notReady` and no buttons',
        (WidgetTester tester) async {
      final CitizenDocument openable = tDocument(
        available: true,
        fileUrl: 'https://example.test/doc.pdf',
      );
      // The predicate IS ported — the deferral is a choice at the render site,
      // not a missing predicate. FU-2's owner flips the branch without
      // re-deriving it.
      expect(openable.openable, isTrue);

      await pump(tester, documents: <CitizenDocument>[openable]);

      expect(find.text('Not available yet'), findsOneWidget);
      expect(
        find.text('View'),
        findsNothing,
        reason: 'a button that does nothing is worse than an honest '
            '"not available yet" — B8-AC-29 forbids the dead affordance',
      );
      expect(find.text('Download'), findsNothing);
    });

    test('the deferral cites FU-2 in the code, so the next faithful-port '
        'dispatch does not silently "complete" it', () {
      final String source = File(
        'lib/features/account/presentation/widgets/documents_card.dart',
      ).readAsStringSync();

      expect(source, contains('FU-2'));
      expect(source, contains('DocumentViewer'));
      expect(source, contains('DialogShell'));
      expect(source, contains('PDF renderer'));
    });
  });

  // ── Both locales ──────────────────────────────────────────────────────────

  testWidgets('the Lao column renders Lao, not a hardcoded English string',
      (WidgetTester tester) async {
    await pump(tester, locale: const Locale('lo'));
    expect(find.text('ຍັງບໍ່ມີເອກະສານທີ່ເຊື່ອມກັບບັນຊີຂອງທ່ານ.'), findsOneWidget);

    await pump(
      tester,
      locale: const Locale('lo'),
      documents: <CitizenDocument>[tDocument(status: DocumentStatus.expired)],
    );
    // The bilingual title's Lao side, and the badge's Lao label.
    expect(find.text('ບັດປະຈຳຕົວ'), findsOneWidget);
    expect(find.text('ໝົດອາຍຸ'), findsOneWidget);
    expect(find.text('ຍັງບໍ່ພ້ອມໃຫ້ດາວໂຫລດ'), findsOneWidget);
  });
}
