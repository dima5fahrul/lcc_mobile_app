/// `HelpBloc` — the `/help` page's state. One screen, five independent reads.
///
/// Ports `HelpCenterPage.tsx`'s six `useState`s and five `useQuery`s.
///
/// ## Five regions, five statuses
///
/// Topics, questions, guides, the expanded guide's body, and support channels
/// all fail independently on the web, and each renders its own `ErrorBlock`
/// (`:269`, `:404`, `:441`, `:477`). Collapsing them into one page status would
/// take the whole help centre down over a channel list.
///
/// ## The debounce is the BLoC's, not the field's
///
/// `useDebounced(query.trim(), 350)` (`:102`) means the *query parameter* is
/// debounced while the input value is not — the field updates instantly and the
/// request trails it. That is reproduced with a `Timer`: [HelpSearchChanged]
/// moves `query` immediately and schedules [HelpSearchDebounced], which is what
/// actually fetches. `HomeBloc` uses the same shape, and the `Timer` is
/// cancelled in [close] for the same reason.
library;

import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:dartz/dartz.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/usecase/usecase.dart';
import '../../domain/entities/help_entities.dart';
import '../../domain/repositories/help_faq_page.dart';
import '../../domain/usecases/help_usecases.dart';

part 'help_event.dart';
part 'help_state.dart';
part 'help_bloc.freezed.dart';

class HelpBloc extends Bloc<HelpEvent, HelpState> {
  HelpBloc({
    required this.getHelpCategories,
    required this.getHelpFaqs,
    required this.getHelpGuides,
    required this.getHelpGuide,
    required this.getSupportChannels,
    required this.sendFaqFeedback,
  }) : super(const HelpState()) {
    on<HelpStarted>(_onStarted);
    on<HelpCategoriesRetried>(_onCategoriesRetried);
    on<HelpFaqsRetried>(_onFaqsRetried);
    on<HelpGuidesRetried>(_onGuidesRetried);
    on<HelpChannelsRetried>(_onChannelsRetried);
    on<HelpTopicPicked>(_onTopicPicked);
    on<HelpSearchChanged>(_onSearchChanged);
    on<HelpSearchDebounced>(_onSearchDebounced);
    on<HelpSearchCleared>(_onSearchCleared);
    on<HelpPreviousPage>(_onPreviousPage);
    on<HelpNextPage>(_onNextPage);
    on<HelpFaqToggled>(_onFaqToggled);
    on<HelpGuideToggled>(_onGuideToggled);
    on<HelpGuideRetried>(_onGuideRetried);
    on<HelpFaqVoted>(_onFaqVoted);
  }

  final GetHelpCategories getHelpCategories;
  final GetHelpFaqs getHelpFaqs;
  final GetHelpGuides getHelpGuides;
  final GetHelpGuide getHelpGuide;
  final GetSupportChannels getSupportChannels;
  final SendFaqFeedback sendFaqFeedback;

  Timer? _debounce;

  @override
  Future<void> close() {
    _debounce?.cancel();
    return super.close();
  }

  // ── Mount ──────────────────────────────────────────────────────────────────

  /// The four unconditional `useQuery` calls (`:104`, `:107`, `:116`, `:120`).
  /// The fifth (`:117`, the guide body) is `enabled: Boolean(openGuide)` and
  /// fires only on expand.
  Future<void> _onStarted(HelpStarted event, Emitter<HelpState> emit) async {
    emit(state.copyWith(
      categoriesStatus: RegionStatus.loading,
      faqStatus: RegionStatus.loading,
      guidesStatus: RegionStatus.loading,
      channelsStatus: RegionStatus.loading,
    ));

    final List<Object> results = await Future.wait(<Future<Object>>[
      getHelpCategories(NoParams()),
      _fetchFaqs(state.topic, state.debouncedQuery, 1),
      getHelpGuides(NoParams()),
      getSupportChannels(NoParams()),
    ]);

    final Either<Failure, List<FaqCategory>> categories =
        results[0] as Either<Failure, List<FaqCategory>>;
    final Either<Failure, HelpFaqPage> faqs =
        results[1] as Either<Failure, HelpFaqPage>;
    final Either<Failure, List<HelpArticle>> guides =
        results[2] as Either<Failure, List<HelpArticle>>;
    final Either<Failure, List<SupportChannel>> channels =
        results[3] as Either<Failure, List<SupportChannel>>;

    emit(state
        .copyWith(
          categoriesStatus: _statusOf(categories),
          categories: categories.getOrElse(() => state.categories),
          guidesStatus: _statusOf(guides),
          guides: guides.getOrElse(() => state.guides),
          channelsStatus: _statusOf(channels),
          channels: channels.getOrElse(() => state.channels),
        )
        .withFaqs(faqs));
  }

  // ── Retries (§ 6.6, B2-AC-16) ──────────────────────────────────────────────

  Future<void> _onCategoriesRetried(
    HelpCategoriesRetried event,
    Emitter<HelpState> emit,
  ) async {
    emit(state.copyWith(categoriesStatus: RegionStatus.loading));
    final Either<Failure, List<FaqCategory>> result =
        await getHelpCategories(NoParams());
    emit(state.copyWith(
      categoriesStatus: _statusOf(result),
      categories: result.getOrElse(() => state.categories),
    ));
  }

  Future<void> _onFaqsRetried(
    HelpFaqsRetried event,
    Emitter<HelpState> emit,
  ) =>
      _loadFaqs(emit, state.topic, state.debouncedQuery, state.page);

  Future<void> _onGuidesRetried(
    HelpGuidesRetried event,
    Emitter<HelpState> emit,
  ) async {
    emit(state.copyWith(guidesStatus: RegionStatus.loading));
    final Either<Failure, List<HelpArticle>> result =
        await getHelpGuides(NoParams());
    emit(state.copyWith(
      guidesStatus: _statusOf(result),
      guides: result.getOrElse(() => state.guides),
    ));
  }

  Future<void> _onChannelsRetried(
    HelpChannelsRetried event,
    Emitter<HelpState> emit,
  ) async {
    emit(state.copyWith(channelsStatus: RegionStatus.loading));
    final Either<Failure, List<SupportChannel>> result =
        await getSupportChannels(NoParams());
    emit(state.copyWith(
      channelsStatus: _statusOf(result),
      channels: result.getOrElse(() => state.channels),
    ));
  }

  // ── The question query: topic, search and page are its three inputs ────────

  /// `setCat(code); setPage(1)` — `:212-214`, `:231-234`.
  Future<void> _onTopicPicked(
    HelpTopicPicked event,
    Emitter<HelpState> emit,
  ) =>
      _loadFaqs(emit, event.topic, state.debouncedQuery, 1);

  /// The field moves now; the request trails by [kHelpSearchDebounce].
  ///
  /// `setPage(1)` fires on every keystroke on the web (`:186`), so it is
  /// applied here rather than in the debounced handler — otherwise a citizen
  /// on page 3 who starts typing would see "3 / 3" until the request landed.
  Future<void> _onSearchChanged(
    HelpSearchChanged event,
    Emitter<HelpState> emit,
  ) async {
    emit(state.copyWith(query: event.query, page: 1));

    _debounce?.cancel();
    final String pending = event.query.trim();
    _debounce = Timer(
      kHelpSearchDebounce,
      () => add(HelpSearchDebounced(pending)),
    );
  }

  Future<void> _onSearchDebounced(
    HelpSearchDebounced event,
    Emitter<HelpState> emit,
  ) async {
    // A keystroke after the timer was scheduled but before it fired makes this
    // event stale. Dropping it keeps the "one request for N keystrokes"
    // property the debounce exists for.
    if (event.query != state.query.trim()) return;
    await _loadFaqs(emit, state.topic, event.query, 1);
  }

  /// The `X` inside the field — `:194-197`. Cancels any pending debounce, so
  /// clearing never lands a search for the text that was just removed.
  Future<void> _onSearchCleared(
    HelpSearchCleared event,
    Emitter<HelpState> emit,
  ) async {
    _debounce?.cancel();
    emit(state.copyWith(query: ''));
    await _loadFaqs(emit, state.topic, '', 1);
  }

  Future<void> _onPreviousPage(
    HelpPreviousPage event,
    Emitter<HelpState> emit,
  ) =>
      _loadFaqs(
        emit,
        state.topic,
        state.debouncedQuery,
        state.page - 1 < 1 ? 1 : state.page - 1,
      );

  Future<void> _onNextPage(HelpNextPage event, Emitter<HelpState> emit) =>
      _loadFaqs(emit, state.topic, state.debouncedQuery, state.page + 1);

  Future<void> _loadFaqs(
    Emitter<HelpState> emit,
    String topic,
    String query,
    int page,
  ) async {
    emit(state.copyWith(
      topic: topic,
      debouncedQuery: query,
      page: page,
      faqStatus: RegionStatus.loading,
    ));
    emit(state.withFaqs(await _fetchFaqs(topic, query, page)));
  }

  Future<Either<Failure, HelpFaqPage>> _fetchFaqs(
    String topic,
    String query,
    int page,
  ) =>
      getHelpFaqs(GetHelpFaqsParams(
        page: page,
        category: topic,
        search: query,
      ));

  // ── Accordions ─────────────────────────────────────────────────────────────

  /// `setOpen(isOpen ? null : a.id)` — `:287`. One question open at a time.
  Future<void> _onFaqToggled(
    HelpFaqToggled event,
    Emitter<HelpState> emit,
  ) async {
    emit(state.copyWith(
      openFaqId: state.openFaqId == event.id ? null : event.id,
    ));
  }

  /// `setOpenGuide(isOpen ? null : g.slug)` — `:416`, plus the lazy body fetch
  /// the `enabled: Boolean(openGuide)` query performs.
  ///
  /// Collapsing does **not** clear [HelpState.guideBody]: the source's
  /// `guide.data?.slug === g.slug` check (`:442`) means a re-expand renders the
  /// cached body immediately, and re-fetching it would show a skeleton for
  /// content already in hand. Re-expanding a *different* guide still fetches,
  /// because the slug no longer matches.
  Future<void> _onGuideToggled(
    HelpGuideToggled event,
    Emitter<HelpState> emit,
  ) async {
    if (state.openGuideSlug == event.slug) {
      emit(state.copyWith(openGuideSlug: null));
      return;
    }
    emit(state.copyWith(openGuideSlug: event.slug));
    if (state.guideBody?.slug == event.slug) return;
    await _loadGuide(emit, event.slug);
  }

  Future<void> _onGuideRetried(
    HelpGuideRetried event,
    Emitter<HelpState> emit,
  ) async {
    final String? slug = state.openGuideSlug;
    if (slug == null) return;
    await _loadGuide(emit, slug);
  }

  Future<void> _loadGuide(Emitter<HelpState> emit, String slug) async {
    emit(state.copyWith(guideStatus: RegionStatus.loading, guideBody: null));
    final Either<Failure, HelpArticle> result =
        await getHelpGuide(GetHelpGuideParams(slug));
    emit(state.copyWith(
      guideStatus: _statusOf(result),
      guideBody: result.getOrElse(() => const HelpArticle()),
    ));
  }

  // ── Feedback ───────────────────────────────────────────────────────────────

  /// `vote(id, helpful)` — `:138-146`.
  ///
  /// The vote is recorded in state **before** the request and is **not rolled
  /// back on failure**. That is the source's own decision, with its own reason
  /// at `:143-145`: *"A failed vote is not worth interrupting the reader; leave
  /// the thanks in place rather than flipping the row back under their
  /// finger."* Ported as written.
  Future<void> _onFaqVoted(HelpFaqVoted event, Emitter<HelpState> emit) async {
    emit(state.copyWith(
      votes: <String, bool>{...state.votes, event.id: event.helpful},
    ));
    await sendFaqFeedback(
      SendFaqFeedbackParams(id: event.id, helpful: event.helpful),
    );
  }

  static RegionStatus _statusOf(Either<Failure, Object?> result) =>
      result.isLeft() ? RegionStatus.failure : RegionStatus.success;
}
