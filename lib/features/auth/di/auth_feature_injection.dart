/// Auth feature injection entry point.
///
/// Called from `DependencyInjection.init` AFTER `SessionFeatureInjection.init`
/// — the auth feature's BLoC emits a [CitizenSession] that the page wires into
/// `SessionBloc.add(SessionSignIn(session))`, so the session feature must
/// already be registered. The ordering matters: datasource → repository →
/// usecase → bloc, mirroring `SessionFeatureInjection.init()`.
library;

import '../domain/usecases/forgot_password.dart';
import '../domain/usecases/login.dart';
import '../domain/usecases/register.dart';
import '../domain/usecases/request_otp.dart';
import '../domain/usecases/reset_password.dart';
import '../domain/usecases/verify_otp.dart';
import '../presentation/bloc/auth_bloc.dart';
import 'auth_datasource_injection.dart';
import 'auth_injection.dart';
import 'auth_repository_injection.dart';
import 'auth_usecase_injection.dart';

class AuthFeatureInjection {
  /// Register the auth feature. Safe to call once at boot, after the core
  /// singletons and the session feature are ready.
  static Future<void> init() async {
    AuthDatasourceInjection.inject();
    AuthRepositoryInjection.inject();
    AuthUsecaseInjection.inject();

    authInjection.registerFactory<AuthBloc>(
      () => AuthBloc(
        register: authInjection<Register>(),
        requestOtp: authInjection<RequestOtp>(),
        verifyOtp: authInjection<VerifyOtp>(),
        login: authInjection<Login>(),
        forgotPassword: authInjection<ForgotPassword>(),
        resetPassword: authInjection<ResetPassword>(),
      ),
    );
  }
}
