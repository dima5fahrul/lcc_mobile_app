/// Standing the help centre up in a test.
///
/// Every fixture is a **recording** parsed by the production `*From` functions
/// — `/help/categories`, `/help/faqs` (page 1 of 2), `/help/articles`,
/// `/help/articles/<slug>` and `/help/channels`, all captured from live staging
/// through the same reverse-proxy rig at `62f8a529`. See
/// `news_test_helper.dart`'s header for why that closes B2-AC-36 where B2b had
/// to record a gap.
library;

import 'package:dartz/dartz.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lcc_mobile_app/core/error/failure.dart';
import 'package:lcc_mobile_app/features/help/data/models/help_wire.dart';
import 'package:lcc_mobile_app/features/help/domain/entities/help_entities.dart';
import 'package:lcc_mobile_app/features/help/domain/repositories/help_faq_page.dart';
import 'package:lcc_mobile_app/features/help/domain/repositories/help_repository.dart';
import 'package:lcc_mobile_app/features/help/domain/usecases/help_usecases.dart';
import 'package:lcc_mobile_app/features/help/presentation/bloc/help_bloc.dart';
import 'package:lcc_mobile_app/features/help/presentation/pages/help_page.dart';
import 'package:lcc_mobile_app/presentation/theme/app_theme.dart';

import '../fidelity/oracle.dart';
import 'app_test_harness.dart';

/// The guide whose `body` is recorded.
const String kRecordedGuideSlug = 'how-to-apply-residence-certificate';

// ─────────────────────────────────────────────────────────────────────────────
// Fixtures — recordings
// ─────────────────────────────────────────────────────────────────────────────

List<FaqCategory> recordedTopics() =>
    loadApi('help-categories').map(faqCategoryFrom).toList(growable: false);

List<FaqItem> recordedFaqs() =>
    loadApi('help-faqs').map(faqItemFrom).toList(growable: false);

List<HelpArticle> recordedGuides() =>
    loadApi('help-articles').map(helpArticleFrom).toList(growable: false);

/// The one recorded guide that carries a `body`.
HelpArticle recordedGuideBody() =>
    helpArticleFrom(loadApiObject('help-article-$kRecordedGuideSlug'));

List<SupportChannel> recordedChannels() =>
    loadApi('help-channels').map(supportChannelFrom).toList(growable: false);

/// `GET /help/faqs` page 1 as staging answered it — 10 of 11 rows, 2 pages.
///
/// The two-page shape is a **recording**, not a construction: `/help/faqs` has
/// 11 rows at `per_page` 10, which is why help's pager is Tier-1 gated and
/// news' is not (news answers 6 rows in 1 page).
HelpFaqPage recordedFaqPage() {
  final Map<String, dynamic> meta = loadApiMeta('help-faqs')!;
  return HelpFaqPage(
    items: recordedFaqs(),
    page: meta['page'] as int,
    totalPages: meta['total_pages'] as int,
    total: meta['total'] as int,
    hasNext: meta['has_next'] as bool,
    hasPrev: meta['has_prev'] as bool,
  );
}

/// **Hand-written, and labelled as such** — § 5's plain-string wire shape on
/// `/help/faqs`, one of the two endpoints § 5 names. The recording does not
/// happen to contain one.
FaqItem plainStringFaq() => faqItemFrom(<String, dynamic>{
      'id': 'synthetic-1',
      'category': 'account',
      'question': 'A single-language question?',
      'answer': 'A single-language answer.',
      'helpful': 9,
    });

// ─────────────────────────────────────────────────────────────────────────────
// The repository double
// ─────────────────────────────────────────────────────────────────────────────

class FakeHelpRepository implements HelpRepository {
  late Either<Failure, List<FaqCategory>> categories =
      Right<Failure, List<FaqCategory>>(recordedTopics());
  late Either<Failure, HelpFaqPage> faqs =
      Right<Failure, HelpFaqPage>(recordedFaqPage());
  late Either<Failure, List<HelpArticle>> guides =
      Right<Failure, List<HelpArticle>>(recordedGuides());
  late Either<Failure, HelpArticle> guide =
      Right<Failure, HelpArticle>(recordedGuideBody());
  late Either<Failure, List<SupportChannel>> channels =
      Right<Failure, List<SupportChannel>>(recordedChannels());
  Either<Failure, Unit> feedback = const Right<Failure, Unit>(unit);

  int categoryCalls = 0;
  int guidesCalls = 0;
  int channelCalls = 0;

  /// Every `getFaqs` call, in order. The debounce and filter assertions read
  /// this rather than a count: "one request for six keystrokes" and "one
  /// request with the *last* term" are different claims.
  final List<({int page, String? category, String? search})> faqCalls =
      <({int page, String? category, String? search})>[];

  final List<String> guideSlugs = <String>[];
  final List<({String id, bool helpful})> votes =
      <({String id, bool helpful})>[];

  Duration latency = Duration.zero;

  Future<void> _wait() async {
    if (latency > Duration.zero) await Future<void>.delayed(latency);
  }

  void failEverything() {
    const Failure f = Failure('stubbed failure');
    categories = const Left<Failure, List<FaqCategory>>(f);
    faqs = const Left<Failure, HelpFaqPage>(f);
    guides = const Left<Failure, List<HelpArticle>>(f);
    guide = const Left<Failure, HelpArticle>(f);
    channels = const Left<Failure, List<SupportChannel>>(f);
    feedback = const Left<Failure, Unit>(f);
  }

  void emptyEverything() {
    categories = const Right<Failure, List<FaqCategory>>(<FaqCategory>[]);
    faqs = const Right<Failure, HelpFaqPage>(HelpFaqPage.empty);
    guides = const Right<Failure, List<HelpArticle>>(<HelpArticle>[]);
    channels = const Right<Failure, List<SupportChannel>>(<SupportChannel>[]);
  }

  @override
  Future<Either<Failure, List<FaqCategory>>> getCategories() async {
    categoryCalls++;
    await _wait();
    return categories;
  }

  @override
  Future<Either<Failure, HelpFaqPage>> getFaqs({
    required int page,
    required int perPage,
    String? category,
    String? search,
  }) async {
    faqCalls.add((page: page, category: category, search: search));
    await _wait();
    return faqs;
  }

  @override
  Future<Either<Failure, List<HelpArticle>>> getGuides() async {
    guidesCalls++;
    await _wait();
    return guides;
  }

  @override
  Future<Either<Failure, HelpArticle>> getGuide(String slug) async {
    guideSlugs.add(slug);
    await _wait();
    return guide;
  }

  @override
  Future<Either<Failure, List<SupportChannel>>> getChannels() async {
    channelCalls++;
    await _wait();
    return channels;
  }

  @override
  Future<Either<Failure, Unit>> sendFaqFeedback({
    required String id,
    required bool helpful,
  }) async {
    votes.add((id: id, helpful: helpful));
    await _wait();
    return feedback;
  }
}

/// A [HelpBloc] over [repository], wired exactly as production wires it.
HelpBloc helpBlocOver(FakeHelpRepository repository) => HelpBloc(
      getHelpCategories: GetHelpCategories(repository: repository),
      getHelpFaqs: GetHelpFaqs(repository: repository),
      getHelpGuides: GetHelpGuides(repository: repository),
      getHelpGuide: GetHelpGuide(repository: repository),
      getSupportChannels: GetSupportChannels(repository: repository),
      sendFaqFeedback: SendFaqFeedback(repository: repository),
    );

// ─────────────────────────────────────────────────────────────────────────────
// Pumping
// ─────────────────────────────────────────────────────────────────────────────

const Duration kHelpStubLatency = Duration(milliseconds: 500);

/// Pumps [HelpPage] under [bloc]. **Does not settle** — the accordions hold an
/// `AnimatedRotation`, so callers pump explicitly, as `pumpServicePage` and
/// `pumpHomePage` do for the same reason.
Future<void> pumpHelpPage(
  WidgetTester tester,
  HelpBloc bloc, {
  Locale locale = const Locale('en'),
  Size surface = const Size(390, 4000),
}) async {
  tester.view.devicePixelRatio = 1.0;
  tester.view.physicalSize = surface;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    wrapWithLocalization(
      startLocale: locale,
      Builder(
        builder: (BuildContext context) => MaterialApp(
          theme: AppTheme.light(),
          localizationsDelegates: context.localizationDelegates,
          supportedLocales: context.supportedLocales,
          locale: context.locale,
          home: BlocProvider<HelpBloc>.value(value: bloc, child: const HelpPage()),
        ),
      ),
    ),
  );
  await tester.pump();
}

/// Pumps past the debounce window and any stubbed latency, without calling
/// `pumpAndSettle`.
Future<void> settleHelp(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(
    kHelpSearchDebounce + kHelpStubLatency + const Duration(milliseconds: 50),
  );
  await tester.pump();
}
