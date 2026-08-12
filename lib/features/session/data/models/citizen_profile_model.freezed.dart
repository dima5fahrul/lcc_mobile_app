// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'citizen_profile_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$CitizenProfileModel {

 CitizenAccountModel get account; PlaceNamesModel? get place;@JsonKey(name: 'household_no') String? get householdNo;// P0 stub: typed port lands with the registry feature (batch berikut).
 Map<String, dynamic>? get registry; Map<String, dynamic>? get household;
/// Create a copy of CitizenProfileModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CitizenProfileModelCopyWith<CitizenProfileModel> get copyWith => _$CitizenProfileModelCopyWithImpl<CitizenProfileModel>(this as CitizenProfileModel, _$identity);

  /// Serializes this CitizenProfileModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CitizenProfileModel&&(identical(other.account, account) || other.account == account)&&(identical(other.place, place) || other.place == place)&&(identical(other.householdNo, householdNo) || other.householdNo == householdNo)&&const DeepCollectionEquality().equals(other.registry, registry)&&const DeepCollectionEquality().equals(other.household, household));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,account,place,householdNo,const DeepCollectionEquality().hash(registry),const DeepCollectionEquality().hash(household));

@override
String toString() {
  return 'CitizenProfileModel(account: $account, place: $place, householdNo: $householdNo, registry: $registry, household: $household)';
}


}

/// @nodoc
abstract mixin class $CitizenProfileModelCopyWith<$Res>  {
  factory $CitizenProfileModelCopyWith(CitizenProfileModel value, $Res Function(CitizenProfileModel) _then) = _$CitizenProfileModelCopyWithImpl;
@useResult
$Res call({
 CitizenAccountModel account, PlaceNamesModel? place,@JsonKey(name: 'household_no') String? householdNo, Map<String, dynamic>? registry, Map<String, dynamic>? household
});


$CitizenAccountModelCopyWith<$Res> get account;$PlaceNamesModelCopyWith<$Res>? get place;

}
/// @nodoc
class _$CitizenProfileModelCopyWithImpl<$Res>
    implements $CitizenProfileModelCopyWith<$Res> {
  _$CitizenProfileModelCopyWithImpl(this._self, this._then);

  final CitizenProfileModel _self;
  final $Res Function(CitizenProfileModel) _then;

/// Create a copy of CitizenProfileModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? account = null,Object? place = freezed,Object? householdNo = freezed,Object? registry = freezed,Object? household = freezed,}) {
  return _then(_self.copyWith(
account: null == account ? _self.account : account // ignore: cast_nullable_to_non_nullable
as CitizenAccountModel,place: freezed == place ? _self.place : place // ignore: cast_nullable_to_non_nullable
as PlaceNamesModel?,householdNo: freezed == householdNo ? _self.householdNo : householdNo // ignore: cast_nullable_to_non_nullable
as String?,registry: freezed == registry ? _self.registry : registry // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>?,household: freezed == household ? _self.household : household // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>?,
  ));
}
/// Create a copy of CitizenProfileModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CitizenAccountModelCopyWith<$Res> get account {
  
  return $CitizenAccountModelCopyWith<$Res>(_self.account, (value) {
    return _then(_self.copyWith(account: value));
  });
}/// Create a copy of CitizenProfileModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PlaceNamesModelCopyWith<$Res>? get place {
    if (_self.place == null) {
    return null;
  }

  return $PlaceNamesModelCopyWith<$Res>(_self.place!, (value) {
    return _then(_self.copyWith(place: value));
  });
}
}


/// Adds pattern-matching-related methods to [CitizenProfileModel].
extension CitizenProfileModelPatterns on CitizenProfileModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CitizenProfileModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CitizenProfileModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CitizenProfileModel value)  $default,){
final _that = this;
switch (_that) {
case _CitizenProfileModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CitizenProfileModel value)?  $default,){
final _that = this;
switch (_that) {
case _CitizenProfileModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( CitizenAccountModel account,  PlaceNamesModel? place, @JsonKey(name: 'household_no')  String? householdNo,  Map<String, dynamic>? registry,  Map<String, dynamic>? household)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CitizenProfileModel() when $default != null:
return $default(_that.account,_that.place,_that.householdNo,_that.registry,_that.household);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( CitizenAccountModel account,  PlaceNamesModel? place, @JsonKey(name: 'household_no')  String? householdNo,  Map<String, dynamic>? registry,  Map<String, dynamic>? household)  $default,) {final _that = this;
switch (_that) {
case _CitizenProfileModel():
return $default(_that.account,_that.place,_that.householdNo,_that.registry,_that.household);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( CitizenAccountModel account,  PlaceNamesModel? place, @JsonKey(name: 'household_no')  String? householdNo,  Map<String, dynamic>? registry,  Map<String, dynamic>? household)?  $default,) {final _that = this;
switch (_that) {
case _CitizenProfileModel() when $default != null:
return $default(_that.account,_that.place,_that.householdNo,_that.registry,_that.household);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _CitizenProfileModel implements CitizenProfileModel {
  const _CitizenProfileModel({required this.account, this.place, @JsonKey(name: 'household_no') this.householdNo, final  Map<String, dynamic>? registry, final  Map<String, dynamic>? household}): _registry = registry,_household = household;
  factory _CitizenProfileModel.fromJson(Map<String, dynamic> json) => _$CitizenProfileModelFromJson(json);

@override final  CitizenAccountModel account;
@override final  PlaceNamesModel? place;
@override@JsonKey(name: 'household_no') final  String? householdNo;
// P0 stub: typed port lands with the registry feature (batch berikut).
 final  Map<String, dynamic>? _registry;
// P0 stub: typed port lands with the registry feature (batch berikut).
@override Map<String, dynamic>? get registry {
  final value = _registry;
  if (value == null) return null;
  if (_registry is EqualUnmodifiableMapView) return _registry;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(value);
}

 final  Map<String, dynamic>? _household;
@override Map<String, dynamic>? get household {
  final value = _household;
  if (value == null) return null;
  if (_household is EqualUnmodifiableMapView) return _household;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(value);
}


/// Create a copy of CitizenProfileModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CitizenProfileModelCopyWith<_CitizenProfileModel> get copyWith => __$CitizenProfileModelCopyWithImpl<_CitizenProfileModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CitizenProfileModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CitizenProfileModel&&(identical(other.account, account) || other.account == account)&&(identical(other.place, place) || other.place == place)&&(identical(other.householdNo, householdNo) || other.householdNo == householdNo)&&const DeepCollectionEquality().equals(other._registry, _registry)&&const DeepCollectionEquality().equals(other._household, _household));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,account,place,householdNo,const DeepCollectionEquality().hash(_registry),const DeepCollectionEquality().hash(_household));

@override
String toString() {
  return 'CitizenProfileModel(account: $account, place: $place, householdNo: $householdNo, registry: $registry, household: $household)';
}


}

/// @nodoc
abstract mixin class _$CitizenProfileModelCopyWith<$Res> implements $CitizenProfileModelCopyWith<$Res> {
  factory _$CitizenProfileModelCopyWith(_CitizenProfileModel value, $Res Function(_CitizenProfileModel) _then) = __$CitizenProfileModelCopyWithImpl;
@override @useResult
$Res call({
 CitizenAccountModel account, PlaceNamesModel? place,@JsonKey(name: 'household_no') String? householdNo, Map<String, dynamic>? registry, Map<String, dynamic>? household
});


@override $CitizenAccountModelCopyWith<$Res> get account;@override $PlaceNamesModelCopyWith<$Res>? get place;

}
/// @nodoc
class __$CitizenProfileModelCopyWithImpl<$Res>
    implements _$CitizenProfileModelCopyWith<$Res> {
  __$CitizenProfileModelCopyWithImpl(this._self, this._then);

  final _CitizenProfileModel _self;
  final $Res Function(_CitizenProfileModel) _then;

/// Create a copy of CitizenProfileModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? account = null,Object? place = freezed,Object? householdNo = freezed,Object? registry = freezed,Object? household = freezed,}) {
  return _then(_CitizenProfileModel(
account: null == account ? _self.account : account // ignore: cast_nullable_to_non_nullable
as CitizenAccountModel,place: freezed == place ? _self.place : place // ignore: cast_nullable_to_non_nullable
as PlaceNamesModel?,householdNo: freezed == householdNo ? _self.householdNo : householdNo // ignore: cast_nullable_to_non_nullable
as String?,registry: freezed == registry ? _self._registry : registry // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>?,household: freezed == household ? _self._household : household // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>?,
  ));
}

/// Create a copy of CitizenProfileModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CitizenAccountModelCopyWith<$Res> get account {
  
  return $CitizenAccountModelCopyWith<$Res>(_self.account, (value) {
    return _then(_self.copyWith(account: value));
  });
}/// Create a copy of CitizenProfileModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PlaceNamesModelCopyWith<$Res>? get place {
    if (_self.place == null) {
    return null;
  }

  return $PlaceNamesModelCopyWith<$Res>(_self.place!, (value) {
    return _then(_self.copyWith(place: value));
  });
}
}

// dart format on
