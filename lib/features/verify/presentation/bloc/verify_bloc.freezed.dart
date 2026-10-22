// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'verify_bloc.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$VerifyState {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is VerifyState);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'VerifyState()';
}


}

/// @nodoc
class $VerifyStateCopyWith<$Res>  {
$VerifyStateCopyWith(VerifyState _, $Res Function(VerifyState) __);
}


/// Adds pattern-matching-related methods to [VerifyState].
extension VerifyStatePatterns on VerifyState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( VerifyInitial value)?  initial,TResult Function( VerifyLoading value)?  loading,TResult Function( VerifyResult value)?  result,TResult Function( VerifyTooManyRequests value)?  tooManyRequests,TResult Function( VerifyFailure value)?  failure,required TResult orElse(),}){
final _that = this;
switch (_that) {
case VerifyInitial() when initial != null:
return initial(_that);case VerifyLoading() when loading != null:
return loading(_that);case VerifyResult() when result != null:
return result(_that);case VerifyTooManyRequests() when tooManyRequests != null:
return tooManyRequests(_that);case VerifyFailure() when failure != null:
return failure(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( VerifyInitial value)  initial,required TResult Function( VerifyLoading value)  loading,required TResult Function( VerifyResult value)  result,required TResult Function( VerifyTooManyRequests value)  tooManyRequests,required TResult Function( VerifyFailure value)  failure,}){
final _that = this;
switch (_that) {
case VerifyInitial():
return initial(_that);case VerifyLoading():
return loading(_that);case VerifyResult():
return result(_that);case VerifyTooManyRequests():
return tooManyRequests(_that);case VerifyFailure():
return failure(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( VerifyInitial value)?  initial,TResult? Function( VerifyLoading value)?  loading,TResult? Function( VerifyResult value)?  result,TResult? Function( VerifyTooManyRequests value)?  tooManyRequests,TResult? Function( VerifyFailure value)?  failure,}){
final _that = this;
switch (_that) {
case VerifyInitial() when initial != null:
return initial(_that);case VerifyLoading() when loading != null:
return loading(_that);case VerifyResult() when result != null:
return result(_that);case VerifyTooManyRequests() when tooManyRequests != null:
return tooManyRequests(_that);case VerifyFailure() when failure != null:
return failure(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  initial,TResult Function()?  loading,TResult Function( VerificationResult result)?  result,TResult Function()?  tooManyRequests,TResult Function( String message)?  failure,required TResult orElse(),}) {final _that = this;
switch (_that) {
case VerifyInitial() when initial != null:
return initial();case VerifyLoading() when loading != null:
return loading();case VerifyResult() when result != null:
return result(_that.result);case VerifyTooManyRequests() when tooManyRequests != null:
return tooManyRequests();case VerifyFailure() when failure != null:
return failure(_that.message);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  initial,required TResult Function()  loading,required TResult Function( VerificationResult result)  result,required TResult Function()  tooManyRequests,required TResult Function( String message)  failure,}) {final _that = this;
switch (_that) {
case VerifyInitial():
return initial();case VerifyLoading():
return loading();case VerifyResult():
return result(_that.result);case VerifyTooManyRequests():
return tooManyRequests();case VerifyFailure():
return failure(_that.message);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  initial,TResult? Function()?  loading,TResult? Function( VerificationResult result)?  result,TResult? Function()?  tooManyRequests,TResult? Function( String message)?  failure,}) {final _that = this;
switch (_that) {
case VerifyInitial() when initial != null:
return initial();case VerifyLoading() when loading != null:
return loading();case VerifyResult() when result != null:
return result(_that.result);case VerifyTooManyRequests() when tooManyRequests != null:
return tooManyRequests();case VerifyFailure() when failure != null:
return failure(_that.message);case _:
  return null;

}
}

}

/// @nodoc


class VerifyInitial extends VerifyState {
  const VerifyInitial(): super._();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is VerifyInitial);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'VerifyState.initial()';
}


}




/// @nodoc


class VerifyLoading extends VerifyState {
  const VerifyLoading(): super._();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is VerifyLoading);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'VerifyState.loading()';
}


}




/// @nodoc


class VerifyResult extends VerifyState {
  const VerifyResult(this.result): super._();
  

 final  VerificationResult result;

/// Create a copy of VerifyState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$VerifyResultCopyWith<VerifyResult> get copyWith => _$VerifyResultCopyWithImpl<VerifyResult>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is VerifyResult&&(identical(other.result, result) || other.result == result));
}


@override
int get hashCode => Object.hash(runtimeType,result);

@override
String toString() {
  return 'VerifyState.result(result: $result)';
}


}

/// @nodoc
abstract mixin class $VerifyResultCopyWith<$Res> implements $VerifyStateCopyWith<$Res> {
  factory $VerifyResultCopyWith(VerifyResult value, $Res Function(VerifyResult) _then) = _$VerifyResultCopyWithImpl;
@useResult
$Res call({
 VerificationResult result
});


$VerificationResultCopyWith<$Res> get result;

}
/// @nodoc
class _$VerifyResultCopyWithImpl<$Res>
    implements $VerifyResultCopyWith<$Res> {
  _$VerifyResultCopyWithImpl(this._self, this._then);

  final VerifyResult _self;
  final $Res Function(VerifyResult) _then;

/// Create a copy of VerifyState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? result = null,}) {
  return _then(VerifyResult(
null == result ? _self.result : result // ignore: cast_nullable_to_non_nullable
as VerificationResult,
  ));
}

/// Create a copy of VerifyState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$VerificationResultCopyWith<$Res> get result {
  
  return $VerificationResultCopyWith<$Res>(_self.result, (value) {
    return _then(_self.copyWith(result: value));
  });
}
}

/// @nodoc


class VerifyTooManyRequests extends VerifyState {
  const VerifyTooManyRequests(): super._();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is VerifyTooManyRequests);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'VerifyState.tooManyRequests()';
}


}




/// @nodoc


class VerifyFailure extends VerifyState {
  const VerifyFailure(this.message): super._();
  

 final  String message;

/// Create a copy of VerifyState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$VerifyFailureCopyWith<VerifyFailure> get copyWith => _$VerifyFailureCopyWithImpl<VerifyFailure>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is VerifyFailure&&(identical(other.message, message) || other.message == message));
}


@override
int get hashCode => Object.hash(runtimeType,message);

@override
String toString() {
  return 'VerifyState.failure(message: $message)';
}


}

/// @nodoc
abstract mixin class $VerifyFailureCopyWith<$Res> implements $VerifyStateCopyWith<$Res> {
  factory $VerifyFailureCopyWith(VerifyFailure value, $Res Function(VerifyFailure) _then) = _$VerifyFailureCopyWithImpl;
@useResult
$Res call({
 String message
});




}
/// @nodoc
class _$VerifyFailureCopyWithImpl<$Res>
    implements $VerifyFailureCopyWith<$Res> {
  _$VerifyFailureCopyWithImpl(this._self, this._then);

  final VerifyFailure _self;
  final $Res Function(VerifyFailure) _then;

/// Create a copy of VerifyState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? message = null,}) {
  return _then(VerifyFailure(
null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
