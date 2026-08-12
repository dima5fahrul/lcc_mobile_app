import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lcc_mobile_app/core/error/failure.dart';
import 'package:lcc_mobile_app/features/auth/data/models/citizen_session_model.dart';
import 'package:lcc_mobile_app/features/auth/data/models/otp_challenge_model.dart';
import 'package:lcc_mobile_app/features/auth/data/models/register_result_model.dart';
import 'package:lcc_mobile_app/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:lcc_mobile_app/features/session/domain/entities/citizen_session.dart';
import 'package:lcc_mobile_app/features/session/domain/entities/otp_challenge.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../helpers/auth_fallback_values.dart';
import '../../../../helpers/auth_mock_data.dart';
import '../../../../helpers/auth_test_helper.dart';

void main() {
  setUpAll(registerAuthFallbackValues);

  AuthBloc buildBloc({
    MockRegister? register,
    MockRequestOtp? requestOtp,
    MockVerifyOtp? verifyOtp,
    MockLogin? login,
    MockForgotPassword? forgotPassword,
    MockResetPassword? resetPassword,
  }) {
    return AuthBloc(
      register: register ?? MockRegister(),
      requestOtp: requestOtp ?? MockRequestOtp(),
      verifyOtp: verifyOtp ?? MockVerifyOtp(),
      login: login ?? MockLogin(),
      forgotPassword: forgotPassword ?? MockForgotPassword(),
      resetPassword: resetPassword ?? MockResetPassword(),
    );
  }

  group('AuthBloc.loginStarted', () {
    blocTest<AuthBloc, AuthState>(
      'emits loading then success(session) on success',
      build: () {
        final mockLogin = MockLogin();
        final session = CitizenSessionModel.fromJson(tCitizenSessionJson()).toEntity();
        when(() => mockLogin(any()))
            .thenAnswer((_) async => Right(session));
        return buildBloc(login: mockLogin);
      },
      act: (bloc) => bloc.add(const AuthEvent.loginStarted(
        phone: '+8562012345',
        password: 'password123',
      )),
      wait: const Duration(milliseconds: 100),
      verify: (bloc) {
        expect(bloc.state.status, AuthStatus.success);
        expect(bloc.state.session, isA<CitizenSession>());
        expect(bloc.state.session?.citizen.id, 'citizen-123');
      },
    );

    blocTest<AuthBloc, AuthState>(
      'emits loading then failure with fieldErrors on ApiException',
      build: () {
        final mockLogin = MockLogin();
        when(() => mockLogin(any()))
            .thenThrow(fakeValidationApiException(field: 'password'));
        return buildBloc(login: mockLogin);
      },
      act: (bloc) => bloc.add(const AuthEvent.loginStarted(
        phone: '+8562012345',
        password: 'bad',
      )),
      wait: const Duration(milliseconds: 100),
      verify: (bloc) {
        expect(bloc.state.status, AuthStatus.failure);
        expect(bloc.state.fieldErrors, containsPair('password', 'phone is invalid'));
      },
    );

    blocTest<AuthBloc, AuthState>(
      'emits loading then failure on generic Failure',
      build: () {
        final mockLogin = MockLogin();
        when(() => mockLogin(any()))
            .thenAnswer((_) async => Left(Failure('network down')));
        return buildBloc(login: mockLogin);
      },
      act: (bloc) => bloc.add(const AuthEvent.loginStarted(
        phone: '+8562012345',
        password: 'password123',
      )),
      wait: const Duration(milliseconds: 100),
      verify: (bloc) {
        expect(bloc.state.status, AuthStatus.failure);
        expect(bloc.state.errorMessage, 'network down');
        expect(bloc.state.fieldErrors, isEmpty);
      },
    );
  });

  group('AuthBloc.registerStarted', () {
    blocTest<AuthBloc, AuthState>(
      'emits loading then success(challenge) on success',
      build: () {
        final mockRegister = MockRegister();
        final registerResult =
            RegisterResultModel.fromJson(tRegisterResultJson()).toEntity();
        when(() => mockRegister(any()))
            .thenAnswer((_) async => Right(registerResult));
        return buildBloc(register: mockRegister);
      },
      act: (bloc) => bloc.add(const AuthEvent.registerStarted(
        phone: '+8562012345',
        name: 'Test',
        password: 'password123',
      )),
      wait: const Duration(milliseconds: 100),
      verify: (bloc) {
        expect(bloc.state.status, AuthStatus.success);
        expect(bloc.state.challenge, isA<OTPChallenge>());
        expect(bloc.state.challenge?.phone, '+8562012345');
      },
    );
  });

  // ── GOR-245 additions ─────────────────────────────────────────────────────
  //
  // The three groups above cover login and the happy path of register. The OTP
  // and password-reset halves of the state machine — the flows the plan's
  // manual-verification items 6 and 7 exercise — had no test at all, which is
  // most of why `auth_bloc.dart` sat at 37% line coverage. § 7.2 names "two
  // BLoC state machines" as part of what the retained 80% gate exists to
  // assure, so they are completed here rather than left to the manual pass.

  group('AuthBloc.registerStarted — failure paths', () {
    blocTest<AuthBloc, AuthState>(
      'surfaces the per-field map from a 422',
      build: () {
        final mockRegister = MockRegister();
        when(() => mockRegister(any()))
            .thenThrow(fakeValidationApiException(field: 'phone'));
        return buildBloc(register: mockRegister);
      },
      act: (bloc) => bloc.add(const AuthEvent.registerStarted(
        phone: '+8562012345',
        name: 'Test',
        password: 'password123',
      )),
      wait: const Duration(milliseconds: 100),
      verify: (bloc) {
        expect(bloc.state.status, AuthStatus.failure);
        expect(bloc.state.fieldErrors, containsPair('phone', 'phone is invalid'));
      },
    );

    blocTest<AuthBloc, AuthState>(
      'reports a generic Failure message',
      build: () {
        final mockRegister = MockRegister();
        when(() => mockRegister(any()))
            .thenAnswer((_) async => const Left(Failure('registration closed')));
        return buildBloc(register: mockRegister);
      },
      act: (bloc) => bloc.add(const AuthEvent.registerStarted(
        phone: '+8562012345',
        name: 'Test',
        password: 'password123',
      )),
      wait: const Duration(milliseconds: 100),
      verify: (bloc) {
        expect(bloc.state.status, AuthStatus.failure);
        expect(bloc.state.errorMessage, 'registration closed');
      },
    );

    blocTest<AuthBloc, AuthState>(
      'catches a non-Api exception rather than letting it escape the bloc',
      build: () {
        final mockRegister = MockRegister();
        when(() => mockRegister(any())).thenThrow(StateError('boom'));
        return buildBloc(register: mockRegister);
      },
      act: (bloc) => bloc.add(const AuthEvent.registerStarted(
        phone: '+8562012345',
        name: 'Test',
        password: 'password123',
      )),
      wait: const Duration(milliseconds: 100),
      verify: (bloc) {
        expect(bloc.state.status, AuthStatus.failure);
        expect(bloc.state.errorMessage, contains('boom'));
      },
    );
  });

  group('AuthBloc.loginStarted — remaining branch', () {
    blocTest<AuthBloc, AuthState>(
      'catches a non-Api exception',
      build: () {
        final mockLogin = MockLogin();
        when(() => mockLogin(any())).thenThrow(StateError('boom'));
        return buildBloc(login: mockLogin);
      },
      act: (bloc) => bloc.add(const AuthEvent.loginStarted(
        phone: '+8562012345',
        password: 'password123',
      )),
      wait: const Duration(milliseconds: 100),
      verify: (bloc) {
        expect(bloc.state.status, AuthStatus.failure);
        expect(bloc.state.errorMessage, contains('boom'));
      },
    );
  });

  group('AuthBloc.otpRequested', () {
    blocTest<AuthBloc, AuthState>(
      'emits success carrying the challenge',
      build: () {
        final mockRequestOtp = MockRequestOtp();
        when(() => mockRequestOtp(any())).thenAnswer(
          (_) async => Right(
            OtpChallengeModel.fromJson(tOtpChallengeJson(purpose: 'login'))
                .toEntity(),
          ),
        );
        return buildBloc(requestOtp: mockRequestOtp);
      },
      act: (bloc) => bloc.add(const AuthEvent.otpRequested(
        phone: '+8562012345',
        purpose: 'login',
      )),
      wait: const Duration(milliseconds: 100),
      verify: (bloc) {
        expect(bloc.state.status, AuthStatus.success);
        expect(bloc.state.challenge?.purpose, 'login');
        expect(bloc.state.challenge?.resendAfter, 60);
      },
    );

    blocTest<AuthBloc, AuthState>(
      'emits failure with the per-field map on a 422',
      build: () {
        final mockRequestOtp = MockRequestOtp();
        when(() => mockRequestOtp(any()))
            .thenThrow(fakeValidationApiException(field: 'phone'));
        return buildBloc(requestOtp: mockRequestOtp);
      },
      act: (bloc) => bloc.add(const AuthEvent.otpRequested(
        phone: 'not-a-phone',
        purpose: 'login',
      )),
      wait: const Duration(milliseconds: 100),
      verify: (bloc) {
        expect(bloc.state.status, AuthStatus.failure);
        expect(bloc.state.fieldErrors, containsPair('phone', 'phone is invalid'));
      },
    );

    blocTest<AuthBloc, AuthState>(
      'emits failure on a generic Failure',
      build: () {
        final mockRequestOtp = MockRequestOtp();
        when(() => mockRequestOtp(any()))
            .thenAnswer((_) async => const Left(Failure('sms gateway down')));
        return buildBloc(requestOtp: mockRequestOtp);
      },
      act: (bloc) => bloc.add(const AuthEvent.otpRequested(
        phone: '+8562012345',
        purpose: 'forgot',
      )),
      wait: const Duration(milliseconds: 100),
      verify: (bloc) {
        expect(bloc.state.status, AuthStatus.failure);
        expect(bloc.state.errorMessage, 'sms gateway down');
      },
    );

    blocTest<AuthBloc, AuthState>(
      'catches a non-Api exception',
      build: () {
        final mockRequestOtp = MockRequestOtp();
        when(() => mockRequestOtp(any())).thenThrow(StateError('boom'));
        return buildBloc(requestOtp: mockRequestOtp);
      },
      act: (bloc) => bloc.add(const AuthEvent.otpRequested(
        phone: '+8562012345',
        purpose: 'login',
      )),
      wait: const Duration(milliseconds: 100),
      verify: (bloc) => expect(bloc.state.status, AuthStatus.failure),
    );
  });

  group('AuthBloc.otpVerified', () {
    blocTest<AuthBloc, AuthState>(
      'emits success carrying the session — the register → OTP → session flow',
      build: () {
        final mockVerifyOtp = MockVerifyOtp();
        when(() => mockVerifyOtp(any())).thenAnswer(
          (_) async => Right(
            CitizenSessionModel.fromJson(tCitizenSessionJson()).toEntity(),
          ),
        );
        return buildBloc(verifyOtp: mockVerifyOtp);
      },
      act: (bloc) => bloc.add(const AuthEvent.otpVerified(
        phone: '+8562012345',
        code: '123456',
        purpose: 'register',
      )),
      wait: const Duration(milliseconds: 100),
      verify: (bloc) {
        expect(bloc.state.status, AuthStatus.success);
        expect(bloc.state.session?.tokens.accessToken, 'access-abc');
      },
    );

    blocTest<AuthBloc, AuthState>(
      'emits failure with the per-field map on a wrong code',
      build: () {
        final mockVerifyOtp = MockVerifyOtp();
        when(() => mockVerifyOtp(any())).thenThrow(
          fakeValidationApiException(field: 'code', message: 'code is wrong'),
        );
        return buildBloc(verifyOtp: mockVerifyOtp);
      },
      act: (bloc) => bloc.add(const AuthEvent.otpVerified(
        phone: '+8562012345',
        code: '000000',
        purpose: 'login',
      )),
      wait: const Duration(milliseconds: 100),
      verify: (bloc) {
        expect(bloc.state.status, AuthStatus.failure);
        expect(bloc.state.fieldErrors, containsPair('code', 'code is wrong'));
      },
    );

    blocTest<AuthBloc, AuthState>(
      'emits failure on a generic Failure',
      build: () {
        final mockVerifyOtp = MockVerifyOtp();
        when(() => mockVerifyOtp(any()))
            .thenAnswer((_) async => const Left(Failure('challenge expired')));
        return buildBloc(verifyOtp: mockVerifyOtp);
      },
      act: (bloc) => bloc.add(const AuthEvent.otpVerified(
        phone: '+8562012345',
        code: '123456',
        purpose: 'login',
      )),
      wait: const Duration(milliseconds: 100),
      verify: (bloc) {
        expect(bloc.state.status, AuthStatus.failure);
        expect(bloc.state.errorMessage, 'challenge expired');
      },
    );

    blocTest<AuthBloc, AuthState>(
      'catches a non-Api exception',
      build: () {
        final mockVerifyOtp = MockVerifyOtp();
        when(() => mockVerifyOtp(any())).thenThrow(StateError('boom'));
        return buildBloc(verifyOtp: mockVerifyOtp);
      },
      act: (bloc) => bloc.add(const AuthEvent.otpVerified(
        phone: '+8562012345',
        code: '123456',
        purpose: 'login',
      )),
      wait: const Duration(milliseconds: 100),
      verify: (bloc) => expect(bloc.state.status, AuthStatus.failure),
    );
  });

  group('AuthBloc.passwordReset', () {
    blocTest<AuthBloc, AuthState>(
      'emits success when the reset lands',
      build: () {
        final mockResetPassword = MockResetPassword();
        when(() => mockResetPassword(any()))
            .thenAnswer((_) async => const Right(true));
        return buildBloc(resetPassword: mockResetPassword);
      },
      act: (bloc) => bloc.add(const AuthEvent.passwordReset(
        phone: '+8562012345',
        code: '123456',
        newPassword: 'newpass123',
      )),
      wait: const Duration(milliseconds: 100),
      verify: (bloc) {
        expect(bloc.state.status, AuthStatus.success);
        // A reset produces no session and no challenge — the citizen goes back
        // to the login form and signs in with the new password.
        expect(bloc.state.session, isNull);
        expect(bloc.state.challenge, isNull);
      },
    );

    blocTest<AuthBloc, AuthState>(
      'emits failure with the per-field map on a 422',
      build: () {
        final mockResetPassword = MockResetPassword();
        when(() => mockResetPassword(any())).thenThrow(
          fakeValidationApiException(
            field: 'new_password',
            message: 'too weak',
          ),
        );
        return buildBloc(resetPassword: mockResetPassword);
      },
      act: (bloc) => bloc.add(const AuthEvent.passwordReset(
        phone: '+8562012345',
        code: '123456',
        newPassword: 'x',
      )),
      wait: const Duration(milliseconds: 100),
      verify: (bloc) {
        expect(bloc.state.status, AuthStatus.failure);
        expect(bloc.state.fieldErrors, containsPair('new_password', 'too weak'));
      },
    );

    blocTest<AuthBloc, AuthState>(
      'emits failure on a generic Failure',
      build: () {
        final mockResetPassword = MockResetPassword();
        when(() => mockResetPassword(any()))
            .thenAnswer((_) async => const Left(Failure('code expired')));
        return buildBloc(resetPassword: mockResetPassword);
      },
      act: (bloc) => bloc.add(const AuthEvent.passwordReset(
        phone: '+8562012345',
        code: '123456',
        newPassword: 'newpass123',
      )),
      wait: const Duration(milliseconds: 100),
      verify: (bloc) {
        expect(bloc.state.status, AuthStatus.failure);
        expect(bloc.state.errorMessage, 'code expired');
      },
    );

    blocTest<AuthBloc, AuthState>(
      'catches a non-Api exception',
      build: () {
        final mockResetPassword = MockResetPassword();
        when(() => mockResetPassword(any())).thenThrow(StateError('boom'));
        return buildBloc(resetPassword: mockResetPassword);
      },
      act: (bloc) => bloc.add(const AuthEvent.passwordReset(
        phone: '+8562012345',
        code: '123456',
        newPassword: 'newpass123',
      )),
      wait: const Duration(milliseconds: 100),
      verify: (bloc) => expect(bloc.state.status, AuthStatus.failure),
    );
  });

  group('AuthBloc.resetState', () {
    blocTest<AuthBloc, AuthState>(
      'resets state to initial',
      build: () => buildBloc(),
      act: (bloc) => bloc.add(const AuthEvent.resetState()),
      wait: const Duration(milliseconds: 50),
      verify: (bloc) {
        expect(bloc.state.status, AuthStatus.initial);
        expect(bloc.state.session, isNull);
        expect(bloc.state.challenge, isNull);
        expect(bloc.state.errorMessage, isNull);
      },
    );

    blocTest<AuthBloc, AuthState>(
      'clears a session and a field-error map left by an earlier attempt',
      build: () {
        final mockLogin = MockLogin();
        when(() => mockLogin(any()))
            .thenThrow(fakeValidationApiException(field: 'password'));
        return buildBloc(login: mockLogin);
      },
      act: (bloc) async {
        bloc.add(const AuthEvent.loginStarted(
          phone: '+8562012345',
          password: 'bad',
        ));
        await Future<void>.delayed(const Duration(milliseconds: 50));
        bloc.add(const AuthEvent.resetState());
      },
      wait: const Duration(milliseconds: 150),
      verify: (bloc) {
        expect(bloc.state.status, AuthStatus.initial);
        expect(bloc.state.fieldErrors, isEmpty);
        expect(bloc.state.errorMessage, isNull);
      },
    );
  });
}
