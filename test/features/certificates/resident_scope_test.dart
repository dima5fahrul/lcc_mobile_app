/// The scope and layering criteria that can only be checked by reading the
/// tree — `F1-AC-9`, `F1-AC-11`…`F1-AC-17`, `F1-AC-25`, `F1-AC-39`,
/// `F1-AC-44`, `F1-AC-74`…`F1-AC-77`.
///
/// ## § 7.0(2): a negative grep over an empty directory is NOT EVALUATED
///
/// Every negative scan below is **gated** on its subject existing first. The
/// preconditions are asserted once, at the top, and a failure there makes the
/// whole file's negatives meaningless rather than vacuously green — which is
/// the Capability Rule's exact failure mode.
library;

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

const String kLib = 'lib';
const String kResidentDir = 'lib/features/certificates/presentation/resident';
const String kPaymentDir = 'lib/presentation/payment';

List<File> dartFilesIn(String dir) {
  final Directory d = Directory(dir);
  if (!d.existsSync()) return <File>[];
  return d
      .listSync(recursive: true)
      .whereType<File>()
      .where((File f) => f.path.endsWith('.dart'))
      .toList(growable: false);
}

/// Non-empty `.dart` files, which is what § 7.0(2)'s preconditions count.
int nonEmptyDartCount(String dir) => dartFilesIn(dir)
    .where((File f) => f.readAsStringSync().trim().length > 40)
    .length;

/// Every line of every `.dart` file under [dir] that matches [pattern],
/// **excluding comment lines** — a rule named in a doc comment is not a call.
List<String> scan(String dir, RegExp pattern, {List<String> exclude = const <String>[]}) {
  final List<String> hits = <String>[];
  for (final File f in dartFilesIn(dir)) {
    if (exclude.any(f.path.contains)) continue;
    final List<String> lines = f.readAsLinesSync();
    for (int i = 0; i < lines.length; i++) {
      final String line = lines[i];
      final String t = line.trimLeft();
      if (t.startsWith('///') || t.startsWith('//') || t.startsWith('*')) continue;
      if (pattern.hasMatch(line)) hits.add('${f.path}:${i + 1}: $line');
    }
  }
  return hits;
}

void main() {
  // ───────────────────────────────────────────────────────────────────────────
  // § 7.0(2) — the preconditions every [gated] criterion below depends on
  // ───────────────────────────────────────────────────────────────────────────
  group('§ 7.0(2) preconditions — without these the negatives are NOT '
      'EVALUATED, not PASS', () {
    test('the resident page directory holds at least five non-empty files', () {
      expect(nonEmptyDartCount(kResidentDir), greaterThanOrEqualTo(5));
    });

    test('lib/presentation/payment/ holds at least four non-empty files', () {
      expect(nonEmptyDartCount(kPaymentDir), greaterThanOrEqualTo(4));
    });

    test('the four write usecases exist', () {
      final String src = File(
        'lib/features/application/domain/usecases/application_usecases.dart',
      ).readAsStringSync();
      for (final String name in <String>[
        'class CreateApplication',
        'class UpdateApplication',
        'class AddAttachment',
        'class SubmitApplication',
      ]) {
        expect(src, contains(name), reason: name);
      }
    });
  });

  // ───────────────────────────────────────────────────────────────────────────
  // F1-AC-25 — no duplicate pay capability
  // ───────────────────────────────────────────────────────────────────────────
  group('F1-AC-25 the pay seam is a hole in F1\'s tree', () {
    test('F1 declares no PayApplication, PaymentResult or PaymentInstruction',
        () {
      // Scoped to what F1 owns. `features/wallet/` HAS a `PayApplication` and a
      // `PaymentResult` — **B6b's, landed in parallel** — and that is the
      // capability F1 must not duplicate, not one it must delete. Scanning all
      // of `lib/` would report B6b's work as F1's violation, which is the
      // misread this comment exists to prevent.
      for (final String dir in <String>[
        'lib/features/certificates',
        kPaymentDir,
      ]) {
        expect(
          scan(dir, RegExp(r'class (PayApplication|PaymentResult|PaymentInstruction)\b')),
          isEmpty,
          reason: '$dir must not declare a pay capability',
        );
      }
    });

    test('nothing F1 owns builds a /pay path', () {
      for (final String dir in <String>[
        'lib/features/certificates',
        kPaymentDir,
      ]) {
        expect(scan(dir, RegExp(r"'/pay|/pay'|applicationPay")), isEmpty,
            reason: '$dir reaches the pay capability through an injected '
                'function, never a URL');
      }
    });

    test('the ResidentFormCubit\'s pay port is nullable and defaulted null', () {
      final String src =
          File('$kResidentDir/resident_form_cubit.dart').readAsStringSync();
      expect(src, contains('final ResidentPayPort? pay;'));
      expect(src, contains('this.pay,'),
          reason: 'an optional named parameter — no `required`');
    });
  });

  // ───────────────────────────────────────────────────────────────────────────
  // F1-AC-11..13 — layering
  // ───────────────────────────────────────────────────────────────────────────
  group('F1-AC-11/12/13 layering', () {
    test('F1-AC-11 no endpoint knowledge in lib/presentation/payment/', () {
      expect(
        scan(kPaymentDir, RegExp(r'\b(ApiClient|api_endpoint|Dio|http)\b')),
        isEmpty,
      );
    });

    test('F1-AC-12 no wire keys anywhere under lib/presentation/', () {
      // Resident's `form_data` keys live under `features/certificates/`, not in
      // a shared widget.
      expect(
        scan(
          'lib/presentation',
          RegExp(r'''"(header|applicant|purpose|parentage|household_reference)\.|'(header|applicant|purpose|parentage|household_reference)\.'''),
        ),
        isEmpty,
      );
    });

    test('F1-AC-13 CFI — payment reaches no feature\'s data/ or presentation/',
        () {
      expect(
        scan(kPaymentDir, RegExp(r'features/[a-z_]+/(data|presentation)')),
        isEmpty,
      );
    });

    test('F1-AC-13 certificates reaches other features through domain/ only',
        () {
      expect(
        scan(
          'lib/features/certificates',
          RegExp(r"import '.*features/(?!certificates)[a-z_]+/(data|presentation)/"),
        ),
        isEmpty,
      );
    });

    test('F1-AC-46 no service locator under lib/presentation/payment/', () {
      expect(
        scan(kPaymentDir, RegExp(r'\b(injection|GetIt|sl<)\b|/di/')),
        isEmpty,
      );
    });
  });

  // ───────────────────────────────────────────────────────────────────────────
  // F1-AC-17 / F1-AC-8 — the module shape
  // ───────────────────────────────────────────────────────────────────────────
  group('F1-AC-8/17 module shape', () {
    test('F1-AC-17 features/certificates/data/ does NOT exist', () {
      expect(Directory('lib/features/certificates/data').existsSync(), isFalse,
          reason: 'the wire work is features/application/\'s (§ 6.3); an '
              'empty-but-present data/ would invite F2 to duplicate it');
    });

    test('certificates holds exactly domain/, di/ and presentation/', () {
      final List<String> subdirs = Directory('lib/features/certificates')
          .listSync()
          .whereType<Directory>()
          .map((Directory d) => d.uri.pathSegments[d.uri.pathSegments.length - 2])
          .toList()
        ..sort();
      expect(subdirs, <String>['di', 'domain', 'presentation']);
    });

    test('F1-AC-8 F1 adds no eighth lib/presentation/ group', () {
      final List<String> groups = Directory('lib/presentation')
          .listSync()
          .whereType<Directory>()
          .map((Directory d) => d.uri.pathSegments[d.uri.pathSegments.length - 2])
          .toList()
        ..sort();
      expect(groups, contains('payment'));
      expect(groups, contains('forms'));
      // The set is `ssd.md` § 4.4's; F1 adds none, so a NEW name appearing here
      // is either F1's violation or another batch's and must be attributed.
      expect(groups.length, lessThanOrEqualTo(8),
          reason: 'groups found: $groups');
    });

    test('F1-AC-16 exactly ONE Bloc/Cubit under features/certificates/', () {
      final List<String> blocs = scan(
        'lib/features/certificates',
        RegExp(r'^class \w+ extends (Cubit|Bloc)<'),
      );
      expect(blocs.length, 1, reason: blocs.join('\n'));
      expect(blocs.single, contains('ResidentFormCubit'));
    });
  });

  // ───────────────────────────────────────────────────────────────────────────
  // F1-AC-39 / F1-AC-44 — the clock and R-21
  // ───────────────────────────────────────────────────────────────────────────
  group('F1-AC-39/44 the two prohibitions', () {
    test('F1-AC-39 the ONLY DateTime.now() under certificates/ is '
        "SubmissionClock's registered site", () {
      // `submission_clock.dart` holds F0b's single sanctioned wall-clock read
      // and is the reason the repo-wide guard can name one site. Excluding it
      // and asserting it separately is the difference between "F1 added no
      // clock" and "there is no clock" — only the first is true or desirable.
      final List<String> outside = scan(
        'lib/features/certificates',
        RegExp(r'DateTime\.now\(\)'),
        exclude: <String>['domain/submission/submission_clock.dart'],
      );
      expect(outside, isEmpty,
          reason: 'every date on this page comes from the injected clock');

      expect(
        scan('lib/features/certificates', RegExp(r'DateTime\.now\(\)')).length,
        1,
        reason: 'the registered site still exists — without it this test would '
            'pass against a tree that had no clock at all',
      );

      expect(scan(kPaymentDir, RegExp(r'DateTime\.now\(\)')), isEmpty);
    });

    test('F1-AC-39 no toUtc() anywhere F1 wrote', () {
      for (final String dir in <String>['lib/features/certificates', kPaymentDir]) {
        expect(scan(dir, RegExp(r'\.toUtc\(\)')), isEmpty);
      }
    });

    test('F1-AC-44 FileType.custom and allowedExtensions appear NOWHERE in lib/',
        () {
      // This one really is repo-wide: a hard picker filter anywhere would break
      // R-21, and no other batch has a reason to add one.
      expect(scan(kLib, RegExp(r'FileType\.custom|allowedExtensions')), isEmpty);
    });

    test('the picker is called with no type filter at all', () {
      final String src =
          File('$kResidentDir/resident_fields.dart').readAsStringSync();
      expect(src, contains('FilePicker.platform.pickFiles('));
      expect(src, isNot(contains('type:')),
          reason: 'no `type:` argument means the picker\'s default view, and '
              'no rejection (specs.md § 6.7)');
    });
  });

  // ───────────────────────────────────────────────────────────────────────────
  // F1-AC-42(ii) / F1-AC-74..76 — the demo name and the namespace
  // ───────────────────────────────────────────────────────────────────────────
  group('F1-AC-42(ii)/74/76 the strings', () {
    test('"Somchai Vongkhamphanh" appears NOWHERE in lib/', () {
      // DD-1's deployed demo fallback. Slot 17 shows it; the pinned source does
      // not have it and neither may the port.
      expect(scan(kLib, RegExp('Somchai Vongkhamphanh')), isEmpty);
    });

    test('F1-AC-74 the resident namespace has exactly 102 keys in BOTH locales,'
        ' with identical key sets', () {
      final Map<String, dynamic> en = jsonDecode(
        File('assets/i18n/en.json').readAsStringSync(),
      ) as Map<String, dynamic>;
      final Map<String, dynamic> lo = jsonDecode(
        File('assets/i18n/lo.json').readAsStringSync(),
      ) as Map<String, dynamic>;

      final Map<String, dynamic> enNs = en['resident']! as Map<String, dynamic>;
      final Map<String, dynamic> loNs = lo['resident']! as Map<String, dynamic>;

      expect(enNs.length, 102);
      expect(loNs.length, 102);
      expect(enNs.keys.toSet(), equals(loNs.keys.toSet()));
    });

    test('F1-AC-76 TXT\'s six page-local sentences were NOT promoted into the '
        'namespace — which would have made the count 108', () {
      final Map<String, dynamic> en = jsonDecode(
        File('assets/i18n/en.json').readAsStringSync(),
      ) as Map<String, dynamic>;
      final Map<String, dynamic> ns = en['resident']! as Map<String, dynamic>;

      for (final String key in <String>[
        'loadFailed',
        'retry',
        'loading',
        'receipt',
        'fee',
      ]) {
        expect(ns.containsKey(key), isFalse,
            reason: '`$key` is a TXT sentence (`:136-146`), not a `resident` '
                'namespace key in the source');
      }
      // `successCompletionValue` IS a namespace key — TXT only carries the
      // fallback's *use*, not a sixth entry. Asserted so the exclusion above is
      // not over-applied.
      expect(ns.containsKey('successCompletionValue'), isTrue);
    });
  });

  // ───────────────────────────────────────────────────────────────────────────
  // F1-AC-15 — api_endpoint
  // ───────────────────────────────────────────────────────────────────────────
  group('F1-AC-15 api_endpoint and persistence', () {
    test('the two write paths F1 added exist and are the only two', () {
      final String src =
          File('lib/core/constant/api_endpoint.dart').readAsStringSync();
      expect(src, contains('applicationAttachments'));
      expect(src, contains('applicationSubmit'));
      // `create` is POST on `applications` and `update` is PATCH on
      // `application(id)` — a verb is not an endpoint, so no constant was added
      // for either.
      // Declarations, not mentions: the block's own comment explains why the
      // two were NOT added, so a bare `contains` matches its own rationale.
      expect(src, isNot(contains('String applicationCreate')));
      expect(src, isNot(contains('String applicationUpdate')));
    });

    test('no Hive box anywhere — F1 adds no local persistence', () {
      expect(scan(kLib, RegExp(r'Hive\.(openBox|box)\b')), isEmpty);
    });
  });
}
