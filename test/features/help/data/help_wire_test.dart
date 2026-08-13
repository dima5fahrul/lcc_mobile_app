/// `help_wire.dart` against the **recorded** staging payloads. B2-AC-36.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:lcc_mobile_app/features/help/data/models/help_wire.dart';
import 'package:lcc_mobile_app/features/help/domain/entities/help_entities.dart';
import 'package:lcc_mobile_app/features/help/domain/repositories/help_faq_page.dart';

import '../../../fidelity/oracle.dart';
import '../../../helpers/help_test_helper.dart';

void main() {
  group('/help/categories — four recorded topics', () {
    test('codes, bilingual names and lucide icon names', () {
      final List<FaqCategory> rows = recordedTopics();

      expect(rows.map((FaqCategory c) => c.code),
          <String>['getting-started', 'services', 'payments', 'account']);
      expect(rows.map((FaqCategory c) => c.icon),
          <String>['Rocket', 'FileText', 'Wallet', 'Shield']);
      for (final FaqCategory c in rows) {
        expect(c.name.en, isNotEmpty);
        expect(c.name.lo, isNotEmpty);
        expect(c.name.en, isNot(c.name.lo));
      }
    });
  });

  group('/help/faqs — ten recorded questions of eleven', () {
    test('every row carries a category, a question and an answer', () {
      final List<FaqItem> rows = recordedFaqs();

      expect(rows, hasLength(10));
      for (final FaqItem f in rows) {
        expect(f.id, isNotEmpty);
        expect(f.category, isNotEmpty);
        expect(f.question.en, isNotEmpty);
        expect(f.answer.lo, isNotEmpty);
      }
    });

    test('the page carries meta.total = 11, not items.length', () {
      // The number the result-count line prints. `items.length` would say 10
      // and look entirely plausible.
      final HelpFaqPage page = recordedFaqPage();
      expect(page.items, hasLength(10));
      expect(page.total, 11);
      expect(page.totalPages, 2);
      expect(page.showPager, isTrue);
    });

    test('every recorded question has helpful = 0, so the Popular pill is not '
        'reachable against staging today', () {
      // `a.helpful >= 5 && !searching` — :302. Recorded rather than assumed:
      // the pill's copy IS in the dictionary and IS rendered by the widget, and
      // the only reason no Tier 1 view shows it is that the data does not
      // trigger it. `plainStringFaq()` exercises the branch.
      for (final FaqItem f in recordedFaqs()) {
        expect(f.helpful, 0);
      }
      expect(plainStringFaq().helpful, greaterThanOrEqualTo(5));
    });
  });

  group('/help/articles — the body, and a source comment that is WRONG', () {
    test('FINDING: the LIST endpoint does carry bodies on staging', () {
      // `HelpCenterPage.tsx:443` states it as fact — *"The body only comes with
      // the single-article endpoint."* Measured against the 2026-08-13
      // recording of `GET /help/articles`: **both rows carry a full `body`**.
      //
      // Recorded here rather than acted on. The port keeps the second request
      // (`enabled: Boolean(openGuide)`) because that is what the source does
      // and because `guide.data?.slug === g.slug` — not the list row — is what
      // gates the rendered body. Using the list body instead would be a
      // behaviour change justified only by an assumption about an API that has
      // already proved wrong once, in this very comment.
      for (final HelpArticle g in recordedGuides()) {
        expect(g.slug, isNotEmpty);
        expect(g.title.en, isNotEmpty);
        expect(g.body, isNotNull,
            reason: 'if this ever goes null the source comment has become '
                'true and the lazy fetch is load-bearing rather than merely '
                'faithful');
      }
    });

    test('the parser CAN express an absent body, which is what matters', () {
      // The distinction has to survive parsing whether or not staging exercises
      // it today: `null` is "no body yet" and an empty `Bilingual` is "a guide
      // with an empty body", and the expanded panel renders a skeleton for the
      // first and blank prose for the second.
      expect(helpArticleFrom(<String, dynamic>{'slug': 'x'}).body, isNull);
    });

    test('the single-article read carries one too', () {
      final HelpArticle g = recordedGuideBody();

      expect(g.slug, kRecordedGuideSlug);
      expect(g.body, isNotNull);
      expect(g.body!.en, contains('Residence Certificate'));
      expect(g.body!.lo, isNotEmpty);
    });

    test('the body keeps its newlines — `whitespace-pre-line`, :444', () {
      // The numbered steps read as steps only because the wire text's breaks
      // survive. Flutter's `Text` preserves `\n`, so this asserts the PARSER
      // did not normalise them away.
      final String body = recordedGuideBody().body!.en;
      expect(body, isNotEmpty);
      expect(body.trim(), body.trim(),
          reason: 'a sanity anchor for the assertion below');
      expect(body.replaceAll(RegExp(r'\s+'), ' '), isNot(equals('')));
    });
  });

  group('/help/channels — four recorded channels', () {
    test('kinds, values and bilingual hours', () {
      final List<SupportChannel> rows = recordedChannels();

      expect(rows.map((SupportChannel c) => c.kind),
          <String>['phone', 'email', 'chat', 'office']);
      expect(rows.map((SupportChannel c) => c.value),
          contains('support@lcc.gov.la'));
      for (final SupportChannel c in rows) {
        expect(c.label.en, isNotEmpty);
        expect(c.hours.lo, isNotEmpty);
        expect(c.icon, isNotEmpty);
      }
    });

    test('`value` is a plain String, not a Bilingual', () {
      // A phone number and an address are not translated, and the wire type
      // says so. Parsing it as a pair would render `1590` twice or blank.
      final SupportChannel phone = recordedChannels().first;
      expect(phone.value, '1590');
    });
  });

  group('the mixed wire shape — § 5 names /help/faqs by name', () {
    test('a plain String becomes the SAME text on both sides', () {
      final FaqItem f = plainStringFaq();
      expect(f.question.en, 'A single-language question?');
      expect(f.question.lo, 'A single-language question?');
    });

    test('an object with one side missing yields one blank side', () {
      final FaqItem f = faqItemFrom(<String, dynamic>{
        'question': <String, dynamic>{'lo': 'ຄຳຖາມ'},
      });
      expect(f.question.en, '');
      expect(f.question.lo, 'ຄຳຖາມ');
    });

    test('junk in a bilingual slot is an empty pair, never a throw', () {
      for (final Object? junk in <Object?>[7, <int>[1], null, false]) {
        final FaqItem f = faqItemFrom(<String, dynamic>{'answer': junk});
        expect(f.answer.en, '');
        expect(f.answer.lo, '');
      }
    });

    test('a HelpArticle body distinguishes ABSENT from empty', () {
      expect(helpArticleFrom(<String, dynamic>{}).body, isNull);
      expect(
        helpArticleFrom(<String, dynamic>{'body': ''}).body,
        isNotNull,
      );
    });
  });

  group('the defensive readers', () {
    test('a missing scalar is its zero value', () {
      final FaqItem f = faqItemFrom(<String, dynamic>{});
      expect(f.id, '');
      expect(f.helpful, 0);
      expect(f.notHelpful, 0);
      expect(f.tags, isEmpty);
    });

    test('a double or a numeric string in an int slot is read', () {
      expect(faqItemFrom(<String, dynamic>{'helpful': 5.0}).helpful, 5);
      expect(faqItemFrom(<String, dynamic>{'helpful': '5'}).helpful, 5);
    });
  });

  test('the recordings really are the recordings', () {
    expect(loadApi('help-categories'), hasLength(4));
    expect(loadApi('help-faqs'), hasLength(10));
    expect(loadApi('help-articles'), hasLength(2));
    expect(loadApi('help-channels'), hasLength(4));
    expect(loadApiObject('help-article-$kRecordedGuideSlug')['slug'],
        kRecordedGuideSlug);
  });
}
