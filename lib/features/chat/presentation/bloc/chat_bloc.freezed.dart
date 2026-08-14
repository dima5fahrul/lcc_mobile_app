// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'chat_bloc.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$ChatState {

/// The `isAuthenticated` prop — `:30`.
 bool get isAuthenticated;/// `const [open, setOpen] = useState(false)` — `:32`.
 bool get open;/// `:33`. Minimised means the panel is on screen at 64 px showing only its
/// header; it is **not** closed, and the distinction is what makes [live]
/// four conditions rather than three.
 bool get minimized;/// `:34`. Null means "no conversation yet"; the next message starts one.
 String? get threadId;/// `:35` — the composer's contents. See [ChatInputChanged].
 String get input;/// `:36` — the optimistic bubble's text while a send is in flight
/// (`:411-428`). Cleared in the `finally`, so it disappears on success and
/// on failure alike; on failure [input] gets the text back instead
/// (§ 6.9(4)).
 String? get pendingText;/// `:37` — whether the rate-and-close strip is showing. Not the rating
/// itself: the stars are tapped, not held.
 bool get ratingOpen;/// `threads.data ?? []` — `:67`.
 List<ChatThread> get threads; ChatRegionStatus get threadsStatus;/// `transcript.data?.data ?? []` — `:89`, **before** the `threadId` guard.
/// Read through [messages], never directly.
 List<ChatMessage> get transcript; ChatRegionStatus get transcriptStatus;/// `hasData` — `hooks.ts:56`. True once a transcript request has
/// **succeeded**, and never false again. It is what distinguishes the first
/// open (spinner) from a poll (no spinner) — `:317`'s
/// `transcript.loading && messages.length === 0`.
 bool get transcriptLoaded;/// `channels.data ?? []` — `:51`. Fetched only while the panel is open
/// (`enabled: open`, `:48`).
///
/// **No status field.** The source renders neither a loading nor an error
/// state for it: an unresolved channel simply means no button (`:239`,
/// `:249`). A status nothing can render would be state a test could assert
/// and a citizen could never see.
 List<SupportChannel> get channels;/// `start.pending` — `:115`.
 bool get startPending;/// `sendOne.pending` — `:115`.
 bool get sendPending;/// `closeThread.pending` — `:476`, which disables the stars mid-close.
 bool get closePending;/// `const ended = useRef<Set<string>>(new Set())` — `:61`.
///
/// Threads closed in this session. The id is added **before** the close
/// call (`:155`) so *"a stale list cannot re-adopt one between the close
/// call and the next poll"* (`:59-60`). BLoC state, not a `static`
/// (§ 6.9(3), B9-AC-20).
 Set<String> get ended;
/// Create a copy of ChatState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ChatStateCopyWith<ChatState> get copyWith => _$ChatStateCopyWithImpl<ChatState>(this as ChatState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ChatState&&(identical(other.isAuthenticated, isAuthenticated) || other.isAuthenticated == isAuthenticated)&&(identical(other.open, open) || other.open == open)&&(identical(other.minimized, minimized) || other.minimized == minimized)&&(identical(other.threadId, threadId) || other.threadId == threadId)&&(identical(other.input, input) || other.input == input)&&(identical(other.pendingText, pendingText) || other.pendingText == pendingText)&&(identical(other.ratingOpen, ratingOpen) || other.ratingOpen == ratingOpen)&&const DeepCollectionEquality().equals(other.threads, threads)&&(identical(other.threadsStatus, threadsStatus) || other.threadsStatus == threadsStatus)&&const DeepCollectionEquality().equals(other.transcript, transcript)&&(identical(other.transcriptStatus, transcriptStatus) || other.transcriptStatus == transcriptStatus)&&(identical(other.transcriptLoaded, transcriptLoaded) || other.transcriptLoaded == transcriptLoaded)&&const DeepCollectionEquality().equals(other.channels, channels)&&(identical(other.startPending, startPending) || other.startPending == startPending)&&(identical(other.sendPending, sendPending) || other.sendPending == sendPending)&&(identical(other.closePending, closePending) || other.closePending == closePending)&&const DeepCollectionEquality().equals(other.ended, ended));
}


@override
int get hashCode => Object.hash(runtimeType,isAuthenticated,open,minimized,threadId,input,pendingText,ratingOpen,const DeepCollectionEquality().hash(threads),threadsStatus,const DeepCollectionEquality().hash(transcript),transcriptStatus,transcriptLoaded,const DeepCollectionEquality().hash(channels),startPending,sendPending,closePending,const DeepCollectionEquality().hash(ended));

@override
String toString() {
  return 'ChatState(isAuthenticated: $isAuthenticated, open: $open, minimized: $minimized, threadId: $threadId, input: $input, pendingText: $pendingText, ratingOpen: $ratingOpen, threads: $threads, threadsStatus: $threadsStatus, transcript: $transcript, transcriptStatus: $transcriptStatus, transcriptLoaded: $transcriptLoaded, channels: $channels, startPending: $startPending, sendPending: $sendPending, closePending: $closePending, ended: $ended)';
}


}

/// @nodoc
abstract mixin class $ChatStateCopyWith<$Res>  {
  factory $ChatStateCopyWith(ChatState value, $Res Function(ChatState) _then) = _$ChatStateCopyWithImpl;
@useResult
$Res call({
 bool isAuthenticated, bool open, bool minimized, String? threadId, String input, String? pendingText, bool ratingOpen, List<ChatThread> threads, ChatRegionStatus threadsStatus, List<ChatMessage> transcript, ChatRegionStatus transcriptStatus, bool transcriptLoaded, List<SupportChannel> channels, bool startPending, bool sendPending, bool closePending, Set<String> ended
});




}
/// @nodoc
class _$ChatStateCopyWithImpl<$Res>
    implements $ChatStateCopyWith<$Res> {
  _$ChatStateCopyWithImpl(this._self, this._then);

  final ChatState _self;
  final $Res Function(ChatState) _then;

/// Create a copy of ChatState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? isAuthenticated = null,Object? open = null,Object? minimized = null,Object? threadId = freezed,Object? input = null,Object? pendingText = freezed,Object? ratingOpen = null,Object? threads = null,Object? threadsStatus = null,Object? transcript = null,Object? transcriptStatus = null,Object? transcriptLoaded = null,Object? channels = null,Object? startPending = null,Object? sendPending = null,Object? closePending = null,Object? ended = null,}) {
  return _then(_self.copyWith(
isAuthenticated: null == isAuthenticated ? _self.isAuthenticated : isAuthenticated // ignore: cast_nullable_to_non_nullable
as bool,open: null == open ? _self.open : open // ignore: cast_nullable_to_non_nullable
as bool,minimized: null == minimized ? _self.minimized : minimized // ignore: cast_nullable_to_non_nullable
as bool,threadId: freezed == threadId ? _self.threadId : threadId // ignore: cast_nullable_to_non_nullable
as String?,input: null == input ? _self.input : input // ignore: cast_nullable_to_non_nullable
as String,pendingText: freezed == pendingText ? _self.pendingText : pendingText // ignore: cast_nullable_to_non_nullable
as String?,ratingOpen: null == ratingOpen ? _self.ratingOpen : ratingOpen // ignore: cast_nullable_to_non_nullable
as bool,threads: null == threads ? _self.threads : threads // ignore: cast_nullable_to_non_nullable
as List<ChatThread>,threadsStatus: null == threadsStatus ? _self.threadsStatus : threadsStatus // ignore: cast_nullable_to_non_nullable
as ChatRegionStatus,transcript: null == transcript ? _self.transcript : transcript // ignore: cast_nullable_to_non_nullable
as List<ChatMessage>,transcriptStatus: null == transcriptStatus ? _self.transcriptStatus : transcriptStatus // ignore: cast_nullable_to_non_nullable
as ChatRegionStatus,transcriptLoaded: null == transcriptLoaded ? _self.transcriptLoaded : transcriptLoaded // ignore: cast_nullable_to_non_nullable
as bool,channels: null == channels ? _self.channels : channels // ignore: cast_nullable_to_non_nullable
as List<SupportChannel>,startPending: null == startPending ? _self.startPending : startPending // ignore: cast_nullable_to_non_nullable
as bool,sendPending: null == sendPending ? _self.sendPending : sendPending // ignore: cast_nullable_to_non_nullable
as bool,closePending: null == closePending ? _self.closePending : closePending // ignore: cast_nullable_to_non_nullable
as bool,ended: null == ended ? _self.ended : ended // ignore: cast_nullable_to_non_nullable
as Set<String>,
  ));
}

}


/// Adds pattern-matching-related methods to [ChatState].
extension ChatStatePatterns on ChatState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ChatState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ChatState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ChatState value)  $default,){
final _that = this;
switch (_that) {
case _ChatState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ChatState value)?  $default,){
final _that = this;
switch (_that) {
case _ChatState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( bool isAuthenticated,  bool open,  bool minimized,  String? threadId,  String input,  String? pendingText,  bool ratingOpen,  List<ChatThread> threads,  ChatRegionStatus threadsStatus,  List<ChatMessage> transcript,  ChatRegionStatus transcriptStatus,  bool transcriptLoaded,  List<SupportChannel> channels,  bool startPending,  bool sendPending,  bool closePending,  Set<String> ended)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ChatState() when $default != null:
return $default(_that.isAuthenticated,_that.open,_that.minimized,_that.threadId,_that.input,_that.pendingText,_that.ratingOpen,_that.threads,_that.threadsStatus,_that.transcript,_that.transcriptStatus,_that.transcriptLoaded,_that.channels,_that.startPending,_that.sendPending,_that.closePending,_that.ended);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( bool isAuthenticated,  bool open,  bool minimized,  String? threadId,  String input,  String? pendingText,  bool ratingOpen,  List<ChatThread> threads,  ChatRegionStatus threadsStatus,  List<ChatMessage> transcript,  ChatRegionStatus transcriptStatus,  bool transcriptLoaded,  List<SupportChannel> channels,  bool startPending,  bool sendPending,  bool closePending,  Set<String> ended)  $default,) {final _that = this;
switch (_that) {
case _ChatState():
return $default(_that.isAuthenticated,_that.open,_that.minimized,_that.threadId,_that.input,_that.pendingText,_that.ratingOpen,_that.threads,_that.threadsStatus,_that.transcript,_that.transcriptStatus,_that.transcriptLoaded,_that.channels,_that.startPending,_that.sendPending,_that.closePending,_that.ended);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( bool isAuthenticated,  bool open,  bool minimized,  String? threadId,  String input,  String? pendingText,  bool ratingOpen,  List<ChatThread> threads,  ChatRegionStatus threadsStatus,  List<ChatMessage> transcript,  ChatRegionStatus transcriptStatus,  bool transcriptLoaded,  List<SupportChannel> channels,  bool startPending,  bool sendPending,  bool closePending,  Set<String> ended)?  $default,) {final _that = this;
switch (_that) {
case _ChatState() when $default != null:
return $default(_that.isAuthenticated,_that.open,_that.minimized,_that.threadId,_that.input,_that.pendingText,_that.ratingOpen,_that.threads,_that.threadsStatus,_that.transcript,_that.transcriptStatus,_that.transcriptLoaded,_that.channels,_that.startPending,_that.sendPending,_that.closePending,_that.ended);case _:
  return null;

}
}

}

/// @nodoc


class _ChatState extends ChatState {
  const _ChatState({this.isAuthenticated = false, this.open = false, this.minimized = false, this.threadId, this.input = '', this.pendingText, this.ratingOpen = false, final  List<ChatThread> threads = const <ChatThread>[], this.threadsStatus = ChatRegionStatus.initial, final  List<ChatMessage> transcript = const <ChatMessage>[], this.transcriptStatus = ChatRegionStatus.initial, this.transcriptLoaded = false, final  List<SupportChannel> channels = const <SupportChannel>[], this.startPending = false, this.sendPending = false, this.closePending = false, final  Set<String> ended = const <String>{}}): _threads = threads,_transcript = transcript,_channels = channels,_ended = ended,super._();
  

/// The `isAuthenticated` prop — `:30`.
@override@JsonKey() final  bool isAuthenticated;
/// `const [open, setOpen] = useState(false)` — `:32`.
@override@JsonKey() final  bool open;
/// `:33`. Minimised means the panel is on screen at 64 px showing only its
/// header; it is **not** closed, and the distinction is what makes [live]
/// four conditions rather than three.
@override@JsonKey() final  bool minimized;
/// `:34`. Null means "no conversation yet"; the next message starts one.
@override final  String? threadId;
/// `:35` — the composer's contents. See [ChatInputChanged].
@override@JsonKey() final  String input;
/// `:36` — the optimistic bubble's text while a send is in flight
/// (`:411-428`). Cleared in the `finally`, so it disappears on success and
/// on failure alike; on failure [input] gets the text back instead
/// (§ 6.9(4)).
@override final  String? pendingText;
/// `:37` — whether the rate-and-close strip is showing. Not the rating
/// itself: the stars are tapped, not held.
@override@JsonKey() final  bool ratingOpen;
/// `threads.data ?? []` — `:67`.
 final  List<ChatThread> _threads;
/// `threads.data ?? []` — `:67`.
@override@JsonKey() List<ChatThread> get threads {
  if (_threads is EqualUnmodifiableListView) return _threads;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_threads);
}

@override@JsonKey() final  ChatRegionStatus threadsStatus;
/// `transcript.data?.data ?? []` — `:89`, **before** the `threadId` guard.
/// Read through [messages], never directly.
 final  List<ChatMessage> _transcript;
/// `transcript.data?.data ?? []` — `:89`, **before** the `threadId` guard.
/// Read through [messages], never directly.
@override@JsonKey() List<ChatMessage> get transcript {
  if (_transcript is EqualUnmodifiableListView) return _transcript;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_transcript);
}

@override@JsonKey() final  ChatRegionStatus transcriptStatus;
/// `hasData` — `hooks.ts:56`. True once a transcript request has
/// **succeeded**, and never false again. It is what distinguishes the first
/// open (spinner) from a poll (no spinner) — `:317`'s
/// `transcript.loading && messages.length === 0`.
@override@JsonKey() final  bool transcriptLoaded;
/// `channels.data ?? []` — `:51`. Fetched only while the panel is open
/// (`enabled: open`, `:48`).
///
/// **No status field.** The source renders neither a loading nor an error
/// state for it: an unresolved channel simply means no button (`:239`,
/// `:249`). A status nothing can render would be state a test could assert
/// and a citizen could never see.
 final  List<SupportChannel> _channels;
/// `channels.data ?? []` — `:51`. Fetched only while the panel is open
/// (`enabled: open`, `:48`).
///
/// **No status field.** The source renders neither a loading nor an error
/// state for it: an unresolved channel simply means no button (`:239`,
/// `:249`). A status nothing can render would be state a test could assert
/// and a citizen could never see.
@override@JsonKey() List<SupportChannel> get channels {
  if (_channels is EqualUnmodifiableListView) return _channels;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_channels);
}

/// `start.pending` — `:115`.
@override@JsonKey() final  bool startPending;
/// `sendOne.pending` — `:115`.
@override@JsonKey() final  bool sendPending;
/// `closeThread.pending` — `:476`, which disables the stars mid-close.
@override@JsonKey() final  bool closePending;
/// `const ended = useRef<Set<string>>(new Set())` — `:61`.
///
/// Threads closed in this session. The id is added **before** the close
/// call (`:155`) so *"a stale list cannot re-adopt one between the close
/// call and the next poll"* (`:59-60`). BLoC state, not a `static`
/// (§ 6.9(3), B9-AC-20).
 final  Set<String> _ended;
/// `const ended = useRef<Set<string>>(new Set())` — `:61`.
///
/// Threads closed in this session. The id is added **before** the close
/// call (`:155`) so *"a stale list cannot re-adopt one between the close
/// call and the next poll"* (`:59-60`). BLoC state, not a `static`
/// (§ 6.9(3), B9-AC-20).
@override@JsonKey() Set<String> get ended {
  if (_ended is EqualUnmodifiableSetView) return _ended;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableSetView(_ended);
}


/// Create a copy of ChatState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ChatStateCopyWith<_ChatState> get copyWith => __$ChatStateCopyWithImpl<_ChatState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ChatState&&(identical(other.isAuthenticated, isAuthenticated) || other.isAuthenticated == isAuthenticated)&&(identical(other.open, open) || other.open == open)&&(identical(other.minimized, minimized) || other.minimized == minimized)&&(identical(other.threadId, threadId) || other.threadId == threadId)&&(identical(other.input, input) || other.input == input)&&(identical(other.pendingText, pendingText) || other.pendingText == pendingText)&&(identical(other.ratingOpen, ratingOpen) || other.ratingOpen == ratingOpen)&&const DeepCollectionEquality().equals(other._threads, _threads)&&(identical(other.threadsStatus, threadsStatus) || other.threadsStatus == threadsStatus)&&const DeepCollectionEquality().equals(other._transcript, _transcript)&&(identical(other.transcriptStatus, transcriptStatus) || other.transcriptStatus == transcriptStatus)&&(identical(other.transcriptLoaded, transcriptLoaded) || other.transcriptLoaded == transcriptLoaded)&&const DeepCollectionEquality().equals(other._channels, _channels)&&(identical(other.startPending, startPending) || other.startPending == startPending)&&(identical(other.sendPending, sendPending) || other.sendPending == sendPending)&&(identical(other.closePending, closePending) || other.closePending == closePending)&&const DeepCollectionEquality().equals(other._ended, _ended));
}


@override
int get hashCode => Object.hash(runtimeType,isAuthenticated,open,minimized,threadId,input,pendingText,ratingOpen,const DeepCollectionEquality().hash(_threads),threadsStatus,const DeepCollectionEquality().hash(_transcript),transcriptStatus,transcriptLoaded,const DeepCollectionEquality().hash(_channels),startPending,sendPending,closePending,const DeepCollectionEquality().hash(_ended));

@override
String toString() {
  return 'ChatState(isAuthenticated: $isAuthenticated, open: $open, minimized: $minimized, threadId: $threadId, input: $input, pendingText: $pendingText, ratingOpen: $ratingOpen, threads: $threads, threadsStatus: $threadsStatus, transcript: $transcript, transcriptStatus: $transcriptStatus, transcriptLoaded: $transcriptLoaded, channels: $channels, startPending: $startPending, sendPending: $sendPending, closePending: $closePending, ended: $ended)';
}


}

/// @nodoc
abstract mixin class _$ChatStateCopyWith<$Res> implements $ChatStateCopyWith<$Res> {
  factory _$ChatStateCopyWith(_ChatState value, $Res Function(_ChatState) _then) = __$ChatStateCopyWithImpl;
@override @useResult
$Res call({
 bool isAuthenticated, bool open, bool minimized, String? threadId, String input, String? pendingText, bool ratingOpen, List<ChatThread> threads, ChatRegionStatus threadsStatus, List<ChatMessage> transcript, ChatRegionStatus transcriptStatus, bool transcriptLoaded, List<SupportChannel> channels, bool startPending, bool sendPending, bool closePending, Set<String> ended
});




}
/// @nodoc
class __$ChatStateCopyWithImpl<$Res>
    implements _$ChatStateCopyWith<$Res> {
  __$ChatStateCopyWithImpl(this._self, this._then);

  final _ChatState _self;
  final $Res Function(_ChatState) _then;

/// Create a copy of ChatState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? isAuthenticated = null,Object? open = null,Object? minimized = null,Object? threadId = freezed,Object? input = null,Object? pendingText = freezed,Object? ratingOpen = null,Object? threads = null,Object? threadsStatus = null,Object? transcript = null,Object? transcriptStatus = null,Object? transcriptLoaded = null,Object? channels = null,Object? startPending = null,Object? sendPending = null,Object? closePending = null,Object? ended = null,}) {
  return _then(_ChatState(
isAuthenticated: null == isAuthenticated ? _self.isAuthenticated : isAuthenticated // ignore: cast_nullable_to_non_nullable
as bool,open: null == open ? _self.open : open // ignore: cast_nullable_to_non_nullable
as bool,minimized: null == minimized ? _self.minimized : minimized // ignore: cast_nullable_to_non_nullable
as bool,threadId: freezed == threadId ? _self.threadId : threadId // ignore: cast_nullable_to_non_nullable
as String?,input: null == input ? _self.input : input // ignore: cast_nullable_to_non_nullable
as String,pendingText: freezed == pendingText ? _self.pendingText : pendingText // ignore: cast_nullable_to_non_nullable
as String?,ratingOpen: null == ratingOpen ? _self.ratingOpen : ratingOpen // ignore: cast_nullable_to_non_nullable
as bool,threads: null == threads ? _self._threads : threads // ignore: cast_nullable_to_non_nullable
as List<ChatThread>,threadsStatus: null == threadsStatus ? _self.threadsStatus : threadsStatus // ignore: cast_nullable_to_non_nullable
as ChatRegionStatus,transcript: null == transcript ? _self._transcript : transcript // ignore: cast_nullable_to_non_nullable
as List<ChatMessage>,transcriptStatus: null == transcriptStatus ? _self.transcriptStatus : transcriptStatus // ignore: cast_nullable_to_non_nullable
as ChatRegionStatus,transcriptLoaded: null == transcriptLoaded ? _self.transcriptLoaded : transcriptLoaded // ignore: cast_nullable_to_non_nullable
as bool,channels: null == channels ? _self._channels : channels // ignore: cast_nullable_to_non_nullable
as List<SupportChannel>,startPending: null == startPending ? _self.startPending : startPending // ignore: cast_nullable_to_non_nullable
as bool,sendPending: null == sendPending ? _self.sendPending : sendPending // ignore: cast_nullable_to_non_nullable
as bool,closePending: null == closePending ? _self.closePending : closePending // ignore: cast_nullable_to_non_nullable
as bool,ended: null == ended ? _self._ended : ended // ignore: cast_nullable_to_non_nullable
as Set<String>,
  ));
}


}

// dart format on
