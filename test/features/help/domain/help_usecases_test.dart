/// The help centre's use cases — params normalisation and `helpCategoryMeta`.
///
/// `helpCategoryMeta` is the interesting one: it clamps an unknown category to
/// swatch index 0 while still resolving its icon at the RAW index, and that
/// asymmetry is the source's (`list[index]?.icon` reads `list[-1]`, which is
/// `undefined`, while `index < 0 ? 0 : index` clamps the swatch). It is exactly
/// the boundary a widget test would not think to cover.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:lcc_mobile_app/features/help/domain/entities/help_entities.dart';
import 'package:lcc_mobile_app/features/help/domain/usecases/help_usecases.dart';
import 'package:lcc_mobile_app/presentation/theme/app_colors.dart';

import '../../../helpers/help_test_helper.dart';

void main() {
  group('GetHelpFaqsParams — the two "unset" normalisations, :110', () {
    test('"all" and an empty topic become null', () {
      expect(GetHelpFaqsParams(page: 1).wireCategory, isNull);
      expect(GetHelpFaqsParams(page: 1, category: '').wireCategory, isNull);
      expect(
        GetHelpFaqsParams(page: 1, category: kHelpAllTopics).wireCategory,
        isNull,
      );
    });

    test('a real topic passes through', () {
      expect(
        GetHelpFaqsParams(page: 1, category: 'payments').wireCategory,
        'payments',
      );
    });

    test('an empty or whitespace-only search becomes null', () {
      // `search: search || undefined`. Sending `?search=` would filter to the
      // empty string and return a result set that looks like a real empty.
      expect(GetHelpFaqsParams(page: 1).wireSearch, isNull);
      expect(GetHelpFaqsParams(page: 1, search: '   ').wireSearch, isNull);
    });

    test('a search term is trimmed at construction', () {
      // `useDebounced(query.trim(), 350)` — the trim is upstream of the
      // debounce on the web, so `' x '` and `'x'` are one request there too.
      final GetHelpFaqsParams p =
          GetHelpFaqsParams(page: 1, search: '  refund  ');
      expect(p.search, 'refund');
      expect(p.wireSearch, 'refund');
    });

    test('the default page size is the source\'s 10', () {
      expect(GetHelpFaqsParams(page: 1).perPage, kHelpPerPage);
      expect(kHelpPerPage, 10);
    });

    test('the debounce window is the source\'s 350 ms', () {
      expect(kHelpSearchDebounce, const Duration(milliseconds: 350));
    });

    test('value equality', () {
      expect(
        GetHelpFaqsParams(page: 2, category: 'account', search: 'x'),
        GetHelpFaqsParams(page: 2, category: 'account', search: ' x '),
      );
    });
  });

  group('GetHelpGuideParams', () {
    test('the slug is trimmed', () {
      expect(GetHelpGuideParams('  a-slug ').slug, 'a-slug');
    });
  });

  group('helpCategoryMeta — catMeta(), :132-136', () {
    late List<FaqCategory> topics;

    setUp(() => topics = recordedTopics());

    test('a known code resolves to its position and its icon', () {
      expect(helpCategoryMeta(topics, 'getting-started'),
          (index: 0, icon: 'Rocket'));
      expect(helpCategoryMeta(topics, 'services'),
          (index: 1, icon: 'FileText'));
      expect(helpCategoryMeta(topics, 'payments'), (index: 2, icon: 'Wallet'));
      expect(helpCategoryMeta(topics, 'account'), (index: 3, icon: 'Shield'));
    });

    test('an UNKNOWN code clamps the swatch to 0 and yields no icon', () {
      // `index < 0 ? 0 : index` clamps the swatch, while `list[index]?.icon`
      // reads `list[-1]` → `undefined` → the FileText fallback. The two differ,
      // and the asymmetry is the source's — a question whose category is not in
      // the list wears the first topic's colour rather than disappearing.
      expect(helpCategoryMeta(topics, 'no-such-topic'), (index: 0, icon: ''));
    });

    test('an empty category list is survivable', () {
      expect(helpCategoryMeta(const <FaqCategory>[], 'services'),
          (index: 0, icon: ''));
    });

    test('the clamped index still yields a real swatch', () {
      final ({int index, String icon}) meta =
          helpCategoryMeta(topics, 'no-such-topic');
      expect(AppColors.helpSwatch(meta.index), AppColors.helpPalette.first);
    });
  });

  test('the "all topics" sentinel is the source\'s string', () {
    expect(kHelpAllTopics, 'all');
  });
}
