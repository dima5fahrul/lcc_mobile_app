/// Mock data for auth feature tests.
///
/// Complete JSON shapes matching the wire contract so the generated
/// `fromJson` / hand-written `fromJson` paths can parse without missing-field
/// errors.
library;

const Map<String, dynamic> tCitizenAccountJson = {
  'id': 'citizen-123',
  'uin': '12345678901',
  'name': 'Test Citizen',
  'phone': '+8562012345',
  'email': 'test@example.com',
  'national_id_no': 'ID1234567',
  'date_of_birth': '1990-01-01',
  'gender': 'male',
  'preferred_lang': 'lo',
  // An OBJECT, not a string — `types.ts` `interface Jurisdiction`. This
  // fixture said `'Vientiane'` until 2026-08-19, and being wrong in the same
  // direction as the production model is exactly why 13 tests over this data
  // could not see that citizen login was broken. A fixture that agrees with
  // the code it feeds proves the two agree, not that either is right.
  'jurisdiction': <String, dynamic>{
    'province_id': 'P-VTE',
    'province_name': 'Vientiane',
  },
  'household_no': 'H001',
  'address': 'Vientiane',
  'verified': true,
  'eid_verified': false,
  'active': true,
  'created_at': '2026-01-01T00:00:00Z',
};

const Map<String, dynamic> tAuthTokensJson = {
  'access_token': 'access-abc',
  'refresh_token': 'refresh-abc',
};

Map<String, dynamic> tCitizenSessionJson({
  Map<String, dynamic>? citizen,
  Map<String, dynamic>? tokens,
}) {
  return <String, dynamic>{
    'actor': 'citizen',
    'citizen': citizen ?? tCitizenAccountJson,
    'tokens': tokens ?? tAuthTokensJson,
  };
}

Map<String, dynamic> tOtpChallengeJson({
  String phone = '+8562012345',
  String purpose = 'login',
}) {
  return <String, dynamic>{
    'phone': phone,
    'purpose': purpose,
    'expires_in': 300,
    'resend_after': 60,
    'dev_code': '123456',
  };
}

Map<String, dynamic> tRegisterResultJson({
  String phone = '+8562012345',
  String purpose = 'register',
}) {
  return <String, dynamic>{
    'citizen_id': 'citizen-123',
    'challenge': tOtpChallengeJson(phone: phone, purpose: purpose),
  };
}
