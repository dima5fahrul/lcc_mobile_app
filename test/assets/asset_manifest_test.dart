/// **B1b-AC-8** — no missing-asset exception at runtime, and **B1b-AC-7**'s
/// manifest half: every declared image asset *and every density rung* resolves
/// through `rootBundle`.
///
/// Why the DECLARED set and not the REFERENCED set (specs.md § 7.2, § 2.2
/// Finding A): `lib/**` references zero image assets today — B1b adds no call
/// site, and `lib/**` is frozen outright (§ 4.1). A reference-based check would
/// pass vacuously and prove nothing. Asserting the declared set is the
/// assertion with content, and it is the one that catches a mis-declared
/// directory or a missing 1x base sibling before B2/B6/B8's call sites do.
///
/// The 1x base sibling matters more than it looks: a `3.0x/` file with no base
/// sibling at the main path resolves to NOTHING (§ 6.4). Flutter's resolution
/// mechanism keys variants off the main asset, so an orphaned rung is invisible
/// at runtime rather than an error — exactly the class of defect that only
/// surfaces when a citizen opens the screen.
///
/// This test is purely additive: it removes and weakens no existing test.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Tier A (specs.md § 6.1) — photographic surfaces, single asset at the main
/// path, no density rungs (§ 6.4 rules the ladder out for this tier).
const List<String> kTierAStems = <String>[
  'civil-population',
  'immigration',
  'land-property',
  'health',
  'social-protection',
  'education',
  'transport',
  'tax-payment',
  'hero-bg',
  'bg-id',
  'user-photo',
];

/// Tier B (specs.md § 6.1) — marks/emblems, three density rungs each (§ 6.4).
const List<String> kTierBStems = <String>[
  'logo-lcc',
  'moha-sm',
  'mops-sm',
  'edl-logo',
  'nampapa-logo',
];

/// The density rung directories. Exactly `2.0x`/`3.0x` — NOT `2x`/`3x`, which
/// Flutter does not recognise and which resolve to nothing (§ 2.1 correction 5).
const List<String> kRungDirs = <String>['2.0x', '3.0x'];

const String kImageDir = 'assets/images';

/// B1b-AC-2's total budget, re-asserted here as a regression guard so a future
/// re-export cannot quietly re-import the weight this ticket removed.
const int kTotalCeilingBytes = 1048576; // 1.00 MiB

String _base(String stem) => '$kImageDir/$stem.webp';

String _rung(String dir, String stem) => '$kImageDir/$dir/$stem.webp';

/// All 26 declared image assets: 11 Tier A + 5 Tier B at the main path,
/// plus 10 Tier B density rungs.
List<String> allDeclaredImageAssets() => <String>[
      for (final String stem in kTierAStems) _base(stem),
      for (final String stem in kTierBStems) _base(stem),
      for (final String dir in kRungDirs)
        for (final String stem in kTierBStems) _rung(dir, stem),
    ];

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('B1b-AC-8 declared image assets resolve', () {
    test('the declared set is exactly 26 assets', () {
      // Guards the list above against drift: § 6.3's file count is 11 + 5 + 10.
      expect(allDeclaredImageAssets().length, 26);
      expect(allDeclaredImageAssets().toSet().length, 26,
          reason: 'declared asset paths must be unique');
    });

    test('every declared asset loads via rootBundle with non-zero length',
        () async {
      final List<String> failures = <String>[];

      for (final String key in allDeclaredImageAssets()) {
        try {
          final ByteData data = await rootBundle.load(key);
          if (data.lengthInBytes == 0) {
            failures.add('$key -> 0 bytes');
          }
        } on FlutterError catch (e) {
          // A missing declaration surfaces here, not at `flutter analyze` time
          // and not in any other unit test — it would otherwise throw when the
          // citizen opens the screen (§ 6.6).
          failures.add('$key -> ${e.message}');
        }
      }

      expect(failures, isEmpty,
          reason: 'B1b-AC-8: every declared image asset must resolve. '
              'Unresolved: $failures');
    });

    test('all 26 assets together stay within B1b-AC-2 (1,048,576 B)', () async {
      int total = 0;
      for (final String key in allDeclaredImageAssets()) {
        total += (await rootBundle.load(key)).lengthInBytes;
      }

      expect(total, lessThanOrEqualTo(kTotalCeilingBytes),
          reason: 'B1b-AC-2: the optimised set must stay under 1.00 MiB. '
              'Measured $total B.');
    });
  });

  group('B1b-AC-7 asset manifest lists every base asset and every rung', () {
    test('the manifest lists all 16 base image assets', () async {
      final AssetManifest manifest =
          await AssetManifest.loadFromAssetBundle(rootBundle);

      // `listAssets()` returns MAIN asset keys only — density rungs are
      // reported as variants of their base sibling, not as assets in their own
      // right. So the expected count here is 16, not 26.
      final Set<String> declaredImages = manifest
          .listAssets()
          .where((String key) => key.startsWith('$kImageDir/'))
          .toSet();

      final Set<String> expected = <String>{
        for (final String stem in kTierAStems) _base(stem),
        for (final String stem in kTierBStems) _base(stem),
      };

      expect(declaredImages, expected,
          reason: 'B1b-AC-7: the pubspec directory entry must register all 16 '
              'base assets. Missing: ${expected.difference(declaredImages)}; '
              'unexpected: ${declaredImages.difference(expected)}');
    });

    test('each Tier B asset registers its 2.0x and 3.0x rungs as variants',
        () async {
      final AssetManifest manifest =
          await AssetManifest.loadFromAssetBundle(rootBundle);

      for (final String stem in kTierBStems) {
        // `getAssetVariants` returns null for an asset the manifest does not
        // know at all — which is itself an B1b-AC-7 failure, so it is folded
        // into the assertion below rather than short-circuited.
        final Set<String> variantKeys =
            (manifest.getAssetVariants(_base(stem)) ?? const <AssetMetadata>[])
                .map((AssetMetadata m) => m.key)
                .toSet();

        for (final String dir in kRungDirs) {
          expect(variantKeys, contains(_rung(dir, stem)),
              reason: 'B1b-AC-7: $stem must expose its $dir rung. This is what '
                  'the single `- assets/images/` pubspec entry is asserted to '
                  'cover (§ 6.6); if it does not, § 3.1 permits adding the two '
                  'variant-directory entries. Found: $variantKeys');
        }
      }
    });

    test('Tier A assets have no density rungs (§ 6.4)', () async {
      final AssetManifest manifest =
          await AssetManifest.loadFromAssetBundle(rootBundle);

      for (final String stem in kTierAStems) {
        final Iterable<String> rungKeys =
            (manifest.getAssetVariants(_base(stem)) ?? const <AssetMetadata>[])
                .map((AssetMetadata m) => m.key)
                .where((String key) =>
                    key.contains('/2.0x/') || key.contains('/3.0x/'));

        expect(rungKeys, isEmpty,
            reason: '§ 6.4 rules a density ladder OUT for Tier A: under '
                'ADR-0002 every declared variant ships in every APK, so a rung '
                'that would never be selected is pure payload. Found: '
                '$rungKeys');
      }
    });
  });
}
