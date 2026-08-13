/// **Tier 3 — the Flutter half of the paired screenshot.**
///
/// § 6.5.1 rules Tier 3 *"APPLICABLE, blocking, sampled. Pass = no unresolved
/// MAJOR. 3-iteration cap then escalate."* It is a **human** review of two
/// images side by side; this file produces the one image a human cannot get
/// any other way, and it does so under the baseline's own rig conditions so the
/// pair is comparable at all.
///
/// ## Matching the rig, and why each part matters
///
/// | Baseline (manifest) | Here |
/// |---|---|
/// | 390 CSS px wide, fixed | `setSurfaceSize(Size(390, …))` |
/// | viewport expanded to full content height | a surface taller than the page, so nothing scrolls or clips |
/// | `scale: "css"` — 1 device pixel per CSS px | `devicePixelRatio = 1` |
/// | real fonts | `loadAppFonts()` — **both** families; with only the Lao one, Latin and every ASCII digit lay out in the placeholder font |
/// | per-locale image, heights not canonical (§ 6.5.6) | one capture per locale |
///
/// The `devicePixelRatio = 1` line is the one that looks like boilerplate and
/// is not: `flutter_test` defaults to 3.0, so without it the PNG comes out
/// 1170 px wide and every side-by-side comparison is against a 3× image. The
/// manifest's own closing note warns about exactly this class of mistake — *"it
/// will look wrong even when the image is correct"*.
///
/// ## Output is gitignored, deliberately
///
/// `build/tier3/` — B2-AC-32 makes any modification to the 28 baseline PNGs an
/// automatic FAIL, and the safest way to never write one is to never write into
/// that tree. These captures are review aids, not artefacts.
///
/// ## This is not a pixel gate
///
/// § II.R-E rejected pixel-diff *as the gate*, and § 6.5.4 item 4 warns that a
/// mask register plus an image differ is exactly the shape that quietly becomes
/// one. So this file asserts only what it can honestly assert about its own
/// output — that the page renders at the rig's width, without exceptions, with
/// every card present. The comparison is a reviewer's, recorded in
/// `disparity-report-iteration-N.md`.
library;

import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lcc_mobile_app/features/service/presentation/bloc/service_bloc.dart';
import 'package:lcc_mobile_app/features/service/presentation/pages/service_page.dart';
import 'package:lcc_mobile_app/features/service/presentation/widgets/category_card.dart';

import '../helpers/service_test_helper.dart';

/// The baseline's fixed capture width.
const double kRigWidth = 390;

/// Taller than the page in either locale (measured: 1094 both), so the render
/// is the whole page rather than a viewport crop — the `fullPage` no-op the
/// manifest records as finding F-6, in Flutter form.
const double kRigHeight = 1400;

const String kOutDir = 'build/tier3';

void main() {
  for (final String locale in <String>['en', 'lo']) {
    testWidgets('captures /service at 390 CSS px — $locale',
        (WidgetTester tester) async {
      await loadAppFonts();

      tester.view.devicePixelRatio = 1.0;
      await tester.binding.setSurfaceSize(const Size(kRigWidth, kRigHeight));
      addTearDown(() async {
        await tester.binding.setSurfaceSize(null);
        tester.view.resetDevicePixelRatio();
      });

      final FakeServiceRepository repository = FakeServiceRepository();
      final ServiceBloc bloc = serviceBlocOver(repository);
      addTearDown(bloc.close);

      final GlobalKey boundary = GlobalKey();
      bloc.add(const ServiceStarted());
      await pumpServicePage(
        tester,
        bloc,
        locale: Locale(locale),
        page: null,
      );
      await settleCatalogue(tester);

      expect(tester.takeException(), isNull);
      expect(find.byType(CategoryCard), findsNWidgets(8));

      final Size page = tester.getSize(find.byType(ServicePage));
      expect(page.width, kRigWidth,
          reason: 'the pair is only comparable at the rig width');

      // `boundary` is unused for the render itself — `flutter_test` gives every
      // pumped tree a root RepaintBoundary, which is what is captured below.
      // Keeping the key documents the intent for whoever widens this to a
      // sub-region capture.
      expect(boundary, isNotNull);

      // The root RepaintBoundary `flutter_test` wraps every pumped tree in.
      // Found by type rather than by walking `renderView.child`, whose concrete
      // type is a framework detail that has changed between releases.
      final RenderRepaintBoundary render = tester.renderObject(
        find.byType(RepaintBoundary).first,
      ) as RenderRepaintBoundary;

      await tester.runAsync(() async {
        final ui.Image image = await render.toImage(pixelRatio: 1.0);
        final ByteData? png =
            await image.toByteData(format: ui.ImageByteFormat.png);
        expect(png, isNotNull);

        Directory(kOutDir).createSync(recursive: true);
        File('$kOutDir/02-service.$locale.png')
            .writeAsBytesSync(png!.buffer.asUint8List());
      });

      expect(File('$kOutDir/02-service.$locale.png').existsSync(), isTrue);
    });
  }
}
