part of 'auth_bloc.dart';

enum AuthStatus { initial, loading, success, failure }

@freezed
abstract class AuthState with _$AuthState {
  const factory AuthState({
    @Default(AuthStatus.initial) AuthStatus status,
    CitizenSession? session,
    OTPChallenge? challenge,
    String? errorMessage,
    @Default(<String, String>{}) Map<String, String> fieldErrors,
  }) = _AuthState;
}
