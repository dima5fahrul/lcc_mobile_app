/// The small `core/` primitives: `Failure`, the exception hierarchy,
/// `NoParams`, `ApiEndpoint`, `AppBlocObserver`.
///
/// Grouped into one file on purpose. Each is a handful of lines with no
/// collaborators; five near-empty files would add navigation cost without
/// adding a single assertion. They stay separate *groups* so a failure still
/// names the unit.
library;

import 'package:bloc/bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lcc_mobile_app/core/constant/api_endpoint.dart';
import 'package:lcc_mobile_app/core/error/exception.dart';
import 'package:lcc_mobile_app/core/error/failure.dart';
import 'package:lcc_mobile_app/core/observer/app_bloc_observer.dart';
import 'package:lcc_mobile_app/core/usecase/usecase.dart';

/// A trivial counter bloc, just so the observer has a real transition to see.
class _CounterBloc extends Bloc<int, int> {
  _CounterBloc() : super(0) {
    on<int>((int event, Emitter<int> emit) => emit(state + event));
  }
}

void main() {
  group('Failure', () {
    test('compares by message', () {
      expect(const Failure('boom'), const Failure('boom'));
      expect(const Failure('boom'), isNot(const Failure('bang')));
      expect(const Failure('boom').hashCode, const Failure('boom').hashCode);
    });

    test('exposes its message', () {
      expect(const Failure('boom').message, 'boom');
      expect(const Failure('boom').props, <Object?>['boom']);
    });
  });

  group('exception hierarchy', () {
    test('all five are Exceptions', () {
      expect(ServerException(), isA<Exception>());
      expect(const ClientException('bad'), isA<Exception>());
      expect(CacheException(), isA<Exception>());
      expect(const ValidationException('invalid'), isA<Exception>());
      expect(const AuthException('expired'), isA<Exception>());
    });

    test('ClientException carries a message', () {
      expect(const ClientException('bad request').message, 'bad request');
    });

    test('ValidationException defaults to no field errors', () {
      const ValidationException e = ValidationException('invalid');
      expect(e.message, 'invalid');
      expect(e.fields, isEmpty);
    });

    test('ValidationException carries per-field errors when given', () {
      const ValidationException e = ValidationException(
        'invalid',
        <String, String>{'phone': 'required'},
      );
      expect(e.fields, <String, String>{'phone': 'required'});
    });

    test('AuthException carries a message', () {
      expect(const AuthException('expired').message, 'expired');
    });
  });

  group('NoParams', () {
    test('every instance is equal to every other', () {
      expect(NoParams(), NoParams());
      expect(NoParams().props, isEmpty);
    });
  });

  group('ApiEndpoint', () {
    test('baseUrl has no trailing slash', () {
      expect(ApiEndpoint.baseUrl, isNotEmpty);
      expect(ApiEndpoint.baseUrl.endsWith('/'), isFalse);
    });

    test('defaults to the staging HTTPS backend when LCC_API_URL is not defined', () {
      // The suite is run without --dart-define, so this pins the HTTPS fallback
      // (V-6: no cleartext default ships to release builds).
      expect(ApiEndpoint.baseUrl, 'https://api.staging.linkit360.la/api/v1');
    });

    test('every auth path is relative and matches the web client', () {
      const List<String> paths = <String>[
        ApiEndpoint.authRegister,
        ApiEndpoint.authRequestOtp,
        ApiEndpoint.authVerifyOtp,
        ApiEndpoint.authLogin,
        ApiEndpoint.authLoginEid,
        ApiEndpoint.authForgotPassword,
        ApiEndpoint.authResetPassword,
        ApiEndpoint.authMe,
        ApiEndpoint.authLogout,
        ApiEndpoint.authChangePassword,
        ApiEndpoint.authRefresh,
        ApiEndpoint.meProfile,
      ];

      for (final String path in paths) {
        expect(path.startsWith('/'), isTrue, reason: '$path must be relative');
        expect(path.contains('://'), isFalse, reason: '$path must carry no host');
      }

      expect(ApiEndpoint.authLogin, '/auth/citizen/login');
      expect(ApiEndpoint.authRefresh, '/auth/refresh');
      expect(ApiEndpoint.meProfile, '/me/profile');
    });
  });

  group('AppBlocObserver', () {
    test('observes a transition without interfering with the bloc', () async {
      final BlocObserver previous = Bloc.observer;
      Bloc.observer = AppBlocObserver();
      addTearDown(() => Bloc.observer = previous);

      final _CounterBloc bloc = _CounterBloc();
      addTearDown(bloc.close);

      bloc.add(2);
      await expectLater(bloc.stream, emits(2));
    });

    test('observes an error without swallowing it', () {
      final AppBlocObserver observer = AppBlocObserver();
      final _CounterBloc bloc = _CounterBloc();
      addTearDown(bloc.close);

      expect(
        () => observer.onError(bloc, StateError('boom'), StackTrace.empty),
        returnsNormally,
      );
    });
  });
}
