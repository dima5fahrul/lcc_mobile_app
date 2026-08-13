// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'news_article.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$NewsArticle {

 String get id;/// The API's key for an article, and the Flutter route parameter:
/// `/news/:slug`. See `news_repository.dart` for why the port does **not**
/// carry the web's numeric `#/news/3` position bridge.
 String get slug;/// The category *code* (`announcement`, `service`, …) — used by
/// `NewsDetailPage.tsx:167`'s `article.category === "service"` related-tab
/// fallback, which is a code comparison and not a label one.
 String get category; Bilingual get categoryName;/// `#RRGGBB`, or empty. Data, not a token — see [NewsCategory.color].
 String get categoryColor; Bilingual get title; Bilingual get excerpt;/// **Null when the row came from a list endpoint** — see the library doc.
 Bilingual? get body;/// A remote hero/thumbnail URL, or empty. The card and the hero both draw
/// the category gradient underneath either way (`NewsPage.tsx:161-173`,
/// `NewsDetailPage.tsx:189-202`), so an absent cover is a styled surface
/// rather than a hole.
 String get coverUrl; String get author; String get source;/// `NewsDetailPage.tsx:166` looks for a tag that names an app tab.
 List<String> get tags; bool get featured; bool get pinned;/// Both are rendered only when `> 0` (`NewsDetailPage.tsx:211,217`).
 int get viewCount; int get readMinutes; String get publishedDate; String get publishedAt;
/// Create a copy of NewsArticle
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$NewsArticleCopyWith<NewsArticle> get copyWith => _$NewsArticleCopyWithImpl<NewsArticle>(this as NewsArticle, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is NewsArticle&&(identical(other.id, id) || other.id == id)&&(identical(other.slug, slug) || other.slug == slug)&&(identical(other.category, category) || other.category == category)&&(identical(other.categoryName, categoryName) || other.categoryName == categoryName)&&(identical(other.categoryColor, categoryColor) || other.categoryColor == categoryColor)&&(identical(other.title, title) || other.title == title)&&(identical(other.excerpt, excerpt) || other.excerpt == excerpt)&&(identical(other.body, body) || other.body == body)&&(identical(other.coverUrl, coverUrl) || other.coverUrl == coverUrl)&&(identical(other.author, author) || other.author == author)&&(identical(other.source, source) || other.source == source)&&const DeepCollectionEquality().equals(other.tags, tags)&&(identical(other.featured, featured) || other.featured == featured)&&(identical(other.pinned, pinned) || other.pinned == pinned)&&(identical(other.viewCount, viewCount) || other.viewCount == viewCount)&&(identical(other.readMinutes, readMinutes) || other.readMinutes == readMinutes)&&(identical(other.publishedDate, publishedDate) || other.publishedDate == publishedDate)&&(identical(other.publishedAt, publishedAt) || other.publishedAt == publishedAt));
}


@override
int get hashCode => Object.hash(runtimeType,id,slug,category,categoryName,categoryColor,title,excerpt,body,coverUrl,author,source,const DeepCollectionEquality().hash(tags),featured,pinned,viewCount,readMinutes,publishedDate,publishedAt);

@override
String toString() {
  return 'NewsArticle(id: $id, slug: $slug, category: $category, categoryName: $categoryName, categoryColor: $categoryColor, title: $title, excerpt: $excerpt, body: $body, coverUrl: $coverUrl, author: $author, source: $source, tags: $tags, featured: $featured, pinned: $pinned, viewCount: $viewCount, readMinutes: $readMinutes, publishedDate: $publishedDate, publishedAt: $publishedAt)';
}


}

/// @nodoc
abstract mixin class $NewsArticleCopyWith<$Res>  {
  factory $NewsArticleCopyWith(NewsArticle value, $Res Function(NewsArticle) _then) = _$NewsArticleCopyWithImpl;
@useResult
$Res call({
 String id, String slug, String category, Bilingual categoryName, String categoryColor, Bilingual title, Bilingual excerpt, Bilingual? body, String coverUrl, String author, String source, List<String> tags, bool featured, bool pinned, int viewCount, int readMinutes, String publishedDate, String publishedAt
});


$BilingualCopyWith<$Res> get categoryName;$BilingualCopyWith<$Res> get title;$BilingualCopyWith<$Res> get excerpt;$BilingualCopyWith<$Res>? get body;

}
/// @nodoc
class _$NewsArticleCopyWithImpl<$Res>
    implements $NewsArticleCopyWith<$Res> {
  _$NewsArticleCopyWithImpl(this._self, this._then);

  final NewsArticle _self;
  final $Res Function(NewsArticle) _then;

/// Create a copy of NewsArticle
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? slug = null,Object? category = null,Object? categoryName = null,Object? categoryColor = null,Object? title = null,Object? excerpt = null,Object? body = freezed,Object? coverUrl = null,Object? author = null,Object? source = null,Object? tags = null,Object? featured = null,Object? pinned = null,Object? viewCount = null,Object? readMinutes = null,Object? publishedDate = null,Object? publishedAt = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,slug: null == slug ? _self.slug : slug // ignore: cast_nullable_to_non_nullable
as String,category: null == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as String,categoryName: null == categoryName ? _self.categoryName : categoryName // ignore: cast_nullable_to_non_nullable
as Bilingual,categoryColor: null == categoryColor ? _self.categoryColor : categoryColor // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as Bilingual,excerpt: null == excerpt ? _self.excerpt : excerpt // ignore: cast_nullable_to_non_nullable
as Bilingual,body: freezed == body ? _self.body : body // ignore: cast_nullable_to_non_nullable
as Bilingual?,coverUrl: null == coverUrl ? _self.coverUrl : coverUrl // ignore: cast_nullable_to_non_nullable
as String,author: null == author ? _self.author : author // ignore: cast_nullable_to_non_nullable
as String,source: null == source ? _self.source : source // ignore: cast_nullable_to_non_nullable
as String,tags: null == tags ? _self.tags : tags // ignore: cast_nullable_to_non_nullable
as List<String>,featured: null == featured ? _self.featured : featured // ignore: cast_nullable_to_non_nullable
as bool,pinned: null == pinned ? _self.pinned : pinned // ignore: cast_nullable_to_non_nullable
as bool,viewCount: null == viewCount ? _self.viewCount : viewCount // ignore: cast_nullable_to_non_nullable
as int,readMinutes: null == readMinutes ? _self.readMinutes : readMinutes // ignore: cast_nullable_to_non_nullable
as int,publishedDate: null == publishedDate ? _self.publishedDate : publishedDate // ignore: cast_nullable_to_non_nullable
as String,publishedAt: null == publishedAt ? _self.publishedAt : publishedAt // ignore: cast_nullable_to_non_nullable
as String,
  ));
}
/// Create a copy of NewsArticle
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BilingualCopyWith<$Res> get categoryName {
  
  return $BilingualCopyWith<$Res>(_self.categoryName, (value) {
    return _then(_self.copyWith(categoryName: value));
  });
}/// Create a copy of NewsArticle
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BilingualCopyWith<$Res> get title {
  
  return $BilingualCopyWith<$Res>(_self.title, (value) {
    return _then(_self.copyWith(title: value));
  });
}/// Create a copy of NewsArticle
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BilingualCopyWith<$Res> get excerpt {
  
  return $BilingualCopyWith<$Res>(_self.excerpt, (value) {
    return _then(_self.copyWith(excerpt: value));
  });
}/// Create a copy of NewsArticle
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BilingualCopyWith<$Res>? get body {
    if (_self.body == null) {
    return null;
  }

  return $BilingualCopyWith<$Res>(_self.body!, (value) {
    return _then(_self.copyWith(body: value));
  });
}
}


/// Adds pattern-matching-related methods to [NewsArticle].
extension NewsArticlePatterns on NewsArticle {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _NewsArticle value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _NewsArticle() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _NewsArticle value)  $default,){
final _that = this;
switch (_that) {
case _NewsArticle():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _NewsArticle value)?  $default,){
final _that = this;
switch (_that) {
case _NewsArticle() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String slug,  String category,  Bilingual categoryName,  String categoryColor,  Bilingual title,  Bilingual excerpt,  Bilingual? body,  String coverUrl,  String author,  String source,  List<String> tags,  bool featured,  bool pinned,  int viewCount,  int readMinutes,  String publishedDate,  String publishedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _NewsArticle() when $default != null:
return $default(_that.id,_that.slug,_that.category,_that.categoryName,_that.categoryColor,_that.title,_that.excerpt,_that.body,_that.coverUrl,_that.author,_that.source,_that.tags,_that.featured,_that.pinned,_that.viewCount,_that.readMinutes,_that.publishedDate,_that.publishedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String slug,  String category,  Bilingual categoryName,  String categoryColor,  Bilingual title,  Bilingual excerpt,  Bilingual? body,  String coverUrl,  String author,  String source,  List<String> tags,  bool featured,  bool pinned,  int viewCount,  int readMinutes,  String publishedDate,  String publishedAt)  $default,) {final _that = this;
switch (_that) {
case _NewsArticle():
return $default(_that.id,_that.slug,_that.category,_that.categoryName,_that.categoryColor,_that.title,_that.excerpt,_that.body,_that.coverUrl,_that.author,_that.source,_that.tags,_that.featured,_that.pinned,_that.viewCount,_that.readMinutes,_that.publishedDate,_that.publishedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String slug,  String category,  Bilingual categoryName,  String categoryColor,  Bilingual title,  Bilingual excerpt,  Bilingual? body,  String coverUrl,  String author,  String source,  List<String> tags,  bool featured,  bool pinned,  int viewCount,  int readMinutes,  String publishedDate,  String publishedAt)?  $default,) {final _that = this;
switch (_that) {
case _NewsArticle() when $default != null:
return $default(_that.id,_that.slug,_that.category,_that.categoryName,_that.categoryColor,_that.title,_that.excerpt,_that.body,_that.coverUrl,_that.author,_that.source,_that.tags,_that.featured,_that.pinned,_that.viewCount,_that.readMinutes,_that.publishedDate,_that.publishedAt);case _:
  return null;

}
}

}

/// @nodoc


class _NewsArticle extends NewsArticle {
  const _NewsArticle({this.id = '', this.slug = '', this.category = '', this.categoryName = const Bilingual(en: '', lo: ''), this.categoryColor = '', this.title = const Bilingual(en: '', lo: ''), this.excerpt = const Bilingual(en: '', lo: ''), this.body, this.coverUrl = '', this.author = '', this.source = '', final  List<String> tags = const <String>[], this.featured = false, this.pinned = false, this.viewCount = 0, this.readMinutes = 0, this.publishedDate = '', this.publishedAt = ''}): _tags = tags,super._();
  

@override@JsonKey() final  String id;
/// The API's key for an article, and the Flutter route parameter:
/// `/news/:slug`. See `news_repository.dart` for why the port does **not**
/// carry the web's numeric `#/news/3` position bridge.
@override@JsonKey() final  String slug;
/// The category *code* (`announcement`, `service`, …) — used by
/// `NewsDetailPage.tsx:167`'s `article.category === "service"` related-tab
/// fallback, which is a code comparison and not a label one.
@override@JsonKey() final  String category;
@override@JsonKey() final  Bilingual categoryName;
/// `#RRGGBB`, or empty. Data, not a token — see [NewsCategory.color].
@override@JsonKey() final  String categoryColor;
@override@JsonKey() final  Bilingual title;
@override@JsonKey() final  Bilingual excerpt;
/// **Null when the row came from a list endpoint** — see the library doc.
@override final  Bilingual? body;
/// A remote hero/thumbnail URL, or empty. The card and the hero both draw
/// the category gradient underneath either way (`NewsPage.tsx:161-173`,
/// `NewsDetailPage.tsx:189-202`), so an absent cover is a styled surface
/// rather than a hole.
@override@JsonKey() final  String coverUrl;
@override@JsonKey() final  String author;
@override@JsonKey() final  String source;
/// `NewsDetailPage.tsx:166` looks for a tag that names an app tab.
 final  List<String> _tags;
/// `NewsDetailPage.tsx:166` looks for a tag that names an app tab.
@override@JsonKey() List<String> get tags {
  if (_tags is EqualUnmodifiableListView) return _tags;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_tags);
}

@override@JsonKey() final  bool featured;
@override@JsonKey() final  bool pinned;
/// Both are rendered only when `> 0` (`NewsDetailPage.tsx:211,217`).
@override@JsonKey() final  int viewCount;
@override@JsonKey() final  int readMinutes;
@override@JsonKey() final  String publishedDate;
@override@JsonKey() final  String publishedAt;

/// Create a copy of NewsArticle
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$NewsArticleCopyWith<_NewsArticle> get copyWith => __$NewsArticleCopyWithImpl<_NewsArticle>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _NewsArticle&&(identical(other.id, id) || other.id == id)&&(identical(other.slug, slug) || other.slug == slug)&&(identical(other.category, category) || other.category == category)&&(identical(other.categoryName, categoryName) || other.categoryName == categoryName)&&(identical(other.categoryColor, categoryColor) || other.categoryColor == categoryColor)&&(identical(other.title, title) || other.title == title)&&(identical(other.excerpt, excerpt) || other.excerpt == excerpt)&&(identical(other.body, body) || other.body == body)&&(identical(other.coverUrl, coverUrl) || other.coverUrl == coverUrl)&&(identical(other.author, author) || other.author == author)&&(identical(other.source, source) || other.source == source)&&const DeepCollectionEquality().equals(other._tags, _tags)&&(identical(other.featured, featured) || other.featured == featured)&&(identical(other.pinned, pinned) || other.pinned == pinned)&&(identical(other.viewCount, viewCount) || other.viewCount == viewCount)&&(identical(other.readMinutes, readMinutes) || other.readMinutes == readMinutes)&&(identical(other.publishedDate, publishedDate) || other.publishedDate == publishedDate)&&(identical(other.publishedAt, publishedAt) || other.publishedAt == publishedAt));
}


@override
int get hashCode => Object.hash(runtimeType,id,slug,category,categoryName,categoryColor,title,excerpt,body,coverUrl,author,source,const DeepCollectionEquality().hash(_tags),featured,pinned,viewCount,readMinutes,publishedDate,publishedAt);

@override
String toString() {
  return 'NewsArticle(id: $id, slug: $slug, category: $category, categoryName: $categoryName, categoryColor: $categoryColor, title: $title, excerpt: $excerpt, body: $body, coverUrl: $coverUrl, author: $author, source: $source, tags: $tags, featured: $featured, pinned: $pinned, viewCount: $viewCount, readMinutes: $readMinutes, publishedDate: $publishedDate, publishedAt: $publishedAt)';
}


}

/// @nodoc
abstract mixin class _$NewsArticleCopyWith<$Res> implements $NewsArticleCopyWith<$Res> {
  factory _$NewsArticleCopyWith(_NewsArticle value, $Res Function(_NewsArticle) _then) = __$NewsArticleCopyWithImpl;
@override @useResult
$Res call({
 String id, String slug, String category, Bilingual categoryName, String categoryColor, Bilingual title, Bilingual excerpt, Bilingual? body, String coverUrl, String author, String source, List<String> tags, bool featured, bool pinned, int viewCount, int readMinutes, String publishedDate, String publishedAt
});


@override $BilingualCopyWith<$Res> get categoryName;@override $BilingualCopyWith<$Res> get title;@override $BilingualCopyWith<$Res> get excerpt;@override $BilingualCopyWith<$Res>? get body;

}
/// @nodoc
class __$NewsArticleCopyWithImpl<$Res>
    implements _$NewsArticleCopyWith<$Res> {
  __$NewsArticleCopyWithImpl(this._self, this._then);

  final _NewsArticle _self;
  final $Res Function(_NewsArticle) _then;

/// Create a copy of NewsArticle
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? slug = null,Object? category = null,Object? categoryName = null,Object? categoryColor = null,Object? title = null,Object? excerpt = null,Object? body = freezed,Object? coverUrl = null,Object? author = null,Object? source = null,Object? tags = null,Object? featured = null,Object? pinned = null,Object? viewCount = null,Object? readMinutes = null,Object? publishedDate = null,Object? publishedAt = null,}) {
  return _then(_NewsArticle(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,slug: null == slug ? _self.slug : slug // ignore: cast_nullable_to_non_nullable
as String,category: null == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as String,categoryName: null == categoryName ? _self.categoryName : categoryName // ignore: cast_nullable_to_non_nullable
as Bilingual,categoryColor: null == categoryColor ? _self.categoryColor : categoryColor // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as Bilingual,excerpt: null == excerpt ? _self.excerpt : excerpt // ignore: cast_nullable_to_non_nullable
as Bilingual,body: freezed == body ? _self.body : body // ignore: cast_nullable_to_non_nullable
as Bilingual?,coverUrl: null == coverUrl ? _self.coverUrl : coverUrl // ignore: cast_nullable_to_non_nullable
as String,author: null == author ? _self.author : author // ignore: cast_nullable_to_non_nullable
as String,source: null == source ? _self.source : source // ignore: cast_nullable_to_non_nullable
as String,tags: null == tags ? _self._tags : tags // ignore: cast_nullable_to_non_nullable
as List<String>,featured: null == featured ? _self.featured : featured // ignore: cast_nullable_to_non_nullable
as bool,pinned: null == pinned ? _self.pinned : pinned // ignore: cast_nullable_to_non_nullable
as bool,viewCount: null == viewCount ? _self.viewCount : viewCount // ignore: cast_nullable_to_non_nullable
as int,readMinutes: null == readMinutes ? _self.readMinutes : readMinutes // ignore: cast_nullable_to_non_nullable
as int,publishedDate: null == publishedDate ? _self.publishedDate : publishedDate // ignore: cast_nullable_to_non_nullable
as String,publishedAt: null == publishedAt ? _self.publishedAt : publishedAt // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

/// Create a copy of NewsArticle
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BilingualCopyWith<$Res> get categoryName {
  
  return $BilingualCopyWith<$Res>(_self.categoryName, (value) {
    return _then(_self.copyWith(categoryName: value));
  });
}/// Create a copy of NewsArticle
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BilingualCopyWith<$Res> get title {
  
  return $BilingualCopyWith<$Res>(_self.title, (value) {
    return _then(_self.copyWith(title: value));
  });
}/// Create a copy of NewsArticle
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BilingualCopyWith<$Res> get excerpt {
  
  return $BilingualCopyWith<$Res>(_self.excerpt, (value) {
    return _then(_self.copyWith(excerpt: value));
  });
}/// Create a copy of NewsArticle
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BilingualCopyWith<$Res>? get body {
    if (_self.body == null) {
    return null;
  }

  return $BilingualCopyWith<$Res>(_self.body!, (value) {
    return _then(_self.copyWith(body: value));
  });
}
}

// dart format on
