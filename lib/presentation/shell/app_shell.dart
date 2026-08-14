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
/// This widget reads none, and B9a did not change that. The only
/// session-dependent chrome in the React header is the notification bell, and
/// it is composed in through [topBarActions] as an already-built widget that
/// reads `SessionBloc` for itself. The per-tab affordances that depend on the
/// session — the home sign-in CTA, the account sign-out button — do the same in
/// their own pages, via `BlocSelector`/`BlocProvider.of` against the app-wide
/// `SessionBloc` that `main.dart` provides above the router. Keeping the shell
/// session-agnostic means a session transition rebuilds one widget, not the
/// whole chrome.
///
/// ## The two composition slots (B9a, specs.md § 6.4)
///
/// [topBarActions] and [floatingAction] are how the shell hosts a widget it
/// **cannot name**. `ssd.md`:255 forbids `lib/presentation/**` from importing
/// `features/*/presentation/**`; the `ShellRoute` builder in
/// `lib/utils/routes/app_routes.dart` is not under `lib/presentation/**`, is
/// already the sanctioned place to resolve from a container (CR-1), and is
/// therefore where the `BlocProvider` + feature widget pair is assembled.
///
/// **G-L7** (`test/architecture/layering_rules.dart`, landed by B9a and proved
/// to fire against a planted fixture) is what turns that from a convention into
/// a build failure.
///
/// [floatingAction] was added by B9a and is filled by **B9b**, whose chat
/// launcher is its only consumer. The slot landed with B9a rather than with its
/// consumer because the two sub-batches would otherwise both edit this file,
/// which is the merge conflict § 2.3 splits the batch to avoid — and the split
/// worked: B9b changed nothing here but this sentence.
///
/// Two feature widgets now come through the two slots and this file still names
/// neither of them, which is what makes G-L7 a proven mechanism rather than a
/// signature nothing exercises (§ 8.1(2)).
library;

import 'package:flutter/material.dart';

import '../../core/storage/storage_service.dart';
import 'app_bottom_nav.dart';
import 'app_top_bar.dart';

class AppShell extends StatelessWidget {
  const AppShell({
    super.key,
    required this.location,
    required this.child,
    required this.storage,
    this.topBarActions = const <Widget>[],
    this.floatingAction,
  });

  /// `GoRouterState.matchedLocation` for the page currently in [child].
  final String location;

  /// The active route's page, built by the `ShellRoute`.
  final Widget child;

  /// Passed straight through to [AppTopBar] → `LanguageToggle`.
  ///
  /// CR-1's seam: the `ShellRoute` builder in
  /// `lib/utils/routes/app_routes.dart` is a route builder, so it is allowed
  /// to resolve this from the container. The shell is a widget, so it is not —
  /// it only forwards what it was handed.
  final StorageService storage;

  /// Forwarded unchanged to `AppTopBar.trailingActions`. B9a supplies the
  /// notification bell here; empty is a valid shell.
  final List<Widget> topBarActions;

  /// `Scaffold.floatingActionButton` — B9b's chat launcher.
  ///
  /// The launcher's "main tabs only" rule (`Layout.tsx:385`'s
  /// `{!isSubPage && …}`) needs **no flag and no route list** in Flutter: the
  /// five main tabs are the `ShellRoute`'s children and every other route is
  /// mounted outside it, so a sub-page simply never builds this widget. That is
  /// the same structural argument the bottom bar makes above, and it is why
  /// specs.md § 6.3 rules that `isSubPage` must not appear anywhere in B9.
  final Widget? floatingAction;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppTopBar(storage: storage, trailingActions: topBarActions),
      body: child,
      floatingActionButton: floatingAction,
      bottomNavigationBar: AppBottomNav(location: location),
    );
  }
}
