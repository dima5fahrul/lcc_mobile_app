// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'chat_entities.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$ChatThread {

 String get id;/// The citizen's own words, truncated to 80 UTF-16 code units at creation
/// (`:140`). A plain `String`; see the library doc.
 String get subject;/// Always `"general"` from this client — the literal at `:106`. Kept as a
/// `String` because it is the server's field and other clients may set it.
 String get topic;/// `"open" | "pending" | "resolved" | "closed"` (`types.ts:726`).
///
/// Modelled as a `String`, not an enum, for the reason
/// `notification_entities.dart` gives for `severity`: the source never
/// switches on the closed set, it only asks [isActive]. An enum would have
/// to decide what an unrecognised fifth value means, and the source answers
/// that question by simply not matching.
 String get status;/// `assigned_name` — the human agent, once one picks the thread up.
///
/// **Null is load-bearing.** It selects the header title (`:217`) *and* it
/// suppresses the bot suggestion chips (`:190-191`): once an agent is on
/// the thread the API stops suggesting and so does the UI.
 String? get assignedName;/// On the wire, never rendered.
 String? get applicationId; String? get lastMessageAt;/// `types.ts:730`. Summed across threads for the launcher badge
/// (`:127`), and **not** the same number as the notification bell's
/// unread count — different feature, different endpoint (§ 2.2 Finding B).
 int get unreadCitizen;/// The 1-5 star rating a closed thread carries. On the wire; the panel
/// writes it and never reads it back.
 int? get rating; String get createdAt;
/// Create a copy of ChatThread
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ChatThreadCopyWith<ChatThread> get copyWith => _$ChatThreadCopyWithImpl<ChatThread>(this as ChatThread, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ChatThread&&(identical(other.id, id) || other.id == id)&&(identical(other.subject, subject) || other.subject == subject)&&(identical(other.topic, topic) || other.topic == topic)&&(identical(other.status, status) || other.status == status)&&(identical(other.assignedName, assignedName) || other.assignedName == assignedName)&&(identical(other.applicationId, applicationId) || other.applicationId == applicationId)&&(identical(other.lastMessageAt, lastMessageAt) || other.lastMessageAt == lastMessageAt)&&(identical(other.unreadCitizen, unreadCitizen) || other.unreadCitizen == unreadCitizen)&&(identical(other.rating, rating) || other.rating == rating)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}


@override
int get hashCode => Object.hash(runtimeType,id,subject,topic,status,assignedName,applicationId,lastMessageAt,unreadCitizen,rating,createdAt);

@override
String toString() {
  return 'ChatThread(id: $id, subject: $subject, topic: $topic, status: $status, assignedName: $assignedName, applicationId: $applicationId, lastMessageAt: $lastMessageAt, unreadCitizen: $unreadCitizen, rating: $rating, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class $ChatThreadCopyWith<$Res>  {
  factory $ChatThreadCopyWith(ChatThread value, $Res Function(ChatThread) _then) = _$ChatThreadCopyWithImpl;
@useResult
$Res call({
 String id, String subject, String topic, String status, String? assignedName, String? applicationId, String? lastMessageAt, int unreadCitizen, int? rating, String createdAt
});




}
/// @nodoc
class _$ChatThreadCopyWithImpl<$Res>
    implements $ChatThreadCopyWith<$Res> {
  _$ChatThreadCopyWithImpl(this._self, this._then);

  final ChatThread _self;
  final $Res Function(ChatThread) _then;

/// Create a copy of ChatThread
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? subject = null,Object? topic = null,Object? status = null,Object? assignedName = freezed,Object? applicationId = freezed,Object? lastMessageAt = freezed,Object? unreadCitizen = null,Object? rating = freezed,Object? createdAt = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,subject: null == subject ? _self.subject : subject // ignore: cast_nullable_to_non_nullable
as String,topic: null == topic ? _self.topic : topic // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,assignedName: freezed == assignedName ? _self.assignedName : assignedName // ignore: cast_nullable_to_non_nullable
as String?,applicationId: freezed == applicationId ? _self.applicationId : applicationId // ignore: cast_nullable_to_non_nullable
as String?,lastMessageAt: freezed == lastMessageAt ? _self.lastMessageAt : lastMessageAt // ignore: cast_nullable_to_non_nullable
as String?,unreadCitizen: null == unreadCitizen ? _self.unreadCitizen : unreadCitizen // ignore: cast_nullable_to_non_nullable
as int,rating: freezed == rating ? _self.rating : rating // ignore: cast_nullable_to_non_nullable
as int?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [ChatThread].
extension ChatThreadPatterns on ChatThread {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ChatThread value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ChatThread() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ChatThread value)  $default,){
final _that = this;
switch (_that) {
case _ChatThread():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ChatThread value)?  $default,){
final _that = this;
switch (_that) {
case _ChatThread() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String subject,  String topic,  String status,  String? assignedName,  String? applicationId,  String? lastMessageAt,  int unreadCitizen,  int? rating,  String createdAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ChatThread() when $default != null:
return $default(_that.id,_that.subject,_that.topic,_that.status,_that.assignedName,_that.applicationId,_that.lastMessageAt,_that.unreadCitizen,_that.rating,_that.createdAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String subject,  String topic,  String status,  String? assignedName,  String? applicationId,  String? lastMessageAt,  int unreadCitizen,  int? rating,  String createdAt)  $default,) {final _that = this;
switch (_that) {
case _ChatThread():
return $default(_that.id,_that.subject,_that.topic,_that.status,_that.assignedName,_that.applicationId,_that.lastMessageAt,_that.unreadCitizen,_that.rating,_that.createdAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String subject,  String topic,  String status,  String? assignedName,  String? applicationId,  String? lastMessageAt,  int unreadCitizen,  int? rating,  String createdAt)?  $default,) {final _that = this;
switch (_that) {
case _ChatThread() when $default != null:
return $default(_that.id,_that.subject,_that.topic,_that.status,_that.assignedName,_that.applicationId,_that.lastMessageAt,_that.unreadCitizen,_that.rating,_that.createdAt);case _:
  return null;

}
}

}

/// @nodoc


class _ChatThread extends ChatThread {
  const _ChatThread({this.id = '', this.subject = '', this.topic = '', this.status = '', this.assignedName, this.applicationId, this.lastMessageAt, this.unreadCitizen = 0, this.rating, this.createdAt = ''}): super._();
  

@override@JsonKey() final  String id;
/// The citizen's own words, truncated to 80 UTF-16 code units at creation
/// (`:140`). A plain `String`; see the library doc.
@override@JsonKey() final  String subject;
/// Always `"general"` from this client — the literal at `:106`. Kept as a
/// `String` because it is the server's field and other clients may set it.
@override@JsonKey() final  String topic;
/// `"open" | "pending" | "resolved" | "closed"` (`types.ts:726`).
///
/// Modelled as a `String`, not an enum, for the reason
/// `notification_entities.dart` gives for `severity`: the source never
/// switches on the closed set, it only asks [isActive]. An enum would have
/// to decide what an unrecognised fifth value means, and the source answers
/// that question by simply not matching.
@override@JsonKey() final  String status;
/// `assigned_name` — the human agent, once one picks the thread up.
///
/// **Null is load-bearing.** It selects the header title (`:217`) *and* it
/// suppresses the bot suggestion chips (`:190-191`): once an agent is on
/// the thread the API stops suggesting and so does the UI.
@override final  String? assignedName;
/// On the wire, never rendered.
@override final  String? applicationId;
@override final  String? lastMessageAt;
/// `types.ts:730`. Summed across threads for the launcher badge
/// (`:127`), and **not** the same number as the notification bell's
/// unread count — different feature, different endpoint (§ 2.2 Finding B).
@override@JsonKey() final  int unreadCitizen;
/// The 1-5 star rating a closed thread carries. On the wire; the panel
/// writes it and never reads it back.
@override final  int? rating;
@override@JsonKey() final  String createdAt;

/// Create a copy of ChatThread
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ChatThreadCopyWith<_ChatThread> get copyWith => __$ChatThreadCopyWithImpl<_ChatThread>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ChatThread&&(identical(other.id, id) || other.id == id)&&(identical(other.subject, subject) || other.subject == subject)&&(identical(other.topic, topic) || other.topic == topic)&&(identical(other.status, status) || other.status == status)&&(identical(other.assignedName, assignedName) || other.assignedName == assignedName)&&(identical(other.applicationId, applicationId) || other.applicationId == applicationId)&&(identical(other.lastMessageAt, lastMessageAt) || other.lastMessageAt == lastMessageAt)&&(identical(other.unreadCitizen, unreadCitizen) || other.unreadCitizen == unreadCitizen)&&(identical(other.rating, rating) || other.rating == rating)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}


@override
int get hashCode => Object.hash(runtimeType,id,subject,topic,status,assignedName,applicationId,lastMessageAt,unreadCitizen,rating,createdAt);

@override
String toString() {
  return 'ChatThread(id: $id, subject: $subject, topic: $topic, status: $status, assignedName: $assignedName, applicationId: $applicationId, lastMessageAt: $lastMessageAt, unreadCitizen: $unreadCitizen, rating: $rating, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class _$ChatThreadCopyWith<$Res> implements $ChatThreadCopyWith<$Res> {
  factory _$ChatThreadCopyWith(_ChatThread value, $Res Function(_ChatThread) _then) = __$ChatThreadCopyWithImpl;
@override @useResult
$Res call({
 String id, String subject, String topic, String status, String? assignedName, String? applicationId, String? lastMessageAt, int unreadCitizen, int? rating, String createdAt
});




}
/// @nodoc
class __$ChatThreadCopyWithImpl<$Res>
    implements _$ChatThreadCopyWith<$Res> {
  __$ChatThreadCopyWithImpl(this._self, this._then);

  final _ChatThread _self;
  final $Res Function(_ChatThread) _then;

/// Create a copy of ChatThread
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? subject = null,Object? topic = null,Object? status = null,Object? assignedName = freezed,Object? applicationId = freezed,Object? lastMessageAt = freezed,Object? unreadCitizen = null,Object? rating = freezed,Object? createdAt = null,}) {
  return _then(_ChatThread(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,subject: null == subject ? _self.subject : subject // ignore: cast_nullable_to_non_nullable
as String,topic: null == topic ? _self.topic : topic // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,assignedName: freezed == assignedName ? _self.assignedName : assignedName // ignore: cast_nullable_to_non_nullable
as String?,applicationId: freezed == applicationId ? _self.applicationId : applicationId // ignore: cast_nullable_to_non_nullable
as String?,lastMessageAt: freezed == lastMessageAt ? _self.lastMessageAt : lastMessageAt // ignore: cast_nullable_to_non_nullable
as String?,unreadCitizen: null == unreadCitizen ? _self.unreadCitizen : unreadCitizen // ignore: cast_nullable_to_non_nullable
as int,rating: freezed == rating ? _self.rating : rating // ignore: cast_nullable_to_non_nullable
as int?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc
mixin _$ChatMessage {

 String get id; String get threadId;/// `"citizen" | "agent" | "bot" | "system"` (`types.ts:737`). The only
/// question asked of it is [isMine] (`:365`); the other three render
/// identically.
 String get senderType;/// On the wire, never rendered — the header shows
/// `ChatThread.assignedName`, not this.
 String get senderName;/// Rendered through the two-rule mini-markdown parser (`:402`). **This is
/// server-supplied text**, which is why `formatted_text.dart` is a
/// security-review item and not only a fidelity one (§ 6.14, § 7.8).
 String get body;/// `types.ts:740` — `string[] | null | undefined`, and **all three occur**.
///
/// Only the *last* message's list is read, and only when no agent is
/// assigned (`:187-192`). `null` and `[]` are not distinguished by any
/// consumer, but they are distinguished here because the wire distinguishes
/// them and collapsing them at the edge would make the fixture unable to
/// discriminate.
 List<String>? get suggestions;/// On the wire, never rendered. There is no attachment UI in the chat.
 String? get attachmentUrl; String? get readAt;/// An ISO timestamp rendered through `clockTime` (`:404`). Kept as the raw
/// `String` the wire sends for the reason `CitizenNotification.sentAt`
/// documents: the source's formatter answers `""` for an unparseable value
/// instead of throwing, and parsing at the edge would move that decision to
/// a place that cannot express it.
 String get sentAt;
/// Create a copy of ChatMessage
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ChatMessageCopyWith<ChatMessage> get copyWith => _$ChatMessageCopyWithImpl<ChatMessage>(this as ChatMessage, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ChatMessage&&(identical(other.id, id) || other.id == id)&&(identical(other.threadId, threadId) || other.threadId == threadId)&&(identical(other.senderType, senderType) || other.senderType == senderType)&&(identical(other.senderName, senderName) || other.senderName == senderName)&&(identical(other.body, body) || other.body == body)&&const DeepCollectionEquality().equals(other.suggestions, suggestions)&&(identical(other.attachmentUrl, attachmentUrl) || other.attachmentUrl == attachmentUrl)&&(identical(other.readAt, readAt) || other.readAt == readAt)&&(identical(other.sentAt, sentAt) || other.sentAt == sentAt));
}


@override
int get hashCode => Object.hash(runtimeType,id,threadId,senderType,senderName,body,const DeepCollectionEquality().hash(suggestions),attachmentUrl,readAt,sentAt);

@override
String toString() {
  return 'ChatMessage(id: $id, threadId: $threadId, senderType: $senderType, senderName: $senderName, body: $body, suggestions: $suggestions, attachmentUrl: $attachmentUrl, readAt: $readAt, sentAt: $sentAt)';
}


}

/// @nodoc
abstract mixin class $ChatMessageCopyWith<$Res>  {
  factory $ChatMessageCopyWith(ChatMessage value, $Res Function(ChatMessage) _then) = _$ChatMessageCopyWithImpl;
@useResult
$Res call({
 String id, String threadId, String senderType, String senderName, String body, List<String>? suggestions, String? attachmentUrl, String? readAt, String sentAt
});




}
/// @nodoc
class _$ChatMessageCopyWithImpl<$Res>
    implements $ChatMessageCopyWith<$Res> {
  _$ChatMessageCopyWithImpl(this._self, this._then);

  final ChatMessage _self;
  final $Res Function(ChatMessage) _then;

/// Create a copy of ChatMessage
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? threadId = null,Object? senderType = null,Object? senderName = null,Object? body = null,Object? suggestions = freezed,Object? attachmentUrl = freezed,Object? readAt = freezed,Object? sentAt = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,threadId: null == threadId ? _self.threadId : threadId // ignore: cast_nullable_to_non_nullable
as String,senderType: null == senderType ? _self.senderType : senderType // ignore: cast_nullable_to_non_nullable
as String,senderName: null == senderName ? _self.senderName : senderName // ignore: cast_nullable_to_non_nullable
as String,body: null == body ? _self.body : body // ignore: cast_nullable_to_non_nullable
as String,suggestions: freezed == suggestions ? _self.suggestions : suggestions // ignore: cast_nullable_to_non_nullable
as List<String>?,attachmentUrl: freezed == attachmentUrl ? _self.attachmentUrl : attachmentUrl // ignore: cast_nullable_to_non_nullable
as String?,readAt: freezed == readAt ? _self.readAt : readAt // ignore: cast_nullable_to_non_nullable
as String?,sentAt: null == sentAt ? _self.sentAt : sentAt // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [ChatMessage].
extension ChatMessagePatterns on ChatMessage {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ChatMessage value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ChatMessage() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ChatMessage value)  $default,){
final _that = this;
switch (_that) {
case _ChatMessage():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ChatMessage value)?  $default,){
final _that = this;
switch (_that) {
case _ChatMessage() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String threadId,  String senderType,  String senderName,  String body,  List<String>? suggestions,  String? attachmentUrl,  String? readAt,  String sentAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ChatMessage() when $default != null:
return $default(_that.id,_that.threadId,_that.senderType,_that.senderName,_that.body,_that.suggestions,_that.attachmentUrl,_that.readAt,_that.sentAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String threadId,  String senderType,  String senderName,  String body,  List<String>? suggestions,  String? attachmentUrl,  String? readAt,  String sentAt)  $default,) {final _that = this;
switch (_that) {
case _ChatMessage():
return $default(_that.id,_that.threadId,_that.senderType,_that.senderName,_that.body,_that.suggestions,_that.attachmentUrl,_that.readAt,_that.sentAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String threadId,  String senderType,  String senderName,  String body,  List<String>? suggestions,  String? attachmentUrl,  String? readAt,  String sentAt)?  $default,) {final _that = this;
switch (_that) {
case _ChatMessage() when $default != null:
return $default(_that.id,_that.threadId,_that.senderType,_that.senderName,_that.body,_that.suggestions,_that.attachmentUrl,_that.readAt,_that.sentAt);case _:
  return null;

}
}

}

/// @nodoc


class _ChatMessage extends ChatMessage {
  const _ChatMessage({this.id = '', this.threadId = '', this.senderType = '', this.senderName = '', this.body = '', final  List<String>? suggestions, this.attachmentUrl, this.readAt, this.sentAt = ''}): _suggestions = suggestions,super._();
  

@override@JsonKey() final  String id;
@override@JsonKey() final  String threadId;
/// `"citizen" | "agent" | "bot" | "system"` (`types.ts:737`). The only
/// question asked of it is [isMine] (`:365`); the other three render
/// identically.
@override@JsonKey() final  String senderType;
/// On the wire, never rendered — the header shows
/// `ChatThread.assignedName`, not this.
@override@JsonKey() final  String senderName;
/// Rendered through the two-rule mini-markdown parser (`:402`). **This is
/// server-supplied text**, which is why `formatted_text.dart` is a
/// security-review item and not only a fidelity one (§ 6.14, § 7.8).
@override@JsonKey() final  String body;
/// `types.ts:740` — `string[] | null | undefined`, and **all three occur**.
///
/// Only the *last* message's list is read, and only when no agent is
/// assigned (`:187-192`). `null` and `[]` are not distinguished by any
/// consumer, but they are distinguished here because the wire distinguishes
/// them and collapsing them at the edge would make the fixture unable to
/// discriminate.
 final  List<String>? _suggestions;
/// `types.ts:740` — `string[] | null | undefined`, and **all three occur**.
///
/// Only the *last* message's list is read, and only when no agent is
/// assigned (`:187-192`). `null` and `[]` are not distinguished by any
/// consumer, but they are distinguished here because the wire distinguishes
/// them and collapsing them at the edge would make the fixture unable to
/// discriminate.
@override List<String>? get suggestions {
  final value = _suggestions;
  if (value == null) return null;
  if (_suggestions is EqualUnmodifiableListView) return _suggestions;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(value);
}

/// On the wire, never rendered. There is no attachment UI in the chat.
@override final  String? attachmentUrl;
@override final  String? readAt;
/// An ISO timestamp rendered through `clockTime` (`:404`). Kept as the raw
/// `String` the wire sends for the reason `CitizenNotification.sentAt`
/// documents: the source's formatter answers `""` for an unparseable value
/// instead of throwing, and parsing at the edge would move that decision to
/// a place that cannot express it.
@override@JsonKey() final  String sentAt;

/// Create a copy of ChatMessage
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ChatMessageCopyWith<_ChatMessage> get copyWith => __$ChatMessageCopyWithImpl<_ChatMessage>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ChatMessage&&(identical(other.id, id) || other.id == id)&&(identical(other.threadId, threadId) || other.threadId == threadId)&&(identical(other.senderType, senderType) || other.senderType == senderType)&&(identical(other.senderName, senderName) || other.senderName == senderName)&&(identical(other.body, body) || other.body == body)&&const DeepCollectionEquality().equals(other._suggestions, _suggestions)&&(identical(other.attachmentUrl, attachmentUrl) || other.attachmentUrl == attachmentUrl)&&(identical(other.readAt, readAt) || other.readAt == readAt)&&(identical(other.sentAt, sentAt) || other.sentAt == sentAt));
}


@override
int get hashCode => Object.hash(runtimeType,id,threadId,senderType,senderName,body,const DeepCollectionEquality().hash(_suggestions),attachmentUrl,readAt,sentAt);

@override
String toString() {
  return 'ChatMessage(id: $id, threadId: $threadId, senderType: $senderType, senderName: $senderName, body: $body, suggestions: $suggestions, attachmentUrl: $attachmentUrl, readAt: $readAt, sentAt: $sentAt)';
}


}

/// @nodoc
abstract mixin class _$ChatMessageCopyWith<$Res> implements $ChatMessageCopyWith<$Res> {
  factory _$ChatMessageCopyWith(_ChatMessage value, $Res Function(_ChatMessage) _then) = __$ChatMessageCopyWithImpl;
@override @useResult
$Res call({
 String id, String threadId, String senderType, String senderName, String body, List<String>? suggestions, String? attachmentUrl, String? readAt, String sentAt
});




}
/// @nodoc
class __$ChatMessageCopyWithImpl<$Res>
    implements _$ChatMessageCopyWith<$Res> {
  __$ChatMessageCopyWithImpl(this._self, this._then);

  final _ChatMessage _self;
  final $Res Function(_ChatMessage) _then;

/// Create a copy of ChatMessage
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? threadId = null,Object? senderType = null,Object? senderName = null,Object? body = null,Object? suggestions = freezed,Object? attachmentUrl = freezed,Object? readAt = freezed,Object? sentAt = null,}) {
  return _then(_ChatMessage(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,threadId: null == threadId ? _self.threadId : threadId // ignore: cast_nullable_to_non_nullable
as String,senderType: null == senderType ? _self.senderType : senderType // ignore: cast_nullable_to_non_nullable
as String,senderName: null == senderName ? _self.senderName : senderName // ignore: cast_nullable_to_non_nullable
as String,body: null == body ? _self.body : body // ignore: cast_nullable_to_non_nullable
as String,suggestions: freezed == suggestions ? _self._suggestions : suggestions // ignore: cast_nullable_to_non_nullable
as List<String>?,attachmentUrl: freezed == attachmentUrl ? _self.attachmentUrl : attachmentUrl // ignore: cast_nullable_to_non_nullable
as String?,readAt: freezed == readAt ? _self.readAt : readAt // ignore: cast_nullable_to_non_nullable
as String?,sentAt: null == sentAt ? _self.sentAt : sentAt // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc
mixin _$StartedThread {

 ChatThread get thread; ChatMessage get message; List<String>? get suggestions;
/// Create a copy of StartedThread
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$StartedThreadCopyWith<StartedThread> get copyWith => _$StartedThreadCopyWithImpl<StartedThread>(this as StartedThread, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is StartedThread&&(identical(other.thread, thread) || other.thread == thread)&&(identical(other.message, message) || other.message == message)&&const DeepCollectionEquality().equals(other.suggestions, suggestions));
}


@override
int get hashCode => Object.hash(runtimeType,thread,message,const DeepCollectionEquality().hash(suggestions));

@override
String toString() {
  return 'StartedThread(thread: $thread, message: $message, suggestions: $suggestions)';
}


}

/// @nodoc
abstract mixin class $StartedThreadCopyWith<$Res>  {
  factory $StartedThreadCopyWith(StartedThread value, $Res Function(StartedThread) _then) = _$StartedThreadCopyWithImpl;
@useResult
$Res call({
 ChatThread thread, ChatMessage message, List<String>? suggestions
});


$ChatThreadCopyWith<$Res> get thread;$ChatMessageCopyWith<$Res> get message;

}
/// @nodoc
class _$StartedThreadCopyWithImpl<$Res>
    implements $StartedThreadCopyWith<$Res> {
  _$StartedThreadCopyWithImpl(this._self, this._then);

  final StartedThread _self;
  final $Res Function(StartedThread) _then;

/// Create a copy of StartedThread
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? thread = null,Object? message = null,Object? suggestions = freezed,}) {
  return _then(_self.copyWith(
thread: null == thread ? _self.thread : thread // ignore: cast_nullable_to_non_nullable
as ChatThread,message: null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as ChatMessage,suggestions: freezed == suggestions ? _self.suggestions : suggestions // ignore: cast_nullable_to_non_nullable
as List<String>?,
  ));
}
/// Create a copy of StartedThread
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ChatThreadCopyWith<$Res> get thread {
  
  return $ChatThreadCopyWith<$Res>(_self.thread, (value) {
    return _then(_self.copyWith(thread: value));
  });
}/// Create a copy of StartedThread
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ChatMessageCopyWith<$Res> get message {
  
  return $ChatMessageCopyWith<$Res>(_self.message, (value) {
    return _then(_self.copyWith(message: value));
  });
}
}


/// Adds pattern-matching-related methods to [StartedThread].
extension StartedThreadPatterns on StartedThread {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _StartedThread value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _StartedThread() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _StartedThread value)  $default,){
final _that = this;
switch (_that) {
case _StartedThread():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _StartedThread value)?  $default,){
final _that = this;
switch (_that) {
case _StartedThread() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( ChatThread thread,  ChatMessage message,  List<String>? suggestions)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _StartedThread() when $default != null:
return $default(_that.thread,_that.message,_that.suggestions);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( ChatThread thread,  ChatMessage message,  List<String>? suggestions)  $default,) {final _that = this;
switch (_that) {
case _StartedThread():
return $default(_that.thread,_that.message,_that.suggestions);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( ChatThread thread,  ChatMessage message,  List<String>? suggestions)?  $default,) {final _that = this;
switch (_that) {
case _StartedThread() when $default != null:
return $default(_that.thread,_that.message,_that.suggestions);case _:
  return null;

}
}

}

/// @nodoc


class _StartedThread implements StartedThread {
  const _StartedThread({this.thread = const ChatThread(), this.message = const ChatMessage(), final  List<String>? suggestions}): _suggestions = suggestions;
  

@override@JsonKey() final  ChatThread thread;
@override@JsonKey() final  ChatMessage message;
 final  List<String>? _suggestions;
@override List<String>? get suggestions {
  final value = _suggestions;
  if (value == null) return null;
  if (_suggestions is EqualUnmodifiableListView) return _suggestions;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(value);
}


/// Create a copy of StartedThread
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$StartedThreadCopyWith<_StartedThread> get copyWith => __$StartedThreadCopyWithImpl<_StartedThread>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _StartedThread&&(identical(other.thread, thread) || other.thread == thread)&&(identical(other.message, message) || other.message == message)&&const DeepCollectionEquality().equals(other._suggestions, _suggestions));
}


@override
int get hashCode => Object.hash(runtimeType,thread,message,const DeepCollectionEquality().hash(_suggestions));

@override
String toString() {
  return 'StartedThread(thread: $thread, message: $message, suggestions: $suggestions)';
}


}

/// @nodoc
abstract mixin class _$StartedThreadCopyWith<$Res> implements $StartedThreadCopyWith<$Res> {
  factory _$StartedThreadCopyWith(_StartedThread value, $Res Function(_StartedThread) _then) = __$StartedThreadCopyWithImpl;
@override @useResult
$Res call({
 ChatThread thread, ChatMessage message, List<String>? suggestions
});


@override $ChatThreadCopyWith<$Res> get thread;@override $ChatMessageCopyWith<$Res> get message;

}
/// @nodoc
class __$StartedThreadCopyWithImpl<$Res>
    implements _$StartedThreadCopyWith<$Res> {
  __$StartedThreadCopyWithImpl(this._self, this._then);

  final _StartedThread _self;
  final $Res Function(_StartedThread) _then;

/// Create a copy of StartedThread
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? thread = null,Object? message = null,Object? suggestions = freezed,}) {
  return _then(_StartedThread(
thread: null == thread ? _self.thread : thread // ignore: cast_nullable_to_non_nullable
as ChatThread,message: null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as ChatMessage,suggestions: freezed == suggestions ? _self._suggestions : suggestions // ignore: cast_nullable_to_non_nullable
as List<String>?,
  ));
}

/// Create a copy of StartedThread
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ChatThreadCopyWith<$Res> get thread {
  
  return $ChatThreadCopyWith<$Res>(_self.thread, (value) {
    return _then(_self.copyWith(thread: value));
  });
}/// Create a copy of StartedThread
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ChatMessageCopyWith<$Res> get message {
  
  return $ChatMessageCopyWith<$Res>(_self.message, (value) {
    return _then(_self.copyWith(message: value));
  });
}
}

/// @nodoc
mixin _$SentMessage {

 ChatMessage get message; List<String>? get suggestions;
/// Create a copy of SentMessage
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SentMessageCopyWith<SentMessage> get copyWith => _$SentMessageCopyWithImpl<SentMessage>(this as SentMessage, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SentMessage&&(identical(other.message, message) || other.message == message)&&const DeepCollectionEquality().equals(other.suggestions, suggestions));
}


@override
int get hashCode => Object.hash(runtimeType,message,const DeepCollectionEquality().hash(suggestions));

@override
String toString() {
  return 'SentMessage(message: $message, suggestions: $suggestions)';
}


}

/// @nodoc
abstract mixin class $SentMessageCopyWith<$Res>  {
  factory $SentMessageCopyWith(SentMessage value, $Res Function(SentMessage) _then) = _$SentMessageCopyWithImpl;
@useResult
$Res call({
 ChatMessage message, List<String>? suggestions
});


$ChatMessageCopyWith<$Res> get message;

}
/// @nodoc
class _$SentMessageCopyWithImpl<$Res>
    implements $SentMessageCopyWith<$Res> {
  _$SentMessageCopyWithImpl(this._self, this._then);

  final SentMessage _self;
  final $Res Function(SentMessage) _then;

/// Create a copy of SentMessage
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? message = null,Object? suggestions = freezed,}) {
  return _then(_self.copyWith(
message: null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as ChatMessage,suggestions: freezed == suggestions ? _self.suggestions : suggestions // ignore: cast_nullable_to_non_nullable
as List<String>?,
  ));
}
/// Create a copy of SentMessage
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ChatMessageCopyWith<$Res> get message {
  
  return $ChatMessageCopyWith<$Res>(_self.message, (value) {
    return _then(_self.copyWith(message: value));
  });
}
}


/// Adds pattern-matching-related methods to [SentMessage].
extension SentMessagePatterns on SentMessage {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SentMessage value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SentMessage() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SentMessage value)  $default,){
final _that = this;
switch (_that) {
case _SentMessage():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SentMessage value)?  $default,){
final _that = this;
switch (_that) {
case _SentMessage() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( ChatMessage message,  List<String>? suggestions)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SentMessage() when $default != null:
return $default(_that.message,_that.suggestions);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( ChatMessage message,  List<String>? suggestions)  $default,) {final _that = this;
switch (_that) {
case _SentMessage():
return $default(_that.message,_that.suggestions);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( ChatMessage message,  List<String>? suggestions)?  $default,) {final _that = this;
switch (_that) {
case _SentMessage() when $default != null:
return $default(_that.message,_that.suggestions);case _:
  return null;

}
}

}

/// @nodoc


class _SentMessage implements SentMessage {
  const _SentMessage({this.message = const ChatMessage(), final  List<String>? suggestions}): _suggestions = suggestions;
  

@override@JsonKey() final  ChatMessage message;
 final  List<String>? _suggestions;
@override List<String>? get suggestions {
  final value = _suggestions;
  if (value == null) return null;
  if (_suggestions is EqualUnmodifiableListView) return _suggestions;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(value);
}


/// Create a copy of SentMessage
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SentMessageCopyWith<_SentMessage> get copyWith => __$SentMessageCopyWithImpl<_SentMessage>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SentMessage&&(identical(other.message, message) || other.message == message)&&const DeepCollectionEquality().equals(other._suggestions, _suggestions));
}


@override
int get hashCode => Object.hash(runtimeType,message,const DeepCollectionEquality().hash(_suggestions));

@override
String toString() {
  return 'SentMessage(message: $message, suggestions: $suggestions)';
}


}

/// @nodoc
abstract mixin class _$SentMessageCopyWith<$Res> implements $SentMessageCopyWith<$Res> {
  factory _$SentMessageCopyWith(_SentMessage value, $Res Function(_SentMessage) _then) = __$SentMessageCopyWithImpl;
@override @useResult
$Res call({
 ChatMessage message, List<String>? suggestions
});


@override $ChatMessageCopyWith<$Res> get message;

}
/// @nodoc
class __$SentMessageCopyWithImpl<$Res>
    implements _$SentMessageCopyWith<$Res> {
  __$SentMessageCopyWithImpl(this._self, this._then);

  final _SentMessage _self;
  final $Res Function(_SentMessage) _then;

/// Create a copy of SentMessage
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? message = null,Object? suggestions = freezed,}) {
  return _then(_SentMessage(
message: null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as ChatMessage,suggestions: freezed == suggestions ? _self._suggestions : suggestions // ignore: cast_nullable_to_non_nullable
as List<String>?,
  ));
}

/// Create a copy of SentMessage
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ChatMessageCopyWith<$Res> get message {
  
  return $ChatMessageCopyWith<$Res>(_self.message, (value) {
    return _then(_self.copyWith(message: value));
  });
}
}

// dart format on
