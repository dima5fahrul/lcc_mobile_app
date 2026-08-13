// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'home_news_item.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$HomeNewsItem {

 String get id;/// The article's stable key. `newsHref(item.slug)` (`HomePage.tsx:656`)
/// builds `#/news/<slug>`; the Flutter route is B2c's `/news/:slug`.
 String get slug; Bilingual get categoryName;/// `#RRGGBB`, or empty. **Data, not a token** — `item.category_color ||
/// "#344EAD"` (`HomePage.tsx:652`) is the source's own fallback chain and
/// the value behind it changes without an app release, so it is parsed at
/// the edge and never transcribed (see `AppColors`' note on runtime colour
/// families).
 String get categoryColor; Bilingual get title; Bilingual get excerpt;/// A remote thumbnail URL, or empty. The card draws the category gradient
/// underneath either way (`HomePage.tsx:661-673`), so an absent cover is a
/// styled card rather than a hole.
 String get coverUrl;/// `item.published_date || item.published_at` is the source's precedence
/// (`HomePage.tsx:684`); both are kept so the fallback is expressible.
 String get publishedDate; String get publishedAt;
/// Create a copy of HomeNewsItem
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$HomeNewsItemCopyWith<HomeNewsItem> get copyWith => _$HomeNewsItemCopyWithImpl<HomeNewsItem>(this as HomeNewsItem, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is HomeNewsItem&&(identical(other.id, id) || other.id == id)&&(identical(other.slug, slug) || other.slug == slug)&&(identical(other.categoryName, categoryName) || other.categoryName == categoryName)&&(identical(other.categoryColor, categoryColor) || other.categoryColor == categoryColor)&&(identical(other.title, title) || other.title == title)&&(identical(other.excerpt, excerpt) || other.excerpt == excerpt)&&(identical(other.coverUrl, coverUrl) || other.coverUrl == coverUrl)&&(identical(other.publishedDate, publishedDate) || other.publishedDate == publishedDate)&&(identical(other.publishedAt, publishedAt) || other.publishedAt == publishedAt));
}


@override
int get hashCode => Object.hash(runtimeType,id,slug,categoryName,categoryColor,title,excerpt,coverUrl,publishedDate,publishedAt);

@override
String toString() {
  return 'HomeNewsItem(id: $id, slug: $slug, categoryName: $categoryName, categoryColor: $categoryColor, title: $title, excerpt: $excerpt, coverUrl: $coverUrl, publishedDate: $publishedDate, publishedAt: $publishedAt)';
}


}

/// @nodoc
abstract mixin class $HomeNewsItemCopyWith<$Res>  {
  factory $HomeNewsItemCopyWith(HomeNewsItem value, $Res Function(HomeNewsItem) _then) = _$HomeNewsItemCopyWithImpl;
@useResult
$Res call({
 String id, String slug, Bilingual categoryName, String categoryColor, Bilingual title, Bilingual excerpt, String coverUrl, String publishedDate, String publishedAt
});


$BilingualCopyWith<$Res> get categoryName;$BilingualCopyWith<$Res> get title;$BilingualCopyWith<$Res> get excerpt;

}
/// @nodoc
class _$HomeNewsItemCopyWithImpl<$Res>
    implements $HomeNewsItemCopyWith<$Res> {
  _$HomeNewsItemCopyWithImpl(this._self, this._then);

  final HomeNewsItem _self;
  final $Res Function(HomeNewsItem) _then;

/// Create a copy of HomeNewsItem
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? slug = null,Object? categoryName = null,Object? categoryColor = null,Object? title = null,Object? excerpt = null,Object? coverUrl = null,Object? publishedDate = null,Object? publishedAt = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,slug: null == slug ? _self.slug : slug // ignore: cast_nullable_to_non_nullable
as String,categoryName: null == categoryName ? _self.categoryName : categoryName // ignore: cast_nullable_to_non_nullable
as Bilingual,categoryColor: null == categoryColor ? _self.categoryColor : categoryColor // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as Bilingual,excerpt: null == excerpt ? _self.excerpt : excerpt // ignore: cast_nullable_to_non_nullable
as Bilingual,coverUrl: null == coverUrl ? _self.coverUrl : coverUrl // ignore: cast_nullable_to_non_nullable
as String,publishedDate: null == publishedDate ? _self.publishedDate : publishedDate // ignore: cast_nullable_to_non_nullable
as String,publishedAt: null == publishedAt ? _self.publishedAt : publishedAt // ignore: cast_nullable_to_non_nullable
as String,
  ));
}
/// Create a copy of HomeNewsItem
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BilingualCopyWith<$Res> get categoryName {
  
  return $BilingualCopyWith<$Res>(_self.categoryName, (value) {
    return _then(_self.copyWith(categoryName: value));
  });
}/// Create a copy of HomeNewsItem
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BilingualCopyWith<$Res> get title {
  
  return $BilingualCopyWith<$Res>(_self.title, (value) {
    return _then(_self.copyWith(title: value));
  });
}/// Create a copy of HomeNewsItem
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BilingualCopyWith<$Res> get excerpt {
  
  return $BilingualCopyWith<$Res>(_self.excerpt, (value) {
    return _then(_self.copyWith(excerpt: value));
  });
}
}


/// Adds pattern-matching-related methods to [HomeNewsItem].
extension HomeNewsItemPatterns on HomeNewsItem {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _HomeNewsItem value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _HomeNewsItem() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _HomeNewsItem value)  $default,){
final _that = this;
switch (_that) {
case _HomeNewsItem():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _HomeNewsItem value)?  $default,){
final _that = this;
switch (_that) {
case _HomeNewsItem() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String slug,  Bilingual categoryName,  String categoryColor,  Bilingual title,  Bilingual excerpt,  String coverUrl,  String publishedDate,  String publishedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _HomeNewsItem() when $default != null:
return $default(_that.id,_that.slug,_that.categoryName,_that.categoryColor,_that.title,_that.excerpt,_that.coverUrl,_that.publishedDate,_that.publishedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String slug,  Bilingual categoryName,  String categoryColor,  Bilingual title,  Bilingual excerpt,  String coverUrl,  String publishedDate,  String publishedAt)  $default,) {final _that = this;
switch (_that) {
case _HomeNewsItem():
return $default(_that.id,_that.slug,_that.categoryName,_that.categoryColor,_that.title,_that.excerpt,_that.coverUrl,_that.publishedDate,_that.publishedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String slug,  Bilingual categoryName,  String categoryColor,  Bilingual title,  Bilingual excerpt,  String coverUrl,  String publishedDate,  String publishedAt)?  $default,) {final _that = this;
switch (_that) {
case _HomeNewsItem() when $default != null:
return $default(_that.id,_that.slug,_that.categoryName,_that.categoryColor,_that.title,_that.excerpt,_that.coverUrl,_that.publishedDate,_that.publishedAt);case _:
  return null;

}
}

}

/// @nodoc


class _HomeNewsItem extends HomeNewsItem {
  const _HomeNewsItem({this.id = '', this.slug = '', this.categoryName = const Bilingual(en: '', lo: ''), this.categoryColor = '', this.title = const Bilingual(en: '', lo: ''), this.excerpt = const Bilingual(en: '', lo: ''), this.coverUrl = '', this.publishedDate = '', this.publishedAt = ''}): super._();
  

@override@JsonKey() final  String id;
/// The article's stable key. `newsHref(item.slug)` (`HomePage.tsx:656`)
/// builds `#/news/<slug>`; the Flutter route is B2c's `/news/:slug`.
@override@JsonKey() final  String slug;
@override@JsonKey() final  Bilingual categoryName;
/// `#RRGGBB`, or empty. **Data, not a token** — `item.category_color ||
/// "#344EAD"` (`HomePage.tsx:652`) is the source's own fallback chain and
/// the value behind it changes without an app release, so it is parsed at
/// the edge and never transcribed (see `AppColors`' note on runtime colour
/// families).
@override@JsonKey() final  String categoryColor;
@override@JsonKey() final  Bilingual title;
@override@JsonKey() final  Bilingual excerpt;
/// A remote thumbnail URL, or empty. The card draws the category gradient
/// underneath either way (`HomePage.tsx:661-673`), so an absent cover is a
/// styled card rather than a hole.
@override@JsonKey() final  String coverUrl;
/// `item.published_date || item.published_at` is the source's precedence
/// (`HomePage.tsx:684`); both are kept so the fallback is expressible.
@override@JsonKey() final  String publishedDate;
@override@JsonKey() final  String publishedAt;

/// Create a copy of HomeNewsItem
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$HomeNewsItemCopyWith<_HomeNewsItem> get copyWith => __$HomeNewsItemCopyWithImpl<_HomeNewsItem>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _HomeNewsItem&&(identical(other.id, id) || other.id == id)&&(identical(other.slug, slug) || other.slug == slug)&&(identical(other.categoryName, categoryName) || other.categoryName == categoryName)&&(identical(other.categoryColor, categoryColor) || other.categoryColor == categoryColor)&&(identical(other.title, title) || other.title == title)&&(identical(other.excerpt, excerpt) || other.excerpt == excerpt)&&(identical(other.coverUrl, coverUrl) || other.coverUrl == coverUrl)&&(identical(other.publishedDate, publishedDate) || other.publishedDate == publishedDate)&&(identical(other.publishedAt, publishedAt) || other.publishedAt == publishedAt));
}


@override
int get hashCode => Object.hash(runtimeType,id,slug,categoryName,categoryColor,title,excerpt,coverUrl,publishedDate,publishedAt);

@override
String toString() {
  return 'HomeNewsItem(id: $id, slug: $slug, categoryName: $categoryName, categoryColor: $categoryColor, title: $title, excerpt: $excerpt, coverUrl: $coverUrl, publishedDate: $publishedDate, publishedAt: $publishedAt)';
}


}

/// @nodoc
abstract mixin class _$HomeNewsItemCopyWith<$Res> implements $HomeNewsItemCopyWith<$Res> {
  factory _$HomeNewsItemCopyWith(_HomeNewsItem value, $Res Function(_HomeNewsItem) _then) = __$HomeNewsItemCopyWithImpl;
@override @useResult
$Res call({
 String id, String slug, Bilingual categoryName, String categoryColor, Bilingual title, Bilingual excerpt, String coverUrl, String publishedDate, String publishedAt
});


@override $BilingualCopyWith<$Res> get categoryName;@override $BilingualCopyWith<$Res> get title;@override $BilingualCopyWith<$Res> get excerpt;

}
/// @nodoc
class __$HomeNewsItemCopyWithImpl<$Res>
    implements _$HomeNewsItemCopyWith<$Res> {
  __$HomeNewsItemCopyWithImpl(this._self, this._then);

  final _HomeNewsItem _self;
  final $Res Function(_HomeNewsItem) _then;

/// Create a copy of HomeNewsItem
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? slug = null,Object? categoryName = null,Object? categoryColor = null,Object? title = null,Object? excerpt = null,Object? coverUrl = null,Object? publishedDate = null,Object? publishedAt = null,}) {
  return _then(_HomeNewsItem(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,slug: null == slug ? _self.slug : slug // ignore: cast_nullable_to_non_nullable
as String,categoryName: null == categoryName ? _self.categoryName : categoryName // ignore: cast_nullable_to_non_nullable
as Bilingual,categoryColor: null == categoryColor ? _self.categoryColor : categoryColor // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as Bilingual,excerpt: null == excerpt ? _self.excerpt : excerpt // ignore: cast_nullable_to_non_nullable
as Bilingual,coverUrl: null == coverUrl ? _self.coverUrl : coverUrl // ignore: cast_nullable_to_non_nullable
as String,publishedDate: null == publishedDate ? _self.publishedDate : publishedDate // ignore: cast_nullable_to_non_nullable
as String,publishedAt: null == publishedAt ? _self.publishedAt : publishedAt // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

/// Create a copy of HomeNewsItem
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BilingualCopyWith<$Res> get categoryName {
  
  return $BilingualCopyWith<$Res>(_self.categoryName, (value) {
    return _then(_self.copyWith(categoryName: value));
  });
}/// Create a copy of HomeNewsItem
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BilingualCopyWith<$Res> get title {
  
  return $BilingualCopyWith<$Res>(_self.title, (value) {
    return _then(_self.copyWith(title: value));
  });
}/// Create a copy of HomeNewsItem
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BilingualCopyWith<$Res> get excerpt {
  
  return $BilingualCopyWith<$Res>(_self.excerpt, (value) {
    return _then(_self.copyWith(excerpt: value));
  });
}
}

// dart format on
