/// **Tier 1 — structural parity for `/help`. B2-AC-8.**
///
/// § 6.5.1: *"APPLICABLE, blocking, 100 %. This is B2's principal gate."*
/// A Dart test against a versioned oracle, no browser in the loop.
///
/// ## Region by region, and why that is not a weaker gate here
///
/// `/help` is five independent reads on one screen, and its own § 6.6 contract
/// is per-region: a failed channel list must not take the questions down. So
/// the page's states are not a single enumeration and a whole-page dump would
/// only ever describe one combination of five. Each region is dumped from its
/// own subtree against its own oracle view; the union is the page.
///
/// Where a region *is* a single ordered subtree — the header, the topic chips,
/// each accordion card, each channel tile — the comparison is the **ordered**
/// one, so a page that renders every right string in the wrong place still
/// fails. Only the cross-region assertions (an error block that lives in a
/// sibling of the region it belongs to) fall back to presence, and each says so.
library;

import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lcc_mobile_app/core/error/failure.dart';
import 'package:lcc_mobile_app/features/help/domain/entities/help_entities.dart';
import 'package:lcc_mobile_app/features/help/domain/repositories/help_faq_page.dart';
import 'package:lcc_mobile_app/features/help/presentation/bloc/help_bloc.dart';
import 'package:lcc_mobile_app/features/help/presentation/widgets/faq_card.dart';
import 'package:lcc_mobile_app/features/help/presentation/widgets/guide_card.dart';
import 'package:lcc_mobile_app/features/help/presentation/widgets/help_header.dart';
import 'package:lcc_mobile_app/features/help/presentation/widgets/help_topic_chips.dart';
import 'package:lcc_mobile_app/features/help/presentation/widgets/support_channel_tile.dart';

import '../../../fidelity/oracle.dart';
import '../../../fidelity/text_dump.dart';
import '../../../helpers/help_test_helper.dart';
import '../../news/fidelity/tier1_news_test.dart' show dumpEach, expectParity;

const List<Locale> kLocales = <Locale>[Locale('en'), Locale('lo')];

void main() {
  group('the oracle is the versioned artefact, pinned to 62f8a529', () {
    for (final Locale locale in kLocales) {
      test('help.${locale.languageCode} carries the commit', () {
        final Map<String, dynamic> oracle =
            loadTier1('help', locale.languageCode);
        expect(
          (oracle['provenance'] as Map<String, dynamic>)['web_commit'],
          kWebCommit,
        );
      });
    }
  });

  for (final Locale locale in kLocales) {
    final String lang = locale.languageCode;

    group('Tier 1 — /help — $lang', () {
      late Map<String, dynamic> oracle;

      setUp(() => oracle = loadTier1('help', lang));

      /// Built **inside the test body**: `setUp` runs outside `testWidgets`'
      /// `FakeAsync` zone, so a BLoC constructed there owns an event queue
      /// `tester.pump()` never drains and every region stays on its skeleton.
      /// See `tier1_news_test.dart` for the run that proved it.
      ({FakeHelpRepository repository, HelpBloc bloc}) subject() {
        final FakeHelpRepository repository = FakeHelpRepository();
        final HelpBloc bloc = helpBlocOver(repository);
        addTearDown(bloc.close);
        return (repository: repository, bloc: bloc);
      }

      /// Presence, in order-free form, for a view whose nodes are spread across
      /// sibling subtrees. Named so the weaker check is visible at the call
      /// site rather than hidden in a helper.
      void expectPresence(String view) {
        for (final OracleNode n in tier1View(oracle, view)) {
          expect(find.text(n.text), findsWidgets,
              reason: '"${n.text}" (${n.role}) <- ${n.source}');
        }
      }

      // ── Header ─────────────────────────────────────────────────────────────

      testWidgets('header — title, subtitle and the search placeholder',
          (WidgetTester tester) async {
        final (repository: _, :HelpBloc bloc) = subject();
        await pumpHelpPage(tester, bloc, locale: locale);
        bloc.add(const HelpStarted());
        await settleHelp(tester);

        expectParity(oracle, 'header', dumpText(tester, find.byType(HelpHeader)),
            route: '/help', locale: lang);
      });

      // ── Topics ─────────────────────────────────────────────────────────────

      testWidgets('topics.data — All topics plus the four recorded topics',
          (WidgetTester tester) async {
        final (repository: _, :HelpBloc bloc) = subject();
        await pumpHelpPage(tester, bloc, locale: locale);
        bloc.add(const HelpStarted());
        await settleHelp(tester);

        expectParity(
          oracle,
          'topics.data',
          dumpText(tester, find.byType(HelpTopicChips)),
          route: '/help',
          locale: lang,
        );
      });

      testWidgets('topics.error — the § 6.6 addition, recorded as one',
          (WidgetTester tester) async {
        final (:FakeHelpRepository repository, :HelpBloc bloc) = subject();
        // Only the topics fail: the whole point of the five separate statuses
        // is that one failure does not take the page down.
        repository.categories = const Left<Failure, List<FaqCategory>>(
          Failure('stubbed topics failure'),
        );
        await pumpHelpPage(tester, bloc, locale: locale);
        bloc.add(const HelpStarted());
        await settleHelp(tester);

        expectPresence('topics.error');
        expect(find.byType(FaqCard), findsWidgets,
            reason: 'the questions survived their sibling\'s failure');
      });

      // ── Questions ──────────────────────────────────────────────────────────

      testWidgets('results.count — meta.total, not items.length',
          (WidgetTester tester) async {
        // The recorded page carries 10 rows out of 11. Printing `items.length`
        // would say "10 articles" and look entirely plausible.
        final (repository: _, :HelpBloc bloc) = subject();
        await pumpHelpPage(tester, bloc, locale: locale);
        bloc.add(const HelpStarted());
        await settleHelp(tester);

        expectPresence('results.count');
      });

      testWidgets('faqs.data — ten recorded questions, card by card',
          (WidgetTester tester) async {
        final (repository: _, :HelpBloc bloc) = subject();
        await pumpHelpPage(
          tester,
          bloc,
          locale: locale,
          surface: const Size(390, 8000),
        );
        bloc.add(const HelpStarted());
        await settleHelp(tester);

        expect(find.byType(FaqCard), findsNWidgets(10),
            reason: 'a lazy viewport that built fewer would make the dump '
                'below measure nothing');

        expectParity(oracle, 'faqs.data', dumpEach<FaqCard>(tester),
            route: '/help', locale: lang);
      });

      testWidgets('faqs.expanded — answer plus the helpful prompt',
          (WidgetTester tester) async {
        final (:FakeHelpRepository repository, :HelpBloc bloc) = subject();
        await pumpHelpPage(tester, bloc, locale: locale);
        bloc.add(const HelpStarted());
        await settleHelp(tester);

        bloc.add(HelpFaqToggled(recordedFaqs().first.id));
        await settleHelp(tester);

        expectParity(
          oracle,
          'faqs.expanded',
          dumpText(tester, find.byType(FaqCard).first),
          route: '/help',
          locale: lang,
        );
      });

      testWidgets('faqs.voted — the thanks replaces the two thumbs',
          (WidgetTester tester) async {
        final (repository: _, :HelpBloc bloc) = subject();
        await pumpHelpPage(tester, bloc, locale: locale);
        bloc.add(const HelpStarted());
        await settleHelp(tester);

        final String id = recordedFaqs().first.id;
        bloc.add(HelpFaqToggled(id));
        await settleHelp(tester);
        bloc.add(HelpFaqVoted(id: id, helpful: true));
        await settleHelp(tester);

        expectPresence('faqs.voted');
        // `:332` — the prompt and both thumbs are gone, not merely disabled.
        expect(find.text(tier1View(oracle, 'faqs.expanded').last.text),
            findsNothing);
      });

      testWidgets('faqs.empty — two lines, and no retry',
          (WidgetTester tester) async {
        final (:FakeHelpRepository repository, :HelpBloc bloc) = subject();
        repository.faqs = const Right<Failure, HelpFaqPage>(HelpFaqPage.empty);
        await pumpHelpPage(tester, bloc, locale: locale);
        bloc.add(const HelpStarted());
        await settleHelp(tester);

        expectPresence('faqs.empty');
      });

      testWidgets('faqs.error — message plus Try again',
          (WidgetTester tester) async {
        final (:FakeHelpRepository repository, :HelpBloc bloc) = subject();
        repository.faqs =
            const Left<Failure, HelpFaqPage>(Failure('stubbed faq failure'));
        await pumpHelpPage(tester, bloc, locale: locale);
        bloc.add(const HelpStarted());
        await settleHelp(tester);

        expectPresence('faqs.error');
      });

      testWidgets('pager — 1 / 2, because staging really does paginate here',
          (WidgetTester tester) async {
        // 11 questions at per_page 10. This is the pager view `/news` does not
        // have — 6 rows at per_page 6 is one page there — and the two controls
        // are byte-identical in the source, so gating it once gates both.
        final (repository: _, :HelpBloc bloc) = subject();
        await pumpHelpPage(
          tester,
          bloc,
          locale: locale,
          surface: const Size(390, 8000),
        );
        bloc.add(const HelpStarted());
        await settleHelp(tester);

        expectPresence('pager');
      });

      // ── Guides ─────────────────────────────────────────────────────────────

      testWidgets('guides.header and guides.data',
          (WidgetTester tester) async {
        final (repository: _, :HelpBloc bloc) = subject();
        await pumpHelpPage(
          tester,
          bloc,
          locale: locale,
          surface: const Size(390, 8000),
        );
        bloc.add(const HelpStarted());
        await settleHelp(tester);

        expectPresence('guides.header');
        expect(find.byType(GuideCard), findsNWidgets(2));
        expectParity(oracle, 'guides.data', dumpEach<GuideCard>(tester),
            route: '/help', locale: lang);
      });

      testWidgets('guides.expanded — the body arrives from the SECOND request',
          (WidgetTester tester) async {
        final (:FakeHelpRepository repository, :HelpBloc bloc) = subject();
        await pumpHelpPage(
          tester,
          bloc,
          locale: locale,
          surface: const Size(390, 8000),
        );
        bloc.add(const HelpStarted());
        await settleHelp(tester);

        // The list endpoint carries no body, so nothing is on screen yet.
        expect(repository.guideSlugs, isEmpty);

        bloc.add(HelpGuideToggled(kRecordedGuideSlug));
        await settleHelp(tester);

        expect(repository.guideSlugs, <String>[kRecordedGuideSlug]);
        expectParity(
          oracle,
          'guides.expanded',
          dumpText(tester, find.byType(GuideCard).first),
          route: '/help',
          locale: lang,
        );
      });

      testWidgets('guides.empty', (WidgetTester tester) async {
        final (:FakeHelpRepository repository, :HelpBloc bloc) = subject();
        repository.guides =
            const Right<Failure, List<HelpArticle>>(<HelpArticle>[]);
        await pumpHelpPage(
          tester,
          bloc,
          locale: locale,
          surface: const Size(390, 8000),
        );
        bloc.add(const HelpStarted());
        await settleHelp(tester);

        expectPresence('guides.empty');
      });

      testWidgets('guides.error', (WidgetTester tester) async {
        final (:FakeHelpRepository repository, :HelpBloc bloc) = subject();
        repository.guides = const Left<Failure, List<HelpArticle>>(
          Failure('stubbed guides failure'),
        );
        await pumpHelpPage(
          tester,
          bloc,
          locale: locale,
          surface: const Size(390, 8000),
        );
        bloc.add(const HelpStarted());
        await settleHelp(tester);

        expectPresence('guides.error');
      });

      // ── Still stuck / channels ─────────────────────────────────────────────

      testWidgets('stillStuck and channels.data',
          (WidgetTester tester) async {
        final (repository: _, :HelpBloc bloc) = subject();
        await pumpHelpPage(
          tester,
          bloc,
          locale: locale,
          surface: const Size(390, 8000),
        );
        bloc.add(const HelpStarted());
        await settleHelp(tester);

        expectPresence('stillStuck');
        expect(find.byType(SupportChannelTile), findsNWidgets(4));
        expectParity(
          oracle,
          'channels.data',
          dumpEach<SupportChannelTile>(tester),
          route: '/help',
          locale: lang,
        );
      });

      testWidgets('channels.empty is the account LINK, not a message',
          (WidgetTester tester) async {
        // `:479-486`. The one empty state in B2c that is a control rather than
        // copy, and the one most likely to be "simplified" into a sentence.
        final (:FakeHelpRepository repository, :HelpBloc bloc) = subject();
        repository.channels =
            const Right<Failure, List<SupportChannel>>(<SupportChannel>[]);
        await pumpHelpPage(
          tester,
          bloc,
          locale: locale,
          surface: const Size(390, 8000),
        );
        bloc.add(const HelpStarted());
        await settleHelp(tester);

        expectPresence('channels.empty');
        expect(find.byType(SupportChannelTile), findsNothing);
      });

      testWidgets('channels.error', (WidgetTester tester) async {
        final (:FakeHelpRepository repository, :HelpBloc bloc) = subject();
        repository.channels = const Left<Failure, List<SupportChannel>>(
          Failure('stubbed channels failure'),
        );
        await pumpHelpPage(
          tester,
          bloc,
          locale: locale,
          surface: const Size(390, 8000),
        );
        bloc.add(const HelpStarted());
        await settleHelp(tester);

        expectPresence('channels.error');
      });
    });
  }
}
