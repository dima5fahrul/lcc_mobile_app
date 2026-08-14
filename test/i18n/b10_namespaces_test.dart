/// B10's two i18n namespaces — `B10-AC-51`, `B10-AC-52`, `B10-AC-54`,
/// `B10-AC-55`.
///
/// ## The key names are DERIVED from the pinned source, not transcribed
///
/// `B10-AC-52` says the key names must match `onboarding.ts` and `tutorial.ts`
/// exactly. A test that restated the 77 names as a Dart literal would assert
/// that B10's port agrees with B10's own transcription of the source — which
/// is a tautology, and would stay green if the transcription itself dropped or
/// renamed a key. So this parses the `.ts` files at
/// `62f8a529aaa024a8b35b0af50a8fbd4850a63962` and compares against that.
/// B9's `tier1_chat_test.dart`:434-441 established the precedent for reading
/// the port source from a test.
///
/// **`sources/lcc-app` is READ-ONLY** (ADR-0001). Nothing here writes, and the
/// reads are guarded so a missing checkout reports NOT EVALUATED loudly rather
/// than passing quietly.
///
/// ## Why `lo` is checked for the same key SET but not the same values
///
/// `ssd.md`:771-772 requires both locales to carry an identical key set;
/// it does not require Lao copy to equal English copy, obviously. So the
/// `lo` assertion is set equality against `en`, and separately against the
/// source's own `lo` block.
///
/// ## `B10-AC-54` asserts UNTOUCHED, not a frozen namespace census
///
/// This AC was implemented as `en.keys.toSet() == <14 hardcoded names>`. Two
/// defects, and the second is the serious one:
///
/// 1. **It bound later batches.** It went red when `fields`/`formFields` (F0b)
///    and `payment` (B6b) were added — each mandated by its own approved spec,
///    and none of which makes a *pre-B10* namespace "touched". That is the
///    shape `ssd.md` § 4.4.1 RULING 13 ruled on for `B9-AC-10`: a batch-scoped
///    narrowing implemented as a permanent global guard is not a narrowing, it
///    is an amendment made by a document that may not amend the SSD. Growing
///    the literal by three names would have re-armed the same trap for the next
///    batch, so the literal is gone: the pre-B10 set is now DERIVED from
///    `$_base` (see [_baselineJson]), which is immutable and therefore cannot
///    go stale.
/// 2. **It never checked what its name promises.** A set of namespace *names*
///    says nothing about their contents. Measured before this rewrite:
///    `history.ref` was rewritten from `"Ref"` to `"TAMPERED …"` and the file
///    stayed **12/12 green**. The guard called "untouched" was blind to the
///    single most likely way a pre-B10 namespace gets touched.
///
/// So the property asserted is now the one `B10-AC-54` names: every namespace
/// present at `$_base` still exists, retains every key it had, and every one of
/// those keys holds a byte-identical value. Additions — new namespaces, and new
/// keys inside existing ones — are permitted, because `ssd.md`:769-770 makes
/// i18n append-only and later batches append by mandate. `B10-AC-6`
/// (`b10_scope_test.dart`:301) independently pins deletions at zero.
///
/// **Reported, not silently patched (§ 15 T-7).** `specs.md`:974 words AC-54 as
/// *byte-identical to `7db61e7`*. Read literally over the whole file that is
/// now unsatisfiable: `history`, `wallet` and `account` have each gained keys
/// since — +26, +35 and +48 respectively, with **zero** removals and **zero**
/// value changes in all three, i.e. exactly the append the SSD requires. This
/// test measures the satisfiable and discriminating reading; recording the
/// re-scope in `ssd.md` is the architect's call, not this file's.
library;

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// The pinned web source. Relative to the package root, which is where
/// `flutter test` runs.
const String _srcRoot = '../lcc-app/src/app/i18n/ns';

/// Extracts the key names of the `en:` (or `lo:`) block of an `ns({...})`
/// namespace file by brace-matching, so a nested object or a comment
/// containing a colon cannot fool it.
List<String> _keysOf(String source, String locale) {
  final int start = source.indexOf('$locale: {');
  if (start < 0) return const <String>[];

  int depth = 0;
  int i = start + locale.length + 2;
  while (i < source.length) {
    if (source[i] == '{') {
      depth++;
    } else if (source[i] == '}') {
      depth--;
      if (depth == 0) break;
    }
    i++;
  }

  final String block = source.substring(start, i);
  // Exactly four spaces of indent = a direct child of the locale block. A
  // nested object's members are indented six or more and must not be counted.
  return RegExp(r'^ {4}([A-Za-z][A-Za-z0-9_]*):', multiLine: true)
      .allMatches(block)
      .map((RegExpMatch m) => m.group(1)!)
      .toList();
}

Map<String, dynamic> _localeJson(String locale) =>
    jsonDecode(File('assets/i18n/$locale.json').readAsStringSync())
        as Map<String, dynamic>;

/// The Flutter base B10 branched from — `specs.md` metadata, same pin
/// `b10_scope_test.dart`:42 uses.
const String _base = '7db61e7';

/// `assets/i18n/$locale.json` **as it stood at [_base]**, which is what
/// `B10-AC-54` names as its comparand. Read from git rather than restated as a
/// Dart literal, for the same reason `B10-AC-52` parses the `.ts` source: a
/// transcription only proves the port agrees with its own transcription.
Map<String, dynamic> _baselineJson(String locale) {
  final ProcessResult r = Process.runSync(
    'git',
    <String>['show', '$_base:assets/i18n/$locale.json'],
    stdoutEncoding: utf8, // Lao copy is non-ASCII; systemEncoding would mangle it.
    stderrEncoding: utf8,
  );
  if (r.exitCode != 0) {
    fail(
      'NOT EVALUATED: cannot read `assets/i18n/$locale.json` at $_base, so '
      '`B10-AC-54` has no comparand and is unmeasured. This is a blocking '
      'reason, not a pass — see CLAUDE.md § Gate Status Reporting.\n'
      'git said: ${r.stderr}',
    );
  }
  return jsonDecode(r.stdout as String) as Map<String, dynamic>;
}

void main() {
  late Map<String, dynamic> en;
  late Map<String, dynamic> lo;

  setUpAll(() {
    en = _localeJson('en');
    lo = _localeJson('lo');
  });

  group('B10-AC-51 — both namespaces exist in both locales with identical '
      'key sets', () {
    for (final String ns in <String>['onboarding', 'tutorial']) {
      test('$ns is present in en.json and lo.json', () {
        expect(en.containsKey(ns), isTrue, reason: 'en.json is missing "$ns"');
        expect(lo.containsKey(ns), isTrue, reason: 'lo.json is missing "$ns"');
      });

      test('$ns has an identical key set in both locales', () {
        final Set<String> enKeys = (en[ns] as Map<String, dynamic>).keys.toSet();
        final Set<String> loKeys = (lo[ns] as Map<String, dynamic>).keys.toSet();
        expect(
          loKeys,
          enKeys,
          reason: '`ssd.md`:771-772 — additions land in BOTH locales. '
              'Only in en: ${enKeys.difference(loKeys)}; '
              'only in lo: ${loKeys.difference(enKeys)}',
        );
      });

      test('$ns has no empty value in either locale', () {
        // A key present with an empty string satisfies "identical key sets"
        // and still renders as a blank line on the splash.
        for (final MapEntry<String, Map<String, dynamic>> e
            in <String, Map<String, dynamic>>{
          'en': en[ns] as Map<String, dynamic>,
          'lo': lo[ns] as Map<String, dynamic>,
        }.entries) {
          for (final MapEntry<String, dynamic> kv in e.value.entries) {
            expect(
              (kv.value as String).trim(),
              isNotEmpty,
              reason: '${e.key}.json $ns.${kv.key} is blank',
            );
          }
        }
      });
    }

    test('the counts are 24 and 53', () {
      expect((en['onboarding'] as Map<String, dynamic>).length, 24);
      expect((lo['onboarding'] as Map<String, dynamic>).length, 24);
      expect((en['tutorial'] as Map<String, dynamic>).length, 53);
      expect((lo['tutorial'] as Map<String, dynamic>).length, 53);
    });
  });

  group('B10-AC-52 — the key names match the PINNED SOURCE exactly', () {
    for (final String ns in <String>['onboarding', 'tutorial']) {
      test('$ns.ts', () {
        final File f = File('$_srcRoot/$ns.ts');
        if (!f.existsSync()) {
          fail(
            'NOT EVALUATED: the pinned port source is not checked out at '
            '$_srcRoot/$ns.ts, so `B10-AC-52` cannot be derived. This is a '
            'blocking reason, not a pass — see CLAUDE.md § Gate Status '
            'Reporting.',
          );
        }

        final String src = f.readAsStringSync();
        final Set<String> sourceKeys = _keysOf(src, 'en').toSet();

        // Guard the parser itself: a regex that matched nothing would make
        // every assertion below vacuously true.
        expect(
          sourceKeys,
          isNotEmpty,
          reason: 'the `.ts` parser found no keys in $ns.ts — the parser is '
              'broken, not the port',
        );

        final Set<String> ported =
            (en[ns] as Map<String, dynamic>).keys.toSet();

        expect(
          ported.difference(sourceKeys),
          isEmpty,
          reason: 'B10 INVENTED keys the source does not have, in $ns',
        );
        expect(
          sourceKeys.difference(ported),
          isEmpty,
          reason: 'B10 DROPPED keys the source has, in $ns',
        );

        // And the source's own `lo` block agrees, so a namespace that was
        // ported from a stale English-only copy is caught.
        expect(_keysOf(src, 'lo').toSet(), sourceKeys);
      });
    }
  });

  group('B10-AC-54 — every pre-B10 namespace is untouched', () {
    late Map<String, Map<String, dynamic>> baseline;

    setUpAll(() {
      baseline = <String, Map<String, dynamic>>{
        'en': _baselineJson('en'),
        'lo': _baselineJson('lo'),
      };
    });

    // Non-vacuity, and it pins the BASELINE rather than the future: `$_base` is
    // an immutable commit, so "it had exactly these 12" can never be made stale
    // by a later batch. A broken `git show`, a wrong path or a silently-empty
    // parse would otherwise make every assertion below vacuously true.
    test('the pinned baseline reads back intact (guards the instrument)', () {
      for (final String locale in <String>['en', 'lo']) {
        expect(
          baseline[locale]!.keys.toSet(),
          <String>{
            'account', 'auth', 'chat', 'common', 'help', 'hero',
            'history', 'home', 'layout', 'news', 'service', 'wallet',
          },
          reason: 'the 12 namespaces § 2.1 measured at $_base. If this fails '
              'the baseline READ is broken, not the working tree.',
        );
        expect(
          baseline[locale]!.values
              .map((dynamic v) => (v as Map<String, dynamic>).length)
              .reduce((int a, int b) => a + b),
          greaterThan(100),
          reason: 'baseline $locale.json parsed to suspiciously few keys',
        );
      }
    });

    for (final String locale in <String>['en', 'lo']) {
      test('$locale.json — no pre-B10 key was dropped or reworded', () {
        final Map<String, dynamic> current = locale == 'en' ? en : lo;

        for (final MapEntry<String, dynamic> nsEntry
            in baseline[locale]!.entries) {
          final String ns = nsEntry.key;
          final Map<String, dynamic> was =
              nsEntry.value as Map<String, dynamic>;

          expect(
            current.containsKey(ns),
            isTrue,
            reason: '$locale.json DELETED the pre-B10 namespace "$ns". It '
                'exists at $_base and nothing may remove it.',
          );
          final Map<String, dynamic> now =
              current[ns] as Map<String, dynamic>;

          for (final MapEntry<String, dynamic> kv in was.entries) {
            expect(
              now.containsKey(kv.key),
              isTrue,
              reason: '$locale.json DELETED the pre-B10 key "$ns.${kv.key}". '
                  'i18n is append-only (`ssd.md`:769-770).',
            );
            expect(
              jsonEncode(now[kv.key]),
              jsonEncode(kv.value),
              reason: '$locale.json REWORDED the pre-B10 key "$ns.${kv.key}".\n'
                  '  at $_base: ${jsonEncode(kv.value)}\n'
                  '  now:       ${jsonEncode(now[kv.key])}\n'
                  'Copy owned by an earlier batch may not be edited by a '
                  'later one. If the change is wanted, it belongs to the '
                  'batch that owns "$ns", recorded in its spec.',
            );
          }
        }
      });
    }

    test('pre-B10 namespaces have not drifted between locales', () {
      for (final String ns in baseline['en']!.keys) {
        // A namespace deleted outright is the previous test's finding. Without
        // this guard the cast below throws `Null is not a Map` and reports a
        // type error instead of a named reason — observed while planting the
        // deletion mutation.
        if (!en.containsKey(ns) || !lo.containsKey(ns)) continue;
        expect(
          (en[ns] as Map<String, dynamic>).keys.toSet(),
          (lo[ns] as Map<String, dynamic>).keys.toSet(),
          reason: '$ns drifted between locales',
        );
      }
    });
  });

  test('B10-AC-55 — `lib/i18n/i18n.dart` is unmodified (frozen, ssd.md:773)',
      () {
    final ProcessResult r = Process.runSync(
      'git',
      <String>['diff', '--name-only', 'HEAD', '--', 'lib/i18n/i18n.dart'],
    );
    expect(r.exitCode, 0, reason: 'git diff failed: ${r.stderr}');
    expect(
      (r.stdout as String).trim(),
      isEmpty,
      reason: '`lib/i18n/i18n.dart` is frozen. `text(Bilingual, Lang)` is the '
          'only bilingual renderer and B10 must import it, never re-implement '
          'it — the defect four B2 features shipped.',
    );
  });

  test('B10-AC-53 — `slideOf` carries BOTH interpolation placeholders', () {
    // The rendered-semantics half of this AC lives in the splash test; this is
    // the copy half. A `slideOf` that lost `{total}` would still render, just
    // wrongly, and no widget test that only greps for "Slide" would notice.
    for (final Map<String, dynamic> m in <Map<String, dynamic>>[
      en['onboarding'] as Map<String, dynamic>,
      lo['onboarding'] as Map<String, dynamic>,
    ]) {
      final String v = m['slideOf'] as String;
      expect(v, contains('{current}'));
      expect(v, contains('{total}'));
    }
  });
}
