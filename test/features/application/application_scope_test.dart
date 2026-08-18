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
      // regex; it is 18 now, with zero added and zero removed. A literal number
      // rather than a relative check, so *adding* one and *removing* one cannot
      // cancel out — and a `removeAttachment` path would necessarily take this
      // form, because it needs two segments interpolated.
      expect(endpointMembersOf(endpointSrc), hasLength(18));
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

      expect(endpointMembersOf(mutated), hasLength(19));
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
    test('B4-AC-8 the i18n namespaces are 22, and none is named `application`',
        () {
      for (final String locale in <String>['en', 'lo']) {
        final Map<String, dynamic> json =
            jsonDecode(File('assets/i18n/$locale.json').readAsStringSync())
                as Map<String, dynamic>;
        expect(json.keys, hasLength(22), reason: '$locale: ${json.keys}');
        expect(json.keys, isNot(contains('application')));
      }
    });

    test('B4-AC-9 features/application has no route and no page', () {
      expect(
        scan('lib/utils/routes', RegExp(r'features/application')),
        isEmpty,
      );
    });
  });
}
