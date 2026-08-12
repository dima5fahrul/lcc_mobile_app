// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'citizen_account.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$CitizenAccount {

 String get id; String get uin; String get name; String get phone; String get email;@JsonKey(name: 'national_id_no') String get nationalIdNo;@JsonKey(name: 'date_of_birth') String get dateOfBirth; String get gender;@JsonKey(name: 'avatar_url') String? get avatarUrl;@JsonKey(name: 'preferred_lang') String get preferredLang; String get jurisdiction;@JsonKey(name: 'household_no') String get householdNo; String get address; bool get verified;@JsonKey(name: 'eid_verified') bool get eidVerified; bool get active;@JsonKey(name: 'last_login_at') String? get lastLoginAt;@JsonKey(name: 'created_at') String get createdAt;
/// Create a copy of CitizenAccount
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CitizenAccountCopyWith<CitizenAccount> get copyWith => _$CitizenAccountCopyWithImpl<CitizenAccount>(this as CitizenAccount, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CitizenAccount&&(identical(other.id, id) || other.id == id)&&(identical(other.uin, uin) || other.uin == uin)&&(identical(other.name, name) || other.name == name)&&(identical(other.phone, phone) || other.phone == phone)&&(identical(other.email, email) || other.email == email)&&(identical(other.nationalIdNo, nationalIdNo) || other.nationalIdNo == nationalIdNo)&&(identical(other.dateOfBirth, dateOfBirth) || other.dateOfBirth == dateOfBirth)&&(identical(other.gender, gender) || other.gender == gender)&&(identical(other.avatarUrl, avatarUrl) || other.avatarUrl == avatarUrl)&&(identical(other.preferredLang, preferredLang) || other.preferredLang == preferredLang)&&(identical(other.jurisdiction, jurisdiction) || other.jurisdiction == jurisdiction)&&(identical(other.householdNo, householdNo) || other.householdNo == householdNo)&&(identical(other.address, address) || other.address == address)&&(identical(other.verified, verified) || other.verified == verified)&&(identical(other.eidVerified, eidVerified) || other.eidVerified == eidVerified)&&(identical(other.active, active) || other.active == active)&&(identical(other.lastLoginAt, lastLoginAt) || other.lastLoginAt == lastLoginAt)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}


@override
int get hashCode => Object.hash(runtimeType,id,uin,name,phone,email,nationalIdNo,dateOfBirth,gender,avatarUrl,preferredLang,jurisdiction,householdNo,address,verified,eidVerified,active,lastLoginAt,createdAt);

@override
String toString() {
  return 'CitizenAccount(id: $id, uin: $uin, name: $name, phone: $phone, email: $email, nationalIdNo: $nationalIdNo, dateOfBirth: $dateOfBirth, gender: $gender, avatarUrl: $avatarUrl, preferredLang: $preferredLang, jurisdiction: $jurisdiction, householdNo: $householdNo, address: $address, verified: $verified, eidVerified: $eidVerified, active: $active, lastLoginAt: $lastLoginAt, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class $CitizenAccountCopyWith<$Res>  {
  factory $CitizenAccountCopyWith(CitizenAccount value, $Res Function(CitizenAccount) _then) = _$CitizenAccountCopyWithImpl;
@useResult
$Res call({
 String id, String uin, String name, String phone, String email,@JsonKey(name: 'national_id_no') String nationalIdNo,@JsonKey(name: 'date_of_birth') String dateOfBirth, String gender,@JsonKey(name: 'avatar_url') String? avatarUrl,@JsonKey(name: 'preferred_lang') String preferredLang, String jurisdiction,@JsonKey(name: 'household_no') String householdNo, String address, bool verified,@JsonKey(name: 'eid_verified') bool eidVerified, bool active,@JsonKey(name: 'last_login_at') String? lastLoginAt,@JsonKey(name: 'created_at') String createdAt
});




}
/// @nodoc
class _$CitizenAccountCopyWithImpl<$Res>
    implements $CitizenAccountCopyWith<$Res> {
  _$CitizenAccountCopyWithImpl(this._self, this._then);

  final CitizenAccount _self;
  final $Res Function(CitizenAccount) _then;

/// Create a copy of CitizenAccount
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? uin = null,Object? name = null,Object? phone = null,Object? email = null,Object? nationalIdNo = null,Object? dateOfBirth = null,Object? gender = null,Object? avatarUrl = freezed,Object? preferredLang = null,Object? jurisdiction = null,Object? householdNo = null,Object? address = null,Object? verified = null,Object? eidVerified = null,Object? active = null,Object? lastLoginAt = freezed,Object? createdAt = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,uin: null == uin ? _self.uin : uin // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,phone: null == phone ? _self.phone : phone // ignore: cast_nullable_to_non_nullable
as String,email: null == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String,nationalIdNo: null == nationalIdNo ? _self.nationalIdNo : nationalIdNo // ignore: cast_nullable_to_non_nullable
as String,dateOfBirth: null == dateOfBirth ? _self.dateOfBirth : dateOfBirth // ignore: cast_nullable_to_non_nullable
as String,gender: null == gender ? _self.gender : gender // ignore: cast_nullable_to_non_nullable
as String,avatarUrl: freezed == avatarUrl ? _self.avatarUrl : avatarUrl // ignore: cast_nullable_to_non_nullable
as String?,preferredLang: null == preferredLang ? _self.preferredLang : preferredLang // ignore: cast_nullable_to_non_nullable
as String,jurisdiction: null == jurisdiction ? _self.jurisdiction : jurisdiction // ignore: cast_nullable_to_non_nullable
as String,householdNo: null == householdNo ? _self.householdNo : householdNo // ignore: cast_nullable_to_non_nullable
as String,address: null == address ? _self.address : address // ignore: cast_nullable_to_non_nullable
as String,verified: null == verified ? _self.verified : verified // ignore: cast_nullable_to_non_nullable
as bool,eidVerified: null == eidVerified ? _self.eidVerified : eidVerified // ignore: cast_nullable_to_non_nullable
as bool,active: null == active ? _self.active : active // ignore: cast_nullable_to_non_nullable
as bool,lastLoginAt: freezed == lastLoginAt ? _self.lastLoginAt : lastLoginAt // ignore: cast_nullable_to_non_nullable
as String?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [CitizenAccount].
extension CitizenAccountPatterns on CitizenAccount {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CitizenAccount value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CitizenAccount() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CitizenAccount value)  $default,){
final _that = this;
switch (_that) {
case _CitizenAccount():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CitizenAccount value)?  $default,){
final _that = this;
switch (_that) {
case _CitizenAccount() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String uin,  String name,  String phone,  String email, @JsonKey(name: 'national_id_no')  String nationalIdNo, @JsonKey(name: 'date_of_birth')  String dateOfBirth,  String gender, @JsonKey(name: 'avatar_url')  String? avatarUrl, @JsonKey(name: 'preferred_lang')  String preferredLang,  String jurisdiction, @JsonKey(name: 'household_no')  String householdNo,  String address,  bool verified, @JsonKey(name: 'eid_verified')  bool eidVerified,  bool active, @JsonKey(name: 'last_login_at')  String? lastLoginAt, @JsonKey(name: 'created_at')  String createdAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CitizenAccount() when $default != null:
return $default(_that.id,_that.uin,_that.name,_that.phone,_that.email,_that.nationalIdNo,_that.dateOfBirth,_that.gender,_that.avatarUrl,_that.preferredLang,_that.jurisdiction,_that.householdNo,_that.address,_that.verified,_that.eidVerified,_that.active,_that.lastLoginAt,_that.createdAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String uin,  String name,  String phone,  String email, @JsonKey(name: 'national_id_no')  String nationalIdNo, @JsonKey(name: 'date_of_birth')  String dateOfBirth,  String gender, @JsonKey(name: 'avatar_url')  String? avatarUrl, @JsonKey(name: 'preferred_lang')  String preferredLang,  String jurisdiction, @JsonKey(name: 'household_no')  String householdNo,  String address,  bool verified, @JsonKey(name: 'eid_verified')  bool eidVerified,  bool active, @JsonKey(name: 'last_login_at')  String? lastLoginAt, @JsonKey(name: 'created_at')  String createdAt)  $default,) {final _that = this;
switch (_that) {
case _CitizenAccount():
return $default(_that.id,_that.uin,_that.name,_that.phone,_that.email,_that.nationalIdNo,_that.dateOfBirth,_that.gender,_that.avatarUrl,_that.preferredLang,_that.jurisdiction,_that.householdNo,_that.address,_that.verified,_that.eidVerified,_that.active,_that.lastLoginAt,_that.createdAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String uin,  String name,  String phone,  String email, @JsonKey(name: 'national_id_no')  String nationalIdNo, @JsonKey(name: 'date_of_birth')  String dateOfBirth,  String gender, @JsonKey(name: 'avatar_url')  String? avatarUrl, @JsonKey(name: 'preferred_lang')  String preferredLang,  String jurisdiction, @JsonKey(name: 'household_no')  String householdNo,  String address,  bool verified, @JsonKey(name: 'eid_verified')  bool eidVerified,  bool active, @JsonKey(name: 'last_login_at')  String? lastLoginAt, @JsonKey(name: 'created_at')  String createdAt)?  $default,) {final _that = this;
switch (_that) {
case _CitizenAccount() when $default != null:
return $default(_that.id,_that.uin,_that.name,_that.phone,_that.email,_that.nationalIdNo,_that.dateOfBirth,_that.gender,_that.avatarUrl,_that.preferredLang,_that.jurisdiction,_that.householdNo,_that.address,_that.verified,_that.eidVerified,_that.active,_that.lastLoginAt,_that.createdAt);case _:
  return null;

}
}

}

/// @nodoc


class _CitizenAccount implements CitizenAccount {
  const _CitizenAccount({required this.id, required this.uin, required this.name, required this.phone, required this.email, @JsonKey(name: 'national_id_no') required this.nationalIdNo, @JsonKey(name: 'date_of_birth') required this.dateOfBirth, required this.gender, @JsonKey(name: 'avatar_url') this.avatarUrl, @JsonKey(name: 'preferred_lang') required this.preferredLang, required this.jurisdiction, @JsonKey(name: 'household_no') required this.householdNo, required this.address, required this.verified, @JsonKey(name: 'eid_verified') required this.eidVerified, required this.active, @JsonKey(name: 'last_login_at') this.lastLoginAt, @JsonKey(name: 'created_at') required this.createdAt});
  

@override final  String id;
@override final  String uin;
@override final  String name;
@override final  String phone;
@override final  String email;
@override@JsonKey(name: 'national_id_no') final  String nationalIdNo;
@override@JsonKey(name: 'date_of_birth') final  String dateOfBirth;
@override final  String gender;
@override@JsonKey(name: 'avatar_url') final  String? avatarUrl;
@override@JsonKey(name: 'preferred_lang') final  String preferredLang;
@override final  String jurisdiction;
@override@JsonKey(name: 'household_no') final  String householdNo;
@override final  String address;
@override final  bool verified;
@override@JsonKey(name: 'eid_verified') final  bool eidVerified;
@override final  bool active;
@override@JsonKey(name: 'last_login_at') final  String? lastLoginAt;
@override@JsonKey(name: 'created_at') final  String createdAt;

/// Create a copy of CitizenAccount
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CitizenAccountCopyWith<_CitizenAccount> get copyWith => __$CitizenAccountCopyWithImpl<_CitizenAccount>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CitizenAccount&&(identical(other.id, id) || other.id == id)&&(identical(other.uin, uin) || other.uin == uin)&&(identical(other.name, name) || other.name == name)&&(identical(other.phone, phone) || other.phone == phone)&&(identical(other.email, email) || other.email == email)&&(identical(other.nationalIdNo, nationalIdNo) || other.nationalIdNo == nationalIdNo)&&(identical(other.dateOfBirth, dateOfBirth) || other.dateOfBirth == dateOfBirth)&&(identical(other.gender, gender) || other.gender == gender)&&(identical(other.avatarUrl, avatarUrl) || other.avatarUrl == avatarUrl)&&(identical(other.preferredLang, preferredLang) || other.preferredLang == preferredLang)&&(identical(other.jurisdiction, jurisdiction) || other.jurisdiction == jurisdiction)&&(identical(other.householdNo, householdNo) || other.householdNo == householdNo)&&(identical(other.address, address) || other.address == address)&&(identical(other.verified, verified) || other.verified == verified)&&(identical(other.eidVerified, eidVerified) || other.eidVerified == eidVerified)&&(identical(other.active, active) || other.active == active)&&(identical(other.lastLoginAt, lastLoginAt) || other.lastLoginAt == lastLoginAt)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}


@override
int get hashCode => Object.hash(runtimeType,id,uin,name,phone,email,nationalIdNo,dateOfBirth,gender,avatarUrl,preferredLang,jurisdiction,householdNo,address,verified,eidVerified,active,lastLoginAt,createdAt);

@override
String toString() {
  return 'CitizenAccount(id: $id, uin: $uin, name: $name, phone: $phone, email: $email, nationalIdNo: $nationalIdNo, dateOfBirth: $dateOfBirth, gender: $gender, avatarUrl: $avatarUrl, preferredLang: $preferredLang, jurisdiction: $jurisdiction, householdNo: $householdNo, address: $address, verified: $verified, eidVerified: $eidVerified, active: $active, lastLoginAt: $lastLoginAt, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class _$CitizenAccountCopyWith<$Res> implements $CitizenAccountCopyWith<$Res> {
  factory _$CitizenAccountCopyWith(_CitizenAccount value, $Res Function(_CitizenAccount) _then) = __$CitizenAccountCopyWithImpl;
@override @useResult
$Res call({
 String id, String uin, String name, String phone, String email,@JsonKey(name: 'national_id_no') String nationalIdNo,@JsonKey(name: 'date_of_birth') String dateOfBirth, String gender,@JsonKey(name: 'avatar_url') String? avatarUrl,@JsonKey(name: 'preferred_lang') String preferredLang, String jurisdiction,@JsonKey(name: 'household_no') String householdNo, String address, bool verified,@JsonKey(name: 'eid_verified') bool eidVerified, bool active,@JsonKey(name: 'last_login_at') String? lastLoginAt,@JsonKey(name: 'created_at') String createdAt
});




}
/// @nodoc
class __$CitizenAccountCopyWithImpl<$Res>
    implements _$CitizenAccountCopyWith<$Res> {
  __$CitizenAccountCopyWithImpl(this._self, this._then);

  final _CitizenAccount _self;
  final $Res Function(_CitizenAccount) _then;

/// Create a copy of CitizenAccount
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? uin = null,Object? name = null,Object? phone = null,Object? email = null,Object? nationalIdNo = null,Object? dateOfBirth = null,Object? gender = null,Object? avatarUrl = freezed,Object? preferredLang = null,Object? jurisdiction = null,Object? householdNo = null,Object? address = null,Object? verified = null,Object? eidVerified = null,Object? active = null,Object? lastLoginAt = freezed,Object? createdAt = null,}) {
  return _then(_CitizenAccount(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,uin: null == uin ? _self.uin : uin // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,phone: null == phone ? _self.phone : phone // ignore: cast_nullable_to_non_nullable
as String,email: null == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String,nationalIdNo: null == nationalIdNo ? _self.nationalIdNo : nationalIdNo // ignore: cast_nullable_to_non_nullable
as String,dateOfBirth: null == dateOfBirth ? _self.dateOfBirth : dateOfBirth // ignore: cast_nullable_to_non_nullable
as String,gender: null == gender ? _self.gender : gender // ignore: cast_nullable_to_non_nullable
as String,avatarUrl: freezed == avatarUrl ? _self.avatarUrl : avatarUrl // ignore: cast_nullable_to_non_nullable
as String?,preferredLang: null == preferredLang ? _self.preferredLang : preferredLang // ignore: cast_nullable_to_non_nullable
as String,jurisdiction: null == jurisdiction ? _self.jurisdiction : jurisdiction // ignore: cast_nullable_to_non_nullable
as String,householdNo: null == householdNo ? _self.householdNo : householdNo // ignore: cast_nullable_to_non_nullable
as String,address: null == address ? _self.address : address // ignore: cast_nullable_to_non_nullable
as String,verified: null == verified ? _self.verified : verified // ignore: cast_nullable_to_non_nullable
as bool,eidVerified: null == eidVerified ? _self.eidVerified : eidVerified // ignore: cast_nullable_to_non_nullable
as bool,active: null == active ? _self.active : active // ignore: cast_nullable_to_non_nullable
as bool,lastLoginAt: freezed == lastLoginAt ? _self.lastLoginAt : lastLoginAt // ignore: cast_nullable_to_non_nullable
as String?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
