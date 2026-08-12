/// The five primary destinations of the app shell.
///
/// Single port of three things that were separate in the React source and
/// only ever moved together:
///
/// - `NAV_ITEMS` (`Layout.tsx`) — the ordered id + icon list.
/// - `MAIN_TABS` (`Layout.tsx`) — the set of tabs that *show* the bottom nav.
/// - `TAB_TO_PATH` (`routes.ts`) — the id → path map.
///
/// In Flutter those collapse into one ordered list: membership in [shellTabs]
/// *is* membership in `MAIN_TABS`, because the router mounts exactly these
/// five inside the `ShellRoute` and everything else outside it (see
/// `app_routes.dart`). There is no `translate-y-full` equivalent to maintain —
/// a route that is not a shell child simply has no bottom bar in its tree.
///
/// Labels are i18n keys into the `layout` namespace, whose values are the same
/// `t(item.id)` lookups the React bottom nav performs.
library;

import 'package:flutter/material.dart';

import '../../utils/routes/app_name_routes.dart';

@immutable
class ShellTab {
  const ShellTab({
    required this.path,
    required this.labelKey,
    required this.icon,
    required this.selectedIcon,
  });

  /// Absolute `go_router` path — the [AppNameRoutes] constant, never a literal.
  final String path;

  /// `easy_localization` key, e.g. `layout.home`.
  final String labelKey;

  final IconData icon;
  final IconData selectedIcon;
}

/// Ordered destinations. Order is load-bearing: it is both the bottom-bar
/// order and the index space [shellTabIndexFor] returns.
///
/// Icon choices map the lucide icons in `NAV_ITEMS` onto their Material
/// equivalents: `Home`→home, `LayoutGrid`→grid_view, `History`→history,
/// `Wallet`→account_balance_wallet, `User`→person.
const List<ShellTab> shellTabs = <ShellTab>[
  ShellTab(
    path: AppNameRoutes.home,
    labelKey: 'layout.home',
    icon: Icons.home_outlined,
    selectedIcon: Icons.home,
  ),
  ShellTab(
    path: AppNameRoutes.service,
    labelKey: 'layout.service',
    icon: Icons.grid_view_outlined,
    selectedIcon: Icons.grid_view,
  ),
  ShellTab(
    path: AppNameRoutes.history,
    labelKey: 'layout.history',
    icon: Icons.history_outlined,
    selectedIcon: Icons.history,
  ),
  ShellTab(
    path: AppNameRoutes.wallet,
    labelKey: 'layout.wallet',
    icon: Icons.account_balance_wallet_outlined,
    selectedIcon: Icons.account_balance_wallet,
  ),
  ShellTab(
    path: AppNameRoutes.account,
    labelKey: 'layout.account',
    icon: Icons.person_outline,
    selectedIcon: Icons.person,
  ),
];

/// Index of the tab owning [location], or `0` (home) when none matches.
///
/// A sub-route counts as its parent tab (`/service/resident-certificate` keeps
/// Service highlighted) — the same thing the React `activeTab` does for the
/// certificate pages. Home is excluded from the prefix test because its path
/// is `/`, which prefixes everything; it only matches exactly.
int shellTabIndexFor(String location) {
  for (int i = 0; i < shellTabs.length; i++) {
    final String path = shellTabs[i].path;
    if (location == path) return i;
    if (path != AppNameRoutes.home && location.startsWith('$path/')) return i;
  }
  return 0;
}
