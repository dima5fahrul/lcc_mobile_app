// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'verification_result.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$IssuerContact {

 String get phone; String get email; String get address;
/// Create a copy of IssuerContact
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$IssuerContactCopyWith<IssuerContact> get copyWith => _$IssuerContactCopyWithImpl<IssuerContact>(this as IssuerContact, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is IssuerContact&&(identical(other.phone, phone) || other.phone == phone)&&(identical(other.email, email) || other.email == email)&&(identical(other.address, address) || other.address == address));
}


@override
int get hashCode => Object.hash(runtimeType,phone,email,address);

@override
String toString() {
  return 'IssuerContact(phone: $phone, email: $email, address: $address)';
}


}

/// @nodoc
abstract mixin class $IssuerContactCopyWith<$Res>  {
  factory $IssuerContactCopyWith(IssuerContact value, $Res Function(IssuerContact) _then) = _$IssuerContactCopyWithImpl;
@useResult
$Res call({
 String phone, String email, String address
});




}
/// @nodoc
class _$IssuerContactCopyWithImpl<$Res>
    implements $IssuerContactCopyWith<$Res> {
  _$IssuerContactCopyWithImpl(this._self, this._then);

  final IssuerContact _self;
  final $Res Function(IssuerContact) _then;

/// Create a copy of IssuerContact
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? phone = null,Object? email = null,Object? address = null,}) {
  return _then(_self.copyWith(
phone: null == phone ? _self.phone : phone // ignore: cast_nullable_to_non_nullable
as String,email: null == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String,address: null == address ? _self.address : address // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [IssuerContact].
extension IssuerContactPatterns on IssuerContact {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _IssuerContact value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _IssuerContact() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _IssuerContact value)  $default,){
final _that = this;
switch (_that) {
case _IssuerContact():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _IssuerContact value)?  $default,){
final _that = this;
switch (_that) {
case _IssuerContact() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String phone,  String email,  String address)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _IssuerContact() when $default != null:
return $default(_that.phone,_that.email,_that.address);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String phone,  String email,  String address)  $default,) {final _that = this;
switch (_that) {
case _IssuerContact():
return $default(_that.phone,_that.email,_that.address);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String phone,  String email,  String address)?  $default,) {final _that = this;
switch (_that) {
case _IssuerContact() when $default != null:
return $default(_that.phone,_that.email,_that.address);case _:
  return null;

}
}

}

/// @nodoc


class _IssuerContact implements IssuerContact {
  const _IssuerContact({required this.phone, required this.email, required this.address});
  

@override final  String phone;
@override final  String email;
@override final  String address;

/// Create a copy of IssuerContact
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$IssuerContactCopyWith<_IssuerContact> get copyWith => __$IssuerContactCopyWithImpl<_IssuerContact>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _IssuerContact&&(identical(other.phone, phone) || other.phone == phone)&&(identical(other.email, email) || other.email == email)&&(identical(other.address, address) || other.address == address));
}


@override
int get hashCode => Object.hash(runtimeType,phone,email,address);

@override
String toString() {
  return 'IssuerContact(phone: $phone, email: $email, address: $address)';
}


}

/// @nodoc
abstract mixin class _$IssuerContactCopyWith<$Res> implements $IssuerContactCopyWith<$Res> {
  factory _$IssuerContactCopyWith(_IssuerContact value, $Res Function(_IssuerContact) _then) = __$IssuerContactCopyWithImpl;
@override @useResult
$Res call({
 String phone, String email, String address
});




}
/// @nodoc
class __$IssuerContactCopyWithImpl<$Res>
    implements _$IssuerContactCopyWith<$Res> {
  __$IssuerContactCopyWithImpl(this._self, this._then);

  final _IssuerContact _self;
  final $Res Function(_IssuerContact) _then;

/// Create a copy of IssuerContact
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? phone = null,Object? email = null,Object? address = null,}) {
  return _then(_IssuerContact(
phone: null == phone ? _self.phone : phone // ignore: cast_nullable_to_non_nullable
as String,email: null == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String,address: null == address ? _self.address : address // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc
mixin _$SignatureCheck {

/// `recorded` (an officer's signature is on file) or `missing`. A plain
/// String — never worded as "verified" anywhere downstream.
 String get status; String get provider; String get method; String get signerName; Bilingual? get signerTitle; String get signedAt; String get ca; String get format; String get timestamp;
/// Create a copy of SignatureCheck
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SignatureCheckCopyWith<SignatureCheck> get copyWith => _$SignatureCheckCopyWithImpl<SignatureCheck>(this as SignatureCheck, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SignatureCheck&&(identical(other.status, status) || other.status == status)&&(identical(other.provider, provider) || other.provider == provider)&&(identical(other.method, method) || other.method == method)&&(identical(other.signerName, signerName) || other.signerName == signerName)&&(identical(other.signerTitle, signerTitle) || other.signerTitle == signerTitle)&&(identical(other.signedAt, signedAt) || other.signedAt == signedAt)&&(identical(other.ca, ca) || other.ca == ca)&&(identical(other.format, format) || other.format == format)&&(identical(other.timestamp, timestamp) || other.timestamp == timestamp));
}


@override
int get hashCode => Object.hash(runtimeType,status,provider,method,signerName,signerTitle,signedAt,ca,format,timestamp);

@override
String toString() {
  return 'SignatureCheck(status: $status, provider: $provider, method: $method, signerName: $signerName, signerTitle: $signerTitle, signedAt: $signedAt, ca: $ca, format: $format, timestamp: $timestamp)';
}


}

/// @nodoc
abstract mixin class $SignatureCheckCopyWith<$Res>  {
  factory $SignatureCheckCopyWith(SignatureCheck value, $Res Function(SignatureCheck) _then) = _$SignatureCheckCopyWithImpl;
@useResult
$Res call({
 String status, String provider, String method, String signerName, Bilingual? signerTitle, String signedAt, String ca, String format, String timestamp
});


$BilingualCopyWith<$Res>? get signerTitle;

}
/// @nodoc
class _$SignatureCheckCopyWithImpl<$Res>
    implements $SignatureCheckCopyWith<$Res> {
  _$SignatureCheckCopyWithImpl(this._self, this._then);

  final SignatureCheck _self;
  final $Res Function(SignatureCheck) _then;

/// Create a copy of SignatureCheck
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? status = null,Object? provider = null,Object? method = null,Object? signerName = null,Object? signerTitle = freezed,Object? signedAt = null,Object? ca = null,Object? format = null,Object? timestamp = null,}) {
  return _then(_self.copyWith(
status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,provider: null == provider ? _self.provider : provider // ignore: cast_nullable_to_non_nullable
as String,method: null == method ? _self.method : method // ignore: cast_nullable_to_non_nullable
as String,signerName: null == signerName ? _self.signerName : signerName // ignore: cast_nullable_to_non_nullable
as String,signerTitle: freezed == signerTitle ? _self.signerTitle : signerTitle // ignore: cast_nullable_to_non_nullable
as Bilingual?,signedAt: null == signedAt ? _self.signedAt : signedAt // ignore: cast_nullable_to_non_nullable
as String,ca: null == ca ? _self.ca : ca // ignore: cast_nullable_to_non_nullable
as String,format: null == format ? _self.format : format // ignore: cast_nullable_to_non_nullable
as String,timestamp: null == timestamp ? _self.timestamp : timestamp // ignore: cast_nullable_to_non_nullable
as String,
  ));
}
/// Create a copy of SignatureCheck
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BilingualCopyWith<$Res>? get signerTitle {
    if (_self.signerTitle == null) {
    return null;
  }

  return $BilingualCopyWith<$Res>(_self.signerTitle!, (value) {
    return _then(_self.copyWith(signerTitle: value));
  });
}
}


/// Adds pattern-matching-related methods to [SignatureCheck].
extension SignatureCheckPatterns on SignatureCheck {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SignatureCheck value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SignatureCheck() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SignatureCheck value)  $default,){
final _that = this;
switch (_that) {
case _SignatureCheck():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SignatureCheck value)?  $default,){
final _that = this;
switch (_that) {
case _SignatureCheck() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String status,  String provider,  String method,  String signerName,  Bilingual? signerTitle,  String signedAt,  String ca,  String format,  String timestamp)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SignatureCheck() when $default != null:
return $default(_that.status,_that.provider,_that.method,_that.signerName,_that.signerTitle,_that.signedAt,_that.ca,_that.format,_that.timestamp);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String status,  String provider,  String method,  String signerName,  Bilingual? signerTitle,  String signedAt,  String ca,  String format,  String timestamp)  $default,) {final _that = this;
switch (_that) {
case _SignatureCheck():
return $default(_that.status,_that.provider,_that.method,_that.signerName,_that.signerTitle,_that.signedAt,_that.ca,_that.format,_that.timestamp);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String status,  String provider,  String method,  String signerName,  Bilingual? signerTitle,  String signedAt,  String ca,  String format,  String timestamp)?  $default,) {final _that = this;
switch (_that) {
case _SignatureCheck() when $default != null:
return $default(_that.status,_that.provider,_that.method,_that.signerName,_that.signerTitle,_that.signedAt,_that.ca,_that.format,_that.timestamp);case _:
  return null;

}
}

}

/// @nodoc


class _SignatureCheck implements SignatureCheck {
  const _SignatureCheck({required this.status, required this.provider, required this.method, required this.signerName, this.signerTitle, required this.signedAt, required this.ca, required this.format, required this.timestamp});
  

/// `recorded` (an officer's signature is on file) or `missing`. A plain
/// String — never worded as "verified" anywhere downstream.
@override final  String status;
@override final  String provider;
@override final  String method;
@override final  String signerName;
@override final  Bilingual? signerTitle;
@override final  String signedAt;
@override final  String ca;
@override final  String format;
@override final  String timestamp;

/// Create a copy of SignatureCheck
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SignatureCheckCopyWith<_SignatureCheck> get copyWith => __$SignatureCheckCopyWithImpl<_SignatureCheck>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SignatureCheck&&(identical(other.status, status) || other.status == status)&&(identical(other.provider, provider) || other.provider == provider)&&(identical(other.method, method) || other.method == method)&&(identical(other.signerName, signerName) || other.signerName == signerName)&&(identical(other.signerTitle, signerTitle) || other.signerTitle == signerTitle)&&(identical(other.signedAt, signedAt) || other.signedAt == signedAt)&&(identical(other.ca, ca) || other.ca == ca)&&(identical(other.format, format) || other.format == format)&&(identical(other.timestamp, timestamp) || other.timestamp == timestamp));
}


@override
int get hashCode => Object.hash(runtimeType,status,provider,method,signerName,signerTitle,signedAt,ca,format,timestamp);

@override
String toString() {
  return 'SignatureCheck(status: $status, provider: $provider, method: $method, signerName: $signerName, signerTitle: $signerTitle, signedAt: $signedAt, ca: $ca, format: $format, timestamp: $timestamp)';
}


}

/// @nodoc
abstract mixin class _$SignatureCheckCopyWith<$Res> implements $SignatureCheckCopyWith<$Res> {
  factory _$SignatureCheckCopyWith(_SignatureCheck value, $Res Function(_SignatureCheck) _then) = __$SignatureCheckCopyWithImpl;
@override @useResult
$Res call({
 String status, String provider, String method, String signerName, Bilingual? signerTitle, String signedAt, String ca, String format, String timestamp
});


@override $BilingualCopyWith<$Res>? get signerTitle;

}
/// @nodoc
class __$SignatureCheckCopyWithImpl<$Res>
    implements _$SignatureCheckCopyWith<$Res> {
  __$SignatureCheckCopyWithImpl(this._self, this._then);

  final _SignatureCheck _self;
  final $Res Function(_SignatureCheck) _then;

/// Create a copy of SignatureCheck
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? status = null,Object? provider = null,Object? method = null,Object? signerName = null,Object? signerTitle = freezed,Object? signedAt = null,Object? ca = null,Object? format = null,Object? timestamp = null,}) {
  return _then(_SignatureCheck(
status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,provider: null == provider ? _self.provider : provider // ignore: cast_nullable_to_non_nullable
as String,method: null == method ? _self.method : method // ignore: cast_nullable_to_non_nullable
as String,signerName: null == signerName ? _self.signerName : signerName // ignore: cast_nullable_to_non_nullable
as String,signerTitle: freezed == signerTitle ? _self.signerTitle : signerTitle // ignore: cast_nullable_to_non_nullable
as Bilingual?,signedAt: null == signedAt ? _self.signedAt : signedAt // ignore: cast_nullable_to_non_nullable
as String,ca: null == ca ? _self.ca : ca // ignore: cast_nullable_to_non_nullable
as String,format: null == format ? _self.format : format // ignore: cast_nullable_to_non_nullable
as String,timestamp: null == timestamp ? _self.timestamp : timestamp // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

/// Create a copy of SignatureCheck
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BilingualCopyWith<$Res>? get signerTitle {
    if (_self.signerTitle == null) {
    return null;
  }

  return $BilingualCopyWith<$Res>(_self.signerTitle!, (value) {
    return _then(_self.copyWith(signerTitle: value));
  });
}
}

/// @nodoc
mixin _$RecordHashCheck {

/// `match | mismatch | missing` — plain String, open set.
 String get status; String get algorithm;
/// Create a copy of RecordHashCheck
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RecordHashCheckCopyWith<RecordHashCheck> get copyWith => _$RecordHashCheckCopyWithImpl<RecordHashCheck>(this as RecordHashCheck, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RecordHashCheck&&(identical(other.status, status) || other.status == status)&&(identical(other.algorithm, algorithm) || other.algorithm == algorithm));
}


@override
int get hashCode => Object.hash(runtimeType,status,algorithm);

@override
String toString() {
  return 'RecordHashCheck(status: $status, algorithm: $algorithm)';
}


}

/// @nodoc
abstract mixin class $RecordHashCheckCopyWith<$Res>  {
  factory $RecordHashCheckCopyWith(RecordHashCheck value, $Res Function(RecordHashCheck) _then) = _$RecordHashCheckCopyWithImpl;
@useResult
$Res call({
 String status, String algorithm
});




}
/// @nodoc
class _$RecordHashCheckCopyWithImpl<$Res>
    implements $RecordHashCheckCopyWith<$Res> {
  _$RecordHashCheckCopyWithImpl(this._self, this._then);

  final RecordHashCheck _self;
  final $Res Function(RecordHashCheck) _then;

/// Create a copy of RecordHashCheck
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? status = null,Object? algorithm = null,}) {
  return _then(_self.copyWith(
status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,algorithm: null == algorithm ? _self.algorithm : algorithm // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [RecordHashCheck].
extension RecordHashCheckPatterns on RecordHashCheck {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _RecordHashCheck value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _RecordHashCheck() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _RecordHashCheck value)  $default,){
final _that = this;
switch (_that) {
case _RecordHashCheck():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _RecordHashCheck value)?  $default,){
final _that = this;
switch (_that) {
case _RecordHashCheck() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String status,  String algorithm)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _RecordHashCheck() when $default != null:
return $default(_that.status,_that.algorithm);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String status,  String algorithm)  $default,) {final _that = this;
switch (_that) {
case _RecordHashCheck():
return $default(_that.status,_that.algorithm);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String status,  String algorithm)?  $default,) {final _that = this;
switch (_that) {
case _RecordHashCheck() when $default != null:
return $default(_that.status,_that.algorithm);case _:
  return null;

}
}

}

/// @nodoc


class _RecordHashCheck implements RecordHashCheck {
  const _RecordHashCheck({required this.status, required this.algorithm});
  

/// `match | mismatch | missing` — plain String, open set.
@override final  String status;
@override final  String algorithm;

/// Create a copy of RecordHashCheck
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$RecordHashCheckCopyWith<_RecordHashCheck> get copyWith => __$RecordHashCheckCopyWithImpl<_RecordHashCheck>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _RecordHashCheck&&(identical(other.status, status) || other.status == status)&&(identical(other.algorithm, algorithm) || other.algorithm == algorithm));
}


@override
int get hashCode => Object.hash(runtimeType,status,algorithm);

@override
String toString() {
  return 'RecordHashCheck(status: $status, algorithm: $algorithm)';
}


}

/// @nodoc
abstract mixin class _$RecordHashCheckCopyWith<$Res> implements $RecordHashCheckCopyWith<$Res> {
  factory _$RecordHashCheckCopyWith(_RecordHashCheck value, $Res Function(_RecordHashCheck) _then) = __$RecordHashCheckCopyWithImpl;
@override @useResult
$Res call({
 String status, String algorithm
});




}
/// @nodoc
class __$RecordHashCheckCopyWithImpl<$Res>
    implements _$RecordHashCheckCopyWith<$Res> {
  __$RecordHashCheckCopyWithImpl(this._self, this._then);

  final _RecordHashCheck _self;
  final $Res Function(_RecordHashCheck) _then;

/// Create a copy of RecordHashCheck
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? status = null,Object? algorithm = null,}) {
  return _then(_RecordHashCheck(
status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,algorithm: null == algorithm ? _self.algorithm : algorithm // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc
mixin _$RevocationCheck {

 String get status; String get checkedAt;
/// Create a copy of RevocationCheck
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RevocationCheckCopyWith<RevocationCheck> get copyWith => _$RevocationCheckCopyWithImpl<RevocationCheck>(this as RevocationCheck, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RevocationCheck&&(identical(other.status, status) || other.status == status)&&(identical(other.checkedAt, checkedAt) || other.checkedAt == checkedAt));
}


@override
int get hashCode => Object.hash(runtimeType,status,checkedAt);

@override
String toString() {
  return 'RevocationCheck(status: $status, checkedAt: $checkedAt)';
}


}

/// @nodoc
abstract mixin class $RevocationCheckCopyWith<$Res>  {
  factory $RevocationCheckCopyWith(RevocationCheck value, $Res Function(RevocationCheck) _then) = _$RevocationCheckCopyWithImpl;
@useResult
$Res call({
 String status, String checkedAt
});




}
/// @nodoc
class _$RevocationCheckCopyWithImpl<$Res>
    implements $RevocationCheckCopyWith<$Res> {
  _$RevocationCheckCopyWithImpl(this._self, this._then);

  final RevocationCheck _self;
  final $Res Function(RevocationCheck) _then;

/// Create a copy of RevocationCheck
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? status = null,Object? checkedAt = null,}) {
  return _then(_self.copyWith(
status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,checkedAt: null == checkedAt ? _self.checkedAt : checkedAt // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [RevocationCheck].
extension RevocationCheckPatterns on RevocationCheck {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _RevocationCheck value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _RevocationCheck() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _RevocationCheck value)  $default,){
final _that = this;
switch (_that) {
case _RevocationCheck():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _RevocationCheck value)?  $default,){
final _that = this;
switch (_that) {
case _RevocationCheck() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String status,  String checkedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _RevocationCheck() when $default != null:
return $default(_that.status,_that.checkedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String status,  String checkedAt)  $default,) {final _that = this;
switch (_that) {
case _RevocationCheck():
return $default(_that.status,_that.checkedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String status,  String checkedAt)?  $default,) {final _that = this;
switch (_that) {
case _RevocationCheck() when $default != null:
return $default(_that.status,_that.checkedAt);case _:
  return null;

}
}

}

/// @nodoc


class _RevocationCheck implements RevocationCheck {
  const _RevocationCheck({required this.status, required this.checkedAt});
  

@override final  String status;
@override final  String checkedAt;

/// Create a copy of RevocationCheck
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$RevocationCheckCopyWith<_RevocationCheck> get copyWith => __$RevocationCheckCopyWithImpl<_RevocationCheck>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _RevocationCheck&&(identical(other.status, status) || other.status == status)&&(identical(other.checkedAt, checkedAt) || other.checkedAt == checkedAt));
}


@override
int get hashCode => Object.hash(runtimeType,status,checkedAt);

@override
String toString() {
  return 'RevocationCheck(status: $status, checkedAt: $checkedAt)';
}


}

/// @nodoc
abstract mixin class _$RevocationCheckCopyWith<$Res> implements $RevocationCheckCopyWith<$Res> {
  factory _$RevocationCheckCopyWith(_RevocationCheck value, $Res Function(_RevocationCheck) _then) = __$RevocationCheckCopyWithImpl;
@override @useResult
$Res call({
 String status, String checkedAt
});




}
/// @nodoc
class __$RevocationCheckCopyWithImpl<$Res>
    implements _$RevocationCheckCopyWith<$Res> {
  __$RevocationCheckCopyWithImpl(this._self, this._then);

  final _RevocationCheck _self;
  final $Res Function(_RevocationCheck) _then;

/// Create a copy of RevocationCheck
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? status = null,Object? checkedAt = null,}) {
  return _then(_RevocationCheck(
status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,checkedAt: null == checkedAt ? _self.checkedAt : checkedAt // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc
mixin _$VerificationChecks {

 SignatureCheck get signature; RecordHashCheck get recordHash; RevocationCheck get revocation;
/// Create a copy of VerificationChecks
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$VerificationChecksCopyWith<VerificationChecks> get copyWith => _$VerificationChecksCopyWithImpl<VerificationChecks>(this as VerificationChecks, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is VerificationChecks&&(identical(other.signature, signature) || other.signature == signature)&&(identical(other.recordHash, recordHash) || other.recordHash == recordHash)&&(identical(other.revocation, revocation) || other.revocation == revocation));
}


@override
int get hashCode => Object.hash(runtimeType,signature,recordHash,revocation);

@override
String toString() {
  return 'VerificationChecks(signature: $signature, recordHash: $recordHash, revocation: $revocation)';
}


}

/// @nodoc
abstract mixin class $VerificationChecksCopyWith<$Res>  {
  factory $VerificationChecksCopyWith(VerificationChecks value, $Res Function(VerificationChecks) _then) = _$VerificationChecksCopyWithImpl;
@useResult
$Res call({
 SignatureCheck signature, RecordHashCheck recordHash, RevocationCheck revocation
});


$SignatureCheckCopyWith<$Res> get signature;$RecordHashCheckCopyWith<$Res> get recordHash;$RevocationCheckCopyWith<$Res> get revocation;

}
/// @nodoc
class _$VerificationChecksCopyWithImpl<$Res>
    implements $VerificationChecksCopyWith<$Res> {
  _$VerificationChecksCopyWithImpl(this._self, this._then);

  final VerificationChecks _self;
  final $Res Function(VerificationChecks) _then;

/// Create a copy of VerificationChecks
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? signature = null,Object? recordHash = null,Object? revocation = null,}) {
  return _then(_self.copyWith(
signature: null == signature ? _self.signature : signature // ignore: cast_nullable_to_non_nullable
as SignatureCheck,recordHash: null == recordHash ? _self.recordHash : recordHash // ignore: cast_nullable_to_non_nullable
as RecordHashCheck,revocation: null == revocation ? _self.revocation : revocation // ignore: cast_nullable_to_non_nullable
as RevocationCheck,
  ));
}
/// Create a copy of VerificationChecks
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$SignatureCheckCopyWith<$Res> get signature {
  
  return $SignatureCheckCopyWith<$Res>(_self.signature, (value) {
    return _then(_self.copyWith(signature: value));
  });
}/// Create a copy of VerificationChecks
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$RecordHashCheckCopyWith<$Res> get recordHash {
  
  return $RecordHashCheckCopyWith<$Res>(_self.recordHash, (value) {
    return _then(_self.copyWith(recordHash: value));
  });
}/// Create a copy of VerificationChecks
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$RevocationCheckCopyWith<$Res> get revocation {
  
  return $RevocationCheckCopyWith<$Res>(_self.revocation, (value) {
    return _then(_self.copyWith(revocation: value));
  });
}
}


/// Adds pattern-matching-related methods to [VerificationChecks].
extension VerificationChecksPatterns on VerificationChecks {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _VerificationChecks value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _VerificationChecks() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _VerificationChecks value)  $default,){
final _that = this;
switch (_that) {
case _VerificationChecks():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _VerificationChecks value)?  $default,){
final _that = this;
switch (_that) {
case _VerificationChecks() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( SignatureCheck signature,  RecordHashCheck recordHash,  RevocationCheck revocation)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _VerificationChecks() when $default != null:
return $default(_that.signature,_that.recordHash,_that.revocation);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( SignatureCheck signature,  RecordHashCheck recordHash,  RevocationCheck revocation)  $default,) {final _that = this;
switch (_that) {
case _VerificationChecks():
return $default(_that.signature,_that.recordHash,_that.revocation);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( SignatureCheck signature,  RecordHashCheck recordHash,  RevocationCheck revocation)?  $default,) {final _that = this;
switch (_that) {
case _VerificationChecks() when $default != null:
return $default(_that.signature,_that.recordHash,_that.revocation);case _:
  return null;

}
}

}

/// @nodoc


class _VerificationChecks implements VerificationChecks {
  const _VerificationChecks({required this.signature, required this.recordHash, required this.revocation});
  

@override final  SignatureCheck signature;
@override final  RecordHashCheck recordHash;
@override final  RevocationCheck revocation;

/// Create a copy of VerificationChecks
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$VerificationChecksCopyWith<_VerificationChecks> get copyWith => __$VerificationChecksCopyWithImpl<_VerificationChecks>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _VerificationChecks&&(identical(other.signature, signature) || other.signature == signature)&&(identical(other.recordHash, recordHash) || other.recordHash == recordHash)&&(identical(other.revocation, revocation) || other.revocation == revocation));
}


@override
int get hashCode => Object.hash(runtimeType,signature,recordHash,revocation);

@override
String toString() {
  return 'VerificationChecks(signature: $signature, recordHash: $recordHash, revocation: $revocation)';
}


}

/// @nodoc
abstract mixin class _$VerificationChecksCopyWith<$Res> implements $VerificationChecksCopyWith<$Res> {
  factory _$VerificationChecksCopyWith(_VerificationChecks value, $Res Function(_VerificationChecks) _then) = __$VerificationChecksCopyWithImpl;
@override @useResult
$Res call({
 SignatureCheck signature, RecordHashCheck recordHash, RevocationCheck revocation
});


@override $SignatureCheckCopyWith<$Res> get signature;@override $RecordHashCheckCopyWith<$Res> get recordHash;@override $RevocationCheckCopyWith<$Res> get revocation;

}
/// @nodoc
class __$VerificationChecksCopyWithImpl<$Res>
    implements _$VerificationChecksCopyWith<$Res> {
  __$VerificationChecksCopyWithImpl(this._self, this._then);

  final _VerificationChecks _self;
  final $Res Function(_VerificationChecks) _then;

/// Create a copy of VerificationChecks
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? signature = null,Object? recordHash = null,Object? revocation = null,}) {
  return _then(_VerificationChecks(
signature: null == signature ? _self.signature : signature // ignore: cast_nullable_to_non_nullable
as SignatureCheck,recordHash: null == recordHash ? _self.recordHash : recordHash // ignore: cast_nullable_to_non_nullable
as RecordHashCheck,revocation: null == revocation ? _self.revocation : revocation // ignore: cast_nullable_to_non_nullable
as RevocationCheck,
  ));
}

/// Create a copy of VerificationChecks
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$SignatureCheckCopyWith<$Res> get signature {
  
  return $SignatureCheckCopyWith<$Res>(_self.signature, (value) {
    return _then(_self.copyWith(signature: value));
  });
}/// Create a copy of VerificationChecks
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$RecordHashCheckCopyWith<$Res> get recordHash {
  
  return $RecordHashCheckCopyWith<$Res>(_self.recordHash, (value) {
    return _then(_self.copyWith(recordHash: value));
  });
}/// Create a copy of VerificationChecks
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$RevocationCheckCopyWith<$Res> get revocation {
  
  return $RevocationCheckCopyWith<$Res>(_self.revocation, (value) {
    return _then(_self.copyWith(revocation: value));
  });
}
}

/// @nodoc
mixin _$VerificationResult {

/// `true` only for `issued` — but read as `bool?`: a non-bool wire value
/// is *unknown*, which `false` would misreport
/// (`certificate_wire.dart`'s `_nullableBoolAt` disposition).
 bool? get valid;/// `issued | expired | revoked | superseded | not-found` — plain String,
/// open set, the five-screen router Task 4 builds.
 String get status; String get certificateNo; String get documentType;/// `""` joint card, `A` husband's booklet, `B` wife's booklet (§ Divorce).
 String get copy; String get layout; Bilingual? get service; String get serviceCode;/// Masked server-side (`P****** S********`). Never unmasked here.
 String get holderName; List<String> get holders; String get issuedAt;/// The one optional whose `''` IS absence, per `certificate_wire.dart`'s
/// `_nullableDateAt` — EXPIRED needs a real date or nothing.
 String? get validUntil; Bilingual? get issuingOffice; IssuerContact? get issuerContact; String get verifyCode; String? get documentHash; String get language; String get revokedAt; String get revokeReason; String get replacedByCertificateNo; VerificationChecks get checks; String get checkedAt;
/// Create a copy of VerificationResult
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$VerificationResultCopyWith<VerificationResult> get copyWith => _$VerificationResultCopyWithImpl<VerificationResult>(this as VerificationResult, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is VerificationResult&&(identical(other.valid, valid) || other.valid == valid)&&(identical(other.status, status) || other.status == status)&&(identical(other.certificateNo, certificateNo) || other.certificateNo == certificateNo)&&(identical(other.documentType, documentType) || other.documentType == documentType)&&(identical(other.copy, copy) || other.copy == copy)&&(identical(other.layout, layout) || other.layout == layout)&&(identical(other.service, service) || other.service == service)&&(identical(other.serviceCode, serviceCode) || other.serviceCode == serviceCode)&&(identical(other.holderName, holderName) || other.holderName == holderName)&&const DeepCollectionEquality().equals(other.holders, holders)&&(identical(other.issuedAt, issuedAt) || other.issuedAt == issuedAt)&&(identical(other.validUntil, validUntil) || other.validUntil == validUntil)&&(identical(other.issuingOffice, issuingOffice) || other.issuingOffice == issuingOffice)&&(identical(other.issuerContact, issuerContact) || other.issuerContact == issuerContact)&&(identical(other.verifyCode, verifyCode) || other.verifyCode == verifyCode)&&(identical(other.documentHash, documentHash) || other.documentHash == documentHash)&&(identical(other.language, language) || other.language == language)&&(identical(other.revokedAt, revokedAt) || other.revokedAt == revokedAt)&&(identical(other.revokeReason, revokeReason) || other.revokeReason == revokeReason)&&(identical(other.replacedByCertificateNo, replacedByCertificateNo) || other.replacedByCertificateNo == replacedByCertificateNo)&&(identical(other.checks, checks) || other.checks == checks)&&(identical(other.checkedAt, checkedAt) || other.checkedAt == checkedAt));
}


@override
int get hashCode => Object.hashAll([runtimeType,valid,status,certificateNo,documentType,copy,layout,service,serviceCode,holderName,const DeepCollectionEquality().hash(holders),issuedAt,validUntil,issuingOffice,issuerContact,verifyCode,documentHash,language,revokedAt,revokeReason,replacedByCertificateNo,checks,checkedAt]);

@override
String toString() {
  return 'VerificationResult(valid: $valid, status: $status, certificateNo: $certificateNo, documentType: $documentType, copy: $copy, layout: $layout, service: $service, serviceCode: $serviceCode, holderName: $holderName, holders: $holders, issuedAt: $issuedAt, validUntil: $validUntil, issuingOffice: $issuingOffice, issuerContact: $issuerContact, verifyCode: $verifyCode, documentHash: $documentHash, language: $language, revokedAt: $revokedAt, revokeReason: $revokeReason, replacedByCertificateNo: $replacedByCertificateNo, checks: $checks, checkedAt: $checkedAt)';
}


}

/// @nodoc
abstract mixin class $VerificationResultCopyWith<$Res>  {
  factory $VerificationResultCopyWith(VerificationResult value, $Res Function(VerificationResult) _then) = _$VerificationResultCopyWithImpl;
@useResult
$Res call({
 bool? valid, String status, String certificateNo, String documentType, String copy, String layout, Bilingual? service, String serviceCode, String holderName, List<String> holders, String issuedAt, String? validUntil, Bilingual? issuingOffice, IssuerContact? issuerContact, String verifyCode, String? documentHash, String language, String revokedAt, String revokeReason, String replacedByCertificateNo, VerificationChecks checks, String checkedAt
});


$BilingualCopyWith<$Res>? get service;$BilingualCopyWith<$Res>? get issuingOffice;$IssuerContactCopyWith<$Res>? get issuerContact;$VerificationChecksCopyWith<$Res> get checks;

}
/// @nodoc
class _$VerificationResultCopyWithImpl<$Res>
    implements $VerificationResultCopyWith<$Res> {
  _$VerificationResultCopyWithImpl(this._self, this._then);

  final VerificationResult _self;
  final $Res Function(VerificationResult) _then;

/// Create a copy of VerificationResult
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? valid = freezed,Object? status = null,Object? certificateNo = null,Object? documentType = null,Object? copy = null,Object? layout = null,Object? service = freezed,Object? serviceCode = null,Object? holderName = null,Object? holders = null,Object? issuedAt = null,Object? validUntil = freezed,Object? issuingOffice = freezed,Object? issuerContact = freezed,Object? verifyCode = null,Object? documentHash = freezed,Object? language = null,Object? revokedAt = null,Object? revokeReason = null,Object? replacedByCertificateNo = null,Object? checks = null,Object? checkedAt = null,}) {
  return _then(_self.copyWith(
valid: freezed == valid ? _self.valid : valid // ignore: cast_nullable_to_non_nullable
as bool?,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,certificateNo: null == certificateNo ? _self.certificateNo : certificateNo // ignore: cast_nullable_to_non_nullable
as String,documentType: null == documentType ? _self.documentType : documentType // ignore: cast_nullable_to_non_nullable
as String,copy: null == copy ? _self.copy : copy // ignore: cast_nullable_to_non_nullable
as String,layout: null == layout ? _self.layout : layout // ignore: cast_nullable_to_non_nullable
as String,service: freezed == service ? _self.service : service // ignore: cast_nullable_to_non_nullable
as Bilingual?,serviceCode: null == serviceCode ? _self.serviceCode : serviceCode // ignore: cast_nullable_to_non_nullable
as String,holderName: null == holderName ? _self.holderName : holderName // ignore: cast_nullable_to_non_nullable
as String,holders: null == holders ? _self.holders : holders // ignore: cast_nullable_to_non_nullable
as List<String>,issuedAt: null == issuedAt ? _self.issuedAt : issuedAt // ignore: cast_nullable_to_non_nullable
as String,validUntil: freezed == validUntil ? _self.validUntil : validUntil // ignore: cast_nullable_to_non_nullable
as String?,issuingOffice: freezed == issuingOffice ? _self.issuingOffice : issuingOffice // ignore: cast_nullable_to_non_nullable
as Bilingual?,issuerContact: freezed == issuerContact ? _self.issuerContact : issuerContact // ignore: cast_nullable_to_non_nullable
as IssuerContact?,verifyCode: null == verifyCode ? _self.verifyCode : verifyCode // ignore: cast_nullable_to_non_nullable
as String,documentHash: freezed == documentHash ? _self.documentHash : documentHash // ignore: cast_nullable_to_non_nullable
as String?,language: null == language ? _self.language : language // ignore: cast_nullable_to_non_nullable
as String,revokedAt: null == revokedAt ? _self.revokedAt : revokedAt // ignore: cast_nullable_to_non_nullable
as String,revokeReason: null == revokeReason ? _self.revokeReason : revokeReason // ignore: cast_nullable_to_non_nullable
as String,replacedByCertificateNo: null == replacedByCertificateNo ? _self.replacedByCertificateNo : replacedByCertificateNo // ignore: cast_nullable_to_non_nullable
as String,checks: null == checks ? _self.checks : checks // ignore: cast_nullable_to_non_nullable
as VerificationChecks,checkedAt: null == checkedAt ? _self.checkedAt : checkedAt // ignore: cast_nullable_to_non_nullable
as String,
  ));
}
/// Create a copy of VerificationResult
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BilingualCopyWith<$Res>? get service {
    if (_self.service == null) {
    return null;
  }

  return $BilingualCopyWith<$Res>(_self.service!, (value) {
    return _then(_self.copyWith(service: value));
  });
}/// Create a copy of VerificationResult
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BilingualCopyWith<$Res>? get issuingOffice {
    if (_self.issuingOffice == null) {
    return null;
  }

  return $BilingualCopyWith<$Res>(_self.issuingOffice!, (value) {
    return _then(_self.copyWith(issuingOffice: value));
  });
}/// Create a copy of VerificationResult
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$IssuerContactCopyWith<$Res>? get issuerContact {
    if (_self.issuerContact == null) {
    return null;
  }

  return $IssuerContactCopyWith<$Res>(_self.issuerContact!, (value) {
    return _then(_self.copyWith(issuerContact: value));
  });
}/// Create a copy of VerificationResult
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$VerificationChecksCopyWith<$Res> get checks {
  
  return $VerificationChecksCopyWith<$Res>(_self.checks, (value) {
    return _then(_self.copyWith(checks: value));
  });
}
}


/// Adds pattern-matching-related methods to [VerificationResult].
extension VerificationResultPatterns on VerificationResult {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _VerificationResult value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _VerificationResult() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _VerificationResult value)  $default,){
final _that = this;
switch (_that) {
case _VerificationResult():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _VerificationResult value)?  $default,){
final _that = this;
switch (_that) {
case _VerificationResult() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( bool? valid,  String status,  String certificateNo,  String documentType,  String copy,  String layout,  Bilingual? service,  String serviceCode,  String holderName,  List<String> holders,  String issuedAt,  String? validUntil,  Bilingual? issuingOffice,  IssuerContact? issuerContact,  String verifyCode,  String? documentHash,  String language,  String revokedAt,  String revokeReason,  String replacedByCertificateNo,  VerificationChecks checks,  String checkedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _VerificationResult() when $default != null:
return $default(_that.valid,_that.status,_that.certificateNo,_that.documentType,_that.copy,_that.layout,_that.service,_that.serviceCode,_that.holderName,_that.holders,_that.issuedAt,_that.validUntil,_that.issuingOffice,_that.issuerContact,_that.verifyCode,_that.documentHash,_that.language,_that.revokedAt,_that.revokeReason,_that.replacedByCertificateNo,_that.checks,_that.checkedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( bool? valid,  String status,  String certificateNo,  String documentType,  String copy,  String layout,  Bilingual? service,  String serviceCode,  String holderName,  List<String> holders,  String issuedAt,  String? validUntil,  Bilingual? issuingOffice,  IssuerContact? issuerContact,  String verifyCode,  String? documentHash,  String language,  String revokedAt,  String revokeReason,  String replacedByCertificateNo,  VerificationChecks checks,  String checkedAt)  $default,) {final _that = this;
switch (_that) {
case _VerificationResult():
return $default(_that.valid,_that.status,_that.certificateNo,_that.documentType,_that.copy,_that.layout,_that.service,_that.serviceCode,_that.holderName,_that.holders,_that.issuedAt,_that.validUntil,_that.issuingOffice,_that.issuerContact,_that.verifyCode,_that.documentHash,_that.language,_that.revokedAt,_that.revokeReason,_that.replacedByCertificateNo,_that.checks,_that.checkedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( bool? valid,  String status,  String certificateNo,  String documentType,  String copy,  String layout,  Bilingual? service,  String serviceCode,  String holderName,  List<String> holders,  String issuedAt,  String? validUntil,  Bilingual? issuingOffice,  IssuerContact? issuerContact,  String verifyCode,  String? documentHash,  String language,  String revokedAt,  String revokeReason,  String replacedByCertificateNo,  VerificationChecks checks,  String checkedAt)?  $default,) {final _that = this;
switch (_that) {
case _VerificationResult() when $default != null:
return $default(_that.valid,_that.status,_that.certificateNo,_that.documentType,_that.copy,_that.layout,_that.service,_that.serviceCode,_that.holderName,_that.holders,_that.issuedAt,_that.validUntil,_that.issuingOffice,_that.issuerContact,_that.verifyCode,_that.documentHash,_that.language,_that.revokedAt,_that.revokeReason,_that.replacedByCertificateNo,_that.checks,_that.checkedAt);case _:
  return null;

}
}

}

/// @nodoc


class _VerificationResult implements VerificationResult {
  const _VerificationResult({this.valid, required this.status, required this.certificateNo, required this.documentType, required this.copy, required this.layout, this.service, required this.serviceCode, required this.holderName, final  List<String> holders = const <String>[], required this.issuedAt, this.validUntil, this.issuingOffice, this.issuerContact, required this.verifyCode, this.documentHash, required this.language, required this.revokedAt, required this.revokeReason, required this.replacedByCertificateNo, required this.checks, required this.checkedAt}): _holders = holders;
  

/// `true` only for `issued` — but read as `bool?`: a non-bool wire value
/// is *unknown*, which `false` would misreport
/// (`certificate_wire.dart`'s `_nullableBoolAt` disposition).
@override final  bool? valid;
/// `issued | expired | revoked | superseded | not-found` — plain String,
/// open set, the five-screen router Task 4 builds.
@override final  String status;
@override final  String certificateNo;
@override final  String documentType;
/// `""` joint card, `A` husband's booklet, `B` wife's booklet (§ Divorce).
@override final  String copy;
@override final  String layout;
@override final  Bilingual? service;
@override final  String serviceCode;
/// Masked server-side (`P****** S********`). Never unmasked here.
@override final  String holderName;
 final  List<String> _holders;
@override@JsonKey() List<String> get holders {
  if (_holders is EqualUnmodifiableListView) return _holders;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_holders);
}

@override final  String issuedAt;
/// The one optional whose `''` IS absence, per `certificate_wire.dart`'s
/// `_nullableDateAt` — EXPIRED needs a real date or nothing.
@override final  String? validUntil;
@override final  Bilingual? issuingOffice;
@override final  IssuerContact? issuerContact;
@override final  String verifyCode;
@override final  String? documentHash;
@override final  String language;
@override final  String revokedAt;
@override final  String revokeReason;
@override final  String replacedByCertificateNo;
@override final  VerificationChecks checks;
@override final  String checkedAt;

/// Create a copy of VerificationResult
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$VerificationResultCopyWith<_VerificationResult> get copyWith => __$VerificationResultCopyWithImpl<_VerificationResult>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _VerificationResult&&(identical(other.valid, valid) || other.valid == valid)&&(identical(other.status, status) || other.status == status)&&(identical(other.certificateNo, certificateNo) || other.certificateNo == certificateNo)&&(identical(other.documentType, documentType) || other.documentType == documentType)&&(identical(other.copy, copy) || other.copy == copy)&&(identical(other.layout, layout) || other.layout == layout)&&(identical(other.service, service) || other.service == service)&&(identical(other.serviceCode, serviceCode) || other.serviceCode == serviceCode)&&(identical(other.holderName, holderName) || other.holderName == holderName)&&const DeepCollectionEquality().equals(other._holders, _holders)&&(identical(other.issuedAt, issuedAt) || other.issuedAt == issuedAt)&&(identical(other.validUntil, validUntil) || other.validUntil == validUntil)&&(identical(other.issuingOffice, issuingOffice) || other.issuingOffice == issuingOffice)&&(identical(other.issuerContact, issuerContact) || other.issuerContact == issuerContact)&&(identical(other.verifyCode, verifyCode) || other.verifyCode == verifyCode)&&(identical(other.documentHash, documentHash) || other.documentHash == documentHash)&&(identical(other.language, language) || other.language == language)&&(identical(other.revokedAt, revokedAt) || other.revokedAt == revokedAt)&&(identical(other.revokeReason, revokeReason) || other.revokeReason == revokeReason)&&(identical(other.replacedByCertificateNo, replacedByCertificateNo) || other.replacedByCertificateNo == replacedByCertificateNo)&&(identical(other.checks, checks) || other.checks == checks)&&(identical(other.checkedAt, checkedAt) || other.checkedAt == checkedAt));
}


@override
int get hashCode => Object.hashAll([runtimeType,valid,status,certificateNo,documentType,copy,layout,service,serviceCode,holderName,const DeepCollectionEquality().hash(_holders),issuedAt,validUntil,issuingOffice,issuerContact,verifyCode,documentHash,language,revokedAt,revokeReason,replacedByCertificateNo,checks,checkedAt]);

@override
String toString() {
  return 'VerificationResult(valid: $valid, status: $status, certificateNo: $certificateNo, documentType: $documentType, copy: $copy, layout: $layout, service: $service, serviceCode: $serviceCode, holderName: $holderName, holders: $holders, issuedAt: $issuedAt, validUntil: $validUntil, issuingOffice: $issuingOffice, issuerContact: $issuerContact, verifyCode: $verifyCode, documentHash: $documentHash, language: $language, revokedAt: $revokedAt, revokeReason: $revokeReason, replacedByCertificateNo: $replacedByCertificateNo, checks: $checks, checkedAt: $checkedAt)';
}


}

/// @nodoc
abstract mixin class _$VerificationResultCopyWith<$Res> implements $VerificationResultCopyWith<$Res> {
  factory _$VerificationResultCopyWith(_VerificationResult value, $Res Function(_VerificationResult) _then) = __$VerificationResultCopyWithImpl;
@override @useResult
$Res call({
 bool? valid, String status, String certificateNo, String documentType, String copy, String layout, Bilingual? service, String serviceCode, String holderName, List<String> holders, String issuedAt, String? validUntil, Bilingual? issuingOffice, IssuerContact? issuerContact, String verifyCode, String? documentHash, String language, String revokedAt, String revokeReason, String replacedByCertificateNo, VerificationChecks checks, String checkedAt
});


@override $BilingualCopyWith<$Res>? get service;@override $BilingualCopyWith<$Res>? get issuingOffice;@override $IssuerContactCopyWith<$Res>? get issuerContact;@override $VerificationChecksCopyWith<$Res> get checks;

}
/// @nodoc
class __$VerificationResultCopyWithImpl<$Res>
    implements _$VerificationResultCopyWith<$Res> {
  __$VerificationResultCopyWithImpl(this._self, this._then);

  final _VerificationResult _self;
  final $Res Function(_VerificationResult) _then;

/// Create a copy of VerificationResult
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? valid = freezed,Object? status = null,Object? certificateNo = null,Object? documentType = null,Object? copy = null,Object? layout = null,Object? service = freezed,Object? serviceCode = null,Object? holderName = null,Object? holders = null,Object? issuedAt = null,Object? validUntil = freezed,Object? issuingOffice = freezed,Object? issuerContact = freezed,Object? verifyCode = null,Object? documentHash = freezed,Object? language = null,Object? revokedAt = null,Object? revokeReason = null,Object? replacedByCertificateNo = null,Object? checks = null,Object? checkedAt = null,}) {
  return _then(_VerificationResult(
valid: freezed == valid ? _self.valid : valid // ignore: cast_nullable_to_non_nullable
as bool?,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,certificateNo: null == certificateNo ? _self.certificateNo : certificateNo // ignore: cast_nullable_to_non_nullable
as String,documentType: null == documentType ? _self.documentType : documentType // ignore: cast_nullable_to_non_nullable
as String,copy: null == copy ? _self.copy : copy // ignore: cast_nullable_to_non_nullable
as String,layout: null == layout ? _self.layout : layout // ignore: cast_nullable_to_non_nullable
as String,service: freezed == service ? _self.service : service // ignore: cast_nullable_to_non_nullable
as Bilingual?,serviceCode: null == serviceCode ? _self.serviceCode : serviceCode // ignore: cast_nullable_to_non_nullable
as String,holderName: null == holderName ? _self.holderName : holderName // ignore: cast_nullable_to_non_nullable
as String,holders: null == holders ? _self._holders : holders // ignore: cast_nullable_to_non_nullable
as List<String>,issuedAt: null == issuedAt ? _self.issuedAt : issuedAt // ignore: cast_nullable_to_non_nullable
as String,validUntil: freezed == validUntil ? _self.validUntil : validUntil // ignore: cast_nullable_to_non_nullable
as String?,issuingOffice: freezed == issuingOffice ? _self.issuingOffice : issuingOffice // ignore: cast_nullable_to_non_nullable
as Bilingual?,issuerContact: freezed == issuerContact ? _self.issuerContact : issuerContact // ignore: cast_nullable_to_non_nullable
as IssuerContact?,verifyCode: null == verifyCode ? _self.verifyCode : verifyCode // ignore: cast_nullable_to_non_nullable
as String,documentHash: freezed == documentHash ? _self.documentHash : documentHash // ignore: cast_nullable_to_non_nullable
as String?,language: null == language ? _self.language : language // ignore: cast_nullable_to_non_nullable
as String,revokedAt: null == revokedAt ? _self.revokedAt : revokedAt // ignore: cast_nullable_to_non_nullable
as String,revokeReason: null == revokeReason ? _self.revokeReason : revokeReason // ignore: cast_nullable_to_non_nullable
as String,replacedByCertificateNo: null == replacedByCertificateNo ? _self.replacedByCertificateNo : replacedByCertificateNo // ignore: cast_nullable_to_non_nullable
as String,checks: null == checks ? _self.checks : checks // ignore: cast_nullable_to_non_nullable
as VerificationChecks,checkedAt: null == checkedAt ? _self.checkedAt : checkedAt // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

/// Create a copy of VerificationResult
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BilingualCopyWith<$Res>? get service {
    if (_self.service == null) {
    return null;
  }

  return $BilingualCopyWith<$Res>(_self.service!, (value) {
    return _then(_self.copyWith(service: value));
  });
}/// Create a copy of VerificationResult
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BilingualCopyWith<$Res>? get issuingOffice {
    if (_self.issuingOffice == null) {
    return null;
  }

  return $BilingualCopyWith<$Res>(_self.issuingOffice!, (value) {
    return _then(_self.copyWith(issuingOffice: value));
  });
}/// Create a copy of VerificationResult
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$IssuerContactCopyWith<$Res>? get issuerContact {
    if (_self.issuerContact == null) {
    return null;
  }

  return $IssuerContactCopyWith<$Res>(_self.issuerContact!, (value) {
    return _then(_self.copyWith(issuerContact: value));
  });
}/// Create a copy of VerificationResult
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$VerificationChecksCopyWith<$Res> get checks {
  
  return $VerificationChecksCopyWith<$Res>(_self.checks, (value) {
    return _then(_self.copyWith(checks: value));
  });
}
}

// dart format on
