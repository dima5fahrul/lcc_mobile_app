// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'citizen_document.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$CitizenDocument {

 String get id; String get type; Bilingual get title; String get number; DocumentStatus get status; String? get issuedAt; String? get expiresAt; String get authority; bool get available; String? get fileUrl; String? get verifyCode;
/// Create a copy of CitizenDocument
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CitizenDocumentCopyWith<CitizenDocument> get copyWith => _$CitizenDocumentCopyWithImpl<CitizenDocument>(this as CitizenDocument, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CitizenDocument&&(identical(other.id, id) || other.id == id)&&(identical(other.type, type) || other.type == type)&&(identical(other.title, title) || other.title == title)&&(identical(other.number, number) || other.number == number)&&(identical(other.status, status) || other.status == status)&&(identical(other.issuedAt, issuedAt) || other.issuedAt == issuedAt)&&(identical(other.expiresAt, expiresAt) || other.expiresAt == expiresAt)&&(identical(other.authority, authority) || other.authority == authority)&&(identical(other.available, available) || other.available == available)&&(identical(other.fileUrl, fileUrl) || other.fileUrl == fileUrl)&&(identical(other.verifyCode, verifyCode) || other.verifyCode == verifyCode));
}


@override
int get hashCode => Object.hash(runtimeType,id,type,title,number,status,issuedAt,expiresAt,authority,available,fileUrl,verifyCode);

@override
String toString() {
  return 'CitizenDocument(id: $id, type: $type, title: $title, number: $number, status: $status, issuedAt: $issuedAt, expiresAt: $expiresAt, authority: $authority, available: $available, fileUrl: $fileUrl, verifyCode: $verifyCode)';
}


}

/// @nodoc
abstract mixin class $CitizenDocumentCopyWith<$Res>  {
  factory $CitizenDocumentCopyWith(CitizenDocument value, $Res Function(CitizenDocument) _then) = _$CitizenDocumentCopyWithImpl;
@useResult
$Res call({
 String id, String type, Bilingual title, String number, DocumentStatus status, String? issuedAt, String? expiresAt, String authority, bool available, String? fileUrl, String? verifyCode
});


$BilingualCopyWith<$Res> get title;

}
/// @nodoc
class _$CitizenDocumentCopyWithImpl<$Res>
    implements $CitizenDocumentCopyWith<$Res> {
  _$CitizenDocumentCopyWithImpl(this._self, this._then);

  final CitizenDocument _self;
  final $Res Function(CitizenDocument) _then;

/// Create a copy of CitizenDocument
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? type = null,Object? title = null,Object? number = null,Object? status = null,Object? issuedAt = freezed,Object? expiresAt = freezed,Object? authority = null,Object? available = null,Object? fileUrl = freezed,Object? verifyCode = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as Bilingual,number: null == number ? _self.number : number // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as DocumentStatus,issuedAt: freezed == issuedAt ? _self.issuedAt : issuedAt // ignore: cast_nullable_to_non_nullable
as String?,expiresAt: freezed == expiresAt ? _self.expiresAt : expiresAt // ignore: cast_nullable_to_non_nullable
as String?,authority: null == authority ? _self.authority : authority // ignore: cast_nullable_to_non_nullable
as String,available: null == available ? _self.available : available // ignore: cast_nullable_to_non_nullable
as bool,fileUrl: freezed == fileUrl ? _self.fileUrl : fileUrl // ignore: cast_nullable_to_non_nullable
as String?,verifyCode: freezed == verifyCode ? _self.verifyCode : verifyCode // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}
/// Create a copy of CitizenDocument
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BilingualCopyWith<$Res> get title {
  
  return $BilingualCopyWith<$Res>(_self.title, (value) {
    return _then(_self.copyWith(title: value));
  });
}
}


/// Adds pattern-matching-related methods to [CitizenDocument].
extension CitizenDocumentPatterns on CitizenDocument {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CitizenDocument value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CitizenDocument() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CitizenDocument value)  $default,){
final _that = this;
switch (_that) {
case _CitizenDocument():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CitizenDocument value)?  $default,){
final _that = this;
switch (_that) {
case _CitizenDocument() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String type,  Bilingual title,  String number,  DocumentStatus status,  String? issuedAt,  String? expiresAt,  String authority,  bool available,  String? fileUrl,  String? verifyCode)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CitizenDocument() when $default != null:
return $default(_that.id,_that.type,_that.title,_that.number,_that.status,_that.issuedAt,_that.expiresAt,_that.authority,_that.available,_that.fileUrl,_that.verifyCode);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String type,  Bilingual title,  String number,  DocumentStatus status,  String? issuedAt,  String? expiresAt,  String authority,  bool available,  String? fileUrl,  String? verifyCode)  $default,) {final _that = this;
switch (_that) {
case _CitizenDocument():
return $default(_that.id,_that.type,_that.title,_that.number,_that.status,_that.issuedAt,_that.expiresAt,_that.authority,_that.available,_that.fileUrl,_that.verifyCode);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String type,  Bilingual title,  String number,  DocumentStatus status,  String? issuedAt,  String? expiresAt,  String authority,  bool available,  String? fileUrl,  String? verifyCode)?  $default,) {final _that = this;
switch (_that) {
case _CitizenDocument() when $default != null:
return $default(_that.id,_that.type,_that.title,_that.number,_that.status,_that.issuedAt,_that.expiresAt,_that.authority,_that.available,_that.fileUrl,_that.verifyCode);case _:
  return null;

}
}

}

/// @nodoc


class _CitizenDocument extends CitizenDocument {
  const _CitizenDocument({required this.id, required this.type, required this.title, required this.number, required this.status, this.issuedAt, this.expiresAt, required this.authority, required this.available, this.fileUrl, this.verifyCode}): super._();
  

@override final  String id;
@override final  String type;
@override final  Bilingual title;
@override final  String number;
@override final  DocumentStatus status;
@override final  String? issuedAt;
@override final  String? expiresAt;
@override final  String authority;
@override final  bool available;
@override final  String? fileUrl;
@override final  String? verifyCode;

/// Create a copy of CitizenDocument
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CitizenDocumentCopyWith<_CitizenDocument> get copyWith => __$CitizenDocumentCopyWithImpl<_CitizenDocument>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CitizenDocument&&(identical(other.id, id) || other.id == id)&&(identical(other.type, type) || other.type == type)&&(identical(other.title, title) || other.title == title)&&(identical(other.number, number) || other.number == number)&&(identical(other.status, status) || other.status == status)&&(identical(other.issuedAt, issuedAt) || other.issuedAt == issuedAt)&&(identical(other.expiresAt, expiresAt) || other.expiresAt == expiresAt)&&(identical(other.authority, authority) || other.authority == authority)&&(identical(other.available, available) || other.available == available)&&(identical(other.fileUrl, fileUrl) || other.fileUrl == fileUrl)&&(identical(other.verifyCode, verifyCode) || other.verifyCode == verifyCode));
}


@override
int get hashCode => Object.hash(runtimeType,id,type,title,number,status,issuedAt,expiresAt,authority,available,fileUrl,verifyCode);

@override
String toString() {
  return 'CitizenDocument(id: $id, type: $type, title: $title, number: $number, status: $status, issuedAt: $issuedAt, expiresAt: $expiresAt, authority: $authority, available: $available, fileUrl: $fileUrl, verifyCode: $verifyCode)';
}


}

/// @nodoc
abstract mixin class _$CitizenDocumentCopyWith<$Res> implements $CitizenDocumentCopyWith<$Res> {
  factory _$CitizenDocumentCopyWith(_CitizenDocument value, $Res Function(_CitizenDocument) _then) = __$CitizenDocumentCopyWithImpl;
@override @useResult
$Res call({
 String id, String type, Bilingual title, String number, DocumentStatus status, String? issuedAt, String? expiresAt, String authority, bool available, String? fileUrl, String? verifyCode
});


@override $BilingualCopyWith<$Res> get title;

}
/// @nodoc
class __$CitizenDocumentCopyWithImpl<$Res>
    implements _$CitizenDocumentCopyWith<$Res> {
  __$CitizenDocumentCopyWithImpl(this._self, this._then);

  final _CitizenDocument _self;
  final $Res Function(_CitizenDocument) _then;

/// Create a copy of CitizenDocument
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? type = null,Object? title = null,Object? number = null,Object? status = null,Object? issuedAt = freezed,Object? expiresAt = freezed,Object? authority = null,Object? available = null,Object? fileUrl = freezed,Object? verifyCode = freezed,}) {
  return _then(_CitizenDocument(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as Bilingual,number: null == number ? _self.number : number // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as DocumentStatus,issuedAt: freezed == issuedAt ? _self.issuedAt : issuedAt // ignore: cast_nullable_to_non_nullable
as String?,expiresAt: freezed == expiresAt ? _self.expiresAt : expiresAt // ignore: cast_nullable_to_non_nullable
as String?,authority: null == authority ? _self.authority : authority // ignore: cast_nullable_to_non_nullable
as String,available: null == available ? _self.available : available // ignore: cast_nullable_to_non_nullable
as bool,fileUrl: freezed == fileUrl ? _self.fileUrl : fileUrl // ignore: cast_nullable_to_non_nullable
as String?,verifyCode: freezed == verifyCode ? _self.verifyCode : verifyCode // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

/// Create a copy of CitizenDocument
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BilingualCopyWith<$Res> get title {
  
  return $BilingualCopyWith<$Res>(_self.title, (value) {
    return _then(_self.copyWith(title: value));
  });
}
}

// dart format on
