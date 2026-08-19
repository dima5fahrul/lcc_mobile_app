// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'jurisdiction_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$JurisdictionModel {

@JsonKey(name: 'province_id') String? get provinceId;@JsonKey(name: 'province_name') String? get provinceName;@JsonKey(name: 'district_id') String? get districtId;@JsonKey(name: 'district_name') String? get districtName;@JsonKey(name: 'village_id') String? get villageId;@JsonKey(name: 'village_name') String? get villageName;
/// Create a copy of JurisdictionModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$JurisdictionModelCopyWith<JurisdictionModel> get copyWith => _$JurisdictionModelCopyWithImpl<JurisdictionModel>(this as JurisdictionModel, _$identity);

  /// Serializes this JurisdictionModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is JurisdictionModel&&(identical(other.provinceId, provinceId) || other.provinceId == provinceId)&&(identical(other.provinceName, provinceName) || other.provinceName == provinceName)&&(identical(other.districtId, districtId) || other.districtId == districtId)&&(identical(other.districtName, districtName) || other.districtName == districtName)&&(identical(other.villageId, villageId) || other.villageId == villageId)&&(identical(other.villageName, villageName) || other.villageName == villageName));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,provinceId,provinceName,districtId,districtName,villageId,villageName);

@override
String toString() {
  return 'JurisdictionModel(provinceId: $provinceId, provinceName: $provinceName, districtId: $districtId, districtName: $districtName, villageId: $villageId, villageName: $villageName)';
}


}

/// @nodoc
abstract mixin class $JurisdictionModelCopyWith<$Res>  {
  factory $JurisdictionModelCopyWith(JurisdictionModel value, $Res Function(JurisdictionModel) _then) = _$JurisdictionModelCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'province_id') String? provinceId,@JsonKey(name: 'province_name') String? provinceName,@JsonKey(name: 'district_id') String? districtId,@JsonKey(name: 'district_name') String? districtName,@JsonKey(name: 'village_id') String? villageId,@JsonKey(name: 'village_name') String? villageName
});




}
/// @nodoc
class _$JurisdictionModelCopyWithImpl<$Res>
    implements $JurisdictionModelCopyWith<$Res> {
  _$JurisdictionModelCopyWithImpl(this._self, this._then);

  final JurisdictionModel _self;
  final $Res Function(JurisdictionModel) _then;

/// Create a copy of JurisdictionModel
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


/// Adds pattern-matching-related methods to [JurisdictionModel].
extension JurisdictionModelPatterns on JurisdictionModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _JurisdictionModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _JurisdictionModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _JurisdictionModel value)  $default,){
final _that = this;
switch (_that) {
case _JurisdictionModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _JurisdictionModel value)?  $default,){
final _that = this;
switch (_that) {
case _JurisdictionModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'province_id')  String? provinceId, @JsonKey(name: 'province_name')  String? provinceName, @JsonKey(name: 'district_id')  String? districtId, @JsonKey(name: 'district_name')  String? districtName, @JsonKey(name: 'village_id')  String? villageId, @JsonKey(name: 'village_name')  String? villageName)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _JurisdictionModel() when $default != null:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'province_id')  String? provinceId, @JsonKey(name: 'province_name')  String? provinceName, @JsonKey(name: 'district_id')  String? districtId, @JsonKey(name: 'district_name')  String? districtName, @JsonKey(name: 'village_id')  String? villageId, @JsonKey(name: 'village_name')  String? villageName)  $default,) {final _that = this;
switch (_that) {
case _JurisdictionModel():
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'province_id')  String? provinceId, @JsonKey(name: 'province_name')  String? provinceName, @JsonKey(name: 'district_id')  String? districtId, @JsonKey(name: 'district_name')  String? districtName, @JsonKey(name: 'village_id')  String? villageId, @JsonKey(name: 'village_name')  String? villageName)?  $default,) {final _that = this;
switch (_that) {
case _JurisdictionModel() when $default != null:
return $default(_that.provinceId,_that.provinceName,_that.districtId,_that.districtName,_that.villageId,_that.villageName);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _JurisdictionModel implements JurisdictionModel {
  const _JurisdictionModel({@JsonKey(name: 'province_id') this.provinceId, @JsonKey(name: 'province_name') this.provinceName, @JsonKey(name: 'district_id') this.districtId, @JsonKey(name: 'district_name') this.districtName, @JsonKey(name: 'village_id') this.villageId, @JsonKey(name: 'village_name') this.villageName});
  factory _JurisdictionModel.fromJson(Map<String, dynamic> json) => _$JurisdictionModelFromJson(json);

@override@JsonKey(name: 'province_id') final  String? provinceId;
@override@JsonKey(name: 'province_name') final  String? provinceName;
@override@JsonKey(name: 'district_id') final  String? districtId;
@override@JsonKey(name: 'district_name') final  String? districtName;
@override@JsonKey(name: 'village_id') final  String? villageId;
@override@JsonKey(name: 'village_name') final  String? villageName;

/// Create a copy of JurisdictionModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$JurisdictionModelCopyWith<_JurisdictionModel> get copyWith => __$JurisdictionModelCopyWithImpl<_JurisdictionModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$JurisdictionModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _JurisdictionModel&&(identical(other.provinceId, provinceId) || other.provinceId == provinceId)&&(identical(other.provinceName, provinceName) || other.provinceName == provinceName)&&(identical(other.districtId, districtId) || other.districtId == districtId)&&(identical(other.districtName, districtName) || other.districtName == districtName)&&(identical(other.villageId, villageId) || other.villageId == villageId)&&(identical(other.villageName, villageName) || other.villageName == villageName));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,provinceId,provinceName,districtId,districtName,villageId,villageName);

@override
String toString() {
  return 'JurisdictionModel(provinceId: $provinceId, provinceName: $provinceName, districtId: $districtId, districtName: $districtName, villageId: $villageId, villageName: $villageName)';
}


}

/// @nodoc
abstract mixin class _$JurisdictionModelCopyWith<$Res> implements $JurisdictionModelCopyWith<$Res> {
  factory _$JurisdictionModelCopyWith(_JurisdictionModel value, $Res Function(_JurisdictionModel) _then) = __$JurisdictionModelCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'province_id') String? provinceId,@JsonKey(name: 'province_name') String? provinceName,@JsonKey(name: 'district_id') String? districtId,@JsonKey(name: 'district_name') String? districtName,@JsonKey(name: 'village_id') String? villageId,@JsonKey(name: 'village_name') String? villageName
});




}
/// @nodoc
class __$JurisdictionModelCopyWithImpl<$Res>
    implements _$JurisdictionModelCopyWith<$Res> {
  __$JurisdictionModelCopyWithImpl(this._self, this._then);

  final _JurisdictionModel _self;
  final $Res Function(_JurisdictionModel) _then;

/// Create a copy of JurisdictionModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? provinceId = freezed,Object? provinceName = freezed,Object? districtId = freezed,Object? districtName = freezed,Object? villageId = freezed,Object? villageName = freezed,}) {
  return _then(_JurisdictionModel(
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
