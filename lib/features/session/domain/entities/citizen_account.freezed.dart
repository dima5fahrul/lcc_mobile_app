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

 String get id; String get name; String get phone; String get email;@JsonKey(name: 'preferred_lang') String get preferredLang; bool get verified;@JsonKey(name: 'eid_verified') bool get eidVerified; bool get active;@JsonKey(name: 'created_at') String get createdAt;// ── Absent from a real staging payload, 2026-08-19 ──────────────────────
//
// `types.ts` declares all six required. Staging sends none of them for an
// unverified account created 2026-08-12. Nullable so a login succeeds; the
// divergence from the source's declaration is stated in the library doc
// above rather than hidden behind a default.
 String? get uin;@JsonKey(name: 'national_id_no') String? get nationalIdNo;@JsonKey(name: 'date_of_birth') String? get dateOfBirth; String? get gender;@JsonKey(name: 'household_no') String? get householdNo; String? get address;/// **An object, not a string** — `types.ts` `interface Jurisdiction`.
/// Nullable because the field may be absent entirely; `{}` parses to a
/// `Jurisdiction` with all six members null, which is what staging sends.
 Jurisdiction? get jurisdiction;@JsonKey(name: 'avatar_url') String? get avatarUrl;@JsonKey(name: 'last_login_at') String? get lastLoginAt;
/// Create a copy of CitizenAccount
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CitizenAccountCopyWith<CitizenAccount> get copyWith => _$CitizenAccountCopyWithImpl<CitizenAccount>(this as CitizenAccount, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CitizenAccount&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.phone, phone) || other.phone == phone)&&(identical(other.email, email) || other.email == email)&&(identical(other.preferredLang, preferredLang) || other.preferredLang == preferredLang)&&(identical(other.verified, verified) || other.verified == verified)&&(identical(other.eidVerified, eidVerified) || other.eidVerified == eidVerified)&&(identical(other.active, active) || other.active == active)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.uin, uin) || other.uin == uin)&&(identical(other.nationalIdNo, nationalIdNo) || other.nationalIdNo == nationalIdNo)&&(identical(other.dateOfBirth, dateOfBirth) || other.dateOfBirth == dateOfBirth)&&(identical(other.gender, gender) || other.gender == gender)&&(identical(other.householdNo, householdNo) || other.householdNo == householdNo)&&(identical(other.address, address) || other.address == address)&&(identical(other.jurisdiction, jurisdiction) || other.jurisdiction == jurisdiction)&&(identical(other.avatarUrl, avatarUrl) || other.avatarUrl == avatarUrl)&&(identical(other.lastLoginAt, lastLoginAt) || other.lastLoginAt == lastLoginAt));
}


@override
int get hashCode => Object.hash(runtimeType,id,name,phone,email,preferredLang,verified,eidVerified,active,createdAt,uin,nationalIdNo,dateOfBirth,gender,householdNo,address,jurisdiction,avatarUrl,lastLoginAt);

@override
String toString() {
  return 'CitizenAccount(id: $id, name: $name, phone: $phone, email: $email, preferredLang: $preferredLang, verified: $verified, eidVerified: $eidVerified, active: $active, createdAt: $createdAt, uin: $uin, nationalIdNo: $nationalIdNo, dateOfBirth: $dateOfBirth, gender: $gender, householdNo: $householdNo, address: $address, jurisdiction: $jurisdiction, avatarUrl: $avatarUrl, lastLoginAt: $lastLoginAt)';
}


}

/// @nodoc
abstract mixin class $CitizenAccountCopyWith<$Res>  {
  factory $CitizenAccountCopyWith(CitizenAccount value, $Res Function(CitizenAccount) _then) = _$CitizenAccountCopyWithImpl;
@useResult
$Res call({
 String id, String name, String phone, String email,@JsonKey(name: 'preferred_lang') String preferredLang, bool verified,@JsonKey(name: 'eid_verified') bool eidVerified, bool active,@JsonKey(name: 'created_at') String createdAt, String? uin,@JsonKey(name: 'national_id_no') String? nationalIdNo,@JsonKey(name: 'date_of_birth') String? dateOfBirth, String? gender,@JsonKey(name: 'household_no') String? householdNo, String? address, Jurisdiction? jurisdiction,@JsonKey(name: 'avatar_url') String? avatarUrl,@JsonKey(name: 'last_login_at') String? lastLoginAt
});


$JurisdictionCopyWith<$Res>? get jurisdiction;

}
/// @nodoc
class _$CitizenAccountCopyWithImpl<$Res>
    implements $CitizenAccountCopyWith<$Res> {
  _$CitizenAccountCopyWithImpl(this._self, this._then);

  final CitizenAccount _self;
  final $Res Function(CitizenAccount) _then;

/// Create a copy of CitizenAccount
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? phone = null,Object? email = null,Object? preferredLang = null,Object? verified = null,Object? eidVerified = null,Object? active = null,Object? createdAt = null,Object? uin = freezed,Object? nationalIdNo = freezed,Object? dateOfBirth = freezed,Object? gender = freezed,Object? householdNo = freezed,Object? address = freezed,Object? jurisdiction = freezed,Object? avatarUrl = freezed,Object? lastLoginAt = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,phone: null == phone ? _self.phone : phone // ignore: cast_nullable_to_non_nullable
as String,email: null == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String,preferredLang: null == preferredLang ? _self.preferredLang : preferredLang // ignore: cast_nullable_to_non_nullable
as String,verified: null == verified ? _self.verified : verified // ignore: cast_nullable_to_non_nullable
as bool,eidVerified: null == eidVerified ? _self.eidVerified : eidVerified // ignore: cast_nullable_to_non_nullable
as bool,active: null == active ? _self.active : active // ignore: cast_nullable_to_non_nullable
as bool,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as String,uin: freezed == uin ? _self.uin : uin // ignore: cast_nullable_to_non_nullable
as String?,nationalIdNo: freezed == nationalIdNo ? _self.nationalIdNo : nationalIdNo // ignore: cast_nullable_to_non_nullable
as String?,dateOfBirth: freezed == dateOfBirth ? _self.dateOfBirth : dateOfBirth // ignore: cast_nullable_to_non_nullable
as String?,gender: freezed == gender ? _self.gender : gender // ignore: cast_nullable_to_non_nullable
as String?,householdNo: freezed == householdNo ? _self.householdNo : householdNo // ignore: cast_nullable_to_non_nullable
as String?,address: freezed == address ? _self.address : address // ignore: cast_nullable_to_non_nullable
as String?,jurisdiction: freezed == jurisdiction ? _self.jurisdiction : jurisdiction // ignore: cast_nullable_to_non_nullable
as Jurisdiction?,avatarUrl: freezed == avatarUrl ? _self.avatarUrl : avatarUrl // ignore: cast_nullable_to_non_nullable
as String?,lastLoginAt: freezed == lastLoginAt ? _self.lastLoginAt : lastLoginAt // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}
/// Create a copy of CitizenAccount
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$JurisdictionCopyWith<$Res>? get jurisdiction {
    if (_self.jurisdiction == null) {
    return null;
  }

  return $JurisdictionCopyWith<$Res>(_self.jurisdiction!, (value) {
    return _then(_self.copyWith(jurisdiction: value));
  });
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String name,  String phone,  String email, @JsonKey(name: 'preferred_lang')  String preferredLang,  bool verified, @JsonKey(name: 'eid_verified')  bool eidVerified,  bool active, @JsonKey(name: 'created_at')  String createdAt,  String? uin, @JsonKey(name: 'national_id_no')  String? nationalIdNo, @JsonKey(name: 'date_of_birth')  String? dateOfBirth,  String? gender, @JsonKey(name: 'household_no')  String? householdNo,  String? address,  Jurisdiction? jurisdiction, @JsonKey(name: 'avatar_url')  String? avatarUrl, @JsonKey(name: 'last_login_at')  String? lastLoginAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CitizenAccount() when $default != null:
return $default(_that.id,_that.name,_that.phone,_that.email,_that.preferredLang,_that.verified,_that.eidVerified,_that.active,_that.createdAt,_that.uin,_that.nationalIdNo,_that.dateOfBirth,_that.gender,_that.householdNo,_that.address,_that.jurisdiction,_that.avatarUrl,_that.lastLoginAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String name,  String phone,  String email, @JsonKey(name: 'preferred_lang')  String preferredLang,  bool verified, @JsonKey(name: 'eid_verified')  bool eidVerified,  bool active, @JsonKey(name: 'created_at')  String createdAt,  String? uin, @JsonKey(name: 'national_id_no')  String? nationalIdNo, @JsonKey(name: 'date_of_birth')  String? dateOfBirth,  String? gender, @JsonKey(name: 'household_no')  String? householdNo,  String? address,  Jurisdiction? jurisdiction, @JsonKey(name: 'avatar_url')  String? avatarUrl, @JsonKey(name: 'last_login_at')  String? lastLoginAt)  $default,) {final _that = this;
switch (_that) {
case _CitizenAccount():
return $default(_that.id,_that.name,_that.phone,_that.email,_that.preferredLang,_that.verified,_that.eidVerified,_that.active,_that.createdAt,_that.uin,_that.nationalIdNo,_that.dateOfBirth,_that.gender,_that.householdNo,_that.address,_that.jurisdiction,_that.avatarUrl,_that.lastLoginAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String name,  String phone,  String email, @JsonKey(name: 'preferred_lang')  String preferredLang,  bool verified, @JsonKey(name: 'eid_verified')  bool eidVerified,  bool active, @JsonKey(name: 'created_at')  String createdAt,  String? uin, @JsonKey(name: 'national_id_no')  String? nationalIdNo, @JsonKey(name: 'date_of_birth')  String? dateOfBirth,  String? gender, @JsonKey(name: 'household_no')  String? householdNo,  String? address,  Jurisdiction? jurisdiction, @JsonKey(name: 'avatar_url')  String? avatarUrl, @JsonKey(name: 'last_login_at')  String? lastLoginAt)?  $default,) {final _that = this;
switch (_that) {
case _CitizenAccount() when $default != null:
return $default(_that.id,_that.name,_that.phone,_that.email,_that.preferredLang,_that.verified,_that.eidVerified,_that.active,_that.createdAt,_that.uin,_that.nationalIdNo,_that.dateOfBirth,_that.gender,_that.householdNo,_that.address,_that.jurisdiction,_that.avatarUrl,_that.lastLoginAt);case _:
  return null;

}
}

}

/// @nodoc


class _CitizenAccount implements CitizenAccount {
  const _CitizenAccount({required this.id, required this.name, required this.phone, required this.email, @JsonKey(name: 'preferred_lang') required this.preferredLang, required this.verified, @JsonKey(name: 'eid_verified') required this.eidVerified, required this.active, @JsonKey(name: 'created_at') required this.createdAt, this.uin, @JsonKey(name: 'national_id_no') this.nationalIdNo, @JsonKey(name: 'date_of_birth') this.dateOfBirth, this.gender, @JsonKey(name: 'household_no') this.householdNo, this.address, this.jurisdiction, @JsonKey(name: 'avatar_url') this.avatarUrl, @JsonKey(name: 'last_login_at') this.lastLoginAt});
  

@override final  String id;
@override final  String name;
@override final  String phone;
@override final  String email;
@override@JsonKey(name: 'preferred_lang') final  String preferredLang;
@override final  bool verified;
@override@JsonKey(name: 'eid_verified') final  bool eidVerified;
@override final  bool active;
@override@JsonKey(name: 'created_at') final  String createdAt;
// ── Absent from a real staging payload, 2026-08-19 ──────────────────────
//
// `types.ts` declares all six required. Staging sends none of them for an
// unverified account created 2026-08-12. Nullable so a login succeeds; the
// divergence from the source's declaration is stated in the library doc
// above rather than hidden behind a default.
@override final  String? uin;
@override@JsonKey(name: 'national_id_no') final  String? nationalIdNo;
@override@JsonKey(name: 'date_of_birth') final  String? dateOfBirth;
@override final  String? gender;
@override@JsonKey(name: 'household_no') final  String? householdNo;
@override final  String? address;
/// **An object, not a string** — `types.ts` `interface Jurisdiction`.
/// Nullable because the field may be absent entirely; `{}` parses to a
/// `Jurisdiction` with all six members null, which is what staging sends.
@override final  Jurisdiction? jurisdiction;
@override@JsonKey(name: 'avatar_url') final  String? avatarUrl;
@override@JsonKey(name: 'last_login_at') final  String? lastLoginAt;

/// Create a copy of CitizenAccount
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CitizenAccountCopyWith<_CitizenAccount> get copyWith => __$CitizenAccountCopyWithImpl<_CitizenAccount>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CitizenAccount&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.phone, phone) || other.phone == phone)&&(identical(other.email, email) || other.email == email)&&(identical(other.preferredLang, preferredLang) || other.preferredLang == preferredLang)&&(identical(other.verified, verified) || other.verified == verified)&&(identical(other.eidVerified, eidVerified) || other.eidVerified == eidVerified)&&(identical(other.active, active) || other.active == active)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.uin, uin) || other.uin == uin)&&(identical(other.nationalIdNo, nationalIdNo) || other.nationalIdNo == nationalIdNo)&&(identical(other.dateOfBirth, dateOfBirth) || other.dateOfBirth == dateOfBirth)&&(identical(other.gender, gender) || other.gender == gender)&&(identical(other.householdNo, householdNo) || other.householdNo == householdNo)&&(identical(other.address, address) || other.address == address)&&(identical(other.jurisdiction, jurisdiction) || other.jurisdiction == jurisdiction)&&(identical(other.avatarUrl, avatarUrl) || other.avatarUrl == avatarUrl)&&(identical(other.lastLoginAt, lastLoginAt) || other.lastLoginAt == lastLoginAt));
}


@override
int get hashCode => Object.hash(runtimeType,id,name,phone,email,preferredLang,verified,eidVerified,active,createdAt,uin,nationalIdNo,dateOfBirth,gender,householdNo,address,jurisdiction,avatarUrl,lastLoginAt);

@override
String toString() {
  return 'CitizenAccount(id: $id, name: $name, phone: $phone, email: $email, preferredLang: $preferredLang, verified: $verified, eidVerified: $eidVerified, active: $active, createdAt: $createdAt, uin: $uin, nationalIdNo: $nationalIdNo, dateOfBirth: $dateOfBirth, gender: $gender, householdNo: $householdNo, address: $address, jurisdiction: $jurisdiction, avatarUrl: $avatarUrl, lastLoginAt: $lastLoginAt)';
}


}

/// @nodoc
abstract mixin class _$CitizenAccountCopyWith<$Res> implements $CitizenAccountCopyWith<$Res> {
  factory _$CitizenAccountCopyWith(_CitizenAccount value, $Res Function(_CitizenAccount) _then) = __$CitizenAccountCopyWithImpl;
@override @useResult
$Res call({
 String id, String name, String phone, String email,@JsonKey(name: 'preferred_lang') String preferredLang, bool verified,@JsonKey(name: 'eid_verified') bool eidVerified, bool active,@JsonKey(name: 'created_at') String createdAt, String? uin,@JsonKey(name: 'national_id_no') String? nationalIdNo,@JsonKey(name: 'date_of_birth') String? dateOfBirth, String? gender,@JsonKey(name: 'household_no') String? householdNo, String? address, Jurisdiction? jurisdiction,@JsonKey(name: 'avatar_url') String? avatarUrl,@JsonKey(name: 'last_login_at') String? lastLoginAt
});


@override $JurisdictionCopyWith<$Res>? get jurisdiction;

}
/// @nodoc
class __$CitizenAccountCopyWithImpl<$Res>
    implements _$CitizenAccountCopyWith<$Res> {
  __$CitizenAccountCopyWithImpl(this._self, this._then);

  final _CitizenAccount _self;
  final $Res Function(_CitizenAccount) _then;

/// Create a copy of CitizenAccount
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? phone = null,Object? email = null,Object? preferredLang = null,Object? verified = null,Object? eidVerified = null,Object? active = null,Object? createdAt = null,Object? uin = freezed,Object? nationalIdNo = freezed,Object? dateOfBirth = freezed,Object? gender = freezed,Object? householdNo = freezed,Object? address = freezed,Object? jurisdiction = freezed,Object? avatarUrl = freezed,Object? lastLoginAt = freezed,}) {
  return _then(_CitizenAccount(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,phone: null == phone ? _self.phone : phone // ignore: cast_nullable_to_non_nullable
as String,email: null == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String,preferredLang: null == preferredLang ? _self.preferredLang : preferredLang // ignore: cast_nullable_to_non_nullable
as String,verified: null == verified ? _self.verified : verified // ignore: cast_nullable_to_non_nullable
as bool,eidVerified: null == eidVerified ? _self.eidVerified : eidVerified // ignore: cast_nullable_to_non_nullable
as bool,active: null == active ? _self.active : active // ignore: cast_nullable_to_non_nullable
as bool,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as String,uin: freezed == uin ? _self.uin : uin // ignore: cast_nullable_to_non_nullable
as String?,nationalIdNo: freezed == nationalIdNo ? _self.nationalIdNo : nationalIdNo // ignore: cast_nullable_to_non_nullable
as String?,dateOfBirth: freezed == dateOfBirth ? _self.dateOfBirth : dateOfBirth // ignore: cast_nullable_to_non_nullable
as String?,gender: freezed == gender ? _self.gender : gender // ignore: cast_nullable_to_non_nullable
as String?,householdNo: freezed == householdNo ? _self.householdNo : householdNo // ignore: cast_nullable_to_non_nullable
as String?,address: freezed == address ? _self.address : address // ignore: cast_nullable_to_non_nullable
as String?,jurisdiction: freezed == jurisdiction ? _self.jurisdiction : jurisdiction // ignore: cast_nullable_to_non_nullable
as Jurisdiction?,avatarUrl: freezed == avatarUrl ? _self.avatarUrl : avatarUrl // ignore: cast_nullable_to_non_nullable
as String?,lastLoginAt: freezed == lastLoginAt ? _self.lastLoginAt : lastLoginAt // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

/// Create a copy of CitizenAccount
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$JurisdictionCopyWith<$Res>? get jurisdiction {
    if (_self.jurisdiction == null) {
    return null;
  }

  return $JurisdictionCopyWith<$Res>(_self.jurisdiction!, (value) {
    return _then(_self.copyWith(jurisdiction: value));
  });
}
}

// dart format on
