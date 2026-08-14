/// The inbox's wire → entity parsing, and the fixture-shape correction
/// **B9-AC-57** requires.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:lcc_mobile_app/features/notifications/data/models/notification_wire.dart';
import 'package:lcc_mobile_app/features/notifications/domain/entities/notification_entities.dart';

import '../notification_test_helper.dart';

void main() {
  group('the unread count is an OBJECT — § 2.2 Finding H, B9-AC-57', () {
    test('the corrected fixture deserialises to a number', () {
      // The heart of the finding. This fixture shipped `"data": []` — an array
      // — where `endpoints.ts:137` types the endpoint
      // `api.get<{ unread: number }>`. Its own provenance note recorded why
      // nobody caught it ("it feeds no Tier 0 leaf"), which was true for F0 and
      // is false for B9: this is the first batch to deserialise it for real.
      expect(syntheticUnreadCount(), 3);
    });

    test('the fixture is an object, not an array — the correction itself', () {
      final Object? data =
          loadSyntheticApi('me-notifications-unread-count')['data'];
      expect(
        data,
        isA<Map<String, dynamic>>(),
        reason: 'if this is a List again the correction was reverted, and '
            'every count read silently answers 0 (§ 6.11(b)).',
      );
      expect((data! as Map<String, dynamic>)['unread'], 3);
    });

    test('the count and the fixture row count are DIFFERENT numbers', () {
      // Deliberate (§ 6.11: "chosen to discriminate, not to look plausible").
      // The count endpoint and the list endpoint are separate reads; a test —
      // or an implementation — that derived one from the other would pass
      // against a fixture where they happened to agree.
      final int unreadRows =
          syntheticNotifications().where((CitizenNotification n) => n.isUnread).length;
      expect(unreadRows, 5);
      expect(syntheticUnreadCount(), isNot(unreadRows));
    });

    test('`counter.data?.unread ?? 0` — anything unreadable is 0, not a throw',
        () {
      // `Layout.tsx:122`. A malformed count must cost the badge, not the shell.
      expect(unreadCountFrom(null), 0);
      expect(unreadCountFrom(<dynamic>[]), 0, reason: 'the OLD fixture shape');
      expect(unreadCountFrom(<String, dynamic>{}), 0);
      expect(unreadCountFrom(<String, dynamic>{'unread': null}), 0);
      expect(unreadCountFrom(<String, dynamic>{'unread': 'oops'}), 0);
      expect(unreadCountFrom('7'), 0);
    });

    test('a JSON number that arrived as a double is an integer count', () {
      // JSON has one number type; a backend serialising `3.0` is sending 3.
      expect(unreadCountFrom(<String, dynamic>{'unread': 3.0}), 3);
      expect(unreadCountFrom(<String, dynamic>{'unread': '4'}), 4);
    });
  });

  group('one notification row — types.ts:752-767', () {
    test('the eight synthetic rows parse, field for field', () {
      final List<CitizenNotification> rows = syntheticNotifications();
      expect(rows, hasLength(8));

      final CitizenNotification first = rows.first;
      expect(first.id, 'ntf-0001');
      expect(first.template, 'application.submitted');
      expect(first.title.en, 'Residence Certificate submitted');
      expect(first.title.lo, 'ສົ່ງໃບຢັ້ງຢືນທີ່ຢູ່ອາໄສແລ້ວ');
      expect(first.body.en, 'RC-2026-004821 is now with the district office.');
      expect(first.channel, 'in_app');
      expect(first.category, 'application');
      expect(first.severity, 'info');
      expect(first.refType, 'application');
      expect(first.refId, 'RC-2026-004821');
      expect(first.actionUrl, '/history/RC-2026-004821');
      expect(first.readAt, isNull);
      expect(first.sentAt, '2026-08-13T23:50:00.000Z');
    });

    test('`read_at` null vs a timestamp is the unread distinction — :257', () {
      final List<CitizenNotification> rows = syntheticNotifications();
      expect(rows[0].isUnread, isTrue, reason: 'read_at: null');
      expect(rows[2].isUnread, isFalse, reason: 'read_at: a timestamp');
      // Both shapes occur in the fixture, so neither branch is unreachable.
      expect(rows.where((CitizenNotification n) => n.isUnread), hasLength(5));
      expect(rows.where((CitizenNotification n) => !n.isUnread), hasLength(3));
    });

    test('`!it.read_at` treats an EMPTY string as unread, as JavaScript does',
        () {
      expect(
        citizenNotificationFrom(<String, dynamic>{'read_at': ''}).isUnread,
        isTrue,
        reason: "JS `!''` is true. A Dart `readAt != null` alone would call "
            'this read and hide the row\'s blue dot.',
      );
    });

    test('an absent optional is null, not an empty string', () {
      // The distinction has to survive parsing: `template` absent and
      // `template: ""` are different wire facts, and `read_at` is the field
      // where the difference decides whether a POST is issued.
      final CitizenNotification row =
          citizenNotificationFrom(<String, dynamic>{'id': 'x'});
      expect(row.template, isNull);
      expect(row.refType, isNull);
      expect(row.refId, isNull);
      expect(row.actionUrl, isNull);
      expect(row.readAt, isNull);
      // The non-optional ones default rather than go null.
      expect(row.channel, '');
      expect(row.category, '');
      expect(row.sentAt, '');
      expect(row.title.en, '');
    });

    test('a bilingual field accepts `{en,lo}`, a bare string, or neither', () {
      // No recording of this endpoint exists to confirm which shapes it really
      // sends (§ 2.2 Finding I), so the tolerant reader `help_wire.dart` uses
      // is kept rather than narrowed on an assumption.
      expect(
        citizenNotificationFrom(<String, dynamic>{
          'title': <String, dynamic>{'en': 'A', 'lo': 'ກ'},
        }).title.lo,
        'ກ',
      );
      final CitizenNotification bare =
          citizenNotificationFrom(<String, dynamic>{'title': 'One language'});
      expect(bare.title.en, 'One language');
      expect(bare.title.lo, 'One language');
      expect(
        citizenNotificationFrom(<String, dynamic>{'title': 42}).title.en,
        '',
      );
    });

    test('a wrong-typed scalar degrades to the default rather than throwing',
        () {
      final CitizenNotification row = citizenNotificationFrom(<String, dynamic>{
        'id': 99,
        'category': <String>['nope'],
        'read_at': 12345,
      });
      expect(row.id, '');
      expect(row.category, '');
      expect(row.readAt, isNull);
    });
  });

  group('the fixture discriminates — § 6.11', () {
    test('all seven mapped categories appear, plus one that is mapped by '
        'nothing', () {
      final Set<String> categories =
          syntheticNotifications().map((CitizenNotification n) => n.category).toSet();
      expect(
        categories,
        containsAll(<String>[
          'application',
          'case',
          'certificate',
          'document',
          'payment',
          'wallet',
          'announcement',
        ]),
      );
      expect(
        categories,
        contains('maintenance'),
        reason: 'the unrecognised-category row. Without it the fallback test '
            '(B9-AC-33) could not fail, whatever the map did.',
      );
    });

    test('the fixture declares itself synthetic — B9-AC-57', () {
      final Map<String, dynamic> capture =
          loadSyntheticApi('me-notifications')['_capture']
              as Map<String, dynamic>;
      final String provenance = capture['provenance'] as String;
      expect(provenance, contains('SYNTHETIC'));
      expect(provenance, contains('NOT A RECORDING'));
      expect(
        provenance,
        contains('NOT EVALUATED'),
        reason: "B2-AC-36's recorded-payload standard must be reported NOT "
            'EVALUATED with its reason, never PASS or silently omitted.',
      );
      expect(capture['credential'], contains('never authenticates'));
    });

    test('the corrected fixture records WHAT was corrected and why', () {
      final String provenance =
          (loadSyntheticApi('me-notifications-unread-count')['_capture']
              as Map<String, dynamic>)['provenance'] as String;
      expect(provenance, contains('CORRECTED BY B9a'));
      expect(
        provenance,
        isNot(contains('feeds no Tier 0 leaf')),
        reason: '§ 6.11(b) requires the now-false note to be DROPPED, not left '
            'standing beside the correction. It was true for F0 and is false '
            'for B9a, which reads this endpoint for real.',
      );
    });
  });
}
