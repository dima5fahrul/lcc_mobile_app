/// The header notification bell — `Layout.tsx:96-296`'s `NotificationMenu`.
///
/// A **feature** widget composed into the shell, not a shell widget. It is
/// mounted by the `ShellRoute` builder in `lib/utils/routes/app_routes.dart`,
/// which wraps it in its `BlocProvider<NotificationsBloc>` and hands the pair
/// to `AppTopBar.trailingActions`. Nothing under `lib/presentation/**` names
/// this class, imports this file, or knows the feature exists — that is the
/// seam specs.md § 6.4 rules and **G-L7** is what keeps it true.
///
/// ## Where the session comes from, and why it is dispatched twice
///
/// [NotificationsAuthChanged] is read off the app-wide `SessionBloc` — a
/// provider read, not a locator read — once in `initState` and again from a
/// `BlocListener`. `home_page.dart`'s header records why the listener alone is
/// not enough and it applies verbatim here: `NotificationsBloc` is a
/// `registerFactory` behind `BlocProvider(create:)`, so a fresh one starting at
/// `isAuthenticated: false` is built whenever the shell is rebuilt, against a
/// `SessionBloc` that may not transition again.
///
/// `initial` / `loading` is held rather than treated as signed out, matching
/// `AppRoutes._redirect`'s boot hold: a warm-booted citizen must not see the
/// signed-out prompt for the moment it takes to read their token.
///
/// ## Why `MenuAnchor`
///
/// The source's dropdown closes on an outside `mousedown` and on Escape
/// (`Layout.tsx:146-160`) — twenty lines of listener wiring whose entire
/// purpose Flutter's `MenuAnchor` already provides, with the correct focus and
/// semantics behaviour attached. The alternative, an `OverlayPortal` plus a
/// hand-rolled barrier, would be reimplementing those two behaviours and would
/// have to be tested for them.
///
/// The BLoC stays the single source of truth for `open`: this widget pushes
/// state changes into the controller and reports the controller's own
/// dismissals back as [NotificationsMenuDismissed]. `_syncMenu` is guarded on
/// `isOpen` so the two cannot loop.
library;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/session/bloc/session_bloc.dart';
import '../../../../presentation/theme/app_colors.dart';
import '../../../../utils/routes/app_name_routes.dart';
import '../../domain/entities/notification_entities.dart';
import '../bloc/notifications_bloc.dart';
import 'notif_style.dart';
import 'notification_menu_sheet.dart';

/// `w-9 h-9` — `Layout.tsx:169`.
const double kNotificationBellSize = 36;

class NotificationBell extends StatefulWidget {
  const NotificationBell({super.key});

  @override
  State<NotificationBell> createState() => _NotificationBellState();
}

class _NotificationBellState extends State<NotificationBell> {
  final MenuController _menu = MenuController();

  @override
  void initState() {
    super.initState();
    // The mount half — see the library doc. `context.read` in `initState` is a
    // lookup, not a subscription, and it is the only place a bell built after
    // the session resolved can learn about it.
    _syncAuth(context.read<SessionBloc>().state);
  }

  void _syncAuth(SessionState session) {
    if (session.status == SessionStatus.initial ||
        session.status == SessionStatus.loading) {
      return;
    }
    context.read<NotificationsBloc>().add(
          NotificationsAuthChanged(
            session.status == SessionStatus.authenticated,
          ),
        );
  }

  /// Drives the overlay from BLoC state, never the other way round.
  void _syncMenu(bool open) {
    if (open == _menu.isOpen) return;
    open ? _menu.open() : _menu.close();
  }

  /// `setOpen(false); onTabChange(tab)` then the mark-read — `:129-137`.
  ///
  /// Navigation happens **here and first**, exactly as the source orders it:
  /// `onTabChange` at `:132` precedes the `await` at `:134`. The BLoC owns the
  /// close and the POST because neither needs a `BuildContext`; this owns the
  /// `go` because it does.
  void _openNotification(CitizenNotification item) {
    context.read<NotificationsBloc>().add(NotificationOpened(item));
    // `NOTIF_STYLE[item.category]?.tab ?? NOTIF_FALLBACK.tab` — `:131`.
    context.go(notifStyleFor(item.category).tab);
  }

  void _goTo(String path) {
    context.read<NotificationsBloc>().add(const NotificationsMenuDismissed());
    context.go(path);
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<SessionBloc, SessionState>(
      listenWhen: (SessionState previous, SessionState current) =>
          previous.status != current.status,
      listener: (BuildContext context, SessionState state) => _syncAuth(state),
      child: BlocConsumer<NotificationsBloc, NotificationsState>(
        listenWhen: (NotificationsState p, NotificationsState c) =>
            p.open != c.open,
        listener: (BuildContext context, NotificationsState state) =>
            _syncMenu(state.open),
        builder: (BuildContext context, NotificationsState state) {
          return MenuAnchor(
            controller: _menu,
            // `absolute right-0 top-full mt-2` — `:184`.
            alignmentOffset: const Offset(0, 8),
            style: MenuStyle(
              // The sheet draws its own surface, border, radius and shadow, so
              // the anchor contributes geometry only. Without this the panel
              // sits inside a second Material card.
              padding: const WidgetStatePropertyAll<EdgeInsets>(EdgeInsets.zero),
              // `AppColors.transparent`, not `Colors.transparent`:
              // `color_literal_test.dart` enforces B2-AC-11 over
              // `Colors.<name>` too, and it caught all three of these.
              backgroundColor:
                  const WidgetStatePropertyAll<Color>(AppColors.transparent),
              elevation: const WidgetStatePropertyAll<double>(0),
              shadowColor:
                  const WidgetStatePropertyAll<Color>(AppColors.transparent),
              surfaceTintColor:
                  const WidgetStatePropertyAll<Color>(AppColors.transparent),
              maximumSize: const WidgetStatePropertyAll<Size>(
                Size(kNotificationMenuWidth, double.infinity),
              ),
            ),
            // An outside tap or Escape closes the overlay without going through
            // the BLoC, so the state has to be told. Guarded on `state.open` so
            // a close this widget itself initiated does not re-dispatch.
            onClose: () {
              if (!context.read<NotificationsBloc>().state.open) return;
              context
                  .read<NotificationsBloc>()
                  .add(const NotificationsMenuDismissed());
            },
            menuChildren: <Widget>[
              NotificationMenuSheet(
                onSignIn: () => _goTo(AppNameRoutes.account),
                onViewAll: () => _goTo(AppNameRoutes.history),
                onOpenNotification: _openNotification,
              ),
            ],
            builder: (BuildContext context, MenuController _, Widget? __) =>
                _BellButton(
              showsDot: state.showsDot,
              expanded: state.open,
              onPressed: () => context
                  .read<NotificationsBloc>()
                  .add(const NotificationsMenuToggled()),
            ),
          );
        },
      ),
    );
  }
}

/// The button itself — `Layout.tsx:164-178`.
class _BellButton extends StatelessWidget {
  const _BellButton({
    required this.showsDot,
    required this.expanded,
    required this.onPressed,
  });

  final bool showsDot;

  /// `aria-expanded={open}` — `:168`.
  final bool expanded;

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      // `aria-label={t("notifOpen")}` + `aria-haspopup="menu"` — `:166-168`.
      label: 'layout.notifOpen'.tr(),
      button: true,
      expanded: expanded,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: kNotificationBellSize,
          height: kNotificationBellSize,
          decoration: BoxDecoration(
            // `bg-white/15 border border-white/20` — `:169`.
            color: AppColors.white.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.white.withValues(alpha: 0.20)),
          ),
          child: Stack(
            children: <Widget>[
              const Center(
                child: Icon(
                  // lucide `Bell`, `w-4 h-4 text-white` — `:171`.
                  Icons.notifications_outlined,
                  size: 16,
                  color: AppColors.white,
                ),
              ),
              // `{(!isAuthenticated || unreadCount > 0) && …}` — `:172-177`.
              // A 2 × 2 amber dot with NO number, and it shows when signed out.
              // The count pill in the menu header is the other idiom for the
              // same number and the two are deliberately not unified
              // (specs.md § 2.2 Finding B).
              if (showsDot)
                Positioned(
                  top: 6,
                  right: 6,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      // `#F59E0B` — inline hex at `:175`.
                      color: AppColors.warningStrong,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.white.withValues(alpha: 0.5),
                        width: 1,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
