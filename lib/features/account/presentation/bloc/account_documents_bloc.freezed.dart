// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'account_documents_bloc.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$AccountDocumentsState {

 RegionStatus get status;/// `docsQuery.data ?? []` — `AccountPage.tsx:295`.
 List<CitizenDocument> get items;/// `docsQuery.error.message` — rendered **in preference to** the local
/// `c("docsError")` string (`:409`: `docsQuery.error.message ||
/// c("docsError")`). The API's message wins; the local one is the fallback
/// for an error with no message, not the other way round.
 String? get errorMessage;
/// Create a copy of AccountDocumentsState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AccountDocumentsStateCopyWith<AccountDocumentsState> get copyWith => _$AccountDocumentsStateCopyWithImpl<AccountDocumentsState>(this as AccountDocumentsState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AccountDocumentsState&&(identical(other.status, status) || other.status == status)&&const DeepCollectionEquality().equals(other.items, items)&&(identical(other.errorMessage, errorMessage) || other.errorMessage == errorMessage));
}


@override
int get hashCode => Object.hash(runtimeType,status,const DeepCollectionEquality().hash(items),errorMessage);

@override
String toString() {
  return 'AccountDocumentsState(status: $status, items: $items, errorMessage: $errorMessage)';
}


}

/// @nodoc
abstract mixin class $AccountDocumentsStateCopyWith<$Res>  {
  factory $AccountDocumentsStateCopyWith(AccountDocumentsState value, $Res Function(AccountDocumentsState) _then) = _$AccountDocumentsStateCopyWithImpl;
@useResult
$Res call({
 RegionStatus status, List<CitizenDocument> items, String? errorMessage
});




}
/// @nodoc
class _$AccountDocumentsStateCopyWithImpl<$Res>
    implements $AccountDocumentsStateCopyWith<$Res> {
  _$AccountDocumentsStateCopyWithImpl(this._self, this._then);

  final AccountDocumentsState _self;
  final $Res Function(AccountDocumentsState) _then;

/// Create a copy of AccountDocumentsState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? status = null,Object? items = null,Object? errorMessage = freezed,}) {
  return _then(_self.copyWith(
status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as RegionStatus,items: null == items ? _self.items : items // ignore: cast_nullable_to_non_nullable
as List<CitizenDocument>,errorMessage: freezed == errorMessage ? _self.errorMessage : errorMessage // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [AccountDocumentsState].
extension AccountDocumentsStatePatterns on AccountDocumentsState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AccountDocumentsState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AccountDocumentsState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AccountDocumentsState value)  $default,){
final _that = this;
switch (_that) {
case _AccountDocumentsState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AccountDocumentsState value)?  $default,){
final _that = this;
switch (_that) {
case _AccountDocumentsState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( RegionStatus status,  List<CitizenDocument> items,  String? errorMessage)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AccountDocumentsState() when $default != null:
return $default(_that.status,_that.items,_that.errorMessage);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( RegionStatus status,  List<CitizenDocument> items,  String? errorMessage)  $default,) {final _that = this;
switch (_that) {
case _AccountDocumentsState():
return $default(_that.status,_that.items,_that.errorMessage);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( RegionStatus status,  List<CitizenDocument> items,  String? errorMessage)?  $default,) {final _that = this;
switch (_that) {
case _AccountDocumentsState() when $default != null:
return $default(_that.status,_that.items,_that.errorMessage);case _:
  return null;

}
}

}

/// @nodoc


class _AccountDocumentsState extends AccountDocumentsState {
  const _AccountDocumentsState({this.status = RegionStatus.initial, final  List<CitizenDocument> items = const <CitizenDocument>[], this.errorMessage}): _items = items,super._();
  

@override@JsonKey() final  RegionStatus status;
/// `docsQuery.data ?? []` — `AccountPage.tsx:295`.
 final  List<CitizenDocument> _items;
/// `docsQuery.data ?? []` — `AccountPage.tsx:295`.
@override@JsonKey() List<CitizenDocument> get items {
  if (_items is EqualUnmodifiableListView) return _items;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_items);
}

/// `docsQuery.error.message` — rendered **in preference to** the local
/// `c("docsError")` string (`:409`: `docsQuery.error.message ||
/// c("docsError")`). The API's message wins; the local one is the fallback
/// for an error with no message, not the other way round.
@override final  String? errorMessage;

/// Create a copy of AccountDocumentsState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AccountDocumentsStateCopyWith<_AccountDocumentsState> get copyWith => __$AccountDocumentsStateCopyWithImpl<_AccountDocumentsState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AccountDocumentsState&&(identical(other.status, status) || other.status == status)&&const DeepCollectionEquality().equals(other._items, _items)&&(identical(other.errorMessage, errorMessage) || other.errorMessage == errorMessage));
}


@override
int get hashCode => Object.hash(runtimeType,status,const DeepCollectionEquality().hash(_items),errorMessage);

@override
String toString() {
  return 'AccountDocumentsState(status: $status, items: $items, errorMessage: $errorMessage)';
}


}

/// @nodoc
abstract mixin class _$AccountDocumentsStateCopyWith<$Res> implements $AccountDocumentsStateCopyWith<$Res> {
  factory _$AccountDocumentsStateCopyWith(_AccountDocumentsState value, $Res Function(_AccountDocumentsState) _then) = __$AccountDocumentsStateCopyWithImpl;
@override @useResult
$Res call({
 RegionStatus status, List<CitizenDocument> items, String? errorMessage
});




}
/// @nodoc
class __$AccountDocumentsStateCopyWithImpl<$Res>
    implements _$AccountDocumentsStateCopyWith<$Res> {
  __$AccountDocumentsStateCopyWithImpl(this._self, this._then);

  final _AccountDocumentsState _self;
  final $Res Function(_AccountDocumentsState) _then;

/// Create a copy of AccountDocumentsState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? status = null,Object? items = null,Object? errorMessage = freezed,}) {
  return _then(_AccountDocumentsState(
status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as RegionStatus,items: null == items ? _self._items : items // ignore: cast_nullable_to_non_nullable
as List<CitizenDocument>,errorMessage: freezed == errorMessage ? _self.errorMessage : errorMessage // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
