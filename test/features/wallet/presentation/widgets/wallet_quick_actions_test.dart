/// The quick-actions grid — and specifically the two **logo** tiles, which are
/// the only place in `features/wallet/` that loads a bundled raster.
///
/// ## Why this file exists at all
///
/// `_QuickTileLogo` was written to satisfy B2-AC-31's scanner, which rejects
/// `Image.asset(someVariable)` because it cannot resolve the asset behind a
/// variable and refuses to treat "I could not tell" as "it is fine". The fix
/// turned one dynamic call site into two literal ones behind a `switch`.
///
/// That fix introduces its own failure mode, and it is worse than the one it
/// replaced: the [kWalletQuickActions] table and the `switch` are now two
/// separate statements of the same fact. Editing the table alone would compile,
/// pass the scanner — the call sites are still literals — and throw
/// `ArgumentError` at first render of that tile, in a widget no unit test had
/// any reason to pump.
///
/// So this asserts the **capability**, not the wiring: it pumps the real grid
/// and reads back the `ImageProvider` Flutter actually resolved, per tile. A
/// test that merely compared the two constants to each other would pass with
/// the `switch` deleted.
library;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lcc_mobile_app/features/wallet/presentation/widgets/wallet_quick_actions.dart';

import '../../../../helpers/app_test_harness.dart';

/// Pumps the grid inside a localisation scope, since the tiles call `.tr()`.
Future<void> pumpGrid(
  WidgetTester tester, {
  ValueChanged<String>? onAction,
}) async {
  await tester.pumpWidget(
    wrapWithLocalization(
      // The `Builder` is load-bearing, not ceremony: the tiles label themselves
      // with `.tr(context: context)`, which reads the delegates off the
      // `EasyLocalization` scope. Handing `MaterialApp` no
      // `localizationsDelegates` makes every tile throw
      // `Null check operator used on a null value` — the shape
      // `tutorial_overlay_test.dart:37-49` already solved.
      Builder(
        builder: (BuildContext context) => MaterialApp(
          localizationsDelegates: context.localizationDelegates,
          supportedLocales: context.supportedLocales,
          locale: context.locale,
          home: Scaffold(
            body: SizedBox(
              width: 390,
              child: WalletQuickActions(onAction: onAction ?? (_) {}),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('B2-AC-31 — the logo tiles name their asset literally', () {
    testWidgets(
      'both logo rows resolve a real AssetImage at the table\'s path',
      (WidgetTester tester) async {
        await pumpGrid(tester);

        final Iterable<Image> images = tester.widgetList<Image>(
          find.byType(Image),
        );

        // The grid draws a raster for exactly the two rows that carry one.
        // Six of the eight tiles draw a glyph, not an image.
        expect(
          images,
          hasLength(2),
          reason: 'Exactly the `electricity` and `water` rows carry a '
              '`logoAsset`; the other six draw a LucideIcon or an Icon.',
        );

        final Set<String> resolved = images
            .map((Image i) => (i.image as AssetImage).assetName)
            .toSet();

        expect(
          resolved,
          <String>{kEdlLogoAsset, kNampapaLogoAsset},
          reason: 'The `switch` in `_QuickTileLogo` has drifted from the '
              '`kWalletQuickActions` table it renders. Both sides must name '
              'the same two constants.',
        );
      },
    );

    testWidgets(
      'every table row carrying a logoAsset is one the switch can render',
      (WidgetTester tester) async {
        // The drift this catches is a *third* row being added to the table
        // without a matching literal call site — which throws at that tile's
        // first build, not at compile time. Pumping the whole grid is what
        // makes that a test failure instead of a crash in production.
        await pumpGrid(tester);
        expect(tester.takeException(), isNull);

        final Iterable<String> tableLogos = kWalletQuickActions
            .map((WalletQuickAction a) => a.logoAsset)
            .whereType<String>();

        expect(
          tableLogos.toSet(),
          <String>{kEdlLogoAsset, kNampapaLogoAsset},
          reason: 'A logo row was added to the table. `_QuickTileLogo` needs a '
              'matching literal `Image.asset` case, or it will throw at the '
              'first render of that tile.',
        );
      },
    );

    testWidgets(
      'NEGATIVE CONTROL — the assertion rejects a non-literal render',
      (WidgetTester tester) async {
        // Would the first test fail if the discipline were violated? This is
        // the shape the rule that reopened AC-24 demands: the same assertion,
        // run against a deliberately wrong subject, must go red.
        //
        // `Image.asset` over a runtime-composed path is exactly what
        // `_QuickTileLogo` replaced. It still produces an `AssetImage`, so a
        // test that only checked the *type* would pass here — this one checks
        // the resolved name against the table and therefore does not.
        //
        // The subject is `logo-lcc.webp`: a **real, bundled** Tier B asset that
        // is simply not one of the wallet's two. An unbundled path would make
        // this test throw on decode and pass for the wrong reason — it would be
        // asserting that a missing file is missing, not that the assertion
        // discriminates between two assets that both load.
        final String smuggled = <String>[
          'assets',
          'images',
          'logo-lcc.webp',
        ].join('/');

        await tester.pumpWidget(
          MaterialApp(home: Scaffold(body: Image.asset(smuggled))),
        );
        await tester.pump();

        final AssetImage provider =
            tester.widget<Image>(find.byType(Image)).image as AssetImage;

        expect(
          <String>{kEdlLogoAsset, kNampapaLogoAsset}.contains(
            provider.assetName,
          ),
          isFalse,
          reason: 'The positive assertion above must be capable of rejecting '
              'an asset that is not one of the two declared logos.',
        );
      },
    );
  });

  group('the grid itself', () {
    testWidgets('renders all eight tiles', (WidgetTester tester) async {
      await pumpGrid(tester);
      expect(find.byType(InkWell), findsNWidgets(kWalletQuickActions.length));
      expect(kWalletQuickActions, hasLength(8));
    });

    testWidgets('a tap reports the tile id', (WidgetTester tester) async {
      final List<String> taps = <String>[];
      await pumpGrid(tester, onAction: taps.add);

      await tester.tap(find.byType(InkWell).first);
      await tester.pump();

      // `topup` is row 1 in the source's order (`WalletPage.tsx:51-60`).
      expect(taps, <String>['topup']);
    });
  });
}
