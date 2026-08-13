// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'citizen_session_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$CitizenSessionModel {

 String get actor; CitizenAccount get citizen; AuthTokens get tokens;
/// Create a copy of CitizenSessionModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CitizenSessionModelCopyWith<CitizenSessionModel> get copyWith => _$CitizenSessionModelCopyWithImpl<CitizenSessionModel>(this as CitizenSessionModel, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CitizenSessionModel&&(identical(other.actor, actor) || other.actor == actor)&&(identical(other.citizen, citizen) || other.citizen == citizen)&&(identical(other.tokens, tokens) || other.tokens == tokens));
}


@override
int get hashCode => Object.hash(runtimeType,actor,citizen,tokens);

@override
String toString() {
  return 'CitizenSessionModel(actor: $actor, citizen: $citizen, tokens: $tokens)';
}


}

/// @nodoc
abstract mixin class $CitizenSessionModelCopyWith<$Res>  {
  factory $CitizenSessionModelCopyWith(CitizenSessionModel value, $Res Function(CitizenSessionModel) _then) = _$CitizenSessionModelCopyWithImpl;
@useResult
$Res call({
 String actor, CitizenAccount citizen, AuthTokens tokens
});


$CitizenAccountCopyWith<$Res> get citizen;$AuthTokensCopyWith<$Res> get tokens;

}
/// @nodoc
class _$CitizenSessionModelCopyWithImpl<$Res>
    implements $CitizenSessionModelCopyWith<$Res> {
  _$CitizenSessionModelCopyWithImpl(this._self, this._then);

  final CitizenSessionModel _self;
  final $Res Function(CitizenSessionModel) _then;

/// Create a copy of CitizenSessionModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? actor = null,Object? citizen = null,Object? tokens = null,}) {
  return _then(_self.copyWith(
actor: null == actor ? _self.actor : actor // ignore: cast_nullable_to_non_nullable
as String,citizen: null == citizen ? _self.citizen : citizen // ignore: cast_nullable_to_non_nullable
as CitizenAccount,tokens: null == tokens ? _self.tokens : tokens // ignore: cast_nullable_to_non_nullable
as AuthTokens,
  ));
}
/// Create a copy of CitizenSessionModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CitizenAccountCopyWith<$Res> get citizen {
  
  return $CitizenAccountCopyWith<$Res>(_self.citizen, (value) {
    return _then(_self.copyWith(citizen: value));
  });
}/// Create a copy of CitizenSessionModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$AuthTokensCopyWith<$Res> get tokens {
  
  return $AuthTokensCopyWith<$Res>(_self.tokens, (value) {
    return _then(_self.copyWith(tokens: value));
  });
}
}


/// Adds pattern-matching-related methods to [CitizenSessionModel].
extension CitizenSessionModelPatterns on CitizenSessionModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CitizenSessionModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CitizenSessionModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CitizenSessionModel value)  $default,){
final _that = this;
switch (_that) {
case _CitizenSessionModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CitizenSessionModel value)?  $default,){
final _that = this;
switch (_that) {
case _CitizenSessionModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String actor,  CitizenAccount citizen,  AuthTokens tokens)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CitizenSessionModel() when $default != null:
return $default(_that.actor,_that.citizen,_that.tokens);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String actor,  CitizenAccount citizen,  AuthTokens tokens)  $default,) {final _that = this;
switch (_that) {
case _CitizenSessionModel():
return $default(_that.actor,_that.citizen,_that.tokens);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String actor,  CitizenAccount citizen,  AuthTokens tokens)?  $default,) {final _that = this;
switch (_that) {
case _CitizenSessionModel() when $default != null:
return $default(_that.actor,_that.citizen,_that.tokens);case _:
  return null;

}
}

}

/// @nodoc


class _CitizenSessionModel implements CitizenSessionModel {
  const _CitizenSessionModel({required this.actor, required this.citizen, required this.tokens});
  

@override final  String actor;
@override final  CitizenAccount citizen;
@override final  AuthTokens tokens;

/// Create a copy of CitizenSessionModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CitizenSessionModelCopyWith<_CitizenSessionModel> get copyWith => __$CitizenSessionModelCopyWithImpl<_CitizenSessionModel>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CitizenSessionModel&&(identical(other.actor, actor) || other.actor == actor)&&(identical(other.citizen, citizen) || other.citizen == citizen)&&(identical(other.tokens, tokens) || other.tokens == tokens));
}


@override
int get hashCode => Object.hash(runtimeType,actor,citizen,tokens);

@override
String toString() {
  return 'CitizenSessionModel(actor: $actor, citizen: $citizen, tokens: $tokens)';
}


}

/// @nodoc
abstract mixin class _$CitizenSessionModelCopyWith<$Res> implements $CitizenSessionModelCopyWith<$Res> {
  factory _$CitizenSessionModelCopyWith(_CitizenSessionModel value, $Res Function(_CitizenSessionModel) _then) = __$CitizenSessionModelCopyWithImpl;
@override @useResult
$Res call({
 String actor, CitizenAccount citizen, AuthTokens tokens
});


@override $CitizenAccountCopyWith<$Res> get citizen;@override $AuthTokensCopyWith<$Res> get tokens;

}
/// @nodoc
class __$CitizenSessionModelCopyWithImpl<$Res>
    implements _$CitizenSessionModelCopyWith<$Res> {
  __$CitizenSessionModelCopyWithImpl(this._self, this._then);

  final _CitizenSessionModel _self;
  final $Res Function(_CitizenSessionModel) _then;

/// Create a copy of CitizenSessionModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? actor = null,Object? citizen = null,Object? tokens = null,}) {
  return _then(_CitizenSessionModel(
actor: null == actor ? _self.actor : actor // ignore: cast_nullable_to_non_nullable
as String,citizen: null == citizen ? _self.citizen : citizen // ignore: cast_nullable_to_non_nullable
as CitizenAccount,tokens: null == tokens ? _self.tokens : tokens // ignore: cast_nullable_to_non_nullable
as AuthTokens,
  ));
}

/// Create a copy of CitizenSessionModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CitizenAccountCopyWith<$Res> get citizen {
  
  return $CitizenAccountCopyWith<$Res>(_self.citizen, (value) {
    return _then(_self.copyWith(citizen: value));
  });
}/// Create a copy of CitizenSessionModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$AuthTokensCopyWith<$Res> get tokens {
  
  return $AuthTokensCopyWith<$Res>(_self.tokens, (value) {
    return _then(_self.copyWith(tokens: value));
  });
}
}

// dart format on
