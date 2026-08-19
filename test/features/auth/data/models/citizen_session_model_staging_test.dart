/// The `verify-otp` payload staging actually sends — the one that broke login.
///
/// ## Why this file exists
///
/// On 2026-08-19 every citizen OTP login failed with
/// `type 'Null' is not a subtype of type 'String' in type cast`, shown under
/// the code inputs. `CitizenSessionModel.fromJson` required fourteen `String`s
/// on the nested `citizen` object; a real staging response carries **nine** of
/// them and types a tenth differently.
///
/// The suite could not see it. Every existing fixture for this model was built
/// from the model's own shape — so it necessarily contained every field the
/// model demanded, and necessarily passed. **A fixture derived from the code it
/// tests cannot contradict that code.** This one is transcribed from a real
/// response instead, which is the only reason it has anything to say.
///
/// ## The payload
///
/// Captured from `POST /auth/citizen/verify-otp` against
/// `api.staging.linkit360.la` on 2026-08-19, for an account created 2026-08-12
/// with `verified: false`. Identifiers are replaced with synthetic values of
/// the same shape and the two JWTs with `'...'` — **what this file asserts is
/// which keys are present and what type each holds**, never their contents.
///
/// Absent from the `citizen` object: `uin`, `national_id_no`, `date_of_birth`,
/// `gender`, `household_no`, `address`. Present but an **object**, not a
/// string: `jurisdiction`, sent as `{}`.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:lcc_mobile_app/features/auth/data/models/citizen_session_model.dart';

/// The `data` object, verbatim in structure.
Map<String, dynamic> stagingVerifyOtpData() => <String, dynamic>{
      'actor': 'citizen',
      'citizen': <String, dynamic>{
        'id': '82b101ac-8f8f-498f-b715-eb32abc8b60b',
        'name': 'Mencoba',
        'phone': '+62896xxxxxxx',
        'email': 'citizen@example.test',
        'preferred_lang': 'lo',
        'jurisdiction': <String, dynamic>{},
        'verified': false,
        'eid_verified': false,
        'active': true,
        'last_login_at': '2026-08-19T08:03:04Z',
        'created_at': '2026-08-12T01:09:36Z',
      },
      'tokens': <String, dynamic>{
        'access_token': '...',
        'refresh_token': '...',
        'token_type': 'Bearer',
        'expires_in': 86399,
        'expires_at': '2026-08-20T08:03:04Z',
        'refresh_expires_at': '2026-09-18T08:03:04Z',
      },
    };

void main() {
  group('the payload staging sends', () {
    test('parses — this is the login that was failing', () {
      final CitizenSessionModel session =
          CitizenSessionModel.fromJson(stagingVerifyOtpData());

      expect(session.actor, 'citizen');
      expect(session.citizen.name, 'Mencoba');
      expect(session.tokens.accessToken, '...');
    });

    test('the six fields staging omits arrive as null, not as empty strings',
        () {
      final CitizenSessionModel session =
          CitizenSessionModel.fromJson(stagingVerifyOtpData());

      // `null` and `''` are different claims. `''` would assert the server
      // said this citizen has no household number; it said nothing at all.
      // Anything rendering these must decide, and `null` is what forces it to.
      expect(session.citizen.uin, isNull);
      expect(session.citizen.nationalIdNo, isNull);
      expect(session.citizen.dateOfBirth, isNull);
      expect(session.citizen.gender, isNull);
      expect(session.citizen.householdNo, isNull);
      expect(session.citizen.address, isNull);
    });

    test('`jurisdiction: {}` parses to an all-null Jurisdiction, not a crash',
        () {
      final CitizenSessionModel session =
          CitizenSessionModel.fromJson(stagingVerifyOtpData());

      expect(session.citizen.jurisdiction, isNotNull);
      expect(session.citizen.jurisdiction!.provinceId, isNull);
      expect(session.citizen.jurisdiction!.villageName, isNull);
    });
  });

  group('jurisdiction, when the server fills it in', () {
    test('all six members map by their wire names', () {
      final Map<String, dynamic> data = stagingVerifyOtpData();
      (data['citizen']! as Map<String, dynamic>)['jurisdiction'] =
          <String, dynamic>{
        'province_id': 'P1',
        'province_name': 'Vientiane',
        'district_id': 'D1',
        'district_name': 'Chanthabouly',
        'village_id': 'V1',
        'village_name': 'Ban Sisavath',
      };

      final CitizenSessionModel session = CitizenSessionModel.fromJson(data);

      expect(session.citizen.jurisdiction!.provinceId, 'P1');
      expect(session.citizen.jurisdiction!.provinceName, 'Vientiane');
      expect(session.citizen.jurisdiction!.districtId, 'D1');
      expect(session.citizen.jurisdiction!.districtName, 'Chanthabouly');
      expect(session.citizen.jurisdiction!.villageId, 'V1');
      expect(session.citizen.jurisdiction!.villageName, 'Ban Sisavath');
    });

    test('a non-object jurisdiction degrades to null rather than throwing', () {
      // The defensive half of the fix, and the reason `_jurisdictionFromJson`
      // takes `Object?`. This field was typed `String` in the port for months;
      // if the server ever sends one, the citizen must not meet a cast error on
      // a screen they cannot get past.
      for (final Object? hostile in <Object?>['Vientiane', 42, <int>[1], null]) {
        final Map<String, dynamic> data = stagingVerifyOtpData();
        (data['citizen']! as Map<String, dynamic>)['jurisdiction'] = hostile;

        final CitizenSessionModel session = CitizenSessionModel.fromJson(data);
        expect(session.citizen.jurisdiction, isNull,
            reason: 'a ${hostile.runtimeType} jurisdiction must not throw');
      }
    });
  });

  group('what still must be present', () {
    // The correction loosened seven fields. It must not have loosened the nine
    // the payload does carry — otherwise a genuinely malformed response parses
    // into a half-empty session and fails somewhere further from the cause.
    for (final String required in <String>[
      'id',
      'name',
      'phone',
      'email',
      'preferred_lang',
      'verified',
      'eid_verified',
      'active',
      'created_at',
    ]) {
      test('a missing `$required` still throws', () {
        final Map<String, dynamic> data = stagingVerifyOtpData();
        (data['citizen']! as Map<String, dynamic>).remove(required);

        expect(
          () => CitizenSessionModel.fromJson(data),
          throwsA(isA<TypeError>()),
          reason: '$required is present in every measured payload; dropping it '
              'silently would hide a real contract break',
        );
      });
    }
  });
}
