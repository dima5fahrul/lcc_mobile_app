// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'attachment.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$Attachment {

 String get id;/// `"document" | "photo" | "signature" | "stamp"` (`types.ts:452`).
///
/// Carried as the wire string rather than an enum: nothing in B7 branches
/// on it, and an enum would need the same [CaseStatus.unknown]-shaped
/// escape hatch to survive a fifth kind — cost with no reader. B5 models it
/// properly when it builds the viewer that selects on it.
 String get kind; String get slot; String get label; String get fileName; String get fileUrl;// **`mime_type` (`types.ts:457`) is deliberately NOT carried**, and this is
// the § 6.9 `STATUS_META` disposition rather than an oversight. Measured:
// `grep -n mime HistoryDetailPage.tsx` returns nothing — the attachments
// card renders label-or-filename, slot, KB and the upload date (`:603-624`)
// and never the MIME type. Porting the field would model a value with zero
// readers on either side.
//
// It also trips **R-21** (`layering_test.dart:275`), which forbids the
// identifier repo-wide because `.mimeType` is how a file-type rejection
// gets hand-rolled once the picker is open. This entity is read-only and
// reaches no picker, so the guard's hit here was a false positive — but the
// right answer to a false positive on a field nothing reads is to drop the
// field, not to widen the guard. `PickedAttachment` (`:44`) and
// `application_usecases.dart:266` already record the same stance for the
// upload direction; this makes the read direction agree with them.
 int get sizeBytes; String get uploadedAt;
/// Create a copy of Attachment
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AttachmentCopyWith<Attachment> get copyWith => _$AttachmentCopyWithImpl<Attachment>(this as Attachment, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Attachment&&(identical(other.id, id) || other.id == id)&&(identical(other.kind, kind) || other.kind == kind)&&(identical(other.slot, slot) || other.slot == slot)&&(identical(other.label, label) || other.label == label)&&(identical(other.fileName, fileName) || other.fileName == fileName)&&(identical(other.fileUrl, fileUrl) || other.fileUrl == fileUrl)&&(identical(other.sizeBytes, sizeBytes) || other.sizeBytes == sizeBytes)&&(identical(other.uploadedAt, uploadedAt) || other.uploadedAt == uploadedAt));
}


@override
int get hashCode => Object.hash(runtimeType,id,kind,slot,label,fileName,fileUrl,sizeBytes,uploadedAt);

@override
String toString() {
  return 'Attachment(id: $id, kind: $kind, slot: $slot, label: $label, fileName: $fileName, fileUrl: $fileUrl, sizeBytes: $sizeBytes, uploadedAt: $uploadedAt)';
}


}

/// @nodoc
abstract mixin class $AttachmentCopyWith<$Res>  {
  factory $AttachmentCopyWith(Attachment value, $Res Function(Attachment) _then) = _$AttachmentCopyWithImpl;
@useResult
$Res call({
 String id, String kind, String slot, String label, String fileName, String fileUrl, int sizeBytes, String uploadedAt
});




}
/// @nodoc
class _$AttachmentCopyWithImpl<$Res>
    implements $AttachmentCopyWith<$Res> {
  _$AttachmentCopyWithImpl(this._self, this._then);

  final Attachment _self;
  final $Res Function(Attachment) _then;

/// Create a copy of Attachment
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? kind = null,Object? slot = null,Object? label = null,Object? fileName = null,Object? fileUrl = null,Object? sizeBytes = null,Object? uploadedAt = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as String,slot: null == slot ? _self.slot : slot // ignore: cast_nullable_to_non_nullable
as String,label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String,fileName: null == fileName ? _self.fileName : fileName // ignore: cast_nullable_to_non_nullable
as String,fileUrl: null == fileUrl ? _self.fileUrl : fileUrl // ignore: cast_nullable_to_non_nullable
as String,sizeBytes: null == sizeBytes ? _self.sizeBytes : sizeBytes // ignore: cast_nullable_to_non_nullable
as int,uploadedAt: null == uploadedAt ? _self.uploadedAt : uploadedAt // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [Attachment].
extension AttachmentPatterns on Attachment {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Attachment value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Attachment() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Attachment value)  $default,){
final _that = this;
switch (_that) {
case _Attachment():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Attachment value)?  $default,){
final _that = this;
switch (_that) {
case _Attachment() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String kind,  String slot,  String label,  String fileName,  String fileUrl,  int sizeBytes,  String uploadedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Attachment() when $default != null:
return $default(_that.id,_that.kind,_that.slot,_that.label,_that.fileName,_that.fileUrl,_that.sizeBytes,_that.uploadedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String kind,  String slot,  String label,  String fileName,  String fileUrl,  int sizeBytes,  String uploadedAt)  $default,) {final _that = this;
switch (_that) {
case _Attachment():
return $default(_that.id,_that.kind,_that.slot,_that.label,_that.fileName,_that.fileUrl,_that.sizeBytes,_that.uploadedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String kind,  String slot,  String label,  String fileName,  String fileUrl,  int sizeBytes,  String uploadedAt)?  $default,) {final _that = this;
switch (_that) {
case _Attachment() when $default != null:
return $default(_that.id,_that.kind,_that.slot,_that.label,_that.fileName,_that.fileUrl,_that.sizeBytes,_that.uploadedAt);case _:
  return null;

}
}

}

/// @nodoc


class _Attachment extends Attachment {
  const _Attachment({required this.id, required this.kind, required this.slot, required this.label, required this.fileName, required this.fileUrl, required this.sizeBytes, required this.uploadedAt}): super._();
  

@override final  String id;
/// `"document" | "photo" | "signature" | "stamp"` (`types.ts:452`).
///
/// Carried as the wire string rather than an enum: nothing in B7 branches
/// on it, and an enum would need the same [CaseStatus.unknown]-shaped
/// escape hatch to survive a fifth kind — cost with no reader. B5 models it
/// properly when it builds the viewer that selects on it.
@override final  String kind;
@override final  String slot;
@override final  String label;
@override final  String fileName;
@override final  String fileUrl;
// **`mime_type` (`types.ts:457`) is deliberately NOT carried**, and this is
// the § 6.9 `STATUS_META` disposition rather than an oversight. Measured:
// `grep -n mime HistoryDetailPage.tsx` returns nothing — the attachments
// card renders label-or-filename, slot, KB and the upload date (`:603-624`)
// and never the MIME type. Porting the field would model a value with zero
// readers on either side.
//
// It also trips **R-21** (`layering_test.dart:275`), which forbids the
// identifier repo-wide because `.mimeType` is how a file-type rejection
// gets hand-rolled once the picker is open. This entity is read-only and
// reaches no picker, so the guard's hit here was a false positive — but the
// right answer to a false positive on a field nothing reads is to drop the
// field, not to widen the guard. `PickedAttachment` (`:44`) and
// `application_usecases.dart:266` already record the same stance for the
// upload direction; this makes the read direction agree with them.
@override final  int sizeBytes;
@override final  String uploadedAt;

/// Create a copy of Attachment
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AttachmentCopyWith<_Attachment> get copyWith => __$AttachmentCopyWithImpl<_Attachment>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Attachment&&(identical(other.id, id) || other.id == id)&&(identical(other.kind, kind) || other.kind == kind)&&(identical(other.slot, slot) || other.slot == slot)&&(identical(other.label, label) || other.label == label)&&(identical(other.fileName, fileName) || other.fileName == fileName)&&(identical(other.fileUrl, fileUrl) || other.fileUrl == fileUrl)&&(identical(other.sizeBytes, sizeBytes) || other.sizeBytes == sizeBytes)&&(identical(other.uploadedAt, uploadedAt) || other.uploadedAt == uploadedAt));
}


@override
int get hashCode => Object.hash(runtimeType,id,kind,slot,label,fileName,fileUrl,sizeBytes,uploadedAt);

@override
String toString() {
  return 'Attachment(id: $id, kind: $kind, slot: $slot, label: $label, fileName: $fileName, fileUrl: $fileUrl, sizeBytes: $sizeBytes, uploadedAt: $uploadedAt)';
}


}

/// @nodoc
abstract mixin class _$AttachmentCopyWith<$Res> implements $AttachmentCopyWith<$Res> {
  factory _$AttachmentCopyWith(_Attachment value, $Res Function(_Attachment) _then) = __$AttachmentCopyWithImpl;
@override @useResult
$Res call({
 String id, String kind, String slot, String label, String fileName, String fileUrl, int sizeBytes, String uploadedAt
});




}
/// @nodoc
class __$AttachmentCopyWithImpl<$Res>
    implements _$AttachmentCopyWith<$Res> {
  __$AttachmentCopyWithImpl(this._self, this._then);

  final _Attachment _self;
  final $Res Function(_Attachment) _then;

/// Create a copy of Attachment
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? kind = null,Object? slot = null,Object? label = null,Object? fileName = null,Object? fileUrl = null,Object? sizeBytes = null,Object? uploadedAt = null,}) {
  return _then(_Attachment(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as String,slot: null == slot ? _self.slot : slot // ignore: cast_nullable_to_non_nullable
as String,label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String,fileName: null == fileName ? _self.fileName : fileName // ignore: cast_nullable_to_non_nullable
as String,fileUrl: null == fileUrl ? _self.fileUrl : fileUrl // ignore: cast_nullable_to_non_nullable
as String,sizeBytes: null == sizeBytes ? _self.sizeBytes : sizeBytes // ignore: cast_nullable_to_non_nullable
as int,uploadedAt: null == uploadedAt ? _self.uploadedAt : uploadedAt // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
