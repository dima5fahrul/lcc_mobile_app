// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'service_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ServiceModel _$ServiceModelFromJson(Map<String, dynamic> json) =>
    _ServiceModel(
      id: json['id'] as String,
      code: json['code'] as String,
      categoryId: json['category_id'] as String? ?? '',
      categoryCode: json['category_code'] as String? ?? '',
      name: const BilingualConverter().fromJson(
        json['name'] as Map<String, dynamic>,
      ),
      shortName: json['short_name'] as String? ?? '',
      description: const BilingualConverter().fromJson(
        json['description'] as Map<String, dynamic>,
      ),
      icon: json['icon'] as String? ?? '',
      color: json['color'] as String? ?? '',
      feeLak: (json['fee_lak'] as num?)?.toInt() ?? 0,
      feeMaxLak: (json['fee_max_lak'] as num?)?.toInt() ?? 0,
      feeIsRange: json['fee_is_range'] as bool? ?? false,
      slaDays: (json['sla_days'] as num?)?.toInt() ?? 0,
      processingTime: json['processing_time'] == null
          ? const Bilingual(en: '', lo: '')
          : const BilingualConverter().fromJson(
              json['processing_time'] as Map<String, dynamic>,
            ),
      requiredDocs:
          (json['required_docs'] as List<dynamic>?)
              ?.map(
                (e) => const BilingualConverter().fromJson(
                  e as Map<String, dynamic>,
                ),
              )
              .toList() ??
          const <Bilingual>[],
      requiresPayment: json['requires_payment'] as bool? ?? false,
      isPhase1: json['is_phase1'] as bool? ?? false,
      active: json['active'] as bool? ?? true,
      sortOrder: (json['sort_order'] as num?)?.toInt() ?? 0,
      routePath: json['route_path'] as String? ?? '',
      familyBookEffect: json['family_book_effect'] as String? ?? '',
    );

Map<String, dynamic> _$ServiceModelToJson(
  _ServiceModel instance,
) => <String, dynamic>{
  'id': instance.id,
  'code': instance.code,
  'category_id': instance.categoryId,
  'category_code': instance.categoryCode,
  'name': const BilingualConverter().toJson(instance.name),
  'short_name': instance.shortName,
  'description': const BilingualConverter().toJson(instance.description),
  'icon': instance.icon,
  'color': instance.color,
  'fee_lak': instance.feeLak,
  'fee_max_lak': instance.feeMaxLak,
  'fee_is_range': instance.feeIsRange,
  'sla_days': instance.slaDays,
  'processing_time': const BilingualConverter().toJson(instance.processingTime),
  'required_docs': instance.requiredDocs
      .map(const BilingualConverter().toJson)
      .toList(),
  'requires_payment': instance.requiresPayment,
  'is_phase1': instance.isPhase1,
  'active': instance.active,
  'sort_order': instance.sortOrder,
  'route_path': instance.routePath,
  'family_book_effect': instance.familyBookEffect,
};
