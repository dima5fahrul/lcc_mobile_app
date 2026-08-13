/// Standing the two news pages up in a test.
///
/// ## The fixtures are RECORDINGS, and that closes B2-AC-36 for this feature
///
/// B2b's helper had to record an honest gap: it hand-wrote `/news`,
/// `/help/faqs` and the two `/me/*` payloads because B2a had captured only
/// `/services` and `/service-categories`. **B2c recorded all seven content
/// endpoints** from live staging through the same reverse-proxy rig at the same
/// commit, so every fixture below is parsed by the production `newsArticleFrom`
/// / `newsCategoryFrom` out of a real recording — not hand-written JSON.
///
/// That is what B2-AC-36 asks for, and it is the stronger check for the reason
/// § 5 gives: a hand-written fixture and a hand-written parser can be wrong
/// together.
///
/// The one hand-written fixture is [plainStringArticle], and it is deliberate:
/// § 5 measured that `/news` MAY send a plain `String` where `/services` sends
/// `{en,lo}`, and the recording happens not to. Exercising the branch needs a
/// row the server did not send today — labelled as synthetic so it cannot be
/// mistaken for evidence about the wire.
library;

import 'package:dartz/dartz.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lcc_mobile_app/core/error/failure.dart';
import 'package:lcc_mobile_app/features/news/data/models/news_wire.dart';
import 'package:lcc_mobile_app/features/news/domain/entities/news_article.dart';
import 'package:lcc_mobile_app/features/news/domain/entities/news_category.dart';
import 'package:lcc_mobile_app/features/news/domain/news_failures.dart';
import 'package:lcc_mobile_app/features/news/domain/repositories/news_page_result.dart';
import 'package:lcc_mobile_app/features/news/domain/repositories/news_repository.dart';
import 'package:lcc_mobile_app/features/news/domain/usecases/news_usecases.dart';
import 'package:lcc_mobile_app/features/news/presentation/bloc/news_bloc.dart';
import 'package:lcc_mobile_app/features/news/presentation/bloc/news_detail_bloc.dart';
import 'package:lcc_mobile_app/features/news/presentation/pages/news_detail_page.dart';
import 'package:lcc_mobile_app/features/news/presentation/pages/news_page.dart';
import 'package:lcc_mobile_app/presentation/theme/app_theme.dart';

import '../fidelity/oracle.dart';
import 'app_test_harness.dart';

/// The article slot 15 was captured against, and the one whose `body` is
/// recorded.
const String kRecordedSlug = 'lao-citizen-center-goes-live';

// ─────────────────────────────────────────────────────────────────────────────
// Fixtures — recordings
// ─────────────────────────────────────────────────────────────────────────────

/// The **six recorded articles**, parsed by the production `newsArticleFrom`.
List<NewsArticle> recordedArticles() =>
    loadApi('news').map(newsArticleFrom).toList(growable: false);

/// The **four recorded categories**.
List<NewsCategory> recordedCategories() =>
    loadApi('news-categories').map(newsCategoryFrom).toList(growable: false);

/// The one recorded article that carries a `body`.
NewsArticle recordedDetail() =>
    newsArticleFrom(loadApiObject('news-article-$kRecordedSlug'));

/// `GET /news` page 1 as staging answered it — 6 rows, 1 page.
NewsPageResult recordedPage() {
  final Map<String, dynamic> meta = loadApiMeta('news')!;
  return NewsPageResult(
    articles: recordedArticles(),
    page: meta['page'] as int,
    totalPages: meta['total_pages'] as int,
    hasNext: meta['has_next'] as bool,
    hasPrev: meta['has_prev'] as bool,
  );
}

/// **Hand-written, and labelled as such.** § 5's plain-string wire shape, which
/// the recording does not happen to contain.
NewsArticle plainStringArticle() => newsArticleFrom(<String, dynamic>{
      'id': 'synthetic-1',
      'slug': 'plain-string-row',
      'category': 'announcement',
      'category_name': 'Notice',
      'category_color': '#3752AE',
      'title': 'A single-language headline',
      'excerpt': 'A single-language excerpt.',
      'published_date': '2026-09-01',
    });

/// The failure `NewsRepositoryImpl` produces from a 404 on
/// `GET /news/<slug>`.
///
/// Its own type, not a plain [Failure], because that distinction is the whole
/// of the difference between the detail page's **empty** render (a way back, no
/// retry) and its **error** render (a retry). A test that stubbed a plain
/// `Failure` here would assert the wrong branch and pass.
Either<Failure, NewsArticle> notFound() =>
    const Left<Failure, NewsArticle>(NewsArticleNotFound('404'));

/// A multi-page result, for the pager. Staging answers one page at `per_page`
/// 6, so the two-page shape has to be constructed — the numbers, not the rows.
NewsPageResult pagedResult({required int page, required int totalPages}) =>
    NewsPageResult(
      articles: recordedArticles(),
      page: page,
      totalPages: totalPages,
      hasNext: page < totalPages,
      hasPrev: page > 1,
    );

// ─────────────────────────────────────────────────────────────────────────────
// The repository double
// ─────────────────────────────────────────────────────────────────────────────

/// A [NewsRepository] whose four answers a test sets, and whose calls it reads
/// back.
///
/// Hand-written rather than a `mocktail` mock for the reason
/// `FakeHomeRepository` gives: several behaviours under test are about *what
/// was asked for* — that picking a category resets to page 1, that the detail
/// page asks for the slug the router gave it — and a stub that records reads
/// better at the call site than a `verify(() => …)` chain.
class FakeNewsRepository implements NewsRepository {
  late Either<Failure, List<NewsCategory>> categories =
      Right<Failure, List<NewsCategory>>(recordedCategories());
  late Either<Failure, NewsPageResult> articles =
      Right<Failure, NewsPageResult>(recordedPage());
  late Either<Failure, List<NewsArticle>> catalogue =
      Right<Failure, List<NewsArticle>>(recordedArticles());
  late Either<Failure, NewsArticle> article =
      Right<Failure, NewsArticle>(recordedDetail());

  int categoryCalls = 0;
  int catalogueCalls = 0;

  /// Every `getArticles` call, in order. Read by the filter/pager assertions,
  /// which are claims about *what was requested*, not about a call count.
  final List<({int page, int perPage, String? category})> listCalls =
      <({int page, int perPage, String? category})>[];

  /// Every slug `getArticle` was asked for.
  final List<String> articleSlugs = <String>[];

  /// How long every call takes. Zero by default; a test that wants to observe
  /// the **loading** state sets it, because with an instant repository the
  /// first `pump()` already carries resolved data and a skeleton assertion
  /// would silently assert on the grid instead.
  Duration latency = Duration.zero;

  Future<void> _wait() async {
    if (latency > Duration.zero) await Future<void>.delayed(latency);
  }

  void failEverything() {
    const Failure f = Failure('stubbed failure');
    categories = const Left<Failure, List<NewsCategory>>(f);
    articles = const Left<Failure, NewsPageResult>(f);
    catalogue = const Left<Failure, List<NewsArticle>>(f);
    article = const Left<Failure, NewsArticle>(f);
  }

  void emptyEverything() {
    categories = const Right<Failure, List<NewsCategory>>(<NewsCategory>[]);
    articles = const Right<Failure, NewsPageResult>(NewsPageResult.empty);
    catalogue = const Right<Failure, List<NewsArticle>>(<NewsArticle>[]);
  }

  @override
  Future<Either<Failure, List<NewsCategory>>> getCategories() async {
    categoryCalls++;
    await _wait();
    return categories;
  }

  @override
  Future<Either<Failure, NewsPageResult>> getArticles({
    required int page,
    required int perPage,
    String? category,
  }) async {
    listCalls.add((page: page, perPage: perPage, category: category));
    await _wait();
    return articles;
  }

  @override
  Future<Either<Failure, List<NewsArticle>>> getCatalogue() async {
    catalogueCalls++;
    await _wait();
    return catalogue;
  }

  @override
  Future<Either<Failure, NewsArticle>> getArticle(String slug) async {
    articleSlugs.add(slug);
    await _wait();
    return article;
  }
}

/// A [NewsBloc] over [repository], wired exactly as production wires it.
NewsBloc newsBlocOver(FakeNewsRepository repository) => NewsBloc(
      getNewsCategories: GetNewsCategories(repository: repository),
      getNewsArticles: GetNewsArticles(repository: repository),
    );

/// A [NewsDetailBloc] over [repository], for [slug].
NewsDetailBloc newsDetailBlocOver(
  FakeNewsRepository repository, {
  String slug = kRecordedSlug,
}) =>
    NewsDetailBloc(
      slug: slug,
      getNewsArticle: GetNewsArticle(repository: repository),
      getNewsCatalogue: GetNewsCatalogue(repository: repository),
    );

// ─────────────────────────────────────────────────────────────────────────────
// Pumping
// ─────────────────────────────────────────────────────────────────────────────

/// How long [FakeNewsRepository.latency] is set to when a test wants to observe
/// the loading state.
const Duration kNewsStubLatency = Duration(milliseconds: 500);

Widget _app(Widget page, Locale locale, List<BlocProvider<dynamic>> providers) =>
    wrapWithLocalization(
      startLocale: locale,
      Builder(
        builder: (BuildContext context) => MaterialApp(
          theme: AppTheme.light(),
          localizationsDelegates: context.localizationDelegates,
          supportedLocales: context.supportedLocales,
          locale: context.locale,
          home: MultiBlocProvider(providers: providers, child: page),
        ),
      ),
    );

/// Pumps [NewsPage] under [bloc]. **Does not settle** — several states render a
/// skeleton and the page holds no infinite animation, but a caller that wants
/// the loading frame must be able to stop before the future resolves.
Future<void> pumpNewsPage(
  WidgetTester tester,
  NewsBloc bloc, {
  Locale locale = const Locale('en'),
  Size surface = const Size(390, 3000),
}) async {
  tester.view.devicePixelRatio = 1.0;
  tester.view.physicalSize = surface;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(_app(
    const NewsPage(),
    locale,
    <BlocProvider<dynamic>>[BlocProvider<NewsBloc>.value(value: bloc)],
  ));
  await tester.pump();
}

/// Pumps [NewsDetailPage] under [bloc].
Future<void> pumpNewsDetailPage(
  WidgetTester tester,
  NewsDetailBloc bloc, {
  Locale locale = const Locale('en'),
  Size surface = const Size(390, 3000),
}) async {
  tester.view.devicePixelRatio = 1.0;
  tester.view.physicalSize = surface;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(_app(
    const NewsDetailPage(),
    locale,
    <BlocProvider<dynamic>>[BlocProvider<NewsDetailBloc>.value(value: bloc)],
  ));
  await tester.pump();
}

/// Pumps past any stubbed latency without ever calling `pumpAndSettle` — the
/// pages draw `Image.network`, whose loading future never completes in a test
/// binary, so settling would hang.
Future<void> settleNews(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(kNewsStubLatency + const Duration(milliseconds: 50));
  await tester.pump();
}
