// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'account_preferences_bloc.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$AccountPreferencesState {

 RegionStatus get status;/// `prefsQuery.data` — `AccountPage.tsx:195`. Null until the first
/// successful read, which is what `if (!prefs) return` and the `{prefs &&
/// …}` render guards at `:581`, `:662` both test.
 CitizenPreferences? get preferences;/// `prefsQuery.error.message` — `:575`. Rendered raw, with **no local
/// fallback string**: unlike the documents card (`:409`), the preferences
/// panel has no `c("prefsError")` to fall back to. Ported as measured; an
/// error with an empty message renders an empty paragraph in the web too.
 String? get errorMessage;/// `savePrefs.pending` — `hooks.ts`' `useMutation`. Nothing in the source
/// renders it for this mutation (the toggles have no busy state), so it is
/// carried to keep the two states distinguishable in a test rather than to
/// draw anything.
 bool get saving;/// `savePrefs.error.message` — `:600`. A **separate** slot from
/// [errorMessage]: the source renders the read's error above the switches
/// and the write's error below them, and one can be set while the other is
/// not.
 String? get saveError;
/// Create a copy of AccountPreferencesState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AccountPreferencesStateCopyWith<AccountPreferencesState> get copyWith => _$AccountPreferencesStateCopyWithImpl<AccountPreferencesState>(this as AccountPreferencesState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AccountPreferencesState&&(identical(other.status, status) || other.status == status)&&(identical(other.preferences, preferences) || other.preferences == preferences)&&(identical(other.errorMessage, errorMessage) || other.errorMessage == errorMessage)&&(identical(other.saving, saving) || other.saving == saving)&&(identical(other.saveError, saveError) || other.saveError == saveError));
}


@override
int get hashCode => Object.hash(runtimeType,status,preferences,errorMessage,saving,saveError);

@override
String toString() {
  return 'AccountPreferencesState(status: $status, preferences: $preferences, errorMessage: $errorMessage, saving: $saving, saveError: $saveError)';
}


}

/// @nodoc
abstract mixin class $AccountPreferencesStateCopyWith<$Res>  {
  factory $AccountPreferencesStateCopyWith(AccountPreferencesState value, $Res Function(AccountPreferencesState) _then) = _$AccountPreferencesStateCopyWithImpl;
@useResult
$Res call({
 RegionStatus status, CitizenPreferences? preferences, String? errorMessage, bool saving, String? saveError
});


$CitizenPreferencesCopyWith<$Res>? get preferences;

}
/// @nodoc
class _$AccountPreferencesStateCopyWithImpl<$Res>
    implements $AccountPreferencesStateCopyWith<$Res> {
  _$AccountPreferencesStateCopyWithImpl(this._self, this._then);

  final AccountPreferencesState _self;
  final $Res Function(AccountPreferencesState) _then;

/// Create a copy of AccountPreferencesState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? status = null,Object? preferences = freezed,Object? errorMessage = freezed,Object? saving = null,Object? saveError = freezed,}) {
  return _then(_self.copyWith(
status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as RegionStatus,preferences: freezed == preferences ? _self.preferences : preferences // ignore: cast_nullable_to_non_nullable
as CitizenPreferences?,errorMessage: freezed == errorMessage ? _self.errorMessage : errorMessage // ignore: cast_nullable_to_non_nullable
as String?,saving: null == saving ? _self.saving : saving // ignore: cast_nullable_to_non_nullable
as bool,saveError: freezed == saveError ? _self.saveError : saveError // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}
/// Create a copy of AccountPreferencesState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CitizenPreferencesCopyWith<$Res>? get preferences {
    if (_self.preferences == null) {
    return null;
  }

  return $CitizenPreferencesCopyWith<$Res>(_self.preferences!, (value) {
    return _then(_self.copyWith(preferences: value));
  });
}
}


/// Adds pattern-matching-related methods to [AccountPreferencesState].
extension AccountPreferencesStatePatterns on AccountPreferencesState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AccountPreferencesState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AccountPreferencesState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AccountPreferencesState value)  $default,){
final _that = this;
switch (_that) {
case _AccountPreferencesState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AccountPreferencesState value)?  $default,){
final _that = this;
switch (_that) {
case _AccountPreferencesState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( RegionStatus status,  CitizenPreferences? preferences,  String? errorMessage,  bool saving,  String? saveError)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AccountPreferencesState() when $default != null:
return $default(_that.status,_that.preferences,_that.errorMessage,_that.saving,_that.saveError);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( RegionStatus status,  CitizenPreferences? preferences,  String? errorMessage,  bool saving,  String? saveError)  $default,) {final _that = this;
switch (_that) {
case _AccountPreferencesState():
return $default(_that.status,_that.preferences,_that.errorMessage,_that.saving,_that.saveError);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( RegionStatus status,  CitizenPreferences? preferences,  String? errorMessage,  bool saving,  String? saveError)?  $default,) {final _that = this;
switch (_that) {
case _AccountPreferencesState() when $default != null:
return $default(_that.status,_that.preferences,_that.errorMessage,_that.saving,_that.saveError);case _:
  return null;

}
}

}

/// @nodoc


class _AccountPreferencesState extends AccountPreferencesState {
  const _AccountPreferencesState({this.status = RegionStatus.initial, this.preferences, this.errorMessage, this.saving = false, this.saveError}): super._();
  

@override@JsonKey() final  RegionStatus status;
/// `prefsQuery.data` — `AccountPage.tsx:195`. Null until the first
/// successful read, which is what `if (!prefs) return` and the `{prefs &&
/// …}` render guards at `:581`, `:662` both test.
@override final  CitizenPreferences? preferences;
/// `prefsQuery.error.message` — `:575`. Rendered raw, with **no local
/// fallback string**: unlike the documents card (`:409`), the preferences
/// panel has no `c("prefsError")` to fall back to. Ported as measured; an
/// error with an empty message renders an empty paragraph in the web too.
@override final  String? errorMessage;
/// `savePrefs.pending` — `hooks.ts`' `useMutation`. Nothing in the source
/// renders it for this mutation (the toggles have no busy state), so it is
/// carried to keep the two states distinguishable in a test rather than to
/// draw anything.
@override@JsonKey() final  bool saving;
/// `savePrefs.error.message` — `:600`. A **separate** slot from
/// [errorMessage]: the source renders the read's error above the switches
/// and the write's error below them, and one can be set while the other is
/// not.
@override final  String? saveError;

/// Create a copy of AccountPreferencesState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AccountPreferencesStateCopyWith<_AccountPreferencesState> get copyWith => __$AccountPreferencesStateCopyWithImpl<_AccountPreferencesState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AccountPreferencesState&&(identical(other.status, status) || other.status == status)&&(identical(other.preferences, preferences) || other.preferences == preferences)&&(identical(other.errorMessage, errorMessage) || other.errorMessage == errorMessage)&&(identical(other.saving, saving) || other.saving == saving)&&(identical(other.saveError, saveError) || other.saveError == saveError));
}


@override
int get hashCode => Object.hash(runtimeType,status,preferences,errorMessage,saving,saveError);

@override
String toString() {
  return 'AccountPreferencesState(status: $status, preferences: $preferences, errorMessage: $errorMessage, saving: $saving, saveError: $saveError)';
}


}

/// @nodoc
abstract mixin class _$AccountPreferencesStateCopyWith<$Res> implements $AccountPreferencesStateCopyWith<$Res> {
  factory _$AccountPreferencesStateCopyWith(_AccountPreferencesState value, $Res Function(_AccountPreferencesState) _then) = __$AccountPreferencesStateCopyWithImpl;
@override @useResult
$Res call({
 RegionStatus status, CitizenPreferences? preferences, String? errorMessage, bool saving, String? saveError
});


@override $CitizenPreferencesCopyWith<$Res>? get preferences;

}
/// @nodoc
class __$AccountPreferencesStateCopyWithImpl<$Res>
    implements _$AccountPreferencesStateCopyWith<$Res> {
  __$AccountPreferencesStateCopyWithImpl(this._self, this._then);

  final _AccountPreferencesState _self;
  final $Res Function(_AccountPreferencesState) _then;

/// Create a copy of AccountPreferencesState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? status = null,Object? preferences = freezed,Object? errorMessage = freezed,Object? saving = null,Object? saveError = freezed,}) {
  return _then(_AccountPreferencesState(
status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as RegionStatus,preferences: freezed == preferences ? _self.preferences : preferences // ignore: cast_nullable_to_non_nullable
as CitizenPreferences?,errorMessage: freezed == errorMessage ? _self.errorMessage : errorMessage // ignore: cast_nullable_to_non_nullable
as String?,saving: null == saving ? _self.saving : saving // ignore: cast_nullable_to_non_nullable
as bool,saveError: freezed == saveError ? _self.saveError : saveError // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

/// Create a copy of AccountPreferencesState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CitizenPreferencesCopyWith<$Res>? get preferences {
    if (_self.preferences == null) {
    return null;
  }

  return $CitizenPreferencesCopyWith<$Res>(_self.preferences!, (value) {
    return _then(_self.copyWith(preferences: value));
  });
}
}

// dart format on
