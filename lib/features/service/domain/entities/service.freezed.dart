// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'service.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$Service {

 String get id;/// The catalogue's stable key (`resident`, `birth`, `family-book`). This is
/// `ServiceItem.id` in the port source (`ServicePage.tsx:126`).
 String get code; String get categoryId; String get categoryCode; Bilingual get name; String get shortName; Bilingual get description;/// A lucide component name. Resolve through `AppIcons.service`.
 String get icon;/// `#RRGGBB` accent, or empty when the catalogue does not set one. Data,
/// not a token — see `ServiceCategory`'s note.
 String get color; int get feeLak; int get feeMaxLak; bool get feeIsRange; int get slaDays; Bilingual get processingTime; List<Bilingual> get requiredDocs; bool get requiresPayment; bool get isPhase1; bool get active; int get sortOrder;/// The **web's** route for this service (`/service/resident-certificate`),
/// or empty for the 37 rows that have none.
///
/// **This is not an availability flag** (SSD § 13 C-3). Six of 43 carry
/// one, and after F1 only one of those six will have a Flutter page, so
/// reading it as "tappable" would be wrong in both directions. It is the
/// page-pairing seed for the fidelity harness and the input to
/// `ServiceAvailability`, which asks the *client* route registry whether a
/// destination exists. Nothing else may branch on it.
 String get routePath; String get familyBookEffect;
/// Create a copy of Service
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ServiceCopyWith<Service> get copyWith => _$ServiceCopyWithImpl<Service>(this as Service, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Service&&(identical(other.id, id) || other.id == id)&&(identical(other.code, code) || other.code == code)&&(identical(other.categoryId, categoryId) || other.categoryId == categoryId)&&(identical(other.categoryCode, categoryCode) || other.categoryCode == categoryCode)&&(identical(other.name, name) || other.name == name)&&(identical(other.shortName, shortName) || other.shortName == shortName)&&(identical(other.description, description) || other.description == description)&&(identical(other.icon, icon) || other.icon == icon)&&(identical(other.color, color) || other.color == color)&&(identical(other.feeLak, feeLak) || other.feeLak == feeLak)&&(identical(other.feeMaxLak, feeMaxLak) || other.feeMaxLak == feeMaxLak)&&(identical(other.feeIsRange, feeIsRange) || other.feeIsRange == feeIsRange)&&(identical(other.slaDays, slaDays) || other.slaDays == slaDays)&&(identical(other.processingTime, processingTime) || other.processingTime == processingTime)&&const DeepCollectionEquality().equals(other.requiredDocs, requiredDocs)&&(identical(other.requiresPayment, requiresPayment) || other.requiresPayment == requiresPayment)&&(identical(other.isPhase1, isPhase1) || other.isPhase1 == isPhase1)&&(identical(other.active, active) || other.active == active)&&(identical(other.sortOrder, sortOrder) || other.sortOrder == sortOrder)&&(identical(other.routePath, routePath) || other.routePath == routePath)&&(identical(other.familyBookEffect, familyBookEffect) || other.familyBookEffect == familyBookEffect));
}


@override
int get hashCode => Object.hashAll([runtimeType,id,code,categoryId,categoryCode,name,shortName,description,icon,color,feeLak,feeMaxLak,feeIsRange,slaDays,processingTime,const DeepCollectionEquality().hash(requiredDocs),requiresPayment,isPhase1,active,sortOrder,routePath,familyBookEffect]);

@override
String toString() {
  return 'Service(id: $id, code: $code, categoryId: $categoryId, categoryCode: $categoryCode, name: $name, shortName: $shortName, description: $description, icon: $icon, color: $color, feeLak: $feeLak, feeMaxLak: $feeMaxLak, feeIsRange: $feeIsRange, slaDays: $slaDays, processingTime: $processingTime, requiredDocs: $requiredDocs, requiresPayment: $requiresPayment, isPhase1: $isPhase1, active: $active, sortOrder: $sortOrder, routePath: $routePath, familyBookEffect: $familyBookEffect)';
}


}

/// @nodoc
abstract mixin class $ServiceCopyWith<$Res>  {
  factory $ServiceCopyWith(Service value, $Res Function(Service) _then) = _$ServiceCopyWithImpl;
@useResult
$Res call({
 String id, String code, String categoryId, String categoryCode, Bilingual name, String shortName, Bilingual description, String icon, String color, int feeLak, int feeMaxLak, bool feeIsRange, int slaDays, Bilingual processingTime, List<Bilingual> requiredDocs, bool requiresPayment, bool isPhase1, bool active, int sortOrder, String routePath, String familyBookEffect
});


$BilingualCopyWith<$Res> get name;$BilingualCopyWith<$Res> get description;$BilingualCopyWith<$Res> get processingTime;

}
/// @nodoc
class _$ServiceCopyWithImpl<$Res>
    implements $ServiceCopyWith<$Res> {
  _$ServiceCopyWithImpl(this._self, this._then);

  final Service _self;
  final $Res Function(Service) _then;

/// Create a copy of Service
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? code = null,Object? categoryId = null,Object? categoryCode = null,Object? name = null,Object? shortName = null,Object? description = null,Object? icon = null,Object? color = null,Object? feeLak = null,Object? feeMaxLak = null,Object? feeIsRange = null,Object? slaDays = null,Object? processingTime = null,Object? requiredDocs = null,Object? requiresPayment = null,Object? isPhase1 = null,Object? active = null,Object? sortOrder = null,Object? routePath = null,Object? familyBookEffect = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,code: null == code ? _self.code : code // ignore: cast_nullable_to_non_nullable
as String,categoryId: null == categoryId ? _self.categoryId : categoryId // ignore: cast_nullable_to_non_nullable
as String,categoryCode: null == categoryCode ? _self.categoryCode : categoryCode // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as Bilingual,shortName: null == shortName ? _self.shortName : shortName // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as Bilingual,icon: null == icon ? _self.icon : icon // ignore: cast_nullable_to_non_nullable
as String,color: null == color ? _self.color : color // ignore: cast_nullable_to_non_nullable
as String,feeLak: null == feeLak ? _self.feeLak : feeLak // ignore: cast_nullable_to_non_nullable
as int,feeMaxLak: null == feeMaxLak ? _self.feeMaxLak : feeMaxLak // ignore: cast_nullable_to_non_nullable
as int,feeIsRange: null == feeIsRange ? _self.feeIsRange : feeIsRange // ignore: cast_nullable_to_non_nullable
as bool,slaDays: null == slaDays ? _self.slaDays : slaDays // ignore: cast_nullable_to_non_nullable
as int,processingTime: null == processingTime ? _self.processingTime : processingTime // ignore: cast_nullable_to_non_nullable
as Bilingual,requiredDocs: null == requiredDocs ? _self.requiredDocs : requiredDocs // ignore: cast_nullable_to_non_nullable
as List<Bilingual>,requiresPayment: null == requiresPayment ? _self.requiresPayment : requiresPayment // ignore: cast_nullable_to_non_nullable
as bool,isPhase1: null == isPhase1 ? _self.isPhase1 : isPhase1 // ignore: cast_nullable_to_non_nullable
as bool,active: null == active ? _self.active : active // ignore: cast_nullable_to_non_nullable
as bool,sortOrder: null == sortOrder ? _self.sortOrder : sortOrder // ignore: cast_nullable_to_non_nullable
as int,routePath: null == routePath ? _self.routePath : routePath // ignore: cast_nullable_to_non_nullable
as String,familyBookEffect: null == familyBookEffect ? _self.familyBookEffect : familyBookEffect // ignore: cast_nullable_to_non_nullable
as String,
  ));
}
/// Create a copy of Service
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BilingualCopyWith<$Res> get name {
  
  return $BilingualCopyWith<$Res>(_self.name, (value) {
    return _then(_self.copyWith(name: value));
  });
}/// Create a copy of Service
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BilingualCopyWith<$Res> get description {
  
  return $BilingualCopyWith<$Res>(_self.description, (value) {
    return _then(_self.copyWith(description: value));
  });
}/// Create a copy of Service
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BilingualCopyWith<$Res> get processingTime {
  
  return $BilingualCopyWith<$Res>(_self.processingTime, (value) {
    return _then(_self.copyWith(processingTime: value));
  });
}
}


/// Adds pattern-matching-related methods to [Service].
extension ServicePatterns on Service {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Service value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Service() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Service value)  $default,){
final _that = this;
switch (_that) {
case _Service():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Service value)?  $default,){
final _that = this;
switch (_that) {
case _Service() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String code,  String categoryId,  String categoryCode,  Bilingual name,  String shortName,  Bilingual description,  String icon,  String color,  int feeLak,  int feeMaxLak,  bool feeIsRange,  int slaDays,  Bilingual processingTime,  List<Bilingual> requiredDocs,  bool requiresPayment,  bool isPhase1,  bool active,  int sortOrder,  String routePath,  String familyBookEffect)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Service() when $default != null:
return $default(_that.id,_that.code,_that.categoryId,_that.categoryCode,_that.name,_that.shortName,_that.description,_that.icon,_that.color,_that.feeLak,_that.feeMaxLak,_that.feeIsRange,_that.slaDays,_that.processingTime,_that.requiredDocs,_that.requiresPayment,_that.isPhase1,_that.active,_that.sortOrder,_that.routePath,_that.familyBookEffect);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String code,  String categoryId,  String categoryCode,  Bilingual name,  String shortName,  Bilingual description,  String icon,  String color,  int feeLak,  int feeMaxLak,  bool feeIsRange,  int slaDays,  Bilingual processingTime,  List<Bilingual> requiredDocs,  bool requiresPayment,  bool isPhase1,  bool active,  int sortOrder,  String routePath,  String familyBookEffect)  $default,) {final _that = this;
switch (_that) {
case _Service():
return $default(_that.id,_that.code,_that.categoryId,_that.categoryCode,_that.name,_that.shortName,_that.description,_that.icon,_that.color,_that.feeLak,_that.feeMaxLak,_that.feeIsRange,_that.slaDays,_that.processingTime,_that.requiredDocs,_that.requiresPayment,_that.isPhase1,_that.active,_that.sortOrder,_that.routePath,_that.familyBookEffect);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String code,  String categoryId,  String categoryCode,  Bilingual name,  String shortName,  Bilingual description,  String icon,  String color,  int feeLak,  int feeMaxLak,  bool feeIsRange,  int slaDays,  Bilingual processingTime,  List<Bilingual> requiredDocs,  bool requiresPayment,  bool isPhase1,  bool active,  int sortOrder,  String routePath,  String familyBookEffect)?  $default,) {final _that = this;
switch (_that) {
case _Service() when $default != null:
return $default(_that.id,_that.code,_that.categoryId,_that.categoryCode,_that.name,_that.shortName,_that.description,_that.icon,_that.color,_that.feeLak,_that.feeMaxLak,_that.feeIsRange,_that.slaDays,_that.processingTime,_that.requiredDocs,_that.requiresPayment,_that.isPhase1,_that.active,_that.sortOrder,_that.routePath,_that.familyBookEffect);case _:
  return null;

}
}

}

/// @nodoc


class _Service implements Service {
  const _Service({required this.id, required this.code, required this.categoryId, required this.categoryCode, required this.name, required this.shortName, required this.description, required this.icon, required this.color, required this.feeLak, required this.feeMaxLak, required this.feeIsRange, required this.slaDays, required this.processingTime, required final  List<Bilingual> requiredDocs, required this.requiresPayment, required this.isPhase1, required this.active, required this.sortOrder, required this.routePath, required this.familyBookEffect}): _requiredDocs = requiredDocs;
  

@override final  String id;
/// The catalogue's stable key (`resident`, `birth`, `family-book`). This is
/// `ServiceItem.id` in the port source (`ServicePage.tsx:126`).
@override final  String code;
@override final  String categoryId;
@override final  String categoryCode;
@override final  Bilingual name;
@override final  String shortName;
@override final  Bilingual description;
/// A lucide component name. Resolve through `AppIcons.service`.
@override final  String icon;
/// `#RRGGBB` accent, or empty when the catalogue does not set one. Data,
/// not a token — see `ServiceCategory`'s note.
@override final  String color;
@override final  int feeLak;
@override final  int feeMaxLak;
@override final  bool feeIsRange;
@override final  int slaDays;
@override final  Bilingual processingTime;
 final  List<Bilingual> _requiredDocs;
@override List<Bilingual> get requiredDocs {
  if (_requiredDocs is EqualUnmodifiableListView) return _requiredDocs;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_requiredDocs);
}

@override final  bool requiresPayment;
@override final  bool isPhase1;
@override final  bool active;
@override final  int sortOrder;
/// The **web's** route for this service (`/service/resident-certificate`),
/// or empty for the 37 rows that have none.
///
/// **This is not an availability flag** (SSD § 13 C-3). Six of 43 carry
/// one, and after F1 only one of those six will have a Flutter page, so
/// reading it as "tappable" would be wrong in both directions. It is the
/// page-pairing seed for the fidelity harness and the input to
/// `ServiceAvailability`, which asks the *client* route registry whether a
/// destination exists. Nothing else may branch on it.
@override final  String routePath;
@override final  String familyBookEffect;

/// Create a copy of Service
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ServiceCopyWith<_Service> get copyWith => __$ServiceCopyWithImpl<_Service>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Service&&(identical(other.id, id) || other.id == id)&&(identical(other.code, code) || other.code == code)&&(identical(other.categoryId, categoryId) || other.categoryId == categoryId)&&(identical(other.categoryCode, categoryCode) || other.categoryCode == categoryCode)&&(identical(other.name, name) || other.name == name)&&(identical(other.shortName, shortName) || other.shortName == shortName)&&(identical(other.description, description) || other.description == description)&&(identical(other.icon, icon) || other.icon == icon)&&(identical(other.color, color) || other.color == color)&&(identical(other.feeLak, feeLak) || other.feeLak == feeLak)&&(identical(other.feeMaxLak, feeMaxLak) || other.feeMaxLak == feeMaxLak)&&(identical(other.feeIsRange, feeIsRange) || other.feeIsRange == feeIsRange)&&(identical(other.slaDays, slaDays) || other.slaDays == slaDays)&&(identical(other.processingTime, processingTime) || other.processingTime == processingTime)&&const DeepCollectionEquality().equals(other._requiredDocs, _requiredDocs)&&(identical(other.requiresPayment, requiresPayment) || other.requiresPayment == requiresPayment)&&(identical(other.isPhase1, isPhase1) || other.isPhase1 == isPhase1)&&(identical(other.active, active) || other.active == active)&&(identical(other.sortOrder, sortOrder) || other.sortOrder == sortOrder)&&(identical(other.routePath, routePath) || other.routePath == routePath)&&(identical(other.familyBookEffect, familyBookEffect) || other.familyBookEffect == familyBookEffect));
}


@override
int get hashCode => Object.hashAll([runtimeType,id,code,categoryId,categoryCode,name,shortName,description,icon,color,feeLak,feeMaxLak,feeIsRange,slaDays,processingTime,const DeepCollectionEquality().hash(_requiredDocs),requiresPayment,isPhase1,active,sortOrder,routePath,familyBookEffect]);

@override
String toString() {
  return 'Service(id: $id, code: $code, categoryId: $categoryId, categoryCode: $categoryCode, name: $name, shortName: $shortName, description: $description, icon: $icon, color: $color, feeLak: $feeLak, feeMaxLak: $feeMaxLak, feeIsRange: $feeIsRange, slaDays: $slaDays, processingTime: $processingTime, requiredDocs: $requiredDocs, requiresPayment: $requiresPayment, isPhase1: $isPhase1, active: $active, sortOrder: $sortOrder, routePath: $routePath, familyBookEffect: $familyBookEffect)';
}


}

/// @nodoc
abstract mixin class _$ServiceCopyWith<$Res> implements $ServiceCopyWith<$Res> {
  factory _$ServiceCopyWith(_Service value, $Res Function(_Service) _then) = __$ServiceCopyWithImpl;
@override @useResult
$Res call({
 String id, String code, String categoryId, String categoryCode, Bilingual name, String shortName, Bilingual description, String icon, String color, int feeLak, int feeMaxLak, bool feeIsRange, int slaDays, Bilingual processingTime, List<Bilingual> requiredDocs, bool requiresPayment, bool isPhase1, bool active, int sortOrder, String routePath, String familyBookEffect
});


@override $BilingualCopyWith<$Res> get name;@override $BilingualCopyWith<$Res> get description;@override $BilingualCopyWith<$Res> get processingTime;

}
/// @nodoc
class __$ServiceCopyWithImpl<$Res>
    implements _$ServiceCopyWith<$Res> {
  __$ServiceCopyWithImpl(this._self, this._then);

  final _Service _self;
  final $Res Function(_Service) _then;

/// Create a copy of Service
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? code = null,Object? categoryId = null,Object? categoryCode = null,Object? name = null,Object? shortName = null,Object? description = null,Object? icon = null,Object? color = null,Object? feeLak = null,Object? feeMaxLak = null,Object? feeIsRange = null,Object? slaDays = null,Object? processingTime = null,Object? requiredDocs = null,Object? requiresPayment = null,Object? isPhase1 = null,Object? active = null,Object? sortOrder = null,Object? routePath = null,Object? familyBookEffect = null,}) {
  return _then(_Service(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,code: null == code ? _self.code : code // ignore: cast_nullable_to_non_nullable
as String,categoryId: null == categoryId ? _self.categoryId : categoryId // ignore: cast_nullable_to_non_nullable
as String,categoryCode: null == categoryCode ? _self.categoryCode : categoryCode // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as Bilingual,shortName: null == shortName ? _self.shortName : shortName // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as Bilingual,icon: null == icon ? _self.icon : icon // ignore: cast_nullable_to_non_nullable
as String,color: null == color ? _self.color : color // ignore: cast_nullable_to_non_nullable
as String,feeLak: null == feeLak ? _self.feeLak : feeLak // ignore: cast_nullable_to_non_nullable
as int,feeMaxLak: null == feeMaxLak ? _self.feeMaxLak : feeMaxLak // ignore: cast_nullable_to_non_nullable
as int,feeIsRange: null == feeIsRange ? _self.feeIsRange : feeIsRange // ignore: cast_nullable_to_non_nullable
as bool,slaDays: null == slaDays ? _self.slaDays : slaDays // ignore: cast_nullable_to_non_nullable
as int,processingTime: null == processingTime ? _self.processingTime : processingTime // ignore: cast_nullable_to_non_nullable
as Bilingual,requiredDocs: null == requiredDocs ? _self._requiredDocs : requiredDocs // ignore: cast_nullable_to_non_nullable
as List<Bilingual>,requiresPayment: null == requiresPayment ? _self.requiresPayment : requiresPayment // ignore: cast_nullable_to_non_nullable
as bool,isPhase1: null == isPhase1 ? _self.isPhase1 : isPhase1 // ignore: cast_nullable_to_non_nullable
as bool,active: null == active ? _self.active : active // ignore: cast_nullable_to_non_nullable
as bool,sortOrder: null == sortOrder ? _self.sortOrder : sortOrder // ignore: cast_nullable_to_non_nullable
as int,routePath: null == routePath ? _self.routePath : routePath // ignore: cast_nullable_to_non_nullable
as String,familyBookEffect: null == familyBookEffect ? _self.familyBookEffect : familyBookEffect // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

/// Create a copy of Service
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BilingualCopyWith<$Res> get name {
  
  return $BilingualCopyWith<$Res>(_self.name, (value) {
    return _then(_self.copyWith(name: value));
  });
}/// Create a copy of Service
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BilingualCopyWith<$Res> get description {
  
  return $BilingualCopyWith<$Res>(_self.description, (value) {
    return _then(_self.copyWith(description: value));
  });
}/// Create a copy of Service
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BilingualCopyWith<$Res> get processingTime {
  
  return $BilingualCopyWith<$Res>(_self.processingTime, (value) {
    return _then(_self.copyWith(processingTime: value));
  });
}
}

// dart format on
