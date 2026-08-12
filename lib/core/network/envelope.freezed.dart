// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'envelope.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$PageMeta {

@JsonKey(name: 'page') int get page;@JsonKey(name: 'per_page') int get perPage;@JsonKey(name: 'total') int get total;@JsonKey(name: 'total_pages') int get totalPages;@JsonKey(name: 'has_next') bool get hasNext;@JsonKey(name: 'has_prev') bool get hasPrev;
/// Create a copy of PageMeta
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PageMetaCopyWith<PageMeta> get copyWith => _$PageMetaCopyWithImpl<PageMeta>(this as PageMeta, _$identity);

  /// Serializes this PageMeta to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PageMeta&&(identical(other.page, page) || other.page == page)&&(identical(other.perPage, perPage) || other.perPage == perPage)&&(identical(other.total, total) || other.total == total)&&(identical(other.totalPages, totalPages) || other.totalPages == totalPages)&&(identical(other.hasNext, hasNext) || other.hasNext == hasNext)&&(identical(other.hasPrev, hasPrev) || other.hasPrev == hasPrev));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,page,perPage,total,totalPages,hasNext,hasPrev);

@override
String toString() {
  return 'PageMeta(page: $page, perPage: $perPage, total: $total, totalPages: $totalPages, hasNext: $hasNext, hasPrev: $hasPrev)';
}


}

/// @nodoc
abstract mixin class $PageMetaCopyWith<$Res>  {
  factory $PageMetaCopyWith(PageMeta value, $Res Function(PageMeta) _then) = _$PageMetaCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'page') int page,@JsonKey(name: 'per_page') int perPage,@JsonKey(name: 'total') int total,@JsonKey(name: 'total_pages') int totalPages,@JsonKey(name: 'has_next') bool hasNext,@JsonKey(name: 'has_prev') bool hasPrev
});




}
/// @nodoc
class _$PageMetaCopyWithImpl<$Res>
    implements $PageMetaCopyWith<$Res> {
  _$PageMetaCopyWithImpl(this._self, this._then);

  final PageMeta _self;
  final $Res Function(PageMeta) _then;

/// Create a copy of PageMeta
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? page = null,Object? perPage = null,Object? total = null,Object? totalPages = null,Object? hasNext = null,Object? hasPrev = null,}) {
  return _then(_self.copyWith(
page: null == page ? _self.page : page // ignore: cast_nullable_to_non_nullable
as int,perPage: null == perPage ? _self.perPage : perPage // ignore: cast_nullable_to_non_nullable
as int,total: null == total ? _self.total : total // ignore: cast_nullable_to_non_nullable
as int,totalPages: null == totalPages ? _self.totalPages : totalPages // ignore: cast_nullable_to_non_nullable
as int,hasNext: null == hasNext ? _self.hasNext : hasNext // ignore: cast_nullable_to_non_nullable
as bool,hasPrev: null == hasPrev ? _self.hasPrev : hasPrev // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [PageMeta].
extension PageMetaPatterns on PageMeta {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PageMeta value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PageMeta() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PageMeta value)  $default,){
final _that = this;
switch (_that) {
case _PageMeta():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PageMeta value)?  $default,){
final _that = this;
switch (_that) {
case _PageMeta() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'page')  int page, @JsonKey(name: 'per_page')  int perPage, @JsonKey(name: 'total')  int total, @JsonKey(name: 'total_pages')  int totalPages, @JsonKey(name: 'has_next')  bool hasNext, @JsonKey(name: 'has_prev')  bool hasPrev)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PageMeta() when $default != null:
return $default(_that.page,_that.perPage,_that.total,_that.totalPages,_that.hasNext,_that.hasPrev);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'page')  int page, @JsonKey(name: 'per_page')  int perPage, @JsonKey(name: 'total')  int total, @JsonKey(name: 'total_pages')  int totalPages, @JsonKey(name: 'has_next')  bool hasNext, @JsonKey(name: 'has_prev')  bool hasPrev)  $default,) {final _that = this;
switch (_that) {
case _PageMeta():
return $default(_that.page,_that.perPage,_that.total,_that.totalPages,_that.hasNext,_that.hasPrev);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'page')  int page, @JsonKey(name: 'per_page')  int perPage, @JsonKey(name: 'total')  int total, @JsonKey(name: 'total_pages')  int totalPages, @JsonKey(name: 'has_next')  bool hasNext, @JsonKey(name: 'has_prev')  bool hasPrev)?  $default,) {final _that = this;
switch (_that) {
case _PageMeta() when $default != null:
return $default(_that.page,_that.perPage,_that.total,_that.totalPages,_that.hasNext,_that.hasPrev);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PageMeta implements PageMeta {
  const _PageMeta({@JsonKey(name: 'page') required this.page, @JsonKey(name: 'per_page') required this.perPage, @JsonKey(name: 'total') required this.total, @JsonKey(name: 'total_pages') required this.totalPages, @JsonKey(name: 'has_next') required this.hasNext, @JsonKey(name: 'has_prev') required this.hasPrev});
  factory _PageMeta.fromJson(Map<String, dynamic> json) => _$PageMetaFromJson(json);

@override@JsonKey(name: 'page') final  int page;
@override@JsonKey(name: 'per_page') final  int perPage;
@override@JsonKey(name: 'total') final  int total;
@override@JsonKey(name: 'total_pages') final  int totalPages;
@override@JsonKey(name: 'has_next') final  bool hasNext;
@override@JsonKey(name: 'has_prev') final  bool hasPrev;

/// Create a copy of PageMeta
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PageMetaCopyWith<_PageMeta> get copyWith => __$PageMetaCopyWithImpl<_PageMeta>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PageMetaToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PageMeta&&(identical(other.page, page) || other.page == page)&&(identical(other.perPage, perPage) || other.perPage == perPage)&&(identical(other.total, total) || other.total == total)&&(identical(other.totalPages, totalPages) || other.totalPages == totalPages)&&(identical(other.hasNext, hasNext) || other.hasNext == hasNext)&&(identical(other.hasPrev, hasPrev) || other.hasPrev == hasPrev));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,page,perPage,total,totalPages,hasNext,hasPrev);

@override
String toString() {
  return 'PageMeta(page: $page, perPage: $perPage, total: $total, totalPages: $totalPages, hasNext: $hasNext, hasPrev: $hasPrev)';
}


}

/// @nodoc
abstract mixin class _$PageMetaCopyWith<$Res> implements $PageMetaCopyWith<$Res> {
  factory _$PageMetaCopyWith(_PageMeta value, $Res Function(_PageMeta) _then) = __$PageMetaCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'page') int page,@JsonKey(name: 'per_page') int perPage,@JsonKey(name: 'total') int total,@JsonKey(name: 'total_pages') int totalPages,@JsonKey(name: 'has_next') bool hasNext,@JsonKey(name: 'has_prev') bool hasPrev
});




}
/// @nodoc
class __$PageMetaCopyWithImpl<$Res>
    implements _$PageMetaCopyWith<$Res> {
  __$PageMetaCopyWithImpl(this._self, this._then);

  final _PageMeta _self;
  final $Res Function(_PageMeta) _then;

/// Create a copy of PageMeta
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? page = null,Object? perPage = null,Object? total = null,Object? totalPages = null,Object? hasNext = null,Object? hasPrev = null,}) {
  return _then(_PageMeta(
page: null == page ? _self.page : page // ignore: cast_nullable_to_non_nullable
as int,perPage: null == perPage ? _self.perPage : perPage // ignore: cast_nullable_to_non_nullable
as int,total: null == total ? _self.total : total // ignore: cast_nullable_to_non_nullable
as int,totalPages: null == totalPages ? _self.totalPages : totalPages // ignore: cast_nullable_to_non_nullable
as int,hasNext: null == hasNext ? _self.hasNext : hasNext // ignore: cast_nullable_to_non_nullable
as bool,hasPrev: null == hasPrev ? _self.hasPrev : hasPrev // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}


/// @nodoc
mixin _$FieldError {

@JsonKey(name: 'field') String get field;@JsonKey(name: 'rule') String? get rule;@JsonKey(name: 'message') String get message;
/// Create a copy of FieldError
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$FieldErrorCopyWith<FieldError> get copyWith => _$FieldErrorCopyWithImpl<FieldError>(this as FieldError, _$identity);

  /// Serializes this FieldError to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is FieldError&&(identical(other.field, field) || other.field == field)&&(identical(other.rule, rule) || other.rule == rule)&&(identical(other.message, message) || other.message == message));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,field,rule,message);

@override
String toString() {
  return 'FieldError(field: $field, rule: $rule, message: $message)';
}


}

/// @nodoc
abstract mixin class $FieldErrorCopyWith<$Res>  {
  factory $FieldErrorCopyWith(FieldError value, $Res Function(FieldError) _then) = _$FieldErrorCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'field') String field,@JsonKey(name: 'rule') String? rule,@JsonKey(name: 'message') String message
});




}
/// @nodoc
class _$FieldErrorCopyWithImpl<$Res>
    implements $FieldErrorCopyWith<$Res> {
  _$FieldErrorCopyWithImpl(this._self, this._then);

  final FieldError _self;
  final $Res Function(FieldError) _then;

/// Create a copy of FieldError
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? field = null,Object? rule = freezed,Object? message = null,}) {
  return _then(_self.copyWith(
field: null == field ? _self.field : field // ignore: cast_nullable_to_non_nullable
as String,rule: freezed == rule ? _self.rule : rule // ignore: cast_nullable_to_non_nullable
as String?,message: null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [FieldError].
extension FieldErrorPatterns on FieldError {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _FieldError value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _FieldError() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _FieldError value)  $default,){
final _that = this;
switch (_that) {
case _FieldError():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _FieldError value)?  $default,){
final _that = this;
switch (_that) {
case _FieldError() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'field')  String field, @JsonKey(name: 'rule')  String? rule, @JsonKey(name: 'message')  String message)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _FieldError() when $default != null:
return $default(_that.field,_that.rule,_that.message);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'field')  String field, @JsonKey(name: 'rule')  String? rule, @JsonKey(name: 'message')  String message)  $default,) {final _that = this;
switch (_that) {
case _FieldError():
return $default(_that.field,_that.rule,_that.message);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'field')  String field, @JsonKey(name: 'rule')  String? rule, @JsonKey(name: 'message')  String message)?  $default,) {final _that = this;
switch (_that) {
case _FieldError() when $default != null:
return $default(_that.field,_that.rule,_that.message);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _FieldError implements FieldError {
  const _FieldError({@JsonKey(name: 'field') required this.field, @JsonKey(name: 'rule') this.rule, @JsonKey(name: 'message') required this.message});
  factory _FieldError.fromJson(Map<String, dynamic> json) => _$FieldErrorFromJson(json);

@override@JsonKey(name: 'field') final  String field;
@override@JsonKey(name: 'rule') final  String? rule;
@override@JsonKey(name: 'message') final  String message;

/// Create a copy of FieldError
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$FieldErrorCopyWith<_FieldError> get copyWith => __$FieldErrorCopyWithImpl<_FieldError>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$FieldErrorToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _FieldError&&(identical(other.field, field) || other.field == field)&&(identical(other.rule, rule) || other.rule == rule)&&(identical(other.message, message) || other.message == message));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,field,rule,message);

@override
String toString() {
  return 'FieldError(field: $field, rule: $rule, message: $message)';
}


}

/// @nodoc
abstract mixin class _$FieldErrorCopyWith<$Res> implements $FieldErrorCopyWith<$Res> {
  factory _$FieldErrorCopyWith(_FieldError value, $Res Function(_FieldError) _then) = __$FieldErrorCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'field') String field,@JsonKey(name: 'rule') String? rule,@JsonKey(name: 'message') String message
});




}
/// @nodoc
class __$FieldErrorCopyWithImpl<$Res>
    implements _$FieldErrorCopyWith<$Res> {
  __$FieldErrorCopyWithImpl(this._self, this._then);

  final _FieldError _self;
  final $Res Function(_FieldError) _then;

/// Create a copy of FieldError
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? field = null,Object? rule = freezed,Object? message = null,}) {
  return _then(_FieldError(
field: null == field ? _self.field : field // ignore: cast_nullable_to_non_nullable
as String,rule: freezed == rule ? _self.rule : rule // ignore: cast_nullable_to_non_nullable
as String?,message: null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$Envelope<T> {

@JsonKey(name: 'success') bool get success;@JsonKey(name: 'message') String get message;@JsonKey(name: 'data') T? get data;@JsonKey(name: 'meta') PageMeta? get meta;@JsonKey(name: 'code') String? get code;@JsonKey(name: 'errors') List<FieldError>? get errors;@JsonKey(name: 'request_id') String? get requestId;
/// Create a copy of Envelope
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$EnvelopeCopyWith<T, Envelope<T>> get copyWith => _$EnvelopeCopyWithImpl<T, Envelope<T>>(this as Envelope<T>, _$identity);

  /// Serializes this Envelope to a JSON map.
  Map<String, dynamic> toJson(Object? Function(T) toJsonT);


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Envelope<T>&&(identical(other.success, success) || other.success == success)&&(identical(other.message, message) || other.message == message)&&const DeepCollectionEquality().equals(other.data, data)&&(identical(other.meta, meta) || other.meta == meta)&&(identical(other.code, code) || other.code == code)&&const DeepCollectionEquality().equals(other.errors, errors)&&(identical(other.requestId, requestId) || other.requestId == requestId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,success,message,const DeepCollectionEquality().hash(data),meta,code,const DeepCollectionEquality().hash(errors),requestId);

@override
String toString() {
  return 'Envelope<$T>(success: $success, message: $message, data: $data, meta: $meta, code: $code, errors: $errors, requestId: $requestId)';
}


}

/// @nodoc
abstract mixin class $EnvelopeCopyWith<T,$Res>  {
  factory $EnvelopeCopyWith(Envelope<T> value, $Res Function(Envelope<T>) _then) = _$EnvelopeCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'success') bool success,@JsonKey(name: 'message') String message,@JsonKey(name: 'data') T? data,@JsonKey(name: 'meta') PageMeta? meta,@JsonKey(name: 'code') String? code,@JsonKey(name: 'errors') List<FieldError>? errors,@JsonKey(name: 'request_id') String? requestId
});


$PageMetaCopyWith<$Res>? get meta;

}
/// @nodoc
class _$EnvelopeCopyWithImpl<T,$Res>
    implements $EnvelopeCopyWith<T, $Res> {
  _$EnvelopeCopyWithImpl(this._self, this._then);

  final Envelope<T> _self;
  final $Res Function(Envelope<T>) _then;

/// Create a copy of Envelope
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? success = null,Object? message = null,Object? data = freezed,Object? meta = freezed,Object? code = freezed,Object? errors = freezed,Object? requestId = freezed,}) {
  return _then(_self.copyWith(
success: null == success ? _self.success : success // ignore: cast_nullable_to_non_nullable
as bool,message: null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,data: freezed == data ? _self.data : data // ignore: cast_nullable_to_non_nullable
as T?,meta: freezed == meta ? _self.meta : meta // ignore: cast_nullable_to_non_nullable
as PageMeta?,code: freezed == code ? _self.code : code // ignore: cast_nullable_to_non_nullable
as String?,errors: freezed == errors ? _self.errors : errors // ignore: cast_nullable_to_non_nullable
as List<FieldError>?,requestId: freezed == requestId ? _self.requestId : requestId // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}
/// Create a copy of Envelope
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PageMetaCopyWith<$Res>? get meta {
    if (_self.meta == null) {
    return null;
  }

  return $PageMetaCopyWith<$Res>(_self.meta!, (value) {
    return _then(_self.copyWith(meta: value));
  });
}
}


/// Adds pattern-matching-related methods to [Envelope].
extension EnvelopePatterns<T> on Envelope<T> {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Envelope<T> value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Envelope() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Envelope<T> value)  $default,){
final _that = this;
switch (_that) {
case _Envelope():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Envelope<T> value)?  $default,){
final _that = this;
switch (_that) {
case _Envelope() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'success')  bool success, @JsonKey(name: 'message')  String message, @JsonKey(name: 'data')  T? data, @JsonKey(name: 'meta')  PageMeta? meta, @JsonKey(name: 'code')  String? code, @JsonKey(name: 'errors')  List<FieldError>? errors, @JsonKey(name: 'request_id')  String? requestId)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Envelope() when $default != null:
return $default(_that.success,_that.message,_that.data,_that.meta,_that.code,_that.errors,_that.requestId);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'success')  bool success, @JsonKey(name: 'message')  String message, @JsonKey(name: 'data')  T? data, @JsonKey(name: 'meta')  PageMeta? meta, @JsonKey(name: 'code')  String? code, @JsonKey(name: 'errors')  List<FieldError>? errors, @JsonKey(name: 'request_id')  String? requestId)  $default,) {final _that = this;
switch (_that) {
case _Envelope():
return $default(_that.success,_that.message,_that.data,_that.meta,_that.code,_that.errors,_that.requestId);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'success')  bool success, @JsonKey(name: 'message')  String message, @JsonKey(name: 'data')  T? data, @JsonKey(name: 'meta')  PageMeta? meta, @JsonKey(name: 'code')  String? code, @JsonKey(name: 'errors')  List<FieldError>? errors, @JsonKey(name: 'request_id')  String? requestId)?  $default,) {final _that = this;
switch (_that) {
case _Envelope() when $default != null:
return $default(_that.success,_that.message,_that.data,_that.meta,_that.code,_that.errors,_that.requestId);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable(genericArgumentFactories: true)

class _Envelope<T> implements Envelope<T> {
  const _Envelope({@JsonKey(name: 'success') required this.success, @JsonKey(name: 'message') required this.message, @JsonKey(name: 'data') this.data, @JsonKey(name: 'meta') this.meta, @JsonKey(name: 'code') this.code, @JsonKey(name: 'errors') final  List<FieldError>? errors, @JsonKey(name: 'request_id') this.requestId}): _errors = errors;
  factory _Envelope.fromJson(Map<String, dynamic> json,T Function(Object?) fromJsonT) => _$EnvelopeFromJson(json,fromJsonT);

@override@JsonKey(name: 'success') final  bool success;
@override@JsonKey(name: 'message') final  String message;
@override@JsonKey(name: 'data') final  T? data;
@override@JsonKey(name: 'meta') final  PageMeta? meta;
@override@JsonKey(name: 'code') final  String? code;
 final  List<FieldError>? _errors;
@override@JsonKey(name: 'errors') List<FieldError>? get errors {
  final value = _errors;
  if (value == null) return null;
  if (_errors is EqualUnmodifiableListView) return _errors;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(value);
}

@override@JsonKey(name: 'request_id') final  String? requestId;

/// Create a copy of Envelope
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$EnvelopeCopyWith<T, _Envelope<T>> get copyWith => __$EnvelopeCopyWithImpl<T, _Envelope<T>>(this, _$identity);

@override
Map<String, dynamic> toJson(Object? Function(T) toJsonT) {
  return _$EnvelopeToJson<T>(this, toJsonT);
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Envelope<T>&&(identical(other.success, success) || other.success == success)&&(identical(other.message, message) || other.message == message)&&const DeepCollectionEquality().equals(other.data, data)&&(identical(other.meta, meta) || other.meta == meta)&&(identical(other.code, code) || other.code == code)&&const DeepCollectionEquality().equals(other._errors, _errors)&&(identical(other.requestId, requestId) || other.requestId == requestId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,success,message,const DeepCollectionEquality().hash(data),meta,code,const DeepCollectionEquality().hash(_errors),requestId);

@override
String toString() {
  return 'Envelope<$T>(success: $success, message: $message, data: $data, meta: $meta, code: $code, errors: $errors, requestId: $requestId)';
}


}

/// @nodoc
abstract mixin class _$EnvelopeCopyWith<T,$Res> implements $EnvelopeCopyWith<T, $Res> {
  factory _$EnvelopeCopyWith(_Envelope<T> value, $Res Function(_Envelope<T>) _then) = __$EnvelopeCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'success') bool success,@JsonKey(name: 'message') String message,@JsonKey(name: 'data') T? data,@JsonKey(name: 'meta') PageMeta? meta,@JsonKey(name: 'code') String? code,@JsonKey(name: 'errors') List<FieldError>? errors,@JsonKey(name: 'request_id') String? requestId
});


@override $PageMetaCopyWith<$Res>? get meta;

}
/// @nodoc
class __$EnvelopeCopyWithImpl<T,$Res>
    implements _$EnvelopeCopyWith<T, $Res> {
  __$EnvelopeCopyWithImpl(this._self, this._then);

  final _Envelope<T> _self;
  final $Res Function(_Envelope<T>) _then;

/// Create a copy of Envelope
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? success = null,Object? message = null,Object? data = freezed,Object? meta = freezed,Object? code = freezed,Object? errors = freezed,Object? requestId = freezed,}) {
  return _then(_Envelope<T>(
success: null == success ? _self.success : success // ignore: cast_nullable_to_non_nullable
as bool,message: null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,data: freezed == data ? _self.data : data // ignore: cast_nullable_to_non_nullable
as T?,meta: freezed == meta ? _self.meta : meta // ignore: cast_nullable_to_non_nullable
as PageMeta?,code: freezed == code ? _self.code : code // ignore: cast_nullable_to_non_nullable
as String?,errors: freezed == errors ? _self._errors : errors // ignore: cast_nullable_to_non_nullable
as List<FieldError>?,requestId: freezed == requestId ? _self.requestId : requestId // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

/// Create a copy of Envelope
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PageMetaCopyWith<$Res>? get meta {
    if (_self.meta == null) {
    return null;
  }

  return $PageMetaCopyWith<$Res>(_self.meta!, (value) {
    return _then(_self.copyWith(meta: value));
  });
}
}

// dart format on
