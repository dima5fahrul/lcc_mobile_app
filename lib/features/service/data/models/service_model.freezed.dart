// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'service_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ServiceModel {

@JsonKey(name: 'id') String get id;@JsonKey(name: 'code') String get code;@JsonKey(name: 'category_id') String get categoryId;@JsonKey(name: 'category_code') String get categoryCode;@JsonKey(name: 'name')@BilingualConverter() Bilingual get name;@JsonKey(name: 'short_name') String get shortName;@JsonKey(name: 'description')@BilingualConverter() Bilingual get description;@JsonKey(name: 'icon') String get icon;@JsonKey(name: 'color') String get color;@JsonKey(name: 'fee_lak') int get feeLak;@JsonKey(name: 'fee_max_lak') int get feeMaxLak;@JsonKey(name: 'fee_is_range') bool get feeIsRange;@JsonKey(name: 'sla_days') int get slaDays;@JsonKey(name: 'processing_time')@BilingualConverter() Bilingual get processingTime;@JsonKey(name: 'required_docs')@BilingualConverter() List<Bilingual> get requiredDocs;@JsonKey(name: 'requires_payment') bool get requiresPayment;@JsonKey(name: 'is_phase1') bool get isPhase1;@JsonKey(name: 'active') bool get active;@JsonKey(name: 'sort_order') int get sortOrder;@JsonKey(name: 'route_path') String get routePath;@JsonKey(name: 'family_book_effect') String get familyBookEffect;
/// Create a copy of ServiceModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ServiceModelCopyWith<ServiceModel> get copyWith => _$ServiceModelCopyWithImpl<ServiceModel>(this as ServiceModel, _$identity);

  /// Serializes this ServiceModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ServiceModel&&(identical(other.id, id) || other.id == id)&&(identical(other.code, code) || other.code == code)&&(identical(other.categoryId, categoryId) || other.categoryId == categoryId)&&(identical(other.categoryCode, categoryCode) || other.categoryCode == categoryCode)&&(identical(other.name, name) || other.name == name)&&(identical(other.shortName, shortName) || other.shortName == shortName)&&(identical(other.description, description) || other.description == description)&&(identical(other.icon, icon) || other.icon == icon)&&(identical(other.color, color) || other.color == color)&&(identical(other.feeLak, feeLak) || other.feeLak == feeLak)&&(identical(other.feeMaxLak, feeMaxLak) || other.feeMaxLak == feeMaxLak)&&(identical(other.feeIsRange, feeIsRange) || other.feeIsRange == feeIsRange)&&(identical(other.slaDays, slaDays) || other.slaDays == slaDays)&&(identical(other.processingTime, processingTime) || other.processingTime == processingTime)&&const DeepCollectionEquality().equals(other.requiredDocs, requiredDocs)&&(identical(other.requiresPayment, requiresPayment) || other.requiresPayment == requiresPayment)&&(identical(other.isPhase1, isPhase1) || other.isPhase1 == isPhase1)&&(identical(other.active, active) || other.active == active)&&(identical(other.sortOrder, sortOrder) || other.sortOrder == sortOrder)&&(identical(other.routePath, routePath) || other.routePath == routePath)&&(identical(other.familyBookEffect, familyBookEffect) || other.familyBookEffect == familyBookEffect));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,id,code,categoryId,categoryCode,name,shortName,description,icon,color,feeLak,feeMaxLak,feeIsRange,slaDays,processingTime,const DeepCollectionEquality().hash(requiredDocs),requiresPayment,isPhase1,active,sortOrder,routePath,familyBookEffect]);

@override
String toString() {
  return 'ServiceModel(id: $id, code: $code, categoryId: $categoryId, categoryCode: $categoryCode, name: $name, shortName: $shortName, description: $description, icon: $icon, color: $color, feeLak: $feeLak, feeMaxLak: $feeMaxLak, feeIsRange: $feeIsRange, slaDays: $slaDays, processingTime: $processingTime, requiredDocs: $requiredDocs, requiresPayment: $requiresPayment, isPhase1: $isPhase1, active: $active, sortOrder: $sortOrder, routePath: $routePath, familyBookEffect: $familyBookEffect)';
}


}

/// @nodoc
abstract mixin class $ServiceModelCopyWith<$Res>  {
  factory $ServiceModelCopyWith(ServiceModel value, $Res Function(ServiceModel) _then) = _$ServiceModelCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'id') String id,@JsonKey(name: 'code') String code,@JsonKey(name: 'category_id') String categoryId,@JsonKey(name: 'category_code') String categoryCode,@JsonKey(name: 'name')@BilingualConverter() Bilingual name,@JsonKey(name: 'short_name') String shortName,@JsonKey(name: 'description')@BilingualConverter() Bilingual description,@JsonKey(name: 'icon') String icon,@JsonKey(name: 'color') String color,@JsonKey(name: 'fee_lak') int feeLak,@JsonKey(name: 'fee_max_lak') int feeMaxLak,@JsonKey(name: 'fee_is_range') bool feeIsRange,@JsonKey(name: 'sla_days') int slaDays,@JsonKey(name: 'processing_time')@BilingualConverter() Bilingual processingTime,@JsonKey(name: 'required_docs')@BilingualConverter() List<Bilingual> requiredDocs,@JsonKey(name: 'requires_payment') bool requiresPayment,@JsonKey(name: 'is_phase1') bool isPhase1,@JsonKey(name: 'active') bool active,@JsonKey(name: 'sort_order') int sortOrder,@JsonKey(name: 'route_path') String routePath,@JsonKey(name: 'family_book_effect') String familyBookEffect
});


$BilingualCopyWith<$Res> get name;$BilingualCopyWith<$Res> get description;$BilingualCopyWith<$Res> get processingTime;

}
/// @nodoc
class _$ServiceModelCopyWithImpl<$Res>
    implements $ServiceModelCopyWith<$Res> {
  _$ServiceModelCopyWithImpl(this._self, this._then);

  final ServiceModel _self;
  final $Res Function(ServiceModel) _then;

/// Create a copy of ServiceModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? code = null,Object? categoryId = null,Object? categoryCode = null,Object? name = null,Object? shortName = null,Object? description = null,Object? icon = null,Object? color = null,Object? feeLak = null,Object? feeMaxLak = null,Object? feeIsRange = null,Object? slaDays = null,Object? processingTime = null,Object? requiredDocs = null,Object? requiresPayment = null,Object? isPhase1 = null,Object? active = null,Object? sortOrder = null,Object? routePath = null,Object? familyBookEffect = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,code: null == code ? _self.code : code // ignore: cast_nullable_to_non_nullable
as String,categoryId: null == categoryId ? _self.categoryId : categoryId // ignore: cast_nullable_to_non_nullable
as String,categoryCode: null == categoryCode ? _self.categoryCode : categoryCode // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as Bilingual,shortName: null == shortName ? _self.shortName : shortName // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as Bilingual,icon: null == icon ? _self.icon : icon // ignore: cast_nullable_to_non_nullable
as String,color: null == color ? _self.color : color // ignore: cast_nullable_to_non_nullable
as String,feeLak: null == feeLak ? _self.feeLak : feeLak // ignore: cast_nullable_to_non_nullable
as int,feeMaxLak: null == feeMaxLak ? _self.feeMaxLak : feeMaxLak // ignore: cast_nullable_to_non_nullable
as int,feeIsRange: null == feeIsRange ? _self.feeIsRange : feeIsRange // ignore: cast_nullable_to_non_nullable
as bool,slaDays: null == slaDays ? _self.slaDays : slaDays // ignore: cast_nullable_to_non_nullable
as int,processingTime: null == processingTime ? _self.processingTime : processingTime // ignore: cast_nullable_to_non_nullable
as Bilingual,requiredDocs: null == requiredDocs ? _self.requiredDocs : requiredDocs // ignore: cast_nullable_to_non_nullable
as List<Bilingual>,requiresPayment: null == requiresPayment ? _self.requiresPayment : requiresPayment // ignore: cast_nullable_to_non_nullable
as bool,isPhase1: null == isPhase1 ? _self.isPhase1 : isPhase1 // ignore: cast_nullable_to_non_nullable
as bool,active: null == active ? _self.active : active // ignore: cast_nullable_to_non_nullable
as bool,sortOrder: null == sortOrder ? _self.sortOrder : sortOrder // ignore: cast_nullable_to_non_nullable
as int,routePath: null == routePath ? _self.routePath : routePath // ignore: cast_nullable_to_non_nullable
as String,familyBookEffect: null == familyBookEffect ? _self.familyBookEffect : familyBookEffect // ignore: cast_nullable_to_non_nullable
as String,
  ));
}
/// Create a copy of ServiceModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BilingualCopyWith<$Res> get name {
  
  return $BilingualCopyWith<$Res>(_self.name, (value) {
    return _then(_self.copyWith(name: value));
  });
}/// Create a copy of ServiceModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BilingualCopyWith<$Res> get description {
  
  return $BilingualCopyWith<$Res>(_self.description, (value) {
    return _then(_self.copyWith(description: value));
  });
}/// Create a copy of ServiceModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BilingualCopyWith<$Res> get processingTime {
  
  return $BilingualCopyWith<$Res>(_self.processingTime, (value) {
    return _then(_self.copyWith(processingTime: value));
  });
}
}


/// Adds pattern-matching-related methods to [ServiceModel].
extension ServiceModelPatterns on ServiceModel {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ServiceModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ServiceModel() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ServiceModel value)  $default,){
final _that = this;
switch (_that) {
case _ServiceModel():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ServiceModel value)?  $default,){
final _that = this;
switch (_that) {
case _ServiceModel() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'id')  String id, @JsonKey(name: 'code')  String code, @JsonKey(name: 'category_id')  String categoryId, @JsonKey(name: 'category_code')  String categoryCode, @JsonKey(name: 'name')@BilingualConverter()  Bilingual name, @JsonKey(name: 'short_name')  String shortName, @JsonKey(name: 'description')@BilingualConverter()  Bilingual description, @JsonKey(name: 'icon')  String icon, @JsonKey(name: 'color')  String color, @JsonKey(name: 'fee_lak')  int feeLak, @JsonKey(name: 'fee_max_lak')  int feeMaxLak, @JsonKey(name: 'fee_is_range')  bool feeIsRange, @JsonKey(name: 'sla_days')  int slaDays, @JsonKey(name: 'processing_time')@BilingualConverter()  Bilingual processingTime, @JsonKey(name: 'required_docs')@BilingualConverter()  List<Bilingual> requiredDocs, @JsonKey(name: 'requires_payment')  bool requiresPayment, @JsonKey(name: 'is_phase1')  bool isPhase1, @JsonKey(name: 'active')  bool active, @JsonKey(name: 'sort_order')  int sortOrder, @JsonKey(name: 'route_path')  String routePath, @JsonKey(name: 'family_book_effect')  String familyBookEffect)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ServiceModel() when $default != null:
return $default(_that.id,_that.code,_that.categoryId,_that.categoryCode,_that.name,_that.shortName,_that.description,_that.icon,_that.color,_that.feeLak,_that.feeMaxLak,_that.feeIsRange,_that.slaDays,_that.processingTime,_that.requiredDocs,_that.requiresPayment,_that.isPhase1,_that.active,_that.sortOrder,_that.routePath,_that.familyBookEffect);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'id')  String id, @JsonKey(name: 'code')  String code, @JsonKey(name: 'category_id')  String categoryId, @JsonKey(name: 'category_code')  String categoryCode, @JsonKey(name: 'name')@BilingualConverter()  Bilingual name, @JsonKey(name: 'short_name')  String shortName, @JsonKey(name: 'description')@BilingualConverter()  Bilingual description, @JsonKey(name: 'icon')  String icon, @JsonKey(name: 'color')  String color, @JsonKey(name: 'fee_lak')  int feeLak, @JsonKey(name: 'fee_max_lak')  int feeMaxLak, @JsonKey(name: 'fee_is_range')  bool feeIsRange, @JsonKey(name: 'sla_days')  int slaDays, @JsonKey(name: 'processing_time')@BilingualConverter()  Bilingual processingTime, @JsonKey(name: 'required_docs')@BilingualConverter()  List<Bilingual> requiredDocs, @JsonKey(name: 'requires_payment')  bool requiresPayment, @JsonKey(name: 'is_phase1')  bool isPhase1, @JsonKey(name: 'active')  bool active, @JsonKey(name: 'sort_order')  int sortOrder, @JsonKey(name: 'route_path')  String routePath, @JsonKey(name: 'family_book_effect')  String familyBookEffect)  $default,) {final _that = this;
switch (_that) {
case _ServiceModel():
return $default(_that.id,_that.code,_that.categoryId,_that.categoryCode,_that.name,_that.shortName,_that.description,_that.icon,_that.color,_that.feeLak,_that.feeMaxLak,_that.feeIsRange,_that.slaDays,_that.processingTime,_that.requiredDocs,_that.requiresPayment,_that.isPhase1,_that.active,_that.sortOrder,_that.routePath,_that.familyBookEffect);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'id')  String id, @JsonKey(name: 'code')  String code, @JsonKey(name: 'category_id')  String categoryId, @JsonKey(name: 'category_code')  String categoryCode, @JsonKey(name: 'name')@BilingualConverter()  Bilingual name, @JsonKey(name: 'short_name')  String shortName, @JsonKey(name: 'description')@BilingualConverter()  Bilingual description, @JsonKey(name: 'icon')  String icon, @JsonKey(name: 'color')  String color, @JsonKey(name: 'fee_lak')  int feeLak, @JsonKey(name: 'fee_max_lak')  int feeMaxLak, @JsonKey(name: 'fee_is_range')  bool feeIsRange, @JsonKey(name: 'sla_days')  int slaDays, @JsonKey(name: 'processing_time')@BilingualConverter()  Bilingual processingTime, @JsonKey(name: 'required_docs')@BilingualConverter()  List<Bilingual> requiredDocs, @JsonKey(name: 'requires_payment')  bool requiresPayment, @JsonKey(name: 'is_phase1')  bool isPhase1, @JsonKey(name: 'active')  bool active, @JsonKey(name: 'sort_order')  int sortOrder, @JsonKey(name: 'route_path')  String routePath, @JsonKey(name: 'family_book_effect')  String familyBookEffect)?  $default,) {final _that = this;
switch (_that) {
case _ServiceModel() when $default != null:
return $default(_that.id,_that.code,_that.categoryId,_that.categoryCode,_that.name,_that.shortName,_that.description,_that.icon,_that.color,_that.feeLak,_that.feeMaxLak,_that.feeIsRange,_that.slaDays,_that.processingTime,_that.requiredDocs,_that.requiresPayment,_that.isPhase1,_that.active,_that.sortOrder,_that.routePath,_that.familyBookEffect);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ServiceModel implements ServiceModel {
  const _ServiceModel({@JsonKey(name: 'id') required this.id, @JsonKey(name: 'code') required this.code, @JsonKey(name: 'category_id') this.categoryId = '', @JsonKey(name: 'category_code') this.categoryCode = '', @JsonKey(name: 'name')@BilingualConverter() required this.name, @JsonKey(name: 'short_name') this.shortName = '', @JsonKey(name: 'description')@BilingualConverter() required this.description, @JsonKey(name: 'icon') this.icon = '', @JsonKey(name: 'color') this.color = '', @JsonKey(name: 'fee_lak') this.feeLak = 0, @JsonKey(name: 'fee_max_lak') this.feeMaxLak = 0, @JsonKey(name: 'fee_is_range') this.feeIsRange = false, @JsonKey(name: 'sla_days') this.slaDays = 0, @JsonKey(name: 'processing_time')@BilingualConverter() this.processingTime = const Bilingual(en: '', lo: ''), @JsonKey(name: 'required_docs')@BilingualConverter() final  List<Bilingual> requiredDocs = const <Bilingual>[], @JsonKey(name: 'requires_payment') this.requiresPayment = false, @JsonKey(name: 'is_phase1') this.isPhase1 = false, @JsonKey(name: 'active') this.active = true, @JsonKey(name: 'sort_order') this.sortOrder = 0, @JsonKey(name: 'route_path') this.routePath = '', @JsonKey(name: 'family_book_effect') this.familyBookEffect = ''}): _requiredDocs = requiredDocs;
  factory _ServiceModel.fromJson(Map<String, dynamic> json) => _$ServiceModelFromJson(json);

@override@JsonKey(name: 'id') final  String id;
@override@JsonKey(name: 'code') final  String code;
@override@JsonKey(name: 'category_id') final  String categoryId;
@override@JsonKey(name: 'category_code') final  String categoryCode;
@override@JsonKey(name: 'name')@BilingualConverter() final  Bilingual name;
@override@JsonKey(name: 'short_name') final  String shortName;
@override@JsonKey(name: 'description')@BilingualConverter() final  Bilingual description;
@override@JsonKey(name: 'icon') final  String icon;
@override@JsonKey(name: 'color') final  String color;
@override@JsonKey(name: 'fee_lak') final  int feeLak;
@override@JsonKey(name: 'fee_max_lak') final  int feeMaxLak;
@override@JsonKey(name: 'fee_is_range') final  bool feeIsRange;
@override@JsonKey(name: 'sla_days') final  int slaDays;
@override@JsonKey(name: 'processing_time')@BilingualConverter() final  Bilingual processingTime;
 final  List<Bilingual> _requiredDocs;
@override@JsonKey(name: 'required_docs')@BilingualConverter() List<Bilingual> get requiredDocs {
  if (_requiredDocs is EqualUnmodifiableListView) return _requiredDocs;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_requiredDocs);
}

@override@JsonKey(name: 'requires_payment') final  bool requiresPayment;
@override@JsonKey(name: 'is_phase1') final  bool isPhase1;
@override@JsonKey(name: 'active') final  bool active;
@override@JsonKey(name: 'sort_order') final  int sortOrder;
@override@JsonKey(name: 'route_path') final  String routePath;
@override@JsonKey(name: 'family_book_effect') final  String familyBookEffect;

/// Create a copy of ServiceModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ServiceModelCopyWith<_ServiceModel> get copyWith => __$ServiceModelCopyWithImpl<_ServiceModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ServiceModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ServiceModel&&(identical(other.id, id) || other.id == id)&&(identical(other.code, code) || other.code == code)&&(identical(other.categoryId, categoryId) || other.categoryId == categoryId)&&(identical(other.categoryCode, categoryCode) || other.categoryCode == categoryCode)&&(identical(other.name, name) || other.name == name)&&(identical(other.shortName, shortName) || other.shortName == shortName)&&(identical(other.description, description) || other.description == description)&&(identical(other.icon, icon) || other.icon == icon)&&(identical(other.color, color) || other.color == color)&&(identical(other.feeLak, feeLak) || other.feeLak == feeLak)&&(identical(other.feeMaxLak, feeMaxLak) || other.feeMaxLak == feeMaxLak)&&(identical(other.feeIsRange, feeIsRange) || other.feeIsRange == feeIsRange)&&(identical(other.slaDays, slaDays) || other.slaDays == slaDays)&&(identical(other.processingTime, processingTime) || other.processingTime == processingTime)&&const DeepCollectionEquality().equals(other._requiredDocs, _requiredDocs)&&(identical(other.requiresPayment, requiresPayment) || other.requiresPayment == requiresPayment)&&(identical(other.isPhase1, isPhase1) || other.isPhase1 == isPhase1)&&(identical(other.active, active) || other.active == active)&&(identical(other.sortOrder, sortOrder) || other.sortOrder == sortOrder)&&(identical(other.routePath, routePath) || other.routePath == routePath)&&(identical(other.familyBookEffect, familyBookEffect) || other.familyBookEffect == familyBookEffect));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,id,code,categoryId,categoryCode,name,shortName,description,icon,color,feeLak,feeMaxLak,feeIsRange,slaDays,processingTime,const DeepCollectionEquality().hash(_requiredDocs),requiresPayment,isPhase1,active,sortOrder,routePath,familyBookEffect]);

@override
String toString() {
  return 'ServiceModel(id: $id, code: $code, categoryId: $categoryId, categoryCode: $categoryCode, name: $name, shortName: $shortName, description: $description, icon: $icon, color: $color, feeLak: $feeLak, feeMaxLak: $feeMaxLak, feeIsRange: $feeIsRange, slaDays: $slaDays, processingTime: $processingTime, requiredDocs: $requiredDocs, requiresPayment: $requiresPayment, isPhase1: $isPhase1, active: $active, sortOrder: $sortOrder, routePath: $routePath, familyBookEffect: $familyBookEffect)';
}


}

/// @nodoc
abstract mixin class _$ServiceModelCopyWith<$Res> implements $ServiceModelCopyWith<$Res> {
  factory _$ServiceModelCopyWith(_ServiceModel value, $Res Function(_ServiceModel) _then) = __$ServiceModelCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'id') String id,@JsonKey(name: 'code') String code,@JsonKey(name: 'category_id') String categoryId,@JsonKey(name: 'category_code') String categoryCode,@JsonKey(name: 'name')@BilingualConverter() Bilingual name,@JsonKey(name: 'short_name') String shortName,@JsonKey(name: 'description')@BilingualConverter() Bilingual description,@JsonKey(name: 'icon') String icon,@JsonKey(name: 'color') String color,@JsonKey(name: 'fee_lak') int feeLak,@JsonKey(name: 'fee_max_lak') int feeMaxLak,@JsonKey(name: 'fee_is_range') bool feeIsRange,@JsonKey(name: 'sla_days') int slaDays,@JsonKey(name: 'processing_time')@BilingualConverter() Bilingual processingTime,@JsonKey(name: 'required_docs')@BilingualConverter() List<Bilingual> requiredDocs,@JsonKey(name: 'requires_payment') bool requiresPayment,@JsonKey(name: 'is_phase1') bool isPhase1,@JsonKey(name: 'active') bool active,@JsonKey(name: 'sort_order') int sortOrder,@JsonKey(name: 'route_path') String routePath,@JsonKey(name: 'family_book_effect') String familyBookEffect
});


@override $BilingualCopyWith<$Res> get name;@override $BilingualCopyWith<$Res> get description;@override $BilingualCopyWith<$Res> get processingTime;

}
/// @nodoc
class __$ServiceModelCopyWithImpl<$Res>
    implements _$ServiceModelCopyWith<$Res> {
  __$ServiceModelCopyWithImpl(this._self, this._then);

  final _ServiceModel _self;
  final $Res Function(_ServiceModel) _then;

/// Create a copy of ServiceModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? code = null,Object? categoryId = null,Object? categoryCode = null,Object? name = null,Object? shortName = null,Object? description = null,Object? icon = null,Object? color = null,Object? feeLak = null,Object? feeMaxLak = null,Object? feeIsRange = null,Object? slaDays = null,Object? processingTime = null,Object? requiredDocs = null,Object? requiresPayment = null,Object? isPhase1 = null,Object? active = null,Object? sortOrder = null,Object? routePath = null,Object? familyBookEffect = null,}) {
  return _then(_ServiceModel(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,code: null == code ? _self.code : code // ignore: cast_nullable_to_non_nullable
as String,categoryId: null == categoryId ? _self.categoryId : categoryId // ignore: cast_nullable_to_non_nullable
as String,categoryCode: null == categoryCode ? _self.categoryCode : categoryCode // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as Bilingual,shortName: null == shortName ? _self.shortName : shortName // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as Bilingual,icon: null == icon ? _self.icon : icon // ignore: cast_nullable_to_non_nullable
as String,color: null == color ? _self.color : color // ignore: cast_nullable_to_non_nullable
as String,feeLak: null == feeLak ? _self.feeLak : feeLak // ignore: cast_nullable_to_non_nullable
as int,feeMaxLak: null == feeMaxLak ? _self.feeMaxLak : feeMaxLak // ignore: cast_nullable_to_non_nullable
as int,feeIsRange: null == feeIsRange ? _self.feeIsRange : feeIsRange // ignore: cast_nullable_to_non_nullable
as bool,slaDays: null == slaDays ? _self.slaDays : slaDays // ignore: cast_nullable_to_non_nullable
as int,processingTime: null == processingTime ? _self.processingTime : processingTime // ignore: cast_nullable_to_non_nullable
as Bilingual,requiredDocs: null == requiredDocs ? _self._requiredDocs : requiredDocs // ignore: cast_nullable_to_non_nullable
as List<Bilingual>,requiresPayment: null == requiresPayment ? _self.requiresPayment : requiresPayment // ignore: cast_nullable_to_non_nullable
as bool,isPhase1: null == isPhase1 ? _self.isPhase1 : isPhase1 // ignore: cast_nullable_to_non_nullable
as bool,active: null == active ? _self.active : active // ignore: cast_nullable_to_non_nullable
as bool,sortOrder: null == sortOrder ? _self.sortOrder : sortOrder // ignore: cast_nullable_to_non_nullable
as int,routePath: null == routePath ? _self.routePath : routePath // ignore: cast_nullable_to_non_nullable
as String,familyBookEffect: null == familyBookEffect ? _self.familyBookEffect : familyBookEffect // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

/// Create a copy of ServiceModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BilingualCopyWith<$Res> get name {
  
  return $BilingualCopyWith<$Res>(_self.name, (value) {
    return _then(_self.copyWith(name: value));
  });
}/// Create a copy of ServiceModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BilingualCopyWith<$Res> get description {
  
  return $BilingualCopyWith<$Res>(_self.description, (value) {
    return _then(_self.copyWith(description: value));
  });
}/// Create a copy of ServiceModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BilingualCopyWith<$Res> get processingTime {
  
  return $BilingualCopyWith<$Res>(_self.processingTime, (value) {
    return _then(_self.copyWith(processingTime: value));
  });
}
}

// dart format on
