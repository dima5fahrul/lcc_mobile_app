/// The seams are real — **B7-AC-49**, **B7-AC-50**, **B7-AC-51**.
///
/// These three criteria are **negative**: they say what B7b did *not* absorb.
/// A negative claim about a whole module cannot be asserted by pumping a
/// widget — a widget test proves the certificate card is absent from one
/// arrangement, not that no code anywhere names a certificate. So these read
/// the source tree, the way `color_literal_test.dart` and the G-L guards do.
///
/// § 6.1's ruling is what they enforce: `HistoryDetailPage` declares four
/// nullable `Widget?` slots and B5/B6 fill them later. The failure mode this
/// catches is a future edit that "just adds" a certificate number row or a pay
/// button inline — which would quietly make B7 an XL batch shipping an
/// unreviewed payment path (§ 8.3's blocked condition).
library;

import 'package:flutter_test/flutter_test.dart';

import '../../architecture/layering_rules.dart';

/// The two modules B7b must never reach into (§ 6.1, § 4.1).
const List<String> _forbiddenFeatures = <String>[
  'features/documents/',
  'features/wallet/',
];

/// B5's endpoints — `B7-AC-51` greps **all** of `lib/`, not just history.
const List<String> _b5Endpoints = <String>[
  '/me/certificates',
  'me/certificates',
];

void main() {
  late List<DartFile> libFiles;

  setUpAll(() => libFiles = scanTree(kLibDir));

  List<DartFile> under(String prefix) => libFiles
      .where((DartFile f) => f.path.startsWith(prefix))
      .toList(growable: false);

  test('the scan actually found the modules — the guard is not vacuous', () {
    // Capability Rule: every assertion below is "no file does X". All of them
    // pass trivially against an empty list, so the list must be shown non-empty
    // first, or this whole file is evidence for nothing.
    expect(under('features/history/'), isNotEmpty);
    expect(under('features/application/'), isNotEmpty);
    expect(libFiles.length, greaterThan(100),
        reason: 'a partial scan would make the greps below meaningless');
  });

  group('B7-AC-50 — no import of another batch\'s module', () {
    test('features/history/** imports neither documents nor wallet', () {
      final List<String> violations = <String>[];
      for (final DartFile file in under('features/history/')) {
        for (final DartImport import in file.imports) {
          for (final String forbidden in _forbiddenFeatures) {
            if (import.uri.contains(forbidden)) {
              violations.add(cite(file, import));
            }
          }
        }
      }
      expect(violations, isEmpty,
          reason: 'the seam widget arrives as a PARAMETER, never as an import');
    });

    test('features/application/** imports neither documents nor wallet', () {
      final List<String> violations = <String>[];
      for (final DartFile file in under('features/application/')) {
        for (final DartImport import in file.imports) {
          for (final String forbidden in _forbiddenFeatures) {
            if (import.uri.contains(forbidden)) {
              violations.add(cite(file, import));
            }
          }
        }
      }
      expect(violations, isEmpty);
    });

    test('B7b created no features/documents/ module', () {
      expect(under('features/documents/'), isEmpty,
          reason: '`DocumentViewer` and the PDF path are B5\'s (roadmap.md:358)');
    });
  });

  group('B7-AC-49 — history names no B5/B6 type', () {
    /// Identifiers that would betray an absorbed batch. Deliberately narrow —
    /// `payment` alone would match `PaymentState`, which IS B7's (it is a field
    /// on the row the list already renders as a chip).
    const List<String> forbiddenIdentifiers = <String>[
      'DocumentViewer',
      'generateDocumentPdf',
      'docSpecFromApplication',
      'PaymentSection',
      'Certificate(',
      'certificateNo',
      'verifyCode',
      'qrPayload',
    ];

    test('no history source file names one', () {
      final List<String> hits = <String>[];
      for (final DartFile file in under('features/history/')) {
        final String src = file.code;
        for (final String needle in forbiddenIdentifiers) {
          if (src.contains(needle)) hits.add('${file.path}: $needle');
        }
      }
      expect(hits, isEmpty,
          reason: 'B7b renders nothing of B5\'s or B6\'s — § 6.1');
    });

    test('the needle list is not vacuous — it matches where it should', () {
      // `certificateNo` IS parsed on the shared entity (B7a carries every wire
      // field). Proving the needle can match at all is what stops this group
      // from passing because the strings were typo'd.
      final Iterable<DartFile> app = under('features/application/');
      expect(
        app.any((DartFile f) => f.code.contains('certificateNo')),
        isTrue,
        reason: 'the field exists on the row — so the grep above is meaningful',
      );
    });
  });

  group('B7-AC-51 — B5\'s endpoints appear nowhere in lib/', () {
    test('no file mentions /me/certificates', () {
      final List<String> hits = <String>[];
      for (final DartFile file in libFiles) {
        final String src = file.code;
        for (final String endpoint in _b5Endpoints) {
          if (src.contains(endpoint)) hits.add('${file.path}: $endpoint');
        }
      }
      expect(hits, isEmpty,
          reason: 'B7b adds no B5 endpoint — § 5.1, and the third query at '
              '`HistoryDetailPage.tsx:149`/`:157` is a seam, not an omission');
    });
  });

  group('B7-AC-48 — the four slots are declared and default to null', () {
    test('the page declares exactly the four § 6.1 names', () {
      final DartFile page = libFiles.firstWhere(
        (DartFile f) =>
            f.path == 'features/history/presentation/pages/history_detail_page.dart',
      );
      final String src = page.source;

      for (final String seam in <String>[
        'documentActions',
        'paymentAction',
        'paymentPanel',
        'certificatePanel',
      ]) {
        expect(src, contains('final Widget? $seam;'),
            reason: '$seam must be a nullable Widget, not a callback or a bool');
      }
    });
  });
}
