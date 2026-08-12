/// `PlaceNames` — the province/district/village label triple for a citizen.
///
/// Ported verbatim from `lcc-app/src/app/api/types.ts`:
///   `interface PlaceNames { province?: Bilingual; district?: Bilingual; village?: Bilingual; }`
///
/// Every component is optional — a place may be resolved only down to the
/// district level, leaving `village` null.
library;

import 'package:freezed_annotation/freezed_annotation.dart';

import 'bilingual.dart';

part 'place_names.freezed.dart';

@freezed
abstract class PlaceNames with _$PlaceNames {
  const factory PlaceNames({
    Bilingual? province,
    Bilingual? district,
    Bilingual? village,
  }) = _PlaceNames;
}
