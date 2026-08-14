// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'notification_entities.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$CitizenNotification {

 String get id;/// `types.ts:754` — optional, and **never rendered**. On the wire, modelled
/// here, read by nothing.
 String? get template;/// `types.ts:757` — `{en, lo}`. `Layout.tsx:269`, `text(it.title, lang)`.
 Bilingual get title;/// `types.ts:758` — `{en, lo}`. `Layout.tsx:270`.
 Bilingual get body;/// `types.ts:759`. On the wire, never rendered.
 String get channel;/// `types.ts:760`. **The one field the UI switches on** — it picks the
/// row's icon, tint and destination tab through `kNotifStyle`
/// (`Layout.tsx:60-70`, `:131`, `:255`), with `announcement` as the
/// fallback for anything unrecognised.
 String get category;/// `types.ts:761`. On the wire, never rendered.
 String get severity;/// `types.ts:762-763`. On the wire, never rendered.
 String? get refType; String? get refId;/// `types.ts:764` — **on the wire and deliberately not consumed.**
/// `openNotification` (`Layout.tsx:129-137`) navigates by `category`, never
/// by `action_url`. Modelled because the field exists; routing by it would
/// be a behaviour the source does not have (specs.md § 6.15, B9-AC-44).
 String? get actionUrl;/// `types.ts:765`. **Null means unread** — `const unread = !it.read_at`
/// (`Layout.tsx:257`), and it is what gates both the row's blue dot
/// (`:275`) and whether opening the row issues a mark-read POST (`:133`).
 String? get readAt;/// `types.ts:766`. An ISO timestamp rendered through `relativeTime`
/// (`Layout.tsx:272`). Kept as the raw `String` the wire sends rather than
/// a `DateTime`: the source's formatter returns `""` for an unparseable
/// value instead of throwing (`:76`), and parsing at the edge would move
/// that decision to a place that cannot express it.
 String get sentAt;
/// Create a copy of CitizenNotification
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CitizenNotificationCopyWith<CitizenNotification> get copyWith => _$CitizenNotificationCopyWithImpl<CitizenNotification>(this as CitizenNotification, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CitizenNotification&&(identical(other.id, id) || other.id == id)&&(identical(other.template, template) || other.template == template)&&(identical(other.title, title) || other.title == title)&&(identical(other.body, body) || other.body == body)&&(identical(other.channel, channel) || other.channel == channel)&&(identical(other.category, category) || other.category == category)&&(identical(other.severity, severity) || other.severity == severity)&&(identical(other.refType, refType) || other.refType == refType)&&(identical(other.refId, refId) || other.refId == refId)&&(identical(other.actionUrl, actionUrl) || other.actionUrl == actionUrl)&&(identical(other.readAt, readAt) || other.readAt == readAt)&&(identical(other.sentAt, sentAt) || other.sentAt == sentAt));
}


@override
int get hashCode => Object.hash(runtimeType,id,template,title,body,channel,category,severity,refType,refId,actionUrl,readAt,sentAt);

@override
String toString() {
  return 'CitizenNotification(id: $id, template: $template, title: $title, body: $body, channel: $channel, category: $category, severity: $severity, refType: $refType, refId: $refId, actionUrl: $actionUrl, readAt: $readAt, sentAt: $sentAt)';
}


}

/// @nodoc
abstract mixin class $CitizenNotificationCopyWith<$Res>  {
  factory $CitizenNotificationCopyWith(CitizenNotification value, $Res Function(CitizenNotification) _then) = _$CitizenNotificationCopyWithImpl;
@useResult
$Res call({
 String id, String? template, Bilingual title, Bilingual body, String channel, String category, String severity, String? refType, String? refId, String? actionUrl, String? readAt, String sentAt
});


$BilingualCopyWith<$Res> get title;$BilingualCopyWith<$Res> get body;

}
/// @nodoc
class _$CitizenNotificationCopyWithImpl<$Res>
    implements $CitizenNotificationCopyWith<$Res> {
  _$CitizenNotificationCopyWithImpl(this._self, this._then);

  final CitizenNotification _self;
  final $Res Function(CitizenNotification) _then;

/// Create a copy of CitizenNotification
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? template = freezed,Object? title = null,Object? body = null,Object? channel = null,Object? category = null,Object? severity = null,Object? refType = freezed,Object? refId = freezed,Object? actionUrl = freezed,Object? readAt = freezed,Object? sentAt = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,template: freezed == template ? _self.template : template // ignore: cast_nullable_to_non_nullable
as String?,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as Bilingual,body: null == body ? _self.body : body // ignore: cast_nullable_to_non_nullable
as Bilingual,channel: null == channel ? _self.channel : channel // ignore: cast_nullable_to_non_nullable
as String,category: null == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as String,severity: null == severity ? _self.severity : severity // ignore: cast_nullable_to_non_nullable
as String,refType: freezed == refType ? _self.refType : refType // ignore: cast_nullable_to_non_nullable
as String?,refId: freezed == refId ? _self.refId : refId // ignore: cast_nullable_to_non_nullable
as String?,actionUrl: freezed == actionUrl ? _self.actionUrl : actionUrl // ignore: cast_nullable_to_non_nullable
as String?,readAt: freezed == readAt ? _self.readAt : readAt // ignore: cast_nullable_to_non_nullable
as String?,sentAt: null == sentAt ? _self.sentAt : sentAt // ignore: cast_nullable_to_non_nullable
as String,
  ));
}
/// Create a copy of CitizenNotification
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BilingualCopyWith<$Res> get title {
  
  return $BilingualCopyWith<$Res>(_self.title, (value) {
    return _then(_self.copyWith(title: value));
  });
}/// Create a copy of CitizenNotification
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BilingualCopyWith<$Res> get body {
  
  return $BilingualCopyWith<$Res>(_self.body, (value) {
    return _then(_self.copyWith(body: value));
  });
}
}


/// Adds pattern-matching-related methods to [CitizenNotification].
extension CitizenNotificationPatterns on CitizenNotification {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CitizenNotification value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CitizenNotification() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CitizenNotification value)  $default,){
final _that = this;
switch (_that) {
case _CitizenNotification():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CitizenNotification value)?  $default,){
final _that = this;
switch (_that) {
case _CitizenNotification() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String? template,  Bilingual title,  Bilingual body,  String channel,  String category,  String severity,  String? refType,  String? refId,  String? actionUrl,  String? readAt,  String sentAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CitizenNotification() when $default != null:
return $default(_that.id,_that.template,_that.title,_that.body,_that.channel,_that.category,_that.severity,_that.refType,_that.refId,_that.actionUrl,_that.readAt,_that.sentAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String? template,  Bilingual title,  Bilingual body,  String channel,  String category,  String severity,  String? refType,  String? refId,  String? actionUrl,  String? readAt,  String sentAt)  $default,) {final _that = this;
switch (_that) {
case _CitizenNotification():
return $default(_that.id,_that.template,_that.title,_that.body,_that.channel,_that.category,_that.severity,_that.refType,_that.refId,_that.actionUrl,_that.readAt,_that.sentAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String? template,  Bilingual title,  Bilingual body,  String channel,  String category,  String severity,  String? refType,  String? refId,  String? actionUrl,  String? readAt,  String sentAt)?  $default,) {final _that = this;
switch (_that) {
case _CitizenNotification() when $default != null:
return $default(_that.id,_that.template,_that.title,_that.body,_that.channel,_that.category,_that.severity,_that.refType,_that.refId,_that.actionUrl,_that.readAt,_that.sentAt);case _:
  return null;

}
}

}

/// @nodoc


class _CitizenNotification extends CitizenNotification {
  const _CitizenNotification({this.id = '', this.template, this.title = const Bilingual(en: '', lo: ''), this.body = const Bilingual(en: '', lo: ''), this.channel = '', this.category = '', this.severity = '', this.refType, this.refId, this.actionUrl, this.readAt, this.sentAt = ''}): super._();
  

@override@JsonKey() final  String id;
/// `types.ts:754` — optional, and **never rendered**. On the wire, modelled
/// here, read by nothing.
@override final  String? template;
/// `types.ts:757` — `{en, lo}`. `Layout.tsx:269`, `text(it.title, lang)`.
@override@JsonKey() final  Bilingual title;
/// `types.ts:758` — `{en, lo}`. `Layout.tsx:270`.
@override@JsonKey() final  Bilingual body;
/// `types.ts:759`. On the wire, never rendered.
@override@JsonKey() final  String channel;
/// `types.ts:760`. **The one field the UI switches on** — it picks the
/// row's icon, tint and destination tab through `kNotifStyle`
/// (`Layout.tsx:60-70`, `:131`, `:255`), with `announcement` as the
/// fallback for anything unrecognised.
@override@JsonKey() final  String category;
/// `types.ts:761`. On the wire, never rendered.
@override@JsonKey() final  String severity;
/// `types.ts:762-763`. On the wire, never rendered.
@override final  String? refType;
@override final  String? refId;
/// `types.ts:764` — **on the wire and deliberately not consumed.**
/// `openNotification` (`Layout.tsx:129-137`) navigates by `category`, never
/// by `action_url`. Modelled because the field exists; routing by it would
/// be a behaviour the source does not have (specs.md § 6.15, B9-AC-44).
@override final  String? actionUrl;
/// `types.ts:765`. **Null means unread** — `const unread = !it.read_at`
/// (`Layout.tsx:257`), and it is what gates both the row's blue dot
/// (`:275`) and whether opening the row issues a mark-read POST (`:133`).
@override final  String? readAt;
/// `types.ts:766`. An ISO timestamp rendered through `relativeTime`
/// (`Layout.tsx:272`). Kept as the raw `String` the wire sends rather than
/// a `DateTime`: the source's formatter returns `""` for an unparseable
/// value instead of throwing (`:76`), and parsing at the edge would move
/// that decision to a place that cannot express it.
@override@JsonKey() final  String sentAt;

/// Create a copy of CitizenNotification
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CitizenNotificationCopyWith<_CitizenNotification> get copyWith => __$CitizenNotificationCopyWithImpl<_CitizenNotification>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CitizenNotification&&(identical(other.id, id) || other.id == id)&&(identical(other.template, template) || other.template == template)&&(identical(other.title, title) || other.title == title)&&(identical(other.body, body) || other.body == body)&&(identical(other.channel, channel) || other.channel == channel)&&(identical(other.category, category) || other.category == category)&&(identical(other.severity, severity) || other.severity == severity)&&(identical(other.refType, refType) || other.refType == refType)&&(identical(other.refId, refId) || other.refId == refId)&&(identical(other.actionUrl, actionUrl) || other.actionUrl == actionUrl)&&(identical(other.readAt, readAt) || other.readAt == readAt)&&(identical(other.sentAt, sentAt) || other.sentAt == sentAt));
}


@override
int get hashCode => Object.hash(runtimeType,id,template,title,body,channel,category,severity,refType,refId,actionUrl,readAt,sentAt);

@override
String toString() {
  return 'CitizenNotification(id: $id, template: $template, title: $title, body: $body, channel: $channel, category: $category, severity: $severity, refType: $refType, refId: $refId, actionUrl: $actionUrl, readAt: $readAt, sentAt: $sentAt)';
}


}

/// @nodoc
abstract mixin class _$CitizenNotificationCopyWith<$Res> implements $CitizenNotificationCopyWith<$Res> {
  factory _$CitizenNotificationCopyWith(_CitizenNotification value, $Res Function(_CitizenNotification) _then) = __$CitizenNotificationCopyWithImpl;
@override @useResult
$Res call({
 String id, String? template, Bilingual title, Bilingual body, String channel, String category, String severity, String? refType, String? refId, String? actionUrl, String? readAt, String sentAt
});


@override $BilingualCopyWith<$Res> get title;@override $BilingualCopyWith<$Res> get body;

}
/// @nodoc
class __$CitizenNotificationCopyWithImpl<$Res>
    implements _$CitizenNotificationCopyWith<$Res> {
  __$CitizenNotificationCopyWithImpl(this._self, this._then);

  final _CitizenNotification _self;
  final $Res Function(_CitizenNotification) _then;

/// Create a copy of CitizenNotification
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? template = freezed,Object? title = null,Object? body = null,Object? channel = null,Object? category = null,Object? severity = null,Object? refType = freezed,Object? refId = freezed,Object? actionUrl = freezed,Object? readAt = freezed,Object? sentAt = null,}) {
  return _then(_CitizenNotification(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,template: freezed == template ? _self.template : template // ignore: cast_nullable_to_non_nullable
as String?,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as Bilingual,body: null == body ? _self.body : body // ignore: cast_nullable_to_non_nullable
as Bilingual,channel: null == channel ? _self.channel : channel // ignore: cast_nullable_to_non_nullable
as String,category: null == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as String,severity: null == severity ? _self.severity : severity // ignore: cast_nullable_to_non_nullable
as String,refType: freezed == refType ? _self.refType : refType // ignore: cast_nullable_to_non_nullable
as String?,refId: freezed == refId ? _self.refId : refId // ignore: cast_nullable_to_non_nullable
as String?,actionUrl: freezed == actionUrl ? _self.actionUrl : actionUrl // ignore: cast_nullable_to_non_nullable
as String?,readAt: freezed == readAt ? _self.readAt : readAt // ignore: cast_nullable_to_non_nullable
as String?,sentAt: null == sentAt ? _self.sentAt : sentAt // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

/// Create a copy of CitizenNotification
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BilingualCopyWith<$Res> get title {
  
  return $BilingualCopyWith<$Res>(_self.title, (value) {
    return _then(_self.copyWith(title: value));
  });
}/// Create a copy of CitizenNotification
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BilingualCopyWith<$Res> get body {
  
  return $BilingualCopyWith<$Res>(_self.body, (value) {
    return _then(_self.copyWith(body: value));
  });
}
}

// dart format on
