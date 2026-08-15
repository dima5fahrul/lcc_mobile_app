// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'case_timeline.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$CaseTimeline {

 String get applicationId; String get referenceNo; CaseStatus get status; List<CaseEvent> get events;
/// Create a copy of CaseTimeline
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CaseTimelineCopyWith<CaseTimeline> get copyWith => _$CaseTimelineCopyWithImpl<CaseTimeline>(this as CaseTimeline, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CaseTimeline&&(identical(other.applicationId, applicationId) || other.applicationId == applicationId)&&(identical(other.referenceNo, referenceNo) || other.referenceNo == referenceNo)&&(identical(other.status, status) || other.status == status)&&const DeepCollectionEquality().equals(other.events, events));
}


@override
int get hashCode => Object.hash(runtimeType,applicationId,referenceNo,status,const DeepCollectionEquality().hash(events));

@override
String toString() {
  return 'CaseTimeline(applicationId: $applicationId, referenceNo: $referenceNo, status: $status, events: $events)';
}


}

/// @nodoc
abstract mixin class $CaseTimelineCopyWith<$Res>  {
  factory $CaseTimelineCopyWith(CaseTimeline value, $Res Function(CaseTimeline) _then) = _$CaseTimelineCopyWithImpl;
@useResult
$Res call({
 String applicationId, String referenceNo, CaseStatus status, List<CaseEvent> events
});




}
/// @nodoc
class _$CaseTimelineCopyWithImpl<$Res>
    implements $CaseTimelineCopyWith<$Res> {
  _$CaseTimelineCopyWithImpl(this._self, this._then);

  final CaseTimeline _self;
  final $Res Function(CaseTimeline) _then;

/// Create a copy of CaseTimeline
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? applicationId = null,Object? referenceNo = null,Object? status = null,Object? events = null,}) {
  return _then(_self.copyWith(
applicationId: null == applicationId ? _self.applicationId : applicationId // ignore: cast_nullable_to_non_nullable
as String,referenceNo: null == referenceNo ? _self.referenceNo : referenceNo // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as CaseStatus,events: null == events ? _self.events : events // ignore: cast_nullable_to_non_nullable
as List<CaseEvent>,
  ));
}

}


/// Adds pattern-matching-related methods to [CaseTimeline].
extension CaseTimelinePatterns on CaseTimeline {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CaseTimeline value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CaseTimeline() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CaseTimeline value)  $default,){
final _that = this;
switch (_that) {
case _CaseTimeline():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CaseTimeline value)?  $default,){
final _that = this;
switch (_that) {
case _CaseTimeline() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String applicationId,  String referenceNo,  CaseStatus status,  List<CaseEvent> events)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CaseTimeline() when $default != null:
return $default(_that.applicationId,_that.referenceNo,_that.status,_that.events);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String applicationId,  String referenceNo,  CaseStatus status,  List<CaseEvent> events)  $default,) {final _that = this;
switch (_that) {
case _CaseTimeline():
return $default(_that.applicationId,_that.referenceNo,_that.status,_that.events);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String applicationId,  String referenceNo,  CaseStatus status,  List<CaseEvent> events)?  $default,) {final _that = this;
switch (_that) {
case _CaseTimeline() when $default != null:
return $default(_that.applicationId,_that.referenceNo,_that.status,_that.events);case _:
  return null;

}
}

}

/// @nodoc


class _CaseTimeline extends CaseTimeline {
  const _CaseTimeline({required this.applicationId, required this.referenceNo, required this.status, final  List<CaseEvent> events = const <CaseEvent>[]}): _events = events,super._();
  

@override final  String applicationId;
@override final  String referenceNo;
@override final  CaseStatus status;
 final  List<CaseEvent> _events;
@override@JsonKey() List<CaseEvent> get events {
  if (_events is EqualUnmodifiableListView) return _events;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_events);
}


/// Create a copy of CaseTimeline
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CaseTimelineCopyWith<_CaseTimeline> get copyWith => __$CaseTimelineCopyWithImpl<_CaseTimeline>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CaseTimeline&&(identical(other.applicationId, applicationId) || other.applicationId == applicationId)&&(identical(other.referenceNo, referenceNo) || other.referenceNo == referenceNo)&&(identical(other.status, status) || other.status == status)&&const DeepCollectionEquality().equals(other._events, _events));
}


@override
int get hashCode => Object.hash(runtimeType,applicationId,referenceNo,status,const DeepCollectionEquality().hash(_events));

@override
String toString() {
  return 'CaseTimeline(applicationId: $applicationId, referenceNo: $referenceNo, status: $status, events: $events)';
}


}

/// @nodoc
abstract mixin class _$CaseTimelineCopyWith<$Res> implements $CaseTimelineCopyWith<$Res> {
  factory _$CaseTimelineCopyWith(_CaseTimeline value, $Res Function(_CaseTimeline) _then) = __$CaseTimelineCopyWithImpl;
@override @useResult
$Res call({
 String applicationId, String referenceNo, CaseStatus status, List<CaseEvent> events
});




}
/// @nodoc
class __$CaseTimelineCopyWithImpl<$Res>
    implements _$CaseTimelineCopyWith<$Res> {
  __$CaseTimelineCopyWithImpl(this._self, this._then);

  final _CaseTimeline _self;
  final $Res Function(_CaseTimeline) _then;

/// Create a copy of CaseTimeline
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? applicationId = null,Object? referenceNo = null,Object? status = null,Object? events = null,}) {
  return _then(_CaseTimeline(
applicationId: null == applicationId ? _self.applicationId : applicationId // ignore: cast_nullable_to_non_nullable
as String,referenceNo: null == referenceNo ? _self.referenceNo : referenceNo // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as CaseStatus,events: null == events ? _self._events : events // ignore: cast_nullable_to_non_nullable
as List<CaseEvent>,
  ));
}


}

// dart format on
