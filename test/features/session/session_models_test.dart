/// Session wire models and the `GetProfile` usecase.
///
/// The `toEntity()` extensions are hand-written (not generated), so they are
/// the part of `data/models/**` that can actually be wrong: a field dropped
/// from a 17-field mapping compiles fine and silently loses data. Each mapping
/// is therefore asserted field by field against the wire fixture.
library;

import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lcc_mobile_app/core/error/failure.dart';
import 'package:lcc_mobile_app/core/usecase/usecase.dart';
import 'package:lcc_mobile_app/features/session/data/models/auth_tokens_model.dart';
import 'package:lcc_mobile_app/features/session/data/models/bilingual_model.dart';
import 'package:lcc_mobile_app/features/session/data/models/citizen_account_model.dart';
import 'package:lcc_mobile_app/features/session/data/models/citizen_profile_model.dart';
import 'package:lcc_mobile_app/features/session/data/models/place_names_model.dart';
import 'package:lcc_mobile_app/features/session/domain/entities/citizen_account.dart';
import 'package:lcc_mobile_app/features/session/domain/entities/citizen_profile.dart';
import 'package:lcc_mobile_app/features/session/domain/usecases/get_profile.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/auth_mock_data.dart';
import '../../helpers/session_test_helper.dart';

void main() {
  group('BilingualModel', () {
    test('parses and maps both sides', () {
      final BilingualModel model = BilingualModel.fromJson(tBilingualJson());

      expect(model.toEntity().en, 'Vientiane');
      expect(model.toEntity().lo, 'ວຽງຈັນ');
    });
  });

  group('PlaceNamesModel', () {
    test('maps province, district and village', () {
      final PlaceNamesModel model = PlaceNamesModel.fromJson(tPlaceNamesJson());

      expect(model.toEntity().province?.en, 'Vientiane');
      expect(model.toEntity().district?.lo, 'ຈັນທະບູລີ');
      expect(model.toEntity().village?.en, 'Nongbone');
    });

    test('keeps null components null rather than inventing empties', () {
      final PlaceNamesModel model =
          PlaceNamesModel.fromJson(<String, dynamic>{});

      expect(model.toEntity().province, isNull);
      expect(model.toEntity().district, isNull);
      expect(model.toEntity().village, isNull);
    });
  });

  group('AuthTokensModel', () {
    test('parses the snake_case token pair', () {
      final AuthTokensModel model = AuthTokensModel.fromJson(<String, dynamic>{
        ...tAuthTokensJson,
        'token_type': 'Bearer',
        'expires_at': '2026-12-31T00:00:00Z',
      });

      expect(model.toEntity().accessToken, 'access-abc');
      expect(model.toEntity().refreshToken, 'refresh-abc');
      expect(model.toEntity().tokenType, 'Bearer');
      expect(model.toEntity().expiresAt, '2026-12-31T00:00:00Z');
    });

    test('leaves the optional fields null when the server omits them', () {
      final AuthTokensModel model = AuthTokensModel.fromJson(tAuthTokensJson);

      expect(model.toEntity().tokenType, isNull);
      expect(model.toEntity().expiresAt, isNull);
    });
  });

  group('CitizenAccountModel', () {
    test('maps every one of the seventeen fields', () {
      final CitizenAccountModel model = CitizenAccountModel.fromJson(
        tCitizenAccountJsonWith(name: 'Somsak', avatarUrl: 'https://x/y.png'),
      );

      final CitizenAccount entity = model.toEntity();
      expect(entity.id, 'citizen-123');
      expect(entity.uin, '12345678901');
      expect(entity.name, 'Somsak');
      expect(entity.phone, '+8562012345');
      expect(entity.email, 'test@example.com');
      expect(entity.nationalIdNo, 'ID1234567');
      expect(entity.dateOfBirth, '1990-01-01');
      expect(entity.gender, 'male');
      expect(entity.avatarUrl, 'https://x/y.png');
      expect(entity.preferredLang, 'lo');
      expect(entity.jurisdiction, 'Vientiane');
      expect(entity.householdNo, 'H001');
      expect(entity.address, 'Vientiane');
      expect(entity.verified, isTrue);
      expect(entity.eidVerified, isFalse);
      expect(entity.active, isTrue);
      expect(entity.createdAt, '2026-01-01T00:00:00Z');
    });

    test('tolerates the two optional fields being absent', () {
      final CitizenAccountModel model =
          CitizenAccountModel.fromJson(tCitizenAccountJson);

      expect(model.toEntity().avatarUrl, isNull);
      expect(model.toEntity().lastLoginAt, isNull);
    });
  });

  group('CitizenProfileModel', () {
    test('maps the account, place, household number and the P0 stub blocks',
        () {
      final CitizenProfileModel model =
          CitizenProfileModel.fromJson(tCitizenProfileJson());

      final CitizenProfile entity = model.toEntity();
      expect(entity.account.id, 'citizen-123');
      expect(entity.place?.village?.lo, 'ໜອງບອນ');
      expect(entity.householdNo, 'H001');
      expect(entity.registry, <String, dynamic>{'status': 'active'});
      expect(entity.household, <String, dynamic>{'members': 4});
    });

    test('maps a minimal profile carrying only the account', () {
      final CitizenProfileModel model =
          CitizenProfileModel.fromJson(<String, dynamic>{
        'account': tCitizenAccountJson,
      });

      final CitizenProfile entity = model.toEntity();
      expect(entity.place, isNull);
      expect(entity.householdNo, isNull);
      expect(entity.registry, isNull);
      expect(entity.household, isNull);
    });
  });

  group('GetProfile usecase', () {
    test('delegates straight to the repository', () async {
      final MockSessionRepository repository = MockSessionRepository();
      when(() => repository.getProfile()).thenAnswer(
        (_) async => Right<Failure, CitizenProfile>(tCitizenProfile()),
      );

      final Either<Failure, CitizenProfile> result =
          await GetProfile(repository: repository)(NoParams());

      expect(result.isRight(), isTrue);
      verify(() => repository.getProfile()).called(1);
    });

    test('passes a Left straight back', () async {
      final MockSessionRepository repository = MockSessionRepository();
      when(() => repository.getProfile()).thenAnswer(
        (_) async => const Left<Failure, CitizenProfile>(Failure('offline')),
      );

      final Either<Failure, CitizenProfile> result =
          await GetProfile(repository: repository)(NoParams());

      expect(result.fold((Failure f) => f.message, (_) => ''), 'offline');
    });
  });
}
