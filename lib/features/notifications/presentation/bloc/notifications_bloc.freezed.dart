// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'notifications_bloc.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$NotificationsState {

/// The `isAuthenticated` prop — `Layout.tsx:98`. It gates both queries and
/// it is what makes the signed-out bell show its dot (`:172`).
 bool get isAuthenticated;/// `const [open, setOpen] = useState(false)` — `Layout.tsx:106`.
 bool get open;/// `counter.data?.unread ?? 0` — `Layout.tsx:122`.
///
/// The count has **no loading and no error surface**: the source reads only
/// `.data`, so a pending or failed count renders as the last number it saw
/// (0 before the first). That is why there is no `countStatus` here — a
/// status nothing can render would be state the tests could assert and the
/// citizen could never see.
 int get unreadCount;/// `inbox.data?.data ?? []` — `Layout.tsx:121`.
 List<CitizenNotification> get items; RegionStatus get listStatus;/// `hasData` — `hooks.ts:56`. True once a list request has **succeeded**,
/// and never false again.
///
/// It is not the same question as `items.isNotEmpty`: a successful fetch
/// that returns zero rows still counts, and it is what stops the second
/// open from flashing the spinner over rows the citizen can already see.
 bool get listLoaded;/// `refreshing` — `hooks.ts:67`. A refetch **with** data in hand. Nothing in
/// the source renders it (the menu reads only `loading` and `error`), so it
/// is carried to keep the two spinner cases distinguishable in a test
/// rather than to draw anything.
 bool get listRefreshing;
/// Create a copy of NotificationsState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$NotificationsStateCopyWith<NotificationsState> get copyWith => _$NotificationsStateCopyWithImpl<NotificationsState>(this as NotificationsState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is NotificationsState&&(identical(other.isAuthenticated, isAuthenticated) || other.isAuthenticated == isAuthenticated)&&(identical(other.open, open) || other.open == open)&&(identical(other.unreadCount, unreadCount) || other.unreadCount == unreadCount)&&const DeepCollectionEquality().equals(other.items, items)&&(identical(other.listStatus, listStatus) || other.listStatus == listStatus)&&(identical(other.listLoaded, listLoaded) || other.listLoaded == listLoaded)&&(identical(other.listRefreshing, listRefreshing) || other.listRefreshing == listRefreshing));
}


@override
int get hashCode => Object.hash(runtimeType,isAuthenticated,open,unreadCount,const DeepCollectionEquality().hash(items),listStatus,listLoaded,listRefreshing);

@override
String toString() {
  return 'NotificationsState(isAuthenticated: $isAuthenticated, open: $open, unreadCount: $unreadCount, items: $items, listStatus: $listStatus, listLoaded: $listLoaded, listRefreshing: $listRefreshing)';
}


}

/// @nodoc
abstract mixin class $NotificationsStateCopyWith<$Res>  {
  factory $NotificationsStateCopyWith(NotificationsState value, $Res Function(NotificationsState) _then) = _$NotificationsStateCopyWithImpl;
@useResult
$Res call({
 bool isAuthenticated, bool open, int unreadCount, List<CitizenNotification> items, RegionStatus listStatus, bool listLoaded, bool listRefreshing
});




}
/// @nodoc
class _$NotificationsStateCopyWithImpl<$Res>
    implements $NotificationsStateCopyWith<$Res> {
  _$NotificationsStateCopyWithImpl(this._self, this._then);

  final NotificationsState _self;
  final $Res Function(NotificationsState) _then;

/// Create a copy of NotificationsState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? isAuthenticated = null,Object? open = null,Object? unreadCount = null,Object? items = null,Object? listStatus = null,Object? listLoaded = null,Object? listRefreshing = null,}) {
  return _then(_self.copyWith(
isAuthenticated: null == isAuthenticated ? _self.isAuthenticated : isAuthenticated // ignore: cast_nullable_to_non_nullable
as bool,open: null == open ? _self.open : open // ignore: cast_nullable_to_non_nullable
as bool,unreadCount: null == unreadCount ? _self.unreadCount : unreadCount // ignore: cast_nullable_to_non_nullable
as int,items: null == items ? _self.items : items // ignore: cast_nullable_to_non_nullable
as List<CitizenNotification>,listStatus: null == listStatus ? _self.listStatus : listStatus // ignore: cast_nullable_to_non_nullable
as RegionStatus,listLoaded: null == listLoaded ? _self.listLoaded : listLoaded // ignore: cast_nullable_to_non_nullable
as bool,listRefreshing: null == listRefreshing ? _self.listRefreshing : listRefreshing // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [NotificationsState].
extension NotificationsStatePatterns on NotificationsState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _NotificationsState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _NotificationsState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _NotificationsState value)  $default,){
final _that = this;
switch (_that) {
case _NotificationsState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _NotificationsState value)?  $default,){
final _that = this;
switch (_that) {
case _NotificationsState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( bool isAuthenticated,  bool open,  int unreadCount,  List<CitizenNotification> items,  RegionStatus listStatus,  bool listLoaded,  bool listRefreshing)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _NotificationsState() when $default != null:
return $default(_that.isAuthenticated,_that.open,_that.unreadCount,_that.items,_that.listStatus,_that.listLoaded,_that.listRefreshing);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( bool isAuthenticated,  bool open,  int unreadCount,  List<CitizenNotification> items,  RegionStatus listStatus,  bool listLoaded,  bool listRefreshing)  $default,) {final _that = this;
switch (_that) {
case _NotificationsState():
return $default(_that.isAuthenticated,_that.open,_that.unreadCount,_that.items,_that.listStatus,_that.listLoaded,_that.listRefreshing);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( bool isAuthenticated,  bool open,  int unreadCount,  List<CitizenNotification> items,  RegionStatus listStatus,  bool listLoaded,  bool listRefreshing)?  $default,) {final _that = this;
switch (_that) {
case _NotificationsState() when $default != null:
return $default(_that.isAuthenticated,_that.open,_that.unreadCount,_that.items,_that.listStatus,_that.listLoaded,_that.listRefreshing);case _:
  return null;

}
}

}

/// @nodoc


class _NotificationsState extends NotificationsState {
  const _NotificationsState({this.isAuthenticated = false, this.open = false, this.unreadCount = 0, final  List<CitizenNotification> items = const <CitizenNotification>[], this.listStatus = RegionStatus.initial, this.listLoaded = false, this.listRefreshing = false}): _items = items,super._();
  

/// The `isAuthenticated` prop — `Layout.tsx:98`. It gates both queries and
/// it is what makes the signed-out bell show its dot (`:172`).
@override@JsonKey() final  bool isAuthenticated;
/// `const [open, setOpen] = useState(false)` — `Layout.tsx:106`.
@override@JsonKey() final  bool open;
/// `counter.data?.unread ?? 0` — `Layout.tsx:122`.
///
/// The count has **no loading and no error surface**: the source reads only
/// `.data`, so a pending or failed count renders as the last number it saw
/// (0 before the first). That is why there is no `countStatus` here — a
/// status nothing can render would be state the tests could assert and the
/// citizen could never see.
@override@JsonKey() final  int unreadCount;
/// `inbox.data?.data ?? []` — `Layout.tsx:121`.
 final  List<CitizenNotification> _items;
/// `inbox.data?.data ?? []` — `Layout.tsx:121`.
@override@JsonKey() List<CitizenNotification> get items {
  if (_items is EqualUnmodifiableListView) return _items;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_items);
}

@override@JsonKey() final  RegionStatus listStatus;
/// `hasData` — `hooks.ts:56`. True once a list request has **succeeded**,
/// and never false again.
///
/// It is not the same question as `items.isNotEmpty`: a successful fetch
/// that returns zero rows still counts, and it is what stops the second
/// open from flashing the spinner over rows the citizen can already see.
@override@JsonKey() final  bool listLoaded;
/// `refreshing` — `hooks.ts:67`. A refetch **with** data in hand. Nothing in
/// the source renders it (the menu reads only `loading` and `error`), so it
/// is carried to keep the two spinner cases distinguishable in a test
/// rather than to draw anything.
@override@JsonKey() final  bool listRefreshing;

/// Create a copy of NotificationsState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$NotificationsStateCopyWith<_NotificationsState> get copyWith => __$NotificationsStateCopyWithImpl<_NotificationsState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _NotificationsState&&(identical(other.isAuthenticated, isAuthenticated) || other.isAuthenticated == isAuthenticated)&&(identical(other.open, open) || other.open == open)&&(identical(other.unreadCount, unreadCount) || other.unreadCount == unreadCount)&&const DeepCollectionEquality().equals(other._items, _items)&&(identical(other.listStatus, listStatus) || other.listStatus == listStatus)&&(identical(other.listLoaded, listLoaded) || other.listLoaded == listLoaded)&&(identical(other.listRefreshing, listRefreshing) || other.listRefreshing == listRefreshing));
}


@override
int get hashCode => Object.hash(runtimeType,isAuthenticated,open,unreadCount,const DeepCollectionEquality().hash(_items),listStatus,listLoaded,listRefreshing);

@override
String toString() {
  return 'NotificationsState(isAuthenticated: $isAuthenticated, open: $open, unreadCount: $unreadCount, items: $items, listStatus: $listStatus, listLoaded: $listLoaded, listRefreshing: $listRefreshing)';
}


}

/// @nodoc
abstract mixin class _$NotificationsStateCopyWith<$Res> implements $NotificationsStateCopyWith<$Res> {
  factory _$NotificationsStateCopyWith(_NotificationsState value, $Res Function(_NotificationsState) _then) = __$NotificationsStateCopyWithImpl;
@override @useResult
$Res call({
 bool isAuthenticated, bool open, int unreadCount, List<CitizenNotification> items, RegionStatus listStatus, bool listLoaded, bool listRefreshing
});




}
/// @nodoc
class __$NotificationsStateCopyWithImpl<$Res>
    implements _$NotificationsStateCopyWith<$Res> {
  __$NotificationsStateCopyWithImpl(this._self, this._then);

  final _NotificationsState _self;
  final $Res Function(_NotificationsState) _then;

/// Create a copy of NotificationsState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? isAuthenticated = null,Object? open = null,Object? unreadCount = null,Object? items = null,Object? listStatus = null,Object? listLoaded = null,Object? listRefreshing = null,}) {
  return _then(_NotificationsState(
isAuthenticated: null == isAuthenticated ? _self.isAuthenticated : isAuthenticated // ignore: cast_nullable_to_non_nullable
as bool,open: null == open ? _self.open : open // ignore: cast_nullable_to_non_nullable
as bool,unreadCount: null == unreadCount ? _self.unreadCount : unreadCount // ignore: cast_nullable_to_non_nullable
as int,items: null == items ? _self._items : items // ignore: cast_nullable_to_non_nullable
as List<CitizenNotification>,listStatus: null == listStatus ? _self.listStatus : listStatus // ignore: cast_nullable_to_non_nullable
as RegionStatus,listLoaded: null == listLoaded ? _self.listLoaded : listLoaded // ignore: cast_nullable_to_non_nullable
as bool,listRefreshing: null == listRefreshing ? _self.listRefreshing : listRefreshing // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
