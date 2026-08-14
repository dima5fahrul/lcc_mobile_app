/// The five-destination bottom bar.
///
/// Port of the mobile `<nav>` at the foot of
/// `lcc-app/src/app/components/Layout.tsx`. The React version renders anchors
/// and highlights the active one with a `glassTile("#344EAD")` pill; the M3
/// [NavigationBar] draws the same affordance natively through its selection
/// indicator, which is themed to the brand tint in `AppBrand.light()`.
///
/// `BottomNavigationBar` was the alternative. [NavigationBar] wins on three
/// counts: it is the Material 3 component (the app is `useMaterial3: true`, so
/// the legacy bar would be visually out of step), its selection indicator is
/// the built-in equivalent of the React active pill instead of a colour swap,
/// and it carries the correct `Semantics` for a tab set without hand-rolling
/// them. It also handles five destinations without the `fixed` vs `shifting`
/// type juggling `BottomNavigationBar` needs at that count.
library;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'shell_tabs.dart';

class AppBottomNav extends StatelessWidget {
  const AppBottomNav({super.key, required this.location});

  /// The router's `matchedLocation`, used to derive the selected index.
  final String location;

  @override
  Widget build(BuildContext context) {
    final int index = shellTabIndexFor(location);

    return NavigationBar(
      selectedIndex: index,
      onDestinationSelected: (int i) {
        final String target = shellTabs[i].path;
        // `go` (not `push`) so the tabs stay siblings and never stack —
        // the React nav replaces the hash rather than growing history.
        if (target != location) context.go(target);
      },
      destinations: <Widget>[
        for (final ShellTab tab in shellTabs)
          NavigationDestination(
            icon: Icon(tab.icon),
            selectedIcon: Icon(tab.selectedIcon),
            label: tab.labelKey.tr(context: context),
            tooltip: tab.labelKey.tr(context: context),
          ),
      ],
    );
  }
}
