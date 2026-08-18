/// B5's scope, layering and absences — **B5-AC-5** … **B5-AC-26**,
/// **B5-AC-76**, **B5-AC-82**, **B5-AC-89**, **B5-AC-90**, **B5-AC-93**.
///
/// Six of B5's ten dispatched endpoints were removed and two ceded to F4
/// (specs.md § 6.0). Those are **negative** claims about the whole tree, so
/// they are greps — and `B5-AC-14` is the non-vacuity control that makes the
/// greps worth reading: *a grep suite that cannot find what IS there is
/// evidence for nothing.*
///
/// ## Three criteria are reported here as measured, not as claimed
///
/// `B5-AC-6`, `B5-AC-8` and `B5-AC-9` are **unsatisfiable as written**, each
/// for a different reason, and the tests below assert the measured truth with
/// the discrepancy named rather than asserting something false or quietly
/// dropping the criterion:
///
/// * **`B5-AC-6`** demands zero hits for the single-document path. There is
///   one at `api_endpoint.dart:249` — **B8a's own comment explaining why the
///   endpoint is absent** — and it predates B5 by two batches. `B5-AC-6`'s own
///   second clause forbids editing it. The claim that holds is *B5 adds no
///   new hit*, and that is what is asserted.
/// * **`B5-AC-8`** says the `/verify` grep hits *only* `authVerifyOtp`. It
///   already hit **six** files at `7ee0e0b`, all of them B-auth's `verify-otp`,
///   and B5 adds a seventh: the document footer literal
///   *"Verify at lcc.gov.la/verify"* (`document.ts:303`), which is **rendered
///   copy**. Removing or splitting it to satisfy a grep would be the defect.
/// * **`B5-AC-9`** greps for `documentHash` while `B5-AC-27` requires all 15
///   wire fields, one of which specs.md § 5 names `documentHash`. The two
///   cannot both hold. The half that is a real claim — no `verifyHash`, no
///   `VerificationResult` — is asserted.
library;

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:lcc_mobile_app/core/constant/api_endpoint.dart';

import '../../architecture/layering_rules.dart';

/// Every path B5's diff is allowed to contain — specs.md § 3.1's sixteen rows,
/// plus the four **recorded deviations** that could not be avoided.
const List<String> _allowedPrefixes = <String>[
  // § 3.1 rows 1-4
  'lib/features/documents/',
  'lib/presentation/documents/',
  // rows 5-7
  'lib/features/history/presentation/',
  // row 8
  'lib/features/history/di/',
  // row 9
  'lib/utils/routes/app_routes.dart',
  // row 10
  'lib/core/constant/api_endpoint.dart',
  // row 11
  'lib/core/di/dependency_injection.dart',
  // row 12
  'assets/i18n/',
  // rows 13-15
  'test/features/documents/',
  'test/presentation/documents/',
  'test/features/history/',
  'test/architecture/',
];

/// Paths outside § 3.1 that B5 changed, each because the alternative was a red
/// suite. Enumerated here so `B5-AC-93` reports a **known** list rather than a
/// silent one, and so a *new* stray still fails.
const Map<String, String> _recordedDeviations = <String, String>{
  'test/helpers/app_test_harness.dart':
      'HistoryDetailBloc gained two required constructor arguments, and the '
          'harness builds one. It also must reset the new container.',
  'test/core/di/dependency_injection_test.dart':
      'di_teardown_completeness_test.dart discovers every '
          '`GetIt.asNewInstance()` under lib/features/*/di/ and fails any of '
          'its three named DI test files that does not reset it. Tenth '
          'occurrence of this class; see that guard\'s own reason string.',
  'test/features/news/di/news_injection_test.dart': 'Same guard, same reason.',
  'test/features/home/di/home_injection_test.dart': 'Same guard, same reason.',
  'test/features/certificates/di/certificates_injection_test.dart':
      'The same omission, but this file is NOT in `kDiTestFiles`, so the '
          'teardown guard could not catch it — it surfaced as `Type ApiClient '
          'is already registered inside GetIt` on the file\'s second init(). '
          'FU-8 asks for kDiTestFiles to be widened.',
};

List<String> _changedPaths() {
  final ProcessResult tracked =
      Process.runSync('git', <String>['diff', '--name-only', 'HEAD']);
  final ProcessResult untracked = Process.runSync(
    'git',
    <String>['ls-files', '--others', '--exclude-standard'],
  );
  expect(tracked.exitCode, 0, reason: 'git diff failed: ${tracked.stderr}');
  expect(untracked.exitCode, 0, reason: 'git ls-files failed');

  return <String>[
    ...(tracked.stdout as String).trim().split('\n'),
    ...(untracked.stdout as String).trim().split('\n'),
  ].where((String p) => p.isNotEmpty).toList()
    ..sort();
}

/// Case-insensitive grep over `lib/`, comments and all — the criteria are
/// written as `grep -rni`, so the raw source is the subject.
List<String> _grepLib(String pattern) {
  final RegExp re = RegExp(pattern, caseSensitive: false);
  final List<String> hits = <String>[];
  for (final FileSystemEntity e
      in Directory('lib').listSync(recursive: true)) {
    if (e is! File || !e.path.endsWith('.dart')) continue;
    if (e.path.endsWith('.freezed.dart') || e.path.endsWith('.g.dart')) continue;
    final List<String> lines = e.readAsStringSync().split('\n');
    for (int i = 0; i < lines.length; i++) {
      if (re.hasMatch(lines[i])) {
        hits.add('${e.path.replaceAll(r'\', '/')}:${i + 1}');
      }
    }
  }
  return hits..sort();
}

Map<String, dynamic> _i18n(String locale) =>
    jsonDecode(File('assets/i18n/$locale.json').readAsStringSync())
        as Map<String, dynamic>;

void main() {
  late List<DartFile> libFiles;

  setUpAll(() => libFiles = scanTree(kLibDir));

  List<DartFile> under(String prefix) =>
      libFiles.where((DartFile f) => f.path.startsWith(prefix)).toList();

  // ───────────────────────────────────────────────────────────────────────────
  group('B5-AC-14 — the non-vacuity control comes FIRST', () {
    test('the same harness finds /me/certificates, which IS there', () {
      final List<String> hits = _grepLib(r'/me/certificates');
      expect(hits.length, greaterThanOrEqualTo(2),
          reason: 'the two constants B5 added. A grep suite that cannot find '
              'what is there is evidence for nothing — every negative below '
              'depends on this passing');
      expect(hits.any((String h) => h.startsWith('lib/core/constant/')), isTrue);
    });

    test('the scan reaches the whole tree', () {
      expect(libFiles.length, greaterThan(100));
      expect(under('lib/'), isEmpty, reason: 'paths are lib-relative');
      expect(under('features/documents/'), isNotEmpty);
      expect(under('presentation/documents/'), isNotEmpty);
    });
  });

  group('B5-AC-6 … B5-AC-12 — the six removed surfaces', () {
    test('B5-AC-6 — the single-document path: one PRE-EXISTING hit, none new',
        () {
      final List<String> hits = _grepLib(r'/me/documents/');
      expect(hits, <String>['lib/core/constant/api_endpoint.dart:249'],
          reason: 'B8a\'s comment recording why the endpoint is absent. '
              '`B5-AC-6`\'s own second clause forbids editing it, so the '
              'criterion\'s "no hit" is unreachable and this is the claim that '
              'is actually true — B5 added none.');
    });

    test('B5-AC-7 — the QR sub-path has no hit at all', () {
      expect(_grepLib(r"certificateQr|/qr'"), isEmpty);
    });

    test('B5-AC-8 — every `/verify` hit is either B-auth\'s or rendered copy',
        () {
      final List<String> hits = _grepLib(r'/verify');
      // Six pre-existing, all `verify-otp` (B-auth's, and they predate B5 by
      // every batch), plus one B5 adds.
      expect(
        hits.where((String h) => !h.startsWith('lib/presentation/documents/')),
        hasLength(6),
        reason: 'the criterion says "only authVerifyOtp"; the measured '
            'pre-existing count is six files, all of them the same auth '
            'endpoint',
      );
      expect(
        hits.where((String h) => h.startsWith('lib/presentation/documents/')),
        hasLength(1),
        reason: 'the footer literal `document.ts:303` renders on the page. It '
            'is copy, not an endpoint — no `verification.*` constant exists',
      );
      // The claim that actually matters: neither dead endpoint was ported as
      // CODE. `DartFile.code` is comment-stripped, so `api_endpoint.dart`'s own
      // paragraph explaining the absence does not count as a port of it.
      expect(
        libFiles.where((DartFile f) => f.code.contains('verification.')),
        isEmpty,
      );
    });

    test('B5-AC-9 — no verifyHash and no VerificationResult', () {
      expect(_grepLib(r'verificationResult|verifyHash'), isEmpty);
      // `documentHash` IS present, and must be: specs.md § 5's field table
      // names it and `B5-AC-27` requires all 15 wire fields. The two criteria
      // are mutually exclusive; § 5 wins and the conflict is reported.
      final List<String> hash = _grepLib(r'documentHash');
      expect(hash, isNotEmpty);
      expect(
        hash.every((String h) => h.startsWith('lib/features/documents/')),
        isTrue,
        reason: 'it is a parsed wire field on the entity and nothing else — it '
            'is never rendered and no endpoint reads it',
      );
    });

    test('B5-AC-10 — the milestone list has no hit', () {
      expect(_grepLib(r'lifeEvent|life-events'), isEmpty);
    });

    test('B5-AC-11 — B5 adds no household-register hit', () {
      // 94 pre-existing hits at `7ee0e0b`, every one of them F1's resident
      // form and F0's submission plan. The claim is that B5 adds none.
      final List<String> hits = _grepLib(r'familyBook|family-book');
      expect(
        hits.where((String h) =>
            h.startsWith('lib/features/documents/') ||
            h.startsWith('lib/presentation/documents/')),
        isEmpty,
      );
    });

    test('B5-AC-12 — no pre-existing-asset URL prop anywhere', () {
      expect(_grepLib(r'staticUrl'), isEmpty,
          reason: 'porting a parameter with no call site is the same defect as '
              'porting a dead endpoint (§ 6.11)');
    });

    test('B5-AC-13 — api_endpoint gains exactly two members', () {
      expect(ApiEndpoint.meCertificates, '/me/certificates');
      expect(ApiEndpoint.meCertificate('abc'), '/me/certificates/abc');
      expect(ApiEndpoint.meCertificate('a b/c'), '/me/certificates/a%20b%2Fc',
          reason: 'the `meNotificationRead` percent-encoding convention');

      final ProcessResult diff = Process.runSync('git', <String>[
        'diff',
        '-U0',
        'HEAD',
        '--',
        'lib/core/constant/api_endpoint.dart',
      ]);
      final List<String> removed = (diff.stdout as String)
          .split('\n')
          .where((String l) => l.startsWith('-') && !l.startsWith('---'))
          .toList();
      expect(removed, isEmpty,
          reason: 'additive only (SSD § 6.5): `baseUrl` and the release HTTPS '
              'guard must be byte-identical, and so must every constant above');
    });

    test('B5-AC-15 / B5-AC-16 — features/account/** is untouched', () {
      final List<String> changed = _changedPaths();
      expect(
        changed.where((String p) => p.startsWith('lib/features/account/')),
        isEmpty,
        reason: '`documents_card.dart` and its FU-2 deferral comment stay '
            'exactly as B8 wrote them (§ 6.11)',
      );

      // And the deferral is still a rendered `notReady`, not a greyed-out
      // control that reads as "nearly done". Scoped to the card that holds it:
      // `account_header.dart` has an unrelated `Opacity` on the avatar, and a
      // whole-module grep would be measuring that instead.
      final DartFile card = libFiles.firstWhere((DartFile f) =>
          f.path == 'features/account/presentation/widgets/documents_card.dart');
      for (final String needle in <String>[
        'onPressed: null',
        'Opacity(',
        'enabled: false',
        'View',
        'Download',
      ]) {
        expect(card.code.contains(needle), isFalse,
            reason: 'documents_card.dart must render `notReady` and no '
                'View/Download control at all — found `$needle`');
      }
    });
  });

  group('B5-AC-17 … B5-AC-26 — architecture and layering', () {
    test('B5-AC-17 — presentation/documents holds widgets and a painter only',
        () {
      final List<String> offenders = <String>[];
      for (final DartFile f in under('presentation/documents/')) {
        for (final String needle in <String>[
          'injection',
          'GetIt',
          'sl<',
          'Bloc',
          'Cubit',
          'Repository',
          'ApiEndpoint',
        ]) {
          if (f.code.contains(needle)) offenders.add('${f.path}: $needle');
        }
      }
      expect(offenders, isEmpty);
      expect(under('presentation/documents/'), hasLength(4),
          reason: 'the viewer, the actions row, the card and the painter');
    });

    test('B5-AC-19 — it imports no feature presentation and no data', () {
      final List<String> offenders = <String>[];
      for (final DartFile f in under('presentation/documents/')) {
        for (final DartImport i in f.imports) {
          final String t = i.target ?? i.uri;
          if (t.contains('presentation/') && t.startsWith('features/')) {
            offenders.add(cite(f, i));
          }
          if (t.split('/').contains('data')) offenders.add(cite(f, i));
        }
      }
      expect(offenders, isEmpty, reason: 'G-L7 and G-L1');
    });

    test('B5-AC-20 — history imports documents/domain and nothing else of it',
        () {
      final List<String> domainEdges = <String>[];
      final List<String> otherEdges = <String>[];
      for (final DartFile f in under('features/history/')) {
        for (final DartImport i in f.imports) {
          final String t = i.target ?? i.uri;
          if (!t.startsWith('features/documents/')) continue;
          if (t.startsWith('features/documents/domain/')) {
            domainEdges.add(cite(f, i));
          } else if (t.startsWith('features/documents/di/')) {
            // The `ChatUsecaseInjection -> helpInjection` shape (`ssd.md`
            // § 5.1): a DI file closing over another feature's container. G-L3
            // measures `data/` and `presentation/` and permits this, which is
            // why `history_usecase_injection.dart` already imports
            // `application_injection.dart`.
            continue;
          } else {
            otherEdges.add(cite(f, i));
          }
        }
      }
      expect(otherEdges, isEmpty, reason: 'G-L3');
      expect(domainEdges, isNotEmpty,
          reason: 'the domain edge is PRESENT and is the point — a guard that '
              'passed because no edge existed would prove nothing');
    });

    test('B5-AC-21 — app_routes gains no GoRoute and no protected path', () {
      final ProcessResult diff = Process.runSync('git', <String>[
        'diff',
        '-U0',
        'HEAD',
        '--',
        'lib/utils/routes/app_routes.dart',
      ]);
      final List<String> added = (diff.stdout as String)
          .split('\n')
          .where((String l) => l.startsWith('+') && !l.startsWith('+++'))
          // Comment lines are stripped first: B5's own note at the composition
          // point says "no new `GoRoute`, no `_protectedPaths` entry", and a
          // raw scan would read that promise as the breach of it.
          .where((String l) {
            final String body = l.substring(1).trimLeft();
            return !body.startsWith('//') && !body.startsWith('///');
          })
          .toList();
      final List<String> removed = (diff.stdout as String)
          .split('\n')
          .where((String l) => l.startsWith('-') && !l.startsWith('---'))
          .toList();

      expect(added.where((String l) => l.contains('GoRoute(')), isEmpty);
      expect(added.where((String l) => l.contains('_protectedPaths')), isEmpty);
      expect(removed, isEmpty, reason: 'additions only; no reordering');
    });

    test('B5-AC-22 — documents is the EIGHTH presentation group, and no ninth',
        () {
      final List<String> groups = Directory('lib/presentation')
          .listSync()
          .whereType<Directory>()
          .map((Directory d) => d.uri.pathSegments[d.uri.pathSegments.length - 2])
          .toList()
        ..sort();

      expect(groups, hasLength(8));
      expect(groups, contains('documents'));
      expect(
        groups,
        <String>[
          'boot', 'common', 'documents', 'forms', 'icons', 'payment', 'shell',
          'theme',
        ],
      );
    });

    test('B5-AC-23 — features/documents has NO presentation subdirectory', () {
      expect(
        Directory('lib/features/documents/presentation').existsSync(),
        isFalse,
        reason: 'its widgets are in `lib/presentation/documents/` by '
            '`ssd.md` § 4.2 row 3; a stray one here would be the CR-3 mistake '
            'a fifth time',
      );
      final List<String> subdirs = Directory('lib/features/documents')
          .listSync()
          .whereType<Directory>()
          .map((Directory d) => d.uri.pathSegments[d.uri.pathSegments.length - 2])
          .toList()
        ..sort();
      expect(subdirs, <String>['data', 'di', 'domain']);
    });

    test('B5-AC-24 — documents and certificates know nothing of each other',
        () {
      for (final DartFile f in under('features/documents/')) {
        for (final DartImport i in f.imports) {
          expect((i.target ?? i.uri).contains('features/certificates/'), isFalse,
              reason: cite(f, i));
        }
      }
      for (final DartFile f in under('features/certificates/')) {
        for (final DartImport i in f.imports) {
          expect((i.target ?? i.uri).contains('features/documents/'), isFalse,
              reason: cite(f, i));
        }
      }
    });

    test('B5-AC-25 — the data layer has no write verb', () {
      final List<String> offenders = <String>[];
      for (final DartFile f in under('features/documents/data/')) {
        for (final String verb in <String>[
          '.post<',
          '.put<',
          '.patch<',
          '.delete<',
          '.upload<',
        ]) {
          if (f.code.contains(verb)) offenders.add('${f.path}: $verb');
        }
      }
      expect(offenders, isEmpty,
          reason: 'two GETs and nothing else — which is also why Tier 0 is '
              'reported N/A rather than PASS');
    });

    test('B5-AC-26 — the date transform is IMPORTED, not re-implemented', () {
      final Iterable<DartFile> documents = under('features/documents/');
      expect(
        documents.any((DartFile f) => f.imports.any((DartImport i) =>
            (i.target ?? i.uri).contains('application_formatting.dart'))),
        isTrue,
      );
      // No second month table, no second `toLocaleDateString` port.
      for (final DartFile f in <DartFile>[
        ...documents,
        ...under('presentation/documents/'),
      ]) {
        expect(f.code.contains('ShortMonths'), isFalse, reason: f.path);
        expect(f.code.contains("'Jan'"), isFalse, reason: f.path);
        expect(f.code.contains('toLocaleDateString'), isFalse, reason: f.path);
      }
    });
  });

  group('B5-AC-76 / B5-AC-82 — the two prohibitions', () {
    test('no concrete font family is transcribed', () {
      expect(_grepLib(r'Georgia|Times New Roman|\bArial\b'), isEmpty,
          reason: 'the painter names `serif`/`sans-serif` and lets the '
              'platform resolve, as the browser\'s own stack does');
    });

    test('B5-AC-82 — no picker type filter is introduced', () {
      final List<String> hits = _grepLib(r'FileType\.custom|allowedExtensions');
      expect(
        hits.where((String h) =>
            h.startsWith('lib/features/documents/') ||
            h.startsWith('lib/presentation/documents/')),
        isEmpty,
        reason: 'F1-AC-44 bans them repo-wide; the three pre-existing hits are '
            'F0\'s `AttachmentAcceptPolicy` doc and F1\'s picker comment, both '
            'of which say why they are NOT used',
      );
    });
  });

  group('B5-AC-89 / B5-AC-90 — i18n', () {
    late Map<String, dynamic> en;
    late Map<String, dynamic> lo;

    setUpAll(() {
      en = _i18n('en');
      lo = _i18n('lo');
    });

    test('en and lo have identical key sets, namespace for namespace', () {
      expect(en.keys.toSet(), lo.keys.toSet());
      for (final String ns in en.keys) {
        expect(
          (en[ns] as Map<String, dynamic>).keys.toSet(),
          (lo[ns] as Map<String, dynamic>).keys.toSet(),
          reason: '$ns drifted between locales',
        );
      }
    });

    test('exactly one new namespace, with exactly the § 6.12 keys', () {
      expect(en.keys.length, 19, reason: '18 at `7ee0e0b`, plus `documents`');
      expect(
        (en['documents'] as Map<String, dynamic>).keys.toSet(),
        <String>{
          'issuedCertificate',
          'certificateNumber',
          'issuedOn',
          'verificationCode',
          'qrPayload',
          'certificateNotAvailable',
        },
      );
    });

    test('history gains exactly two keys and loses none', () {
      // 53 at `7ee0e0b` — specs.md § 2.1 says 51, measured differently and
      // recorded in `qa-report.md`.
      expect((en['history'] as Map<String, dynamic>).keys.length, 55);
      expect(en['history']['viewDocument'], 'View document');
      expect(en['history']['downloadDocument'], 'Download document');
      expect(lo['history']['viewDocument'], 'ເບິ່ງເອກະສານ');
      expect(lo['history']['downloadDocument'], 'ດາວໂຫຼດເອກະສານ');
    });

    test('B5-AC-86 — every new value is the source arm, including the Lao QR',
        () {
      expect(en['documents']['issuedCertificate'], 'Issued certificate');
      expect(lo['documents']['issuedCertificate'], 'ໃບຢັ້ງຢືນທີ່ອອກແລ້ວ');
      expect(en['documents']['certificateNumber'], 'Certificate number');
      expect(lo['documents']['certificateNumber'], 'ເລກໃບຢັ້ງຢືນ');
      expect(en['documents']['issuedOn'], 'Issued on');
      expect(lo['documents']['issuedOn'], 'ວັນທີອອກ');
      expect(en['documents']['verificationCode'], 'Verification code');
      expect(lo['documents']['verificationCode'], 'ລະຫັດກວດສອບ');
      // `:483` — the Lao arm is the literal `QR`, **not** a translation of
      // "QR payload". Porting it as a translation would be a divergence.
      expect(en['documents']['qrPayload'], 'QR payload');
      expect(lo['documents']['qrPayload'], 'QR');
      expect(en['documents']['certificateNotAvailable'],
          'The verification code for this certificate is not available yet.');
      expect(lo['documents']['certificateNotAvailable'],
          'ຍັງບໍ່ສາມາດອ່ານລະຫັດກວດສອບຂອງໃບຢັ້ງຢືນນີ້ໄດ້ໃນຂະນະນີ້.');
    });

    test('the i18n diff is a PURE INSERTION — zero deletions in either file',
        () {
      // `account_scope_test.dart`'s `B8-AC-63` fails the whole suite on **one**
      // deletion in these two files, because a changed line breaks the parallel
      // merge for every batch sharing them. That is why the two `history` keys
      // are inserted after `"title"` (a line that already ends in a comma) and
      // the `documents` namespace before `"history": {` — appending after the
      // last entry of either would have added a trailing comma to a
      // pre-existing line and shown up here.
      final ProcessResult numstat = Process.runSync('git', <String>[
        'diff',
        '--numstat',
        'HEAD',
        '--',
        'assets/i18n/',
      ]);
      final List<String> rows = (numstat.stdout as String)
          .trim()
          .split('\n')
          .where((String l) => l.isNotEmpty)
          .toList();

      expect(rows, hasLength(2), reason: 'en.json and lo.json');
      for (final String row in rows) {
        final List<String> cells = row.split(RegExp(r'\s+'));
        expect(cells[1], '0',
            reason: '${cells[2]} shows ${cells[1]} deletion(s)');
        expect(int.parse(cells[0]), 10,
            reason: '2 history keys + an 8-line documents namespace');
      }
    });
  });

  group('B5-AC-5 / B5-AC-93 — the diff itself', () {
    test('B5-AC-5 — zero dependencies and zero assets', () {
      final List<String> changed = _changedPaths();
      expect(changed, isNot(contains('pubspec.yaml')));
      expect(changed, isNot(contains('pubspec.lock')));
      expect(
        changed.where((String p) =>
            p.startsWith('assets/') && !p.startsWith('assets/i18n/')),
        isEmpty,
        reason: 'no font, no icon, no new asset of any kind',
      );
    });

    test('B5-AC-93 — every changed path is in § 3.1 or a recorded deviation',
        () {
      final List<String> changed = _changedPaths();
      expect(changed, isNotEmpty, reason: 'a clean tree would pass vacuously');

      final List<String> strays = changed
          .where((String p) =>
              !_allowedPrefixes.any(p.startsWith) &&
              !_recordedDeviations.containsKey(p))
          .toList();

      expect(strays, isEmpty,
          reason: 'a path outside § 3.1 and outside the four recorded '
              'deviations is out of scope and is reverted, not retro-fitted.\n'
              'Strays:\n  ${strays.join('\n  ')}');

      // The deviations are real, not a widened allowlist someone forgot to
      // shrink: each listed file must actually have changed.
      for (final String path in _recordedDeviations.keys) {
        expect(changed, contains(path),
            reason: '$path is listed as a deviation but did not change — '
                'delete the entry rather than leaving a permission behind');
      }
    });
  });
}
