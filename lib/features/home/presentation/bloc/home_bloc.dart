/// `HomeBloc` — the home page's state machine.
///
/// Port of the five `useQuery` calls and six `useState`s in
/// `HomePage.tsx:143-272`, field by field:
///
/// | React | Here |
/// |---|---|
/// | `useState searchQuery` | [HomeState.searchQuery] |
/// | `useState showBanner` | [HomeState.bannerVisible] |
/// | `useState openFaq` | [HomeState.openFaqIndex] |
/// | `summary` (`enabled: isAuthenticated`) | [HomeState.summaryStatus] + `.summary` |
/// | `digitalId` (`enabled: isAuthenticated`) | [HomeState.digitalIdStatus] + `.digitalId` |
/// | `servicesQuery` | [HomeState.servicesStatus] + `.quickActions` |
/// | `newsQuery` | [HomeState.newsStatus] + `.news` |
/// | `faqQuery` | [HomeState.faqStatus] + `.faqs` |
/// | `displayedServices` | [HomeState.displayedServices] |
///
/// ## Five regions, five statuses, and no page-wide state
///
/// See [RegionStatus]' doc. The short version: `HomePage` stacks four
/// independently-fetched sections down one scroll, each with its own loading
/// skeleton, its own error sentence and its own retry. There is no state in
/// which the source shows a single page-level spinner, so there is no
/// page-level status here to be tempted into rendering one.
///
/// ## The four anonymous fetches go out concurrently
///
/// `Future.wait`, because the source issues them concurrently (five parallel
/// `useQuery`s on one render) and serialising them would stack four round trips
/// on the app's landing screen. Each `Either` is folded into its own region, so
/// one failure cannot take another region down with it.
///
/// ## `useState` that is NOT here, and why
///
/// `hoveredService`, `showQr`, `showUin` and `showDismissConfirm` are pointer
/// and disclosure state belonging to one widget, with no consequence outside
/// its own subtree and nothing else in the app able to observe them. They stay
/// in the widgets. `showBanner` and `openFaq` are here instead because both
/// survive a rebuild the citizen can trigger from elsewhere on the page (a
/// search that re-lays out the grid above them), and because Tier 1 compares
/// the *first FAQ's answer* — which is a page state, not a hover.
///
/// `homeServiceIds` / `customized` / `draftIds` are the Customize modal's, and
/// that modal is not ported — see `home_page.dart`'s scope note.
library;

import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:dartz/dartz.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/usecase/usecase.dart';
import '../../../service/domain/entities/service.dart';
import '../../domain/entities/digital_id_card.dart';
import '../../domain/entities/home_faq_item.dart';
import '../../domain/entities/home_news_item.dart';
import '../../domain/entities/home_summary.dart';
import '../../domain/usecases/home_usecases.dart';

part 'home_event.dart';
part 'home_state.dart';
part 'home_bloc.freezed.dart';

/// How long the search field waits before asking the server.
///
/// **The web has no debounce here** — `HomePage.tsx:264` filters an in-memory
/// array on every keystroke, which costs nothing. This app asks the API
/// instead (see `HomeRepository.searchServices` for that decision), so a
/// per-keystroke fetch would put one request per character on a mobile
/// connection. 300 ms is `ServicePage.tsx:292`'s own `useDebounced(query, 300)`
/// — the same catalogue, searched the same way, waiting the same time, rather
/// than a second number invented for the second page.
const Duration kHomeSearchDebounce = Duration(milliseconds: 300);

class HomeBloc extends Bloc<HomeEvent, HomeState> {
  HomeBloc({
    required this.getHomeSummary,
    required this.getDigitalId,
    required this.getPhase1Services,
    required this.searchServices,
    required this.getFeaturedNews,
    required this.getHomeFaqs,
  }) : super(const HomeState()) {
    on<HomeStarted>(_onStarted);
    on<HomeAuthChanged>(_onAuthChanged);
    on<HomeSummaryRetried>(_onSummaryRetried);
    on<HomeServicesRetried>(_onServicesRetried);
    on<HomeNewsRetried>(_onNewsRetried);
    on<HomeFaqsRetried>(_onFaqsRetried);
    on<HomeSearchChanged>(_onSearchChanged);
    on<HomeSearchDebounced>(_onSearchDebounced);
    on<HomeSearchCleared>(_onSearchCleared);
    on<HomeBannerDismissed>(_onBannerDismissed);
    on<HomeFaqToggled>(_onFaqToggled);
  }

  final GetHomeSummary getHomeSummary;
  final GetDigitalId getDigitalId;
  final GetPhase1Services getPhase1Services;
  final SearchServices searchServices;
  final GetFeaturedNews getFeaturedNews;
  final GetHomeFaqs getHomeFaqs;

  Timer? _debounce;

  @override
  Future<void> close() {
    // A BLoC that outlived its own timer would emit after being closed.
    _debounce?.cancel();
    return super.close();
  }

  // ── Mount ──────────────────────────────────────────────────────────────────

  Future<void> _onStarted(HomeStarted event, Emitter<HomeState> emit) async {
    emit(state.copyWith(
      servicesStatus: RegionStatus.loading,
      newsStatus: RegionStatus.loading,
      faqStatus: RegionStatus.loading,
    ));

    final List<Object> results = await Future.wait(<Future<Object>>[
      getPhase1Services(NoParams()),
      getFeaturedNews(NoParams()),
      getHomeFaqs(NoParams()),
    ]);

    final Either<Failure, List<Service>> services =
        results[0] as Either<Failure, List<Service>>;
    final Either<Failure, List<HomeNewsItem>> news =
        results[1] as Either<Failure, List<HomeNewsItem>>;
    final Either<Failure, List<HomeFaqItem>> faqs =
        results[2] as Either<Failure, List<HomeFaqItem>>;

    emit(state.copyWith(
      servicesStatus: _statusOf(services),
      quickActions: services.getOrElse(() => state.quickActions),
      newsStatus: _statusOf(news),
      news: news.getOrElse(() => state.news),
      faqStatus: _statusOf(faqs),
      faqs: faqs.getOrElse(() => state.faqs),
    ));
  }

  // ── The two authenticated regions ──────────────────────────────────────────

  Future<void> _onAuthChanged(
    HomeAuthChanged event,
    Emitter<HomeState> emit,
  ) async {
    if (!event.isAuthenticated) {
      // Signed out: no request, and **no residue**. Back to `initial`, which
      // is what renders the two regions as absent rather than as an error —
      // and what guarantees the previous citizen's UIN and balance are gone
      // from the state, not merely hidden by a widget condition.
      emit(state.copyWith(
        isAuthenticated: false,
        summaryStatus: RegionStatus.initial,
        summary: null,
        digitalIdStatus: RegionStatus.initial,
        digitalId: null,
      ));
      return;
    }

    emit(state.copyWith(
      isAuthenticated: true,
      summaryStatus: RegionStatus.loading,
      digitalIdStatus: RegionStatus.loading,
    ));

    final List<Object> results = await Future.wait(<Future<Object>>[
      getHomeSummary(NoParams()),
      getDigitalId(NoParams()),
    ]);

    final Either<Failure, HomeSummary> summary =
        results[0] as Either<Failure, HomeSummary>;
    final Either<Failure, DigitalIdCard> digitalId =
        results[1] as Either<Failure, DigitalIdCard>;

    emit(state.copyWith(
      summaryStatus: _statusOf(summary),
      summary: summary.getOrElse(() => state.summary ?? const HomeSummary()),
      digitalIdStatus: _statusOf(digitalId),
      digitalId: digitalId.getOrElse(
        () => state.digitalId ?? const DigitalIdCard(),
      ),
    ));
  }

  Future<void> _onSummaryRetried(
    HomeSummaryRetried event,
    Emitter<HomeState> emit,
  ) async {
    // `summary.refetch` is only reachable from the summary error panel, which
    // only renders when signed in. Guarding anyway: a retry dispatched after a
    // sign-out raced the panel's disposal would otherwise fire an
    // authenticated request with no token.
    if (!state.isAuthenticated) return;

    emit(state.copyWith(summaryStatus: RegionStatus.loading));
    final Either<Failure, HomeSummary> result = await getHomeSummary(NoParams());
    emit(state.copyWith(
      summaryStatus: _statusOf(result),
      summary: result.getOrElse(() => state.summary ?? const HomeSummary()),
    ));
  }

  // ── The service grid ───────────────────────────────────────────────────────

  Future<void> _onServicesRetried(
    HomeServicesRetried event,
    Emitter<HomeState> emit,
  ) async {
    if (state.gridMode == ServiceGridMode.search) {
      await _loadSearch(emit, state.debouncedQuery);
      return;
    }
    await _loadQuickActions(emit);
  }

  Future<void> _loadQuickActions(Emitter<HomeState> emit) async {
    emit(state.copyWith(servicesStatus: RegionStatus.loading));
    final Either<Failure, List<Service>> result =
        await getPhase1Services(NoParams());
    emit(state.copyWith(
      servicesStatus: _statusOf(result),
      quickActions: result.getOrElse(() => state.quickActions),
    ));
  }

  Future<void> _loadSearch(Emitter<HomeState> emit, String query) async {
    emit(state.copyWith(searchStatus: RegionStatus.loading));
    final Either<Failure, List<Service>> result =
        await searchServices(SearchServicesParams(query));
    emit(state.copyWith(
      searchStatus: _statusOf(result),
      searchResults: result.getOrElse(() => const <Service>[]),
    ));
  }

  /// Every keystroke. Emits immediately so the field is not laggy, then arms
  /// the debounce; the fetch happens in [_onSearchDebounced].
  void _onSearchChanged(HomeSearchChanged event, Emitter<HomeState> emit) {
    emit(state.copyWith(searchQuery: event.query));

    _debounce?.cancel();

    // Emptying the field is not a search — the grid flips straight back to the
    // quick actions, which are already loaded. Settling the debounced value now
    // avoids 300 ms of `typing` (and therefore of skeleton) on the way to a
    // view that needs no request at all.
    if (event.query.trim().isEmpty) {
      add(const HomeSearchDebounced(''));
      return;
    }

    _debounce = Timer(
      kHomeSearchDebounce,
      () => add(HomeSearchDebounced(event.query.trim())),
    );
  }

  Future<void> _onSearchDebounced(
    HomeSearchDebounced event,
    Emitter<HomeState> emit,
  ) async {
    // A timer that fired after the citizen typed again. `cancel()` makes this
    // rare rather than impossible — the event can already be queued when the
    // next keystroke lands — so this guard is the real correctness boundary.
    if (event.query != state.query) return;

    emit(state.copyWith(debouncedQuery: event.query));
    if (event.query.isEmpty) return;
    await _loadSearch(emit, event.query);
  }

  void _onSearchCleared(HomeSearchCleared event, Emitter<HomeState> emit) {
    _debounce?.cancel();
    emit(state.copyWith(
      searchQuery: '',
      debouncedQuery: '',
      // Back to `initial`, not `success` with an empty list: the next search
      // must show a skeleton, not the previous search's "no results".
      searchStatus: RegionStatus.initial,
      searchResults: const <Service>[],
    ));
  }

  // ── News and FAQs ──────────────────────────────────────────────────────────

  Future<void> _onNewsRetried(
    HomeNewsRetried event,
    Emitter<HomeState> emit,
  ) async {
    emit(state.copyWith(newsStatus: RegionStatus.loading));
    final Either<Failure, List<HomeNewsItem>> result =
        await getFeaturedNews(NoParams());
    emit(state.copyWith(
      newsStatus: _statusOf(result),
      news: result.getOrElse(() => state.news),
    ));
  }

  Future<void> _onFaqsRetried(
    HomeFaqsRetried event,
    Emitter<HomeState> emit,
  ) async {
    emit(state.copyWith(faqStatus: RegionStatus.loading));
    final Either<Failure, List<HomeFaqItem>> result = await getHomeFaqs(NoParams());
    emit(state.copyWith(
      faqStatus: _statusOf(result),
      faqs: result.getOrElse(() => state.faqs),
    ));
  }

  // ── Local UI state ─────────────────────────────────────────────────────────

  void _onBannerDismissed(HomeBannerDismissed event, Emitter<HomeState> emit) =>
      emit(state.copyWith(bannerVisible: false));

  void _onFaqToggled(HomeFaqToggled event, Emitter<HomeState> emit) => emit(
        state.copyWith(
          openFaqIndex:
              state.openFaqIndex == event.index ? null : event.index,
        ),
      );

  /// `Either` → the region status it implies. One place, so a region cannot be
  /// left on `loading` by a handler that forgot the failure branch.
  static RegionStatus _statusOf(Either<Failure, Object?> result) =>
      result.isLeft() ? RegionStatus.failure : RegionStatus.success;
}
