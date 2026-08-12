// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'otp_challenge.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$OTPChallenge {

 String get phone; String get purpose;@JsonKey(name: 'expires_at') String? get expiresAt;@JsonKey(name: 'expires_in') int? get expiresIn;@JsonKey(name: 'resend_after') int? get resendAfter;@JsonKey(name: 'dev_code') String? get devCode;
/// Create a copy of OTPChallenge
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$OTPChallengeCopyWith<OTPChallenge> get copyWith => _$OTPChallengeCopyWithImpl<OTPChallenge>(this as OTPChallenge, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is OTPChallenge&&(identical(other.phone, phone) || other.phone == phone)&&(identical(other.purpose, purpose) || other.purpose == purpose)&&(identical(other.expiresAt, expiresAt) || other.expiresAt == expiresAt)&&(identical(other.expiresIn, expiresIn) || other.expiresIn == expiresIn)&&(identical(other.resendAfter, resendAfter) || other.resendAfter == resendAfter)&&(identical(other.devCode, devCode) || other.devCode == devCode));
}


@override
int get hashCode => Object.hash(runtimeType,phone,purpose,expiresAt,expiresIn,resendAfter,devCode);

@override
String toString() {
  return 'OTPChallenge(phone: $phone, purpose: $purpose, expiresAt: $expiresAt, expiresIn: $expiresIn, resendAfter: $resendAfter, devCode: $devCode)';
}


}

/// @nodoc
abstract mixin class $OTPChallengeCopyWith<$Res>  {
  factory $OTPChallengeCopyWith(OTPChallenge value, $Res Function(OTPChallenge) _then) = _$OTPChallengeCopyWithImpl;
@useResult
$Res call({
 String phone, String purpose,@JsonKey(name: 'expires_at') String? expiresAt,@JsonKey(name: 'expires_in') int? expiresIn,@JsonKey(name: 'resend_after') int? resendAfter,@JsonKey(name: 'dev_code') String? devCode
});




}
/// @nodoc
class _$OTPChallengeCopyWithImpl<$Res>
    implements $OTPChallengeCopyWith<$Res> {
  _$OTPChallengeCopyWithImpl(this._self, this._then);

  final OTPChallenge _self;
  final $Res Function(OTPChallenge) _then;

/// Create a copy of OTPChallenge
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? phone = null,Object? purpose = null,Object? expiresAt = freezed,Object? expiresIn = freezed,Object? resendAfter = freezed,Object? devCode = freezed,}) {
  return _then(_self.copyWith(
phone: null == phone ? _self.phone : phone // ignore: cast_nullable_to_non_nullable
as String,purpose: null == purpose ? _self.purpose : purpose // ignore: cast_nullable_to_non_nullable
as String,expiresAt: freezed == expiresAt ? _self.expiresAt : expiresAt // ignore: cast_nullable_to_non_nullable
as String?,expiresIn: freezed == expiresIn ? _self.expiresIn : expiresIn // ignore: cast_nullable_to_non_nullable
as int?,resendAfter: freezed == resendAfter ? _self.resendAfter : resendAfter // ignore: cast_nullable_to_non_nullable
as int?,devCode: freezed == devCode ? _self.devCode : devCode // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [OTPChallenge].
extension OTPChallengePatterns on OTPChallenge {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _OTPChallenge value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _OTPChallenge() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _OTPChallenge value)  $default,){
final _that = this;
switch (_that) {
case _OTPChallenge():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _OTPChallenge value)?  $default,){
final _that = this;
switch (_that) {
case _OTPChallenge() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String phone,  String purpose, @JsonKey(name: 'expires_at')  String? expiresAt, @JsonKey(name: 'expires_in')  int? expiresIn, @JsonKey(name: 'resend_after')  int? resendAfter, @JsonKey(name: 'dev_code')  String? devCode)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _OTPChallenge() when $default != null:
return $default(_that.phone,_that.purpose,_that.expiresAt,_that.expiresIn,_that.resendAfter,_that.devCode);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String phone,  String purpose, @JsonKey(name: 'expires_at')  String? expiresAt, @JsonKey(name: 'expires_in')  int? expiresIn, @JsonKey(name: 'resend_after')  int? resendAfter, @JsonKey(name: 'dev_code')  String? devCode)  $default,) {final _that = this;
switch (_that) {
case _OTPChallenge():
return $default(_that.phone,_that.purpose,_that.expiresAt,_that.expiresIn,_that.resendAfter,_that.devCode);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String phone,  String purpose, @JsonKey(name: 'expires_at')  String? expiresAt, @JsonKey(name: 'expires_in')  int? expiresIn, @JsonKey(name: 'resend_after')  int? resendAfter, @JsonKey(name: 'dev_code')  String? devCode)?  $default,) {final _that = this;
switch (_that) {
case _OTPChallenge() when $default != null:
return $default(_that.phone,_that.purpose,_that.expiresAt,_that.expiresIn,_that.resendAfter,_that.devCode);case _:
  return null;

}
}

}

/// @nodoc


class _OTPChallenge implements OTPChallenge {
  const _OTPChallenge({required this.phone, required this.purpose, @JsonKey(name: 'expires_at') this.expiresAt, @JsonKey(name: 'expires_in') this.expiresIn, @JsonKey(name: 'resend_after') this.resendAfter, @JsonKey(name: 'dev_code') this.devCode});
  

@override final  String phone;
@override final  String purpose;
@override@JsonKey(name: 'expires_at') final  String? expiresAt;
@override@JsonKey(name: 'expires_in') final  int? expiresIn;
@override@JsonKey(name: 'resend_after') final  int? resendAfter;
@override@JsonKey(name: 'dev_code') final  String? devCode;

/// Create a copy of OTPChallenge
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$OTPChallengeCopyWith<_OTPChallenge> get copyWith => __$OTPChallengeCopyWithImpl<_OTPChallenge>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _OTPChallenge&&(identical(other.phone, phone) || other.phone == phone)&&(identical(other.purpose, purpose) || other.purpose == purpose)&&(identical(other.expiresAt, expiresAt) || other.expiresAt == expiresAt)&&(identical(other.expiresIn, expiresIn) || other.expiresIn == expiresIn)&&(identical(other.resendAfter, resendAfter) || other.resendAfter == resendAfter)&&(identical(other.devCode, devCode) || other.devCode == devCode));
}


@override
int get hashCode => Object.hash(runtimeType,phone,purpose,expiresAt,expiresIn,resendAfter,devCode);

@override
String toString() {
  return 'OTPChallenge(phone: $phone, purpose: $purpose, expiresAt: $expiresAt, expiresIn: $expiresIn, resendAfter: $resendAfter, devCode: $devCode)';
}


}

/// @nodoc
abstract mixin class _$OTPChallengeCopyWith<$Res> implements $OTPChallengeCopyWith<$Res> {
  factory _$OTPChallengeCopyWith(_OTPChallenge value, $Res Function(_OTPChallenge) _then) = __$OTPChallengeCopyWithImpl;
@override @useResult
$Res call({
 String phone, String purpose,@JsonKey(name: 'expires_at') String? expiresAt,@JsonKey(name: 'expires_in') int? expiresIn,@JsonKey(name: 'resend_after') int? resendAfter,@JsonKey(name: 'dev_code') String? devCode
});




}
/// @nodoc
class __$OTPChallengeCopyWithImpl<$Res>
    implements _$OTPChallengeCopyWith<$Res> {
  __$OTPChallengeCopyWithImpl(this._self, this._then);

  final _OTPChallenge _self;
  final $Res Function(_OTPChallenge) _then;

/// Create a copy of OTPChallenge
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? phone = null,Object? purpose = null,Object? expiresAt = freezed,Object? expiresIn = freezed,Object? resendAfter = freezed,Object? devCode = freezed,}) {
  return _then(_OTPChallenge(
phone: null == phone ? _self.phone : phone // ignore: cast_nullable_to_non_nullable
as String,purpose: null == purpose ? _self.purpose : purpose // ignore: cast_nullable_to_non_nullable
as String,expiresAt: freezed == expiresAt ? _self.expiresAt : expiresAt // ignore: cast_nullable_to_non_nullable
as String?,expiresIn: freezed == expiresIn ? _self.expiresIn : expiresIn // ignore: cast_nullable_to_non_nullable
as int?,resendAfter: freezed == resendAfter ? _self.resendAfter : resendAfter // ignore: cast_nullable_to_non_nullable
as int?,devCode: freezed == devCode ? _self.devCode : devCode // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
