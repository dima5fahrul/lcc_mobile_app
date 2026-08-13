// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'service_category_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ServiceCategoryModel {

@JsonKey(name: 'id') String get id;@JsonKey(name: 'code') String get code;@JsonKey(name: 'name')@BilingualConverter() Bilingual get name;@JsonKey(name: 'icon') String get icon;@JsonKey(name: 'color') String get color;@JsonKey(name: 'sort_order') int get sortOrder;@JsonKey(name: 'active') bool get active;
/// Create a copy of ServiceCategoryModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ServiceCategoryModelCopyWith<ServiceCategoryModel> get copyWith => _$ServiceCategoryModelCopyWithImpl<ServiceCategoryModel>(this as ServiceCategoryModel, _$identity);

  /// Serializes this ServiceCategoryModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ServiceCategoryModel&&(identical(other.id, id) || other.id == id)&&(identical(other.code, code) || other.code == code)&&(identical(other.name, name) || other.name == name)&&(identical(other.icon, icon) || other.icon == icon)&&(identical(other.color, color) || other.color == color)&&(identical(other.sortOrder, sortOrder) || other.sortOrder == sortOrder)&&(identical(other.active, active) || other.active == active));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,code,name,icon,color,sortOrder,active);

@override
String toString() {
  return 'ServiceCategoryModel(id: $id, code: $code, name: $name, icon: $icon, color: $color, sortOrder: $sortOrder, active: $active)';
}


}

/// @nodoc
abstract mixin class $ServiceCategoryModelCopyWith<$Res>  {
  factory $ServiceCategoryModelCopyWith(ServiceCategoryModel value, $Res Function(ServiceCategoryModel) _then) = _$ServiceCategoryModelCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'id') String id,@JsonKey(name: 'code') String code,@JsonKey(name: 'name')@BilingualConverter() Bilingual name,@JsonKey(name: 'icon') String icon,@JsonKey(name: 'color') String color,@JsonKey(name: 'sort_order') int sortOrder,@JsonKey(name: 'active') bool active
});


$BilingualCopyWith<$Res> get name;

}
/// @nodoc
class _$ServiceCategoryModelCopyWithImpl<$Res>
    implements $ServiceCategoryModelCopyWith<$Res> {
  _$ServiceCategoryModelCopyWithImpl(this._self, this._then);

  final ServiceCategoryModel _self;
  final $Res Function(ServiceCategoryModel) _then;

/// Create a copy of ServiceCategoryModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? code = null,Object? name = null,Object? icon = null,Object? color = null,Object? sortOrder = null,Object? active = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,code: null == code ? _self.code : code // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as Bilingual,icon: null == icon ? _self.icon : icon // ignore: cast_nullable_to_non_nullable
as String,color: null == color ? _self.color : color // ignore: cast_nullable_to_non_nullable
as String,sortOrder: null == sortOrder ? _self.sortOrder : sortOrder // ignore: cast_nullable_to_non_nullable
as int,active: null == active ? _self.active : active // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}
/// Create a copy of ServiceCategoryModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BilingualCopyWith<$Res> get name {
  
  return $BilingualCopyWith<$Res>(_self.name, (value) {
    return _then(_self.copyWith(name: value));
  });
}
}


/// Adds pattern-matching-related methods to [ServiceCategoryModel].
extension ServiceCategoryModelPatterns on ServiceCategoryModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ServiceCategoryModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ServiceCategoryModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ServiceCategoryModel value)  $default,){
final _that = this;
switch (_that) {
case _ServiceCategoryModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ServiceCategoryModel value)?  $default,){
final _that = this;
switch (_that) {
case _ServiceCategoryModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'id')  String id, @JsonKey(name: 'code')  String code, @JsonKey(name: 'name')@BilingualConverter()  Bilingual name, @JsonKey(name: 'icon')  String icon, @JsonKey(name: 'color')  String color, @JsonKey(name: 'sort_order')  int sortOrder, @JsonKey(name: 'active')  bool active)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ServiceCategoryModel() when $default != null:
return $default(_that.id,_that.code,_that.name,_that.icon,_that.color,_that.sortOrder,_that.active);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'id')  String id, @JsonKey(name: 'code')  String code, @JsonKey(name: 'name')@BilingualConverter()  Bilingual name, @JsonKey(name: 'icon')  String icon, @JsonKey(name: 'color')  String color, @JsonKey(name: 'sort_order')  int sortOrder, @JsonKey(name: 'active')  bool active)  $default,) {final _that = this;
switch (_that) {
case _ServiceCategoryModel():
return $default(_that.id,_that.code,_that.name,_that.icon,_that.color,_that.sortOrder,_that.active);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'id')  String id, @JsonKey(name: 'code')  String code, @JsonKey(name: 'name')@BilingualConverter()  Bilingual name, @JsonKey(name: 'icon')  String icon, @JsonKey(name: 'color')  String color, @JsonKey(name: 'sort_order')  int sortOrder, @JsonKey(name: 'active')  bool active)?  $default,) {final _that = this;
switch (_that) {
case _ServiceCategoryModel() when $default != null:
return $default(_that.id,_that.code,_that.name,_that.icon,_that.color,_that.sortOrder,_that.active);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ServiceCategoryModel implements ServiceCategoryModel {
  const _ServiceCategoryModel({@JsonKey(name: 'id') required this.id, @JsonKey(name: 'code') required this.code, @JsonKey(name: 'name')@BilingualConverter() required this.name, @JsonKey(name: 'icon') required this.icon, @JsonKey(name: 'color') required this.color, @JsonKey(name: 'sort_order') required this.sortOrder, @JsonKey(name: 'active') required this.active});
  factory _ServiceCategoryModel.fromJson(Map<String, dynamic> json) => _$ServiceCategoryModelFromJson(json);

@override@JsonKey(name: 'id') final  String id;
@override@JsonKey(name: 'code') final  String code;
@override@JsonKey(name: 'name')@BilingualConverter() final  Bilingual name;
@override@JsonKey(name: 'icon') final  String icon;
@override@JsonKey(name: 'color') final  String color;
@override@JsonKey(name: 'sort_order') final  int sortOrder;
@override@JsonKey(name: 'active') final  bool active;

/// Create a copy of ServiceCategoryModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ServiceCategoryModelCopyWith<_ServiceCategoryModel> get copyWith => __$ServiceCategoryModelCopyWithImpl<_ServiceCategoryModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ServiceCategoryModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ServiceCategoryModel&&(identical(other.id, id) || other.id == id)&&(identical(other.code, code) || other.code == code)&&(identical(other.name, name) || other.name == name)&&(identical(other.icon, icon) || other.icon == icon)&&(identical(other.color, color) || other.color == color)&&(identical(other.sortOrder, sortOrder) || other.sortOrder == sortOrder)&&(identical(other.active, active) || other.active == active));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,code,name,icon,color,sortOrder,active);

@override
String toString() {
  return 'ServiceCategoryModel(id: $id, code: $code, name: $name, icon: $icon, color: $color, sortOrder: $sortOrder, active: $active)';
}


}

/// @nodoc
abstract mixin class _$ServiceCategoryModelCopyWith<$Res> implements $ServiceCategoryModelCopyWith<$Res> {
  factory _$ServiceCategoryModelCopyWith(_ServiceCategoryModel value, $Res Function(_ServiceCategoryModel) _then) = __$ServiceCategoryModelCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'id') String id,@JsonKey(name: 'code') String code,@JsonKey(name: 'name')@BilingualConverter() Bilingual name,@JsonKey(name: 'icon') String icon,@JsonKey(name: 'color') String color,@JsonKey(name: 'sort_order') int sortOrder,@JsonKey(name: 'active') bool active
});


@override $BilingualCopyWith<$Res> get name;

}
/// @nodoc
class __$ServiceCategoryModelCopyWithImpl<$Res>
    implements _$ServiceCategoryModelCopyWith<$Res> {
  __$ServiceCategoryModelCopyWithImpl(this._self, this._then);

  final _ServiceCategoryModel _self;
  final $Res Function(_ServiceCategoryModel) _then;

/// Create a copy of ServiceCategoryModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? code = null,Object? name = null,Object? icon = null,Object? color = null,Object? sortOrder = null,Object? active = null,}) {
  return _then(_ServiceCategoryModel(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,code: null == code ? _self.code : code // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as Bilingual,icon: null == icon ? _self.icon : icon // ignore: cast_nullable_to_non_nullable
as String,color: null == color ? _self.color : color // ignore: cast_nullable_to_non_nullable
as String,sortOrder: null == sortOrder ? _self.sortOrder : sortOrder // ignore: cast_nullable_to_non_nullable
as int,active: null == active ? _self.active : active // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

/// Create a copy of ServiceCategoryModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BilingualCopyWith<$Res> get name {
  
  return $BilingualCopyWith<$Res>(_self.name, (value) {
    return _then(_self.copyWith(name: value));
  });
}
}

// dart format on
