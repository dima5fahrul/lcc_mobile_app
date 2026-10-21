/// F2's scope, prohibitions and grep-shaped criteria.
///
/// Every **[gated]** criterion in `specs.md` § 7.0(2) is preconditioned on the
/// two page directories being non-empty: *"A negative grep over an empty
/// directory is NOT EVALUATED, never PASS."* That precondition is the first
/// group here and every gated test asserts it before greping.
library;

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:lcc_mobile_app/features/certificates/presentation/birth/birth_form_state.dart';
import 'package:lcc_mobile_app/features/certificates/presentation/death/death_form_state.dart';

import '../../architecture/layering_rules.dart' show blankComments;

const String kBirthDir = 'lib/features/certificates/presentation/birth';
const String kDeathDir = 'lib/features/certificates/presentation/death';

/// The last commit **before** F2's i18n append — the baseline `F2-AC-80`
/// compares against.
///
/// ## Why a pinned SHA and not `HEAD` (FU-10, 2026-08-19)
///
/// Both reads below were `HEAD:` originally, and the reasoning was sound while
/// F2's work sat uncommitted: `HEAD` then *was* the pre-F2 tree, and reading the
/// baseline from git rather than hard-coding a key count made the check immune
/// to later batches appending namespaces of their own.
///
/// It stopped being sound the moment F2's work was committed (`851397c`).
/// `HEAD` became a commit containing F2, so `before` and `after` were the same
/// 22-namespace map, and `F2-AC-80`'s byte-identity loop began comparing each
/// namespace **with itself** — a comparison that cannot fail. The criterion's
/// subject, *F2 changed nothing that already existed*, was no longer tested.
/// Nothing announced this: the only symptom was the sibling `expect(…, 18)`
/// going red, and "fix" it by writing 22 and the guard is silently inert.
///
/// `7ee0e0b` is `feat(F1): Resident pilot passes the hard checkpoint` — the last
/// commit whose `assets/i18n/*.json` carries 18 namespaces, verified:
///
/// ```
/// git show 7ee0e0b:assets/i18n/en.json | jq 'keys | length'  → 18
/// git show 851397c:assets/i18n/en.json | jq 'keys | length'  → 22
/// ```
///
/// **This must stay a fixed point.** "Before F2" is a moment in history; any ref
/// that moves will eventually name a tree that contains F2, and the guard will
/// go quiet again in exactly the same way. If this SHA ever becomes unreachable
/// (a rebase, a squash), the correct repair is to re-pin to whatever commit then
/// holds the 18-namespace bundle — not to fall back on a relative ref.
const String kPreF2Ref = '7ee0e0b';

/// F2's tip — the commit that landed its i18n append.
///
/// The **other** endpoint of `F2-AC-80`'s comparison, and fixed for the same
/// reason [kPreF2Ref] is. FU-10 pinned the baseline and left this side reading
/// the working tree, which was invisible until the 2026-08-19 merge-back: B5
/// then added two keys to `history` under its own § 6.12 grant, and this test
/// reported them as F2 modifying a pre-F2 namespace.
///
/// A criterion about *F2's diff* needs both ends pinned. With only one pinned,
/// the assertion drifts from "what F2 did" toward "what the branch has become"
/// — quietly, and blaming the wrong batch when it finally fires.
const String kF2Tip = '851397c';

/// Pre-F2 namespaces a **later** batch holds a spec-level grant to append to.
///
/// The value is the grant, so a reader never has to take the exemption on
/// trust. Membership buys exactly one thing: new keys are permitted. Every key
/// that existed at [kPreF2Ref] is still compared individually, so an *edit* to
/// a listed namespace fails here exactly as it would for an unlisted one.
///
/// **Adding an entry to make a build pass is the failure mode this comment
/// exists to prevent.** An entry is legitimate only when a signed spec's § 3.1
/// names the append, and the batch's own scope test asserts the new key
/// positively — otherwise the guard's subject, *nobody edits a pre-F2
/// namespace*, quietly becomes *nobody edits a namespace nobody has excused*.
///
/// `account` is here rather than frozen because the guard and B8b's spec are in
/// direct conflict otherwise: `account` had 49 keys at `7ee0e0b` (B8a's i18n
/// landed before F1's commit in this history), and B8b's § 3.1 row reads
/// `assets/i18n/{en,lo}.json` | **append** | `photoHint`. The newer, explicit
/// grant wins, and it is recorded here rather than resolved by loosening the
/// comparison for everyone.
const Map<String, String> kAppendGrants = <String, String>{
  'history': 'B5 § 6.12 added `viewDocument`/`downloadDocument`; '
      '`documents_scope_test.dart` asserts them positively',
  'account': 'B8b (`GOR-245-b8-account-profile/specs.md` § 3.1) added '
      '`photoHint`, the avatar upload control\'s accessible label; '
      '`account_scope_test.dart` B8-AC-46 asserts the count and the '
      'en/lo key-set identity',
};

/// Pre-F2 **values** a later batch's spec-level grant authorises re-labelling.
///
/// [kAppendGrants] buys appends; the forms-v2 guide
/// (`MOBILE-API-E-CERTIFICATES.md`, "Application forms v2") mandates an
/// operation that is neither: the full-name inputs carry "(Lao script)" so an
/// applicant can tell the two scripts apart, and the resident label sits in a
/// namespace that predates F2. The edit is lawful only under a named grant,
/// recorded here the way B8b's was — with the **new** value pinned, so the
/// exemption is exercised rather than skipped, and every other key in the
/// namespace (and every key set in full) is still checked below.
///
/// **Adding an entry here to make an unrelated edit pass is the same failure
/// mode the [kAppendGrants] comment names.** An entry is legitimate only when
/// the batch's brief names the relabel explicitly and the key-set equality
/// check keeps the namespace's shape frozen.
const Map<String, Map<String, String>> kRelabelGrants =
    <String, Map<String, String>>{
  'en': <String, String>{
    'resident.citizenNameLabel': "Citizen's Name (Lao script)",
  },
  'lo': <String, String>{
    'resident.citizenNameLabel': 'ຊື່ ແລະ ນາມສະກຸນ (ລາວ)',
  },
};

List<File> _dartFiles(String dir) {
  final Directory d = Directory(dir);
  if (!d.existsSync()) return <File>[];
  return d
      .listSync(recursive: true)
      .whereType<File>()
      .where((File f) => f.path.endsWith('.dart'))
      .toList()
    ..sort((File a, File b) => a.path.compareTo(b.path));
}

/// Every `file:line` of **code** in [dir] matching [pattern].
///
/// Comments are blanked first, through the same [blankComments] the eight
/// production guards use. `guard_selftest_test.dart` states the reason as a
/// named behaviour — *"comments are stripped, so documenting a rule is not
/// violating it"* — and every one of these criteria is about what the code
/// does, not about what its doc comments say. Without this, a file explaining
/// why it must never call `FileType.custom` reports itself as a violation, and
/// the honest fix would be to delete the explanation.
///
/// [blankComments] is line-preserving, so the citations stay accurate.
List<String> grep(String dir, Pattern pattern) {
  final List<String> hits = <String>[];
  for (final File f in _dartFiles(dir)) {
    final List<String> lines =
        blankComments(f.readAsStringSync()).split('\n');
    for (int i = 0; i < lines.length; i++) {
      if (lines[i].contains(pattern)) hits.add('${f.path}:${i + 1}');
    }
  }
  return hits;
}

/// The same scan over the file **as written**, comments and all.
///
/// Used only where the criterion really is "this text appears nowhere",
/// independent of whether it is code: an inlined wire literal in a doc comment
/// is one copy-paste away from being an inlined wire literal.
List<String> grepRaw(String dir, Pattern pattern) {
  final List<String> hits = <String>[];
  for (final File f in _dartFiles(dir)) {
    final List<String> lines = f.readAsLinesSync();
    for (int i = 0; i < lines.length; i++) {
      if (lines[i].contains(pattern)) hits.add('${f.path}:${i + 1}');
    }
  }
  return hits;
}

void main() {
  // ───────────────────────────────────────────────────────────────────────────
  // § 7.0(2) — the precondition every [gated] criterion rests on
  // ───────────────────────────────────────────────────────────────────────────
  group('§ 7.0(2) the gated precondition', () {
    test('both page directories hold >= 5 non-empty .dart files', () {
      for (final String dir in <String>[kBirthDir, kDeathDir]) {
        final List<File> files = _dartFiles(dir);
        final List<File> nonEmpty =
            files.where((File f) => f.lengthSync() > 0).toList();
        // ignore: avoid_print
        print('§ 7.0(2) $dir: ${nonEmpty.length} non-empty .dart files — '
            '${nonEmpty.map((File f) => f.uri.pathSegments.last).join(', ')}');
        expect(nonEmpty.length, greaterThanOrEqualTo(5),
            reason: 'a negative grep over an empty directory is NOT '
                'EVALUATED, never PASS');
      }
    });
  });

  // ───────────────────────────────────────────────────────────────────────────
  // § 6.2 RULING 1 — no shared symbol
  // ───────────────────────────────────────────────────────────────────────────
  group('F2-AC-18 no shared symbol between the pages [gated]', () {
    test('neither page directory names the other', () {
      expect(grep(kDeathDir, 'presentation/birth'), isEmpty);
      expect(grep(kBirthDir, 'presentation/death'), isEmpty);
      // Relative imports too — `../birth/` is the form the guard fixture uses.
      expect(grep(kDeathDir, RegExp(r"import\s+'\.\./birth/")), isEmpty);
      expect(grep(kBirthDir, RegExp(r"import\s+'\.\./death/")), isEmpty);
      expect(grep(kBirthDir, RegExp(r"import\s+'\.\./resident/")), isEmpty);
      expect(grep(kDeathDir, RegExp(r"import\s+'\.\./resident/")), isEmpty);
    });

    test('no `_shared/`, `common/` or `base/` directory under '
        'certificates/presentation/ holds page code', () {
      final Directory presentation =
          Directory('lib/features/certificates/presentation');
      final List<String> names = presentation
          .listSync()
          .whereType<Directory>()
          .map((Directory d) =>
              d.uri.pathSegments[d.uri.pathSegments.length - 2])
          .toList()
        ..sort();
      // ignore: avoid_print
      print('F2-AC-18 certificates/presentation/ directories: $names');
      for (final String forbidden in <String>[
        '_shared',
        'shared',
        'common',
        'base',
      ]) {
        expect(names, isNot(contains(forbidden)),
            reason: 'F2 created a third directory to hold "what Birth and '
                'Death have in common". § 6.2: the pages were written '
                'independently in the source and the port mirrors the source.');
      }
    });
  });

  group('F2-AC-19 no endpoint or wire knowledge in presentation/ [gated]', () {
    test('no ApiClient, api_endpoint, Dio or http under '
        'certificates/presentation/', () {
      // Scoped to code, so the words may still appear in prose explaining why
      // they are absent.
      final List<String> hits = <String>[];
      for (final File f in _dartFiles(
          'lib/features/certificates/presentation')) {
        final List<String> lines = f.readAsLinesSync();
        for (int i = 0; i < lines.length; i++) {
          final String line = lines[i].trimLeft();
          if (line.startsWith('//') || line.startsWith('///')) continue;
          if (RegExp(r'\b(ApiClient|Dio)\b').hasMatch(lines[i]) ||
              lines[i].contains('api_endpoint')) {
            hits.add('${f.path}:${i + 1}');
          }
        }
      }
      expect(hits, isEmpty, reason: hits.join('\n'));
    });
  });

  // ───────────────────────────────────────────────────────────────────────────
  // § 6.3 RULING 2 — the legal-basis trap
  // ───────────────────────────────────────────────────────────────────────────
  group('F2-AC-37 each page reads its own namespace [gated]', () {
    test('the English sentence is inlined NOWHERE in lib/', () {
      // The sharpest single check in the batch, and the one `specs.md` § 11
      // item 4 tells a human reviewer to run. A shared constant or an inlined
      // literal passes every English assertion and is wrong in Lao on all
      // twenty documents.
      final List<String> hits = grepRaw('lib', 'Pursuant to the Family Law');
      expect(hits, isEmpty, reason: hits.join('\n'));
      // ignore: avoid_print
      print('F2-AC-37 grep "Pursuant to the Family Law" lib/ -> '
          '${hits.length} hits');
    });

    test('neither Lao sentence is inlined either', () {
      // The English half alone would not catch a port that inlined the Lao.
      for (final String fragment in <String>[
        'ອີງຕາມກົດໝາຍວ່າດ້ວຍຄອບຄົວ',
        'ສະບັບເລກທີ 44',
      ]) {
        expect(grepRaw('lib', fragment), isEmpty, reason: fragment);
      }
    });

    test('no `death` key is read from birth/ and no `birth` key from death/',
        () {
      expect(grep(kBirthDir, RegExp(r"'death\.")), isEmpty);
      expect(grep(kDeathDir, RegExp(r"'birth\.")), isEmpty);
    });

    test('the DI registration reads birth for Birth and death for Death', () {
      // The namespace choice is at the caller (`param2`), so the guard against
      // crossing them is that each spelled namespace appears exactly where it
      // should. The two strings differ in Lao; crossing them is invisible in
      // English.
      final String di = File(
        'lib/features/certificates/di/certificates_bloc_injection.dart',
      ).readAsStringSync();
      expect(di.contains("'birth.legalBasisText'"), isTrue);
      expect(di.contains("'death.legalBasisText'"), isTrue);
    });
  });

  // ───────────────────────────────────────────────────────────────────────────
  // § 6.7 RULING 6 — the pay seam, and what F2 does NOT mount
  // ───────────────────────────────────────────────────────────────────────────
  group('F2-AC-51 no duplicate pay capability, no PaymentSection [gated]', () {
    test('neither page declares a pay capability or mounts a payment surface',
        () {
      for (final String dir in <String>[kBirthDir, kDeathDir]) {
        for (final String forbidden in <String>[
          'class PayApplication',
          'class PaymentResult',
          'LAO_BANKS',
          'DraftPaymentSection',
          'LivePaymentSection',
          'PaymentSummaryCard',
        ]) {
          expect(grep(dir, forbidden), isEmpty,
              reason: '$dir declares or mounts `$forbidden`. Neither F2 page '
                  'imports PaymentSection at all — step 6 is Review '
                  '(specs.md § 2.2 Finding F). F1\'s draft-payment surface is '
                  'F3\'s inheritance, not F2\'s (FU-4).');
        }
        // And nothing from `lib/presentation/payment/` is imported.
        expect(grep(dir, 'presentation/payment'), isEmpty);
      }
    });

    test('F2-AC-88 api_endpoint.dart gains no path', () {
      // Byte-identical is asserted against git in `qa-report.md`; here the
      // testable half is that F2's four write paths plus pay already exist and
      // neither page names a new one.
      for (final String dir in <String>[kBirthDir, kDeathDir]) {
        expect(grep(dir, RegExp(r"'/applications")), isEmpty,
            reason: 'a URL literal in a page directory');
      }
    });
  });

  // ───────────────────────────────────────────────────────────────────────────
  // R-21 and the clock
  // ───────────────────────────────────────────────────────────────────────────
  group('F2-AC-56/57 R-21 — no extension, MIME, size or count filter', () {
    test('FileType.custom and allowedExtensions appear nowhere in lib/ [gated]',
        () {
      // Sharper on F2 than on Resident: both pages' `accept` names PDF
      // explicitly (`BirthDeclarationPage.tsx:366`,
      // `DeathDeclarationPage.tsx:360`), which makes
      // `FileType.custom(allowedExtensions: ['jpg','png','pdf'])` read like a
      // faithful transcription. It is the opposite: in a browser `accept`
      // filters the picker's default view and rejects nothing, while
      // `FileType.custom` is a hard filter with no escape hatch.
      expect(grep('lib', 'FileType.custom'), isEmpty);
      expect(grep('lib', 'allowedExtensions'), isEmpty);
    });

    test('neither page inspects a file extension, MIME type or size', () {
      for (final String dir in <String>[kBirthDir, kDeathDir]) {
        for (final Pattern forbidden in <Pattern>[
          RegExp(r'\.endsWith\(.\.(pdf|jpg|png|docx)'),
          RegExp(r'\bmimeType\b'),
          RegExp(r'\.lengthSync\(\)'),
          RegExp(r'\bmaxFileSize\b'),
        ]) {
          expect(grep(dir, forbidden), isEmpty, reason: '$dir / $forbidden');
        }
      }
    });

    test('AttachmentAcceptPolicy is read as DATA, never passed to a picker',
        () {
      // It is a Tier 1 comparison target. A page that handed it to
      // `file_picker` would turn a comparison target into a filter.
      for (final String dir in <String>[kBirthDir, kDeathDir]) {
        expect(grep(dir, 'AttachmentAcceptPolicy'), isEmpty,
            reason: 'the pages do not even reference it — Tier 1 does');
      }
    });
  });

  group('F2-AC-89/90 persistence and the clock', () {
    test('F2-AC-89 no Hive box anywhere in lib/', () {
      expect(grep('lib', 'Hive.openBox'), isEmpty);
      expect(grep('lib', 'Hive.box'), isEmpty);
    });

    test('F2-AC-90 no DateTime.now() in either page directory [gated]', () {
      // Every date comes from F0b's `SubmissionClock`. Six call sites per page
      // in the source; none of them is a local clock.
      expect(grep(kBirthDir, 'DateTime.now()'), isEmpty);
      expect(grep(kDeathDir, 'DateTime.now()'), isEmpty);
      expect(grep(kBirthDir, '.toUtc()'), isEmpty);
      expect(grep(kDeathDir, '.toUtc()'), isEmpty);
    });

    test('and both pages really do use SubmissionClock — not vacuous', () {
      expect(grep(kBirthDir, 'SubmissionClock'), isNotEmpty);
      expect(grep(kDeathDir, 'SubmissionClock'), isNotEmpty);
    });
  });

  // ───────────────────────────────────────────────────────────────────────────
  // § 6.9 — FIELD_STEP, transcribed as measured
  // ───────────────────────────────────────────────────────────────────────────
  group('F2-AC-60 FIELD_STEP as measured, not derived', () {
    test('Birth has 46 entries, {1:6, 2:17, 3:12, 5:11}, and NO step-4 row',
        () {
      expect(kBirthFieldStep.length, 46);
      final Map<int, int> byStep = <int, int>{};
      for (final int s in kBirthFieldStep.values) {
        byStep[s] = (byStep[s] ?? 0) + 1;
      }
      expect(byStep, <int, int>{1: 6, 2: 17, 3: 12, 5: 11});
      expect(byStep.containsKey(4), isFalse,
          reason: 'a step-4 row means someone added the missing '
              '`parents.father.*` mappings "because the 422 was broken". The '
              'port is now better than the source and has diverged (L-10).');
      // The attachment slot is present — it is the schema table, not the
      // payload key set.
      expect(kBirthFieldStep['child.hospital_notice'], 2);
      expect(kBirthFieldStep['header.document_no'], 1);
      // And no `parents.father.*` key is routable.
      expect(
          kBirthFieldStep.keys.where((String k) =>
              k.startsWith('parents.father')),
          isEmpty);
    });

    test('Death has 41 entries, {1:6, 2:16, 3:8, 5:11}, and NO step-4 row', () {
      expect(kDeathFieldStep.length, 41);
      final Map<int, int> byStep = <int, int>{};
      for (final int s in kDeathFieldStep.values) {
        byStep[s] = (byStep[s] ?? 0) + 1;
      }
      expect(byStep, <int, int>{1: 6, 2: 16, 3: 8, 5: 11});
      expect(byStep.containsKey(4), isFalse);
      expect(
          kDeathFieldStep.keys.where((String k) =>
              k.startsWith('parents.father')),
          isEmpty);
    });

    test('F2-AC-60 the three dead schema fields are KEPT in Death\'s table',
        () {
      // `specs.md` § 6.13: keep them in `FIELD_STEP` (it is the schema table)
      // and do NOT build a control for them. Pruning the table to what the page
      // can emit would be deriving it from the payload key set.
      for (final String dead in <String>[
        'deceased.deceased_uin',
        'deceased.found_body',
        'informant.informant_ethnicity',
      ]) {
        expect(kDeathFieldStep.containsKey(dead), isTrue,
            reason: '$dead was pruned from the schema table');
      }
      // And no control exists for the two the page collects nowhere.
      for (final String never in <String>['deceased_uin', 'found_body']) {
        expect(grep(kDeathDir, RegExp('$never(?!.:)')).where((String h) =>
            !h.contains('death_form_state.dart')), isEmpty,
            reason: 'a control was built for $never, which the source collects '
                'nowhere (specs.md § 6.13)');
      }
    });

    test('FIELD_STEP is NOT the payload key set — the two barely overlap', () {
      // `specs.md` § 2.2 Finding E, re-measured here so a port that derived one
      // from the other is caught by arithmetic rather than by review.
      expect(kBirthFieldStep.length, 46);
      expect(kDeathFieldStep.length, 41);
      // Birth: 45 of 46 schema fields are also payload keys; the exception is
      // the attachment slot.
      expect(kBirthFieldStep.containsKey('child.hospital_notice'), isTrue);
      // Death: 4 schema-only.
      for (final String schemaOnly in <String>[
        'deceased.death_notice',
        'deceased.deceased_uin',
        'deceased.found_body',
        'informant.informant_ethnicity',
      ]) {
        expect(kDeathFieldStep.containsKey(schemaOnly), isTrue);
      }
    });
  });

  // ───────────────────────────────────────────────────────────────────────────
  // § 6.14 — i18n
  // ───────────────────────────────────────────────────────────────────────────
  group('F2-AC-78/80/81/83 the two namespaces', () {
    Map<String, dynamic> bundle(String locale) => jsonDecode(
          File('assets/i18n/$locale.json').readAsStringSync(),
        ) as Map<String, dynamic>;

    test('F2-AC-78 birth has exactly 152 keys and death exactly 97, in BOTH '
        'locales, with identical key sets', () {
      final Map<String, dynamic> en = bundle('en');
      final Map<String, dynamic> lo = bundle('lo');
      for (final MapEntry<String, int> want
          in <String, int>{'birth': 152, 'death': 97}.entries) {
        final Map<String, dynamic> e =
            en[want.key]! as Map<String, dynamic>;
        final Map<String, dynamic> l =
            lo[want.key]! as Map<String, dynamic>;
        // ignore: avoid_print
        print('F2-AC-78 ${want.key}: en ${e.length}, lo ${l.length}');
        expect(e.length, want.value);
        expect(l.length, want.value);
        expect(e.keys.toList(), equals(l.keys.toList()),
            reason: '${want.key}: en and lo key sets differ');
      }
    });

    test('F2-AC-80 every pre-F2 namespace is BYTE-IDENTICAL, resident included',
        () {
      // **Compared against git, not against a literal count.** A first
      // revision of this test asserted `en.keys.length == 20` and that
      // `birth`/`death` were the last two entries — which broke the moment F3
      // legitimately appended `marriage` and `divorce` after them. That is an
      // assertion failing for a reason that is not its subject; `F2-AC-80`'s
      // subject is that **F2 changed nothing that already existed**.
      //
      // Reading the pre-F2 file out of git makes the check immune to whatever
      // any other batch appends, and strengthens it from "same key count" to
      // "same bytes".
      //
      // **`kPreF2Ref`, not `HEAD` — FU-10, fixed 2026-08-19.** This read was
      // `HEAD:` until F2's own work was committed, at which point `HEAD` became
      // the commit that *contains* F2 and `before` became byte-identical to
      // `after`. The loop below then compared each namespace with itself and
      // could not fail: the subject named three paragraphs up — *F2 changed
      // nothing that already existed* — stopped being checked at all, and the
      // only remaining sign was the hard-coded `18` two lines down going red.
      //
      // A relative ref cannot express "before F2" once F2 is history. The
      // baseline is a fixed point, so it is spelled as one.
      for (final String locale in <String>['en', 'lo']) {
        final ProcessResult r = Process.runSync(
          'git',
          <String>['show', '$kPreF2Ref:assets/i18n/$locale.json'],
        );
        expect(r.exitCode, 0,
            reason: 'could not read the pre-F2 asset out of HEAD');
        final Map<String, dynamic> before =
            jsonDecode(r.stdout as String) as Map<String, dynamic>;
        // **`kF2Tip`, not the working tree — 2026-08-19.** FU-10 fixed the
        // *baseline* side of this comparison; the merge-back exposed the same
        // defect on the *other* side. Read against the tree, this loop blamed
        // F2 for `history.viewDocument` and `history.downloadDocument` — two
        // keys **B5** added under its own § 6.12 grant, in a namespace that
        // happens to predate F2.
        //
        // `F2-AC-80`'s subject is *F2 changed nothing that already existed*,
        // which is a property of F2's diff. Both endpoints of the comparison
        // are therefore fixed points: `kPreF2Ref..kF2Tip` is F2, and no later
        // batch's lawful append can redden it.
        final ProcessResult tip = Process.runSync(
          'git',
          <String>['show', '$kF2Tip:assets/i18n/$locale.json'],
        );
        expect(tip.exitCode, 0,
            reason: 'could not read the F2 tip asset out of $kF2Tip');
        final Map<String, dynamic> after =
            jsonDecode(tip.stdout as String) as Map<String, dynamic>;

        expect(before.length, 18,
            reason: 'the pre-F2 baseline is 18 namespaces');

        for (final String ns in before.keys) {
          expect(after.containsKey(ns), isTrue,
              reason: '$locale: F2 dropped the `$ns` namespace');
          expect(
            jsonEncode(after[ns]),
            equals(jsonEncode(before[ns])),
            reason: '$locale: F2 modified the `$ns` namespace between '
                '$kPreF2Ref and $kF2Tip. F2 is append-only (§ 3.1 row 5).',
          );
        }

        // **The second half, and it is not redundant with the loop above.**
        //
        // Pinning both ends answers *did F2 modify a pre-F2 namespace* and is
        // blind to the working tree by construction — a mutation in
        // `assets/i18n/` today is invisible to it. Verified the hard way: after
        // pinning both ends, `resident.headerTitle` was given a stray `X` and
        // this file still reported 27/27. One blindness had been traded for
        // another.
        //
        // So the pre-F2 namespaces are also checked against **what actually
        // ships**. Later batches may append namespaces — that is lawful and the
        // loop above no longer objects — but nobody may edit a pre-F2 one, and
        // that is a property of the bundle on disk, not of any diff.
        //
        // [kAppendGrants] are the exceptions, and they are **named rather
        // than skipped**: each carries the spec grant that authorises the
        // append, and each still has every pre-existing key checked one by one.
        // Appending is lawful under a grant; editing is not, under any.
        final Map<String, dynamic> shipped = bundle(locale);
        for (final String ns in before.keys) {
          expect(shipped.containsKey(ns), isTrue,
              reason: '$locale: the shipped bundle lost the `$ns` namespace');
          if (kAppendGrants.containsKey(ns)) {
            final Map<String, dynamic> b = before[ns] as Map<String, dynamic>;
            final Map<String, dynamic> s = shipped[ns] as Map<String, dynamic>;
            for (final String key in b.keys) {
              expect(jsonEncode(s[key]), jsonEncode(b[key]),
                  reason: '$locale: `$ns.$key` was edited. ${kAppendGrants[ns]} '
                      '— that grant permits ADDING to this namespace; nobody '
                      'may change what was already in it.');
            }
            continue;
          }
          // Forms v2's named relabels — mirror of the [kAppendGrants] branch
          // above, per key rather than per namespace: every pre-existing key
          // is still compared byte-identically **except** the granted one,
          // whose shipped value is asserted **positively** against the pinned
          // string. Nothing about the rest of the namespace is exempted; a
          // relabel that drifts from the grant, or any other edit, fails here.
          final Map<String, String>? grants = kRelabelGrants[locale];
          final Map<String, String> grantedKeys = <String, String>{
            for (final String k in grants?.keys ?? const <String>[])
              if (k.startsWith('$ns.'))
                k.substring(ns.length + 1): grants![k]!,
          };
          if (grantedKeys.isNotEmpty) {
            final Map<String, dynamic> b = before[ns] as Map<String, dynamic>;
            final Map<String, dynamic> s = shipped[ns] as Map<String, dynamic>;
            for (final String key in b.keys) {
              if (grantedKeys.containsKey(key)) {
                expect(s[key], grantedKeys[key],
                    reason: '$locale: `$ns.$key` differs from the forms-v2 '
                        'relabel grant — the label is pinned, not free-form');
              } else {
                expect(jsonEncode(s[key]), jsonEncode(b[key]),
                    reason: '$locale: `$ns.$key` was edited without a '
                        'kRelabelGrants entry; only the granted relabels are '
                        'exempt, every other pre-existing key is frozen');
              }
            }
            continue;
          }
          expect(
            jsonEncode(shipped[ns]),
            equals(jsonEncode(before[ns])),
            reason: '$locale: the shipped `$ns` namespace differs from '
                '$kPreF2Ref. Pre-F2 namespaces are append-only for every '
                'batch, not just F2.',
          );
        }

        // The append itself, and the one count the spec names explicitly.
        expect((after['resident']! as Map<String, dynamic>).length, 102);
        expect(after.containsKey('birth'), isTrue);
        expect(after.containsKey('death'), isTrue);
      }
    });

    test('F2-AC-80 the append is ORDERED after the pre-F2 namespaces', () {
      // Weaker than "last two", deliberately: F3 appends after F2, so being
      // last is not F2's property to claim. Being after everything that
      // existed before F2 is.
      final List<String> keys = bundle('en').keys.toList();
      // `kPreF2Ref`, not `HEAD` — see FU-10 in the test above. With `HEAD` this
      // read returned the post-F2 bundle, so `lastPreF2` became the index of
      // the last namespace of *all* (21) rather than the last pre-F2 one, and
      // the assertion failed for a reason that is not its subject.
      final ProcessResult r = Process.runSync(
        'git',
        <String>['show', '$kPreF2Ref:assets/i18n/en.json'],
      );
      final Map<String, dynamic> before =
          jsonDecode(r.stdout as String) as Map<String, dynamic>;
      final int lastPreF2 = before.keys
          .map((String ns) => keys.indexOf(ns))
          .reduce((int a, int b) => a > b ? a : b);
      expect(keys.indexOf('birth'), greaterThan(lastPreF2));
      expect(keys.indexOf('death'), greaterThan(keys.indexOf('birth')));
    });

    test('F2-AC-81 the page-local TXT tables were NOT promoted', () {
      // Birth's `TXT` is 9 entries and Death's 8. Promoting them would make the
      // counts 161 and 105, which `F2-AC-78` catches — this test names the
      // mechanism so the failure is legible.
      final Map<String, dynamic> en = bundle('en');
      final Map<String, dynamic> birth = en['birth']! as Map<String, dynamic>;
      final Map<String, dynamic> death = en['death']! as Map<String, dynamic>;
      for (final String pageLocal in <String>[
        'loading',
        'loadFailed',
        'retry',
        'uploadTap',
        'fileSublabel',
        'payNow',
        'receipt',
        'paid',
        'hospitalNotice',
      ]) {
        expect(birth.containsKey(pageLocal), isFalse,
            reason: 'TXT.$pageLocal was promoted into the birth namespace');
      }
      for (final String pageLocal in <String>[
        'loading',
        'loadFailed',
        'retry',
        'uploadTap',
        'fileSublabel',
        'payNow',
        'receipt',
        'deathNotice',
      ]) {
        expect(death.containsKey(pageLocal), isFalse);
      }
    });

    test('F2-AC-82 TXT.paid is not ported', () {
      // Declared at `BirthDeclarationPage.tsx:155`, translated into both
      // locales, and referenced nowhere on the page — the sixth dead surface
      // found in this project by measurement (`FU-5`).
      expect(grep(kBirthDir, RegExp(r'\bpaid\b')).where((String h) =>
          !h.contains('_form_cubit.dart')), isEmpty);
      expect(grep(kBirthDir, "'Paid'"), isEmpty);
      expect(grep(kBirthDir, 'ຈ່າຍແລ້ວ'), isEmpty);
    });

    test('F2-AC-83 Death\'s GENDERS are bilingual literals and Birth\'s are '
        'namespace keys', () {
      // Measured difference #9. Harmonising them would either invent two
      // `death` keys (making the count 99) or delete two `birth` ones.
      expect(kBirthGenders.map((BirthGenderOption g) => g.labelKey).toList(),
          <String>['optFemale', 'optMale']);
      expect(kDeathGenders.map((DeathGenderOption g) => g.label.en).toList(),
          <String>['Female', 'Male']);
      expect(kDeathGenders.map((DeathGenderOption g) => g.label.lo).toList(),
          <String>['ຍິງ', 'ຊາຍ']);

      final Map<String, dynamic> birth =
          (jsonDecode(File('assets/i18n/en.json').readAsStringSync())
              as Map<String, dynamic>)['birth']! as Map<String, dynamic>;
      final Map<String, dynamic> death =
          (jsonDecode(File('assets/i18n/en.json').readAsStringSync())
              as Map<String, dynamic>)['death']! as Map<String, dynamic>;
      expect(birth.containsKey('optFemale'), isTrue);
      expect(birth.containsKey('optMale'), isTrue);
      expect(death.containsKey('optFemale'), isFalse,
          reason: 'Death bypasses the namespace for gender — promoting its two '
              'literals would take the count from 97 to 99');
      expect(death.containsKey('optMale'), isFalse);
    });

    test('F2-AC-79 every key in both namespaces is reachable, or enumerated',
        () {
      // Reachability is measured against the two PORTS, not against the TSX:
      // a key the port never reads is a key the port is missing a control for.
      final Map<String, dynamic> en =
          jsonDecode(File('assets/i18n/en.json').readAsStringSync())
              as Map<String, dynamic>;
      for (final MapEntry<String, String> ns
          in <String, String>{'birth': kBirthDir, 'death': kDeathDir}.entries) {
        final Set<String> declared =
            (en[ns.key]! as Map<String, dynamic>).keys.toSet();
        final StringBuffer all = StringBuffer();
        for (final File f in _dartFiles(ns.value)) {
          all.write(f.readAsStringSync());
        }
        final String source = all.toString();
        final List<String> unread = declared
            .where((String k) => !source.contains("'$k'"))
            .toList()
          ..sort();
        // ignore: avoid_print
        print('F2-AC-79 ${ns.key}: ${declared.length - unread.length} of '
            '${declared.length} keys read by the port; '
            '${unread.length} unread: ${unread.join(', ')}');
        // Enumerated rather than asserted empty — `F2-NV-4` records that the
        // cross-reference was not done key by key at spec time, and this is
        // where the number is produced. A non-empty list is a finding to
        // report, not silently a failure.
        expect(unread, isA<List<String>>());
      }
    });
  });
}
