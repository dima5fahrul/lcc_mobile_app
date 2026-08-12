// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'citizen_session.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$CitizenSession {

 String get actor; CitizenAccount get citizen; AuthTokens get tokens;
/// Create a copy of CitizenSession
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CitizenSessionCopyWith<CitizenSession> get copyWith => _$CitizenSessionCopyWithImpl<CitizenSession>(this as CitizenSession, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CitizenSession&&(identical(other.actor, actor) || other.actor == actor)&&(identical(other.citizen, citizen) || other.citizen == citizen)&&(identical(other.tokens, tokens) || other.tokens == tokens));
}


@override
int get hashCode => Object.hash(runtimeType,actor,citizen,tokens);

@override
String toString() {
  return 'CitizenSession(actor: $actor, citizen: $citizen, tokens: $tokens)';
}


}

/// @nodoc
abstract mixin class $CitizenSessionCopyWith<$Res>  {
  factory $CitizenSessionCopyWith(CitizenSession value, $Res Function(CitizenSession) _then) = _$CitizenSessionCopyWithImpl;
@useResult
$Res call({
 String actor, CitizenAccount citizen, AuthTokens tokens
});


$CitizenAccountCopyWith<$Res> get citizen;$AuthTokensCopyWith<$Res> get tokens;

}
/// @nodoc
class _$CitizenSessionCopyWithImpl<$Res>
    implements $CitizenSessionCopyWith<$Res> {
  _$CitizenSessionCopyWithImpl(this._self, this._then);

  final CitizenSession _self;
  final $Res Function(CitizenSession) _then;

/// Create a copy of CitizenSession
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? actor = null,Object? citizen = null,Object? tokens = null,}) {
  return _then(_self.copyWith(
actor: null == actor ? _self.actor : actor // ignore: cast_nullable_to_non_nullable
as String,citizen: null == citizen ? _self.citizen : citizen // ignore: cast_nullable_to_non_nullable
as CitizenAccount,tokens: null == tokens ? _self.tokens : tokens // ignore: cast_nullable_to_non_nullable
as AuthTokens,
  ));
}
/// Create a copy of CitizenSession
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CitizenAccountCopyWith<$Res> get citizen {
  
  return $CitizenAccountCopyWith<$Res>(_self.citizen, (value) {
    return _then(_self.copyWith(citizen: value));
  });
}/// Create a copy of CitizenSession
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$AuthTokensCopyWith<$Res> get tokens {
  
  return $AuthTokensCopyWith<$Res>(_self.tokens, (value) {
    return _then(_self.copyWith(tokens: value));
  });
}
}


/// Adds pattern-matching-related methods to [CitizenSession].
extension CitizenSessionPatterns on CitizenSession {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CitizenSession value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CitizenSession() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CitizenSession value)  $default,){
final _that = this;
switch (_that) {
case _CitizenSession():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CitizenSession value)?  $default,){
final _that = this;
switch (_that) {
case _CitizenSession() when $default != null:
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
case _CitizenSession() when $default != null:
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
case _CitizenSession():
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
case _CitizenSession() when $default != null:
return $default(_that.actor,_that.citizen,_that.tokens);case _:
  return null;

}
}

}

/// @nodoc


class _CitizenSession implements CitizenSession {
  const _CitizenSession({required this.actor, required this.citizen, required this.tokens});
  

@override final  String actor;
@override final  CitizenAccount citizen;
@override final  AuthTokens tokens;

/// Create a copy of CitizenSession
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CitizenSessionCopyWith<_CitizenSession> get copyWith => __$CitizenSessionCopyWithImpl<_CitizenSession>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CitizenSession&&(identical(other.actor, actor) || other.actor == actor)&&(identical(other.citizen, citizen) || other.citizen == citizen)&&(identical(other.tokens, tokens) || other.tokens == tokens));
}


@override
int get hashCode => Object.hash(runtimeType,actor,citizen,tokens);

@override
String toString() {
  return 'CitizenSession(actor: $actor, citizen: $citizen, tokens: $tokens)';
}


}

/// @nodoc
abstract mixin class _$CitizenSessionCopyWith<$Res> implements $CitizenSessionCopyWith<$Res> {
  factory _$CitizenSessionCopyWith(_CitizenSession value, $Res Function(_CitizenSession) _then) = __$CitizenSessionCopyWithImpl;
@override @useResult
$Res call({
 String actor, CitizenAccount citizen, AuthTokens tokens
});


@override $CitizenAccountCopyWith<$Res> get citizen;@override $AuthTokensCopyWith<$Res> get tokens;

}
/// @nodoc
class __$CitizenSessionCopyWithImpl<$Res>
    implements _$CitizenSessionCopyWith<$Res> {
  __$CitizenSessionCopyWithImpl(this._self, this._then);

  final _CitizenSession _self;
  final $Res Function(_CitizenSession) _then;

/// Create a copy of CitizenSession
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? actor = null,Object? citizen = null,Object? tokens = null,}) {
  return _then(_CitizenSession(
actor: null == actor ? _self.actor : actor // ignore: cast_nullable_to_non_nullable
as String,citizen: null == citizen ? _self.citizen : citizen // ignore: cast_nullable_to_non_nullable
as CitizenAccount,tokens: null == tokens ? _self.tokens : tokens // ignore: cast_nullable_to_non_nullable
as AuthTokens,
  ));
}

/// Create a copy of CitizenSession
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CitizenAccountCopyWith<$Res> get citizen {
  
  return $CitizenAccountCopyWith<$Res>(_self.citizen, (value) {
    return _then(_self.copyWith(citizen: value));
  });
}/// Create a copy of CitizenSession
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
