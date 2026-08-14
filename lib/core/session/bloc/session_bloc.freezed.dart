// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'session_bloc.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$SessionEvent implements DiagnosticableTreeMixin {




@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
  properties
    ..add(DiagnosticsProperty('type', 'SessionEvent'))
    ;
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SessionEvent);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
  return 'SessionEvent()';
}


}

/// @nodoc
class $SessionEventCopyWith<$Res>  {
$SessionEventCopyWith(SessionEvent _, $Res Function(SessionEvent) __);
}


/// Adds pattern-matching-related methods to [SessionEvent].
extension SessionEventPatterns on SessionEvent {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( SessionStarted value)?  started,TResult Function( SessionSignIn value)?  signIn,TResult Function( SessionSignOut value)?  signOut,TResult Function( SessionRefreshProfile value)?  refreshProfile,TResult Function( SessionMirrorLanguage value)?  mirrorLanguage,required TResult orElse(),}){
final _that = this;
switch (_that) {
case SessionStarted() when started != null:
return started(_that);case SessionSignIn() when signIn != null:
return signIn(_that);case SessionSignOut() when signOut != null:
return signOut(_that);case SessionRefreshProfile() when refreshProfile != null:
return refreshProfile(_that);case SessionMirrorLanguage() when mirrorLanguage != null:
return mirrorLanguage(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( SessionStarted value)  started,required TResult Function( SessionSignIn value)  signIn,required TResult Function( SessionSignOut value)  signOut,required TResult Function( SessionRefreshProfile value)  refreshProfile,required TResult Function( SessionMirrorLanguage value)  mirrorLanguage,}){
final _that = this;
switch (_that) {
case SessionStarted():
return started(_that);case SessionSignIn():
return signIn(_that);case SessionSignOut():
return signOut(_that);case SessionRefreshProfile():
return refreshProfile(_that);case SessionMirrorLanguage():
return mirrorLanguage(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( SessionStarted value)?  started,TResult? Function( SessionSignIn value)?  signIn,TResult? Function( SessionSignOut value)?  signOut,TResult? Function( SessionRefreshProfile value)?  refreshProfile,TResult? Function( SessionMirrorLanguage value)?  mirrorLanguage,}){
final _that = this;
switch (_that) {
case SessionStarted() when started != null:
return started(_that);case SessionSignIn() when signIn != null:
return signIn(_that);case SessionSignOut() when signOut != null:
return signOut(_that);case SessionRefreshProfile() when refreshProfile != null:
return refreshProfile(_that);case SessionMirrorLanguage() when mirrorLanguage != null:
return mirrorLanguage(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  started,TResult Function( CitizenSession session)?  signIn,TResult Function()?  signOut,TResult Function()?  refreshProfile,TResult Function( String languageCode)?  mirrorLanguage,required TResult orElse(),}) {final _that = this;
switch (_that) {
case SessionStarted() when started != null:
return started();case SessionSignIn() when signIn != null:
return signIn(_that.session);case SessionSignOut() when signOut != null:
return signOut();case SessionRefreshProfile() when refreshProfile != null:
return refreshProfile();case SessionMirrorLanguage() when mirrorLanguage != null:
return mirrorLanguage(_that.languageCode);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  started,required TResult Function( CitizenSession session)  signIn,required TResult Function()  signOut,required TResult Function()  refreshProfile,required TResult Function( String languageCode)  mirrorLanguage,}) {final _that = this;
switch (_that) {
case SessionStarted():
return started();case SessionSignIn():
return signIn(_that.session);case SessionSignOut():
return signOut();case SessionRefreshProfile():
return refreshProfile();case SessionMirrorLanguage():
return mirrorLanguage(_that.languageCode);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  started,TResult? Function( CitizenSession session)?  signIn,TResult? Function()?  signOut,TResult? Function()?  refreshProfile,TResult? Function( String languageCode)?  mirrorLanguage,}) {final _that = this;
switch (_that) {
case SessionStarted() when started != null:
return started();case SessionSignIn() when signIn != null:
return signIn(_that.session);case SessionSignOut() when signOut != null:
return signOut();case SessionRefreshProfile() when refreshProfile != null:
return refreshProfile();case SessionMirrorLanguage() when mirrorLanguage != null:
return mirrorLanguage(_that.languageCode);case _:
  return null;

}
}

}

/// @nodoc


class SessionStarted with DiagnosticableTreeMixin implements SessionEvent {
  const SessionStarted();
  





@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
  properties
    ..add(DiagnosticsProperty('type', 'SessionEvent.started'))
    ;
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SessionStarted);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
  return 'SessionEvent.started()';
}


}




/// @nodoc


class SessionSignIn with DiagnosticableTreeMixin implements SessionEvent {
  const SessionSignIn(this.session);
  

 final  CitizenSession session;

/// Create a copy of SessionEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SessionSignInCopyWith<SessionSignIn> get copyWith => _$SessionSignInCopyWithImpl<SessionSignIn>(this, _$identity);


@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
  properties
    ..add(DiagnosticsProperty('type', 'SessionEvent.signIn'))
    ..add(DiagnosticsProperty('session', session));
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SessionSignIn&&(identical(other.session, session) || other.session == session));
}


@override
int get hashCode => Object.hash(runtimeType,session);

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
  return 'SessionEvent.signIn(session: $session)';
}


}

/// @nodoc
abstract mixin class $SessionSignInCopyWith<$Res> implements $SessionEventCopyWith<$Res> {
  factory $SessionSignInCopyWith(SessionSignIn value, $Res Function(SessionSignIn) _then) = _$SessionSignInCopyWithImpl;
@useResult
$Res call({
 CitizenSession session
});


$CitizenSessionCopyWith<$Res> get session;

}
/// @nodoc
class _$SessionSignInCopyWithImpl<$Res>
    implements $SessionSignInCopyWith<$Res> {
  _$SessionSignInCopyWithImpl(this._self, this._then);

  final SessionSignIn _self;
  final $Res Function(SessionSignIn) _then;

/// Create a copy of SessionEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? session = null,}) {
  return _then(SessionSignIn(
null == session ? _self.session : session // ignore: cast_nullable_to_non_nullable
as CitizenSession,
  ));
}

/// Create a copy of SessionEvent
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CitizenSessionCopyWith<$Res> get session {
  
  return $CitizenSessionCopyWith<$Res>(_self.session, (value) {
    return _then(_self.copyWith(session: value));
  });
}
}

/// @nodoc


class SessionSignOut with DiagnosticableTreeMixin implements SessionEvent {
  const SessionSignOut();
  





@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
  properties
    ..add(DiagnosticsProperty('type', 'SessionEvent.signOut'))
    ;
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SessionSignOut);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
  return 'SessionEvent.signOut()';
}


}




/// @nodoc


class SessionRefreshProfile with DiagnosticableTreeMixin implements SessionEvent {
  const SessionRefreshProfile();
  





@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
  properties
    ..add(DiagnosticsProperty('type', 'SessionEvent.refreshProfile'))
    ;
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SessionRefreshProfile);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
  return 'SessionEvent.refreshProfile()';
}


}




/// @nodoc


class SessionMirrorLanguage with DiagnosticableTreeMixin implements SessionEvent {
  const SessionMirrorLanguage(this.languageCode);
  

 final  String languageCode;

/// Create a copy of SessionEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SessionMirrorLanguageCopyWith<SessionMirrorLanguage> get copyWith => _$SessionMirrorLanguageCopyWithImpl<SessionMirrorLanguage>(this, _$identity);


@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
  properties
    ..add(DiagnosticsProperty('type', 'SessionEvent.mirrorLanguage'))
    ..add(DiagnosticsProperty('languageCode', languageCode));
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SessionMirrorLanguage&&(identical(other.languageCode, languageCode) || other.languageCode == languageCode));
}


@override
int get hashCode => Object.hash(runtimeType,languageCode);

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
  return 'SessionEvent.mirrorLanguage(languageCode: $languageCode)';
}


}

/// @nodoc
abstract mixin class $SessionMirrorLanguageCopyWith<$Res> implements $SessionEventCopyWith<$Res> {
  factory $SessionMirrorLanguageCopyWith(SessionMirrorLanguage value, $Res Function(SessionMirrorLanguage) _then) = _$SessionMirrorLanguageCopyWithImpl;
@useResult
$Res call({
 String languageCode
});




}
/// @nodoc
class _$SessionMirrorLanguageCopyWithImpl<$Res>
    implements $SessionMirrorLanguageCopyWith<$Res> {
  _$SessionMirrorLanguageCopyWithImpl(this._self, this._then);

  final SessionMirrorLanguage _self;
  final $Res Function(SessionMirrorLanguage) _then;

/// Create a copy of SessionEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? languageCode = null,}) {
  return _then(SessionMirrorLanguage(
null == languageCode ? _self.languageCode : languageCode // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc
mixin _$SessionState implements DiagnosticableTreeMixin {

 SessionStatus get status; CitizenProfileData? get profile; String? get errorMessage;
/// Create a copy of SessionState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SessionStateCopyWith<SessionState> get copyWith => _$SessionStateCopyWithImpl<SessionState>(this as SessionState, _$identity);


@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
  properties
    ..add(DiagnosticsProperty('type', 'SessionState'))
    ..add(DiagnosticsProperty('status', status))..add(DiagnosticsProperty('profile', profile))..add(DiagnosticsProperty('errorMessage', errorMessage));
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SessionState&&(identical(other.status, status) || other.status == status)&&(identical(other.profile, profile) || other.profile == profile)&&(identical(other.errorMessage, errorMessage) || other.errorMessage == errorMessage));
}


@override
int get hashCode => Object.hash(runtimeType,status,profile,errorMessage);

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
  return 'SessionState(status: $status, profile: $profile, errorMessage: $errorMessage)';
}


}

/// @nodoc
abstract mixin class $SessionStateCopyWith<$Res>  {
  factory $SessionStateCopyWith(SessionState value, $Res Function(SessionState) _then) = _$SessionStateCopyWithImpl;
@useResult
$Res call({
 SessionStatus status, CitizenProfileData? profile, String? errorMessage
});


$CitizenProfileDataCopyWith<$Res>? get profile;

}
/// @nodoc
class _$SessionStateCopyWithImpl<$Res>
    implements $SessionStateCopyWith<$Res> {
  _$SessionStateCopyWithImpl(this._self, this._then);

  final SessionState _self;
  final $Res Function(SessionState) _then;

/// Create a copy of SessionState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? status = null,Object? profile = freezed,Object? errorMessage = freezed,}) {
  return _then(_self.copyWith(
status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as SessionStatus,profile: freezed == profile ? _self.profile : profile // ignore: cast_nullable_to_non_nullable
as CitizenProfileData?,errorMessage: freezed == errorMessage ? _self.errorMessage : errorMessage // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}
/// Create a copy of SessionState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CitizenProfileDataCopyWith<$Res>? get profile {
    if (_self.profile == null) {
    return null;
  }

  return $CitizenProfileDataCopyWith<$Res>(_self.profile!, (value) {
    return _then(_self.copyWith(profile: value));
  });
}
}


/// Adds pattern-matching-related methods to [SessionState].
extension SessionStatePatterns on SessionState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SessionState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SessionState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SessionState value)  $default,){
final _that = this;
switch (_that) {
case _SessionState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SessionState value)?  $default,){
final _that = this;
switch (_that) {
case _SessionState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( SessionStatus status,  CitizenProfileData? profile,  String? errorMessage)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SessionState() when $default != null:
return $default(_that.status,_that.profile,_that.errorMessage);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( SessionStatus status,  CitizenProfileData? profile,  String? errorMessage)  $default,) {final _that = this;
switch (_that) {
case _SessionState():
return $default(_that.status,_that.profile,_that.errorMessage);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( SessionStatus status,  CitizenProfileData? profile,  String? errorMessage)?  $default,) {final _that = this;
switch (_that) {
case _SessionState() when $default != null:
return $default(_that.status,_that.profile,_that.errorMessage);case _:
  return null;

}
}

}

/// @nodoc


class _SessionState with DiagnosticableTreeMixin implements SessionState {
  const _SessionState({this.status = SessionStatus.initial, this.profile, this.errorMessage});
  

@override@JsonKey() final  SessionStatus status;
@override final  CitizenProfileData? profile;
@override final  String? errorMessage;

/// Create a copy of SessionState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SessionStateCopyWith<_SessionState> get copyWith => __$SessionStateCopyWithImpl<_SessionState>(this, _$identity);


@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
  properties
    ..add(DiagnosticsProperty('type', 'SessionState'))
    ..add(DiagnosticsProperty('status', status))..add(DiagnosticsProperty('profile', profile))..add(DiagnosticsProperty('errorMessage', errorMessage));
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SessionState&&(identical(other.status, status) || other.status == status)&&(identical(other.profile, profile) || other.profile == profile)&&(identical(other.errorMessage, errorMessage) || other.errorMessage == errorMessage));
}


@override
int get hashCode => Object.hash(runtimeType,status,profile,errorMessage);

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
  return 'SessionState(status: $status, profile: $profile, errorMessage: $errorMessage)';
}


}

/// @nodoc
abstract mixin class _$SessionStateCopyWith<$Res> implements $SessionStateCopyWith<$Res> {
  factory _$SessionStateCopyWith(_SessionState value, $Res Function(_SessionState) _then) = __$SessionStateCopyWithImpl;
@override @useResult
$Res call({
 SessionStatus status, CitizenProfileData? profile, String? errorMessage
});


@override $CitizenProfileDataCopyWith<$Res>? get profile;

}
/// @nodoc
class __$SessionStateCopyWithImpl<$Res>
    implements _$SessionStateCopyWith<$Res> {
  __$SessionStateCopyWithImpl(this._self, this._then);

  final _SessionState _self;
  final $Res Function(_SessionState) _then;

/// Create a copy of SessionState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? status = null,Object? profile = freezed,Object? errorMessage = freezed,}) {
  return _then(_SessionState(
status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as SessionStatus,profile: freezed == profile ? _self.profile : profile // ignore: cast_nullable_to_non_nullable
as CitizenProfileData?,errorMessage: freezed == errorMessage ? _self.errorMessage : errorMessage // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

/// Create a copy of SessionState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CitizenProfileDataCopyWith<$Res>? get profile {
    if (_self.profile == null) {
    return null;
  }

  return $CitizenProfileDataCopyWith<$Res>(_self.profile!, (value) {
    return _then(_self.copyWith(profile: value));
  });
}
}

/// @nodoc
mixin _$CitizenProfileData implements DiagnosticableTreeMixin {

 String get name; String get avatarUrl;
/// Create a copy of CitizenProfileData
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CitizenProfileDataCopyWith<CitizenProfileData> get copyWith => _$CitizenProfileDataCopyWithImpl<CitizenProfileData>(this as CitizenProfileData, _$identity);


@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
  properties
    ..add(DiagnosticsProperty('type', 'CitizenProfileData'))
    ..add(DiagnosticsProperty('name', name))..add(DiagnosticsProperty('avatarUrl', avatarUrl));
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CitizenProfileData&&(identical(other.name, name) || other.name == name)&&(identical(other.avatarUrl, avatarUrl) || other.avatarUrl == avatarUrl));
}


@override
int get hashCode => Object.hash(runtimeType,name,avatarUrl);

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
  return 'CitizenProfileData(name: $name, avatarUrl: $avatarUrl)';
}


}

/// @nodoc
abstract mixin class $CitizenProfileDataCopyWith<$Res>  {
  factory $CitizenProfileDataCopyWith(CitizenProfileData value, $Res Function(CitizenProfileData) _then) = _$CitizenProfileDataCopyWithImpl;
@useResult
$Res call({
 String name, String avatarUrl
});




}
/// @nodoc
class _$CitizenProfileDataCopyWithImpl<$Res>
    implements $CitizenProfileDataCopyWith<$Res> {
  _$CitizenProfileDataCopyWithImpl(this._self, this._then);

  final CitizenProfileData _self;
  final $Res Function(CitizenProfileData) _then;

/// Create a copy of CitizenProfileData
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? name = null,Object? avatarUrl = null,}) {
  return _then(_self.copyWith(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,avatarUrl: null == avatarUrl ? _self.avatarUrl : avatarUrl // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [CitizenProfileData].
extension CitizenProfileDataPatterns on CitizenProfileData {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CitizenProfileData value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CitizenProfileData() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CitizenProfileData value)  $default,){
final _that = this;
switch (_that) {
case _CitizenProfileData():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CitizenProfileData value)?  $default,){
final _that = this;
switch (_that) {
case _CitizenProfileData() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String name,  String avatarUrl)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CitizenProfileData() when $default != null:
return $default(_that.name,_that.avatarUrl);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String name,  String avatarUrl)  $default,) {final _that = this;
switch (_that) {
case _CitizenProfileData():
return $default(_that.name,_that.avatarUrl);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String name,  String avatarUrl)?  $default,) {final _that = this;
switch (_that) {
case _CitizenProfileData() when $default != null:
return $default(_that.name,_that.avatarUrl);case _:
  return null;

}
}

}

/// @nodoc


class _CitizenProfileData with DiagnosticableTreeMixin implements CitizenProfileData {
  const _CitizenProfileData({required this.name, required this.avatarUrl});
  

@override final  String name;
@override final  String avatarUrl;

/// Create a copy of CitizenProfileData
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CitizenProfileDataCopyWith<_CitizenProfileData> get copyWith => __$CitizenProfileDataCopyWithImpl<_CitizenProfileData>(this, _$identity);


@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
  properties
    ..add(DiagnosticsProperty('type', 'CitizenProfileData'))
    ..add(DiagnosticsProperty('name', name))..add(DiagnosticsProperty('avatarUrl', avatarUrl));
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CitizenProfileData&&(identical(other.name, name) || other.name == name)&&(identical(other.avatarUrl, avatarUrl) || other.avatarUrl == avatarUrl));
}


@override
int get hashCode => Object.hash(runtimeType,name,avatarUrl);

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
  return 'CitizenProfileData(name: $name, avatarUrl: $avatarUrl)';
}


}

/// @nodoc
abstract mixin class _$CitizenProfileDataCopyWith<$Res> implements $CitizenProfileDataCopyWith<$Res> {
  factory _$CitizenProfileDataCopyWith(_CitizenProfileData value, $Res Function(_CitizenProfileData) _then) = __$CitizenProfileDataCopyWithImpl;
@override @useResult
$Res call({
 String name, String avatarUrl
});




}
/// @nodoc
class __$CitizenProfileDataCopyWithImpl<$Res>
    implements _$CitizenProfileDataCopyWith<$Res> {
  __$CitizenProfileDataCopyWithImpl(this._self, this._then);

  final _CitizenProfileData _self;
  final $Res Function(_CitizenProfileData) _then;

/// Create a copy of CitizenProfileData
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? name = null,Object? avatarUrl = null,}) {
  return _then(_CitizenProfileData(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,avatarUrl: null == avatarUrl ? _self.avatarUrl : avatarUrl // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
