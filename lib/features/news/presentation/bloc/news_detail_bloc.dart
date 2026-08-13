/// `NewsDetailBloc` — the `/news/:slug` page's state.
///
/// Ports `NewsDetailPage.tsx`'s two `useQuery`s (`catalogue`, `detail`) and the
/// four-way render it derives from them (`:85-155`).
///
/// ## The web's `resolving` expression, and what survives the port
///
/// ```tsx
/// const resolving = catalogue.loading || detail.loading
///                   || (Boolean(slug) && !article && !detail.error);
/// const loadError = detail.error ?? catalogue.error;
/// ```
///
/// The catalogue is in `resolving` because the web needs it **to find the
/// slug** — the hash route is a numeric position (`newsData.ts`). The Flutter
/// route carries the slug, so the article read no longer waits on the
/// catalogue, and this BLoC fires both concurrently: the article resolves the
/// page, the catalogue only fills "More news".
///
/// That is why [NewsDetailState.status] tracks the **article** alone and
/// `moreStatus` is separate. A failed catalogue on the web blanks the whole
/// page; here it costs the "More news" strip and nothing else — a strictly
/// better outcome that also matches what `catalogue.error` *means* once it is
/// no longer load-bearing for identity.
///
/// ## A 404 is not the error state
///
/// `:117` reads `loadError && !loadError.isNotFound`, so a missing article
/// takes the *empty* branch (`t("empty")` plus "Back to news") and not the
/// error branch. [NewsArticleNotFound] carries that distinction up from the
/// repository; see `news_failures.dart` for why it must not be collapsed.
library;

import 'package:bloc/bloc.dart';
import 'package:dartz/dartz.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/usecase/usecase.dart';
import '../../domain/entities/news_article.dart';
import '../../domain/news_failures.dart';
import '../../domain/usecases/news_usecases.dart';
import 'news_bloc.dart' show RegionStatus;

part 'news_detail_event.dart';
part 'news_detail_state.dart';
part 'news_detail_bloc.freezed.dart';

class NewsDetailBloc extends Bloc<NewsDetailEvent, NewsDetailState> {
  NewsDetailBloc({
    required this.slug,
    required this.getNewsArticle,
    required this.getNewsCatalogue,
  }) : super(NewsDetailState(slug: slug)) {
    on<NewsDetailStarted>(_onStarted);
    on<NewsDetailRetried>(_onRetried);
  }

  /// The `/news/:slug` path parameter, supplied by the route builder.
  final String slug;

  final GetNewsArticle getNewsArticle;
  final GetNewsCatalogue getNewsCatalogue;

  Future<void> _onStarted(
    NewsDetailStarted event,
    Emitter<NewsDetailState> emit,
  ) =>
      _load(emit);

  /// `detail.error ? detail.refetch() : catalogue.refetch()` —
  /// `NewsDetailPage.tsx:122`. Both are re-fired here rather than one: the two
  /// are independent now, and a retry that reloaded only the article would
  /// leave a failed "More news" strip failed with no way to recover it.
  Future<void> _onRetried(
    NewsDetailRetried event,
    Emitter<NewsDetailState> emit,
  ) =>
      _load(emit);

  Future<void> _load(Emitter<NewsDetailState> emit) async {
    // An empty slug cannot be requested. The router will not produce one
    // (`/news/` does not match `/news/:slug`), but a caller constructing the
    // BLoC directly could — and `GET /news/` is `GET /news`, which would answer
    // 200 with the list envelope and parse into a blank article.
    if (slug.isEmpty) {
      emit(state.copyWith(
        status: RegionStatus.failure,
        notFound: true,
        moreStatus: RegionStatus.failure,
      ));
      return;
    }

    emit(state.copyWith(
      status: RegionStatus.loading,
      notFound: false,
      moreStatus: RegionStatus.loading,
    ));

    final List<Object> results = await Future.wait(<Future<Object>>[
      getNewsArticle(GetNewsArticleParams(slug)),
      getNewsCatalogue(NoParams()),
    ]);

    final Either<Failure, NewsArticle> article =
        results[0] as Either<Failure, NewsArticle>;
    final Either<Failure, List<NewsArticle>> catalogue =
        results[1] as Either<Failure, List<NewsArticle>>;

    emit(article.fold(
      (Failure failure) => state.copyWith(
        status: RegionStatus.failure,
        notFound: failure is NewsArticleNotFound,
        article: null,
        moreStatus: _statusOf(catalogue),
        more: catalogue.fold(
          (Failure _) => const <NewsArticle>[],
          // No article means no slug to exclude; `moreNewsFrom` with the
          // requested slug is still right — it is the row that is missing.
          (List<NewsArticle> rows) => moreNewsFrom(rows, slug),
        ),
      ),
      (NewsArticle found) => state.copyWith(
        status: RegionStatus.success,
        notFound: false,
        article: found,
        moreStatus: _statusOf(catalogue),
        more: catalogue.fold(
          (Failure _) => const <NewsArticle>[],
          (List<NewsArticle> rows) => moreNewsFrom(rows, found.slug),
        ),
      ),
    ));
  }

  static RegionStatus _statusOf(Either<Failure, Object?> result) =>
      result.isLeft() ? RegionStatus.failure : RegionStatus.success;
}
