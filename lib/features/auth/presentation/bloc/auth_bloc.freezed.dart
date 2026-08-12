// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'auth_bloc.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$AuthEvent {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AuthEvent);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'AuthEvent()';
}


}

/// @nodoc
class $AuthEventCopyWith<$Res>  {
$AuthEventCopyWith(AuthEvent _, $Res Function(AuthEvent) __);
}


/// Adds pattern-matching-related methods to [AuthEvent].
extension AuthEventPatterns on AuthEvent {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( AuthEventLoginStarted value)?  loginStarted,TResult Function( AuthEventRegisterStarted value)?  registerStarted,TResult Function( AuthEventOtpRequested value)?  otpRequested,TResult Function( AuthEventOtpVerified value)?  otpVerified,TResult Function( AuthEventPasswordReset value)?  passwordReset,TResult Function( AuthEventResetState value)?  resetState,required TResult orElse(),}){
final _that = this;
switch (_that) {
case AuthEventLoginStarted() when loginStarted != null:
return loginStarted(_that);case AuthEventRegisterStarted() when registerStarted != null:
return registerStarted(_that);case AuthEventOtpRequested() when otpRequested != null:
return otpRequested(_that);case AuthEventOtpVerified() when otpVerified != null:
return otpVerified(_that);case AuthEventPasswordReset() when passwordReset != null:
return passwordReset(_that);case AuthEventResetState() when resetState != null:
return resetState(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( AuthEventLoginStarted value)  loginStarted,required TResult Function( AuthEventRegisterStarted value)  registerStarted,required TResult Function( AuthEventOtpRequested value)  otpRequested,required TResult Function( AuthEventOtpVerified value)  otpVerified,required TResult Function( AuthEventPasswordReset value)  passwordReset,required TResult Function( AuthEventResetState value)  resetState,}){
final _that = this;
switch (_that) {
case AuthEventLoginStarted():
return loginStarted(_that);case AuthEventRegisterStarted():
return registerStarted(_that);case AuthEventOtpRequested():
return otpRequested(_that);case AuthEventOtpVerified():
return otpVerified(_that);case AuthEventPasswordReset():
return passwordReset(_that);case AuthEventResetState():
return resetState(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( AuthEventLoginStarted value)?  loginStarted,TResult? Function( AuthEventRegisterStarted value)?  registerStarted,TResult? Function( AuthEventOtpRequested value)?  otpRequested,TResult? Function( AuthEventOtpVerified value)?  otpVerified,TResult? Function( AuthEventPasswordReset value)?  passwordReset,TResult? Function( AuthEventResetState value)?  resetState,}){
final _that = this;
switch (_that) {
case AuthEventLoginStarted() when loginStarted != null:
return loginStarted(_that);case AuthEventRegisterStarted() when registerStarted != null:
return registerStarted(_that);case AuthEventOtpRequested() when otpRequested != null:
return otpRequested(_that);case AuthEventOtpVerified() when otpVerified != null:
return otpVerified(_that);case AuthEventPasswordReset() when passwordReset != null:
return passwordReset(_that);case AuthEventResetState() when resetState != null:
return resetState(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( String phone,  String password)?  loginStarted,TResult Function( String phone,  String name,  String password,  String? email)?  registerStarted,TResult Function( String phone,  String purpose)?  otpRequested,TResult Function( String phone,  String code,  String purpose)?  otpVerified,TResult Function( String phone,  String code,  String newPassword)?  passwordReset,TResult Function()?  resetState,required TResult orElse(),}) {final _that = this;
switch (_that) {
case AuthEventLoginStarted() when loginStarted != null:
return loginStarted(_that.phone,_that.password);case AuthEventRegisterStarted() when registerStarted != null:
return registerStarted(_that.phone,_that.name,_that.password,_that.email);case AuthEventOtpRequested() when otpRequested != null:
return otpRequested(_that.phone,_that.purpose);case AuthEventOtpVerified() when otpVerified != null:
return otpVerified(_that.phone,_that.code,_that.purpose);case AuthEventPasswordReset() when passwordReset != null:
return passwordReset(_that.phone,_that.code,_that.newPassword);case AuthEventResetState() when resetState != null:
return resetState();case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( String phone,  String password)  loginStarted,required TResult Function( String phone,  String name,  String password,  String? email)  registerStarted,required TResult Function( String phone,  String purpose)  otpRequested,required TResult Function( String phone,  String code,  String purpose)  otpVerified,required TResult Function( String phone,  String code,  String newPassword)  passwordReset,required TResult Function()  resetState,}) {final _that = this;
switch (_that) {
case AuthEventLoginStarted():
return loginStarted(_that.phone,_that.password);case AuthEventRegisterStarted():
return registerStarted(_that.phone,_that.name,_that.password,_that.email);case AuthEventOtpRequested():
return otpRequested(_that.phone,_that.purpose);case AuthEventOtpVerified():
return otpVerified(_that.phone,_that.code,_that.purpose);case AuthEventPasswordReset():
return passwordReset(_that.phone,_that.code,_that.newPassword);case AuthEventResetState():
return resetState();}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( String phone,  String password)?  loginStarted,TResult? Function( String phone,  String name,  String password,  String? email)?  registerStarted,TResult? Function( String phone,  String purpose)?  otpRequested,TResult? Function( String phone,  String code,  String purpose)?  otpVerified,TResult? Function( String phone,  String code,  String newPassword)?  passwordReset,TResult? Function()?  resetState,}) {final _that = this;
switch (_that) {
case AuthEventLoginStarted() when loginStarted != null:
return loginStarted(_that.phone,_that.password);case AuthEventRegisterStarted() when registerStarted != null:
return registerStarted(_that.phone,_that.name,_that.password,_that.email);case AuthEventOtpRequested() when otpRequested != null:
return otpRequested(_that.phone,_that.purpose);case AuthEventOtpVerified() when otpVerified != null:
return otpVerified(_that.phone,_that.code,_that.purpose);case AuthEventPasswordReset() when passwordReset != null:
return passwordReset(_that.phone,_that.code,_that.newPassword);case AuthEventResetState() when resetState != null:
return resetState();case _:
  return null;

}
}

}

/// @nodoc


class AuthEventLoginStarted implements AuthEvent {
  const AuthEventLoginStarted({required this.phone, required this.password});
  

 final  String phone;
 final  String password;

/// Create a copy of AuthEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AuthEventLoginStartedCopyWith<AuthEventLoginStarted> get copyWith => _$AuthEventLoginStartedCopyWithImpl<AuthEventLoginStarted>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AuthEventLoginStarted&&(identical(other.phone, phone) || other.phone == phone)&&(identical(other.password, password) || other.password == password));
}


@override
int get hashCode => Object.hash(runtimeType,phone,password);

@override
String toString() {
  return 'AuthEvent.loginStarted(phone: $phone, password: $password)';
}


}

/// @nodoc
abstract mixin class $AuthEventLoginStartedCopyWith<$Res> implements $AuthEventCopyWith<$Res> {
  factory $AuthEventLoginStartedCopyWith(AuthEventLoginStarted value, $Res Function(AuthEventLoginStarted) _then) = _$AuthEventLoginStartedCopyWithImpl;
@useResult
$Res call({
 String phone, String password
});




}
/// @nodoc
class _$AuthEventLoginStartedCopyWithImpl<$Res>
    implements $AuthEventLoginStartedCopyWith<$Res> {
  _$AuthEventLoginStartedCopyWithImpl(this._self, this._then);

  final AuthEventLoginStarted _self;
  final $Res Function(AuthEventLoginStarted) _then;

/// Create a copy of AuthEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? phone = null,Object? password = null,}) {
  return _then(AuthEventLoginStarted(
phone: null == phone ? _self.phone : phone // ignore: cast_nullable_to_non_nullable
as String,password: null == password ? _self.password : password // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class AuthEventRegisterStarted implements AuthEvent {
  const AuthEventRegisterStarted({required this.phone, required this.name, required this.password, this.email});
  

 final  String phone;
 final  String name;
 final  String password;
 final  String? email;

/// Create a copy of AuthEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AuthEventRegisterStartedCopyWith<AuthEventRegisterStarted> get copyWith => _$AuthEventRegisterStartedCopyWithImpl<AuthEventRegisterStarted>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AuthEventRegisterStarted&&(identical(other.phone, phone) || other.phone == phone)&&(identical(other.name, name) || other.name == name)&&(identical(other.password, password) || other.password == password)&&(identical(other.email, email) || other.email == email));
}


@override
int get hashCode => Object.hash(runtimeType,phone,name,password,email);

@override
String toString() {
  return 'AuthEvent.registerStarted(phone: $phone, name: $name, password: $password, email: $email)';
}


}

/// @nodoc
abstract mixin class $AuthEventRegisterStartedCopyWith<$Res> implements $AuthEventCopyWith<$Res> {
  factory $AuthEventRegisterStartedCopyWith(AuthEventRegisterStarted value, $Res Function(AuthEventRegisterStarted) _then) = _$AuthEventRegisterStartedCopyWithImpl;
@useResult
$Res call({
 String phone, String name, String password, String? email
});




}
/// @nodoc
class _$AuthEventRegisterStartedCopyWithImpl<$Res>
    implements $AuthEventRegisterStartedCopyWith<$Res> {
  _$AuthEventRegisterStartedCopyWithImpl(this._self, this._then);

  final AuthEventRegisterStarted _self;
  final $Res Function(AuthEventRegisterStarted) _then;

/// Create a copy of AuthEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? phone = null,Object? name = null,Object? password = null,Object? email = freezed,}) {
  return _then(AuthEventRegisterStarted(
phone: null == phone ? _self.phone : phone // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,password: null == password ? _self.password : password // ignore: cast_nullable_to_non_nullable
as String,email: freezed == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

/// @nodoc


class AuthEventOtpRequested implements AuthEvent {
  const AuthEventOtpRequested({required this.phone, required this.purpose});
  

 final  String phone;
 final  String purpose;

/// Create a copy of AuthEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AuthEventOtpRequestedCopyWith<AuthEventOtpRequested> get copyWith => _$AuthEventOtpRequestedCopyWithImpl<AuthEventOtpRequested>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AuthEventOtpRequested&&(identical(other.phone, phone) || other.phone == phone)&&(identical(other.purpose, purpose) || other.purpose == purpose));
}


@override
int get hashCode => Object.hash(runtimeType,phone,purpose);

@override
String toString() {
  return 'AuthEvent.otpRequested(phone: $phone, purpose: $purpose)';
}


}

/// @nodoc
abstract mixin class $AuthEventOtpRequestedCopyWith<$Res> implements $AuthEventCopyWith<$Res> {
  factory $AuthEventOtpRequestedCopyWith(AuthEventOtpRequested value, $Res Function(AuthEventOtpRequested) _then) = _$AuthEventOtpRequestedCopyWithImpl;
@useResult
$Res call({
 String phone, String purpose
});




}
/// @nodoc
class _$AuthEventOtpRequestedCopyWithImpl<$Res>
    implements $AuthEventOtpRequestedCopyWith<$Res> {
  _$AuthEventOtpRequestedCopyWithImpl(this._self, this._then);

  final AuthEventOtpRequested _self;
  final $Res Function(AuthEventOtpRequested) _then;

/// Create a copy of AuthEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? phone = null,Object? purpose = null,}) {
  return _then(AuthEventOtpRequested(
phone: null == phone ? _self.phone : phone // ignore: cast_nullable_to_non_nullable
as String,purpose: null == purpose ? _self.purpose : purpose // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class AuthEventOtpVerified implements AuthEvent {
  const AuthEventOtpVerified({required this.phone, required this.code, required this.purpose});
  

 final  String phone;
 final  String code;
 final  String purpose;

/// Create a copy of AuthEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AuthEventOtpVerifiedCopyWith<AuthEventOtpVerified> get copyWith => _$AuthEventOtpVerifiedCopyWithImpl<AuthEventOtpVerified>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AuthEventOtpVerified&&(identical(other.phone, phone) || other.phone == phone)&&(identical(other.code, code) || other.code == code)&&(identical(other.purpose, purpose) || other.purpose == purpose));
}


@override
int get hashCode => Object.hash(runtimeType,phone,code,purpose);

@override
String toString() {
  return 'AuthEvent.otpVerified(phone: $phone, code: $code, purpose: $purpose)';
}


}

/// @nodoc
abstract mixin class $AuthEventOtpVerifiedCopyWith<$Res> implements $AuthEventCopyWith<$Res> {
  factory $AuthEventOtpVerifiedCopyWith(AuthEventOtpVerified value, $Res Function(AuthEventOtpVerified) _then) = _$AuthEventOtpVerifiedCopyWithImpl;
@useResult
$Res call({
 String phone, String code, String purpose
});




}
/// @nodoc
class _$AuthEventOtpVerifiedCopyWithImpl<$Res>
    implements $AuthEventOtpVerifiedCopyWith<$Res> {
  _$AuthEventOtpVerifiedCopyWithImpl(this._self, this._then);

  final AuthEventOtpVerified _self;
  final $Res Function(AuthEventOtpVerified) _then;

/// Create a copy of AuthEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? phone = null,Object? code = null,Object? purpose = null,}) {
  return _then(AuthEventOtpVerified(
phone: null == phone ? _self.phone : phone // ignore: cast_nullable_to_non_nullable
as String,code: null == code ? _self.code : code // ignore: cast_nullable_to_non_nullable
as String,purpose: null == purpose ? _self.purpose : purpose // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class AuthEventPasswordReset implements AuthEvent {
  const AuthEventPasswordReset({required this.phone, required this.code, required this.newPassword});
  

 final  String phone;
 final  String code;
 final  String newPassword;

/// Create a copy of AuthEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AuthEventPasswordResetCopyWith<AuthEventPasswordReset> get copyWith => _$AuthEventPasswordResetCopyWithImpl<AuthEventPasswordReset>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AuthEventPasswordReset&&(identical(other.phone, phone) || other.phone == phone)&&(identical(other.code, code) || other.code == code)&&(identical(other.newPassword, newPassword) || other.newPassword == newPassword));
}


@override
int get hashCode => Object.hash(runtimeType,phone,code,newPassword);

@override
String toString() {
  return 'AuthEvent.passwordReset(phone: $phone, code: $code, newPassword: $newPassword)';
}


}

/// @nodoc
abstract mixin class $AuthEventPasswordResetCopyWith<$Res> implements $AuthEventCopyWith<$Res> {
  factory $AuthEventPasswordResetCopyWith(AuthEventPasswordReset value, $Res Function(AuthEventPasswordReset) _then) = _$AuthEventPasswordResetCopyWithImpl;
@useResult
$Res call({
 String phone, String code, String newPassword
});




}
/// @nodoc
class _$AuthEventPasswordResetCopyWithImpl<$Res>
    implements $AuthEventPasswordResetCopyWith<$Res> {
  _$AuthEventPasswordResetCopyWithImpl(this._self, this._then);

  final AuthEventPasswordReset _self;
  final $Res Function(AuthEventPasswordReset) _then;

/// Create a copy of AuthEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? phone = null,Object? code = null,Object? newPassword = null,}) {
  return _then(AuthEventPasswordReset(
phone: null == phone ? _self.phone : phone // ignore: cast_nullable_to_non_nullable
as String,code: null == code ? _self.code : code // ignore: cast_nullable_to_non_nullable
as String,newPassword: null == newPassword ? _self.newPassword : newPassword // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class AuthEventResetState implements AuthEvent {
  const AuthEventResetState();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AuthEventResetState);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'AuthEvent.resetState()';
}


}




/// @nodoc
mixin _$AuthState {

 AuthStatus get status; CitizenSession? get session; OTPChallenge? get challenge; String? get errorMessage; Map<String, String> get fieldErrors;
/// Create a copy of AuthState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AuthStateCopyWith<AuthState> get copyWith => _$AuthStateCopyWithImpl<AuthState>(this as AuthState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AuthState&&(identical(other.status, status) || other.status == status)&&(identical(other.session, session) || other.session == session)&&(identical(other.challenge, challenge) || other.challenge == challenge)&&(identical(other.errorMessage, errorMessage) || other.errorMessage == errorMessage)&&const DeepCollectionEquality().equals(other.fieldErrors, fieldErrors));
}


@override
int get hashCode => Object.hash(runtimeType,status,session,challenge,errorMessage,const DeepCollectionEquality().hash(fieldErrors));

@override
String toString() {
  return 'AuthState(status: $status, session: $session, challenge: $challenge, errorMessage: $errorMessage, fieldErrors: $fieldErrors)';
}


}

/// @nodoc
abstract mixin class $AuthStateCopyWith<$Res>  {
  factory $AuthStateCopyWith(AuthState value, $Res Function(AuthState) _then) = _$AuthStateCopyWithImpl;
@useResult
$Res call({
 AuthStatus status, CitizenSession? session, OTPChallenge? challenge, String? errorMessage, Map<String, String> fieldErrors
});


$CitizenSessionCopyWith<$Res>? get session;$OTPChallengeCopyWith<$Res>? get challenge;

}
/// @nodoc
class _$AuthStateCopyWithImpl<$Res>
    implements $AuthStateCopyWith<$Res> {
  _$AuthStateCopyWithImpl(this._self, this._then);

  final AuthState _self;
  final $Res Function(AuthState) _then;

/// Create a copy of AuthState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? status = null,Object? session = freezed,Object? challenge = freezed,Object? errorMessage = freezed,Object? fieldErrors = null,}) {
  return _then(_self.copyWith(
status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as AuthStatus,session: freezed == session ? _self.session : session // ignore: cast_nullable_to_non_nullable
as CitizenSession?,challenge: freezed == challenge ? _self.challenge : challenge // ignore: cast_nullable_to_non_nullable
as OTPChallenge?,errorMessage: freezed == errorMessage ? _self.errorMessage : errorMessage // ignore: cast_nullable_to_non_nullable
as String?,fieldErrors: null == fieldErrors ? _self.fieldErrors : fieldErrors // ignore: cast_nullable_to_non_nullable
as Map<String, String>,
  ));
}
/// Create a copy of AuthState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CitizenSessionCopyWith<$Res>? get session {
    if (_self.session == null) {
    return null;
  }

  return $CitizenSessionCopyWith<$Res>(_self.session!, (value) {
    return _then(_self.copyWith(session: value));
  });
}/// Create a copy of AuthState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$OTPChallengeCopyWith<$Res>? get challenge {
    if (_self.challenge == null) {
    return null;
  }

  return $OTPChallengeCopyWith<$Res>(_self.challenge!, (value) {
    return _then(_self.copyWith(challenge: value));
  });
}
}


/// Adds pattern-matching-related methods to [AuthState].
extension AuthStatePatterns on AuthState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AuthState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AuthState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AuthState value)  $default,){
final _that = this;
switch (_that) {
case _AuthState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AuthState value)?  $default,){
final _that = this;
switch (_that) {
case _AuthState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( AuthStatus status,  CitizenSession? session,  OTPChallenge? challenge,  String? errorMessage,  Map<String, String> fieldErrors)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AuthState() when $default != null:
return $default(_that.status,_that.session,_that.challenge,_that.errorMessage,_that.fieldErrors);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( AuthStatus status,  CitizenSession? session,  OTPChallenge? challenge,  String? errorMessage,  Map<String, String> fieldErrors)  $default,) {final _that = this;
switch (_that) {
case _AuthState():
return $default(_that.status,_that.session,_that.challenge,_that.errorMessage,_that.fieldErrors);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( AuthStatus status,  CitizenSession? session,  OTPChallenge? challenge,  String? errorMessage,  Map<String, String> fieldErrors)?  $default,) {final _that = this;
switch (_that) {
case _AuthState() when $default != null:
return $default(_that.status,_that.session,_that.challenge,_that.errorMessage,_that.fieldErrors);case _:
  return null;

}
}

}

/// @nodoc


class _AuthState implements AuthState {
  const _AuthState({this.status = AuthStatus.initial, this.session, this.challenge, this.errorMessage, final  Map<String, String> fieldErrors = const <String, String>{}}): _fieldErrors = fieldErrors;
  

@override@JsonKey() final  AuthStatus status;
@override final  CitizenSession? session;
@override final  OTPChallenge? challenge;
@override final  String? errorMessage;
 final  Map<String, String> _fieldErrors;
@override@JsonKey() Map<String, String> get fieldErrors {
  if (_fieldErrors is EqualUnmodifiableMapView) return _fieldErrors;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_fieldErrors);
}


/// Create a copy of AuthState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AuthStateCopyWith<_AuthState> get copyWith => __$AuthStateCopyWithImpl<_AuthState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AuthState&&(identical(other.status, status) || other.status == status)&&(identical(other.session, session) || other.session == session)&&(identical(other.challenge, challenge) || other.challenge == challenge)&&(identical(other.errorMessage, errorMessage) || other.errorMessage == errorMessage)&&const DeepCollectionEquality().equals(other._fieldErrors, _fieldErrors));
}


@override
int get hashCode => Object.hash(runtimeType,status,session,challenge,errorMessage,const DeepCollectionEquality().hash(_fieldErrors));

@override
String toString() {
  return 'AuthState(status: $status, session: $session, challenge: $challenge, errorMessage: $errorMessage, fieldErrors: $fieldErrors)';
}


}

/// @nodoc
abstract mixin class _$AuthStateCopyWith<$Res> implements $AuthStateCopyWith<$Res> {
  factory _$AuthStateCopyWith(_AuthState value, $Res Function(_AuthState) _then) = __$AuthStateCopyWithImpl;
@override @useResult
$Res call({
 AuthStatus status, CitizenSession? session, OTPChallenge? challenge, String? errorMessage, Map<String, String> fieldErrors
});


@override $CitizenSessionCopyWith<$Res>? get session;@override $OTPChallengeCopyWith<$Res>? get challenge;

}
/// @nodoc
class __$AuthStateCopyWithImpl<$Res>
    implements _$AuthStateCopyWith<$Res> {
  __$AuthStateCopyWithImpl(this._self, this._then);

  final _AuthState _self;
  final $Res Function(_AuthState) _then;

/// Create a copy of AuthState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? status = null,Object? session = freezed,Object? challenge = freezed,Object? errorMessage = freezed,Object? fieldErrors = null,}) {
  return _then(_AuthState(
status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as AuthStatus,session: freezed == session ? _self.session : session // ignore: cast_nullable_to_non_nullable
as CitizenSession?,challenge: freezed == challenge ? _self.challenge : challenge // ignore: cast_nullable_to_non_nullable
as OTPChallenge?,errorMessage: freezed == errorMessage ? _self.errorMessage : errorMessage // ignore: cast_nullable_to_non_nullable
as String?,fieldErrors: null == fieldErrors ? _self._fieldErrors : fieldErrors // ignore: cast_nullable_to_non_nullable
as Map<String, String>,
  ));
}

/// Create a copy of AuthState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CitizenSessionCopyWith<$Res>? get session {
    if (_self.session == null) {
    return null;
  }

  return $CitizenSessionCopyWith<$Res>(_self.session!, (value) {
    return _then(_self.copyWith(session: value));
  });
}/// Create a copy of AuthState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$OTPChallengeCopyWith<$Res>? get challenge {
    if (_self.challenge == null) {
    return null;
  }

  return $OTPChallengeCopyWith<$Res>(_self.challenge!, (value) {
    return _then(_self.copyWith(challenge: value));
  });
}
}

// dart format on
