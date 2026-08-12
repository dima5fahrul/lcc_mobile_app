/// `PlaceNamesModel` — wire-shape mirror of [PlaceNames].
///
/// Ported from `lcc-app/src/app/api/types.ts` `PlaceNames`. Each component is
/// optional and maps to a nullable [BilingualModel].
library;

import 'package:freezed_annotation/freezed_annotation.dart';

import '../../domain/entities/place_names.dart';
import 'bilingual_model.dart';

part 'place_names_model.freezed.dart';
part 'place_names_model.g.dart';

@freezed
abstract class PlaceNamesModel with _$PlaceNamesModel {
  const factory PlaceNamesModel({
    BilingualModel? province,
    BilingualModel? district,
    BilingualModel? village,
  }) = _PlaceNamesModel;

  factory PlaceNamesModel.fromJson(Map<String, dynamic> json) =>
      _$PlaceNamesModelFromJson(json);
}

extension PlaceNamesModelX on PlaceNamesModel {
  PlaceNames toEntity() => PlaceNames(
        province: province?.toEntity(),
        district: district?.toEntity(),
        village: village?.toEntity(),
      );
}
