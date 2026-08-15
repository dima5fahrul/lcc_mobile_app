// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'history_detail_bloc.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$HistoryDetailState {

/// Which case is open. Empty before [HistoryDetailStarted].
 String get applicationId;// ── The detail query ─────────────────────────────────────────────────────
 RegionStatus get detailStatus; ApplicationDetail? get detail;/// `detailQuery.error?.message` — **the backend's own sentence**
/// (`HistoryDetailPage.tsx:205`), not a fixed string of the app's.
///
/// B7a's list state carries the same field for the same reason and records
/// the mistake that made it necessary: an earlier cut rendered a fixed
/// `history.listError` and discarded the `Failure` entirely. `B7-AC-35`
/// pinned that; this is the same shape one page over, so it is written
/// carrying the message from the first line rather than fixed later.
 String get detailError;/// `detailQuery.error?.isNotFound` — `:201`. **A separate field, not a
/// substring test on [detailError]**: the two branches print different copy
/// and telling them apart by matching the message text works right up until
/// the backend rewords a sentence (`B7-AC-54`).
 bool get detailNotFound;/// `detailQuery.refreshing` — `:414` spins the glyph on this and nothing
/// else. True only while a reload runs with a case already on screen.
 bool get refreshing;// ── The timeline query ───────────────────────────────────────────────────
 RegionStatus get timelineStatus;/// **Null until the query succeeds**, and that nullability is the first
/// link of `:249`'s fallback chain — see [events].
 CaseTimeline? get timeline; String get timelineError;
/// Create a copy of HistoryDetailState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$HistoryDetailStateCopyWith<HistoryDetailState> get copyWith => _$HistoryDetailStateCopyWithImpl<HistoryDetailState>(this as HistoryDetailState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is HistoryDetailState&&(identical(other.applicationId, applicationId) || other.applicationId == applicationId)&&(identical(other.detailStatus, detailStatus) || other.detailStatus == detailStatus)&&(identical(other.detail, detail) || other.detail == detail)&&(identical(other.detailError, detailError) || other.detailError == detailError)&&(identical(other.detailNotFound, detailNotFound) || other.detailNotFound == detailNotFound)&&(identical(other.refreshing, refreshing) || other.refreshing == refreshing)&&(identical(other.timelineStatus, timelineStatus) || other.timelineStatus == timelineStatus)&&(identical(other.timeline, timeline) || other.timeline == timeline)&&(identical(other.timelineError, timelineError) || other.timelineError == timelineError));
}


@override
int get hashCode => Object.hash(runtimeType,applicationId,detailStatus,detail,detailError,detailNotFound,refreshing,timelineStatus,timeline,timelineError);

@override
String toString() {
  return 'HistoryDetailState(applicationId: $applicationId, detailStatus: $detailStatus, detail: $detail, detailError: $detailError, detailNotFound: $detailNotFound, refreshing: $refreshing, timelineStatus: $timelineStatus, timeline: $timeline, timelineError: $timelineError)';
}


}

/// @nodoc
abstract mixin class $HistoryDetailStateCopyWith<$Res>  {
  factory $HistoryDetailStateCopyWith(HistoryDetailState value, $Res Function(HistoryDetailState) _then) = _$HistoryDetailStateCopyWithImpl;
@useResult
$Res call({
 String applicationId, RegionStatus detailStatus, ApplicationDetail? detail, String detailError, bool detailNotFound, bool refreshing, RegionStatus timelineStatus, CaseTimeline? timeline, String timelineError
});


$ApplicationDetailCopyWith<$Res>? get detail;$CaseTimelineCopyWith<$Res>? get timeline;

}
/// @nodoc
class _$HistoryDetailStateCopyWithImpl<$Res>
    implements $HistoryDetailStateCopyWith<$Res> {
  _$HistoryDetailStateCopyWithImpl(this._self, this._then);

  final HistoryDetailState _self;
  final $Res Function(HistoryDetailState) _then;

/// Create a copy of HistoryDetailState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? applicationId = null,Object? detailStatus = null,Object? detail = freezed,Object? detailError = null,Object? detailNotFound = null,Object? refreshing = null,Object? timelineStatus = null,Object? timeline = freezed,Object? timelineError = null,}) {
  return _then(_self.copyWith(
applicationId: null == applicationId ? _self.applicationId : applicationId // ignore: cast_nullable_to_non_nullable
as String,detailStatus: null == detailStatus ? _self.detailStatus : detailStatus // ignore: cast_nullable_to_non_nullable
as RegionStatus,detail: freezed == detail ? _self.detail : detail // ignore: cast_nullable_to_non_nullable
as ApplicationDetail?,detailError: null == detailError ? _self.detailError : detailError // ignore: cast_nullable_to_non_nullable
as String,detailNotFound: null == detailNotFound ? _self.detailNotFound : detailNotFound // ignore: cast_nullable_to_non_nullable
as bool,refreshing: null == refreshing ? _self.refreshing : refreshing // ignore: cast_nullable_to_non_nullable
as bool,timelineStatus: null == timelineStatus ? _self.timelineStatus : timelineStatus // ignore: cast_nullable_to_non_nullable
as RegionStatus,timeline: freezed == timeline ? _self.timeline : timeline // ignore: cast_nullable_to_non_nullable
as CaseTimeline?,timelineError: null == timelineError ? _self.timelineError : timelineError // ignore: cast_nullable_to_non_nullable
as String,
  ));
}
/// Create a copy of HistoryDetailState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ApplicationDetailCopyWith<$Res>? get detail {
    if (_self.detail == null) {
    return null;
  }

  return $ApplicationDetailCopyWith<$Res>(_self.detail!, (value) {
    return _then(_self.copyWith(detail: value));
  });
}/// Create a copy of HistoryDetailState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CaseTimelineCopyWith<$Res>? get timeline {
    if (_self.timeline == null) {
    return null;
  }

  return $CaseTimelineCopyWith<$Res>(_self.timeline!, (value) {
    return _then(_self.copyWith(timeline: value));
  });
}
}


/// Adds pattern-matching-related methods to [HistoryDetailState].
extension HistoryDetailStatePatterns on HistoryDetailState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _HistoryDetailState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _HistoryDetailState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _HistoryDetailState value)  $default,){
final _that = this;
switch (_that) {
case _HistoryDetailState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _HistoryDetailState value)?  $default,){
final _that = this;
switch (_that) {
case _HistoryDetailState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String applicationId,  RegionStatus detailStatus,  ApplicationDetail? detail,  String detailError,  bool detailNotFound,  bool refreshing,  RegionStatus timelineStatus,  CaseTimeline? timeline,  String timelineError)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _HistoryDetailState() when $default != null:
return $default(_that.applicationId,_that.detailStatus,_that.detail,_that.detailError,_that.detailNotFound,_that.refreshing,_that.timelineStatus,_that.timeline,_that.timelineError);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String applicationId,  RegionStatus detailStatus,  ApplicationDetail? detail,  String detailError,  bool detailNotFound,  bool refreshing,  RegionStatus timelineStatus,  CaseTimeline? timeline,  String timelineError)  $default,) {final _that = this;
switch (_that) {
case _HistoryDetailState():
return $default(_that.applicationId,_that.detailStatus,_that.detail,_that.detailError,_that.detailNotFound,_that.refreshing,_that.timelineStatus,_that.timeline,_that.timelineError);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String applicationId,  RegionStatus detailStatus,  ApplicationDetail? detail,  String detailError,  bool detailNotFound,  bool refreshing,  RegionStatus timelineStatus,  CaseTimeline? timeline,  String timelineError)?  $default,) {final _that = this;
switch (_that) {
case _HistoryDetailState() when $default != null:
return $default(_that.applicationId,_that.detailStatus,_that.detail,_that.detailError,_that.detailNotFound,_that.refreshing,_that.timelineStatus,_that.timeline,_that.timelineError);case _:
  return null;

}
}

}

/// @nodoc


class _HistoryDetailState extends HistoryDetailState {
  const _HistoryDetailState({this.applicationId = '', this.detailStatus = RegionStatus.initial, this.detail, this.detailError = '', this.detailNotFound = false, this.refreshing = false, this.timelineStatus = RegionStatus.initial, this.timeline, this.timelineError = ''}): super._();
  

/// Which case is open. Empty before [HistoryDetailStarted].
@override@JsonKey() final  String applicationId;
// ── The detail query ─────────────────────────────────────────────────────
@override@JsonKey() final  RegionStatus detailStatus;
@override final  ApplicationDetail? detail;
/// `detailQuery.error?.message` — **the backend's own sentence**
/// (`HistoryDetailPage.tsx:205`), not a fixed string of the app's.
///
/// B7a's list state carries the same field for the same reason and records
/// the mistake that made it necessary: an earlier cut rendered a fixed
/// `history.listError` and discarded the `Failure` entirely. `B7-AC-35`
/// pinned that; this is the same shape one page over, so it is written
/// carrying the message from the first line rather than fixed later.
@override@JsonKey() final  String detailError;
/// `detailQuery.error?.isNotFound` — `:201`. **A separate field, not a
/// substring test on [detailError]**: the two branches print different copy
/// and telling them apart by matching the message text works right up until
/// the backend rewords a sentence (`B7-AC-54`).
@override@JsonKey() final  bool detailNotFound;
/// `detailQuery.refreshing` — `:414` spins the glyph on this and nothing
/// else. True only while a reload runs with a case already on screen.
@override@JsonKey() final  bool refreshing;
// ── The timeline query ───────────────────────────────────────────────────
@override@JsonKey() final  RegionStatus timelineStatus;
/// **Null until the query succeeds**, and that nullability is the first
/// link of `:249`'s fallback chain — see [events].
@override final  CaseTimeline? timeline;
@override@JsonKey() final  String timelineError;

/// Create a copy of HistoryDetailState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$HistoryDetailStateCopyWith<_HistoryDetailState> get copyWith => __$HistoryDetailStateCopyWithImpl<_HistoryDetailState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _HistoryDetailState&&(identical(other.applicationId, applicationId) || other.applicationId == applicationId)&&(identical(other.detailStatus, detailStatus) || other.detailStatus == detailStatus)&&(identical(other.detail, detail) || other.detail == detail)&&(identical(other.detailError, detailError) || other.detailError == detailError)&&(identical(other.detailNotFound, detailNotFound) || other.detailNotFound == detailNotFound)&&(identical(other.refreshing, refreshing) || other.refreshing == refreshing)&&(identical(other.timelineStatus, timelineStatus) || other.timelineStatus == timelineStatus)&&(identical(other.timeline, timeline) || other.timeline == timeline)&&(identical(other.timelineError, timelineError) || other.timelineError == timelineError));
}


@override
int get hashCode => Object.hash(runtimeType,applicationId,detailStatus,detail,detailError,detailNotFound,refreshing,timelineStatus,timeline,timelineError);

@override
String toString() {
  return 'HistoryDetailState(applicationId: $applicationId, detailStatus: $detailStatus, detail: $detail, detailError: $detailError, detailNotFound: $detailNotFound, refreshing: $refreshing, timelineStatus: $timelineStatus, timeline: $timeline, timelineError: $timelineError)';
}


}

/// @nodoc
abstract mixin class _$HistoryDetailStateCopyWith<$Res> implements $HistoryDetailStateCopyWith<$Res> {
  factory _$HistoryDetailStateCopyWith(_HistoryDetailState value, $Res Function(_HistoryDetailState) _then) = __$HistoryDetailStateCopyWithImpl;
@override @useResult
$Res call({
 String applicationId, RegionStatus detailStatus, ApplicationDetail? detail, String detailError, bool detailNotFound, bool refreshing, RegionStatus timelineStatus, CaseTimeline? timeline, String timelineError
});


@override $ApplicationDetailCopyWith<$Res>? get detail;@override $CaseTimelineCopyWith<$Res>? get timeline;

}
/// @nodoc
class __$HistoryDetailStateCopyWithImpl<$Res>
    implements _$HistoryDetailStateCopyWith<$Res> {
  __$HistoryDetailStateCopyWithImpl(this._self, this._then);

  final _HistoryDetailState _self;
  final $Res Function(_HistoryDetailState) _then;

/// Create a copy of HistoryDetailState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? applicationId = null,Object? detailStatus = null,Object? detail = freezed,Object? detailError = null,Object? detailNotFound = null,Object? refreshing = null,Object? timelineStatus = null,Object? timeline = freezed,Object? timelineError = null,}) {
  return _then(_HistoryDetailState(
applicationId: null == applicationId ? _self.applicationId : applicationId // ignore: cast_nullable_to_non_nullable
as String,detailStatus: null == detailStatus ? _self.detailStatus : detailStatus // ignore: cast_nullable_to_non_nullable
as RegionStatus,detail: freezed == detail ? _self.detail : detail // ignore: cast_nullable_to_non_nullable
as ApplicationDetail?,detailError: null == detailError ? _self.detailError : detailError // ignore: cast_nullable_to_non_nullable
as String,detailNotFound: null == detailNotFound ? _self.detailNotFound : detailNotFound // ignore: cast_nullable_to_non_nullable
as bool,refreshing: null == refreshing ? _self.refreshing : refreshing // ignore: cast_nullable_to_non_nullable
as bool,timelineStatus: null == timelineStatus ? _self.timelineStatus : timelineStatus // ignore: cast_nullable_to_non_nullable
as RegionStatus,timeline: freezed == timeline ? _self.timeline : timeline // ignore: cast_nullable_to_non_nullable
as CaseTimeline?,timelineError: null == timelineError ? _self.timelineError : timelineError // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

/// Create a copy of HistoryDetailState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ApplicationDetailCopyWith<$Res>? get detail {
    if (_self.detail == null) {
    return null;
  }

  return $ApplicationDetailCopyWith<$Res>(_self.detail!, (value) {
    return _then(_self.copyWith(detail: value));
  });
}/// Create a copy of HistoryDetailState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CaseTimelineCopyWith<$Res>? get timeline {
    if (_self.timeline == null) {
    return null;
  }

  return $CaseTimelineCopyWith<$Res>(_self.timeline!, (value) {
    return _then(_self.copyWith(timeline: value));
  });
}
}

// dart format on
