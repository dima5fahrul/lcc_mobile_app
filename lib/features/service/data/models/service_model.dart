/// `ServiceModel` — wire-shape mirror of [Service].
///
/// `GET /services`, plain envelope, `data` is an array of these. 43 rows on
/// staging today.
///
/// ## Defaults on scalars, none on the two `Bilingual` names
///
/// The numeric and boolean fields carry `@Default`s because the catalogue is
/// administrator-maintained and a newly-added row can reach the wire before
/// every optional column is filled: a missing `fee_max_lak` should render a
/// single fee, not take the page down. [name] and [description] have no
/// default — a service with no name is not a degraded row, it is a bug in the
/// catalogue, and rendering a blank card would hide it.
library;

import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../session/domain/entities/bilingual.dart';
import '../../domain/entities/service.dart';
import 'bilingual_converter.dart';

part 'service_model.freezed.dart';
part 'service_model.g.dart';

@freezed
abstract class ServiceModel with _$ServiceModel {
  const factory ServiceModel({
    @JsonKey(name: 'id') required String id,
    @JsonKey(name: 'code') required String code,
    @JsonKey(name: 'category_id') @Default('') String categoryId,
    @JsonKey(name: 'category_code') @Default('') String categoryCode,
    @JsonKey(name: 'name') @BilingualConverter() required Bilingual name,
    @JsonKey(name: 'short_name') @Default('') String shortName,
    @JsonKey(name: 'description')
    @BilingualConverter()
    required Bilingual description,
    @JsonKey(name: 'icon') @Default('') String icon,
    @JsonKey(name: 'color') @Default('') String color,
    @JsonKey(name: 'fee_lak') @Default(0) int feeLak,
    @JsonKey(name: 'fee_max_lak') @Default(0) int feeMaxLak,
    @JsonKey(name: 'fee_is_range') @Default(false) bool feeIsRange,
    @JsonKey(name: 'sla_days') @Default(0) int slaDays,
    @JsonKey(name: 'processing_time')
    @BilingualConverter()
    @Default(Bilingual(en: '', lo: ''))
    Bilingual processingTime,
    @JsonKey(name: 'required_docs')
    @BilingualConverter()
    @Default(<Bilingual>[])
    List<Bilingual> requiredDocs,
    @JsonKey(name: 'requires_payment') @Default(false) bool requiresPayment,
    @JsonKey(name: 'is_phase1') @Default(false) bool isPhase1,
    @JsonKey(name: 'active') @Default(true) bool active,
    @JsonKey(name: 'sort_order') @Default(0) int sortOrder,
    @JsonKey(name: 'route_path') @Default('') String routePath,
    @JsonKey(name: 'family_book_effect') @Default('') String familyBookEffect,
  }) = _ServiceModel;

  factory ServiceModel.fromJson(Map<String, dynamic> json) =>
      _$ServiceModelFromJson(json);
}

extension ServiceModelX on ServiceModel {
  Service toEntity() => Service(
        id: id,
        code: code,
        categoryId: categoryId,
        categoryCode: categoryCode,
        name: name,
        shortName: shortName,
        description: description,
        icon: icon,
        color: color,
        feeLak: feeLak,
        feeMaxLak: feeMaxLak,
        feeIsRange: feeIsRange,
        slaDays: slaDays,
        processingTime: processingTime,
        requiredDocs: requiredDocs,
        requiresPayment: requiresPayment,
        isPhase1: isPhase1,
        active: active,
        sortOrder: sortOrder,
        routePath: routePath,
        familyBookEffect: familyBookEffect,
      );
}
