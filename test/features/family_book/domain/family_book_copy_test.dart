/// **i18n — `F4-AC-52` … `F4-AC-59`.**
///
/// Two groups, 83 + 10 keys, and 25 of the 83 that must stay dead.
///
/// ## Every count here is measured against the pinned source, not transcribed
///
/// `F4-AC-52` requires the 83 be *"asserted by a test that parses the `.ts`,
/// not by a transcription"*, and the same standard is applied to the 10: the
/// `familyBookPage` group is compared against
/// `family_book_copy.dart`'s transcription of record **and** against a fresh
/// parse of `FamilyBookPage.tsx`'s `COPY` block, so a matched pair of typos in
/// the JSON and the Dart constants still fails.
///
/// F1's equivalent (`resident_scope_test.dart:282`) asserts a hardcoded 102.
/// That is the weaker instrument and this file does not copy it: a hardcoded
/// count passes when the source gains a key and the port does not.
library;

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:lcc_mobile_app/features/family_book/domain/family_book_copy.dart';
import 'package:lcc_mobile_app/features/family_book/domain/family_book_derivations.dart';

const String kNsSource = '../lcc-app/src/app/i18n/ns/familyBook.ts';
const String kPageSource = '../lcc-app/src/app/components/FamilyBookPage.tsx';

/// § 6.9's twenty-five vestigial keys — the list, in full, not a sample.
const List<String> kDeadKeys = <String>[
  'natLao', 'natThai', 'natVietnamese', 'natChinese', 'natCambodian',
  'natOther',
  'ethLao', 'ethKhmu', 'ethHmong', 'ethPhouthai', 'ethTai', 'ethOther',
  'holderNamePlaceholder', 'holderFullNamePlaceholder', 'idCardNoPlaceholder',
  'placeOfBirth', 'placeOfBirthPlaceholder', 'unitPlaceholder',
  'groupPlaceholder',
  'memberFullNamePlaceholder', 'memberPhotoHint', 'selectPlaceholder',
  'ethnicityOptional', 'uinNote', 'addMember',
];

String _read(String path) {
  final File f = File(path);
  expect(
    f.existsSync(),
    isTrue,
    reason: 'NOT EVALUATED — $path is absent, so every assertion below would '
        'pass vacuously against nothing.',
  );
  return f.readAsStringSync();
}

Map<String, dynamic> _json(String locale) =>
    jsonDecode(_read('assets/i18n/$locale.json')) as Map<String, dynamic>;

/// `ns({ en: { … }, lo: { … } })` — the keys of one locale block, in order.
///
/// Brace-matched from the locale's `{`, so a multi-line value cannot end the
/// block early: `reviewNotice` and `successBody` are both multi-line, and a
/// line-anchored scan would drop them — the exact defect
/// `test/fidelity/i18n_parse.py`'s header records having found three times.
List<String> nsKeys(String source, String locale) {
  final int at = source.indexOf('  $locale: {');
  expect(at, isNot(-1), reason: 'no `$locale:` block in $kNsSource');
  final int open = source.indexOf('{', at);
  int depth = 0;
  int i = open;
  while (i < source.length) {
    if (source[i] == '{') depth++;
    if (source[i] == '}') {
      depth--;
      if (depth == 0) break;
    }
    i++;
  }
  final String block = source.substring(open + 1, i);
  return RegExp(r'^\s{4}(\w+):', multiLine: true)
      .allMatches(block)
      .map((RegExpMatch m) => m.group(1)!)
      .toList(growable: false);
}

/// The `en`/`lo` pair of one `COPY` entry, parsed from the component source.
({String en, String lo}) copyEntry(String source, String key) {
  final int start = source.indexOf('const COPY = {');
  expect(start, isNot(-1));
  final int at = source.indexOf('\n  $key: {', start);
  expect(at, isNot(-1), reason: 'COPY.$key is not in the pinned source');
  final int close = source.indexOf('\n  },', at) >= 0 &&
          source.indexOf('\n  },', at) < source.indexOf('\n  },\n', at) + 1
      ? source.indexOf('\n  },', at)
      : source.indexOf('\n  },', at);
  final String block = source.substring(at, close > at ? close : at + 400);

  String side(String lang) {
    final RegExpMatch? m = RegExp('$lang:\\s*"((?:[^"\\\\]|\\\\.)*)"')
        .firstMatch(block);
    expect(m, isNotNull, reason: 'COPY.$key.$lang did not parse');
    return jsonDecode('"${m!.group(1)}"') as String;
  }

  return (en: side('en'), lo: side('lo'));
}

void main() {
  late String ns;
  late String page;
  late Map<String, dynamic> en;
  late Map<String, dynamic> lo;

  setUpAll(() {
    ns = _read(kNsSource);
    page = _read(kPageSource);
    en = _json('en');
    lo = _json('lo');
  });

  group('F4-AC-52 the `familyBook` group mirrors i18n/ns/familyBook.ts 1:1', () {
    test('83 keys per locale, key sets identical to the PARSED source', () {
      final List<String> webEn = nsKeys(ns, 'en');
      final List<String> webLo = nsKeys(ns, 'lo');

      expect(webEn, hasLength(83), reason: 'measured from the .ts, not assumed');
      expect(webLo, hasLength(83));
      expect(webEn, equals(webLo), reason: 'the source itself must agree');

      final Map<String, dynamic> groupEn =
          en[kFamilyBookNamespace]! as Map<String, dynamic>;
      final Map<String, dynamic> groupLo =
          lo[kFamilyBookNamespace]! as Map<String, dynamic>;

      expect(groupEn, hasLength(83));
      expect(groupLo, hasLength(83));
      expect(groupEn.keys.toSet(), equals(webEn.toSet()));
      expect(groupLo.keys.toSet(), equals(webLo.toSet()));
    });

    test('F4-AC-59 every key exists in BOTH locales', () {
      final Set<String> a =
          (en[kFamilyBookNamespace]! as Map<String, dynamic>).keys.toSet();
      final Set<String> b =
          (lo[kFamilyBookNamespace]! as Map<String, dynamic>).keys.toSet();
      expect(a.difference(b), isEmpty,
          reason: 'a key in en.json absent from lo.json is a Tier 1 failure');
      expect(b.difference(a), isEmpty);
    });

    test('the ten COPY sentences were NOT promoted into it — which would have '
        'made the count 93', () {
      final Map<String, dynamic> group =
          en[kFamilyBookNamespace]! as Map<String, dynamic>;
      for (final String dotted in kFamilyBookPageSentences.keys) {
        final String key = dotted.split('.').last;
        expect(group.containsKey(key), isFalse,
            reason: '`$key` is a COPY sentence (`:40-63`), not a namespace key');
      }
    });
  });

  group('F4-AC-53 the 25 vestigial keys are PRESENT and UNWIRED', () {
    test('all 25 exist in both locales', () {
      final Map<String, dynamic> groupEn =
          en[kFamilyBookNamespace]! as Map<String, dynamic>;
      final Map<String, dynamic> groupLo =
          lo[kFamilyBookNamespace]! as Map<String, dynamic>;
      for (final String key in kDeadKeys) {
        expect(groupEn.containsKey(key), isTrue, reason: 'en.$key');
        expect(groupLo.containsKey(key), isTrue, reason: 'lo.$key');
      }
      expect(kDeadKeys, hasLength(25));
    });

    test('none of them is referenced anywhere under features/family_book/', () {
      // The `nat*` six are the specific hazard: `:489` renders
      // `m.nationality` RAW, with no NATIONALITY_KEY map, even though six
      // nationality labels sit in the namespace. An implementer who "notices
      // the bug" and maps them makes the port render `Lao` where the web
      // renders `lao` — L-10 corollary (b).
      final List<String> hits = <String>[];
      for (final FileSystemEntity e
          in Directory('lib/features/family_book').listSync(recursive: true)) {
        if (e is! File || !e.path.endsWith('.dart')) continue;
        final String src = e.readAsStringSync();
        for (final String key in kDeadKeys) {
          if (src.contains(key)) hits.add('${e.path}: $key');
        }
      }
      expect(hits, isEmpty,
          reason: 'a hit means a dead key was wired: ${hits.join(', ')}');
    });
  });

  group('F4-AC-55/56 the `familyBookPage` group and its transcription of '
      'record', () {
    test('exactly 10 keys per locale', () {
      final Map<String, dynamic> groupEn =
          en[kFamilyBookPageNamespace]! as Map<String, dynamic>;
      final Map<String, dynamic> groupLo =
          lo[kFamilyBookPageNamespace]! as Map<String, dynamic>;
      expect(groupEn, hasLength(10));
      expect(groupLo, hasLength(10));
      expect(groupEn.keys.toSet(), equals(groupLo.keys.toSet()));
      expect(kFamilyBookPageSentences, hasLength(10));
    });

    test('the JSON equals the transcription of record, byte for byte', () {
      for (final MapEntry<String, FamilyBookSentence> e
          in kFamilyBookPageSentences.entries) {
        final String key = e.key.split('.').last;
        expect(
          (en[kFamilyBookPageNamespace]! as Map<String, dynamic>)[key],
          e.value.en,
          reason: 'en.$key',
        );
        expect(
          (lo[kFamilyBookPageNamespace]! as Map<String, dynamic>)[key],
          e.value.lo,
          reason: 'lo.$key',
        );
      }
    });

    test('and the transcription equals the PINNED SOURCE — so a matched pair '
        'of typos still fails', () {
      // This is the assertion that makes the file worth having. Comparing the
      // JSON against `family_book_copy.dart` alone proves the two Dart-side
      // copies agree with each other, which they would even if both were
      // wrong. Parsing `FamilyBookPage.tsx` puts the web between them.
      for (final MapEntry<String, FamilyBookSentence> e
          in kFamilyBookPageSentences.entries) {
        final String key = e.key.split('.').last;
        final ({String en, String lo}) web = copyEntry(page, key);
        expect(e.value.en, web.en, reason: 'COPY.$key.en');
        expect(e.value.lo, web.lo, reason: 'COPY.$key.lo');
      }
    });

    test('copyReason matches the Tier 0 oracle — this one reaches the wire',
        () {
      // The single most consequential of the ten: it is the entire request
      // body. Compared against the oracle rather than only against the source,
      // because that is the artefact Tier 0 gates on.
      for (final String locale in <String>['en', 'lo']) {
        final Map<String, dynamic> oracle = jsonDecode(_read(
          '../../docs/fidelity-baseline/2026-08-13/oracle/tier0/'
          'family-book.request.$locale.json',
        )) as Map<String, dynamic>;
        final String want = ((oracle['requestEnvelope']
                as Map<String, dynamic>)['reason']
            as Map<String, dynamic>)['value'] as String;
        expect(locale == 'en' ? kFbCopyReason.en : kFbCopyReason.lo, want);
      }
    });
  });

  group('F4-AC-58 no other i18n group changed', () {
    test('exactly two groups were added and `fields` still has 12 keys', () {
      // `tf("province")`, `tf("district")` and `tf("village")` (`:420-423`) all
      // existed already; F4 adds zero keys to that namespace, whose count is
      // pinned at twelve by `F0-AC-63`.
      expect((en['fields']! as Map<String, dynamic>), hasLength(12));
      expect((lo['fields']! as Map<String, dynamic>), hasLength(12));

      expect(en.keys.toList(), equals(lo.keys.toList()));
      expect(en.keys.last, kFamilyBookPageNamespace);
      expect(en.keys.elementAt(en.keys.length - 2), kFamilyBookNamespace);
    });
  });

  group('F4-AC-57 no `const` subtree contains a .tr() call', () {
    test('every family_book file passes the D-3 scan', () {
      // `easy_localization` resolves `.tr(context: context)` through an
      // `InheritedWidget`; a `const` subtree never rebuilds, so the string
      // freezes at the first locale the citizen saw. The scan is textual and
      // deliberately crude — it flags `const` on the same line as a `.tr(`,
      // which is how the mistake is written.
      final List<String> hits = <String>[];
      for (final FileSystemEntity e
          in Directory('lib/features/family_book').listSync(recursive: true)) {
        if (e is! File || !e.path.endsWith('.dart')) continue;
        final List<String> lines = e.readAsLinesSync();
        for (int i = 0; i < lines.length; i++) {
          final String l = lines[i];
          if (l.contains('.tr(') && RegExp(r'\bconst\b').hasMatch(l)) {
            hits.add('${e.path}:${i + 1}');
          }
        }
      }
      expect(hits, isEmpty, reason: hits.join(', '));
    });
  });
}
