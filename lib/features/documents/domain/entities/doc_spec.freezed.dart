// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'doc_spec.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$DocField {

 String get label; String get value;
/// Create a copy of DocField
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DocFieldCopyWith<DocField> get copyWith => _$DocFieldCopyWithImpl<DocField>(this as DocField, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DocField&&(identical(other.label, label) || other.label == label)&&(identical(other.value, value) || other.value == value));
}


@override
int get hashCode => Object.hash(runtimeType,label,value);

@override
String toString() {
  return 'DocField(label: $label, value: $value)';
}


}

/// @nodoc
abstract mixin class $DocFieldCopyWith<$Res>  {
  factory $DocFieldCopyWith(DocField value, $Res Function(DocField) _then) = _$DocFieldCopyWithImpl;
@useResult
$Res call({
 String label, String value
});




}
/// @nodoc
class _$DocFieldCopyWithImpl<$Res>
    implements $DocFieldCopyWith<$Res> {
  _$DocFieldCopyWithImpl(this._self, this._then);

  final DocField _self;
  final $Res Function(DocField) _then;

/// Create a copy of DocField
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? label = null,Object? value = null,}) {
  return _then(_self.copyWith(
label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String,value: null == value ? _self.value : value // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [DocField].
extension DocFieldPatterns on DocField {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _DocField value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _DocField() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _DocField value)  $default,){
final _that = this;
switch (_that) {
case _DocField():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _DocField value)?  $default,){
final _that = this;
switch (_that) {
case _DocField() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String label,  String value)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _DocField() when $default != null:
return $default(_that.label,_that.value);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String label,  String value)  $default,) {final _that = this;
switch (_that) {
case _DocField():
return $default(_that.label,_that.value);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String label,  String value)?  $default,) {final _that = this;
switch (_that) {
case _DocField() when $default != null:
return $default(_that.label,_that.value);case _:
  return null;

}
}

}

/// @nodoc


class _DocField implements DocField {
  const _DocField({required this.label, required this.value});
  

@override final  String label;
@override final  String value;

/// Create a copy of DocField
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DocFieldCopyWith<_DocField> get copyWith => __$DocFieldCopyWithImpl<_DocField>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _DocField&&(identical(other.label, label) || other.label == label)&&(identical(other.value, value) || other.value == value));
}


@override
int get hashCode => Object.hash(runtimeType,label,value);

@override
String toString() {
  return 'DocField(label: $label, value: $value)';
}


}

/// @nodoc
abstract mixin class _$DocFieldCopyWith<$Res> implements $DocFieldCopyWith<$Res> {
  factory _$DocFieldCopyWith(_DocField value, $Res Function(_DocField) _then) = __$DocFieldCopyWithImpl;
@override @useResult
$Res call({
 String label, String value
});




}
/// @nodoc
class __$DocFieldCopyWithImpl<$Res>
    implements _$DocFieldCopyWith<$Res> {
  __$DocFieldCopyWithImpl(this._self, this._then);

  final _DocField _self;
  final $Res Function(_DocField) _then;

/// Create a copy of DocField
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? label = null,Object? value = null,}) {
  return _then(_DocField(
label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String,value: null == value ? _self.value : value // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc
mixin _$DocSpec {

/// Big document title, e.g. "National Identity Card".
 String get title;/// Small kicker above the title, e.g. "Civil Registration".
/// Painted **upper-cased** (`:124`), so it is stored as written.
 String get kicker; String get refNo; String get holderName;/// Issuing office / authority.
 String get office; List<DocField> get fields; String get issued;/// `validUntil?: string` — **absent on both live mappers**, so the
/// *VALID UNTIL* half of the strip never renders on the History path
/// (`B5-AC-72`). The field exists because the painter's source draws it
/// conditionally and porting the condition is cheaper than porting a
/// painter that cannot express it.
 String? get validUntil;/// Short verification code shown in the footer + faux QR.
 String get verifyCode;/// `hasPhoto?: boolean` — `doc.type.includes("id") || …("passport")`
/// (`data/documents.ts:113`), which only `docSpecFromDocument` sets. That
/// mapper is **dead** (Finding D) and is not ported, so on the History path
/// this is **always false** (`B5-AC-71`).
 bool get hasPhoto;
/// Create a copy of DocSpec
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DocSpecCopyWith<DocSpec> get copyWith => _$DocSpecCopyWithImpl<DocSpec>(this as DocSpec, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DocSpec&&(identical(other.title, title) || other.title == title)&&(identical(other.kicker, kicker) || other.kicker == kicker)&&(identical(other.refNo, refNo) || other.refNo == refNo)&&(identical(other.holderName, holderName) || other.holderName == holderName)&&(identical(other.office, office) || other.office == office)&&const DeepCollectionEquality().equals(other.fields, fields)&&(identical(other.issued, issued) || other.issued == issued)&&(identical(other.validUntil, validUntil) || other.validUntil == validUntil)&&(identical(other.verifyCode, verifyCode) || other.verifyCode == verifyCode)&&(identical(other.hasPhoto, hasPhoto) || other.hasPhoto == hasPhoto));
}


@override
int get hashCode => Object.hash(runtimeType,title,kicker,refNo,holderName,office,const DeepCollectionEquality().hash(fields),issued,validUntil,verifyCode,hasPhoto);

@override
String toString() {
  return 'DocSpec(title: $title, kicker: $kicker, refNo: $refNo, holderName: $holderName, office: $office, fields: $fields, issued: $issued, validUntil: $validUntil, verifyCode: $verifyCode, hasPhoto: $hasPhoto)';
}


}

/// @nodoc
abstract mixin class $DocSpecCopyWith<$Res>  {
  factory $DocSpecCopyWith(DocSpec value, $Res Function(DocSpec) _then) = _$DocSpecCopyWithImpl;
@useResult
$Res call({
 String title, String kicker, String refNo, String holderName, String office, List<DocField> fields, String issued, String? validUntil, String verifyCode, bool hasPhoto
});




}
/// @nodoc
class _$DocSpecCopyWithImpl<$Res>
    implements $DocSpecCopyWith<$Res> {
  _$DocSpecCopyWithImpl(this._self, this._then);

  final DocSpec _self;
  final $Res Function(DocSpec) _then;

/// Create a copy of DocSpec
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? title = null,Object? kicker = null,Object? refNo = null,Object? holderName = null,Object? office = null,Object? fields = null,Object? issued = null,Object? validUntil = freezed,Object? verifyCode = null,Object? hasPhoto = null,}) {
  return _then(_self.copyWith(
title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,kicker: null == kicker ? _self.kicker : kicker // ignore: cast_nullable_to_non_nullable
as String,refNo: null == refNo ? _self.refNo : refNo // ignore: cast_nullable_to_non_nullable
as String,holderName: null == holderName ? _self.holderName : holderName // ignore: cast_nullable_to_non_nullable
as String,office: null == office ? _self.office : office // ignore: cast_nullable_to_non_nullable
as String,fields: null == fields ? _self.fields : fields // ignore: cast_nullable_to_non_nullable
as List<DocField>,issued: null == issued ? _self.issued : issued // ignore: cast_nullable_to_non_nullable
as String,validUntil: freezed == validUntil ? _self.validUntil : validUntil // ignore: cast_nullable_to_non_nullable
as String?,verifyCode: null == verifyCode ? _self.verifyCode : verifyCode // ignore: cast_nullable_to_non_nullable
as String,hasPhoto: null == hasPhoto ? _self.hasPhoto : hasPhoto // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [DocSpec].
extension DocSpecPatterns on DocSpec {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _DocSpec value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _DocSpec() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _DocSpec value)  $default,){
final _that = this;
switch (_that) {
case _DocSpec():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _DocSpec value)?  $default,){
final _that = this;
switch (_that) {
case _DocSpec() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String title,  String kicker,  String refNo,  String holderName,  String office,  List<DocField> fields,  String issued,  String? validUntil,  String verifyCode,  bool hasPhoto)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _DocSpec() when $default != null:
return $default(_that.title,_that.kicker,_that.refNo,_that.holderName,_that.office,_that.fields,_that.issued,_that.validUntil,_that.verifyCode,_that.hasPhoto);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String title,  String kicker,  String refNo,  String holderName,  String office,  List<DocField> fields,  String issued,  String? validUntil,  String verifyCode,  bool hasPhoto)  $default,) {final _that = this;
switch (_that) {
case _DocSpec():
return $default(_that.title,_that.kicker,_that.refNo,_that.holderName,_that.office,_that.fields,_that.issued,_that.validUntil,_that.verifyCode,_that.hasPhoto);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String title,  String kicker,  String refNo,  String holderName,  String office,  List<DocField> fields,  String issued,  String? validUntil,  String verifyCode,  bool hasPhoto)?  $default,) {final _that = this;
switch (_that) {
case _DocSpec() when $default != null:
return $default(_that.title,_that.kicker,_that.refNo,_that.holderName,_that.office,_that.fields,_that.issued,_that.validUntil,_that.verifyCode,_that.hasPhoto);case _:
  return null;

}
}

}

/// @nodoc


class _DocSpec implements DocSpec {
  const _DocSpec({required this.title, required this.kicker, required this.refNo, required this.holderName, required this.office, final  List<DocField> fields = const <DocField>[], required this.issued, this.validUntil, required this.verifyCode, this.hasPhoto = false}): _fields = fields;
  

/// Big document title, e.g. "National Identity Card".
@override final  String title;
/// Small kicker above the title, e.g. "Civil Registration".
/// Painted **upper-cased** (`:124`), so it is stored as written.
@override final  String kicker;
@override final  String refNo;
@override final  String holderName;
/// Issuing office / authority.
@override final  String office;
 final  List<DocField> _fields;
@override@JsonKey() List<DocField> get fields {
  if (_fields is EqualUnmodifiableListView) return _fields;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_fields);
}

@override final  String issued;
/// `validUntil?: string` — **absent on both live mappers**, so the
/// *VALID UNTIL* half of the strip never renders on the History path
/// (`B5-AC-72`). The field exists because the painter's source draws it
/// conditionally and porting the condition is cheaper than porting a
/// painter that cannot express it.
@override final  String? validUntil;
/// Short verification code shown in the footer + faux QR.
@override final  String verifyCode;
/// `hasPhoto?: boolean` — `doc.type.includes("id") || …("passport")`
/// (`data/documents.ts:113`), which only `docSpecFromDocument` sets. That
/// mapper is **dead** (Finding D) and is not ported, so on the History path
/// this is **always false** (`B5-AC-71`).
@override@JsonKey() final  bool hasPhoto;

/// Create a copy of DocSpec
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DocSpecCopyWith<_DocSpec> get copyWith => __$DocSpecCopyWithImpl<_DocSpec>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _DocSpec&&(identical(other.title, title) || other.title == title)&&(identical(other.kicker, kicker) || other.kicker == kicker)&&(identical(other.refNo, refNo) || other.refNo == refNo)&&(identical(other.holderName, holderName) || other.holderName == holderName)&&(identical(other.office, office) || other.office == office)&&const DeepCollectionEquality().equals(other._fields, _fields)&&(identical(other.issued, issued) || other.issued == issued)&&(identical(other.validUntil, validUntil) || other.validUntil == validUntil)&&(identical(other.verifyCode, verifyCode) || other.verifyCode == verifyCode)&&(identical(other.hasPhoto, hasPhoto) || other.hasPhoto == hasPhoto));
}


@override
int get hashCode => Object.hash(runtimeType,title,kicker,refNo,holderName,office,const DeepCollectionEquality().hash(_fields),issued,validUntil,verifyCode,hasPhoto);

@override
String toString() {
  return 'DocSpec(title: $title, kicker: $kicker, refNo: $refNo, holderName: $holderName, office: $office, fields: $fields, issued: $issued, validUntil: $validUntil, verifyCode: $verifyCode, hasPhoto: $hasPhoto)';
}


}

/// @nodoc
abstract mixin class _$DocSpecCopyWith<$Res> implements $DocSpecCopyWith<$Res> {
  factory _$DocSpecCopyWith(_DocSpec value, $Res Function(_DocSpec) _then) = __$DocSpecCopyWithImpl;
@override @useResult
$Res call({
 String title, String kicker, String refNo, String holderName, String office, List<DocField> fields, String issued, String? validUntil, String verifyCode, bool hasPhoto
});




}
/// @nodoc
class __$DocSpecCopyWithImpl<$Res>
    implements _$DocSpecCopyWith<$Res> {
  __$DocSpecCopyWithImpl(this._self, this._then);

  final _DocSpec _self;
  final $Res Function(_DocSpec) _then;

/// Create a copy of DocSpec
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? title = null,Object? kicker = null,Object? refNo = null,Object? holderName = null,Object? office = null,Object? fields = null,Object? issued = null,Object? validUntil = freezed,Object? verifyCode = null,Object? hasPhoto = null,}) {
  return _then(_DocSpec(
title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,kicker: null == kicker ? _self.kicker : kicker // ignore: cast_nullable_to_non_nullable
as String,refNo: null == refNo ? _self.refNo : refNo // ignore: cast_nullable_to_non_nullable
as String,holderName: null == holderName ? _self.holderName : holderName // ignore: cast_nullable_to_non_nullable
as String,office: null == office ? _self.office : office // ignore: cast_nullable_to_non_nullable
as String,fields: null == fields ? _self._fields : fields // ignore: cast_nullable_to_non_nullable
as List<DocField>,issued: null == issued ? _self.issued : issued // ignore: cast_nullable_to_non_nullable
as String,validUntil: freezed == validUntil ? _self.validUntil : validUntil // ignore: cast_nullable_to_non_nullable
as String?,verifyCode: null == verifyCode ? _self.verifyCode : verifyCode // ignore: cast_nullable_to_non_nullable
as String,hasPhoto: null == hasPhoto ? _self.hasPhoto : hasPhoto // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
