/// The brand bar at the top of every main-tab screen.
///
/// Port of the `<header>` block in `lcc-app/src/app/components/Layout.tsx`:
/// brand mark + `layout.brand` / `layout.brandSub` on the left, controls on
/// the right.
///
/// ## Differences from the React source, and why
///
/// - **No logo image.** `Layout.tsx` renders `imports/logo-lcc.png`. Copying a
///   binary asset into this repo would add a path outside GOR-245 § 3.1's
///   asset scope (`assets/i18n/*.json`), so the mark is a white rounded tile
///   with `Icons.account_balance` — the same visual weight, no new asset. The
///   image is decorative next to the brand wordmark, which is present.
/// - **No desktop centre nav.** `Layout.tsx` renders a `hidden lg:flex` row of
///   tab links for wide viewports. This is a handset app; the bottom nav is
///   the only primary navigation, so the duplicate row is dropped rather than
///   ported to a breakpoint that never fires.
/// ## The notification bell (B9a) — composed, never named
///
/// P0 deferred it (`P0 tanpa notification bell (P1-9 batch berikutnya)`) and
/// B9a lands it — **without this file learning that it exists**. `ssd.md`:255
/// forbids `lib/presentation/**` from importing `features/*/presentation/**`,
/// and `AppTopBar` naming `NotificationBell` would be exactly that: the widget
/// needs its BLoC type, and the BLoC type lives in
/// `features/notifications/presentation/bloc/`.
///
/// So the bar takes [trailingActions] and the `ShellRoute` builder in
/// `lib/utils/routes/app_routes.dart` supplies
/// `BlocProvider<NotificationsBloc>(child: NotificationBell())`. Three
/// alternatives were measured and rejected in specs.md § 6.4 — a shell-side
/// widget (still needs the BLoC type), promoting the BLoC to `lib/core/`
/// (§ 4.5 is a closed list of one), and a locator read (G-L5 forbids it).
///
/// This is not a new seam. It is CR-1's — *"route builders and `main.dart` may
/// resolve from a locator; no widget may"* — applied to a widget instead of a
/// page, and it is the same mechanism [storage] below already documents.
///
/// **The payoff is that this file stays pumpable with nothing.**
/// `AppTopBar(storage: …)` builds with no container, no BLoC and no feature in
/// the tree, because `trailingActions` defaults to empty. **G-L7**
/// (`test/architecture/layering_rules.dart`) is what keeps it that way; it is
/// proved to fire against a planted fixture in `guard_selftest_test.dart`.
///
/// Tapping the brand block goes home, matching the React `<a href={tabHref
/// ("home")}>` wrapper.
library;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/storage/storage_service.dart';
import '../../utils/routes/app_name_routes.dart';
import '../theme/app_colors.dart';
import 'app_brand.dart';
import 'language_toggle.dart';

class AppTopBar extends StatelessWidget implements PreferredSizeWidget {
  const AppTopBar({
    super.key,
    required this.storage,
    this.trailingActions = const <Widget>[],
  });

  /// Widgets appended after [LanguageToggle] in the bar's `actions:` list.
  ///
  /// `Layout.tsx:361-367` renders exactly this pair in exactly this order —
  /// `<LanguageToggle />` then `<NotificationMenu />` — inside a `gap-2` row on
  /// the right. The list is a `List<Widget>` rather than a single `Widget?`
  /// because the source's container is a row that already holds two children
  /// and B10 owns `presentation/common/`; a second composed control there must
  /// not need this signature changed again.
  ///
  /// **Defaulted, so every existing call site and every widget test keeps
  /// working unchanged** — which is the property specs.md § 6.16(1) makes B9's
  /// exit contract to B10.
  final List<Widget> trailingActions;

  /// Threaded down to [LanguageToggle], which persists the chosen language.
  ///
  /// The bar itself has no use for it. It is here because CR-1's seam puts the
  /// only sanctioned `injection<StorageService>()` call in the `ShellRoute`
  /// builder, and this widget sits between that builder and the one widget
  /// that needs the value. Passing it explicitly is the cost of not letting a
  /// widget reach into a global container.
  final StorageService storage;

  @override
  Size get preferredSize => const Size.fromHeight(AppBrand.topBarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      titleSpacing: 16,
      title: InkWell(
        onTap: () => context.go(AppNameRoutes.home),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.account_balance,
                  size: 22,
                  color: AppBrand.primary,
                ),
              ),
              const SizedBox(width: 10),
              Flexible(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'layout.brand'.tr(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.white,
                        fontSize: 13,
                        height: 1.2,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.3,
                      ),
                    ),
                    Text(
                      'layout.brandSub'.tr(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: AppColors.white.withValues(alpha: 0.75),
                        fontSize: 11,
                        height: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      actions: <Widget>[
        // Not `const`: `storage` is a runtime value, so neither this element
        // nor the list around it can be constant any more.
        LanguageToggle(storage: storage),
        // `Layout.tsx:361-367`'s `gap-2` between the toggle and the bell.
        // Spread rather than a single slot, and AFTER the toggle, because that
        // is the source's order (§ 6.4).
        for (final Widget action in trailingActions) ...<Widget>[
          const SizedBox(width: 8),
          action,
        ],
        const SizedBox(width: 12),
      ],
    );
  }
}
