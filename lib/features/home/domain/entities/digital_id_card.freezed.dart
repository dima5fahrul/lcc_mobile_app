// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'digital_id_card.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$DigitalIdCard {

/// The citizen's own unique identification number. Printed masked, with a
/// show/hide toggle (`Hero.tsx:261`).
 String get uin; String get cardNo;/// The photo printed on the issued card. **A URL, not a bundled asset** —
/// the stock `user-photo` likeness is never rendered by a B2 surface
/// (B2-AC-42 item 4, V-16/V-17). Empty when the registry record has none,
/// in which case the card falls back to the citizen's initial.
 String get photoUrl; String get verifyCode; String get verifyUrl; String get qrPayload;
/// Create a copy of DigitalIdCard
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DigitalIdCardCopyWith<DigitalIdCard> get copyWith => _$DigitalIdCardCopyWithImpl<DigitalIdCard>(this as DigitalIdCard, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DigitalIdCard&&(identical(other.uin, uin) || other.uin == uin)&&(identical(other.cardNo, cardNo) || other.cardNo == cardNo)&&(identical(other.photoUrl, photoUrl) || other.photoUrl == photoUrl)&&(identical(other.verifyCode, verifyCode) || other.verifyCode == verifyCode)&&(identical(other.verifyUrl, verifyUrl) || other.verifyUrl == verifyUrl)&&(identical(other.qrPayload, qrPayload) || other.qrPayload == qrPayload));
}


@override
int get hashCode => Object.hash(runtimeType,uin,cardNo,photoUrl,verifyCode,verifyUrl,qrPayload);

@override
String toString() {
  return 'DigitalIdCard(uin: $uin, cardNo: $cardNo, photoUrl: $photoUrl, verifyCode: $verifyCode, verifyUrl: $verifyUrl, qrPayload: $qrPayload)';
}


}

/// @nodoc
abstract mixin class $DigitalIdCardCopyWith<$Res>  {
  factory $DigitalIdCardCopyWith(DigitalIdCard value, $Res Function(DigitalIdCard) _then) = _$DigitalIdCardCopyWithImpl;
@useResult
$Res call({
 String uin, String cardNo, String photoUrl, String verifyCode, String verifyUrl, String qrPayload
});




}
/// @nodoc
class _$DigitalIdCardCopyWithImpl<$Res>
    implements $DigitalIdCardCopyWith<$Res> {
  _$DigitalIdCardCopyWithImpl(this._self, this._then);

  final DigitalIdCard _self;
  final $Res Function(DigitalIdCard) _then;

/// Create a copy of DigitalIdCard
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? uin = null,Object? cardNo = null,Object? photoUrl = null,Object? verifyCode = null,Object? verifyUrl = null,Object? qrPayload = null,}) {
  return _then(_self.copyWith(
uin: null == uin ? _self.uin : uin // ignore: cast_nullable_to_non_nullable
as String,cardNo: null == cardNo ? _self.cardNo : cardNo // ignore: cast_nullable_to_non_nullable
as String,photoUrl: null == photoUrl ? _self.photoUrl : photoUrl // ignore: cast_nullable_to_non_nullable
as String,verifyCode: null == verifyCode ? _self.verifyCode : verifyCode // ignore: cast_nullable_to_non_nullable
as String,verifyUrl: null == verifyUrl ? _self.verifyUrl : verifyUrl // ignore: cast_nullable_to_non_nullable
as String,qrPayload: null == qrPayload ? _self.qrPayload : qrPayload // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [DigitalIdCard].
extension DigitalIdCardPatterns on DigitalIdCard {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _DigitalIdCard value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _DigitalIdCard() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _DigitalIdCard value)  $default,){
final _that = this;
switch (_that) {
case _DigitalIdCard():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _DigitalIdCard value)?  $default,){
final _that = this;
switch (_that) {
case _DigitalIdCard() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String uin,  String cardNo,  String photoUrl,  String verifyCode,  String verifyUrl,  String qrPayload)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _DigitalIdCard() when $default != null:
return $default(_that.uin,_that.cardNo,_that.photoUrl,_that.verifyCode,_that.verifyUrl,_that.qrPayload);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String uin,  String cardNo,  String photoUrl,  String verifyCode,  String verifyUrl,  String qrPayload)  $default,) {final _that = this;
switch (_that) {
case _DigitalIdCard():
return $default(_that.uin,_that.cardNo,_that.photoUrl,_that.verifyCode,_that.verifyUrl,_that.qrPayload);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String uin,  String cardNo,  String photoUrl,  String verifyCode,  String verifyUrl,  String qrPayload)?  $default,) {final _that = this;
switch (_that) {
case _DigitalIdCard() when $default != null:
return $default(_that.uin,_that.cardNo,_that.photoUrl,_that.verifyCode,_that.verifyUrl,_that.qrPayload);case _:
  return null;

}
}

}

/// @nodoc


class _DigitalIdCard extends DigitalIdCard {
  const _DigitalIdCard({this.uin = '', this.cardNo = '', this.photoUrl = '', this.verifyCode = '', this.verifyUrl = '', this.qrPayload = ''}): super._();
  

/// The citizen's own unique identification number. Printed masked, with a
/// show/hide toggle (`Hero.tsx:261`).
@override@JsonKey() final  String uin;
@override@JsonKey() final  String cardNo;
/// The photo printed on the issued card. **A URL, not a bundled asset** —
/// the stock `user-photo` likeness is never rendered by a B2 surface
/// (B2-AC-42 item 4, V-16/V-17). Empty when the registry record has none,
/// in which case the card falls back to the citizen's initial.
@override@JsonKey() final  String photoUrl;
@override@JsonKey() final  String verifyCode;
@override@JsonKey() final  String verifyUrl;
@override@JsonKey() final  String qrPayload;

/// Create a copy of DigitalIdCard
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DigitalIdCardCopyWith<_DigitalIdCard> get copyWith => __$DigitalIdCardCopyWithImpl<_DigitalIdCard>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _DigitalIdCard&&(identical(other.uin, uin) || other.uin == uin)&&(identical(other.cardNo, cardNo) || other.cardNo == cardNo)&&(identical(other.photoUrl, photoUrl) || other.photoUrl == photoUrl)&&(identical(other.verifyCode, verifyCode) || other.verifyCode == verifyCode)&&(identical(other.verifyUrl, verifyUrl) || other.verifyUrl == verifyUrl)&&(identical(other.qrPayload, qrPayload) || other.qrPayload == qrPayload));
}


@override
int get hashCode => Object.hash(runtimeType,uin,cardNo,photoUrl,verifyCode,verifyUrl,qrPayload);

@override
String toString() {
  return 'DigitalIdCard(uin: $uin, cardNo: $cardNo, photoUrl: $photoUrl, verifyCode: $verifyCode, verifyUrl: $verifyUrl, qrPayload: $qrPayload)';
}


}

/// @nodoc
abstract mixin class _$DigitalIdCardCopyWith<$Res> implements $DigitalIdCardCopyWith<$Res> {
  factory _$DigitalIdCardCopyWith(_DigitalIdCard value, $Res Function(_DigitalIdCard) _then) = __$DigitalIdCardCopyWithImpl;
@override @useResult
$Res call({
 String uin, String cardNo, String photoUrl, String verifyCode, String verifyUrl, String qrPayload
});




}
/// @nodoc
class __$DigitalIdCardCopyWithImpl<$Res>
    implements _$DigitalIdCardCopyWith<$Res> {
  __$DigitalIdCardCopyWithImpl(this._self, this._then);

  final _DigitalIdCard _self;
  final $Res Function(_DigitalIdCard) _then;

/// Create a copy of DigitalIdCard
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? uin = null,Object? cardNo = null,Object? photoUrl = null,Object? verifyCode = null,Object? verifyUrl = null,Object? qrPayload = null,}) {
  return _then(_DigitalIdCard(
uin: null == uin ? _self.uin : uin // ignore: cast_nullable_to_non_nullable
as String,cardNo: null == cardNo ? _self.cardNo : cardNo // ignore: cast_nullable_to_non_nullable
as String,photoUrl: null == photoUrl ? _self.photoUrl : photoUrl // ignore: cast_nullable_to_non_nullable
as String,verifyCode: null == verifyCode ? _self.verifyCode : verifyCode // ignore: cast_nullable_to_non_nullable
as String,verifyUrl: null == verifyUrl ? _self.verifyUrl : verifyUrl // ignore: cast_nullable_to_non_nullable
as String,qrPayload: null == qrPayload ? _self.qrPayload : qrPayload // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
