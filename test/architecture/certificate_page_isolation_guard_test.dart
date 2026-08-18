/// **`F2-AC-16` / `F2-AC-17`** — the certificate page isolation guard, and the
/// proof it can fail.
///
/// ## What it enforces, and only that
///
/// No import edge between any two of
/// `lib/features/certificates/presentation/{resident,birth,death}/`.
///
/// It is a guard over **three named sibling directories**, not a general
/// "features may not import features" rule and not a general "no presentation
/// directory may import another" — `ssd.md` § 4.4.1 RULING 13. Three of this
/// project's recorded governance failures took a batch-scoped criterion and
/// implemented it as a permanent global mechanism; this is the mirror error the
/// scope list exists to refuse.
///
/// ## Why no pre-existing guard could see this edge
///
/// G-L3 forbids cross-**feature** imports. Birth and Death are the same feature
/// (`certificates`), so the edge `birth/ -> death/` is invisible to it. G-L7
/// covers `lib/presentation/** -> features/*/presentation/**`, which is a
/// different direction entirely. Measured, not assumed: the cross-check below
/// runs all eight existing guards over the planted fixture and asserts every
/// one of them stays silent.
///
/// ## The Capability Rule
///
/// A guard that is green over `lib/` proves nothing on its own — a guard that
/// can never fire is also green over `lib/`. So this file does both halves:
/// green over the real tree, **red over a planted import**, with the citation
/// asserted literally rather than by `isNotEmpty`.
library;

import 'package:flutter_test/flutter_test.dart';

import 'layering_rules.dart';

const String _fixtureRoot =
    'test/architecture/fixtures/violations/certificate_page_isolation';

/// The eight pre-existing guards, so the cross-check can assert that none of
/// them sees this edge — which is the evidence that the new guard was necessary
/// rather than duplicative.
final Map<String, List<String> Function(List<DartFile>)> _preExisting =
    <String, List<String> Function(List<DartFile>)>{
  'G-L1': glL1Violations,
  'G-L2': glL2Violations,
  'G-L3': glL3Violations,
  'G-L4': glL4Violations,
  'G-L5': glL5Violations,
  'G-L6': glL6Violations,
  'G-L7': glL7Violations,
  'G-L8': (List<DartFile> f) =>
      glL8Violations(f, allowlist: const <TrAllowEntry>[]),
};

void main() {
  group('certificate_page_isolation — F2-AC-16', () {
    test('the guard is scoped to exactly the three named sibling pages', () {
      // The scope is a list, by name, and F3 extends it with `marriage` and
      // `divorce` in a one-line diff. Asserted so that a later widening into a
      // general cross-directory rule is a visible change here rather than a
      // quiet one in the rule body.
      expect(kIsolatedCertificatePages, <String>['resident', 'birth', 'death']);
    });

    test('GREEN over the real tree — no sibling edge exists in lib/', () {
      final List<DartFile> files = scanTree(kLibDir);

      // Non-vacuity: the guard must actually have looked at the three pages.
      // Without this, `isEmpty` would pass over a tree where the scan found
      // nothing at all — the AC-24 shape.
      const String base = 'features/certificates/presentation/';
      final Set<String> pagesSeen = <String>{
        for (final DartFile f in files)
          if (f.path.startsWith(base))
            f.path.substring(base.length).split('/').first,
      };
      expect(pagesSeen, containsAll(<String>['resident', 'birth', 'death']),
          reason: 'the guard scanned a tree with fewer than three certificate '
              'pages in it, so an empty result means "found nothing to check", '
              'not "checked and found nothing"');

      expect(certificatePageIsolationViolations(files), isEmpty,
          reason: 'a sibling import edge exists. The nine temptations § 6.2 '
              'names are each one edge: parentData, ParentSection, the '
              'informant block, AddressFields, header.legal_basis, the success '
              'card, methodCode, the TXT tables, the 422 FIELD_STEP.');
    });

    test('F2-AC-17 RED against a planted import, naming both files', () {
      final List<DartFile> files = scanTree(_fixtureRoot);

      // The citation is asserted literally — `path:line -> uri` — rather than
      // with `hasLength(1)`. The fixture is a specification of what a violation
      // looks like; editing it should force the expectation to be restated.
      final List<String> found = certificatePageIsolationViolations(files);
      expect(
        found,
        <String>[
          'features/certificates/presentation/death/'
              'death_borrows_from_birth_fixture.dart:31 -> '
              '../birth/birth_payload_fixture.dart',
        ],
        reason: 'the guard must cite the IMPORTER and name the target',
      );

      // Both ends are named: the importer in the path, the target in the uri.
      expect(found.single, contains('presentation/death/'));
      expect(found.single, contains('birth/birth_payload_fixture.dart'));

      // ignore: avoid_print
      print('F2-AC-17 planted violation, guard output: ${found.single}');
    });

    test('the innocent half of the fixture is NOT cited', () {
      // A guard that reported both ends of the edge would send a reader to the
      // file that did nothing wrong.
      final List<String> found =
          certificatePageIsolationViolations(scanTree(_fixtureRoot));
      expect(
        found.where((String c) => c.startsWith(
            'features/certificates/presentation/birth/')),
        isEmpty,
      );
    });

    test('no pre-existing guard sees this edge — which is why F2 added one',
        () {
      final List<DartFile> files = scanTree(_fixtureRoot);
      _preExisting.forEach(
          (String id, List<String> Function(List<DartFile>) rule) {
        expect(rule(files), isEmpty,
            reason: '$id fired on the certificate_page_isolation fixture. '
                'Either the fixture trips more than the one rule it is built '
                'for, or that guard already covered this edge and the new one '
                'is duplicative. Both are findings.');
      });
    });

    test('the guard does NOT forbid importing downward', () {
      // Into `features/certificates/domain/`, `lib/presentation/forms/`,
      // `features/wallet/domain/`, `lib/i18n/`. That sharing is REQUIRED by
      // § 6.2's second table, not merely permitted, and a guard that blocked it
      // would push each page into reimplementing the kernel — the opposite of
      // what F1 proved.
      final List<DartFile> files = scanTree(kLibDir);
      const String base = 'features/certificates/presentation/';
      int downward = 0;
      for (final DartFile f in files.where(
          (DartFile f) => f.path.startsWith(base))) {
        for (final DartImport i in f.localImports) {
          if (!i.target!.startsWith(base)) downward++;
        }
      }
      expect(downward, greaterThan(0),
          reason: 'the three pages import nothing downward at all, which would '
              'mean each had reimplemented the kernel — so this test is '
              'vacuous and the real defect is elsewhere');
      expect(certificatePageIsolationViolations(files), isEmpty);
      // ignore: avoid_print
      print('certificate_page_isolation: $downward downward imports from the '
          'three pages, all permitted');
    });
  });
}
