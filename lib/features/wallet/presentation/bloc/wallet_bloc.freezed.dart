// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'wallet_bloc.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$WalletState {

 bool get isAuthenticated;// ── overview: `/me/wallet` ───────────────────────────────────────────────
 WalletOverview? get overview; bool get overviewLoading; String? get overviewError;// ── bills: `/applications/?page=1&per_page=50` (B6b) ─────────────────────
/// Already filtered to `payment_state === "pending" && fee_lak > 0` by
/// [ListPendingBills] — the source filters at `:123-125`, immediately after
/// the query and before anything reads it, so an unfiltered list never
/// exists on the web either.
 List<ApplicationRow> get bills; bool get billsLoading; String? get billsError;// ── receipts: `/me/transactions` ─────────────────────────────────────────
 List<Transaction> get receipts; bool get receiptsLoading; String? get receiptsError;// ── ledger: `/me/wallet/entries`, enabled only while [showLedger] ────────
/// `null` until the first page has arrived. Distinguished from an empty
/// page because the *first frame* of the ledger deliberately renders
/// `overview.recentEntries` instead (§ 6.8(3)) — a distinction an empty
/// `PagedRows` could not carry.
 PagedRows<WalletEntry>? get ledger; bool get ledgerLoading; String? get ledgerError; bool get showLedger; int get ledgerPage;// ── methods: `/payment-methods`, fetched by the sheet ────────────────────
 List<PaymentMethod> get methods; bool get methodsLoading; String? get methodsError;// ── the top-up mutation ──────────────────────────────────────────────────
 bool get topUpPending; String? get topUpError;/// Raised for one state emission after a successful credit, so the page can
/// close the sheet. `onDone` (`:559-562`) is a callback on the web; a BLoC
/// has no callbacks, so it is a flag the listener consumes.
 bool get topUpSucceeded;// ── the pay mutation (B6b) ───────────────────────────────────────────────
/// `charge.pending` — `PaymentSection.tsx:456`.
 bool get payPending;/// `charge.error` — the **whole** failure, not its message.
///
/// A `String?` here (as the four read regions carry) would throw away
/// `.code`, and `.code` is what splits the render in two: an amber
/// insufficient-funds panel with a top-up button versus a red line
/// (`:219`, `:352-385`). [payInsufficient] is the split and it is the only
/// reason this field is not a message.
 PaymentFailure? get payFailure;/// `charge.data` — absent until a charge returns. **There is no
/// "succeeded" flag beside it**, unlike [topUpSucceeded]: the source does
/// not close the pay sheet on success, it *re-renders it* into a settled
/// line or an instruction panel (`:439-450`), and the sheet stays open
/// until the citizen dismisses it. `PaymentResult.isSettled` is what the
/// terminal branch reads.
 PaymentResult? get payResult;
/// Create a copy of WalletState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$WalletStateCopyWith<WalletState> get copyWith => _$WalletStateCopyWithImpl<WalletState>(this as WalletState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is WalletState&&(identical(other.isAuthenticated, isAuthenticated) || other.isAuthenticated == isAuthenticated)&&(identical(other.overview, overview) || other.overview == overview)&&(identical(other.overviewLoading, overviewLoading) || other.overviewLoading == overviewLoading)&&(identical(other.overviewError, overviewError) || other.overviewError == overviewError)&&const DeepCollectionEquality().equals(other.bills, bills)&&(identical(other.billsLoading, billsLoading) || other.billsLoading == billsLoading)&&(identical(other.billsError, billsError) || other.billsError == billsError)&&const DeepCollectionEquality().equals(other.receipts, receipts)&&(identical(other.receiptsLoading, receiptsLoading) || other.receiptsLoading == receiptsLoading)&&(identical(other.receiptsError, receiptsError) || other.receiptsError == receiptsError)&&(identical(other.ledger, ledger) || other.ledger == ledger)&&(identical(other.ledgerLoading, ledgerLoading) || other.ledgerLoading == ledgerLoading)&&(identical(other.ledgerError, ledgerError) || other.ledgerError == ledgerError)&&(identical(other.showLedger, showLedger) || other.showLedger == showLedger)&&(identical(other.ledgerPage, ledgerPage) || other.ledgerPage == ledgerPage)&&const DeepCollectionEquality().equals(other.methods, methods)&&(identical(other.methodsLoading, methodsLoading) || other.methodsLoading == methodsLoading)&&(identical(other.methodsError, methodsError) || other.methodsError == methodsError)&&(identical(other.topUpPending, topUpPending) || other.topUpPending == topUpPending)&&(identical(other.topUpError, topUpError) || other.topUpError == topUpError)&&(identical(other.topUpSucceeded, topUpSucceeded) || other.topUpSucceeded == topUpSucceeded)&&(identical(other.payPending, payPending) || other.payPending == payPending)&&(identical(other.payFailure, payFailure) || other.payFailure == payFailure)&&(identical(other.payResult, payResult) || other.payResult == payResult));
}


@override
int get hashCode => Object.hashAll([runtimeType,isAuthenticated,overview,overviewLoading,overviewError,const DeepCollectionEquality().hash(bills),billsLoading,billsError,const DeepCollectionEquality().hash(receipts),receiptsLoading,receiptsError,ledger,ledgerLoading,ledgerError,showLedger,ledgerPage,const DeepCollectionEquality().hash(methods),methodsLoading,methodsError,topUpPending,topUpError,topUpSucceeded,payPending,payFailure,payResult]);

@override
String toString() {
  return 'WalletState(isAuthenticated: $isAuthenticated, overview: $overview, overviewLoading: $overviewLoading, overviewError: $overviewError, bills: $bills, billsLoading: $billsLoading, billsError: $billsError, receipts: $receipts, receiptsLoading: $receiptsLoading, receiptsError: $receiptsError, ledger: $ledger, ledgerLoading: $ledgerLoading, ledgerError: $ledgerError, showLedger: $showLedger, ledgerPage: $ledgerPage, methods: $methods, methodsLoading: $methodsLoading, methodsError: $methodsError, topUpPending: $topUpPending, topUpError: $topUpError, topUpSucceeded: $topUpSucceeded, payPending: $payPending, payFailure: $payFailure, payResult: $payResult)';
}


}

/// @nodoc
abstract mixin class $WalletStateCopyWith<$Res>  {
  factory $WalletStateCopyWith(WalletState value, $Res Function(WalletState) _then) = _$WalletStateCopyWithImpl;
@useResult
$Res call({
 bool isAuthenticated, WalletOverview? overview, bool overviewLoading, String? overviewError, List<ApplicationRow> bills, bool billsLoading, String? billsError, List<Transaction> receipts, bool receiptsLoading, String? receiptsError, PagedRows<WalletEntry>? ledger, bool ledgerLoading, String? ledgerError, bool showLedger, int ledgerPage, List<PaymentMethod> methods, bool methodsLoading, String? methodsError, bool topUpPending, String? topUpError, bool topUpSucceeded, bool payPending, PaymentFailure? payFailure, PaymentResult? payResult
});


$WalletOverviewCopyWith<$Res>? get overview;$PaymentResultCopyWith<$Res>? get payResult;

}
/// @nodoc
class _$WalletStateCopyWithImpl<$Res>
    implements $WalletStateCopyWith<$Res> {
  _$WalletStateCopyWithImpl(this._self, this._then);

  final WalletState _self;
  final $Res Function(WalletState) _then;

/// Create a copy of WalletState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? isAuthenticated = null,Object? overview = freezed,Object? overviewLoading = null,Object? overviewError = freezed,Object? bills = null,Object? billsLoading = null,Object? billsError = freezed,Object? receipts = null,Object? receiptsLoading = null,Object? receiptsError = freezed,Object? ledger = freezed,Object? ledgerLoading = null,Object? ledgerError = freezed,Object? showLedger = null,Object? ledgerPage = null,Object? methods = null,Object? methodsLoading = null,Object? methodsError = freezed,Object? topUpPending = null,Object? topUpError = freezed,Object? topUpSucceeded = null,Object? payPending = null,Object? payFailure = freezed,Object? payResult = freezed,}) {
  return _then(_self.copyWith(
isAuthenticated: null == isAuthenticated ? _self.isAuthenticated : isAuthenticated // ignore: cast_nullable_to_non_nullable
as bool,overview: freezed == overview ? _self.overview : overview // ignore: cast_nullable_to_non_nullable
as WalletOverview?,overviewLoading: null == overviewLoading ? _self.overviewLoading : overviewLoading // ignore: cast_nullable_to_non_nullable
as bool,overviewError: freezed == overviewError ? _self.overviewError : overviewError // ignore: cast_nullable_to_non_nullable
as String?,bills: null == bills ? _self.bills : bills // ignore: cast_nullable_to_non_nullable
as List<ApplicationRow>,billsLoading: null == billsLoading ? _self.billsLoading : billsLoading // ignore: cast_nullable_to_non_nullable
as bool,billsError: freezed == billsError ? _self.billsError : billsError // ignore: cast_nullable_to_non_nullable
as String?,receipts: null == receipts ? _self.receipts : receipts // ignore: cast_nullable_to_non_nullable
as List<Transaction>,receiptsLoading: null == receiptsLoading ? _self.receiptsLoading : receiptsLoading // ignore: cast_nullable_to_non_nullable
as bool,receiptsError: freezed == receiptsError ? _self.receiptsError : receiptsError // ignore: cast_nullable_to_non_nullable
as String?,ledger: freezed == ledger ? _self.ledger : ledger // ignore: cast_nullable_to_non_nullable
as PagedRows<WalletEntry>?,ledgerLoading: null == ledgerLoading ? _self.ledgerLoading : ledgerLoading // ignore: cast_nullable_to_non_nullable
as bool,ledgerError: freezed == ledgerError ? _self.ledgerError : ledgerError // ignore: cast_nullable_to_non_nullable
as String?,showLedger: null == showLedger ? _self.showLedger : showLedger // ignore: cast_nullable_to_non_nullable
as bool,ledgerPage: null == ledgerPage ? _self.ledgerPage : ledgerPage // ignore: cast_nullable_to_non_nullable
as int,methods: null == methods ? _self.methods : methods // ignore: cast_nullable_to_non_nullable
as List<PaymentMethod>,methodsLoading: null == methodsLoading ? _self.methodsLoading : methodsLoading // ignore: cast_nullable_to_non_nullable
as bool,methodsError: freezed == methodsError ? _self.methodsError : methodsError // ignore: cast_nullable_to_non_nullable
as String?,topUpPending: null == topUpPending ? _self.topUpPending : topUpPending // ignore: cast_nullable_to_non_nullable
as bool,topUpError: freezed == topUpError ? _self.topUpError : topUpError // ignore: cast_nullable_to_non_nullable
as String?,topUpSucceeded: null == topUpSucceeded ? _self.topUpSucceeded : topUpSucceeded // ignore: cast_nullable_to_non_nullable
as bool,payPending: null == payPending ? _self.payPending : payPending // ignore: cast_nullable_to_non_nullable
as bool,payFailure: freezed == payFailure ? _self.payFailure : payFailure // ignore: cast_nullable_to_non_nullable
as PaymentFailure?,payResult: freezed == payResult ? _self.payResult : payResult // ignore: cast_nullable_to_non_nullable
as PaymentResult?,
  ));
}
/// Create a copy of WalletState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$WalletOverviewCopyWith<$Res>? get overview {
    if (_self.overview == null) {
    return null;
  }

  return $WalletOverviewCopyWith<$Res>(_self.overview!, (value) {
    return _then(_self.copyWith(overview: value));
  });
}/// Create a copy of WalletState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PaymentResultCopyWith<$Res>? get payResult {
    if (_self.payResult == null) {
    return null;
  }

  return $PaymentResultCopyWith<$Res>(_self.payResult!, (value) {
    return _then(_self.copyWith(payResult: value));
  });
}
}


/// Adds pattern-matching-related methods to [WalletState].
extension WalletStatePatterns on WalletState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _WalletState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _WalletState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _WalletState value)  $default,){
final _that = this;
switch (_that) {
case _WalletState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _WalletState value)?  $default,){
final _that = this;
switch (_that) {
case _WalletState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( bool isAuthenticated,  WalletOverview? overview,  bool overviewLoading,  String? overviewError,  List<ApplicationRow> bills,  bool billsLoading,  String? billsError,  List<Transaction> receipts,  bool receiptsLoading,  String? receiptsError,  PagedRows<WalletEntry>? ledger,  bool ledgerLoading,  String? ledgerError,  bool showLedger,  int ledgerPage,  List<PaymentMethod> methods,  bool methodsLoading,  String? methodsError,  bool topUpPending,  String? topUpError,  bool topUpSucceeded,  bool payPending,  PaymentFailure? payFailure,  PaymentResult? payResult)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _WalletState() when $default != null:
return $default(_that.isAuthenticated,_that.overview,_that.overviewLoading,_that.overviewError,_that.bills,_that.billsLoading,_that.billsError,_that.receipts,_that.receiptsLoading,_that.receiptsError,_that.ledger,_that.ledgerLoading,_that.ledgerError,_that.showLedger,_that.ledgerPage,_that.methods,_that.methodsLoading,_that.methodsError,_that.topUpPending,_that.topUpError,_that.topUpSucceeded,_that.payPending,_that.payFailure,_that.payResult);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( bool isAuthenticated,  WalletOverview? overview,  bool overviewLoading,  String? overviewError,  List<ApplicationRow> bills,  bool billsLoading,  String? billsError,  List<Transaction> receipts,  bool receiptsLoading,  String? receiptsError,  PagedRows<WalletEntry>? ledger,  bool ledgerLoading,  String? ledgerError,  bool showLedger,  int ledgerPage,  List<PaymentMethod> methods,  bool methodsLoading,  String? methodsError,  bool topUpPending,  String? topUpError,  bool topUpSucceeded,  bool payPending,  PaymentFailure? payFailure,  PaymentResult? payResult)  $default,) {final _that = this;
switch (_that) {
case _WalletState():
return $default(_that.isAuthenticated,_that.overview,_that.overviewLoading,_that.overviewError,_that.bills,_that.billsLoading,_that.billsError,_that.receipts,_that.receiptsLoading,_that.receiptsError,_that.ledger,_that.ledgerLoading,_that.ledgerError,_that.showLedger,_that.ledgerPage,_that.methods,_that.methodsLoading,_that.methodsError,_that.topUpPending,_that.topUpError,_that.topUpSucceeded,_that.payPending,_that.payFailure,_that.payResult);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( bool isAuthenticated,  WalletOverview? overview,  bool overviewLoading,  String? overviewError,  List<ApplicationRow> bills,  bool billsLoading,  String? billsError,  List<Transaction> receipts,  bool receiptsLoading,  String? receiptsError,  PagedRows<WalletEntry>? ledger,  bool ledgerLoading,  String? ledgerError,  bool showLedger,  int ledgerPage,  List<PaymentMethod> methods,  bool methodsLoading,  String? methodsError,  bool topUpPending,  String? topUpError,  bool topUpSucceeded,  bool payPending,  PaymentFailure? payFailure,  PaymentResult? payResult)?  $default,) {final _that = this;
switch (_that) {
case _WalletState() when $default != null:
return $default(_that.isAuthenticated,_that.overview,_that.overviewLoading,_that.overviewError,_that.bills,_that.billsLoading,_that.billsError,_that.receipts,_that.receiptsLoading,_that.receiptsError,_that.ledger,_that.ledgerLoading,_that.ledgerError,_that.showLedger,_that.ledgerPage,_that.methods,_that.methodsLoading,_that.methodsError,_that.topUpPending,_that.topUpError,_that.topUpSucceeded,_that.payPending,_that.payFailure,_that.payResult);case _:
  return null;

}
}

}

/// @nodoc


class _WalletState extends WalletState {
  const _WalletState({this.isAuthenticated = false, this.overview, this.overviewLoading = false, this.overviewError, final  List<ApplicationRow> bills = const <ApplicationRow>[], this.billsLoading = false, this.billsError, final  List<Transaction> receipts = const <Transaction>[], this.receiptsLoading = false, this.receiptsError, this.ledger, this.ledgerLoading = false, this.ledgerError, this.showLedger = false, this.ledgerPage = 1, final  List<PaymentMethod> methods = const <PaymentMethod>[], this.methodsLoading = false, this.methodsError, this.topUpPending = false, this.topUpError, this.topUpSucceeded = false, this.payPending = false, this.payFailure, this.payResult}): _bills = bills,_receipts = receipts,_methods = methods,super._();
  

@override@JsonKey() final  bool isAuthenticated;
// ── overview: `/me/wallet` ───────────────────────────────────────────────
@override final  WalletOverview? overview;
@override@JsonKey() final  bool overviewLoading;
@override final  String? overviewError;
// ── bills: `/applications/?page=1&per_page=50` (B6b) ─────────────────────
/// Already filtered to `payment_state === "pending" && fee_lak > 0` by
/// [ListPendingBills] — the source filters at `:123-125`, immediately after
/// the query and before anything reads it, so an unfiltered list never
/// exists on the web either.
 final  List<ApplicationRow> _bills;
// ── bills: `/applications/?page=1&per_page=50` (B6b) ─────────────────────
/// Already filtered to `payment_state === "pending" && fee_lak > 0` by
/// [ListPendingBills] — the source filters at `:123-125`, immediately after
/// the query and before anything reads it, so an unfiltered list never
/// exists on the web either.
@override@JsonKey() List<ApplicationRow> get bills {
  if (_bills is EqualUnmodifiableListView) return _bills;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_bills);
}

@override@JsonKey() final  bool billsLoading;
@override final  String? billsError;
// ── receipts: `/me/transactions` ─────────────────────────────────────────
 final  List<Transaction> _receipts;
// ── receipts: `/me/transactions` ─────────────────────────────────────────
@override@JsonKey() List<Transaction> get receipts {
  if (_receipts is EqualUnmodifiableListView) return _receipts;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_receipts);
}

@override@JsonKey() final  bool receiptsLoading;
@override final  String? receiptsError;
// ── ledger: `/me/wallet/entries`, enabled only while [showLedger] ────────
/// `null` until the first page has arrived. Distinguished from an empty
/// page because the *first frame* of the ledger deliberately renders
/// `overview.recentEntries` instead (§ 6.8(3)) — a distinction an empty
/// `PagedRows` could not carry.
@override final  PagedRows<WalletEntry>? ledger;
@override@JsonKey() final  bool ledgerLoading;
@override final  String? ledgerError;
@override@JsonKey() final  bool showLedger;
@override@JsonKey() final  int ledgerPage;
// ── methods: `/payment-methods`, fetched by the sheet ────────────────────
 final  List<PaymentMethod> _methods;
// ── methods: `/payment-methods`, fetched by the sheet ────────────────────
@override@JsonKey() List<PaymentMethod> get methods {
  if (_methods is EqualUnmodifiableListView) return _methods;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_methods);
}

@override@JsonKey() final  bool methodsLoading;
@override final  String? methodsError;
// ── the top-up mutation ──────────────────────────────────────────────────
@override@JsonKey() final  bool topUpPending;
@override final  String? topUpError;
/// Raised for one state emission after a successful credit, so the page can
/// close the sheet. `onDone` (`:559-562`) is a callback on the web; a BLoC
/// has no callbacks, so it is a flag the listener consumes.
@override@JsonKey() final  bool topUpSucceeded;
// ── the pay mutation (B6b) ───────────────────────────────────────────────
/// `charge.pending` — `PaymentSection.tsx:456`.
@override@JsonKey() final  bool payPending;
/// `charge.error` — the **whole** failure, not its message.
///
/// A `String?` here (as the four read regions carry) would throw away
/// `.code`, and `.code` is what splits the render in two: an amber
/// insufficient-funds panel with a top-up button versus a red line
/// (`:219`, `:352-385`). [payInsufficient] is the split and it is the only
/// reason this field is not a message.
@override final  PaymentFailure? payFailure;
/// `charge.data` — absent until a charge returns. **There is no
/// "succeeded" flag beside it**, unlike [topUpSucceeded]: the source does
/// not close the pay sheet on success, it *re-renders it* into a settled
/// line or an instruction panel (`:439-450`), and the sheet stays open
/// until the citizen dismisses it. `PaymentResult.isSettled` is what the
/// terminal branch reads.
@override final  PaymentResult? payResult;

/// Create a copy of WalletState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$WalletStateCopyWith<_WalletState> get copyWith => __$WalletStateCopyWithImpl<_WalletState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _WalletState&&(identical(other.isAuthenticated, isAuthenticated) || other.isAuthenticated == isAuthenticated)&&(identical(other.overview, overview) || other.overview == overview)&&(identical(other.overviewLoading, overviewLoading) || other.overviewLoading == overviewLoading)&&(identical(other.overviewError, overviewError) || other.overviewError == overviewError)&&const DeepCollectionEquality().equals(other._bills, _bills)&&(identical(other.billsLoading, billsLoading) || other.billsLoading == billsLoading)&&(identical(other.billsError, billsError) || other.billsError == billsError)&&const DeepCollectionEquality().equals(other._receipts, _receipts)&&(identical(other.receiptsLoading, receiptsLoading) || other.receiptsLoading == receiptsLoading)&&(identical(other.receiptsError, receiptsError) || other.receiptsError == receiptsError)&&(identical(other.ledger, ledger) || other.ledger == ledger)&&(identical(other.ledgerLoading, ledgerLoading) || other.ledgerLoading == ledgerLoading)&&(identical(other.ledgerError, ledgerError) || other.ledgerError == ledgerError)&&(identical(other.showLedger, showLedger) || other.showLedger == showLedger)&&(identical(other.ledgerPage, ledgerPage) || other.ledgerPage == ledgerPage)&&const DeepCollectionEquality().equals(other._methods, _methods)&&(identical(other.methodsLoading, methodsLoading) || other.methodsLoading == methodsLoading)&&(identical(other.methodsError, methodsError) || other.methodsError == methodsError)&&(identical(other.topUpPending, topUpPending) || other.topUpPending == topUpPending)&&(identical(other.topUpError, topUpError) || other.topUpError == topUpError)&&(identical(other.topUpSucceeded, topUpSucceeded) || other.topUpSucceeded == topUpSucceeded)&&(identical(other.payPending, payPending) || other.payPending == payPending)&&(identical(other.payFailure, payFailure) || other.payFailure == payFailure)&&(identical(other.payResult, payResult) || other.payResult == payResult));
}


@override
int get hashCode => Object.hashAll([runtimeType,isAuthenticated,overview,overviewLoading,overviewError,const DeepCollectionEquality().hash(_bills),billsLoading,billsError,const DeepCollectionEquality().hash(_receipts),receiptsLoading,receiptsError,ledger,ledgerLoading,ledgerError,showLedger,ledgerPage,const DeepCollectionEquality().hash(_methods),methodsLoading,methodsError,topUpPending,topUpError,topUpSucceeded,payPending,payFailure,payResult]);

@override
String toString() {
  return 'WalletState(isAuthenticated: $isAuthenticated, overview: $overview, overviewLoading: $overviewLoading, overviewError: $overviewError, bills: $bills, billsLoading: $billsLoading, billsError: $billsError, receipts: $receipts, receiptsLoading: $receiptsLoading, receiptsError: $receiptsError, ledger: $ledger, ledgerLoading: $ledgerLoading, ledgerError: $ledgerError, showLedger: $showLedger, ledgerPage: $ledgerPage, methods: $methods, methodsLoading: $methodsLoading, methodsError: $methodsError, topUpPending: $topUpPending, topUpError: $topUpError, topUpSucceeded: $topUpSucceeded, payPending: $payPending, payFailure: $payFailure, payResult: $payResult)';
}


}

/// @nodoc
abstract mixin class _$WalletStateCopyWith<$Res> implements $WalletStateCopyWith<$Res> {
  factory _$WalletStateCopyWith(_WalletState value, $Res Function(_WalletState) _then) = __$WalletStateCopyWithImpl;
@override @useResult
$Res call({
 bool isAuthenticated, WalletOverview? overview, bool overviewLoading, String? overviewError, List<ApplicationRow> bills, bool billsLoading, String? billsError, List<Transaction> receipts, bool receiptsLoading, String? receiptsError, PagedRows<WalletEntry>? ledger, bool ledgerLoading, String? ledgerError, bool showLedger, int ledgerPage, List<PaymentMethod> methods, bool methodsLoading, String? methodsError, bool topUpPending, String? topUpError, bool topUpSucceeded, bool payPending, PaymentFailure? payFailure, PaymentResult? payResult
});


@override $WalletOverviewCopyWith<$Res>? get overview;@override $PaymentResultCopyWith<$Res>? get payResult;

}
/// @nodoc
class __$WalletStateCopyWithImpl<$Res>
    implements _$WalletStateCopyWith<$Res> {
  __$WalletStateCopyWithImpl(this._self, this._then);

  final _WalletState _self;
  final $Res Function(_WalletState) _then;

/// Create a copy of WalletState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? isAuthenticated = null,Object? overview = freezed,Object? overviewLoading = null,Object? overviewError = freezed,Object? bills = null,Object? billsLoading = null,Object? billsError = freezed,Object? receipts = null,Object? receiptsLoading = null,Object? receiptsError = freezed,Object? ledger = freezed,Object? ledgerLoading = null,Object? ledgerError = freezed,Object? showLedger = null,Object? ledgerPage = null,Object? methods = null,Object? methodsLoading = null,Object? methodsError = freezed,Object? topUpPending = null,Object? topUpError = freezed,Object? topUpSucceeded = null,Object? payPending = null,Object? payFailure = freezed,Object? payResult = freezed,}) {
  return _then(_WalletState(
isAuthenticated: null == isAuthenticated ? _self.isAuthenticated : isAuthenticated // ignore: cast_nullable_to_non_nullable
as bool,overview: freezed == overview ? _self.overview : overview // ignore: cast_nullable_to_non_nullable
as WalletOverview?,overviewLoading: null == overviewLoading ? _self.overviewLoading : overviewLoading // ignore: cast_nullable_to_non_nullable
as bool,overviewError: freezed == overviewError ? _self.overviewError : overviewError // ignore: cast_nullable_to_non_nullable
as String?,bills: null == bills ? _self._bills : bills // ignore: cast_nullable_to_non_nullable
as List<ApplicationRow>,billsLoading: null == billsLoading ? _self.billsLoading : billsLoading // ignore: cast_nullable_to_non_nullable
as bool,billsError: freezed == billsError ? _self.billsError : billsError // ignore: cast_nullable_to_non_nullable
as String?,receipts: null == receipts ? _self._receipts : receipts // ignore: cast_nullable_to_non_nullable
as List<Transaction>,receiptsLoading: null == receiptsLoading ? _self.receiptsLoading : receiptsLoading // ignore: cast_nullable_to_non_nullable
as bool,receiptsError: freezed == receiptsError ? _self.receiptsError : receiptsError // ignore: cast_nullable_to_non_nullable
as String?,ledger: freezed == ledger ? _self.ledger : ledger // ignore: cast_nullable_to_non_nullable
as PagedRows<WalletEntry>?,ledgerLoading: null == ledgerLoading ? _self.ledgerLoading : ledgerLoading // ignore: cast_nullable_to_non_nullable
as bool,ledgerError: freezed == ledgerError ? _self.ledgerError : ledgerError // ignore: cast_nullable_to_non_nullable
as String?,showLedger: null == showLedger ? _self.showLedger : showLedger // ignore: cast_nullable_to_non_nullable
as bool,ledgerPage: null == ledgerPage ? _self.ledgerPage : ledgerPage // ignore: cast_nullable_to_non_nullable
as int,methods: null == methods ? _self._methods : methods // ignore: cast_nullable_to_non_nullable
as List<PaymentMethod>,methodsLoading: null == methodsLoading ? _self.methodsLoading : methodsLoading // ignore: cast_nullable_to_non_nullable
as bool,methodsError: freezed == methodsError ? _self.methodsError : methodsError // ignore: cast_nullable_to_non_nullable
as String?,topUpPending: null == topUpPending ? _self.topUpPending : topUpPending // ignore: cast_nullable_to_non_nullable
as bool,topUpError: freezed == topUpError ? _self.topUpError : topUpError // ignore: cast_nullable_to_non_nullable
as String?,topUpSucceeded: null == topUpSucceeded ? _self.topUpSucceeded : topUpSucceeded // ignore: cast_nullable_to_non_nullable
as bool,payPending: null == payPending ? _self.payPending : payPending // ignore: cast_nullable_to_non_nullable
as bool,payFailure: freezed == payFailure ? _self.payFailure : payFailure // ignore: cast_nullable_to_non_nullable
as PaymentFailure?,payResult: freezed == payResult ? _self.payResult : payResult // ignore: cast_nullable_to_non_nullable
as PaymentResult?,
  ));
}

/// Create a copy of WalletState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$WalletOverviewCopyWith<$Res>? get overview {
    if (_self.overview == null) {
    return null;
  }

  return $WalletOverviewCopyWith<$Res>(_self.overview!, (value) {
    return _then(_self.copyWith(overview: value));
  });
}/// Create a copy of WalletState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PaymentResultCopyWith<$Res>? get payResult {
    if (_self.payResult == null) {
    return null;
  }

  return $PaymentResultCopyWith<$Res>(_self.payResult!, (value) {
    return _then(_self.copyWith(payResult: value));
  });
}
}

// dart format on
