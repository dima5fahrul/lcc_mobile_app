/// `news_wire.dart` against the **recorded** staging payloads. B2-AC-36.
///
/// The criterion asks for mixed wire shapes *"proven against real recorded
/// staging payloads in a fixture, not hand-written JSON"*. B2c recorded all
/// seven content endpoints, so every assertion below that is about the wire
/// runs over a recording; the two that are about a shape the recording does not
/// contain say so at the call site.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:lcc_mobile_app/features/news/data/models/news_wire.dart';
import 'package:lcc_mobile_app/features/news/domain/entities/news_article.dart';
import 'package:lcc_mobile_app/features/news/domain/entities/news_category.dart';

import '../../../fidelity/oracle.dart';
import '../../../helpers/news_test_helper.dart';

void main() {
  group('the recorded /news payload parses through the production parser', () {
    test('six rows, every one with a slug and a bilingual title', () {
      final List<NewsArticle> rows = recordedArticles();

      expect(rows, hasLength(6));
      for (final NewsArticle a in rows) {
        expect(a.slug, isNotEmpty);
        expect(a.title.en, isNotEmpty);
        expect(a.title.lo, isNotEmpty);
        expect(a.title.en, isNot(a.title.lo),
            reason: 'a row whose two sides are equal would mean the parser '
                'collapsed an {en,lo} object into a plain string');
      }
    });

    test('a LIST row carries no body — that is what makes the excerpt '
        'fallback reachable', () {
      for (final NewsArticle a in recordedArticles()) {
        expect(a.body, isNull);
        expect(a.paragraphs('en'), isEmpty);
      }
    });

    test('the DETAIL row does carry one, and it splits into paragraphs', () {
      final NewsArticle a = recordedDetail();

      expect(a.body, isNotNull);
      expect(a.paragraphs('en'), isNotEmpty);
      expect(a.paragraphs('lo'), isNotEmpty);
      // `.split("\n").map(trim).filter(Boolean)` — no empty paragraph survives.
      expect(a.paragraphs('en').any((String p) => p.trim().isEmpty), isFalse);
    });

    test('tags, counts and flags come off the wire, not off defaults', () {
      final NewsArticle a = recordedDetail();

      expect(a.tags, isNotEmpty);
      expect(a.readMinutes, greaterThan(0));
      expect(a.featured, isTrue);
      expect(a.category, 'announcement');
      expect(a.categoryColor, startsWith('#'));
    });

    test('publishedOn prefers published_date, then published_at', () {
      // `item.published_date || item.published_at` — HomePage.tsx:684's
      // precedence, and NewsPage.tsx:183 / NewsDetailPage.tsx:209 pass the
      // former. Both are kept so the fallback is expressible.
      expect(recordedDetail().publishedOn, recordedDetail().publishedDate);

      final NewsArticle onlyTimestamp = newsArticleFrom(<String, dynamic>{
        'published_at': '2026-09-01T00:00:00Z',
      });
      expect(onlyTimestamp.publishedOn, '2026-09-01T00:00:00Z');
    });
  });

  group('the recorded /news/categories payload', () {
    test('four rows, each with a code and a colour', () {
      final List<NewsCategory> rows = recordedCategories();

      expect(rows.map((NewsCategory c) => c.code),
          <String>['announcement', 'service', 'policy', 'event']);
      for (final NewsCategory c in rows) {
        expect(c.color, matches(RegExp(r'^#[0-9A-Fa-f]{6}$')));
      }
    });

    test('server order is preserved — no client re-sort (B2-AC-35)', () {
      // SSD § 11.2 L-3/L-4 generalise: the API returns `sort_order` and the web
      // applies none of its own.
      final List<int> order = loadApi('news-categories')
          .map((Map<String, dynamic> r) => r['sort_order'] as int)
          .toList();
      final List<int> sorted = <int>[...order]..sort();
      expect(order, sorted,
          reason: 'the recording is already in server order; if it were not, '
              'this test would be asserting the wrong invariant');
    });
  });

  group('the mixed wire shape — § 5, the branch the recording does not have',
      () {
    test('a plain String becomes the SAME text on both sides', () {
      // Faithful, not a shortcut: `text(value, lang)` falls back
      // `wanted || en || lo || ""`, so a single-language field already renders
      // the same text in either locale on the web.
      final NewsArticle a = plainStringArticle();

      expect(a.title.en, 'A single-language headline');
      expect(a.title.lo, 'A single-language headline');
      expect(a.categoryName.en, 'Notice');
      expect(a.categoryName.lo, 'Notice');
    });

    test('an {en,lo} object with one side missing yields one blank side', () {
      // A half-populated pair renders one language blank, which is visible and
      // diagnosable; a thrown parse error takes the whole page down over one
      // field.
      final NewsArticle a = newsArticleFrom(<String, dynamic>{
        'title': <String, dynamic>{'en': 'Only English'},
      });
      expect(a.title.en, 'Only English');
      expect(a.title.lo, '');
    });

    test('a number, a list or a null in a bilingual slot is an empty pair', () {
      for (final Object? junk in <Object?>[42, <String>['a'], null, true]) {
        final NewsArticle a =
            newsArticleFrom(<String, dynamic>{'title': junk});
        expect(a.title.en, '');
        expect(a.title.lo, '');
      }
    });

    test('body distinguishes ABSENT from empty', () {
      // The distinction the detail page acts on: null means "this row came
      // from a list endpoint", which an empty `Bilingual` could not express.
      expect(newsArticleFrom(<String, dynamic>{}).body, isNull);
      expect(
        newsArticleFrom(<String, dynamic>{'body': <String, dynamic>{}}).body,
        isNotNull,
      );
    });
  });

  group('the defensive readers', () {
    test('a missing scalar is its zero value, never a throw', () {
      final NewsArticle a = newsArticleFrom(<String, dynamic>{});
      expect(a.id, '');
      expect(a.viewCount, 0);
      expect(a.featured, isFalse);
      expect(a.tags, isEmpty);
    });

    test('a double in an int slot rounds — JSON has one number type', () {
      expect(
        newsArticleFrom(<String, dynamic>{'read_minutes': 3.0}).readMinutes,
        3,
      );
      expect(
        newsArticleFrom(<String, dynamic>{'view_count': '17'}).viewCount,
        17,
      );
    });

    test('a tags array with non-strings drops the bad elements only', () {
      expect(
        newsArticleFrom(<String, dynamic>{
          'tags': <Object?>['service', 42, null, 'policy'],
        }).tags,
        <String>['service', 'policy'],
      );
    });
  });
}
