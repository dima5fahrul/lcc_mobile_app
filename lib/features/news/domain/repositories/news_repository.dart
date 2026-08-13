/// News' repository contract — the four reads the two pages fire.
///
/// | Source | Method | Endpoint |
/// |---|---|---|
/// | `NewsPage.tsx:39` | [getCategories] | `GET /news/categories` |
/// | `NewsPage.tsx:43` | [getArticles] | `GET /news` (paged) |
/// | `NewsDetailPage.tsx:70` / `newsData.ts:19` | [getCatalogue] | `GET /news?per_page=100` |
/// | `NewsDetailPage.tsx:73` | [getArticle] | `GET /news/<slug>` |
///
/// All four are `anonymous: true` in `endpoints.ts`, so none carries a token.
///
/// ## The numeric route bridge is NOT ported — and that is the whole of
/// `newsData.ts`
///
/// The web routes an article as `#/news/3`, a **1-based position in the
/// unfiltered catalogue**, and `newsData.ts` exists solely to translate that
/// position to the slug the API is keyed by. Its own header says why the
/// position exists: *"The hash route is numeric … while the API is keyed by
/// slug."* It is a workaround for a hash-router URL scheme, not a product
/// behaviour.
///
/// Flutter has real path parameters, so § 3.1 specifies `/news/:slug` and the
/// slug goes on the wire directly. Porting the bridge would mean fetching 100
/// rows on the list page to compute link targets the router does not need, and
/// would make an article's identity depend on how many articles precede it.
///
/// [getCatalogue] survives that deletion because the **detail page needs the
/// rows for a second reason**: "More news" is
/// `catalogue.filter(n => n.slug !== article.slug).slice(0, 3)`
/// (`NewsDetailPage.tsx:169`). That is data, not routing, so it is kept.
///
/// **Recorded consequence:** the list page therefore does not wait on the
/// catalogue, where the web's loading condition is
/// `list.loading || catalogue.loading` (`NewsPage.tsx:125`). The four states
/// § 6.6 requires are unchanged — this removes a request the Flutter list has
/// no use for, it does not remove a state.
library;

import 'package:dartz/dartz.dart';

import '../../../../core/error/failure.dart';
import '../entities/news_article.dart';
import '../entities/news_category.dart';
import 'news_page_result.dart';

abstract class NewsRepository {
  /// `GET /news/categories` — the filter chips.
  Future<Either<Failure, List<NewsCategory>>> getCategories();

  /// `GET /news?page=&per_page=6[&category=]` — one page of the list.
  ///
  /// [category] is null for "All": `NewsPage.tsx:45` sends
  /// `category: filter === "all" ? undefined : filter`, and `ApiClient`'s
  /// `_buildQuery` drops nulls, so the parameter is absent rather than empty.
  Future<Either<Failure, NewsPageResult>> getArticles({
    required int page,
    required int perPage,
    String? category,
  });

  /// `GET /news?per_page=100` — the unfiltered catalogue, for "More news".
  Future<Either<Failure, List<NewsArticle>>> getCatalogue();

  /// `GET /news/<slug>` — the one read that carries `body` and increments
  /// `view_count` (`newsData.ts:21`).
  Future<Either<Failure, NewsArticle>> getArticle(String slug);
}
