// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'home_faq_item.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$HomeFaqItem {

 String get id; Bilingual get question; Bilingual get answer;
/// Create a copy of HomeFaqItem
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$HomeFaqItemCopyWith<HomeFaqItem> get copyWith => _$HomeFaqItemCopyWithImpl<HomeFaqItem>(this as HomeFaqItem, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is HomeFaqItem&&(identical(other.id, id) || other.id == id)&&(identical(other.question, question) || other.question == question)&&(identical(other.answer, answer) || other.answer == answer));
}


@override
int get hashCode => Object.hash(runtimeType,id,question,answer);

@override
String toString() {
  return 'HomeFaqItem(id: $id, question: $question, answer: $answer)';
}


}

/// @nodoc
abstract mixin class $HomeFaqItemCopyWith<$Res>  {
  factory $HomeFaqItemCopyWith(HomeFaqItem value, $Res Function(HomeFaqItem) _then) = _$HomeFaqItemCopyWithImpl;
@useResult
$Res call({
 String id, Bilingual question, Bilingual answer
});


$BilingualCopyWith<$Res> get question;$BilingualCopyWith<$Res> get answer;

}
/// @nodoc
class _$HomeFaqItemCopyWithImpl<$Res>
    implements $HomeFaqItemCopyWith<$Res> {
  _$HomeFaqItemCopyWithImpl(this._self, this._then);

  final HomeFaqItem _self;
  final $Res Function(HomeFaqItem) _then;

/// Create a copy of HomeFaqItem
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? question = null,Object? answer = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,question: null == question ? _self.question : question // ignore: cast_nullable_to_non_nullable
as Bilingual,answer: null == answer ? _self.answer : answer // ignore: cast_nullable_to_non_nullable
as Bilingual,
  ));
}
/// Create a copy of HomeFaqItem
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BilingualCopyWith<$Res> get question {
  
  return $BilingualCopyWith<$Res>(_self.question, (value) {
    return _then(_self.copyWith(question: value));
  });
}/// Create a copy of HomeFaqItem
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BilingualCopyWith<$Res> get answer {
  
  return $BilingualCopyWith<$Res>(_self.answer, (value) {
    return _then(_self.copyWith(answer: value));
  });
}
}


/// Adds pattern-matching-related methods to [HomeFaqItem].
extension HomeFaqItemPatterns on HomeFaqItem {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _HomeFaqItem value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _HomeFaqItem() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _HomeFaqItem value)  $default,){
final _that = this;
switch (_that) {
case _HomeFaqItem():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _HomeFaqItem value)?  $default,){
final _that = this;
switch (_that) {
case _HomeFaqItem() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  Bilingual question,  Bilingual answer)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _HomeFaqItem() when $default != null:
return $default(_that.id,_that.question,_that.answer);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  Bilingual question,  Bilingual answer)  $default,) {final _that = this;
switch (_that) {
case _HomeFaqItem():
return $default(_that.id,_that.question,_that.answer);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  Bilingual question,  Bilingual answer)?  $default,) {final _that = this;
switch (_that) {
case _HomeFaqItem() when $default != null:
return $default(_that.id,_that.question,_that.answer);case _:
  return null;

}
}

}

/// @nodoc


class _HomeFaqItem implements HomeFaqItem {
  const _HomeFaqItem({this.id = '', this.question = const Bilingual(en: '', lo: ''), this.answer = const Bilingual(en: '', lo: '')});
  

@override@JsonKey() final  String id;
@override@JsonKey() final  Bilingual question;
@override@JsonKey() final  Bilingual answer;

/// Create a copy of HomeFaqItem
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$HomeFaqItemCopyWith<_HomeFaqItem> get copyWith => __$HomeFaqItemCopyWithImpl<_HomeFaqItem>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _HomeFaqItem&&(identical(other.id, id) || other.id == id)&&(identical(other.question, question) || other.question == question)&&(identical(other.answer, answer) || other.answer == answer));
}


@override
int get hashCode => Object.hash(runtimeType,id,question,answer);

@override
String toString() {
  return 'HomeFaqItem(id: $id, question: $question, answer: $answer)';
}


}

/// @nodoc
abstract mixin class _$HomeFaqItemCopyWith<$Res> implements $HomeFaqItemCopyWith<$Res> {
  factory _$HomeFaqItemCopyWith(_HomeFaqItem value, $Res Function(_HomeFaqItem) _then) = __$HomeFaqItemCopyWithImpl;
@override @useResult
$Res call({
 String id, Bilingual question, Bilingual answer
});


@override $BilingualCopyWith<$Res> get question;@override $BilingualCopyWith<$Res> get answer;

}
/// @nodoc
class __$HomeFaqItemCopyWithImpl<$Res>
    implements _$HomeFaqItemCopyWith<$Res> {
  __$HomeFaqItemCopyWithImpl(this._self, this._then);

  final _HomeFaqItem _self;
  final $Res Function(_HomeFaqItem) _then;

/// Create a copy of HomeFaqItem
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? question = null,Object? answer = null,}) {
  return _then(_HomeFaqItem(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,question: null == question ? _self.question : question // ignore: cast_nullable_to_non_nullable
as Bilingual,answer: null == answer ? _self.answer : answer // ignore: cast_nullable_to_non_nullable
as Bilingual,
  ));
}

/// Create a copy of HomeFaqItem
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BilingualCopyWith<$Res> get question {
  
  return $BilingualCopyWith<$Res>(_self.question, (value) {
    return _then(_self.copyWith(question: value));
  });
}/// Create a copy of HomeFaqItem
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BilingualCopyWith<$Res> get answer {
  
  return $BilingualCopyWith<$Res>(_self.answer, (value) {
    return _then(_self.copyWith(answer: value));
  });
}
}

// dart format on
