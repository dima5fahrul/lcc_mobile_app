/// Tier 0 — payload equality. The blocking gate `ssd.md` § 14 F-6 ranks above
/// human review, and the one F0b and F1 are judged by.
///
/// ## What this file is, and what it is not
///
/// It is the **comparator and its negative controls**. The 22 value-bearing
/// oracle documents are produced by `derive_forms_oracles.py` (Entry B) and
/// `execute_forms_oracle.mjs` (Entry A); this harness consumes them when they
/// exist and, independently of them, proves it **can fail** — which is the
/// property `F0-AC-33` exists for and the reason § 8.1 lists it first.
///
/// ## Why the comparison is on BYTES and not on `Map` equality
///
/// `client.ts:241-242` is a bare `JSON.stringify(options.body)` and
/// `endpoints.ts:325` passes the body straight through. There is no schema, no
/// allowlist and no canonicaliser between the page's object literal and the
/// socket, so **insertion order IS wire order** — for the envelope exactly as
/// much as for `form_data` (Finding I). Dart map literals are insertion-ordered
/// `LinkedHashMap`s and `jsonEncode` walks that order, so a faithful
/// transcription serialises identically with no work. That is a property, not a
/// guarantee anyone maintains, so it is asserted directly: a
/// `DeepCollectionEquality` would pass a reordered transcription and this must
/// not.
///
/// ## The five mutants
///
/// M1 one character in a value · M2 two adjacent keys transposed · M3 an `lo`
/// payload in an `en` slot · M4 a non-Finding-E key localised (the COMPLEMENT
/// guard's control, without which that guard is vacuously true on an empty
/// oracle) · M5 a nested payload flattened to dotted keys (the control for
/// § 6.5.1's whole rewrite: `/header/document_no` and `/header.document_no`
/// decode to the same map and must not compare equal).
library;

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'oracle.dart';

import '../features/certificates/presentation/resident/resident_tier0_subject.dart';
import 'package:lcc_mobile_app/features/certificates/domain/submission/case_reference_binding.dart';
import 'package:lcc_mobile_app/features/certificates/domain/submission/submission_clock.dart';
import 'package:lcc_mobile_app/features/certificates/presentation/resident/resident_payload.dart';

// ─────────────────────────────────────────────────────────────────────────────
// The comparator
// ─────────────────────────────────────────────────────────────────────────────

/// Depth-first leaf paths, in emission order, as RFC 6901 JSON Pointers.
///
/// `~` -> `~0` and `/` -> `~1`. A literal `.` needs no escape and is therefore
/// PRESERVED — which is the whole point: Birth's literal flat key
/// `"header.document_no"` yields `/header.document_no`, Marriage's nested
/// `header` -> `document_no` yields `/header/document_no`, and the two are
/// different strings.
List<String> leafPaths(Object? node, [String prefix = '']) {
  if (node is Map) {
    final List<String> out = <String>[];
    node.forEach((Object? k, Object? v) {
      final String token =
          k.toString().replaceAll('~', '~0').replaceAll('/', '~1');
      out.addAll(leafPaths(v, '$prefix/$token'));
    });
    return out;
  }
  if (node is List) {
    final List<String> out = <String>[];
    for (int i = 0; i < node.length; i++) {
      out.addAll(leafPaths(node[i], '$prefix/$i'));
    }
    return out;
  }
  return <String>[prefix];
}

/// The value at a JSON Pointer, or `_missing` if the path is absent.
const Object _missing = Object();
Object? valueAt(Object? root, String pointer) {
  if (pointer.isEmpty) return root;
  Object? cur = root;
  for (final String rawToken in pointer.substring(1).split('/')) {
    final String token =
        rawToken.replaceAll('~1', '/').replaceAll('~0', '~');
    if (cur is Map && cur.containsKey(token)) {
      cur = cur[token];
    } else {
      return _missing;
    }
  }
  return cur;
}

/// One Tier 0 comparison. `exempt` carries `tier0_divergences.yaml`'s pointers
/// — every key NOT in it is compared byte-for-byte (`F0-AC-30`).
class Tier0Result {
  Tier0Result(this.failures);
  final List<String> failures;
  bool get passed => failures.isEmpty;
  @override
  String toString() => failures.isEmpty ? 'PASS' : failures.join('\n');
}

Tier0Result compareTier0({
  required Map<String, Object?> oracle,
  required Map<String, Object?> actual,
  Set<String> exempt = const <String>{},
}) {
  final List<String> failures = <String>[];

  // 1. Structure and ORDER, before values — so a flattened nested payload fails
  //    on the path list even if some flattening made the leaves match (M5).
  final List<String> want = leafPaths(oracle);
  final List<String> got = leafPaths(actual);
  if (!_listEq(want, got)) {
    for (final String p in want) {
      if (!got.contains(p)) failures.add('MISSING PATH  $p');
    }
    for (final String p in got) {
      if (!want.contains(p)) failures.add('UNEXPECTED PATH  $p');
    }
    if (failures.isEmpty) {
      // Same set, different order — a transposition (M2).
      for (int i = 0; i < want.length; i++) {
        if (want[i] != got[i]) {
          failures.add('PATH ORDER  position $i: expected ${want[i]}, '
              'got ${got[i]} — key order is WIRE order (client.ts:242)');
          break;
        }
      }
    }
  }

  // 2. Values, per leaf, excluding the registered divergences.
  for (final String p in want) {
    if (exempt.contains(p)) continue;
    final Object? a = valueAt(oracle, p);
    final Object? b = valueAt(actual, p);
    if (identical(b, _missing)) continue; // already reported as MISSING PATH
    // Encoded, so `"34"` and `34` are different — and `true` and `"true"` are
    // different, which is the ONLY non-string primitive in the product
    // (MarriageCertificatePage.tsx:904).
    final String ea = jsonEncode(a);
    final String eb = jsonEncode(b);
    if (ea != eb) failures.add('VALUE  $p: expected $ea, got $eb');
  }

  // 3. The bytes. Belt and braces: if 1 and 2 pass, this must too — and if it
  //    does not, the comparator itself is wrong and says so.
  final String sa = jsonEncode(oracle);
  final String sb = jsonEncode(actual);
  if (failures.isEmpty && sa != sb && exempt.isEmpty) {
    failures.add('BYTES differ while every path and value matched — the '
        'comparator is unsound, not the payload');
  }
  return Tier0Result(failures);
}

/// Exposed for the A-vs-B group, which needs the same order-sensitive
/// comparison the comparator uses rather than a set equality.
bool _sameList(List<String> a, List<String> b) => _listEq(a, b);

/// The `_missing` marker [valueAt] returns for an absent pointer, re-exported
/// under a name the A-vs-B group can read.
const Object _missingSentinel = _missing;

bool _listEq(List<String> a, List<String> b) {
  if (a.length != b.length) return false;
  for (int i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}

// ─────────────────────────────────────────────────────────────────────────────
// Reference documents.
//
// Deliberately SMALL and hand-built: these exercise the comparator's structural
// distinctions (flat vs nested, boolean, elision, order), not the ~200 real
// values. The real values are Entry A's and Entry B's, and the oracle-content
// criteria (F0-AC-34/35/44/82/83/85) are theirs to satisfy. Mixing the two here
// would make a comparator bug look like an oracle bug.
// ─────────────────────────────────────────────────────────────────────────────

/// Flat family (Resident/Birth/Death): literal dotted keys.
Map<String, Object?> flatCreate() => <String, Object?>{
      'service_code': 'birth-declaration',
      'event_date': '2026-08-13',
      'form_data': <String, Object?>{
        'header.document_no': 'DOC-1',
        'header.legal_basis': 'Pursuant to the Family Law No. 44/NA',
        'applicant.age': '34',
        'purpose.purpose': 'school-enrolment',
      },
    };

/// Nested family (Marriage/Divorce): a real object tree.
Map<String, Object?> nestedCreate() => <String, Object?>{
      'service_code': 'marriage-certificate',
      'province_id': '',
      'event_date': '2026-08-13',
      'linked_reference_no': 'REC-9',
      'form_data': <String, Object?>{
        'header': <String, Object?>{'document_no': 'DOC-1', 'dated': '2026-08-13'},
        'betrothal': <String, Object?>{
          'creates_betrothal_record': true,
          'bride_price': '5000000',
        },
        'spouses': <String, Object?>{
          'name': 'A Only',
          'spouse_a': <String, Object?>{'name': 'A Only', 'dob': ' 1990-01-01 '},
        },
      },
    };

Map<String, Object?> deepCopy(Map<String, Object?> m) =>
    jsonDecode(jsonEncode(m)) as Map<String, Object?>;

// ─────────────────────────────────────────────────────────────────────────────
// F0-AC-34 / F0-AC-60 — NON-VACUITY.
//
// Everything below this line proves the COMPARATOR is correct, using inline
// documents. None of it proves a single REAL payload was ever compared. Without
// the guard in this group the Tier 0 gate reports PASS against ZERO
// comparisons — and F0b is gated on exactly this harness. That is the AC-24
// shape in the one place this batch exists to keep it out of.
//
// Same discipline as F0-AC-101: PASS means "n oracles compared, all equal";
// NOT EVALUATED means "no oracles present". The second must never render as the
// first, and the count is derived from what is on disk — never a literal.
// ─────────────────────────────────────────────────────────────────────────────

/// `$PROJ/docs/fidelity-baseline/2026-08-13/oracle/tier0/`, project-relative
/// from `$PKG` (the split § 7.0(1) exists to stop being mixed up). The path
/// itself is `oracle.dart`'s [kTier0Dir] — one definition, so the harness and
/// the loaders cannot drift apart.
///
/// `listSync()` is ONE level deep on purpose: `variants/` holds the
/// non-canonical fixture derivations and must not inflate `F0-AC-34`'s count.
List<File> tier0OracleFiles() {
  final Directory d = Directory(kTier0Dir);
  if (!d.existsSync()) return <File>[];
  return d
      .listSync()
      .whereType<File>()
      .where((File f) => f.path.endsWith('.json'))
      .toList()
    ..sort((File a, File b) => a.path.compareTo(b.path));
}

void main() {
  group('Tier 0 is NOT VACUOUS — F0-AC-34, F0-AC-60', () {
    test('oracle documents exist, and the count is DERIVED not asserted', () {
      final List<File> files = tier0OracleFiles();
      // Printed either way: a passing gate with no number is what this whole
      // batch exists to stop.
      // ignore: avoid_print
      print('Tier 0 oracle documents discovered: ${files.length} '
          'in $kTier0Dir');
      expect(files, isNotEmpty,
          reason: 'NOT EVALUATED — no Tier 0 oracle document exists under '
              '$kTier0Dir, so ZERO real payload comparisons ran. Every '
              'assertion in this file below is about the COMPARATOR, not about '
              'any payload. Reporting this as PASS would be the AC-24 shape: a '
              'gate that is green because its input is empty.\n'
              'Produced by derive_forms_oracles.py (Entry B) and '
              'execute_forms_oracle.mjs (Entry A) — § 6.5.5, RULING 10.');
    });

    test('every discovered oracle is well-formed and carries its provenance',
        () {
      final List<File> files = tier0OracleFiles();
      if (files.isEmpty) {
        fail('NOT EVALUATED — see the previous test. Not skipped, because '
            'F0-AC-3 requires a skipped count of 0 and a skip reads as '
            '"absent" rather than as "unevaluated".');
      }
      for (final File f in files) {
        final Object? doc = jsonDecode(f.readAsStringSync());
        expect(doc, isA<Map<String, Object?>>(), reason: f.path);
        final Map<String, Object?> m = doc! as Map<String, Object?>;
        for (final String key in <String>[
          'form_data',
          'paths',
          'clock',
          'attempt',
          'provenance',
        ]) {
          expect(m.containsKey(key), isTrue,
              reason: '${f.path}: missing `$key` (§ 6.5.1)');
        }
        // § 6.5.1's own lower bound: an emission of `paths: []` satisfied every
        // structural check in v1.0 and proved nothing.
        expect(m['paths'], isA<List<Object?>>(), reason: f.path);
        expect((m['paths']! as List<Object?>), isNotEmpty,
            reason: '${f.path}: `paths` is empty — a structurally valid oracle '
                'that asserts nothing');
        // The path list must actually describe the tree it ships with.
        expect(leafPaths(m['form_data']), equals(m['paths']),
            reason: '${f.path}: `paths` does not match `form_data`\'s own leaf '
                'order — one of the two is wrong and the comparator would '
                'inherit it');
      }
    });
  });

  // ───────────────────────────────────────────────────────────────────────
  // The DERIVED matrix. Everything above this group is about the comparator
  // and would pass with `oracle/tier0/` deleted. Everything below reads the
  // 22 real documents and fails if they are absent — which is the difference
  // between "the instrument works" and "the instrument was pointed at the
  // product".
  // ───────────────────────────────────────────────────────────────────────
  group('the DERIVED matrix — F0-AC-34, 44, 79, 80, 81, 82, 87', () {
    void requireMatrix() {
      if (!tier0MatrixPresent()) {
        fail('NOT EVALUATED — the 22-document matrix is not on disk. Run '
            '`python3 test/fidelity/derive_forms_oracles.py` (Entry B). Not '
            'skipped: F0-AC-3 requires a skipped count of 0, and a skip reads '
            'as "absent" rather than as "unevaluated".');
      }
    }

    test('F0-AC-34 exactly 22 documents, and every EXPECTED name is present',
        () {
      requireMatrix();
      final List<String> want = tier0OracleNames()..sort();
      final List<String> got = tier0OracleFiles()
          .map((File f) => f.uri.pathSegments.last.replaceAll('.json', ''))
          .toList()
        ..sort();
      // ignore: avoid_print
      print('Tier 0 matrix: ${got.length} documents');
      expect(got, equals(want),
          reason: 'the matrix is {form} x {create,update} x {en,lo}, '
              'FamilyBook x 2 — 22 documents. A glob-derived count would '
              'shrink silently when a derivation fails; this one cannot.');
      expect(want.length, 22);
    });

    test('F0-AC-34 every document carries its required fields, and `paths` '
        'describes the tree it ships with', () {
      requireMatrix();
      for (final String name in tier0OracleNames()) {
        final Tier0Oracle o = Tier0Oracle.load(kTier0Dir, name);
        expect(o.attempt, 'first', reason: name);
        expect(o.clock, '2026-08-14T02:00:00+07:00', reason: name);
        expect(o.paths, isNotEmpty, reason: name);
        expect(leafPaths(o.formData), equals(o.paths),
            reason: '$name: `paths` does not match `form_data`\'s own leaf '
                'order — one of the two is wrong and the comparator would '
                'inherit it');
        expect(o.src.keys.toSet(), equals(o.paths.toSet()),
            reason: '$name: a leaf without a `src` is a leaf with no '
                'attribution (F0-AC-87 ii)');
        expect(o.envelope, isNotEmpty, reason: name);
        expect(o.provenance['web_commit'], kWebCommit, reason: name);
      }
    });

    test('F0-AC-34 the Finding B pair relation holds, per family', () {
      requireMatrix();
      for (final String form in <String>['resident', 'birth', 'death']) {
        for (final String locale in <String>['en', 'lo']) {
          final Tier0Oracle c = loadTier0(form, 'create', locale);
          final Tier0Oracle u = loadTier0(form, 'update', locale);
          final String ref = c.refBinding['pointer']! as String;
          expect(u.paths, equals(<String>[...c.paths, ref]),
              reason: '$form.$locale: the flat family appends the reference '
                  'LAST to a spread copy of the same object — +1 key, order '
                  'otherwise unchanged');
          expect(c.refBinding['mechanic'], 'flat-appended-last');
        }
      }
      for (final String form in <String>['marriage', 'divorce']) {
        for (final String locale in <String>['en', 'lo']) {
          final Tier0Oracle c = loadTier0(form, 'create', locale);
          final Tier0Oracle u = loadTier0(form, 'update', locale);
          expect(u.paths, equals(c.paths),
              reason: '$form.$locale: the nested family RE-INVOKES '
                  'buildFormData with the reference — same paths');
          final List<String> differing = <String>[
            for (final String p in c.paths)
              if (jsonEncode(valueAt(c.formData, p)) !=
                  jsonEncode(valueAt(u.formData, p)))
                p,
          ];
          expect(differing, equals(<String>[c.refBinding['pointer']]),
              reason: '$form.$locale: EXACTLY ONE value differs between the '
                  'create and update bodies, and it is the document number');
        }
      }
    });

    test('F0-AC-87(ii) every cited line really contains its key literal', () {
      requireMatrix();
      final Map<String, List<String>> cache = <String, List<String>>{};
      List<String> sourceLines(String file) => cache.putIfAbsent(file, () {
            final File f = File('../../sources/lcc-app/src/app/components/$file');
            if (!f.existsSync()) {
              fail('NOT EVALUATED — $file is not under sources/lcc-app. The '
                  'attribution check cannot run without the pinned source.');
            }
            return f.readAsLinesSync();
          });

      int checked = 0;
      for (final String name in tier0OracleNames()) {
        final Tier0Oracle o = Tier0Oracle.load(kTier0Dir, name);
        for (final MapEntry<String, String> e in o.src.entries) {
          final List<String> parts = e.value.split(':');
          final List<String> lines = sourceLines(parts.first);
          final int lineNo = int.parse(parts.last);
          expect(lineNo, inInclusiveRange(1, lines.length),
              reason: '$name ${e.key}: ${e.value} is past end of file');
          final String line = lines[lineNo - 1];
          // Three spellings: `"header.province_id":` (flat), `province_id:`
          // (nested) and the helper's computed `[`${prefix}.name`]:`.
          final String leaf = e.key.split('/').last;
          final bool ok = line.contains('"$leaf"') ||
              RegExp('(^|[\\s{(])${RegExp.escape(leaf)}\\s*:').hasMatch(line) ||
              // ES shorthand: `me.requestFamilyBookCopy({ reason })` declares
              // the wire key with no colon at all.
              RegExp('[{,]\\s*${RegExp.escape(leaf)}\\s*[},]').hasMatch(line) ||
              line.contains('\${prefix}.${leaf.split('.').last}');
          expect(ok, isTrue,
              reason: '$name: ${e.value} does not carry `$leaf` — this is the '
                  'attribution that rots, and derive_tier2.py already caught '
                  'AppColors.authGradientEnd this way');
          checked++;
        }
      }
      // ignore: avoid_print
      print('F0-AC-87(ii): $checked leaf attributions verified against '
          'sources/lcc-app');
      expect(checked, greaterThan(700),
          reason: 'a handful of leaves would mean the matrix is a stub');
    });

    test('F0-AC-44 the Tier 0 WIRE value is present, and is the source string',
        () {
      requireMatrix();
      for (final MapEntry<String, String> pair
          in <String, String>{'birth': 'birth', 'death': 'death'}.entries) {
        final File ns =
            File('../../sources/lcc-app/src/app/i18n/ns/${pair.value}.ts');
        if (!ns.existsSync()) {
          fail('NOT EVALUATED — ${ns.path} is absent, so "the exact source '
              'string" cannot be checked against anything.');
        }
        final String text = ns.readAsStringSync();
        for (final String locale in <String>['en', 'lo']) {
          final Object? v = valueAt(
              loadTier0(pair.key, 'create', locale).formData,
              '/header.legal_basis');
          expect(v, isA<String>(), reason: '${pair.key}.$locale');
          expect((v! as String).isNotEmpty, isTrue);
          expect(text.contains(v as String), isTrue,
              reason: '${pair.key}.$locale `header.legal_basis` is not a '
                  'literal in ${pair.value}.ts — the wire value was invented '
                  'somewhere, which is exactly the drop the line-anchored '
                  'parser caused for this key');
        }
      }
    });

    test('F0-AC-79 linked_reference_no: nested family only, between '
        'event_date and form_data, elided', () {
      requireMatrix();
      for (final String form in <String>['marriage', 'divorce']) {
        final Tier0Oracle c = loadTier0(form, 'create', 'en');
        final List<String> keys = c.envelope.keys.toList();
        expect(keys.contains('linked_reference_no'), isTrue, reason: form);
        expect(keys.indexOf('linked_reference_no'),
            greaterThan(keys.indexOf('event_date')));
        expect(keys.indexOf('linked_reference_no'),
            lessThan(keys.indexOf('form_data')));
        final Map<String, dynamic> slot =
            c.envelope['linked_reference_no']! as Map<String, dynamic>;
        expect(slot['present'], isFalse,
            reason: '$form: `/prerequisite-records` answers `data: []` on '
                'every account available to this programme, so linkedRecord '
                'is null and the key is DROPPED by JSON.stringify — see '
                'oracle_coverage.yaml');
        expect(slot.containsKey('value'), isFalse,
            reason: 'an elided key carries no value; absent is not '
                'present-and-empty');
      }
      for (final String form in <String>['resident', 'birth', 'death']) {
        expect(loadTier0(form, 'create', 'en').envelope.keys,
            isNot(contains('linked_reference_no')),
            reason: '$form has no linked record concept at all');
      }
    });

    test('F0-AC-80 the update envelope is a second, differently-ordered '
        'envelope', () {
      requireMatrix();
      for (final String form in <String>[
        'resident', 'birth', 'death', 'marriage', 'divorce',
      ]) {
        for (final String locale in <String>['en', 'lo']) {
          final List<String> create =
              loadTier0(form, 'create', locale).envelope.keys.toList();
          final List<String> update =
              loadTier0(form, 'update', locale).envelope.keys.toList();
          expect(update, equals(<String>['form_data', 'event_date']),
              reason: '$form.$locale: form_data FIRST on the update');
          expect(create.last, 'form_data',
              reason: '$form.$locale: form_data LAST on the create');
          expect(update, isNot(equals(create)),
              reason: 'two distinct byte sequences, not a style to normalise');
        }
      }
    });

    test('F0-AC-81 the boolean is a BOOLEAN, and BOTH literals appear', () {
      requireMatrix();
      const String p = '/betrothal/creates_betrothal_record';
      final Object? whenNew =
          valueAt(loadTier0('marriage', 'create', 'en').formData, p);
      expect(whenNew, isA<bool>(),
          reason: 'MarriageCertificatePage.tsx:904 is `betrothalMode === '
              '"new"` — a bare JSON boolean, the ONLY non-string primitive in '
              'all six payloads');
      expect(whenNew, isTrue);

      final Object? whenExisting = valueAt(
          loadTier0Variant('marriage', 'whitespace', 'create', 'en').formData,
          p);
      expect(whenExisting, isA<bool>());
      expect(whenExisting, isFalse,
          reason: 'a fixture set that only ever drives betrothalMode == "new" '
              'never demonstrates the key is variable');
    });

    test('F0-AC-82 the spouse asymmetry is MEASURED, not asserted in prose',
        () {
      requireMatrix();
      final Tier0Oracle m = loadTier0('marriage', 'create', 'en');
      final Tier0Oracle d = loadTier0('divorce', 'create', 'en');
      int under(Tier0Oracle o, String prefix) =>
          o.paths.where((String p) => p.startsWith(prefix)).length;
      expect(under(m, '/spouses/spouse_a/'), 13);
      expect(under(m, '/spouses/spouse_b/'), 13);
      expect(under(d, '/spouses/husband/'), 8);
      expect(under(d, '/spouses/wife/'), 8);

      List<String> mirror(Tier0Oracle o) => o.paths
          .where((String p) =>
              p.startsWith('/spouses/') && p.split('/').length == 3)
          .map((String p) => p.split('/').last)
          .toList();
      final Set<String> mm = mirror(m).toSet()..remove('medical_certificate');
      final Set<String> dd = mirror(d).toSet();
      expect(mm.length, 7);
      expect(dd.length, 6);
      expect(mm.difference(dd), equals(<String>{
        'gender',
        'residence_certificate_ref',
      }));
      expect(dd.difference(mm), equals(<String>{'marriage_certificate_ref'}));
      expect(mm.contains('residence_certificate_ref'), isTrue);
      expect(dd.contains('residence_certificate_ref'), isFalse,
          reason: 'Divorce renames it — a shared spousePayload/both() helper '
              'would be correct for most keys and silently wrong for the rest '
              '(FU-12)');
    });

    test('F0-AC-83 both()\'s TRIM is observable, and is ASYMMETRIC', () {
      requireMatrix();
      final Map<String, dynamic> fd =
          loadTier0Variant('marriage', 'whitespace', 'create', 'en').formData;
      // The mirror trims; the sub-object does NOT. Whitespace is the only
      // input that makes the divergence visible, and a port that trims
      // uniformly — the natural Dart instinct — fails here and nowhere else.
      for (final String k in <String>['dob', 'nationality', 'current_address']) {
        final String mirrored = valueAt(fd, '/spouses/$k')! as String;
        final String own = valueAt(fd, '/spouses/spouse_a/$k')! as String;
        expect(own, isNot(equals(mirrored)), reason: k);
        expect(own.trim(), equals(mirrored), reason: k);
        expect(own, isNot(equals(own.trim())),
            reason: '$k: the sub-object must emit the value UNTRIMMED');
      }
      // Whitespace-only A makes `a.trim()` falsy: the mirror collapses to ""
      // while the sub-object still emits the spaces.
      expect(valueAt(fd, '/spouses/gender'), '');
      expect(valueAt(fd, '/spouses/spouse_a/gender'), '  ');
      // The three both-sides-trimmed controls, without which this fixture
      // would be testing a uniform rule rather than an asymmetric one.
      for (final String k in <String>[
        'name', 'id_number', 'residence_certificate_ref',
      ]) {
        final String mirrored = valueAt(fd, '/spouses/$k')! as String;
        final String own = valueAt(fd, '/spouses/spouse_a/$k')! as String;
        expect(own, equals(mirrored), reason: k);
        expect(own, equals(own.trim()), reason: '$k trims on BOTH sides');
      }
    });

    test('F0-AC-37(b) a blank B collapses every mirror to ""', () {
      requireMatrix();
      final Map<String, dynamic> fd =
          loadTier0Variant('marriage', 'blank-b', 'create', 'en').formData;
      for (final String k in <String>[
        'name', 'dob', 'gender', 'nationality', 'id_number',
        'current_address', 'residence_certificate_ref',
      ]) {
        expect(valueAt(fd, '/spouses/$k'), '',
            reason: '$k: both(a,b) is `a.trim() && b.trim() ? a.trim() : ""`');
      }
      expect(valueAt(fd, '/spouses/spouse_a/name'), 'Test Spouse Alpha',
          reason: 'the sub-object keeps A regardless');
    });

    test('F0-AC-38 the skip paths change the KEY SET, not just values', () {
      requireMatrix();
      final Tier0Oracle base = loadTier0('birth', 'create', 'en');
      final Tier0Oracle fu =
          loadTier0Variant('birth', 'father-unknown', 'create', 'en');
      List<String> father(Tier0Oracle o) =>
          o.paths.where((String p) => p.startsWith('/parents.father')).toList();
      expect(father(base).length, 13);
      expect(father(fu), equals(<String>['/parents.father.status']));
      expect(valueAt(fu.formData, '/parents.father.status'), 'unknown');

      final Tier0Oracle dBase = loadTier0('death', 'create', 'en');
      expect(
          dBase.paths.where((String p) => p.startsWith('/parents.father')).length,
          14,
          reason: 'Death\'s parentData carries `workplace`; Birth\'s does not. '
              'Never share the helper.');
      final Tier0Oracle ms =
          loadTier0Variant('death', 'mother-skip', 'create', 'en');
      expect(
          ms.paths.where((String p) => p.startsWith('/parents.')).toList(),
          containsAll(<String>['/parents.mother.status']));
      expect(valueAt(ms.formData, '/parents.status'), 'deceased-or-unknown');
      expect(
          ms.paths.where((String p) => p.startsWith('/parents.father')).length,
          14,
          reason: 'motherSkip must not collapse the father block too');
      final Tier0Oracle fs =
          loadTier0Variant('death', 'father-skip', 'create', 'en');
      expect(
          fs.paths.where((String p) => p.startsWith('/parents.father')).toList(),
          equals(<String>['/parents.father.status']));
    });

    test('the flat and nested families stay DISTINGUISHABLE on real data', () {
      requireMatrix();
      // The claim § 6.5.1 was rewritten for, checked against the product
      // rather than against a planted fixture: Birth emits the literal flat
      // key `"header.document_no"`, Marriage emits a nested `header` ->
      // `document_no`, and the two pointers are different strings.
      expect(loadTier0('birth', 'update', 'en').paths,
          contains('/header.document_no'));
      expect(loadTier0('birth', 'update', 'en').paths,
          isNot(contains('/header/document_no')));
      expect(loadTier0('marriage', 'update', 'en').paths,
          contains('/header/document_no'));
      expect(loadTier0('marriage', 'update', 'en').paths,
          isNot(contains('/header.document_no')));
    });
  });

  // ───────────────────────────────────────────────────────────────────────
  // RULING 10's second entry. Everything above compares Entry B against
  // itself or against the comparator; this group is the only place where a
  // byte that came off a socket meets a byte that came off a source file.
  //
  // Entry B is a RE-TRANSCRIPTION and § 6.5.5 concedes it is not an
  // execution: a systematic misreading of the TS is invisible to it. Entry A
  // is the only thing that can catch one, and a Tier 0 resting on B alone is
  // the single-entry gate the ruling was written to avoid — while looking
  // green the whole time.
  // ───────────────────────────────────────────────────────────────────────
  group('Entry A vs Entry B — F0-AC-104, F0-AC-105', () {
    test('Entry A documents exist, are distinguishable from B, and carry '
        'the bytes they claim', () {
      final List<String> executed = tier0ExecutedNames();
      // ignore: avoid_print
      print('Entry A documents on disk: ${executed.length} '
          '(${executed.join(', ')})');
      if (executed.isEmpty) {
        fail('NOT EVALUATED — Entry A has landed no documents, so RULING 10\'s '
            'two-entry structure has ONE entry. Run '
            '`node test/fidelity/execute_forms_oracle.mjs`. Not skipped: '
            'F0-AC-3 requires a skipped count of 0, and a skip reads as '
            '"absent" rather than as "unevaluated".');
      }
      for (final String name in executed) {
        final Tier0Oracle a = loadTier0Executed(name);
        expect(a.provenance['entry'], 'A',
            reason: '$name: an Entry A document that does not say so is '
                'indistinguishable from a transcription');
        expect(a.provenance['leaf_provenance'], 'executed', reason: name);
        expect(a.provenance['web_commit'], kWebCommit, reason: name);

        // `raw_bytes` is the evidence; every other field is derived from it.
        // Re-deriving here is what stops a hand-edited `form_data` passing as
        // a capture — the AC-24 shape, applied to the one gate ssd.md § 14
        // F-6 ranks above human review.
        final Object? raw = a.json['raw_bytes'];
        expect(raw, isA<String>(),
            reason: '$name: no raw_bytes — nothing proves this was captured');
        final Map<String, Object?> decoded =
            jsonDecode(raw! as String) as Map<String, Object?>;
        expect(jsonEncode(decoded['form_data'] ?? decoded),
            equals(jsonEncode(a.formData)),
            reason: '$name: `form_data` does not re-derive from `raw_bytes`. '
                'One of the two was edited by hand, and the document is not '
                'evidence of anything.');
      }
    });

    test('F0-AC-104 A === B byte-for-byte on every leaf A covers', () {
      final List<String> executed = tier0ExecutedNames();
      if (executed.isEmpty) {
        fail('NOT EVALUATED — no Entry A document exists, so "every captured '
            'leaf agrees" is vacuously true. That vacuity is exactly what '
            'F0-AC-106(b) exists to expose, and it is NOT a pass.');
      }
      int compared = 0;
      final List<String> disagreements = <String>[];

      for (final String name in executed) {
        final Tier0Oracle a = loadTier0Executed(name);
        // Resolved by name SHAPE — a variant capture's counterpart lives in
        // `variants/`, not in the canonical matrix. See
        // [loadTier0CounterpartOf].
        final Tier0Oracle b = loadTier0CounterpartOf(name);

        // Structure and ORDER first, so a flattened capture fails on the path
        // list even if the leaf values happen to match.
        if (!_sameList(a.paths, b.paths)) {
          disagreements.add('$name: PATHS differ — A has ${a.paths.length}, '
              'B has ${b.paths.length}');
        }
        for (final String p in b.paths) {
          final Object? av = valueAt(a.formData, p);
          final Object? bv = valueAt(b.formData, p);
          if (identical(av, _missingSentinel)) {
            disagreements.add('$name: MISSING ON THE WIRE  $p');
            continue;
          }
          compared++;
          if (jsonEncode(av) != jsonEncode(bv)) {
            disagreements.add('$name: $p — executed ${jsonEncode(av)}, '
                'transcribed ${jsonEncode(bv)}  (B cites ${b.src[p]})');
          }
        }
      }

      // ignore: avoid_print
      print('F0-AC-104: $compared leaves compared A vs B across '
          '${executed.length} documents');
      expect(compared, greaterThan(0),
          reason: 'zero leaves compared — see the previous test');
      expect(disagreements, isEmpty,
          reason: 'BLOCKED (§ 8.3), not a failure to reconcile.\n\n'
              'A disagreement is EITHER a transcription defect in '
              'derive_forms_oracles.py OR a rig defect in '
              'execute_forms_oracle.mjs. It is NEVER resolved by editing one '
              'side to match the other — that is the double entry deleting '
              'itself. Escalate to sw-architect-lcc-mobile-app-greenfield '
              'with the file:line Entry B cited, printed above per leaf.\n\n'
              '${disagreements.join('\n')}');
    });

    test('F0-AC-105 the coverage register is evidence-bounded, and its '
        'shortfall is stated rather than papered over', () {
      final File register = File('test/fidelity/oracle_coverage.yaml');
      expect(register.existsSync(), isTrue,
          reason: 'the register is what stops "A covered 45 of 1132 leaves" '
              'reading as full coverage');
      final String text = register.readAsStringSync();

      // (i) every registered entry carries a file:line establishing the branch
      //     is structurally unreachable, not merely undriven.
      expect(text, contains('manifest-authenticated.md:230-232'));
      expect(text, contains('MarriageCertificatePage.tsx:963'));
      expect(text, contains('FamilyBookPage.tsx:200-202'));

      // (ii) the honest half. Every leaf Entry A did NOT reach must be either
      //      registered as unreachable or declared undriven. Undriven leaves
      //      may NOT be entered as unreachable — that substitution, effort
      //      recorded as impossibility, is the one thing this register exists
      //      to prevent.
      final Set<String> executedDocs = tier0ExecutedNames().toSet();
      // The denominator is EVERY Entry B document — canonical matrix plus
      // variants. Using `tier0OracleNames()` alone subtracted 4-part variant
      // names from a list of 3-part canonical ones, i.e. two different name
      // spaces, and printed `Entry A covers 24 of 22 documents`. It also hid
      // the variant shortfall entirely: divorce's and marriage's 16 variant
      // documents were outside the denominator, so the register's
      // undriven-declaration check never saw them.
      final List<String> allB = tier0AllOracleNames();
      final List<String> uncovered =
          allB.where((String n) => !executedDocs.contains(n)).toList();

      // Every Entry A capture must correspond to a real Entry B document. A
      // capture with no counterpart is not coverage — it is an orphan, and
      // silently ignoring it would let A "cover" documents B never derived.
      final Set<String> allBSet = allB.toSet();
      final List<String> orphans = executedDocs
          .where((String n) => !allBSet.contains(n))
          .toList()
        ..sort();
      expect(orphans, isEmpty,
          reason: 'Entry A documents with no Entry B counterpart: '
              '${orphans.join(', ')}. Every executed leaf must be checkable '
              'against a transcription (`F0-AC-104`); one that is not is '
              'single entry wearing the label of double entry.');

      // ignore: avoid_print
      print('F0-AC-105: Entry A covers ${executedDocs.length} of '
          '${allB.length} Entry B documents; ${uncovered.length} '
          'uncovered and declared undriven, not unreachable');
      if (uncovered.isNotEmpty) {
        expect(text, contains('not_eligible'),
            reason: '${uncovered.length} documents have no Entry A coverage '
                'and the register does not declare them. Silence here is the '
                'conversion of "we did not test it" into "it is not '
                'testable".');
        for (final String form
            in uncovered.map((String n) => n.split('.').first).toSet()) {
          expect(text, contains(form),
              reason: '$form has no Entry A coverage and is not named in the '
                  'register\'s undriven declaration');
        }
      }
    });
  });

  group('the mutants, against REAL payloads — F0-AC-33', () {
    // The five controls above run on small hand-built documents so a
    // comparator bug cannot look like an oracle bug. These re-run the two that
    // depend on real structure against the derived matrix, because M5's whole
    // subject is a distinction that only exists in the product.
    test('M5 on the real Marriage payload — flattening it must FAIL', () {
      if (!tier0MatrixPresent()) {
        fail('NOT EVALUATED — no derived matrix; see F0-AC-34.');
      }
      final Tier0Oracle m = loadTier0('marriage', 'create', 'en');
      final Map<String, Object?> good =
          deepCopy(m.formData.cast<String, Object?>());
      final Map<String, Object?> flat = <String, Object?>{};
      (good['header']! as Map<String, Object?>)
          .forEach((String k, Object? v) => flat['header.$k'] = v);
      final Map<String, Object?> mutated = <String, Object?>{
        ...flat,
        for (final MapEntry<String, Object?> e in good.entries)
          if (e.key != 'header') e.key: e.value,
      };
      final Tier0Result r = compareTier0(oracle: good, actual: mutated);
      expect(r.passed, isFalse,
          reason: 'M5 passed on REAL data — the instrument cannot tell '
              'Marriage\'s nested header from Birth\'s literal flat key');
      expect(r.toString(), contains('/header/document_no'));
      expect(r.toString(), contains('/header.document_no'));
    });

    test('M3 on the real Birth payload — an `lo` body in an `en` slot FAILS',
        () {
      if (!tier0MatrixPresent()) {
        fail('NOT EVALUATED — no derived matrix; see F0-AC-34.');
      }
      final Tier0Result r = compareTier0(
        oracle: loadTier0('birth', 'create', 'en').formData.cast<String, Object?>(),
        actual: loadTier0('birth', 'create', 'lo').formData.cast<String, Object?>(),
      );
      expect(r.passed, isFalse);
      expect(r.toString(), contains('/header.legal_basis'));
    });

    test('M1 on the real Resident payload — one character FAILS', () {
      if (!tier0MatrixPresent()) {
        fail('NOT EVALUATED — no derived matrix; see F0-AC-34.');
      }
      final Map<String, Object?> good = loadTier0('resident', 'create', 'en')
          .formData
          .cast<String, Object?>();
      final Map<String, Object?> bad = deepCopy(good);
      bad['applicant.age'] = '35';
      final Tier0Result r = compareTier0(oracle: good, actual: bad);
      expect(r.passed, isFalse);
      expect(r.toString(), contains('/applicant.age'));
    });
  });

  group('Tier 0 comparator — F0-AC-16, the comparison is on BYTES', () {
    test('a control payload compares equal to itself', () {
      expect(compareTier0(oracle: flatCreate(), actual: flatCreate()).passed,
          isTrue);
      expect(compareTier0(oracle: nestedCreate(), actual: nestedCreate()).passed,
          isTrue);
    });

    test('F0-AC-16 `{"a":1}` vs `{"a":"1"}` FAILS — decoded maps are not equal',
        () {
      final Tier0Result r = compareTier0(
        oracle: <String, Object?>{'a': 1},
        actual: <String, Object?>{'a': '1'},
      );
      expect(r.passed, isFalse);
      expect(r.toString(), contains('/a'));
    });

    test('F0-AC-16 `{"a":1,"b":2}` vs `{"b":2,"a":1}` FAILS — order is wire order',
        () {
      final Tier0Result r = compareTier0(
        oracle: <String, Object?>{'a': 1, 'b': 2},
        actual: <String, Object?>{'b': 2, 'a': 1},
      );
      expect(r.passed, isFalse);
      expect(r.toString(), contains('PATH ORDER'));
    });

    test('F0-AC-31 numerics stay strings — "34" vs 34 FAILS on applicant.age',
        () {
      final Map<String, Object?> bad = deepCopy(flatCreate());
      (bad['form_data']! as Map<String, Object?>)['applicant.age'] = 34;
      final Tier0Result r =
          compareTier0(oracle: flatCreate(), actual: bad);
      expect(r.passed, isFalse);
      expect(r.toString(), contains('/form_data/applicant.age'));
    });

    test('F0-AC-81 the boolean is a BOOLEAN — true vs "true" FAILS', () {
      final Map<String, Object?> bad = deepCopy(nestedCreate());
      ((bad['form_data']! as Map<String, Object?>)['betrothal']!
          as Map<String, Object?>)['creates_betrothal_record'] = 'true';
      final Tier0Result r =
          compareTier0(oracle: nestedCreate(), actual: bad);
      expect(r.passed, isFalse);
      expect(r.toString(),
          contains('/form_data/betrothal/creates_betrothal_record'));
      expect(r.toString(), contains('expected true, got "true"'));
    });
  });

  group('Tier 0 negative control — F0-AC-33, FIVE planted mutants', () {
    test('M1 — one character changed in one value', () {
      final Map<String, Object?> m = deepCopy(flatCreate());
      (m['form_data']! as Map<String, Object?>)['header.document_no'] = 'DOC-2';
      final Tier0Result r = compareTier0(oracle: flatCreate(), actual: m);
      expect(r.passed, isFalse, reason: 'M1 passed — the harness is inert');
      expect(r.toString(), contains('/form_data/header.document_no'));
    });

    test('M2 — two adjacent keys transposed, values unchanged', () {
      final Map<String, Object?> fd = <String, Object?>{
        'header.legal_basis': 'Pursuant to the Family Law No. 44/NA',
        'header.document_no': 'DOC-1', // swapped with the line above
        'applicant.age': '34',
        'purpose.purpose': 'school-enrolment',
      };
      final Map<String, Object?> m = deepCopy(flatCreate())
        ..['form_data'] = fd;
      final Tier0Result r = compareTier0(oracle: flatCreate(), actual: m);
      expect(r.passed, isFalse,
          reason: 'M2 passed — this is a Map-equality comparator wearing a '
              'byte comparator\'s name');
      expect(r.toString(), contains('PATH ORDER'));
    });

    test('M3 — an `lo` payload substituted into an `en` slot', () {
      final Map<String, Object?> lo = deepCopy(flatCreate());
      (lo['form_data']! as Map<String, Object?>)['header.legal_basis'] =
          'ອີງຕາມກົດໝາຍວ່າດ້ວຍຄອບຄົວ ສະບັບເລກທີ 44/ສພຊ';
      final Tier0Result r = compareTier0(oracle: flatCreate(), actual: lo);
      expect(r.passed, isFalse, reason: 'M3 passed — a locale seed that '
          'silently did not take would be invisible');
      expect(r.toString(), contains('/form_data/header.legal_basis'));
    });

    test('M5 — a nested payload FLATTENED to dotted keys', () {
      // Decoded, these two carry the same information. On the wire they are
      // {"header":{"document_no":X}} versus {"header.document_no":X} — utterly
      // different bytes. A dotted-flattening comparator reports PASS, which is
      // why § 6.5.1 was rewritten to a JSON-Pointer path list.
      final Map<String, Object?> flattened = deepCopy(nestedCreate());
      final Map<String, Object?> fd =
          flattened['form_data']! as Map<String, Object?>;
      final Map<String, Object?> header = fd.remove('header')! as Map<String, Object?>;
      final Map<String, Object?> rebuilt = <String, Object?>{
        'header.document_no': header['document_no'],
        'header.dated': header['dated'],
        ...fd,
      };
      flattened['form_data'] = rebuilt;

      final Tier0Result r =
          compareTier0(oracle: nestedCreate(), actual: flattened);
      expect(r.passed, isFalse,
          reason: 'M5 passed — the instrument cannot tell Marriage\'s nested '
              'header from Birth\'s literal flat key, which is the exact '
              'collapse § 6.5.1 exists to prevent');
      expect(r.toString(), contains('/form_data/header/document_no'));
      expect(r.toString(), contains('/form_data/header.document_no'));
    });
  });

  group('locale guards — F0-AC-35, F0-AC-36 and M4', () {
    // Guard A: submit-time locale. These are read out of the translation table
    // INSIDE buildFormData, so the payload's locale is whatever the locale is
    // at submit (BirthDeclarationPage.tsx:761, DeathDeclarationPage.tsx:789,
    // FamilyBookPage.tsx:57-60).
    const Set<String> guardAPaths = <String>{
      '/form_data/header.legal_basis',
      '/reason',
    };

    Map<String, Object?> enDoc() => flatCreate();
    Map<String, Object?> loDoc() {
      final Map<String, Object?> m = deepCopy(flatCreate());
      (m['form_data']! as Map<String, Object?>)['header.legal_basis'] =
          'ອີງຕາມກົດໝາຍວ່າດ້ວຍຄອບຄົວ';
      return m;
    }

    test('F0-AC-35 Guard A — the locale-dependent keys DIFFER across en/lo', () {
      for (final String p in guardAPaths) {
        final Object? a = valueAt(enDoc(), p);
        final Object? b = valueAt(loDoc(), p);
        if (identical(a, _missing) && identical(b, _missing)) continue;
        expect(a, isNot(equals(b)),
            reason: '$p is equal across locales: either the fixture\'s locale '
                'seed never took, or the port hardcoded one locale');
      }
    });

    test('F0-AC-35 Guard A FIRES when the two are made equal', () {
      final Map<String, Object?> faked = deepCopy(loDoc());
      (faked['form_data']! as Map<String, Object?>)['header.legal_basis'] =
          valueAt(enDoc(), '/form_data/header.legal_basis');
      expect(
          () => expect(
              valueAt(faked, '/form_data/header.legal_basis'),
              isNot(equals(valueAt(enDoc(), '/form_data/header.legal_basis')))),
          throwsA(isA<TestFailure>()));
    });

    test('F0-AC-36 complement — every OTHER key is EQUAL across en/lo', () {
      // Over-localisation is the likelier Flutter error: `.tr()` is one
      // character away from a plain string. Without this, the guard only ever
      // caught under-localisation.
      for (final String p in leafPaths(enDoc())) {
        if (guardAPaths.contains(p)) continue;
        expect(valueAt(loDoc(), p), equals(valueAt(enDoc(), p)),
            reason: '$p differs across locales but is not a registered '
                'locale-dependent key — an accidental .tr() on a UUID or code');
      }
    });

    test('F0-AC-86 M4 — the complement guard\'s negative control', () {
      // `purpose.purpose` is NOT in Finding E's list. Localising it must make
      // F0-AC-36 fail. Without this control, F0-AC-36 is a universally
      // quantified equality that is TRUE on an oracle with zero keys — it
      // cannot distinguish "ran and found nothing" from "inert".
      final Map<String, Object?> over = deepCopy(loDoc());
      (over['form_data']! as Map<String, Object?>)['purpose.purpose'] =
          'ການລົງທະບຽນຮຽນ';

      bool complementHeld = true;
      for (final String p in leafPaths(enDoc())) {
        if (guardAPaths.contains(p)) continue;
        if (jsonEncode(valueAt(over, p)) != jsonEncode(valueAt(enDoc(), p))) {
          complementHeld = false;
        }
      }
      expect(complementHeld, isFalse,
          reason: 'M4 passed — the complement guard is inert and F0-AC-36 '
              'would report PASS on a derivation that emitted zero keys');
    });

    // ── the same two guards, over the 22 REAL documents ──────────────────
    //
    // Guard A is submit-time and asserts INEQUALITY. Guard B is pick-time and
    // asserts a RESOLUTION PATH — it is deliberately NOT in Guard A, because
    // an inequality over `address_text` would fail a faithful port and pass
    // one that re-resolved at submit. Backwards in both directions.
    const Set<String> guardBPaths = <String>{
      '/spouses/spouse_a/address_text',
      '/spouses/spouse_b/address_text',
      '/spouses/husband/address_text',
      '/spouses/wife/address_text',
    };

    test('F0-AC-35 Guard A over the derived matrix', () {
      if (!tier0MatrixPresent()) {
        fail('NOT EVALUATED — no derived matrix; see F0-AC-34.');
      }
      for (final String form in <String>['birth', 'death']) {
        for (final String body in <String>['create', 'update']) {
          final Object? en =
              valueAt(loadTier0(form, body, 'en').formData,
                  '/header.legal_basis');
          final Object? lo =
              valueAt(loadTier0(form, body, 'lo').formData,
                  '/header.legal_basis');
          expect(en, isNot(equals(lo)),
              reason: '$form.$body header.legal_basis is equal across '
                  'locales: either the fixture\'s locale seed never took, or '
                  'the port hardcoded one locale');
        }
      }
      expect(valueAt(loadTier0('family-book', 'request', 'en').formData,
              '/reason'),
          isNot(equals(valueAt(
              loadTier0('family-book', 'request', 'lo').formData, '/reason'))));
    });

    test('F0-AC-85 Guard B — address_text is RESOLVED per locale seed', () {
      if (!tier0MatrixPresent()) {
        fail('NOT EVALUATED — no derived matrix; see F0-AC-34.');
      }
      for (final String form in <String>['marriage', 'divorce']) {
        final Tier0Oracle en = loadTier0(form, 'create', 'en');
        final Tier0Oracle lo = loadTier0(form, 'create', 'lo');
        final List<String> present =
            en.paths.where(guardBPaths.contains).toList();
        expect(present, hasLength(2), reason: '$form: two spouses');
        for (final String p in present) {
          // The two differ because the SELECTION was made under that locale
          // and `nameOf` = text(found.name, lang) ran there — not because two
          // literals were typed into two fixture files.
          expect(valueAt(en.formData, p), isNot(equals(valueAt(lo.formData, p))),
              reason: '$form $p: the location selects were not driven under '
                  'the locale seed, so Guard B is inert');
        }
        expect(en.json['notes'], isA<List<dynamic>>(),
            reason: '$form: § 6.5.2 requires the oracle to record, in the '
                'file, that a locale switch AFTER picking legitimately yields '
                'equal en and lo payloads — so it is never re-filed as a bug');
        expect((en.json['notes']! as List<dynamic>).join(),
            contains('IDENTICAL PAYLOADS'));
      }
    });

    test('F0-AC-36 complement over the derived matrix — nothing ELSE differs',
        () {
      if (!tier0MatrixPresent()) {
        fail('NOT EVALUATED — no derived matrix; see F0-AC-34.');
      }
      const Set<String> registered = <String>{
        '/header.legal_basis', // Guard A, Birth + Death
        '/reason', // Guard A, FamilyBook
        ...guardBPaths, // Guard B, Marriage + Divorce
      };
      int compared = 0;
      for (final String name in tier0OracleNames()) {
        if (name.endsWith('.lo')) continue;
        final Tier0Oracle en = Tier0Oracle.load(kTier0Dir, name);
        final Tier0Oracle lo = Tier0Oracle.load(
            kTier0Dir, '${name.substring(0, name.length - 3)}.lo');
        for (final String p in en.paths) {
          if (registered.contains(p)) continue;
          expect(jsonEncode(valueAt(lo.formData, p)),
              equals(jsonEncode(valueAt(en.formData, p))),
              reason: '$name $p differs across locales but is not a '
                  'registered locale-dependent key — an accidental .tr() on a '
                  'UUID or a code. Over-localisation is the likelier Flutter '
                  'mistake: `.tr()` is one character from a plain string.');
          compared++;
        }
      }
      // ignore: avoid_print
      print('F0-AC-36 complement: $compared leaf pairs compared');
      expect(compared, greaterThan(500),
          reason: 'the complement guard is universally quantified and '
              'therefore vacuously true over an empty set — the count is what '
              'distinguishes "ran and found nothing" from "inert"');
    });
  });

  group('envelope shape — F0-AC-79, F0-AC-80', () {
    test('F0-AC-79 linked_reference_no sits BETWEEN event_date and form_data',
        () {
      final List<String> top = nestedCreate().keys.toList();
      final int ev = top.indexOf('event_date');
      final int lrn = top.indexOf('linked_reference_no');
      final int fd = top.indexOf('form_data');
      expect(lrn, greaterThan(ev));
      expect(lrn, lessThan(fd));
    });

    test('F0-AC-79 the same body with the key APPENDED after form_data FAILS',
        () {
      // Same decoded map, different bytes.
      final Map<String, Object?> reordered = <String, Object?>{};
      nestedCreate().forEach((String k, Object? v) {
        if (k != 'linked_reference_no') reordered[k] = v;
      });
      reordered['linked_reference_no'] = 'REC-9';

      expect(jsonDecode(jsonEncode(reordered)).toString().length,
          jsonDecode(jsonEncode(nestedCreate())).toString().length,
          reason: 'precondition: the two decode to the same information');
      final Tier0Result r =
          compareTier0(oracle: nestedCreate(), actual: reordered);
      expect(r.passed, isFalse);
      expect(r.toString(), contains('PATH ORDER'));
    });

    test('F0-AC-80 the update envelope puts form_data FIRST, create puts it LAST',
        () {
      const List<String> updateKeys = <String>['form_data', 'event_date'];
      final List<String> createKeys = flatCreate().keys.toList();
      expect(createKeys.last, 'form_data');
      expect(updateKeys.first, 'form_data');
      expect(updateKeys, isNot(equals(createKeys)),
          reason: 'two distinct byte sequences, not a style to normalise');
    });

    test('absent is not present-and-empty', () {
      final Map<String, Object?> elided = deepCopy(flatCreate())
        ..remove('event_date');
      final Map<String, Object?> empty = deepCopy(flatCreate())
        ..['event_date'] = '';
      expect(compareTier0(oracle: elided, actual: empty).passed, isFalse,
          reason: 'Resident elides province_id when blank; Marriage sends "". '
              'Those are different bodies.');
    });
  });

  group('the divergence register is honoured — F0-AC-30', () {
    test('a registered key may differ; an unregistered one may not', () {
      final Map<String, Object?> clockDrift = deepCopy(flatCreate());
      (clockDrift['form_data']! as Map<String, Object?>)['header.dated'] =
          '2026-08-14';
      final Map<String, Object?> oracle = deepCopy(flatCreate());
      (oracle['form_data']! as Map<String, Object?>)['header.dated'] =
          '2026-08-13';

      // Registered -> exempt.
      expect(
          compareTier0(
            oracle: oracle,
            actual: clockDrift,
            exempt: <String>{'/form_data/header.dated'},
          ).passed,
          isTrue,
          reason: 'ADR-0005 registers this key; local-vs-UTC is the deliberate '
              'divergence');

      // Unregistered -> compared strictly.
      expect(compareTier0(oracle: oracle, actual: clockDrift).passed, isFalse,
          reason: 'every key NOT in the register is compared byte-for-byte');
    });
  });
  // ───────────────────────────────────────────────────────────────────────────
  // F1 — Resident, the harness's FIRST REAL SUBJECT
  // ───────────────────────────────────────────────────────────────────────────
  //
  // Everything above this line compares oracles against oracles, against
  // hand-built control payloads, or against planted mutants. That was all F0a
  // could do: it built the instrument and had no `buildFormData` to run it on
  // (`specs.md` § 3.1 row 10). This group runs the comparator against
  // **`buildResidentFormData`, the real port function**, and it is the reason
  // F1 is the checkpoint that releases F2 (`ssd.md` § 14 F-1).
  //
  // The subject — the fixture reader, the register's instant and the four
  // exempt rows — is shared with the page-local gate rather than copied, so the
  // two cannot read the fixture differently
  // (`resident_tier0_subject.dart`).
  group('Tier 0 — Resident, the real buildFormData (F1)', () {
    final SubmissionClock clock = SubmissionClock.fixed(kRegisterInstant);

    Map<String, dynamic> fixtureOf(String locale) =>
        readOracleJson('$kResidentFixtureDir/baseline.$locale.json');

    /// The two bodies of one submission, built the way the page builds them:
    /// **payload once**, reference appended through the binding.
    SubmissionBodies bodiesOf(String locale) {
      final Map<String, dynamic> fixture = fixtureOf(locale);
      return residentBodiesFrom(
        buildResidentFormData(formFromFixture(fixture), clock),
        fixture['_reference_no'] as String,
      );
    }

    for (final String locale in <String>['en', 'lo']) {
      test('F1-AC-28/29 $locale create — 22 leaves compared against the '
          'executed oracle', () {
        final Tier0Oracle o =
            Tier0Oracle.load('$kResidentOracleDir/executed', 'resident.create.$locale');
        final Map<String, Object?> want = o.formData.cast<String, Object?>();
        final Map<String, Object?> got = bodiesOf(locale).create;

        // `F1-AC-29`: the count is recorded, and a LOWER number is a FAIL even
        // if every compared leaf passed — it would mean leaves were skipped.
        expect(leafPaths(want).length, 22,
            reason: 'resident.create.$locale carries 22 leaves (specs.md § 6.6)');
        expect(leafPaths(got).length, 22,
            reason: 'the port emitted a different number of leaves');

        final Tier0Result r = compareTier0(
          oracle: want,
          actual: got,
          exempt: kResidentExemptFormDataPointers,
        );
        expect(r.passed, isTrue, reason: r.toString());
      });

      test('F1-AC-28/29/35 $locale update — 23 leaves, header.ref_no LAST', () {
        final Tier0Oracle o =
            Tier0Oracle.load('$kResidentOracleDir/executed', 'resident.update.$locale');
        final Map<String, Object?> want = o.formData.cast<String, Object?>();
        final Map<String, Object?> got = bodiesOf(locale).update;

        expect(leafPaths(want).length, 23);
        expect(leafPaths(got).length, 23,
            reason: 'flat-appended-last raises the key count by exactly one');
        expect(got.keys.last, 'header.ref_no',
            reason: 'LAST, not merged in sorted position (F0-AC-14)');

        final Tier0Result r = compareTier0(
          oracle: want,
          actual: got,
          exempt: kResidentExemptFormDataPointers,
        );
        expect(r.passed, isTrue, reason: r.toString());
      });
    }

    test('F1-AC-31 exactly FOUR Resident rows are exempt, and no more', () {
      // Two `form_data` pointers x {create, update} and two envelope keys x
      // {create, update} = the four rows `tier0_divergences.yaml` registers.
      // The register is CLOSED (`ADR-0005` O-5); a fifth needs an amendment.
      expect(kResidentExemptFormDataPointers, <String>{'/purpose.issue_date'});
      expect(kResidentExemptEnvelopeKeys, <String>{'event_date'});

      // And the exemption actually bites on exactly one leaf per body: every
      // other one of the 22 is compared byte-for-byte.
      final Map<String, Object?> got = bodiesOf('en').create;
      final int exemptLeaves = leafPaths(got)
          .where(kResidentExemptFormDataPointers.contains)
          .length;
      expect(exemptLeaves, 1);
      expect(leafPaths(got).length - exemptLeaves, 21,
          reason: '21 of the 22 create leaves are compared strictly');
    });

    test('F1-AC-32 no Resident leaf is NOT EVALUATED', () {
      // Resident has no entry in `oracle_coverage.yaml`'s `unreachable:`
      // register (specs.md § 6.6), so every leaf the oracle carries must be
      // one the port produces. A path in one and not the other is a defect or
      // a missing fixture arm — never a coverage gap.
      for (final String locale in <String>['en', 'lo']) {
        final Tier0Oracle o =
            Tier0Oracle.load('$kResidentOracleDir/executed', 'resident.create.$locale');
        expect(
          leafPaths(bodiesOf(locale).create).toSet(),
          equals(leafPaths(o.formData).toSet()),
          reason: '$locale: an unmatched path is a port defect, not a skip',
        );
      }
    });

    test('F1-AC-34 the harness FAILS on Resident, naming the leaf', () {
      // Without this the whole tier is unfalsifiable. One character, one leaf,
      // and the failure must SAY which leaf.
      final Map<String, Object?> good = bodiesOf('en').create;
      final Map<String, Object?> bad = Map<String, Object?>.of(good);
      bad['applicant.house_no'] = '${good['applicant.house_no']}9';

      final Tier0Result r = compareTier0(
        oracle: good,
        actual: bad,
        exempt: kResidentExemptFormDataPointers,
      );
      expect(r.passed, isFalse, reason: 'a changed leaf must not pass');
      expect(r.toString(), contains('/applicant.house_no'));
    });

    test('F1-AC-33 the comparison is on BYTES, on Resident\'s own body', () {
      final Map<String, Object?> good = bodiesOf('en').create;

      // `{"a":1}` vs `{"a":"1"}` — a number where the wire has a string.
      final Map<String, Object?> retyped = Map<String, Object?>.of(good)
        ..['applicant.age'] = int.parse(good['applicant.age']! as String);
      expect(
        compareTier0(
          oracle: good,
          actual: retyped,
          exempt: kResidentExemptFormDataPointers,
        ).passed,
        isFalse,
        reason: 'applicant.age is a STRING on the wire (`:466`)',
      );

      // Key-order swap: same keys, same values, different bytes.
      final List<String> keys = good.keys.toList();
      final Map<String, Object?> swapped = <String, Object?>{};
      for (int i = 0; i < keys.length; i++) {
        final int j = i == 0 ? 1 : (i == 1 ? 0 : i);
        swapped[keys[j]] = good[keys[j]];
      }
      expect(
        compareTier0(
          oracle: good,
          actual: swapped,
          exempt: kResidentExemptFormDataPointers,
        ).passed,
        isFalse,
        reason: 'insertion order IS wire order (client.ts:242)',
      );
    });

    test('F1-AC-38 the clock emits the LOCAL date where UTC would be wrong',
        () {
      // Asserting only that the leaf was skipped is not sufficient: a port that
      // reintroduced `toUtc()` would also be skipped. Both halves.
      final Map<String, Object?> got = bodiesOf('en').create;
      expect(got['purpose.issue_date'], kExpectedLocal);
      final Tier0Oracle o =
          Tier0Oracle.load('$kResidentOracleDir/executed', 'resident.create.en');
      expect(o.formData['purpose.issue_date'], kExpectedWebUtc,
          reason: 'the oracle must still carry the WEB value, or the '
              'divergence has gone invisible');
    });
  });
}
