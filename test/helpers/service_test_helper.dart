/// Standing the service catalogue up in a widget test.
///
/// Two things live here: a repository double whose answers are configurable
/// per call, and the real 43-row / 8-category staging payloads parsed through
/// the **production models**.
///
/// ## Why the payloads are recorded, not hand-written (B2-AC-36)
///
/// specs.md § 5 flags the trap: `/news` and `/help/faqs` return plain strings
/// where sibling endpoints return `{en,lo}` objects, and *"a model that assumes
/// one shape for both will parse-fail at runtime on real staging data, and the
/// failure surfaces as an error state that looks like a network problem."*
/// Hand-written fixtures are written to match the model, so they cannot catch
/// that class of bug — they are a restatement of the developer's belief about
/// the wire. These rows are what `GET /services` and `GET /service-categories`
/// actually answered on 2026-08-13, byte for byte, versioned under
/// `oracle/api/`, and they are parsed here by `ServiceModel.fromJson` /
/// `ServiceCategoryModel.fromJson` — the same code path the app runs.
///
/// That also means these fixtures are the Tier 1 oracle's own input, so the
/// page under test and the expectation are fed from one recording rather than
/// two that could drift.
library;

import 'dart:io';
import 'dart:typed_data';

import 'package:dartz/dartz.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show FontLoader;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lcc_mobile_app/core/error/failure.dart';
import 'package:lcc_mobile_app/features/service/data/models/service_category_model.dart';
import 'package:lcc_mobile_app/features/service/data/models/service_model.dart';
import 'package:lcc_mobile_app/features/service/domain/entities/service.dart';
import 'package:lcc_mobile_app/features/service/domain/entities/service_category.dart';
import 'package:lcc_mobile_app/features/service/domain/repositories/service_repository.dart';
import 'package:lcc_mobile_app/features/service/domain/usecases/get_service_categories.dart';
import 'package:lcc_mobile_app/features/service/domain/usecases/get_services.dart';
import 'package:lcc_mobile_app/features/service/presentation/bloc/service_bloc.dart';
import 'package:lcc_mobile_app/features/service/presentation/pages/service_page.dart';
import 'package:lcc_mobile_app/presentation/theme/app_theme.dart';
import 'package:lcc_mobile_app/presentation/theme/app_typography.dart';

import '../fidelity/oracle.dart';
import 'app_test_harness.dart';

// ── The real fonts ───────────────────────────────────────────────────────────

/// The bundled Lao faces, in `pubspec.yaml`'s order. Repo-relative; the test
/// process' CWD is the package root.
const List<String> kNotoSansLaoFaces = <String>[
  'assets/fonts/NotoSansLao-Regular.ttf',
  'assets/fonts/NotoSansLao-Bold.ttf',
];

/// The Roboto faces, relative to `$FLUTTER_ROOT`.
///
/// **From the SDK, not from the repo and not from Android Studio.** Every
/// checkout that can run `flutter test` has these, so the harness is
/// reproducible by construction rather than an accident of one workstation's
/// installed IDE — and nothing is added to the repo to get them.
const List<String> kRobotoFacesUnderFlutterRoot = <String>[
  'bin/cache/artifacts/material_fonts/Roboto-Regular.ttf',
  'bin/cache/artifacts/material_fonts/Roboto-Bold.ttf',
];

/// Absolute paths to the Roboto faces, resolved from the test process'
/// `FLUTTER_ROOT`.
///
/// Throws rather than degrading: a harness that silently skipped the fallback
/// would put us back where AC-24 started — Latin laid out in the placeholder
/// font, and every measurement of it worthless.
List<File> robotoFaceFiles() {
  final String? root = Platform.environment['FLUTTER_ROOT'];
  if (root == null || root.isEmpty) {
    throw StateError(
      'FLUTTER_ROOT is unset. The Tier 3 rig resolves Roboto from '
      '\$FLUTTER_ROOT/bin/cache/artifacts/material_fonts/; without it the '
      'Latin half of every capture is the placeholder font, which is the '
      'defect AC-24 reopened for.',
    );
  }
  return kRobotoFacesUnderFlutterRoot
      .map((String rel) => File('$root/$rel'))
      .toList(growable: false);
}

/// Every face in the resolved chain, primary first — the same order
/// [AppTypography.fontFamily] + [AppTypography.fontFamilyFallback] declares.
///
/// This is what a coverage assertion must read. Reading only the first entry
/// is how a Lao-only subset passed AC-24 at `bda76a1`.
List<File> appFontChainFaces() => <File>[
      ...kNotoSansLaoFaces.map(File.new),
      ...robotoFaceFiles(),
    ];

/// Registers **both** families of the app's font chain with the test renderer.
///
/// **Without this, every locale lays out in the placeholder font**, whose
/// glyphs are all the same uniform box: a Lao string and an English string of
/// the same length measure the same, and any assertion about one wrapping
/// differently from the other is vacuous — it passes or fails on character
/// count, not on typography.
///
/// **Both families, because one is not enough, and that is the whole lesson of
/// `bda76a1`.** The predecessor of this function loaded `NotoSansLao` only and
/// its docstring claimed that gave the renderer real metrics. It gave real
/// metrics to **Lao only**: the bundled faces are Lao-only subsets (0/26 A–Z,
/// 0/10 ASCII digits, verified at the `cmap`), so English stayed in the
/// placeholder font and every ASCII numeral — including the `13 ບໍລິການ`
/// counts and the fee amounts in the **`lo`** capture — drew as a box. A
/// measurement taken against that state is not a measurement of this app.
///
/// `Roboto` comes from the Flutter SDK ([robotoFaceFiles]) rather than the
/// repo, mirroring production, where it is the platform face and equally
/// unbundled.
Future<void> loadAppFonts() async {
  Future<void> register(String family, List<File> faces) async {
    final FontLoader loader = FontLoader(family);
    for (final File file in faces) {
      if (!file.existsSync()) {
        throw StateError('${file.path} is required by the font chain '
            '($family) but absent on disk');
      }
      loader.addFont(
        Future<ByteData>.value(ByteData.sublistView(file.readAsBytesSync())),
      );
    }
    await loader.load();
  }

  await register(
    AppTypography.fontFamily,
    kNotoSansLaoFaces.map(File.new).toList(growable: false),
  );
  await register(
    AppTypography.fontFamilyFallback.single,
    robotoFaceFiles(),
  );
}

// ── Coverage, read out of the file ───────────────────────────────────────────

/// The set of code points a face's `cmap` actually maps to a glyph.
///
/// **Parsed, never inferred.** `NotoSansLao-Regular.ttf` is named for a family
/// whose Google Fonts release *does* carry Latin; the AOSP subset of the same
/// name does not. The filename, the family name, the `pubspec.yaml` entry and
/// the file's existence on disk are each compatible with an empty face — so
/// none of them is evidence of coverage, and this reads the table instead.
///
/// Handles the two subtable formats these faces use: 4 (BMP) and 12 (full).
Set<int> cmapCodePoints(File face) {
  final ByteData d = ByteData.sublistView(face.readAsBytesSync());

  int? cmapOffset;
  final int numTables = d.getUint16(4);
  for (int i = 0; i < numTables; i++) {
    final int rec = 12 + i * 16;
    final String tag = String.fromCharCodes(
      Uint8List.sublistView(d, rec, rec + 4),
    );
    if (tag == 'cmap') cmapOffset = d.getUint32(rec + 8);
  }
  if (cmapOffset == null) {
    throw StateError('${face.path} has no cmap table');
  }

  // Prefer a full-repertoire (3,10) subtable, else BMP (3,1) / Unicode (0,x).
  int? best;
  int bestRank = -1;
  final int subtables = d.getUint16(cmapOffset + 2);
  for (int i = 0; i < subtables; i++) {
    final int rec = cmapOffset + 4 + i * 8;
    final int platform = d.getUint16(rec);
    final int encoding = d.getUint16(rec + 2);
    final int offset = d.getUint32(rec + 4);
    final int rank = switch ((platform, encoding)) {
      (3, 10) => 3,
      (0, 4) || (0, 6) => 2,
      (3, 1) => 1,
      (0, 3) => 1,
      _ => -1,
    };
    if (rank > bestRank) {
      bestRank = rank;
      best = cmapOffset + offset;
    }
  }
  if (best == null) {
    throw StateError('${face.path} has no Unicode cmap subtable');
  }

  final Set<int> cps = <int>{};
  final int format = d.getUint16(best);
  if (format == 4) {
    final int segCountX2 = d.getUint16(best + 6);
    final int segCount = segCountX2 ~/ 2;
    final int endBase = best + 14;
    final int startBase = endBase + segCountX2 + 2;
    final int deltaBase = startBase + segCountX2;
    final int rangeBase = deltaBase + segCountX2;
    for (int s = 0; s < segCount; s++) {
      final int end = d.getUint16(endBase + s * 2);
      final int start = d.getUint16(startBase + s * 2);
      final int delta = d.getInt16(deltaBase + s * 2);
      final int rangeOffset = d.getUint16(rangeBase + s * 2);
      if (start == 0xFFFF) continue;
      for (int c = start; c <= end; c++) {
        int glyph;
        if (rangeOffset == 0) {
          glyph = (c + delta) & 0xFFFF;
        } else {
          final int gi = rangeBase + s * 2 + rangeOffset + (c - start) * 2;
          if (gi + 2 > d.lengthInBytes) continue;
          glyph = d.getUint16(gi);
          if (glyph != 0) glyph = (glyph + delta) & 0xFFFF;
        }
        if (glyph != 0) cps.add(c);
      }
    }
  } else if (format == 12) {
    final int groups = d.getUint32(best + 12);
    for (int i = 0; i < groups; i++) {
      final int g = best + 16 + i * 12;
      final int startChar = d.getUint32(g);
      final int endChar = d.getUint32(g + 4);
      for (int c = startChar; c <= endChar; c++) {
        cps.add(c);
      }
    }
  } else {
    throw StateError('${face.path}: unsupported cmap format $format');
  }
  return cps;
}

/// The union of every face in the resolved chain — what the app can actually
/// draw, as opposed to what any single declared family can.
Set<int> appFontChainCoverage() =>
    appFontChainFaces().map(cmapCodePoints).reduce((Set<int> a, Set<int> b) {
      a.addAll(b);
      return a;
    });

/// Every distinct code point the `/service` page renders, across **both**
/// locales and all nine states.
///
/// Read out of the Tier 1 oracle rather than hand-listed, so the coverage
/// assertion cannot drift from what the page actually presents: a new string
/// with a character the chain cannot draw arrives here automatically.
///
/// The oracle is data-driven, so it contains only the digits the recorded
/// catalogue happens to produce. Callers assert the **class** `0`–`9`, not
/// this set alone — see `service_page_test.dart`.
Set<int> renderedCodePoints() {
  final Set<int> cps = <int>{};
  for (final String locale in const <String>['en', 'lo']) {
    final Map<String, dynamic> oracle = loadTier1('service', locale);
    final Map<String, dynamic> views = oracle['views'] as Map<String, dynamic>;
    for (final String view in views.keys) {
      for (final OracleNode node in tier1View(oracle, view)) {
        cps.addAll(node.text.runes);
      }
    }
  }
  return cps;
}

// ── The recorded catalogue ───────────────────────────────────────────────────

/// The 8 recorded categories, parsed by the production model.
List<ServiceCategory> recordedCategories() => loadApi('service-categories')
    .map((Map<String, dynamic> row) =>
        ServiceCategoryModel.fromJson(row).toEntity())
    .toList(growable: false);

/// The 43 recorded services, parsed by the production model.
List<Service> recordedServices() => loadApi('services')
    .map((Map<String, dynamic> row) => ServiceModel.fromJson(row).toEntity())
    .toList(growable: false);

/// The recorded services in one category, in server order.
///
/// The API applies `category` itself (`ServicePage.tsx:301`: *"search and
/// category are handed to the API, not filtered here"*), so this stands in for
/// the server's own filtering — verified against the live endpoint on
/// 2026-08-13: `/services?category=civil` returned exactly these 13 codes.
List<Service> recordedServicesIn(String categoryCode) => recordedServices()
    .where((Service s) => s.categoryCode == categoryCode)
    .toList(growable: false);

// ── The repository double ────────────────────────────────────────────────────

/// A [ServiceRepository] whose answers a test sets, and whose calls it can read
/// back.
///
/// Hand-written rather than a `mocktail` mock because two of the behaviours
/// under test are about *what was asked for* — B2-AC-34's "no availability
/// gating" and B2-AC-35's "server order, no client re-sort" both need the
/// recorded arguments, and a stub that records is clearer at the call site than
/// a `verify(() => ...)` chain.
class FakeServiceRepository implements ServiceRepository {
  FakeServiceRepository({
    List<ServiceCategory>? categories,
    List<Service>? services,
  })  : _categories = Right<Failure, List<ServiceCategory>>(
          categories ?? recordedCategories(),
        ),
        _services =
            Right<Failure, List<Service>>(services ?? recordedServices());

  Either<Failure, List<ServiceCategory>> _categories;
  Either<Failure, List<Service>> _services;

  /// Every `getServices` call's arguments, in order.
  final List<({String? search, String? category})> serviceCalls =
      <({String? search, String? category})>[];

  /// How many times `getCategories` was called. Retry asserts on this.
  int categoryCalls = 0;

  /// Rows the next `getServices` returns, overriding the recorded catalogue.
  /// Null restores the recording.
  List<Service>? nextServices;

  /// How long a call takes to answer.
  ///
  /// Zero by default, which is what most tests want. It exists because the
  /// **loading** state is otherwise unobservable: with an instant repository
  /// the very first `pump()` after dispatching an event already carries the
  /// resolved data, and a test that tried to assert on the skeleton would
  /// assert on the grid instead — passing or failing for a reason unrelated to
  /// what it claims to check. § 6.6 makes loading one of four mandatory,
  /// *distinguishable* states, so it has to be reachable on demand.
  Duration latency = Duration.zero;

  Future<void> _wait() async {
    if (latency > Duration.zero) {
      await Future<void>.delayed(latency);
    }
  }

  void failCategories() =>
      _categories = const Left<Failure, List<ServiceCategory>>(
        Failure('stubbed categories failure'),
      );

  void failServices() => _services =
      const Left<Failure, List<Service>>(Failure('stubbed services failure'));

  void succeed({List<ServiceCategory>? categories, List<Service>? services}) {
    _categories = Right<Failure, List<ServiceCategory>>(
      categories ?? recordedCategories(),
    );
    _services = Right<Failure, List<Service>>(services ?? recordedServices());
  }

  @override
  Future<Either<Failure, List<ServiceCategory>>> getCategories() async {
    categoryCalls++;
    await _wait();
    return _categories;
  }

  @override
  Future<Either<Failure, List<Service>>> getServices({
    String? search,
    String? category,
  }) async {
    serviceCalls.add((search: search, category: category));
    await _wait();
    final List<Service>? override = nextServices;
    if (override != null && _services.isRight()) {
      return Right<Failure, List<Service>>(override);
    }
    return _services;
  }
}

/// A [ServiceBloc] over [repository], wired exactly as production wires it.
ServiceBloc serviceBlocOver(FakeServiceRepository repository) => ServiceBloc(
      getServiceCategories: GetServiceCategories(repository: repository),
      getServices: GetServices(repository: repository),
    );

// ── Pumping the page ─────────────────────────────────────────────────────────

/// Pumps [ServicePage] under [bloc], localised to [locale].
///
/// `BlocProvider.value`, not `create:`, because the test owns the BLoC's
/// lifetime — it needs to drive events and read state after the frame. In
/// production the route builder uses `create:` and owns it; that difference is
/// deliberate and is why `app_routes.dart` carries its own note.
///
/// **Does not settle.** Several states under test show the loading skeleton,
/// whose pulse animation repeats forever, and `pumpAndSettle` would time out on
/// it. Callers pump explicitly.
Future<void> pumpServicePage(
  WidgetTester tester,
  ServiceBloc bloc, {
  Locale locale = const Locale('en'),
  ServicePage? page,
}) async {
  await tester.pumpWidget(
    wrapWithLocalization(
      startLocale: locale,
      Builder(
        builder: (BuildContext context) => MaterialApp(
          theme: AppTheme.light(),
          localizationsDelegates: context.localizationDelegates,
          supportedLocales: context.supportedLocales,
          locale: context.locale,
          home: Scaffold(
            body: BlocProvider<ServiceBloc>.value(
              value: bloc,
              child: page ?? const ServicePage(),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
}

/// How long [FakeServiceRepository.latency] is set to when a test wants to
/// observe the loading state. Any non-zero value works; a named one keeps the
/// test and the settle helper from disagreeing about how long to wait.
const Duration kStubLatency = Duration(milliseconds: 500);

/// Pumps past the debounce window and any stubbed latency, without ever
/// calling `pumpAndSettle` (see [pumpServicePage]).
Future<void> settleCatalogue(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(
    kSearchDebounce + kStubLatency + const Duration(milliseconds: 50),
  );
  await tester.pump();
}
