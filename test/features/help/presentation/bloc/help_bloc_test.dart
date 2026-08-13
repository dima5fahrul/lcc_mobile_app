/// `HelpBloc` — five regions, one debounce, one optimistic write.
///
/// Every BLoC is constructed **inside the test body**: `setUp` runs outside the
/// test's zone and a BLoC built there owns an event queue nothing drains.
library;

import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lcc_mobile_app/core/error/failure.dart';
import 'package:lcc_mobile_app/features/help/domain/entities/help_entities.dart';
import 'package:lcc_mobile_app/features/help/domain/usecases/help_usecases.dart';
import 'package:lcc_mobile_app/features/help/presentation/bloc/help_bloc.dart';

import '../../../../helpers/help_test_helper.dart';

/// Lets the microtask queue drain, plus [extra] of wall-clock.
Future<void> tick([Duration extra = Duration.zero]) =>
    Future<void>.delayed(extra);

void main() {
  group('mount — four reads, five regions', () {
    test('the initial state reads as loading everywhere', () async {
      final HelpBloc bloc = helpBlocOver(FakeHelpRepository());
      addTearDown(bloc.close);

      expect(bloc.state.categoriesLoading, isTrue);
      expect(bloc.state.faqsLoading, isTrue);
      expect(bloc.state.guidesLoading, isTrue);
      expect(bloc.state.channelsLoading, isTrue);
      // …and NOT as empty, which is the distinction `initial` exists for.
      expect(bloc.state.faqsEmpty, isFalse);
      expect(bloc.state.guidesEmpty, isFalse);
    });

    test('HelpStarted fires exactly four reads — the guide body is lazy',
        () async {
      final FakeHelpRepository repository = FakeHelpRepository();
      final HelpBloc bloc = helpBlocOver(repository);
      addTearDown(bloc.close);

      bloc.add(const HelpStarted());
      await tick();

      expect(repository.categoryCalls, 1);
      expect(repository.faqCalls, hasLength(1));
      expect(repository.guidesCalls, 1);
      expect(repository.channelCalls, 1);
      expect(repository.guideSlugs, isEmpty,
          reason: '`enabled: Boolean(openGuide)` — :117-119');
    });

    test('the recorded page lands with meta.total, not items.length', () async {
      final HelpBloc bloc = helpBlocOver(FakeHelpRepository());
      addTearDown(bloc.close);

      bloc.add(const HelpStarted());
      await tick();

      expect(bloc.state.faqs.items, hasLength(10));
      expect(bloc.state.faqs.total, 11);
      expect(bloc.state.showPager, isTrue);
    });

    test('the five regions fail INDEPENDENTLY', () async {
      final FakeHelpRepository repository = FakeHelpRepository()
        ..channels = const Left<Failure, List<SupportChannel>>(Failure('x'));
      final HelpBloc bloc = helpBlocOver(repository);
      addTearDown(bloc.close);

      bloc.add(const HelpStarted());
      await tick();

      expect(bloc.state.channelsFailed, isTrue);
      expect(bloc.state.faqsFailed, isFalse);
      expect(bloc.state.guidesFailed, isFalse);
      expect(bloc.state.categoriesFailed, isFalse);
    });

    test('an empty result is the EMPTY state, not a failure (B2-AC-16)',
        () async {
      final FakeHelpRepository repository = FakeHelpRepository()
        ..emptyEverything();
      final HelpBloc bloc = helpBlocOver(repository);
      addTearDown(bloc.close);

      bloc.add(const HelpStarted());
      await tick();

      expect(bloc.state.faqsEmpty, isTrue);
      expect(bloc.state.guidesEmpty, isTrue);
      expect(bloc.state.channelsEmpty, isTrue);
      expect(bloc.state.faqsFailed, isFalse);
    });
  });

  group('the debounced search', () {
    test('six keystrokes make ONE request, with the LAST term', () async {
      final FakeHelpRepository repository = FakeHelpRepository();
      final HelpBloc bloc = helpBlocOver(repository);
      addTearDown(bloc.close);

      bloc.add(const HelpStarted());
      await tick();
      final int before = repository.faqCalls.length;

      for (final String q in <String>['r', 're', 'ref', 'refu', 'refun', 'refund']) {
        bloc.add(HelpSearchChanged(q));
        await tick();
      }
      // Still nothing: the window has not elapsed.
      expect(repository.faqCalls.length, before);

      await tick(kHelpSearchDebounce + const Duration(milliseconds: 20));
      await tick();

      expect(repository.faqCalls.length, before + 1);
      expect(repository.faqCalls.last.search, 'refund');
    });

    test('the FIELD moves immediately, ahead of the request', () async {
      final HelpBloc bloc = helpBlocOver(FakeHelpRepository());
      addTearDown(bloc.close);

      bloc.add(const HelpStarted());
      await tick();
      bloc.add(const HelpSearchChanged('ref'));
      await tick();

      expect(bloc.state.query, 'ref');
      expect(bloc.state.debouncedQuery, '',
          reason: '`useDebounced(query.trim(), 350)` debounces the QUERY '
              'PARAMETER, not the input value');
      expect(bloc.state.searching, isTrue);
    });

    test('typing resets to page 1 on every keystroke, not on the request',
        () async {
      // `setPage(1)` sits in the input's onChange (:186). Otherwise a citizen
      // on page 3 who starts typing would see "3 / 3" until the request landed.
      final FakeHelpRepository repository = FakeHelpRepository();
      final HelpBloc bloc = helpBlocOver(repository);
      addTearDown(bloc.close);

      bloc.add(const HelpStarted());
      await tick();
      bloc.add(const HelpNextPage());
      await tick();
      bloc.add(const HelpSearchChanged('r'));
      await tick();

      expect(bloc.state.page, 1);
    });

    test('clearing cancels a pending debounce', () async {
      // Otherwise the search that was just removed would land a moment later
      // and repopulate the list under the citizen's finger.
      final FakeHelpRepository repository = FakeHelpRepository();
      final HelpBloc bloc = helpBlocOver(repository);
      addTearDown(bloc.close);

      bloc.add(const HelpStarted());
      await tick();
      bloc.add(const HelpSearchChanged('refund'));
      await tick();
      bloc.add(const HelpSearchCleared());
      await tick();
      await tick(kHelpSearchDebounce + const Duration(milliseconds: 20));
      await tick();

      expect(bloc.state.query, '');
      expect(repository.faqCalls.last.search, isNull);
      expect(
        repository.faqCalls.where((({int page, String? category, String? search}) c) =>
            c.search == 'refund'),
        isEmpty,
      );
    });

    test('a stale debounced event is dropped', () async {
      final FakeHelpRepository repository = FakeHelpRepository();
      final HelpBloc bloc = helpBlocOver(repository);
      addTearDown(bloc.close);

      bloc.add(const HelpStarted());
      await tick();
      final int before = repository.faqCalls.length;

      // Dispatched by hand with a term that no longer matches the field.
      bloc.add(const HelpSearchDebounced('stale'));
      await tick();

      expect(repository.faqCalls.length, before);
    });

    test('closing the bloc cancels the timer', () async {
      final FakeHelpRepository repository = FakeHelpRepository();
      final HelpBloc bloc = helpBlocOver(repository);

      bloc.add(const HelpStarted());
      await tick();
      bloc.add(const HelpSearchChanged('x'));
      await tick();
      await bloc.close();
      await tick(kHelpSearchDebounce + const Duration(milliseconds: 20));

      // No `Bad state: Cannot add new events after calling close`.
      expect(repository.faqCalls.last.search, isNull);
    });
  });

  group('the topic filter and the pager', () {
    test('picking a topic sends its code and resets to page 1', () async {
      final FakeHelpRepository repository = FakeHelpRepository();
      final HelpBloc bloc = helpBlocOver(repository);
      addTearDown(bloc.close);

      bloc.add(const HelpStarted());
      await tick();
      bloc.add(const HelpTopicPicked('payments'));
      await tick();

      expect(repository.faqCalls.last.category, 'payments');
      expect(repository.faqCalls.last.page, 1);
    });

    test('"All topics" sends NULL, not "all"', () async {
      final FakeHelpRepository repository = FakeHelpRepository();
      final HelpBloc bloc = helpBlocOver(repository);
      addTearDown(bloc.close);

      bloc.add(const HelpStarted());
      await tick();
      bloc.add(const HelpTopicPicked(kHelpAllTopics));
      await tick();

      expect(repository.faqCalls.last.category, isNull);
    });

    test('a topic change KEEPS the search term', () async {
      // Two independent filters on one list; resetting one from the other
      // would silently widen the result set.
      final FakeHelpRepository repository = FakeHelpRepository();
      final HelpBloc bloc = helpBlocOver(repository);
      addTearDown(bloc.close);

      bloc.add(const HelpStarted());
      await tick();
      bloc.add(const HelpSearchChanged('fee'));
      await tick(kHelpSearchDebounce + const Duration(milliseconds: 20));
      await tick();
      bloc.add(const HelpTopicPicked('payments'));
      await tick();

      expect(repository.faqCalls.last.search, 'fee');
      expect(repository.faqCalls.last.category, 'payments');
    });

    test('previous clamps at 1', () async {
      final FakeHelpRepository repository = FakeHelpRepository();
      final HelpBloc bloc = helpBlocOver(repository);
      addTearDown(bloc.close);

      bloc.add(const HelpStarted());
      await tick();
      bloc.add(const HelpPreviousPage());
      await tick();

      expect(repository.faqCalls.last.page, 1);
    });
  });

  group('the two accordions', () {
    test('one question open at a time, and a second tap closes it', () async {
      final HelpBloc bloc = helpBlocOver(FakeHelpRepository());
      addTearDown(bloc.close);

      bloc.add(const HelpStarted());
      await tick();
      final List<FaqItem> rows = recordedFaqs();

      bloc.add(HelpFaqToggled(rows[0].id));
      await tick();
      expect(bloc.state.openFaqId, rows[0].id);

      bloc.add(HelpFaqToggled(rows[1].id));
      await tick();
      expect(bloc.state.openFaqId, rows[1].id);

      bloc.add(HelpFaqToggled(rows[1].id));
      await tick();
      expect(bloc.state.openFaqId, isNull);
    });

    test('expanding a guide fetches its body ONCE and caches it', () async {
      // `guide.data?.slug === g.slug` (:442) means a re-expand renders the
      // cached body immediately; re-fetching would show a skeleton for content
      // already in hand.
      final FakeHelpRepository repository = FakeHelpRepository();
      final HelpBloc bloc = helpBlocOver(repository);
      addTearDown(bloc.close);

      bloc.add(const HelpStarted());
      await tick();

      bloc.add(const HelpGuideToggled(kRecordedGuideSlug));
      await tick();
      expect(repository.guideSlugs, <String>[kRecordedGuideSlug]);
      expect(bloc.state.bodyIsFor(kRecordedGuideSlug), isTrue);

      bloc.add(const HelpGuideToggled(kRecordedGuideSlug));
      await tick();
      expect(bloc.state.openGuideSlug, isNull);

      bloc.add(const HelpGuideToggled(kRecordedGuideSlug));
      await tick();
      expect(repository.guideSlugs, hasLength(1),
          reason: 're-expanding the SAME guide must not re-fetch');
    });

    test('expanding a DIFFERENT guide does fetch', () async {
      final FakeHelpRepository repository = FakeHelpRepository();
      final HelpBloc bloc = helpBlocOver(repository);
      addTearDown(bloc.close);

      bloc.add(const HelpStarted());
      await tick();
      bloc.add(const HelpGuideToggled(kRecordedGuideSlug));
      await tick();
      bloc.add(HelpGuideToggled(recordedGuides().last.slug));
      await tick();

      expect(repository.guideSlugs, hasLength(2));
    });

    test('a failed body is scoped to the open guide', () async {
      final FakeHelpRepository repository = FakeHelpRepository()
        ..guide = const Left<Failure, HelpArticle>(Failure('boom'));
      final HelpBloc bloc = helpBlocOver(repository);
      addTearDown(bloc.close);

      bloc.add(const HelpStarted());
      await tick();
      bloc.add(const HelpGuideToggled(kRecordedGuideSlug));
      await tick();

      expect(bloc.state.guideBodyFailed, isTrue);
      expect(bloc.state.guidesFailed, isFalse,
          reason: 'the LIST of guides is fine; only this one body failed');
    });

    test('a body retry re-asks for the open guide', () async {
      final FakeHelpRepository repository = FakeHelpRepository()
        ..guide = const Left<Failure, HelpArticle>(Failure('boom'));
      final HelpBloc bloc = helpBlocOver(repository);
      addTearDown(bloc.close);

      bloc.add(const HelpStarted());
      await tick();
      bloc.add(const HelpGuideToggled(kRecordedGuideSlug));
      await tick();

      repository.guide = Right<Failure, HelpArticle>(recordedGuideBody());
      bloc.add(const HelpGuideRetried());
      await tick();

      expect(repository.guideSlugs, hasLength(2));
      expect(bloc.state.bodyIsFor(kRecordedGuideSlug), isTrue);
    });

    test('a body retry with nothing open is a no-op', () async {
      final FakeHelpRepository repository = FakeHelpRepository();
      final HelpBloc bloc = helpBlocOver(repository);
      addTearDown(bloc.close);

      bloc.add(const HelpStarted());
      await tick();
      bloc.add(const HelpGuideRetried());
      await tick();

      expect(repository.guideSlugs, isEmpty);
    });
  });

  group('the vote — optimistic, and NOT rolled back', () {
    test('the thanks appears before the request resolves', () async {
      final FakeHelpRepository repository = FakeHelpRepository()
        ..latency = const Duration(milliseconds: 50);
      final HelpBloc bloc = helpBlocOver(repository);
      addTearDown(bloc.close);

      bloc.add(HelpFaqVoted(id: 'faq-1', helpful: true));
      await tick();

      expect(bloc.state.votes['faq-1'], isTrue);
    });

    test('a FAILED vote leaves the thanks in place', () async {
      // The source's own decision, with its own reason at :143-145: "A failed
      // vote is not worth interrupting the reader; leave the thanks in place
      // rather than flipping the row back under their finger."
      final FakeHelpRepository repository = FakeHelpRepository()
        ..feedback = const Left<Failure, Unit>(Failure('offline'));
      final HelpBloc bloc = helpBlocOver(repository);
      addTearDown(bloc.close);

      bloc.add(HelpFaqVoted(id: 'faq-1', helpful: false));
      await tick();

      expect(bloc.state.votes['faq-1'], isFalse);
      expect(repository.votes, <({String id, bool helpful})>[
        (id: 'faq-1', helpful: false),
      ]);
    });

    test('a vote on one question does not mark another', () async {
      final HelpBloc bloc = helpBlocOver(FakeHelpRepository());
      addTearDown(bloc.close);

      bloc.add(HelpFaqVoted(id: 'a', helpful: true));
      await tick();
      bloc.add(HelpFaqVoted(id: 'b', helpful: false));
      await tick();

      expect(bloc.state.votes, <String, bool>{'a': true, 'b': false});
    });
  });

  group('retries', () {
    test('each retry re-asks for ITS region only', () async {
      final FakeHelpRepository repository = FakeHelpRepository();
      final HelpBloc bloc = helpBlocOver(repository);
      addTearDown(bloc.close);

      bloc.add(const HelpStarted());
      await tick();

      bloc.add(const HelpCategoriesRetried());
      await tick();
      expect(repository.categoryCalls, 2);
      expect(repository.guidesCalls, 1);
      expect(repository.channelCalls, 1);

      bloc.add(const HelpGuidesRetried());
      await tick();
      expect(repository.guidesCalls, 2);
      expect(repository.channelCalls, 1);

      bloc.add(const HelpChannelsRetried());
      await tick();
      expect(repository.channelCalls, 2);
    });

    test('a question retry keeps the topic, the search and the page', () async {
      final FakeHelpRepository repository = FakeHelpRepository();
      final HelpBloc bloc = helpBlocOver(repository);
      addTearDown(bloc.close);

      bloc.add(const HelpStarted());
      await tick();
      bloc.add(const HelpTopicPicked('services'));
      await tick();
      bloc.add(const HelpSearchChanged('doc'));
      await tick(kHelpSearchDebounce + const Duration(milliseconds: 20));
      await tick();
      bloc.add(const HelpFaqsRetried());
      await tick();

      expect(repository.faqCalls.last.category, 'services');
      expect(repository.faqCalls.last.search, 'doc');
    });
  });
}
