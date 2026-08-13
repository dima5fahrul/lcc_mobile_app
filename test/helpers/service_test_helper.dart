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

// ── The real font ────────────────────────────────────────────────────────────

/// Registers the bundled `NotoSansLao` faces with the test renderer.
///
/// **Without this, every locale lays out identically.** `flutter_test` renders
/// with a placeholder font whose glyphs are all the same box, so a Lao string
/// and an English string of the same length measure the same and any
/// assertion about one wrapping differently from the other is vacuous — it
/// passes or fails on character count, not on typography. B2-AC-15 claims the
/// Lao page is *taller*, which the baseline measures at 1491 vs 1404; proving
/// that in a widget test requires the renderer to have the real metrics.
///
/// Loads the same two `.ttf` files `pubspec.yaml` bundles, off disk, so the
/// family under test is the shipped one and not a stand-in.
Future<void> loadNotoSansLao() async {
  final FontLoader loader = FontLoader(AppTypography.fontFamily);
  for (final String face in const <String>[
    'assets/fonts/NotoSansLao-Regular.ttf',
    'assets/fonts/NotoSansLao-Bold.ttf',
  ]) {
    final File file = File(face);
    if (!file.existsSync()) {
      throw StateError('$face is bundled by pubspec.yaml but absent on disk');
    }
    loader.addFont(
      Future<ByteData>.value(ByteData.sublistView(file.readAsBytesSync())),
    );
  }
  await loader.load();
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
