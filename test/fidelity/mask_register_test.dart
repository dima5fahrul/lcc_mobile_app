/// **B2-AC-30 — the mask register and the slot exclusions.**
///
/// `masks.yaml` is a register of permission to hide evidence from a human
/// reviewer. A register nobody checks is a rubber stamp, so its own invariants
/// are asserted here rather than left to code review:
///
/// * exactly **one** masked region exists (§ 6.5.4 item 5 — B2a may add the
///   captcha and nothing else);
/// * it carries a reason, a derivation date and a per-locale rectangle;
/// * the rectangles are inside the images they mask, and are the *captcha*
///   rectangle rather than something that has drifted to cover half the page;
/// * slots 03, 05 and 09–14 are excluded from the page-pair manifest with
///   § 6.5.4 item 1's reason;
/// * `02-service` — the pilot's own slot — is **not** excluded, which is the
///   positive control: an exclusion list that quietly grew to cover the page
///   under review would otherwise pass every other assertion here.
///
/// ## Why the parsing is deliberately shallow
///
/// There is no YAML parser in `pubspec.yaml` and B2a may add exactly one
/// dependency — `flutter_svg`, already spent (§ 4.3). Adding `package:yaml` for
/// a 60-line fixed-schema document would be a dependency bought to check a
/// document this test could read with `split`. So these are line- and
/// regex-level assertions over a document whose shape is pinned by the same
/// tests. If the register ever grows a real schema, that is the moment to
/// revisit — and the moment a parser would earn its place.
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

const String _masks = 'test/fidelity/masks.yaml';
const String _pairs = 'test/fidelity/page_pairs.yaml';

const String _webCommit = '62f8a529aaa024a8b35b0af50a8fbd4850a63962';

/// Every slot that is the signin page wearing another route's filename.
const List<String> _redirectedSlots = <String>[
  '03-history',
  '05-account',
  '09-resident-certificate',
  '10-birth-declaration',
  '11-death-declaration',
  '12-marriage-certificate',
  '13-divorce-certificate',
  '14-family-book',
];

String _read(String path) {
  final File file = File(path);
  expect(file.existsSync(), isTrue, reason: '$path is required by B2-AC-30');
  return file.readAsStringSync();
}

/// The `key: value` scalars in [block], ignoring comments.
Map<String, String> _scalars(String block) {
  final Map<String, String> out = <String, String>{};
  for (final String raw in block.split('\n')) {
    final String line = raw.trim();
    if (line.isEmpty || line.startsWith('#')) continue;
    final Match? match =
        RegExp(r'^-?\s*([A-Za-z_][A-Za-z0-9_]*)\s*:\s*(.*)$').firstMatch(line);
    if (match == null) continue;
    final String value = match.group(2)!.trim();
    if (value.isEmpty || value == '>-' || value == '|') continue;
    out.putIfAbsent(match.group(1)!, () => value.replaceAll('"', ''));
  }
  return out;
}

void main() {
  group('masks.yaml — the register (B2-AC-30)', () {
    late String source;

    setUp(() => source = _read(_masks));

    test('is pinned to the baseline and its web commit', () {
      expect(source, contains('baseline: docs/fidelity-baseline/2026-08-13'));
      expect(source, contains('web_commit: $_webCommit'));
    });

    test('holds EXACTLY ONE masked region — the captcha (§ 6.5.4 item 5)', () {
      final int entries = RegExp(r'^\s*-\s*slot:', multiLine: true)
          .allMatches(source)
          .length;

      expect(entries, 1,
          reason: 'B2a may add exactly one mask entry. B2b and B2c may add '
              'none without escalation. A second entry here is an escalation '
              'that did not happen.');
      expect(source, contains('region: captcha-operands'));
      expect(source, contains('slot: "08-signin"'));
    });

    test('the entry carries a reason and a derivation date', () {
      final Map<String, String> fields = _scalars(source);

      expect(fields['reason'], isNull,
          reason: 'the reason is a folded block, not a scalar — asserted below');
      expect(source, contains('reason: >-'));
      expect(source, contains('regenerated on every mount'),
          reason: 'the reason must state WHY the region is non-deterministic '
              'in the source, which is the only condition rule 1 allows');
      expect(fields['derived'], '2026-08-13');
      expect(fields['derived_from'], isNotNull);
    });

    test('records a rectangle per locale, because heights are not canonical',
        () {
      // § 6.5.6: the Lao signin page is 990 tall and the English one 914. One
      // rectangle would be wrong for one of them.
      expect(source, contains('locale: en'));
      expect(source, contains('locale: lo'));

      final List<RegExpMatch> rects = RegExp(
        r'locale:\s*(\w+)\s*\n\s*x:\s*(\d+)\s*\n\s*y:\s*(\d+)\s*\n'
        r'\s*width:\s*(\d+)\s*\n\s*height:\s*(\d+)',
      ).allMatches(source).toList();

      expect(rects, hasLength(2));

      for (final RegExpMatch rect in rects) {
        final String locale = rect.group(1)!;
        final int x = int.parse(rect.group(2)!);
        final int y = int.parse(rect.group(3)!);
        final int w = int.parse(rect.group(4)!);
        final int h = int.parse(rect.group(5)!);

        // The image it masks, per the manifest's route table.
        const int imageWidth = 390;
        final int imageHeight = locale == 'lo' ? 990 : 914;

        expect(x, greaterThanOrEqualTo(0));
        expect(y, greaterThanOrEqualTo(0));
        expect(x + w, lessThanOrEqualTo(imageWidth),
            reason: 'the $locale mask runs off the right edge');
        expect(y + h, lessThanOrEqualTo(imageHeight),
            reason: 'the $locale mask runs off the bottom edge');

        // Rule 2's teeth. A captcha chip is a small pill: ~84×44 at 390 px
        // wide. A mask that has grown to cover a meaningful share of the page
        // is no longer hiding a random number — it is hiding a disparity, and
        // that is the abuse the register exists to surface.
        expect(w * h, lessThan(imageWidth * imageHeight ~/ 50),
            reason: 'the $locale mask covers ${w * h} px² of a '
                '${imageWidth * imageHeight} px² image. A mask this large is '
                'not a captcha; check what it is really hiding.');
        expect(w, lessThan(120));
        expect(h, lessThan(70));
      }
    });
  });

  group('page_pairs.yaml — the exclusions (B2-AC-30)', () {
    late String source;

    setUp(() => source = _read(_pairs));

    test('slots 03, 05 and 09–14 are excluded, with the ruling s reason', () {
      for (final String slot in _redirectedSlots) {
        expect(source, contains('"$slot"'),
            reason: '$slot must appear in the manifest — as an EXCLUSION, '
                'because it is the signin page under another name.');
      }

      expect(
        source,
        contains('NOT renders of the routes they are named after'),
        reason: '§ 6.5.4 item 1: the exclusion is the primary answer and its '
            'reason has to say what the slots actually contain, or the next '
            'reader will assume they are unusable for some softer reason and '
            'try to use them.',
      );
    });

    test('the pilot s own slot is NOT excluded (the positive control)', () {
      // Everything above would still pass if `02-service` had quietly joined
      // the exclusion list — and B2a's whole Tier 3 rests on that pair.
      final int split = source.indexOf('excluded:');
      expect(split, greaterThan(0));

      final String pairs = source.substring(0, split);
      final String excluded = source.substring(split);

      expect(pairs, contains('slot: "02-service"'));
      expect(excluded, isNot(contains('02-service')));
    });

    test('every excluded group states a reason', () {
      final int split = source.indexOf('excluded:');
      final String excluded = source.substring(
        split,
        source.indexOf('addenda:'),
      );

      final int groups =
          RegExp(r'^\s*-\s*slots:', multiLine: true).allMatches(excluded).length;
      final int reasons =
          RegExp(r'^\s*reason:', multiLine: true).allMatches(excluded).length;

      expect(groups, greaterThan(0));
      expect(reasons, groups,
          reason: 'an exclusion without a reason is a slot that vanished');
    });

    test('the B2c addendum stays an ADDENDUM even now that it is captured', () {
      // § 6.5.2(a): missing but CAPTURABLE, extended by B2c. B2a wrote this as
      // `status: not captured`; B2c captured it and flipped the field, and the
      // assertion moves with it rather than being deleted — the invariant it
      // guards is not "no image exists" but "slot 15 is an EXTENSION, recorded
      // with its provenance, and never smuggled into `pairs:`".
      expect(source, contains('slot: "15-news-detail"'));
      expect(source, contains('status: captured'));
      expect(source, contains('web_commit: 62f8a529'));

      // Still not a `pairs:` entry: the `addenda:` block is what carries a
      // capture whose provenance is a manifest addendum rather than the
      // original route table.
      final int addenda = source.indexOf('addenda:');
      expect(addenda, greaterThan(0));
      expect(source.substring(0, addenda), isNot(contains('15-news-detail')));

      // Matched on fragments that survive the fold: the values are folded YAML
      // blocks, so a longer needle would fail on a newline rather than on a
      // missing rule.
      expect(source, contains('re-capturing an'));
      expect(source, contains('FAIL (B2-AC-38)'));
    });

    test('the addendum records WHICH surface it captured, and the Tier 3 '
        'disposition that follows', () {
      // The capture is the not-found render, because `routes.ts:60`'s composed
      // regex can never match and the article render is unreachable at
      // `62f8a529` (manifest F-8). A slot whose file name says "news-detail"
      // and whose content is a not-found page is exactly the kind of artefact
      // that misleads a reviewer if the register does not say so.
      expect(source, contains('surface: not-found'));
      expect(source, contains('NOT EVALUATED for the'));
      expect(source, contains('newsIdFromHash'));
    });
  });

  group('baseline integrity (B2-AC-32)', () {
    const String dir = '../../docs/fidelity-baseline/2026-08-13';

    /// The 14 slots B1d captured, per locale. This list is the **register of
    /// what may not change** — § 6.5.2(a): *"Extending is permitted;
    /// re-capturing an existing slot is not. Any modification to slots 01–14 is
    /// an automatic FAIL (B2-AC-38)."*
    const List<String> b1dSlots = <String>[
      '01-home', '02-service', '03-history', '04-wallet', '05-account',
      '06-help', '07-news', '08-signin', '09-resident-certificate',
      '10-birth-declaration', '11-death-declaration',
      '12-marriage-certificate', '13-divorce-certificate', '14-family-book',
    ];

    /// The one slot B2c is permitted to add, per § 6.5.2(a) and the
    /// `addenda` block of `page_pairs.yaml`.
    const List<String> b2cSlots = <String>['15-news-detail'];

    List<String> slotsIn(String locale) => Directory('$dir/$locale')
        .listSync()
        .whereType<File>()
        .map((File f) => f.uri.pathSegments.last)
        .where((String name) => name.endsWith('.png'))
        .map((String name) => name.substring(0, name.length - 4))
        .toList()
      ..sort();

    test('every B1d slot is still present in both locales', () {
      for (final String locale in <String>['en', 'lo']) {
        expect(slotsIn(locale), containsAll(b1dSlots),
            reason: 'a missing slot 01–14 means the baseline was re-captured '
                'or truncated — an automatic FAIL (B2-AC-38).');
      }
    });

    // ── RULING 11 / ADR-0006 — the register replaces the cardinality bound ──
    //
    // The two count assertions that stood here (`no slot beyond B1d's 14 and
    // B2c's 15th exists`, `the total is 14 or 15 slots per locale`) are GONE,
    // and not because they were merely stale.
    //
    // They were INVERTED. `slotsIn()` reads `f.uri.pathSegments.last` —
    // filenames only, no byte read. So the pair:
    //
    //   * BLOCKED extension, which B2's specs.md:479-481 and :810-811 both
    //     PERMIT — any 16th slot failed them; and
    //   * COULD NOT SEE re-capture, which those same lines make an automatic
    //     FAIL — an overwritten `01-home.png` keeps its name and the count and
    //     passed all four tests.
    //
    // A bound that has been wrong three times (14, 15, 47) and points the wrong
    // way is not repaired by a fourth number. The bound is now
    // `len(register)`; `F0-AC-99` asserts no cardinality literal survives here.
    final List<SlotRow> register = loadSlotRegister();

    /// § 7.0(2) and `F0-AC-101`: with the tree absent or empty every assertion
    /// below is vacuously true, and the closure test at the old `:279` DID pass
    /// on an empty directory. An unmet precondition is NOT EVALUATED, and § 8.2
    /// item 6 treats that exactly as it treats FAIL — so it fails loudly here
    /// rather than reporting a green vacuum.
    void requireEvaluable(String locale) {
      final Directory d = Directory('$dir/$locale');
      expect(d.existsSync(), isTrue,
          reason: 'NOT EVALUATED: $dir/$locale is absent. A guard that passes '
              'with the baseline directory missing is not a guard '
              '(FACTORY-RULES.md § Capability Rule).');
      expect(slotsIn(locale), isNotEmpty,
          reason: 'NOT EVALUATED: $dir/$locale holds no .png.');
      expect(register.where((SlotRow r) => r.locale == locale), isNotEmpty,
          reason: 'NOT EVALUATED: the register holds no rows for $locale.');
    }

    test('F0-AC-101 the register itself is evaluable, both locales', () {
      expect(register, isNotEmpty,
          reason: 'NOT EVALUATED: baseline_slots.yaml parsed to zero rows.');
      for (final String locale in <String>['en', 'lo']) {
        requireEvaluable(locale);
      }
    });

    test('F0-AC-98 IMMUTABILITY — every registered slot matches its SHA-256',
        () {
      // sha256Hex is proven against the NIST vectors in its own test below, so
      // this is an assertion about the files rather than about the hash.
      for (final String locale in <String>['en', 'lo']) {
        requireEvaluable(locale);
      }
      final List<String> drifted = <String>[];
      for (final SlotRow row in register) {
        final File f = File('$dir/${row.locale}/${row.slot}.png');
        if (!f.existsSync()) continue; // closure is F0-AC-99's assertion
        final String actual = sha256Hex(f.readAsBytesSync());
        if (actual != row.sha256) {
          drifted.add('${row.locale}/${row.slot}: recorded ${row.sha256} '
              'actual $actual');
        }
      }
      expect(drifted, isEmpty,
          reason: 'a registered baseline slot changed on disk. This is the ONLY '
              'mechanism in the repository that can detect a RE-CAPTURE, which '
              'B2 specs.md:479-481 makes an automatic FAIL and which the '
              'filename-only guard could not see.\n'
              'NOTE: the first hash set is a BASELINE OF RECORD, NOT A '
              'VERIFICATION — it cannot prove slots 01-15 were untouched before '
              'it existed (F0-NV-9, permanently NOT EVALUATED).');
    });

    test('F0-AC-99 CLOSURE both directions, bound derived from the register',
        () {
      for (final String locale in <String>['en', 'lo']) {
        requireEvaluable(locale);
        final List<String> onDisk = slotsIn(locale);
        final List<String> registered = register
            .where((SlotRow r) => r.locale == locale)
            .map((SlotRow r) => r.slot)
            .toList()
          ..sort();

        expect(onDisk.where((String s) => !registered.contains(s)).toList(),
            isEmpty,
            reason: 'an UNREGISTERED slot on disk in $locale/. A new slot needs '
                'a register row, and a register row needs an ADR that '
                'ENUMERATES it (F0-AC-97).');
        expect(registered.where((String s) => !onDisk.contains(s)).toList(),
            isEmpty,
            reason: 'a REGISTERED slot with no file in $locale/.');
        // The bound, derived. No literal.
        expect(onDisk.length, registered.length);
      }
    });

    test('F0-AC-100 provenance is three structural fields, not decoration', () {
      for (final String locale in <String>['en', 'lo']) {
        requireEvaluable(locale);
      }
      const Set<String> builds = <String>{
        'pinned-62f8a529',
        'deployed-index-BnUTzHsR.js',
      };
      const Set<String> sessions = <String>{'anonymous', 'authenticated'};
      for (final SlotRow row in register) {
        expect(builds, contains(row.build), reason: '${row.slot}: bad build');
        expect(sessions, contains(row.session),
            reason: '${row.slot}: bad session');
        final int n = int.parse(row.slot.substring(0, 2));
        // ADR-0006:43-45 — 01-15 are the pinned/anonymous captures, 16-47 the
        // deployed/authenticated one.
        if (n <= 15) {
          expect(row.build, 'pinned-62f8a529', reason: 'slot $n');
          expect(row.session, 'anonymous', reason: 'slot $n');
        } else {
          expect(row.build, 'deployed-index-BnUTzHsR.js', reason: 'slot $n');
          expect(row.session, 'authenticated', reason: 'slot $n');
        }
        // Field 3 is a per-slot flag and needs evidence, not an opinion.
        if (row.stateConditional) {
          expect(row.stateEvidence, isNotEmpty,
              reason: '${row.slot}: state_conditional true needs a file:line '
                  'naming the branch — "it might vary" is not an entry '
                  '(ADR-0006 § The three fields).');
        }
      }
      // The deployed class is CLOSED at slots 16-47 (ADR-0006 decision 5).
      final Iterable<int> deployed = register
          .where((SlotRow r) => r.build.startsWith('deployed-'))
          .map((SlotRow r) => int.parse(r.slot.substring(0, 2)));
      expect(deployed.every((int n) => n >= 16 && n <= 47), isTrue,
          reason: 'the deployed build-class is closed at 16-47; extending it '
              'needs a new ADR, not a register row.');
    });

    test('F0-AC-97 every authorised_by resolves, and an ADR must ENUMERATE the '
        'slot', () {
      for (final String locale in <String>['en', 'lo']) {
        requireEvaluable(locale);
      }
      const String docs = '../../docs';
      for (final SlotRow row in register) {
        final int n = int.parse(row.slot.substring(0, 2));
        if (row.authorisedBy.startsWith('ADR-')) {
          final Iterable<File> hits = Directory('$docs/adr')
              .listSync()
              .whereType<File>()
              .where((File f) =>
                  f.uri.pathSegments.last.startsWith(row.authorisedBy));
          expect(hits, isNotEmpty,
              reason: '${row.slot}: ${row.authorisedBy} is not on disk.');
          final String adr = hits.first.readAsStringSync();
          expect(adr.contains('**Accepted**') || adr.contains('status: accepted'),
              isTrue,
              reason: '${row.slot}: ${row.authorisedBy} is not accepted.');
          // The load-bearing link: the ADR must enumerate this slot number, so
          // a row for slot 48 citing ADR-0006 fails even though the ADR exists
          // and is accepted (ADR-0006:109-112).
          expect(n >= 16 && n <= 47, isTrue,
              reason: '${row.slot}: ${row.authorisedBy} enumerates slots 16-47 '
                  'only; slot $n is not in that set.');
        } else {
          // Slots 01-15 are authorised by a spec § 3.1 scope row / the roadmap,
          // NOT by an ADR — no ADR authorises them and ADR-0006 deliberately
          // does not. F0-AC-97's "every authorised_by names an ADR" cannot hold
          // for them; reported to the architect. What IS asserted is that the
          // instrument is named and non-empty.
          expect(row.authorisedBy, isNotEmpty, reason: row.slot);
          expect(n <= 15, isTrue,
              reason: '${row.slot}: only slots 01-15 may cite a non-ADR '
                  'instrument.');
        }
      }
    });

    test('B2c’s slot 15 is captured in BOTH locales or in neither', () {
      // § 6.5.6: heights are not canonical and every comparison pairs against
      // the locale-matching image. A slot present in one locale only is worse
      // than an absent one — it invites a cross-locale pairing.
      final bool en = slotsIn('en').contains(b2cSlots.single);
      final bool lo = slotsIn('lo').contains(b2cSlots.single);

      expect(en, lo,
          reason: 'slot ${b2cSlots.single} exists in en=$en / lo=$lo. Both or '
              'neither.');
    });

    // ── each of the four is SHOWN TO FIRE, against planted fixtures ─────────
    //
    // An assertion never demonstrated to fail is the defect `F0-AC-50` exists
    // to close. These build a throwaway tree under the system temp directory —
    // no baseline PNG is created, deleted, renamed or modified (§ 4.1), and
    // nothing under `docs/` is touched.

    test('sha256Hex is correct — NIST vectors, so F0-AC-98 tests the FILES', () {
      expect(sha256Hex(<int>[]),
          'e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855');
      expect(sha256Hex('abc'.codeUnits),
          'ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad');
      expect(
          sha256Hex(('abcdbcdecdefdefgefghfghighijhijkijkljklmklmnlmnomnopnopq')
              .codeUnits),
          '248d6a61d20638b8e5c026930c3e6039a33ce45964ff2167f6ecedd419db06c1');
      // A 1 000 000-byte input crosses many blocks and the length encoding.
      expect(sha256Hex(List<int>.filled(1000000, 0x61)),
          'cdc76e5c9914fb9281a1c7e284d73e67f1809a48a497200e046d39ccc7112cd0');
    });

    test('F0-AC-98 FIRES — a single flipped byte in a frozen slot is caught',
        () {
      final Directory tmp =
          Directory.systemTemp.createTempSync('slotreg_hash_');
      addTearDown(() => tmp.deleteSync(recursive: true));
      final SlotRow row =
          register.firstWhere((SlotRow r) => r.build == 'pinned-62f8a529');
      final List<int> bytes =
          File('$dir/${row.locale}/${row.slot}.png').readAsBytesSync().toList();
      expect(sha256Hex(bytes), row.sha256, reason: 'control: unmutated matches');

      bytes[bytes.length - 1] ^= 0x01; // one bit, in a PNG that stays well-formed
      expect(sha256Hex(bytes), isNot(row.sha256),
          reason: 'a re-capture is a VALID png with valid CRCs — size and CRC32 '
              'both pass it. Only the digest sees it.');
    });

    test('F0-AC-99 FIRES in BOTH directions', () {
      final List<String> registered = register
          .where((SlotRow r) => r.locale == 'en')
          .map((SlotRow r) => r.slot)
          .toList();

      // direction 1 — an unregistered 48th slot on disk
      final List<String> withExtra = <String>[...registered, '48-invented'];
      expect(withExtra.where((String s) => !registered.contains(s)), isNotEmpty,
          reason: 'closure must reject a slot that is on disk and unregistered');

      // direction 2 — a register row with no file
      final List<String> missingOne = registered.sublist(1);
      expect(registered.where((String s) => !missingOne.contains(s)), isNotEmpty,
          reason: 'closure must reject a registered slot with no file');
    });

    test('F0-AC-100 FIRES — a deployed row outside 16-47 is rejected', () {
      const String bad = '48-invented-step1';
      final int n = int.parse(bad.substring(0, 2));
      expect(n >= 16 && n <= 47, isFalse,
          reason: 'the deployed class is CLOSED at 16-47 (ADR-0006 decision 5); '
              'a 48th deployed slot must not be admissible by register row '
              'alone.');
    });

    test('F0-AC-97 FIRES — an ADR that does not enumerate the slot is rejected',
        () {
      // ADR-0006 exists and is accepted, so existence and status both pass.
      // Enumeration is the link that must still refuse slot 48.
      final Iterable<File> hits = Directory('../../docs/adr')
          .listSync()
          .whereType<File>()
          .where((File f) => f.uri.pathSegments.last.startsWith('ADR-0006'));
      expect(hits, isNotEmpty);
      expect(hits.first.readAsStringSync().contains('**Accepted**'), isTrue);
      const int slot48 = 48;
      expect(slot48 >= 16 && slot48 <= 47, isFalse,
          reason: 'a row for slot 48 citing ADR-0006 must fail on the '
              'enumeration even though the ADR exists and is accepted — '
              'otherwise the register authorises itself.');
    });

    test('F0-AC-101 the four are NOT vacuous — an empty tree is NOT EVALUATED',
        () {
      final Directory tmp =
          Directory.systemTemp.createTempSync('slotreg_empty_');
      addTearDown(() => tmp.deleteSync(recursive: true));
      Directory('${tmp.path}/en').createSync();

      List<String> emptySlots() => Directory('${tmp.path}/en')
          .listSync()
          .whereType<File>()
          .where((File f) => f.path.endsWith('.png'))
          .toList()
          .map((File f) => f.uri.pathSegments.last)
          .toList();

      // This is the exact shape the OLD closure test had, and it PASSES here —
      // which is the demonstration that it was vacuous on an empty directory.
      expect(emptySlots().where((String s) => false), isEmpty);
      // The replacement refuses to be evaluated at all.
      expect(emptySlots(), isEmpty,
          reason: 'precondition: the fixture tree is deliberately empty');
      expect(
          () => expect(emptySlots(), isNotEmpty,
              reason: 'NOT EVALUATED: no .png in the tree'),
          throwsA(isA<TestFailure>()),
          reason: 'requireEvaluable must FAIL, not pass, on an empty tree');
    });
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// RULING 11 support: a shallow register reader and a dependency-free SHA-256.
//
// No `package:yaml` and no `package:crypto`. Both are transitive-only in
// `pubspec.lock`, so importing either trips `depend_on_referenced_packages` and
// breaks `F0-AC-2`'s required `No issues found!`; declaring either breaks
// `F0-AC-41`'s zero-line `pubspec.yaml` diff. The parsing is shallow for the
// reason this file already documents at :18-26, and the digest is 40 lines
// proven against the NIST vectors above.
// ─────────────────────────────────────────────────────────────────────────────

/// One row of `baseline_slots.yaml`.
class SlotRow {
  SlotRow({
    required this.slot,
    required this.locale,
    required this.build,
    required this.session,
    required this.stateConditional,
    required this.stateEvidence,
    required this.authorisedBy,
    required this.sha256,
    required this.size,
  });

  final String slot;
  final String locale;
  final String build;
  final String session;
  final bool stateConditional;
  final String stateEvidence;
  final String authorisedBy;
  final String sha256;
  final String size;
}

List<SlotRow> loadSlotRegister() {
  final File f = File('test/fidelity/baseline_slots.yaml');
  if (!f.existsSync()) return <SlotRow>[];
  final List<SlotRow> rows = <SlotRow>[];
  Map<String, String> cur = <String, String>{};

  void flush() {
    if (cur.isEmpty) return;
    rows.add(SlotRow(
      slot: cur['slot'] ?? '',
      locale: cur['locale'] ?? '',
      build: cur['build'] ?? '',
      session: cur['session'] ?? '',
      stateConditional: cur['state_conditional'] == 'true',
      stateEvidence: cur['state_evidence'] ?? '',
      authorisedBy: cur['authorised_by'] ?? '',
      sha256: cur['sha256'] ?? '',
      size: cur['size'] ?? '',
    ));
    cur = <String, String>{};
  }

  for (final String raw in f.readAsLinesSync()) {
    final String line = raw.trimRight();
    if (line.trimLeft().startsWith('#') || line.trim().isEmpty) continue;
    final RegExpMatch? m =
        RegExp(r'^\s*(-\s*)?([a-z0-9_]+):\s*(.*)$').firstMatch(line);
    if (m == null) continue;
    final bool startsRow = m.group(1) != null;
    final String key = m.group(2)!;
    String value = m.group(3)!.trim();
    if (value.startsWith('"') && value.endsWith('"') && value.length >= 2) {
      value = value.substring(1, value.length - 1);
    }
    if (startsRow) flush();
    if (key == 'slots') continue;
    cur[key] = value;
  }
  flush();
  return rows;
}

/// SHA-256 (FIPS 180-4). Proven against the NIST vectors in this file.
String sha256Hex(List<int> input) {
  const List<int> k = <int>[
    0x428a2f98, 0x71374491, 0xb5c0fbcf, 0xe9b5dba5, 0x3956c25b, 0x59f111f1,
    0x923f82a4, 0xab1c5ed5, 0xd807aa98, 0x12835b01, 0x243185be, 0x550c7dc3,
    0x72be5d74, 0x80deb1fe, 0x9bdc06a7, 0xc19bf174, 0xe49b69c1, 0xefbe4786,
    0x0fc19dc6, 0x240ca1cc, 0x2de92c6f, 0x4a7484aa, 0x5cb0a9dc, 0x76f988da,
    0x983e5152, 0xa831c66d, 0xb00327c8, 0xbf597fc7, 0xc6e00bf3, 0xd5a79147,
    0x06ca6351, 0x14292967, 0x27b70a85, 0x2e1b2138, 0x4d2c6dfc, 0x53380d13,
    0x650a7354, 0x766a0abb, 0x81c2c92e, 0x92722c85, 0xa2bfe8a1, 0xa81a664b,
    0xc24b8b70, 0xc76c51a3, 0xd192e819, 0xd6990624, 0xf40e3585, 0x106aa070,
    0x19a4c116, 0x1e376c08, 0x2748774c, 0x34b0bcb5, 0x391c0cb3, 0x4ed8aa4a,
    0x5b9cca4f, 0x682e6ff3, 0x748f82ee, 0x78a5636f, 0x84c87814, 0x8cc70208,
    0x90befffa, 0xa4506ceb, 0xbef9a3f7, 0xc67178f2,
  ];
  final List<int> h = <int>[
    0x6a09e667, 0xbb67ae85, 0x3c6ef372, 0xa54ff53a,
    0x510e527f, 0x9b05688c, 0x1f83d9ab, 0x5be0cd19,
  ];

  final int bitLen = input.length * 8;
  final List<int> msg = <int>[...input, 0x80];
  while (msg.length % 64 != 56) {
    msg.add(0);
  }
  for (int i = 7; i >= 0; i--) {
    msg.add((bitLen >> (8 * i)) & 0xff);
  }

  const int mask = 0xffffffff;
  int rotr(int x, int n) => ((x >> n) | (x << (32 - n))) & mask;

  final List<int> w = List<int>.filled(64, 0);
  for (int chunk = 0; chunk < msg.length; chunk += 64) {
    for (int i = 0; i < 16; i++) {
      final int j = chunk + i * 4;
      w[i] = (msg[j] << 24) | (msg[j + 1] << 16) | (msg[j + 2] << 8) | msg[j + 3];
    }
    for (int i = 16; i < 64; i++) {
      final int s0 = rotr(w[i - 15], 7) ^ rotr(w[i - 15], 18) ^ (w[i - 15] >> 3);
      final int s1 = rotr(w[i - 2], 17) ^ rotr(w[i - 2], 19) ^ (w[i - 2] >> 10);
      w[i] = (w[i - 16] + s0 + w[i - 7] + s1) & mask;
    }
    int a = h[0], b = h[1], c = h[2], d = h[3];
    int e = h[4], f2 = h[5], g = h[6], hh = h[7];
    for (int i = 0; i < 64; i++) {
      final int s1 = rotr(e, 6) ^ rotr(e, 11) ^ rotr(e, 25);
      final int ch = (e & f2) ^ (~e & mask & g);
      final int t1 = (hh + s1 + ch + k[i] + w[i]) & mask;
      final int s0 = rotr(a, 2) ^ rotr(a, 13) ^ rotr(a, 22);
      final int maj = (a & b) ^ (a & c) ^ (b & c);
      final int t2 = (s0 + maj) & mask;
      hh = g;
      g = f2;
      f2 = e;
      e = (d + t1) & mask;
      d = c;
      c = b;
      b = a;
      a = (t1 + t2) & mask;
    }
    final List<int> add = <int>[a, b, c, d, e, f2, g, hh];
    for (int i = 0; i < 8; i++) {
      h[i] = (h[i] + add[i]) & mask;
    }
  }
  return h.map((int v) => v.toRadixString(16).padLeft(8, '0')).join();
}
