// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'case_event.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$CaseEvent {

 String get id; String get action; CaseStatus? get fromStatus; CaseStatus get toStatus;/// Nullable, and the nullability is rendered — see the library doc.
 Bilingual? get statusLabel; String? get actorId; String? get actorName; String? get actorRole; String? get reasonCode; String? get note; String get occurredAt;
/// Create a copy of CaseEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CaseEventCopyWith<CaseEvent> get copyWith => _$CaseEventCopyWithImpl<CaseEvent>(this as CaseEvent, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CaseEvent&&(identical(other.id, id) || other.id == id)&&(identical(other.action, action) || other.action == action)&&(identical(other.fromStatus, fromStatus) || other.fromStatus == fromStatus)&&(identical(other.toStatus, toStatus) || other.toStatus == toStatus)&&(identical(other.statusLabel, statusLabel) || other.statusLabel == statusLabel)&&(identical(other.actorId, actorId) || other.actorId == actorId)&&(identical(other.actorName, actorName) || other.actorName == actorName)&&(identical(other.actorRole, actorRole) || other.actorRole == actorRole)&&(identical(other.reasonCode, reasonCode) || other.reasonCode == reasonCode)&&(identical(other.note, note) || other.note == note)&&(identical(other.occurredAt, occurredAt) || other.occurredAt == occurredAt));
}


@override
int get hashCode => Object.hash(runtimeType,id,action,fromStatus,toStatus,statusLabel,actorId,actorName,actorRole,reasonCode,note,occurredAt);

@override
String toString() {
  return 'CaseEvent(id: $id, action: $action, fromStatus: $fromStatus, toStatus: $toStatus, statusLabel: $statusLabel, actorId: $actorId, actorName: $actorName, actorRole: $actorRole, reasonCode: $reasonCode, note: $note, occurredAt: $occurredAt)';
}


}

/// @nodoc
abstract mixin class $CaseEventCopyWith<$Res>  {
  factory $CaseEventCopyWith(CaseEvent value, $Res Function(CaseEvent) _then) = _$CaseEventCopyWithImpl;
@useResult
$Res call({
 String id, String action, CaseStatus? fromStatus, CaseStatus toStatus, Bilingual? statusLabel, String? actorId, String? actorName, String? actorRole, String? reasonCode, String? note, String occurredAt
});


$BilingualCopyWith<$Res>? get statusLabel;

}
/// @nodoc
class _$CaseEventCopyWithImpl<$Res>
    implements $CaseEventCopyWith<$Res> {
  _$CaseEventCopyWithImpl(this._self, this._then);

  final CaseEvent _self;
  final $Res Function(CaseEvent) _then;

/// Create a copy of CaseEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? action = null,Object? fromStatus = freezed,Object? toStatus = null,Object? statusLabel = freezed,Object? actorId = freezed,Object? actorName = freezed,Object? actorRole = freezed,Object? reasonCode = freezed,Object? note = freezed,Object? occurredAt = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,action: null == action ? _self.action : action // ignore: cast_nullable_to_non_nullable
as String,fromStatus: freezed == fromStatus ? _self.fromStatus : fromStatus // ignore: cast_nullable_to_non_nullable
as CaseStatus?,toStatus: null == toStatus ? _self.toStatus : toStatus // ignore: cast_nullable_to_non_nullable
as CaseStatus,statusLabel: freezed == statusLabel ? _self.statusLabel : statusLabel // ignore: cast_nullable_to_non_nullable
as Bilingual?,actorId: freezed == actorId ? _self.actorId : actorId // ignore: cast_nullable_to_non_nullable
as String?,actorName: freezed == actorName ? _self.actorName : actorName // ignore: cast_nullable_to_non_nullable
as String?,actorRole: freezed == actorRole ? _self.actorRole : actorRole // ignore: cast_nullable_to_non_nullable
as String?,reasonCode: freezed == reasonCode ? _self.reasonCode : reasonCode // ignore: cast_nullable_to_non_nullable
as String?,note: freezed == note ? _self.note : note // ignore: cast_nullable_to_non_nullable
as String?,occurredAt: null == occurredAt ? _self.occurredAt : occurredAt // ignore: cast_nullable_to_non_nullable
as String,
  ));
}
/// Create a copy of CaseEvent
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BilingualCopyWith<$Res>? get statusLabel {
    if (_self.statusLabel == null) {
    return null;
  }

  return $BilingualCopyWith<$Res>(_self.statusLabel!, (value) {
    return _then(_self.copyWith(statusLabel: value));
  });
}
}


/// Adds pattern-matching-related methods to [CaseEvent].
extension CaseEventPatterns on CaseEvent {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CaseEvent value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CaseEvent() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CaseEvent value)  $default,){
final _that = this;
switch (_that) {
case _CaseEvent():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CaseEvent value)?  $default,){
final _that = this;
switch (_that) {
case _CaseEvent() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String action,  CaseStatus? fromStatus,  CaseStatus toStatus,  Bilingual? statusLabel,  String? actorId,  String? actorName,  String? actorRole,  String? reasonCode,  String? note,  String occurredAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CaseEvent() when $default != null:
return $default(_that.id,_that.action,_that.fromStatus,_that.toStatus,_that.statusLabel,_that.actorId,_that.actorName,_that.actorRole,_that.reasonCode,_that.note,_that.occurredAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String action,  CaseStatus? fromStatus,  CaseStatus toStatus,  Bilingual? statusLabel,  String? actorId,  String? actorName,  String? actorRole,  String? reasonCode,  String? note,  String occurredAt)  $default,) {final _that = this;
switch (_that) {
case _CaseEvent():
return $default(_that.id,_that.action,_that.fromStatus,_that.toStatus,_that.statusLabel,_that.actorId,_that.actorName,_that.actorRole,_that.reasonCode,_that.note,_that.occurredAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String action,  CaseStatus? fromStatus,  CaseStatus toStatus,  Bilingual? statusLabel,  String? actorId,  String? actorName,  String? actorRole,  String? reasonCode,  String? note,  String occurredAt)?  $default,) {final _that = this;
switch (_that) {
case _CaseEvent() when $default != null:
return $default(_that.id,_that.action,_that.fromStatus,_that.toStatus,_that.statusLabel,_that.actorId,_that.actorName,_that.actorRole,_that.reasonCode,_that.note,_that.occurredAt);case _:
  return null;

}
}

}

/// @nodoc


class _CaseEvent extends CaseEvent {
  const _CaseEvent({required this.id, required this.action, this.fromStatus, required this.toStatus, this.statusLabel, this.actorId, this.actorName, this.actorRole, this.reasonCode, this.note, required this.occurredAt}): super._();
  

@override final  String id;
@override final  String action;
@override final  CaseStatus? fromStatus;
@override final  CaseStatus toStatus;
/// Nullable, and the nullability is rendered — see the library doc.
@override final  Bilingual? statusLabel;
@override final  String? actorId;
@override final  String? actorName;
@override final  String? actorRole;
@override final  String? reasonCode;
@override final  String? note;
@override final  String occurredAt;

/// Create a copy of CaseEvent
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CaseEventCopyWith<_CaseEvent> get copyWith => __$CaseEventCopyWithImpl<_CaseEvent>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CaseEvent&&(identical(other.id, id) || other.id == id)&&(identical(other.action, action) || other.action == action)&&(identical(other.fromStatus, fromStatus) || other.fromStatus == fromStatus)&&(identical(other.toStatus, toStatus) || other.toStatus == toStatus)&&(identical(other.statusLabel, statusLabel) || other.statusLabel == statusLabel)&&(identical(other.actorId, actorId) || other.actorId == actorId)&&(identical(other.actorName, actorName) || other.actorName == actorName)&&(identical(other.actorRole, actorRole) || other.actorRole == actorRole)&&(identical(other.reasonCode, reasonCode) || other.reasonCode == reasonCode)&&(identical(other.note, note) || other.note == note)&&(identical(other.occurredAt, occurredAt) || other.occurredAt == occurredAt));
}


@override
int get hashCode => Object.hash(runtimeType,id,action,fromStatus,toStatus,statusLabel,actorId,actorName,actorRole,reasonCode,note,occurredAt);

@override
String toString() {
  return 'CaseEvent(id: $id, action: $action, fromStatus: $fromStatus, toStatus: $toStatus, statusLabel: $statusLabel, actorId: $actorId, actorName: $actorName, actorRole: $actorRole, reasonCode: $reasonCode, note: $note, occurredAt: $occurredAt)';
}


}

/// @nodoc
abstract mixin class _$CaseEventCopyWith<$Res> implements $CaseEventCopyWith<$Res> {
  factory _$CaseEventCopyWith(_CaseEvent value, $Res Function(_CaseEvent) _then) = __$CaseEventCopyWithImpl;
@override @useResult
$Res call({
 String id, String action, CaseStatus? fromStatus, CaseStatus toStatus, Bilingual? statusLabel, String? actorId, String? actorName, String? actorRole, String? reasonCode, String? note, String occurredAt
});


@override $BilingualCopyWith<$Res>? get statusLabel;

}
/// @nodoc
class __$CaseEventCopyWithImpl<$Res>
    implements _$CaseEventCopyWith<$Res> {
  __$CaseEventCopyWithImpl(this._self, this._then);

  final _CaseEvent _self;
  final $Res Function(_CaseEvent) _then;

/// Create a copy of CaseEvent
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? action = null,Object? fromStatus = freezed,Object? toStatus = null,Object? statusLabel = freezed,Object? actorId = freezed,Object? actorName = freezed,Object? actorRole = freezed,Object? reasonCode = freezed,Object? note = freezed,Object? occurredAt = null,}) {
  return _then(_CaseEvent(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,action: null == action ? _self.action : action // ignore: cast_nullable_to_non_nullable
as String,fromStatus: freezed == fromStatus ? _self.fromStatus : fromStatus // ignore: cast_nullable_to_non_nullable
as CaseStatus?,toStatus: null == toStatus ? _self.toStatus : toStatus // ignore: cast_nullable_to_non_nullable
as CaseStatus,statusLabel: freezed == statusLabel ? _self.statusLabel : statusLabel // ignore: cast_nullable_to_non_nullable
as Bilingual?,actorId: freezed == actorId ? _self.actorId : actorId // ignore: cast_nullable_to_non_nullable
as String?,actorName: freezed == actorName ? _self.actorName : actorName // ignore: cast_nullable_to_non_nullable
as String?,actorRole: freezed == actorRole ? _self.actorRole : actorRole // ignore: cast_nullable_to_non_nullable
as String?,reasonCode: freezed == reasonCode ? _self.reasonCode : reasonCode // ignore: cast_nullable_to_non_nullable
as String?,note: freezed == note ? _self.note : note // ignore: cast_nullable_to_non_nullable
as String?,occurredAt: null == occurredAt ? _self.occurredAt : occurredAt // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

/// Create a copy of CaseEvent
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BilingualCopyWith<$Res>? get statusLabel {
    if (_self.statusLabel == null) {
    return null;
  }

  return $BilingualCopyWith<$Res>(_self.statusLabel!, (value) {
    return _then(_self.copyWith(statusLabel: value));
  });
}
}

// dart format on
