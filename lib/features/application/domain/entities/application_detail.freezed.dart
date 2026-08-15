// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'application_detail.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$ApplicationDetail {

/// The 26 fields of `ApplicationRow`, parsed by the list's own parser.
 ApplicationRow get row;/// `attachments: Attachment[]` — required in the source, so an absent key
/// is an empty list and not a null. The empty list is a **rendered state**
/// (`HistoryDetailPage.tsx:596-599`), which is the one part of the
/// attachments card B7b ships (see `attachment.dart`).
 List<Attachment> get attachments;/// `timeline?: CaseEvent[]` — **optional, and the optionality is load
/// bearing.** `:249` is
/// `timelineQuery.data?.events ?? detail.timeline ?? []`: a null here falls
/// through to the empty list, an empty list here does **not** fall through
/// to anything. `B7-AC-62` asserts all three arrangements, so this must
/// stay nullable rather than defaulting to `const []`.
 List<CaseEvent>? get timeline; String? get linkedReferenceNo;
/// Create a copy of ApplicationDetail
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ApplicationDetailCopyWith<ApplicationDetail> get copyWith => _$ApplicationDetailCopyWithImpl<ApplicationDetail>(this as ApplicationDetail, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ApplicationDetail&&(identical(other.row, row) || other.row == row)&&const DeepCollectionEquality().equals(other.attachments, attachments)&&const DeepCollectionEquality().equals(other.timeline, timeline)&&(identical(other.linkedReferenceNo, linkedReferenceNo) || other.linkedReferenceNo == linkedReferenceNo));
}


@override
int get hashCode => Object.hash(runtimeType,row,const DeepCollectionEquality().hash(attachments),const DeepCollectionEquality().hash(timeline),linkedReferenceNo);

@override
String toString() {
  return 'ApplicationDetail(row: $row, attachments: $attachments, timeline: $timeline, linkedReferenceNo: $linkedReferenceNo)';
}


}

/// @nodoc
abstract mixin class $ApplicationDetailCopyWith<$Res>  {
  factory $ApplicationDetailCopyWith(ApplicationDetail value, $Res Function(ApplicationDetail) _then) = _$ApplicationDetailCopyWithImpl;
@useResult
$Res call({
 ApplicationRow row, List<Attachment> attachments, List<CaseEvent>? timeline, String? linkedReferenceNo
});


$ApplicationRowCopyWith<$Res> get row;

}
/// @nodoc
class _$ApplicationDetailCopyWithImpl<$Res>
    implements $ApplicationDetailCopyWith<$Res> {
  _$ApplicationDetailCopyWithImpl(this._self, this._then);

  final ApplicationDetail _self;
  final $Res Function(ApplicationDetail) _then;

/// Create a copy of ApplicationDetail
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? row = null,Object? attachments = null,Object? timeline = freezed,Object? linkedReferenceNo = freezed,}) {
  return _then(_self.copyWith(
row: null == row ? _self.row : row // ignore: cast_nullable_to_non_nullable
as ApplicationRow,attachments: null == attachments ? _self.attachments : attachments // ignore: cast_nullable_to_non_nullable
as List<Attachment>,timeline: freezed == timeline ? _self.timeline : timeline // ignore: cast_nullable_to_non_nullable
as List<CaseEvent>?,linkedReferenceNo: freezed == linkedReferenceNo ? _self.linkedReferenceNo : linkedReferenceNo // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}
/// Create a copy of ApplicationDetail
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ApplicationRowCopyWith<$Res> get row {
  
  return $ApplicationRowCopyWith<$Res>(_self.row, (value) {
    return _then(_self.copyWith(row: value));
  });
}
}


/// Adds pattern-matching-related methods to [ApplicationDetail].
extension ApplicationDetailPatterns on ApplicationDetail {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ApplicationDetail value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ApplicationDetail() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ApplicationDetail value)  $default,){
final _that = this;
switch (_that) {
case _ApplicationDetail():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ApplicationDetail value)?  $default,){
final _that = this;
switch (_that) {
case _ApplicationDetail() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( ApplicationRow row,  List<Attachment> attachments,  List<CaseEvent>? timeline,  String? linkedReferenceNo)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ApplicationDetail() when $default != null:
return $default(_that.row,_that.attachments,_that.timeline,_that.linkedReferenceNo);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( ApplicationRow row,  List<Attachment> attachments,  List<CaseEvent>? timeline,  String? linkedReferenceNo)  $default,) {final _that = this;
switch (_that) {
case _ApplicationDetail():
return $default(_that.row,_that.attachments,_that.timeline,_that.linkedReferenceNo);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( ApplicationRow row,  List<Attachment> attachments,  List<CaseEvent>? timeline,  String? linkedReferenceNo)?  $default,) {final _that = this;
switch (_that) {
case _ApplicationDetail() when $default != null:
return $default(_that.row,_that.attachments,_that.timeline,_that.linkedReferenceNo);case _:
  return null;

}
}

}

/// @nodoc


class _ApplicationDetail extends ApplicationDetail {
  const _ApplicationDetail({required this.row, final  List<Attachment> attachments = const <Attachment>[], final  List<CaseEvent>? timeline, this.linkedReferenceNo}): _attachments = attachments,_timeline = timeline,super._();
  

/// The 26 fields of `ApplicationRow`, parsed by the list's own parser.
@override final  ApplicationRow row;
/// `attachments: Attachment[]` — required in the source, so an absent key
/// is an empty list and not a null. The empty list is a **rendered state**
/// (`HistoryDetailPage.tsx:596-599`), which is the one part of the
/// attachments card B7b ships (see `attachment.dart`).
 final  List<Attachment> _attachments;
/// `attachments: Attachment[]` — required in the source, so an absent key
/// is an empty list and not a null. The empty list is a **rendered state**
/// (`HistoryDetailPage.tsx:596-599`), which is the one part of the
/// attachments card B7b ships (see `attachment.dart`).
@override@JsonKey() List<Attachment> get attachments {
  if (_attachments is EqualUnmodifiableListView) return _attachments;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_attachments);
}

/// `timeline?: CaseEvent[]` — **optional, and the optionality is load
/// bearing.** `:249` is
/// `timelineQuery.data?.events ?? detail.timeline ?? []`: a null here falls
/// through to the empty list, an empty list here does **not** fall through
/// to anything. `B7-AC-62` asserts all three arrangements, so this must
/// stay nullable rather than defaulting to `const []`.
 final  List<CaseEvent>? _timeline;
/// `timeline?: CaseEvent[]` — **optional, and the optionality is load
/// bearing.** `:249` is
/// `timelineQuery.data?.events ?? detail.timeline ?? []`: a null here falls
/// through to the empty list, an empty list here does **not** fall through
/// to anything. `B7-AC-62` asserts all three arrangements, so this must
/// stay nullable rather than defaulting to `const []`.
@override List<CaseEvent>? get timeline {
  final value = _timeline;
  if (value == null) return null;
  if (_timeline is EqualUnmodifiableListView) return _timeline;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(value);
}

@override final  String? linkedReferenceNo;

/// Create a copy of ApplicationDetail
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ApplicationDetailCopyWith<_ApplicationDetail> get copyWith => __$ApplicationDetailCopyWithImpl<_ApplicationDetail>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ApplicationDetail&&(identical(other.row, row) || other.row == row)&&const DeepCollectionEquality().equals(other._attachments, _attachments)&&const DeepCollectionEquality().equals(other._timeline, _timeline)&&(identical(other.linkedReferenceNo, linkedReferenceNo) || other.linkedReferenceNo == linkedReferenceNo));
}


@override
int get hashCode => Object.hash(runtimeType,row,const DeepCollectionEquality().hash(_attachments),const DeepCollectionEquality().hash(_timeline),linkedReferenceNo);

@override
String toString() {
  return 'ApplicationDetail(row: $row, attachments: $attachments, timeline: $timeline, linkedReferenceNo: $linkedReferenceNo)';
}


}

/// @nodoc
abstract mixin class _$ApplicationDetailCopyWith<$Res> implements $ApplicationDetailCopyWith<$Res> {
  factory _$ApplicationDetailCopyWith(_ApplicationDetail value, $Res Function(_ApplicationDetail) _then) = __$ApplicationDetailCopyWithImpl;
@override @useResult
$Res call({
 ApplicationRow row, List<Attachment> attachments, List<CaseEvent>? timeline, String? linkedReferenceNo
});


@override $ApplicationRowCopyWith<$Res> get row;

}
/// @nodoc
class __$ApplicationDetailCopyWithImpl<$Res>
    implements _$ApplicationDetailCopyWith<$Res> {
  __$ApplicationDetailCopyWithImpl(this._self, this._then);

  final _ApplicationDetail _self;
  final $Res Function(_ApplicationDetail) _then;

/// Create a copy of ApplicationDetail
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? row = null,Object? attachments = null,Object? timeline = freezed,Object? linkedReferenceNo = freezed,}) {
  return _then(_ApplicationDetail(
row: null == row ? _self.row : row // ignore: cast_nullable_to_non_nullable
as ApplicationRow,attachments: null == attachments ? _self._attachments : attachments // ignore: cast_nullable_to_non_nullable
as List<Attachment>,timeline: freezed == timeline ? _self._timeline : timeline // ignore: cast_nullable_to_non_nullable
as List<CaseEvent>?,linkedReferenceNo: freezed == linkedReferenceNo ? _self.linkedReferenceNo : linkedReferenceNo // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

/// Create a copy of ApplicationDetail
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ApplicationRowCopyWith<$Res> get row {
  
  return $ApplicationRowCopyWith<$Res>(_self.row, (value) {
    return _then(_self.copyWith(row: value));
  });
}
}

// dart format on
