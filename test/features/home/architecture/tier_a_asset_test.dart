/// **B2-AC-31 — Tier A asset discipline, enforced for the first time.**
///
/// > *"a test asserts every `Image.asset`/`AssetImage` referencing a Tier A
/// > asset supplies `cacheWidth`/`cacheHeight` (B1b § 6.4's forward
/// > constraint)."*
///
/// B1b § 6.4 chose one large asset per Tier A photograph over a 1x/2.0x/3.0x
/// ladder — the ladder would have cost ~+56 % of the asset budget and saved
/// nothing on the device — and paid for that choice with a **call-site
/// obligation** it could not enforce, because B1b created no call sites. B2b
/// creates eleven. This is where the obligation becomes a build failure.
///
/// ## Three tests, because one would not be enough
///
/// A source scan alone proves the *text* says `cacheWidth`. That is the shape
/// of evidence the rule that reopened AC-24 rejects:
///
/// > *A criterion is not discharged by proving a configuration value
/// > propagated; it must assert the capability that value was configured to
/// > obtain. If the test would pass with the resource empty, it is evidence for
/// > the wiring, not the criterion.*
///
/// So:
///
/// 1. **The rule** — the scan over `lib/`, which is the gate.
/// 2. **The negative control** — the same scanner over
///    `fixtures/tier_a/`, asserting it reports **exactly** the two violations
///    planted there, by `path:line`. This is the answer to "would it fail if
///    the discipline were violated?"
/// 3. **The capability** — a pumped `CategorySlider` whose eight images are
///    asserted to be real `ResizeImage` providers at the computed width. That
///    is the memory ceiling itself, not a keyword in a file, and it would fail
///    if `cacheWidth` were present but nonsense (0, null, the asset's own
///    width).
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lcc_mobile_app/features/home/presentation/widgets/category_slider.dart';
import 'package:lcc_mobile_app/features/home/presentation/widgets/tier_a_image.dart';
import 'package:lcc_mobile_app/presentation/theme/app_spacing.dart';

import '../../../architecture/layering_rules.dart';
import 'tier_a_scanner.dart';

/// Where the negative control lives.
const String kFixtureDir = 'test/features/home/architecture/fixtures/tier_a';

void main() {
  group('B2-AC-31 — the rule, over lib/', () {
    late final List<ImageCallSite> sites;

    setUpAll(() {
      sites = scanImageCalls(kLibDir);
    });

    test('the scanner is looking at something (a positive control)', () {
      // The hazard `layering_test.dart` guards against with its own
      // `isNotEmpty`: a scan that parses nothing passes trivially, which is
      // worse than failing.
      expect(
        sites,
        isNotEmpty,
        reason: 'No image call site at all was found in `lib/`, which points '
            'at the scanner rather than at the tree.',
      );
      expect(
        sites.where((ImageCallSite s) => s.isTierB),
        isNotEmpty,
        reason: 'No Tier B call site was found. The two ministry marks in the '
            'hero are `Image.asset` with a literal path, so a scanner that '
            'cannot see them cannot see a Tier A violation either.',
      );
      // And the ten Tier A paths the app actually uses are named somewhere —
      // otherwise this whole group is guarding an application with no
      // photographs in it.
      expect(
        tierAPathLiterals(kLibDir),
        hasLength(10),
        reason: 'The eight category slides plus `hero-bg` and `bg-id`. '
            '`user-photo` is the eleventh Tier A asset and must NOT appear '
            '(B2-AC-42 item 4, V-16/V-17).',
      );
    });

    test('a Tier A path can only be written inside TierAImage', () {
      // The other half of the guard, and what makes
      // `kSanctionedDynamicLoader`'s variable argument safe. If every literal
      // lives in the descriptor table, then every load goes through the helper
      // — there is no path left for a hand-written `Image.asset` to name.
      final List<String> elsewhere = tierAPathLiterals(kLibDir)
          .where((String hit) => !hit.startsWith(kSanctionedDynamicLoader))
          .toList(growable: false);

      expect(
        elsewhere,
        isEmpty,
        reason: 'A Tier A asset path is written outside the descriptor table '
            'in `tier_a_image.dart`. Even if that call site supplies a '
            '`cacheWidth`, it duplicates the decode arithmetic and puts the '
            "asset's native size in a second place.\n  "
            '${elsewhere.join('\n  ')}',
      );
    });

    test('the one unresolvable call site is the helper, and it constrains', () {
      // `TierAImage` calls `Image.asset(asset.path, …)` — a variable, which
      // the scanner cannot classify. It is listed here by name, with the
      // assertion that it *does* bound its decode, so the exemption is a
      // checked fact rather than an omission.
      final Iterable<ImageCallSite> dynamicSites =
          sites.where((ImageCallSite s) => s.asset == null);

      expect(dynamicSites, hasLength(1));
      expect(dynamicSites.single.path, kSanctionedDynamicLoader);
      expect(
        dynamicSites.single.constrainsDecode,
        isTrue,
        reason: 'The single sanctioned dynamic loader stopped supplying a '
            'cacheWidth, which silently un-bounds every Tier A decode in the '
            'app at once.',
      );
    });

    test('every Tier A call site constrains its decode', () {
      final List<String> violations = tierAViolations(sites);

      expect(
        violations,
        isEmpty,
        reason: 'B1b § 6.4: a Tier A asset ships at its 3x size with no '
            'density ladder, so the call site is what stops Flutter decoding '
            'the full bitmap. Eight category slides at 864x1152 RGBA is 31.8 '
            'MB of image cache for a strip that paints 281x360 boxes. Load it '
            'through `TierAImage`, which computes '
            '`min(native, ceil(logical x devicePixelRatio))`.\nOffenders:\n  '
            '${violations.join('\n  ')}',
      );
    });

    test('no OTHER call site hides its asset behind a variable', () {
      // `Image.asset(somePath)` is not a violation of the rule — it is a hole
      // in the guard, and it fails separately so the two are never confused.
      // The helper's own site is excluded by name, having just been asserted
      // above to be the only one and to bound its decode.
      final List<String> unresolved = unresolvedTierACandidates(sites)
          .where((String c) => !c.startsWith(kSanctionedDynamicLoader))
          .toList(growable: false);

      expect(
        unresolved,
        isEmpty,
        reason: 'This scanner reads the asset path as a string literal. A call '
            'site that computes it cannot be classified, so it could be a Tier '
            'A load with no `cacheWidth` and this guard would not know. Name '
            'the asset at the call site, or route it through `TierAImage`.\n  '
            '${unresolved.join('\n  ')}',
      );
    });
  });

  group('B2-AC-31 — the negative control (would it fail?)', () {
    late final List<ImageCallSite> fixture;

    setUpAll(() {
      fixture = scanImageCalls(kFixtureDir);
    });

    test('the fixture is parsed at all', () {
      expect(
        fixture,
        hasLength(4),
        reason: 'The fixture plants four call sites. Finding a different '
            'number means the scanner is not reading them, and every '
            'assertion below would then be vacuous.',
      );
    });

    test('it reports EXACTLY the two planted violations, by path and line', () {
      final List<String> violations = tierAViolations(fixture);

      // Count and citation, not merely non-empty — B2-AC-7's standard for the
      // layering guards, applied here. A scanner that flagged all four would
      // be "failing correctly" by accident and would fail the real tree too.
      expect(violations, hasLength(2), reason: violations.join('\n  '));

      expect(
        violations[0],
        'violating_widget.dart:43 -> '
        'Image.asset(assets/images/civil-population.webp)',
      );
      expect(
        violations[1],
        'violating_widget.dart:46 -> AssetImage(assets/images/hero-bg.webp)',
      );
    });

    test('the compliant Tier A call is NOT reported — the nested-call case',
        () {
      // Site (3): `cacheWidth: math.min(1000, (350 * 3).ceil())`. A scanner
      // that read to the first `)` would stop inside `math.min(` and conclude
      // there was no `cacheWidth`, failing a correct call site. This asserts
      // the balanced-paren reader.
      final ImageCallSite compliant = fixture.firstWhere(
        (ImageCallSite s) => s.asset == 'assets/images/bg-id.webp',
      );

      expect(compliant.isTierA, isTrue);
      expect(compliant.hasCacheWidth, isTrue);
      expect(compliant.constrainsDecode, isTrue);
      expect(tierAViolations(fixture), isNot(contains(compliant.citation)));
    });

    test('the Tier B call is NOT reported — B1b § 6.4 exempts the ladder', () {
      final ImageCallSite tierB = fixture.firstWhere(
        (ImageCallSite s) => s.asset == 'assets/images/moha-sm.webp',
      );

      expect(tierB.isTierB, isTrue);
      expect(tierB.isTierA, isFalse);
      expect(tierB.constrainsDecode, isFalse,
          reason: 'and that is correct — the density ladder makes the '
              'call-site discipline unnecessary');
      expect(tierAViolations(fixture), isNot(contains(tierB.citation)));
    });
  });

  group('B2-AC-31 — the arithmetic', () {
    const TierAAsset slide = TierAAsset(
      path: 'assets/images/civil-population.webp',
      nativeWidth: 864,
      nativeHeight: 1152,
    );

    test('a 281 px box on a 3x screen decodes at 843, not at 864', () {
      // The exact case B1b § 6.3 sized the asset for: "the cover box is 281x360
      // CSS at a 0.781 aspect, the 3:4 source is narrower, so width binds — 843
      // device px at 3x."
      expect(
        TierAImage.decodeWidthFor(slide, AppSpacing.categorySlideWidth, 3),
        843,
      );
    });

    test('the same box on a 2x screen halves it — the real saving', () {
      // 562 vs 864 per slide, and 8 slides on the strip: 13.5 MB instead of
      // 31.8 MB. This is the number the whole criterion is about.
      expect(
        TierAImage.decodeWidthFor(slide, AppSpacing.categorySlideWidth, 2),
        562,
      );
    });

    test('it never asks for more than the asset has', () {
      // B1b § 6.2's "never upscale", applied at the call site: a 400 px box on
      // a 3x screen wants 1200, and the asset has 864.
      expect(TierAImage.decodeWidthFor(slide, 400, 3), 864);
    });

    test('it ceils rather than rounds', () {
      // 281 x 2.625 = 737.6. Rounding down would decode one pixel short of the
      // paint box and upsample at draw time — the softness this exists to
      // avoid.
      expect(TierAImage.decodeWidthFor(slide, 281, 2.625), 738);
    });

    test('a zero-width box during layout does not ask for a 0 px decode', () {
      expect(TierAImage.decodeWidthFor(slide, 0, 3), 1);
    });
  });

  group('B2-AC-31 — the capability, not the keyword', () {
    testWidgets('every slide resolves to a ResizeImage bounded by the box',
        (WidgetTester tester) async {
      // The assertion that would still fail if `cacheWidth` were present but
      // wrong. `Image.asset(cacheWidth: n)` produces a `ResizeImage` wrapping
      // the `AssetImage`; without it the provider is a bare `AssetImage` and
      // the decode is the asset's full 864x1152. So the *type* is the evidence,
      // and the width on it is the bound.
      tester.view.devicePixelRatio = 3.0;
      tester.view.physicalSize = const Size(390 * 3, 844 * 3);
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('en'),
          localizationsDelegates: const <LocalizationsDelegate<Object>>[
            DefaultMaterialLocalizations.delegate,
            DefaultWidgetsLocalizations.delegate,
          ],
          home: Scaffold(
            body: CategorySlider(onSlideTap: () {}),
          ),
        ),
      );
      await tester.pump();

      final Iterable<Image> images = tester.widgetList<Image>(
        find.byType(Image),
      );

      expect(images, isNotEmpty, reason: 'no slide photograph rendered');

      for (final Image image in images) {
        expect(
          image.image,
          isA<ResizeImage>(),
          reason: 'a Tier A slide resolved to a bare provider, so Flutter will '
              'decode the full 864x1152 bitmap — exactly the 4 MB-per-slide '
              'waste B1b § 6.4 named',
        );

        final ResizeImage resized = image.image as ResizeImage;
        expect(
          resized.width,
          843,
          reason: '281 logical px at devicePixelRatio 3, capped at the '
              "asset's native 864",
        );
        expect(
          resized.width! < 864,
          isTrue,
          reason: 'a decode at or above native is not a constrained decode, '
              'whatever the argument list says',
        );
      }
    });

    testWidgets('the bound tracks the device, not a hardcoded number',
        (WidgetTester tester) async {
      // If someone replaced the arithmetic with a constant, the previous test
      // would still pass. This one pumps the same widget at 1x and asserts the
      // decode followed.
      tester.view.devicePixelRatio = 1.0;
      tester.view.physicalSize = const Size(390, 844);
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('en'),
          localizationsDelegates: const <LocalizationsDelegate<Object>>[
            DefaultMaterialLocalizations.delegate,
            DefaultWidgetsLocalizations.delegate,
          ],
          home: Scaffold(body: CategorySlider(onSlideTap: () {})),
        ),
      );
      await tester.pump();

      final Image first = tester.widgetList<Image>(find.byType(Image)).first;
      expect((first.image as ResizeImage).width, 281);
    });
  });
}
