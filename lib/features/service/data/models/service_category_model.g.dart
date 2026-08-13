// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'service_category_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ServiceCategoryModel _$ServiceCategoryModelFromJson(
  Map<String, dynamic> json,
) => _ServiceCategoryModel(
  id: json['id'] as String,
  code: json['code'] as String,
  name: const BilingualConverter().fromJson(
    json['name'] as Map<String, dynamic>,
  ),
  icon: json['icon'] as String,
  color: json['color'] as String,
  sortOrder: (json['sort_order'] as num).toInt(),
  active: json['active'] as bool,
);

Map<String, dynamic> _$ServiceCategoryModelToJson(
  _ServiceCategoryModel instance,
) => <String, dynamic>{
  'id': instance.id,
  'code': instance.code,
  'name': const BilingualConverter().toJson(instance.name),
  'icon': instance.icon,
  'color': instance.color,
  'sort_order': instance.sortOrder,
  'active': instance.active,
};
