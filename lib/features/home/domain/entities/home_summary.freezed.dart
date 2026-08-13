// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'home_summary.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$HomeNextAction {

 String get action; Bilingual? get label;/// The tab the banner's "Update document" link goes to. The source
/// defaults it at the call site (`tab ?? "history"`,
/// `HomePage.tsx:409`), so the empty string here means "the source's
/// default applies", not "nowhere".
 String get tab; String get applicationId; String get referenceNo; String get status;
/// Create a copy of HomeNextAction
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$HomeNextActionCopyWith<HomeNextAction> get copyWith => _$HomeNextActionCopyWithImpl<HomeNextAction>(this as HomeNextAction, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is HomeNextAction&&(identical(other.action, action) || other.action == action)&&(identical(other.label, label) || other.label == label)&&(identical(other.tab, tab) || other.tab == tab)&&(identical(other.applicationId, applicationId) || other.applicationId == applicationId)&&(identical(other.referenceNo, referenceNo) || other.referenceNo == referenceNo)&&(identical(other.status, status) || other.status == status));
}


@override
int get hashCode => Object.hash(runtimeType,action,label,tab,applicationId,referenceNo,status);

@override
String toString() {
  return 'HomeNextAction(action: $action, label: $label, tab: $tab, applicationId: $applicationId, referenceNo: $referenceNo, status: $status)';
}


}

/// @nodoc
abstract mixin class $HomeNextActionCopyWith<$Res>  {
  factory $HomeNextActionCopyWith(HomeNextAction value, $Res Function(HomeNextAction) _then) = _$HomeNextActionCopyWithImpl;
@useResult
$Res call({
 String action, Bilingual? label, String tab, String applicationId, String referenceNo, String status
});


$BilingualCopyWith<$Res>? get label;

}
/// @nodoc
class _$HomeNextActionCopyWithImpl<$Res>
    implements $HomeNextActionCopyWith<$Res> {
  _$HomeNextActionCopyWithImpl(this._self, this._then);

  final HomeNextAction _self;
  final $Res Function(HomeNextAction) _then;

/// Create a copy of HomeNextAction
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? action = null,Object? label = freezed,Object? tab = null,Object? applicationId = null,Object? referenceNo = null,Object? status = null,}) {
  return _then(_self.copyWith(
action: null == action ? _self.action : action // ignore: cast_nullable_to_non_nullable
as String,label: freezed == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as Bilingual?,tab: null == tab ? _self.tab : tab // ignore: cast_nullable_to_non_nullable
as String,applicationId: null == applicationId ? _self.applicationId : applicationId // ignore: cast_nullable_to_non_nullable
as String,referenceNo: null == referenceNo ? _self.referenceNo : referenceNo // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,
  ));
}
/// Create a copy of HomeNextAction
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BilingualCopyWith<$Res>? get label {
    if (_self.label == null) {
    return null;
  }

  return $BilingualCopyWith<$Res>(_self.label!, (value) {
    return _then(_self.copyWith(label: value));
  });
}
}


/// Adds pattern-matching-related methods to [HomeNextAction].
extension HomeNextActionPatterns on HomeNextAction {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _HomeNextAction value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _HomeNextAction() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _HomeNextAction value)  $default,){
final _that = this;
switch (_that) {
case _HomeNextAction():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _HomeNextAction value)?  $default,){
final _that = this;
switch (_that) {
case _HomeNextAction() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String action,  Bilingual? label,  String tab,  String applicationId,  String referenceNo,  String status)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _HomeNextAction() when $default != null:
return $default(_that.action,_that.label,_that.tab,_that.applicationId,_that.referenceNo,_that.status);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String action,  Bilingual? label,  String tab,  String applicationId,  String referenceNo,  String status)  $default,) {final _that = this;
switch (_that) {
case _HomeNextAction():
return $default(_that.action,_that.label,_that.tab,_that.applicationId,_that.referenceNo,_that.status);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String action,  Bilingual? label,  String tab,  String applicationId,  String referenceNo,  String status)?  $default,) {final _that = this;
switch (_that) {
case _HomeNextAction() when $default != null:
return $default(_that.action,_that.label,_that.tab,_that.applicationId,_that.referenceNo,_that.status);case _:
  return null;

}
}

}

/// @nodoc


class _HomeNextAction implements HomeNextAction {
  const _HomeNextAction({this.action = '', this.label, this.tab = '', this.applicationId = '', this.referenceNo = '', this.status = ''});
  

@override@JsonKey() final  String action;
@override final  Bilingual? label;
/// The tab the banner's "Update document" link goes to. The source
/// defaults it at the call site (`tab ?? "history"`,
/// `HomePage.tsx:409`), so the empty string here means "the source's
/// default applies", not "nowhere".
@override@JsonKey() final  String tab;
@override@JsonKey() final  String applicationId;
@override@JsonKey() final  String referenceNo;
@override@JsonKey() final  String status;

/// Create a copy of HomeNextAction
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$HomeNextActionCopyWith<_HomeNextAction> get copyWith => __$HomeNextActionCopyWithImpl<_HomeNextAction>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _HomeNextAction&&(identical(other.action, action) || other.action == action)&&(identical(other.label, label) || other.label == label)&&(identical(other.tab, tab) || other.tab == tab)&&(identical(other.applicationId, applicationId) || other.applicationId == applicationId)&&(identical(other.referenceNo, referenceNo) || other.referenceNo == referenceNo)&&(identical(other.status, status) || other.status == status));
}


@override
int get hashCode => Object.hash(runtimeType,action,label,tab,applicationId,referenceNo,status);

@override
String toString() {
  return 'HomeNextAction(action: $action, label: $label, tab: $tab, applicationId: $applicationId, referenceNo: $referenceNo, status: $status)';
}


}

/// @nodoc
abstract mixin class _$HomeNextActionCopyWith<$Res> implements $HomeNextActionCopyWith<$Res> {
  factory _$HomeNextActionCopyWith(_HomeNextAction value, $Res Function(_HomeNextAction) _then) = __$HomeNextActionCopyWithImpl;
@override @useResult
$Res call({
 String action, Bilingual? label, String tab, String applicationId, String referenceNo, String status
});


@override $BilingualCopyWith<$Res>? get label;

}
/// @nodoc
class __$HomeNextActionCopyWithImpl<$Res>
    implements _$HomeNextActionCopyWith<$Res> {
  __$HomeNextActionCopyWithImpl(this._self, this._then);

  final _HomeNextAction _self;
  final $Res Function(_HomeNextAction) _then;

/// Create a copy of HomeNextAction
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? action = null,Object? label = freezed,Object? tab = null,Object? applicationId = null,Object? referenceNo = null,Object? status = null,}) {
  return _then(_HomeNextAction(
action: null == action ? _self.action : action // ignore: cast_nullable_to_non_nullable
as String,label: freezed == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as Bilingual?,tab: null == tab ? _self.tab : tab // ignore: cast_nullable_to_non_nullable
as String,applicationId: null == applicationId ? _self.applicationId : applicationId // ignore: cast_nullable_to_non_nullable
as String,referenceNo: null == referenceNo ? _self.referenceNo : referenceNo // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

/// Create a copy of HomeNextAction
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BilingualCopyWith<$Res>? get label {
    if (_self.label == null) {
    return null;
  }

  return $BilingualCopyWith<$Res>(_self.label!, (value) {
    return _then(_self.copyWith(label: value));
  });
}
}

/// @nodoc
mixin _$HomeSummary {

/// The citizen's display name. The hero prints it beside the greeting
/// (`HomePage.tsx:279`).
 String get name; bool get verified; bool get eidVerified; int get activeApplications; int get readyDocuments; int get unreadNotifications; int get walletBalanceLak;/// Null when nothing is pending — which is the common case and is why the
/// banner is conditional rather than empty.
 HomeNextAction? get nextAction; String get generatedAt;
/// Create a copy of HomeSummary
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$HomeSummaryCopyWith<HomeSummary> get copyWith => _$HomeSummaryCopyWithImpl<HomeSummary>(this as HomeSummary, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is HomeSummary&&(identical(other.name, name) || other.name == name)&&(identical(other.verified, verified) || other.verified == verified)&&(identical(other.eidVerified, eidVerified) || other.eidVerified == eidVerified)&&(identical(other.activeApplications, activeApplications) || other.activeApplications == activeApplications)&&(identical(other.readyDocuments, readyDocuments) || other.readyDocuments == readyDocuments)&&(identical(other.unreadNotifications, unreadNotifications) || other.unreadNotifications == unreadNotifications)&&(identical(other.walletBalanceLak, walletBalanceLak) || other.walletBalanceLak == walletBalanceLak)&&(identical(other.nextAction, nextAction) || other.nextAction == nextAction)&&(identical(other.generatedAt, generatedAt) || other.generatedAt == generatedAt));
}


@override
int get hashCode => Object.hash(runtimeType,name,verified,eidVerified,activeApplications,readyDocuments,unreadNotifications,walletBalanceLak,nextAction,generatedAt);

@override
String toString() {
  return 'HomeSummary(name: $name, verified: $verified, eidVerified: $eidVerified, activeApplications: $activeApplications, readyDocuments: $readyDocuments, unreadNotifications: $unreadNotifications, walletBalanceLak: $walletBalanceLak, nextAction: $nextAction, generatedAt: $generatedAt)';
}


}

/// @nodoc
abstract mixin class $HomeSummaryCopyWith<$Res>  {
  factory $HomeSummaryCopyWith(HomeSummary value, $Res Function(HomeSummary) _then) = _$HomeSummaryCopyWithImpl;
@useResult
$Res call({
 String name, bool verified, bool eidVerified, int activeApplications, int readyDocuments, int unreadNotifications, int walletBalanceLak, HomeNextAction? nextAction, String generatedAt
});


$HomeNextActionCopyWith<$Res>? get nextAction;

}
/// @nodoc
class _$HomeSummaryCopyWithImpl<$Res>
    implements $HomeSummaryCopyWith<$Res> {
  _$HomeSummaryCopyWithImpl(this._self, this._then);

  final HomeSummary _self;
  final $Res Function(HomeSummary) _then;

/// Create a copy of HomeSummary
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? name = null,Object? verified = null,Object? eidVerified = null,Object? activeApplications = null,Object? readyDocuments = null,Object? unreadNotifications = null,Object? walletBalanceLak = null,Object? nextAction = freezed,Object? generatedAt = null,}) {
  return _then(_self.copyWith(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,verified: null == verified ? _self.verified : verified // ignore: cast_nullable_to_non_nullable
as bool,eidVerified: null == eidVerified ? _self.eidVerified : eidVerified // ignore: cast_nullable_to_non_nullable
as bool,activeApplications: null == activeApplications ? _self.activeApplications : activeApplications // ignore: cast_nullable_to_non_nullable
as int,readyDocuments: null == readyDocuments ? _self.readyDocuments : readyDocuments // ignore: cast_nullable_to_non_nullable
as int,unreadNotifications: null == unreadNotifications ? _self.unreadNotifications : unreadNotifications // ignore: cast_nullable_to_non_nullable
as int,walletBalanceLak: null == walletBalanceLak ? _self.walletBalanceLak : walletBalanceLak // ignore: cast_nullable_to_non_nullable
as int,nextAction: freezed == nextAction ? _self.nextAction : nextAction // ignore: cast_nullable_to_non_nullable
as HomeNextAction?,generatedAt: null == generatedAt ? _self.generatedAt : generatedAt // ignore: cast_nullable_to_non_nullable
as String,
  ));
}
/// Create a copy of HomeSummary
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$HomeNextActionCopyWith<$Res>? get nextAction {
    if (_self.nextAction == null) {
    return null;
  }

  return $HomeNextActionCopyWith<$Res>(_self.nextAction!, (value) {
    return _then(_self.copyWith(nextAction: value));
  });
}
}


/// Adds pattern-matching-related methods to [HomeSummary].
extension HomeSummaryPatterns on HomeSummary {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _HomeSummary value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _HomeSummary() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _HomeSummary value)  $default,){
final _that = this;
switch (_that) {
case _HomeSummary():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _HomeSummary value)?  $default,){
final _that = this;
switch (_that) {
case _HomeSummary() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String name,  bool verified,  bool eidVerified,  int activeApplications,  int readyDocuments,  int unreadNotifications,  int walletBalanceLak,  HomeNextAction? nextAction,  String generatedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _HomeSummary() when $default != null:
return $default(_that.name,_that.verified,_that.eidVerified,_that.activeApplications,_that.readyDocuments,_that.unreadNotifications,_that.walletBalanceLak,_that.nextAction,_that.generatedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String name,  bool verified,  bool eidVerified,  int activeApplications,  int readyDocuments,  int unreadNotifications,  int walletBalanceLak,  HomeNextAction? nextAction,  String generatedAt)  $default,) {final _that = this;
switch (_that) {
case _HomeSummary():
return $default(_that.name,_that.verified,_that.eidVerified,_that.activeApplications,_that.readyDocuments,_that.unreadNotifications,_that.walletBalanceLak,_that.nextAction,_that.generatedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String name,  bool verified,  bool eidVerified,  int activeApplications,  int readyDocuments,  int unreadNotifications,  int walletBalanceLak,  HomeNextAction? nextAction,  String generatedAt)?  $default,) {final _that = this;
switch (_that) {
case _HomeSummary() when $default != null:
return $default(_that.name,_that.verified,_that.eidVerified,_that.activeApplications,_that.readyDocuments,_that.unreadNotifications,_that.walletBalanceLak,_that.nextAction,_that.generatedAt);case _:
  return null;

}
}

}

/// @nodoc


class _HomeSummary implements HomeSummary {
  const _HomeSummary({this.name = '', this.verified = false, this.eidVerified = false, this.activeApplications = 0, this.readyDocuments = 0, this.unreadNotifications = 0, this.walletBalanceLak = 0, this.nextAction, this.generatedAt = ''});
  

/// The citizen's display name. The hero prints it beside the greeting
/// (`HomePage.tsx:279`).
@override@JsonKey() final  String name;
@override@JsonKey() final  bool verified;
@override@JsonKey() final  bool eidVerified;
@override@JsonKey() final  int activeApplications;
@override@JsonKey() final  int readyDocuments;
@override@JsonKey() final  int unreadNotifications;
@override@JsonKey() final  int walletBalanceLak;
/// Null when nothing is pending — which is the common case and is why the
/// banner is conditional rather than empty.
@override final  HomeNextAction? nextAction;
@override@JsonKey() final  String generatedAt;

/// Create a copy of HomeSummary
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$HomeSummaryCopyWith<_HomeSummary> get copyWith => __$HomeSummaryCopyWithImpl<_HomeSummary>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _HomeSummary&&(identical(other.name, name) || other.name == name)&&(identical(other.verified, verified) || other.verified == verified)&&(identical(other.eidVerified, eidVerified) || other.eidVerified == eidVerified)&&(identical(other.activeApplications, activeApplications) || other.activeApplications == activeApplications)&&(identical(other.readyDocuments, readyDocuments) || other.readyDocuments == readyDocuments)&&(identical(other.unreadNotifications, unreadNotifications) || other.unreadNotifications == unreadNotifications)&&(identical(other.walletBalanceLak, walletBalanceLak) || other.walletBalanceLak == walletBalanceLak)&&(identical(other.nextAction, nextAction) || other.nextAction == nextAction)&&(identical(other.generatedAt, generatedAt) || other.generatedAt == generatedAt));
}


@override
int get hashCode => Object.hash(runtimeType,name,verified,eidVerified,activeApplications,readyDocuments,unreadNotifications,walletBalanceLak,nextAction,generatedAt);

@override
String toString() {
  return 'HomeSummary(name: $name, verified: $verified, eidVerified: $eidVerified, activeApplications: $activeApplications, readyDocuments: $readyDocuments, unreadNotifications: $unreadNotifications, walletBalanceLak: $walletBalanceLak, nextAction: $nextAction, generatedAt: $generatedAt)';
}


}

/// @nodoc
abstract mixin class _$HomeSummaryCopyWith<$Res> implements $HomeSummaryCopyWith<$Res> {
  factory _$HomeSummaryCopyWith(_HomeSummary value, $Res Function(_HomeSummary) _then) = __$HomeSummaryCopyWithImpl;
@override @useResult
$Res call({
 String name, bool verified, bool eidVerified, int activeApplications, int readyDocuments, int unreadNotifications, int walletBalanceLak, HomeNextAction? nextAction, String generatedAt
});


@override $HomeNextActionCopyWith<$Res>? get nextAction;

}
/// @nodoc
class __$HomeSummaryCopyWithImpl<$Res>
    implements _$HomeSummaryCopyWith<$Res> {
  __$HomeSummaryCopyWithImpl(this._self, this._then);

  final _HomeSummary _self;
  final $Res Function(_HomeSummary) _then;

/// Create a copy of HomeSummary
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? name = null,Object? verified = null,Object? eidVerified = null,Object? activeApplications = null,Object? readyDocuments = null,Object? unreadNotifications = null,Object? walletBalanceLak = null,Object? nextAction = freezed,Object? generatedAt = null,}) {
  return _then(_HomeSummary(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,verified: null == verified ? _self.verified : verified // ignore: cast_nullable_to_non_nullable
as bool,eidVerified: null == eidVerified ? _self.eidVerified : eidVerified // ignore: cast_nullable_to_non_nullable
as bool,activeApplications: null == activeApplications ? _self.activeApplications : activeApplications // ignore: cast_nullable_to_non_nullable
as int,readyDocuments: null == readyDocuments ? _self.readyDocuments : readyDocuments // ignore: cast_nullable_to_non_nullable
as int,unreadNotifications: null == unreadNotifications ? _self.unreadNotifications : unreadNotifications // ignore: cast_nullable_to_non_nullable
as int,walletBalanceLak: null == walletBalanceLak ? _self.walletBalanceLak : walletBalanceLak // ignore: cast_nullable_to_non_nullable
as int,nextAction: freezed == nextAction ? _self.nextAction : nextAction // ignore: cast_nullable_to_non_nullable
as HomeNextAction?,generatedAt: null == generatedAt ? _self.generatedAt : generatedAt // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

/// Create a copy of HomeSummary
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$HomeNextActionCopyWith<$Res>? get nextAction {
    if (_self.nextAction == null) {
    return null;
  }

  return $HomeNextActionCopyWith<$Res>(_self.nextAction!, (value) {
    return _then(_self.copyWith(nextAction: value));
  });
}
}

// dart format on
