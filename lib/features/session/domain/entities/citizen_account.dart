/// `CitizenAccount` — the signed-in citizen's identity record.
///
/// Ported from `lcc-app/src/app/api/types.ts` `CitizenAccount`. Every
/// snake_case wire field is mapped to a camelCase Dart field via `@JsonKey`.
///
/// ## Nullability corrected 2026-08-19, and it was a live login failure
///
/// This class previously required fourteen `String`s, matching `types.ts`'s
/// field list. Measured against a real staging `verify-otp` response, that list
/// is not what the server sends:
///
/// | field | `types.ts` | staging, 2026-08-19 |
/// |---|---|---|
/// | `jurisdiction` | `Jurisdiction` (object) | `{}` — **an object, never a string** |
/// | `uin` | `string` | absent |
/// | `national_id_no` | `string` | absent |
/// | `date_of_birth` | `string` | absent |
/// | `gender` | `string` | absent |
/// | `household_no` | `string` | absent |
/// | `address` | `string` | absent |
///
/// Every one of the seven threw `type 'Null' is not a subtype of type 'String'
/// in type cast` inside `CitizenSessionModel.fromJson`, so **no citizen could
/// complete OTP login**. The screen showed the cast error under the code
/// inputs.
///
/// **Why the web is unaffected, and why that matters here.** `client.ts` ends
/// its success path with `return envelope.data as T`. A TypeScript `as` is a
/// compile-time annotation: nothing verifies it at runtime, so an absent
/// `address` reaches a component as `undefined` and renders blank. Dart's cast
/// is real and throws. The port was faithful to the *declaration* and the
/// declaration has been wrong for as long as this endpoint has existed —
/// silently, because only a language that checks could have said so.
///
/// **These six are nullable, not defaulted.** An absent `household_no` is not
/// `''`: `''` would mean *the server said this citizen has no household number*,
/// and it did not say that. `null` is the honest carrier for "the wire did not
/// send this", and it makes every reader decide what to render — which is the
/// decision the source's `undefined` forces on its own components too.
///
/// **This is a divergence from `types.ts` and it is recorded as one.** The
/// source declares six of them required. The server does not send them. Between
/// a declaration nobody checks and a payload measured today, the payload
/// governs — otherwise the port is faithful to a document and broken against
/// the system it talks to.
library;

import 'package:freezed_annotation/freezed_annotation.dart';

import 'jurisdiction.dart';

part 'citizen_account.freezed.dart';

@freezed
abstract class CitizenAccount with _$CitizenAccount {
  const factory CitizenAccount({
    required String id,
    required String name,
    required String phone,
    required String email,
    @JsonKey(name: 'preferred_lang') required String preferredLang,
    required bool verified,
    @JsonKey(name: 'eid_verified') required bool eidVerified,
    required bool active,
    @JsonKey(name: 'created_at') required String createdAt,

    // ── Absent from a real staging payload, 2026-08-19 ──────────────────────
    //
    // `types.ts` declares all six required. Staging sends none of them for an
    // unverified account created 2026-08-12. Nullable so a login succeeds; the
    // divergence from the source's declaration is stated in the library doc
    // above rather than hidden behind a default.
    String? uin,
    @JsonKey(name: 'national_id_no') String? nationalIdNo,
    @JsonKey(name: 'date_of_birth') String? dateOfBirth,
    String? gender,
    @JsonKey(name: 'household_no') String? householdNo,
    String? address,

    /// **An object, not a string** — `types.ts` `interface Jurisdiction`.
    /// Nullable because the field may be absent entirely; `{}` parses to a
    /// `Jurisdiction` with all six members null, which is what staging sends.
    Jurisdiction? jurisdiction,

    @JsonKey(name: 'avatar_url') String? avatarUrl,
    @JsonKey(name: 'last_login_at') String? lastLoginAt,
  }) = _CitizenAccount;
}
