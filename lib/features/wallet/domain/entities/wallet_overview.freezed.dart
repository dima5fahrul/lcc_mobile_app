// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'wallet_overview.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$Wallet {

 String get id;/// Rendered under the balance, in a monospace face, **and only while the
/// balance is shown** (`WalletPage.tsx:190` — the branch requires
/// `showBalance`). Hiding the balance hides the account number with it.
 String get accountNo; int get balanceLak; String get currency; String get status;
/// Create a copy of Wallet
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$WalletCopyWith<Wallet> get copyWith => _$WalletCopyWithImpl<Wallet>(this as Wallet, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Wallet&&(identical(other.id, id) || other.id == id)&&(identical(other.accountNo, accountNo) || other.accountNo == accountNo)&&(identical(other.balanceLak, balanceLak) || other.balanceLak == balanceLak)&&(identical(other.currency, currency) || other.currency == currency)&&(identical(other.status, status) || other.status == status));
}


@override
int get hashCode => Object.hash(runtimeType,id,accountNo,balanceLak,currency,status);

@override
String toString() {
  return 'Wallet(id: $id, accountNo: $accountNo, balanceLak: $balanceLak, currency: $currency, status: $status)';
}


}

/// @nodoc
abstract mixin class $WalletCopyWith<$Res>  {
  factory $WalletCopyWith(Wallet value, $Res Function(Wallet) _then) = _$WalletCopyWithImpl;
@useResult
$Res call({
 String id, String accountNo, int balanceLak, String currency, String status
});




}
/// @nodoc
class _$WalletCopyWithImpl<$Res>
    implements $WalletCopyWith<$Res> {
  _$WalletCopyWithImpl(this._self, this._then);

  final Wallet _self;
  final $Res Function(Wallet) _then;

/// Create a copy of Wallet
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? accountNo = null,Object? balanceLak = null,Object? currency = null,Object? status = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,accountNo: null == accountNo ? _self.accountNo : accountNo // ignore: cast_nullable_to_non_nullable
as String,balanceLak: null == balanceLak ? _self.balanceLak : balanceLak // ignore: cast_nullable_to_non_nullable
as int,currency: null == currency ? _self.currency : currency // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [Wallet].
extension WalletPatterns on Wallet {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Wallet value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Wallet() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Wallet value)  $default,){
final _that = this;
switch (_that) {
case _Wallet():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Wallet value)?  $default,){
final _that = this;
switch (_that) {
case _Wallet() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String accountNo,  int balanceLak,  String currency,  String status)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Wallet() when $default != null:
return $default(_that.id,_that.accountNo,_that.balanceLak,_that.currency,_that.status);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String accountNo,  int balanceLak,  String currency,  String status)  $default,) {final _that = this;
switch (_that) {
case _Wallet():
return $default(_that.id,_that.accountNo,_that.balanceLak,_that.currency,_that.status);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String accountNo,  int balanceLak,  String currency,  String status)?  $default,) {final _that = this;
switch (_that) {
case _Wallet() when $default != null:
return $default(_that.id,_that.accountNo,_that.balanceLak,_that.currency,_that.status);case _:
  return null;

}
}

}

/// @nodoc


class _Wallet implements Wallet {
  const _Wallet({required this.id, required this.accountNo, required this.balanceLak, required this.currency, required this.status});
  

@override final  String id;
/// Rendered under the balance, in a monospace face, **and only while the
/// balance is shown** (`WalletPage.tsx:190` — the branch requires
/// `showBalance`). Hiding the balance hides the account number with it.
@override final  String accountNo;
@override final  int balanceLak;
@override final  String currency;
@override final  String status;

/// Create a copy of Wallet
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$WalletCopyWith<_Wallet> get copyWith => __$WalletCopyWithImpl<_Wallet>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Wallet&&(identical(other.id, id) || other.id == id)&&(identical(other.accountNo, accountNo) || other.accountNo == accountNo)&&(identical(other.balanceLak, balanceLak) || other.balanceLak == balanceLak)&&(identical(other.currency, currency) || other.currency == currency)&&(identical(other.status, status) || other.status == status));
}


@override
int get hashCode => Object.hash(runtimeType,id,accountNo,balanceLak,currency,status);

@override
String toString() {
  return 'Wallet(id: $id, accountNo: $accountNo, balanceLak: $balanceLak, currency: $currency, status: $status)';
}


}

/// @nodoc
abstract mixin class _$WalletCopyWith<$Res> implements $WalletCopyWith<$Res> {
  factory _$WalletCopyWith(_Wallet value, $Res Function(_Wallet) _then) = __$WalletCopyWithImpl;
@override @useResult
$Res call({
 String id, String accountNo, int balanceLak, String currency, String status
});




}
/// @nodoc
class __$WalletCopyWithImpl<$Res>
    implements _$WalletCopyWith<$Res> {
  __$WalletCopyWithImpl(this._self, this._then);

  final _Wallet _self;
  final $Res Function(_Wallet) _then;

/// Create a copy of Wallet
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? accountNo = null,Object? balanceLak = null,Object? currency = null,Object? status = null,}) {
  return _then(_Wallet(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,accountNo: null == accountNo ? _self.accountNo : accountNo // ignore: cast_nullable_to_non_nullable
as String,balanceLak: null == balanceLak ? _self.balanceLak : balanceLak // ignore: cast_nullable_to_non_nullable
as int,currency: null == currency ? _self.currency : currency // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc
mixin _$WalletOverview {

 Wallet get wallet;/// The ledger's **first frame** comes from here, not from
/// `/me/wallet/entries` — `WalletPage.tsx:128-130`, and it is deliberate:
/// *"While page 1 of the ledger loads, the wallet overview already carries
/// the last few entries — show those rather than an empty panel."*
/// (`B6-DIV-5`, `B6-AC-27`.)
 List<WalletEntry> get recentEntries; int get entryCount; bool get canTopUp;/// Nullable on purpose — see the library doc.
 int? get minTopUpLak; int? get maxTopUpLak;
/// Create a copy of WalletOverview
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$WalletOverviewCopyWith<WalletOverview> get copyWith => _$WalletOverviewCopyWithImpl<WalletOverview>(this as WalletOverview, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is WalletOverview&&(identical(other.wallet, wallet) || other.wallet == wallet)&&const DeepCollectionEquality().equals(other.recentEntries, recentEntries)&&(identical(other.entryCount, entryCount) || other.entryCount == entryCount)&&(identical(other.canTopUp, canTopUp) || other.canTopUp == canTopUp)&&(identical(other.minTopUpLak, minTopUpLak) || other.minTopUpLak == minTopUpLak)&&(identical(other.maxTopUpLak, maxTopUpLak) || other.maxTopUpLak == maxTopUpLak));
}


@override
int get hashCode => Object.hash(runtimeType,wallet,const DeepCollectionEquality().hash(recentEntries),entryCount,canTopUp,minTopUpLak,maxTopUpLak);

@override
String toString() {
  return 'WalletOverview(wallet: $wallet, recentEntries: $recentEntries, entryCount: $entryCount, canTopUp: $canTopUp, minTopUpLak: $minTopUpLak, maxTopUpLak: $maxTopUpLak)';
}


}

/// @nodoc
abstract mixin class $WalletOverviewCopyWith<$Res>  {
  factory $WalletOverviewCopyWith(WalletOverview value, $Res Function(WalletOverview) _then) = _$WalletOverviewCopyWithImpl;
@useResult
$Res call({
 Wallet wallet, List<WalletEntry> recentEntries, int entryCount, bool canTopUp, int? minTopUpLak, int? maxTopUpLak
});


$WalletCopyWith<$Res> get wallet;

}
/// @nodoc
class _$WalletOverviewCopyWithImpl<$Res>
    implements $WalletOverviewCopyWith<$Res> {
  _$WalletOverviewCopyWithImpl(this._self, this._then);

  final WalletOverview _self;
  final $Res Function(WalletOverview) _then;

/// Create a copy of WalletOverview
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? wallet = null,Object? recentEntries = null,Object? entryCount = null,Object? canTopUp = null,Object? minTopUpLak = freezed,Object? maxTopUpLak = freezed,}) {
  return _then(_self.copyWith(
wallet: null == wallet ? _self.wallet : wallet // ignore: cast_nullable_to_non_nullable
as Wallet,recentEntries: null == recentEntries ? _self.recentEntries : recentEntries // ignore: cast_nullable_to_non_nullable
as List<WalletEntry>,entryCount: null == entryCount ? _self.entryCount : entryCount // ignore: cast_nullable_to_non_nullable
as int,canTopUp: null == canTopUp ? _self.canTopUp : canTopUp // ignore: cast_nullable_to_non_nullable
as bool,minTopUpLak: freezed == minTopUpLak ? _self.minTopUpLak : minTopUpLak // ignore: cast_nullable_to_non_nullable
as int?,maxTopUpLak: freezed == maxTopUpLak ? _self.maxTopUpLak : maxTopUpLak // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}
/// Create a copy of WalletOverview
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$WalletCopyWith<$Res> get wallet {
  
  return $WalletCopyWith<$Res>(_self.wallet, (value) {
    return _then(_self.copyWith(wallet: value));
  });
}
}


/// Adds pattern-matching-related methods to [WalletOverview].
extension WalletOverviewPatterns on WalletOverview {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _WalletOverview value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _WalletOverview() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _WalletOverview value)  $default,){
final _that = this;
switch (_that) {
case _WalletOverview():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _WalletOverview value)?  $default,){
final _that = this;
switch (_that) {
case _WalletOverview() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( Wallet wallet,  List<WalletEntry> recentEntries,  int entryCount,  bool canTopUp,  int? minTopUpLak,  int? maxTopUpLak)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _WalletOverview() when $default != null:
return $default(_that.wallet,_that.recentEntries,_that.entryCount,_that.canTopUp,_that.minTopUpLak,_that.maxTopUpLak);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( Wallet wallet,  List<WalletEntry> recentEntries,  int entryCount,  bool canTopUp,  int? minTopUpLak,  int? maxTopUpLak)  $default,) {final _that = this;
switch (_that) {
case _WalletOverview():
return $default(_that.wallet,_that.recentEntries,_that.entryCount,_that.canTopUp,_that.minTopUpLak,_that.maxTopUpLak);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( Wallet wallet,  List<WalletEntry> recentEntries,  int entryCount,  bool canTopUp,  int? minTopUpLak,  int? maxTopUpLak)?  $default,) {final _that = this;
switch (_that) {
case _WalletOverview() when $default != null:
return $default(_that.wallet,_that.recentEntries,_that.entryCount,_that.canTopUp,_that.minTopUpLak,_that.maxTopUpLak);case _:
  return null;

}
}

}

/// @nodoc


class _WalletOverview implements WalletOverview {
  const _WalletOverview({required this.wallet, final  List<WalletEntry> recentEntries = const <WalletEntry>[], this.entryCount = 0, this.canTopUp = false, this.minTopUpLak, this.maxTopUpLak}): _recentEntries = recentEntries;
  

@override final  Wallet wallet;
/// The ledger's **first frame** comes from here, not from
/// `/me/wallet/entries` — `WalletPage.tsx:128-130`, and it is deliberate:
/// *"While page 1 of the ledger loads, the wallet overview already carries
/// the last few entries — show those rather than an empty panel."*
/// (`B6-DIV-5`, `B6-AC-27`.)
 final  List<WalletEntry> _recentEntries;
/// The ledger's **first frame** comes from here, not from
/// `/me/wallet/entries` — `WalletPage.tsx:128-130`, and it is deliberate:
/// *"While page 1 of the ledger loads, the wallet overview already carries
/// the last few entries — show those rather than an empty panel."*
/// (`B6-DIV-5`, `B6-AC-27`.)
@override@JsonKey() List<WalletEntry> get recentEntries {
  if (_recentEntries is EqualUnmodifiableListView) return _recentEntries;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_recentEntries);
}

@override@JsonKey() final  int entryCount;
@override@JsonKey() final  bool canTopUp;
/// Nullable on purpose — see the library doc.
@override final  int? minTopUpLak;
@override final  int? maxTopUpLak;

/// Create a copy of WalletOverview
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$WalletOverviewCopyWith<_WalletOverview> get copyWith => __$WalletOverviewCopyWithImpl<_WalletOverview>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _WalletOverview&&(identical(other.wallet, wallet) || other.wallet == wallet)&&const DeepCollectionEquality().equals(other._recentEntries, _recentEntries)&&(identical(other.entryCount, entryCount) || other.entryCount == entryCount)&&(identical(other.canTopUp, canTopUp) || other.canTopUp == canTopUp)&&(identical(other.minTopUpLak, minTopUpLak) || other.minTopUpLak == minTopUpLak)&&(identical(other.maxTopUpLak, maxTopUpLak) || other.maxTopUpLak == maxTopUpLak));
}


@override
int get hashCode => Object.hash(runtimeType,wallet,const DeepCollectionEquality().hash(_recentEntries),entryCount,canTopUp,minTopUpLak,maxTopUpLak);

@override
String toString() {
  return 'WalletOverview(wallet: $wallet, recentEntries: $recentEntries, entryCount: $entryCount, canTopUp: $canTopUp, minTopUpLak: $minTopUpLak, maxTopUpLak: $maxTopUpLak)';
}


}

/// @nodoc
abstract mixin class _$WalletOverviewCopyWith<$Res> implements $WalletOverviewCopyWith<$Res> {
  factory _$WalletOverviewCopyWith(_WalletOverview value, $Res Function(_WalletOverview) _then) = __$WalletOverviewCopyWithImpl;
@override @useResult
$Res call({
 Wallet wallet, List<WalletEntry> recentEntries, int entryCount, bool canTopUp, int? minTopUpLak, int? maxTopUpLak
});


@override $WalletCopyWith<$Res> get wallet;

}
/// @nodoc
class __$WalletOverviewCopyWithImpl<$Res>
    implements _$WalletOverviewCopyWith<$Res> {
  __$WalletOverviewCopyWithImpl(this._self, this._then);

  final _WalletOverview _self;
  final $Res Function(_WalletOverview) _then;

/// Create a copy of WalletOverview
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? wallet = null,Object? recentEntries = null,Object? entryCount = null,Object? canTopUp = null,Object? minTopUpLak = freezed,Object? maxTopUpLak = freezed,}) {
  return _then(_WalletOverview(
wallet: null == wallet ? _self.wallet : wallet // ignore: cast_nullable_to_non_nullable
as Wallet,recentEntries: null == recentEntries ? _self._recentEntries : recentEntries // ignore: cast_nullable_to_non_nullable
as List<WalletEntry>,entryCount: null == entryCount ? _self.entryCount : entryCount // ignore: cast_nullable_to_non_nullable
as int,canTopUp: null == canTopUp ? _self.canTopUp : canTopUp // ignore: cast_nullable_to_non_nullable
as bool,minTopUpLak: freezed == minTopUpLak ? _self.minTopUpLak : minTopUpLak // ignore: cast_nullable_to_non_nullable
as int?,maxTopUpLak: freezed == maxTopUpLak ? _self.maxTopUpLak : maxTopUpLak // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}

/// Create a copy of WalletOverview
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$WalletCopyWith<$Res> get wallet {
  
  return $WalletCopyWith<$Res>(_self.wallet, (value) {
    return _then(_self.copyWith(wallet: value));
  });
}
}

// dart format on
