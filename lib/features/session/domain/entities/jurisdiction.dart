/// `Jurisdiction` — the citizen's administrative location, as the wire sends it.
///
/// Ported from `lcc-app/src/app/api/types.ts`:
///
/// ```ts
/// export interface Jurisdiction {
///   province_id?: string;
///   province_name?: string;
///   district_id?: string;
///   district_name?: string;
///   village_id?: string;
///   village_name?: string;
/// }
/// ```
///
/// **All six are optional in the source and all six are nullable here.** That
/// is not defensive nullability — it is the declaration. A staging account
/// measured on 2026-08-19 returned `"jurisdiction": {}`, an object with none of
/// the six set, which the source's type permits exactly.
///
/// ## Why this type exists (2026-08-19)
///
/// `citizen_account.dart` carried `required String jurisdiction` with a doc
/// comment saying so deliberately: *"kept as a plain `String` for P0 — the full
/// `Jurisdiction` union lands in a later stage when the registry feature is
/// ported."* The later stage never came, and the shortcut was not free: the
/// wire sends an **object**, so `json['jurisdiction'] as String` threw
/// `type 'Null' is not a subtype of type 'String' in type cast` and **every
/// citizen login failed at the OTP screen**.
///
/// The web never noticed. `client.ts` returns `envelope.data as T`, and a
/// TypeScript `as` is a compile-time annotation with no runtime check — so a
/// mistyped field reaches a component and renders as `undefined`. Dart's cast
/// is real. The port was faithful to `types.ts`'s field *list* and not to its
/// field *types*, and only the second kind of infidelity is observable.
library;

import 'package:freezed_annotation/freezed_annotation.dart';

part 'jurisdiction.freezed.dart';

@freezed
abstract class Jurisdiction with _$Jurisdiction {
  const factory Jurisdiction({
    @JsonKey(name: 'province_id') String? provinceId,
    @JsonKey(name: 'province_name') String? provinceName,
    @JsonKey(name: 'district_id') String? districtId,
    @JsonKey(name: 'district_name') String? districtName,
    @JsonKey(name: 'village_id') String? villageId,
    @JsonKey(name: 'village_name') String? villageName,
  }) = _Jurisdiction;
}
