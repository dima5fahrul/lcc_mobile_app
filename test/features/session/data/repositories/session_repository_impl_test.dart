/// `SessionRepositoryImpl` — `Either` folding, and the one documented
/// deviation from the boilerplate pattern.
///
/// The deviation is the point of most of these tests: `ApiException` is
/// **rethrown**, not wrapped into `Left(Failure)`, because `SessionBloc` has to
/// branch on `isUnauthorized`/`isForbidden` to clear a dead token. Wrapping it
/// would flatten that signal into a string, and nothing downstream could tell a
/// 401 from a timeout. Every other exception type still becomes `Left`.
library;

import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lcc_mobile_app/core/error/failure.dart';
import 'package:lcc_mobile_app/core/network/api_exception.dart';
import 'package:lcc_mobile_app/features/session/data/models/auth_tokens_model.dart';
import 'package:lcc_mobile_app/features/session/data/models/citizen_profile_model.dart';
import 'package:lcc_mobile_app/features/session/data/repositories/session_repository_impl.dart';
import 'package:lcc_mobile_app/features/session/domain/entities/auth_tokens.dart';
import 'package:lcc_mobile_app/features/session/domain/entities/citizen_profile.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../helpers/auth_mock_data.dart';
import '../../../../helpers/session_test_helper.dart';

void main() {
  late MockSessionRemoteDatasource remote;
  late SessionRepositoryImpl repository;

  setUp(() {
    remote = MockSessionRemoteDatasource();
    repository = SessionRepositoryImpl(remote: remote);
  });

  group('getProfile', () {
    test('returns Right with the mapped entity on success', () async {
      when(() => remote.getProfile()).thenAnswer(
        (_) async => CitizenProfileModel.fromJson(tCitizenProfileJson()),
      );

      final Either<Failure, CitizenProfile> result =
          await repository.getProfile();

      final CitizenProfile profile = result.getOrElse(
        () => throw StateError('expected Right'),
      );
      expect(profile.account.name, 'Test Citizen');
      expect(profile.place?.district?.en, 'Chanthabouly');
      expect(profile.householdNo, 'H001');
    });

    test('rethrows ApiException so the bloc can read isUnauthorized', () async {
      when(() => remote.getProfile()).thenThrow(
        const ApiException(status: 401, code: 'UNAUTHORIZED', message: 'nope'),
      );

      await expectLater(
        repository.getProfile(),
        throwsA(isA<ApiException>()
            .having((ApiException e) => e.isUnauthorized, 'isUnauthorized', isTrue)),
      );
    });

    test('wraps any other exception as Left(Failure)', () async {
      when(() => remote.getProfile()).thenThrow(const FormatException('bad json'));

      final Either<Failure, CitizenProfile> result =
          await repository.getProfile();

      expect(result.isLeft(), isTrue);
      expect(
        result.fold((Failure f) => f.message, (_) => ''),
        contains('bad json'),
      );
    });
  });

  group('logout', () {
    test('returns Right(null) when the revoke succeeds', () async {
      when(() => remote.logout(any())).thenAnswer((_) async {});

      final Either<Failure, void> result = await repository.logout('refresh-abc');

      expect(result.isRight(), isTrue);
      verify(() => remote.logout('refresh-abc')).called(1);
    });

    test('wraps even an ApiException as Left — a failed revoke must never trap '
        'the citizen in a session they asked to leave', () async {
      when(() => remote.logout(any())).thenThrow(
        const ApiException(status: 500, code: 'INTERNAL_ERROR', message: 'x'),
      );

      final Either<Failure, void> result = await repository.logout('refresh-abc');

      expect(result.isLeft(), isTrue);
    });
  });

  group('refreshTokens', () {
    test('returns Right with the mapped token pair', () async {
      when(() => remote.refreshTokens(any())).thenAnswer(
        (_) async => AuthTokensModel.fromJson(tAuthTokensJson),
      );

      final Either<Failure, AuthTokens> result =
          await repository.refreshTokens('refresh-abc');

      expect(
        result.getOrElse(() => throw StateError('expected Right')).accessToken,
        'access-abc',
      );
    });

    test('rethrows ApiException', () async {
      when(() => remote.refreshTokens(any())).thenThrow(
        const ApiException(status: 401, code: 'UNAUTHORIZED', message: 'nope'),
      );

      await expectLater(
        repository.refreshTokens('refresh-abc'),
        throwsA(isA<ApiException>()),
      );
    });

    test('wraps any other exception as Left(Failure)', () async {
      when(() => remote.refreshTokens(any()))
          .thenThrow(const FormatException('bad json'));

      final Either<Failure, AuthTokens> result =
          await repository.refreshTokens('refresh-abc');

      expect(result.isLeft(), isTrue);
    });
  });
}
