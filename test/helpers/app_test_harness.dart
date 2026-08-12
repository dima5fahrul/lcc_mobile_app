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
import 'package:lcc_mobile_app/core/storage/storage_service.dart';
import 'package:lcc_mobile_app/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:lcc_mobile_app/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:lcc_mobile_app/features/auth/di/auth_injection.dart';
import 'package:lcc_mobile_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:lcc_mobile_app/features/auth/domain/usecases/forgot_password.dart';
import 'package:lcc_mobile_app/features/auth/domain/usecases/login.dart';
import 'package:lcc_mobile_app/features/auth/domain/usecases/register.dart';
import 'package:lcc_mobile_app/features/auth/domain/usecases/request_otp.dart';
import 'package:lcc_mobile_app/features/auth/domain/usecases/reset_password.dart';
import 'package:lcc_mobile_app/features/auth/domain/usecases/verify_otp.dart';
import 'package:lcc_mobile_app/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:lcc_mobile_app/features/session/data/datasources/session_remote_datasource.dart';
import 'package:lcc_mobile_app/features/session/data/repositories/session_repository_impl.dart';
import 'package:lcc_mobile_app/features/session/di/session_injection.dart';
import 'package:lcc_mobile_app/features/session/domain/repositories/session_repository.dart';
import 'package:lcc_mobile_app/features/session/domain/usecases/get_profile.dart';
import 'package:lcc_mobile_app/features/session/presentation/bloc/session_bloc.dart';
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
Future<AppHarness> bootHarness({Map<String, String>? seed}) async {
  final Map<String, String> store = <String, String>{...?seed};
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
  // Lazy *singleton*, exactly as the production DI does — one SessionBloc for
  // the app's lifetime is the F-2 invariant these tests exist to prove.
  sessionInjection.registerLazySingleton<SessionBloc>(
    () => SessionBloc(
      storage: storage,
      getProfile: sessionInjection<GetProfile>(),
      repository: sessionRepository,
    ),
  );

  // ── Auth feature (mirrors AuthFeatureInjection.init) ──────────────────────
  final AuthRepository authRepository = AuthRepositoryImpl(
    remote: AuthRemoteDatasourceImpl(apiClient: apiClient),
  );
  authInjection.registerSingleton<AuthRepository>(authRepository);
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

  return AppHarness(
    store: store,
    storage: storage,
    dio: dio,
    adapter: adapter,
    apiClient: apiClient,
    sessionBloc: sessionInjection<SessionBloc>(),
  );
}

/// Empties all three GetIt containers. Without this the second test in a file
/// hits `already registered inside GetIt` — the same non-idempotency that
/// makes the frozen `*FeatureInjection.init()` unusable here.
Future<void> resetHarness() async {
  await injection.reset();
  await sessionInjection.reset();
  await authInjection.reset();
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
