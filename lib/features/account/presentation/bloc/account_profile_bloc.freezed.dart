// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'account_profile_bloc.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$AccountProfileState {

 RegionStatus get status;/// `profileQuery.data` — `:193`. See the BLoC's doc for why there is no
/// `?? session.profile` fallback.
 CitizenProfile? get profile;/// `profileQuery.error.message` — `:384`, rendered **in preference to**
/// `c("profileError")`.
 String? get errorMessage;// ── The profile editor ─────────────────────────────────────────────────
/// `saveProfile.pending` — the Save button's `loading` prop (`:548`).
 bool get saving;/// `profileNote` — `:547`. Green text under the form.
 SaveOutcome get saveOutcome;/// `saveProfile.error.message` — `:545`. Red text under the form, above
/// the note.
 String? get saveError;/// `saveProfile.fieldErrors` — `:516`, `:530`. Keyed by the **wire** field
/// name (`name`, `email`), because that is what the 422 body names.
/// `address` is present in this map when the server sends it and is
/// **never rendered**, matching the source (B8-AC-49).
 Map<String, String> get fieldErrors;// ── The password form ──────────────────────────────────────────────────
/// `changePassword.pending` — `:703`.
 bool get changingPassword;/// The client-side rule that failed, if any.
 PasswordError get passwordError;/// `setPwError((err as Error).message)` — `:284`. The **server's** text.
 String? get passwordServerError;/// `pwNote` — `:702`. True after a success, and the widget's cue to clear
/// the three controllers (`setPw({current:"", next:"", confirm:""})`,
/// `:281`).
 bool get passwordChanged;
/// Create a copy of AccountProfileState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AccountProfileStateCopyWith<AccountProfileState> get copyWith => _$AccountProfileStateCopyWithImpl<AccountProfileState>(this as AccountProfileState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AccountProfileState&&(identical(other.status, status) || other.status == status)&&(identical(other.profile, profile) || other.profile == profile)&&(identical(other.errorMessage, errorMessage) || other.errorMessage == errorMessage)&&(identical(other.saving, saving) || other.saving == saving)&&(identical(other.saveOutcome, saveOutcome) || other.saveOutcome == saveOutcome)&&(identical(other.saveError, saveError) || other.saveError == saveError)&&const DeepCollectionEquality().equals(other.fieldErrors, fieldErrors)&&(identical(other.changingPassword, changingPassword) || other.changingPassword == changingPassword)&&(identical(other.passwordError, passwordError) || other.passwordError == passwordError)&&(identical(other.passwordServerError, passwordServerError) || other.passwordServerError == passwordServerError)&&(identical(other.passwordChanged, passwordChanged) || other.passwordChanged == passwordChanged));
}


@override
int get hashCode => Object.hash(runtimeType,status,profile,errorMessage,saving,saveOutcome,saveError,const DeepCollectionEquality().hash(fieldErrors),changingPassword,passwordError,passwordServerError,passwordChanged);

@override
String toString() {
  return 'AccountProfileState(status: $status, profile: $profile, errorMessage: $errorMessage, saving: $saving, saveOutcome: $saveOutcome, saveError: $saveError, fieldErrors: $fieldErrors, changingPassword: $changingPassword, passwordError: $passwordError, passwordServerError: $passwordServerError, passwordChanged: $passwordChanged)';
}


}

/// @nodoc
abstract mixin class $AccountProfileStateCopyWith<$Res>  {
  factory $AccountProfileStateCopyWith(AccountProfileState value, $Res Function(AccountProfileState) _then) = _$AccountProfileStateCopyWithImpl;
@useResult
$Res call({
 RegionStatus status, CitizenProfile? profile, String? errorMessage, bool saving, SaveOutcome saveOutcome, String? saveError, Map<String, String> fieldErrors, bool changingPassword, PasswordError passwordError, String? passwordServerError, bool passwordChanged
});


$CitizenProfileCopyWith<$Res>? get profile;

}
/// @nodoc
class _$AccountProfileStateCopyWithImpl<$Res>
    implements $AccountProfileStateCopyWith<$Res> {
  _$AccountProfileStateCopyWithImpl(this._self, this._then);

  final AccountProfileState _self;
  final $Res Function(AccountProfileState) _then;

/// Create a copy of AccountProfileState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? status = null,Object? profile = freezed,Object? errorMessage = freezed,Object? saving = null,Object? saveOutcome = null,Object? saveError = freezed,Object? fieldErrors = null,Object? changingPassword = null,Object? passwordError = null,Object? passwordServerError = freezed,Object? passwordChanged = null,}) {
  return _then(_self.copyWith(
status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as RegionStatus,profile: freezed == profile ? _self.profile : profile // ignore: cast_nullable_to_non_nullable
as CitizenProfile?,errorMessage: freezed == errorMessage ? _self.errorMessage : errorMessage // ignore: cast_nullable_to_non_nullable
as String?,saving: null == saving ? _self.saving : saving // ignore: cast_nullable_to_non_nullable
as bool,saveOutcome: null == saveOutcome ? _self.saveOutcome : saveOutcome // ignore: cast_nullable_to_non_nullable
as SaveOutcome,saveError: freezed == saveError ? _self.saveError : saveError // ignore: cast_nullable_to_non_nullable
as String?,fieldErrors: null == fieldErrors ? _self.fieldErrors : fieldErrors // ignore: cast_nullable_to_non_nullable
as Map<String, String>,changingPassword: null == changingPassword ? _self.changingPassword : changingPassword // ignore: cast_nullable_to_non_nullable
as bool,passwordError: null == passwordError ? _self.passwordError : passwordError // ignore: cast_nullable_to_non_nullable
as PasswordError,passwordServerError: freezed == passwordServerError ? _self.passwordServerError : passwordServerError // ignore: cast_nullable_to_non_nullable
as String?,passwordChanged: null == passwordChanged ? _self.passwordChanged : passwordChanged // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}
/// Create a copy of AccountProfileState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CitizenProfileCopyWith<$Res>? get profile {
    if (_self.profile == null) {
    return null;
  }

  return $CitizenProfileCopyWith<$Res>(_self.profile!, (value) {
    return _then(_self.copyWith(profile: value));
  });
}
}


/// Adds pattern-matching-related methods to [AccountProfileState].
extension AccountProfileStatePatterns on AccountProfileState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AccountProfileState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AccountProfileState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AccountProfileState value)  $default,){
final _that = this;
switch (_that) {
case _AccountProfileState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AccountProfileState value)?  $default,){
final _that = this;
switch (_that) {
case _AccountProfileState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( RegionStatus status,  CitizenProfile? profile,  String? errorMessage,  bool saving,  SaveOutcome saveOutcome,  String? saveError,  Map<String, String> fieldErrors,  bool changingPassword,  PasswordError passwordError,  String? passwordServerError,  bool passwordChanged)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AccountProfileState() when $default != null:
return $default(_that.status,_that.profile,_that.errorMessage,_that.saving,_that.saveOutcome,_that.saveError,_that.fieldErrors,_that.changingPassword,_that.passwordError,_that.passwordServerError,_that.passwordChanged);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( RegionStatus status,  CitizenProfile? profile,  String? errorMessage,  bool saving,  SaveOutcome saveOutcome,  String? saveError,  Map<String, String> fieldErrors,  bool changingPassword,  PasswordError passwordError,  String? passwordServerError,  bool passwordChanged)  $default,) {final _that = this;
switch (_that) {
case _AccountProfileState():
return $default(_that.status,_that.profile,_that.errorMessage,_that.saving,_that.saveOutcome,_that.saveError,_that.fieldErrors,_that.changingPassword,_that.passwordError,_that.passwordServerError,_that.passwordChanged);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( RegionStatus status,  CitizenProfile? profile,  String? errorMessage,  bool saving,  SaveOutcome saveOutcome,  String? saveError,  Map<String, String> fieldErrors,  bool changingPassword,  PasswordError passwordError,  String? passwordServerError,  bool passwordChanged)?  $default,) {final _that = this;
switch (_that) {
case _AccountProfileState() when $default != null:
return $default(_that.status,_that.profile,_that.errorMessage,_that.saving,_that.saveOutcome,_that.saveError,_that.fieldErrors,_that.changingPassword,_that.passwordError,_that.passwordServerError,_that.passwordChanged);case _:
  return null;

}
}

}

/// @nodoc


class _AccountProfileState extends AccountProfileState {
  const _AccountProfileState({this.status = RegionStatus.initial, this.profile, this.errorMessage, this.saving = false, this.saveOutcome = SaveOutcome.none, this.saveError, final  Map<String, String> fieldErrors = const <String, String>{}, this.changingPassword = false, this.passwordError = PasswordError.none, this.passwordServerError, this.passwordChanged = false}): _fieldErrors = fieldErrors,super._();
  

@override@JsonKey() final  RegionStatus status;
/// `profileQuery.data` — `:193`. See the BLoC's doc for why there is no
/// `?? session.profile` fallback.
@override final  CitizenProfile? profile;
/// `profileQuery.error.message` — `:384`, rendered **in preference to**
/// `c("profileError")`.
@override final  String? errorMessage;
// ── The profile editor ─────────────────────────────────────────────────
/// `saveProfile.pending` — the Save button's `loading` prop (`:548`).
@override@JsonKey() final  bool saving;
/// `profileNote` — `:547`. Green text under the form.
@override@JsonKey() final  SaveOutcome saveOutcome;
/// `saveProfile.error.message` — `:545`. Red text under the form, above
/// the note.
@override final  String? saveError;
/// `saveProfile.fieldErrors` — `:516`, `:530`. Keyed by the **wire** field
/// name (`name`, `email`), because that is what the 422 body names.
/// `address` is present in this map when the server sends it and is
/// **never rendered**, matching the source (B8-AC-49).
 final  Map<String, String> _fieldErrors;
/// `saveProfile.fieldErrors` — `:516`, `:530`. Keyed by the **wire** field
/// name (`name`, `email`), because that is what the 422 body names.
/// `address` is present in this map when the server sends it and is
/// **never rendered**, matching the source (B8-AC-49).
@override@JsonKey() Map<String, String> get fieldErrors {
  if (_fieldErrors is EqualUnmodifiableMapView) return _fieldErrors;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_fieldErrors);
}

// ── The password form ──────────────────────────────────────────────────
/// `changePassword.pending` — `:703`.
@override@JsonKey() final  bool changingPassword;
/// The client-side rule that failed, if any.
@override@JsonKey() final  PasswordError passwordError;
/// `setPwError((err as Error).message)` — `:284`. The **server's** text.
@override final  String? passwordServerError;
/// `pwNote` — `:702`. True after a success, and the widget's cue to clear
/// the three controllers (`setPw({current:"", next:"", confirm:""})`,
/// `:281`).
@override@JsonKey() final  bool passwordChanged;

/// Create a copy of AccountProfileState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AccountProfileStateCopyWith<_AccountProfileState> get copyWith => __$AccountProfileStateCopyWithImpl<_AccountProfileState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AccountProfileState&&(identical(other.status, status) || other.status == status)&&(identical(other.profile, profile) || other.profile == profile)&&(identical(other.errorMessage, errorMessage) || other.errorMessage == errorMessage)&&(identical(other.saving, saving) || other.saving == saving)&&(identical(other.saveOutcome, saveOutcome) || other.saveOutcome == saveOutcome)&&(identical(other.saveError, saveError) || other.saveError == saveError)&&const DeepCollectionEquality().equals(other._fieldErrors, _fieldErrors)&&(identical(other.changingPassword, changingPassword) || other.changingPassword == changingPassword)&&(identical(other.passwordError, passwordError) || other.passwordError == passwordError)&&(identical(other.passwordServerError, passwordServerError) || other.passwordServerError == passwordServerError)&&(identical(other.passwordChanged, passwordChanged) || other.passwordChanged == passwordChanged));
}


@override
int get hashCode => Object.hash(runtimeType,status,profile,errorMessage,saving,saveOutcome,saveError,const DeepCollectionEquality().hash(_fieldErrors),changingPassword,passwordError,passwordServerError,passwordChanged);

@override
String toString() {
  return 'AccountProfileState(status: $status, profile: $profile, errorMessage: $errorMessage, saving: $saving, saveOutcome: $saveOutcome, saveError: $saveError, fieldErrors: $fieldErrors, changingPassword: $changingPassword, passwordError: $passwordError, passwordServerError: $passwordServerError, passwordChanged: $passwordChanged)';
}


}

/// @nodoc
abstract mixin class _$AccountProfileStateCopyWith<$Res> implements $AccountProfileStateCopyWith<$Res> {
  factory _$AccountProfileStateCopyWith(_AccountProfileState value, $Res Function(_AccountProfileState) _then) = __$AccountProfileStateCopyWithImpl;
@override @useResult
$Res call({
 RegionStatus status, CitizenProfile? profile, String? errorMessage, bool saving, SaveOutcome saveOutcome, String? saveError, Map<String, String> fieldErrors, bool changingPassword, PasswordError passwordError, String? passwordServerError, bool passwordChanged
});


@override $CitizenProfileCopyWith<$Res>? get profile;

}
/// @nodoc
class __$AccountProfileStateCopyWithImpl<$Res>
    implements _$AccountProfileStateCopyWith<$Res> {
  __$AccountProfileStateCopyWithImpl(this._self, this._then);

  final _AccountProfileState _self;
  final $Res Function(_AccountProfileState) _then;

/// Create a copy of AccountProfileState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? status = null,Object? profile = freezed,Object? errorMessage = freezed,Object? saving = null,Object? saveOutcome = null,Object? saveError = freezed,Object? fieldErrors = null,Object? changingPassword = null,Object? passwordError = null,Object? passwordServerError = freezed,Object? passwordChanged = null,}) {
  return _then(_AccountProfileState(
status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as RegionStatus,profile: freezed == profile ? _self.profile : profile // ignore: cast_nullable_to_non_nullable
as CitizenProfile?,errorMessage: freezed == errorMessage ? _self.errorMessage : errorMessage // ignore: cast_nullable_to_non_nullable
as String?,saving: null == saving ? _self.saving : saving // ignore: cast_nullable_to_non_nullable
as bool,saveOutcome: null == saveOutcome ? _self.saveOutcome : saveOutcome // ignore: cast_nullable_to_non_nullable
as SaveOutcome,saveError: freezed == saveError ? _self.saveError : saveError // ignore: cast_nullable_to_non_nullable
as String?,fieldErrors: null == fieldErrors ? _self._fieldErrors : fieldErrors // ignore: cast_nullable_to_non_nullable
as Map<String, String>,changingPassword: null == changingPassword ? _self.changingPassword : changingPassword // ignore: cast_nullable_to_non_nullable
as bool,passwordError: null == passwordError ? _self.passwordError : passwordError // ignore: cast_nullable_to_non_nullable
as PasswordError,passwordServerError: freezed == passwordServerError ? _self.passwordServerError : passwordServerError // ignore: cast_nullable_to_non_nullable
as String?,passwordChanged: null == passwordChanged ? _self.passwordChanged : passwordChanged // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

/// Create a copy of AccountProfileState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CitizenProfileCopyWith<$Res>? get profile {
    if (_self.profile == null) {
    return null;
  }

  return $CitizenProfileCopyWith<$Res>(_self.profile!, (value) {
    return _then(_self.copyWith(profile: value));
  });
}
}

// dart format on
