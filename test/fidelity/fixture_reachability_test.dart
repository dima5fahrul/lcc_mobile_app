// `F0-AC-107`, `F0-AC-108`, `F0-AC-109` — RULING 12(b) and RULING 13's
// fixture-reachability precondition (§ 6.5.3 item 7, § 6.5.7), wired into the
// Dart gate.
//
// The three checks are Python, for the same reason Entry B is: they read the
// pinned TypeScript, and `constant_scan.py` / `fixture_classify.py` carry the
// source reader that does it. What they were NOT, until this file, is part of
// `flutter test` — and a check nobody runs is a check that does not exist.
// Every test below shells out and asserts on the child's exit code and its
// stdout, so a script that starts refusing shows up here as a red test rather
// than as a quiet absence.
//
// Each criterion is paired with its NEGATIVE CONTROL in the same group,
// because `F0-AC-108` says in terms that a check which passes on the tree as
// it stood at v1.3 is inert: all three of Finding M's instances are replanted
// in memory and each must fail.
//
// `_classification` is a GENERATED block (`fixture_classify.py --write`) and
// this file deliberately does NOT regenerate it before checking. Checking
// against a freshly generated table would be circular — it would assert that
// the generator agrees with itself. The table is an artefact a human reviews,
// and its citations are verified here against the source independently.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Runs a fidelity script from the package root and returns `(code, output)`.
({int code, String out}) run(String script, [List<String> args = const []]) {
  final ProcessResult r = Process.runSync(
    'python3',
    <String>['test/fidelity/$script', ...args],
    workingDirectory: Directory.current.path,
  );
  return (code: r.exitCode, out: '${r.stdout}${r.stderr}');
}

void main() {
  group('F0-AC-107 — the `constant:` register is derived from the source', () {
    test('set equality with oracle_coverage.yaml, both directions', () {
      final ({int code, String out}) r = run('constant_scan.py');
      // ignore: avoid_print
      print(r.out.trim());
      expect(r.code, 0, reason: r.out);
      expect(r.out, contains('PASS — set equality, both directions'));
      // The denominator is real and tiny, which is the point: the assertion
      // has one member today, so it cannot be satisfied vacuously.
      expect(r.out, contains("derived   (1): ['podCountry']"));
      expect(r.out, contains('DeathDeclarationPage.tsx:224'));
    });

    test('control (a) — a planted WRITER drops the leaf and FAILS', () {
      final ({int code, String out}) r =
          run('constant_scan.py', <String>['--control=planted-writer']);
      expect(r.code, 0, reason: r.out);
      expect(r.out, contains('the equality FAILED as required'),
          reason: 'a `constant:` row whose field acquires a writer must go '
              'red, or the register has decayed into the standing waiver '
              'RULING 12(b) refused.\n${r.out}');
    });

    test('control (b) — a planted ROW with no scan support FAILS', () {
      final ({int code, String out}) r =
          run('constant_scan.py', <String>['--control=planted-row']);
      expect(r.code, 0, reason: r.out);
      expect(r.out, contains('the equality FAILED as required'));
      expect(r.out, contains('notAFieldAnyPageHas'));
    });
  });

  group('F0-AC-108 / F0-AC-109 — every fixture key is classified and every '
      'drivable arm is covered', () {
    test('all keys classified, all citations verified, all arms accounted for',
        () {
      final ({int code, String out}) r = run('fixture_classify.py');
      // ignore: avoid_print
      print(r.out.trim());
      expect(r.code, 0, reason: r.out);
      expect(r.out, contains('F0-AC-108, F0-AC-109: PASS'));
    });

    // ── Finding M, all three instances, replanted ───────────────────────────
    test('control — `podCountry: "LA"` (M-1) FAILS as a constant-key defect',
        () {
      final ({int code, String out}) r =
          run('fixture_classify.py', <String>['--control=pod-country']);
      expect(r.code, 0, reason: r.out);
      expect(r.out, contains('the check FAILED as required'));
      expect(r.out, contains('is a defect by definition'),
          reason: 'a `constant` key whose value differs from its initialiser '
              'must be caught at authoring time, not escalated as an A-vs-B '
              'disagreement twelve documents later.\n${r.out}');
    });

    test('control — `divorceType: "mutual"` (M-2) FAILS naming the arms', () {
      final ({int code, String out}) r =
          run('fixture_classify.py', <String>['--control=divorce-mutual']);
      expect(r.code, 0, reason: r.out);
      expect(r.out, contains('the check FAILED as required'));
      expect(r.out, contains('DivorceCertificatePage.tsx:749-766'));
    });

    test('control — `betrothalMode: "existing"` (M-3) FAILS', () {
      final ({int code, String out}) r =
          run('fixture_classify.py', <String>['--control=betrothal-existing']);
      expect(r.code, 0, reason: r.out);
      expect(r.out, contains('the check FAILED as required'));
    });

    test('control — deleting the `contested` variant FAILS *naming* the '
        'uncovered arm, not merely reducing a count', () {
      final ({int code, String out}) r =
          run('fixture_classify.py', <String>['--control=delete-contested']);
      expect(r.code, 0, reason: r.out);
      expect(r.out, contains('the check FAILED as required'));
      expect(r.out, contains("the arm 'contested' is REACHABLE"),
          reason: 'F0-AC-109 requires the uncovered ARM to be named. A count '
              'that merely dropped would not tell the reader which of the two '
              'payload groups had gone permanently empty — which is the '
              'F0-AC-86 vacuity RULING 13 exists to close.\n${r.out}');
    });
  });
}
