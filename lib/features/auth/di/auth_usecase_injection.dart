/// Auth usecase DI.
///
/// Registers the six auth usecases against the repository. Mirrors the
/// session feature's `session_usecase_injection.dart`.
library;

import '../domain/repositories/auth_repository.dart';
import '../domain/usecases/change_password.dart';
import '../domain/usecases/forgot_password.dart';
import '../domain/usecases/login.dart';
import '../domain/usecases/register.dart';
import '../domain/usecases/request_otp.dart';
import '../domain/usecases/reset_password.dart';
import '../domain/usecases/verify_otp.dart';
import 'auth_injection.dart';

class AuthUsecaseInjection {
  static void inject() {
    authInjection
      ..registerLazySingleton<Register>(
        () => Register(repository: authInjection<AuthRepository>()),
      )
      ..registerLazySingleton<RequestOtp>(
        () => RequestOtp(repository: authInjection<AuthRepository>()),
      )
      ..registerLazySingleton<VerifyOtp>(
        () => VerifyOtp(repository: authInjection<AuthRepository>()),
      )
      ..registerLazySingleton<Login>(
        () => Login(repository: authInjection<AuthRepository>()),
      )
      ..registerLazySingleton<ForgotPassword>(
        () => ForgotPassword(repository: authInjection<AuthRepository>()),
      )
      ..registerLazySingleton<ResetPassword>(
        () => ResetPassword(repository: authInjection<AuthRepository>()),
      )
      // B8a — the seventh. `AccountFeatureInjection` re-exports it into
      // `accountInjection` rather than having the account BLoC reach into this
      // container, mirroring how `ChatUsecaseInjection` re-exports
      // `GetSupportChannels` out of `helpInjection`.
      ..registerLazySingleton<ChangePassword>(
        () => ChangePassword(repository: authInjection<AuthRepository>()),
      );
  }
}
