/// `shellTabs` and `shellTabIndexFor` — the destination table behind the
/// bottom bar.
///
/// A pure function, so it is tested directly rather than through the widget:
/// the sub-route rule (`/service/resident-certificate` keeps Service
/// highlighted) is about to matter for the certificate batch, and it is far
/// cheaper to pin here than to rediscover through a pumped shell.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:lcc_mobile_app/presentation/shell/shell_tabs.dart';
import 'package:lcc_mobile_app/utils/routes/app_name_routes.dart';

void main() {
  group('shellTabs', () {
    test('holds the five main destinations in bottom-bar order', () {
      expect(
        shellTabs.map((ShellTab t) => t.path).toList(),
        <String>[
          AppNameRoutes.home,
          AppNameRoutes.service,
          AppNameRoutes.history,
          AppNameRoutes.wallet,
          AppNameRoutes.account,
        ],
      );
    });

    test('labels every tab with a layout-namespace i18n key', () {
      expect(
        shellTabs.map((ShellTab t) => t.labelKey).toList(),
        <String>[
          'layout.home',
          'layout.service',
          'layout.history',
          'layout.wallet',
          'layout.account',
        ],
      );
    });

    test('gives each tab a distinct selected and unselected icon', () {
      for (final ShellTab tab in shellTabs) {
        expect(tab.icon, isNot(tab.selectedIcon), reason: tab.path);
      }
    });
  });

  group('shellTabIndexFor', () {
    test('matches each tab exactly', () {
      expect(shellTabIndexFor(AppNameRoutes.home), 0);
      expect(shellTabIndexFor(AppNameRoutes.service), 1);
      expect(shellTabIndexFor(AppNameRoutes.history), 2);
      expect(shellTabIndexFor(AppNameRoutes.wallet), 3);
      expect(shellTabIndexFor(AppNameRoutes.account), 4);
    });

    test('keeps a sub-route on its parent tab', () {
      expect(shellTabIndexFor('/service/resident-certificate'), 1);
      expect(shellTabIndexFor('/history/RC-2026-004821'), 2);
      expect(shellTabIndexFor('/account/settings/language'), 4);
    });

    test('does not let home prefix-match everything', () {
      // `/` prefixes every path, so home matches only exactly. Without that
      // carve-out `/wallet` would light up Home.
      expect(shellTabIndexFor('/wallet'), 3);
      expect(shellTabIndexFor('/service'), 1);
    });

    test('falls back to home for a path outside the shell', () {
      expect(shellTabIndexFor(AppNameRoutes.signin), 0);
      expect(shellTabIndexFor('/nothing-like-this'), 0);
      expect(shellTabIndexFor(''), 0);
    });

    test('does not treat a same-prefix sibling as a sub-route', () {
      // `/services` is not `/service/...`; only a `/` boundary counts.
      expect(shellTabIndexFor('/services'), 0);
    });

    group('CR-8 — the unmatched fallback is explicit (B2-AC-37)', () {
      test('is the named constant, not an anonymous literal 0', () {
        // The point of CR-8 is that "no tab owns this location" is a *decision*
        // with a name, so asserting against the constant is the assertion —
        // if the fallback is ever retuned, this test moves with it instead of
        // silently continuing to pass against a hardcoded 0.
        expect(shellTabIndexFor(AppNameRoutes.signin),
            kUnmatchedShellTabIndex);
        expect(shellTabIndexFor('/nothing-like-this'),
            kUnmatchedShellTabIndex);
        expect(shellTabIndexFor(''), kUnmatchedShellTabIndex);
        expect(shellTabIndexFor('/services'), kUnmatchedShellTabIndex);
      });

      test('resolves to a real tab index, so the bottom bar cannot throw', () {
        // `NavigationBar.selectedIndex` must be in range. The fallback being
        // "home" is a choice; the fallback being *addressable* is a contract.
        expect(kUnmatchedShellTabIndex, greaterThanOrEqualTo(0));
        expect(kUnmatchedShellTabIndex, lessThan(shellTabs.length));
        expect(shellTabs[kUnmatchedShellTabIndex].path, AppNameRoutes.home);
      });
    });
  });
}
