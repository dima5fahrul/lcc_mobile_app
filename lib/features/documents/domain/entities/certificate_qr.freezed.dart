// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'certificate_qr.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$CertificateQr {

 String get certificateId; String get certificateNo; String get verifyCode; String? get verifyUrl; String? get payload; String? get documentHash; String get status; bool? get valid; String get issuedAt;
/// Create a copy of CertificateQr
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CertificateQrCopyWith<CertificateQr> get copyWith => _$CertificateQrCopyWithImpl<CertificateQr>(this as CertificateQr, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CertificateQr&&(identical(other.certificateId, certificateId) || other.certificateId == certificateId)&&(identical(other.certificateNo, certificateNo) || other.certificateNo == certificateNo)&&(identical(other.verifyCode, verifyCode) || other.verifyCode == verifyCode)&&(identical(other.verifyUrl, verifyUrl) || other.verifyUrl == verifyUrl)&&(identical(other.payload, payload) || other.payload == payload)&&(identical(other.documentHash, documentHash) || other.documentHash == documentHash)&&(identical(other.status, status) || other.status == status)&&(identical(other.valid, valid) || other.valid == valid)&&(identical(other.issuedAt, issuedAt) || other.issuedAt == issuedAt));
}


@override
int get hashCode => Object.hash(runtimeType,certificateId,certificateNo,verifyCode,verifyUrl,payload,documentHash,status,valid,issuedAt);

@override
String toString() {
  return 'CertificateQr(certificateId: $certificateId, certificateNo: $certificateNo, verifyCode: $verifyCode, verifyUrl: $verifyUrl, payload: $payload, documentHash: $documentHash, status: $status, valid: $valid, issuedAt: $issuedAt)';
}


}

/// @nodoc
abstract mixin class $CertificateQrCopyWith<$Res>  {
  factory $CertificateQrCopyWith(CertificateQr value, $Res Function(CertificateQr) _then) = _$CertificateQrCopyWithImpl;
@useResult
$Res call({
 String certificateId, String certificateNo, String verifyCode, String? verifyUrl, String? payload, String? documentHash, String status, bool? valid, String issuedAt
});




}
/// @nodoc
class _$CertificateQrCopyWithImpl<$Res>
    implements $CertificateQrCopyWith<$Res> {
  _$CertificateQrCopyWithImpl(this._self, this._then);

  final CertificateQr _self;
  final $Res Function(CertificateQr) _then;

/// Create a copy of CertificateQr
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? certificateId = null,Object? certificateNo = null,Object? verifyCode = null,Object? verifyUrl = freezed,Object? payload = freezed,Object? documentHash = freezed,Object? status = null,Object? valid = freezed,Object? issuedAt = null,}) {
  return _then(_self.copyWith(
certificateId: null == certificateId ? _self.certificateId : certificateId // ignore: cast_nullable_to_non_nullable
as String,certificateNo: null == certificateNo ? _self.certificateNo : certificateNo // ignore: cast_nullable_to_non_nullable
as String,verifyCode: null == verifyCode ? _self.verifyCode : verifyCode // ignore: cast_nullable_to_non_nullable
as String,verifyUrl: freezed == verifyUrl ? _self.verifyUrl : verifyUrl // ignore: cast_nullable_to_non_nullable
as String?,payload: freezed == payload ? _self.payload : payload // ignore: cast_nullable_to_non_nullable
as String?,documentHash: freezed == documentHash ? _self.documentHash : documentHash // ignore: cast_nullable_to_non_nullable
as String?,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,valid: freezed == valid ? _self.valid : valid // ignore: cast_nullable_to_non_nullable
as bool?,issuedAt: null == issuedAt ? _self.issuedAt : issuedAt // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [CertificateQr].
extension CertificateQrPatterns on CertificateQr {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CertificateQr value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CertificateQr() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CertificateQr value)  $default,){
final _that = this;
switch (_that) {
case _CertificateQr():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CertificateQr value)?  $default,){
final _that = this;
switch (_that) {
case _CertificateQr() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String certificateId,  String certificateNo,  String verifyCode,  String? verifyUrl,  String? payload,  String? documentHash,  String status,  bool? valid,  String issuedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CertificateQr() when $default != null:
return $default(_that.certificateId,_that.certificateNo,_that.verifyCode,_that.verifyUrl,_that.payload,_that.documentHash,_that.status,_that.valid,_that.issuedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String certificateId,  String certificateNo,  String verifyCode,  String? verifyUrl,  String? payload,  String? documentHash,  String status,  bool? valid,  String issuedAt)  $default,) {final _that = this;
switch (_that) {
case _CertificateQr():
return $default(_that.certificateId,_that.certificateNo,_that.verifyCode,_that.verifyUrl,_that.payload,_that.documentHash,_that.status,_that.valid,_that.issuedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String certificateId,  String certificateNo,  String verifyCode,  String? verifyUrl,  String? payload,  String? documentHash,  String status,  bool? valid,  String issuedAt)?  $default,) {final _that = this;
switch (_that) {
case _CertificateQr() when $default != null:
return $default(_that.certificateId,_that.certificateNo,_that.verifyCode,_that.verifyUrl,_that.payload,_that.documentHash,_that.status,_that.valid,_that.issuedAt);case _:
  return null;

}
}

}

/// @nodoc


class _CertificateQr implements CertificateQr {
  const _CertificateQr({required this.certificateId, required this.certificateNo, required this.verifyCode, this.verifyUrl, this.payload, this.documentHash, required this.status, this.valid, required this.issuedAt});
  

@override final  String certificateId;
@override final  String certificateNo;
@override final  String verifyCode;
@override final  String? verifyUrl;
@override final  String? payload;
@override final  String? documentHash;
@override final  String status;
@override final  bool? valid;
@override final  String issuedAt;

/// Create a copy of CertificateQr
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CertificateQrCopyWith<_CertificateQr> get copyWith => __$CertificateQrCopyWithImpl<_CertificateQr>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CertificateQr&&(identical(other.certificateId, certificateId) || other.certificateId == certificateId)&&(identical(other.certificateNo, certificateNo) || other.certificateNo == certificateNo)&&(identical(other.verifyCode, verifyCode) || other.verifyCode == verifyCode)&&(identical(other.verifyUrl, verifyUrl) || other.verifyUrl == verifyUrl)&&(identical(other.payload, payload) || other.payload == payload)&&(identical(other.documentHash, documentHash) || other.documentHash == documentHash)&&(identical(other.status, status) || other.status == status)&&(identical(other.valid, valid) || other.valid == valid)&&(identical(other.issuedAt, issuedAt) || other.issuedAt == issuedAt));
}


@override
int get hashCode => Object.hash(runtimeType,certificateId,certificateNo,verifyCode,verifyUrl,payload,documentHash,status,valid,issuedAt);

@override
String toString() {
  return 'CertificateQr(certificateId: $certificateId, certificateNo: $certificateNo, verifyCode: $verifyCode, verifyUrl: $verifyUrl, payload: $payload, documentHash: $documentHash, status: $status, valid: $valid, issuedAt: $issuedAt)';
}


}

/// @nodoc
abstract mixin class _$CertificateQrCopyWith<$Res> implements $CertificateQrCopyWith<$Res> {
  factory _$CertificateQrCopyWith(_CertificateQr value, $Res Function(_CertificateQr) _then) = __$CertificateQrCopyWithImpl;
@override @useResult
$Res call({
 String certificateId, String certificateNo, String verifyCode, String? verifyUrl, String? payload, String? documentHash, String status, bool? valid, String issuedAt
});




}
/// @nodoc
class __$CertificateQrCopyWithImpl<$Res>
    implements _$CertificateQrCopyWith<$Res> {
  __$CertificateQrCopyWithImpl(this._self, this._then);

  final _CertificateQr _self;
  final $Res Function(_CertificateQr) _then;

/// Create a copy of CertificateQr
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? certificateId = null,Object? certificateNo = null,Object? verifyCode = null,Object? verifyUrl = freezed,Object? payload = freezed,Object? documentHash = freezed,Object? status = null,Object? valid = freezed,Object? issuedAt = null,}) {
  return _then(_CertificateQr(
certificateId: null == certificateId ? _self.certificateId : certificateId // ignore: cast_nullable_to_non_nullable
as String,certificateNo: null == certificateNo ? _self.certificateNo : certificateNo // ignore: cast_nullable_to_non_nullable
as String,verifyCode: null == verifyCode ? _self.verifyCode : verifyCode // ignore: cast_nullable_to_non_nullable
as String,verifyUrl: freezed == verifyUrl ? _self.verifyUrl : verifyUrl // ignore: cast_nullable_to_non_nullable
as String?,payload: freezed == payload ? _self.payload : payload // ignore: cast_nullable_to_non_nullable
as String?,documentHash: freezed == documentHash ? _self.documentHash : documentHash // ignore: cast_nullable_to_non_nullable
as String?,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,valid: freezed == valid ? _self.valid : valid // ignore: cast_nullable_to_non_nullable
as bool?,issuedAt: null == issuedAt ? _self.issuedAt : issuedAt // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
