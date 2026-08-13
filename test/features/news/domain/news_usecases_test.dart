/// News' use cases — the params normalisation and `moreNewsFrom`.
///
/// Five of the six behaviours here are one-line rules that exist in exactly one
/// place *because* they were put in `domain/`, and every one of them is the
/// kind that fails silently: `?category=all` returns an empty list that looks
/// real, and a `.take(4)` where the source says `.slice(0, 3)` is invisible
/// until someone counts the cards.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:lcc_mobile_app/features/news/domain/entities/news_article.dart';
import 'package:lcc_mobile_app/features/news/domain/usecases/news_usecases.dart';

import '../../../helpers/news_test_helper.dart';

void main() {
  group('GetNewsArticlesParams — `filter === "all" ? undefined : filter`', () {
    test('"all" becomes null on the wire', () {
      expect(
        const GetNewsArticlesParams(page: 1, category: kNewsAllCategories)
            .wireCategory,
        isNull,
      );
    });

    test('an empty category becomes null too', () {
      expect(
        const GetNewsArticlesParams(page: 1, category: '').wireCategory,
        isNull,
      );
    });

    test('a real code passes through', () {
      expect(
        const GetNewsArticlesParams(page: 1, category: 'policy').wireCategory,
        'policy',
      );
    });

    test('the default page size is the source\'s 6', () {
      expect(const GetNewsArticlesParams(page: 1).perPage, kNewsPerPage);
      expect(kNewsPerPage, 6);
    });

    test('value equality, so a repeated request is recognisable as one', () {
      expect(
        const GetNewsArticlesParams(page: 2, category: 'policy'),
        const GetNewsArticlesParams(page: 2, category: 'policy'),
      );
      expect(
        const GetNewsArticlesParams(page: 2, category: 'policy'),
        isNot(const GetNewsArticlesParams(page: 3, category: 'policy')),
      );
    });
  });

  group('GetNewsArticleParams', () {
    test('the slug is trimmed at construction', () {
      // `' x '` and `'x'` must not be two spellings of one request that only
      // happen to behave alike — the reason `GetServicesParams` does the same.
      expect(GetNewsArticleParams('  a-slug  ').slug, 'a-slug');
      expect(GetNewsArticleParams('a-slug'), GetNewsArticleParams(' a-slug '));
    });
  });

  group('moreNewsFrom — `.filter(...).slice(0, 3)`, :169', () {
    test('excludes the current article', () {
      final List<NewsArticle> more =
          moreNewsFrom(recordedArticles(), kRecordedSlug);

      expect(more.map((NewsArticle a) => a.slug), isNot(contains(kRecordedSlug)));
    });

    test('takes at most three, from a six-row catalogue', () {
      expect(moreNewsFrom(recordedArticles(), kRecordedSlug), hasLength(3));
      expect(kNewsMoreCount, 3);
    });

    test('preserves server order', () {
      final List<NewsArticle> all = recordedArticles();
      final List<NewsArticle> more = moreNewsFrom(all, kRecordedSlug);
      final List<String> expected = all
          .where((NewsArticle a) => a.slug != kRecordedSlug)
          .take(3)
          .map((NewsArticle a) => a.slug)
          .toList();

      expect(more.map((NewsArticle a) => a.slug), expected);
    });

    test('an empty catalogue yields an empty strip, not a throw', () {
      expect(moreNewsFrom(const <NewsArticle>[], kRecordedSlug), isEmpty);
    });

    test('a catalogue of only this article yields nothing', () {
      expect(moreNewsFrom(<NewsArticle>[recordedDetail()], kRecordedSlug),
          isEmpty);
    });

    test('a slug that is not in the catalogue still caps at three', () {
      expect(moreNewsFrom(recordedArticles(), 'not-in-the-list'), hasLength(3));
    });
  });

  test('the catalogue page size is the source\'s 100', () {
    // `newsData.ts:15`. Kept at the source's number even though the port drops
    // the numeric route bridge: a different page size would ask staging a
    // question the web never asks.
    expect(kNewsCataloguePageSize, 100);
  });
}
