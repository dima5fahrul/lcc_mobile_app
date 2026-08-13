// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'help_bloc.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$HelpState {

// ── Topic chips ──────────────────────────────────────────────────────────
 RegionStatus get categoriesStatus; List<FaqCategory> get categories;// ── Questions ────────────────────────────────────────────────────────────
 RegionStatus get faqStatus; HelpFaqPage get faqs;/// The selected chip — a `FaqCategory.code`, or [kHelpAllTopics].
 String get topic;/// What is in the field **right now**. Moves on every keystroke.
 String get query;/// What the last request was made with. Trails [query] by
/// [kHelpSearchDebounce] — `useDebounced(query.trim(), 350)`.
 String get debouncedQuery; int get page;/// The one expanded question's id, or null — `:98`, `setOpen`.
 String? get openFaqId;// ── Guides ───────────────────────────────────────────────────────────────
 RegionStatus get guidesStatus; List<HelpArticle> get guides;/// The one expanded guide's slug, or null — `:99`, `setOpenGuide`.
 String? get openGuideSlug;/// The lazily-fetched body — `enabled: Boolean(openGuide)`.
 RegionStatus get guideStatus; HelpArticle? get guideBody;// ── Support channels ─────────────────────────────────────────────────────
 RegionStatus get channelsStatus; List<SupportChannel> get channels;// ── Feedback ─────────────────────────────────────────────────────────────
/// `voted` — `:100`. Question id → the vote cast this visit. Absent means
/// "not voted", which is what shows the two thumb controls.
 Map<String, bool> get votes;
/// Create a copy of HelpState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$HelpStateCopyWith<HelpState> get copyWith => _$HelpStateCopyWithImpl<HelpState>(this as HelpState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is HelpState&&(identical(other.categoriesStatus, categoriesStatus) || other.categoriesStatus == categoriesStatus)&&const DeepCollectionEquality().equals(other.categories, categories)&&(identical(other.faqStatus, faqStatus) || other.faqStatus == faqStatus)&&(identical(other.faqs, faqs) || other.faqs == faqs)&&(identical(other.topic, topic) || other.topic == topic)&&(identical(other.query, query) || other.query == query)&&(identical(other.debouncedQuery, debouncedQuery) || other.debouncedQuery == debouncedQuery)&&(identical(other.page, page) || other.page == page)&&(identical(other.openFaqId, openFaqId) || other.openFaqId == openFaqId)&&(identical(other.guidesStatus, guidesStatus) || other.guidesStatus == guidesStatus)&&const DeepCollectionEquality().equals(other.guides, guides)&&(identical(other.openGuideSlug, openGuideSlug) || other.openGuideSlug == openGuideSlug)&&(identical(other.guideStatus, guideStatus) || other.guideStatus == guideStatus)&&(identical(other.guideBody, guideBody) || other.guideBody == guideBody)&&(identical(other.channelsStatus, channelsStatus) || other.channelsStatus == channelsStatus)&&const DeepCollectionEquality().equals(other.channels, channels)&&const DeepCollectionEquality().equals(other.votes, votes));
}


@override
int get hashCode => Object.hash(runtimeType,categoriesStatus,const DeepCollectionEquality().hash(categories),faqStatus,faqs,topic,query,debouncedQuery,page,openFaqId,guidesStatus,const DeepCollectionEquality().hash(guides),openGuideSlug,guideStatus,guideBody,channelsStatus,const DeepCollectionEquality().hash(channels),const DeepCollectionEquality().hash(votes));

@override
String toString() {
  return 'HelpState(categoriesStatus: $categoriesStatus, categories: $categories, faqStatus: $faqStatus, faqs: $faqs, topic: $topic, query: $query, debouncedQuery: $debouncedQuery, page: $page, openFaqId: $openFaqId, guidesStatus: $guidesStatus, guides: $guides, openGuideSlug: $openGuideSlug, guideStatus: $guideStatus, guideBody: $guideBody, channelsStatus: $channelsStatus, channels: $channels, votes: $votes)';
}


}

/// @nodoc
abstract mixin class $HelpStateCopyWith<$Res>  {
  factory $HelpStateCopyWith(HelpState value, $Res Function(HelpState) _then) = _$HelpStateCopyWithImpl;
@useResult
$Res call({
 RegionStatus categoriesStatus, List<FaqCategory> categories, RegionStatus faqStatus, HelpFaqPage faqs, String topic, String query, String debouncedQuery, int page, String? openFaqId, RegionStatus guidesStatus, List<HelpArticle> guides, String? openGuideSlug, RegionStatus guideStatus, HelpArticle? guideBody, RegionStatus channelsStatus, List<SupportChannel> channels, Map<String, bool> votes
});


$HelpArticleCopyWith<$Res>? get guideBody;

}
/// @nodoc
class _$HelpStateCopyWithImpl<$Res>
    implements $HelpStateCopyWith<$Res> {
  _$HelpStateCopyWithImpl(this._self, this._then);

  final HelpState _self;
  final $Res Function(HelpState) _then;

/// Create a copy of HelpState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? categoriesStatus = null,Object? categories = null,Object? faqStatus = null,Object? faqs = null,Object? topic = null,Object? query = null,Object? debouncedQuery = null,Object? page = null,Object? openFaqId = freezed,Object? guidesStatus = null,Object? guides = null,Object? openGuideSlug = freezed,Object? guideStatus = null,Object? guideBody = freezed,Object? channelsStatus = null,Object? channels = null,Object? votes = null,}) {
  return _then(_self.copyWith(
categoriesStatus: null == categoriesStatus ? _self.categoriesStatus : categoriesStatus // ignore: cast_nullable_to_non_nullable
as RegionStatus,categories: null == categories ? _self.categories : categories // ignore: cast_nullable_to_non_nullable
as List<FaqCategory>,faqStatus: null == faqStatus ? _self.faqStatus : faqStatus // ignore: cast_nullable_to_non_nullable
as RegionStatus,faqs: null == faqs ? _self.faqs : faqs // ignore: cast_nullable_to_non_nullable
as HelpFaqPage,topic: null == topic ? _self.topic : topic // ignore: cast_nullable_to_non_nullable
as String,query: null == query ? _self.query : query // ignore: cast_nullable_to_non_nullable
as String,debouncedQuery: null == debouncedQuery ? _self.debouncedQuery : debouncedQuery // ignore: cast_nullable_to_non_nullable
as String,page: null == page ? _self.page : page // ignore: cast_nullable_to_non_nullable
as int,openFaqId: freezed == openFaqId ? _self.openFaqId : openFaqId // ignore: cast_nullable_to_non_nullable
as String?,guidesStatus: null == guidesStatus ? _self.guidesStatus : guidesStatus // ignore: cast_nullable_to_non_nullable
as RegionStatus,guides: null == guides ? _self.guides : guides // ignore: cast_nullable_to_non_nullable
as List<HelpArticle>,openGuideSlug: freezed == openGuideSlug ? _self.openGuideSlug : openGuideSlug // ignore: cast_nullable_to_non_nullable
as String?,guideStatus: null == guideStatus ? _self.guideStatus : guideStatus // ignore: cast_nullable_to_non_nullable
as RegionStatus,guideBody: freezed == guideBody ? _self.guideBody : guideBody // ignore: cast_nullable_to_non_nullable
as HelpArticle?,channelsStatus: null == channelsStatus ? _self.channelsStatus : channelsStatus // ignore: cast_nullable_to_non_nullable
as RegionStatus,channels: null == channels ? _self.channels : channels // ignore: cast_nullable_to_non_nullable
as List<SupportChannel>,votes: null == votes ? _self.votes : votes // ignore: cast_nullable_to_non_nullable
as Map<String, bool>,
  ));
}
/// Create a copy of HelpState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$HelpArticleCopyWith<$Res>? get guideBody {
    if (_self.guideBody == null) {
    return null;
  }

  return $HelpArticleCopyWith<$Res>(_self.guideBody!, (value) {
    return _then(_self.copyWith(guideBody: value));
  });
}
}


/// Adds pattern-matching-related methods to [HelpState].
extension HelpStatePatterns on HelpState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _HelpState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _HelpState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _HelpState value)  $default,){
final _that = this;
switch (_that) {
case _HelpState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _HelpState value)?  $default,){
final _that = this;
switch (_that) {
case _HelpState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( RegionStatus categoriesStatus,  List<FaqCategory> categories,  RegionStatus faqStatus,  HelpFaqPage faqs,  String topic,  String query,  String debouncedQuery,  int page,  String? openFaqId,  RegionStatus guidesStatus,  List<HelpArticle> guides,  String? openGuideSlug,  RegionStatus guideStatus,  HelpArticle? guideBody,  RegionStatus channelsStatus,  List<SupportChannel> channels,  Map<String, bool> votes)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _HelpState() when $default != null:
return $default(_that.categoriesStatus,_that.categories,_that.faqStatus,_that.faqs,_that.topic,_that.query,_that.debouncedQuery,_that.page,_that.openFaqId,_that.guidesStatus,_that.guides,_that.openGuideSlug,_that.guideStatus,_that.guideBody,_that.channelsStatus,_that.channels,_that.votes);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( RegionStatus categoriesStatus,  List<FaqCategory> categories,  RegionStatus faqStatus,  HelpFaqPage faqs,  String topic,  String query,  String debouncedQuery,  int page,  String? openFaqId,  RegionStatus guidesStatus,  List<HelpArticle> guides,  String? openGuideSlug,  RegionStatus guideStatus,  HelpArticle? guideBody,  RegionStatus channelsStatus,  List<SupportChannel> channels,  Map<String, bool> votes)  $default,) {final _that = this;
switch (_that) {
case _HelpState():
return $default(_that.categoriesStatus,_that.categories,_that.faqStatus,_that.faqs,_that.topic,_that.query,_that.debouncedQuery,_that.page,_that.openFaqId,_that.guidesStatus,_that.guides,_that.openGuideSlug,_that.guideStatus,_that.guideBody,_that.channelsStatus,_that.channels,_that.votes);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( RegionStatus categoriesStatus,  List<FaqCategory> categories,  RegionStatus faqStatus,  HelpFaqPage faqs,  String topic,  String query,  String debouncedQuery,  int page,  String? openFaqId,  RegionStatus guidesStatus,  List<HelpArticle> guides,  String? openGuideSlug,  RegionStatus guideStatus,  HelpArticle? guideBody,  RegionStatus channelsStatus,  List<SupportChannel> channels,  Map<String, bool> votes)?  $default,) {final _that = this;
switch (_that) {
case _HelpState() when $default != null:
return $default(_that.categoriesStatus,_that.categories,_that.faqStatus,_that.faqs,_that.topic,_that.query,_that.debouncedQuery,_that.page,_that.openFaqId,_that.guidesStatus,_that.guides,_that.openGuideSlug,_that.guideStatus,_that.guideBody,_that.channelsStatus,_that.channels,_that.votes);case _:
  return null;

}
}

}

/// @nodoc


class _HelpState extends HelpState {
  const _HelpState({this.categoriesStatus = RegionStatus.initial, final  List<FaqCategory> categories = const <FaqCategory>[], this.faqStatus = RegionStatus.initial, this.faqs = HelpFaqPage.empty, this.topic = kHelpAllTopics, this.query = '', this.debouncedQuery = '', this.page = 1, this.openFaqId, this.guidesStatus = RegionStatus.initial, final  List<HelpArticle> guides = const <HelpArticle>[], this.openGuideSlug, this.guideStatus = RegionStatus.initial, this.guideBody, this.channelsStatus = RegionStatus.initial, final  List<SupportChannel> channels = const <SupportChannel>[], final  Map<String, bool> votes = const <String, bool>{}}): _categories = categories,_guides = guides,_channels = channels,_votes = votes,super._();
  

// ── Topic chips ──────────────────────────────────────────────────────────
@override@JsonKey() final  RegionStatus categoriesStatus;
 final  List<FaqCategory> _categories;
@override@JsonKey() List<FaqCategory> get categories {
  if (_categories is EqualUnmodifiableListView) return _categories;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_categories);
}

// ── Questions ────────────────────────────────────────────────────────────
@override@JsonKey() final  RegionStatus faqStatus;
@override@JsonKey() final  HelpFaqPage faqs;
/// The selected chip — a `FaqCategory.code`, or [kHelpAllTopics].
@override@JsonKey() final  String topic;
/// What is in the field **right now**. Moves on every keystroke.
@override@JsonKey() final  String query;
/// What the last request was made with. Trails [query] by
/// [kHelpSearchDebounce] — `useDebounced(query.trim(), 350)`.
@override@JsonKey() final  String debouncedQuery;
@override@JsonKey() final  int page;
/// The one expanded question's id, or null — `:98`, `setOpen`.
@override final  String? openFaqId;
// ── Guides ───────────────────────────────────────────────────────────────
@override@JsonKey() final  RegionStatus guidesStatus;
 final  List<HelpArticle> _guides;
@override@JsonKey() List<HelpArticle> get guides {
  if (_guides is EqualUnmodifiableListView) return _guides;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_guides);
}

/// The one expanded guide's slug, or null — `:99`, `setOpenGuide`.
@override final  String? openGuideSlug;
/// The lazily-fetched body — `enabled: Boolean(openGuide)`.
@override@JsonKey() final  RegionStatus guideStatus;
@override final  HelpArticle? guideBody;
// ── Support channels ─────────────────────────────────────────────────────
@override@JsonKey() final  RegionStatus channelsStatus;
 final  List<SupportChannel> _channels;
@override@JsonKey() List<SupportChannel> get channels {
  if (_channels is EqualUnmodifiableListView) return _channels;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_channels);
}

// ── Feedback ─────────────────────────────────────────────────────────────
/// `voted` — `:100`. Question id → the vote cast this visit. Absent means
/// "not voted", which is what shows the two thumb controls.
 final  Map<String, bool> _votes;
// ── Feedback ─────────────────────────────────────────────────────────────
/// `voted` — `:100`. Question id → the vote cast this visit. Absent means
/// "not voted", which is what shows the two thumb controls.
@override@JsonKey() Map<String, bool> get votes {
  if (_votes is EqualUnmodifiableMapView) return _votes;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_votes);
}


/// Create a copy of HelpState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$HelpStateCopyWith<_HelpState> get copyWith => __$HelpStateCopyWithImpl<_HelpState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _HelpState&&(identical(other.categoriesStatus, categoriesStatus) || other.categoriesStatus == categoriesStatus)&&const DeepCollectionEquality().equals(other._categories, _categories)&&(identical(other.faqStatus, faqStatus) || other.faqStatus == faqStatus)&&(identical(other.faqs, faqs) || other.faqs == faqs)&&(identical(other.topic, topic) || other.topic == topic)&&(identical(other.query, query) || other.query == query)&&(identical(other.debouncedQuery, debouncedQuery) || other.debouncedQuery == debouncedQuery)&&(identical(other.page, page) || other.page == page)&&(identical(other.openFaqId, openFaqId) || other.openFaqId == openFaqId)&&(identical(other.guidesStatus, guidesStatus) || other.guidesStatus == guidesStatus)&&const DeepCollectionEquality().equals(other._guides, _guides)&&(identical(other.openGuideSlug, openGuideSlug) || other.openGuideSlug == openGuideSlug)&&(identical(other.guideStatus, guideStatus) || other.guideStatus == guideStatus)&&(identical(other.guideBody, guideBody) || other.guideBody == guideBody)&&(identical(other.channelsStatus, channelsStatus) || other.channelsStatus == channelsStatus)&&const DeepCollectionEquality().equals(other._channels, _channels)&&const DeepCollectionEquality().equals(other._votes, _votes));
}


@override
int get hashCode => Object.hash(runtimeType,categoriesStatus,const DeepCollectionEquality().hash(_categories),faqStatus,faqs,topic,query,debouncedQuery,page,openFaqId,guidesStatus,const DeepCollectionEquality().hash(_guides),openGuideSlug,guideStatus,guideBody,channelsStatus,const DeepCollectionEquality().hash(_channels),const DeepCollectionEquality().hash(_votes));

@override
String toString() {
  return 'HelpState(categoriesStatus: $categoriesStatus, categories: $categories, faqStatus: $faqStatus, faqs: $faqs, topic: $topic, query: $query, debouncedQuery: $debouncedQuery, page: $page, openFaqId: $openFaqId, guidesStatus: $guidesStatus, guides: $guides, openGuideSlug: $openGuideSlug, guideStatus: $guideStatus, guideBody: $guideBody, channelsStatus: $channelsStatus, channels: $channels, votes: $votes)';
}


}

/// @nodoc
abstract mixin class _$HelpStateCopyWith<$Res> implements $HelpStateCopyWith<$Res> {
  factory _$HelpStateCopyWith(_HelpState value, $Res Function(_HelpState) _then) = __$HelpStateCopyWithImpl;
@override @useResult
$Res call({
 RegionStatus categoriesStatus, List<FaqCategory> categories, RegionStatus faqStatus, HelpFaqPage faqs, String topic, String query, String debouncedQuery, int page, String? openFaqId, RegionStatus guidesStatus, List<HelpArticle> guides, String? openGuideSlug, RegionStatus guideStatus, HelpArticle? guideBody, RegionStatus channelsStatus, List<SupportChannel> channels, Map<String, bool> votes
});


@override $HelpArticleCopyWith<$Res>? get guideBody;

}
/// @nodoc
class __$HelpStateCopyWithImpl<$Res>
    implements _$HelpStateCopyWith<$Res> {
  __$HelpStateCopyWithImpl(this._self, this._then);

  final _HelpState _self;
  final $Res Function(_HelpState) _then;

/// Create a copy of HelpState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? categoriesStatus = null,Object? categories = null,Object? faqStatus = null,Object? faqs = null,Object? topic = null,Object? query = null,Object? debouncedQuery = null,Object? page = null,Object? openFaqId = freezed,Object? guidesStatus = null,Object? guides = null,Object? openGuideSlug = freezed,Object? guideStatus = null,Object? guideBody = freezed,Object? channelsStatus = null,Object? channels = null,Object? votes = null,}) {
  return _then(_HelpState(
categoriesStatus: null == categoriesStatus ? _self.categoriesStatus : categoriesStatus // ignore: cast_nullable_to_non_nullable
as RegionStatus,categories: null == categories ? _self._categories : categories // ignore: cast_nullable_to_non_nullable
as List<FaqCategory>,faqStatus: null == faqStatus ? _self.faqStatus : faqStatus // ignore: cast_nullable_to_non_nullable
as RegionStatus,faqs: null == faqs ? _self.faqs : faqs // ignore: cast_nullable_to_non_nullable
as HelpFaqPage,topic: null == topic ? _self.topic : topic // ignore: cast_nullable_to_non_nullable
as String,query: null == query ? _self.query : query // ignore: cast_nullable_to_non_nullable
as String,debouncedQuery: null == debouncedQuery ? _self.debouncedQuery : debouncedQuery // ignore: cast_nullable_to_non_nullable
as String,page: null == page ? _self.page : page // ignore: cast_nullable_to_non_nullable
as int,openFaqId: freezed == openFaqId ? _self.openFaqId : openFaqId // ignore: cast_nullable_to_non_nullable
as String?,guidesStatus: null == guidesStatus ? _self.guidesStatus : guidesStatus // ignore: cast_nullable_to_non_nullable
as RegionStatus,guides: null == guides ? _self._guides : guides // ignore: cast_nullable_to_non_nullable
as List<HelpArticle>,openGuideSlug: freezed == openGuideSlug ? _self.openGuideSlug : openGuideSlug // ignore: cast_nullable_to_non_nullable
as String?,guideStatus: null == guideStatus ? _self.guideStatus : guideStatus // ignore: cast_nullable_to_non_nullable
as RegionStatus,guideBody: freezed == guideBody ? _self.guideBody : guideBody // ignore: cast_nullable_to_non_nullable
as HelpArticle?,channelsStatus: null == channelsStatus ? _self.channelsStatus : channelsStatus // ignore: cast_nullable_to_non_nullable
as RegionStatus,channels: null == channels ? _self._channels : channels // ignore: cast_nullable_to_non_nullable
as List<SupportChannel>,votes: null == votes ? _self._votes : votes // ignore: cast_nullable_to_non_nullable
as Map<String, bool>,
  ));
}

/// Create a copy of HelpState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$HelpArticleCopyWith<$Res>? get guideBody {
    if (_self.guideBody == null) {
    return null;
  }

  return $HelpArticleCopyWith<$Res>(_self.guideBody!, (value) {
    return _then(_self.copyWith(guideBody: value));
  });
}
}

// dart format on
