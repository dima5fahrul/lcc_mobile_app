// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'bilingual.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$Bilingual {

 String get en; String get lo;
/// Create a copy of Bilingual
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BilingualCopyWith<Bilingual> get copyWith => _$BilingualCopyWithImpl<Bilingual>(this as Bilingual, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Bilingual&&(identical(other.en, en) || other.en == en)&&(identical(other.lo, lo) || other.lo == lo));
}


@override
int get hashCode => Object.hash(runtimeType,en,lo);

@override
String toString() {
  return 'Bilingual(en: $en, lo: $lo)';
}


}

/// @nodoc
abstract mixin class $BilingualCopyWith<$Res>  {
  factory $BilingualCopyWith(Bilingual value, $Res Function(Bilingual) _then) = _$BilingualCopyWithImpl;
@useResult
$Res call({
 String en, String lo
});




}
/// @nodoc
class _$BilingualCopyWithImpl<$Res>
    implements $BilingualCopyWith<$Res> {
  _$BilingualCopyWithImpl(this._self, this._then);

  final Bilingual _self;
  final $Res Function(Bilingual) _then;

/// Create a copy of Bilingual
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? en = null,Object? lo = null,}) {
  return _then(_self.copyWith(
en: null == en ? _self.en : en // ignore: cast_nullable_to_non_nullable
as String,lo: null == lo ? _self.lo : lo // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [Bilingual].
extension BilingualPatterns on Bilingual {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Bilingual value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Bilingual() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Bilingual value)  $default,){
final _that = this;
switch (_that) {
case _Bilingual():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Bilingual value)?  $default,){
final _that = this;
switch (_that) {
case _Bilingual() when $default != null:
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
case _Bilingual() when $default != null:
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
case _Bilingual():
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
case _Bilingual() when $default != null:
return $default(_that.en,_that.lo);case _:
  return null;

}
}

}

/// @nodoc


class _Bilingual implements Bilingual {
  const _Bilingual({required this.en, required this.lo});
  

@override final  String en;
@override final  String lo;

/// Create a copy of Bilingual
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BilingualCopyWith<_Bilingual> get copyWith => __$BilingualCopyWithImpl<_Bilingual>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Bilingual&&(identical(other.en, en) || other.en == en)&&(identical(other.lo, lo) || other.lo == lo));
}


@override
int get hashCode => Object.hash(runtimeType,en,lo);

@override
String toString() {
  return 'Bilingual(en: $en, lo: $lo)';
}


}

/// @nodoc
abstract mixin class _$BilingualCopyWith<$Res> implements $BilingualCopyWith<$Res> {
  factory _$BilingualCopyWith(_Bilingual value, $Res Function(_Bilingual) _then) = __$BilingualCopyWithImpl;
@override @useResult
$Res call({
 String en, String lo
});




}
/// @nodoc
class __$BilingualCopyWithImpl<$Res>
    implements _$BilingualCopyWith<$Res> {
  __$BilingualCopyWithImpl(this._self, this._then);

  final _Bilingual _self;
  final $Res Function(_Bilingual) _then;

/// Create a copy of Bilingual
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? en = null,Object? lo = null,}) {
  return _then(_Bilingual(
en: null == en ? _self.en : en // ignore: cast_nullable_to_non_nullable
as String,lo: null == lo ? _self.lo : lo // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
