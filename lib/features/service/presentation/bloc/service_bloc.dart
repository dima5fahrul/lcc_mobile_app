/// `ServiceBloc` — the catalogue page's state machine.
///
/// Port of the three `useQuery` calls and two `useState`s in
/// `ServicePage.tsx:285-355`. The React page keeps its state in hooks that
/// re-run on render; a BLoC keeps it in one immutable value, so the mapping is
/// worth stating field by field:
///
/// | React | Here |
/// |---|---|
/// | `useState activeCategory` | [ServiceState.activeCategory] |
/// | `useState searchQuery` | [ServiceState.searchQuery] |
/// | `useDebounced(query, 300)` | [ServiceState.debouncedQuery] + [_debounce] |
/// | `categoriesQuery` | [ServiceState.catalogueStatus] + `.categories` |
/// | `allServicesQuery` | the same status + `.allServices` (see below) |
/// | `listQuery` (`enabled: !showCategoryView`) | [ServiceState.listStatus] + `.services` |
///
/// ## Two catalogue queries, one status — and why that is faithful
///
/// The source fires `/service-categories` and `/services` as two independent
/// `useQuery`s, then renders `categoriesQuery.loading || allServicesQuery.loading`
/// as one skeleton and `categoriesQuery.error || allServicesQuery.error` as one
/// error panel, retried together by `retryCatalogue()`. There is no state in
/// which the page shows one and not the other, so they are one status here.
/// What the source *does* distinguish is **which message** the error panel
/// shows — categories failing says "Could not load the categories.", services
/// failing says "Could not load the services." — so that distinction is kept
/// as [ServiceState.catalogueErrorSource] rather than collapsed away.
///
/// The two requests still go out **concurrently** (`Future.wait`), because the
/// source issues them concurrently and serialising them would double the
/// time-to-first-paint on the app's second-most-visited screen.
///
/// ## Why `allServices` is fetched at all
///
/// Only for the per-category counts (`ServicePage.tsx:331-337`). It is the
/// unfiltered 43-row array; the *cards* come from [ServiceState.services],
/// which is a separately-filtered request. Deriving the counts from the
/// filtered list instead would make every category's count read as the count of
/// whatever the citizen last searched for.
///
/// ## The debounce, and `typing`
///
/// `useDebounced(query, 300)` holds the trimmed query for 300 ms; the source
/// then computes `typing = query !== debouncedQuery` and folds it into
/// `listLoading`, so the grid shows a skeleton *during* the debounce window
/// rather than rows from the previous search. Same here: [_debounce] is a
/// `Timer` that dispatches [ServiceSearchDebounced], and [ServiceState.typing]
/// is the same comparison. The timer is cancelled in [close] — a BLoC that
/// outlived its own timer would emit after being closed.
library;

import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:dartz/dartz.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/usecase/usecase.dart';
import '../../domain/entities/service.dart';
import '../../domain/entities/service_category.dart';
import '../../domain/usecases/get_service_categories.dart';
import '../../domain/usecases/get_services.dart';

part 'service_event.dart';
part 'service_state.dart';
part 'service_bloc.freezed.dart';

/// `useDebounced(query, 300)` — `ServicePage.tsx:292`.
const Duration kSearchDebounce = Duration(milliseconds: 300);

class ServiceBloc extends Bloc<ServiceEvent, ServiceState> {
  ServiceBloc({
    required this.getServiceCategories,
    required this.getServices,
  }) : super(const ServiceState()) {
    on<ServiceStarted>(_onStarted);
    on<ServiceCatalogueRetried>(_onCatalogueRetried);
    on<ServiceCategorySelected>(_onCategorySelected);
    on<ServiceSearchChanged>(_onSearchChanged);
    on<ServiceSearchDebounced>(_onSearchDebounced);
    on<ServiceListRetried>(_onListRetried);
  }

  final GetServiceCategories getServiceCategories;
  final GetServices getServices;

  Timer? _debounce;

  @override
  Future<void> close() {
    _debounce?.cancel();
    return super.close();
  }

  // ── The catalogue pair ─────────────────────────────────────────────────────

  Future<void> _onStarted(
    ServiceStarted event,
    Emitter<ServiceState> emit,
  ) =>
      _loadCatalogue(emit);

  Future<void> _onCatalogueRetried(
    ServiceCatalogueRetried event,
    Emitter<ServiceState> emit,
  ) =>
      _loadCatalogue(emit);

  /// `retryCatalogue()` (`ServicePage.tsx:352-355`): both queries, together.
  Future<void> _loadCatalogue(Emitter<ServiceState> emit) async {
    emit(state.copyWith(
      catalogueStatus: CatalogueStatus.loading,
      catalogueErrorSource: null,
    ));

    final List<Object> results = await Future.wait(<Future<Object>>[
      getServiceCategories(NoParams()),
      getServices(GetServicesParams.all),
    ]);

    final Either<Failure, List<ServiceCategory>> categories =
        results[0] as Either<Failure, List<ServiceCategory>>;
    final Either<Failure, List<Service>> all =
        results[1] as Either<Failure, List<Service>>;

    // Source order: `categoriesQuery.error ? categoriesError : servicesError`
    // — categories win when both fail, because that is the branch the source
    // tests first.
    if (categories.isLeft()) {
      emit(state.copyWith(
        catalogueStatus: CatalogueStatus.failure,
        catalogueErrorSource: CatalogueErrorSource.categories,
      ));
      return;
    }
    if (all.isLeft()) {
      emit(state.copyWith(
        catalogueStatus: CatalogueStatus.failure,
        catalogueErrorSource: CatalogueErrorSource.services,
      ));
      return;
    }

    emit(state.copyWith(
      catalogueStatus: CatalogueStatus.success,
      catalogueErrorSource: null,
      categories: categories.getOrElse(() => const <ServiceCategory>[]),
      allServices: all.getOrElse(() => const <Service>[]),
    ));
  }

  // ── Filters ────────────────────────────────────────────────────────────────

  Future<void> _onCategorySelected(
    ServiceCategorySelected event,
    Emitter<ServiceState> emit,
  ) async {
    emit(state.copyWith(activeCategory: event.code));
    if (state.showCategoryView) return;
    await _loadList(emit);
  }

  /// Every keystroke. Emits immediately so the field is not laggy, then arms
  /// the debounce; the fetch happens in [_onSearchDebounced].
  void _onSearchChanged(
    ServiceSearchChanged event,
    Emitter<ServiceState> emit,
  ) {
    emit(state.copyWith(searchQuery: event.query));

    _debounce?.cancel();

    // Clearing the field is not a search — the source's `showCategoryView`
    // flips back to the category grid and `listQuery` is disabled, so there is
    // nothing to wait 300 ms for. Settle the debounced value now, or the page
    // would sit in `typing` (and therefore in a skeleton) for 300 ms on its way
    // back to a view that needs no request at all.
    if (event.query.trim().isEmpty) {
      add(const ServiceSearchDebounced(''));
      return;
    }

    _debounce = Timer(
      kSearchDebounce,
      () => add(ServiceSearchDebounced(event.query.trim())),
    );
  }

  Future<void> _onSearchDebounced(
    ServiceSearchDebounced event,
    Emitter<ServiceState> emit,
  ) async {
    // A timer that fired after the citizen typed again. `_debounce.cancel()`
    // makes this rare rather than impossible — the event can already be queued
    // when the next keystroke lands — so the guard is the real correctness
    // boundary, not the cancel.
    if (event.query != state.searchQuery.trim()) return;

    emit(state.copyWith(debouncedQuery: event.query));
    if (state.showCategoryView) return;
    await _loadList(emit);
  }

  Future<void> _onListRetried(
    ServiceListRetried event,
    Emitter<ServiceState> emit,
  ) =>
      _loadList(emit);

  /// `listQuery` — `/services?search=&category=`.
  Future<void> _loadList(Emitter<ServiceState> emit) async {
    emit(state.copyWith(listStatus: ServiceListStatus.loading));

    final Either<Failure, List<Service>> result = await getServices(
      GetServicesParams(
        search: state.debouncedQuery,
        category: state.activeCategory,
      ),
    );

    emit(
      result.fold(
        (Failure _) => state.copyWith(listStatus: ServiceListStatus.failure),
        (List<Service> rows) => state.copyWith(
          listStatus: ServiceListStatus.success,
          services: rows,
        ),
      ),
    );
  }
}
