// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'citizen_preferences.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$NotificationPreferences {

 bool get inApp; bool get email; bool get sms;
/// Create a copy of NotificationPreferences
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$NotificationPreferencesCopyWith<NotificationPreferences> get copyWith => _$NotificationPreferencesCopyWithImpl<NotificationPreferences>(this as NotificationPreferences, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is NotificationPreferences&&(identical(other.inApp, inApp) || other.inApp == inApp)&&(identical(other.email, email) || other.email == email)&&(identical(other.sms, sms) || other.sms == sms));
}


@override
int get hashCode => Object.hash(runtimeType,inApp,email,sms);

@override
String toString() {
  return 'NotificationPreferences(inApp: $inApp, email: $email, sms: $sms)';
}


}

/// @nodoc
abstract mixin class $NotificationPreferencesCopyWith<$Res>  {
  factory $NotificationPreferencesCopyWith(NotificationPreferences value, $Res Function(NotificationPreferences) _then) = _$NotificationPreferencesCopyWithImpl;
@useResult
$Res call({
 bool inApp, bool email, bool sms
});




}
/// @nodoc
class _$NotificationPreferencesCopyWithImpl<$Res>
    implements $NotificationPreferencesCopyWith<$Res> {
  _$NotificationPreferencesCopyWithImpl(this._self, this._then);

  final NotificationPreferences _self;
  final $Res Function(NotificationPreferences) _then;

/// Create a copy of NotificationPreferences
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? inApp = null,Object? email = null,Object? sms = null,}) {
  return _then(_self.copyWith(
inApp: null == inApp ? _self.inApp : inApp // ignore: cast_nullable_to_non_nullable
as bool,email: null == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as bool,sms: null == sms ? _self.sms : sms // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [NotificationPreferences].
extension NotificationPreferencesPatterns on NotificationPreferences {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _NotificationPreferences value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _NotificationPreferences() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _NotificationPreferences value)  $default,){
final _that = this;
switch (_that) {
case _NotificationPreferences():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _NotificationPreferences value)?  $default,){
final _that = this;
switch (_that) {
case _NotificationPreferences() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( bool inApp,  bool email,  bool sms)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _NotificationPreferences() when $default != null:
return $default(_that.inApp,_that.email,_that.sms);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( bool inApp,  bool email,  bool sms)  $default,) {final _that = this;
switch (_that) {
case _NotificationPreferences():
return $default(_that.inApp,_that.email,_that.sms);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( bool inApp,  bool email,  bool sms)?  $default,) {final _that = this;
switch (_that) {
case _NotificationPreferences() when $default != null:
return $default(_that.inApp,_that.email,_that.sms);case _:
  return null;

}
}

}

/// @nodoc


class _NotificationPreferences implements NotificationPreferences {
  const _NotificationPreferences({required this.inApp, required this.email, required this.sms});
  

@override final  bool inApp;
@override final  bool email;
@override final  bool sms;

/// Create a copy of NotificationPreferences
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$NotificationPreferencesCopyWith<_NotificationPreferences> get copyWith => __$NotificationPreferencesCopyWithImpl<_NotificationPreferences>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _NotificationPreferences&&(identical(other.inApp, inApp) || other.inApp == inApp)&&(identical(other.email, email) || other.email == email)&&(identical(other.sms, sms) || other.sms == sms));
}


@override
int get hashCode => Object.hash(runtimeType,inApp,email,sms);

@override
String toString() {
  return 'NotificationPreferences(inApp: $inApp, email: $email, sms: $sms)';
}


}

/// @nodoc
abstract mixin class _$NotificationPreferencesCopyWith<$Res> implements $NotificationPreferencesCopyWith<$Res> {
  factory _$NotificationPreferencesCopyWith(_NotificationPreferences value, $Res Function(_NotificationPreferences) _then) = __$NotificationPreferencesCopyWithImpl;
@override @useResult
$Res call({
 bool inApp, bool email, bool sms
});




}
/// @nodoc
class __$NotificationPreferencesCopyWithImpl<$Res>
    implements _$NotificationPreferencesCopyWith<$Res> {
  __$NotificationPreferencesCopyWithImpl(this._self, this._then);

  final _NotificationPreferences _self;
  final $Res Function(_NotificationPreferences) _then;

/// Create a copy of NotificationPreferences
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? inApp = null,Object? email = null,Object? sms = null,}) {
  return _then(_NotificationPreferences(
inApp: null == inApp ? _self.inApp : inApp // ignore: cast_nullable_to_non_nullable
as bool,email: null == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as bool,sms: null == sms ? _self.sms : sms // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

/// @nodoc
mixin _$CitizenPreferences {

 String get language; NotificationPreferences get notifications; bool get biometricLogin;
/// Create a copy of CitizenPreferences
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CitizenPreferencesCopyWith<CitizenPreferences> get copyWith => _$CitizenPreferencesCopyWithImpl<CitizenPreferences>(this as CitizenPreferences, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CitizenPreferences&&(identical(other.language, language) || other.language == language)&&(identical(other.notifications, notifications) || other.notifications == notifications)&&(identical(other.biometricLogin, biometricLogin) || other.biometricLogin == biometricLogin));
}


@override
int get hashCode => Object.hash(runtimeType,language,notifications,biometricLogin);

@override
String toString() {
  return 'CitizenPreferences(language: $language, notifications: $notifications, biometricLogin: $biometricLogin)';
}


}

/// @nodoc
abstract mixin class $CitizenPreferencesCopyWith<$Res>  {
  factory $CitizenPreferencesCopyWith(CitizenPreferences value, $Res Function(CitizenPreferences) _then) = _$CitizenPreferencesCopyWithImpl;
@useResult
$Res call({
 String language, NotificationPreferences notifications, bool biometricLogin
});


$NotificationPreferencesCopyWith<$Res> get notifications;

}
/// @nodoc
class _$CitizenPreferencesCopyWithImpl<$Res>
    implements $CitizenPreferencesCopyWith<$Res> {
  _$CitizenPreferencesCopyWithImpl(this._self, this._then);

  final CitizenPreferences _self;
  final $Res Function(CitizenPreferences) _then;

/// Create a copy of CitizenPreferences
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? language = null,Object? notifications = null,Object? biometricLogin = null,}) {
  return _then(_self.copyWith(
language: null == language ? _self.language : language // ignore: cast_nullable_to_non_nullable
as String,notifications: null == notifications ? _self.notifications : notifications // ignore: cast_nullable_to_non_nullable
as NotificationPreferences,biometricLogin: null == biometricLogin ? _self.biometricLogin : biometricLogin // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}
/// Create a copy of CitizenPreferences
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$NotificationPreferencesCopyWith<$Res> get notifications {
  
  return $NotificationPreferencesCopyWith<$Res>(_self.notifications, (value) {
    return _then(_self.copyWith(notifications: value));
  });
}
}


/// Adds pattern-matching-related methods to [CitizenPreferences].
extension CitizenPreferencesPatterns on CitizenPreferences {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CitizenPreferences value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CitizenPreferences() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CitizenPreferences value)  $default,){
final _that = this;
switch (_that) {
case _CitizenPreferences():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CitizenPreferences value)?  $default,){
final _that = this;
switch (_that) {
case _CitizenPreferences() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String language,  NotificationPreferences notifications,  bool biometricLogin)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CitizenPreferences() when $default != null:
return $default(_that.language,_that.notifications,_that.biometricLogin);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String language,  NotificationPreferences notifications,  bool biometricLogin)  $default,) {final _that = this;
switch (_that) {
case _CitizenPreferences():
return $default(_that.language,_that.notifications,_that.biometricLogin);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String language,  NotificationPreferences notifications,  bool biometricLogin)?  $default,) {final _that = this;
switch (_that) {
case _CitizenPreferences() when $default != null:
return $default(_that.language,_that.notifications,_that.biometricLogin);case _:
  return null;

}
}

}

/// @nodoc


class _CitizenPreferences extends CitizenPreferences {
  const _CitizenPreferences({required this.language, required this.notifications, required this.biometricLogin}): super._();
  

@override final  String language;
@override final  NotificationPreferences notifications;
@override final  bool biometricLogin;

/// Create a copy of CitizenPreferences
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CitizenPreferencesCopyWith<_CitizenPreferences> get copyWith => __$CitizenPreferencesCopyWithImpl<_CitizenPreferences>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CitizenPreferences&&(identical(other.language, language) || other.language == language)&&(identical(other.notifications, notifications) || other.notifications == notifications)&&(identical(other.biometricLogin, biometricLogin) || other.biometricLogin == biometricLogin));
}


@override
int get hashCode => Object.hash(runtimeType,language,notifications,biometricLogin);

@override
String toString() {
  return 'CitizenPreferences(language: $language, notifications: $notifications, biometricLogin: $biometricLogin)';
}


}

/// @nodoc
abstract mixin class _$CitizenPreferencesCopyWith<$Res> implements $CitizenPreferencesCopyWith<$Res> {
  factory _$CitizenPreferencesCopyWith(_CitizenPreferences value, $Res Function(_CitizenPreferences) _then) = __$CitizenPreferencesCopyWithImpl;
@override @useResult
$Res call({
 String language, NotificationPreferences notifications, bool biometricLogin
});


@override $NotificationPreferencesCopyWith<$Res> get notifications;

}
/// @nodoc
class __$CitizenPreferencesCopyWithImpl<$Res>
    implements _$CitizenPreferencesCopyWith<$Res> {
  __$CitizenPreferencesCopyWithImpl(this._self, this._then);

  final _CitizenPreferences _self;
  final $Res Function(_CitizenPreferences) _then;

/// Create a copy of CitizenPreferences
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? language = null,Object? notifications = null,Object? biometricLogin = null,}) {
  return _then(_CitizenPreferences(
language: null == language ? _self.language : language // ignore: cast_nullable_to_non_nullable
as String,notifications: null == notifications ? _self.notifications : notifications // ignore: cast_nullable_to_non_nullable
as NotificationPreferences,biometricLogin: null == biometricLogin ? _self.biometricLogin : biometricLogin // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

/// Create a copy of CitizenPreferences
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$NotificationPreferencesCopyWith<$Res> get notifications {
  
  return $NotificationPreferencesCopyWith<$Res>(_self.notifications, (value) {
    return _then(_self.copyWith(notifications: value));
  });
}
}

// dart format on
