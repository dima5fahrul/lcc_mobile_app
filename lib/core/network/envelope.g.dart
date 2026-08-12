// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'envelope.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_PageMeta _$PageMetaFromJson(Map<String, dynamic> json) => _PageMeta(
  page: (json['page'] as num).toInt(),
  perPage: (json['per_page'] as num).toInt(),
  total: (json['total'] as num).toInt(),
  totalPages: (json['total_pages'] as num).toInt(),
  hasNext: json['has_next'] as bool,
  hasPrev: json['has_prev'] as bool,
);

Map<String, dynamic> _$PageMetaToJson(_PageMeta instance) => <String, dynamic>{
  'page': instance.page,
  'per_page': instance.perPage,
  'total': instance.total,
  'total_pages': instance.totalPages,
  'has_next': instance.hasNext,
  'has_prev': instance.hasPrev,
};

_FieldError _$FieldErrorFromJson(Map<String, dynamic> json) => _FieldError(
  field: json['field'] as String,
  rule: json['rule'] as String?,
  message: json['message'] as String,
);

Map<String, dynamic> _$FieldErrorToJson(_FieldError instance) =>
    <String, dynamic>{
      'field': instance.field,
      'rule': instance.rule,
      'message': instance.message,
    };

_Envelope<T> _$EnvelopeFromJson<T>(
  Map<String, dynamic> json,
  T Function(Object? json) fromJsonT,
) => _Envelope<T>(
  success: json['success'] as bool,
  message: json['message'] as String,
  data: _$nullableGenericFromJson(json['data'], fromJsonT),
  meta: json['meta'] == null
      ? null
      : PageMeta.fromJson(json['meta'] as Map<String, dynamic>),
  code: json['code'] as String?,
  errors: (json['errors'] as List<dynamic>?)
      ?.map((e) => FieldError.fromJson(e as Map<String, dynamic>))
      .toList(),
  requestId: json['request_id'] as String?,
);

Map<String, dynamic> _$EnvelopeToJson<T>(
  _Envelope<T> instance,
  Object? Function(T value) toJsonT,
) => <String, dynamic>{
  'success': instance.success,
  'message': instance.message,
  'data': _$nullableGenericToJson(instance.data, toJsonT),
  'meta': instance.meta,
  'code': instance.code,
  'errors': instance.errors,
  'request_id': instance.requestId,
};

T? _$nullableGenericFromJson<T>(
  Object? input,
  T Function(Object? json) fromJson,
) => input == null ? null : fromJson(input);

Object? _$nullableGenericToJson<T>(
  T? input,
  Object? Function(T value) toJson,
) => input == null ? null : toJson(input);
