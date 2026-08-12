// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'place_names.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$PlaceNames {

 Bilingual? get province; Bilingual? get district; Bilingual? get village;
/// Create a copy of PlaceNames
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PlaceNamesCopyWith<PlaceNames> get copyWith => _$PlaceNamesCopyWithImpl<PlaceNames>(this as PlaceNames, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PlaceNames&&(identical(other.province, province) || other.province == province)&&(identical(other.district, district) || other.district == district)&&(identical(other.village, village) || other.village == village));
}


@override
int get hashCode => Object.hash(runtimeType,province,district,village);

@override
String toString() {
  return 'PlaceNames(province: $province, district: $district, village: $village)';
}


}

/// @nodoc
abstract mixin class $PlaceNamesCopyWith<$Res>  {
  factory $PlaceNamesCopyWith(PlaceNames value, $Res Function(PlaceNames) _then) = _$PlaceNamesCopyWithImpl;
@useResult
$Res call({
 Bilingual? province, Bilingual? district, Bilingual? village
});


$BilingualCopyWith<$Res>? get province;$BilingualCopyWith<$Res>? get district;$BilingualCopyWith<$Res>? get village;

}
/// @nodoc
class _$PlaceNamesCopyWithImpl<$Res>
    implements $PlaceNamesCopyWith<$Res> {
  _$PlaceNamesCopyWithImpl(this._self, this._then);

  final PlaceNames _self;
  final $Res Function(PlaceNames) _then;

/// Create a copy of PlaceNames
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? province = freezed,Object? district = freezed,Object? village = freezed,}) {
  return _then(_self.copyWith(
province: freezed == province ? _self.province : province // ignore: cast_nullable_to_non_nullable
as Bilingual?,district: freezed == district ? _self.district : district // ignore: cast_nullable_to_non_nullable
as Bilingual?,village: freezed == village ? _self.village : village // ignore: cast_nullable_to_non_nullable
as Bilingual?,
  ));
}
/// Create a copy of PlaceNames
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BilingualCopyWith<$Res>? get province {
    if (_self.province == null) {
    return null;
  }

  return $BilingualCopyWith<$Res>(_self.province!, (value) {
    return _then(_self.copyWith(province: value));
  });
}/// Create a copy of PlaceNames
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BilingualCopyWith<$Res>? get district {
    if (_self.district == null) {
    return null;
  }

  return $BilingualCopyWith<$Res>(_self.district!, (value) {
    return _then(_self.copyWith(district: value));
  });
}/// Create a copy of PlaceNames
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BilingualCopyWith<$Res>? get village {
    if (_self.village == null) {
    return null;
  }

  return $BilingualCopyWith<$Res>(_self.village!, (value) {
    return _then(_self.copyWith(village: value));
  });
}
}


/// Adds pattern-matching-related methods to [PlaceNames].
extension PlaceNamesPatterns on PlaceNames {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PlaceNames value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PlaceNames() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PlaceNames value)  $default,){
final _that = this;
switch (_that) {
case _PlaceNames():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PlaceNames value)?  $default,){
final _that = this;
switch (_that) {
case _PlaceNames() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( Bilingual? province,  Bilingual? district,  Bilingual? village)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PlaceNames() when $default != null:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( Bilingual? province,  Bilingual? district,  Bilingual? village)  $default,) {final _that = this;
switch (_that) {
case _PlaceNames():
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( Bilingual? province,  Bilingual? district,  Bilingual? village)?  $default,) {final _that = this;
switch (_that) {
case _PlaceNames() when $default != null:
return $default(_that.province,_that.district,_that.village);case _:
  return null;

}
}

}

/// @nodoc


class _PlaceNames implements PlaceNames {
  const _PlaceNames({this.province, this.district, this.village});
  

@override final  Bilingual? province;
@override final  Bilingual? district;
@override final  Bilingual? village;

/// Create a copy of PlaceNames
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PlaceNamesCopyWith<_PlaceNames> get copyWith => __$PlaceNamesCopyWithImpl<_PlaceNames>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PlaceNames&&(identical(other.province, province) || other.province == province)&&(identical(other.district, district) || other.district == district)&&(identical(other.village, village) || other.village == village));
}


@override
int get hashCode => Object.hash(runtimeType,province,district,village);

@override
String toString() {
  return 'PlaceNames(province: $province, district: $district, village: $village)';
}


}

/// @nodoc
abstract mixin class _$PlaceNamesCopyWith<$Res> implements $PlaceNamesCopyWith<$Res> {
  factory _$PlaceNamesCopyWith(_PlaceNames value, $Res Function(_PlaceNames) _then) = __$PlaceNamesCopyWithImpl;
@override @useResult
$Res call({
 Bilingual? province, Bilingual? district, Bilingual? village
});


@override $BilingualCopyWith<$Res>? get province;@override $BilingualCopyWith<$Res>? get district;@override $BilingualCopyWith<$Res>? get village;

}
/// @nodoc
class __$PlaceNamesCopyWithImpl<$Res>
    implements _$PlaceNamesCopyWith<$Res> {
  __$PlaceNamesCopyWithImpl(this._self, this._then);

  final _PlaceNames _self;
  final $Res Function(_PlaceNames) _then;

/// Create a copy of PlaceNames
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? province = freezed,Object? district = freezed,Object? village = freezed,}) {
  return _then(_PlaceNames(
province: freezed == province ? _self.province : province // ignore: cast_nullable_to_non_nullable
as Bilingual?,district: freezed == district ? _self.district : district // ignore: cast_nullable_to_non_nullable
as Bilingual?,village: freezed == village ? _self.village : village // ignore: cast_nullable_to_non_nullable
as Bilingual?,
  ));
}

/// Create a copy of PlaceNames
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BilingualCopyWith<$Res>? get province {
    if (_self.province == null) {
    return null;
  }

  return $BilingualCopyWith<$Res>(_self.province!, (value) {
    return _then(_self.copyWith(province: value));
  });
}/// Create a copy of PlaceNames
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BilingualCopyWith<$Res>? get district {
    if (_self.district == null) {
    return null;
  }

  return $BilingualCopyWith<$Res>(_self.district!, (value) {
    return _then(_self.copyWith(district: value));
  });
}/// Create a copy of PlaceNames
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BilingualCopyWith<$Res>? get village {
    if (_self.village == null) {
    return null;
  }

  return $BilingualCopyWith<$Res>(_self.village!, (value) {
    return _then(_self.copyWith(village: value));
  });
}
}

// dart format on
