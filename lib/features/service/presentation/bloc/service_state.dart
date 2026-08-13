part of 'service_bloc.dart';

/// The catalogue pair's lifecycle — `/service-categories` + unfiltered
/// `/services`, which the page always shows and retries as one.
enum CatalogueStatus { initial, loading, success, failure }

/// **Which** of the pair failed. The source shows a different sentence for
/// each (`COPY.categoriesError` vs `COPY.servicesError`,
/// `ServicePage.tsx:426-428`), so collapsing this would lose a string Tier 1
/// compares.
enum CatalogueErrorSource { categories, services }

/// The filtered list's lifecycle — `listQuery`, live only when the page is not
/// in category view.
enum ServiceListStatus { initial, loading, success, failure }

@freezed
abstract class ServiceState with _$ServiceState {
  const factory ServiceState({
    @Default(CatalogueStatus.initial) CatalogueStatus catalogueStatus,
    @Default(<ServiceCategory>[]) List<ServiceCategory> categories,

    /// The **unfiltered** 43 rows. Feeds [counts] and nothing else.
    @Default(<Service>[]) List<Service> allServices,
    CatalogueErrorSource? catalogueErrorSource,
    @Default(ServiceListStatus.initial) ServiceListStatus listStatus,

    /// The rows the grid draws — filtered by the API, in server order.
    @Default(<Service>[]) List<Service> services,

    /// The selected category's code, or null for the category grid.
    String? activeCategory,

    /// Exactly what is in the text field, untrimmed.
    @Default('') String searchQuery,

    /// The trimmed query the last request used. Lags [searchQuery] by up to
    /// [kSearchDebounce].
    @Default('') String debouncedQuery,
  }) = _ServiceState;

  const ServiceState._();

  /// `const query = searchQuery.trim()` — `ServicePage.tsx:291`.
  String get query => searchQuery.trim();

  /// `!activeCategory && query === ""` — `ServicePage.tsx:295`.
  ///
  /// The whole page hinges on this one boolean: true renders the category grid
  /// (and `listQuery` is disabled), false renders the service cards.
  bool get showCategoryView => activeCategory == null && query.isEmpty;

  /// `query !== debouncedQuery` — `ServicePage.tsx:293`. True inside the
  /// debounce window.
  bool get typing => query != debouncedQuery;

  /// `listQuery.loading || listQuery.refreshing || typing`
  /// (`ServicePage.tsx:350`). The `typing` term is the load-bearing one: it is
  /// what stops the grid showing the previous search's rows while the next
  /// request is still 300 ms away.
  ///
  /// `initial` counts as loading. The list view is only ever reached by
  /// selecting a category or typing, both of which dispatch a fetch — so a
  /// list that is `initial` while the view is visible is a frame in flight,
  /// not an empty result, and rendering "No services available yet" for it
  /// would be the § 6.6 failure mode of showing an empty list where a spinner
  /// belongs.
  bool get listLoading =>
      listStatus == ServiceListStatus.loading ||
      listStatus == ServiceListStatus.initial ||
      typing;

  /// Services per category code, over the **unfiltered** catalogue —
  /// `ServicePage.tsx:331-337`.
  Map<String, int> get counts {
    final Map<String, int> totals = <String, int>{};
    for (final Service s in allServices) {
      totals[s.categoryCode] = (totals[s.categoryCode] ?? 0) + 1;
    }
    return totals;
  }

  /// The category currently drilled into, or null.
  ///
  /// `ServicePage.tsx:344-346` falls back to the *static* `CATEGORIES` table
  /// when the API list has no match. That fallback cannot fire here: the only
  /// way to set [activeCategory] is to tap a chip built from [categories], so
  /// a code that is not in [categories] is unreachable. Porting the fallback
  /// would be porting a branch with no input.
  ServiceCategory? get currentCategory {
    final String? code = activeCategory;
    if (code == null) return null;
    for (final ServiceCategory c in categories) {
      if (c.code == code) return c;
    }
    return null;
  }
}
