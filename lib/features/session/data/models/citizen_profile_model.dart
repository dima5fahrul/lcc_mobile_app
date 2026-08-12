/// `CitizenProfileModel` — wire-shape mirror of [CitizenProfile].
///
/// Ported from `lcc-app/src/app/api/types.ts` `CitizenProfile`. Returned by
/// `GET /me/profile`. The `registry` and `household` sub-objects are P0 stubs
/// (typed ports land with the registry feature, batch berikut) and pass
/// through as raw maps so the payload is not lost.
library;

import 'package:freezed_annotation/freezed_annotation.dart';

import '../../domain/entities/citizen_profile.dart';
import 'citizen_account_model.dart';
import 'place_names_model.dart';

part 'citizen_profile_model.freezed.dart';
part 'citizen_profile_model.g.dart';

@freezed
abstract class CitizenProfileModel with _$CitizenProfileModel {
  const factory CitizenProfileModel({
    required CitizenAccountModel account,
    PlaceNamesModel? place,
    @JsonKey(name: 'household_no') String? householdNo,
    // P0 stub: typed port lands with the registry feature (batch berikut).
    Map<String, dynamic>? registry,
    Map<String, dynamic>? household,
  }) = _CitizenProfileModel;

  factory CitizenProfileModel.fromJson(Map<String, dynamic> json) =>
      _$CitizenProfileModelFromJson(json);
}

extension CitizenProfileModelX on CitizenProfileModel {
  CitizenProfile toEntity() => CitizenProfile(
        account: account.toEntity(),
        place: place?.toEntity(),
        householdNo: householdNo,
        registry: registry,
        household: household,
      );
}
