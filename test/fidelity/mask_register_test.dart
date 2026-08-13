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

    test('the B2c addendum is recorded as not-yet-captured, not as a pair', () {
      // § 6.5.2(a): missing but CAPTURABLE. Listing it under `pairs` would
      // claim a baseline image that does not exist.
      expect(source, contains('slot: "15-news-detail"'));
      expect(source, contains('status: not captured'));
      // Matched on the fragment that survives the fold: the value is a folded
      // YAML block, so the sentence is wrapped in the file and a longer needle
      // would fail on the newline rather than on a missing rule.
      expect(source, contains('re-capturing an'));
      expect(source, contains('FAIL (B2-AC-38)'));
    });
  });

  group('baseline integrity (B2-AC-32)', () {
    test('all 28 existing PNGs are present and none was added', () {
      const String dir = '../../docs/fidelity-baseline/2026-08-13';

      for (final String locale in <String>['en', 'lo']) {
        final List<File> pngs = Directory('$dir/$locale')
            .listSync()
            .whereType<File>()
            .where((File f) => f.path.endsWith('.png'))
            .toList();

        expect(pngs, hasLength(14),
            reason: 'B2a captures nothing. 14 slots per locale, 28 total; '
                'B2c adds the 15th and nothing else may.');
      }
    });
  });
}
