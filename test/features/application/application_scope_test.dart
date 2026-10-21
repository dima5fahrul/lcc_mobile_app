/// B4's scope and ruling criteria, the ones that can only be checked by
/// reading the tree — `B4-AC-11`…`B4-AC-16`, `B4-AC-24`, `B4-AC-36`…`B4-AC-38`.
///
/// ## What this file is guarding, and why it needs a control
///
/// § 6.4 ruled `cancel` (`DELETE /applications/{id}`) and `removeAttachment`
/// (`DELETE /applications/{id}/attachments/{aid}`) **NOT PORTED** — no
/// `ApiEndpoint` constant, no datasource method, no repository method, no use
/// case, no UI. An assertion that they are absent is the easiest kind of test
/// to pass and the easiest to be wrong about: *"the guard passed"* over an
/// interface nobody changed is exactly the criterion the Capability Rule warns
/// about.
///
/// So every absence assertion below is paired with a **control that proves the
/// assertion can fail** — a scratch subclass declaring a ninth member, a
/// scratch source string carrying a `DELETE` path constant. Both live here,
/// asserted to fail, in the shape `test/architecture/guard_selftest_test.dart`
/// established for the layering guards.
///
/// ## Why the member sets are read from source and not from reflection
///
/// `dart:mirrors` is unavailable in a Flutter build. The declared member set of
/// an `abstract class` is therefore read the way the rest of this suite reads
/// structure — off the file — and the parser below is shared between the
/// assertion and its control, so a parser that missed a declaration would make
/// the control fail rather than make the assertion pass.
library;

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:lcc_mobile_app/core/constant/api_endpoint.dart';

const String kRepositorySrc =
    'lib/features/application/domain/repositories/application_repository.dart';
const String kDatasourceSrc =
    'lib/features/application/data/datasources/application_remote_datasource.dart';
const String kEndpointSrc = 'lib/core/constant/api_endpoint.dart';
const String kRowSrc =
    'lib/features/application/domain/entities/application_row.dart';

/// Every `.dart` file under [dir].
List<File> dartFilesIn(String dir) {
  final Directory d = Directory(dir);
  if (!d.existsSync()) return <File>[];
  return d
      .listSync(recursive: true)
      .whereType<File>()
      .where((File f) => f.path.endsWith('.dart'))
      .toList(growable: false);
}

/// Lines under [dir] matching [pattern], **excluding comment lines** — a rule
/// named in a doc comment is not a call. `resident_scope_test.dart:38-51`'s
/// scanner, and deliberately the same shape.
List<String> scan(String dir, RegExp pattern) {
  final List<String> hits = <String>[];
  for (final File f in dartFilesIn(dir)) {
    final List<String> lines = f.readAsLinesSync();
    for (int i = 0; i < lines.length; i++) {
      final String t = lines[i].trimLeft();
      if (t.startsWith('///') || t.startsWith('//') || t.startsWith('*')) {
        continue;
      }
      if (pattern.hasMatch(lines[i])) hits.add('${f.path}:${i + 1}: ${lines[i]}');
    }
  }
  return hits;
}

/// The method names declared on the **first** `abstract class` in [source].
///
/// Shared by the assertions and by their controls, so a parser that missed a
/// declaration would make the control fail rather than make the assertion pass
/// vacuously.
Set<String> abstractMembersOf(String source) {
  final List<String> lines = source.split('\n');
  final int start = lines.indexWhere((String l) => l.startsWith('abstract class'));
  expect(start, isNonNegative, reason: 'no abstract class found');

  final Set<String> names = <String>{};
  // `Future<Either<Failure, X>> name(` or `Future<X> name(` — the return type
  // may carry nested generics and may wrap onto the declaration line.
  final RegExp decl = RegExp(r'^\s{2}(?:Future|Stream)<.*>\s+(\w+)\s*\(');
  for (int i = start; i < lines.length; i++) {
    final String l = lines[i];
    if (l.startsWith('}')) break;
    final String t = l.trimLeft();
    if (t.startsWith('///') || t.startsWith('//')) continue;
    final RegExpMatch? m = decl.firstMatch(l);
    if (m != null) names.add(m.group(1)!);
  }
  return names;
}

void main() {
  final String repositorySrc = File(kRepositorySrc).readAsStringSync();
  final String datasourceSrc = File(kDatasourceSrc).readAsStringSync();
  final String endpointSrc = File(kEndpointSrc).readAsStringSync();

  // ───────────────────────────────────────────────────────────────────────────
  // B4-AC-12 — the two interfaces are exactly eight members each
  // ───────────────────────────────────────────────────────────────────────────
  group('B4-AC-12 the write and read surfaces are exactly four and four', () {
    const Set<String> expected = <String>{
      // read — B7a, B7b
      'listApplications',
      'getApplication',
      'getApplicationTimeline',
      'getStatusPipeline',
      // write — F1
      'createApplication',
      'updateApplication',
      'addAttachment',
      'submitApplication',
    };

    test('ApplicationRepository declares exactly those eight', () {
      expect(abstractMembersOf(repositorySrc), expected);
    });

    test('ApplicationRemoteDatasource declares exactly those eight', () {
      expect(abstractMembersOf(datasourceSrc), expected);
    });

    test('neither declares cancel, removeAttachment or pay — § 6.4\'s ruling '
        'and § 4.1\'s pay boundary', () {
      for (final String src in <String>[repositorySrc, datasourceSrc]) {
        final Set<String> members = abstractMembersOf(src);
        expect(members, isNot(contains('cancel')));
        expect(members, isNot(contains('cancelApplication')));
        expect(members, isNot(contains('removeAttachment')));
        expect(members, isNot(contains('payApplication')));
      }
    });

    test('B4-AC-15 THE CAPABILITY CONTROL — a ninth member makes the guard '
        'FAIL', () {
      // Without this, AC-12 passes on any tree in which nobody happened to add
      // a method — including one where `abstractMembersOf` returns the empty
      // set because its regex stopped matching.
      final String mutated = repositorySrc.replaceFirst(
        '  Future<Either<Failure, ApplicationDetail>> submitApplication(',
        '  Future<Either<Failure, Unit>> cancelApplication(String id);\n\n'
            '  Future<Either<Failure, ApplicationDetail>> submitApplication(',
      );
      expect(mutated, isNot(repositorySrc), reason: 'the mutation must apply');

      final Set<String> members = abstractMembersOf(mutated);
      expect(members, contains('cancelApplication'));
      expect(members, hasLength(9));
      expect(
        members,
        isNot(<String>{
          'listApplications',
          'getApplication',
          'getApplicationTimeline',
          'getStatusPipeline',
          'createApplication',
          'updateApplication',
          'addAttachment',
          'submitApplication',
        }),
        reason: 'the AC-12 assertion must not hold over the mutated source',
      );
    });
  });

  // ───────────────────────────────────────────────────────────────────────────
  // B4-AC-13 — api_endpoint.dart gains no constant, and no DELETE path
  // ───────────────────────────────────────────────────────────────────────────
  group('B4-AC-13 no endpoint constant was added', () {
    /// `static String x = …` and `static String x(String id) => …`.
    final RegExp member = RegExp(r'^\s+static\s+\w[\w<>?]*\s+(\w+)');

    Set<String> endpointMembersOf(String source) => source
        .split('\n')
        .map(member.firstMatch)
        .whereType<RegExpMatch>()
        .map((RegExpMatch m) => m.group(1)!)
        .toSet();

    test('the path-function member count is unchanged from the branch point '
        '— 18', () {
      // `member` matches the `static <Type> <name>` form, which on this file is
      // the **path functions** — `static String application(String id) => …`.
      // The `static const String x = '/…'` constants take three words before
      // the name and are covered by the named-absence assertions below instead.
      //
      // 18 was measured on `851397c` before B4's first edit with this exact
      // regex, and B4 added and removed none. **19 after the 2026-08-19
      // merge-back**: B5 landed `meCertificate(String id)`, granted by its own
      // § 3.1 row 10 (*"exactly two constants: `meCertificates` and
      // `meCertificate(id)`"*), and B5 merged into this branch after B4's
      // measurement was taken. Verified to be that one member and no other:
      //
      //   851397c → 18 · HEAD → 19 · delta → {meCertificate}
      //
      // **22 after the 2026-10-21 e-certificates work** — two movements,
      // both granted by the 2026-10 API guide (MOBILE-API-E-CERTIFICATES.md):
      // Task 2 landed `meCertificateFile(String id)` and
      // `meCertificateQr(String id)` (§ Citizen endpoints; that batch did not
      // touch this guard, so B4-AC-13 was found RED at 21-vs-19 before Task 3
      // began), and Task 3 landed `verifyByCode(String code)` (§ Public
      // verification endpoints — the same supersession that rewrote B5-AC-8
      // in `documents_scope_test.dart`). Verified against the measured member
      // set, no other delta:
      //
      //   851397c → 18 · B5 → 19 · Task 2 → 21 · Task 3 → 22
      //   deltas → {meCertificate}, {meCertificateFile, meCertificateQr},
      //            {verifyByCode}
      //
      // **The literal stays a literal.** The number moved, the instrument did
      // not: a relative check would let *adding* one path and *removing*
      // another cancel out, and a `removeAttachment` path — the thing this
      // assertion exists to catch — would necessarily take this form, because
      // it needs two segments interpolated. Raising the number after measuring
      // the delta is the correct maintenance; making it derive itself from the
      // tree is not, and is the defect FU-10 records elsewhere in this suite.
      expect(endpointMembersOf(endpointSrc), hasLength(22));
    });

    test('no member is named for either uncalled endpoint', () {
      final Set<String> members = endpointMembersOf(endpointSrc);
      expect(members, isNot(contains('applicationCancel')));
      expect(members, isNot(contains('applicationRemoveAttachment')));
      expect(members, isNot(contains('applicationAttachment')));
      // …and the two that DO exist still do, so this is not passing against a
      // file the regex failed to parse.
      expect(members, contains('applicationAttachments'));
      expect(members, contains('applicationSubmit'));
      expect(members, contains('applicationPay'));
    });

    test('no member VALUE contains `/attachments/` beyond the collection path',
        () {
      // The single-attachment path `/applications/{id}/attachments/{aid}` is
      // what `removeAttachment` would need. `applicationAttachments` ends at
      // the collection.
      expect(ApiEndpoint.applicationAttachments('c-1'),
          '/applications/c-1/attachments');
      expect(
        ApiEndpoint.applicationAttachments('c-1'),
        isNot(endsWith('/')),
      );
      final List<String> offenders = endpointSrc
          .split('\n')
          .where((String l) => !l.trimLeft().startsWith('//'))
          .where((String l) => l.contains('/attachments/'))
          .toList();
      expect(offenders, isEmpty, reason: offenders.join('\n'));
    });

    test('B4-AC-15 THE CAPABILITY CONTROL — a DELETE path constant makes the '
        'guard FAIL', () {
      final String mutated = endpointSrc.replaceFirst(
        '  static String applicationSubmit(String id) =>',
        '  static String applicationRemoveAttachment(String id, String aid) =>\n'
            "      '/applications/\$id/attachments/\$aid';\n\n"
            '  static String applicationSubmit(String id) =>',
      );
      expect(mutated, isNot(endpointSrc), reason: 'the mutation must apply');

      // Baseline + 1. The number has moved with each measured baseline above
      // (19→20 at B5's merge-back, 20→23 across the 2026-10 e-certificates
      // work); the property asserted — *one more member than the tree has* —
      // is unchanged.
      expect(endpointMembersOf(mutated), hasLength(23));
      expect(
        endpointMembersOf(mutated),
        contains('applicationRemoveAttachment'),
      );
      expect(
        mutated
            .split('\n')
            .where((String l) => !l.trimLeft().startsWith('//'))
            .where((String l) => l.contains('/attachments/')),
        isNotEmpty,
        reason: 'the `/attachments/` scan must see the added path',
      );
    });
  });

  // ───────────────────────────────────────────────────────────────────────────
  // B4-AC-14 — the decision is recorded IN THE TREE, not only in the spec
  // ───────────────────────────────────────────────────────────────────────────
  group('B4-AC-14 the ruling is where the next reader will look', () {
    test('application_repository.dart records NOT PORTED and no longer poses '
        'the question', () {
      expect(repositorySrc, contains('NOT PORTED'));
      expect(repositorySrc, contains('cancel'));
      expect(repositorySrc, contains('removeAttachment'));
      expect(
        repositorySrc,
        isNot(contains('B4 must decide')),
        reason: 'the question must have been replaced by the answer',
      );
    });

    test('api_endpoint.dart records the same decision', () {
      expect(endpointSrc, contains('NOT PORTED'));
      expect(endpointSrc, isNot(contains('B4 must decide')));
    });
  });

  // ───────────────────────────────────────────────────────────────────────────
  // B4-AC-11 — CreateApplicationInput is REFUSED, and says so
  // ───────────────────────────────────────────────────────────────────────────
  group('B4-AC-11 CreateApplicationInput is refused, not deferred', () {
    test('exactly one occurrence in lib/, and it is a comment', () {
      // `scan` skips comment lines, so a hit here is a declaration, a
      // constructor call or a type annotation — none of which may exist.
      final List<String> code = scan('lib', RegExp('CreateApplicationInput'));
      expect(code, isEmpty,
          reason: 'zero class declarations, constructor calls or type '
              'annotations:\n${code.join('\n')}');

      // The positive half: the comment IS there. Without it this criterion is
      // satisfied by a tree nobody touched.
      final int mentions = dartFilesIn('lib')
          .map((File f) =>
              'CreateApplicationInput'.allMatches(f.readAsStringSync()).length)
          .fold<int>(0, (int a, int b) => a + b);
      expect(mentions, 1, reason: 'one comment, in application_row.dart');
    });

    test('and that comment says REFUSED, not reserved', () {
      final String rowSrc = File(kRowSrc).readAsStringSync();
      expect(rowSrc, contains('CreateApplicationInput'));
      expect(rowSrc, contains('REFUSED'));
      expect(
        rowSrc,
        isNot(contains("`CreateApplicationInput` is B4's alone")),
        reason: 'the reservation must have become the refusal',
      );
    });
  });

  // ───────────────────────────────────────────────────────────────────────────
  // B4-AC-16 / B4-AC-24 / B4-AC-36 / B4-AC-37 / B4-AC-38 — the executor's
  // placement and the module graph
  // ───────────────────────────────────────────────────────────────────────────
  group('the executor\'s placement', () {
    test('B4-AC-16 SubmissionStep is read by production code beyond its own '
        'declaration', () {
      final List<String> hits =
          scan('lib', RegExp(r'\bSubmissionStep\b'))
              .map((String h) => h.split(':').first)
              .toSet()
              .toList()
            ..sort();
      expect(hits, contains(contains('submission_executor.dart')));
      expect(hits.length, greaterThanOrEqualTo(3),
          reason: 'declaration, plan, executor at minimum — got $hits');
    });

    test('B4-AC-16 the complement — plan.reference still has its five '
        '*_payload.dart call sites, so this cannot pass by deleting readers',
        () {
      // Scoped to the payload files. The executor reads `plan.reference` too —
      // that is B4's own new reader and counting it here would let the five
      // pre-existing ones be deleted one at a time without this failing.
      final List<String> hits =
          scan('lib/features/certificates', RegExp(r'plan\.reference'))
              .where((String h) => h.contains('_payload.dart'))
              .toList();
      expect(hits, hasLength(5), reason: hits.join('\n'));
    });

    test('B4-AC-22 plan.attachmentGuard and plan.methodCode are read by '
        'production code', () {
      // Measured 2026-08-18: both returned ZERO before B4, while the bare type
      // names already appeared — so a type-name grep would have passed before a
      // line was written. The field access is the thing only an executor
      // produces.
      expect(
        scan('lib', RegExp(r'plan\.attachmentGuard')),
        isNotEmpty,
      );
      expect(
        scan('lib', RegExp(r'plan\.methodCode')),
        isNotEmpty,
      );
    });

    test('B4-AC-24 the executor imports no data/ and no presentation/', () {
      final List<String> bad = File(
        'lib/features/certificates/domain/submission/submission_executor.dart',
      )
          .readAsLinesSync()
          .where((String l) => l.startsWith('import'))
          .where((String l) => l.contains('/data/') || l.contains('/presentation/'))
          .toList();
      expect(bad, isEmpty, reason: bad.join('\n'));
    });

    test('B4-AC-36 features/application imports NOTHING from '
        'features/certificates — the cycle § 6.6 avoided', () {
      expect(
        scan(
          'lib/features/application',
          RegExp(r'''^\s*import\s+.*features/certificates'''),
        ),
        isEmpty,
      );
    });

    test('B4-AC-36 the complement — features/certificates DOES import '
        'features/application/domain, so the criterion is not vacuous', () {
      final List<String> hits = scan(
        'lib/features/certificates',
        RegExp(r'features/application/domain|\.\./\.\./\.\./application/domain'),
      );
      expect(hits, isNotEmpty, reason: 'the edge that makes the cycle possible');
    });

    test('B4-AC-37 features/application/presentation and '
        'features/certificates/data still do not exist', () {
      expect(
        Directory('lib/features/application/presentation').existsSync(),
        isFalse,
        reason: 'B7-AC-10',
      );
      expect(
        Directory('lib/features/certificates/data').existsSync(),
        isFalse,
        reason: 'F1-AC-17',
      );
    });

    test('B4-AC-38 no second write path — ApiEndpoint.application* is reached '
        'only from the datasource, plus B6b\'s one pay call site', () {
      final List<String> hits =
          scan('lib', RegExp(r'ApiEndpoint\.application'));
      expect(hits, isNotEmpty, reason: 'the scan must find something');
      for (final String h in hits) {
        final bool inDatasource =
            h.contains('lib/features/application/data/');
        final bool isTheKnownPayException =
            h.contains('wallet_remote_datasource.dart') &&
                h.contains('applicationPay');
        expect(
          inDatasource || isTheKnownPayException,
          isTrue,
          reason: 'a second write path appeared: $h',
        );
      }
    });
  });

  // ───────────────────────────────────────────────────────────────────────────
  // B4-AC-8 / B4-AC-9 — B4 renders nothing
  // ───────────────────────────────────────────────────────────────────────────
  group('B4 renders nothing', () {
    test('B4-AC-8 B4 adds no i18n namespace, and none is named `application`',
        () {
      // **Rewritten 2026-08-19.** This asserted `hasLength(22)` — the count at
      // B4's branch point. B4 added none, so the number was right when written
      // and wrong the moment F4 (`familyBook`, `familyBookPage`) and B5
      // (`documents`) merged in: 25 now, and 26 the next time any batch appends
      // one legitimately.
      //
      // The criterion's subject is **B4 adds none**, which is a statement about
      // B4's diff, not about the tree's total. An absolute count cannot express
      // that and turns every later batch's lawful append into a red B4 test —
      // the same class of defect FU-10 records in `f2_scope_test.dart`, where a
      // guard that dereferenced a moving `HEAD` went silently inert.
      //
      // So: measure **B4's own diff**, not the tree. `git diff <base>..<tip>`
      // over `assets/i18n/` across B4's two commits must be empty — that is the
      // statement *B4 added none*, and it stays true no matter what F4, B5 or
      // any later batch appends afterwards.
      //
      // A first attempt at this fix compared the branch point against the
      // working tree and failed, blaming B4 for `history.viewDocument` — a key
      // **B5** added under its own § 6.12 grant. Measuring the tree cannot tell
      // you whose change it is; measuring the diff can. `kB4Base`/`kB4Tip` are
      // fixed points for the same reason `kPreF2Ref` is.
      const String kB4Base = '851397c';
      const String kB4Tip = '66d757b';
      final ProcessResult diff = Process.runSync(
        'git',
        <String>['diff', '--name-only', '$kB4Base..$kB4Tip', '--', 'assets/'],
      );
      expect(diff.exitCode, 0, reason: 'could not diff B4 over assets/');
      expect((diff.stdout as String).trim(), isEmpty,
          reason: 'B4 touched assets/: ${diff.stdout}');

      // And no namespace is named `application`, measured on the tree — this
      // half is a property of the shipped bundle, not of B4's diff, so it is
      // correct to read the tree here.
      for (final String locale in <String>['en', 'lo']) {
        final Map<String, dynamic> json =
            jsonDecode(File('assets/i18n/$locale.json').readAsStringSync())
                as Map<String, dynamic>;
        expect(json.keys, isNot(contains('application')));
      }
    });

    test('B4-AC-9 features/application has no route and no page', () {
      // **Narrowed 2026-08-19, and narrowed rather than relaxed.** The original
      // regex was `features/application` over the whole routes directory, which
      // read every mention as evidence of a route. After the merge-back it
      // matched `app_routes.dart:114`:
      //
      //   import '../../features/application/domain/entities/application_detail.dart';
      //
      // That import is **B5's**, granted by its § 3.1 row 9 — the route builder
      // supplies `HistoryPage`'s two document seams and needs the domain type to
      // spell their signatures. A domain-entity import is exactly what CFI
      // *requires* of a cross-feature reference (`ssd.md` § 4.3); reading it as
      // a route inverted the rule it was written to protect.
      //
      // The subject is this group's title — *B4 renders nothing*. So the scan
      // now looks for what a route or a page would actually be: a `GoRoute`
      // naming an application path, or any import reaching into
      // `features/application/presentation/`, which does not exist and must not
      // come to exist. A `domain/` import is permitted **and named as
      // permitted**, so a future reader does not re-widen this on the
      // assumption the narrowing was a workaround.
      final List<String> routeShaped = scan(
        'lib/utils/routes',
        RegExp(r"features/application/presentation|GoRoute\([^)]*application"),
      );
      expect(routeShaped, isEmpty, reason: routeShaped.join('\n'));

      // The capability half: prove the scan can still see a violation. Without
      // this the assertion above passes on any tree in which the regex has
      // silently stopped matching — the failure mode FU-10 records.
      const String planted =
          "import '../../features/application/presentation/foo_page.dart';";
      expect(
        RegExp(r'features/application/presentation').hasMatch(planted),
        isTrue,
        reason: 'the narrowed pattern must still catch a real page import',
      );
    });
  });
}
