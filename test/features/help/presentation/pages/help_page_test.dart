/// `HelpPage` as a rendered surface.
///
/// Tier 1 gates **what text** each region shows. This gates what a text dump
/// cannot see: that the states are distinguishable, that the controls work,
/// that the Lao render neither tofus nor overflows, and that no widget reads a
/// locator.
library;

import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lcc_mobile_app/core/error/failure.dart';
import 'package:lcc_mobile_app/features/help/domain/entities/help_entities.dart';
import 'package:lcc_mobile_app/features/help/domain/repositories/help_faq_page.dart';
import 'package:lcc_mobile_app/features/help/domain/usecases/help_usecases.dart';
import 'package:lcc_mobile_app/features/help/presentation/bloc/help_bloc.dart';
import 'package:lcc_mobile_app/features/help/presentation/pages/help_page.dart';
import 'package:lcc_mobile_app/features/help/presentation/widgets/faq_card.dart';
import 'package:lcc_mobile_app/features/help/presentation/widgets/guide_card.dart';
import 'package:lcc_mobile_app/features/help/presentation/widgets/help_pager.dart';
import 'package:lcc_mobile_app/features/help/presentation/widgets/help_panels.dart';
import 'package:lcc_mobile_app/features/help/presentation/widgets/help_search_field.dart';
import 'package:lcc_mobile_app/features/help/presentation/widgets/support_channel_tile.dart';

import '../../../../helpers/help_test_helper.dart';

const Size kTall = Size(390, 8000);

void main() {
  group('the four states, per region (B2-AC-16)', () {
    testWidgets('loading is skeletons everywhere and no content',
        (WidgetTester tester) async {
      final FakeHelpRepository repository = FakeHelpRepository()
        ..latency = kHelpStubLatency;
      final HelpBloc bloc = helpBlocOver(repository);
      addTearDown(bloc.close);

      await pumpHelpPage(tester, bloc, surface: kTall);
      bloc.add(const HelpStarted());
      await tester.pump();

      expect(find.byType(HelpSkeleton), findsWidgets);
      expect(find.byType(FaqCard), findsNothing);
      expect(find.byType(GuideCard), findsNothing);
      expect(find.byType(SupportChannelTile), findsNothing);
      expect(find.byType(HelpErrorBlock), findsNothing);

      await settleHelp(tester);
    });

    testWidgets('data is 10 questions, 2 guides and 4 channels',
        (WidgetTester tester) async {
      final HelpBloc bloc = helpBlocOver(FakeHelpRepository());
      addTearDown(bloc.close);

      await pumpHelpPage(tester, bloc, surface: kTall);
      bloc.add(const HelpStarted());
      await settleHelp(tester);

      expect(find.byType(FaqCard), findsNWidgets(10));
      expect(find.byType(GuideCard), findsNWidgets(2));
      expect(find.byType(SupportChannelTile), findsNWidgets(4));
      expect(find.byType(HelpSkeleton), findsNothing);
      expect(find.byType(HelpErrorBlock), findsNothing);
    });

    testWidgets('empty (stubbed) is copy, and the channels empty is a LINK',
        (WidgetTester tester) async {
      // § 6.6: `/help/articles` returns 2 and `/help/faqs` returns 11 against
      // staging, so no empty state occurs by accident — each must be tested
      // with a stubbed empty response.
      final FakeHelpRepository repository = FakeHelpRepository()
        ..emptyEverything();
      final HelpBloc bloc = helpBlocOver(repository);
      addTearDown(bloc.close);

      await pumpHelpPage(tester, bloc, surface: kTall);
      bloc.add(const HelpStarted());
      await settleHelp(tester);

      expect(find.text('No articles match your search'), findsOneWidget);
      expect(find.text('No guides have been published yet.'), findsOneWidget);
      // `:479-486` — not a message.
      expect(find.text('Contact support'), findsOneWidget);
      expect(find.byType(HelpErrorBlock), findsNothing);
    });

    testWidgets('error is one block per failed region, each with a retry',
        (WidgetTester tester) async {
      final FakeHelpRepository repository = FakeHelpRepository()
        ..failEverything();
      final HelpBloc bloc = helpBlocOver(repository);
      addTearDown(bloc.close);

      await pumpHelpPage(tester, bloc, surface: kTall);
      bloc.add(const HelpStarted());
      await settleHelp(tester);

      // Topics, questions, guides, channels — four regions, four blocks.
      expect(find.byType(HelpErrorBlock), findsNWidgets(4));
      expect(find.text('Try again'), findsNWidgets(4));
    });

    testWidgets('a question retry re-asks and recovers',
        (WidgetTester tester) async {
      final FakeHelpRepository repository = FakeHelpRepository()
        ..faqs = const Left<Failure, HelpFaqPage>(Failure('boom'));
      final HelpBloc bloc = helpBlocOver(repository);
      addTearDown(bloc.close);

      await pumpHelpPage(tester, bloc, surface: kTall);
      bloc.add(const HelpStarted());
      await settleHelp(tester);

      expect(find.byType(FaqCard), findsNothing);
      final int before = repository.faqCalls.length;

      repository.faqs = Right<Failure, HelpFaqPage>(recordedFaqPage());
      await tester.tap(find.text('Try again').first);
      await settleHelp(tester);

      expect(repository.faqCalls.length, before + 1);
      expect(find.byType(FaqCard), findsNWidgets(10));
    });
  });

  group('the controls', () {
    testWidgets('typing debounces into ONE request and clears with the X',
        (WidgetTester tester) async {
      final FakeHelpRepository repository = FakeHelpRepository();
      final HelpBloc bloc = helpBlocOver(repository);
      addTearDown(bloc.close);

      await pumpHelpPage(tester, bloc, surface: kTall);
      bloc.add(const HelpStarted());
      await settleHelp(tester);
      final int before = repository.faqCalls.length;

      await tester.enterText(find.byType(TextField), 'refund');
      await tester.pump();

      // The clear control only exists while there is a query — `searching`.
      expect(find.bySemanticsLabel('Clear search'), findsOneWidget);

      await settleHelp(tester);
      expect(repository.faqCalls.length, before + 1);
      expect(repository.faqCalls.last.search, 'refund');

      await tester.tap(find.bySemanticsLabel('Clear search'));
      await settleHelp(tester);

      expect(repository.faqCalls.last.search, isNull);
      expect(find.bySemanticsLabel('Clear search'), findsNothing);
      expect(
        tester.widget<TextField>(find.byType(TextField)).controller?.text,
        '',
        reason: 'the programmatic clear must empty the VISIBLE field, which is '
            'what the controller mirror in HelpSearchField exists for',
      );
    });

    testWidgets('tapping a topic chip filters', (WidgetTester tester) async {
      final FakeHelpRepository repository = FakeHelpRepository();
      final HelpBloc bloc = helpBlocOver(repository);
      addTearDown(bloc.close);

      await pumpHelpPage(tester, bloc, surface: kTall);
      bloc.add(const HelpStarted());
      await settleHelp(tester);

      await tester.tap(find.text('Payments & fees'));
      await settleHelp(tester);

      expect(repository.faqCalls.last.category, 'payments');
    });

    testWidgets('expanding a question reveals its answer and the vote',
        (WidgetTester tester) async {
      final FakeHelpRepository repository = FakeHelpRepository();
      final HelpBloc bloc = helpBlocOver(repository);
      addTearDown(bloc.close);

      await pumpHelpPage(tester, bloc, surface: kTall);
      bloc.add(const HelpStarted());
      await settleHelp(tester);

      final FaqItem first = recordedFaqs().first;
      expect(find.text(first.answer.en), findsNothing);

      await tester.tap(find.text(first.question.en));
      await settleHelp(tester);

      expect(find.text(first.answer.en), findsOneWidget);
      expect(find.text('Was this helpful?'), findsOneWidget);

      await tester.tap(find.bySemanticsLabel('Yes, this helped'));
      await settleHelp(tester);

      expect(repository.votes, <({String id, bool helpful})>[
        (id: first.id, helpful: true),
      ]);
      expect(find.text('Thanks for the feedback'), findsOneWidget);
      expect(find.text('Was this helpful?'), findsNothing);
    });

    testWidgets('a question in a tab-bearing topic shows the deep link',
        (WidgetTester tester) async {
      // `CATEGORY_TAB` — :64-68. Three of the four recorded topics name a tab;
      // `getting-started` does not, and its questions must NOT show the link.
      final HelpBloc bloc = helpBlocOver(FakeHelpRepository());
      addTearDown(bloc.close);

      await pumpHelpPage(tester, bloc, surface: kTall);
      bloc.add(const HelpStarted());
      await settleHelp(tester);

      final FaqItem gettingStarted = recordedFaqs()
          .firstWhere((FaqItem f) => f.category == 'getting-started');
      final FaqItem services =
          recordedFaqs().firstWhere((FaqItem f) => f.category == 'services');

      bloc.add(HelpFaqToggled(gettingStarted.id));
      await settleHelp(tester);
      expect(find.text('Go to service'), findsNothing);

      bloc.add(HelpFaqToggled(services.id));
      await settleHelp(tester);
      expect(find.text('Go to service'), findsOneWidget);
    });

    testWidgets('expanding a guide shows a skeleton, then its body',
        (WidgetTester tester) async {
      final FakeHelpRepository repository = FakeHelpRepository()
        ..latency = kHelpStubLatency;
      final HelpBloc bloc = helpBlocOver(repository);
      addTearDown(bloc.close);

      await pumpHelpPage(tester, bloc, surface: kTall);
      bloc.add(const HelpStarted());
      await settleHelp(tester);

      bloc.add(const HelpGuideToggled(kRecordedGuideSlug));
      // TWO pumps, not one: the first lets the BLoC's event queue run the
      // handler, the second rebuilds the tree against the state it emitted.
      // One pump asserts against the frame before the expansion.
      await tester.pump();
      await tester.pump();

      // The panel is a skeleton until the single-article request lands —
      // `:448-452`. The port keeps that second request even though staging's
      // LIST endpoint happens to include a body (see `help_wire_test.dart`),
      // because the source fetches and `guide.data?.slug === g.slug` is what
      // gates the render.
      expect(find.byType(HelpSkeleton), findsWidgets);

      await settleHelp(tester);
      expect(find.textContaining('Open Services and choose'), findsOneWidget);
    });

    testWidgets('the pager shows 1 / 2 and moves the query',
        (WidgetTester tester) async {
      final FakeHelpRepository repository = FakeHelpRepository();
      final HelpBloc bloc = helpBlocOver(repository);
      addTearDown(bloc.close);

      await pumpHelpPage(tester, bloc, surface: kTall);
      bloc.add(const HelpStarted());
      await settleHelp(tester);

      expect(find.byType(HelpPager), findsOneWidget);
      expect(find.text('1 / 2'), findsOneWidget);

      await tester.tap(find.bySemanticsLabel('Next page'));
      await settleHelp(tester);

      expect(repository.faqCalls.last.page, 2);
    });
  });

  group('the swatch and the icon scope', () {
    testWidgets('each question wears its topic\'s swatch, cycled by POSITION',
        (WidgetTester tester) async {
      // `swatch(catMeta(a.category).index)` — the position in the category
      // list, not the code. Four topics, four swatches, no wrap-around here.
      final HelpBloc bloc = helpBlocOver(FakeHelpRepository());
      addTearDown(bloc.close);

      await pumpHelpPage(tester, bloc, surface: kTall);
      bloc.add(const HelpStarted());
      await settleHelp(tester);

      final List<FaqCategory> topics = recordedTopics();
      for (final FaqItem f in recordedFaqs()) {
        final ({int index, String icon}) meta =
            helpCategoryMeta(topics, f.category);
        expect(meta.index, inInclusiveRange(0, 3));
      }
      expect(find.byType(FaqCard), findsNWidgets(10));
    });

    testWidgets('a channel with an unknown icon falls back to MessageCircle, '
        'not FileText', (WidgetTester tester) async {
      // `icon(ch.icon, MessageCircle)` — :490 is the ONE call site whose
      // fallback is not `FileText`, and merging it into `AppIcons.help` would
      // change every other call site.
      final FakeHelpRepository repository = FakeHelpRepository()
        ..channels = Right<Failure, List<SupportChannel>>(<SupportChannel>[
          const SupportChannel(
            id: 'c1',
            kind: 'chat',
            value: 'chat',
            icon: 'NotARealIconName',
          ),
        ]);
      final HelpBloc bloc = helpBlocOver(repository);
      addTearDown(bloc.close);

      await pumpHelpPage(tester, bloc, surface: kTall);
      bloc.add(const HelpStarted());
      await settleHelp(tester);

      final SupportChannelTile tile =
          tester.widget<SupportChannelTile>(find.byType(SupportChannelTile));
      expect(tile.iconName, 'MessageCircle');
    });
  });

  group('B2-AC-15 — the Lao render', () {
    testWidgets('Lao glyphs from the dictionary AND the API, no overflow',
        (WidgetTester tester) async {
      final HelpBloc bloc = helpBlocOver(FakeHelpRepository());
      addTearDown(bloc.close);

      await pumpHelpPage(
        tester,
        bloc,
        locale: const Locale('lo'),
        surface: kTall,
      );
      bloc.add(const HelpStarted());
      await settleHelp(tester);

      expect(find.text('ທຸກຫົວຂໍ້'), findsOneWidget);
      expect(find.text(recordedTopics()[1].name.lo), findsOneWidget);
      expect(find.text(recordedFaqs().first.question.lo), findsOneWidget);
      // The check that caught the 14 px chip overflow and the 22 px button one.
      expect(tester.takeException(), isNull);
    });

    testWidgets('every expanded surface survives Lao too',
        (WidgetTester tester) async {
      final HelpBloc bloc = helpBlocOver(FakeHelpRepository());
      addTearDown(bloc.close);

      await pumpHelpPage(
        tester,
        bloc,
        locale: const Locale('lo'),
        surface: kTall,
      );
      bloc.add(const HelpStarted());
      await settleHelp(tester);

      bloc.add(HelpFaqToggled(recordedFaqs().first.id));
      await settleHelp(tester);
      bloc.add(const HelpGuideToggled(kRecordedGuideSlug));
      await settleHelp(tester);

      expect(find.text(recordedFaqs().first.answer.lo), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('the error and empty states survive Lao',
        (WidgetTester tester) async {
      final FakeHelpRepository repository = FakeHelpRepository()
        ..failEverything();
      final HelpBloc bloc = helpBlocOver(repository);
      addTearDown(bloc.close);

      await pumpHelpPage(
        tester,
        bloc,
        locale: const Locale('lo'),
        surface: kTall,
      );
      bloc.add(const HelpStarted());
      await settleHelp(tester);

      expect(find.text('ລອງໃໝ່'), findsNWidgets(4));
      expect(tester.takeException(), isNull);
    });
  });

  group('G-L5 — the page reads no locator', () {
    testWidgets('it renders under a BlocProvider alone',
        (WidgetTester tester) async {
      // No `DependencyInjection.init()` here, so a widget reaching for
      // `helpInjection` would throw rather than quietly work.
      final HelpBloc bloc = helpBlocOver(FakeHelpRepository());
      addTearDown(bloc.close);

      await pumpHelpPage(tester, bloc, surface: kTall);
      bloc.add(const HelpStarted());
      await settleHelp(tester);

      expect(find.byType(HelpPage), findsOneWidget);
      expect(find.byType(HelpSearchField), findsOneWidget);
    });
  });
}
