// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'payment_result.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$PaymentTransaction {

 String? get receiptNo; int? get amountLak; String? get status; String? get methodCode;
/// Create a copy of PaymentTransaction
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PaymentTransactionCopyWith<PaymentTransaction> get copyWith => _$PaymentTransactionCopyWithImpl<PaymentTransaction>(this as PaymentTransaction, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PaymentTransaction&&(identical(other.receiptNo, receiptNo) || other.receiptNo == receiptNo)&&(identical(other.amountLak, amountLak) || other.amountLak == amountLak)&&(identical(other.status, status) || other.status == status)&&(identical(other.methodCode, methodCode) || other.methodCode == methodCode));
}


@override
int get hashCode => Object.hash(runtimeType,receiptNo,amountLak,status,methodCode);

@override
String toString() {
  return 'PaymentTransaction(receiptNo: $receiptNo, amountLak: $amountLak, status: $status, methodCode: $methodCode)';
}


}

/// @nodoc
abstract mixin class $PaymentTransactionCopyWith<$Res>  {
  factory $PaymentTransactionCopyWith(PaymentTransaction value, $Res Function(PaymentTransaction) _then) = _$PaymentTransactionCopyWithImpl;
@useResult
$Res call({
 String? receiptNo, int? amountLak, String? status, String? methodCode
});




}
/// @nodoc
class _$PaymentTransactionCopyWithImpl<$Res>
    implements $PaymentTransactionCopyWith<$Res> {
  _$PaymentTransactionCopyWithImpl(this._self, this._then);

  final PaymentTransaction _self;
  final $Res Function(PaymentTransaction) _then;

/// Create a copy of PaymentTransaction
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? receiptNo = freezed,Object? amountLak = freezed,Object? status = freezed,Object? methodCode = freezed,}) {
  return _then(_self.copyWith(
receiptNo: freezed == receiptNo ? _self.receiptNo : receiptNo // ignore: cast_nullable_to_non_nullable
as String?,amountLak: freezed == amountLak ? _self.amountLak : amountLak // ignore: cast_nullable_to_non_nullable
as int?,status: freezed == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String?,methodCode: freezed == methodCode ? _self.methodCode : methodCode // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [PaymentTransaction].
extension PaymentTransactionPatterns on PaymentTransaction {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PaymentTransaction value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PaymentTransaction() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PaymentTransaction value)  $default,){
final _that = this;
switch (_that) {
case _PaymentTransaction():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PaymentTransaction value)?  $default,){
final _that = this;
switch (_that) {
case _PaymentTransaction() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String? receiptNo,  int? amountLak,  String? status,  String? methodCode)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PaymentTransaction() when $default != null:
return $default(_that.receiptNo,_that.amountLak,_that.status,_that.methodCode);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String? receiptNo,  int? amountLak,  String? status,  String? methodCode)  $default,) {final _that = this;
switch (_that) {
case _PaymentTransaction():
return $default(_that.receiptNo,_that.amountLak,_that.status,_that.methodCode);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String? receiptNo,  int? amountLak,  String? status,  String? methodCode)?  $default,) {final _that = this;
switch (_that) {
case _PaymentTransaction() when $default != null:
return $default(_that.receiptNo,_that.amountLak,_that.status,_that.methodCode);case _:
  return null;

}
}

}

/// @nodoc


class _PaymentTransaction implements PaymentTransaction {
  const _PaymentTransaction({this.receiptNo, this.amountLak, this.status, this.methodCode});
  

@override final  String? receiptNo;
@override final  int? amountLak;
@override final  String? status;
@override final  String? methodCode;

/// Create a copy of PaymentTransaction
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PaymentTransactionCopyWith<_PaymentTransaction> get copyWith => __$PaymentTransactionCopyWithImpl<_PaymentTransaction>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PaymentTransaction&&(identical(other.receiptNo, receiptNo) || other.receiptNo == receiptNo)&&(identical(other.amountLak, amountLak) || other.amountLak == amountLak)&&(identical(other.status, status) || other.status == status)&&(identical(other.methodCode, methodCode) || other.methodCode == methodCode));
}


@override
int get hashCode => Object.hash(runtimeType,receiptNo,amountLak,status,methodCode);

@override
String toString() {
  return 'PaymentTransaction(receiptNo: $receiptNo, amountLak: $amountLak, status: $status, methodCode: $methodCode)';
}


}

/// @nodoc
abstract mixin class _$PaymentTransactionCopyWith<$Res> implements $PaymentTransactionCopyWith<$Res> {
  factory _$PaymentTransactionCopyWith(_PaymentTransaction value, $Res Function(_PaymentTransaction) _then) = __$PaymentTransactionCopyWithImpl;
@override @useResult
$Res call({
 String? receiptNo, int? amountLak, String? status, String? methodCode
});




}
/// @nodoc
class __$PaymentTransactionCopyWithImpl<$Res>
    implements _$PaymentTransactionCopyWith<$Res> {
  __$PaymentTransactionCopyWithImpl(this._self, this._then);

  final _PaymentTransaction _self;
  final $Res Function(_PaymentTransaction) _then;

/// Create a copy of PaymentTransaction
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? receiptNo = freezed,Object? amountLak = freezed,Object? status = freezed,Object? methodCode = freezed,}) {
  return _then(_PaymentTransaction(
receiptNo: freezed == receiptNo ? _self.receiptNo : receiptNo // ignore: cast_nullable_to_non_nullable
as String?,amountLak: freezed == amountLak ? _self.amountLak : amountLak // ignore: cast_nullable_to_non_nullable
as int?,status: freezed == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String?,methodCode: freezed == methodCode ? _self.methodCode : methodCode // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

/// @nodoc
mixin _$PaymentInstruction {

/// The payable datum. `:397` prints it verbatim beneath a QR bitmap that
/// **does not encode it** (`B6-DIV-3`, § 6.10, security item 4).
 String? get qrPayload; String? get account; Bilingual? get note; String? get referenceNo; int? get amountLak; List<Bilingual> get steps; String? get expiresAt;
/// Create a copy of PaymentInstruction
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PaymentInstructionCopyWith<PaymentInstruction> get copyWith => _$PaymentInstructionCopyWithImpl<PaymentInstruction>(this as PaymentInstruction, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PaymentInstruction&&(identical(other.qrPayload, qrPayload) || other.qrPayload == qrPayload)&&(identical(other.account, account) || other.account == account)&&(identical(other.note, note) || other.note == note)&&(identical(other.referenceNo, referenceNo) || other.referenceNo == referenceNo)&&(identical(other.amountLak, amountLak) || other.amountLak == amountLak)&&const DeepCollectionEquality().equals(other.steps, steps)&&(identical(other.expiresAt, expiresAt) || other.expiresAt == expiresAt));
}


@override
int get hashCode => Object.hash(runtimeType,qrPayload,account,note,referenceNo,amountLak,const DeepCollectionEquality().hash(steps),expiresAt);

@override
String toString() {
  return 'PaymentInstruction(qrPayload: $qrPayload, account: $account, note: $note, referenceNo: $referenceNo, amountLak: $amountLak, steps: $steps, expiresAt: $expiresAt)';
}


}

/// @nodoc
abstract mixin class $PaymentInstructionCopyWith<$Res>  {
  factory $PaymentInstructionCopyWith(PaymentInstruction value, $Res Function(PaymentInstruction) _then) = _$PaymentInstructionCopyWithImpl;
@useResult
$Res call({
 String? qrPayload, String? account, Bilingual? note, String? referenceNo, int? amountLak, List<Bilingual> steps, String? expiresAt
});


$BilingualCopyWith<$Res>? get note;

}
/// @nodoc
class _$PaymentInstructionCopyWithImpl<$Res>
    implements $PaymentInstructionCopyWith<$Res> {
  _$PaymentInstructionCopyWithImpl(this._self, this._then);

  final PaymentInstruction _self;
  final $Res Function(PaymentInstruction) _then;

/// Create a copy of PaymentInstruction
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? qrPayload = freezed,Object? account = freezed,Object? note = freezed,Object? referenceNo = freezed,Object? amountLak = freezed,Object? steps = null,Object? expiresAt = freezed,}) {
  return _then(_self.copyWith(
qrPayload: freezed == qrPayload ? _self.qrPayload : qrPayload // ignore: cast_nullable_to_non_nullable
as String?,account: freezed == account ? _self.account : account // ignore: cast_nullable_to_non_nullable
as String?,note: freezed == note ? _self.note : note // ignore: cast_nullable_to_non_nullable
as Bilingual?,referenceNo: freezed == referenceNo ? _self.referenceNo : referenceNo // ignore: cast_nullable_to_non_nullable
as String?,amountLak: freezed == amountLak ? _self.amountLak : amountLak // ignore: cast_nullable_to_non_nullable
as int?,steps: null == steps ? _self.steps : steps // ignore: cast_nullable_to_non_nullable
as List<Bilingual>,expiresAt: freezed == expiresAt ? _self.expiresAt : expiresAt // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}
/// Create a copy of PaymentInstruction
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BilingualCopyWith<$Res>? get note {
    if (_self.note == null) {
    return null;
  }

  return $BilingualCopyWith<$Res>(_self.note!, (value) {
    return _then(_self.copyWith(note: value));
  });
}
}


/// Adds pattern-matching-related methods to [PaymentInstruction].
extension PaymentInstructionPatterns on PaymentInstruction {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PaymentInstruction value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PaymentInstruction() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PaymentInstruction value)  $default,){
final _that = this;
switch (_that) {
case _PaymentInstruction():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PaymentInstruction value)?  $default,){
final _that = this;
switch (_that) {
case _PaymentInstruction() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String? qrPayload,  String? account,  Bilingual? note,  String? referenceNo,  int? amountLak,  List<Bilingual> steps,  String? expiresAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PaymentInstruction() when $default != null:
return $default(_that.qrPayload,_that.account,_that.note,_that.referenceNo,_that.amountLak,_that.steps,_that.expiresAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String? qrPayload,  String? account,  Bilingual? note,  String? referenceNo,  int? amountLak,  List<Bilingual> steps,  String? expiresAt)  $default,) {final _that = this;
switch (_that) {
case _PaymentInstruction():
return $default(_that.qrPayload,_that.account,_that.note,_that.referenceNo,_that.amountLak,_that.steps,_that.expiresAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String? qrPayload,  String? account,  Bilingual? note,  String? referenceNo,  int? amountLak,  List<Bilingual> steps,  String? expiresAt)?  $default,) {final _that = this;
switch (_that) {
case _PaymentInstruction() when $default != null:
return $default(_that.qrPayload,_that.account,_that.note,_that.referenceNo,_that.amountLak,_that.steps,_that.expiresAt);case _:
  return null;

}
}

}

/// @nodoc


class _PaymentInstruction extends PaymentInstruction {
  const _PaymentInstruction({this.qrPayload, this.account, this.note, this.referenceNo, this.amountLak, final  List<Bilingual> steps = const <Bilingual>[], this.expiresAt}): _steps = steps,super._();
  

/// The payable datum. `:397` prints it verbatim beneath a QR bitmap that
/// **does not encode it** (`B6-DIV-3`, § 6.10, security item 4).
@override final  String? qrPayload;
@override final  String? account;
@override final  Bilingual? note;
@override final  String? referenceNo;
@override final  int? amountLak;
 final  List<Bilingual> _steps;
@override@JsonKey() List<Bilingual> get steps {
  if (_steps is EqualUnmodifiableListView) return _steps;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_steps);
}

@override final  String? expiresAt;

/// Create a copy of PaymentInstruction
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PaymentInstructionCopyWith<_PaymentInstruction> get copyWith => __$PaymentInstructionCopyWithImpl<_PaymentInstruction>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PaymentInstruction&&(identical(other.qrPayload, qrPayload) || other.qrPayload == qrPayload)&&(identical(other.account, account) || other.account == account)&&(identical(other.note, note) || other.note == note)&&(identical(other.referenceNo, referenceNo) || other.referenceNo == referenceNo)&&(identical(other.amountLak, amountLak) || other.amountLak == amountLak)&&const DeepCollectionEquality().equals(other._steps, _steps)&&(identical(other.expiresAt, expiresAt) || other.expiresAt == expiresAt));
}


@override
int get hashCode => Object.hash(runtimeType,qrPayload,account,note,referenceNo,amountLak,const DeepCollectionEquality().hash(_steps),expiresAt);

@override
String toString() {
  return 'PaymentInstruction(qrPayload: $qrPayload, account: $account, note: $note, referenceNo: $referenceNo, amountLak: $amountLak, steps: $steps, expiresAt: $expiresAt)';
}


}

/// @nodoc
abstract mixin class _$PaymentInstructionCopyWith<$Res> implements $PaymentInstructionCopyWith<$Res> {
  factory _$PaymentInstructionCopyWith(_PaymentInstruction value, $Res Function(_PaymentInstruction) _then) = __$PaymentInstructionCopyWithImpl;
@override @useResult
$Res call({
 String? qrPayload, String? account, Bilingual? note, String? referenceNo, int? amountLak, List<Bilingual> steps, String? expiresAt
});


@override $BilingualCopyWith<$Res>? get note;

}
/// @nodoc
class __$PaymentInstructionCopyWithImpl<$Res>
    implements _$PaymentInstructionCopyWith<$Res> {
  __$PaymentInstructionCopyWithImpl(this._self, this._then);

  final _PaymentInstruction _self;
  final $Res Function(_PaymentInstruction) _then;

/// Create a copy of PaymentInstruction
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? qrPayload = freezed,Object? account = freezed,Object? note = freezed,Object? referenceNo = freezed,Object? amountLak = freezed,Object? steps = null,Object? expiresAt = freezed,}) {
  return _then(_PaymentInstruction(
qrPayload: freezed == qrPayload ? _self.qrPayload : qrPayload // ignore: cast_nullable_to_non_nullable
as String?,account: freezed == account ? _self.account : account // ignore: cast_nullable_to_non_nullable
as String?,note: freezed == note ? _self.note : note // ignore: cast_nullable_to_non_nullable
as Bilingual?,referenceNo: freezed == referenceNo ? _self.referenceNo : referenceNo // ignore: cast_nullable_to_non_nullable
as String?,amountLak: freezed == amountLak ? _self.amountLak : amountLak // ignore: cast_nullable_to_non_nullable
as int?,steps: null == steps ? _self._steps : steps // ignore: cast_nullable_to_non_nullable
as List<Bilingual>,expiresAt: freezed == expiresAt ? _self.expiresAt : expiresAt // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

/// Create a copy of PaymentInstruction
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BilingualCopyWith<$Res>? get note {
    if (_self.note == null) {
    return null;
  }

  return $BilingualCopyWith<$Res>(_self.note!, (value) {
    return _then(_self.copyWith(note: value));
  });
}
}

/// @nodoc
mixin _$PaymentResult {

 String get receiptNo;/// **Nullable on purpose.** [chargedAmount] resolves it with `??`, so the
/// difference between "the server sent 0" and "the server sent nothing" is
/// observable and `B6-AC-30` asserts it. An `int` defaulting to `0` would
/// erase exactly that distinction.
 int? get amountLak; String get status; String get paymentState; String get methodCode; int? get walletBalanceLak;/// `PaymentSection.tsx:44`. Tri-state: `true`, `false`, or absent — and
/// [isSettled] only treats `=== true` as settled, so absent is not false
/// by accident, it is one of three inputs to an `||`.
 bool? get settled; PaymentTransaction? get transaction; PaymentInstruction? get instruction;
/// Create a copy of PaymentResult
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PaymentResultCopyWith<PaymentResult> get copyWith => _$PaymentResultCopyWithImpl<PaymentResult>(this as PaymentResult, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PaymentResult&&(identical(other.receiptNo, receiptNo) || other.receiptNo == receiptNo)&&(identical(other.amountLak, amountLak) || other.amountLak == amountLak)&&(identical(other.status, status) || other.status == status)&&(identical(other.paymentState, paymentState) || other.paymentState == paymentState)&&(identical(other.methodCode, methodCode) || other.methodCode == methodCode)&&(identical(other.walletBalanceLak, walletBalanceLak) || other.walletBalanceLak == walletBalanceLak)&&(identical(other.settled, settled) || other.settled == settled)&&(identical(other.transaction, transaction) || other.transaction == transaction)&&(identical(other.instruction, instruction) || other.instruction == instruction));
}


@override
int get hashCode => Object.hash(runtimeType,receiptNo,amountLak,status,paymentState,methodCode,walletBalanceLak,settled,transaction,instruction);

@override
String toString() {
  return 'PaymentResult(receiptNo: $receiptNo, amountLak: $amountLak, status: $status, paymentState: $paymentState, methodCode: $methodCode, walletBalanceLak: $walletBalanceLak, settled: $settled, transaction: $transaction, instruction: $instruction)';
}


}

/// @nodoc
abstract mixin class $PaymentResultCopyWith<$Res>  {
  factory $PaymentResultCopyWith(PaymentResult value, $Res Function(PaymentResult) _then) = _$PaymentResultCopyWithImpl;
@useResult
$Res call({
 String receiptNo, int? amountLak, String status, String paymentState, String methodCode, int? walletBalanceLak, bool? settled, PaymentTransaction? transaction, PaymentInstruction? instruction
});


$PaymentTransactionCopyWith<$Res>? get transaction;$PaymentInstructionCopyWith<$Res>? get instruction;

}
/// @nodoc
class _$PaymentResultCopyWithImpl<$Res>
    implements $PaymentResultCopyWith<$Res> {
  _$PaymentResultCopyWithImpl(this._self, this._then);

  final PaymentResult _self;
  final $Res Function(PaymentResult) _then;

/// Create a copy of PaymentResult
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? receiptNo = null,Object? amountLak = freezed,Object? status = null,Object? paymentState = null,Object? methodCode = null,Object? walletBalanceLak = freezed,Object? settled = freezed,Object? transaction = freezed,Object? instruction = freezed,}) {
  return _then(_self.copyWith(
receiptNo: null == receiptNo ? _self.receiptNo : receiptNo // ignore: cast_nullable_to_non_nullable
as String,amountLak: freezed == amountLak ? _self.amountLak : amountLak // ignore: cast_nullable_to_non_nullable
as int?,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,paymentState: null == paymentState ? _self.paymentState : paymentState // ignore: cast_nullable_to_non_nullable
as String,methodCode: null == methodCode ? _self.methodCode : methodCode // ignore: cast_nullable_to_non_nullable
as String,walletBalanceLak: freezed == walletBalanceLak ? _self.walletBalanceLak : walletBalanceLak // ignore: cast_nullable_to_non_nullable
as int?,settled: freezed == settled ? _self.settled : settled // ignore: cast_nullable_to_non_nullable
as bool?,transaction: freezed == transaction ? _self.transaction : transaction // ignore: cast_nullable_to_non_nullable
as PaymentTransaction?,instruction: freezed == instruction ? _self.instruction : instruction // ignore: cast_nullable_to_non_nullable
as PaymentInstruction?,
  ));
}
/// Create a copy of PaymentResult
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PaymentTransactionCopyWith<$Res>? get transaction {
    if (_self.transaction == null) {
    return null;
  }

  return $PaymentTransactionCopyWith<$Res>(_self.transaction!, (value) {
    return _then(_self.copyWith(transaction: value));
  });
}/// Create a copy of PaymentResult
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PaymentInstructionCopyWith<$Res>? get instruction {
    if (_self.instruction == null) {
    return null;
  }

  return $PaymentInstructionCopyWith<$Res>(_self.instruction!, (value) {
    return _then(_self.copyWith(instruction: value));
  });
}
}


/// Adds pattern-matching-related methods to [PaymentResult].
extension PaymentResultPatterns on PaymentResult {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PaymentResult value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PaymentResult() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PaymentResult value)  $default,){
final _that = this;
switch (_that) {
case _PaymentResult():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PaymentResult value)?  $default,){
final _that = this;
switch (_that) {
case _PaymentResult() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String receiptNo,  int? amountLak,  String status,  String paymentState,  String methodCode,  int? walletBalanceLak,  bool? settled,  PaymentTransaction? transaction,  PaymentInstruction? instruction)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PaymentResult() when $default != null:
return $default(_that.receiptNo,_that.amountLak,_that.status,_that.paymentState,_that.methodCode,_that.walletBalanceLak,_that.settled,_that.transaction,_that.instruction);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String receiptNo,  int? amountLak,  String status,  String paymentState,  String methodCode,  int? walletBalanceLak,  bool? settled,  PaymentTransaction? transaction,  PaymentInstruction? instruction)  $default,) {final _that = this;
switch (_that) {
case _PaymentResult():
return $default(_that.receiptNo,_that.amountLak,_that.status,_that.paymentState,_that.methodCode,_that.walletBalanceLak,_that.settled,_that.transaction,_that.instruction);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String receiptNo,  int? amountLak,  String status,  String paymentState,  String methodCode,  int? walletBalanceLak,  bool? settled,  PaymentTransaction? transaction,  PaymentInstruction? instruction)?  $default,) {final _that = this;
switch (_that) {
case _PaymentResult() when $default != null:
return $default(_that.receiptNo,_that.amountLak,_that.status,_that.paymentState,_that.methodCode,_that.walletBalanceLak,_that.settled,_that.transaction,_that.instruction);case _:
  return null;

}
}

}

/// @nodoc


class _PaymentResult extends PaymentResult {
  const _PaymentResult({this.receiptNo = '', this.amountLak, this.status = '', this.paymentState = '', this.methodCode = '', this.walletBalanceLak, this.settled, this.transaction, this.instruction}): super._();
  

@override@JsonKey() final  String receiptNo;
/// **Nullable on purpose.** [chargedAmount] resolves it with `??`, so the
/// difference between "the server sent 0" and "the server sent nothing" is
/// observable and `B6-AC-30` asserts it. An `int` defaulting to `0` would
/// erase exactly that distinction.
@override final  int? amountLak;
@override@JsonKey() final  String status;
@override@JsonKey() final  String paymentState;
@override@JsonKey() final  String methodCode;
@override final  int? walletBalanceLak;
/// `PaymentSection.tsx:44`. Tri-state: `true`, `false`, or absent — and
/// [isSettled] only treats `=== true` as settled, so absent is not false
/// by accident, it is one of three inputs to an `||`.
@override final  bool? settled;
@override final  PaymentTransaction? transaction;
@override final  PaymentInstruction? instruction;

/// Create a copy of PaymentResult
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PaymentResultCopyWith<_PaymentResult> get copyWith => __$PaymentResultCopyWithImpl<_PaymentResult>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PaymentResult&&(identical(other.receiptNo, receiptNo) || other.receiptNo == receiptNo)&&(identical(other.amountLak, amountLak) || other.amountLak == amountLak)&&(identical(other.status, status) || other.status == status)&&(identical(other.paymentState, paymentState) || other.paymentState == paymentState)&&(identical(other.methodCode, methodCode) || other.methodCode == methodCode)&&(identical(other.walletBalanceLak, walletBalanceLak) || other.walletBalanceLak == walletBalanceLak)&&(identical(other.settled, settled) || other.settled == settled)&&(identical(other.transaction, transaction) || other.transaction == transaction)&&(identical(other.instruction, instruction) || other.instruction == instruction));
}


@override
int get hashCode => Object.hash(runtimeType,receiptNo,amountLak,status,paymentState,methodCode,walletBalanceLak,settled,transaction,instruction);

@override
String toString() {
  return 'PaymentResult(receiptNo: $receiptNo, amountLak: $amountLak, status: $status, paymentState: $paymentState, methodCode: $methodCode, walletBalanceLak: $walletBalanceLak, settled: $settled, transaction: $transaction, instruction: $instruction)';
}


}

/// @nodoc
abstract mixin class _$PaymentResultCopyWith<$Res> implements $PaymentResultCopyWith<$Res> {
  factory _$PaymentResultCopyWith(_PaymentResult value, $Res Function(_PaymentResult) _then) = __$PaymentResultCopyWithImpl;
@override @useResult
$Res call({
 String receiptNo, int? amountLak, String status, String paymentState, String methodCode, int? walletBalanceLak, bool? settled, PaymentTransaction? transaction, PaymentInstruction? instruction
});


@override $PaymentTransactionCopyWith<$Res>? get transaction;@override $PaymentInstructionCopyWith<$Res>? get instruction;

}
/// @nodoc
class __$PaymentResultCopyWithImpl<$Res>
    implements _$PaymentResultCopyWith<$Res> {
  __$PaymentResultCopyWithImpl(this._self, this._then);

  final _PaymentResult _self;
  final $Res Function(_PaymentResult) _then;

/// Create a copy of PaymentResult
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? receiptNo = null,Object? amountLak = freezed,Object? status = null,Object? paymentState = null,Object? methodCode = null,Object? walletBalanceLak = freezed,Object? settled = freezed,Object? transaction = freezed,Object? instruction = freezed,}) {
  return _then(_PaymentResult(
receiptNo: null == receiptNo ? _self.receiptNo : receiptNo // ignore: cast_nullable_to_non_nullable
as String,amountLak: freezed == amountLak ? _self.amountLak : amountLak // ignore: cast_nullable_to_non_nullable
as int?,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,paymentState: null == paymentState ? _self.paymentState : paymentState // ignore: cast_nullable_to_non_nullable
as String,methodCode: null == methodCode ? _self.methodCode : methodCode // ignore: cast_nullable_to_non_nullable
as String,walletBalanceLak: freezed == walletBalanceLak ? _self.walletBalanceLak : walletBalanceLak // ignore: cast_nullable_to_non_nullable
as int?,settled: freezed == settled ? _self.settled : settled // ignore: cast_nullable_to_non_nullable
as bool?,transaction: freezed == transaction ? _self.transaction : transaction // ignore: cast_nullable_to_non_nullable
as PaymentTransaction?,instruction: freezed == instruction ? _self.instruction : instruction // ignore: cast_nullable_to_non_nullable
as PaymentInstruction?,
  ));
}

/// Create a copy of PaymentResult
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PaymentTransactionCopyWith<$Res>? get transaction {
    if (_self.transaction == null) {
    return null;
  }

  return $PaymentTransactionCopyWith<$Res>(_self.transaction!, (value) {
    return _then(_self.copyWith(transaction: value));
  });
}/// Create a copy of PaymentResult
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PaymentInstructionCopyWith<$Res>? get instruction {
    if (_self.instruction == null) {
    return null;
  }

  return $PaymentInstructionCopyWith<$Res>(_self.instruction!, (value) {
    return _then(_self.copyWith(instruction: value));
  });
}
}

// dart format on
