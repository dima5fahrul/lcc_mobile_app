// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'certificate_file.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$CertificateFile {

 String get layout; String get url; String get sha256;
/// Create a copy of CertificateFile
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CertificateFileCopyWith<CertificateFile> get copyWith => _$CertificateFileCopyWithImpl<CertificateFile>(this as CertificateFile, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CertificateFile&&(identical(other.layout, layout) || other.layout == layout)&&(identical(other.url, url) || other.url == url)&&(identical(other.sha256, sha256) || other.sha256 == sha256));
}


@override
int get hashCode => Object.hash(runtimeType,layout,url,sha256);

@override
String toString() {
  return 'CertificateFile(layout: $layout, url: $url, sha256: $sha256)';
}


}

/// @nodoc
abstract mixin class $CertificateFileCopyWith<$Res>  {
  factory $CertificateFileCopyWith(CertificateFile value, $Res Function(CertificateFile) _then) = _$CertificateFileCopyWithImpl;
@useResult
$Res call({
 String layout, String url, String sha256
});




}
/// @nodoc
class _$CertificateFileCopyWithImpl<$Res>
    implements $CertificateFileCopyWith<$Res> {
  _$CertificateFileCopyWithImpl(this._self, this._then);

  final CertificateFile _self;
  final $Res Function(CertificateFile) _then;

/// Create a copy of CertificateFile
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? layout = null,Object? url = null,Object? sha256 = null,}) {
  return _then(_self.copyWith(
layout: null == layout ? _self.layout : layout // ignore: cast_nullable_to_non_nullable
as String,url: null == url ? _self.url : url // ignore: cast_nullable_to_non_nullable
as String,sha256: null == sha256 ? _self.sha256 : sha256 // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [CertificateFile].
extension CertificateFilePatterns on CertificateFile {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CertificateFile value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CertificateFile() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CertificateFile value)  $default,){
final _that = this;
switch (_that) {
case _CertificateFile():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CertificateFile value)?  $default,){
final _that = this;
switch (_that) {
case _CertificateFile() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String layout,  String url,  String sha256)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CertificateFile() when $default != null:
return $default(_that.layout,_that.url,_that.sha256);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String layout,  String url,  String sha256)  $default,) {final _that = this;
switch (_that) {
case _CertificateFile():
return $default(_that.layout,_that.url,_that.sha256);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String layout,  String url,  String sha256)?  $default,) {final _that = this;
switch (_that) {
case _CertificateFile() when $default != null:
return $default(_that.layout,_that.url,_that.sha256);case _:
  return null;

}
}

}

/// @nodoc


class _CertificateFile implements CertificateFile {
  const _CertificateFile({required this.layout, required this.url, required this.sha256});
  

@override final  String layout;
@override final  String url;
@override final  String sha256;

/// Create a copy of CertificateFile
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CertificateFileCopyWith<_CertificateFile> get copyWith => __$CertificateFileCopyWithImpl<_CertificateFile>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CertificateFile&&(identical(other.layout, layout) || other.layout == layout)&&(identical(other.url, url) || other.url == url)&&(identical(other.sha256, sha256) || other.sha256 == sha256));
}


@override
int get hashCode => Object.hash(runtimeType,layout,url,sha256);

@override
String toString() {
  return 'CertificateFile(layout: $layout, url: $url, sha256: $sha256)';
}


}

/// @nodoc
abstract mixin class _$CertificateFileCopyWith<$Res> implements $CertificateFileCopyWith<$Res> {
  factory _$CertificateFileCopyWith(_CertificateFile value, $Res Function(_CertificateFile) _then) = __$CertificateFileCopyWithImpl;
@override @useResult
$Res call({
 String layout, String url, String sha256
});




}
/// @nodoc
class __$CertificateFileCopyWithImpl<$Res>
    implements _$CertificateFileCopyWith<$Res> {
  __$CertificateFileCopyWithImpl(this._self, this._then);

  final _CertificateFile _self;
  final $Res Function(_CertificateFile) _then;

/// Create a copy of CertificateFile
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? layout = null,Object? url = null,Object? sha256 = null,}) {
  return _then(_CertificateFile(
layout: null == layout ? _self.layout : layout // ignore: cast_nullable_to_non_nullable
as String,url: null == url ? _self.url : url // ignore: cast_nullable_to_non_nullable
as String,sha256: null == sha256 ? _self.sha256 : sha256 // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
