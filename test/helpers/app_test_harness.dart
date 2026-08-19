/// Stands the **assembled** app up headlessly for the GOR-245 AC-6 flow tests
/// and the AC-7 shell tests.
///
/// "Assembled" is meant literally: [pumpAssembledApp] pumps the real `App`
/// widget from `lib/main.dart`, over the real `AppRoutes` router, with the real
/// `SessionBloc`, `SessionRepositoryImpl`, `SessionRemoteDatasourceImpl`,
/// `AuthBloc`, `AuthRepositoryImpl`, `AuthRemoteDatasourceImpl`, `ApiClient`,
/// `AuthInterceptor` and `RefreshInterceptor`. Only two things are doubled: the
/// HTTP transport (`http_mock_adapter`) and the secure-storage platform channel
/// (an in-memory map). Everything the ticket's defects F-1/F-2/F-3 live in is
/// the production object.
///
/// ## Three hazards this file exists to contain
///
/// 1. **`AuthFeatureInjection.init()` / `SessionFeatureInjection.init()` are
///    not idempotent** — a second call throws `already registered inside
///    GetIt`. They are also frozen (§ 4.1), so they cannot be made idempotent.
///    [bootHarness] therefore performs the *equivalent* registrations directly
///    and [resetHarness] tears all three containers down, so every test starts
///    from an empty container. The registration graph below is a deliberate
///    mirror of `DependencyInjection.init()`; if that file changes, this must
///    follow, and the flow tests will fail loudly rather than silently drift.
///
/// 2. **`EasyLocalization` stalls headless.** `test/widget_test.dart` was
///    `skip: true` for exactly this. The cause is the default
///    `RootBundleAssetLoader` plus `saveLocale: true`, which drags
///    `SharedPreferences` (a platform channel with no responder in a headless
///    run) into both boot and every `setLocale`. [JsonFileAssetLoader] reads
///    the very same `assets/i18n/*.json` straight off disk with `dart:io`, and
///    `saveLocale: false` matches what `main.dart` already does — the language
///    is owned by `StorageService` under `lcc.lang`, not by easy_localization.
///    With those two changes the widget settles and the real translations are
///    still what gets asserted, so `layout.home` renders as "Home" / "ໜ້າຫຼັກ"
///    rather than as a raw key.
///
/// 3. **A `Bloc` built in `setUp` lives outside `testWidgets`' FakeAsync
///    zone**, so `pumpAndSettle` cannot flush its microtasks and an event like
///    `SessionStarted` is accepted but never handled — the session sits on
///    `SessionStatus.initial` for the whole test, silently. [bootHarness] is
///    therefore an `async` function called *from inside the test body*, never
///    from `setUp`.
library;

import 'dart:convert';
import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dio/dio.dart';
import 'package:http_mock_adapter/http_mock_adapter.dart';
import 'package:lcc_mobile_app/core/di/dependency_injection.dart';
import 'package:lcc_mobile_app/core/network/api_client.dart';
import 'package:lcc_mobile_app/core/network/auth_interceptor.dart';
import 'package:lcc_mobile_app/core/network/refresh_interceptor.dart';
import 'package:lcc_mobile_app/core/storage/storage_keys.dart';
import 'package:lcc_mobile_app/core/storage/storage_service.dart';
import 'package:lcc_mobile_app/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:lcc_mobile_app/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:lcc_mobile_app/features/account/data/datasources/account_remote_datasource.dart';
import 'package:lcc_mobile_app/features/account/data/repositories/account_repository_impl.dart';
import 'package:lcc_mobile_app/features/account/di/account_injection.dart';
import 'package:lcc_mobile_app/features/account/domain/repositories/account_repository.dart';
import 'package:lcc_mobile_app/features/account/domain/usecases/account_usecases.dart';
import 'package:lcc_mobile_app/features/account/presentation/bloc/account_documents_bloc.dart';
import 'package:lcc_mobile_app/features/account/presentation/bloc/account_preferences_bloc.dart';
import 'package:lcc_mobile_app/features/account/presentation/bloc/account_profile_bloc.dart';
import 'package:lcc_mobile_app/features/auth/di/auth_injection.dart';
import 'package:lcc_mobile_app/features/auth/domain/usecases/change_password.dart';
import 'package:lcc_mobile_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:lcc_mobile_app/features/auth/domain/usecases/forgot_password.dart';
import 'package:lcc_mobile_app/features/auth/domain/usecases/login.dart';
import 'package:lcc_mobile_app/features/auth/domain/usecases/register.dart';
import 'package:lcc_mobile_app/features/auth/domain/usecases/request_otp.dart';
import 'package:lcc_mobile_app/features/auth/domain/usecases/reset_password.dart';
import 'package:lcc_mobile_app/features/auth/domain/usecases/verify_otp.dart';
import 'package:lcc_mobile_app/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:lcc_mobile_app/features/chat/data/datasources/chat_remote_datasource.dart';
import 'package:lcc_mobile_app/features/chat/data/repositories/chat_repository_impl.dart';
import 'package:lcc_mobile_app/features/chat/di/chat_injection.dart';
import 'package:lcc_mobile_app/features/chat/domain/repositories/chat_repository.dart';
import 'package:lcc_mobile_app/features/chat/domain/usecases/chat_usecases.dart';
import 'package:lcc_mobile_app/features/chat/presentation/bloc/chat_bloc.dart';
import 'package:lcc_mobile_app/core/constant/api_endpoint.dart';
import 'package:lcc_mobile_app/features/documents/data/datasources/documents_remote_datasource.dart';
import 'package:lcc_mobile_app/features/documents/data/repositories/documents_repository_impl.dart';
import 'package:lcc_mobile_app/features/documents/di/documents_injection.dart';
import 'package:lcc_mobile_app/features/documents/domain/repositories/documents_repository.dart';
import 'package:lcc_mobile_app/features/documents/domain/usecases/documents_usecases.dart';
import 'package:lcc_mobile_app/features/home/data/datasources/home_remote_datasource.dart';
import 'package:lcc_mobile_app/features/home/data/repositories/home_repository_impl.dart';
import 'package:lcc_mobile_app/features/home/di/home_injection.dart';
import 'package:lcc_mobile_app/features/home/domain/repositories/home_repository.dart';
import 'package:lcc_mobile_app/features/home/domain/usecases/home_usecases.dart';
import 'package:lcc_mobile_app/features/home/presentation/bloc/home_bloc.dart';
import 'package:lcc_mobile_app/features/help/data/datasources/help_remote_datasource.dart';
import 'package:lcc_mobile_app/features/help/data/repositories/help_repository_impl.dart';
import 'package:lcc_mobile_app/features/help/di/help_injection.dart';
import 'package:lcc_mobile_app/features/help/domain/repositories/help_repository.dart';
import 'package:lcc_mobile_app/features/help/domain/usecases/help_usecases.dart';
import 'package:lcc_mobile_app/features/help/presentation/bloc/help_bloc.dart';
import 'package:lcc_mobile_app/features/news/data/datasources/news_remote_datasource.dart';
import 'package:lcc_mobile_app/features/news/data/repositories/news_repository_impl.dart';
import 'package:lcc_mobile_app/features/news/di/news_injection.dart';
import 'package:lcc_mobile_app/features/news/domain/repositories/news_repository.dart';
import 'package:lcc_mobile_app/features/news/domain/usecases/news_usecases.dart';
import 'package:lcc_mobile_app/features/news/presentation/bloc/news_bloc.dart';
import 'package:lcc_mobile_app/features/news/presentation/bloc/news_detail_bloc.dart';
import 'package:lcc_mobile_app/features/notifications/data/datasources/notification_remote_datasource.dart';
import 'package:lcc_mobile_app/features/notifications/data/repositories/notification_repository_impl.dart';
import 'package:lcc_mobile_app/features/notifications/di/notifications_injection.dart';
import 'package:lcc_mobile_app/features/notifications/domain/repositories/notification_repository.dart';
import 'package:lcc_mobile_app/features/notifications/domain/usecases/notification_usecases.dart';
import 'package:lcc_mobile_app/features/notifications/presentation/bloc/notifications_bloc.dart';
import 'package:lcc_mobile_app/features/service/data/datasources/service_remote_datasource.dart';
import 'package:lcc_mobile_app/features/service/data/repositories/service_repository_impl.dart';
import 'package:lcc_mobile_app/features/service/di/service_injection.dart';
import 'package:lcc_mobile_app/features/service/domain/repositories/service_repository.dart';
import 'package:lcc_mobile_app/features/service/domain/usecases/get_service_categories.dart';
import 'package:lcc_mobile_app/features/service/domain/usecases/get_services.dart';
import 'package:lcc_mobile_app/features/service/presentation/bloc/service_bloc.dart';
import 'package:lcc_mobile_app/features/session/data/datasources/session_remote_datasource.dart';
import 'package:lcc_mobile_app/features/session/data/repositories/session_repository_impl.dart';
import 'package:lcc_mobile_app/features/session/di/session_injection.dart';
import 'package:lcc_mobile_app/features/session/domain/repositories/session_repository.dart';
import 'package:lcc_mobile_app/features/session/domain/usecases/get_profile.dart';
import 'package:lcc_mobile_app/features/session/domain/usecases/update_profile.dart';
import 'package:lcc_mobile_app/core/session/bloc/session_bloc.dart';
import 'package:lcc_mobile_app/features/application/data/datasources/application_remote_datasource.dart';
import 'package:lcc_mobile_app/features/application/data/repositories/application_repository_impl.dart';
import 'package:lcc_mobile_app/features/application/di/application_injection.dart';
import 'package:lcc_mobile_app/features/certificates/di/certificates_injection.dart';
// B12 — the three feature compositions this harness resolves through the
// assembled app's route builders. Production's own `init()`s, called rather
// than hand-mirrored: each re-registers the ROOT `ApiClient`, which was
// registered above over the stubbed transport, so the wire stays stubbed and
// the graph stays production's.
import 'package:lcc_mobile_app/features/certificates/di/certificates_feature_injection.dart';
import 'package:lcc_mobile_app/features/family_book/di/family_book_feature_injection.dart';
import 'package:lcc_mobile_app/features/family_book/di/family_book_injection.dart';
import 'package:lcc_mobile_app/features/reference/di/reference_feature_injection.dart';
import 'package:lcc_mobile_app/features/reference/di/reference_injection.dart';
import 'package:lcc_mobile_app/features/application/domain/repositories/application_repository.dart';
import 'package:lcc_mobile_app/features/application/domain/usecases/application_usecases.dart';
import 'package:lcc_mobile_app/features/history/di/history_injection.dart';
import 'package:lcc_mobile_app/features/history/presentation/bloc/history_bloc.dart';
import 'package:lcc_mobile_app/features/history/presentation/bloc/history_detail_bloc.dart';
import 'package:lcc_mobile_app/features/wallet/data/datasources/wallet_remote_datasource.dart';
import 'package:lcc_mobile_app/features/wallet/data/repositories/wallet_repository_impl.dart';
import 'package:lcc_mobile_app/features/wallet/di/wallet_injection.dart';
import 'package:lcc_mobile_app/features/wallet/domain/repositories/wallet_repository.dart';
import 'package:lcc_mobile_app/features/wallet/domain/usecases/list_pending_bills.dart';
import 'package:lcc_mobile_app/features/wallet/domain/usecases/pay_application.dart';
import 'package:lcc_mobile_app/features/wallet/domain/usecases/wallet_usecases.dart';
import 'package:lcc_mobile_app/features/wallet/presentation/bloc/wallet_bloc.dart';

// B12 — the recorded oracle, so `stubCertificateEndpoints` answers `/services`
// with the same 43 rows `recordedServices()` parses. One recording, two readers.
import '../fidelity/oracle.dart';
import 'package:lcc_mobile_app/main.dart';

import 'core_test_helper.dart';

/// Loads `assets/i18n/{lang}.json` from the working directory with `dart:io`.
///
/// `flutter test` runs with the package root as its working directory, so this
/// reads the *same* files the shipped app loads through `rootBundle` — the
/// asserted strings are the real translations, not a test-only dictionary.
///
/// **The read is synchronous, and that is load-bearing.** `testWidgets` runs
/// its body inside a `FakeAsync` zone: `pumpAndSettle` drains fake timers and
/// microtasks, but it never lets the *real* event loop run, so a future that
/// completes on real file I/O never resolves. An `await file.readAsString()`
/// here leaves `_EasyLocalizationDelegate.load` pending forever, `Localizations`
/// renders its empty placeholder instead of the child, and every finder comes
/// back empty while `pumpAndSettle` reports success — a silent false negative,
/// and the shape of the original "EasyLocalization never settles" symptom.
/// `readAsStringSync` keeps the whole load inside the microtask queue the fake
/// zone does drain. The per-locale [_cache] then keeps repeated pumps cheap.
class JsonFileAssetLoader extends AssetLoader {
  const JsonFileAssetLoader();

  static final Map<String, Map<String, dynamic>> _cache =
      <String, Map<String, dynamic>>{};

  @override
  Future<Map<String, dynamic>?> load(String path, Locale locale) async {
    final String key = '$path/${locale.languageCode}';
    return _cache.putIfAbsent(
      key,
      () => json.decode(File('$key.json').readAsStringSync())
          as Map<String, dynamic>,
    );
  }
}

/// Everything a flow test needs a handle on after [bootHarness].
class AppHarness {
  AppHarness({
    required this.store,
    required this.storage,
    required this.dio,
    required this.adapter,
    required this.apiClient,
    required this.sessionBloc,
  });

  /// The backing map of the fake secure storage — assert token persistence and
  /// the `lcc.lang` preference here.
  final Map<String, String> store;

  final StorageService storage;
  final Dio dio;

  /// Stub the backend on this: `adapter.onGet(ApiEndpoint.meProfile, ...)`.
  final DioAdapter adapter;

  final ApiClient apiClient;

  /// The single app-wide session BLoC (defect F-2's invariant).
  final SessionBloc sessionBloc;
}

/// Registers the full production object graph against a stubbed transport.
///
/// MUST be awaited from inside the test body, not `setUp` — see hazard 3 in
/// the library doc. Pair every call with [resetHarness] in `tearDown`.
///
/// [seed] pre-populates secure storage; pass
/// `{StorageKeys.accessToken: 'token'}` for a warm-boot scenario.
///
/// ## The two first-run flags are seeded by default (B10)
///
/// `lcc.onboarding_seen` and `lcc.tutorial_seen` are pre-set unless [firstRun]
/// is true, so an assembled test lands on Home as a **returning** citizen. That
/// is not a convenience — it is the source's own rig behaviour, twice over:
///
/// * `e2e/smoke.mjs`:91-96 seeds `lcc_onboarding_seen` before the walk, and
///   says why: *"the app itself does not mount behind them, so a fresh browser
///   profile would sit on 'Welcome' and make every screen below look like a
///   wiring failure … The first-run sequence is covered separately."*
/// * `manifest.md`:262-264 records that the baseline capture operator set
///   `lcc_tutorial_seen` explicitly so no overlay could land in a shot.
///
/// Pass `firstRun: true` to get the fresh-install path — that is what B10's
/// boot-phase and tutorial-gate tests do.
Future<AppHarness> bootHarness({
  Map<String, String>? seed,
  bool firstRun = false,
}) async {
  final Map<String, String> store = <String, String>{
    if (!firstRun) ...<String, String>{
      StorageKeys.onboardingSeen: '1',
      StorageKeys.tutorialSeen: '1',
    },
    ...?seed,
  };
  final StorageService storage = inMemoryStorageService(store);

  final Dio dio = Dio(
    BaseOptions(
      baseUrl: kTestBaseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      contentType: 'application/json',
    ),
  );
  // Real interceptors — the flow tests exercise token injection as part of the
  // assembled app, not in isolation.
  dio.interceptors.add(AuthInterceptor(storage));
  dio.interceptors.add(RefreshInterceptor(dio, storage));

  // `http_mock_adapter` rather than the hand-written adapter in
  // `core_test_helper.dart`: the flow tests only need "this route answers this
  // envelope", which is exactly what it is for. Route-only matching, because
  // the interceptors add headers the default full-signature matcher would then
  // demand be declared in every stub.
  final DioAdapter adapter = DioAdapter(
    dio: dio,
    matcher: const UrlRequestMatcher(),
  );

  final ApiClient apiClient = ApiClient(dio: dio, storage: storage);

  // ── Root container (mirrors DependencyInjection.init steps 1–2) ───────────
  injection.registerSingleton<StorageService>(storage);
  injection.registerSingleton<ApiClient>(apiClient);

  // ── Session feature (mirrors SessionFeatureInjection.init) ────────────────
  final SessionRepository sessionRepository = SessionRepositoryImpl(
    remote: SessionRemoteDatasourceImpl(apiClient: apiClient),
  );
  sessionInjection.registerSingleton<SessionRepository>(sessionRepository);
  sessionInjection.registerSingleton<GetProfile>(
    GetProfile(repository: sessionRepository),
  );
  // B8a. The harness is a deliberate mirror of `DependencyInjection.init()`
  // (see this file's hazard 1), so R-25's `PATCH /me/profile` use case is
  // registered here too — over the SAME repository, not a second one.
  sessionInjection.registerSingleton<UpdateProfile>(
    UpdateProfile(repository: sessionRepository),
  );
  // Lazy *singleton* on the ROOT container, exactly as the production DI does
  // (CR-3 moved it off `sessionInjection`) — one SessionBloc for the app's
  // lifetime is the F-2 invariant these tests exist to prove.
  injection.registerLazySingleton<SessionBloc>(
    () => SessionBloc(
      storage: storage,
      getProfile: sessionInjection<GetProfile>(),
      repository: sessionRepository,
      updateProfile: sessionInjection<UpdateProfile>(),
    ),
  );

  // ── Auth feature (mirrors AuthFeatureInjection.init) ──────────────────────
  final AuthRepository authRepository = AuthRepositoryImpl(
    remote: AuthRemoteDatasourceImpl(apiClient: apiClient),
  );
  authInjection.registerSingleton<AuthRepository>(authRepository);
  // B8a — the account page's credential write, re-exported into
  // `accountInjection` below exactly as production's
  // `AccountUsecaseInjection` does.
  authInjection.registerSingleton<ChangePassword>(
    ChangePassword(repository: authRepository),
  );
  // `registerFactory`, as production does: an auth attempt is scoped to one
  // visit to /signin and AuthPage closes the instance it resolved.
  authInjection.registerFactory<AuthBloc>(
    () => AuthBloc(
      register: Register(repository: authRepository),
      requestOtp: RequestOtp(repository: authRepository),
      verifyOtp: VerifyOtp(repository: authRepository),
      login: Login(repository: authRepository),
      forgotPassword: ForgotPassword(repository: authRepository),
      resetPassword: ResetPassword(repository: authRepository),
    ),
  );

  // ── Service catalogue (mirrors ServiceFeatureInjection.init) ──────────────
  // Registered even by tests that never visit `/service`: `AppRoutes` builds
  // the whole table up front and the `/service` builder resolves from this
  // container the moment the shell navigates there, so an unregistered service
  // feature would surface as a GetIt throw inside an unrelated navigation
  // test rather than as a missing registration.
  final ServiceRepository serviceRepository = ServiceRepositoryImpl(
    remote: ServiceRemoteDatasourceImpl(apiClient: apiClient),
  );
  serviceInjection.registerSingleton<ServiceRepository>(serviceRepository);
  // `registerFactory`, as production does: one ServiceBloc per visit.
  serviceInjection.registerFactory<ServiceBloc>(
    () => ServiceBloc(
      getServiceCategories:
          GetServiceCategories(repository: serviceRepository),
      getServices: GetServices(repository: serviceRepository),
    ),
  );

  // ── Home feature (mirrors HomeFeatureInjection.init) ──────────────────────
  // `/` is `AppRoutes.initialLocation`, so unlike the service catalogue this
  // one is resolved by **every** assembled-app test the moment the app mounts,
  // not only by tests that navigate somewhere.
  final HomeRepository homeRepository = HomeRepositoryImpl(
    remote: HomeRemoteDatasourceImpl(apiClient: apiClient),
  );
  homeInjection.registerSingleton<HomeRepository>(homeRepository);
  // `registerFactory`, as production does: one HomeBloc per visit, because it
  // holds a debounce timer and one citizen's summary.
  homeInjection.registerFactory<HomeBloc>(
    () => HomeBloc(
      getHomeSummary: GetHomeSummary(repository: homeRepository),
      getDigitalId: GetDigitalId(repository: homeRepository),
      getPhase1Services: GetPhase1Services(repository: homeRepository),
      searchServices: SearchServices(repository: homeRepository),
      getFeaturedNews: GetFeaturedNews(repository: homeRepository),
      getHomeFaqs: GetHomeFaqs(repository: homeRepository),
    ),
  );

  // ── News feature (mirrors NewsFeatureInjection.init) ──────────────────────
  // Registered for the same reason the service catalogue is: `AppRoutes` builds
  // the whole table up front, and `/news` — now with a `/news/:slug` child —
  // resolves from this container the moment anything navigates there. An
  // unregistered feature would surface as a GetIt throw inside an unrelated
  // navigation test.
  final NewsRepository newsRepository = NewsRepositoryImpl(
    remote: NewsRemoteDatasourceImpl(apiClient: apiClient),
  );
  newsInjection.registerSingleton<NewsRepository>(newsRepository);
  newsInjection.registerFactory<NewsBloc>(
    () => NewsBloc(
      getNewsCategories: GetNewsCategories(repository: newsRepository),
      getNewsArticles: GetNewsArticles(repository: newsRepository),
    ),
  );
  // `registerFactoryParam`, as production does — the detail BLoC takes the
  // route's slug at construction.
  newsInjection.registerFactoryParam<NewsDetailBloc, String, void>(
    (String slug, _) => NewsDetailBloc(
      slug: slug,
      getNewsArticle: GetNewsArticle(repository: newsRepository),
      getNewsCatalogue: GetNewsCatalogue(repository: newsRepository),
    ),
  );

  // ── Help feature (mirrors HelpFeatureInjection.init) ──────────────────────
  final HelpRepository helpRepository = HelpRepositoryImpl(
    remote: HelpRemoteDatasourceImpl(apiClient: apiClient),
  );
  helpInjection.registerSingleton<HelpRepository>(helpRepository);
  // B9b: production's `HelpUsecaseInjection` registers this as a lazy
  // singleton (`help_usecase_injection.dart:23`) and this mirror did not,
  // because nothing resolved it by type — `HelpBloc` is handed a freshly
  // constructed one below. `ChatUsecaseInjection` re-exports it out of THIS
  // container (specs.md § 6.6), so the omission is now load-bearing: without
  // this line the first shell build in any assembled-app test throws a GetIt
  // lookup naming `helpInjection` and not the cause.
  helpInjection.registerLazySingleton<GetSupportChannels>(
    () => GetSupportChannels(repository: helpRepository),
  );
  helpInjection.registerFactory<HelpBloc>(
    () => HelpBloc(
      getHelpCategories: GetHelpCategories(repository: helpRepository),
      getHelpFaqs: GetHelpFaqs(repository: helpRepository),
      getHelpGuides: GetHelpGuides(repository: helpRepository),
      getHelpGuide: GetHelpGuide(repository: helpRepository),
      getSupportChannels: GetSupportChannels(repository: helpRepository),
      sendFaqFeedback: SendFaqFeedback(repository: helpRepository),
    ),
  );

  // ── Notification feature (mirrors NotificationsFeatureInjection.init) ─────
  //
  // REQUIRED, not optional, and it is why B9a had to touch a file its § 3.1
  // scope table does not name. B9a composes the bell into the `ShellRoute`
  // builder (`app_routes.dart`), so **every** assembled-app test now resolves
  // `notificationsInjection<NotificationsBloc>()` while building the shell —
  // `app_shell_test.dart`, both `language_toggle` files, `app_flow_test.dart`
  // and the route tests. Without this block they all fail at the first pump
  // with a GetIt lookup error that names the container and not the cause.
  //
  // Recorded as a required § 3.1 deviation in B9a's hand-back rather than
  // slipped in: the table lists `test/presentation/shell/**` but not the
  // harness those tests are built on, which is a gap in the table rather than
  // a licence.
  //
  // `registerFactory`, as production does: the BLoC holds one citizen's unread
  // count and their own notices, and a surviving instance would carry both
  // across a sign-out.
  final NotificationRepository notificationRepository =
      NotificationRepositoryImpl(
    remote: NotificationRemoteDatasourceImpl(apiClient: apiClient),
  );
  notificationsInjection
      .registerSingleton<NotificationRepository>(notificationRepository);
  notificationsInjection.registerFactory<NotificationsBloc>(
    () => NotificationsBloc(
      getNotifications:
          GetNotifications(repository: notificationRepository),
      getUnreadCount: GetUnreadCount(repository: notificationRepository),
      markNotificationRead:
          MarkNotificationRead(repository: notificationRepository),
      markAllNotificationsRead:
          MarkAllNotificationsRead(repository: notificationRepository),
    ),
  );

  // ── Chat feature (mirrors ChatFeatureInjection.init) ──────────────────────
  //
  // REQUIRED for the same reason the notification block above is, and it is why
  // B9b had to touch a file its § 3.1 scope table does not name. B9b composes
  // the launcher into the `ShellRoute` builder's `floatingAction` slot, so
  // **every** assembled-app test now resolves `chatInjection<ChatBloc>()` while
  // building the shell. Without this block they all fail at the first pump with
  // a GetIt lookup error that names the container and not the cause.
  //
  // Recorded as a required § 3.1 deviation in B9b's hand-back rather than
  // slipped in — the table lists `test/features/chat/**` but not the harness
  // those shell tests are built on, which is a gap in the table rather than a
  // licence.
  //
  // `registerFactory`, as production does: the BLoC holds one citizen's
  // transcript and composer text, and `close()` is what cancels its poll timer.
  final ChatRepository chatRepository = ChatRepositoryImpl(
    remote: ChatRemoteDatasourceImpl(apiClient: apiClient),
  );
  chatInjection.registerSingleton<ChatRepository>(chatRepository);
  chatInjection.registerFactory<ChatBloc>(
    () => ChatBloc(
      getChatThreads: GetChatThreads(repository: chatRepository),
      getChatMessages: GetChatMessages(repository: chatRepository),
      startChatThread: StartChatThread(repository: chatRepository),
      sendChatMessage: SendChatMessage(repository: chatRepository),
      markThreadRead: MarkThreadRead(repository: chatRepository),
      closeChatThread: CloseChatThread(repository: chatRepository),
      // Out of `helpInjection`, exactly as production's re-export does.
      getSupportChannels: helpInjection<GetSupportChannels>(),
    ),
  );

  // ── Account feature (mirrors AccountFeatureInjection.init) — B8a ──────────
  //
  // REQUIRED for exactly the reason the chat block above records, one step
  // further along: B8a replaces the `/account` route's `const AccountPage()`
  // with a `MultiBlocProvider` over three `accountInjection` factories, so
  // **every assembled test that navigates to `/account` now resolves them
  // while building the route**. `app_flow_test.dart` scenario 2 does exactly
  // that (`expect(find.byType(AccountPage), findsOneWidget)`), and without this
  // block it fails at the pump with a GetIt lookup error naming the container
  // rather than the cause.
  //
  // Recorded as a required specs.md § 3.1 deviation in B8a's hand-back, not
  // slipped in — the table lists `test/features/account/**` but not the harness
  // the shell and flow tests are built on, which is a gap in the table rather
  // than a licence.
  //
  // `registerFactory` for all three, as production does: each holds one
  // citizen's profile buffer, preference switches or document wallet.
  // `GetProfile`/`UpdateProfile` come out of `sessionInjection` and
  // `ChangePassword` out of `authInjection`, exactly as production's
  // re-exports do — one repository behind each, never a second parse.
  final AccountRepository accountRepository = AccountRepositoryImpl(
    remote: AccountRemoteDatasourceImpl(apiClient: apiClient),
  );
  accountInjection.registerSingleton<AccountRepository>(accountRepository);
  accountInjection
    ..registerFactory<AccountProfileBloc>(
      () => AccountProfileBloc(
        getProfile: sessionInjection<GetProfile>(),
        updateProfile: sessionInjection<UpdateProfile>(),
        changePassword: authInjection<ChangePassword>(),
        // B8b, over the same `accountRepository` the two BLoCs below use —
        // one repository, never a second parse, as production's DI does.
        uploadAvatar: UploadAvatar(repository: accountRepository),
      ),
    )
    ..registerFactory<AccountPreferencesBloc>(
      () => AccountPreferencesBloc(
        getPreferences: GetPreferences(repository: accountRepository),
        savePreferences: SavePreferences(repository: accountRepository),
      ),
    )
    ..registerFactory<AccountDocumentsBloc>(
      () => AccountDocumentsBloc(
        getDocuments: GetDocuments(repository: accountRepository),
      ),
    );

  // ── Wallet feature (mirrors WalletFeatureInjection.init) — B6a ────────────
  //
  // REQUIRED for exactly the reason the account block above records. B6a wraps
  // the **existing** `/wallet` route's builder in a
  // `BlocProvider<WalletBloc>(create: walletInjection<WalletBloc>())`
  // (`app_routes.dart:492-497`, the one edit specs.md § 3.1 allows that file),
  // so **every assembled test that renders the `/wallet` route now resolves
  // that factory while building the route**. `app_flow_test.dart` scenario 4
  // ("/, /service, /wallet are not gated") and `chat_launcher_test.dart`'s
  // "renders on every one of the five shell routes" both navigate there, and
  // without this block they fail at the pump with
  // `Bad state: GetIt: Object/factory with type WalletBloc is not registered`
  // — a lookup error that names the container and not the cause, which is the
  // same misleading shape the DI-teardown defect wore five times.
  //
  // Recorded as a required specs.md § 3.1 deviation in B6a's hand-back, not
  // slipped in — the table lists `test/features/wallet/**` but not the harness
  // the shell and flow tests are built on, which is a gap in the table rather
  // than a licence. B8a, B9a and B9b each hit and recorded the identical gap.
  //
  // `registerFactory`, as production does: `WalletBloc` holds one visit's
  // money — a balance, an account number, a page of receipts and a page of the
  // ledger — and a surviving instance would hand all four to whoever signs in
  // next on the same device (`wallet_feature_injection.dart`'s own rationale).
  //
  // The repository is built over `apiClient`, the same root client production
  // re-exports (DI-3), so the anonymous `/payment-methods` call keeps the one
  // interceptor chain that knows how to skip itself.
  final WalletRepository walletRepository = WalletRepositoryImpl(
    remote: WalletRemoteDatasourceImpl(apiClient: apiClient),
  );
  walletInjection.registerSingleton<WalletRepository>(walletRepository);
  walletInjection.registerFactory<WalletBloc>(
    () => WalletBloc(
      getWalletOverview: GetWalletOverview(repository: walletRepository),
      getWalletEntries: GetWalletEntries(repository: walletRepository),
      getTransactions: GetTransactions(repository: walletRepository),
      getPaymentMethods: GetPaymentMethods(repository: walletRepository),
      topUpWallet: TopUpWallet(repository: walletRepository),
      // B6b. `ListPendingBills` composes B7a's `ListApplications` out of
      // `applicationInjection` rather than owning a second `/applications`
      // datasource (specs.md § 2.3 as amended at v1.1), and production wires it
      // through a lazy closure in `WalletUsecaseInjection`. Mirrored here as a
      // lazy resolve **inside the factory closure** for the same reason it is
      // lazy there: the application block below has not run yet at this line,
      // and it does not need to have — the closure body runs when a test
      // resolves `WalletBloc`, by which point both blocks are registered.
      // Resolving eagerly here would fail with `GetIt: Object/factory with
      // type ListApplications is not registered` and would look like a missing
      // registration rather than a line-order mistake.
      listPendingBills: ListPendingBills(
        listApplications: applicationInjection<ListApplications>(),
      ),
      payApplication: PayApplication(repository: walletRepository),
    ),
  );

  // ── Application + History (mirrors Application/HistoryFeatureInjection) — B7a
  //
  // REQUIRED for the same reason the wallet block above records, and it is the
  // same § 3.1 gap: B7a's table lists `test/features/{application,history}/**`
  // but not this harness, which B6a, B8a, B9a and B9b each hit and recorded
  // before it. **Recorded as a deviation in B7a's hand-back, not slipped in.**
  //
  // B7a wraps the **existing** `/history` route's builder in a
  // `BlocProvider<HistoryBloc>` (`app_routes.dart:463-467`), so every assembled
  // test that renders that route now resolves the factory while building it.
  // `app_shell_test.dart`'s two navigation cases and
  // `chat_launcher_test.dart`'s "five shell routes" case all go there, and
  // without this block they fail with `Bad state: GetIt: Object/factory with
  // type HistoryBloc is not registered` — again a lookup error that names the
  // container rather than the cause.
  //
  // TWO containers, because `features/application/` is a **page-less shared
  // slice** (specs.md § 6.2): it is consumed by history today and by wallet
  // (B6b) and the certificate pages next, so `historyInjection` resolves the
  // two use cases *out of* `applicationInjection` rather than building its own
  // — mirrored here exactly, or the harness would prove a wiring production
  // does not have.
  //
  // `registerFactory` for the bloc, as production does: `HistoryBloc` holds one
  // visit's filter, search term and page, and a surviving instance would hand
  // the previous citizen's search back to whoever signs in next.
  final ApplicationRepository applicationRepository = ApplicationRepositoryImpl(
    remote: ApplicationRemoteDatasourceImpl(apiClient: apiClient),
  );
  applicationInjection
      .registerSingleton<ApplicationRepository>(applicationRepository);
  applicationInjection.registerLazySingleton<ListApplications>(
    () => ListApplications(repository: applicationRepository),
  );
  applicationInjection.registerLazySingleton<GetStatusPipeline>(
    () => GetStatusPipeline(repository: applicationRepository),
  );
  // B7b — the detail's two reads, same repository instance as the list's.
  applicationInjection.registerLazySingleton<GetApplication>(
    () => GetApplication(repository: applicationRepository),
  );
  applicationInjection.registerLazySingleton<GetApplicationTimeline>(
    () => GetApplicationTimeline(repository: applicationRepository),
  );

  historyInjection.registerLazySingleton<ListApplications>(
    () => applicationInjection<ListApplications>(),
  );
  historyInjection.registerLazySingleton<GetStatusPipeline>(
    () => applicationInjection<GetStatusPipeline>(),
  );
  historyInjection.registerLazySingleton<GetApplication>(
    () => applicationInjection<GetApplication>(),
  );
  historyInjection.registerLazySingleton<GetApplicationTimeline>(
    () => applicationInjection<GetApplicationTimeline>(),
  );
  historyInjection.registerFactory<HistoryBloc>(
    () => HistoryBloc(
      listApplications: historyInjection<ListApplications>(),
      getStatusPipeline: historyInjection<GetStatusPipeline>(),
    ),
  );
  // B5 — the collection slice, over the same mocked client. `historyInjection`
  // re-exports its two use cases exactly as production's
  // `HistoryUsecaseInjection` does, so the harness proves the wiring the app
  // has rather than one it invented.
  final DocumentsRepository documentsRepository = DocumentsRepositoryImpl(
    remote: DocumentsRemoteDatasourceImpl(apiClient: apiClient),
  );
  documentsInjection
      .registerSingleton<DocumentsRepository>(documentsRepository);
  documentsInjection.registerLazySingleton<GetCertificates>(
    () => GetCertificates(repository: documentsRepository),
  );
  documentsInjection.registerLazySingleton<GetCertificate>(
    () => GetCertificate(repository: documentsRepository),
  );
  historyInjection.registerLazySingleton<GetCertificates>(
    () => documentsInjection<GetCertificates>(),
  );
  historyInjection.registerLazySingleton<GetCertificate>(
    () => documentsInjection<GetCertificate>(),
  );

  // B7b's second bloc — a factory for the same reason, plus the open case's id
  // and its three generation counters (B5 added the third).
  historyInjection.registerFactory<HistoryDetailBloc>(
    () => HistoryDetailBloc(
      getApplication: historyInjection<GetApplication>(),
      getApplicationTimeline: historyInjection<GetApplicationTimeline>(),
      getCertificates: historyInjection<GetCertificates>(),
      getCertificate: historyInjection<GetCertificate>(),
    ),
  );

  // ── Reference + certificates + family book (B12) ──────────────────────────
  //
  // REQUIRED for exactly the reason the wallet, application, account, chat and
  // notification blocks above record — and this is the **eleventh** occurrence
  // of that same shape. B12 mounts six certificate `GoRoute`s whose builders
  // resolve `certificatesInjection<*FormCubit>(param1: …)` and
  // `familyBookInjection<FamilyBookCubit>(param1: …)`, so every assembled test
  // that navigates to one of the six now resolves them while building the
  // route. Without this block they fail at the pump with
  // `Bad state: GetIt: Object/factory with type ResidentFormCubit is not
  // registered` — a lookup error that names the container and not the cause.
  //
  // **B12's specs.md § 3.1 row 12 grants this file**, unlike the five batches
  // before it, which each had to record a scope deviation to touch it. What the
  // row *describes* is `stubCertificateEndpoints` plus a family-book stub; it
  // did not anticipate the DI mirror, because § 2.1a measured only whether the
  // harness **stubbed** `GET /me/family-book` and not whether it **registered**
  // the containers. It does neither. Reported in the hand-back as a measured
  // difference from the spec rather than slipped in.
  //
  // ## Why this block calls the production `init()`s instead of hand-mirroring
  //
  // Every block above builds its repository by hand because it must inject the
  // stubbed `Dio`. These four cannot drift that way: each of their datasource
  // injections re-registers the ROOT container's `ApiClient`
  // (`familyBookInjection..registerLazySingleton<ApiClient>(() =>
  // injection<ApiClient>())`, and the same in `ReferenceDatasourceInjection`),
  // and `injection<ApiClient>` was registered above over the stubbed transport.
  // So calling production's own composition keeps the transport stubbed **and**
  // removes any possibility of the harness proving a wiring production does not
  // have — which is the failure the hand-mirrors above each warn about in their
  // own words.
  //
  // ## Ordering is load-bearing and is production's own
  //
  // `dependency_injection.dart` runs `ServiceFeatureInjection.init()` (`:162`)
  // before `FamilyBookFeatureInjection.init()` (`:402`), because
  // `family_book_bloc_injection.dart:24-25` closes over `serviceInjection` for
  // the review step's fee. The service block above has already run, so that
  // ordering holds here too. `CertificatesBlocInjection` closes over
  // `referenceInjection`, `applicationInjection`, `walletInjection` and
  // `serviceInjection` — all inside its factory closures, so they need only be
  // registered by the time a route resolves a cubit, not by the time this line
  // runs.
  await ReferenceFeatureInjection.init();
  await CertificatesFeatureInjection.init();
  await FamilyBookFeatureInjection.init();

  // The four write use cases the five certificate cubits resolve out of
  // `applicationInjection`, over the SAME repository the four read use cases
  // above use. Production registers all eight in one
  // `ApplicationUsecaseInjection` (`:28-85`); the block above mirrored only the
  // four B7a/B7b needed, because nothing resolved the others until now.
  applicationInjection.registerLazySingleton<CreateApplication>(
    () => CreateApplication(repository: applicationRepository),
  );
  applicationInjection.registerLazySingleton<UpdateApplication>(
    () => UpdateApplication(repository: applicationRepository),
  );
  applicationInjection.registerLazySingleton<AddAttachment>(
    () => AddAttachment(repository: applicationRepository),
  );
  applicationInjection.registerLazySingleton<SubmitApplication>(
    () => SubmitApplication(repository: applicationRepository),
  );

  // `GetServices` **by type**. The service block above registers `ServiceBloc`
  // with a `GetServices` constructed inline, which is not resolvable — and the
  // certificate cubits' `loadService` / `loadQuote` ports, plus
  // `familyBookFeeReader`, all resolve `serviceInjection<GetServices>()`.
  // Production registers it in `ServiceUsecaseInjection:19`.
  serviceInjection.registerLazySingleton<GetServices>(
    () => GetServices(repository: serviceRepository),
  );

  // Resident, Birth and Death read `/payment-methods` through
  // `walletInjection<GetPaymentMethods>()`, and all five certificate cubits
  // take `walletInjection<PayApplication>()` as their pay port — B6b's
  // published cross-batch surface, whose own doc names F1, F2, F3 and B7 as its
  // consumers. Same repository instance the `WalletBloc` above builds over.
  walletInjection.registerLazySingleton<GetPaymentMethods>(
    () => GetPaymentMethods(repository: walletRepository),
  );
  walletInjection.registerLazySingleton<PayApplication>(
    () => PayApplication(repository: walletRepository),
  );

  stubHomeEndpoints(adapter);
  stubContentEndpoints(adapter);
  stubAccountEndpoints(adapter);
  stubWalletEndpoints(adapter);

  // NOTE: `stubCertificateEndpoints` is deliberately **not** called here. It
  // re-stubs `GET /services` with the recorded 43-row catalogue, and
  // `stubHomeEndpoints` answers that route with an empty list on purpose so
  // assembled tests that never asked for catalogue content do not get 43
  // services in `find.text`. A test that needs the six routes calls it itself,
  // after `bootHarness`, where the later registration wins.

  return AppHarness(
    store: store,
    storage: storage,
    dio: dio,
    adapter: adapter,
    apiClient: apiClient,
    sessionBloc: injection<SessionBloc>(),
  );
}

/// Answers Home's five reads with empty successes.
///
/// **Not politeness — a precondition.** `/` mounts `HomePage`, which fires
/// three anonymous requests on arrival and two more once the session resolves.
/// `http_mock_adapter` throws on a route it was not told about, and that throw
/// surfaces inside `pumpAndSettle` as an unrelated-looking failure in whatever
/// test happened to boot the app. Every existing flow and shell test would
/// break on a page they do not assert anything about.
///
/// Empty payloads rather than fixtures, deliberately: these tests are about
/// routing, the auth gate and the shell, and giving Home real content would
/// put three news headlines and five questions into `find.text` for suites
/// that never asked for them. Home's own tests supply their own data. A test
/// that *does* want content re-stubs the route — `DioAdapter` lets a later
/// registration win.
void stubHomeEndpoints(DioAdapter adapter) {
  void ok(String path, Object data, {Map<String, dynamic>? meta}) {
    adapter.onGet(
      path,
      (dynamic server) => server.reply(200, <String, dynamic>{
        'success': true,
        'message': 'ok',
        'data': data,
        if (meta != null) 'meta': meta,
      }),
    );
  }

  const Map<String, dynamic> emptyPage = <String, dynamic>{
    'page': 1,
    'per_page': 0,
    'total': 0,
    'total_pages': 1,
    'has_next': false,
    'has_prev': false,
  };

  ok(ApiEndpoint.services, const <dynamic>[]);
  ok(ApiEndpoint.news, const <dynamic>[], meta: emptyPage);
  ok(ApiEndpoint.helpFaqs, const <dynamic>[], meta: emptyPage);
  ok(ApiEndpoint.meHomeSummary, const <String, dynamic>{
    'name': '',
    'verified': false,
    'eid_verified': false,
    'active_applications': 0,
    'ready_documents': 0,
    'unread_notifications': 0,
    'wallet_balance_lak': 0,
    'next_action': null,
    'generated_at': '',
  });
  ok(ApiEndpoint.meDigitalId, const <String, dynamic>{
    'uin': '',
    'card_no': '',
    'photo_url': '',
  });
}

/// Answers the five B2c content reads with empty successes.
///
/// **Not politeness — a precondition**, exactly as [stubHomeEndpoints]'
/// doc explains: `http_mock_adapter` throws on a route it was not told about,
/// and the throw surfaces inside `pumpAndSettle` as an unrelated-looking
/// failure in whatever test happened to navigate there.
///
/// `/news` and `/help/faqs` are **already** stubbed by [stubHomeEndpoints] —
/// Home consumes both — so they are deliberately not repeated here. `DioAdapter`
/// lets a later registration win, and a duplicate would silently make which
/// stub answers depend on call order.
///
/// `GET /news/<slug>` and `GET /help/articles/<slug>` are **not** stubbed: they
/// need a concrete segment, so a suite that navigates to a detail route stubs
/// its own. A blanket stub would answer every slug with an empty object and
/// turn a 404 test into a pass.
void stubContentEndpoints(DioAdapter adapter) {
  void ok(String path, Object data, {Map<String, dynamic>? meta}) {
    adapter.onGet(
      path,
      (dynamic server) => server.reply(200, <String, dynamic>{
        'success': true,
        'message': 'ok',
        'data': data,
        if (meta != null) 'meta': meta,
      }),
    );
  }

  ok(ApiEndpoint.newsCategories, const <dynamic>[]);
  ok(ApiEndpoint.helpCategories, const <dynamic>[]);
  ok(ApiEndpoint.helpArticles, const <dynamic>[]);
  ok(ApiEndpoint.helpChannels, const <dynamic>[]);
}

/// Answers B8a's two account reads with empty successes — B8a.
///
/// **Not politeness — a precondition**, for the reason [stubHomeEndpoints]'
/// doc gives: `http_mock_adapter` throws on a route it was not told about, and
/// the throw surfaces inside `pumpAndSettle` as an unrelated-looking failure in
/// whatever test happened to navigate to `/account`.
///
/// `GET /me/profile` is **deliberately absent**: it is the one endpoint whose
/// content every assembled test cares about, and every such test already stubs
/// it with the citizen it wants. A blanket stub here would silently win or lose
/// against theirs depending on registration order.
///
/// The empty document list is a **default, not a measurement**. `/me/documents`
/// has never been called for the live test citizen (specs.md § 6.5, GG-2), so a
/// test that needs the populated row stubs its own; nothing here should be read
/// as evidence about what staging returns.
/// Answers the wallet's reads with the **measured** production shapes — B6a.
///
/// Not a convenience: `http_mock_adapter` throws on a route it was not told
/// about, and `/payment-methods` is fired by `WalletPage` on mount even while
/// signed out (it is the batch's one `anonymous: true` endpoint), so an
/// unstubbed wallet route surfaces inside `pumpAndSettle` as an unrelated-
/// looking failure in whatever test happened to reach the tab.
///
/// The bodies are the ones actually observed against staging on 2026-08-13 —
/// `balance_lak 0`, `recent_entries []`, `entry_count 0`. That is the honest
/// state of the only available test citizen, and it is why B6a's populated-
/// state ACs are reported NOT EVALUATED rather than passed against invented
/// data (specs.md § 6.14's "declared synthetic" rule).
///
/// **`POST /me/wallet/topup` is deliberately NOT stubbed.** It moves real money
/// in staging, § 4.4 forbids executing it, and leaving it unstubbed means any
/// test that ever reaches it fails loudly instead of quietly appearing to work.
void stubWalletEndpoints(DioAdapter adapter) {
  adapter.onGet(
    ApiEndpoint.meWallet,
    (dynamic server) => server.reply(200, <String, dynamic>{
      'success': true,
      'message': 'ok',
      'data': const <String, dynamic>{
        'wallet': <String, dynamic>{
          'id': '',
          'account_no': '',
          'balance_lak': 0,
          'currency': 'LAK',
          'status': 'active',
        },
        'recent_entries': <dynamic>[],
        'entry_count': 0,
        'can_top_up': true,
        'min_top_up_lak': null,
        'max_top_up_lak': null,
      },
    }),
  );
  for (final String paged in <String>[
    ApiEndpoint.meWalletEntries,
    ApiEndpoint.meTransactions,
  ]) {
    adapter.onGet(
      paged,
      (dynamic server) => server.reply(200, <String, dynamic>{
        'success': true,
        'message': 'ok',
        'data': const <dynamic>[],
        'meta': const <String, dynamic>{
          'page': 1,
          'per_page': 20,
          'total': 0,
          'total_pages': 0,
        },
      }),
    );
  }
  // A plain array, not a paged envelope (specs.md § 5.1).
  adapter.onGet(
    ApiEndpoint.paymentMethods,
    (dynamic server) => server.reply(200, <String, dynamic>{
      'success': true,
      'message': 'ok',
      'data': const <dynamic>[],
    }),
  );
}

void stubAccountEndpoints(DioAdapter adapter) {
  adapter.onGet(
    ApiEndpoint.meDocuments,
    (dynamic server) => server.reply(200, <String, dynamic>{
      'success': true,
      'message': 'ok',
      'data': const <dynamic>[],
    }),
  );
  adapter.onGet(
    ApiEndpoint.mePreferences,
    (dynamic server) => server.reply(200, <String, dynamic>{
      'success': true,
      'message': 'ok',
      'data': const <String, dynamic>{
        'language': 'lo',
        'notifications': <String, dynamic>{
          'in_app': true,
          'email': false,
          'sms': false,
        },
        'biometric_login': false,
      },
    }),
  );
}

/// Answers every read the six B12 certificate routes fire **on mount** — B12.
///
/// **Not politeness — a precondition**, for the reason [stubHomeEndpoints]'
/// doc gives and more sharply here: `http_mock_adapter` throws on a route it was
/// not told about, and the throw surfaces inside `pumpAndSettle` as an
/// unrelated-looking failure. Without this every criterion in B12 § 7.3 would
/// die inside the pump for a reason that has nothing to do with routing.
///
/// ## Called by the test, never by [bootHarness], and that is deliberate
///
/// This re-stubs `GET /services` with the **recorded 43-row catalogue**, while
/// [stubHomeEndpoints] answers the same route with an empty list on purpose so
/// that assembled tests which never asked for catalogue content do not get 43
/// services in `find.text`. `DioAdapter` lets a later registration win, so a
/// test that wants the catalogue calls this **after** `bootHarness` and gets it;
/// every other test is unaffected. Calling it from `bootHarness` would flip that
/// default for the whole suite.
///
/// ## The catalogue is the recorded one, not a synthetic row
///
/// Two criteria depend on it being real data. `B12-AC-17` asserts the rendered
/// fee is that page's own recorded `fee_lak` (`marriage` 100 000, `divorce`
/// 10 000), and `B12-AC-30` measures `destinationFor` over all 43 rows — six
/// with a `route_path`, 37 without. A one-row fixture would make the first
/// vacuous and the second impossible.
///
/// ## `GET /me/family-book` answers **404**, and that is the empty state
///
/// Measured 2026-08-13 against the one available staging account:
/// `404 {"success":false,"message":"family book not found","code":"NOT_FOUND"}`
/// (`manifest-authenticated.md`:229). `FamilyBookViewState.showsError` excludes
/// `NotFoundFailure`, so a 404 routes past the error card into
/// *"No household on file"* — `FamilyBookPage.tsx:326`, slot 47's render, and
/// the only branch of this endpoint any reference in this repository exercises.
/// It is also the only branch `B12-AC-17` can assert: `F4-NV-2` leaves the
/// populated household **permanently NOT EVALUATED** without a seeded staging
/// account, so a criterion asserting a rendered household could only be closed
/// against invented data.
///
/// ## No existing stub function is edited
///
/// `/payment-methods` (Resident, Birth and Death read it; Marriage and Divorce
/// deliberately do not, `F3-AC-65`) is already answered by
/// [stubWalletEndpoints], and `familyBookInjection.reset()` in [resetHarness]
/// stays exactly as F4 left it. Registration order between two stubs of the same
/// route is the failure [stubAccountEndpoints]' doc warns about, and `/services`
/// above is the one place this function deliberately takes that override.
void stubCertificateEndpoints(DioAdapter adapter) {
  void ok(String path, Object data) {
    adapter.onGet(
      path,
      (dynamic server) => server.reply(200, <String, dynamic>{
        'success': true,
        'message': 'ok',
        'data': data,
      }),
    );
  }

  // The recorded catalogue, parsed by nobody here — the raw rows go on the wire
  // and the production `ServiceModel` parses them, which is what makes
  // `B12-AC-17`'s fee a measurement of the real pipeline rather than of a
  // literal a test wrote down.
  ok(ApiEndpoint.services, loadApi('services'));

  // The catalogue page reads BOTH in one `Future.wait`
  // (`service_bloc.dart:117-119`), and `stubHomeEndpoints` answers only
  // `/services` — Home needs no categories. Without this, `/service` renders
  // its error state and `B12-AC-31`'s tap has no card to tap. The recorded
  // eight, so the six certificate rows land in the category the source puts
  // them in rather than in an invented one.
  ok(ApiEndpoint.serviceCategories, loadApi('service-categories'));

  // Every `lookup_key` the five certificate cubits request on mount, measured
  // from their own `load()` bodies: Resident's two (`:382-383`), Birth's ten
  // (`BirthRefList.values`), Death's eight (`DeathRefList.values`), Marriage's
  // four (`:406-409`) and Divorce's two. Empty lists, because no B12 criterion
  // asserts a dropdown's contents — F1/F2/F3's own tests do that with their own
  // fakes, and giving these real options would put a hundred strings into
  // `find.text` for a suite about routing.
  for (final String type in <String>[
    'nationality',
    'certificate-purpose',
    'ethnicity',
    'ethnic-group',
    'religion',
    'education-level',
    'marital-status',
    'relation',
    'blood-type',
    'delivery-mode',
    'birth-type',
    'cause-of-death',
    'divorce-type',
  ]) {
    ok(ApiEndpoint.referenceList(type), const <dynamic>[]);
  }

  // Resident, Marriage and Divorce call `loadProvinces()` on mount. A plain
  // array, not paged (`api_endpoint.dart:335`).
  ok(ApiEndpoint.locationProvinces, const <dynamic>[]);

  // The 404 above. `server.reply` with a non-2xx is how the other suites drive
  // a failure branch, and the body is the recorded one verbatim.
  adapter.onGet(
    ApiEndpoint.meFamilyBook,
    (dynamic server) => server.reply(404, <String, dynamic>{
      'success': false,
      'message': 'family book not found',
      'code': 'NOT_FOUND',
    }),
  );
}

/// Empties all ten GetIt containers. Without this the second test in a file
/// hits `already registered inside GetIt` — the same non-idempotency that
/// makes the frozen `*FeatureInjection.init()` unusable here.
///
/// Every feature container added to [bootHarness] MUST be added here in the
/// same change. B2b's own comment in `dependency_injection_test.dart` records
/// what a forgotten line costs: a test that passes once and throws on the next
/// `init()`, in a file that has nothing to do with the new feature.
Future<void> resetHarness() async {
  await injection.reset();
  await sessionInjection.reset();
  await authInjection.reset();
  await serviceInjection.reset();
  await homeInjection.reset();
  await newsInjection.reset();
  await helpInjection.reset();
  await notificationsInjection.reset();
  await chatInjection.reset();
  await accountInjection.reset();
  // B6a. `test/architecture/di_teardown_completeness_test.dart` guards the
  // three *feature* teardowns by scanning for `GetIt.asNewInstance()`; it does
  // not scan this harness, so this line is the one the guard cannot catch for
  // me. Omitting it is the sixth occurrence of the defect the guard exists for.
  await walletInjection.reset();
  // B7a. Same blind spot the line above records, and the same two-container
  // shape as the registration block: `features/application/` is page-less and
  // shared, so BOTH containers have to come down. Leaving either registered
  // makes the *second* test in a file fail with `already registered inside
  // GetIt` — which points at the container, not at this omission, the same
  // misleading shape the defect has worn every time.
  await applicationInjection.reset();
  await historyInjection.reset();
  // B5's container. `di_teardown_completeness_test.dart` discovers it by
  // pattern and fails any DI test file that forgets it.
  await documentsInjection.reset();
  // F1. Same harness blind spot the two lines above record. ONE container:
  // `features/certificates/` registers a BLoC and nothing else, so there is no
  // second container to bring down the way `features/application/` needs.
  await certificatesInjection.reset();
  // B12. ELEVENTH occurrence of the same omission, and the first found by
  // *registering* into a container the harness had never populated rather than
  // by a test failing: `referenceInjection` was absent from this file entirely
  // — no registration, and therefore no teardown either, so the gap was
  // invisible while nothing resolved it. B12's route builders are the first
  // code to resolve `referenceInjection<GetLookupOptions>` through the
  // assembled app, and without this line the second test in any file fails with
  // `Type ApiClient is already registered inside GetIt` — pointing at the
  // container rather than at the omission, the same misleading shape the defect
  // has worn every time.
  await referenceInjection.reset();
  await familyBookInjection.reset();
  // F4's. TENTH occurrence of the same omission, and the first predicted by
  // the container's own doc before it happened
  // (`family_book_injection.dart:16-25`). Added by the meta-orchestrator
  // after F4's implementer was cut off mid-batch: without it,
  // `FamilyBookDatasourceInjection.inject` re-registers `ApiClient` into a
  // container the previous test left populated, and 43 tests fail with
  // `Type ApiClient is already registered inside GetIt`. Recorded scope
  // deviation on the same grounds the nine before it were.
}

/// Wraps [child] in a headless-safe `EasyLocalization` — see hazard 2.
Widget wrapWithLocalization(
  Widget child, {
  Locale startLocale = const Locale('en'),
}) {
  return EasyLocalization(
    supportedLocales: const <Locale>[Locale('en'), Locale('lo')],
    path: 'assets/i18n',
    assetLoader: const JsonFileAssetLoader(),
    fallbackLocale: const Locale('lo'),
    startLocale: startLocale,
    // Off, exactly as `main.dart` sets it: `StorageService` owns `lcc.lang`.
    // It also keeps SharedPreferences out of the headless run entirely.
    saveLocale: false,
    child: child,
  );
}

/// Pumps the real `App` from `lib/main.dart` for one frame, without settling.
///
/// `App.initState` builds the router and dispatches `SessionStarted`, so this
/// is the moment the boot begins. Use it when the test needs to observe the
/// boot *window* — the `initial`/`loading` hold in `AppRoutes._redirect`.
/// Otherwise use [pumpAssembledApp].
Future<void> mountAssembledApp(
  WidgetTester tester,
  AppHarness harness, {
  Locale startLocale = const Locale('en'),
}) async {
  await tester.pumpWidget(
    wrapWithLocalization(
      App(sessionBloc: harness.sessionBloc),
      startLocale: startLocale,
    ),
  );
}

/// [mountAssembledApp] plus `pumpAndSettle`, so the boot has actually run
/// against the stubbed backend by the time this returns — which is the whole
/// point of AC-6.
Future<void> pumpAssembledApp(
  WidgetTester tester,
  AppHarness harness, {
  Locale startLocale = const Locale('en'),
}) async {
  await mountAssembledApp(tester, harness, startLocale: startLocale);
  await tester.pumpAndSettle();
}
