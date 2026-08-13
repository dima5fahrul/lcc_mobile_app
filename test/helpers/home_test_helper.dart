/// Standing Home up in a test.
///
/// A repository double whose five answers a test sets per call, plus the pump
/// helpers, plus the fixtures.
///
/// ## On the fixtures, and an honest gap in B2-AC-36
///
/// B2-AC-36 asks for mixed wire shapes *"proven against **real recorded
/// staging payloads** in a fixture, not hand-written JSON"*. B2a recorded two
/// endpoints — `/services` and `/service-categories` — under
/// `docs/fidelity-baseline/2026-08-13/oracle/api/`. It recorded **none** of
/// Home's other four, and B2b has no authenticated staging identity with which
/// to record `/me/home-summary` or `/me/digital-id` (that is F0's blocking
/// question, § 6.5.2(b)).
///
/// So this file splits them, and says which is which rather than letting a
/// hand-written map pass as evidence:
///
/// * **`/services`** — [recordedPhase1Services] parses the **real recording**,
///   through the production `serviceFrom`. It is the endpoint that carries the
///   `{en,lo}` objects, the `required_docs` list and the one fee range, so it
///   is also where the mixed-shape risk actually lives for B2b.
/// * **`/news`, `/help/faqs`, `/me/*`** — hand-written, and labelled. They are
///   still worth having (they exercise the plain-string branch § 5 warns
///   about, which is the *whole* point of the criterion) but they are not
///   recordings and this doc is the record that B2-AC-36 is **PARTIAL** for
///   B2b's four unrecorded endpoints.
library;

import 'package:dartz/dartz.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lcc_mobile_app/core/error/failure.dart';
import 'package:lcc_mobile_app/core/session/bloc/session_bloc.dart';
import 'package:lcc_mobile_app/features/home/data/models/home_wire.dart';
import 'package:lcc_mobile_app/features/home/domain/entities/digital_id_card.dart';
import 'package:lcc_mobile_app/features/home/domain/entities/home_faq_item.dart';
import 'package:lcc_mobile_app/features/home/domain/entities/home_news_item.dart';
import 'package:lcc_mobile_app/features/home/domain/entities/home_summary.dart';
import 'package:lcc_mobile_app/features/home/domain/repositories/home_repository.dart';
import 'package:lcc_mobile_app/features/home/domain/usecases/home_usecases.dart';
import 'package:lcc_mobile_app/features/home/presentation/bloc/home_bloc.dart';
import 'package:lcc_mobile_app/features/home/presentation/pages/home_page.dart';
import 'package:lcc_mobile_app/features/service/domain/entities/service.dart';
import 'package:lcc_mobile_app/presentation/theme/app_theme.dart';

import '../fidelity/oracle.dart';
import 'app_test_harness.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Fixtures
// ─────────────────────────────────────────────────────────────────────────────

/// The **six recorded phase-1 rows**, parsed by the production `serviceFrom`.
///
/// `GET /services?phase1=true` is not itself recorded; the unfiltered 43-row
/// recording is, and `is_phase1` is one of its columns, so filtering it here is
/// the server's own answer rather than an invented one. Verified against the
/// recording: exactly six, all `civil`, codes `resident` · `birth` · `death` ·
/// `marriage` · `divorce` · `family-book` — the same six
/// `DEFAULT_HOME_SERVICES` names at `HomePage.tsx:43-50`.
List<Service> recordedPhase1Services() => loadApi('services')
    .map(serviceFrom)
    .where((Service s) => s.isPhase1)
    .toList(growable: false);

/// The whole recorded catalogue, for the search path.
List<Service> recordedCatalogue() =>
    loadApi('services').map(serviceFrom).toList(growable: false);

/// **Hand-written** — see the library doc. A signed-in citizen with work
/// pending, so the tiles, the wallet formatting and the banner all have input.
HomeSummary tHomeSummary({HomeNextAction? nextAction}) => HomeSummary(
      name: 'Bounmy Sisavath',
      verified: true,
      eidVerified: true,
      activeApplications: 2,
      readyDocuments: 1,
      unreadNotifications: 3,
      walletBalanceLak: 145000,
      nextAction: nextAction,
      generatedAt: '2026-08-13T09:00:00Z',
    );

/// **Hand-written.**
const HomeNextAction tNextAction = HomeNextAction(
  action: 'reupload',
  tab: 'history',
  referenceNo: 'RC-2026-004821',
);

/// **Hand-written.**
const DigitalIdCard tDigitalId = DigitalIdCard(
  uin: '1-2540-08842-99',
  cardNo: 'LA-0001',
  qrPayload: 'https://verify.example/la/abc123',
);

/// **Hand-written**, three articles.
List<HomeNewsItem> tNews() => <HomeNewsItem>[
      newsItemFrom(<String, dynamic>{
        'id': 'n1',
        'slug': 'new-service-online',
        'category_name': <String, dynamic>{'en': 'Announcement', 'lo': 'ແຈ້ງການ'},
        'category_color': '#344EAD',
        'title': <String, dynamic>{
          'en': 'Vehicle registration is now online',
          'lo': 'ການຂຶ້ນທະບຽນລົດອອນລາຍແລ້ວ',
        },
        'excerpt': <String, dynamic>{
          'en': 'Renew without visiting an office.',
          'lo': 'ຕໍ່ອາຍຸໂດຍບໍ່ຕ້ອງໄປຫ້ອງການ.',
        },
        'published_date': '2026-08-06',
      }),
      newsItemFrom(<String, dynamic>{
        'id': 'n2',
        'slug': 'office-hours',
        // § 5's plain-string shape, on the endpoint § 5 names.
        'category_name': 'Notice',
        'title': 'Updated office hours',
        'excerpt': 'District offices open at 08:00 from September.',
        'published_at': '2026-09-01T00:00:00Z',
      }),
      newsItemFrom(<String, dynamic>{
        'id': 'n3',
        'slug': 'fee-change',
        'category_name': <String, dynamic>{'en': 'Fees', 'lo': 'ຄ່າທຳນຽມ'},
        'category_color': '',
        'title': <String, dynamic>{'en': 'Fee schedule update', 'lo': 'ປັບປຸງຄ່າທຳນຽມ'},
        'excerpt': <String, dynamic>{'en': 'Effective 1 October.', 'lo': 'ມີຜົນ 1 ຕຸລາ.'},
        'published_date': 'not-a-date',
      }),
    ];

/// **Hand-written**, five questions — `per_page: 5`.
List<HomeFaqItem> tFaqs() => List<HomeFaqItem>.generate(
      5,
      (int i) => faqItemFrom(<String, dynamic>{
        'id': 'f$i',
        'question': <String, dynamic>{
          'en': 'Question ${i + 1}?',
          'lo': 'ຄຳຖາມ ${i + 1}?',
        },
        'answer': <String, dynamic>{
          'en': 'Answer ${i + 1}.',
          'lo': 'ຄຳຕອບ ${i + 1}.',
        },
      }),
    );

// ─────────────────────────────────────────────────────────────────────────────
// The repository double
// ─────────────────────────────────────────────────────────────────────────────

/// A [HomeRepository] whose five answers a test sets, and whose calls it can
/// read back.
///
/// Hand-written rather than a `mocktail` mock for the reason
/// `FakeServiceRepository` gives: several behaviours under test are about
/// *what was asked for* — that a signed-out Home never calls `/me/*`, that the
/// debounce collapses six keystrokes into one search — and a stub that records
/// reads better at the call site than a `verify(() => …)` chain.
class FakeHomeRepository implements HomeRepository {
  Either<Failure, HomeSummary> summary =
      Right<Failure, HomeSummary>(tHomeSummary());
  Either<Failure, DigitalIdCard> digitalId =
      const Right<Failure, DigitalIdCard>(tDigitalId);
  late Either<Failure, List<Service>> phase1 =
      Right<Failure, List<Service>>(recordedPhase1Services());
  late Either<Failure, List<Service>> search =
      Right<Failure, List<Service>>(recordedPhase1Services().take(3).toList());
  late Either<Failure, List<HomeNewsItem>> news =
      Right<Failure, List<HomeNewsItem>>(tNews());
  late Either<Failure, List<HomeFaqItem>> faqs =
      Right<Failure, List<HomeFaqItem>>(tFaqs());

  int summaryCalls = 0;
  int digitalIdCalls = 0;
  int phase1Calls = 0;
  int newsCalls = 0;
  int faqCalls = 0;

  /// Every `searchServices` argument, in order. The debounce assertions read
  /// this rather than a call count, because "one request for six keystrokes"
  /// and "one request with the *last* query" are different claims.
  final List<String> searchQueries = <String>[];

  /// How long every call takes to answer.
  ///
  /// Zero by default. It exists because the **loading** state is otherwise
  /// unobservable: with an instant repository the first `pump()` after an
  /// event already carries the resolved data, and a test asserting on the
  /// skeleton would assert on the grid instead — passing for a reason
  /// unrelated to what it claims. § 6.6 makes loading one of four mandatory,
  /// *distinguishable* states, so it has to be reachable on demand.
  Duration latency = Duration.zero;

  Future<void> _wait() async {
    if (latency > Duration.zero) await Future<void>.delayed(latency);
  }

  void failEverything() {
    const Failure f = Failure('stubbed failure');
    summary = const Left<Failure, HomeSummary>(f);
    digitalId = const Left<Failure, DigitalIdCard>(f);
    phase1 = const Left<Failure, List<Service>>(f);
    search = const Left<Failure, List<Service>>(f);
    news = const Left<Failure, List<HomeNewsItem>>(f);
    faqs = const Left<Failure, List<HomeFaqItem>>(f);
  }

  void emptyEverything() {
    phase1 = const Right<Failure, List<Service>>(<Service>[]);
    search = const Right<Failure, List<Service>>(<Service>[]);
    news = const Right<Failure, List<HomeNewsItem>>(<HomeNewsItem>[]);
    faqs = const Right<Failure, List<HomeFaqItem>>(<HomeFaqItem>[]);
  }

  @override
  Future<Either<Failure, HomeSummary>> getSummary() async {
    summaryCalls++;
    await _wait();
    return summary;
  }

  @override
  Future<Either<Failure, DigitalIdCard>> getDigitalId() async {
    digitalIdCalls++;
    await _wait();
    return digitalId;
  }

  @override
  Future<Either<Failure, List<Service>>> getPhase1Services() async {
    phase1Calls++;
    await _wait();
    return phase1;
  }

  @override
  Future<Either<Failure, List<Service>>> searchServices(String query) async {
    searchQueries.add(query);
    await _wait();
    return search;
  }

  @override
  Future<Either<Failure, List<HomeNewsItem>>> getFeaturedNews() async {
    newsCalls++;
    await _wait();
    return news;
  }

  @override
  Future<Either<Failure, List<HomeFaqItem>>> getFaqs() async {
    faqCalls++;
    await _wait();
    return faqs;
  }
}

/// A [HomeBloc] over [repository], wired exactly as production wires it.
HomeBloc homeBlocOver(FakeHomeRepository repository) => HomeBloc(
      getHomeSummary: GetHomeSummary(repository: repository),
      getDigitalId: GetDigitalId(repository: repository),
      getPhase1Services: GetPhase1Services(repository: repository),
      searchServices: SearchServices(repository: repository),
      getFeaturedNews: GetFeaturedNews(repository: repository),
      getHomeFaqs: GetHomeFaqs(repository: repository),
    );

// ─────────────────────────────────────────────────────────────────────────────
// Pumping
// ─────────────────────────────────────────────────────────────────────────────

/// A `SessionBloc` stand-in that only has to answer "is the citizen signed in".
///
/// `HomePage` reads the real `SessionBloc` through a provider, and a real one
/// would need `StorageService`, `GetProfile` and `SessionRepository` — three
/// doubles for one boolean. This emits the two states Home listens for and
/// nothing else.
class FakeSessionBloc extends Cubit<SessionState> implements SessionBloc {
  FakeSessionBloc({bool authenticated = false})
      : super(SessionState(
          status: authenticated
              ? SessionStatus.authenticated
              : SessionStatus.unauthenticated,
        ));

  void signIn() => emit(const SessionState(status: SessionStatus.authenticated));

  void signOut() =>
      emit(const SessionState(status: SessionStatus.unauthenticated));

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      super.noSuchMethod(invocation);
}

/// Pumps [HomePage] under [bloc] and a session in the given state.
///
/// **Does not settle.** Several states under test render the loading skeleton
/// and the page holds `AnimatedRotation` in the FAQ accordion; callers pump
/// explicitly, as `pumpServicePage` does for the same reason.
Future<void> pumpHomePage(
  WidgetTester tester,
  HomeBloc bloc, {
  Locale locale = const Locale('en'),
  FakeSessionBloc? session,
  Size surface = const Size(390, 4000),
}) async {
  tester.view.devicePixelRatio = 1.0;
  tester.view.physicalSize = surface;
  addTearDown(tester.view.reset);

  final FakeSessionBloc sessionBloc = session ?? FakeSessionBloc();
  addTearDown(sessionBloc.close);

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
            body: MultiBlocProvider(
              providers: <BlocProvider<dynamic>>[
                BlocProvider<SessionBloc>.value(value: sessionBloc),
                BlocProvider<HomeBloc>.value(value: bloc),
              ],
              child: const HomePage(),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
}

/// How long [FakeHomeRepository.latency] is set to when a test wants to observe
/// the loading state.
const Duration kHomeStubLatency = Duration(milliseconds: 500);

/// Pumps past the debounce window and any stubbed latency, without ever calling
/// `pumpAndSettle` (see [pumpHomePage]).
Future<void> settleHome(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(
    kHomeSearchDebounce + kHomeStubLatency + const Duration(milliseconds: 50),
  );
  await tester.pump();
}
