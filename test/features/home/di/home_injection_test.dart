/// Home's container — DI-1, DI-2, DI-3 and DI-6, asserted rather than assumed.
///
/// `test/core/di/dependency_injection_test.dart` covers the root graph and now
/// tears `homeInjection` down with the rest; this file is the feature's own,
/// mirroring what B2a's service block asserts inside that file. It boots the
/// **real** `DependencyInjection.init()`, so what it checks is the production
/// wiring and not a re-statement of it.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:lcc_mobile_app/core/di/dependency_injection.dart';
import 'package:lcc_mobile_app/core/network/api_client.dart';
import 'package:lcc_mobile_app/core/session/bloc/session_bloc.dart';
import 'package:lcc_mobile_app/core/storage/storage_service.dart';
import 'package:lcc_mobile_app/features/account/di/account_injection.dart';
import 'package:lcc_mobile_app/features/application/di/application_injection.dart';
import 'package:lcc_mobile_app/features/certificates/di/certificates_injection.dart';
import 'package:lcc_mobile_app/features/family_book/di/family_book_injection.dart';
import 'package:lcc_mobile_app/features/history/di/history_injection.dart';
import 'package:lcc_mobile_app/features/chat/di/chat_injection.dart';
import 'package:lcc_mobile_app/features/documents/di/documents_injection.dart';
import 'package:lcc_mobile_app/features/auth/di/auth_injection.dart';
import 'package:lcc_mobile_app/features/home/data/datasources/home_remote_datasource.dart';
import 'package:lcc_mobile_app/features/help/di/help_injection.dart';
import 'package:lcc_mobile_app/features/reference/di/reference_injection.dart';
import 'package:lcc_mobile_app/features/wallet/di/wallet_injection.dart';
import 'package:lcc_mobile_app/features/home/di/home_injection.dart';
import 'package:lcc_mobile_app/features/news/di/news_injection.dart';
import 'package:lcc_mobile_app/features/notifications/di/notifications_injection.dart';
import 'package:lcc_mobile_app/features/home/domain/repositories/home_repository.dart';
import 'package:lcc_mobile_app/features/home/domain/usecases/home_usecases.dart';
import 'package:lcc_mobile_app/features/home/presentation/bloc/home_bloc.dart';
import 'package:lcc_mobile_app/features/service/di/service_injection.dart';
import 'package:lcc_mobile_app/features/session/di/session_injection.dart';

void main() {
  setUp(() async => const DependencyInjection().init());

  tearDown(() async {
    await injection.reset();
    await sessionInjection.reset();
    await authInjection.reset();
    await serviceInjection.reset();
    await homeInjection.reset();
    // B2c's containers — see `app_test_harness.dart`'s `resetHarness`.
    await newsInjection.reset();
    await helpInjection.reset();
    // B9a's, and this file's own header predicted it: *"Adding a feature
    // container without adding its reset here breaks this file first and
    // loudly, which is the behaviour that caught it."* It did — 30 failures
    // across three DI test files, every one of them
    // `Type ApiClient is already registered inside GetIt`.
    await notificationsInjection.reset();
    // B9b's, and the prediction held a second time: without this line every
    // test after the first in this file fails with
    // `Type ApiClient is already registered inside GetIt`, thrown from
    // `ChatDatasourceInjection.inject`. B9b's § 3.1 table names
    // `test/features/chat/**` and not this file; the edit is a recorded scope
    // deviation, and the alternative is leaving three DI test files red.
    await chatInjection.reset();
    // B8a's — same failure, third occurrence. See
    // `dependency_injection_test.dart`'s note for the measured counts.
    await accountInjection.reset();
    await referenceInjection.reset();
    // B6a's, sixth occurrence — see `dependency_injection_test.dart`'s
    // tearDown for the full note. Recorded scope deviation: B6's § 3.1 names
    // `test/features/wallet/**`, not this file.
    await walletInjection.reset();
    // B7a's two — see `dependency_injection_test.dart`'s tearDown for the full
    // note. `features/application/` is page-less (specs.md § 6.2) and
    // `features/history/` holds the BLoC, so the scan discovers two containers,
    // not one. Recorded scope deviation: B7's § 3.1 names
    // `test/features/{application,history}/**`, not this file.
    await applicationInjection.reset();
    await historyInjection.reset();
    // F1's. NINTH occurrence of the same omission — and the third caught by
    // `di_teardown_completeness_test.dart` rather than by an `ApiClient is
    // already registered inside GetIt` cascade. ONE container, not two:
    // `features/certificates/` is BLoC-only and has no `data/` (`F1-AC-17`),
    // the inverse of B7a's page-less pair. F1's § 3.1 table names
    // `test/features/certificates/**` and not this file; the edit is a recorded
    // scope deviation on exactly B9a's, B9b's, B8a's, F0b's, B6a's and B7a's
    // grounds.
    await certificatesInjection.reset();
    await documentsInjection.reset();
    await familyBookInjection.reset();
    // B5's. TENTH occurrence of the same omission, and the fourth caught by
    // `di_teardown_completeness_test.dart` rather than by an `ApiClient is
    // already registered inside GetIt` cascade. `features/documents/` is
    // page-less (the third such feature) and owns a real data layer, so it is
    // one container with a datasource, a repository and two use cases behind
    // it. B5's § 3.1 table names `test/features/documents/**` and not this
    // file; the edit is a recorded scope deviation on exactly B9a's, B9b's,
    // B8a's, F0b's, B6a's, B7a's and F1's grounds.
    // F4's. TENTH occurrence of the same omission, and the first predicted by
    // the container's own doc before it happened
    // (`family_book_injection.dart:16-25`). Added by the meta-orchestrator
    // after F4's implementer was cut off mid-batch: without it,
    // `FamilyBookDatasourceInjection.inject` re-registers `ApiClient` into a
    // container the previous test left populated, and 43 tests fail with
    // `Type ApiClient is already registered inside GetIt`. Recorded scope
    // deviation on the same grounds the nine before it were.
  });

  test('DI-6: one line in init() populates the whole feature', () {
    // The defect this guards is F-3's shape: a fully-written feature that
    // nothing ever registers, so the first resolution throws at runtime and
    // the code is dead no matter what the router points at.
    expect(homeInjection<HomeRemoteDatasource>(), isA<HomeRemoteDatasource>());
    expect(homeInjection<HomeRepository>(), isA<HomeRepository>());
    expect(homeInjection<HomeBloc>(), isA<HomeBloc>());
  });

  test('all six usecases resolve', () {
    expect(homeInjection<GetHomeSummary>(), isA<GetHomeSummary>());
    expect(homeInjection<GetDigitalId>(), isA<GetDigitalId>());
    expect(homeInjection<GetPhase1Services>(), isA<GetPhase1Services>());
    expect(homeInjection<SearchServices>(), isA<SearchServices>());
    expect(homeInjection<GetFeaturedNews>(), isA<GetFeaturedNews>());
    expect(homeInjection<GetHomeFaqs>(), isA<GetHomeFaqs>());
  });

  test('DI-3: it re-exports the ROOT ApiClient rather than building a Dio', () {
    // One client, one interceptor chain. It matters more here than for the
    // catalogue: Home makes two **authenticated** reads, and a second client
    // would carry no token, so `/me/home-summary` would 401 on every call
    // while the catalogue kept working — a failure that looks like a
    // permissions problem.
    expect(
      identical(homeInjection<ApiClient>(), injection<ApiClient>()),
      isTrue,
    );
  });

  test('DI-1: the ROOT container still holds exactly three registrations', () {
    // "root container still holds exactly `StorageService`, `ApiClient`,
    // `SessionBloc`" (B2-AC-18). Adding Home must not grow it.
    expect(injection.isRegistered<StorageService>(), isTrue);
    expect(injection.isRegistered<ApiClient>(), isTrue);
    expect(injection.isRegistered<SessionBloc>(), isTrue);
    expect(injection.isRegistered<HomeRepository>(), isFalse);
    expect(injection.isRegistered<HomeBloc>(), isFalse);
  });

  test('HomeBloc is a FACTORY — a fresh one per visit to /', () async {
    // Required rather than incidental on this page: the BLoC holds a live
    // debounce `Timer` **and** the citizen's summary and digital-ID data. A
    // lazy singleton would keep one citizen's UIN and wallet balance in memory
    // across a sign-out, because the container outlives the session.
    final HomeBloc first = homeInjection<HomeBloc>();
    final HomeBloc second = homeInjection<HomeBloc>();

    expect(identical(first, second), isFalse);
    await first.close();
    await second.close();
  });

  test('DI-2: the repository is a lazy singleton, shared by all six', () {
    final HomeRepository a = homeInjection<HomeRepository>();
    final HomeRepository b = homeInjection<HomeRepository>();
    expect(identical(a, b), isTrue);

    // …and every usecase resolved the same one, rather than each closing over
    // its own. `GetHomeSummary` and `GetHomeFaqs` are the two furthest apart in
    // `HomeUsecaseInjection`, so if the hoisting ever comes back they are the
    // pair that shows it.
    expect(identical(homeInjection<GetHomeSummary>().repository, a), isTrue);
    expect(identical(homeInjection<GetHomeFaqs>().repository, a), isTrue);
  });

  test('the whole graph resolves from a cold container in one pass', () {
    // Registration order is load-bearing and every registration is lazy, so a
    // wrong order would not fail at `init()` — it would fail at first
    // resolution, i.e. at app boot. This is that first resolution.
    expect(
      () => homeInjection<HomeBloc>().close(),
      returnsNormally,
    );
  });
}
