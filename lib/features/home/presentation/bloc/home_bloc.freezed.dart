// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'home_bloc.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$HomeState {

/// Mirrors the `isAuthenticated` prop. The two `me.*` queries are enabled
/// by it and the hero card switches between the specimen and the citizen's
/// own record on it.
 bool get isAuthenticated;// ── /me/home-summary ────────────────────────────────────────────────────
 RegionStatus get summaryStatus; HomeSummary? get summary;// ── /me/digital-id ──────────────────────────────────────────────────────
 RegionStatus get digitalIdStatus; DigitalIdCard? get digitalId;// ── /services?phase1=true ───────────────────────────────────────────────
 RegionStatus get servicesStatus; List<Service> get quickActions;// ── /services?search= ───────────────────────────────────────────────────
 RegionStatus get searchStatus; List<Service> get searchResults;/// Exactly what is in the search field, untrimmed — the field shows what
/// was typed.
 String get searchQuery;/// The trimmed query the last request used. Lags [searchQuery] by up to
/// [kHomeSearchDebounce].
 String get debouncedQuery;// ── /news?per_page=3&featured=true ──────────────────────────────────────
 RegionStatus get newsStatus; List<HomeNewsItem> get news;// ── /help/faqs?per_page=5 ───────────────────────────────────────────────
 RegionStatus get faqStatus; List<HomeFaqItem> get faqs;/// `useState<number | null>(0)` — `HomePage.tsx:207`. The **first question
/// is open on arrival**; tapping it closes it and tapping another moves the
/// open one. Null means all closed.
 int? get openFaqIndex;/// `showBanner` — `HomePage.tsx:148`. False once the citizen confirms the
/// dismissal. Per-visit, like the source's `useState`: the web does not
/// persist it either, so a reload brings the banner back.
 bool get bannerVisible;
/// Create a copy of HomeState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$HomeStateCopyWith<HomeState> get copyWith => _$HomeStateCopyWithImpl<HomeState>(this as HomeState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is HomeState&&(identical(other.isAuthenticated, isAuthenticated) || other.isAuthenticated == isAuthenticated)&&(identical(other.summaryStatus, summaryStatus) || other.summaryStatus == summaryStatus)&&(identical(other.summary, summary) || other.summary == summary)&&(identical(other.digitalIdStatus, digitalIdStatus) || other.digitalIdStatus == digitalIdStatus)&&(identical(other.digitalId, digitalId) || other.digitalId == digitalId)&&(identical(other.servicesStatus, servicesStatus) || other.servicesStatus == servicesStatus)&&const DeepCollectionEquality().equals(other.quickActions, quickActions)&&(identical(other.searchStatus, searchStatus) || other.searchStatus == searchStatus)&&const DeepCollectionEquality().equals(other.searchResults, searchResults)&&(identical(other.searchQuery, searchQuery) || other.searchQuery == searchQuery)&&(identical(other.debouncedQuery, debouncedQuery) || other.debouncedQuery == debouncedQuery)&&(identical(other.newsStatus, newsStatus) || other.newsStatus == newsStatus)&&const DeepCollectionEquality().equals(other.news, news)&&(identical(other.faqStatus, faqStatus) || other.faqStatus == faqStatus)&&const DeepCollectionEquality().equals(other.faqs, faqs)&&(identical(other.openFaqIndex, openFaqIndex) || other.openFaqIndex == openFaqIndex)&&(identical(other.bannerVisible, bannerVisible) || other.bannerVisible == bannerVisible));
}


@override
int get hashCode => Object.hash(runtimeType,isAuthenticated,summaryStatus,summary,digitalIdStatus,digitalId,servicesStatus,const DeepCollectionEquality().hash(quickActions),searchStatus,const DeepCollectionEquality().hash(searchResults),searchQuery,debouncedQuery,newsStatus,const DeepCollectionEquality().hash(news),faqStatus,const DeepCollectionEquality().hash(faqs),openFaqIndex,bannerVisible);

@override
String toString() {
  return 'HomeState(isAuthenticated: $isAuthenticated, summaryStatus: $summaryStatus, summary: $summary, digitalIdStatus: $digitalIdStatus, digitalId: $digitalId, servicesStatus: $servicesStatus, quickActions: $quickActions, searchStatus: $searchStatus, searchResults: $searchResults, searchQuery: $searchQuery, debouncedQuery: $debouncedQuery, newsStatus: $newsStatus, news: $news, faqStatus: $faqStatus, faqs: $faqs, openFaqIndex: $openFaqIndex, bannerVisible: $bannerVisible)';
}


}

/// @nodoc
abstract mixin class $HomeStateCopyWith<$Res>  {
  factory $HomeStateCopyWith(HomeState value, $Res Function(HomeState) _then) = _$HomeStateCopyWithImpl;
@useResult
$Res call({
 bool isAuthenticated, RegionStatus summaryStatus, HomeSummary? summary, RegionStatus digitalIdStatus, DigitalIdCard? digitalId, RegionStatus servicesStatus, List<Service> quickActions, RegionStatus searchStatus, List<Service> searchResults, String searchQuery, String debouncedQuery, RegionStatus newsStatus, List<HomeNewsItem> news, RegionStatus faqStatus, List<HomeFaqItem> faqs, int? openFaqIndex, bool bannerVisible
});


$HomeSummaryCopyWith<$Res>? get summary;$DigitalIdCardCopyWith<$Res>? get digitalId;

}
/// @nodoc
class _$HomeStateCopyWithImpl<$Res>
    implements $HomeStateCopyWith<$Res> {
  _$HomeStateCopyWithImpl(this._self, this._then);

  final HomeState _self;
  final $Res Function(HomeState) _then;

/// Create a copy of HomeState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? isAuthenticated = null,Object? summaryStatus = null,Object? summary = freezed,Object? digitalIdStatus = null,Object? digitalId = freezed,Object? servicesStatus = null,Object? quickActions = null,Object? searchStatus = null,Object? searchResults = null,Object? searchQuery = null,Object? debouncedQuery = null,Object? newsStatus = null,Object? news = null,Object? faqStatus = null,Object? faqs = null,Object? openFaqIndex = freezed,Object? bannerVisible = null,}) {
  return _then(_self.copyWith(
isAuthenticated: null == isAuthenticated ? _self.isAuthenticated : isAuthenticated // ignore: cast_nullable_to_non_nullable
as bool,summaryStatus: null == summaryStatus ? _self.summaryStatus : summaryStatus // ignore: cast_nullable_to_non_nullable
as RegionStatus,summary: freezed == summary ? _self.summary : summary // ignore: cast_nullable_to_non_nullable
as HomeSummary?,digitalIdStatus: null == digitalIdStatus ? _self.digitalIdStatus : digitalIdStatus // ignore: cast_nullable_to_non_nullable
as RegionStatus,digitalId: freezed == digitalId ? _self.digitalId : digitalId // ignore: cast_nullable_to_non_nullable
as DigitalIdCard?,servicesStatus: null == servicesStatus ? _self.servicesStatus : servicesStatus // ignore: cast_nullable_to_non_nullable
as RegionStatus,quickActions: null == quickActions ? _self.quickActions : quickActions // ignore: cast_nullable_to_non_nullable
as List<Service>,searchStatus: null == searchStatus ? _self.searchStatus : searchStatus // ignore: cast_nullable_to_non_nullable
as RegionStatus,searchResults: null == searchResults ? _self.searchResults : searchResults // ignore: cast_nullable_to_non_nullable
as List<Service>,searchQuery: null == searchQuery ? _self.searchQuery : searchQuery // ignore: cast_nullable_to_non_nullable
as String,debouncedQuery: null == debouncedQuery ? _self.debouncedQuery : debouncedQuery // ignore: cast_nullable_to_non_nullable
as String,newsStatus: null == newsStatus ? _self.newsStatus : newsStatus // ignore: cast_nullable_to_non_nullable
as RegionStatus,news: null == news ? _self.news : news // ignore: cast_nullable_to_non_nullable
as List<HomeNewsItem>,faqStatus: null == faqStatus ? _self.faqStatus : faqStatus // ignore: cast_nullable_to_non_nullable
as RegionStatus,faqs: null == faqs ? _self.faqs : faqs // ignore: cast_nullable_to_non_nullable
as List<HomeFaqItem>,openFaqIndex: freezed == openFaqIndex ? _self.openFaqIndex : openFaqIndex // ignore: cast_nullable_to_non_nullable
as int?,bannerVisible: null == bannerVisible ? _self.bannerVisible : bannerVisible // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}
/// Create a copy of HomeState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$HomeSummaryCopyWith<$Res>? get summary {
    if (_self.summary == null) {
    return null;
  }

  return $HomeSummaryCopyWith<$Res>(_self.summary!, (value) {
    return _then(_self.copyWith(summary: value));
  });
}/// Create a copy of HomeState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$DigitalIdCardCopyWith<$Res>? get digitalId {
    if (_self.digitalId == null) {
    return null;
  }

  return $DigitalIdCardCopyWith<$Res>(_self.digitalId!, (value) {
    return _then(_self.copyWith(digitalId: value));
  });
}
}


/// Adds pattern-matching-related methods to [HomeState].
extension HomeStatePatterns on HomeState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _HomeState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _HomeState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _HomeState value)  $default,){
final _that = this;
switch (_that) {
case _HomeState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _HomeState value)?  $default,){
final _that = this;
switch (_that) {
case _HomeState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( bool isAuthenticated,  RegionStatus summaryStatus,  HomeSummary? summary,  RegionStatus digitalIdStatus,  DigitalIdCard? digitalId,  RegionStatus servicesStatus,  List<Service> quickActions,  RegionStatus searchStatus,  List<Service> searchResults,  String searchQuery,  String debouncedQuery,  RegionStatus newsStatus,  List<HomeNewsItem> news,  RegionStatus faqStatus,  List<HomeFaqItem> faqs,  int? openFaqIndex,  bool bannerVisible)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _HomeState() when $default != null:
return $default(_that.isAuthenticated,_that.summaryStatus,_that.summary,_that.digitalIdStatus,_that.digitalId,_that.servicesStatus,_that.quickActions,_that.searchStatus,_that.searchResults,_that.searchQuery,_that.debouncedQuery,_that.newsStatus,_that.news,_that.faqStatus,_that.faqs,_that.openFaqIndex,_that.bannerVisible);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( bool isAuthenticated,  RegionStatus summaryStatus,  HomeSummary? summary,  RegionStatus digitalIdStatus,  DigitalIdCard? digitalId,  RegionStatus servicesStatus,  List<Service> quickActions,  RegionStatus searchStatus,  List<Service> searchResults,  String searchQuery,  String debouncedQuery,  RegionStatus newsStatus,  List<HomeNewsItem> news,  RegionStatus faqStatus,  List<HomeFaqItem> faqs,  int? openFaqIndex,  bool bannerVisible)  $default,) {final _that = this;
switch (_that) {
case _HomeState():
return $default(_that.isAuthenticated,_that.summaryStatus,_that.summary,_that.digitalIdStatus,_that.digitalId,_that.servicesStatus,_that.quickActions,_that.searchStatus,_that.searchResults,_that.searchQuery,_that.debouncedQuery,_that.newsStatus,_that.news,_that.faqStatus,_that.faqs,_that.openFaqIndex,_that.bannerVisible);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( bool isAuthenticated,  RegionStatus summaryStatus,  HomeSummary? summary,  RegionStatus digitalIdStatus,  DigitalIdCard? digitalId,  RegionStatus servicesStatus,  List<Service> quickActions,  RegionStatus searchStatus,  List<Service> searchResults,  String searchQuery,  String debouncedQuery,  RegionStatus newsStatus,  List<HomeNewsItem> news,  RegionStatus faqStatus,  List<HomeFaqItem> faqs,  int? openFaqIndex,  bool bannerVisible)?  $default,) {final _that = this;
switch (_that) {
case _HomeState() when $default != null:
return $default(_that.isAuthenticated,_that.summaryStatus,_that.summary,_that.digitalIdStatus,_that.digitalId,_that.servicesStatus,_that.quickActions,_that.searchStatus,_that.searchResults,_that.searchQuery,_that.debouncedQuery,_that.newsStatus,_that.news,_that.faqStatus,_that.faqs,_that.openFaqIndex,_that.bannerVisible);case _:
  return null;

}
}

}

/// @nodoc


class _HomeState extends HomeState {
  const _HomeState({this.isAuthenticated = false, this.summaryStatus = RegionStatus.initial, this.summary, this.digitalIdStatus = RegionStatus.initial, this.digitalId, this.servicesStatus = RegionStatus.initial, final  List<Service> quickActions = const <Service>[], this.searchStatus = RegionStatus.initial, final  List<Service> searchResults = const <Service>[], this.searchQuery = '', this.debouncedQuery = '', this.newsStatus = RegionStatus.initial, final  List<HomeNewsItem> news = const <HomeNewsItem>[], this.faqStatus = RegionStatus.initial, final  List<HomeFaqItem> faqs = const <HomeFaqItem>[], this.openFaqIndex = 0, this.bannerVisible = true}): _quickActions = quickActions,_searchResults = searchResults,_news = news,_faqs = faqs,super._();
  

/// Mirrors the `isAuthenticated` prop. The two `me.*` queries are enabled
/// by it and the hero card switches between the specimen and the citizen's
/// own record on it.
@override@JsonKey() final  bool isAuthenticated;
// ── /me/home-summary ────────────────────────────────────────────────────
@override@JsonKey() final  RegionStatus summaryStatus;
@override final  HomeSummary? summary;
// ── /me/digital-id ──────────────────────────────────────────────────────
@override@JsonKey() final  RegionStatus digitalIdStatus;
@override final  DigitalIdCard? digitalId;
// ── /services?phase1=true ───────────────────────────────────────────────
@override@JsonKey() final  RegionStatus servicesStatus;
 final  List<Service> _quickActions;
@override@JsonKey() List<Service> get quickActions {
  if (_quickActions is EqualUnmodifiableListView) return _quickActions;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_quickActions);
}

// ── /services?search= ───────────────────────────────────────────────────
@override@JsonKey() final  RegionStatus searchStatus;
 final  List<Service> _searchResults;
@override@JsonKey() List<Service> get searchResults {
  if (_searchResults is EqualUnmodifiableListView) return _searchResults;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_searchResults);
}

/// Exactly what is in the search field, untrimmed — the field shows what
/// was typed.
@override@JsonKey() final  String searchQuery;
/// The trimmed query the last request used. Lags [searchQuery] by up to
/// [kHomeSearchDebounce].
@override@JsonKey() final  String debouncedQuery;
// ── /news?per_page=3&featured=true ──────────────────────────────────────
@override@JsonKey() final  RegionStatus newsStatus;
 final  List<HomeNewsItem> _news;
@override@JsonKey() List<HomeNewsItem> get news {
  if (_news is EqualUnmodifiableListView) return _news;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_news);
}

// ── /help/faqs?per_page=5 ───────────────────────────────────────────────
@override@JsonKey() final  RegionStatus faqStatus;
 final  List<HomeFaqItem> _faqs;
@override@JsonKey() List<HomeFaqItem> get faqs {
  if (_faqs is EqualUnmodifiableListView) return _faqs;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_faqs);
}

/// `useState<number | null>(0)` — `HomePage.tsx:207`. The **first question
/// is open on arrival**; tapping it closes it and tapping another moves the
/// open one. Null means all closed.
@override@JsonKey() final  int? openFaqIndex;
/// `showBanner` — `HomePage.tsx:148`. False once the citizen confirms the
/// dismissal. Per-visit, like the source's `useState`: the web does not
/// persist it either, so a reload brings the banner back.
@override@JsonKey() final  bool bannerVisible;

/// Create a copy of HomeState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$HomeStateCopyWith<_HomeState> get copyWith => __$HomeStateCopyWithImpl<_HomeState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _HomeState&&(identical(other.isAuthenticated, isAuthenticated) || other.isAuthenticated == isAuthenticated)&&(identical(other.summaryStatus, summaryStatus) || other.summaryStatus == summaryStatus)&&(identical(other.summary, summary) || other.summary == summary)&&(identical(other.digitalIdStatus, digitalIdStatus) || other.digitalIdStatus == digitalIdStatus)&&(identical(other.digitalId, digitalId) || other.digitalId == digitalId)&&(identical(other.servicesStatus, servicesStatus) || other.servicesStatus == servicesStatus)&&const DeepCollectionEquality().equals(other._quickActions, _quickActions)&&(identical(other.searchStatus, searchStatus) || other.searchStatus == searchStatus)&&const DeepCollectionEquality().equals(other._searchResults, _searchResults)&&(identical(other.searchQuery, searchQuery) || other.searchQuery == searchQuery)&&(identical(other.debouncedQuery, debouncedQuery) || other.debouncedQuery == debouncedQuery)&&(identical(other.newsStatus, newsStatus) || other.newsStatus == newsStatus)&&const DeepCollectionEquality().equals(other._news, _news)&&(identical(other.faqStatus, faqStatus) || other.faqStatus == faqStatus)&&const DeepCollectionEquality().equals(other._faqs, _faqs)&&(identical(other.openFaqIndex, openFaqIndex) || other.openFaqIndex == openFaqIndex)&&(identical(other.bannerVisible, bannerVisible) || other.bannerVisible == bannerVisible));
}


@override
int get hashCode => Object.hash(runtimeType,isAuthenticated,summaryStatus,summary,digitalIdStatus,digitalId,servicesStatus,const DeepCollectionEquality().hash(_quickActions),searchStatus,const DeepCollectionEquality().hash(_searchResults),searchQuery,debouncedQuery,newsStatus,const DeepCollectionEquality().hash(_news),faqStatus,const DeepCollectionEquality().hash(_faqs),openFaqIndex,bannerVisible);

@override
String toString() {
  return 'HomeState(isAuthenticated: $isAuthenticated, summaryStatus: $summaryStatus, summary: $summary, digitalIdStatus: $digitalIdStatus, digitalId: $digitalId, servicesStatus: $servicesStatus, quickActions: $quickActions, searchStatus: $searchStatus, searchResults: $searchResults, searchQuery: $searchQuery, debouncedQuery: $debouncedQuery, newsStatus: $newsStatus, news: $news, faqStatus: $faqStatus, faqs: $faqs, openFaqIndex: $openFaqIndex, bannerVisible: $bannerVisible)';
}


}

/// @nodoc
abstract mixin class _$HomeStateCopyWith<$Res> implements $HomeStateCopyWith<$Res> {
  factory _$HomeStateCopyWith(_HomeState value, $Res Function(_HomeState) _then) = __$HomeStateCopyWithImpl;
@override @useResult
$Res call({
 bool isAuthenticated, RegionStatus summaryStatus, HomeSummary? summary, RegionStatus digitalIdStatus, DigitalIdCard? digitalId, RegionStatus servicesStatus, List<Service> quickActions, RegionStatus searchStatus, List<Service> searchResults, String searchQuery, String debouncedQuery, RegionStatus newsStatus, List<HomeNewsItem> news, RegionStatus faqStatus, List<HomeFaqItem> faqs, int? openFaqIndex, bool bannerVisible
});


@override $HomeSummaryCopyWith<$Res>? get summary;@override $DigitalIdCardCopyWith<$Res>? get digitalId;

}
/// @nodoc
class __$HomeStateCopyWithImpl<$Res>
    implements _$HomeStateCopyWith<$Res> {
  __$HomeStateCopyWithImpl(this._self, this._then);

  final _HomeState _self;
  final $Res Function(_HomeState) _then;

/// Create a copy of HomeState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? isAuthenticated = null,Object? summaryStatus = null,Object? summary = freezed,Object? digitalIdStatus = null,Object? digitalId = freezed,Object? servicesStatus = null,Object? quickActions = null,Object? searchStatus = null,Object? searchResults = null,Object? searchQuery = null,Object? debouncedQuery = null,Object? newsStatus = null,Object? news = null,Object? faqStatus = null,Object? faqs = null,Object? openFaqIndex = freezed,Object? bannerVisible = null,}) {
  return _then(_HomeState(
isAuthenticated: null == isAuthenticated ? _self.isAuthenticated : isAuthenticated // ignore: cast_nullable_to_non_nullable
as bool,summaryStatus: null == summaryStatus ? _self.summaryStatus : summaryStatus // ignore: cast_nullable_to_non_nullable
as RegionStatus,summary: freezed == summary ? _self.summary : summary // ignore: cast_nullable_to_non_nullable
as HomeSummary?,digitalIdStatus: null == digitalIdStatus ? _self.digitalIdStatus : digitalIdStatus // ignore: cast_nullable_to_non_nullable
as RegionStatus,digitalId: freezed == digitalId ? _self.digitalId : digitalId // ignore: cast_nullable_to_non_nullable
as DigitalIdCard?,servicesStatus: null == servicesStatus ? _self.servicesStatus : servicesStatus // ignore: cast_nullable_to_non_nullable
as RegionStatus,quickActions: null == quickActions ? _self._quickActions : quickActions // ignore: cast_nullable_to_non_nullable
as List<Service>,searchStatus: null == searchStatus ? _self.searchStatus : searchStatus // ignore: cast_nullable_to_non_nullable
as RegionStatus,searchResults: null == searchResults ? _self._searchResults : searchResults // ignore: cast_nullable_to_non_nullable
as List<Service>,searchQuery: null == searchQuery ? _self.searchQuery : searchQuery // ignore: cast_nullable_to_non_nullable
as String,debouncedQuery: null == debouncedQuery ? _self.debouncedQuery : debouncedQuery // ignore: cast_nullable_to_non_nullable
as String,newsStatus: null == newsStatus ? _self.newsStatus : newsStatus // ignore: cast_nullable_to_non_nullable
as RegionStatus,news: null == news ? _self._news : news // ignore: cast_nullable_to_non_nullable
as List<HomeNewsItem>,faqStatus: null == faqStatus ? _self.faqStatus : faqStatus // ignore: cast_nullable_to_non_nullable
as RegionStatus,faqs: null == faqs ? _self._faqs : faqs // ignore: cast_nullable_to_non_nullable
as List<HomeFaqItem>,openFaqIndex: freezed == openFaqIndex ? _self.openFaqIndex : openFaqIndex // ignore: cast_nullable_to_non_nullable
as int?,bannerVisible: null == bannerVisible ? _self.bannerVisible : bannerVisible // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

/// Create a copy of HomeState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$HomeSummaryCopyWith<$Res>? get summary {
    if (_self.summary == null) {
    return null;
  }

  return $HomeSummaryCopyWith<$Res>(_self.summary!, (value) {
    return _then(_self.copyWith(summary: value));
  });
}/// Create a copy of HomeState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$DigitalIdCardCopyWith<$Res>? get digitalId {
    if (_self.digitalId == null) {
    return null;
  }

  return $DigitalIdCardCopyWith<$Res>(_self.digitalId!, (value) {
    return _then(_self.copyWith(digitalId: value));
  });
}
}

// dart format on
