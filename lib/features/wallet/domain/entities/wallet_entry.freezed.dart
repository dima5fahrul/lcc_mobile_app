// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'wallet_entry.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$WalletEntry {

 String get id;/// `"credit"` | `"debit"` — see the library doc on why this is not an enum.
 String get direction; String get kind; int get amountLak; int get balanceAfterLak;/// The row's title, falling back to [kind] when the pair is empty —
/// `text(e.description, lang) || e.kind` (`WalletPage.tsx:663`).
 Bilingual get description; String? get referenceNo; String? get methodCode; String get status;/// `date` and `occurredAt` are both sent; the row prints
/// `occurred_at ?? date` (`:675`), so the fallback order is the source's,
/// not a preference.
 String get date; String get occurredAt;
/// Create a copy of WalletEntry
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$WalletEntryCopyWith<WalletEntry> get copyWith => _$WalletEntryCopyWithImpl<WalletEntry>(this as WalletEntry, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is WalletEntry&&(identical(other.id, id) || other.id == id)&&(identical(other.direction, direction) || other.direction == direction)&&(identical(other.kind, kind) || other.kind == kind)&&(identical(other.amountLak, amountLak) || other.amountLak == amountLak)&&(identical(other.balanceAfterLak, balanceAfterLak) || other.balanceAfterLak == balanceAfterLak)&&(identical(other.description, description) || other.description == description)&&(identical(other.referenceNo, referenceNo) || other.referenceNo == referenceNo)&&(identical(other.methodCode, methodCode) || other.methodCode == methodCode)&&(identical(other.status, status) || other.status == status)&&(identical(other.date, date) || other.date == date)&&(identical(other.occurredAt, occurredAt) || other.occurredAt == occurredAt));
}


@override
int get hashCode => Object.hash(runtimeType,id,direction,kind,amountLak,balanceAfterLak,description,referenceNo,methodCode,status,date,occurredAt);

@override
String toString() {
  return 'WalletEntry(id: $id, direction: $direction, kind: $kind, amountLak: $amountLak, balanceAfterLak: $balanceAfterLak, description: $description, referenceNo: $referenceNo, methodCode: $methodCode, status: $status, date: $date, occurredAt: $occurredAt)';
}


}

/// @nodoc
abstract mixin class $WalletEntryCopyWith<$Res>  {
  factory $WalletEntryCopyWith(WalletEntry value, $Res Function(WalletEntry) _then) = _$WalletEntryCopyWithImpl;
@useResult
$Res call({
 String id, String direction, String kind, int amountLak, int balanceAfterLak, Bilingual description, String? referenceNo, String? methodCode, String status, String date, String occurredAt
});


$BilingualCopyWith<$Res> get description;

}
/// @nodoc
class _$WalletEntryCopyWithImpl<$Res>
    implements $WalletEntryCopyWith<$Res> {
  _$WalletEntryCopyWithImpl(this._self, this._then);

  final WalletEntry _self;
  final $Res Function(WalletEntry) _then;

/// Create a copy of WalletEntry
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? direction = null,Object? kind = null,Object? amountLak = null,Object? balanceAfterLak = null,Object? description = null,Object? referenceNo = freezed,Object? methodCode = freezed,Object? status = null,Object? date = null,Object? occurredAt = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,direction: null == direction ? _self.direction : direction // ignore: cast_nullable_to_non_nullable
as String,kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as String,amountLak: null == amountLak ? _self.amountLak : amountLak // ignore: cast_nullable_to_non_nullable
as int,balanceAfterLak: null == balanceAfterLak ? _self.balanceAfterLak : balanceAfterLak // ignore: cast_nullable_to_non_nullable
as int,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as Bilingual,referenceNo: freezed == referenceNo ? _self.referenceNo : referenceNo // ignore: cast_nullable_to_non_nullable
as String?,methodCode: freezed == methodCode ? _self.methodCode : methodCode // ignore: cast_nullable_to_non_nullable
as String?,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,date: null == date ? _self.date : date // ignore: cast_nullable_to_non_nullable
as String,occurredAt: null == occurredAt ? _self.occurredAt : occurredAt // ignore: cast_nullable_to_non_nullable
as String,
  ));
}
/// Create a copy of WalletEntry
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BilingualCopyWith<$Res> get description {
  
  return $BilingualCopyWith<$Res>(_self.description, (value) {
    return _then(_self.copyWith(description: value));
  });
}
}


/// Adds pattern-matching-related methods to [WalletEntry].
extension WalletEntryPatterns on WalletEntry {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _WalletEntry value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _WalletEntry() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _WalletEntry value)  $default,){
final _that = this;
switch (_that) {
case _WalletEntry():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _WalletEntry value)?  $default,){
final _that = this;
switch (_that) {
case _WalletEntry() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String direction,  String kind,  int amountLak,  int balanceAfterLak,  Bilingual description,  String? referenceNo,  String? methodCode,  String status,  String date,  String occurredAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _WalletEntry() when $default != null:
return $default(_that.id,_that.direction,_that.kind,_that.amountLak,_that.balanceAfterLak,_that.description,_that.referenceNo,_that.methodCode,_that.status,_that.date,_that.occurredAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String direction,  String kind,  int amountLak,  int balanceAfterLak,  Bilingual description,  String? referenceNo,  String? methodCode,  String status,  String date,  String occurredAt)  $default,) {final _that = this;
switch (_that) {
case _WalletEntry():
return $default(_that.id,_that.direction,_that.kind,_that.amountLak,_that.balanceAfterLak,_that.description,_that.referenceNo,_that.methodCode,_that.status,_that.date,_that.occurredAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String direction,  String kind,  int amountLak,  int balanceAfterLak,  Bilingual description,  String? referenceNo,  String? methodCode,  String status,  String date,  String occurredAt)?  $default,) {final _that = this;
switch (_that) {
case _WalletEntry() when $default != null:
return $default(_that.id,_that.direction,_that.kind,_that.amountLak,_that.balanceAfterLak,_that.description,_that.referenceNo,_that.methodCode,_that.status,_that.date,_that.occurredAt);case _:
  return null;

}
}

}

/// @nodoc


class _WalletEntry extends WalletEntry {
  const _WalletEntry({required this.id, required this.direction, required this.kind, required this.amountLak, required this.balanceAfterLak, required this.description, this.referenceNo, this.methodCode, this.status = '', this.date = '', this.occurredAt = ''}): super._();
  

@override final  String id;
/// `"credit"` | `"debit"` — see the library doc on why this is not an enum.
@override final  String direction;
@override final  String kind;
@override final  int amountLak;
@override final  int balanceAfterLak;
/// The row's title, falling back to [kind] when the pair is empty —
/// `text(e.description, lang) || e.kind` (`WalletPage.tsx:663`).
@override final  Bilingual description;
@override final  String? referenceNo;
@override final  String? methodCode;
@override@JsonKey() final  String status;
/// `date` and `occurredAt` are both sent; the row prints
/// `occurred_at ?? date` (`:675`), so the fallback order is the source's,
/// not a preference.
@override@JsonKey() final  String date;
@override@JsonKey() final  String occurredAt;

/// Create a copy of WalletEntry
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$WalletEntryCopyWith<_WalletEntry> get copyWith => __$WalletEntryCopyWithImpl<_WalletEntry>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _WalletEntry&&(identical(other.id, id) || other.id == id)&&(identical(other.direction, direction) || other.direction == direction)&&(identical(other.kind, kind) || other.kind == kind)&&(identical(other.amountLak, amountLak) || other.amountLak == amountLak)&&(identical(other.balanceAfterLak, balanceAfterLak) || other.balanceAfterLak == balanceAfterLak)&&(identical(other.description, description) || other.description == description)&&(identical(other.referenceNo, referenceNo) || other.referenceNo == referenceNo)&&(identical(other.methodCode, methodCode) || other.methodCode == methodCode)&&(identical(other.status, status) || other.status == status)&&(identical(other.date, date) || other.date == date)&&(identical(other.occurredAt, occurredAt) || other.occurredAt == occurredAt));
}


@override
int get hashCode => Object.hash(runtimeType,id,direction,kind,amountLak,balanceAfterLak,description,referenceNo,methodCode,status,date,occurredAt);

@override
String toString() {
  return 'WalletEntry(id: $id, direction: $direction, kind: $kind, amountLak: $amountLak, balanceAfterLak: $balanceAfterLak, description: $description, referenceNo: $referenceNo, methodCode: $methodCode, status: $status, date: $date, occurredAt: $occurredAt)';
}


}

/// @nodoc
abstract mixin class _$WalletEntryCopyWith<$Res> implements $WalletEntryCopyWith<$Res> {
  factory _$WalletEntryCopyWith(_WalletEntry value, $Res Function(_WalletEntry) _then) = __$WalletEntryCopyWithImpl;
@override @useResult
$Res call({
 String id, String direction, String kind, int amountLak, int balanceAfterLak, Bilingual description, String? referenceNo, String? methodCode, String status, String date, String occurredAt
});


@override $BilingualCopyWith<$Res> get description;

}
/// @nodoc
class __$WalletEntryCopyWithImpl<$Res>
    implements _$WalletEntryCopyWith<$Res> {
  __$WalletEntryCopyWithImpl(this._self, this._then);

  final _WalletEntry _self;
  final $Res Function(_WalletEntry) _then;

/// Create a copy of WalletEntry
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? direction = null,Object? kind = null,Object? amountLak = null,Object? balanceAfterLak = null,Object? description = null,Object? referenceNo = freezed,Object? methodCode = freezed,Object? status = null,Object? date = null,Object? occurredAt = null,}) {
  return _then(_WalletEntry(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,direction: null == direction ? _self.direction : direction // ignore: cast_nullable_to_non_nullable
as String,kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as String,amountLak: null == amountLak ? _self.amountLak : amountLak // ignore: cast_nullable_to_non_nullable
as int,balanceAfterLak: null == balanceAfterLak ? _self.balanceAfterLak : balanceAfterLak // ignore: cast_nullable_to_non_nullable
as int,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as Bilingual,referenceNo: freezed == referenceNo ? _self.referenceNo : referenceNo // ignore: cast_nullable_to_non_nullable
as String?,methodCode: freezed == methodCode ? _self.methodCode : methodCode // ignore: cast_nullable_to_non_nullable
as String?,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,date: null == date ? _self.date : date // ignore: cast_nullable_to_non_nullable
as String,occurredAt: null == occurredAt ? _self.occurredAt : occurredAt // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

/// Create a copy of WalletEntry
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BilingualCopyWith<$Res> get description {
  
  return $BilingualCopyWith<$Res>(_self.description, (value) {
    return _then(_self.copyWith(description: value));
  });
}
}

// dart format on
