/// The chat launcher — `CustomerServiceChat.tsx:194-563` in one widget.
///
/// A **feature** widget composed into the shell, not a shell widget. It is
/// mounted by the `ShellRoute` builder in `lib/utils/routes/app_routes.dart`,
/// which wraps it in its `BlocProvider<ChatBloc>` and hands the pair to
/// `AppShell.floatingAction` — the slot B9a added and left null. Nothing under
/// `lib/presentation/**` names this class, imports this file, or knows the
/// feature exists; that is the seam specs.md § 6.4 rules and **G-L7** is what
/// keeps it true.
///
/// ## Why the panel lives in this widget and not beside it
///
/// The source renders the panel and the button as **mutually exclusive**
/// siblings — `{open && <panel>}` (`:197`) and `{!open && <button>}` (`:544`) —
/// both fixed at `bottom-24 right-4`. One slot, one widget at a time, so one
/// widget here, ternary inside. Splitting them would need two composition slots
/// on `AppShell` for two things that are never both on screen.
///
/// ## Main tabs only, structurally — no flag, no route list
///
/// `Layout.tsx:385` renders `{!isSubPage && <CustomerServiceChat />}` where
/// `isSubPage = !MAIN_TABS.has(activeTab)`. Flutter's `ShellRoute` boundary
/// **is** that set: the five main tabs are its children and `/signin`, `/help`,
/// `/news`, `/debug` are mounted outside it, so a sub-page never builds this
/// widget. `grep -rn "isSubPage\|MAIN_TABS" lib/` is empty and B9-AC-41 asserts
/// it stays that way — the same argument `app_shell.dart:34-42` already makes
/// for the bottom nav (§ 6.3).
///
/// ## Where the session comes from, and why it is read twice
///
/// [ChatAuthChanged] is read off the app-wide `SessionBloc` — a provider read,
/// not a locator read — once in `initState` and again from a `BlocListener`.
/// `notification_bell.dart` records why the listener alone is not enough and it
/// applies verbatim: `ChatBloc` is a `registerFactory` behind
/// `BlocProvider(create:)`, so a fresh one starting at `isAuthenticated: false`
/// is built whenever the shell is rebuilt, against a `SessionBloc` that may not
/// transition again.
///
/// `initial` / `loading` is held rather than treated as signed out, matching
/// `AppRoutes._redirect`'s boot hold: a warm-booted citizen must not see the
/// sign-in prompt for the moment it takes to read their token.
library;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/session/bloc/session_bloc.dart';
import '../../../../presentation/theme/app_colors.dart';
import '../bloc/chat_bloc.dart';
import 'chat_panel.dart';

/// `w-14 h-14` — `:549`.
const double kChatLauncherSize = 56;

class ChatLauncher extends StatefulWidget {
  const ChatLauncher({super.key});

  @override
  State<ChatLauncher> createState() => _ChatLauncherState();
}

class _ChatLauncherState extends State<ChatLauncher> {
  @override
  void initState() {
    super.initState();
    // The mount half — see the library doc. `context.read` in `initState` is a
    // lookup, not a subscription, and it is the only place a launcher built
    // after the session resolved can learn about it.
    _syncAuth(context.read<SessionBloc>().state);
  }

  void _syncAuth(SessionState session) {
    if (session.status == SessionStatus.initial ||
        session.status == SessionStatus.loading) {
      return;
    }
    context.read<ChatBloc>().add(
          ChatAuthChanged(session.status == SessionStatus.authenticated),
        );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<SessionBloc, SessionState>(
      listenWhen: (SessionState previous, SessionState current) =>
          previous.status != current.status,
      listener: (BuildContext context, SessionState state) => _syncAuth(state),
      child: BlocBuilder<ChatBloc, ChatState>(
        // `{open && <panel>}` / `{!open && <button>}` — one or the other, never
        // both, never neither.
        builder: (BuildContext context, ChatState state) => state.open
            ? const ChatPanel()
            : ChatLauncherButton(
                unread: state.unread,
                onPressed: () =>
                    context.read<ChatBloc>().add(const ChatOpened()),
              ),
      ),
    );
  }
}

/// The floating button — `:544-561`.
///
/// Public so the Tier 1 launcher views can pump it without a session or a
/// router in the tree.
class ChatLauncherButton extends StatelessWidget {
  const ChatLauncherButton({
    super.key,
    required this.unread,
    required this.onPressed,
  });

  /// `live ? 0 : Σ th.unread_citizen` — `:127`, already computed by the BLoC.
  final int unread;

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      // `aria-label={t("openChat")}` — `:547`.
      label: 'chat.openChat'.tr(),
      button: true,
      child: SizedBox(
        width: kChatLauncherSize,
        height: kChatLauncherSize,
        child: Stack(
          // The badge sits at `-top-1 -right-1` (`:555`), i.e. outside the
          // button's own box; without this it is clipped.
          clipBehavior: Clip.none,
          children: <Widget>[
            Material(
              // `#344EAD` — inline hex at `:550`.
              color: AppColors.primary,
              shape: const CircleBorder(),
              // `shadow-xl` — `:549`.
              elevation: 6,
              shadowColor: AppColors.cardShadowMedium,
              child: InkWell(
                onTap: onPressed,
                customBorder: const CircleBorder(),
                child: const SizedBox(
                  width: kChatLauncherSize,
                  height: kChatLauncherSize,
                  child: Icon(
                    // lucide `MessageCircle`, `w-6 h-6 text-white` — `:552`.
                    Icons.chat_bubble_outline,
                    size: 24,
                    color: AppColors.white,
                  ),
                ),
              ),
            ),
            // `{unread > 0 && …}` — `:553-559`. A **red circle with the
            // number** in it.
            //
            // Deliberately not the notification bell's idiom: that one is a
            // numberless amber dot that shows when SIGNED OUT (`Layout.tsx:172`,
            // `!isAuthenticated || unreadCount > 0`). Two badges, one shell, two
            // different numbers, and § 2.2 Finding B rules that they must not be
            // unified. B9-AC-34 asserts both.
            if (unread > 0)
              Positioned(
                top: -4,
                right: -4,
                child: Container(
                  width: 20,
                  height: 20,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    // `bg-red-500`. Tailwind v4 `red-500` is
                    // `oklch(63.7% 0.237 25.331)` = `#FB2C36`, which is
                    // already in the theme as `dangerGlyph`; a fourth name for
                    // it would be the mistake `categoryAccentFallback`'s own
                    // doc apologises for.
                    color: AppColors.dangerGlyph,
                    shape: BoxShape.circle,
                    // `border-2 border-white` — `:555`.
                    border: Border.all(color: AppColors.white, width: 2),
                  ),
                  child: Text(
                    '$unread',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.white,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
