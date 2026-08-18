// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'family_book.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$FamilyBook {

/// `types.ts:599`. Parsed, never rendered.
 String? get id;/// `:402`, `:358`, `:524`.
 String get householdNo;/// Rendered **twice** on step 1 — once as the cover holder (`:409`), once
/// as the head (`:412`) — and again at `:357` and `:525`. That is the
/// source's own duplication, not a copy-paste in this port.
 String get headName;/// `:413`, `:526`. **Not in `HouseholdSummary`** — the page's own local
/// extension at `:34`.
 String? get headIdNo;/// **Not in `HouseholdSummary`** (`:35`) and read by no line. Modelled per
/// `specs.md` § 5; never rendered.
 String? get nationality;/// `:415`, `:527`.
 String get unit;/// `:416`, `:527`.
 String get group;/// `:220` — the **second** fallback of [addressLine], never a field of its
/// own on screen.
 String? get address;/// `types.ts:604`. Parsed, never rendered.
 String? get houseNo;/// `types.ts:620`. Parsed, never rendered — and not to be confused with a
/// member's `status`, which `:471` and `:490` do render.
 String? get status;/// `types.ts:621`. Parsed, never rendered.
 int? get reissueCount;/// `:213`. Nullable — see the library doc: `??`, not `||`.
 int? get totalMembers;/// `:214`.
 int? get maleMembers;/// `:215`.
 int? get femaleMembers;/// `:431` (step 1, falling back to [registeredAt] then to
/// `t("setOnIssuance")`) and `:529` (step 3, same chain but falling back to
/// `"—"`). **Two different fallbacks for one field**, both reproduced
/// (`F4-AC-71`).
 String? get issuedAt;/// `:431`, `:529`.
 String? get registeredAt;/// `:217`. The six flat strings behind the three address rows. Shared with
/// the application feature under CFI — one `Jurisdiction`, not a second
/// copy (`ssd.md` § 4.3, § 4.5).
 Jurisdiction? get jurisdiction;/// `:212` — `book?.members ?? []`.
 List<HouseholdMember> get members;
/// Create a copy of FamilyBook
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$FamilyBookCopyWith<FamilyBook> get copyWith => _$FamilyBookCopyWithImpl<FamilyBook>(this as FamilyBook, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is FamilyBook&&(identical(other.id, id) || other.id == id)&&(identical(other.householdNo, householdNo) || other.householdNo == householdNo)&&(identical(other.headName, headName) || other.headName == headName)&&(identical(other.headIdNo, headIdNo) || other.headIdNo == headIdNo)&&(identical(other.nationality, nationality) || other.nationality == nationality)&&(identical(other.unit, unit) || other.unit == unit)&&(identical(other.group, group) || other.group == group)&&(identical(other.address, address) || other.address == address)&&(identical(other.houseNo, houseNo) || other.houseNo == houseNo)&&(identical(other.status, status) || other.status == status)&&(identical(other.reissueCount, reissueCount) || other.reissueCount == reissueCount)&&(identical(other.totalMembers, totalMembers) || other.totalMembers == totalMembers)&&(identical(other.maleMembers, maleMembers) || other.maleMembers == maleMembers)&&(identical(other.femaleMembers, femaleMembers) || other.femaleMembers == femaleMembers)&&(identical(other.issuedAt, issuedAt) || other.issuedAt == issuedAt)&&(identical(other.registeredAt, registeredAt) || other.registeredAt == registeredAt)&&(identical(other.jurisdiction, jurisdiction) || other.jurisdiction == jurisdiction)&&const DeepCollectionEquality().equals(other.members, members));
}


@override
int get hashCode => Object.hash(runtimeType,id,householdNo,headName,headIdNo,nationality,unit,group,address,houseNo,status,reissueCount,totalMembers,maleMembers,femaleMembers,issuedAt,registeredAt,jurisdiction,const DeepCollectionEquality().hash(members));

@override
String toString() {
  return 'FamilyBook(id: $id, householdNo: $householdNo, headName: $headName, headIdNo: $headIdNo, nationality: $nationality, unit: $unit, group: $group, address: $address, houseNo: $houseNo, status: $status, reissueCount: $reissueCount, totalMembers: $totalMembers, maleMembers: $maleMembers, femaleMembers: $femaleMembers, issuedAt: $issuedAt, registeredAt: $registeredAt, jurisdiction: $jurisdiction, members: $members)';
}


}

/// @nodoc
abstract mixin class $FamilyBookCopyWith<$Res>  {
  factory $FamilyBookCopyWith(FamilyBook value, $Res Function(FamilyBook) _then) = _$FamilyBookCopyWithImpl;
@useResult
$Res call({
 String? id, String householdNo, String headName, String? headIdNo, String? nationality, String unit, String group, String? address, String? houseNo, String? status, int? reissueCount, int? totalMembers, int? maleMembers, int? femaleMembers, String? issuedAt, String? registeredAt, Jurisdiction? jurisdiction, List<HouseholdMember> members
});


$JurisdictionCopyWith<$Res>? get jurisdiction;

}
/// @nodoc
class _$FamilyBookCopyWithImpl<$Res>
    implements $FamilyBookCopyWith<$Res> {
  _$FamilyBookCopyWithImpl(this._self, this._then);

  final FamilyBook _self;
  final $Res Function(FamilyBook) _then;

/// Create a copy of FamilyBook
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = freezed,Object? householdNo = null,Object? headName = null,Object? headIdNo = freezed,Object? nationality = freezed,Object? unit = null,Object? group = null,Object? address = freezed,Object? houseNo = freezed,Object? status = freezed,Object? reissueCount = freezed,Object? totalMembers = freezed,Object? maleMembers = freezed,Object? femaleMembers = freezed,Object? issuedAt = freezed,Object? registeredAt = freezed,Object? jurisdiction = freezed,Object? members = null,}) {
  return _then(_self.copyWith(
id: freezed == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String?,householdNo: null == householdNo ? _self.householdNo : householdNo // ignore: cast_nullable_to_non_nullable
as String,headName: null == headName ? _self.headName : headName // ignore: cast_nullable_to_non_nullable
as String,headIdNo: freezed == headIdNo ? _self.headIdNo : headIdNo // ignore: cast_nullable_to_non_nullable
as String?,nationality: freezed == nationality ? _self.nationality : nationality // ignore: cast_nullable_to_non_nullable
as String?,unit: null == unit ? _self.unit : unit // ignore: cast_nullable_to_non_nullable
as String,group: null == group ? _self.group : group // ignore: cast_nullable_to_non_nullable
as String,address: freezed == address ? _self.address : address // ignore: cast_nullable_to_non_nullable
as String?,houseNo: freezed == houseNo ? _self.houseNo : houseNo // ignore: cast_nullable_to_non_nullable
as String?,status: freezed == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String?,reissueCount: freezed == reissueCount ? _self.reissueCount : reissueCount // ignore: cast_nullable_to_non_nullable
as int?,totalMembers: freezed == totalMembers ? _self.totalMembers : totalMembers // ignore: cast_nullable_to_non_nullable
as int?,maleMembers: freezed == maleMembers ? _self.maleMembers : maleMembers // ignore: cast_nullable_to_non_nullable
as int?,femaleMembers: freezed == femaleMembers ? _self.femaleMembers : femaleMembers // ignore: cast_nullable_to_non_nullable
as int?,issuedAt: freezed == issuedAt ? _self.issuedAt : issuedAt // ignore: cast_nullable_to_non_nullable
as String?,registeredAt: freezed == registeredAt ? _self.registeredAt : registeredAt // ignore: cast_nullable_to_non_nullable
as String?,jurisdiction: freezed == jurisdiction ? _self.jurisdiction : jurisdiction // ignore: cast_nullable_to_non_nullable
as Jurisdiction?,members: null == members ? _self.members : members // ignore: cast_nullable_to_non_nullable
as List<HouseholdMember>,
  ));
}
/// Create a copy of FamilyBook
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


/// Adds pattern-matching-related methods to [FamilyBook].
extension FamilyBookPatterns on FamilyBook {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _FamilyBook value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _FamilyBook() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _FamilyBook value)  $default,){
final _that = this;
switch (_that) {
case _FamilyBook():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _FamilyBook value)?  $default,){
final _that = this;
switch (_that) {
case _FamilyBook() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String? id,  String householdNo,  String headName,  String? headIdNo,  String? nationality,  String unit,  String group,  String? address,  String? houseNo,  String? status,  int? reissueCount,  int? totalMembers,  int? maleMembers,  int? femaleMembers,  String? issuedAt,  String? registeredAt,  Jurisdiction? jurisdiction,  List<HouseholdMember> members)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _FamilyBook() when $default != null:
return $default(_that.id,_that.householdNo,_that.headName,_that.headIdNo,_that.nationality,_that.unit,_that.group,_that.address,_that.houseNo,_that.status,_that.reissueCount,_that.totalMembers,_that.maleMembers,_that.femaleMembers,_that.issuedAt,_that.registeredAt,_that.jurisdiction,_that.members);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String? id,  String householdNo,  String headName,  String? headIdNo,  String? nationality,  String unit,  String group,  String? address,  String? houseNo,  String? status,  int? reissueCount,  int? totalMembers,  int? maleMembers,  int? femaleMembers,  String? issuedAt,  String? registeredAt,  Jurisdiction? jurisdiction,  List<HouseholdMember> members)  $default,) {final _that = this;
switch (_that) {
case _FamilyBook():
return $default(_that.id,_that.householdNo,_that.headName,_that.headIdNo,_that.nationality,_that.unit,_that.group,_that.address,_that.houseNo,_that.status,_that.reissueCount,_that.totalMembers,_that.maleMembers,_that.femaleMembers,_that.issuedAt,_that.registeredAt,_that.jurisdiction,_that.members);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String? id,  String householdNo,  String headName,  String? headIdNo,  String? nationality,  String unit,  String group,  String? address,  String? houseNo,  String? status,  int? reissueCount,  int? totalMembers,  int? maleMembers,  int? femaleMembers,  String? issuedAt,  String? registeredAt,  Jurisdiction? jurisdiction,  List<HouseholdMember> members)?  $default,) {final _that = this;
switch (_that) {
case _FamilyBook() when $default != null:
return $default(_that.id,_that.householdNo,_that.headName,_that.headIdNo,_that.nationality,_that.unit,_that.group,_that.address,_that.houseNo,_that.status,_that.reissueCount,_that.totalMembers,_that.maleMembers,_that.femaleMembers,_that.issuedAt,_that.registeredAt,_that.jurisdiction,_that.members);case _:
  return null;

}
}

}

/// @nodoc


class _FamilyBook extends FamilyBook {
  const _FamilyBook({this.id, this.householdNo = '', this.headName = '', this.headIdNo, this.nationality, this.unit = '', this.group = '', this.address, this.houseNo, this.status, this.reissueCount, this.totalMembers, this.maleMembers, this.femaleMembers, this.issuedAt, this.registeredAt, this.jurisdiction, final  List<HouseholdMember> members = const <HouseholdMember>[]}): _members = members,super._();
  

/// `types.ts:599`. Parsed, never rendered.
@override final  String? id;
/// `:402`, `:358`, `:524`.
@override@JsonKey() final  String householdNo;
/// Rendered **twice** on step 1 — once as the cover holder (`:409`), once
/// as the head (`:412`) — and again at `:357` and `:525`. That is the
/// source's own duplication, not a copy-paste in this port.
@override@JsonKey() final  String headName;
/// `:413`, `:526`. **Not in `HouseholdSummary`** — the page's own local
/// extension at `:34`.
@override final  String? headIdNo;
/// **Not in `HouseholdSummary`** (`:35`) and read by no line. Modelled per
/// `specs.md` § 5; never rendered.
@override final  String? nationality;
/// `:415`, `:527`.
@override@JsonKey() final  String unit;
/// `:416`, `:527`.
@override@JsonKey() final  String group;
/// `:220` — the **second** fallback of [addressLine], never a field of its
/// own on screen.
@override final  String? address;
/// `types.ts:604`. Parsed, never rendered.
@override final  String? houseNo;
/// `types.ts:620`. Parsed, never rendered — and not to be confused with a
/// member's `status`, which `:471` and `:490` do render.
@override final  String? status;
/// `types.ts:621`. Parsed, never rendered.
@override final  int? reissueCount;
/// `:213`. Nullable — see the library doc: `??`, not `||`.
@override final  int? totalMembers;
/// `:214`.
@override final  int? maleMembers;
/// `:215`.
@override final  int? femaleMembers;
/// `:431` (step 1, falling back to [registeredAt] then to
/// `t("setOnIssuance")`) and `:529` (step 3, same chain but falling back to
/// `"—"`). **Two different fallbacks for one field**, both reproduced
/// (`F4-AC-71`).
@override final  String? issuedAt;
/// `:431`, `:529`.
@override final  String? registeredAt;
/// `:217`. The six flat strings behind the three address rows. Shared with
/// the application feature under CFI — one `Jurisdiction`, not a second
/// copy (`ssd.md` § 4.3, § 4.5).
@override final  Jurisdiction? jurisdiction;
/// `:212` — `book?.members ?? []`.
 final  List<HouseholdMember> _members;
/// `:212` — `book?.members ?? []`.
@override@JsonKey() List<HouseholdMember> get members {
  if (_members is EqualUnmodifiableListView) return _members;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_members);
}


/// Create a copy of FamilyBook
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$FamilyBookCopyWith<_FamilyBook> get copyWith => __$FamilyBookCopyWithImpl<_FamilyBook>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _FamilyBook&&(identical(other.id, id) || other.id == id)&&(identical(other.householdNo, householdNo) || other.householdNo == householdNo)&&(identical(other.headName, headName) || other.headName == headName)&&(identical(other.headIdNo, headIdNo) || other.headIdNo == headIdNo)&&(identical(other.nationality, nationality) || other.nationality == nationality)&&(identical(other.unit, unit) || other.unit == unit)&&(identical(other.group, group) || other.group == group)&&(identical(other.address, address) || other.address == address)&&(identical(other.houseNo, houseNo) || other.houseNo == houseNo)&&(identical(other.status, status) || other.status == status)&&(identical(other.reissueCount, reissueCount) || other.reissueCount == reissueCount)&&(identical(other.totalMembers, totalMembers) || other.totalMembers == totalMembers)&&(identical(other.maleMembers, maleMembers) || other.maleMembers == maleMembers)&&(identical(other.femaleMembers, femaleMembers) || other.femaleMembers == femaleMembers)&&(identical(other.issuedAt, issuedAt) || other.issuedAt == issuedAt)&&(identical(other.registeredAt, registeredAt) || other.registeredAt == registeredAt)&&(identical(other.jurisdiction, jurisdiction) || other.jurisdiction == jurisdiction)&&const DeepCollectionEquality().equals(other._members, _members));
}


@override
int get hashCode => Object.hash(runtimeType,id,householdNo,headName,headIdNo,nationality,unit,group,address,houseNo,status,reissueCount,totalMembers,maleMembers,femaleMembers,issuedAt,registeredAt,jurisdiction,const DeepCollectionEquality().hash(_members));

@override
String toString() {
  return 'FamilyBook(id: $id, householdNo: $householdNo, headName: $headName, headIdNo: $headIdNo, nationality: $nationality, unit: $unit, group: $group, address: $address, houseNo: $houseNo, status: $status, reissueCount: $reissueCount, totalMembers: $totalMembers, maleMembers: $maleMembers, femaleMembers: $femaleMembers, issuedAt: $issuedAt, registeredAt: $registeredAt, jurisdiction: $jurisdiction, members: $members)';
}


}

/// @nodoc
abstract mixin class _$FamilyBookCopyWith<$Res> implements $FamilyBookCopyWith<$Res> {
  factory _$FamilyBookCopyWith(_FamilyBook value, $Res Function(_FamilyBook) _then) = __$FamilyBookCopyWithImpl;
@override @useResult
$Res call({
 String? id, String householdNo, String headName, String? headIdNo, String? nationality, String unit, String group, String? address, String? houseNo, String? status, int? reissueCount, int? totalMembers, int? maleMembers, int? femaleMembers, String? issuedAt, String? registeredAt, Jurisdiction? jurisdiction, List<HouseholdMember> members
});


@override $JurisdictionCopyWith<$Res>? get jurisdiction;

}
/// @nodoc
class __$FamilyBookCopyWithImpl<$Res>
    implements _$FamilyBookCopyWith<$Res> {
  __$FamilyBookCopyWithImpl(this._self, this._then);

  final _FamilyBook _self;
  final $Res Function(_FamilyBook) _then;

/// Create a copy of FamilyBook
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = freezed,Object? householdNo = null,Object? headName = null,Object? headIdNo = freezed,Object? nationality = freezed,Object? unit = null,Object? group = null,Object? address = freezed,Object? houseNo = freezed,Object? status = freezed,Object? reissueCount = freezed,Object? totalMembers = freezed,Object? maleMembers = freezed,Object? femaleMembers = freezed,Object? issuedAt = freezed,Object? registeredAt = freezed,Object? jurisdiction = freezed,Object? members = null,}) {
  return _then(_FamilyBook(
id: freezed == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String?,householdNo: null == householdNo ? _self.householdNo : householdNo // ignore: cast_nullable_to_non_nullable
as String,headName: null == headName ? _self.headName : headName // ignore: cast_nullable_to_non_nullable
as String,headIdNo: freezed == headIdNo ? _self.headIdNo : headIdNo // ignore: cast_nullable_to_non_nullable
as String?,nationality: freezed == nationality ? _self.nationality : nationality // ignore: cast_nullable_to_non_nullable
as String?,unit: null == unit ? _self.unit : unit // ignore: cast_nullable_to_non_nullable
as String,group: null == group ? _self.group : group // ignore: cast_nullable_to_non_nullable
as String,address: freezed == address ? _self.address : address // ignore: cast_nullable_to_non_nullable
as String?,houseNo: freezed == houseNo ? _self.houseNo : houseNo // ignore: cast_nullable_to_non_nullable
as String?,status: freezed == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String?,reissueCount: freezed == reissueCount ? _self.reissueCount : reissueCount // ignore: cast_nullable_to_non_nullable
as int?,totalMembers: freezed == totalMembers ? _self.totalMembers : totalMembers // ignore: cast_nullable_to_non_nullable
as int?,maleMembers: freezed == maleMembers ? _self.maleMembers : maleMembers // ignore: cast_nullable_to_non_nullable
as int?,femaleMembers: freezed == femaleMembers ? _self.femaleMembers : femaleMembers // ignore: cast_nullable_to_non_nullable
as int?,issuedAt: freezed == issuedAt ? _self.issuedAt : issuedAt // ignore: cast_nullable_to_non_nullable
as String?,registeredAt: freezed == registeredAt ? _self.registeredAt : registeredAt // ignore: cast_nullable_to_non_nullable
as String?,jurisdiction: freezed == jurisdiction ? _self.jurisdiction : jurisdiction // ignore: cast_nullable_to_non_nullable
as Jurisdiction?,members: null == members ? _self._members : members // ignore: cast_nullable_to_non_nullable
as List<HouseholdMember>,
  ));
}

/// Create a copy of FamilyBook
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
