// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'help_entities.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$FaqCategory {

 String get id;/// Sent back as `?category=<code>`, and the key
/// `HelpCenterPage.tsx:64`'s `CATEGORY_TAB` deep-link table is looked up by.
 String get code; Bilingual get name;/// A **lucide name**, resolved through `AppIcons.help` — the 12-name help
/// scope, not the 54-name service one. `app_icons.dart`'s doc explains why
/// merging the two registries would be an observable divergence.
 String get icon;
/// Create a copy of FaqCategory
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$FaqCategoryCopyWith<FaqCategory> get copyWith => _$FaqCategoryCopyWithImpl<FaqCategory>(this as FaqCategory, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is FaqCategory&&(identical(other.id, id) || other.id == id)&&(identical(other.code, code) || other.code == code)&&(identical(other.name, name) || other.name == name)&&(identical(other.icon, icon) || other.icon == icon));
}


@override
int get hashCode => Object.hash(runtimeType,id,code,name,icon);

@override
String toString() {
  return 'FaqCategory(id: $id, code: $code, name: $name, icon: $icon)';
}


}

/// @nodoc
abstract mixin class $FaqCategoryCopyWith<$Res>  {
  factory $FaqCategoryCopyWith(FaqCategory value, $Res Function(FaqCategory) _then) = _$FaqCategoryCopyWithImpl;
@useResult
$Res call({
 String id, String code, Bilingual name, String icon
});


$BilingualCopyWith<$Res> get name;

}
/// @nodoc
class _$FaqCategoryCopyWithImpl<$Res>
    implements $FaqCategoryCopyWith<$Res> {
  _$FaqCategoryCopyWithImpl(this._self, this._then);

  final FaqCategory _self;
  final $Res Function(FaqCategory) _then;

/// Create a copy of FaqCategory
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? code = null,Object? name = null,Object? icon = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,code: null == code ? _self.code : code // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as Bilingual,icon: null == icon ? _self.icon : icon // ignore: cast_nullable_to_non_nullable
as String,
  ));
}
/// Create a copy of FaqCategory
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BilingualCopyWith<$Res> get name {
  
  return $BilingualCopyWith<$Res>(_self.name, (value) {
    return _then(_self.copyWith(name: value));
  });
}
}


/// Adds pattern-matching-related methods to [FaqCategory].
extension FaqCategoryPatterns on FaqCategory {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _FaqCategory value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _FaqCategory() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _FaqCategory value)  $default,){
final _that = this;
switch (_that) {
case _FaqCategory():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _FaqCategory value)?  $default,){
final _that = this;
switch (_that) {
case _FaqCategory() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String code,  Bilingual name,  String icon)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _FaqCategory() when $default != null:
return $default(_that.id,_that.code,_that.name,_that.icon);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String code,  Bilingual name,  String icon)  $default,) {final _that = this;
switch (_that) {
case _FaqCategory():
return $default(_that.id,_that.code,_that.name,_that.icon);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String code,  Bilingual name,  String icon)?  $default,) {final _that = this;
switch (_that) {
case _FaqCategory() when $default != null:
return $default(_that.id,_that.code,_that.name,_that.icon);case _:
  return null;

}
}

}

/// @nodoc


class _FaqCategory implements FaqCategory {
  const _FaqCategory({this.id = '', this.code = '', this.name = const Bilingual(en: '', lo: ''), this.icon = ''});
  

@override@JsonKey() final  String id;
/// Sent back as `?category=<code>`, and the key
/// `HelpCenterPage.tsx:64`'s `CATEGORY_TAB` deep-link table is looked up by.
@override@JsonKey() final  String code;
@override@JsonKey() final  Bilingual name;
/// A **lucide name**, resolved through `AppIcons.help` — the 12-name help
/// scope, not the 54-name service one. `app_icons.dart`'s doc explains why
/// merging the two registries would be an observable divergence.
@override@JsonKey() final  String icon;

/// Create a copy of FaqCategory
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$FaqCategoryCopyWith<_FaqCategory> get copyWith => __$FaqCategoryCopyWithImpl<_FaqCategory>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _FaqCategory&&(identical(other.id, id) || other.id == id)&&(identical(other.code, code) || other.code == code)&&(identical(other.name, name) || other.name == name)&&(identical(other.icon, icon) || other.icon == icon));
}


@override
int get hashCode => Object.hash(runtimeType,id,code,name,icon);

@override
String toString() {
  return 'FaqCategory(id: $id, code: $code, name: $name, icon: $icon)';
}


}

/// @nodoc
abstract mixin class _$FaqCategoryCopyWith<$Res> implements $FaqCategoryCopyWith<$Res> {
  factory _$FaqCategoryCopyWith(_FaqCategory value, $Res Function(_FaqCategory) _then) = __$FaqCategoryCopyWithImpl;
@override @useResult
$Res call({
 String id, String code, Bilingual name, String icon
});


@override $BilingualCopyWith<$Res> get name;

}
/// @nodoc
class __$FaqCategoryCopyWithImpl<$Res>
    implements _$FaqCategoryCopyWith<$Res> {
  __$FaqCategoryCopyWithImpl(this._self, this._then);

  final _FaqCategory _self;
  final $Res Function(_FaqCategory) _then;

/// Create a copy of FaqCategory
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? code = null,Object? name = null,Object? icon = null,}) {
  return _then(_FaqCategory(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,code: null == code ? _self.code : code // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as Bilingual,icon: null == icon ? _self.icon : icon // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

/// Create a copy of FaqCategory
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BilingualCopyWith<$Res> get name {
  
  return $BilingualCopyWith<$Res>(_self.name, (value) {
    return _then(_self.copyWith(name: value));
  });
}
}

/// @nodoc
mixin _$FaqItem {

 String get id;/// The category **code**, matched against [FaqCategory.code] to find the
/// question's swatch and icon (`catMeta`, `HelpCenterPage.tsx:132-136`).
 String get category; Bilingual get question; Bilingual get answer; List<String> get tags;/// `a.helpful >= 5 && !searching` gates the "Popular right now" pill
/// (`:302`).
 int get helpful; int get notHelpful;
/// Create a copy of FaqItem
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$FaqItemCopyWith<FaqItem> get copyWith => _$FaqItemCopyWithImpl<FaqItem>(this as FaqItem, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is FaqItem&&(identical(other.id, id) || other.id == id)&&(identical(other.category, category) || other.category == category)&&(identical(other.question, question) || other.question == question)&&(identical(other.answer, answer) || other.answer == answer)&&const DeepCollectionEquality().equals(other.tags, tags)&&(identical(other.helpful, helpful) || other.helpful == helpful)&&(identical(other.notHelpful, notHelpful) || other.notHelpful == notHelpful));
}


@override
int get hashCode => Object.hash(runtimeType,id,category,question,answer,const DeepCollectionEquality().hash(tags),helpful,notHelpful);

@override
String toString() {
  return 'FaqItem(id: $id, category: $category, question: $question, answer: $answer, tags: $tags, helpful: $helpful, notHelpful: $notHelpful)';
}


}

/// @nodoc
abstract mixin class $FaqItemCopyWith<$Res>  {
  factory $FaqItemCopyWith(FaqItem value, $Res Function(FaqItem) _then) = _$FaqItemCopyWithImpl;
@useResult
$Res call({
 String id, String category, Bilingual question, Bilingual answer, List<String> tags, int helpful, int notHelpful
});


$BilingualCopyWith<$Res> get question;$BilingualCopyWith<$Res> get answer;

}
/// @nodoc
class _$FaqItemCopyWithImpl<$Res>
    implements $FaqItemCopyWith<$Res> {
  _$FaqItemCopyWithImpl(this._self, this._then);

  final FaqItem _self;
  final $Res Function(FaqItem) _then;

/// Create a copy of FaqItem
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? category = null,Object? question = null,Object? answer = null,Object? tags = null,Object? helpful = null,Object? notHelpful = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,category: null == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as String,question: null == question ? _self.question : question // ignore: cast_nullable_to_non_nullable
as Bilingual,answer: null == answer ? _self.answer : answer // ignore: cast_nullable_to_non_nullable
as Bilingual,tags: null == tags ? _self.tags : tags // ignore: cast_nullable_to_non_nullable
as List<String>,helpful: null == helpful ? _self.helpful : helpful // ignore: cast_nullable_to_non_nullable
as int,notHelpful: null == notHelpful ? _self.notHelpful : notHelpful // ignore: cast_nullable_to_non_nullable
as int,
  ));
}
/// Create a copy of FaqItem
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BilingualCopyWith<$Res> get question {
  
  return $BilingualCopyWith<$Res>(_self.question, (value) {
    return _then(_self.copyWith(question: value));
  });
}/// Create a copy of FaqItem
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BilingualCopyWith<$Res> get answer {
  
  return $BilingualCopyWith<$Res>(_self.answer, (value) {
    return _then(_self.copyWith(answer: value));
  });
}
}


/// Adds pattern-matching-related methods to [FaqItem].
extension FaqItemPatterns on FaqItem {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _FaqItem value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _FaqItem() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _FaqItem value)  $default,){
final _that = this;
switch (_that) {
case _FaqItem():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _FaqItem value)?  $default,){
final _that = this;
switch (_that) {
case _FaqItem() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String category,  Bilingual question,  Bilingual answer,  List<String> tags,  int helpful,  int notHelpful)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _FaqItem() when $default != null:
return $default(_that.id,_that.category,_that.question,_that.answer,_that.tags,_that.helpful,_that.notHelpful);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String category,  Bilingual question,  Bilingual answer,  List<String> tags,  int helpful,  int notHelpful)  $default,) {final _that = this;
switch (_that) {
case _FaqItem():
return $default(_that.id,_that.category,_that.question,_that.answer,_that.tags,_that.helpful,_that.notHelpful);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String category,  Bilingual question,  Bilingual answer,  List<String> tags,  int helpful,  int notHelpful)?  $default,) {final _that = this;
switch (_that) {
case _FaqItem() when $default != null:
return $default(_that.id,_that.category,_that.question,_that.answer,_that.tags,_that.helpful,_that.notHelpful);case _:
  return null;

}
}

}

/// @nodoc


class _FaqItem implements FaqItem {
  const _FaqItem({this.id = '', this.category = '', this.question = const Bilingual(en: '', lo: ''), this.answer = const Bilingual(en: '', lo: ''), final  List<String> tags = const <String>[], this.helpful = 0, this.notHelpful = 0}): _tags = tags;
  

@override@JsonKey() final  String id;
/// The category **code**, matched against [FaqCategory.code] to find the
/// question's swatch and icon (`catMeta`, `HelpCenterPage.tsx:132-136`).
@override@JsonKey() final  String category;
@override@JsonKey() final  Bilingual question;
@override@JsonKey() final  Bilingual answer;
 final  List<String> _tags;
@override@JsonKey() List<String> get tags {
  if (_tags is EqualUnmodifiableListView) return _tags;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_tags);
}

/// `a.helpful >= 5 && !searching` gates the "Popular right now" pill
/// (`:302`).
@override@JsonKey() final  int helpful;
@override@JsonKey() final  int notHelpful;

/// Create a copy of FaqItem
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$FaqItemCopyWith<_FaqItem> get copyWith => __$FaqItemCopyWithImpl<_FaqItem>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _FaqItem&&(identical(other.id, id) || other.id == id)&&(identical(other.category, category) || other.category == category)&&(identical(other.question, question) || other.question == question)&&(identical(other.answer, answer) || other.answer == answer)&&const DeepCollectionEquality().equals(other._tags, _tags)&&(identical(other.helpful, helpful) || other.helpful == helpful)&&(identical(other.notHelpful, notHelpful) || other.notHelpful == notHelpful));
}


@override
int get hashCode => Object.hash(runtimeType,id,category,question,answer,const DeepCollectionEquality().hash(_tags),helpful,notHelpful);

@override
String toString() {
  return 'FaqItem(id: $id, category: $category, question: $question, answer: $answer, tags: $tags, helpful: $helpful, notHelpful: $notHelpful)';
}


}

/// @nodoc
abstract mixin class _$FaqItemCopyWith<$Res> implements $FaqItemCopyWith<$Res> {
  factory _$FaqItemCopyWith(_FaqItem value, $Res Function(_FaqItem) _then) = __$FaqItemCopyWithImpl;
@override @useResult
$Res call({
 String id, String category, Bilingual question, Bilingual answer, List<String> tags, int helpful, int notHelpful
});


@override $BilingualCopyWith<$Res> get question;@override $BilingualCopyWith<$Res> get answer;

}
/// @nodoc
class __$FaqItemCopyWithImpl<$Res>
    implements _$FaqItemCopyWith<$Res> {
  __$FaqItemCopyWithImpl(this._self, this._then);

  final _FaqItem _self;
  final $Res Function(_FaqItem) _then;

/// Create a copy of FaqItem
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? category = null,Object? question = null,Object? answer = null,Object? tags = null,Object? helpful = null,Object? notHelpful = null,}) {
  return _then(_FaqItem(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,category: null == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as String,question: null == question ? _self.question : question // ignore: cast_nullable_to_non_nullable
as Bilingual,answer: null == answer ? _self.answer : answer // ignore: cast_nullable_to_non_nullable
as Bilingual,tags: null == tags ? _self._tags : tags // ignore: cast_nullable_to_non_nullable
as List<String>,helpful: null == helpful ? _self.helpful : helpful // ignore: cast_nullable_to_non_nullable
as int,notHelpful: null == notHelpful ? _self.notHelpful : notHelpful // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

/// Create a copy of FaqItem
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BilingualCopyWith<$Res> get question {
  
  return $BilingualCopyWith<$Res>(_self.question, (value) {
    return _then(_self.copyWith(question: value));
  });
}/// Create a copy of FaqItem
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BilingualCopyWith<$Res> get answer {
  
  return $BilingualCopyWith<$Res>(_self.answer, (value) {
    return _then(_self.copyWith(answer: value));
  });
}
}

/// @nodoc
mixin _$HelpArticle {

 String get id; String get slug; Bilingual get title;/// **Null on the list endpoint.** The source says so in as many words at
/// `:443`: *"The body only comes with the single-article endpoint."* — and
/// that is exactly what makes the expanded guide show a skeleton until the
/// second request lands. An empty `Bilingual` could not express the
/// difference between "no body yet" and "a guide with an empty body".
 Bilingual? get body;
/// Create a copy of HelpArticle
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$HelpArticleCopyWith<HelpArticle> get copyWith => _$HelpArticleCopyWithImpl<HelpArticle>(this as HelpArticle, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is HelpArticle&&(identical(other.id, id) || other.id == id)&&(identical(other.slug, slug) || other.slug == slug)&&(identical(other.title, title) || other.title == title)&&(identical(other.body, body) || other.body == body));
}


@override
int get hashCode => Object.hash(runtimeType,id,slug,title,body);

@override
String toString() {
  return 'HelpArticle(id: $id, slug: $slug, title: $title, body: $body)';
}


}

/// @nodoc
abstract mixin class $HelpArticleCopyWith<$Res>  {
  factory $HelpArticleCopyWith(HelpArticle value, $Res Function(HelpArticle) _then) = _$HelpArticleCopyWithImpl;
@useResult
$Res call({
 String id, String slug, Bilingual title, Bilingual? body
});


$BilingualCopyWith<$Res> get title;$BilingualCopyWith<$Res>? get body;

}
/// @nodoc
class _$HelpArticleCopyWithImpl<$Res>
    implements $HelpArticleCopyWith<$Res> {
  _$HelpArticleCopyWithImpl(this._self, this._then);

  final HelpArticle _self;
  final $Res Function(HelpArticle) _then;

/// Create a copy of HelpArticle
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? slug = null,Object? title = null,Object? body = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,slug: null == slug ? _self.slug : slug // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as Bilingual,body: freezed == body ? _self.body : body // ignore: cast_nullable_to_non_nullable
as Bilingual?,
  ));
}
/// Create a copy of HelpArticle
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BilingualCopyWith<$Res> get title {
  
  return $BilingualCopyWith<$Res>(_self.title, (value) {
    return _then(_self.copyWith(title: value));
  });
}/// Create a copy of HelpArticle
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


/// Adds pattern-matching-related methods to [HelpArticle].
extension HelpArticlePatterns on HelpArticle {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _HelpArticle value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _HelpArticle() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _HelpArticle value)  $default,){
final _that = this;
switch (_that) {
case _HelpArticle():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _HelpArticle value)?  $default,){
final _that = this;
switch (_that) {
case _HelpArticle() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String slug,  Bilingual title,  Bilingual? body)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _HelpArticle() when $default != null:
return $default(_that.id,_that.slug,_that.title,_that.body);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String slug,  Bilingual title,  Bilingual? body)  $default,) {final _that = this;
switch (_that) {
case _HelpArticle():
return $default(_that.id,_that.slug,_that.title,_that.body);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String slug,  Bilingual title,  Bilingual? body)?  $default,) {final _that = this;
switch (_that) {
case _HelpArticle() when $default != null:
return $default(_that.id,_that.slug,_that.title,_that.body);case _:
  return null;

}
}

}

/// @nodoc


class _HelpArticle implements HelpArticle {
  const _HelpArticle({this.id = '', this.slug = '', this.title = const Bilingual(en: '', lo: ''), this.body});
  

@override@JsonKey() final  String id;
@override@JsonKey() final  String slug;
@override@JsonKey() final  Bilingual title;
/// **Null on the list endpoint.** The source says so in as many words at
/// `:443`: *"The body only comes with the single-article endpoint."* — and
/// that is exactly what makes the expanded guide show a skeleton until the
/// second request lands. An empty `Bilingual` could not express the
/// difference between "no body yet" and "a guide with an empty body".
@override final  Bilingual? body;

/// Create a copy of HelpArticle
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$HelpArticleCopyWith<_HelpArticle> get copyWith => __$HelpArticleCopyWithImpl<_HelpArticle>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _HelpArticle&&(identical(other.id, id) || other.id == id)&&(identical(other.slug, slug) || other.slug == slug)&&(identical(other.title, title) || other.title == title)&&(identical(other.body, body) || other.body == body));
}


@override
int get hashCode => Object.hash(runtimeType,id,slug,title,body);

@override
String toString() {
  return 'HelpArticle(id: $id, slug: $slug, title: $title, body: $body)';
}


}

/// @nodoc
abstract mixin class _$HelpArticleCopyWith<$Res> implements $HelpArticleCopyWith<$Res> {
  factory _$HelpArticleCopyWith(_HelpArticle value, $Res Function(_HelpArticle) _then) = __$HelpArticleCopyWithImpl;
@override @useResult
$Res call({
 String id, String slug, Bilingual title, Bilingual? body
});


@override $BilingualCopyWith<$Res> get title;@override $BilingualCopyWith<$Res>? get body;

}
/// @nodoc
class __$HelpArticleCopyWithImpl<$Res>
    implements _$HelpArticleCopyWith<$Res> {
  __$HelpArticleCopyWithImpl(this._self, this._then);

  final _HelpArticle _self;
  final $Res Function(_HelpArticle) _then;

/// Create a copy of HelpArticle
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? slug = null,Object? title = null,Object? body = freezed,}) {
  return _then(_HelpArticle(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,slug: null == slug ? _self.slug : slug // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as Bilingual,body: freezed == body ? _self.body : body // ignore: cast_nullable_to_non_nullable
as Bilingual?,
  ));
}

/// Create a copy of HelpArticle
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BilingualCopyWith<$Res> get title {
  
  return $BilingualCopyWith<$Res>(_self.title, (value) {
    return _then(_self.copyWith(title: value));
  });
}/// Create a copy of HelpArticle
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

/// @nodoc
mixin _$SupportChannel {

 String get id;/// `phone` · `email` · `chat` · `office`. Only the first two become links
/// (`tel:` / `mailto:`, `:492-496`); the other two render as plain tiles.
 String get kind; Bilingual get label;/// The dialable number / address / free text. Rendered verbatim, so it is a
/// plain `String` on the wire and here.
 String get value; Bilingual get hours;/// A lucide name, resolved through `AppIcons.help`. Note the source passes
/// a **different fallback** here — `icon(ch.icon, MessageCircle)` at `:490`
/// versus the default `FileText` everywhere else; see
/// `help_repository.dart` for how that is preserved.
 String get icon;
/// Create a copy of SupportChannel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SupportChannelCopyWith<SupportChannel> get copyWith => _$SupportChannelCopyWithImpl<SupportChannel>(this as SupportChannel, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SupportChannel&&(identical(other.id, id) || other.id == id)&&(identical(other.kind, kind) || other.kind == kind)&&(identical(other.label, label) || other.label == label)&&(identical(other.value, value) || other.value == value)&&(identical(other.hours, hours) || other.hours == hours)&&(identical(other.icon, icon) || other.icon == icon));
}


@override
int get hashCode => Object.hash(runtimeType,id,kind,label,value,hours,icon);

@override
String toString() {
  return 'SupportChannel(id: $id, kind: $kind, label: $label, value: $value, hours: $hours, icon: $icon)';
}


}

/// @nodoc
abstract mixin class $SupportChannelCopyWith<$Res>  {
  factory $SupportChannelCopyWith(SupportChannel value, $Res Function(SupportChannel) _then) = _$SupportChannelCopyWithImpl;
@useResult
$Res call({
 String id, String kind, Bilingual label, String value, Bilingual hours, String icon
});


$BilingualCopyWith<$Res> get label;$BilingualCopyWith<$Res> get hours;

}
/// @nodoc
class _$SupportChannelCopyWithImpl<$Res>
    implements $SupportChannelCopyWith<$Res> {
  _$SupportChannelCopyWithImpl(this._self, this._then);

  final SupportChannel _self;
  final $Res Function(SupportChannel) _then;

/// Create a copy of SupportChannel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? kind = null,Object? label = null,Object? value = null,Object? hours = null,Object? icon = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as String,label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as Bilingual,value: null == value ? _self.value : value // ignore: cast_nullable_to_non_nullable
as String,hours: null == hours ? _self.hours : hours // ignore: cast_nullable_to_non_nullable
as Bilingual,icon: null == icon ? _self.icon : icon // ignore: cast_nullable_to_non_nullable
as String,
  ));
}
/// Create a copy of SupportChannel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BilingualCopyWith<$Res> get label {
  
  return $BilingualCopyWith<$Res>(_self.label, (value) {
    return _then(_self.copyWith(label: value));
  });
}/// Create a copy of SupportChannel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BilingualCopyWith<$Res> get hours {
  
  return $BilingualCopyWith<$Res>(_self.hours, (value) {
    return _then(_self.copyWith(hours: value));
  });
}
}


/// Adds pattern-matching-related methods to [SupportChannel].
extension SupportChannelPatterns on SupportChannel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SupportChannel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SupportChannel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SupportChannel value)  $default,){
final _that = this;
switch (_that) {
case _SupportChannel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SupportChannel value)?  $default,){
final _that = this;
switch (_that) {
case _SupportChannel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String kind,  Bilingual label,  String value,  Bilingual hours,  String icon)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SupportChannel() when $default != null:
return $default(_that.id,_that.kind,_that.label,_that.value,_that.hours,_that.icon);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String kind,  Bilingual label,  String value,  Bilingual hours,  String icon)  $default,) {final _that = this;
switch (_that) {
case _SupportChannel():
return $default(_that.id,_that.kind,_that.label,_that.value,_that.hours,_that.icon);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String kind,  Bilingual label,  String value,  Bilingual hours,  String icon)?  $default,) {final _that = this;
switch (_that) {
case _SupportChannel() when $default != null:
return $default(_that.id,_that.kind,_that.label,_that.value,_that.hours,_that.icon);case _:
  return null;

}
}

}

/// @nodoc


class _SupportChannel implements SupportChannel {
  const _SupportChannel({this.id = '', this.kind = '', this.label = const Bilingual(en: '', lo: ''), this.value = '', this.hours = const Bilingual(en: '', lo: ''), this.icon = ''});
  

@override@JsonKey() final  String id;
/// `phone` · `email` · `chat` · `office`. Only the first two become links
/// (`tel:` / `mailto:`, `:492-496`); the other two render as plain tiles.
@override@JsonKey() final  String kind;
@override@JsonKey() final  Bilingual label;
/// The dialable number / address / free text. Rendered verbatim, so it is a
/// plain `String` on the wire and here.
@override@JsonKey() final  String value;
@override@JsonKey() final  Bilingual hours;
/// A lucide name, resolved through `AppIcons.help`. Note the source passes
/// a **different fallback** here — `icon(ch.icon, MessageCircle)` at `:490`
/// versus the default `FileText` everywhere else; see
/// `help_repository.dart` for how that is preserved.
@override@JsonKey() final  String icon;

/// Create a copy of SupportChannel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SupportChannelCopyWith<_SupportChannel> get copyWith => __$SupportChannelCopyWithImpl<_SupportChannel>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SupportChannel&&(identical(other.id, id) || other.id == id)&&(identical(other.kind, kind) || other.kind == kind)&&(identical(other.label, label) || other.label == label)&&(identical(other.value, value) || other.value == value)&&(identical(other.hours, hours) || other.hours == hours)&&(identical(other.icon, icon) || other.icon == icon));
}


@override
int get hashCode => Object.hash(runtimeType,id,kind,label,value,hours,icon);

@override
String toString() {
  return 'SupportChannel(id: $id, kind: $kind, label: $label, value: $value, hours: $hours, icon: $icon)';
}


}

/// @nodoc
abstract mixin class _$SupportChannelCopyWith<$Res> implements $SupportChannelCopyWith<$Res> {
  factory _$SupportChannelCopyWith(_SupportChannel value, $Res Function(_SupportChannel) _then) = __$SupportChannelCopyWithImpl;
@override @useResult
$Res call({
 String id, String kind, Bilingual label, String value, Bilingual hours, String icon
});


@override $BilingualCopyWith<$Res> get label;@override $BilingualCopyWith<$Res> get hours;

}
/// @nodoc
class __$SupportChannelCopyWithImpl<$Res>
    implements _$SupportChannelCopyWith<$Res> {
  __$SupportChannelCopyWithImpl(this._self, this._then);

  final _SupportChannel _self;
  final $Res Function(_SupportChannel) _then;

/// Create a copy of SupportChannel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? kind = null,Object? label = null,Object? value = null,Object? hours = null,Object? icon = null,}) {
  return _then(_SupportChannel(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as String,label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as Bilingual,value: null == value ? _self.value : value // ignore: cast_nullable_to_non_nullable
as String,hours: null == hours ? _self.hours : hours // ignore: cast_nullable_to_non_nullable
as Bilingual,icon: null == icon ? _self.icon : icon // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

/// Create a copy of SupportChannel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BilingualCopyWith<$Res> get label {
  
  return $BilingualCopyWith<$Res>(_self.label, (value) {
    return _then(_self.copyWith(label: value));
  });
}/// Create a copy of SupportChannel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BilingualCopyWith<$Res> get hours {
  
  return $BilingualCopyWith<$Res>(_self.hours, (value) {
    return _then(_self.copyWith(hours: value));
  });
}
}

// dart format on
