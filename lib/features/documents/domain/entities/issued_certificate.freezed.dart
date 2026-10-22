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
 String? get documentHash;// ---- The v2 keys of MOBILE-API-E-CERTIFICATES.md (§ Certificate model,
// list item in § Citizen endpoints), each defaulted to its empty shape so
// the legacy rows — which send none of them — keep parsing unchanged.
// `service` (the bilingual object) is mapped onto [serviceName]
// new-first, `service_name` falling back; see `certificate_wire.dart`.
/// `document_type` — the certificate type's three-letter code (`RES`,
/// `BIR`, `DEA`, `MAR`, `DIV`, `FBK`), as the spec's § Certificate model
/// table lists them. A plain `String` for the `status` reason: the table
/// grows by row and an enum would fail a type it was never told about.
///
/// **Added 2026-10-22 (review I-2).** It was the one list-item key
/// `issuedCertificateFrom` did not read, and the spec's implementation
/// checklist asks for exactly it: *"Certificates list … grouped by
/// `application_id`; label by `document_type` and `copy`"*. Without it a
/// divorce's three rows could only be told apart by [copy], which does not
/// say what kind of document the copy is of.
 String get documentType;/// Which copy of a multi-document issue this row is — `"A"`/`"B"` on the
/// divorce booklet rows, `""` on every single-document row. Kept a plain
/// `String` for the same reason `status` is: the set belongs to the
/// server's document-type table, not to this entity.
 String get copy;/// The layouts this row's type produces (`card`, `booklet`). The spec's
/// table grows by row, so an enum would fail rows it was never told
/// about — see `certificate_file.dart` § `layout`.
 List<String> get layouts;/// One per-layout PDF. **The download currency** — the legacy `fileUrl`
/// above stays parsed but the spec says "Use `files[]`, not the legacy
/// `file_url` field". [hasStoredFile] and [fileForLayout] are the two
/// gates the download task reads through.
 List<CertificateFile> get files;/// Every person the certificate names — both spouses on a marriage row,
/// where the singular [holderName] cannot carry both.
 List<String> get holders;/// The validity horizon (`valid_until`), empty-string-on-the-wire meaning
/// absent for legacy rows — hence nullable, with the mapper collapsing
/// `''` to null so callers test one absence, not two.
 String? get validUntil;/// `valid` — the server's own current-validity verdict, which is not the
/// same question as [status]: `issued` implies it, but `expired` (a
/// public-verification-only status) and revoked rows answer differently.
/// Nullable because absent (`valid_until` empty, legacy rows) means
/// unknown, which `false` would misreport.
 bool? get valid;/// The PDF's language — `lo` bilingual Lao/English, `en` English only.
/// A plain `String`, not an enum, per the `status` rule above.
 String? get language;/// `reissued_from` — the row this one replaced, set on the *new* row of a
/// reissue chain. A link, parsed like [applicationId]: carried because
/// every wire field is parsed, rendered by no call site yet.
 String? get reissuedFrom;
/// Create a copy of IssuedCertificate
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$IssuedCertificateCopyWith<IssuedCertificate> get copyWith => _$IssuedCertificateCopyWithImpl<IssuedCertificate>(this as IssuedCertificate, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is IssuedCertificate&&(identical(other.id, id) || other.id == id)&&(identical(other.certificateNo, certificateNo) || other.certificateNo == certificateNo)&&(identical(other.applicationId, applicationId) || other.applicationId == applicationId)&&(identical(other.referenceNo, referenceNo) || other.referenceNo == referenceNo)&&(identical(other.serviceCode, serviceCode) || other.serviceCode == serviceCode)&&(identical(other.serviceName, serviceName) || other.serviceName == serviceName)&&(identical(other.holderName, holderName) || other.holderName == holderName)&&(identical(other.uin, uin) || other.uin == uin)&&(identical(other.issuedAt, issuedAt) || other.issuedAt == issuedAt)&&(identical(other.issuedByName, issuedByName) || other.issuedByName == issuedByName)&&(identical(other.status, status) || other.status == status)&&(identical(other.verifyCode, verifyCode) || other.verifyCode == verifyCode)&&(identical(other.verifyUrl, verifyUrl) || other.verifyUrl == verifyUrl)&&(identical(other.qrPayload, qrPayload) || other.qrPayload == qrPayload)&&(identical(other.fileUrl, fileUrl) || other.fileUrl == fileUrl)&&(identical(other.documentHash, documentHash) || other.documentHash == documentHash)&&(identical(other.documentType, documentType) || other.documentType == documentType)&&(identical(other.copy, copy) || other.copy == copy)&&const DeepCollectionEquality().equals(other.layouts, layouts)&&const DeepCollectionEquality().equals(other.files, files)&&const DeepCollectionEquality().equals(other.holders, holders)&&(identical(other.validUntil, validUntil) || other.validUntil == validUntil)&&(identical(other.valid, valid) || other.valid == valid)&&(identical(other.language, language) || other.language == language)&&(identical(other.reissuedFrom, reissuedFrom) || other.reissuedFrom == reissuedFrom));
}


@override
int get hashCode => Object.hashAll([runtimeType,id,certificateNo,applicationId,referenceNo,serviceCode,serviceName,holderName,uin,issuedAt,issuedByName,status,verifyCode,verifyUrl,qrPayload,fileUrl,documentHash,documentType,copy,const DeepCollectionEquality().hash(layouts),const DeepCollectionEquality().hash(files),const DeepCollectionEquality().hash(holders),validUntil,valid,language,reissuedFrom]);

@override
String toString() {
  return 'IssuedCertificate(id: $id, certificateNo: $certificateNo, applicationId: $applicationId, referenceNo: $referenceNo, serviceCode: $serviceCode, serviceName: $serviceName, holderName: $holderName, uin: $uin, issuedAt: $issuedAt, issuedByName: $issuedByName, status: $status, verifyCode: $verifyCode, verifyUrl: $verifyUrl, qrPayload: $qrPayload, fileUrl: $fileUrl, documentHash: $documentHash, documentType: $documentType, copy: $copy, layouts: $layouts, files: $files, holders: $holders, validUntil: $validUntil, valid: $valid, language: $language, reissuedFrom: $reissuedFrom)';
}


}

/// @nodoc
abstract mixin class $IssuedCertificateCopyWith<$Res>  {
  factory $IssuedCertificateCopyWith(IssuedCertificate value, $Res Function(IssuedCertificate) _then) = _$IssuedCertificateCopyWithImpl;
@useResult
$Res call({
 String id, String certificateNo, String? applicationId, String? referenceNo, String serviceCode, Bilingual? serviceName, String holderName, String? uin, String issuedAt, String? issuedByName, String status, String verifyCode, String? verifyUrl, String? qrPayload, String? fileUrl, String? documentHash, String documentType, String copy, List<String> layouts, List<CertificateFile> files, List<String> holders, String? validUntil, bool? valid, String? language, String? reissuedFrom
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
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? certificateNo = null,Object? applicationId = freezed,Object? referenceNo = freezed,Object? serviceCode = null,Object? serviceName = freezed,Object? holderName = null,Object? uin = freezed,Object? issuedAt = null,Object? issuedByName = freezed,Object? status = null,Object? verifyCode = null,Object? verifyUrl = freezed,Object? qrPayload = freezed,Object? fileUrl = freezed,Object? documentHash = freezed,Object? documentType = null,Object? copy = null,Object? layouts = null,Object? files = null,Object? holders = null,Object? validUntil = freezed,Object? valid = freezed,Object? language = freezed,Object? reissuedFrom = freezed,}) {
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
as String?,documentType: null == documentType ? _self.documentType : documentType // ignore: cast_nullable_to_non_nullable
as String,copy: null == copy ? _self.copy : copy // ignore: cast_nullable_to_non_nullable
as String,layouts: null == layouts ? _self.layouts : layouts // ignore: cast_nullable_to_non_nullable
as List<String>,files: null == files ? _self.files : files // ignore: cast_nullable_to_non_nullable
as List<CertificateFile>,holders: null == holders ? _self.holders : holders // ignore: cast_nullable_to_non_nullable
as List<String>,validUntil: freezed == validUntil ? _self.validUntil : validUntil // ignore: cast_nullable_to_non_nullable
as String?,valid: freezed == valid ? _self.valid : valid // ignore: cast_nullable_to_non_nullable
as bool?,language: freezed == language ? _self.language : language // ignore: cast_nullable_to_non_nullable
as String?,reissuedFrom: freezed == reissuedFrom ? _self.reissuedFrom : reissuedFrom // ignore: cast_nullable_to_non_nullable
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String certificateNo,  String? applicationId,  String? referenceNo,  String serviceCode,  Bilingual? serviceName,  String holderName,  String? uin,  String issuedAt,  String? issuedByName,  String status,  String verifyCode,  String? verifyUrl,  String? qrPayload,  String? fileUrl,  String? documentHash,  String documentType,  String copy,  List<String> layouts,  List<CertificateFile> files,  List<String> holders,  String? validUntil,  bool? valid,  String? language,  String? reissuedFrom)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _IssuedCertificate() when $default != null:
return $default(_that.id,_that.certificateNo,_that.applicationId,_that.referenceNo,_that.serviceCode,_that.serviceName,_that.holderName,_that.uin,_that.issuedAt,_that.issuedByName,_that.status,_that.verifyCode,_that.verifyUrl,_that.qrPayload,_that.fileUrl,_that.documentHash,_that.documentType,_that.copy,_that.layouts,_that.files,_that.holders,_that.validUntil,_that.valid,_that.language,_that.reissuedFrom);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String certificateNo,  String? applicationId,  String? referenceNo,  String serviceCode,  Bilingual? serviceName,  String holderName,  String? uin,  String issuedAt,  String? issuedByName,  String status,  String verifyCode,  String? verifyUrl,  String? qrPayload,  String? fileUrl,  String? documentHash,  String documentType,  String copy,  List<String> layouts,  List<CertificateFile> files,  List<String> holders,  String? validUntil,  bool? valid,  String? language,  String? reissuedFrom)  $default,) {final _that = this;
switch (_that) {
case _IssuedCertificate():
return $default(_that.id,_that.certificateNo,_that.applicationId,_that.referenceNo,_that.serviceCode,_that.serviceName,_that.holderName,_that.uin,_that.issuedAt,_that.issuedByName,_that.status,_that.verifyCode,_that.verifyUrl,_that.qrPayload,_that.fileUrl,_that.documentHash,_that.documentType,_that.copy,_that.layouts,_that.files,_that.holders,_that.validUntil,_that.valid,_that.language,_that.reissuedFrom);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String certificateNo,  String? applicationId,  String? referenceNo,  String serviceCode,  Bilingual? serviceName,  String holderName,  String? uin,  String issuedAt,  String? issuedByName,  String status,  String verifyCode,  String? verifyUrl,  String? qrPayload,  String? fileUrl,  String? documentHash,  String documentType,  String copy,  List<String> layouts,  List<CertificateFile> files,  List<String> holders,  String? validUntil,  bool? valid,  String? language,  String? reissuedFrom)?  $default,) {final _that = this;
switch (_that) {
case _IssuedCertificate() when $default != null:
return $default(_that.id,_that.certificateNo,_that.applicationId,_that.referenceNo,_that.serviceCode,_that.serviceName,_that.holderName,_that.uin,_that.issuedAt,_that.issuedByName,_that.status,_that.verifyCode,_that.verifyUrl,_that.qrPayload,_that.fileUrl,_that.documentHash,_that.documentType,_that.copy,_that.layouts,_that.files,_that.holders,_that.validUntil,_that.valid,_that.language,_that.reissuedFrom);case _:
  return null;

}
}

}

/// @nodoc


class _IssuedCertificate extends IssuedCertificate {
  const _IssuedCertificate({required this.id, required this.certificateNo, this.applicationId, this.referenceNo, required this.serviceCode, this.serviceName, required this.holderName, this.uin, required this.issuedAt, this.issuedByName, required this.status, required this.verifyCode, this.verifyUrl, this.qrPayload, this.fileUrl, this.documentHash, this.documentType = '', this.copy = '', final  List<String> layouts = const <String>[], final  List<CertificateFile> files = const <CertificateFile>[], final  List<String> holders = const <String>[], this.validUntil, this.valid, this.language, this.reissuedFrom}): _layouts = layouts,_files = files,_holders = holders,super._();
  

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
// ---- The v2 keys of MOBILE-API-E-CERTIFICATES.md (§ Certificate model,
// list item in § Citizen endpoints), each defaulted to its empty shape so
// the legacy rows — which send none of them — keep parsing unchanged.
// `service` (the bilingual object) is mapped onto [serviceName]
// new-first, `service_name` falling back; see `certificate_wire.dart`.
/// `document_type` — the certificate type's three-letter code (`RES`,
/// `BIR`, `DEA`, `MAR`, `DIV`, `FBK`), as the spec's § Certificate model
/// table lists them. A plain `String` for the `status` reason: the table
/// grows by row and an enum would fail a type it was never told about.
///
/// **Added 2026-10-22 (review I-2).** It was the one list-item key
/// `issuedCertificateFrom` did not read, and the spec's implementation
/// checklist asks for exactly it: *"Certificates list … grouped by
/// `application_id`; label by `document_type` and `copy`"*. Without it a
/// divorce's three rows could only be told apart by [copy], which does not
/// say what kind of document the copy is of.
@override@JsonKey() final  String documentType;
/// Which copy of a multi-document issue this row is — `"A"`/`"B"` on the
/// divorce booklet rows, `""` on every single-document row. Kept a plain
/// `String` for the same reason `status` is: the set belongs to the
/// server's document-type table, not to this entity.
@override@JsonKey() final  String copy;
/// The layouts this row's type produces (`card`, `booklet`). The spec's
/// table grows by row, so an enum would fail rows it was never told
/// about — see `certificate_file.dart` § `layout`.
 final  List<String> _layouts;
/// The layouts this row's type produces (`card`, `booklet`). The spec's
/// table grows by row, so an enum would fail rows it was never told
/// about — see `certificate_file.dart` § `layout`.
@override@JsonKey() List<String> get layouts {
  if (_layouts is EqualUnmodifiableListView) return _layouts;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_layouts);
}

/// One per-layout PDF. **The download currency** — the legacy `fileUrl`
/// above stays parsed but the spec says "Use `files[]`, not the legacy
/// `file_url` field". [hasStoredFile] and [fileForLayout] are the two
/// gates the download task reads through.
 final  List<CertificateFile> _files;
/// One per-layout PDF. **The download currency** — the legacy `fileUrl`
/// above stays parsed but the spec says "Use `files[]`, not the legacy
/// `file_url` field". [hasStoredFile] and [fileForLayout] are the two
/// gates the download task reads through.
@override@JsonKey() List<CertificateFile> get files {
  if (_files is EqualUnmodifiableListView) return _files;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_files);
}

/// Every person the certificate names — both spouses on a marriage row,
/// where the singular [holderName] cannot carry both.
 final  List<String> _holders;
/// Every person the certificate names — both spouses on a marriage row,
/// where the singular [holderName] cannot carry both.
@override@JsonKey() List<String> get holders {
  if (_holders is EqualUnmodifiableListView) return _holders;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_holders);
}

/// The validity horizon (`valid_until`), empty-string-on-the-wire meaning
/// absent for legacy rows — hence nullable, with the mapper collapsing
/// `''` to null so callers test one absence, not two.
@override final  String? validUntil;
/// `valid` — the server's own current-validity verdict, which is not the
/// same question as [status]: `issued` implies it, but `expired` (a
/// public-verification-only status) and revoked rows answer differently.
/// Nullable because absent (`valid_until` empty, legacy rows) means
/// unknown, which `false` would misreport.
@override final  bool? valid;
/// The PDF's language — `lo` bilingual Lao/English, `en` English only.
/// A plain `String`, not an enum, per the `status` rule above.
@override final  String? language;
/// `reissued_from` — the row this one replaced, set on the *new* row of a
/// reissue chain. A link, parsed like [applicationId]: carried because
/// every wire field is parsed, rendered by no call site yet.
@override final  String? reissuedFrom;

/// Create a copy of IssuedCertificate
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$IssuedCertificateCopyWith<_IssuedCertificate> get copyWith => __$IssuedCertificateCopyWithImpl<_IssuedCertificate>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _IssuedCertificate&&(identical(other.id, id) || other.id == id)&&(identical(other.certificateNo, certificateNo) || other.certificateNo == certificateNo)&&(identical(other.applicationId, applicationId) || other.applicationId == applicationId)&&(identical(other.referenceNo, referenceNo) || other.referenceNo == referenceNo)&&(identical(other.serviceCode, serviceCode) || other.serviceCode == serviceCode)&&(identical(other.serviceName, serviceName) || other.serviceName == serviceName)&&(identical(other.holderName, holderName) || other.holderName == holderName)&&(identical(other.uin, uin) || other.uin == uin)&&(identical(other.issuedAt, issuedAt) || other.issuedAt == issuedAt)&&(identical(other.issuedByName, issuedByName) || other.issuedByName == issuedByName)&&(identical(other.status, status) || other.status == status)&&(identical(other.verifyCode, verifyCode) || other.verifyCode == verifyCode)&&(identical(other.verifyUrl, verifyUrl) || other.verifyUrl == verifyUrl)&&(identical(other.qrPayload, qrPayload) || other.qrPayload == qrPayload)&&(identical(other.fileUrl, fileUrl) || other.fileUrl == fileUrl)&&(identical(other.documentHash, documentHash) || other.documentHash == documentHash)&&(identical(other.documentType, documentType) || other.documentType == documentType)&&(identical(other.copy, copy) || other.copy == copy)&&const DeepCollectionEquality().equals(other._layouts, _layouts)&&const DeepCollectionEquality().equals(other._files, _files)&&const DeepCollectionEquality().equals(other._holders, _holders)&&(identical(other.validUntil, validUntil) || other.validUntil == validUntil)&&(identical(other.valid, valid) || other.valid == valid)&&(identical(other.language, language) || other.language == language)&&(identical(other.reissuedFrom, reissuedFrom) || other.reissuedFrom == reissuedFrom));
}


@override
int get hashCode => Object.hashAll([runtimeType,id,certificateNo,applicationId,referenceNo,serviceCode,serviceName,holderName,uin,issuedAt,issuedByName,status,verifyCode,verifyUrl,qrPayload,fileUrl,documentHash,documentType,copy,const DeepCollectionEquality().hash(_layouts),const DeepCollectionEquality().hash(_files),const DeepCollectionEquality().hash(_holders),validUntil,valid,language,reissuedFrom]);

@override
String toString() {
  return 'IssuedCertificate(id: $id, certificateNo: $certificateNo, applicationId: $applicationId, referenceNo: $referenceNo, serviceCode: $serviceCode, serviceName: $serviceName, holderName: $holderName, uin: $uin, issuedAt: $issuedAt, issuedByName: $issuedByName, status: $status, verifyCode: $verifyCode, verifyUrl: $verifyUrl, qrPayload: $qrPayload, fileUrl: $fileUrl, documentHash: $documentHash, documentType: $documentType, copy: $copy, layouts: $layouts, files: $files, holders: $holders, validUntil: $validUntil, valid: $valid, language: $language, reissuedFrom: $reissuedFrom)';
}


}

/// @nodoc
abstract mixin class _$IssuedCertificateCopyWith<$Res> implements $IssuedCertificateCopyWith<$Res> {
  factory _$IssuedCertificateCopyWith(_IssuedCertificate value, $Res Function(_IssuedCertificate) _then) = __$IssuedCertificateCopyWithImpl;
@override @useResult
$Res call({
 String id, String certificateNo, String? applicationId, String? referenceNo, String serviceCode, Bilingual? serviceName, String holderName, String? uin, String issuedAt, String? issuedByName, String status, String verifyCode, String? verifyUrl, String? qrPayload, String? fileUrl, String? documentHash, String documentType, String copy, List<String> layouts, List<CertificateFile> files, List<String> holders, String? validUntil, bool? valid, String? language, String? reissuedFrom
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
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? certificateNo = null,Object? applicationId = freezed,Object? referenceNo = freezed,Object? serviceCode = null,Object? serviceName = freezed,Object? holderName = null,Object? uin = freezed,Object? issuedAt = null,Object? issuedByName = freezed,Object? status = null,Object? verifyCode = null,Object? verifyUrl = freezed,Object? qrPayload = freezed,Object? fileUrl = freezed,Object? documentHash = freezed,Object? documentType = null,Object? copy = null,Object? layouts = null,Object? files = null,Object? holders = null,Object? validUntil = freezed,Object? valid = freezed,Object? language = freezed,Object? reissuedFrom = freezed,}) {
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
as String?,documentType: null == documentType ? _self.documentType : documentType // ignore: cast_nullable_to_non_nullable
as String,copy: null == copy ? _self.copy : copy // ignore: cast_nullable_to_non_nullable
as String,layouts: null == layouts ? _self._layouts : layouts // ignore: cast_nullable_to_non_nullable
as List<String>,files: null == files ? _self._files : files // ignore: cast_nullable_to_non_nullable
as List<CertificateFile>,holders: null == holders ? _self._holders : holders // ignore: cast_nullable_to_non_nullable
as List<String>,validUntil: freezed == validUntil ? _self.validUntil : validUntil // ignore: cast_nullable_to_non_nullable
as String?,valid: freezed == valid ? _self.valid : valid // ignore: cast_nullable_to_non_nullable
as bool?,language: freezed == language ? _self.language : language // ignore: cast_nullable_to_non_nullable
as String?,reissuedFrom: freezed == reissuedFrom ? _self.reissuedFrom : reissuedFrom // ignore: cast_nullable_to_non_nullable
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
