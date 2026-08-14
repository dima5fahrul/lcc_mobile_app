/// **B9-AC-33** — the category→dressing table, and the fallback that is a
/// mandatory criterion rather than a nicety.
///
/// § 6.15 / `Layout.tsx:55-70`. The same discipline B2-AC-14 applied to the
/// unknown-icon fallback, for the same reason: the API can add a category
/// tomorrow and the app must not blank the row or crash.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:lcc_mobile_app/features/notifications/domain/entities/notification_entities.dart';
import 'package:lcc_mobile_app/features/notifications/presentation/widgets/notif_style.dart';
import 'package:lcc_mobile_app/presentation/theme/app_colors.dart';
import 'package:lcc_mobile_app/utils/routes/app_name_routes.dart';

import '../notification_test_helper.dart';

void main() {
  group('the seven mapped categories — Layout.tsx:61-67', () {
    test('the map holds exactly seven keys, no more', () {
      // An eighth key would be a category the web does not dress, which is a
      // divergence a reviewer would never spot in a rendered tree.
      expect(kNotifStyle.keys.toSet(), <String>{
        'application',
        'case',
        'certificate',
        'document',
        'payment',
        'wallet',
        'announcement',
      });
    });

    test('the four dressings, value for value against the inline hex', () {
      // `application` / `case` — Clock, #F59E0B on #FEF3C7, → history.
      for (final String c in <String>['application', 'case']) {
        expect(notifStyleFor(c).color, AppColors.warningStrong, reason: c);
        expect(notifStyleFor(c).background, AppColors.categoryTintTransport,
            reason: c);
        expect(notifStyleFor(c).tab, AppNameRoutes.history, reason: c);
      }

      // `certificate` / `document` — FileCheck2, #16A34A on #DCFCE7, → account.
      for (final String c in <String>['certificate', 'document']) {
        expect(notifStyleFor(c).color, AppColors.categoryAccentFinance,
            reason: c);
        expect(notifStyleFor(c).background, AppColors.categoryTintFinance,
            reason: c);
        expect(notifStyleFor(c).tab, AppNameRoutes.account, reason: c);
      }

      // `payment` / `wallet` — CreditCard, #344EAD on #EEF2FF, → wallet.
      for (final String c in <String>['payment', 'wallet']) {
        expect(notifStyleFor(c).color, AppColors.primary, reason: c);
        expect(notifStyleFor(c).background, AppColors.primarySoft, reason: c);
        expect(notifStyleFor(c).tab, AppNameRoutes.wallet, reason: c);
      }

      // `announcement` — Megaphone, #6366F1 on #E0E7FF, → service.
      expect(notifStyleFor('announcement').color,
          AppColors.notifAccentAnnouncement);
      expect(notifStyleFor('announcement').background,
          AppColors.notifTintAnnouncement);
      expect(notifStyleFor('announcement').tab, AppNameRoutes.service);
    });

    test('the paired categories are the SAME row, not two that agree today',
        () {
      // `Layout.tsx:61,62` write one object per line but the pairs are
      // deliberately identical. Asserting identity rather than equality is what
      // catches a future edit that changes one and forgets the other.
      expect(identical(kNotifStyle['application'], kNotifStyle['case']), isTrue);
      expect(
          identical(kNotifStyle['certificate'], kNotifStyle['document']), isTrue);
      expect(identical(kNotifStyle['payment'], kNotifStyle['wallet']), isTrue);
    });

    test('every destination is a real, mounted route', () {
      // A tab this build does not serve would navigate nowhere and the row
      // would read as broken.
      for (final NotifStyle style in kNotifStyle.values) {
        expect(AppNameRoutes.registered, contains(style.tab));
      }
    });
  });

  group('the fallback — Layout.tsx:70, :131, :255. B9-AC-33', () {
    test('an unrecognised category resolves to the announcement dressing — '
        'icon, tint AND destination', () {
      final NotifStyle unknown = notifStyleFor('maintenance');
      final NotifStyle announcement = notifStyleFor('announcement');

      // All three, not just the colour: `:131` falls back for the TAB and
      // `:255` falls back for the DRESSING, and a port that did one and not the
      // other would render correctly and navigate wrongly.
      expect(unknown.icon, announcement.icon);
      expect(unknown.color, announcement.color);
      expect(unknown.background, announcement.background);
      expect(unknown.tab, announcement.tab);
      expect(identical(unknown, kNotifFallback), isTrue);
    });

    test('the empty string and never-before-seen values fall back too', () {
      for (final String c in <String>['', 'MAINTENANCE', 'Announcement', '🙂']) {
        expect(identical(notifStyleFor(c), kNotifFallback), isTrue, reason: c);
      }
      // Case-sensitive, as a JS object-key lookup is. `Announcement` above is
      // NOT `announcement`, and it correctly falls through rather than being
      // normalised — normalising would be the port being cleverer than the web.
    });

    test('the fixture really contains a row the map cannot resolve', () {
      // Without this, the fallback assertion above is true of a code path the
      // suite never exercises end to end (§ 6.11: fixtures chosen to
      // discriminate).
      final Iterable<CitizenNotification> unmapped = syntheticNotifications()
          .where((CitizenNotification n) => !kNotifStyle.containsKey(n.category));
      expect(unmapped, hasLength(1));
      expect(unmapped.single.category, 'maintenance');
    });

    test('every fixture row resolves to SOME dressing — no null, no crash', () {
      for (final CitizenNotification row in syntheticNotifications()) {
        expect(
          () => notifStyleFor(row.category),
          returnsNormally,
          reason: row.category,
        );
      }
    });
  });
}
