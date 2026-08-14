// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'payment_method.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$PaymentMethod {

 String get id;/// **The value that goes on the wire in a payment body** — never [id],
/// never [label], never [kind] (`B6-AC-36`, and `B6-AC-33` for top-up).
 String get code; Bilingual get label; PaymentMethodKind get kind; bool get enabled;/// **`double`, not `int` — measured, not assumed.** `types.ts:518` types it
/// `number`, and the live recording carries four fractional values:
/// `bcel-one 1.2`, `ldb-onepay 1.5`, `laoqr 0.8`, `unitel-money 1.8`
/// (three of the seven rows are `0`). An `int` field parses `1.2` to `1` —
/// a 17 % error on a *fee rate*, in the data layer, silently, on a batch
/// that moves money.
///
/// Nothing in either B6 file renders it today (it is absent from § 6.5's
/// call-site table), which is exactly why the wrong type would have
/// survived: no Tier can see a field nothing draws. Recorded here so the
/// first consumer inherits the right number.
 double get feePercent;/// English-only on the wire and rendered untranslated. See the library doc
/// (`B6-DIV-2`, FU-7).
 String get note; String? get logoUrl;/// A `#RRGGBB` string as the API sends it, or `''`. Parsed at the widget
/// edge with `AppColors.parseHex`, never stored as a `Color`.
 String get color;
/// Create a copy of PaymentMethod
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PaymentMethodCopyWith<PaymentMethod> get copyWith => _$PaymentMethodCopyWithImpl<PaymentMethod>(this as PaymentMethod, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PaymentMethod&&(identical(other.id, id) || other.id == id)&&(identical(other.code, code) || other.code == code)&&(identical(other.label, label) || other.label == label)&&(identical(other.kind, kind) || other.kind == kind)&&(identical(other.enabled, enabled) || other.enabled == enabled)&&(identical(other.feePercent, feePercent) || other.feePercent == feePercent)&&(identical(other.note, note) || other.note == note)&&(identical(other.logoUrl, logoUrl) || other.logoUrl == logoUrl)&&(identical(other.color, color) || other.color == color));
}


@override
int get hashCode => Object.hash(runtimeType,id,code,label,kind,enabled,feePercent,note,logoUrl,color);

@override
String toString() {
  return 'PaymentMethod(id: $id, code: $code, label: $label, kind: $kind, enabled: $enabled, feePercent: $feePercent, note: $note, logoUrl: $logoUrl, color: $color)';
}


}

/// @nodoc
abstract mixin class $PaymentMethodCopyWith<$Res>  {
  factory $PaymentMethodCopyWith(PaymentMethod value, $Res Function(PaymentMethod) _then) = _$PaymentMethodCopyWithImpl;
@useResult
$Res call({
 String id, String code, Bilingual label, PaymentMethodKind kind, bool enabled, double feePercent, String note, String? logoUrl, String color
});


$BilingualCopyWith<$Res> get label;

}
/// @nodoc
class _$PaymentMethodCopyWithImpl<$Res>
    implements $PaymentMethodCopyWith<$Res> {
  _$PaymentMethodCopyWithImpl(this._self, this._then);

  final PaymentMethod _self;
  final $Res Function(PaymentMethod) _then;

/// Create a copy of PaymentMethod
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? code = null,Object? label = null,Object? kind = null,Object? enabled = null,Object? feePercent = null,Object? note = null,Object? logoUrl = freezed,Object? color = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,code: null == code ? _self.code : code // ignore: cast_nullable_to_non_nullable
as String,label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as Bilingual,kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as PaymentMethodKind,enabled: null == enabled ? _self.enabled : enabled // ignore: cast_nullable_to_non_nullable
as bool,feePercent: null == feePercent ? _self.feePercent : feePercent // ignore: cast_nullable_to_non_nullable
as double,note: null == note ? _self.note : note // ignore: cast_nullable_to_non_nullable
as String,logoUrl: freezed == logoUrl ? _self.logoUrl : logoUrl // ignore: cast_nullable_to_non_nullable
as String?,color: null == color ? _self.color : color // ignore: cast_nullable_to_non_nullable
as String,
  ));
}
/// Create a copy of PaymentMethod
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BilingualCopyWith<$Res> get label {
  
  return $BilingualCopyWith<$Res>(_self.label, (value) {
    return _then(_self.copyWith(label: value));
  });
}
}


/// Adds pattern-matching-related methods to [PaymentMethod].
extension PaymentMethodPatterns on PaymentMethod {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PaymentMethod value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PaymentMethod() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PaymentMethod value)  $default,){
final _that = this;
switch (_that) {
case _PaymentMethod():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PaymentMethod value)?  $default,){
final _that = this;
switch (_that) {
case _PaymentMethod() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String code,  Bilingual label,  PaymentMethodKind kind,  bool enabled,  double feePercent,  String note,  String? logoUrl,  String color)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PaymentMethod() when $default != null:
return $default(_that.id,_that.code,_that.label,_that.kind,_that.enabled,_that.feePercent,_that.note,_that.logoUrl,_that.color);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String code,  Bilingual label,  PaymentMethodKind kind,  bool enabled,  double feePercent,  String note,  String? logoUrl,  String color)  $default,) {final _that = this;
switch (_that) {
case _PaymentMethod():
return $default(_that.id,_that.code,_that.label,_that.kind,_that.enabled,_that.feePercent,_that.note,_that.logoUrl,_that.color);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String code,  Bilingual label,  PaymentMethodKind kind,  bool enabled,  double feePercent,  String note,  String? logoUrl,  String color)?  $default,) {final _that = this;
switch (_that) {
case _PaymentMethod() when $default != null:
return $default(_that.id,_that.code,_that.label,_that.kind,_that.enabled,_that.feePercent,_that.note,_that.logoUrl,_that.color);case _:
  return null;

}
}

}

/// @nodoc


class _PaymentMethod implements PaymentMethod {
  const _PaymentMethod({required this.id, required this.code, required this.label, required this.kind, required this.enabled, this.feePercent = 0.0, this.note = '', this.logoUrl, this.color = ''});
  

@override final  String id;
/// **The value that goes on the wire in a payment body** — never [id],
/// never [label], never [kind] (`B6-AC-36`, and `B6-AC-33` for top-up).
@override final  String code;
@override final  Bilingual label;
@override final  PaymentMethodKind kind;
@override final  bool enabled;
/// **`double`, not `int` — measured, not assumed.** `types.ts:518` types it
/// `number`, and the live recording carries four fractional values:
/// `bcel-one 1.2`, `ldb-onepay 1.5`, `laoqr 0.8`, `unitel-money 1.8`
/// (three of the seven rows are `0`). An `int` field parses `1.2` to `1` —
/// a 17 % error on a *fee rate*, in the data layer, silently, on a batch
/// that moves money.
///
/// Nothing in either B6 file renders it today (it is absent from § 6.5's
/// call-site table), which is exactly why the wrong type would have
/// survived: no Tier can see a field nothing draws. Recorded here so the
/// first consumer inherits the right number.
@override@JsonKey() final  double feePercent;
/// English-only on the wire and rendered untranslated. See the library doc
/// (`B6-DIV-2`, FU-7).
@override@JsonKey() final  String note;
@override final  String? logoUrl;
/// A `#RRGGBB` string as the API sends it, or `''`. Parsed at the widget
/// edge with `AppColors.parseHex`, never stored as a `Color`.
@override@JsonKey() final  String color;

/// Create a copy of PaymentMethod
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PaymentMethodCopyWith<_PaymentMethod> get copyWith => __$PaymentMethodCopyWithImpl<_PaymentMethod>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PaymentMethod&&(identical(other.id, id) || other.id == id)&&(identical(other.code, code) || other.code == code)&&(identical(other.label, label) || other.label == label)&&(identical(other.kind, kind) || other.kind == kind)&&(identical(other.enabled, enabled) || other.enabled == enabled)&&(identical(other.feePercent, feePercent) || other.feePercent == feePercent)&&(identical(other.note, note) || other.note == note)&&(identical(other.logoUrl, logoUrl) || other.logoUrl == logoUrl)&&(identical(other.color, color) || other.color == color));
}


@override
int get hashCode => Object.hash(runtimeType,id,code,label,kind,enabled,feePercent,note,logoUrl,color);

@override
String toString() {
  return 'PaymentMethod(id: $id, code: $code, label: $label, kind: $kind, enabled: $enabled, feePercent: $feePercent, note: $note, logoUrl: $logoUrl, color: $color)';
}


}

/// @nodoc
abstract mixin class _$PaymentMethodCopyWith<$Res> implements $PaymentMethodCopyWith<$Res> {
  factory _$PaymentMethodCopyWith(_PaymentMethod value, $Res Function(_PaymentMethod) _then) = __$PaymentMethodCopyWithImpl;
@override @useResult
$Res call({
 String id, String code, Bilingual label, PaymentMethodKind kind, bool enabled, double feePercent, String note, String? logoUrl, String color
});


@override $BilingualCopyWith<$Res> get label;

}
/// @nodoc
class __$PaymentMethodCopyWithImpl<$Res>
    implements _$PaymentMethodCopyWith<$Res> {
  __$PaymentMethodCopyWithImpl(this._self, this._then);

  final _PaymentMethod _self;
  final $Res Function(_PaymentMethod) _then;

/// Create a copy of PaymentMethod
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? code = null,Object? label = null,Object? kind = null,Object? enabled = null,Object? feePercent = null,Object? note = null,Object? logoUrl = freezed,Object? color = null,}) {
  return _then(_PaymentMethod(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,code: null == code ? _self.code : code // ignore: cast_nullable_to_non_nullable
as String,label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as Bilingual,kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as PaymentMethodKind,enabled: null == enabled ? _self.enabled : enabled // ignore: cast_nullable_to_non_nullable
as bool,feePercent: null == feePercent ? _self.feePercent : feePercent // ignore: cast_nullable_to_non_nullable
as double,note: null == note ? _self.note : note // ignore: cast_nullable_to_non_nullable
as String,logoUrl: freezed == logoUrl ? _self.logoUrl : logoUrl // ignore: cast_nullable_to_non_nullable
as String?,color: null == color ? _self.color : color // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

/// Create a copy of PaymentMethod
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BilingualCopyWith<$Res> get label {
  
  return $BilingualCopyWith<$Res>(_self.label, (value) {
    return _then(_self.copyWith(label: value));
  });
}
}

// dart format on
