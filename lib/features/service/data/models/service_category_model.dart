/// `ServiceCategoryModel` — wire-shape mirror of [ServiceCategory].
///
/// `GET /service-categories`, plain envelope, `data` is an array of these.
/// Field names are the wire's snake_case; the entity's are Dart's camelCase,
/// and this file is the only place the two meet.
library;

import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../session/domain/entities/bilingual.dart';
import '../../domain/entities/service_category.dart';
import 'bilingual_converter.dart';

part 'service_category_model.freezed.dart';
part 'service_category_model.g.dart';

@freezed
abstract class ServiceCategoryModel with _$ServiceCategoryModel {
  const factory ServiceCategoryModel({
    @JsonKey(name: 'id') required String id,
    @JsonKey(name: 'code') required String code,
    @JsonKey(name: 'name') @BilingualConverter() required Bilingual name,
    @JsonKey(name: 'icon') required String icon,
    @JsonKey(name: 'color') required String color,
    @JsonKey(name: 'sort_order') required int sortOrder,
    @JsonKey(name: 'active') required bool active,
  }) = _ServiceCategoryModel;

  factory ServiceCategoryModel.fromJson(Map<String, dynamic> json) =>
      _$ServiceCategoryModelFromJson(json);
}

extension ServiceCategoryModelX on ServiceCategoryModel {
  ServiceCategory toEntity() => ServiceCategory(
        id: id,
        code: code,
        name: name,
        icon: icon,
        color: color,
        sortOrder: sortOrder,
        active: active,
      );
}
