/// `CitizenSession` — the boot payload returned by login/OTP-verify.
///
/// Ported verbatim from `lcc-app/src/app/api/types.ts`:
///   `interface CitizenSession { actor: "citizen"; citizen: CitizenAccount; tokens: AuthTokens; }`
///
/// The `actor` field is always `"citizen"` for this portal; kept as a required
/// string so a future admin/eid actor surface shows up as a compile-time
/// change rather than a silent branch.
library;

import 'package:freezed_annotation/freezed_annotation.dart';

import 'auth_tokens.dart';
import 'citizen_account.dart';

part 'citizen_session.freezed.dart';

@freezed
abstract class CitizenSession with _$CitizenSession {
  const factory CitizenSession({
    required String actor,
    required CitizenAccount citizen,
    required AuthTokens tokens,
  }) = _CitizenSession;
}
