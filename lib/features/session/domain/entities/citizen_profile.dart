/// `CitizenProfile` — the full profile payload returned by `GET /me/profile`.
///
/// Ported verbatim from `lcc-app/src/app/api/types.ts`:
///   `interface CitizenProfile { account: CitizenAccount; place: PlaceNames; household_no: string; registry?: RegistryPerson; household?: HouseholdSummary; }`
///
/// For P0-2 only `account`, `place`, and `household_no` are typed. The
/// `registry` and `household` sub-objects belong to the registry feature
/// (batch berikut) and are kept as `Map<String, dynamic>?` stubs so the wire
/// payload is not lost while the typed ports do not yet exist.
library;

import 'package:freezed_annotation/freezed_annotation.dart';

import 'citizen_account.dart';
import 'place_names.dart';

part 'citizen_profile.freezed.dart';

@freezed
abstract class CitizenProfile with _$CitizenProfile {
  const factory CitizenProfile({
    required CitizenAccount account,
    PlaceNames? place,
    @JsonKey(name: 'household_no') String? householdNo,
    // P0 stub: typed port lands with the registry feature (batch berikut).
    Map<String, dynamic>? registry,
    Map<String, dynamic>? household,
  }) = _CitizenProfile;
}
