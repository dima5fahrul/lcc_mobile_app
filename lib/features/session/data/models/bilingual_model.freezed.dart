// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'bilingual_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$BilingualModel {

 String get en; String get lo;
/// Create a copy of BilingualModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BilingualModelCopyWith<BilingualModel> get copyWith => _$BilingualModelCopyWithImpl<BilingualModel>(this as BilingualModel, _$identity);

  /// Serializes this BilingualModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BilingualModel&&(identical(other.en, en) || other.en == en)&&(identical(other.lo, lo) || other.lo == lo));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,en,lo);

@override
String toString() {
  return 'BilingualModel(en: $en, lo: $lo)';
}


}

/// @nodoc
abstract mixin class $BilingualModelCopyWith<$Res>  {
  factory $BilingualModelCopyWith(BilingualModel value, $Res Function(BilingualModel) _then) = _$BilingualModelCopyWithImpl;
@useResult
$Res call({
 String en, String lo
});




}
/// @nodoc
class _$BilingualModelCopyWithImpl<$Res>
    implements $BilingualModelCopyWith<$Res> {
  _$BilingualModelCopyWithImpl(this._self, this._then);

  final BilingualModel _self;
  final $Res Function(BilingualModel) _then;

/// Create a copy of BilingualModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? en = null,Object? lo = null,}) {
  return _then(_self.copyWith(
en: null == en ? _self.en : en // ignore: cast_nullable_to_non_nullable
as String,lo: null == lo ? _self.lo : lo // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [BilingualModel].
extension BilingualModelPatterns on BilingualModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _BilingualModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _BilingualModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _BilingualModel value)  $default,){
final _that = this;
switch (_that) {
case _BilingualModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _BilingualModel value)?  $default,){
final _that = this;
switch (_that) {
case _BilingualModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String en,  String lo)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _BilingualModel() when $default != null:
return $default(_that.en,_that.lo);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String en,  String lo)  $default,) {final _that = this;
switch (_that) {
case _BilingualModel():
return $default(_that.en,_that.lo);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String en,  String lo)?  $default,) {final _that = this;
switch (_that) {
case _BilingualModel() when $default != null:
return $default(_that.en,_that.lo);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _BilingualModel implements BilingualModel {
  const _BilingualModel({required this.en, required this.lo});
  factory _BilingualModel.fromJson(Map<String, dynamic> json) => _$BilingualModelFromJson(json);

@override final  String en;
@override final  String lo;

/// Create a copy of BilingualModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BilingualModelCopyWith<_BilingualModel> get copyWith => __$BilingualModelCopyWithImpl<_BilingualModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$BilingualModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _BilingualModel&&(identical(other.en, en) || other.en == en)&&(identical(other.lo, lo) || other.lo == lo));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,en,lo);

@override
String toString() {
  return 'BilingualModel(en: $en, lo: $lo)';
}


}

/// @nodoc
abstract mixin class _$BilingualModelCopyWith<$Res> implements $BilingualModelCopyWith<$Res> {
  factory _$BilingualModelCopyWith(_BilingualModel value, $Res Function(_BilingualModel) _then) = __$BilingualModelCopyWithImpl;
@override @useResult
$Res call({
 String en, String lo
});




}
/// @nodoc
class __$BilingualModelCopyWithImpl<$Res>
    implements _$BilingualModelCopyWith<$Res> {
  __$BilingualModelCopyWithImpl(this._self, this._then);

  final _BilingualModel _self;
  final $Res Function(_BilingualModel) _then;

/// Create a copy of BilingualModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? en = null,Object? lo = null,}) {
  return _then(_BilingualModel(
en: null == en ? _self.en : en // ignore: cast_nullable_to_non_nullable
as String,lo: null == lo ? _self.lo : lo // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
