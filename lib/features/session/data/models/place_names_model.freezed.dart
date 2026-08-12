// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'place_names_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$PlaceNamesModel {

 BilingualModel? get province; BilingualModel? get district; BilingualModel? get village;
/// Create a copy of PlaceNamesModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PlaceNamesModelCopyWith<PlaceNamesModel> get copyWith => _$PlaceNamesModelCopyWithImpl<PlaceNamesModel>(this as PlaceNamesModel, _$identity);

  /// Serializes this PlaceNamesModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PlaceNamesModel&&(identical(other.province, province) || other.province == province)&&(identical(other.district, district) || other.district == district)&&(identical(other.village, village) || other.village == village));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,province,district,village);

@override
String toString() {
  return 'PlaceNamesModel(province: $province, district: $district, village: $village)';
}


}

/// @nodoc
abstract mixin class $PlaceNamesModelCopyWith<$Res>  {
  factory $PlaceNamesModelCopyWith(PlaceNamesModel value, $Res Function(PlaceNamesModel) _then) = _$PlaceNamesModelCopyWithImpl;
@useResult
$Res call({
 BilingualModel? province, BilingualModel? district, BilingualModel? village
});


$BilingualModelCopyWith<$Res>? get province;$BilingualModelCopyWith<$Res>? get district;$BilingualModelCopyWith<$Res>? get village;

}
/// @nodoc
class _$PlaceNamesModelCopyWithImpl<$Res>
    implements $PlaceNamesModelCopyWith<$Res> {
  _$PlaceNamesModelCopyWithImpl(this._self, this._then);

  final PlaceNamesModel _self;
  final $Res Function(PlaceNamesModel) _then;

/// Create a copy of PlaceNamesModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? province = freezed,Object? district = freezed,Object? village = freezed,}) {
  return _then(_self.copyWith(
province: freezed == province ? _self.province : province // ignore: cast_nullable_to_non_nullable
as BilingualModel?,district: freezed == district ? _self.district : district // ignore: cast_nullable_to_non_nullable
as BilingualModel?,village: freezed == village ? _self.village : village // ignore: cast_nullable_to_non_nullable
as BilingualModel?,
  ));
}
/// Create a copy of PlaceNamesModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BilingualModelCopyWith<$Res>? get province {
    if (_self.province == null) {
    return null;
  }

  return $BilingualModelCopyWith<$Res>(_self.province!, (value) {
    return _then(_self.copyWith(province: value));
  });
}/// Create a copy of PlaceNamesModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BilingualModelCopyWith<$Res>? get district {
    if (_self.district == null) {
    return null;
  }

  return $BilingualModelCopyWith<$Res>(_self.district!, (value) {
    return _then(_self.copyWith(district: value));
  });
}/// Create a copy of PlaceNamesModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BilingualModelCopyWith<$Res>? get village {
    if (_self.village == null) {
    return null;
  }

  return $BilingualModelCopyWith<$Res>(_self.village!, (value) {
    return _then(_self.copyWith(village: value));
  });
}
}


/// Adds pattern-matching-related methods to [PlaceNamesModel].
extension PlaceNamesModelPatterns on PlaceNamesModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PlaceNamesModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PlaceNamesModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PlaceNamesModel value)  $default,){
final _that = this;
switch (_that) {
case _PlaceNamesModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PlaceNamesModel value)?  $default,){
final _that = this;
switch (_that) {
case _PlaceNamesModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( BilingualModel? province,  BilingualModel? district,  BilingualModel? village)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PlaceNamesModel() when $default != null:
return $default(_that.province,_that.district,_that.village);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( BilingualModel? province,  BilingualModel? district,  BilingualModel? village)  $default,) {final _that = this;
switch (_that) {
case _PlaceNamesModel():
return $default(_that.province,_that.district,_that.village);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( BilingualModel? province,  BilingualModel? district,  BilingualModel? village)?  $default,) {final _that = this;
switch (_that) {
case _PlaceNamesModel() when $default != null:
return $default(_that.province,_that.district,_that.village);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PlaceNamesModel implements PlaceNamesModel {
  const _PlaceNamesModel({this.province, this.district, this.village});
  factory _PlaceNamesModel.fromJson(Map<String, dynamic> json) => _$PlaceNamesModelFromJson(json);

@override final  BilingualModel? province;
@override final  BilingualModel? district;
@override final  BilingualModel? village;

/// Create a copy of PlaceNamesModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PlaceNamesModelCopyWith<_PlaceNamesModel> get copyWith => __$PlaceNamesModelCopyWithImpl<_PlaceNamesModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PlaceNamesModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PlaceNamesModel&&(identical(other.province, province) || other.province == province)&&(identical(other.district, district) || other.district == district)&&(identical(other.village, village) || other.village == village));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,province,district,village);

@override
String toString() {
  return 'PlaceNamesModel(province: $province, district: $district, village: $village)';
}


}

/// @nodoc
abstract mixin class _$PlaceNamesModelCopyWith<$Res> implements $PlaceNamesModelCopyWith<$Res> {
  factory _$PlaceNamesModelCopyWith(_PlaceNamesModel value, $Res Function(_PlaceNamesModel) _then) = __$PlaceNamesModelCopyWithImpl;
@override @useResult
$Res call({
 BilingualModel? province, BilingualModel? district, BilingualModel? village
});


@override $BilingualModelCopyWith<$Res>? get province;@override $BilingualModelCopyWith<$Res>? get district;@override $BilingualModelCopyWith<$Res>? get village;

}
/// @nodoc
class __$PlaceNamesModelCopyWithImpl<$Res>
    implements _$PlaceNamesModelCopyWith<$Res> {
  __$PlaceNamesModelCopyWithImpl(this._self, this._then);

  final _PlaceNamesModel _self;
  final $Res Function(_PlaceNamesModel) _then;

/// Create a copy of PlaceNamesModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? province = freezed,Object? district = freezed,Object? village = freezed,}) {
  return _then(_PlaceNamesModel(
province: freezed == province ? _self.province : province // ignore: cast_nullable_to_non_nullable
as BilingualModel?,district: freezed == district ? _self.district : district // ignore: cast_nullable_to_non_nullable
as BilingualModel?,village: freezed == village ? _self.village : village // ignore: cast_nullable_to_non_nullable
as BilingualModel?,
  ));
}

/// Create a copy of PlaceNamesModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BilingualModelCopyWith<$Res>? get province {
    if (_self.province == null) {
    return null;
  }

  return $BilingualModelCopyWith<$Res>(_self.province!, (value) {
    return _then(_self.copyWith(province: value));
  });
}/// Create a copy of PlaceNamesModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BilingualModelCopyWith<$Res>? get district {
    if (_self.district == null) {
    return null;
  }

  return $BilingualModelCopyWith<$Res>(_self.district!, (value) {
    return _then(_self.copyWith(district: value));
  });
}/// Create a copy of PlaceNamesModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BilingualModelCopyWith<$Res>? get village {
    if (_self.village == null) {
    return null;
  }

  return $BilingualModelCopyWith<$Res>(_self.village!, (value) {
    return _then(_self.copyWith(village: value));
  });
}
}

// dart format on
