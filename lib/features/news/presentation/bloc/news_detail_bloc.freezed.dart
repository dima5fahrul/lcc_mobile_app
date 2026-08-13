// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'news_detail_bloc.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$NewsDetailState {

/// The route parameter this state is about. Held so a widget test can
/// assert the page asked for what the router gave it.
 String get slug;// ── The article ──────────────────────────────────────────────────────────
 RegionStatus get status; NewsArticle? get article;/// True when the failure was a 404 — the **empty** branch
/// (`NewsDetailPage.tsx:141`), not the error one.
 bool get notFound;// ── "More news" ──────────────────────────────────────────────────────────
 RegionStatus get moreStatus; List<NewsArticle> get more;
/// Create a copy of NewsDetailState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$NewsDetailStateCopyWith<NewsDetailState> get copyWith => _$NewsDetailStateCopyWithImpl<NewsDetailState>(this as NewsDetailState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is NewsDetailState&&(identical(other.slug, slug) || other.slug == slug)&&(identical(other.status, status) || other.status == status)&&(identical(other.article, article) || other.article == article)&&(identical(other.notFound, notFound) || other.notFound == notFound)&&(identical(other.moreStatus, moreStatus) || other.moreStatus == moreStatus)&&const DeepCollectionEquality().equals(other.more, more));
}


@override
int get hashCode => Object.hash(runtimeType,slug,status,article,notFound,moreStatus,const DeepCollectionEquality().hash(more));

@override
String toString() {
  return 'NewsDetailState(slug: $slug, status: $status, article: $article, notFound: $notFound, moreStatus: $moreStatus, more: $more)';
}


}

/// @nodoc
abstract mixin class $NewsDetailStateCopyWith<$Res>  {
  factory $NewsDetailStateCopyWith(NewsDetailState value, $Res Function(NewsDetailState) _then) = _$NewsDetailStateCopyWithImpl;
@useResult
$Res call({
 String slug, RegionStatus status, NewsArticle? article, bool notFound, RegionStatus moreStatus, List<NewsArticle> more
});


$NewsArticleCopyWith<$Res>? get article;

}
/// @nodoc
class _$NewsDetailStateCopyWithImpl<$Res>
    implements $NewsDetailStateCopyWith<$Res> {
  _$NewsDetailStateCopyWithImpl(this._self, this._then);

  final NewsDetailState _self;
  final $Res Function(NewsDetailState) _then;

/// Create a copy of NewsDetailState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? slug = null,Object? status = null,Object? article = freezed,Object? notFound = null,Object? moreStatus = null,Object? more = null,}) {
  return _then(_self.copyWith(
slug: null == slug ? _self.slug : slug // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as RegionStatus,article: freezed == article ? _self.article : article // ignore: cast_nullable_to_non_nullable
as NewsArticle?,notFound: null == notFound ? _self.notFound : notFound // ignore: cast_nullable_to_non_nullable
as bool,moreStatus: null == moreStatus ? _self.moreStatus : moreStatus // ignore: cast_nullable_to_non_nullable
as RegionStatus,more: null == more ? _self.more : more // ignore: cast_nullable_to_non_nullable
as List<NewsArticle>,
  ));
}
/// Create a copy of NewsDetailState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$NewsArticleCopyWith<$Res>? get article {
    if (_self.article == null) {
    return null;
  }

  return $NewsArticleCopyWith<$Res>(_self.article!, (value) {
    return _then(_self.copyWith(article: value));
  });
}
}


/// Adds pattern-matching-related methods to [NewsDetailState].
extension NewsDetailStatePatterns on NewsDetailState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _NewsDetailState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _NewsDetailState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _NewsDetailState value)  $default,){
final _that = this;
switch (_that) {
case _NewsDetailState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _NewsDetailState value)?  $default,){
final _that = this;
switch (_that) {
case _NewsDetailState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String slug,  RegionStatus status,  NewsArticle? article,  bool notFound,  RegionStatus moreStatus,  List<NewsArticle> more)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _NewsDetailState() when $default != null:
return $default(_that.slug,_that.status,_that.article,_that.notFound,_that.moreStatus,_that.more);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String slug,  RegionStatus status,  NewsArticle? article,  bool notFound,  RegionStatus moreStatus,  List<NewsArticle> more)  $default,) {final _that = this;
switch (_that) {
case _NewsDetailState():
return $default(_that.slug,_that.status,_that.article,_that.notFound,_that.moreStatus,_that.more);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String slug,  RegionStatus status,  NewsArticle? article,  bool notFound,  RegionStatus moreStatus,  List<NewsArticle> more)?  $default,) {final _that = this;
switch (_that) {
case _NewsDetailState() when $default != null:
return $default(_that.slug,_that.status,_that.article,_that.notFound,_that.moreStatus,_that.more);case _:
  return null;

}
}

}

/// @nodoc


class _NewsDetailState extends NewsDetailState {
  const _NewsDetailState({this.slug = '', this.status = RegionStatus.initial, this.article, this.notFound = false, this.moreStatus = RegionStatus.initial, final  List<NewsArticle> more = const <NewsArticle>[]}): _more = more,super._();
  

/// The route parameter this state is about. Held so a widget test can
/// assert the page asked for what the router gave it.
@override@JsonKey() final  String slug;
// ── The article ──────────────────────────────────────────────────────────
@override@JsonKey() final  RegionStatus status;
@override final  NewsArticle? article;
/// True when the failure was a 404 — the **empty** branch
/// (`NewsDetailPage.tsx:141`), not the error one.
@override@JsonKey() final  bool notFound;
// ── "More news" ──────────────────────────────────────────────────────────
@override@JsonKey() final  RegionStatus moreStatus;
 final  List<NewsArticle> _more;
@override@JsonKey() List<NewsArticle> get more {
  if (_more is EqualUnmodifiableListView) return _more;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_more);
}


/// Create a copy of NewsDetailState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$NewsDetailStateCopyWith<_NewsDetailState> get copyWith => __$NewsDetailStateCopyWithImpl<_NewsDetailState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _NewsDetailState&&(identical(other.slug, slug) || other.slug == slug)&&(identical(other.status, status) || other.status == status)&&(identical(other.article, article) || other.article == article)&&(identical(other.notFound, notFound) || other.notFound == notFound)&&(identical(other.moreStatus, moreStatus) || other.moreStatus == moreStatus)&&const DeepCollectionEquality().equals(other._more, _more));
}


@override
int get hashCode => Object.hash(runtimeType,slug,status,article,notFound,moreStatus,const DeepCollectionEquality().hash(_more));

@override
String toString() {
  return 'NewsDetailState(slug: $slug, status: $status, article: $article, notFound: $notFound, moreStatus: $moreStatus, more: $more)';
}


}

/// @nodoc
abstract mixin class _$NewsDetailStateCopyWith<$Res> implements $NewsDetailStateCopyWith<$Res> {
  factory _$NewsDetailStateCopyWith(_NewsDetailState value, $Res Function(_NewsDetailState) _then) = __$NewsDetailStateCopyWithImpl;
@override @useResult
$Res call({
 String slug, RegionStatus status, NewsArticle? article, bool notFound, RegionStatus moreStatus, List<NewsArticle> more
});


@override $NewsArticleCopyWith<$Res>? get article;

}
/// @nodoc
class __$NewsDetailStateCopyWithImpl<$Res>
    implements _$NewsDetailStateCopyWith<$Res> {
  __$NewsDetailStateCopyWithImpl(this._self, this._then);

  final _NewsDetailState _self;
  final $Res Function(_NewsDetailState) _then;

/// Create a copy of NewsDetailState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? slug = null,Object? status = null,Object? article = freezed,Object? notFound = null,Object? moreStatus = null,Object? more = null,}) {
  return _then(_NewsDetailState(
slug: null == slug ? _self.slug : slug // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as RegionStatus,article: freezed == article ? _self.article : article // ignore: cast_nullable_to_non_nullable
as NewsArticle?,notFound: null == notFound ? _self.notFound : notFound // ignore: cast_nullable_to_non_nullable
as bool,moreStatus: null == moreStatus ? _self.moreStatus : moreStatus // ignore: cast_nullable_to_non_nullable
as RegionStatus,more: null == more ? _self._more : more // ignore: cast_nullable_to_non_nullable
as List<NewsArticle>,
  ));
}

/// Create a copy of NewsDetailState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$NewsArticleCopyWith<$Res>? get article {
    if (_self.article == null) {
    return null;
  }

  return $NewsArticleCopyWith<$Res>(_self.article!, (value) {
    return _then(_self.copyWith(article: value));
  });
}
}

// dart format on
