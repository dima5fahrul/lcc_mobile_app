/// Doubles and wire fixtures for the **session** feature.
///
/// Parallel to `auth_test_helper.dart` / `auth_mock_data.dart` rather than an
/// extension of them: the two features share only `CitizenAccount`, and a
/// single shared helper would make every auth test compile the session
/// repository graph and vice versa. The one genuinely shared fixture —
/// `tCitizenAccountJson` — is re-used from `auth_mock_data.dart` instead of
/// being copied.
library;

import 'package:lcc_mobile_app/features/session/data/datasources/session_remote_datasource.dart';
import 'package:lcc_mobile_app/features/session/domain/entities/auth_tokens.dart';
import 'package:lcc_mobile_app/features/session/domain/entities/citizen_account.dart';
import 'package:lcc_mobile_app/features/session/domain/entities/citizen_profile.dart';
import 'package:lcc_mobile_app/features/session/domain/entities/citizen_session.dart';
import 'package:lcc_mobile_app/features/session/domain/repositories/session_repository.dart';
import 'package:lcc_mobile_app/features/session/domain/usecases/get_profile.dart';
import 'package:lcc_mobile_app/features/session/domain/usecases/update_profile.dart';
import 'package:mocktail/mocktail.dart';

import 'auth_mock_data.dart';

class MockSessionRemoteDatasource extends Mock
    implements SessionRemoteDatasource {}

class MockSessionRepository extends Mock implements SessionRepository {}

class MockGetProfile extends Mock implements GetProfile {}

/// B8a — R-25's `PATCH /me/profile {preferred_lang}` mirror.
///
/// `SessionBloc` now takes it as a required dependency, so every construction
/// site needs one. A mock rather than a real use case over a mock repository:
/// the R-25 assertions are about **whether it was called at all** (B8-AC-20's
/// zero-call case) and about the exact body (B8-AC-16), both of which are
/// invocation questions.
class MockUpdateProfile extends Mock implements UpdateProfile {}

// ── Wire fixtures ───────────────────────────────────────────────────────────

/// `{en, lo}` — the `Bilingual` wire shape.
Map<String, dynamic> tBilingualJson({String en = 'Vientiane', String lo = 'ວຽງຈັນ'}) =>
    <String, dynamic>{'en': en, 'lo': lo};

/// The `place` block of a profile: province / district / village.
Map<String, dynamic> tPlaceNamesJson() => <String, dynamic>{
      'province': tBilingualJson(),
      'district': tBilingualJson(en: 'Chanthabouly', lo: 'ຈັນທະບູລີ'),
      'village': tBilingualJson(en: 'Nongbone', lo: 'ໜອງບອນ'),
    };

/// `GET /me/profile` payload — the envelope's `data`.
///
/// [account] defaults to the shared `tCitizenAccountJson`; pass an override to
/// vary the citizen's name (the field the shell projection reads).
Map<String, dynamic> tCitizenProfileJson({
  Map<String, dynamic>? account,
  bool withPlace = true,
}) {
  return <String, dynamic>{
    'account': account ?? tCitizenAccountJson,
    if (withPlace) 'place': tPlaceNamesJson(),
    'household_no': 'H001',
    'registry': <String, dynamic>{'status': 'active'},
    'household': <String, dynamic>{'members': 4},
  };
}

/// A citizen account JSON with [name] and [avatarUrl] overridden — the two
/// fields `SessionBloc` projects into `CitizenProfileData`.
Map<String, dynamic> tCitizenAccountJsonWith({
  String name = 'Test Citizen',
  String? avatarUrl,
}) {
  return <String, dynamic>{
    ...tCitizenAccountJson,
    'name': name,
    if (avatarUrl != null) 'avatar_url': avatarUrl,
  };
}

// ── Entity fixtures ─────────────────────────────────────────────────────────

CitizenAccount tCitizenAccount({String name = 'Test Citizen', String? avatarUrl}) {
  return CitizenAccount(
    id: 'citizen-123',
    uin: '12345678901',
    name: name,
    phone: '+8562012345',
    email: 'test@example.com',
    nationalIdNo: 'ID1234567',
    dateOfBirth: '1990-01-01',
    gender: 'male',
    avatarUrl: avatarUrl,
    preferredLang: 'lo',
    jurisdiction: 'Vientiane',
    householdNo: 'H001',
    address: 'Vientiane',
    verified: true,
    eidVerified: false,
    active: true,
    createdAt: '2026-01-01T00:00:00Z',
  );
}

CitizenProfile tCitizenProfile({String name = 'Test Citizen', String? avatarUrl}) {
  return CitizenProfile(
    account: tCitizenAccount(name: name, avatarUrl: avatarUrl),
    householdNo: 'H001',
  );
}

AuthTokens tAuthTokens({
  String access = 'access-abc',
  String refresh = 'refresh-abc',
}) {
  return AuthTokens(accessToken: access, refreshToken: refresh);
}

CitizenSession tCitizenSession({
  String access = 'access-abc',
  String refresh = 'refresh-abc',
  String name = 'Test Citizen',
}) {
  return CitizenSession(
    actor: 'citizen',
    citizen: tCitizenAccount(name: name),
    tokens: tAuthTokens(access: access, refresh: refresh),
  );
}
