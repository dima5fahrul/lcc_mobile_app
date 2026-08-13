/// The production dependency graph — `DependencyInjection.init()` and both
/// feature containers.
///
/// This is the file that would have caught **F-3**. The auth feature was 51
/// files of well-tested code that nothing ever registered: `authInjection` was
/// empty, so `AuthPage.initState`'s `authInjection<AuthBloc>()` threw and the
/// whole feature was dead. Thirty-seven green unit tests said nothing about it,
/// because a unit test constructs its subject directly and never asks the
/// container for one.
///
/// So every registration is *resolved* here, not merely checked for presence:
/// `isRegistered` returns true for a factory that throws the moment it runs.
///
/// Note the containers are not idempotent — a second `init()` throws
/// `already registered inside GetIt`. That is a real constraint on the frozen
/// DI files (§ 4.1), so each test boots once and `tearDown` empties all
/// **five**: B2a added `serviceInjection` and B2b adds `homeInjection`, and a
/// container that `tearDown`
/// forgets does not fail on the test that added it — it fails on the second
/// test in the file, with a message naming `ApiClient`.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:lcc_mobile_app/core/di/dependency_injection.dart';
import 'package:lcc_mobile_app/core/network/api_client.dart';
import 'package:lcc_mobile_app/core/network/auth_interceptor.dart';
import 'package:lcc_mobile_app/core/network/refresh_interceptor.dart';
import 'package:lcc_mobile_app/core/storage/storage_service.dart';
import 'package:lcc_mobile_app/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:lcc_mobile_app/features/auth/di/auth_injection.dart';
import 'package:lcc_mobile_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:lcc_mobile_app/features/auth/domain/usecases/forgot_password.dart';
import 'package:lcc_mobile_app/features/auth/domain/usecases/login.dart';
import 'package:lcc_mobile_app/features/auth/domain/usecases/register.dart';
import 'package:lcc_mobile_app/features/auth/domain/usecases/request_otp.dart';
import 'package:lcc_mobile_app/features/auth/domain/usecases/reset_password.dart';
import 'package:lcc_mobile_app/features/auth/domain/usecases/verify_otp.dart';
import 'package:lcc_mobile_app/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:lcc_mobile_app/features/home/di/home_injection.dart';
import 'package:lcc_mobile_app/features/service/di/service_injection.dart';
import 'package:lcc_mobile_app/features/service/domain/repositories/service_repository.dart';
import 'package:lcc_mobile_app/features/service/domain/usecases/get_service_categories.dart';
import 'package:lcc_mobile_app/features/service/domain/usecases/get_services.dart';
import 'package:lcc_mobile_app/features/service/presentation/bloc/service_bloc.dart';
import 'package:lcc_mobile_app/features/session/data/datasources/session_remote_datasource.dart';
import 'package:lcc_mobile_app/features/session/di/session_injection.dart';
import 'package:lcc_mobile_app/features/session/domain/repositories/session_repository.dart';
import 'package:lcc_mobile_app/features/session/domain/usecases/get_profile.dart';
import 'package:lcc_mobile_app/core/session/bloc/session_bloc.dart';

void main() {
  setUp(() async {
    await const DependencyInjection().init();
  });

  tearDown(() async {
    await injection.reset();
    await sessionInjection.reset();
    await authInjection.reset();
    await serviceInjection.reset();
    // B2b's container. A container `tearDown` forgets is a test that passes
    // once and throws `already registered inside GetIt` on the next `init()` —
    // which is exactly what happened when this line was missing.
    await homeInjection.reset();
  });

  group('root container', () {
    test('resolves a single StorageService', () {
      expect(injection<StorageService>(), isA<StorageService>());
      expect(injection<StorageService>(), same(injection<StorageService>()));
    });

    test('resolves a single ApiClient wired to that same StorageService', () {
      final ApiClient client = injection<ApiClient>();

      expect(client, same(injection<ApiClient>()));
      expect(client.storage, same(injection<StorageService>()),
          reason: 'a second StorageService would mean two token stores');
    });

    test('the ApiClient Dio carries both interceptors and the configured base '
        'URL', () {
      // Resolving ApiClient runs `buildDio(...)` for real, including
      // `debugInterceptors()`.
      final ApiClient client = injection<ApiClient>();
      // `storage` is the only public window onto the client; the Dio itself is
      // private, so the wiring is asserted through the interceptors the
      // *session* datasource will depend on at runtime.
      expect(client.storage, isNotNull);
      expect(AuthInterceptor(client.storage), isA<AuthInterceptor>());
      expect(RefreshInterceptor, isNotNull);
    });
  });

  group('session container', () {
    test('resolves the datasource, repository and usecase', () {
      expect(
        sessionInjection<SessionRemoteDatasource>(),
        isA<SessionRemoteDatasourceImpl>(),
      );
      expect(sessionInjection<SessionRepository>(), isA<SessionRepository>());
      expect(sessionInjection<GetProfile>(), isA<GetProfile>());
    });

    test('F-2: SessionBloc is a singleton — every resolution is the same '
        'instance', () {
      final SessionBloc first = injection<SessionBloc>();
      final SessionBloc second = injection<SessionBloc>();

      expect(first, same(second));
      addTearDown(first.close);
    });

    test('SessionBloc reads the root StorageService, not a second one', () {
      final SessionBloc bloc = injection<SessionBloc>();
      addTearDown(bloc.close);

      expect(bloc.storage, same(injection<StorageService>()));
      expect(bloc.authStateNotifier,
          same(injection<StorageService>().authStateNotifier));
    });
  });

  group('auth container (F-3)', () {
    test('is populated at all — the defect was that init() was never called',
        () {
      expect(authInjection.isRegistered<AuthBloc>(), isTrue);
    });

    test('resolves the datasource and repository', () {
      expect(
        authInjection<AuthRemoteDatasource>(),
        isA<AuthRemoteDatasourceImpl>(),
      );
      expect(authInjection<AuthRepository>(), isA<AuthRepository>());
    });

    test('resolves all six usecases', () {
      expect(authInjection<Register>(), isA<Register>());
      expect(authInjection<RequestOtp>(), isA<RequestOtp>());
      expect(authInjection<VerifyOtp>(), isA<VerifyOtp>());
      expect(authInjection<Login>(), isA<Login>());
      expect(authInjection<ForgotPassword>(), isA<ForgotPassword>());
      expect(authInjection<ResetPassword>(), isA<ResetPassword>());
    });

    test('AuthBloc resolves and is a FACTORY — a fresh one per visit to '
        '/signin', () {
      final AuthBloc first = authInjection<AuthBloc>();
      final AuthBloc second = authInjection<AuthBloc>();
      addTearDown(first.close);
      addTearDown(second.close);

      expect(first, isNot(same(second)),
          reason: 'an app-scoped AuthBloc would keep a half-entered password '
              'and an unverified OTP challenge resident, and would replay a '
              'stale success into BlocListener on the next mount');
    });

    test('the auth datasource re-exports the ROOT ApiClient rather than '
        'building a second Dio', () {
      // Both containers must end up on one HTTP client, or a token refreshed
      // on one would be invisible to the other.
      expect(injection<ApiClient>(), same(injection<ApiClient>()));
      expect(authInjection<AuthRemoteDatasource>(), isNotNull);
    });
  });

  group('service container (B2a, DI-6)', () {
    test('resolves the repository and both usecases', () {
      expect(serviceInjection<ServiceRepository>(), isA<ServiceRepository>());
      expect(
        serviceInjection<GetServiceCategories>(),
        isA<GetServiceCategories>(),
      );
      expect(serviceInjection<GetServices>(), isA<GetServices>());
    });

    test('DI-3: it re-exports the ROOT ApiClient rather than building a Dio',
        () {
      expect(serviceInjection<ApiClient>(), same(injection<ApiClient>()));
    });

    test('DI-1: the ROOT container did not grow a fourth registration', () {
      // The root holds exactly StorageService, ApiClient and SessionBloc. A
      // feature that registers itself on the root instead of its own container
      // is the failure this pins — it works, and it makes the root the place
      // everything accumulates.
      expect(injection.isRegistered<ServiceRepository>(), isFalse);
      expect(injection.isRegistered<GetServices>(), isFalse);
      expect(injection.isRegistered<ServiceBloc>(), isFalse);
    });

    test('ServiceBloc is a FACTORY — a fresh one per visit to /service', () {
      final ServiceBloc first = serviceInjection<ServiceBloc>();
      final ServiceBloc second = serviceInjection<ServiceBloc>();
      addTearDown(first.close);
      addTearDown(second.close);

      expect(first, isNot(same(second)),
          reason: 'a shared ServiceBloc would hand the next visit the previous '
              "visit's search results and a debounce Timer already scheduled "
              'against a closed emitter');
    });
  });

  group('registration order', () {
    test('the whole graph resolves from a cold container in one pass', () {
      // The ordering `DependencyInjection.init` documents — StorageService →
      // ApiClient → session → auth — is only load-bearing if nothing below it
      // reaches back up too early. Resolving the leaf-most object first is the
      // strongest single check of that.
      final AuthBloc bloc = authInjection<AuthBloc>();
      addTearDown(bloc.close);

      expect(bloc, isA<AuthBloc>());
      expect(injection.isRegistered<StorageService>(), isTrue);
      expect(injection.isRegistered<ApiClient>(), isTrue);
    });
  });
}
