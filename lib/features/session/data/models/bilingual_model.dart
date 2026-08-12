/// `BilingualModel` — wire-shape mirror of [Bilingual].
///
/// Ported from `lcc-app/src/app/api/types.ts` `Bilingual`. Nested inside
/// [PlaceNamesModel].
library;

import 'package:freezed_annotation/freezed_annotation.dart';

import '../../domain/entities/bilingual.dart';

part 'bilingual_model.freezed.dart';
part 'bilingual_model.g.dart';

@freezed
abstract class BilingualModel with _$BilingualModel {
  const factory BilingualModel({
    required String en,
    required String lo,
  }) = _BilingualModel;

  factory BilingualModel.fromJson(Map<String, dynamic> json) =>
      _$BilingualModelFromJson(json);
}

extension BilingualModelX on BilingualModel {
  Bilingual toEntity() => Bilingual(en: en, lo: lo);
}
