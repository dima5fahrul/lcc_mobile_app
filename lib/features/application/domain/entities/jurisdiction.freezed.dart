// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'jurisdiction.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$Jurisdiction {

 String? get provinceId; String? get provinceName; String? get districtId; String? get districtName; String? get villageId; String? get villageName;
/// Create a copy of Jurisdiction
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$JurisdictionCopyWith<Jurisdiction> get copyWith => _$JurisdictionCopyWithImpl<Jurisdiction>(this as Jurisdiction, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Jurisdiction&&(identical(other.provinceId, provinceId) || other.provinceId == provinceId)&&(identical(other.provinceName, provinceName) || other.provinceName == provinceName)&&(identical(other.districtId, districtId) || other.districtId == districtId)&&(identical(other.districtName, districtName) || other.districtName == districtName)&&(identical(other.villageId, villageId) || other.villageId == villageId)&&(identical(other.villageName, villageName) || other.villageName == villageName));
}


@override
int get hashCode => Object.hash(runtimeType,provinceId,provinceName,districtId,districtName,villageId,villageName);

@override
String toString() {
  return 'Jurisdiction(provinceId: $provinceId, provinceName: $provinceName, districtId: $districtId, districtName: $districtName, villageId: $villageId, villageName: $villageName)';
}


}

/// @nodoc
abstract mixin class $JurisdictionCopyWith<$Res>  {
  factory $JurisdictionCopyWith(Jurisdiction value, $Res Function(Jurisdiction) _then) = _$JurisdictionCopyWithImpl;
@useResult
$Res call({
 String? provinceId, String? provinceName, String? districtId, String? districtName, String? villageId, String? villageName
});




}
/// @nodoc
class _$JurisdictionCopyWithImpl<$Res>
    implements $JurisdictionCopyWith<$Res> {
  _$JurisdictionCopyWithImpl(this._self, this._then);

  final Jurisdiction _self;
  final $Res Function(Jurisdiction) _then;

/// Create a copy of Jurisdiction
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? provinceId = freezed,Object? provinceName = freezed,Object? districtId = freezed,Object? districtName = freezed,Object? villageId = freezed,Object? villageName = freezed,}) {
  return _then(_self.copyWith(
provinceId: freezed == provinceId ? _self.provinceId : provinceId // ignore: cast_nullable_to_non_nullable
as String?,provinceName: freezed == provinceName ? _self.provinceName : provinceName // ignore: cast_nullable_to_non_nullable
as String?,districtId: freezed == districtId ? _self.districtId : districtId // ignore: cast_nullable_to_non_nullable
as String?,districtName: freezed == districtName ? _self.districtName : districtName // ignore: cast_nullable_to_non_nullable
as String?,villageId: freezed == villageId ? _self.villageId : villageId // ignore: cast_nullable_to_non_nullable
as String?,villageName: freezed == villageName ? _self.villageName : villageName // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [Jurisdiction].
extension JurisdictionPatterns on Jurisdiction {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Jurisdiction value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Jurisdiction() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Jurisdiction value)  $default,){
final _that = this;
switch (_that) {
case _Jurisdiction():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Jurisdiction value)?  $default,){
final _that = this;
switch (_that) {
case _Jurisdiction() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String? provinceId,  String? provinceName,  String? districtId,  String? districtName,  String? villageId,  String? villageName)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Jurisdiction() when $default != null:
return $default(_that.provinceId,_that.provinceName,_that.districtId,_that.districtName,_that.villageId,_that.villageName);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String? provinceId,  String? provinceName,  String? districtId,  String? districtName,  String? villageId,  String? villageName)  $default,) {final _that = this;
switch (_that) {
case _Jurisdiction():
return $default(_that.provinceId,_that.provinceName,_that.districtId,_that.districtName,_that.villageId,_that.villageName);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String? provinceId,  String? provinceName,  String? districtId,  String? districtName,  String? villageId,  String? villageName)?  $default,) {final _that = this;
switch (_that) {
case _Jurisdiction() when $default != null:
return $default(_that.provinceId,_that.provinceName,_that.districtId,_that.districtName,_that.villageId,_that.villageName);case _:
  return null;

}
}

}

/// @nodoc


class _Jurisdiction extends Jurisdiction {
  const _Jurisdiction({this.provinceId, this.provinceName, this.districtId, this.districtName, this.villageId, this.villageName}): super._();
  

@override final  String? provinceId;
@override final  String? provinceName;
@override final  String? districtId;
@override final  String? districtName;
@override final  String? villageId;
@override final  String? villageName;

/// Create a copy of Jurisdiction
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$JurisdictionCopyWith<_Jurisdiction> get copyWith => __$JurisdictionCopyWithImpl<_Jurisdiction>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Jurisdiction&&(identical(other.provinceId, provinceId) || other.provinceId == provinceId)&&(identical(other.provinceName, provinceName) || other.provinceName == provinceName)&&(identical(other.districtId, districtId) || other.districtId == districtId)&&(identical(other.districtName, districtName) || other.districtName == districtName)&&(identical(other.villageId, villageId) || other.villageId == villageId)&&(identical(other.villageName, villageName) || other.villageName == villageName));
}


@override
int get hashCode => Object.hash(runtimeType,provinceId,provinceName,districtId,districtName,villageId,villageName);

@override
String toString() {
  return 'Jurisdiction(provinceId: $provinceId, provinceName: $provinceName, districtId: $districtId, districtName: $districtName, villageId: $villageId, villageName: $villageName)';
}


}

/// @nodoc
abstract mixin class _$JurisdictionCopyWith<$Res> implements $JurisdictionCopyWith<$Res> {
  factory _$JurisdictionCopyWith(_Jurisdiction value, $Res Function(_Jurisdiction) _then) = __$JurisdictionCopyWithImpl;
@override @useResult
$Res call({
 String? provinceId, String? provinceName, String? districtId, String? districtName, String? villageId, String? villageName
});




}
/// @nodoc
class __$JurisdictionCopyWithImpl<$Res>
    implements _$JurisdictionCopyWith<$Res> {
  __$JurisdictionCopyWithImpl(this._self, this._then);

  final _Jurisdiction _self;
  final $Res Function(_Jurisdiction) _then;

/// Create a copy of Jurisdiction
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? provinceId = freezed,Object? provinceName = freezed,Object? districtId = freezed,Object? districtName = freezed,Object? villageId = freezed,Object? villageName = freezed,}) {
  return _then(_Jurisdiction(
provinceId: freezed == provinceId ? _self.provinceId : provinceId // ignore: cast_nullable_to_non_nullable
as String?,provinceName: freezed == provinceName ? _self.provinceName : provinceName // ignore: cast_nullable_to_non_nullable
as String?,districtId: freezed == districtId ? _self.districtId : districtId // ignore: cast_nullable_to_non_nullable
as String?,districtName: freezed == districtName ? _self.districtName : districtName // ignore: cast_nullable_to_non_nullable
as String?,villageId: freezed == villageId ? _self.villageId : villageId // ignore: cast_nullable_to_non_nullable
as String?,villageName: freezed == villageName ? _self.villageName : villageName // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
