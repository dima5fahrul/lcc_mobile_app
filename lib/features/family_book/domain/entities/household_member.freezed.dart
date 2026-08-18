// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'household_member.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$HouseholdMember {

/// `types.ts:587`. The React list key at `:458`; never rendered.
 String get id;/// `:495` — rendered as `{m.uin || "—"}`, so an empty string is a real
/// state with its own copy.
 String? get uin;/// `:482`, through `ReadField`'s own `value || "—"`.
 String get name;/// `:484` via `labelOf(GENDER_KEY, m.gender ?? "")`, and `:214`'s count via
/// `m.gender?.toLowerCase().startsWith("m")`.
 String? get gender;/// `:485`, `:556`. An ISO date string; the page never parses it.
 String? get dateOfBirth;/// `:487` via `labelOf(RELATION_KEY, m.relation ?? "")`, and `:456`'s
/// `isHeadRelation(m.relation ?? "")`.
 String? get relation;/// `:489` — rendered **raw**, through no lookup map, even though six
/// `nat*` labels sit in the namespace. See `family_book_derivations.dart`.
 String? get nationality;/// `:475-481`. Falsy — `null` **or** `''` — renders no element at all.
 String? get photoUrl;/// `:471` and `:490`, both raw.
 String? get status;/// `types.ts:589`, `:597`. Parsed, never rendered.
 String? get personId; int? get age;
/// Create a copy of HouseholdMember
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$HouseholdMemberCopyWith<HouseholdMember> get copyWith => _$HouseholdMemberCopyWithImpl<HouseholdMember>(this as HouseholdMember, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is HouseholdMember&&(identical(other.id, id) || other.id == id)&&(identical(other.uin, uin) || other.uin == uin)&&(identical(other.name, name) || other.name == name)&&(identical(other.gender, gender) || other.gender == gender)&&(identical(other.dateOfBirth, dateOfBirth) || other.dateOfBirth == dateOfBirth)&&(identical(other.relation, relation) || other.relation == relation)&&(identical(other.nationality, nationality) || other.nationality == nationality)&&(identical(other.photoUrl, photoUrl) || other.photoUrl == photoUrl)&&(identical(other.status, status) || other.status == status)&&(identical(other.personId, personId) || other.personId == personId)&&(identical(other.age, age) || other.age == age));
}


@override
int get hashCode => Object.hash(runtimeType,id,uin,name,gender,dateOfBirth,relation,nationality,photoUrl,status,personId,age);

@override
String toString() {
  return 'HouseholdMember(id: $id, uin: $uin, name: $name, gender: $gender, dateOfBirth: $dateOfBirth, relation: $relation, nationality: $nationality, photoUrl: $photoUrl, status: $status, personId: $personId, age: $age)';
}


}

/// @nodoc
abstract mixin class $HouseholdMemberCopyWith<$Res>  {
  factory $HouseholdMemberCopyWith(HouseholdMember value, $Res Function(HouseholdMember) _then) = _$HouseholdMemberCopyWithImpl;
@useResult
$Res call({
 String id, String? uin, String name, String? gender, String? dateOfBirth, String? relation, String? nationality, String? photoUrl, String? status, String? personId, int? age
});




}
/// @nodoc
class _$HouseholdMemberCopyWithImpl<$Res>
    implements $HouseholdMemberCopyWith<$Res> {
  _$HouseholdMemberCopyWithImpl(this._self, this._then);

  final HouseholdMember _self;
  final $Res Function(HouseholdMember) _then;

/// Create a copy of HouseholdMember
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? uin = freezed,Object? name = null,Object? gender = freezed,Object? dateOfBirth = freezed,Object? relation = freezed,Object? nationality = freezed,Object? photoUrl = freezed,Object? status = freezed,Object? personId = freezed,Object? age = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,uin: freezed == uin ? _self.uin : uin // ignore: cast_nullable_to_non_nullable
as String?,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,gender: freezed == gender ? _self.gender : gender // ignore: cast_nullable_to_non_nullable
as String?,dateOfBirth: freezed == dateOfBirth ? _self.dateOfBirth : dateOfBirth // ignore: cast_nullable_to_non_nullable
as String?,relation: freezed == relation ? _self.relation : relation // ignore: cast_nullable_to_non_nullable
as String?,nationality: freezed == nationality ? _self.nationality : nationality // ignore: cast_nullable_to_non_nullable
as String?,photoUrl: freezed == photoUrl ? _self.photoUrl : photoUrl // ignore: cast_nullable_to_non_nullable
as String?,status: freezed == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String?,personId: freezed == personId ? _self.personId : personId // ignore: cast_nullable_to_non_nullable
as String?,age: freezed == age ? _self.age : age // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}

}


/// Adds pattern-matching-related methods to [HouseholdMember].
extension HouseholdMemberPatterns on HouseholdMember {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _HouseholdMember value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _HouseholdMember() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _HouseholdMember value)  $default,){
final _that = this;
switch (_that) {
case _HouseholdMember():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _HouseholdMember value)?  $default,){
final _that = this;
switch (_that) {
case _HouseholdMember() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String? uin,  String name,  String? gender,  String? dateOfBirth,  String? relation,  String? nationality,  String? photoUrl,  String? status,  String? personId,  int? age)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _HouseholdMember() when $default != null:
return $default(_that.id,_that.uin,_that.name,_that.gender,_that.dateOfBirth,_that.relation,_that.nationality,_that.photoUrl,_that.status,_that.personId,_that.age);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String? uin,  String name,  String? gender,  String? dateOfBirth,  String? relation,  String? nationality,  String? photoUrl,  String? status,  String? personId,  int? age)  $default,) {final _that = this;
switch (_that) {
case _HouseholdMember():
return $default(_that.id,_that.uin,_that.name,_that.gender,_that.dateOfBirth,_that.relation,_that.nationality,_that.photoUrl,_that.status,_that.personId,_that.age);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String? uin,  String name,  String? gender,  String? dateOfBirth,  String? relation,  String? nationality,  String? photoUrl,  String? status,  String? personId,  int? age)?  $default,) {final _that = this;
switch (_that) {
case _HouseholdMember() when $default != null:
return $default(_that.id,_that.uin,_that.name,_that.gender,_that.dateOfBirth,_that.relation,_that.nationality,_that.photoUrl,_that.status,_that.personId,_that.age);case _:
  return null;

}
}

}

/// @nodoc


class _HouseholdMember extends HouseholdMember {
  const _HouseholdMember({required this.id, this.uin, this.name = '', this.gender, this.dateOfBirth, this.relation, this.nationality, this.photoUrl, this.status, this.personId, this.age}): super._();
  

/// `types.ts:587`. The React list key at `:458`; never rendered.
@override final  String id;
/// `:495` — rendered as `{m.uin || "—"}`, so an empty string is a real
/// state with its own copy.
@override final  String? uin;
/// `:482`, through `ReadField`'s own `value || "—"`.
@override@JsonKey() final  String name;
/// `:484` via `labelOf(GENDER_KEY, m.gender ?? "")`, and `:214`'s count via
/// `m.gender?.toLowerCase().startsWith("m")`.
@override final  String? gender;
/// `:485`, `:556`. An ISO date string; the page never parses it.
@override final  String? dateOfBirth;
/// `:487` via `labelOf(RELATION_KEY, m.relation ?? "")`, and `:456`'s
/// `isHeadRelation(m.relation ?? "")`.
@override final  String? relation;
/// `:489` — rendered **raw**, through no lookup map, even though six
/// `nat*` labels sit in the namespace. See `family_book_derivations.dart`.
@override final  String? nationality;
/// `:475-481`. Falsy — `null` **or** `''` — renders no element at all.
@override final  String? photoUrl;
/// `:471` and `:490`, both raw.
@override final  String? status;
/// `types.ts:589`, `:597`. Parsed, never rendered.
@override final  String? personId;
@override final  int? age;

/// Create a copy of HouseholdMember
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$HouseholdMemberCopyWith<_HouseholdMember> get copyWith => __$HouseholdMemberCopyWithImpl<_HouseholdMember>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _HouseholdMember&&(identical(other.id, id) || other.id == id)&&(identical(other.uin, uin) || other.uin == uin)&&(identical(other.name, name) || other.name == name)&&(identical(other.gender, gender) || other.gender == gender)&&(identical(other.dateOfBirth, dateOfBirth) || other.dateOfBirth == dateOfBirth)&&(identical(other.relation, relation) || other.relation == relation)&&(identical(other.nationality, nationality) || other.nationality == nationality)&&(identical(other.photoUrl, photoUrl) || other.photoUrl == photoUrl)&&(identical(other.status, status) || other.status == status)&&(identical(other.personId, personId) || other.personId == personId)&&(identical(other.age, age) || other.age == age));
}


@override
int get hashCode => Object.hash(runtimeType,id,uin,name,gender,dateOfBirth,relation,nationality,photoUrl,status,personId,age);

@override
String toString() {
  return 'HouseholdMember(id: $id, uin: $uin, name: $name, gender: $gender, dateOfBirth: $dateOfBirth, relation: $relation, nationality: $nationality, photoUrl: $photoUrl, status: $status, personId: $personId, age: $age)';
}


}

/// @nodoc
abstract mixin class _$HouseholdMemberCopyWith<$Res> implements $HouseholdMemberCopyWith<$Res> {
  factory _$HouseholdMemberCopyWith(_HouseholdMember value, $Res Function(_HouseholdMember) _then) = __$HouseholdMemberCopyWithImpl;
@override @useResult
$Res call({
 String id, String? uin, String name, String? gender, String? dateOfBirth, String? relation, String? nationality, String? photoUrl, String? status, String? personId, int? age
});




}
/// @nodoc
class __$HouseholdMemberCopyWithImpl<$Res>
    implements _$HouseholdMemberCopyWith<$Res> {
  __$HouseholdMemberCopyWithImpl(this._self, this._then);

  final _HouseholdMember _self;
  final $Res Function(_HouseholdMember) _then;

/// Create a copy of HouseholdMember
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? uin = freezed,Object? name = null,Object? gender = freezed,Object? dateOfBirth = freezed,Object? relation = freezed,Object? nationality = freezed,Object? photoUrl = freezed,Object? status = freezed,Object? personId = freezed,Object? age = freezed,}) {
  return _then(_HouseholdMember(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,uin: freezed == uin ? _self.uin : uin // ignore: cast_nullable_to_non_nullable
as String?,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,gender: freezed == gender ? _self.gender : gender // ignore: cast_nullable_to_non_nullable
as String?,dateOfBirth: freezed == dateOfBirth ? _self.dateOfBirth : dateOfBirth // ignore: cast_nullable_to_non_nullable
as String?,relation: freezed == relation ? _self.relation : relation // ignore: cast_nullable_to_non_nullable
as String?,nationality: freezed == nationality ? _self.nationality : nationality // ignore: cast_nullable_to_non_nullable
as String?,photoUrl: freezed == photoUrl ? _self.photoUrl : photoUrl // ignore: cast_nullable_to_non_nullable
as String?,status: freezed == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String?,personId: freezed == personId ? _self.personId : personId // ignore: cast_nullable_to_non_nullable
as String?,age: freezed == age ? _self.age : age // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}


}

// dart format on
