// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'service_bloc.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$ServiceState {

 CatalogueStatus get catalogueStatus; List<ServiceCategory> get categories;/// The **unfiltered** 43 rows. Feeds [counts] and nothing else.
 List<Service> get allServices; CatalogueErrorSource? get catalogueErrorSource; ServiceListStatus get listStatus;/// The rows the grid draws — filtered by the API, in server order.
 List<Service> get services;/// The selected category's code, or null for the category grid.
 String? get activeCategory;/// Exactly what is in the text field, untrimmed.
 String get searchQuery;/// The trimmed query the last request used. Lags [searchQuery] by up to
/// [kSearchDebounce].
 String get debouncedQuery;
/// Create a copy of ServiceState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ServiceStateCopyWith<ServiceState> get copyWith => _$ServiceStateCopyWithImpl<ServiceState>(this as ServiceState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ServiceState&&(identical(other.catalogueStatus, catalogueStatus) || other.catalogueStatus == catalogueStatus)&&const DeepCollectionEquality().equals(other.categories, categories)&&const DeepCollectionEquality().equals(other.allServices, allServices)&&(identical(other.catalogueErrorSource, catalogueErrorSource) || other.catalogueErrorSource == catalogueErrorSource)&&(identical(other.listStatus, listStatus) || other.listStatus == listStatus)&&const DeepCollectionEquality().equals(other.services, services)&&(identical(other.activeCategory, activeCategory) || other.activeCategory == activeCategory)&&(identical(other.searchQuery, searchQuery) || other.searchQuery == searchQuery)&&(identical(other.debouncedQuery, debouncedQuery) || other.debouncedQuery == debouncedQuery));
}


@override
int get hashCode => Object.hash(runtimeType,catalogueStatus,const DeepCollectionEquality().hash(categories),const DeepCollectionEquality().hash(allServices),catalogueErrorSource,listStatus,const DeepCollectionEquality().hash(services),activeCategory,searchQuery,debouncedQuery);

@override
String toString() {
  return 'ServiceState(catalogueStatus: $catalogueStatus, categories: $categories, allServices: $allServices, catalogueErrorSource: $catalogueErrorSource, listStatus: $listStatus, services: $services, activeCategory: $activeCategory, searchQuery: $searchQuery, debouncedQuery: $debouncedQuery)';
}


}

/// @nodoc
abstract mixin class $ServiceStateCopyWith<$Res>  {
  factory $ServiceStateCopyWith(ServiceState value, $Res Function(ServiceState) _then) = _$ServiceStateCopyWithImpl;
@useResult
$Res call({
 CatalogueStatus catalogueStatus, List<ServiceCategory> categories, List<Service> allServices, CatalogueErrorSource? catalogueErrorSource, ServiceListStatus listStatus, List<Service> services, String? activeCategory, String searchQuery, String debouncedQuery
});




}
/// @nodoc
class _$ServiceStateCopyWithImpl<$Res>
    implements $ServiceStateCopyWith<$Res> {
  _$ServiceStateCopyWithImpl(this._self, this._then);

  final ServiceState _self;
  final $Res Function(ServiceState) _then;

/// Create a copy of ServiceState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? catalogueStatus = null,Object? categories = null,Object? allServices = null,Object? catalogueErrorSource = freezed,Object? listStatus = null,Object? services = null,Object? activeCategory = freezed,Object? searchQuery = null,Object? debouncedQuery = null,}) {
  return _then(_self.copyWith(
catalogueStatus: null == catalogueStatus ? _self.catalogueStatus : catalogueStatus // ignore: cast_nullable_to_non_nullable
as CatalogueStatus,categories: null == categories ? _self.categories : categories // ignore: cast_nullable_to_non_nullable
as List<ServiceCategory>,allServices: null == allServices ? _self.allServices : allServices // ignore: cast_nullable_to_non_nullable
as List<Service>,catalogueErrorSource: freezed == catalogueErrorSource ? _self.catalogueErrorSource : catalogueErrorSource // ignore: cast_nullable_to_non_nullable
as CatalogueErrorSource?,listStatus: null == listStatus ? _self.listStatus : listStatus // ignore: cast_nullable_to_non_nullable
as ServiceListStatus,services: null == services ? _self.services : services // ignore: cast_nullable_to_non_nullable
as List<Service>,activeCategory: freezed == activeCategory ? _self.activeCategory : activeCategory // ignore: cast_nullable_to_non_nullable
as String?,searchQuery: null == searchQuery ? _self.searchQuery : searchQuery // ignore: cast_nullable_to_non_nullable
as String,debouncedQuery: null == debouncedQuery ? _self.debouncedQuery : debouncedQuery // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [ServiceState].
extension ServiceStatePatterns on ServiceState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ServiceState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ServiceState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ServiceState value)  $default,){
final _that = this;
switch (_that) {
case _ServiceState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ServiceState value)?  $default,){
final _that = this;
switch (_that) {
case _ServiceState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( CatalogueStatus catalogueStatus,  List<ServiceCategory> categories,  List<Service> allServices,  CatalogueErrorSource? catalogueErrorSource,  ServiceListStatus listStatus,  List<Service> services,  String? activeCategory,  String searchQuery,  String debouncedQuery)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ServiceState() when $default != null:
return $default(_that.catalogueStatus,_that.categories,_that.allServices,_that.catalogueErrorSource,_that.listStatus,_that.services,_that.activeCategory,_that.searchQuery,_that.debouncedQuery);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( CatalogueStatus catalogueStatus,  List<ServiceCategory> categories,  List<Service> allServices,  CatalogueErrorSource? catalogueErrorSource,  ServiceListStatus listStatus,  List<Service> services,  String? activeCategory,  String searchQuery,  String debouncedQuery)  $default,) {final _that = this;
switch (_that) {
case _ServiceState():
return $default(_that.catalogueStatus,_that.categories,_that.allServices,_that.catalogueErrorSource,_that.listStatus,_that.services,_that.activeCategory,_that.searchQuery,_that.debouncedQuery);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( CatalogueStatus catalogueStatus,  List<ServiceCategory> categories,  List<Service> allServices,  CatalogueErrorSource? catalogueErrorSource,  ServiceListStatus listStatus,  List<Service> services,  String? activeCategory,  String searchQuery,  String debouncedQuery)?  $default,) {final _that = this;
switch (_that) {
case _ServiceState() when $default != null:
return $default(_that.catalogueStatus,_that.categories,_that.allServices,_that.catalogueErrorSource,_that.listStatus,_that.services,_that.activeCategory,_that.searchQuery,_that.debouncedQuery);case _:
  return null;

}
}

}

/// @nodoc


class _ServiceState extends ServiceState {
  const _ServiceState({this.catalogueStatus = CatalogueStatus.initial, final  List<ServiceCategory> categories = const <ServiceCategory>[], final  List<Service> allServices = const <Service>[], this.catalogueErrorSource, this.listStatus = ServiceListStatus.initial, final  List<Service> services = const <Service>[], this.activeCategory, this.searchQuery = '', this.debouncedQuery = ''}): _categories = categories,_allServices = allServices,_services = services,super._();
  

@override@JsonKey() final  CatalogueStatus catalogueStatus;
 final  List<ServiceCategory> _categories;
@override@JsonKey() List<ServiceCategory> get categories {
  if (_categories is EqualUnmodifiableListView) return _categories;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_categories);
}

/// The **unfiltered** 43 rows. Feeds [counts] and nothing else.
 final  List<Service> _allServices;
/// The **unfiltered** 43 rows. Feeds [counts] and nothing else.
@override@JsonKey() List<Service> get allServices {
  if (_allServices is EqualUnmodifiableListView) return _allServices;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_allServices);
}

@override final  CatalogueErrorSource? catalogueErrorSource;
@override@JsonKey() final  ServiceListStatus listStatus;
/// The rows the grid draws — filtered by the API, in server order.
 final  List<Service> _services;
/// The rows the grid draws — filtered by the API, in server order.
@override@JsonKey() List<Service> get services {
  if (_services is EqualUnmodifiableListView) return _services;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_services);
}

/// The selected category's code, or null for the category grid.
@override final  String? activeCategory;
/// Exactly what is in the text field, untrimmed.
@override@JsonKey() final  String searchQuery;
/// The trimmed query the last request used. Lags [searchQuery] by up to
/// [kSearchDebounce].
@override@JsonKey() final  String debouncedQuery;

/// Create a copy of ServiceState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ServiceStateCopyWith<_ServiceState> get copyWith => __$ServiceStateCopyWithImpl<_ServiceState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ServiceState&&(identical(other.catalogueStatus, catalogueStatus) || other.catalogueStatus == catalogueStatus)&&const DeepCollectionEquality().equals(other._categories, _categories)&&const DeepCollectionEquality().equals(other._allServices, _allServices)&&(identical(other.catalogueErrorSource, catalogueErrorSource) || other.catalogueErrorSource == catalogueErrorSource)&&(identical(other.listStatus, listStatus) || other.listStatus == listStatus)&&const DeepCollectionEquality().equals(other._services, _services)&&(identical(other.activeCategory, activeCategory) || other.activeCategory == activeCategory)&&(identical(other.searchQuery, searchQuery) || other.searchQuery == searchQuery)&&(identical(other.debouncedQuery, debouncedQuery) || other.debouncedQuery == debouncedQuery));
}


@override
int get hashCode => Object.hash(runtimeType,catalogueStatus,const DeepCollectionEquality().hash(_categories),const DeepCollectionEquality().hash(_allServices),catalogueErrorSource,listStatus,const DeepCollectionEquality().hash(_services),activeCategory,searchQuery,debouncedQuery);

@override
String toString() {
  return 'ServiceState(catalogueStatus: $catalogueStatus, categories: $categories, allServices: $allServices, catalogueErrorSource: $catalogueErrorSource, listStatus: $listStatus, services: $services, activeCategory: $activeCategory, searchQuery: $searchQuery, debouncedQuery: $debouncedQuery)';
}


}

/// @nodoc
abstract mixin class _$ServiceStateCopyWith<$Res> implements $ServiceStateCopyWith<$Res> {
  factory _$ServiceStateCopyWith(_ServiceState value, $Res Function(_ServiceState) _then) = __$ServiceStateCopyWithImpl;
@override @useResult
$Res call({
 CatalogueStatus catalogueStatus, List<ServiceCategory> categories, List<Service> allServices, CatalogueErrorSource? catalogueErrorSource, ServiceListStatus listStatus, List<Service> services, String? activeCategory, String searchQuery, String debouncedQuery
});




}
/// @nodoc
class __$ServiceStateCopyWithImpl<$Res>
    implements _$ServiceStateCopyWith<$Res> {
  __$ServiceStateCopyWithImpl(this._self, this._then);

  final _ServiceState _self;
  final $Res Function(_ServiceState) _then;

/// Create a copy of ServiceState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? catalogueStatus = null,Object? categories = null,Object? allServices = null,Object? catalogueErrorSource = freezed,Object? listStatus = null,Object? services = null,Object? activeCategory = freezed,Object? searchQuery = null,Object? debouncedQuery = null,}) {
  return _then(_ServiceState(
catalogueStatus: null == catalogueStatus ? _self.catalogueStatus : catalogueStatus // ignore: cast_nullable_to_non_nullable
as CatalogueStatus,categories: null == categories ? _self._categories : categories // ignore: cast_nullable_to_non_nullable
as List<ServiceCategory>,allServices: null == allServices ? _self._allServices : allServices // ignore: cast_nullable_to_non_nullable
as List<Service>,catalogueErrorSource: freezed == catalogueErrorSource ? _self.catalogueErrorSource : catalogueErrorSource // ignore: cast_nullable_to_non_nullable
as CatalogueErrorSource?,listStatus: null == listStatus ? _self.listStatus : listStatus // ignore: cast_nullable_to_non_nullable
as ServiceListStatus,services: null == services ? _self._services : services // ignore: cast_nullable_to_non_nullable
as List<Service>,activeCategory: freezed == activeCategory ? _self.activeCategory : activeCategory // ignore: cast_nullable_to_non_nullable
as String?,searchQuery: null == searchQuery ? _self.searchQuery : searchQuery // ignore: cast_nullable_to_non_nullable
as String,debouncedQuery: null == debouncedQuery ? _self.debouncedQuery : debouncedQuery // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
