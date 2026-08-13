/// The service catalogue — the pilot page of B2a.
///
/// Port of `lcc-app/src/app/components/ServicePage.tsx:285-538`, the only B2
/// page with a complete public baseline. It is the pilot because it is the one
/// screen that exercises everything the substrate claims to provide at once:
/// 57 of the 86 bundled lucide glyphs, **both** API registries
/// (`/service-categories` and `/services`), the token layer on every colour it
/// draws, and Lao at list scale — 43 service names and 8 category names, which
/// is where a font problem stops being theoretical.
///
/// ## One page, two views
///
/// `showCategoryView` (`ServicePage.tsx:295`) is the whole structure:
///
/// * **true** — no category selected and the search box empty. Renders the
///   `service.categories` label and an 8-tile category grid whose per-tile
///   counts come from the unfiltered catalogue.
/// * **false** — a category was tapped or something was typed. Renders the
///   filtered service cards, optionally under a "N result(s) for …" line.
///
/// Both views carry all four states independently, because they read different
/// requests and can fail independently.
///
/// ## The four states, per view (§ 6.6, B2-AC-16)
///
/// | | loading | data | empty | error |
/// |---|---|---|---|---|
/// | category view | `SkeletonGrid(8)` | 8 tiles | "No categories are published yet." | `CatalogueErrorPanel` + Retry |
/// | list view | `SkeletonGrid(8)` | N cards | `service.emptyTitle` + `emptyDesc` (+ "Browse other categories" when a category is active) | `CatalogueErrorPanel` + Retry |
///
/// This is the whole of the offline story (SSD § 12.1): **no persistent cache,
/// no Hive box**. "Offline-aware" is discharged by the error-with-retry state,
/// not by storage, and adding a cache here would be out of scope *and* would
/// remove the only signal a citizen has that they are looking at stale data.
///
/// Measured today, `/services` returns 43 rows and `/service-categories`
/// returns 8, so **neither empty state can occur against staging by accident**.
/// They are exercised with stubbed empty responses in
/// `test/features/service/presentation/pages/service_page_states_test.dart`,
/// which is the only way they get tested at all before a citizen finds one.
///
/// ## Where the BLoC comes from
///
/// Nowhere in this file. `AppRoutes`' `/service` builder creates it with
/// `BlocProvider(create: (_) => serviceInjection<ServiceBloc>()..add(...))` and
/// this page reads it out of the tree. That is CR-1's seam — *route builders
/// and `main.dart` may resolve from a locator; no widget may* — and G-L5 fails
/// the build if this file so much as names `serviceInjection`.
library;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../presentation/theme/app_colors.dart';
import '../../../../presentation/theme/app_spacing.dart';
import '../../../../presentation/theme/app_typography.dart';
import '../../domain/entities/service.dart';
import '../../domain/entities/service_category.dart';
import '../../domain/service_availability.dart';
import '../bloc/service_bloc.dart';
import '../widgets/bilingual_text.dart';
import '../widgets/catalogue_grid.dart';
import '../widgets/catalogue_header.dart';
import '../widgets/catalogue_panels.dart';
import '../widgets/category_card.dart';
import '../widgets/category_seed.dart';
import '../widgets/service_card.dart';

/// The bilingual sentences `ServicePage.tsx:226-235` keeps inline rather than
/// in the `service` dictionary.
///
/// They are appended to the `service` namespace in `assets/i18n/{en,lo}.json`
/// instead of being hardcoded here, which is a deliberate divergence in
/// *mechanism*: the React `COPY` object exists because that file had no
/// convenient way to reach a namespace it did not own, whereas
/// `easy_localization` makes every namespace reachable from anywhere. The
/// rendered strings are identical in both locales — that is what Tier 1
/// compares — and keeping them out of the JSON would put five user-visible
/// sentences somewhere the i18n key-parity test cannot see them.
class _Copy {
  const _Copy._();

  static String categoriesError() => 'service.categoriesError'.tr();
  static String servicesError() => 'service.servicesError'.tr();
  static String errorHint() => 'service.errorHint'.tr();
  static String retry() => 'service.retry'.tr();
  static String noCategories() => 'service.noCategories'.tr();
}

class ServicePage extends StatefulWidget {
  const ServicePage({super.key, this.availability = ServiceAvailability.forApp});

  /// C-2's predicate. Injected with a default rather than read from a locator
  /// so a test can prove both the no-op branch of today and the navigating
  /// branch of F1 (G-L5 would fail this file for the alternative).
  final ServiceAvailability availability;

  @override
  State<ServicePage> createState() => _ServicePageState();
}

class _ServicePageState extends State<ServicePage> {
  /// Owned by the page, not the BLoC: a `TextEditingController` is a widget
  /// resource with a `dispose`, and putting one in a BLoC would make the BLoC
  /// un-unit-testable and give it a second lifetime to manage. The BLoC holds
  /// the query *value*; this holds the field's cursor and selection.
  final TextEditingController _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _clear() {
    _search.clear();
    context.read<ServiceBloc>().add(const ServiceSearchChanged(''));
  }

  /// `onClick={() => { if (s.tab) onTabChange(s.tab); }}` — C-4. A service with
  /// no client destination is tapped and nothing happens, exactly as on the
  /// web.
  void _openService(Service service) {
    final String? destination = widget.availability.destinationFor(service);
    if (destination == null) return;
    // `go`, not `push`: `onTabChange` in the source *replaces* the active tab
    // rather than stacking a screen, and the certificate routes will be shell
    // children of `/service` (see `AppNameRoutes`' own note), so a push would
    // leave the bottom bar highlighting the wrong destination.
    GoRouter.of(context).go(destination);
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ServiceBloc, ServiceState>(
      builder: (BuildContext context, ServiceState state) {
        final ServiceBloc bloc = context.read<ServiceBloc>();
        final String languageCode =
            Localizations.localeOf(context).languageCode;
        final ServiceCategory? current = state.currentCategory;

        return SafeArea(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                CatalogueHeader(
                  title: current != null
                      ? current.name.forLanguage(languageCode)
                      : 'service.allServices'.tr(),
                  subtitle: current != null
                      ? (kCategorySeeds[current.code]
                              ?.descriptionFor(languageCode) ??
                          '')
                      : 'service.subtitle'.tr(),
                  searchController: _search,
                  onSearchChanged: (String q) =>
                      bloc.add(ServiceSearchChanged(q)),
                  onClear: _clear,
                  showBack: state.activeCategory != null,
                  onBack: () => bloc.add(const ServiceCategorySelected(null)),
                ),
                Padding(
                  // `px-4 py-6`
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.gap16,
                    vertical: AppSpacing.gap24,
                  ),
                  child: state.showCategoryView
                      ? _CategoryView(state: state, bloc: bloc)
                      : _ListView(
                          state: state,
                          bloc: bloc,
                          onOpen: _openService,
                        ),
                ),
                // `<div className="h-4" />` — the source's trailing spacer.
                const SizedBox(height: AppSpacing.gap16),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// `showCategoryView === true` — `ServicePage.tsx:416-476`.
class _CategoryView extends StatelessWidget {
  const _CategoryView({required this.state, required this.bloc});

  final ServiceState state;
  final ServiceBloc bloc;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        // `text-xs text-gray-500 uppercase tracking-wider mb-3`
        Text(
          'service.categories'.tr().toUpperCase(),
          style: const TextStyle(
            fontSize: AppTypography.size12,
            color: AppColors.gray500,
            // `tracking-wider` — 0.05em at 12 px.
            letterSpacing: 0.6,
          ),
        ),
        const SizedBox(height: AppSpacing.gap12),
        _body(context),
      ],
    );
  }

  Widget _body(BuildContext context) {
    switch (state.catalogueStatus) {
      case CatalogueStatus.initial:
      case CatalogueStatus.loading:
        return const SkeletonGrid();

      case CatalogueStatus.failure:
        return CatalogueErrorPanel(
          // `categoriesQuery.error ? categoriesError : servicesError`
          message:
              state.catalogueErrorSource == CatalogueErrorSource.categories
                  ? _Copy.categoriesError()
                  : _Copy.servicesError(),
          hint: _Copy.errorHint(),
          retryLabel: _Copy.retry(),
          onRetry: () => bloc.add(const ServiceCatalogueRetried()),
        );

      case CatalogueStatus.success:
        if (state.categories.isEmpty) {
          return CatalogueEmptyPanel(message: _Copy.noCategories());
        }
        final Map<String, int> counts = state.counts;
        return CatalogueGrid(
          children: state.categories
              .map((ServiceCategory c) => CategoryCard(
                    category: c,
                    count: counts[c.code] ?? 0,
                    onTap: () => bloc.add(ServiceCategorySelected(c.code)),
                  ))
              .toList(growable: false),
        );
    }
  }
}

/// `showCategoryView === false` — `ServicePage.tsx:478-531`.
class _ListView extends StatelessWidget {
  const _ListView({
    required this.state,
    required this.bloc,
    required this.onOpen,
  });

  final ServiceState state;
  final ServiceBloc bloc;
  final ValueChanged<Service> onOpen;

  @override
  Widget build(BuildContext context) {
    final bool showResultCount = state.searchQuery.isNotEmpty &&
        !state.listLoading &&
        state.listStatus != ServiceListStatus.failure;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        if (showResultCount) ...<Widget>[
          // `text-xs text-gray-500 mb-3`
          Text(
            'service.resultsFor'.tr(
              namedArgs: <String, String>{
                'count': '${state.services.length}',
                'q': state.searchQuery,
              },
            ),
            style: const TextStyle(
              fontSize: AppTypography.size12,
              color: AppColors.gray500,
            ),
          ),
          const SizedBox(height: AppSpacing.gap12),
        ],
        _body(context),
      ],
    );
  }

  Widget _body(BuildContext context) {
    // Order matters and is the source's: `listLoading` is tested BEFORE
    // `listQuery.error`, so a retry shows the skeleton rather than flashing the
    // old error panel while the new request is in flight.
    if (state.listLoading) return const SkeletonGrid();

    if (state.listStatus == ServiceListStatus.failure) {
      return CatalogueErrorPanel(
        message: _Copy.servicesError(),
        hint: _Copy.errorHint(),
        retryLabel: _Copy.retry(),
        onRetry: () => bloc.add(const ServiceListRetried()),
      );
    }

    if (state.services.isEmpty) {
      return CatalogueEmptyPanel(
        message: 'service.emptyTitle'.tr(),
        hint: 'service.emptyDesc'.tr(),
        // The pill only appears when a category is active — with a search and
        // no category there is no "other category" to go back to.
        actionLabel: state.activeCategory != null
            ? 'service.browseOther'.tr()
            : null,
        onAction: state.activeCategory != null
            ? () => bloc.add(const ServiceCategorySelected(null))
            : null,
      );
    }

    return CatalogueGrid(
      children: state.services
          .map((Service s) =>
              ServiceCard(service: s, onTap: () => onOpen(s)))
          .toList(growable: false),
    );
  }
}
