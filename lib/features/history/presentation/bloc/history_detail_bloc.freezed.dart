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
 CaseTimeline? get timeline; String get timelineError;// ── The certificate query (B5, specs.md § 6.6) ───────────────────────────
/// The **list** query's region status — `certListQuery` (`:149`). The
/// single fetch at `:157` deliberately does **not** move it: the source's
/// `:486` gate reads `certListQuery.loading` and nothing else, so folding
/// the two would make the note disappear during a fetch the source does
/// not wait for (`B5-AC-44`).
 RegionStatus get certificateStatus;/// `certFromList ?? certOneQuery.data` — `:160`. Null until one of the two
/// resolves, and permanently null when neither has a match.
 IssuedCertificate? get certificate;/// **Every** certificate of this application, in the server's list order —
/// review I-2, 2026-10-22, and the spec's implementation checklist
/// (*"grouped by `application_id`; label by `document_type` and `copy`"*).
///
/// A divorce issues three rows for one application (joint card, booklet A,
/// booklet B) and [certificate] can only ever name one of them, so the
/// document actions read this list instead. Empty until the list query
/// answers; a single-document application holds exactly one entry and the
/// surface renders what it always did.
///
/// Carried **beside** [certificate] rather than replacing it: `:160`'s
/// `certFromList ?? certOneQuery.data` precedence, the single-fetch skip
/// (`B5-AC-41`) and `showsCertificatePanel` are all about the one row the
/// source picks, and none of them changes.
 List<IssuedCertificate> get certificates;/// The backend's own sentence when the certificate slice fails. Carried on
/// its **own** field so a certificate outage cannot be mistaken for a case
/// outage: the source runs three independent `useQuery`s and the detail and
/// the timeline keep their data (`B5-AC-31`).
 String get certificateError;
/// Create a copy of HistoryDetailState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$HistoryDetailStateCopyWith<HistoryDetailState> get copyWith => _$HistoryDetailStateCopyWithImpl<HistoryDetailState>(this as HistoryDetailState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is HistoryDetailState&&(identical(other.applicationId, applicationId) || other.applicationId == applicationId)&&(identical(other.detailStatus, detailStatus) || other.detailStatus == detailStatus)&&(identical(other.detail, detail) || other.detail == detail)&&(identical(other.detailError, detailError) || other.detailError == detailError)&&(identical(other.detailNotFound, detailNotFound) || other.detailNotFound == detailNotFound)&&(identical(other.refreshing, refreshing) || other.refreshing == refreshing)&&(identical(other.timelineStatus, timelineStatus) || other.timelineStatus == timelineStatus)&&(identical(other.timeline, timeline) || other.timeline == timeline)&&(identical(other.timelineError, timelineError) || other.timelineError == timelineError)&&(identical(other.certificateStatus, certificateStatus) || other.certificateStatus == certificateStatus)&&(identical(other.certificate, certificate) || other.certificate == certificate)&&const DeepCollectionEquality().equals(other.certificates, certificates)&&(identical(other.certificateError, certificateError) || other.certificateError == certificateError));
}


@override
int get hashCode => Object.hash(runtimeType,applicationId,detailStatus,detail,detailError,detailNotFound,refreshing,timelineStatus,timeline,timelineError,certificateStatus,certificate,const DeepCollectionEquality().hash(certificates),certificateError);

@override
String toString() {
  return 'HistoryDetailState(applicationId: $applicationId, detailStatus: $detailStatus, detail: $detail, detailError: $detailError, detailNotFound: $detailNotFound, refreshing: $refreshing, timelineStatus: $timelineStatus, timeline: $timeline, timelineError: $timelineError, certificateStatus: $certificateStatus, certificate: $certificate, certificates: $certificates, certificateError: $certificateError)';
}


}

/// @nodoc
abstract mixin class $HistoryDetailStateCopyWith<$Res>  {
  factory $HistoryDetailStateCopyWith(HistoryDetailState value, $Res Function(HistoryDetailState) _then) = _$HistoryDetailStateCopyWithImpl;
@useResult
$Res call({
 String applicationId, RegionStatus detailStatus, ApplicationDetail? detail, String detailError, bool detailNotFound, bool refreshing, RegionStatus timelineStatus, CaseTimeline? timeline, String timelineError, RegionStatus certificateStatus, IssuedCertificate? certificate, List<IssuedCertificate> certificates, String certificateError
});


$ApplicationDetailCopyWith<$Res>? get detail;$CaseTimelineCopyWith<$Res>? get timeline;$IssuedCertificateCopyWith<$Res>? get certificate;

}
/// @nodoc
class _$HistoryDetailStateCopyWithImpl<$Res>
    implements $HistoryDetailStateCopyWith<$Res> {
  _$HistoryDetailStateCopyWithImpl(this._self, this._then);

  final HistoryDetailState _self;
  final $Res Function(HistoryDetailState) _then;

/// Create a copy of HistoryDetailState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? applicationId = null,Object? detailStatus = null,Object? detail = freezed,Object? detailError = null,Object? detailNotFound = null,Object? refreshing = null,Object? timelineStatus = null,Object? timeline = freezed,Object? timelineError = null,Object? certificateStatus = null,Object? certificate = freezed,Object? certificates = null,Object? certificateError = null,}) {
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
as String,certificateStatus: null == certificateStatus ? _self.certificateStatus : certificateStatus // ignore: cast_nullable_to_non_nullable
as RegionStatus,certificate: freezed == certificate ? _self.certificate : certificate // ignore: cast_nullable_to_non_nullable
as IssuedCertificate?,certificates: null == certificates ? _self.certificates : certificates // ignore: cast_nullable_to_non_nullable
as List<IssuedCertificate>,certificateError: null == certificateError ? _self.certificateError : certificateError // ignore: cast_nullable_to_non_nullable
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
}/// Create a copy of HistoryDetailState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$IssuedCertificateCopyWith<$Res>? get certificate {
    if (_self.certificate == null) {
    return null;
  }

  return $IssuedCertificateCopyWith<$Res>(_self.certificate!, (value) {
    return _then(_self.copyWith(certificate: value));
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String applicationId,  RegionStatus detailStatus,  ApplicationDetail? detail,  String detailError,  bool detailNotFound,  bool refreshing,  RegionStatus timelineStatus,  CaseTimeline? timeline,  String timelineError,  RegionStatus certificateStatus,  IssuedCertificate? certificate,  List<IssuedCertificate> certificates,  String certificateError)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _HistoryDetailState() when $default != null:
return $default(_that.applicationId,_that.detailStatus,_that.detail,_that.detailError,_that.detailNotFound,_that.refreshing,_that.timelineStatus,_that.timeline,_that.timelineError,_that.certificateStatus,_that.certificate,_that.certificates,_that.certificateError);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String applicationId,  RegionStatus detailStatus,  ApplicationDetail? detail,  String detailError,  bool detailNotFound,  bool refreshing,  RegionStatus timelineStatus,  CaseTimeline? timeline,  String timelineError,  RegionStatus certificateStatus,  IssuedCertificate? certificate,  List<IssuedCertificate> certificates,  String certificateError)  $default,) {final _that = this;
switch (_that) {
case _HistoryDetailState():
return $default(_that.applicationId,_that.detailStatus,_that.detail,_that.detailError,_that.detailNotFound,_that.refreshing,_that.timelineStatus,_that.timeline,_that.timelineError,_that.certificateStatus,_that.certificate,_that.certificates,_that.certificateError);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String applicationId,  RegionStatus detailStatus,  ApplicationDetail? detail,  String detailError,  bool detailNotFound,  bool refreshing,  RegionStatus timelineStatus,  CaseTimeline? timeline,  String timelineError,  RegionStatus certificateStatus,  IssuedCertificate? certificate,  List<IssuedCertificate> certificates,  String certificateError)?  $default,) {final _that = this;
switch (_that) {
case _HistoryDetailState() when $default != null:
return $default(_that.applicationId,_that.detailStatus,_that.detail,_that.detailError,_that.detailNotFound,_that.refreshing,_that.timelineStatus,_that.timeline,_that.timelineError,_that.certificateStatus,_that.certificate,_that.certificates,_that.certificateError);case _:
  return null;

}
}

}

/// @nodoc


class _HistoryDetailState extends HistoryDetailState {
  const _HistoryDetailState({this.applicationId = '', this.detailStatus = RegionStatus.initial, this.detail, this.detailError = '', this.detailNotFound = false, this.refreshing = false, this.timelineStatus = RegionStatus.initial, this.timeline, this.timelineError = '', this.certificateStatus = RegionStatus.initial, this.certificate, final  List<IssuedCertificate> certificates = const <IssuedCertificate>[], this.certificateError = ''}): _certificates = certificates,super._();
  

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
// ── The certificate query (B5, specs.md § 6.6) ───────────────────────────
/// The **list** query's region status — `certListQuery` (`:149`). The
/// single fetch at `:157` deliberately does **not** move it: the source's
/// `:486` gate reads `certListQuery.loading` and nothing else, so folding
/// the two would make the note disappear during a fetch the source does
/// not wait for (`B5-AC-44`).
@override@JsonKey() final  RegionStatus certificateStatus;
/// `certFromList ?? certOneQuery.data` — `:160`. Null until one of the two
/// resolves, and permanently null when neither has a match.
@override final  IssuedCertificate? certificate;
/// **Every** certificate of this application, in the server's list order —
/// review I-2, 2026-10-22, and the spec's implementation checklist
/// (*"grouped by `application_id`; label by `document_type` and `copy`"*).
///
/// A divorce issues three rows for one application (joint card, booklet A,
/// booklet B) and [certificate] can only ever name one of them, so the
/// document actions read this list instead. Empty until the list query
/// answers; a single-document application holds exactly one entry and the
/// surface renders what it always did.
///
/// Carried **beside** [certificate] rather than replacing it: `:160`'s
/// `certFromList ?? certOneQuery.data` precedence, the single-fetch skip
/// (`B5-AC-41`) and `showsCertificatePanel` are all about the one row the
/// source picks, and none of them changes.
 final  List<IssuedCertificate> _certificates;
/// **Every** certificate of this application, in the server's list order —
/// review I-2, 2026-10-22, and the spec's implementation checklist
/// (*"grouped by `application_id`; label by `document_type` and `copy`"*).
///
/// A divorce issues three rows for one application (joint card, booklet A,
/// booklet B) and [certificate] can only ever name one of them, so the
/// document actions read this list instead. Empty until the list query
/// answers; a single-document application holds exactly one entry and the
/// surface renders what it always did.
///
/// Carried **beside** [certificate] rather than replacing it: `:160`'s
/// `certFromList ?? certOneQuery.data` precedence, the single-fetch skip
/// (`B5-AC-41`) and `showsCertificatePanel` are all about the one row the
/// source picks, and none of them changes.
@override@JsonKey() List<IssuedCertificate> get certificates {
  if (_certificates is EqualUnmodifiableListView) return _certificates;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_certificates);
}

/// The backend's own sentence when the certificate slice fails. Carried on
/// its **own** field so a certificate outage cannot be mistaken for a case
/// outage: the source runs three independent `useQuery`s and the detail and
/// the timeline keep their data (`B5-AC-31`).
@override@JsonKey() final  String certificateError;

/// Create a copy of HistoryDetailState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$HistoryDetailStateCopyWith<_HistoryDetailState> get copyWith => __$HistoryDetailStateCopyWithImpl<_HistoryDetailState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _HistoryDetailState&&(identical(other.applicationId, applicationId) || other.applicationId == applicationId)&&(identical(other.detailStatus, detailStatus) || other.detailStatus == detailStatus)&&(identical(other.detail, detail) || other.detail == detail)&&(identical(other.detailError, detailError) || other.detailError == detailError)&&(identical(other.detailNotFound, detailNotFound) || other.detailNotFound == detailNotFound)&&(identical(other.refreshing, refreshing) || other.refreshing == refreshing)&&(identical(other.timelineStatus, timelineStatus) || other.timelineStatus == timelineStatus)&&(identical(other.timeline, timeline) || other.timeline == timeline)&&(identical(other.timelineError, timelineError) || other.timelineError == timelineError)&&(identical(other.certificateStatus, certificateStatus) || other.certificateStatus == certificateStatus)&&(identical(other.certificate, certificate) || other.certificate == certificate)&&const DeepCollectionEquality().equals(other._certificates, _certificates)&&(identical(other.certificateError, certificateError) || other.certificateError == certificateError));
}


@override
int get hashCode => Object.hash(runtimeType,applicationId,detailStatus,detail,detailError,detailNotFound,refreshing,timelineStatus,timeline,timelineError,certificateStatus,certificate,const DeepCollectionEquality().hash(_certificates),certificateError);

@override
String toString() {
  return 'HistoryDetailState(applicationId: $applicationId, detailStatus: $detailStatus, detail: $detail, detailError: $detailError, detailNotFound: $detailNotFound, refreshing: $refreshing, timelineStatus: $timelineStatus, timeline: $timeline, timelineError: $timelineError, certificateStatus: $certificateStatus, certificate: $certificate, certificates: $certificates, certificateError: $certificateError)';
}


}

/// @nodoc
abstract mixin class _$HistoryDetailStateCopyWith<$Res> implements $HistoryDetailStateCopyWith<$Res> {
  factory _$HistoryDetailStateCopyWith(_HistoryDetailState value, $Res Function(_HistoryDetailState) _then) = __$HistoryDetailStateCopyWithImpl;
@override @useResult
$Res call({
 String applicationId, RegionStatus detailStatus, ApplicationDetail? detail, String detailError, bool detailNotFound, bool refreshing, RegionStatus timelineStatus, CaseTimeline? timeline, String timelineError, RegionStatus certificateStatus, IssuedCertificate? certificate, List<IssuedCertificate> certificates, String certificateError
});


@override $ApplicationDetailCopyWith<$Res>? get detail;@override $CaseTimelineCopyWith<$Res>? get timeline;@override $IssuedCertificateCopyWith<$Res>? get certificate;

}
/// @nodoc
class __$HistoryDetailStateCopyWithImpl<$Res>
    implements _$HistoryDetailStateCopyWith<$Res> {
  __$HistoryDetailStateCopyWithImpl(this._self, this._then);

  final _HistoryDetailState _self;
  final $Res Function(_HistoryDetailState) _then;

/// Create a copy of HistoryDetailState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? applicationId = null,Object? detailStatus = null,Object? detail = freezed,Object? detailError = null,Object? detailNotFound = null,Object? refreshing = null,Object? timelineStatus = null,Object? timeline = freezed,Object? timelineError = null,Object? certificateStatus = null,Object? certificate = freezed,Object? certificates = null,Object? certificateError = null,}) {
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
as String,certificateStatus: null == certificateStatus ? _self.certificateStatus : certificateStatus // ignore: cast_nullable_to_non_nullable
as RegionStatus,certificate: freezed == certificate ? _self.certificate : certificate // ignore: cast_nullable_to_non_nullable
as IssuedCertificate?,certificates: null == certificates ? _self._certificates : certificates // ignore: cast_nullable_to_non_nullable
as List<IssuedCertificate>,certificateError: null == certificateError ? _self.certificateError : certificateError // ignore: cast_nullable_to_non_nullable
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
}/// Create a copy of HistoryDetailState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$IssuedCertificateCopyWith<$Res>? get certificate {
    if (_self.certificate == null) {
    return null;
  }

  return $IssuedCertificateCopyWith<$Res>(_self.certificate!, (value) {
    return _then(_self.copyWith(certificate: value));
  });
}
}

// dart format on
