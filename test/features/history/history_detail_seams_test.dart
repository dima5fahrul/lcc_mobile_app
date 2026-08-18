/// The seams are real — **B7-AC-49**, **B7-AC-50**, **B7-AC-51**.
///
/// These three criteria are **negative**: they say what B7b did *not* absorb.
/// A negative claim about a whole module cannot be asserted by pumping a
/// widget — a widget test proves the certificate card is absent from one
/// arrangement, not that no code anywhere names a certificate. So these read
/// the source tree, the way `color_literal_test.dart` and the G-L guards do.
///
/// § 6.1's ruling is what they enforce: `HistoryDetailPage` declares four
/// nullable slots and B5/B6 fill them later. The failure mode this
/// catches is a future edit that "just adds" a certificate number row or a pay
/// button inline — which would quietly make B7 an XL batch shipping an
/// unreviewed payment path (§ 8.3's blocked condition).
///
/// ─────────────────────────────────────────────────────────────────────────
///
/// # Amended by B5, exactly as `GOR-245-b5-…/specs.md` § 6.8 rules
///
/// Three of B7b's criteria are **batch-scoped claims implemented as permanent
/// global guards**, and B5 is the batch they fire on — the fourth instance of
/// the class `ssd.md` § 4.4.1 RULING 13 named. The rule that ruling fixed is
/// applied here rather than re-argued: *a criterion that names a batch must be
/// implemented at that batch's scope.* Every change below is on § 6.8's closed
/// list, and nothing that is not on it changed:
///
/// | Was | Now | Why |
/// | --- | --- | --- |
/// | `_forbiddenFeatures` = the two whole modules | the four `{data,presentation}` paths | the criterion's own reason is *"the seam widget arrives as a PARAMETER, never as an import"*, which is about `data` and `presentation`. The **domain** edge is CFI-permitted (`ssd.md` § 4.3) and is the one B5 uses. G-L3 enforces the same rule globally, so nothing is lost |
/// | `features/documents/` is empty | **deleted** | its whole content was *"B5 has not landed."* There is no narrower true version. Deleting a satisfied precondition is not weakening a guard; pretending it still means something is |
/// | `forbiddenIdentifiers` scanned all of `features/history/` | scans `presentation/{pages,widgets}/` | the criterion's purpose (`:11-13`) is a **rendering** claim. § 6.6 puts certificate *state* in the BLoC, which is where the source puts it too (`:149-160` are hooks, not JSX). **The needle list did not shrink** |
/// | `/me/certificates` appears nowhere in `lib/` | appears **only** in `api_endpoint.dart` and `features/documents/data/**` | the claim worth keeping is *"no second copy of B5's endpoint"*. The claim *"B5 does not exist"* has expired |
/// | four seams are `final Widget? …` | B6's two still are; B5's two carry the § 6.7 builder signatures | the criterion's reason is *"must be a nullable Widget, not a callback or a bool"*, written to stop a `bool showCertificate`. § 6.7's builders are neither |
///
/// **The test count falls by exactly one** — the single deletion above
/// (`B5-AC-55`). The two negative controls `B5-AC-52` and `B5-AC-54` require
/// are additional `expect`s **inside** the existing cases rather than new
/// cases, so the count is 8 → 7 and no more.
library;

import 'package:flutter_test/flutter_test.dart';

import '../../architecture/layering_rules.dart';

/// The four paths `features/history/**` must never import (§ 6.1, § 4.1, as
/// narrowed by B5 § 6.8).
///
/// `features/documents/domain/` and `features/wallet/domain/` are **absent on
/// purpose**: CFI names domain entities *"the only shared currency"* and
/// `ssd.md` § 4.4.1 RULING 13 makes `features/A → features/B/domain/**`
/// explicit. B5's third query uses exactly that edge.
const List<String> _forbiddenFeatures = <String>[
  'features/documents/data/',
  'features/documents/presentation/',
  'features/wallet/data/',
  'features/wallet/presentation/',
];

/// B5's endpoints. Post-B5 they exist, so the claim is **where**, not whether.
const List<String> _b5Endpoints = <String>[
  '/me/certificates',
  'me/certificates',
];

/// The only two places a B5 endpoint string may appear (§ 6.8).
///
/// `api_endpoint.dart` declares the two constants; `features/documents/data/**`
/// is the transport that consumes them. A third home is a second copy, which is
/// the hazard worth guarding once B5 exists.
bool _mayNameB5Endpoint(String path) =>
    path == 'core/constant/api_endpoint.dart' ||
    path.startsWith('features/documents/data/');

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
    // B5 landed the module the deleted case used to prove absent. Asserting it
    // is now non-empty keeps the *file* honest: the narrowed guard below scans
    // for imports of `features/documents/{data,presentation}/`, and a guard
    // that fires on a module nobody wrote proves nothing either.
    expect(under('features/documents/'), isNotEmpty,
        reason: 'B5 created the module B7b reserved the name for');
  });

  group('B7-AC-50 — no import of another batch\'s module', () {
    /// Every violating `path:line -> uri` in [files].
    ///
    /// **Matched on `DartImport.target`, not on the raw `uri` — a
    /// STRENGTHENING, and the one change here that is not on § 6.8's list.**
    /// `target` is the lib-relative path `scanTree` resolves a relative import
    /// to; `uri` is what the author typed. B7b matched on `uri`, so
    /// `import '../../../documents/data/x.dart';` — the form every intra-`lib/`
    /// import in this tree actually takes — never contained the string
    /// `features/documents/data/` and could not have been caught. Measured
    /// while writing `B5-AC-52`'s control, which failed against the original
    /// predicate.
    ///
    /// § 6.8's hard limit is that no guard may be **weakened**; this makes the
    /// criterion true for the first time, and `code-review.md` records it.
    List<String> violationsIn(Iterable<DartFile> files) {
      final List<String> violations = <String>[];
      for (final DartFile file in files) {
        for (final DartImport import in file.imports) {
          final String resolved = import.target ?? import.uri;
          for (final String forbidden in _forbiddenFeatures) {
            if (resolved.contains(forbidden) || import.uri.contains(forbidden)) {
              violations.add(cite(file, import));
            }
          }
        }
      }
      return violations;
    }

    test('features/history/** imports neither module\'s data nor presentation',
        () {
      expect(violationsIn(under('features/history/')), isEmpty,
          reason: 'the seam widget arrives as a PARAMETER, never as an import');

      // ── B5-AC-52: the narrowed guard still fires ────────────────────────────
      //
      // A planted file that does what the criterion forbids. Without this the
      // narrowing could have removed the only pattern that ever matched, and
      // the guard above would be green because it can no longer see anything.
      final DartFile planted = DartFile(
        path: 'features/history/presentation/pages/planted.dart',
        imports: const <DartImport>[
          DartImport(
            uri: '../../../documents/data/models/certificate_wire.dart',
            line: 3,
            target: 'features/documents/data/models/certificate_wire.dart',
          ),
        ],
        code: '',
      );
      expect(violationsIn(<DartFile>[planted]), hasLength(1),
          reason: 'the narrowed guard must still catch a data/ import');

      // And the complement: the edge B5 actually uses must NOT trip it, or the
      // narrowing did not happen.
      final DartFile permitted = DartFile(
        path: 'features/history/presentation/bloc/history_detail_bloc.dart',
        imports: const <DartImport>[
          DartImport(
            uri: '../../../documents/domain/entities/issued_certificate.dart',
            line: 3,
            target: 'features/documents/domain/entities/issued_certificate.dart',
          ),
        ],
        code: '',
      );
      expect(violationsIn(<DartFile>[permitted]), isEmpty,
          reason: 'CFI permits features/A -> features/B/domain/** '
              '(ssd.md § 4.3, § 4.4.1 RULING 13)');
    });

    test('features/application/** imports neither documents nor wallet', () {
      expect(violationsIn(under('features/application/')), isEmpty);
    });
  });

  group('B7-AC-49 — history names no B5/B6 type', () {
    /// Identifiers that would betray an absorbed batch. Deliberately narrow —
    /// `payment` alone would match `PaymentState`, which IS B7's (it is a field
    /// on the row the list already renders as a chip).
    ///
    /// **All eight survive B5's amendment** (`B5-AC-53`); only the scanned
    /// directory narrowed.
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

    /// The **rendering** surfaces — what the criterion's reason (`:11-13`) is
    /// about: *"a future edit that just adds a certificate number row or a pay
    /// button inline"*. `bloc/` is excluded because that is where the source
    /// keeps the certificate too (`:149-160` are hooks, not JSX).
    const List<String> renderingDirs = <String>[
      'features/history/presentation/pages/',
      'features/history/presentation/widgets/',
    ];

    test('no history rendering file names one', () {
      final List<String> hits = <String>[];
      for (final String dir in renderingDirs) {
        for (final DartFile file in under(dir)) {
          final String src = file.code;
          for (final String needle in forbiddenIdentifiers) {
            if (src.contains(needle)) hits.add('${file.path}: $needle');
          }
        }
      }
      expect(hits, isEmpty,
          reason: 'B7b renders nothing of B5\'s or B6\'s — § 6.1');

      // The narrowed subject must still be a real, non-empty set of files.
      for (final String dir in renderingDirs) {
        expect(under(dir), isNotEmpty, reason: 'nothing scanned under $dir');
      }
      expect(forbiddenIdentifiers, hasLength(8),
          reason: 'B5 § 6.8 narrowed the DIRECTORY, never the needle list');
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

  group('B7-AC-51 — B5\'s endpoints live in exactly two places', () {
    /// Every `path: needle` outside the two sanctioned homes.
    List<String> straysIn(Iterable<DartFile> files) {
      final List<String> hits = <String>[];
      for (final DartFile file in files) {
        if (_mayNameB5Endpoint(file.path)) continue;
        for (final String endpoint in _b5Endpoints) {
          if (file.code.contains(endpoint)) hits.add('${file.path}: $endpoint');
        }
      }
      return hits;
    }

    test('no second copy of /me/certificates', () {
      expect(straysIn(libFiles), isEmpty,
          reason: 'the two constants are `api_endpoint.dart`\'s and the only '
              'consumer is `features/documents/data/**`. A third home is a '
              'second copy of B5\'s endpoint — B5 § 6.8');

      // ── B5-AC-54: the retargeted guard fires on a planted second copy ──────
      final DartFile planted = DartFile(
        path: 'features/wallet/data/datasources/planted.dart',
        imports: const <DartImport>[],
        code: "const String x = '/me/certificates';",
      );
      expect(straysIn(<DartFile>[planted]), isNotEmpty,
          reason: 'a copy outside the two homes must fail this');

      // Non-vacuity in the other direction: the endpoint really does exist in
      // the tree now, so "no strays" is not "no occurrences anywhere".
      expect(
        libFiles.where((DartFile f) =>
            _mayNameB5Endpoint(f.path) &&
            _b5Endpoints.any((String e) => f.code.contains(e))),
        isNotEmpty,
        reason: 'B5 landed the constants; a green guard over zero occurrences '
            'would be evidence for nothing',
      );
    });
  });

  group('B7-AC-48 — the four slots are declared, and two are now builders', () {
    // **One case, not two.** § 6.8 SPLITS the assertion, and `B5-AC-55` caps
    // this file's test count at "falls by exactly one" — so the split lives
    // inside a single `test()` rather than adding a second.
    test('B6\'s two stay `final Widget? …`; B5\'s two are § 6.7 builders', () {
      final String src = libFiles
          .firstWhere((DartFile f) =>
              f.path ==
              'features/history/presentation/pages/history_detail_page.dart')
          .source;

      for (final String seam in <String>['paymentAction', 'paymentPanel']) {
        expect(src, contains('final Widget? $seam;'),
            reason: '$seam must be a nullable Widget, not a callback or a bool '
                '— and B5 does not touch B6\'s pair (§ 8.4 FU-3)');
      }

      // Written as the whitespace-insensitive shape rather than a byte match,
      // because `dart format` chooses the line breaks inside a function type.
      final String flat = src.replaceAll(RegExp(r'\s+'), ' ');

      expect(
        flat,
        contains('final Widget Function( ApplicationDetail detail, '
            'IssuedCertificate? certificate, )? documentActions;'),
        reason: 'the action row\'s spec is a function of the payload '
            '(`HistoryDetailPage.tsx:247`), which a pre-built Widget cannot see',
      );
      expect(
        flat,
        contains('final Widget Function( ApplicationDetail detail, '
            'IssuedCertificate? certificate, bool certificateLoading, )? '
            'certificatePanel;'),
        reason: '`certificateLoading` is a SEPARATE parameter: `:486` is a '
            'three-state gate and collapsing it would render "not available '
            'yet" while the list is still loading (`B5-AC-49`)',
      );

      // Neither became a bool or an inline render — the thing the original
      // criterion was written to stop.
      expect(src, isNot(contains('bool showCertificate')));
      expect(src, isNot(contains('final Widget? documentActions;')));
      expect(src, isNot(contains('final Widget? certificatePanel;')));
    });
  });
}
