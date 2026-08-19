/// `JurisdictionModel` — wire-shape mirror of [Jurisdiction].
///
/// Ported from `lcc-app/src/app/api/types.ts` `interface Jurisdiction`, whose
/// six members are all optional. Added 2026-08-19 with the nullability
/// correction `citizen_account.dart` records: the field was typed `String` in
/// this port and the wire sends an object, which is what broke citizen login.
///
/// Exists as a model rather than reusing the entity because
/// `CitizenAccountModel` is `json_serializable`-generated and the generator
/// needs a `fromJson` on the nested type to build the parse.
library;

import 'package:freezed_annotation/freezed_annotation.dart';

import '../../domain/entities/jurisdiction.dart';

part 'jurisdiction_model.freezed.dart';
part 'jurisdiction_model.g.dart';

@freezed
abstract class JurisdictionModel with _$JurisdictionModel {
  const factory JurisdictionModel({
    @JsonKey(name: 'province_id') String? provinceId,
    @JsonKey(name: 'province_name') String? provinceName,
    @JsonKey(name: 'district_id') String? districtId,
    @JsonKey(name: 'district_name') String? districtName,
    @JsonKey(name: 'village_id') String? villageId,
    @JsonKey(name: 'village_name') String? villageName,
  }) = _JurisdictionModel;

  factory JurisdictionModel.fromJson(Map<String, dynamic> json) =>
      _$JurisdictionModelFromJson(json);
}

extension JurisdictionModelX on JurisdictionModel {
  Jurisdiction toEntity() => Jurisdiction(
        provinceId: provinceId,
        provinceName: provinceName,
        districtId: districtId,
        districtName: districtName,
        villageId: villageId,
        villageName: villageName,
      );
}
