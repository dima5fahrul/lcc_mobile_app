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
/// - **No notification bell.** The plan defers it (`P0 tanpa notification
///   bell (P1-9 batch berikutnya)`), and it needs `me.unreadCount` /
///   `me.notifications`, which GOR-245 § 6 puts out of scope.
///
/// Tapping the brand block goes home, matching the React `<a href={tabHref
/// ("home")}>` wrapper.
library;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../utils/routes/app_name_routes.dart';
import 'app_brand.dart';
import 'language_toggle.dart';

class AppTopBar extends StatelessWidget implements PreferredSizeWidget {
  const AppTopBar({super.key});

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
                  color: Colors.white,
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
                        color: Colors.white,
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
                        color: Colors.white.withValues(alpha: 0.75),
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
      actions: const <Widget>[
        LanguageToggle(),
        SizedBox(width: 12),
      ],
    );
  }
}
