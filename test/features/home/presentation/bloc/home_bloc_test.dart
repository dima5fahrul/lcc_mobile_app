/// `HomeBloc` — five regions, five statuses, and the two that are auth-gated.
///
/// The four-state contract (§ 6.6, **B2-AC-16**) is asserted here at the state
/// level and again in `home_page_test.dart` at the render level. Both matter
/// and neither substitutes: a BLoC can hold `RegionStatus.failure` while the
/// page draws nothing for it, and a page can draw an error panel from a state
/// that never failed.
library;

import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lcc_mobile_app/core/error/failure.dart';
import 'package:lcc_mobile_app/features/home/domain/entities/digital_id_card.dart';
import 'package:lcc_mobile_app/features/home/domain/entities/home_news_item.dart';
import 'package:lcc_mobile_app/features/home/domain/entities/home_summary.dart';
import 'package:lcc_mobile_app/features/home/domain/usecases/home_usecases.dart';
import 'package:lcc_mobile_app/features/home/presentation/bloc/home_bloc.dart';
import 'package:lcc_mobile_app/features/service/domain/entities/service.dart';

import '../../../../helpers/home_test_helper.dart';

void main() {
  late FakeHomeRepository repository;

  setUp(() => repository = FakeHomeRepository());

  group('HomeStarted — the three ANONYMOUS reads, and only those', () {
    blocTest<HomeBloc, HomeState>(
      'loads services, news and FAQs',
      build: () => homeBlocOver(repository),
      act: (HomeBloc bloc) => bloc.add(const HomeStarted()),
      verify: (_) {
        expect(repository.phase1Calls, 1);
        expect(repository.newsCalls, 1);
        expect(repository.faqCalls, 1);
      },
    );

    blocTest<HomeBloc, HomeState>(
      'and does NOT touch /me/* — those are enabled: isAuthenticated',
      build: () => homeBlocOver(repository),
      act: (HomeBloc bloc) => bloc.add(const HomeStarted()),
      verify: (_) {
        // The whole point of § 6.6's "signed out, they are in neither loading
        // nor error but simply absent" (manifest F-4). A mount that fetched
        // them anyway would 401 and paint an error panel on a page that is
        // working correctly.
        expect(repository.summaryCalls, 0);
        expect(repository.digitalIdCalls, 0);
      },
    );

    blocTest<HomeBloc, HomeState>(
      'emits loading for all three, then success with the rows',
      build: () => homeBlocOver(repository),
      act: (HomeBloc bloc) => bloc.add(const HomeStarted()),
      expect: () => <Matcher>[
        isA<HomeState>()
            .having((HomeState s) => s.servicesStatus, 'services',
                RegionStatus.loading)
            .having((HomeState s) => s.newsStatus, 'news', RegionStatus.loading)
            .having((HomeState s) => s.faqStatus, 'faq', RegionStatus.loading),
        isA<HomeState>()
            .having((HomeState s) => s.servicesStatus, 'services',
                RegionStatus.success)
            .having((HomeState s) => s.quickActions.length, 'quick actions', 6)
            .having((HomeState s) => s.news.length, 'news', 3)
            .having((HomeState s) => s.faqs.length, 'faqs', 5),
      ],
    );

    blocTest<HomeBloc, HomeState>(
      'one region failing does not take the others down',
      // The reason the statuses are not collapsed into one. `HomePage` stacks
      // four independently-fetched sections; a citizen whose news request
      // failed still sees their services.
      build: () {
        repository.news =
            const Left<Failure, List<HomeNewsItem>>(Failure('news down'));
        return homeBlocOver(repository);
      },
      act: (HomeBloc bloc) => bloc.add(const HomeStarted()),
      verify: (HomeBloc bloc) {
        expect(bloc.state.newsStatus, RegionStatus.failure);
        expect(bloc.state.servicesStatus, RegionStatus.success);
        expect(bloc.state.faqStatus, RegionStatus.success);
        expect(bloc.state.quickActions, hasLength(6));
      },
    );

    blocTest<HomeBloc, HomeState>(
      'an empty success is success, not failure — the fourth state',
      build: () {
        repository.emptyEverything();
        return homeBlocOver(repository);
      },
      act: (HomeBloc bloc) => bloc.add(const HomeStarted()),
      verify: (HomeBloc bloc) {
        // "An empty list or dropdown is never an acceptable rendering of a
        // failed fetch" (B2-AC-16) — and the converse: an empty result must
        // not be reported as a failure either.
        expect(bloc.state.servicesStatus, RegionStatus.success);
        expect(bloc.state.quickActions, isEmpty);
        expect(bloc.state.newsStatus, RegionStatus.success);
        expect(bloc.state.faqStatus, RegionStatus.success);
      },
    );
  });

  group('HomeAuthChanged — the two authenticated regions', () {
    blocTest<HomeBloc, HomeState>(
      'signing in fetches the summary and the digital ID, concurrently',
      build: () => homeBlocOver(repository),
      act: (HomeBloc bloc) =>
          bloc.add(const HomeAuthChanged(isAuthenticated: true)),
      expect: () => <Matcher>[
        isA<HomeState>()
            .having((HomeState s) => s.isAuthenticated, 'authed', true)
            .having((HomeState s) => s.summaryStatus, 'summary',
                RegionStatus.loading)
            .having((HomeState s) => s.digitalIdStatus, 'id',
                RegionStatus.loading),
        isA<HomeState>()
            .having((HomeState s) => s.summaryStatus, 'summary',
                RegionStatus.success)
            .having((HomeState s) => s.summary?.name, 'name', 'Bounmy Sisavath')
            .having((HomeState s) => s.digitalId?.uin, 'uin',
                '1-2540-08842-99'),
      ],
      verify: (_) {
        expect(repository.summaryCalls, 1);
        expect(repository.digitalIdCalls, 1);
      },
    );

    blocTest<HomeBloc, HomeState>(
      'signing out clears both regions back to initial — no residue',
      // Not merely hidden by a widget condition: the previous citizen's UIN
      // and wallet balance must be gone from the STATE. A container-scoped
      // BLoC plus a widget-level `if (isAuthenticated)` would keep them in
      // memory across a sign-out.
      build: () => homeBlocOver(repository),
      seed: () => HomeState(
        isAuthenticated: true,
        summaryStatus: RegionStatus.success,
        summary: tHomeSummary(),
        digitalIdStatus: RegionStatus.success,
        digitalId: tDigitalId,
      ),
      act: (HomeBloc bloc) =>
          bloc.add(const HomeAuthChanged(isAuthenticated: false)),
      verify: (HomeBloc bloc) {
        expect(bloc.state.isAuthenticated, isFalse);
        expect(bloc.state.summary, isNull);
        expect(bloc.state.digitalId, isNull);
        expect(bloc.state.summaryStatus, RegionStatus.initial);
        expect(bloc.state.digitalIdStatus, RegionStatus.initial);
        expect(repository.summaryCalls, 0, reason: 'and it made no request');
      },
    );

    blocTest<HomeBloc, HomeState>(
      'initial is the signed-out state — absent, not loading, not an error',
      build: () => homeBlocOver(repository),
      verify: (HomeBloc bloc) {
        expect(bloc.state.summaryStatus, RegionStatus.initial);
        expect(bloc.state.showSummaryTiles, isFalse);
        expect(bloc.state.showActionBanner, isFalse);
      },
    );

    blocTest<HomeBloc, HomeState>(
      'a failing summary is a failure state, and the ID is unaffected',
      build: () {
        repository.summary =
            const Left<Failure, HomeSummary>(Failure('403'));
        return homeBlocOver(repository);
      },
      act: (HomeBloc bloc) =>
          bloc.add(const HomeAuthChanged(isAuthenticated: true)),
      verify: (HomeBloc bloc) {
        expect(bloc.state.summaryStatus, RegionStatus.failure);
        expect(bloc.state.digitalIdStatus, RegionStatus.success);
        expect(bloc.state.showSummaryTiles, isFalse);
      },
    );

    blocTest<HomeBloc, HomeState>(
      'the summary retry refetches, and only when signed in',
      build: () => homeBlocOver(repository),
      seed: () => const HomeState(isAuthenticated: true),
      act: (HomeBloc bloc) => bloc.add(const HomeSummaryRetried()),
      verify: (_) => expect(repository.summaryCalls, 1),
    );

    blocTest<HomeBloc, HomeState>(
      'a retry dispatched after a sign-out makes no authenticated request',
      // Guards the race between the panel's disposal and a queued tap.
      build: () => homeBlocOver(repository),
      act: (HomeBloc bloc) => bloc.add(const HomeSummaryRetried()),
      expect: () => <Matcher>[],
      verify: (_) => expect(repository.summaryCalls, 0),
    );
  });

  group('the action banner — HomePage.tsx:393', () {
    test('it needs all three of authenticated, visible and a next_action', () {
      const HomeState base = HomeState();
      expect(base.showActionBanner, isFalse);

      final HomeState authedNoAction = base.copyWith(
        isAuthenticated: true,
        summary: tHomeSummary(),
      );
      expect(authedNoAction.showActionBanner, isFalse,
          reason: 'a summary with next_action: null must not paint an empty '
              'amber banner');

      final HomeState withAction = authedNoAction.copyWith(
        summary: tHomeSummary(nextAction: tNextAction),
      );
      expect(withAction.showActionBanner, isTrue);

      expect(
        withAction.copyWith(bannerVisible: false).showActionBanner,
        isFalse,
      );
      expect(
        withAction.copyWith(isAuthenticated: false).showActionBanner,
        isFalse,
      );
    });

    blocTest<HomeBloc, HomeState>(
      'dismissing hides it for the visit',
      build: () => homeBlocOver(repository),
      act: (HomeBloc bloc) => bloc.add(const HomeBannerDismissed()),
      expect: () => <Matcher>[
        isA<HomeState>().having((HomeState s) => s.bannerVisible, 'visible',
            false),
      ],
    );
  });

  group('search — the grid mode, the debounce and the two empties', () {
    test('gridMode flips on a trimmed query, not on whitespace', () {
      const HomeState blank = HomeState(searchQuery: '   ');
      expect(blank.query, '');
      expect(blank.gridMode, ServiceGridMode.quickActions);

      const HomeState typed = HomeState(searchQuery: ' cert ');
      expect(typed.query, 'cert');
      expect(typed.gridMode, ServiceGridMode.search);
    });

    blocTest<HomeBloc, HomeState>(
      'six keystrokes make ONE request, with the last query',
      build: () => homeBlocOver(repository),
      act: (HomeBloc bloc) async {
        for (final String q in <String>['c', 'ce', 'cer', 'cert']) {
          bloc.add(HomeSearchChanged(q));
          await Future<void>.delayed(const Duration(milliseconds: 40));
        }
      },
      wait: kHomeSearchDebounce + const Duration(milliseconds: 100),
      verify: (_) {
        // Not a call count alone: "one request" and "one request for the query
        // the citizen actually finished typing" are different claims, and only
        // the second is the behaviour.
        expect(repository.searchQueries, <String>['cert']);
      },
    );

    blocTest<HomeBloc, HomeState>(
      'a stale debounce that fires after the next keystroke is discarded',
      build: () => homeBlocOver(repository),
      seed: () => const HomeState(searchQuery: 'cert'),
      act: (HomeBloc bloc) => bloc.add(const HomeSearchDebounced('cer')),
      expect: () => <Matcher>[],
      verify: (_) => expect(repository.searchQueries, isEmpty),
    );

    blocTest<HomeBloc, HomeState>(
      'emptying the field settles immediately — no 300 ms of skeleton',
      // The grid flips straight back to the quick actions, which are already
      // loaded; waiting out the debounce would sit in `typing` on the way to a
      // view that needs no request at all.
      build: () => homeBlocOver(repository),
      seed: () => const HomeState(searchQuery: 'cert', debouncedQuery: 'cert'),
      act: (HomeBloc bloc) => bloc.add(const HomeSearchChanged('')),
      wait: const Duration(milliseconds: 10),
      verify: (HomeBloc bloc) {
        expect(bloc.state.query, '');
        expect(bloc.state.debouncedQuery, '');
        expect(bloc.state.typing, isFalse);
        expect(repository.searchQueries, isEmpty);
      },
    );

    blocTest<HomeBloc, HomeState>(
      'clearing resets the results to initial, not to an empty success',
      // Otherwise the next search shows the previous search's "No services
      // found" for a frame instead of a skeleton.
      build: () => homeBlocOver(repository),
      seed: () => HomeState(
        searchQuery: 'cert',
        debouncedQuery: 'cert',
        searchStatus: RegionStatus.success,
        searchResults: recordedPhase1Services(),
      ),
      act: (HomeBloc bloc) => bloc.add(const HomeSearchCleared()),
      verify: (HomeBloc bloc) {
        expect(bloc.state.searchStatus, RegionStatus.initial);
        expect(bloc.state.searchResults, isEmpty);
        expect(bloc.state.gridMode, ServiceGridMode.quickActions);
      },
    );

    test('servicesLoading is mode-aware, and `typing` counts as loading', () {
      // `listQuery.loading || listQuery.refreshing || typing` —
      // `ServicePage.tsx:350`. The `typing` term is what stops the grid showing
      // the previous search's rows while the next request is 300 ms away.
      const HomeState typing = HomeState(
        searchQuery: 'cert',
        debouncedQuery: '',
        searchStatus: RegionStatus.success,
      );
      expect(typing.typing, isTrue);
      expect(typing.servicesLoading, isTrue);

      const HomeState settled = HomeState(
        searchQuery: 'cert',
        debouncedQuery: 'cert',
        searchStatus: RegionStatus.success,
      );
      expect(settled.servicesLoading, isFalse);

      // In quick-actions mode the search status is irrelevant.
      const HomeState quick = HomeState(
        servicesStatus: RegionStatus.success,
        searchStatus: RegionStatus.loading,
      );
      expect(quick.servicesLoading, isFalse);
    });

    test('servicesFailed reads the status of whichever grid is showing', () {
      const HomeState searchFailed = HomeState(
        searchQuery: 'x',
        debouncedQuery: 'x',
        servicesStatus: RegionStatus.success,
        searchStatus: RegionStatus.failure,
      );
      expect(searchFailed.servicesFailed, isTrue);

      const HomeState quickFailed = HomeState(
        servicesStatus: RegionStatus.failure,
        searchStatus: RegionStatus.success,
      );
      expect(quickFailed.servicesFailed, isTrue);
      expect(searchFailed.copyWith(searchStatus: RegionStatus.success)
          .servicesFailed, isFalse);
    });

    blocTest<HomeBloc, HomeState>(
      'the services retry refetches the grid that is showing — quick actions',
      build: () => homeBlocOver(repository),
      act: (HomeBloc bloc) => bloc.add(const HomeServicesRetried()),
      verify: (_) {
        expect(repository.phase1Calls, 1);
        expect(repository.searchQueries, isEmpty);
      },
    );

    blocTest<HomeBloc, HomeState>(
      '…and the search grid when that is the one showing',
      build: () => homeBlocOver(repository),
      seed: () => const HomeState(searchQuery: 'cert', debouncedQuery: 'cert'),
      act: (HomeBloc bloc) => bloc.add(const HomeServicesRetried()),
      verify: (_) {
        expect(repository.searchQueries, <String>['cert']);
        expect(repository.phase1Calls, 0);
      },
    );

    test('displayedServices follows the mode', () {
      final List<Service> quick = recordedPhase1Services();
      final List<Service> found = quick.take(2).toList();

      final HomeState state = HomeState(
        quickActions: quick,
        searchResults: found,
      );
      expect(state.displayedServices, quick);
      expect(
        state.copyWith(searchQuery: 'x').displayedServices,
        found,
      );
    });
  });

  group('news and FAQ retries', () {
    blocTest<HomeBloc, HomeState>(
      'the news retry refetches only the news',
      build: () => homeBlocOver(repository),
      act: (HomeBloc bloc) => bloc.add(const HomeNewsRetried()),
      verify: (_) {
        expect(repository.newsCalls, 1);
        expect(repository.faqCalls, 0);
        expect(repository.phase1Calls, 0);
      },
    );

    blocTest<HomeBloc, HomeState>(
      'the FAQ retry exists at all — an addition to the port',
      // `HomePage.tsx:745-748` renders the FAQ error as a bare paragraph with
      // nothing to press. § 6.6 makes error-WITH-RETRY one of four mandatory
      // states and B2-AC-16 asserts it per surface, so the control is added
      // and this is the record that it is an addition.
      build: () => homeBlocOver(repository),
      act: (HomeBloc bloc) => bloc.add(const HomeFaqsRetried()),
      verify: (_) => expect(repository.faqCalls, 1),
    );

    blocTest<HomeBloc, HomeState>(
      'a failed retry keeps the last good rows rather than blanking them',
      build: () => homeBlocOver(repository),
      seed: () => HomeState(
        newsStatus: RegionStatus.success,
        news: tNews(),
      ),
      act: (HomeBloc bloc) {
        repository.news =
            const Left<Failure, List<HomeNewsItem>>(Failure('down'));
        bloc.add(const HomeNewsRetried());
      },
      verify: (HomeBloc bloc) {
        expect(bloc.state.newsStatus, RegionStatus.failure);
        expect(bloc.state.news, hasLength(3),
            reason: 'the rows are kept so a transient failure does not destroy '
                'content the citizen was already reading');
      },
    );
  });

  group('the FAQ accordion — HomePage.tsx:207,755', () {
    test('the first question is open on arrival', () {
      expect(const HomeState().openFaqIndex, 0);
    });

    blocTest<HomeBloc, HomeState>(
      'tapping another moves the open one',
      build: () => homeBlocOver(repository),
      act: (HomeBloc bloc) => bloc.add(const HomeFaqToggled(2)),
      expect: () => <Matcher>[
        isA<HomeState>().having((HomeState s) => s.openFaqIndex, 'open', 2),
      ],
    );

    blocTest<HomeBloc, HomeState>(
      'tapping the open one closes it — `open ? null : i`',
      build: () => homeBlocOver(repository),
      act: (HomeBloc bloc) => bloc.add(const HomeFaqToggled(0)),
      expect: () => <Matcher>[
        isA<HomeState>().having((HomeState s) => s.openFaqIndex, 'open', null),
      ],
    );
  });

  group('the two remaining branches', () {
    test('SearchServicesParams is a value — equal queries are equal params', () {
      // `Equatable`'s `props`. It matters because `bloc_test` and any future
      // `distinct()` on the event stream compare params by value; an identity
      // comparison would re-fire a search the citizen did not change.
      expect(SearchServicesParams('cert'), SearchServicesParams(' cert '));
      expect(
        SearchServicesParams('cert'),
        isNot(SearchServicesParams('birth')),
      );
      expect(SearchServicesParams('  ').query, '');
    });

    blocTest<HomeBloc, HomeState>(
      'a failing digital-ID keeps the last good card rather than nulling it',
      // The `getOrElse` fallback on the digital ID. A citizen whose card
      // request fails on a refetch must not watch their UIN vanish from a card
      // that is still on screen; the region's status carries the failure.
      build: () => homeBlocOver(repository),
      seed: () => const HomeState(
        isAuthenticated: true,
        digitalIdStatus: RegionStatus.success,
        digitalId: tDigitalId,
      ),
      act: (HomeBloc bloc) {
        repository.digitalId =
            const Left<Failure, DigitalIdCard>(Failure('down'));
        bloc.add(const HomeAuthChanged(isAuthenticated: true));
      },
      verify: (HomeBloc bloc) {
        expect(bloc.state.digitalIdStatus, RegionStatus.failure);
        expect(bloc.state.digitalId, tDigitalId);
      },
    );
  });

  group('lifetime', () {
    test('close() cancels the debounce timer', () async {
      // A BLoC that outlived its own timer would emit after being closed —
      // which `flutter_test` reports as an unrelated "emit after close" error
      // in whatever test happened to be running next.
      final HomeBloc bloc = homeBlocOver(repository);
      bloc.add(const HomeSearchChanged('cert'));
      await Future<void>.delayed(const Duration(milliseconds: 10));
      await bloc.close();

      await Future<void>.delayed(
        kHomeSearchDebounce + const Duration(milliseconds: 50),
      );
      expect(repository.searchQueries, isEmpty);
    });
  });
}
