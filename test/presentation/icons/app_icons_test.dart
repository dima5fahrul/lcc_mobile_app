/// The two resolver scopes (§ 6.3.5) — including the divergence that makes
/// scoping worth the trouble.
///
/// The interesting assertion in this file is
/// `AppIcons.service('Rocket') == 'FileText'`. Merging the two registries into
/// one 86-name lookup is the obvious simplification, and it would make that
/// line read `'Rocket'` — matching nothing in the web, invisible today because
/// `/services` does not send `Rocket`, and surfacing much later as a fidelity
/// failure with no obvious cause.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:lcc_mobile_app/presentation/icons/app_icons.dart';
import 'package:lcc_mobile_app/presentation/icons/lucide_registry.g.dart';

void main() {
  group('AppIcons.service — ServicePage.tsx:112 serviceIcon()', () {
    test('resolves a name in scope to itself', () {
      expect(AppIcons.service('Users2'), 'Users2');
      expect(AppIcons.service('HeartPulse'), 'HeartPulse');
      expect(AppIcons.service('ChevronRight'), 'ChevronRight');
    });

    test('null and empty fall back', () {
      expect(AppIcons.service(null), AppIcons.fallback);
      expect(AppIcons.service(''), AppIcons.fallback);
    });

    test('an unknown name falls back', () {
      expect(AppIcons.service('NotARealIconName'), AppIcons.fallback);
    });

    test('is case-sensitive — the API token is the exact component name', () {
      expect(AppIcons.service('users2'), AppIcons.fallback);
      expect(AppIcons.service('FILETEXT'), AppIcons.fallback);
    });
  });

  group('AppIcons.help — HelpCenterPage.tsx:51 icon()', () {
    test('resolves a name in scope to itself', () {
      expect(AppIcons.help('Rocket'), 'Rocket');
      expect(AppIcons.help('LifeBuoy'), 'LifeBuoy');
      expect(AppIcons.help('Mail'), 'Mail');
    });

    test('null, empty and unknown fall back', () {
      expect(AppIcons.help(null), AppIcons.fallback);
      expect(AppIcons.help(''), AppIcons.fallback);
      expect(AppIcons.help('NotARealIconName'), AppIcons.fallback);
    });
  });

  group('the scopes are NOT interchangeable — § 6.3.5s whole point', () {
    test('Help-only names fall back under the service scope', () {
      // Measured in § 2.2 Finding C: exactly these three API-supplied names
      // are in Help's registry and absent from Service's.
      for (final String name in <String>['Mail', 'Phone', 'Rocket']) {
        expect(AppIcons.help(name), name, reason: '$name is in Help s scope');
        expect(AppIcons.service(name), AppIcons.fallback,
            reason: 'the web renders FileText for $name on a service card');
        // …and the glyph IS bundled, so this is a scoping decision and not a
        // missing asset masquerading as one.
        expect(lucideRegistry, contains(name));
      }
    });

    test('service-only names fall back under the help scope', () {
      for (final String name in <String>['Plane', 'Tractor', 'Gavel']) {
        expect(AppIcons.service(name), name);
        expect(AppIcons.help(name), AppIcons.fallback);
      }
    });

    test('the seven shared names resolve under both', () {
      final Set<String> shared =
          AppIcons.serviceScope.intersection(AppIcons.helpScope);
      expect(shared, <String>{
        'FileText',
        'Wallet',
        'Shield',
        'UserCircle',
        'MessageCircle',
        'MapPin',
        'BookOpen',
      });
      for (final String name in shared) {
        expect(AppIcons.service(name), name);
        expect(AppIcons.help(name), name);
      }
    });
  });

  group('API-supplied names measured in § 2.2 Finding C', () {
    test('the 4 help-category names resolve non-fallback under help', () {
      for (final String name in <String>[
        'FileText',
        'Rocket',
        'Shield',
        'Wallet',
      ]) {
        expect(AppIcons.help(name), name);
      }
    });

    test('the 4 channel names resolve non-fallback under help', () {
      for (final String name in <String>[
        'Phone',
        'Mail',
        'MessageCircle',
        'MapPin',
      ]) {
        expect(AppIcons.help(name), name);
      }
    });
  });

  group('assetFor', () {
    test('maps a bundled name to its path', () {
      expect(AppIcons.assetFor('FileText'), 'assets/icons/lucide/FileText.svg');
    });

    test('an unbundled name still yields the fallback asset, never null', () {
      expect(
        AppIcons.assetFor('NotARealIconName'),
        'assets/icons/lucide/FileText.svg',
      );
    });
  });
}
