// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'news_bloc.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$NewsState {

// ── Category chips ───────────────────────────────────────────────────────
 RegionStatus get categoriesStatus; List<NewsCategory> get categories;// ── The list ─────────────────────────────────────────────────────────────
 RegionStatus get listStatus; NewsPageResult get result;/// The selected chip — a `NewsCategory.code`, or [kNewsAllCategories].
 String get filter;/// The requested page. Moves on tap, ahead of the response, so the pager
/// and the chips do not lag their own controls.
 int get page;
/// Create a copy of NewsState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$NewsStateCopyWith<NewsState> get copyWith => _$NewsStateCopyWithImpl<NewsState>(this as NewsState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is NewsState&&(identical(other.categoriesStatus, categoriesStatus) || other.categoriesStatus == categoriesStatus)&&const DeepCollectionEquality().equals(other.categories, categories)&&(identical(other.listStatus, listStatus) || other.listStatus == listStatus)&&(identical(other.result, result) || other.result == result)&&(identical(other.filter, filter) || other.filter == filter)&&(identical(other.page, page) || other.page == page));
}


@override
int get hashCode => Object.hash(runtimeType,categoriesStatus,const DeepCollectionEquality().hash(categories),listStatus,result,filter,page);

@override
String toString() {
  return 'NewsState(categoriesStatus: $categoriesStatus, categories: $categories, listStatus: $listStatus, result: $result, filter: $filter, page: $page)';
}


}

/// @nodoc
abstract mixin class $NewsStateCopyWith<$Res>  {
  factory $NewsStateCopyWith(NewsState value, $Res Function(NewsState) _then) = _$NewsStateCopyWithImpl;
@useResult
$Res call({
 RegionStatus categoriesStatus, List<NewsCategory> categories, RegionStatus listStatus, NewsPageResult result, String filter, int page
});




}
/// @nodoc
class _$NewsStateCopyWithImpl<$Res>
    implements $NewsStateCopyWith<$Res> {
  _$NewsStateCopyWithImpl(this._self, this._then);

  final NewsState _self;
  final $Res Function(NewsState) _then;

/// Create a copy of NewsState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? categoriesStatus = null,Object? categories = null,Object? listStatus = null,Object? result = null,Object? filter = null,Object? page = null,}) {
  return _then(_self.copyWith(
categoriesStatus: null == categoriesStatus ? _self.categoriesStatus : categoriesStatus // ignore: cast_nullable_to_non_nullable
as RegionStatus,categories: null == categories ? _self.categories : categories // ignore: cast_nullable_to_non_nullable
as List<NewsCategory>,listStatus: null == listStatus ? _self.listStatus : listStatus // ignore: cast_nullable_to_non_nullable
as RegionStatus,result: null == result ? _self.result : result // ignore: cast_nullable_to_non_nullable
as NewsPageResult,filter: null == filter ? _self.filter : filter // ignore: cast_nullable_to_non_nullable
as String,page: null == page ? _self.page : page // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [NewsState].
extension NewsStatePatterns on NewsState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _NewsState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _NewsState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _NewsState value)  $default,){
final _that = this;
switch (_that) {
case _NewsState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _NewsState value)?  $default,){
final _that = this;
switch (_that) {
case _NewsState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( RegionStatus categoriesStatus,  List<NewsCategory> categories,  RegionStatus listStatus,  NewsPageResult result,  String filter,  int page)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _NewsState() when $default != null:
return $default(_that.categoriesStatus,_that.categories,_that.listStatus,_that.result,_that.filter,_that.page);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( RegionStatus categoriesStatus,  List<NewsCategory> categories,  RegionStatus listStatus,  NewsPageResult result,  String filter,  int page)  $default,) {final _that = this;
switch (_that) {
case _NewsState():
return $default(_that.categoriesStatus,_that.categories,_that.listStatus,_that.result,_that.filter,_that.page);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( RegionStatus categoriesStatus,  List<NewsCategory> categories,  RegionStatus listStatus,  NewsPageResult result,  String filter,  int page)?  $default,) {final _that = this;
switch (_that) {
case _NewsState() when $default != null:
return $default(_that.categoriesStatus,_that.categories,_that.listStatus,_that.result,_that.filter,_that.page);case _:
  return null;

}
}

}

/// @nodoc


class _NewsState extends NewsState {
  const _NewsState({this.categoriesStatus = RegionStatus.initial, final  List<NewsCategory> categories = const <NewsCategory>[], this.listStatus = RegionStatus.initial, this.result = NewsPageResult.empty, this.filter = kNewsAllCategories, this.page = 1}): _categories = categories,super._();
  

// ── Category chips ───────────────────────────────────────────────────────
@override@JsonKey() final  RegionStatus categoriesStatus;
 final  List<NewsCategory> _categories;
@override@JsonKey() List<NewsCategory> get categories {
  if (_categories is EqualUnmodifiableListView) return _categories;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_categories);
}

// ── The list ─────────────────────────────────────────────────────────────
@override@JsonKey() final  RegionStatus listStatus;
@override@JsonKey() final  NewsPageResult result;
/// The selected chip — a `NewsCategory.code`, or [kNewsAllCategories].
@override@JsonKey() final  String filter;
/// The requested page. Moves on tap, ahead of the response, so the pager
/// and the chips do not lag their own controls.
@override@JsonKey() final  int page;

/// Create a copy of NewsState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$NewsStateCopyWith<_NewsState> get copyWith => __$NewsStateCopyWithImpl<_NewsState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _NewsState&&(identical(other.categoriesStatus, categoriesStatus) || other.categoriesStatus == categoriesStatus)&&const DeepCollectionEquality().equals(other._categories, _categories)&&(identical(other.listStatus, listStatus) || other.listStatus == listStatus)&&(identical(other.result, result) || other.result == result)&&(identical(other.filter, filter) || other.filter == filter)&&(identical(other.page, page) || other.page == page));
}


@override
int get hashCode => Object.hash(runtimeType,categoriesStatus,const DeepCollectionEquality().hash(_categories),listStatus,result,filter,page);

@override
String toString() {
  return 'NewsState(categoriesStatus: $categoriesStatus, categories: $categories, listStatus: $listStatus, result: $result, filter: $filter, page: $page)';
}


}

/// @nodoc
abstract mixin class _$NewsStateCopyWith<$Res> implements $NewsStateCopyWith<$Res> {
  factory _$NewsStateCopyWith(_NewsState value, $Res Function(_NewsState) _then) = __$NewsStateCopyWithImpl;
@override @useResult
$Res call({
 RegionStatus categoriesStatus, List<NewsCategory> categories, RegionStatus listStatus, NewsPageResult result, String filter, int page
});




}
/// @nodoc
class __$NewsStateCopyWithImpl<$Res>
    implements _$NewsStateCopyWith<$Res> {
  __$NewsStateCopyWithImpl(this._self, this._then);

  final _NewsState _self;
  final $Res Function(_NewsState) _then;

/// Create a copy of NewsState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? categoriesStatus = null,Object? categories = null,Object? listStatus = null,Object? result = null,Object? filter = null,Object? page = null,}) {
  return _then(_NewsState(
categoriesStatus: null == categoriesStatus ? _self.categoriesStatus : categoriesStatus // ignore: cast_nullable_to_non_nullable
as RegionStatus,categories: null == categories ? _self._categories : categories // ignore: cast_nullable_to_non_nullable
as List<NewsCategory>,listStatus: null == listStatus ? _self.listStatus : listStatus // ignore: cast_nullable_to_non_nullable
as RegionStatus,result: null == result ? _self.result : result // ignore: cast_nullable_to_non_nullable
as NewsPageResult,filter: null == filter ? _self.filter : filter // ignore: cast_nullable_to_non_nullable
as String,page: null == page ? _self.page : page // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on
