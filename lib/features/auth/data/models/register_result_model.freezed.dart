// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'register_result_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$RegisterResultModel {

@JsonKey(name: 'citizen_id') String get citizenId; OtpChallengeModel get challenge;
/// Create a copy of RegisterResultModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RegisterResultModelCopyWith<RegisterResultModel> get copyWith => _$RegisterResultModelCopyWithImpl<RegisterResultModel>(this as RegisterResultModel, _$identity);

  /// Serializes this RegisterResultModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RegisterResultModel&&(identical(other.citizenId, citizenId) || other.citizenId == citizenId)&&(identical(other.challenge, challenge) || other.challenge == challenge));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,citizenId,challenge);

@override
String toString() {
  return 'RegisterResultModel(citizenId: $citizenId, challenge: $challenge)';
}


}

/// @nodoc
abstract mixin class $RegisterResultModelCopyWith<$Res>  {
  factory $RegisterResultModelCopyWith(RegisterResultModel value, $Res Function(RegisterResultModel) _then) = _$RegisterResultModelCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'citizen_id') String citizenId, OtpChallengeModel challenge
});


$OtpChallengeModelCopyWith<$Res> get challenge;

}
/// @nodoc
class _$RegisterResultModelCopyWithImpl<$Res>
    implements $RegisterResultModelCopyWith<$Res> {
  _$RegisterResultModelCopyWithImpl(this._self, this._then);

  final RegisterResultModel _self;
  final $Res Function(RegisterResultModel) _then;

/// Create a copy of RegisterResultModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? citizenId = null,Object? challenge = null,}) {
  return _then(_self.copyWith(
citizenId: null == citizenId ? _self.citizenId : citizenId // ignore: cast_nullable_to_non_nullable
as String,challenge: null == challenge ? _self.challenge : challenge // ignore: cast_nullable_to_non_nullable
as OtpChallengeModel,
  ));
}
/// Create a copy of RegisterResultModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$OtpChallengeModelCopyWith<$Res> get challenge {
  
  return $OtpChallengeModelCopyWith<$Res>(_self.challenge, (value) {
    return _then(_self.copyWith(challenge: value));
  });
}
}


/// Adds pattern-matching-related methods to [RegisterResultModel].
extension RegisterResultModelPatterns on RegisterResultModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _RegisterResultModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _RegisterResultModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _RegisterResultModel value)  $default,){
final _that = this;
switch (_that) {
case _RegisterResultModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _RegisterResultModel value)?  $default,){
final _that = this;
switch (_that) {
case _RegisterResultModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'citizen_id')  String citizenId,  OtpChallengeModel challenge)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _RegisterResultModel() when $default != null:
return $default(_that.citizenId,_that.challenge);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'citizen_id')  String citizenId,  OtpChallengeModel challenge)  $default,) {final _that = this;
switch (_that) {
case _RegisterResultModel():
return $default(_that.citizenId,_that.challenge);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'citizen_id')  String citizenId,  OtpChallengeModel challenge)?  $default,) {final _that = this;
switch (_that) {
case _RegisterResultModel() when $default != null:
return $default(_that.citizenId,_that.challenge);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _RegisterResultModel implements RegisterResultModel {
  const _RegisterResultModel({@JsonKey(name: 'citizen_id') required this.citizenId, required this.challenge});
  factory _RegisterResultModel.fromJson(Map<String, dynamic> json) => _$RegisterResultModelFromJson(json);

@override@JsonKey(name: 'citizen_id') final  String citizenId;
@override final  OtpChallengeModel challenge;

/// Create a copy of RegisterResultModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$RegisterResultModelCopyWith<_RegisterResultModel> get copyWith => __$RegisterResultModelCopyWithImpl<_RegisterResultModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$RegisterResultModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _RegisterResultModel&&(identical(other.citizenId, citizenId) || other.citizenId == citizenId)&&(identical(other.challenge, challenge) || other.challenge == challenge));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,citizenId,challenge);

@override
String toString() {
  return 'RegisterResultModel(citizenId: $citizenId, challenge: $challenge)';
}


}

/// @nodoc
abstract mixin class _$RegisterResultModelCopyWith<$Res> implements $RegisterResultModelCopyWith<$Res> {
  factory _$RegisterResultModelCopyWith(_RegisterResultModel value, $Res Function(_RegisterResultModel) _then) = __$RegisterResultModelCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'citizen_id') String citizenId, OtpChallengeModel challenge
});


@override $OtpChallengeModelCopyWith<$Res> get challenge;

}
/// @nodoc
class __$RegisterResultModelCopyWithImpl<$Res>
    implements _$RegisterResultModelCopyWith<$Res> {
  __$RegisterResultModelCopyWithImpl(this._self, this._then);

  final _RegisterResultModel _self;
  final $Res Function(_RegisterResultModel) _then;

/// Create a copy of RegisterResultModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? citizenId = null,Object? challenge = null,}) {
  return _then(_RegisterResultModel(
citizenId: null == citizenId ? _self.citizenId : citizenId // ignore: cast_nullable_to_non_nullable
as String,challenge: null == challenge ? _self.challenge : challenge // ignore: cast_nullable_to_non_nullable
as OtpChallengeModel,
  ));
}

/// Create a copy of RegisterResultModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$OtpChallengeModelCopyWith<$Res> get challenge {
  
  return $OtpChallengeModelCopyWith<$Res>(_self.challenge, (value) {
    return _then(_self.copyWith(challenge: value));
  });
}
}

// dart format on
