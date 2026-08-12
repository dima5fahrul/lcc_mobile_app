/// `AuthBloc` — the auth feature's state machine.
///
/// Ported from `lcc-app/src/app/components/AuthPage.tsx` (the `useMutation`
/// calls + the four-step state machine: login / register / otp / reset).
///
/// The bloc owns the six auth usecases and emits one [AuthState] per event.
/// On a successful login / verify-otp it emits the [CitizenSession]; the
/// PAGE wires `context.read<SessionBloc>().add(SessionSignIn(session))` on
/// that success — the AuthBloc does not depend on SessionBloc, so the two
/// features stay decoupled.
///
/// On `ApiException` (a 422 validation failure names every offending field)
/// the bloc reads `fieldMap()` and surfaces it in [AuthState.fieldErrors] so
/// the form can highlight each bad field where the citizen typed.
library;

import 'package:bloc/bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../core/network/api_exception.dart';
import '../../domain/usecases/forgot_password.dart';
import '../../domain/usecases/login.dart';
import '../../domain/usecases/register.dart';
import '../../domain/usecases/request_otp.dart';
import '../../domain/usecases/reset_password.dart';
import '../../domain/usecases/verify_otp.dart';
import '../../../session/domain/entities/citizen_session.dart';
import '../../../session/domain/entities/otp_challenge.dart';

part 'auth_event.dart';
part 'auth_state.dart';
part 'auth_bloc.freezed.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc({
    required this.register,
    required this.requestOtp,
    required this.verifyOtp,
    required this.login,
    required this.forgotPassword,
    required this.resetPassword,
  }) : super(const AuthState()) {
    on<AuthEventLoginStarted>(_onLoginStarted);
    on<AuthEventRegisterStarted>(_onRegisterStarted);
    on<AuthEventOtpRequested>(_onOtpRequested);
    on<AuthEventOtpVerified>(_onOtpVerified);
    on<AuthEventPasswordReset>(_onPasswordReset);
    on<AuthEventResetState>(_onResetState);
  }

  final Register register;
  final RequestOtp requestOtp;
  final VerifyOtp verifyOtp;
  final Login login;
  final ForgotPassword forgotPassword;
  final ResetPassword resetPassword;

  Future<void> _onLoginStarted(
    AuthEventLoginStarted event,
    Emitter<AuthState> emit,
  ) async {
    emit(state.copyWith(status: AuthStatus.loading, errorMessage: null));
    try {
      final result = await login(LoginParams(
        phone: event.phone,
        password: event.password,
      ));
      result.fold(
        (failure) => emit(state.copyWith(
          status: AuthStatus.failure,
          errorMessage: failure.message,
        )),
        (session) => emit(state.copyWith(
          status: AuthStatus.success,
          session: session,
        )),
      );
    } on ApiException catch (e) {
      emit(state.copyWith(
        status: AuthStatus.failure,
        errorMessage: e.message,
        fieldErrors: e.fieldMap(),
      ));
    } catch (e) {
      emit(state.copyWith(
        status: AuthStatus.failure,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> _onRegisterStarted(
    AuthEventRegisterStarted event,
    Emitter<AuthState> emit,
  ) async {
    emit(state.copyWith(status: AuthStatus.loading, errorMessage: null));
    try {
      final result = await register(RegisterParams(
        phone: event.phone,
        name: event.name,
        password: event.password,
        email: event.email,
      ));
      result.fold(
        (failure) => emit(state.copyWith(
          status: AuthStatus.failure,
          errorMessage: failure.message,
        )),
        (registerResult) => emit(state.copyWith(
          status: AuthStatus.success,
          challenge: registerResult.challenge,
        )),
      );
    } on ApiException catch (e) {
      emit(state.copyWith(
        status: AuthStatus.failure,
        errorMessage: e.message,
        fieldErrors: e.fieldMap(),
      ));
    } catch (e) {
      emit(state.copyWith(
        status: AuthStatus.failure,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> _onOtpRequested(
    AuthEventOtpRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(state.copyWith(status: AuthStatus.loading, errorMessage: null));
    try {
      final result = await requestOtp(
        RequestOtpParams(phone: event.phone, purpose: event.purpose),
      );
      result.fold(
        (failure) => emit(state.copyWith(
          status: AuthStatus.failure,
          errorMessage: failure.message,
        )),
        (challenge) => emit(state.copyWith(
          status: AuthStatus.success,
          challenge: challenge,
        )),
      );
    } on ApiException catch (e) {
      emit(state.copyWith(
        status: AuthStatus.failure,
        errorMessage: e.message,
        fieldErrors: e.fieldMap(),
      ));
    } catch (e) {
      emit(state.copyWith(
        status: AuthStatus.failure,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> _onOtpVerified(
    AuthEventOtpVerified event,
    Emitter<AuthState> emit,
  ) async {
    emit(state.copyWith(status: AuthStatus.loading, errorMessage: null));
    try {
      final result = await verifyOtp(VerifyOtpParams(
        phone: event.phone,
        code: event.code,
        purpose: event.purpose,
      ));
      result.fold(
        (failure) => emit(state.copyWith(
          status: AuthStatus.failure,
          errorMessage: failure.message,
        )),
        (session) => emit(state.copyWith(
          status: AuthStatus.success,
          session: session,
        )),
      );
    } on ApiException catch (e) {
      emit(state.copyWith(
        status: AuthStatus.failure,
        errorMessage: e.message,
        fieldErrors: e.fieldMap(),
      ));
    } catch (e) {
      emit(state.copyWith(
        status: AuthStatus.failure,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> _onPasswordReset(
    AuthEventPasswordReset event,
    Emitter<AuthState> emit,
  ) async {
    emit(state.copyWith(status: AuthStatus.loading, errorMessage: null));
    try {
      final result = await resetPassword(ResetPasswordParams(
        phone: event.phone,
        code: event.code,
        newPassword: event.newPassword,
      ));
      result.fold(
        (failure) => emit(state.copyWith(
          status: AuthStatus.failure,
          errorMessage: failure.message,
        )),
        (_) => emit(state.copyWith(status: AuthStatus.success)),
      );
    } on ApiException catch (e) {
      emit(state.copyWith(
        status: AuthStatus.failure,
        errorMessage: e.message,
        fieldErrors: e.fieldMap(),
      ));
    } catch (e) {
      emit(state.copyWith(
        status: AuthStatus.failure,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> _onResetState(
    AuthEventResetState event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthState());
  }
}
