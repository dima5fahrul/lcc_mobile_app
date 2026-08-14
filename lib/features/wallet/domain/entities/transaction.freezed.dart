// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'transaction.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$Transaction {

 String get id; String get receiptNo; String? get applicationId; String? get referenceNo; String get payerName; String get serviceCode;/// Nullable in `types.ts:530`, and the fallback chain at `:486` is
/// `text(tx.service_name, lang) || tx.service_code || tx.kind` — three
/// deep, in that order.
 Bilingual? get serviceName; String get kind; String get methodCode; Bilingual? get methodLabel; int get amountLak;/// `"paid"` | `"pending"` | `"refunded"` | `"failed"`.
 String get status;/// The row prints `tx.paid_at ?? tx.date` (`:506`) — `??`, so an empty
/// string `paid_at` still wins over `date`. Both are modelled nullable so
/// the `??` can mean what it means on the wire.
 String? get paidAt; String? get date; String? get note;
/// Create a copy of Transaction
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TransactionCopyWith<Transaction> get copyWith => _$TransactionCopyWithImpl<Transaction>(this as Transaction, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Transaction&&(identical(other.id, id) || other.id == id)&&(identical(other.receiptNo, receiptNo) || other.receiptNo == receiptNo)&&(identical(other.applicationId, applicationId) || other.applicationId == applicationId)&&(identical(other.referenceNo, referenceNo) || other.referenceNo == referenceNo)&&(identical(other.payerName, payerName) || other.payerName == payerName)&&(identical(other.serviceCode, serviceCode) || other.serviceCode == serviceCode)&&(identical(other.serviceName, serviceName) || other.serviceName == serviceName)&&(identical(other.kind, kind) || other.kind == kind)&&(identical(other.methodCode, methodCode) || other.methodCode == methodCode)&&(identical(other.methodLabel, methodLabel) || other.methodLabel == methodLabel)&&(identical(other.amountLak, amountLak) || other.amountLak == amountLak)&&(identical(other.status, status) || other.status == status)&&(identical(other.paidAt, paidAt) || other.paidAt == paidAt)&&(identical(other.date, date) || other.date == date)&&(identical(other.note, note) || other.note == note));
}


@override
int get hashCode => Object.hash(runtimeType,id,receiptNo,applicationId,referenceNo,payerName,serviceCode,serviceName,kind,methodCode,methodLabel,amountLak,status,paidAt,date,note);

@override
String toString() {
  return 'Transaction(id: $id, receiptNo: $receiptNo, applicationId: $applicationId, referenceNo: $referenceNo, payerName: $payerName, serviceCode: $serviceCode, serviceName: $serviceName, kind: $kind, methodCode: $methodCode, methodLabel: $methodLabel, amountLak: $amountLak, status: $status, paidAt: $paidAt, date: $date, note: $note)';
}


}

/// @nodoc
abstract mixin class $TransactionCopyWith<$Res>  {
  factory $TransactionCopyWith(Transaction value, $Res Function(Transaction) _then) = _$TransactionCopyWithImpl;
@useResult
$Res call({
 String id, String receiptNo, String? applicationId, String? referenceNo, String payerName, String serviceCode, Bilingual? serviceName, String kind, String methodCode, Bilingual? methodLabel, int amountLak, String status, String? paidAt, String? date, String? note
});


$BilingualCopyWith<$Res>? get serviceName;$BilingualCopyWith<$Res>? get methodLabel;

}
/// @nodoc
class _$TransactionCopyWithImpl<$Res>
    implements $TransactionCopyWith<$Res> {
  _$TransactionCopyWithImpl(this._self, this._then);

  final Transaction _self;
  final $Res Function(Transaction) _then;

/// Create a copy of Transaction
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? receiptNo = null,Object? applicationId = freezed,Object? referenceNo = freezed,Object? payerName = null,Object? serviceCode = null,Object? serviceName = freezed,Object? kind = null,Object? methodCode = null,Object? methodLabel = freezed,Object? amountLak = null,Object? status = null,Object? paidAt = freezed,Object? date = freezed,Object? note = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,receiptNo: null == receiptNo ? _self.receiptNo : receiptNo // ignore: cast_nullable_to_non_nullable
as String,applicationId: freezed == applicationId ? _self.applicationId : applicationId // ignore: cast_nullable_to_non_nullable
as String?,referenceNo: freezed == referenceNo ? _self.referenceNo : referenceNo // ignore: cast_nullable_to_non_nullable
as String?,payerName: null == payerName ? _self.payerName : payerName // ignore: cast_nullable_to_non_nullable
as String,serviceCode: null == serviceCode ? _self.serviceCode : serviceCode // ignore: cast_nullable_to_non_nullable
as String,serviceName: freezed == serviceName ? _self.serviceName : serviceName // ignore: cast_nullable_to_non_nullable
as Bilingual?,kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as String,methodCode: null == methodCode ? _self.methodCode : methodCode // ignore: cast_nullable_to_non_nullable
as String,methodLabel: freezed == methodLabel ? _self.methodLabel : methodLabel // ignore: cast_nullable_to_non_nullable
as Bilingual?,amountLak: null == amountLak ? _self.amountLak : amountLak // ignore: cast_nullable_to_non_nullable
as int,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,paidAt: freezed == paidAt ? _self.paidAt : paidAt // ignore: cast_nullable_to_non_nullable
as String?,date: freezed == date ? _self.date : date // ignore: cast_nullable_to_non_nullable
as String?,note: freezed == note ? _self.note : note // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}
/// Create a copy of Transaction
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
}/// Create a copy of Transaction
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BilingualCopyWith<$Res>? get methodLabel {
    if (_self.methodLabel == null) {
    return null;
  }

  return $BilingualCopyWith<$Res>(_self.methodLabel!, (value) {
    return _then(_self.copyWith(methodLabel: value));
  });
}
}


/// Adds pattern-matching-related methods to [Transaction].
extension TransactionPatterns on Transaction {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Transaction value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Transaction() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Transaction value)  $default,){
final _that = this;
switch (_that) {
case _Transaction():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Transaction value)?  $default,){
final _that = this;
switch (_that) {
case _Transaction() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String receiptNo,  String? applicationId,  String? referenceNo,  String payerName,  String serviceCode,  Bilingual? serviceName,  String kind,  String methodCode,  Bilingual? methodLabel,  int amountLak,  String status,  String? paidAt,  String? date,  String? note)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Transaction() when $default != null:
return $default(_that.id,_that.receiptNo,_that.applicationId,_that.referenceNo,_that.payerName,_that.serviceCode,_that.serviceName,_that.kind,_that.methodCode,_that.methodLabel,_that.amountLak,_that.status,_that.paidAt,_that.date,_that.note);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String receiptNo,  String? applicationId,  String? referenceNo,  String payerName,  String serviceCode,  Bilingual? serviceName,  String kind,  String methodCode,  Bilingual? methodLabel,  int amountLak,  String status,  String? paidAt,  String? date,  String? note)  $default,) {final _that = this;
switch (_that) {
case _Transaction():
return $default(_that.id,_that.receiptNo,_that.applicationId,_that.referenceNo,_that.payerName,_that.serviceCode,_that.serviceName,_that.kind,_that.methodCode,_that.methodLabel,_that.amountLak,_that.status,_that.paidAt,_that.date,_that.note);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String receiptNo,  String? applicationId,  String? referenceNo,  String payerName,  String serviceCode,  Bilingual? serviceName,  String kind,  String methodCode,  Bilingual? methodLabel,  int amountLak,  String status,  String? paidAt,  String? date,  String? note)?  $default,) {final _that = this;
switch (_that) {
case _Transaction() when $default != null:
return $default(_that.id,_that.receiptNo,_that.applicationId,_that.referenceNo,_that.payerName,_that.serviceCode,_that.serviceName,_that.kind,_that.methodCode,_that.methodLabel,_that.amountLak,_that.status,_that.paidAt,_that.date,_that.note);case _:
  return null;

}
}

}

/// @nodoc


class _Transaction extends Transaction {
  const _Transaction({required this.id, required this.receiptNo, this.applicationId, this.referenceNo, this.payerName = '', this.serviceCode = '', this.serviceName, this.kind = '', this.methodCode = '', this.methodLabel, required this.amountLak, this.status = '', this.paidAt, this.date, this.note}): super._();
  

@override final  String id;
@override final  String receiptNo;
@override final  String? applicationId;
@override final  String? referenceNo;
@override@JsonKey() final  String payerName;
@override@JsonKey() final  String serviceCode;
/// Nullable in `types.ts:530`, and the fallback chain at `:486` is
/// `text(tx.service_name, lang) || tx.service_code || tx.kind` — three
/// deep, in that order.
@override final  Bilingual? serviceName;
@override@JsonKey() final  String kind;
@override@JsonKey() final  String methodCode;
@override final  Bilingual? methodLabel;
@override final  int amountLak;
/// `"paid"` | `"pending"` | `"refunded"` | `"failed"`.
@override@JsonKey() final  String status;
/// The row prints `tx.paid_at ?? tx.date` (`:506`) — `??`, so an empty
/// string `paid_at` still wins over `date`. Both are modelled nullable so
/// the `??` can mean what it means on the wire.
@override final  String? paidAt;
@override final  String? date;
@override final  String? note;

/// Create a copy of Transaction
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TransactionCopyWith<_Transaction> get copyWith => __$TransactionCopyWithImpl<_Transaction>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Transaction&&(identical(other.id, id) || other.id == id)&&(identical(other.receiptNo, receiptNo) || other.receiptNo == receiptNo)&&(identical(other.applicationId, applicationId) || other.applicationId == applicationId)&&(identical(other.referenceNo, referenceNo) || other.referenceNo == referenceNo)&&(identical(other.payerName, payerName) || other.payerName == payerName)&&(identical(other.serviceCode, serviceCode) || other.serviceCode == serviceCode)&&(identical(other.serviceName, serviceName) || other.serviceName == serviceName)&&(identical(other.kind, kind) || other.kind == kind)&&(identical(other.methodCode, methodCode) || other.methodCode == methodCode)&&(identical(other.methodLabel, methodLabel) || other.methodLabel == methodLabel)&&(identical(other.amountLak, amountLak) || other.amountLak == amountLak)&&(identical(other.status, status) || other.status == status)&&(identical(other.paidAt, paidAt) || other.paidAt == paidAt)&&(identical(other.date, date) || other.date == date)&&(identical(other.note, note) || other.note == note));
}


@override
int get hashCode => Object.hash(runtimeType,id,receiptNo,applicationId,referenceNo,payerName,serviceCode,serviceName,kind,methodCode,methodLabel,amountLak,status,paidAt,date,note);

@override
String toString() {
  return 'Transaction(id: $id, receiptNo: $receiptNo, applicationId: $applicationId, referenceNo: $referenceNo, payerName: $payerName, serviceCode: $serviceCode, serviceName: $serviceName, kind: $kind, methodCode: $methodCode, methodLabel: $methodLabel, amountLak: $amountLak, status: $status, paidAt: $paidAt, date: $date, note: $note)';
}


}

/// @nodoc
abstract mixin class _$TransactionCopyWith<$Res> implements $TransactionCopyWith<$Res> {
  factory _$TransactionCopyWith(_Transaction value, $Res Function(_Transaction) _then) = __$TransactionCopyWithImpl;
@override @useResult
$Res call({
 String id, String receiptNo, String? applicationId, String? referenceNo, String payerName, String serviceCode, Bilingual? serviceName, String kind, String methodCode, Bilingual? methodLabel, int amountLak, String status, String? paidAt, String? date, String? note
});


@override $BilingualCopyWith<$Res>? get serviceName;@override $BilingualCopyWith<$Res>? get methodLabel;

}
/// @nodoc
class __$TransactionCopyWithImpl<$Res>
    implements _$TransactionCopyWith<$Res> {
  __$TransactionCopyWithImpl(this._self, this._then);

  final _Transaction _self;
  final $Res Function(_Transaction) _then;

/// Create a copy of Transaction
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? receiptNo = null,Object? applicationId = freezed,Object? referenceNo = freezed,Object? payerName = null,Object? serviceCode = null,Object? serviceName = freezed,Object? kind = null,Object? methodCode = null,Object? methodLabel = freezed,Object? amountLak = null,Object? status = null,Object? paidAt = freezed,Object? date = freezed,Object? note = freezed,}) {
  return _then(_Transaction(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,receiptNo: null == receiptNo ? _self.receiptNo : receiptNo // ignore: cast_nullable_to_non_nullable
as String,applicationId: freezed == applicationId ? _self.applicationId : applicationId // ignore: cast_nullable_to_non_nullable
as String?,referenceNo: freezed == referenceNo ? _self.referenceNo : referenceNo // ignore: cast_nullable_to_non_nullable
as String?,payerName: null == payerName ? _self.payerName : payerName // ignore: cast_nullable_to_non_nullable
as String,serviceCode: null == serviceCode ? _self.serviceCode : serviceCode // ignore: cast_nullable_to_non_nullable
as String,serviceName: freezed == serviceName ? _self.serviceName : serviceName // ignore: cast_nullable_to_non_nullable
as Bilingual?,kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as String,methodCode: null == methodCode ? _self.methodCode : methodCode // ignore: cast_nullable_to_non_nullable
as String,methodLabel: freezed == methodLabel ? _self.methodLabel : methodLabel // ignore: cast_nullable_to_non_nullable
as Bilingual?,amountLak: null == amountLak ? _self.amountLak : amountLak // ignore: cast_nullable_to_non_nullable
as int,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,paidAt: freezed == paidAt ? _self.paidAt : paidAt // ignore: cast_nullable_to_non_nullable
as String?,date: freezed == date ? _self.date : date // ignore: cast_nullable_to_non_nullable
as String?,note: freezed == note ? _self.note : note // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

/// Create a copy of Transaction
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
}/// Create a copy of Transaction
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BilingualCopyWith<$Res>? get methodLabel {
    if (_self.methodLabel == null) {
    return null;
  }

  return $BilingualCopyWith<$Res>(_self.methodLabel!, (value) {
    return _then(_self.copyWith(methodLabel: value));
  });
}
}

// dart format on
