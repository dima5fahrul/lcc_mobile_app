/// The bell's dropdown panel — `Layout.tsx:180-293`.
///
/// A widget of its own rather than a closure inside [NotificationBell], for two
/// reasons that are both about being able to prove things about it:
///
/// 1. **Tier 1 pumps it directly.** B9's oracles key on a `surface`
///    (`notifications.menu`), not a route, and specs.md § 6.10 says they are
///    *"asserted by pumping the widget, not the page"*. A panel that only
///    exists inside an open `MenuAnchor` overlay would have to be reached
///    through the anchor for every one of its seven states.
/// 2. **Seven states, one subtree.** `signedOut`, `loading`, `data`, `empty`,
///    `error`, `header.markAllRead` and `footer.viewAll` are all decided here,
///    in the order the source decides them.
///
/// ## The order of the branches is the source's and it matters
///
/// `!isAuthenticated` (`:208`) → `inbox.loading` (`:225`) → `inbox.error`
/// (`:229`) → `items.length === 0` (`:241`) → the rows. So a signed-out citizen
/// never sees a spinner for a request that was never enabled, and an error wins
/// over rows left in state from a previous successful fetch.
///
/// ## The footer is inside the authenticated branch
///
/// `:283-289`'s "View all activity" is a sibling of the four body branches
/// **inside** the `<>…</>` that the `isAuthenticated` ternary selects (`:224`,
/// `:290`). It is therefore absent from the signed-out panel, present in all
/// four others — including the error one, which is how the same label ends up
/// on screen twice in that state. See [_ErrorBody].
library;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../i18n/i18n.dart';
import '../../../../presentation/theme/app_colors.dart';
import '../../domain/entities/notification_entities.dart';
import '../bloc/notifications_bloc.dart';
import 'notif_style.dart';
import 'relative_time.dart';

/// `w-80` — `Layout.tsx:184`.
const double kNotificationMenuWidth = 320;

/// `max-h-80` on the scrolling row list — `:253`.
const double kNotificationListMaxHeight = 320;

class NotificationMenuSheet extends StatelessWidget {
  const NotificationMenuSheet({
    super.key,
    required this.onSignIn,
    required this.onViewAll,
    required this.onOpenNotification,
    this.now,
  });

  /// Pins `relativeTime`'s clock. Production omits it; the Tier 1 test supplies
  /// the instant `oracle/tier1/notifications.*.json`'s `provenance.clock`
  /// records.
  ///
  /// Threaded rather than read from a global because every `cardMeta` node in
  /// the `data` view is a function of "now": without a pinnable clock those
  /// eight strings could not be gated at all, and the one state-bearing string
  /// per row would drop out of Tier 1.
  final DateTime? now;

  /// `setOpen(false); onTabChange("account")` — `:216`.
  final VoidCallback onSignIn;

  /// `setOpen(false); onTabChange("history")` — `:284`.
  final VoidCallback onViewAll;

  /// `openNotification(it)` — `:262`. Navigation is the caller's because it
  /// needs a router; the BLoC owns the close and the mark-read.
  final void Function(CitizenNotification item) onOpenNotification;

  @override
  Widget build(BuildContext context) {
    final Lang lang = Lang.fromCode(context.locale.languageCode);

    return BlocBuilder<NotificationsBloc, NotificationsState>(
      builder: (BuildContext context, NotificationsState state) {
        return Container(
          width: kNotificationMenuWidth,
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.gray100),
            boxShadow: const <BoxShadow>[
              // `shadow-2xl` — `:184`.
              BoxShadow(
                color: AppColors.cardShadowMedium,
                blurRadius: 24,
                offset: Offset(0, 12),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              NotificationMenuHeader(state: state),
              if (state.showsSignInPrompt)
                _SignInPrompt(onSignIn: onSignIn)
              else ...<Widget>[
                _body(state, lang),
                NotificationMenuFooter(onPressed: onViewAll),
              ],
            ],
          ),
        );
      },
    );
  }

  /// The four authenticated branches, in `Layout.tsx:225-282`'s own order.
  Widget _body(NotificationsState state, Lang lang) {
    if (state.listLoading) return const _LoadingBody();
    if (state.listFailed) return const _ErrorBody();
    if (state.listEmpty) return const _EmptyBody();
    return _RowList(
      items: state.items,
      lang: lang,
      now: now,
      onOpenNotification: onOpenNotification,
    );
  }
}

// ── Header — `:187-206` ──────────────────────────────────────────────────────

class NotificationMenuHeader extends StatelessWidget {
  const NotificationMenuHeader({super.key, required this.state});

  final NotificationsState state;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.gray100)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            Flexible(
              child: Text(
                'layout.notifications'.tr(),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.gray800,
                ),
              ),
            ),
            // One branch in the source, so one branch here: the button and the
            // pill appear and disappear together (`:189`).
            if (state.showsMarkAllRead)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  _LinkButton(
                    label: 'layout.notifMarkAllRead'.tr(),
                    fontSize: 11,
                    onPressed: () => context
                        .read<NotificationsBloc>()
                        .add(const NotificationsMarkAllRead()),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primarySoft,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      '${state.unreadCount}',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

// ── Signed out — `:209-222` ──────────────────────────────────────────────────

class _SignInPrompt extends StatelessWidget {
  const _SignInPrompt({required this.onSignIn});

  final VoidCallback onSignIn;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          const _GlyphTile(icon: Icons.login),
          const SizedBox(height: 12),
          Text(
            'layout.notifSignInTitle'.tr(),
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.gray800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'layout.notifSignInDesc'.tr(),
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 12,
              height: 1.5,
              color: AppColors.gray500,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: onSignIn,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.white,
                padding: const EdgeInsets.symmetric(vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'layout.notifSignIn'.tr(),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Loading — `:226-228` ─────────────────────────────────────────────────────

class _LoadingBody extends StatelessWidget {
  const _LoadingBody();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 40),
      child: Center(
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.gray400),
          ),
        ),
      ),
    );
  }
}

// ── Error — `:230-240` ───────────────────────────────────────────────────────

/// **The button here says "View all activity" and calls refetch.**
///
/// That is not a typo in this port. `Layout.tsx:238` labels the retry control
/// `t("notifViewAll")` while its `onClick` is `inbox.refetch()` (`:234`) —
/// wrong copy on a right action. Reproduced verbatim (specs.md § 2.2
/// Finding K(1), B9-AC-37): a port reading "Try again" there has diverged, and
/// it would be a divergence only someone comparing the two screens side by side
/// could catch.
///
/// The consequence is that the error state renders the same label twice, once
/// here and once in the footer below, doing two different things. That is what
/// the web does.
///
/// **The message line is `inbox.error.message` on the web and is not ported.**
/// `Layout.tsx:232` prints the backend's own sentence. Rendering
/// `Failure.message` here would put a stringified Dart exception in front of a
/// citizen — and `NotificationRepositoryImpl` builds it with `e.toString()`,
/// so it would read `ApiException: …`. The alternative, a fixed bilingual line,
/// needs an i18n key, and B9a's i18n diff is required to be **empty**
/// (B9-AC-45): all 22 `layout.notif*` keys are already in the tree and none of
/// them is an error message. So the line is omitted and the omission is
/// recorded, rather than adding a key or shipping exception text.
class _ErrorBody extends StatelessWidget {
  const _ErrorBody();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          const Icon(
            Icons.error_outline,
            size: 24,
            color: AppColors.dangerGlyphSoft,
          ),
          const SizedBox(height: 12),
          _LinkButton(
            label: 'layout.notifViewAll'.tr(),
            fontSize: 12,
            onPressed: () => context
                .read<NotificationsBloc>()
                .add(const NotificationsListRetried()),
          ),
        ],
      ),
    );
  }
}

// ── Empty — `:242-251` ───────────────────────────────────────────────────────

class _EmptyBody extends StatelessWidget {
  const _EmptyBody();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          // lucide `BellOff`.
          const _GlyphTile(icon: Icons.notifications_off_outlined),
          const SizedBox(height: 12),
          Text(
            'layout.notifEmpty'.tr(),
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.gray800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'layout.notifEmptyDesc'.tr(),
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 12,
              height: 1.5,
              color: AppColors.gray500,
            ),
          ),
        ],
      ),
    );
  }
}

// ── The rows — `:253-281` ────────────────────────────────────────────────────

/// `<div className="max-h-80 overflow-y-auto divide-y divide-gray-50">` — a
/// height-capped scroll container holding **every** row.
///
/// A `SingleChildScrollView` + `Column`, deliberately, and not a
/// `ListView.separated`. `ListView` is lazy: with the cap at 320 px and eight
/// rows it would only ever build the four or five that fit, and the rest would
/// not exist in the element tree at all. The DOM this ports has all eight
/// present and scrolls them — and Tier 1's ordered text dump reads the element
/// tree, so a lazy list would silently gate the visible half of the oracle's
/// `data` view and report 100 %.
///
/// The laziness would buy nothing here anyway: `per_page` is 8
/// (`Layout.tsx:117`), and the menu has no pager.
class _RowList extends StatelessWidget {
  const _RowList({
    required this.items,
    required this.lang,
    required this.now,
    required this.onOpenNotification,
  });

  final List<CitizenNotification> items;
  final Lang lang;
  final DateTime? now;
  final void Function(CitizenNotification item) onOpenNotification;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxHeight: kNotificationListMaxHeight),
      child: SingleChildScrollView(
        // `primary: false` is REQUIRED, not tidiness, and a widget test caught
        // its absence as a framework assertion rather than a wrong pixel:
        //
        //   The PrimaryScrollController is attached to more than one
        //   ScrollPosition. The Scrollbar requires a single ScrollPosition in
        //   order to be painted.
        //
        // `MenuAnchor` wraps its `menuChildren` in a scroll view of its own
        // that adopts the `PrimaryScrollController` on mobile, and so does an
        // unqualified vertical `SingleChildScrollView`. Two positions, one
        // controller, and the bell throws the first time a citizen opens it in
        // a debug build. This list is nested inside somebody else's menu; it
        // has no business being the primary scrollable.
        primary: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            for (int i = 0; i < items.length; i++) ...<Widget>[
              // `divide-y divide-gray-50` — `:253`. Between rows only, so the
              // first row has no rule above it and the list has none below,
              // which is what a CSS `divide-y` does.
              if (i > 0)
                const Divider(
                  height: 1,
                  thickness: 1,
                  color: AppColors.gray50,
                ),
              NotificationRow(
                item: items[i],
                lang: lang,
                now: now,
                onTap: () => onOpenNotification(items[i]),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class NotificationRow extends StatelessWidget {
  const NotificationRow({
    super.key,
    required this.item,
    required this.lang,
    required this.onTap,
    this.now,
  });

  final CitizenNotification item;
  final Lang lang;

  /// See [NotificationMenuSheet.now].
  final DateTime? now;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    // `NOTIF_STYLE[it.category] ?? NOTIF_FALLBACK` — `:255`.
    final NotifStyle style = notifStyleFor(item.category);

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: style.background,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(style.icon, size: 18, color: style.color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  // `text(it.title, lang)` — `:269`. The SHARED helper from
                  // `lib/i18n/i18n.dart`, imported rather than re-implemented:
                  // that file is frozen, not forbidden, and no layering guard
                  // has anything to say about it.
                  Text(
                    text(item.title, lang),
                    style: const TextStyle(
                      fontSize: 14,
                      height: 1.35,
                      fontWeight: FontWeight.w500,
                      color: AppColors.gray800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    text(item.body, lang),
                    style: const TextStyle(
                      fontSize: 12,
                      height: 1.35,
                      color: AppColors.gray500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    relativeTime(
                      item.sentAt,
                      lang,
                      'layout.notifJustNow'.tr(),
                      now: now,
                    ),
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.gray400,
                    ),
                  ),
                ],
              ),
            ),
            // `{unread && …}` — `:275`. `unread = !it.read_at`.
            if (item.isUnread) ...<Widget>[
              const SizedBox(width: 8),
              Container(
                margin: const EdgeInsets.only(top: 6),
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Footer — `:283-289` ──────────────────────────────────────────────────────

class NotificationMenuFooter extends StatelessWidget {
  const NotificationMenuFooter({super.key, required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.gray100)),
      ),
      child: InkWell(
        onTap: onPressed,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Center(
            child: Text(
              'layout.notifViewAll'.tr(),
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Two shapes the panel repeats ─────────────────────────────────────────────

/// The 48 × 48 rounded tile behind the sign-in and empty glyphs — `:210`,
/// `:243`.
class _GlyphTile extends StatelessWidget {
  const _GlyphTile({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: AppColors.primarySoft,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Icon(icon, size: 24, color: AppColors.primary),
    );
  }
}

/// A borderless brand-coloured text button — the source's bare `<button>` with
/// `style={{ color: "#344EAD" }}` (`:191-197`, `:233-239`).
class _LinkButton extends StatelessWidget {
  const _LinkButton({
    required this.label,
    required this.fontSize,
    required this.onPressed,
  });

  final String label;
  final double fontSize;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        child: Text(
          label,
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.w600,
            color: AppColors.primary,
          ),
        ),
      ),
    );
  }
}
