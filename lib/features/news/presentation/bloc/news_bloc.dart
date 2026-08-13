/// `NewsBloc` — the `/news` list page's state.
///
/// Ports `NewsPage.tsx`'s three `useState`s and two `useQuery`s:
/// `filter` + `page` are the query, `categories` and `list` are the answers.
///
/// ## Two regions, two statuses
///
/// The chips and the list fail independently on the web — `categories.data ??
/// []` (`:103`) means a failed category fetch renders "All" alone and the list
/// still works — so they carry separate [RegionStatus]es here rather than one
/// page-wide status. Collapsing them would take the whole page down over a
/// filter bar.
///
/// ## The catalogue query is absent, deliberately
///
/// `NewsPage.tsx:51` fetches the 100-row catalogue purely to turn a slug into
/// the numeric position `#/news/3` needs. The Flutter route is `/news/:slug`,
/// so there is nothing to translate — see `NewsRepository`'s doc. The web's
/// loading condition is `list.loading || catalogue.loading`; here it is the
/// list alone.
library;

import 'package:bloc/bloc.dart';
import 'package:dartz/dartz.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/usecase/usecase.dart';
import '../../domain/entities/news_article.dart';
import '../../domain/entities/news_category.dart';
import '../../domain/repositories/news_page_result.dart';
import '../../domain/usecases/news_usecases.dart';

part 'news_event.dart';
part 'news_state.dart';
part 'news_bloc.freezed.dart';

class NewsBloc extends Bloc<NewsEvent, NewsState> {
  NewsBloc({
    required this.getNewsCategories,
    required this.getNewsArticles,
  }) : super(const NewsState()) {
    on<NewsStarted>(_onStarted);
    on<NewsCategoriesRetried>(_onCategoriesRetried);
    on<NewsListRetried>(_onListRetried);
    on<NewsCategoryPicked>(_onCategoryPicked);
    on<NewsPreviousPage>(_onPreviousPage);
    on<NewsNextPage>(_onNextPage);
  }

  final GetNewsCategories getNewsCategories;
  final GetNewsArticles getNewsArticles;

  // ── Mount ──────────────────────────────────────────────────────────────────

  /// The two `useQuery` calls `NewsPage.tsx:39,43` fires on render. Issued
  /// concurrently: neither depends on the other, and the source's two hooks run
  /// in the same tick.
  Future<void> _onStarted(NewsStarted event, Emitter<NewsState> emit) async {
    emit(state.copyWith(
      categoriesStatus: RegionStatus.loading,
      listStatus: RegionStatus.loading,
    ));

    final List<Object> results = await Future.wait(<Future<Object>>[
      getNewsCategories(NoParams()),
      _fetchPage(state.filter, 1),
    ]);

    final Either<Failure, List<NewsCategory>> categories =
        results[0] as Either<Failure, List<NewsCategory>>;
    final Either<Failure, NewsPageResult> list =
        results[1] as Either<Failure, NewsPageResult>;

    emit(state
        .copyWith(
          categoriesStatus: _statusOf(categories),
          categories: categories.getOrElse(() => state.categories),
        )
        .withList(list));
  }

  Future<void> _onCategoriesRetried(
    NewsCategoriesRetried event,
    Emitter<NewsState> emit,
  ) async {
    emit(state.copyWith(categoriesStatus: RegionStatus.loading));
    final Either<Failure, List<NewsCategory>> result =
        await getNewsCategories(NoParams());
    emit(state.copyWith(
      categoriesStatus: _statusOf(result),
      categories: result.getOrElse(() => state.categories),
    ));
  }

  // ── The list query: filter and page are its two inputs ─────────────────────

  Future<void> _onListRetried(
    NewsListRetried event,
    Emitter<NewsState> emit,
  ) =>
      _load(emit, state.filter, state.page);

  /// `pick(c)` — `NewsPage.tsx:56-59`: set the filter **and reset to page 1**.
  /// Keeping the page would ask for page 3 of a filter that may have one page
  /// and render an empty list that is not empty.
  Future<void> _onCategoryPicked(
    NewsCategoryPicked event,
    Emitter<NewsState> emit,
  ) =>
      _load(emit, event.category, 1);

  /// `setPage(p => Math.max(1, p - 1))` — `NewsPage.tsx:208`.
  Future<void> _onPreviousPage(
    NewsPreviousPage event,
    Emitter<NewsState> emit,
  ) =>
      _load(emit, state.filter, state.page - 1 < 1 ? 1 : state.page - 1);

  /// `setPage(p => p + 1)` — `NewsPage.tsx:219`.
  Future<void> _onNextPage(NewsNextPage event, Emitter<NewsState> emit) =>
      _load(emit, state.filter, state.page + 1);

  Future<void> _load(
    Emitter<NewsState> emit,
    String filter,
    int page,
  ) async {
    // The filter and the requested page move to their new values immediately —
    // the chip must look selected while its list is still in flight, which is
    // what `setFilter` before the query re-runs does on the web.
    emit(state.copyWith(
      filter: filter,
      page: page,
      listStatus: RegionStatus.loading,
    ));
    emit(state.withList(await _fetchPage(filter, page)));
  }

  Future<Either<Failure, NewsPageResult>> _fetchPage(
    String filter,
    int page,
  ) =>
      getNewsArticles(GetNewsArticlesParams(page: page, category: filter));

  static RegionStatus _statusOf(Either<Failure, Object?> result) =>
      result.isLeft() ? RegionStatus.failure : RegionStatus.success;
}
