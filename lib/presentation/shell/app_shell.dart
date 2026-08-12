/// The application shell: brand bar, active page, bottom nav.
///
/// Port of the `Layout` component in
/// `lcc-app/src/app/components/Layout.tsx`, mounted by the `ShellRoute` in
/// `lib/utils/routes/app_routes.dart`.
///
/// ## Why `ShellRoute` and not `StatefulShellRoute`
///
/// `StatefulShellRoute.indexedStack` gives every tab its own `Navigator` and
/// keeps all five branches alive so each remembers its scroll offset and
/// nested stack. That is the right tool when tabs are independent workspaces.
/// It is the wrong tool here, for reasons that come straight from the source
/// being ported:
///
/// 1. **The React app deliberately does not preserve per-tab state.**
///    `Layout.tsx` runs `mainRef.current?.scrollTo({top: 0})` on every
///    `activeTab` change — "the scroll container otherwise keeps the previous
///    page's offset". Choosing an indexed stack would re-introduce exactly the
///    behaviour the source removes on purpose.
/// 2. **The auth gate is a single global `redirect`.** With one navigator
///    there is one location to reason about; with five parallel branches a
///    redirect off `/account` has to consider the state of branches the
///    citizen cannot see.
/// 3. **P0 tabs are placeholders.** There is no state to preserve yet, so the
///    extra machinery would be paid for now and justified later — and
///    `DECISION-MATRIX.md`'s tie-break is simplicity, then reliability.
///
/// A plain wrapper widget (each page building its own `Scaffold` with a copy
/// of the bars) was the third option and is the worst: it duplicates the
/// chrome five times, and rebuilding the `AppBar`/`NavigationBar` on every
/// navigation loses the M3 destination-selection animation. `ShellRoute`
/// keeps one `Scaffold` alive and swaps only [child].
///
/// ## How the bottom bar disappears on sub-pages
///
/// It is structural, not conditional. `MAIN_TABS` + the `translate-y-full`
/// transform in the React source exist because that app renders one component
/// tree for every route. Here, the five main tabs are children of the
/// `ShellRoute` and therefore get this widget; `/signin`, `/help`, `/news`,
/// `/debug` and the certificate sub-routes to come are mounted *outside* it
/// and simply never build a bottom bar. No visibility flag to keep in sync
/// with a route list, and no chance of the two disagreeing.
///
/// ## Session state
///
/// This widget reads none. The only session-dependent chrome in the React
/// header is the notification bell, which P0 defers (see `AppTopBar`). The
/// per-tab affordances that *do* depend on the session — the home sign-in CTA
/// and the account sign-out button — read it in their own pages via
/// `BlocSelector`/`BlocProvider.of` against the app-wide `SessionBloc` that
/// `main.dart` provides above the router. Keeping the shell session-agnostic
/// means a session transition rebuilds one page, not the whole chrome.
library;

import 'package:flutter/material.dart';

import 'app_bottom_nav.dart';
import 'app_top_bar.dart';

class AppShell extends StatelessWidget {
  const AppShell({
    super.key,
    required this.location,
    required this.child,
  });

  /// `GoRouterState.matchedLocation` for the page currently in [child].
  final String location;

  /// The active route's page, built by the `ShellRoute`.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const AppTopBar(),
      body: child,
      bottomNavigationBar: AppBottomNav(location: location),
    );
  }
}
