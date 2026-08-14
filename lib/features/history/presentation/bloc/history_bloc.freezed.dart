// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'history_bloc.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$HistoryState {

// ── The list ─────────────────────────────────────────────────────────────
 RegionStatus get listStatus; ApplicationPage get result;// ── The four tiles ───────────────────────────────────────────────────────
 RegionStatus get countsStatus; HistoryCounts get counts;// ── The pipeline ─────────────────────────────────────────────────────────
//
// Seeded, not empty. `statusCatalogue.ts:27-33` exports `PIPELINE`
// pre-populated so a progress bar never renders blank and so an offline
// start still counts "Step 1 of 5" against something.
 StatusPipeline get pipeline;/// The selected chip — a key of `kFilterStatuses`.
 String get filter;/// What is in the box right now. Moves on every keystroke so the field is
/// not laggy.
 String get searchQuery;/// The debounced, trimmed term that is actually on the wire —
/// `useDebounced(query.trim(), 350)`.
 String get search;/// The requested page. Moves on tap, ahead of the response, so the pager
/// does not lag its own controls.
 int get page;/// The failed list response's own message — `list.error.message`,
/// `HistoryPage.tsx:254`.
///
/// The web prints the **API's** sentence here, not one of its own, so the
/// port carries it rather than dropping it on the fold. An earlier cut of
/// this file discarded the `Failure` and rendered a fixed
/// `history.listError` string; that reads better and is a divergence
/// (`B7-AC-35`, ADR-0001 — the shipped web is the source of truth, and
/// "mirror the web exactly" beats cleverness).
 String get listError;
/// Create a copy of HistoryState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$HistoryStateCopyWith<HistoryState> get copyWith => _$HistoryStateCopyWithImpl<HistoryState>(this as HistoryState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is HistoryState&&(identical(other.listStatus, listStatus) || other.listStatus == listStatus)&&(identical(other.result, result) || other.result == result)&&(identical(other.countsStatus, countsStatus) || other.countsStatus == countsStatus)&&(identical(other.counts, counts) || other.counts == counts)&&(identical(other.pipeline, pipeline) || other.pipeline == pipeline)&&(identical(other.filter, filter) || other.filter == filter)&&(identical(other.searchQuery, searchQuery) || other.searchQuery == searchQuery)&&(identical(other.search, search) || other.search == search)&&(identical(other.page, page) || other.page == page)&&(identical(other.listError, listError) || other.listError == listError));
}


@override
int get hashCode => Object.hash(runtimeType,listStatus,result,countsStatus,counts,pipeline,filter,searchQuery,search,page,listError);

@override
String toString() {
  return 'HistoryState(listStatus: $listStatus, result: $result, countsStatus: $countsStatus, counts: $counts, pipeline: $pipeline, filter: $filter, searchQuery: $searchQuery, search: $search, page: $page, listError: $listError)';
}


}

/// @nodoc
abstract mixin class $HistoryStateCopyWith<$Res>  {
  factory $HistoryStateCopyWith(HistoryState value, $Res Function(HistoryState) _then) = _$HistoryStateCopyWithImpl;
@useResult
$Res call({
 RegionStatus listStatus, ApplicationPage result, RegionStatus countsStatus, HistoryCounts counts, StatusPipeline pipeline, String filter, String searchQuery, String search, int page, String listError
});




}
/// @nodoc
class _$HistoryStateCopyWithImpl<$Res>
    implements $HistoryStateCopyWith<$Res> {
  _$HistoryStateCopyWithImpl(this._self, this._then);

  final HistoryState _self;
  final $Res Function(HistoryState) _then;

/// Create a copy of HistoryState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? listStatus = null,Object? result = null,Object? countsStatus = null,Object? counts = null,Object? pipeline = null,Object? filter = null,Object? searchQuery = null,Object? search = null,Object? page = null,Object? listError = null,}) {
  return _then(_self.copyWith(
listStatus: null == listStatus ? _self.listStatus : listStatus // ignore: cast_nullable_to_non_nullable
as RegionStatus,result: null == result ? _self.result : result // ignore: cast_nullable_to_non_nullable
as ApplicationPage,countsStatus: null == countsStatus ? _self.countsStatus : countsStatus // ignore: cast_nullable_to_non_nullable
as RegionStatus,counts: null == counts ? _self.counts : counts // ignore: cast_nullable_to_non_nullable
as HistoryCounts,pipeline: null == pipeline ? _self.pipeline : pipeline // ignore: cast_nullable_to_non_nullable
as StatusPipeline,filter: null == filter ? _self.filter : filter // ignore: cast_nullable_to_non_nullable
as String,searchQuery: null == searchQuery ? _self.searchQuery : searchQuery // ignore: cast_nullable_to_non_nullable
as String,search: null == search ? _self.search : search // ignore: cast_nullable_to_non_nullable
as String,page: null == page ? _self.page : page // ignore: cast_nullable_to_non_nullable
as int,listError: null == listError ? _self.listError : listError // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [HistoryState].
extension HistoryStatePatterns on HistoryState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _HistoryState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _HistoryState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _HistoryState value)  $default,){
final _that = this;
switch (_that) {
case _HistoryState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _HistoryState value)?  $default,){
final _that = this;
switch (_that) {
case _HistoryState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( RegionStatus listStatus,  ApplicationPage result,  RegionStatus countsStatus,  HistoryCounts counts,  StatusPipeline pipeline,  String filter,  String searchQuery,  String search,  int page,  String listError)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _HistoryState() when $default != null:
return $default(_that.listStatus,_that.result,_that.countsStatus,_that.counts,_that.pipeline,_that.filter,_that.searchQuery,_that.search,_that.page,_that.listError);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( RegionStatus listStatus,  ApplicationPage result,  RegionStatus countsStatus,  HistoryCounts counts,  StatusPipeline pipeline,  String filter,  String searchQuery,  String search,  int page,  String listError)  $default,) {final _that = this;
switch (_that) {
case _HistoryState():
return $default(_that.listStatus,_that.result,_that.countsStatus,_that.counts,_that.pipeline,_that.filter,_that.searchQuery,_that.search,_that.page,_that.listError);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( RegionStatus listStatus,  ApplicationPage result,  RegionStatus countsStatus,  HistoryCounts counts,  StatusPipeline pipeline,  String filter,  String searchQuery,  String search,  int page,  String listError)?  $default,) {final _that = this;
switch (_that) {
case _HistoryState() when $default != null:
return $default(_that.listStatus,_that.result,_that.countsStatus,_that.counts,_that.pipeline,_that.filter,_that.searchQuery,_that.search,_that.page,_that.listError);case _:
  return null;

}
}

}

/// @nodoc


class _HistoryState extends HistoryState {
  const _HistoryState({this.listStatus = RegionStatus.initial, this.result = ApplicationPage.empty, this.countsStatus = RegionStatus.initial, this.counts = HistoryCounts.zero, this.pipeline = StatusPipeline.seeded, this.filter = kFilterAll, this.searchQuery = '', this.search = '', this.page = 1, this.listError = ''}): super._();
  

// ── The list ─────────────────────────────────────────────────────────────
@override@JsonKey() final  RegionStatus listStatus;
@override@JsonKey() final  ApplicationPage result;
// ── The four tiles ───────────────────────────────────────────────────────
@override@JsonKey() final  RegionStatus countsStatus;
@override@JsonKey() final  HistoryCounts counts;
// ── The pipeline ─────────────────────────────────────────────────────────
//
// Seeded, not empty. `statusCatalogue.ts:27-33` exports `PIPELINE`
// pre-populated so a progress bar never renders blank and so an offline
// start still counts "Step 1 of 5" against something.
@override@JsonKey() final  StatusPipeline pipeline;
/// The selected chip — a key of `kFilterStatuses`.
@override@JsonKey() final  String filter;
/// What is in the box right now. Moves on every keystroke so the field is
/// not laggy.
@override@JsonKey() final  String searchQuery;
/// The debounced, trimmed term that is actually on the wire —
/// `useDebounced(query.trim(), 350)`.
@override@JsonKey() final  String search;
/// The requested page. Moves on tap, ahead of the response, so the pager
/// does not lag its own controls.
@override@JsonKey() final  int page;
/// The failed list response's own message — `list.error.message`,
/// `HistoryPage.tsx:254`.
///
/// The web prints the **API's** sentence here, not one of its own, so the
/// port carries it rather than dropping it on the fold. An earlier cut of
/// this file discarded the `Failure` and rendered a fixed
/// `history.listError` string; that reads better and is a divergence
/// (`B7-AC-35`, ADR-0001 — the shipped web is the source of truth, and
/// "mirror the web exactly" beats cleverness).
@override@JsonKey() final  String listError;

/// Create a copy of HistoryState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$HistoryStateCopyWith<_HistoryState> get copyWith => __$HistoryStateCopyWithImpl<_HistoryState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _HistoryState&&(identical(other.listStatus, listStatus) || other.listStatus == listStatus)&&(identical(other.result, result) || other.result == result)&&(identical(other.countsStatus, countsStatus) || other.countsStatus == countsStatus)&&(identical(other.counts, counts) || other.counts == counts)&&(identical(other.pipeline, pipeline) || other.pipeline == pipeline)&&(identical(other.filter, filter) || other.filter == filter)&&(identical(other.searchQuery, searchQuery) || other.searchQuery == searchQuery)&&(identical(other.search, search) || other.search == search)&&(identical(other.page, page) || other.page == page)&&(identical(other.listError, listError) || other.listError == listError));
}


@override
int get hashCode => Object.hash(runtimeType,listStatus,result,countsStatus,counts,pipeline,filter,searchQuery,search,page,listError);

@override
String toString() {
  return 'HistoryState(listStatus: $listStatus, result: $result, countsStatus: $countsStatus, counts: $counts, pipeline: $pipeline, filter: $filter, searchQuery: $searchQuery, search: $search, page: $page, listError: $listError)';
}


}

/// @nodoc
abstract mixin class _$HistoryStateCopyWith<$Res> implements $HistoryStateCopyWith<$Res> {
  factory _$HistoryStateCopyWith(_HistoryState value, $Res Function(_HistoryState) _then) = __$HistoryStateCopyWithImpl;
@override @useResult
$Res call({
 RegionStatus listStatus, ApplicationPage result, RegionStatus countsStatus, HistoryCounts counts, StatusPipeline pipeline, String filter, String searchQuery, String search, int page, String listError
});




}
/// @nodoc
class __$HistoryStateCopyWithImpl<$Res>
    implements _$HistoryStateCopyWith<$Res> {
  __$HistoryStateCopyWithImpl(this._self, this._then);

  final _HistoryState _self;
  final $Res Function(_HistoryState) _then;

/// Create a copy of HistoryState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? listStatus = null,Object? result = null,Object? countsStatus = null,Object? counts = null,Object? pipeline = null,Object? filter = null,Object? searchQuery = null,Object? search = null,Object? page = null,Object? listError = null,}) {
  return _then(_HistoryState(
listStatus: null == listStatus ? _self.listStatus : listStatus // ignore: cast_nullable_to_non_nullable
as RegionStatus,result: null == result ? _self.result : result // ignore: cast_nullable_to_non_nullable
as ApplicationPage,countsStatus: null == countsStatus ? _self.countsStatus : countsStatus // ignore: cast_nullable_to_non_nullable
as RegionStatus,counts: null == counts ? _self.counts : counts // ignore: cast_nullable_to_non_nullable
as HistoryCounts,pipeline: null == pipeline ? _self.pipeline : pipeline // ignore: cast_nullable_to_non_nullable
as StatusPipeline,filter: null == filter ? _self.filter : filter // ignore: cast_nullable_to_non_nullable
as String,searchQuery: null == searchQuery ? _self.searchQuery : searchQuery // ignore: cast_nullable_to_non_nullable
as String,search: null == search ? _self.search : search // ignore: cast_nullable_to_non_nullable
as String,page: null == page ? _self.page : page // ignore: cast_nullable_to_non_nullable
as int,listError: null == listError ? _self.listError : listError // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
