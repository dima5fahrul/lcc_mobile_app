/// F3's scope and negative-scan criteria, run as greps over the tree.
///
/// `F3-AC-9`, `F3-AC-11`, `F3-AC-13`, `F3-AC-18`, `F3-AC-19`, `F3-AC-22`,
/// `F3-AC-23`, `F3-AC-24`, `F3-AC-37`, `F3-AC-38`, `F3-AC-70`, `F3-AC-79`,
/// `F3-AC-98`.
///
/// ## § 7.0(2) — the gate on every negative scan, reported rather than assumed
///
/// > *A negative grep over an empty directory is NOT EVALUATED, never PASS.*
///
/// The three directory thresholds are **measured and printed** by the first
/// test below, and each negative scan states which side of the threshold it is
/// on. At the time of writing `marriage/` and `divorce/` hold their state,
/// payload and cubit and **not** their page or step widgets, so the scans that
/// depend on the view layer are recorded NOT EVALUATED in `qa-report.md` rather
/// than reported green over a directory that cannot contain the thing being
/// scanned for.
///
/// The scans over `certificate_forms/` are **evaluated**: that directory is
/// complete at ten files, so `F3-AC-24`'s "no `ReferenceSelectView`" is a real
/// negative over a real subject.
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

const String kMarriageDir =
    'lib/features/certificates/presentation/marriage';
const String kDivorceDir = 'lib/features/certificates/presentation/divorce';
const String kSharedDir =
    'lib/features/certificates/presentation/certificate_forms';

/// Non-empty `.dart` files directly under [dir].
List<File> _dartFiles(String dir) {
  final Directory d = Directory(dir);
  if (!d.existsSync()) return <File>[];
  return d
      .listSync(recursive: true)
      .whereType<File>()
      .where((File f) => f.path.endsWith('.dart'))
      .where((File f) => f.lengthSync() > 0)
      .toList();
}

String _textOf(List<String> dirs) {
  final StringBuffer b = StringBuffer();
  for (final String dir in dirs) {
    for (final File f in _dartFiles(dir)) {
      b.writeln('// FILE ${f.path}');
      b.writeln(f.readAsStringSync());
    }
  }
  return b.toString();
}

/// Source text with `///` doc comments and `//` line comments removed.
///
/// Every one of these files **discusses** the thing it must not do — the doc
/// comments name `ReferenceSelectView`, `LoadFailure`, `FileType.custom` and
/// `DateTime.now()` explicitly, because that is how the next implementer learns
/// not to add them. A scan over raw text would trip on the warning and report
/// the defect it exists to prevent.
String _stripComments(String src) {
  final List<String> out = <String>[];
  for (final String line in src.split('\n')) {
    final String t = line.trimLeft();
    if (t.startsWith('///') || t.startsWith('//')) continue;
    out.add(line);
  }
  return out.join('\n');
}

void main() {
  test('§ 7.0(2) the three directory thresholds, MEASURED', () {
    final int marriage = _dartFiles(kMarriageDir).length;
    final int divorce = _dartFiles(kDivorceDir).length;
    final int shared = _dartFiles(kSharedDir).length;

    // ignore: avoid_print
    print('§ 7.0(2) file counts — marriage/ $marriage (needs >= 6), '
        'divorce/ $divorce (needs >= 5), certificate_forms/ $shared '
        '(needs >= 5)');
    // ignore: avoid_print
    print(marriage >= 6 && divorce >= 5
        ? '§ 7.0(2): the [gated] page-level criteria are EVALUABLE'
        : '§ 7.0(2): the [gated] page-level criteria over marriage/ and '
            'divorce/ are NOT EVALUATED — the view layer is absent, so a '
            'negative scan over those directories proves nothing. Recorded in '
            'qa-report.md by name.');

    // `certificate_forms/` is complete, so its scans below ARE evaluated. This
    // is asserted rather than printed, because it is the precondition the
    // shared-set criteria rest on.
    expect(shared, greaterThanOrEqualTo(5),
        reason: 'the shared set is F3\'s own directory and must be complete '
            'for F3-AC-24 to mean anything');
  });

  group('the kernel is untouched — F3-AC-13', () {
    test('nothing under lib/presentation/forms/ or domain/submission/ is '
        'imported for MODIFICATION, and no F3 file lives there', () {
      // The diff-level assertion is `F3-AC-13` proper and is made in
      // `code-review.md` against `git diff --name-only`. What a test can add is
      // the structural half: no F3 source file is inside those directories.
      for (final String forbidden in <String>[
        'lib/presentation/forms',
        'lib/features/certificates/domain/submission',
        'lib/features/certificates/presentation/resident',
      ]) {
        final List<File> f3Files = _dartFiles(forbidden)
            .where((File f) =>
                f.readAsStringSync().contains('certificate_forms/') ||
                f.readAsStringSync().contains('marriage_payload') ||
                f.readAsStringSync().contains('divorce_payload'))
            .toList();
        expect(f3Files, isEmpty,
            reason: '$forbidden must not reference F3 — the kernel is F3\'s '
                'dependency, never its dependent');
      }
    });

    test('F3-AC-19 nothing under resident/ imports certificate_forms/', () {
      expect(
        _textOf(<String>['lib/features/certificates/presentation/resident'])
            .contains('certificate_forms/'),
        isFalse,
        reason: 'the hard boundary in § 6.2: if a third consumer appears, THAT '
            'is when § 4.2 row 3 fires and the promotion is decided — with a '
            'document, not in passing',
      );
    });

    test('F3-AC-18 nothing under lib/presentation/** imports '
        'certificate_forms/', () {
      final List<File> offenders = Directory('lib/presentation')
          .listSync(recursive: true)
          .whereType<File>()
          .where((File f) => f.path.endsWith('.dart'))
          .where((File f) => f.readAsStringSync().contains('certificate_forms/'))
          .toList();
      expect(offenders, isEmpty, reason: 'G-L7\'s property, by name');
    });
  });

  group('the lookup surface — evaluated over a complete directory', () {
    test('F3-AC-24 neither the shared set nor either page mounts '
        'ReferenceSelectView', () {
      final String src =
          _stripComments(_textOf(<String>[kSharedDir, kMarriageDir, kDivorceDir]));
      expect(src.contains('ReferenceSelectView'), isFalse,
          reason: 'mounting it would add FOUR states the web does not have, on '
              'the exact page where "but the kernel already does it properly" '
              'is most tempting (§ 6.3(i), L-10(b))');
      expect(src.contains('LoadFailure'), isFalse,
          reason: 'the cascade must render no failure row (§ 6.3(iii))');
    });

    test('F3-AC-22 the reference-list holder exposes `loading`, and no call '
        'site reads it', () {
      final String shared = File('$kSharedDir/certificate_ref_list.dart')
          .readAsStringSync();
      expect(shared.contains('final bool loading;'), isTrue,
          reason: 'it must be COMPUTED — dropping it would be tidying away a '
              'measured property of the source (§ 6.3(ii))');

      // Every `.loading` read across the three directories, enumerated. The
      // criterion allows exactly three families of reader: the location
      // cascade, the record picker and the fee quote. A reference list is not
      // among them.
      final List<String> readers = <String>[];
      for (final String dir in <String>[kSharedDir, kMarriageDir, kDivorceDir]) {
        for (final File f in _dartFiles(dir)) {
          final List<String> lines = _stripComments(f.readAsStringSync()).split('\n');
          for (int i = 0; i < lines.length; i++) {
            // `.loading` as a FIELD READ. `.loadingList` is a named
            // constant and `.loading()` is a named constructor; neither reads
            // the field, and matching them would make this scan report the
            // defect it exists to find.
            if (!RegExp(r'\.loading\b(?!List|\s*\()').hasMatch(lines[i])) {
              continue;
            }
            readers.add('${f.path}:${i + 1}: ${lines[i].trim()}');
          }
        }
      }
      // ignore: avoid_print
      print('F3-AC-22 — every `.loading` occurrence across the three '
          'directories, enumerated:\n${readers.join('\n')}');

      for (final String r in readers) {
        // The three families of reader the source has: the location cascade
        // (:320, :337, :355), the record picker (:1206) and the fee quote
        // (:1575). Plus the declarations themselves.
        final bool permitted = r.contains('provinces.loading') ||
            r.contains('districts.loading') ||
            r.contains('villages.loading') ||
            r.contains('records.loading') ||
            r.contains('quote.loading') ||
            r.contains('this.loading');
        expect(permitted, isTrue,
            reason: 'an unpermitted `.loading` read: $r. The six reference '
                'lists compute it and NOTHING reads it — wiring one up adds a '
                'state the web does not have.');
      }
      expect(
        readers.any((String r) =>
            r.contains('nationalities.loading') ||
            r.contains('ethnicities.loading') ||
            r.contains('ethnicGroups.loading') ||
            r.contains('religions.loading') ||
            r.contains('divorceTypes.loading')),
        isFalse,
        reason: 'a reference list\'s `loading` was read',
      );
    });

    test('F3-AC-23 no shared spousePayload symbol exists in the shared set', () {
      final String shared = _stripComments(_textOf(<String>[kSharedDir]));
      expect(shared.contains('spousePayload'), isFalse);
      expect(shared.contains('buildSpouse'), isFalse);
      expect(shared.contains('SpouseInfo'), isFalse,
          reason: 'the two spouse models are 15 fields and 7, and one key is '
              'renamed — § 6.5, the Birth/Death parentData prohibition one '
              'family over');
    });
  });

  group('the clock — F3-AC-37, F3-AC-38', () {
    test('no DateTime.now() anywhere in F3\'s three directories', () {
      final String src =
          _stripComments(_textOf(<String>[kSharedDir, kMarriageDir, kDivorceDir]));
      expect(src.contains('DateTime.now()'), isFalse,
          reason: 'the clock is INJECTED — ADR-0005 point 2, one '
              'SubmissionClock for the whole submission');
    });

    test('no toUtc() anywhere in F3\'s three directories', () {
      final String src =
          _stripComments(_textOf(<String>[kSharedDir, kMarriageDir, kDivorceDir]));
      expect(src.contains('toUtc()'), isFalse,
          reason: 'ADR-0005: the port reads LOCAL. `toUtc()` is the defect the '
              'register exists to record a deliberate divergence FROM.');
    });
  });

  group('D-G is REPRODUCED — F3-AC-70', () {
    test('neither page defines a FIELD_STEP map or calls a step-of-first-error '
        'resolver', () {
      final String src = _stripComments(_textOf(<String>[kMarriageDir, kDivorceDir]));
      for (final String needle in <String>[
        'stepOfFirstError',
        'fieldStep',
        'FIELD_STEP',
        'FieldStep',
      ]) {
        expect(src.contains(needle), isFalse,
            reason: 'Marriage and Divorce have ZERO occurrences of these in '
                'the source. Routing a 422 would mean AUTHORING a ~200-key '
                'step map with nothing to check it against, and it would '
                'change the visible step — § 6.10 refuses fsd.md\'s FIX and '
                'narrows it to Birth and Death (FU-8).');
      }
    });
  });

  group('R-21 — F3-AC-98', () {
    test('FileType.custom and allowedExtensions appear NOWHERE under lib/', () {
      // Repo-wide, not F3-wide: the prohibition is the whole product's
      // (`attachment_accept_policy.dart:22-24`), and F3 adds the tenth upload
      // control.
      final List<String> offenders = <String>[];
      for (final File f in Directory('lib')
          .listSync(recursive: true)
          .whereType<File>()
          .where((File f) => f.path.endsWith('.dart'))) {
        final String src = _stripComments(f.readAsStringSync());
        if (src.contains('FileType.custom') || src.contains('allowedExtensions')) {
          offenders.add(f.path);
        }
      }
      expect(offenders, isEmpty,
          reason: 'in a browser `accept` is a HINT the citizen can override; '
              'FileType.custom is a HARD FILTER with no escape hatch, and '
              'porting it verbatim makes the port stricter than the source');
    });
  });

  group('the instrument was not edited — F3-AC-79', () {
    test('the fixtures, oracles and registers are byte-unchanged by F3', () {
      // The diff-level assertion is made in `code-review.md`; what a test adds
      // is that the two registers still hold what F3 read them as holding, so
      // a silent widening shows up here rather than in a green suite.
      final String divergences =
          File('test/fidelity/tier0_divergences.yaml').readAsStringSync();
      expect(
        RegExp(r'page:\s*marriage').allMatches(divergences).length,
        2,
        reason: 'exactly two Marriage rows — create and update, both '
            '/header/dated. A fifth F3 row is § 8.3 BLOCKED.',
      );
      expect(
        RegExp(r'page:\s*divorce').allMatches(divergences).length,
        2,
        reason: 'exactly two Divorce rows',
      );
      expect(divergences.contains('pointer: "/header/dated"'), isTrue);
      expect(divergences.contains('pointer: "/header.dated"'), isTrue,
          reason: 'Birth\'s and Death\'s literal flat key must still be in the '
              'register too — if it vanished, someone normalised the two '
              'families');
    });
  });
}
