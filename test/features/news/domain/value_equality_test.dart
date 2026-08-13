/// The `props` overrides on B2c's four value types.
///
/// Small, and not busywork: `NewsState` and `HelpState` are `@freezed`, so
/// their generated `==` compares *fields*. A `NewsPageResult` or `HelpFaqPage`
/// without value equality would make every state carrying a freshly-parsed page
/// compare unequal to an identical one — which turns `bloc_test`'s `expect:`
/// into an identity check nobody can satisfy, and makes `BlocBuilder` rebuild
/// on every emission whether or not anything changed.
///
/// The two `Params` types are here for the same reason `GetNewsArticlesParams`'
/// own test gives: a repeated request has to be recognisable as one.
///
/// These were the last eight uncovered lines in `lib/features/{news,help}/**`.
/// Covering them is cheap; leaving them uncovered would mean the property above
/// is asserted nowhere.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:lcc_mobile_app/features/help/domain/repositories/help_faq_page.dart';
import 'package:lcc_mobile_app/features/help/domain/usecases/help_usecases.dart';
import 'package:lcc_mobile_app/features/news/domain/repositories/news_page_result.dart';

import '../../../helpers/help_test_helper.dart';
import '../../../helpers/news_test_helper.dart';

void main() {
  group('NewsPageResult', () {
    test('two independently-parsed identical pages are equal', () {
      expect(recordedPage(), recordedPage());
      expect(recordedPage().hashCode, recordedPage().hashCode);
    });

    test('a different page number makes them unequal', () {
      expect(
        pagedResult(page: 1, totalPages: 3),
        isNot(pagedResult(page: 2, totalPages: 3)),
      );
    });

    test('the empty page is not equal to a populated one', () {
      expect(NewsPageResult.empty, isNot(recordedPage()));
      expect(NewsPageResult.empty, NewsPageResult.empty);
    });
  });

  group('HelpFaqPage', () {
    test('two independently-parsed identical pages are equal', () {
      expect(recordedFaqPage(), recordedFaqPage());
      expect(recordedFaqPage().hashCode, recordedFaqPage().hashCode);
    });

    test('`total` participates in equality — it is what the count line prints',
        () {
      final HelpFaqPage a = recordedFaqPage();
      final HelpFaqPage b = HelpFaqPage(
        items: a.items,
        page: a.page,
        totalPages: a.totalPages,
        total: a.total + 1,
        hasNext: a.hasNext,
        hasPrev: a.hasPrev,
      );
      expect(a, isNot(b));
    });

    test('the empty page equals itself and nothing else', () {
      expect(HelpFaqPage.empty, HelpFaqPage.empty);
      expect(HelpFaqPage.empty, isNot(recordedFaqPage()));
    });
  });

  group('the two help Params types', () {
    test('GetHelpGuideParams compares by slug, after trimming', () {
      expect(GetHelpGuideParams('a'), GetHelpGuideParams(' a '));
      expect(GetHelpGuideParams('a'), isNot(GetHelpGuideParams('b')));
      expect(GetHelpGuideParams('a').hashCode, GetHelpGuideParams('a').hashCode);
    });

    test('SendFaqFeedbackParams compares by id AND direction', () {
      expect(
        const SendFaqFeedbackParams(id: 'x', helpful: true),
        const SendFaqFeedbackParams(id: 'x', helpful: true),
      );
      expect(
        const SendFaqFeedbackParams(id: 'x', helpful: true),
        isNot(const SendFaqFeedbackParams(id: 'x', helpful: false)),
        reason: 'a thumbs-up and a thumbs-down on the same question are two '
            'different requests, not one repeated',
      );
      expect(
        const SendFaqFeedbackParams(id: 'x', helpful: true),
        isNot(const SendFaqFeedbackParams(id: 'y', helpful: true)),
      );
    });
  });
}
