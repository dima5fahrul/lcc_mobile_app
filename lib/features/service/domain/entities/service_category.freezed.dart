// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'service_category.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$ServiceCategory {

 String get id; String get code; Bilingual get name;/// A lucide component name (`Users`, `Plane`, …). Resolve it through
/// `AppIcons.service` before rendering — never through `AppIcons.help`,
/// and never straight into `LucideIcon` (specs.md § 6.3.5).
 String get icon;/// `#RRGGBB`, verbatim off the wire. See the note above.
 String get color; int get sortOrder; bool get active;
/// Create a copy of ServiceCategory
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ServiceCategoryCopyWith<ServiceCategory> get copyWith => _$ServiceCategoryCopyWithImpl<ServiceCategory>(this as ServiceCategory, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ServiceCategory&&(identical(other.id, id) || other.id == id)&&(identical(other.code, code) || other.code == code)&&(identical(other.name, name) || other.name == name)&&(identical(other.icon, icon) || other.icon == icon)&&(identical(other.color, color) || other.color == color)&&(identical(other.sortOrder, sortOrder) || other.sortOrder == sortOrder)&&(identical(other.active, active) || other.active == active));
}


@override
int get hashCode => Object.hash(runtimeType,id,code,name,icon,color,sortOrder,active);

@override
String toString() {
  return 'ServiceCategory(id: $id, code: $code, name: $name, icon: $icon, color: $color, sortOrder: $sortOrder, active: $active)';
}


}

/// @nodoc
abstract mixin class $ServiceCategoryCopyWith<$Res>  {
  factory $ServiceCategoryCopyWith(ServiceCategory value, $Res Function(ServiceCategory) _then) = _$ServiceCategoryCopyWithImpl;
@useResult
$Res call({
 String id, String code, Bilingual name, String icon, String color, int sortOrder, bool active
});


$BilingualCopyWith<$Res> get name;

}
/// @nodoc
class _$ServiceCategoryCopyWithImpl<$Res>
    implements $ServiceCategoryCopyWith<$Res> {
  _$ServiceCategoryCopyWithImpl(this._self, this._then);

  final ServiceCategory _self;
  final $Res Function(ServiceCategory) _then;

/// Create a copy of ServiceCategory
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
/// Create a copy of ServiceCategory
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BilingualCopyWith<$Res> get name {
  
  return $BilingualCopyWith<$Res>(_self.name, (value) {
    return _then(_self.copyWith(name: value));
  });
}
}


/// Adds pattern-matching-related methods to [ServiceCategory].
extension ServiceCategoryPatterns on ServiceCategory {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ServiceCategory value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ServiceCategory() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ServiceCategory value)  $default,){
final _that = this;
switch (_that) {
case _ServiceCategory():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ServiceCategory value)?  $default,){
final _that = this;
switch (_that) {
case _ServiceCategory() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String code,  Bilingual name,  String icon,  String color,  int sortOrder,  bool active)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ServiceCategory() when $default != null:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String code,  Bilingual name,  String icon,  String color,  int sortOrder,  bool active)  $default,) {final _that = this;
switch (_that) {
case _ServiceCategory():
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String code,  Bilingual name,  String icon,  String color,  int sortOrder,  bool active)?  $default,) {final _that = this;
switch (_that) {
case _ServiceCategory() when $default != null:
return $default(_that.id,_that.code,_that.name,_that.icon,_that.color,_that.sortOrder,_that.active);case _:
  return null;

}
}

}

/// @nodoc


class _ServiceCategory implements ServiceCategory {
  const _ServiceCategory({required this.id, required this.code, required this.name, required this.icon, required this.color, required this.sortOrder, required this.active});
  

@override final  String id;
@override final  String code;
@override final  Bilingual name;
/// A lucide component name (`Users`, `Plane`, …). Resolve it through
/// `AppIcons.service` before rendering — never through `AppIcons.help`,
/// and never straight into `LucideIcon` (specs.md § 6.3.5).
@override final  String icon;
/// `#RRGGBB`, verbatim off the wire. See the note above.
@override final  String color;
@override final  int sortOrder;
@override final  bool active;

/// Create a copy of ServiceCategory
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ServiceCategoryCopyWith<_ServiceCategory> get copyWith => __$ServiceCategoryCopyWithImpl<_ServiceCategory>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ServiceCategory&&(identical(other.id, id) || other.id == id)&&(identical(other.code, code) || other.code == code)&&(identical(other.name, name) || other.name == name)&&(identical(other.icon, icon) || other.icon == icon)&&(identical(other.color, color) || other.color == color)&&(identical(other.sortOrder, sortOrder) || other.sortOrder == sortOrder)&&(identical(other.active, active) || other.active == active));
}


@override
int get hashCode => Object.hash(runtimeType,id,code,name,icon,color,sortOrder,active);

@override
String toString() {
  return 'ServiceCategory(id: $id, code: $code, name: $name, icon: $icon, color: $color, sortOrder: $sortOrder, active: $active)';
}


}

/// @nodoc
abstract mixin class _$ServiceCategoryCopyWith<$Res> implements $ServiceCategoryCopyWith<$Res> {
  factory _$ServiceCategoryCopyWith(_ServiceCategory value, $Res Function(_ServiceCategory) _then) = __$ServiceCategoryCopyWithImpl;
@override @useResult
$Res call({
 String id, String code, Bilingual name, String icon, String color, int sortOrder, bool active
});


@override $BilingualCopyWith<$Res> get name;

}
/// @nodoc
class __$ServiceCategoryCopyWithImpl<$Res>
    implements _$ServiceCategoryCopyWith<$Res> {
  __$ServiceCategoryCopyWithImpl(this._self, this._then);

  final _ServiceCategory _self;
  final $Res Function(_ServiceCategory) _then;

/// Create a copy of ServiceCategory
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? code = null,Object? name = null,Object? icon = null,Object? color = null,Object? sortOrder = null,Object? active = null,}) {
  return _then(_ServiceCategory(
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

/// Create a copy of ServiceCategory
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
