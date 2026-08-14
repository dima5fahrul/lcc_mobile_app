// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'application_row.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$ApplicationRow {

 String get id; String get referenceNo; String get serviceCode; Bilingual get serviceName; String get applicant; String get subjectName; CaseStatus get status; Bilingual get statusLabel; PaymentState get paymentState; int get feeLak; String get channel; Jurisdiction get jurisdiction; String? get assignedOfficer; int get slaDays; int get daysWaiting; int get daysOverdue; bool get isOverdue; String? get submittedAt; String? get dueAt; String? get issuedAt; String? get closedAt; String get createdAt; String get updatedAt; String? get reasonNote; String? get certificateId; String? get certificateNo;
/// Create a copy of ApplicationRow
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ApplicationRowCopyWith<ApplicationRow> get copyWith => _$ApplicationRowCopyWithImpl<ApplicationRow>(this as ApplicationRow, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ApplicationRow&&(identical(other.id, id) || other.id == id)&&(identical(other.referenceNo, referenceNo) || other.referenceNo == referenceNo)&&(identical(other.serviceCode, serviceCode) || other.serviceCode == serviceCode)&&(identical(other.serviceName, serviceName) || other.serviceName == serviceName)&&(identical(other.applicant, applicant) || other.applicant == applicant)&&(identical(other.subjectName, subjectName) || other.subjectName == subjectName)&&(identical(other.status, status) || other.status == status)&&(identical(other.statusLabel, statusLabel) || other.statusLabel == statusLabel)&&(identical(other.paymentState, paymentState) || other.paymentState == paymentState)&&(identical(other.feeLak, feeLak) || other.feeLak == feeLak)&&(identical(other.channel, channel) || other.channel == channel)&&(identical(other.jurisdiction, jurisdiction) || other.jurisdiction == jurisdiction)&&(identical(other.assignedOfficer, assignedOfficer) || other.assignedOfficer == assignedOfficer)&&(identical(other.slaDays, slaDays) || other.slaDays == slaDays)&&(identical(other.daysWaiting, daysWaiting) || other.daysWaiting == daysWaiting)&&(identical(other.daysOverdue, daysOverdue) || other.daysOverdue == daysOverdue)&&(identical(other.isOverdue, isOverdue) || other.isOverdue == isOverdue)&&(identical(other.submittedAt, submittedAt) || other.submittedAt == submittedAt)&&(identical(other.dueAt, dueAt) || other.dueAt == dueAt)&&(identical(other.issuedAt, issuedAt) || other.issuedAt == issuedAt)&&(identical(other.closedAt, closedAt) || other.closedAt == closedAt)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.reasonNote, reasonNote) || other.reasonNote == reasonNote)&&(identical(other.certificateId, certificateId) || other.certificateId == certificateId)&&(identical(other.certificateNo, certificateNo) || other.certificateNo == certificateNo));
}


@override
int get hashCode => Object.hashAll([runtimeType,id,referenceNo,serviceCode,serviceName,applicant,subjectName,status,statusLabel,paymentState,feeLak,channel,jurisdiction,assignedOfficer,slaDays,daysWaiting,daysOverdue,isOverdue,submittedAt,dueAt,issuedAt,closedAt,createdAt,updatedAt,reasonNote,certificateId,certificateNo]);

@override
String toString() {
  return 'ApplicationRow(id: $id, referenceNo: $referenceNo, serviceCode: $serviceCode, serviceName: $serviceName, applicant: $applicant, subjectName: $subjectName, status: $status, statusLabel: $statusLabel, paymentState: $paymentState, feeLak: $feeLak, channel: $channel, jurisdiction: $jurisdiction, assignedOfficer: $assignedOfficer, slaDays: $slaDays, daysWaiting: $daysWaiting, daysOverdue: $daysOverdue, isOverdue: $isOverdue, submittedAt: $submittedAt, dueAt: $dueAt, issuedAt: $issuedAt, closedAt: $closedAt, createdAt: $createdAt, updatedAt: $updatedAt, reasonNote: $reasonNote, certificateId: $certificateId, certificateNo: $certificateNo)';
}


}

/// @nodoc
abstract mixin class $ApplicationRowCopyWith<$Res>  {
  factory $ApplicationRowCopyWith(ApplicationRow value, $Res Function(ApplicationRow) _then) = _$ApplicationRowCopyWithImpl;
@useResult
$Res call({
 String id, String referenceNo, String serviceCode, Bilingual serviceName, String applicant, String subjectName, CaseStatus status, Bilingual statusLabel, PaymentState paymentState, int feeLak, String channel, Jurisdiction jurisdiction, String? assignedOfficer, int slaDays, int daysWaiting, int daysOverdue, bool isOverdue, String? submittedAt, String? dueAt, String? issuedAt, String? closedAt, String createdAt, String updatedAt, String? reasonNote, String? certificateId, String? certificateNo
});


$BilingualCopyWith<$Res> get serviceName;$BilingualCopyWith<$Res> get statusLabel;$JurisdictionCopyWith<$Res> get jurisdiction;

}
/// @nodoc
class _$ApplicationRowCopyWithImpl<$Res>
    implements $ApplicationRowCopyWith<$Res> {
  _$ApplicationRowCopyWithImpl(this._self, this._then);

  final ApplicationRow _self;
  final $Res Function(ApplicationRow) _then;

/// Create a copy of ApplicationRow
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? referenceNo = null,Object? serviceCode = null,Object? serviceName = null,Object? applicant = null,Object? subjectName = null,Object? status = null,Object? statusLabel = null,Object? paymentState = null,Object? feeLak = null,Object? channel = null,Object? jurisdiction = null,Object? assignedOfficer = freezed,Object? slaDays = null,Object? daysWaiting = null,Object? daysOverdue = null,Object? isOverdue = null,Object? submittedAt = freezed,Object? dueAt = freezed,Object? issuedAt = freezed,Object? closedAt = freezed,Object? createdAt = null,Object? updatedAt = null,Object? reasonNote = freezed,Object? certificateId = freezed,Object? certificateNo = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,referenceNo: null == referenceNo ? _self.referenceNo : referenceNo // ignore: cast_nullable_to_non_nullable
as String,serviceCode: null == serviceCode ? _self.serviceCode : serviceCode // ignore: cast_nullable_to_non_nullable
as String,serviceName: null == serviceName ? _self.serviceName : serviceName // ignore: cast_nullable_to_non_nullable
as Bilingual,applicant: null == applicant ? _self.applicant : applicant // ignore: cast_nullable_to_non_nullable
as String,subjectName: null == subjectName ? _self.subjectName : subjectName // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as CaseStatus,statusLabel: null == statusLabel ? _self.statusLabel : statusLabel // ignore: cast_nullable_to_non_nullable
as Bilingual,paymentState: null == paymentState ? _self.paymentState : paymentState // ignore: cast_nullable_to_non_nullable
as PaymentState,feeLak: null == feeLak ? _self.feeLak : feeLak // ignore: cast_nullable_to_non_nullable
as int,channel: null == channel ? _self.channel : channel // ignore: cast_nullable_to_non_nullable
as String,jurisdiction: null == jurisdiction ? _self.jurisdiction : jurisdiction // ignore: cast_nullable_to_non_nullable
as Jurisdiction,assignedOfficer: freezed == assignedOfficer ? _self.assignedOfficer : assignedOfficer // ignore: cast_nullable_to_non_nullable
as String?,slaDays: null == slaDays ? _self.slaDays : slaDays // ignore: cast_nullable_to_non_nullable
as int,daysWaiting: null == daysWaiting ? _self.daysWaiting : daysWaiting // ignore: cast_nullable_to_non_nullable
as int,daysOverdue: null == daysOverdue ? _self.daysOverdue : daysOverdue // ignore: cast_nullable_to_non_nullable
as int,isOverdue: null == isOverdue ? _self.isOverdue : isOverdue // ignore: cast_nullable_to_non_nullable
as bool,submittedAt: freezed == submittedAt ? _self.submittedAt : submittedAt // ignore: cast_nullable_to_non_nullable
as String?,dueAt: freezed == dueAt ? _self.dueAt : dueAt // ignore: cast_nullable_to_non_nullable
as String?,issuedAt: freezed == issuedAt ? _self.issuedAt : issuedAt // ignore: cast_nullable_to_non_nullable
as String?,closedAt: freezed == closedAt ? _self.closedAt : closedAt // ignore: cast_nullable_to_non_nullable
as String?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as String,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as String,reasonNote: freezed == reasonNote ? _self.reasonNote : reasonNote // ignore: cast_nullable_to_non_nullable
as String?,certificateId: freezed == certificateId ? _self.certificateId : certificateId // ignore: cast_nullable_to_non_nullable
as String?,certificateNo: freezed == certificateNo ? _self.certificateNo : certificateNo // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}
/// Create a copy of ApplicationRow
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BilingualCopyWith<$Res> get serviceName {
  
  return $BilingualCopyWith<$Res>(_self.serviceName, (value) {
    return _then(_self.copyWith(serviceName: value));
  });
}/// Create a copy of ApplicationRow
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BilingualCopyWith<$Res> get statusLabel {
  
  return $BilingualCopyWith<$Res>(_self.statusLabel, (value) {
    return _then(_self.copyWith(statusLabel: value));
  });
}/// Create a copy of ApplicationRow
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$JurisdictionCopyWith<$Res> get jurisdiction {
  
  return $JurisdictionCopyWith<$Res>(_self.jurisdiction, (value) {
    return _then(_self.copyWith(jurisdiction: value));
  });
}
}


/// Adds pattern-matching-related methods to [ApplicationRow].
extension ApplicationRowPatterns on ApplicationRow {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ApplicationRow value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ApplicationRow() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ApplicationRow value)  $default,){
final _that = this;
switch (_that) {
case _ApplicationRow():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ApplicationRow value)?  $default,){
final _that = this;
switch (_that) {
case _ApplicationRow() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String referenceNo,  String serviceCode,  Bilingual serviceName,  String applicant,  String subjectName,  CaseStatus status,  Bilingual statusLabel,  PaymentState paymentState,  int feeLak,  String channel,  Jurisdiction jurisdiction,  String? assignedOfficer,  int slaDays,  int daysWaiting,  int daysOverdue,  bool isOverdue,  String? submittedAt,  String? dueAt,  String? issuedAt,  String? closedAt,  String createdAt,  String updatedAt,  String? reasonNote,  String? certificateId,  String? certificateNo)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ApplicationRow() when $default != null:
return $default(_that.id,_that.referenceNo,_that.serviceCode,_that.serviceName,_that.applicant,_that.subjectName,_that.status,_that.statusLabel,_that.paymentState,_that.feeLak,_that.channel,_that.jurisdiction,_that.assignedOfficer,_that.slaDays,_that.daysWaiting,_that.daysOverdue,_that.isOverdue,_that.submittedAt,_that.dueAt,_that.issuedAt,_that.closedAt,_that.createdAt,_that.updatedAt,_that.reasonNote,_that.certificateId,_that.certificateNo);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String referenceNo,  String serviceCode,  Bilingual serviceName,  String applicant,  String subjectName,  CaseStatus status,  Bilingual statusLabel,  PaymentState paymentState,  int feeLak,  String channel,  Jurisdiction jurisdiction,  String? assignedOfficer,  int slaDays,  int daysWaiting,  int daysOverdue,  bool isOverdue,  String? submittedAt,  String? dueAt,  String? issuedAt,  String? closedAt,  String createdAt,  String updatedAt,  String? reasonNote,  String? certificateId,  String? certificateNo)  $default,) {final _that = this;
switch (_that) {
case _ApplicationRow():
return $default(_that.id,_that.referenceNo,_that.serviceCode,_that.serviceName,_that.applicant,_that.subjectName,_that.status,_that.statusLabel,_that.paymentState,_that.feeLak,_that.channel,_that.jurisdiction,_that.assignedOfficer,_that.slaDays,_that.daysWaiting,_that.daysOverdue,_that.isOverdue,_that.submittedAt,_that.dueAt,_that.issuedAt,_that.closedAt,_that.createdAt,_that.updatedAt,_that.reasonNote,_that.certificateId,_that.certificateNo);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String referenceNo,  String serviceCode,  Bilingual serviceName,  String applicant,  String subjectName,  CaseStatus status,  Bilingual statusLabel,  PaymentState paymentState,  int feeLak,  String channel,  Jurisdiction jurisdiction,  String? assignedOfficer,  int slaDays,  int daysWaiting,  int daysOverdue,  bool isOverdue,  String? submittedAt,  String? dueAt,  String? issuedAt,  String? closedAt,  String createdAt,  String updatedAt,  String? reasonNote,  String? certificateId,  String? certificateNo)?  $default,) {final _that = this;
switch (_that) {
case _ApplicationRow() when $default != null:
return $default(_that.id,_that.referenceNo,_that.serviceCode,_that.serviceName,_that.applicant,_that.subjectName,_that.status,_that.statusLabel,_that.paymentState,_that.feeLak,_that.channel,_that.jurisdiction,_that.assignedOfficer,_that.slaDays,_that.daysWaiting,_that.daysOverdue,_that.isOverdue,_that.submittedAt,_that.dueAt,_that.issuedAt,_that.closedAt,_that.createdAt,_that.updatedAt,_that.reasonNote,_that.certificateId,_that.certificateNo);case _:
  return null;

}
}

}

/// @nodoc


class _ApplicationRow extends ApplicationRow {
  const _ApplicationRow({required this.id, required this.referenceNo, required this.serviceCode, required this.serviceName, required this.applicant, required this.subjectName, required this.status, required this.statusLabel, required this.paymentState, required this.feeLak, required this.channel, required this.jurisdiction, this.assignedOfficer, required this.slaDays, required this.daysWaiting, required this.daysOverdue, required this.isOverdue, this.submittedAt, this.dueAt, this.issuedAt, this.closedAt, required this.createdAt, required this.updatedAt, this.reasonNote, this.certificateId, this.certificateNo}): super._();
  

@override final  String id;
@override final  String referenceNo;
@override final  String serviceCode;
@override final  Bilingual serviceName;
@override final  String applicant;
@override final  String subjectName;
@override final  CaseStatus status;
@override final  Bilingual statusLabel;
@override final  PaymentState paymentState;
@override final  int feeLak;
@override final  String channel;
@override final  Jurisdiction jurisdiction;
@override final  String? assignedOfficer;
@override final  int slaDays;
@override final  int daysWaiting;
@override final  int daysOverdue;
@override final  bool isOverdue;
@override final  String? submittedAt;
@override final  String? dueAt;
@override final  String? issuedAt;
@override final  String? closedAt;
@override final  String createdAt;
@override final  String updatedAt;
@override final  String? reasonNote;
@override final  String? certificateId;
@override final  String? certificateNo;

/// Create a copy of ApplicationRow
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ApplicationRowCopyWith<_ApplicationRow> get copyWith => __$ApplicationRowCopyWithImpl<_ApplicationRow>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ApplicationRow&&(identical(other.id, id) || other.id == id)&&(identical(other.referenceNo, referenceNo) || other.referenceNo == referenceNo)&&(identical(other.serviceCode, serviceCode) || other.serviceCode == serviceCode)&&(identical(other.serviceName, serviceName) || other.serviceName == serviceName)&&(identical(other.applicant, applicant) || other.applicant == applicant)&&(identical(other.subjectName, subjectName) || other.subjectName == subjectName)&&(identical(other.status, status) || other.status == status)&&(identical(other.statusLabel, statusLabel) || other.statusLabel == statusLabel)&&(identical(other.paymentState, paymentState) || other.paymentState == paymentState)&&(identical(other.feeLak, feeLak) || other.feeLak == feeLak)&&(identical(other.channel, channel) || other.channel == channel)&&(identical(other.jurisdiction, jurisdiction) || other.jurisdiction == jurisdiction)&&(identical(other.assignedOfficer, assignedOfficer) || other.assignedOfficer == assignedOfficer)&&(identical(other.slaDays, slaDays) || other.slaDays == slaDays)&&(identical(other.daysWaiting, daysWaiting) || other.daysWaiting == daysWaiting)&&(identical(other.daysOverdue, daysOverdue) || other.daysOverdue == daysOverdue)&&(identical(other.isOverdue, isOverdue) || other.isOverdue == isOverdue)&&(identical(other.submittedAt, submittedAt) || other.submittedAt == submittedAt)&&(identical(other.dueAt, dueAt) || other.dueAt == dueAt)&&(identical(other.issuedAt, issuedAt) || other.issuedAt == issuedAt)&&(identical(other.closedAt, closedAt) || other.closedAt == closedAt)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.reasonNote, reasonNote) || other.reasonNote == reasonNote)&&(identical(other.certificateId, certificateId) || other.certificateId == certificateId)&&(identical(other.certificateNo, certificateNo) || other.certificateNo == certificateNo));
}


@override
int get hashCode => Object.hashAll([runtimeType,id,referenceNo,serviceCode,serviceName,applicant,subjectName,status,statusLabel,paymentState,feeLak,channel,jurisdiction,assignedOfficer,slaDays,daysWaiting,daysOverdue,isOverdue,submittedAt,dueAt,issuedAt,closedAt,createdAt,updatedAt,reasonNote,certificateId,certificateNo]);

@override
String toString() {
  return 'ApplicationRow(id: $id, referenceNo: $referenceNo, serviceCode: $serviceCode, serviceName: $serviceName, applicant: $applicant, subjectName: $subjectName, status: $status, statusLabel: $statusLabel, paymentState: $paymentState, feeLak: $feeLak, channel: $channel, jurisdiction: $jurisdiction, assignedOfficer: $assignedOfficer, slaDays: $slaDays, daysWaiting: $daysWaiting, daysOverdue: $daysOverdue, isOverdue: $isOverdue, submittedAt: $submittedAt, dueAt: $dueAt, issuedAt: $issuedAt, closedAt: $closedAt, createdAt: $createdAt, updatedAt: $updatedAt, reasonNote: $reasonNote, certificateId: $certificateId, certificateNo: $certificateNo)';
}


}

/// @nodoc
abstract mixin class _$ApplicationRowCopyWith<$Res> implements $ApplicationRowCopyWith<$Res> {
  factory _$ApplicationRowCopyWith(_ApplicationRow value, $Res Function(_ApplicationRow) _then) = __$ApplicationRowCopyWithImpl;
@override @useResult
$Res call({
 String id, String referenceNo, String serviceCode, Bilingual serviceName, String applicant, String subjectName, CaseStatus status, Bilingual statusLabel, PaymentState paymentState, int feeLak, String channel, Jurisdiction jurisdiction, String? assignedOfficer, int slaDays, int daysWaiting, int daysOverdue, bool isOverdue, String? submittedAt, String? dueAt, String? issuedAt, String? closedAt, String createdAt, String updatedAt, String? reasonNote, String? certificateId, String? certificateNo
});


@override $BilingualCopyWith<$Res> get serviceName;@override $BilingualCopyWith<$Res> get statusLabel;@override $JurisdictionCopyWith<$Res> get jurisdiction;

}
/// @nodoc
class __$ApplicationRowCopyWithImpl<$Res>
    implements _$ApplicationRowCopyWith<$Res> {
  __$ApplicationRowCopyWithImpl(this._self, this._then);

  final _ApplicationRow _self;
  final $Res Function(_ApplicationRow) _then;

/// Create a copy of ApplicationRow
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? referenceNo = null,Object? serviceCode = null,Object? serviceName = null,Object? applicant = null,Object? subjectName = null,Object? status = null,Object? statusLabel = null,Object? paymentState = null,Object? feeLak = null,Object? channel = null,Object? jurisdiction = null,Object? assignedOfficer = freezed,Object? slaDays = null,Object? daysWaiting = null,Object? daysOverdue = null,Object? isOverdue = null,Object? submittedAt = freezed,Object? dueAt = freezed,Object? issuedAt = freezed,Object? closedAt = freezed,Object? createdAt = null,Object? updatedAt = null,Object? reasonNote = freezed,Object? certificateId = freezed,Object? certificateNo = freezed,}) {
  return _then(_ApplicationRow(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,referenceNo: null == referenceNo ? _self.referenceNo : referenceNo // ignore: cast_nullable_to_non_nullable
as String,serviceCode: null == serviceCode ? _self.serviceCode : serviceCode // ignore: cast_nullable_to_non_nullable
as String,serviceName: null == serviceName ? _self.serviceName : serviceName // ignore: cast_nullable_to_non_nullable
as Bilingual,applicant: null == applicant ? _self.applicant : applicant // ignore: cast_nullable_to_non_nullable
as String,subjectName: null == subjectName ? _self.subjectName : subjectName // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as CaseStatus,statusLabel: null == statusLabel ? _self.statusLabel : statusLabel // ignore: cast_nullable_to_non_nullable
as Bilingual,paymentState: null == paymentState ? _self.paymentState : paymentState // ignore: cast_nullable_to_non_nullable
as PaymentState,feeLak: null == feeLak ? _self.feeLak : feeLak // ignore: cast_nullable_to_non_nullable
as int,channel: null == channel ? _self.channel : channel // ignore: cast_nullable_to_non_nullable
as String,jurisdiction: null == jurisdiction ? _self.jurisdiction : jurisdiction // ignore: cast_nullable_to_non_nullable
as Jurisdiction,assignedOfficer: freezed == assignedOfficer ? _self.assignedOfficer : assignedOfficer // ignore: cast_nullable_to_non_nullable
as String?,slaDays: null == slaDays ? _self.slaDays : slaDays // ignore: cast_nullable_to_non_nullable
as int,daysWaiting: null == daysWaiting ? _self.daysWaiting : daysWaiting // ignore: cast_nullable_to_non_nullable
as int,daysOverdue: null == daysOverdue ? _self.daysOverdue : daysOverdue // ignore: cast_nullable_to_non_nullable
as int,isOverdue: null == isOverdue ? _self.isOverdue : isOverdue // ignore: cast_nullable_to_non_nullable
as bool,submittedAt: freezed == submittedAt ? _self.submittedAt : submittedAt // ignore: cast_nullable_to_non_nullable
as String?,dueAt: freezed == dueAt ? _self.dueAt : dueAt // ignore: cast_nullable_to_non_nullable
as String?,issuedAt: freezed == issuedAt ? _self.issuedAt : issuedAt // ignore: cast_nullable_to_non_nullable
as String?,closedAt: freezed == closedAt ? _self.closedAt : closedAt // ignore: cast_nullable_to_non_nullable
as String?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as String,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as String,reasonNote: freezed == reasonNote ? _self.reasonNote : reasonNote // ignore: cast_nullable_to_non_nullable
as String?,certificateId: freezed == certificateId ? _self.certificateId : certificateId // ignore: cast_nullable_to_non_nullable
as String?,certificateNo: freezed == certificateNo ? _self.certificateNo : certificateNo // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

/// Create a copy of ApplicationRow
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BilingualCopyWith<$Res> get serviceName {
  
  return $BilingualCopyWith<$Res>(_self.serviceName, (value) {
    return _then(_self.copyWith(serviceName: value));
  });
}/// Create a copy of ApplicationRow
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BilingualCopyWith<$Res> get statusLabel {
  
  return $BilingualCopyWith<$Res>(_self.statusLabel, (value) {
    return _then(_self.copyWith(statusLabel: value));
  });
}/// Create a copy of ApplicationRow
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$JurisdictionCopyWith<$Res> get jurisdiction {
  
  return $JurisdictionCopyWith<$Res>(_self.jurisdiction, (value) {
    return _then(_self.copyWith(jurisdiction: value));
  });
}
}

// dart format on
