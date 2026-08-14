/// Home — the port of `lcc-app/src/app/components/HomePage.tsx` (1,058 lines),
/// `Hero.tsx` (348) and `ServiceCard.tsx` (110).
///
/// Replaces the P0 `TabPlaceholder`. Seven regions down one scroll:
///
/// 1. **Hero** — photo backdrop, greeting, the two ministries, the LaoID card,
///    the search field.
/// 2. **Summary tiles** — four, *signed in only* (`enabled: isAuthenticated`).
/// 3. **Action banner** — whatever the API says needs the citizen next, *signed
///    in only*, dismissible behind a confirmation.
/// 4. **Services** — "What do you need?", the quick-actions grid plus a "More"
///    tile, or the search results.
/// 5. **Categories** — the eight-photograph slider (hidden while searching).
/// 6. **News** — three featured articles.
/// 7. **FAQ** — five questions, the first open.
///
/// ## Two regions are auth-gated, and Tier 3 is NOT EVALUATED for them
///
/// **B2-AC-33.** `summary` and `digitalId` are `enabled: isAuthenticated`
/// (`HomePage.tsx:163,168`), the 2026-08-13 baseline was captured signed out,
/// and § 6.5.2(b) rules that class: **Tiers 1 and 2 remain fully binding**
/// because they read source rather than screenshots, and **Tier 3 is reported
/// NOT EVALUATED for those two regions by name**, with the signed-out render
/// gated normally. Producing a reference would need a test citizen identity in
/// a national-identity system, which is F0's blocking question and a user
/// decision.
///
/// Signed out, those two regions are **absent** — not a spinner, not an error,
/// not four zeroes. The card shows the masked specimen and "Sign in to
/// activate" (manifest F-4).
///
/// ## What is deliberately NOT ported, and why
///
/// Both are recorded here rather than left to be noticed as gaps:
///
/// * **The Customize modal** (`HomePage.tsx:920-1056`, and the
///   `homeServiceIds` / `customized` / `draftIds` state behind it). Its entire
///   observable effect is persistence: it writes the chosen shortcut set to
///   `localStorage["lcc_home_services"]` and reads it back on mount
///   (`:52`, `:214-225`, `:249`). **SSD § 12.4 forbids persistent storage in
///   B2** and B2-AC-20 asserts it (`no Hive box opened, no secure-storage key
///   added`). An in-memory port would render a full picker whose result
///   vanishes on restart — a control that lies about what it does, which is
///   worse than one that is absent. The **chip stays** (Tier 1 compares the
///   text the web presents) and its tap is a no-op, the same shape C-4 already
///   sanctions for the catalogue card. **Escalated, not decided here.**
/// * ~~**The tutorial overlay**~~ — **landed in B10** (§ 6.10). B2b left it
///   out because § 2.3's table scoped that batch to *"`HomePage` + `Hero` +
///   `ServiceCard`, 1,516 lines"* and `TutorialOverlay` is a separate
///   component. It is now mounted below, gated on `lcc.tutorial_seen`, exactly
///   as `HomePage.tsx`:212 gates it. The "How it works" chip's tap is still a
///   no-op: in the source that chip does **not** open the tutorial either —
///   the overlay is first-run-automatic, not chip-triggered.
///
/// ## The BLoC is created by the route builder, not by this page
///
/// CR-1 / G-L5: *route builders and `main.dart` may resolve from a locator; no
/// widget may.* `app_routes.dart`'s `/` builder resolves `HomeBloc`, dispatches
/// [HomeStarted] and hands it down; this file names no container.
///
/// ## …but the auth flag is dispatched on MOUNT as well as on change
///
/// [HomeAuthChanged] comes from here, off the app-wide `SessionBloc` — a
/// provider read, not a locator read. It is dispatched **twice over**: once in
/// `initState` for the session's current value, and again from a
/// `BlocListener` whenever it changes.
///
/// The listener alone is not enough, and the gap is not theoretical. `HomeBloc`
/// is a `registerFactory` behind `BlocProvider(create:)`, so **every visit to
/// `/` builds a fresh one starting at `isAuthenticated: false`**. A signed-in
/// citizen who taps Service and then Home again re-mounts this page against a
/// `SessionBloc` that has not changed state — no transition, no listener call,
/// and the summary tiles and the citizen's own UIN silently do not come back.
/// Caught by `home_page_test.dart`'s "signed in" cases, which pump a session
/// that is *already* authenticated rather than one that transitions.
library;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/session/bloc/session_bloc.dart';
import '../../../../core/storage/storage_service.dart';
import '../../../../presentation/icons/lucide_icon.dart';
import '../../../../presentation/theme/app_colors.dart';
import '../../../../presentation/theme/app_spacing.dart';
import '../../../../presentation/theme/app_typography.dart';
import '../../../../utils/routes/app_name_routes.dart';
import '../../../service/domain/entities/service.dart';
import '../../../service/domain/service_availability.dart';
import '../../domain/entities/home_news_item.dart';
import '../bloc/home_bloc.dart';
import '../widgets/action_banner.dart';
import '../widgets/category_slider.dart';
import '../widgets/faq_accordion.dart';
import '../widgets/hero_header.dart';
import '../widgets/home_panels.dart';
import '../widgets/home_search_field.dart';
import '../widgets/home_service_card.dart';
import '../widgets/news_slider.dart';
import '../widgets/section_header.dart';
import '../widgets/service_detail_sheet.dart';
import '../widgets/summary_tiles.dart';
import '../widgets/tutorial_overlay.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key, this.storage});

  /// Reads and writes `lcc.tutorial_seen` — B10 § 6.10, § 6.11.
  ///
  /// Threaded from the `/` route builder (CR-1 / G-L5: *route builders may
  /// resolve from a locator; no widget may*). **Nullable, and null means "no
  /// tutorial"**: without a storage service there is no gate to read, and a
  /// tutorial that mounted unconditionally would appear over every widget test
  /// that pumps this page directly. Production always supplies it; the gate
  /// itself is exercised by `test/features/home/.../tutorial_gate_test.dart`.
  final StorageService? storage;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  /// `useState showTutorial` — `HomePage.tsx`:211-213. Starts false and is
  /// raised only after the async read says the flag is absent, which is the
  /// Flutter cost of a `localStorage` call that is synchronous in the source.
  bool _showTutorial = false;

  @override
  void initState() {
    super.initState();
    // The mount half. `context.read` is legal in `initState` (it is a lookup,
    // not a subscription) and this is the only place the two authenticated
    // regions can learn about a session that was already resolved before this
    // page existed.
    _syncAuth(context.read<SessionBloc>().state);
    _resolveTutorialGate();
  }

  /// `const seen = localStorage.getItem("lcc_tutorial_seen"); if (!seen)
  /// setShowTutorial(true);` — `HomePage.tsx`:212-213.
  ///
  /// **Independent of the splash's gate.** `manifest.md`:262-264 measured that
  /// dismissing the onboarding splash does *not* set this key, so a fresh
  /// install shows splash → Home → tutorial (`B10-AC-35`).
  Future<void> _resolveTutorialGate() async {
    final StorageService? storage = widget.storage;
    if (storage == null) return;
    final bool seen = await storage.hasSeenTutorial();
    if (!mounted || seen) return;
    setState(() => _showTutorial = true);
  }

  /// `handleTutorialDone` — `HomePage.tsx`:228-231.
  void _dismissTutorial() {
    widget.storage?.markTutorialSeen();
    if (mounted) setState(() => _showTutorial = false);
  }

  void _syncAuth(SessionState session) {
    // `initial` / `loading` is the boot hold `AppRoutes._redirect` also
    // respects: treating an unresolved session as signed out would clear a
    // warm-booted citizen's summary before their token had been read.
    if (session.status == SessionStatus.initial ||
        session.status == SessionStatus.loading) {
      return;
    }
    context.read<HomeBloc>().add(
          HomeAuthChanged(
            isAuthenticated: session.status == SessionStatus.authenticated,
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<SessionBloc, SessionState>(
      // The change half — see `_syncAuth` for the hold on unresolved states.
      listenWhen: (SessionState previous, SessionState current) =>
          previous.status != current.status,
      listener: (BuildContext context, SessionState state) =>
          _syncAuth(state),
      child: BlocBuilder<HomeBloc, HomeState>(
        builder: (BuildContext context, HomeState state) {
          final Widget body = _HomeBody(state: state);
          // `{showTutorial && <TutorialOverlay onDone={handleTutorialDone} />}`
          // — `HomePage.tsx`:791. A `Stack`, not a `showDialog`: the source
          // renders it as a sibling inside the page, so it scrolls with
          // nothing and sits inside the shell's chrome rather than above it.
          if (!_showTutorial) return body;
          return Stack(
            children: <Widget>[
              body,
              Positioned.fill(
                child: TutorialOverlay(onDone: _dismissTutorial),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _HomeBody extends StatelessWidget {
  const _HomeBody({required this.state});

  final HomeState state;

  HomeBloc _bloc(BuildContext context) => context.read<HomeBloc>();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      // The hero is full-bleed and everything under it is gutter-padded, so the
      // scroll view carries no padding of its own — `px-4` lives on the content
      // column (`HomePage.tsx:314`).
      child: ListView(
        padding: EdgeInsets.zero,
        children: <Widget>[
          HeroHeader(
            authenticated: state.isAuthenticated,
            name: state.summary?.name ?? '',
            card: state.digitalId,
            // `onSignIn={() => onTabChange("account")}`. `/account` is
            // protected, so the router's own gate converts it into
            // `/signin?from=%2Faccount` and the citizen lands back on Account
            // after signing in. Hard-coding `/signin` here would drop that
            // intent and duplicate gate logic that already exists.
            onSignIn: () => context.go(AppNameRoutes.account),
            search: HomeSearchField(
              query: state.searchQuery,
              onChanged: (String value) =>
                  _bloc(context).add(HomeSearchChanged(value)),
              onCleared: () => _bloc(context).add(const HomeSearchCleared()),
            ),
          ),
          Padding(
            // `px-4 py-6 space-y-10`
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.gap16,
              vertical: AppSpacing.gap24,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                ..._summaryRegion(context),
                ..._bannerRegion(context),
                _servicesRegion(context),
                if (state.gridMode == ServiceGridMode.quickActions) ...<Widget>[
                  const SizedBox(height: AppSpacing.gap40),
                  SectionHeader(
                    title: 'home.categoriesTitle'.tr(),
                    subtitle: 'home.categoriesSubtitle'.tr(),
                  ),
                  CategorySlider(
                    onSlideTap: () => context.go(AppNameRoutes.service),
                  ),
                ],
                const SizedBox(height: AppSpacing.gap40),
                _newsRegion(context),
                const SizedBox(height: AppSpacing.gap40),
                _faqRegion(context),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── 2. Summary tiles ───────────────────────────────────────────────────────

  List<Widget> _summaryRegion(BuildContext context) {
    if (!state.isAuthenticated) return const <Widget>[];

    Widget? region;
    if (state.summaryStatus == RegionStatus.loading) {
      region = GridView.count(
        crossAxisCount: 2,
        crossAxisSpacing: AppSpacing.gap12,
        mainAxisSpacing: AppSpacing.gap12,
        childAspectRatio: kSummaryTileAspect,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        children: List<Widget>.generate(
          4,
          (_) => const HomeSkeleton(height: AppSpacing.skeletonSummary),
        ),
      );
    } else if (state.summaryStatus == RegionStatus.failure) {
      region = HomeErrorNotice(
        message: 'home.summaryError'.tr(),
        retryLabel: 'home.retry'.tr(),
        onRetry: () => _bloc(context).add(const HomeSummaryRetried()),
      );
    } else if (state.showSummaryTiles) {
      region = SummaryTiles(
        tiles: summaryTilesFor(
          state.summary!,
          Localizations.localeOf(context).languageCode,
          historyPath: AppNameRoutes.history,
          accountPath: AppNameRoutes.account,
          walletPath: AppNameRoutes.wallet,
        ),
        onTileTap: context.go,
      );
    }

    if (region == null) return const <Widget>[];
    return <Widget>[region, const SizedBox(height: AppSpacing.gap40)];
  }

  // ── 3. Action banner ───────────────────────────────────────────────────────

  List<Widget> _bannerRegion(BuildContext context) {
    if (!state.showActionBanner) return const <Widget>[];

    return <Widget>[
      ActionBanner(
        action: state.summary!.nextAction!,
        // `summary.data?.next_action?.tab ?? "history"` —
        // `HomePage.tsx:409`. The tabs the API names are the web's, so they
        // map onto `AppNameRoutes` by the same table `routes.ts`'s
        // `TAB_TO_PATH` holds; anything unrecognised falls to history, which
        // is the source's own default.
        onFollow: (String tab) => context.go(_pathForTab(tab)),
        onDismissConfirmed: () =>
            _bloc(context).add(const HomeBannerDismissed()),
      ),
      const SizedBox(height: AppSpacing.gap40),
    ];
  }

  /// `TAB_TO_PATH` (`routes.ts:12-26`), restricted to the tabs this build
  /// mounts. An unmounted tab (the six certificate routes) falls back to
  /// history rather than navigating nowhere — the same C-3 reasoning
  /// `ServiceAvailability` applies: the client route registry is the authority
  /// on what exists.
  static String _pathForTab(String tab) => switch (tab) {
        'history' => AppNameRoutes.history,
        'account' => AppNameRoutes.account,
        'wallet' => AppNameRoutes.wallet,
        'service' => AppNameRoutes.service,
        'help' => AppNameRoutes.help,
        'news' => AppNameRoutes.news,
        'home' => AppNameRoutes.home,
        _ => AppNameRoutes.history,
      };

  // ── 4. Services ────────────────────────────────────────────────────────────

  Widget _servicesRegion(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        _servicesHeader(context),
        const SizedBox(height: AppSpacing.gap24),
        _servicesBody(context),
      ],
    );
  }

  Widget _servicesHeader(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Semantics(
          header: true,
          child: Text(
            'home.whatDoYouNeed'.tr(),
            style: const TextStyle(
              color: AppColors.gray900,
              fontSize: AppTypography.size24,
              fontWeight: AppTypography.bold,
              height: AppTypography.lineTight,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.gap8),
        Text(
          'home.whatDoYouNeedSub'.tr(),
          style: const TextStyle(
            color: AppColors.gray500,
            fontSize: AppTypography.size14,
            height: AppTypography.lineRelaxed,
          ),
        ),
        const SizedBox(height: AppSpacing.gap12),
        Row(
          children: <Widget>[
            // Both chips render and neither does anything — see the library
            // doc's scope note. They are not omitted because Tier 1 compares
            // the text the web presents, and they are not wired to a
            // half-ported modal because a control whose effect vanishes on
            // restart is worse than one that is inert.
            _chip(glyph: 'Settings2', label: 'home.customize'.tr()),
            const SizedBox(width: AppSpacing.gap8),
            _chip(
              glyph: 'HelpCircle',
              label: 'home.howItWorks'.tr(),
              filled: true,
            ),
          ],
        ),
      ],
    );
  }

  Widget _chip({
    required String glyph,
    required String label,
    bool filled = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.gap12,
        vertical: AppSpacing.gap6,
      ),
      decoration: BoxDecoration(
        color: filled ? AppColors.primarySoft : AppColors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
        border: Border.all(color: AppColors.infoBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          LucideIcon(
            name: glyph,
            size: AppSpacing.gap14,
            color: AppColors.primary,
          ),
          const SizedBox(width: AppSpacing.gap6),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.primary,
              fontSize: AppTypography.size12,
              fontWeight: AppTypography.medium,
            ),
          ),
        ],
      ),
    );
  }

  Widget _servicesBody(BuildContext context) {
    if (state.servicesLoading) {
      return _grid(
        List<Widget>.generate(
          6,
          (_) => const HomeSkeleton(height: AppSpacing.skeletonServiceCard),
        ),
      );
    }

    if (state.servicesFailed) {
      return HomeErrorNotice(
        message: 'home.servicesError'.tr(),
        retryLabel: 'home.retry'.tr(),
        onRetry: () => _bloc(context).add(const HomeServicesRetried()),
      );
    }

    final List<Service> services = state.displayedServices;

    if (services.isEmpty) {
      // Two different sentences, and the source distinguishes them: an empty
      // catalogue is "No services are open for online requests yet."
      // (`:478`), an empty *search* is "No services found" (`:535`). Folding
      // them would tell a citizen who mistyped that the government has no
      // services.
      return HomeEmptyNotice(
        message: state.gridMode == ServiceGridMode.search
            ? 'home.noServicesFound'.tr()
            : 'home.servicesEmpty'.tr(),
      );
    }

    return _grid(<Widget>[
      ...services.map(
        (Service service) => HomeServiceCard(
          service: service,
          onTap: () => _openService(context, service),
        ),
      ),
      // `{!searchQuery.trim() && (…)}` — no "More" tile while searching.
      if (state.gridMode == ServiceGridMode.quickActions)
        MoreServicesTile(onTap: () => context.go(AppNameRoutes.service)),
    ]);
  }

  /// `grid grid-cols-2 gap-4`.
  Widget _grid(List<Widget> children) {
    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: AppSpacing.gap16,
      mainAxisSpacing: AppSpacing.gap16,
      // A grid cell is a fixed box, so this number is the card's height. It is
      // derived, not tuned: at the 390 px rig a cell is 171 wide, and the
      // card's fixed furniture is 40 (padding) + 56 (GlassIcon) + 16 + a
      // two-line title + 4 + 12 + 1 (rule) + 12 + a fee line + 8 + a 28 px
      // chip. 0.55 leaves the description room for three lines in Lao, which
      // wraps wider than English on every one of these six names.
      childAspectRatio: 0.55,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: children,
    );
  }

  /// **C-2's second call site.**
  ///
  /// The predicate is asked here, once, and its answer is handed to the sheet
  /// — which returns it back if the citizen pressed Apply Now. Null means
  /// C-4's no-op, and there is no branch for it: `context.go(null)` is not
  /// reachable because the null is filtered before the call.
  Future<void> _openService(BuildContext context, Service service) async {
    final String? destination =
        ServiceAvailability.forApp.destinationFor(service);

    final String? chosen = await showServiceDetailSheet(
      context,
      service: service,
      destination: destination,
    );

    if (chosen == null || !context.mounted) return;
    context.go(chosen);
  }

  // ── 6. News ────────────────────────────────────────────────────────────────

  Widget _newsRegion(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        SectionHeader(
          title: 'home.latestUpdates'.tr(),
          subtitle: 'home.latestUpdatesSub'.tr(),
        ),
        _newsBody(context),
        const SizedBox(height: AppSpacing.gap16),
        Center(
          child: InkWell(
            onTap: () => context.go(AppNameRoutes.news),
            child: ChevronLabel(
              label: 'home.newsViewAll'.tr(),
              color: AppColors.primary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _newsBody(BuildContext context) {
    return switch (state.newsStatus) {
      RegionStatus.initial || RegionStatus.loading => SizedBox(
          height: AppSpacing.skeletonNewsCard,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: 3,
            separatorBuilder: (_, __) =>
                const SizedBox(width: AppSpacing.gap16),
            itemBuilder: (_, __) => const HomeSkeleton(
              height: AppSpacing.skeletonNewsCard,
              width: 320,
            ),
          ),
        ),
      RegionStatus.failure => HomeErrorNotice(
          message: 'home.newsError'.tr(),
          retryLabel: 'home.retry'.tr(),
          onRetry: () => _bloc(context).add(const HomeNewsRetried()),
        ),
      RegionStatus.success => state.news.isEmpty
          ? HomeEmptyNotice(message: 'home.newsEmpty'.tr())
          : NewsSlider(
              items: state.news,
              onArticleTap: (HomeNewsItem item) => context.go(
                '${AppNameRoutes.news}/${item.slug}',
              ),
            ),
    };
  }

  // ── 7. FAQ ─────────────────────────────────────────────────────────────────

  Widget _faqRegion(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        SectionHeader(
          title: 'home.faqTitle'.tr(),
          subtitle: 'home.faqSubtitle'.tr(),
        ),
        _faqBody(context),
        const SizedBox(height: AppSpacing.gap24),
        Center(
          child: InkWell(
            onTap: () => context.go(AppNameRoutes.help),
            child: ChevronLabel(
              label: 'home.faqBrowseAll'.tr(),
              color: AppColors.primary,
              leading: 'LifeBuoy',
            ),
          ),
        ),
      ],
    );
  }

  Widget _faqBody(BuildContext context) {
    return switch (state.faqStatus) {
      RegionStatus.initial || RegionStatus.loading => Column(
          children: List<Widget>.generate(
            5,
            (int i) => Padding(
              padding: EdgeInsets.only(top: i == 0 ? 0 : AppSpacing.gap12),
              child: const HomeSkeleton(height: AppSpacing.tile56),
            ),
          ),
        ),
      // The source shows a bare sentence with no control here
      // (`HomePage.tsx:745-748`) — see `HomeFaqsRetried`'s doc for why this
      // adds the retry § 6.6 and B2-AC-16 require.
      RegionStatus.failure => HomeErrorNotice(
          message: 'home.faqError'.tr(),
          retryLabel: 'home.retry'.tr(),
          onRetry: () => _bloc(context).add(const HomeFaqsRetried()),
        ),
      RegionStatus.success => state.faqs.isEmpty
          ? HomeEmptyNotice(message: 'home.faqEmpty'.tr())
          : FaqAccordion(
              items: state.faqs,
              openIndex: state.openFaqIndex,
              onToggle: (int index) =>
                  _bloc(context).add(HomeFaqToggled(index)),
            ),
    };
  }
}
