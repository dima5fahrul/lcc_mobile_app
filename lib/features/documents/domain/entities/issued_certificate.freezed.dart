// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'issued_certificate.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$IssuedCertificate {

 String get id; String get certificateNo;/// The **first** clause of the three-step resolution at
/// `HistoryDetailPage.tsx:150-156`.
 String? get applicationId;/// The **third** clause of that resolution.
 String? get referenceNo; String get serviceCode;/// The shared kernel's [Bilingual], **imported not redefined**
/// (`ssd.md` § 4.6, `B5-AC-29`).
 Bilingual? get serviceName; String get holderName; String? get uin;/// Kept as the **raw wire string**: formatting is the mapper's job and the
/// card renders it through `formatApplicationDate` (`:473`), which needs
/// the unparsed value to reproduce the source's verbatim fallback.
 String get issuedAt; String? get issuedByName;/// A plain `String`, not an enum — see the library doc.
 String get status; String get verifyCode;/// Parsed, **not rendered**: no call site on this surface reads it.
/// Carried because `application_row.dart`'s rule is that every field the
/// wire sends is parsed.
 String? get verifyUrl; String? get qrPayload;/// Parsed, **not rendered** — the History path always *generates* the
/// document (`HistoryDetailPage.tsx:651` passes a `spec`, never a URL).
/// The Account branch that would read this — a remote PDF URL in an
/// `<iframe>` — stays deferred (specs.md § 6.11, FU-1).
 String? get fileUrl;/// Parsed, **not rendered** — its only reader in the source was the
/// document-hash check in the `verification` namespace, whose two endpoints
/// have zero call sites (specs.md Finding A).
///
/// **The Dart name is `documentHash` because specs.md § 5's field table
/// says so, and that makes `B5-AC-9` unsatisfiable as written**: that
/// criterion greps `lib/` for the identifier while `B5-AC-27` requires all
/// 15 wire fields including this one. The two cannot both hold. § 5 wins —
/// an entity that silently drops a wire field is the defect
/// `application_row.dart` wrote its rule against — and the conflict is
/// reported rather than resolved by renaming the field to dodge a grep.
 String? get documentHash;
/// Create a copy of IssuedCertificate
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$IssuedCertificateCopyWith<IssuedCertificate> get copyWith => _$IssuedCertificateCopyWithImpl<IssuedCertificate>(this as IssuedCertificate, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is IssuedCertificate&&(identical(other.id, id) || other.id == id)&&(identical(other.certificateNo, certificateNo) || other.certificateNo == certificateNo)&&(identical(other.applicationId, applicationId) || other.applicationId == applicationId)&&(identical(other.referenceNo, referenceNo) || other.referenceNo == referenceNo)&&(identical(other.serviceCode, serviceCode) || other.serviceCode == serviceCode)&&(identical(other.serviceName, serviceName) || other.serviceName == serviceName)&&(identical(other.holderName, holderName) || other.holderName == holderName)&&(identical(other.uin, uin) || other.uin == uin)&&(identical(other.issuedAt, issuedAt) || other.issuedAt == issuedAt)&&(identical(other.issuedByName, issuedByName) || other.issuedByName == issuedByName)&&(identical(other.status, status) || other.status == status)&&(identical(other.verifyCode, verifyCode) || other.verifyCode == verifyCode)&&(identical(other.verifyUrl, verifyUrl) || other.verifyUrl == verifyUrl)&&(identical(other.qrPayload, qrPayload) || other.qrPayload == qrPayload)&&(identical(other.fileUrl, fileUrl) || other.fileUrl == fileUrl)&&(identical(other.documentHash, documentHash) || other.documentHash == documentHash));
}


@override
int get hashCode => Object.hash(runtimeType,id,certificateNo,applicationId,referenceNo,serviceCode,serviceName,holderName,uin,issuedAt,issuedByName,status,verifyCode,verifyUrl,qrPayload,fileUrl,documentHash);

@override
String toString() {
  return 'IssuedCertificate(id: $id, certificateNo: $certificateNo, applicationId: $applicationId, referenceNo: $referenceNo, serviceCode: $serviceCode, serviceName: $serviceName, holderName: $holderName, uin: $uin, issuedAt: $issuedAt, issuedByName: $issuedByName, status: $status, verifyCode: $verifyCode, verifyUrl: $verifyUrl, qrPayload: $qrPayload, fileUrl: $fileUrl, documentHash: $documentHash)';
}


}

/// @nodoc
abstract mixin class $IssuedCertificateCopyWith<$Res>  {
  factory $IssuedCertificateCopyWith(IssuedCertificate value, $Res Function(IssuedCertificate) _then) = _$IssuedCertificateCopyWithImpl;
@useResult
$Res call({
 String id, String certificateNo, String? applicationId, String? referenceNo, String serviceCode, Bilingual? serviceName, String holderName, String? uin, String issuedAt, String? issuedByName, String status, String verifyCode, String? verifyUrl, String? qrPayload, String? fileUrl, String? documentHash
});


$BilingualCopyWith<$Res>? get serviceName;

}
/// @nodoc
class _$IssuedCertificateCopyWithImpl<$Res>
    implements $IssuedCertificateCopyWith<$Res> {
  _$IssuedCertificateCopyWithImpl(this._self, this._then);

  final IssuedCertificate _self;
  final $Res Function(IssuedCertificate) _then;

/// Create a copy of IssuedCertificate
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? certificateNo = null,Object? applicationId = freezed,Object? referenceNo = freezed,Object? serviceCode = null,Object? serviceName = freezed,Object? holderName = null,Object? uin = freezed,Object? issuedAt = null,Object? issuedByName = freezed,Object? status = null,Object? verifyCode = null,Object? verifyUrl = freezed,Object? qrPayload = freezed,Object? fileUrl = freezed,Object? documentHash = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,certificateNo: null == certificateNo ? _self.certificateNo : certificateNo // ignore: cast_nullable_to_non_nullable
as String,applicationId: freezed == applicationId ? _self.applicationId : applicationId // ignore: cast_nullable_to_non_nullable
as String?,referenceNo: freezed == referenceNo ? _self.referenceNo : referenceNo // ignore: cast_nullable_to_non_nullable
as String?,serviceCode: null == serviceCode ? _self.serviceCode : serviceCode // ignore: cast_nullable_to_non_nullable
as String,serviceName: freezed == serviceName ? _self.serviceName : serviceName // ignore: cast_nullable_to_non_nullable
as Bilingual?,holderName: null == holderName ? _self.holderName : holderName // ignore: cast_nullable_to_non_nullable
as String,uin: freezed == uin ? _self.uin : uin // ignore: cast_nullable_to_non_nullable
as String?,issuedAt: null == issuedAt ? _self.issuedAt : issuedAt // ignore: cast_nullable_to_non_nullable
as String,issuedByName: freezed == issuedByName ? _self.issuedByName : issuedByName // ignore: cast_nullable_to_non_nullable
as String?,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,verifyCode: null == verifyCode ? _self.verifyCode : verifyCode // ignore: cast_nullable_to_non_nullable
as String,verifyUrl: freezed == verifyUrl ? _self.verifyUrl : verifyUrl // ignore: cast_nullable_to_non_nullable
as String?,qrPayload: freezed == qrPayload ? _self.qrPayload : qrPayload // ignore: cast_nullable_to_non_nullable
as String?,fileUrl: freezed == fileUrl ? _self.fileUrl : fileUrl // ignore: cast_nullable_to_non_nullable
as String?,documentHash: freezed == documentHash ? _self.documentHash : documentHash // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}
/// Create a copy of IssuedCertificate
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BilingualCopyWith<$Res>? get serviceName {
    if (_self.serviceName == null) {
    return null;
  }

  return $BilingualCopyWith<$Res>(_self.serviceName!, (value) {
    return _then(_self.copyWith(serviceName: value));
  });
}
}


/// Adds pattern-matching-related methods to [IssuedCertificate].
extension IssuedCertificatePatterns on IssuedCertificate {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _IssuedCertificate value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _IssuedCertificate() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _IssuedCertificate value)  $default,){
final _that = this;
switch (_that) {
case _IssuedCertificate():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _IssuedCertificate value)?  $default,){
final _that = this;
switch (_that) {
case _IssuedCertificate() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String certificateNo,  String? applicationId,  String? referenceNo,  String serviceCode,  Bilingual? serviceName,  String holderName,  String? uin,  String issuedAt,  String? issuedByName,  String status,  String verifyCode,  String? verifyUrl,  String? qrPayload,  String? fileUrl,  String? documentHash)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _IssuedCertificate() when $default != null:
return $default(_that.id,_that.certificateNo,_that.applicationId,_that.referenceNo,_that.serviceCode,_that.serviceName,_that.holderName,_that.uin,_that.issuedAt,_that.issuedByName,_that.status,_that.verifyCode,_that.verifyUrl,_that.qrPayload,_that.fileUrl,_that.documentHash);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String certificateNo,  String? applicationId,  String? referenceNo,  String serviceCode,  Bilingual? serviceName,  String holderName,  String? uin,  String issuedAt,  String? issuedByName,  String status,  String verifyCode,  String? verifyUrl,  String? qrPayload,  String? fileUrl,  String? documentHash)  $default,) {final _that = this;
switch (_that) {
case _IssuedCertificate():
return $default(_that.id,_that.certificateNo,_that.applicationId,_that.referenceNo,_that.serviceCode,_that.serviceName,_that.holderName,_that.uin,_that.issuedAt,_that.issuedByName,_that.status,_that.verifyCode,_that.verifyUrl,_that.qrPayload,_that.fileUrl,_that.documentHash);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String certificateNo,  String? applicationId,  String? referenceNo,  String serviceCode,  Bilingual? serviceName,  String holderName,  String? uin,  String issuedAt,  String? issuedByName,  String status,  String verifyCode,  String? verifyUrl,  String? qrPayload,  String? fileUrl,  String? documentHash)?  $default,) {final _that = this;
switch (_that) {
case _IssuedCertificate() when $default != null:
return $default(_that.id,_that.certificateNo,_that.applicationId,_that.referenceNo,_that.serviceCode,_that.serviceName,_that.holderName,_that.uin,_that.issuedAt,_that.issuedByName,_that.status,_that.verifyCode,_that.verifyUrl,_that.qrPayload,_that.fileUrl,_that.documentHash);case _:
  return null;

}
}

}

/// @nodoc


class _IssuedCertificate extends IssuedCertificate {
  const _IssuedCertificate({required this.id, required this.certificateNo, this.applicationId, this.referenceNo, required this.serviceCode, this.serviceName, required this.holderName, this.uin, required this.issuedAt, this.issuedByName, required this.status, required this.verifyCode, this.verifyUrl, this.qrPayload, this.fileUrl, this.documentHash}): super._();
  

@override final  String id;
@override final  String certificateNo;
/// The **first** clause of the three-step resolution at
/// `HistoryDetailPage.tsx:150-156`.
@override final  String? applicationId;
/// The **third** clause of that resolution.
@override final  String? referenceNo;
@override final  String serviceCode;
/// The shared kernel's [Bilingual], **imported not redefined**
/// (`ssd.md` § 4.6, `B5-AC-29`).
@override final  Bilingual? serviceName;
@override final  String holderName;
@override final  String? uin;
/// Kept as the **raw wire string**: formatting is the mapper's job and the
/// card renders it through `formatApplicationDate` (`:473`), which needs
/// the unparsed value to reproduce the source's verbatim fallback.
@override final  String issuedAt;
@override final  String? issuedByName;
/// A plain `String`, not an enum — see the library doc.
@override final  String status;
@override final  String verifyCode;
/// Parsed, **not rendered**: no call site on this surface reads it.
/// Carried because `application_row.dart`'s rule is that every field the
/// wire sends is parsed.
@override final  String? verifyUrl;
@override final  String? qrPayload;
/// Parsed, **not rendered** — the History path always *generates* the
/// document (`HistoryDetailPage.tsx:651` passes a `spec`, never a URL).
/// The Account branch that would read this — a remote PDF URL in an
/// `<iframe>` — stays deferred (specs.md § 6.11, FU-1).
@override final  String? fileUrl;
/// Parsed, **not rendered** — its only reader in the source was the
/// document-hash check in the `verification` namespace, whose two endpoints
/// have zero call sites (specs.md Finding A).
///
/// **The Dart name is `documentHash` because specs.md § 5's field table
/// says so, and that makes `B5-AC-9` unsatisfiable as written**: that
/// criterion greps `lib/` for the identifier while `B5-AC-27` requires all
/// 15 wire fields including this one. The two cannot both hold. § 5 wins —
/// an entity that silently drops a wire field is the defect
/// `application_row.dart` wrote its rule against — and the conflict is
/// reported rather than resolved by renaming the field to dodge a grep.
@override final  String? documentHash;

/// Create a copy of IssuedCertificate
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$IssuedCertificateCopyWith<_IssuedCertificate> get copyWith => __$IssuedCertificateCopyWithImpl<_IssuedCertificate>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _IssuedCertificate&&(identical(other.id, id) || other.id == id)&&(identical(other.certificateNo, certificateNo) || other.certificateNo == certificateNo)&&(identical(other.applicationId, applicationId) || other.applicationId == applicationId)&&(identical(other.referenceNo, referenceNo) || other.referenceNo == referenceNo)&&(identical(other.serviceCode, serviceCode) || other.serviceCode == serviceCode)&&(identical(other.serviceName, serviceName) || other.serviceName == serviceName)&&(identical(other.holderName, holderName) || other.holderName == holderName)&&(identical(other.uin, uin) || other.uin == uin)&&(identical(other.issuedAt, issuedAt) || other.issuedAt == issuedAt)&&(identical(other.issuedByName, issuedByName) || other.issuedByName == issuedByName)&&(identical(other.status, status) || other.status == status)&&(identical(other.verifyCode, verifyCode) || other.verifyCode == verifyCode)&&(identical(other.verifyUrl, verifyUrl) || other.verifyUrl == verifyUrl)&&(identical(other.qrPayload, qrPayload) || other.qrPayload == qrPayload)&&(identical(other.fileUrl, fileUrl) || other.fileUrl == fileUrl)&&(identical(other.documentHash, documentHash) || other.documentHash == documentHash));
}


@override
int get hashCode => Object.hash(runtimeType,id,certificateNo,applicationId,referenceNo,serviceCode,serviceName,holderName,uin,issuedAt,issuedByName,status,verifyCode,verifyUrl,qrPayload,fileUrl,documentHash);

@override
String toString() {
  return 'IssuedCertificate(id: $id, certificateNo: $certificateNo, applicationId: $applicationId, referenceNo: $referenceNo, serviceCode: $serviceCode, serviceName: $serviceName, holderName: $holderName, uin: $uin, issuedAt: $issuedAt, issuedByName: $issuedByName, status: $status, verifyCode: $verifyCode, verifyUrl: $verifyUrl, qrPayload: $qrPayload, fileUrl: $fileUrl, documentHash: $documentHash)';
}


}

/// @nodoc
abstract mixin class _$IssuedCertificateCopyWith<$Res> implements $IssuedCertificateCopyWith<$Res> {
  factory _$IssuedCertificateCopyWith(_IssuedCertificate value, $Res Function(_IssuedCertificate) _then) = __$IssuedCertificateCopyWithImpl;
@override @useResult
$Res call({
 String id, String certificateNo, String? applicationId, String? referenceNo, String serviceCode, Bilingual? serviceName, String holderName, String? uin, String issuedAt, String? issuedByName, String status, String verifyCode, String? verifyUrl, String? qrPayload, String? fileUrl, String? documentHash
});


@override $BilingualCopyWith<$Res>? get serviceName;

}
/// @nodoc
class __$IssuedCertificateCopyWithImpl<$Res>
    implements _$IssuedCertificateCopyWith<$Res> {
  __$IssuedCertificateCopyWithImpl(this._self, this._then);

  final _IssuedCertificate _self;
  final $Res Function(_IssuedCertificate) _then;

/// Create a copy of IssuedCertificate
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? certificateNo = null,Object? applicationId = freezed,Object? referenceNo = freezed,Object? serviceCode = null,Object? serviceName = freezed,Object? holderName = null,Object? uin = freezed,Object? issuedAt = null,Object? issuedByName = freezed,Object? status = null,Object? verifyCode = null,Object? verifyUrl = freezed,Object? qrPayload = freezed,Object? fileUrl = freezed,Object? documentHash = freezed,}) {
  return _then(_IssuedCertificate(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,certificateNo: null == certificateNo ? _self.certificateNo : certificateNo // ignore: cast_nullable_to_non_nullable
as String,applicationId: freezed == applicationId ? _self.applicationId : applicationId // ignore: cast_nullable_to_non_nullable
as String?,referenceNo: freezed == referenceNo ? _self.referenceNo : referenceNo // ignore: cast_nullable_to_non_nullable
as String?,serviceCode: null == serviceCode ? _self.serviceCode : serviceCode // ignore: cast_nullable_to_non_nullable
as String,serviceName: freezed == serviceName ? _self.serviceName : serviceName // ignore: cast_nullable_to_non_nullable
as Bilingual?,holderName: null == holderName ? _self.holderName : holderName // ignore: cast_nullable_to_non_nullable
as String,uin: freezed == uin ? _self.uin : uin // ignore: cast_nullable_to_non_nullable
as String?,issuedAt: null == issuedAt ? _self.issuedAt : issuedAt // ignore: cast_nullable_to_non_nullable
as String,issuedByName: freezed == issuedByName ? _self.issuedByName : issuedByName // ignore: cast_nullable_to_non_nullable
as String?,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,verifyCode: null == verifyCode ? _self.verifyCode : verifyCode // ignore: cast_nullable_to_non_nullable
as String,verifyUrl: freezed == verifyUrl ? _self.verifyUrl : verifyUrl // ignore: cast_nullable_to_non_nullable
as String?,qrPayload: freezed == qrPayload ? _self.qrPayload : qrPayload // ignore: cast_nullable_to_non_nullable
as String?,fileUrl: freezed == fileUrl ? _self.fileUrl : fileUrl // ignore: cast_nullable_to_non_nullable
as String?,documentHash: freezed == documentHash ? _self.documentHash : documentHash // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

/// Create a copy of IssuedCertificate
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BilingualCopyWith<$Res>? get serviceName {
    if (_self.serviceName == null) {
    return null;
  }

  return $BilingualCopyWith<$Res>(_self.serviceName!, (value) {
    return _then(_self.copyWith(serviceName: value));
  });
}
}

// dart format on
