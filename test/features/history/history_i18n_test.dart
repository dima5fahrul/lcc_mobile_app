/// The `history` i18n namespace and the list's colour tables —
/// **B7-AC-31**, **B7-AC-42**, **B7-AC-43**, **B7-AC-44**.
///
/// These are the criteria that need no widget: a key set is a fact about two
/// JSON files, and `progressBarColour` / `paymentChipStyleFor` /
/// `slaChipStyle` are pure functions over an enum. Asserting them here rather
/// than through a rendered row means a failure names the table that is wrong
/// instead of the pixel that moved.
///
/// The dead-key list is § 6.11's, transcribed **in full** rather than sampled:
/// the criterion is "none of the 27 appears", and a spot-check of five would
/// pass while twenty-two unreachable strings sat in a file every future batch
/// has to read.
library;

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:lcc_mobile_app/features/application/domain/entities/case_status.dart';
import 'package:lcc_mobile_app/features/history/presentation/widgets/history_palette.dart';

/// § 6.11 Finding G — `i18n/ns/history.ts:73-104`, demo-data leftovers with no
/// `t()` call anywhere in `src/**`.
const List<String> kDeadKeys = <String>[
  'statusApproved',
  'statusInReview',
  'statusRejected',
  'fixAndResubmit',
  'reuploadDocument',
  'howToFix',
  'serviceBirthCert',
  'serviceMarriageCert',
  'serviceFamilyBook',
  'serviceResidenceCert',
  'officeVientiane',
  'officeChanthabouly',
  'officeSisattanak',
  'officeXaysetha',
  'step1',
  'step2',
  'step3',
  'step4',
  'step5',
  'dateEstimatedDays',
  'datePending',
  'eta23BusinessDays',
  'rejectionReasonUnclearId',
  'fixStep1',
  'fixStep2',
  'fixStep3',
  'fixStep4',
];

Map<String, dynamic> _namespace(String locale) {
  final File f = File('assets/i18n/$locale.json');
  expect(f.existsSync(), isTrue, reason: '${f.path} must exist');
  final Map<String, dynamic> all =
      jsonDecode(f.readAsStringSync()) as Map<String, dynamic>;
  return (all['history'] as Map<String, dynamic>?) ?? <String, dynamic>{};
}

void main() {
  group('B7-AC-44 — the history namespace', () {
    late Map<String, dynamic> en;
    late Map<String, dynamic> lo;

    setUpAll(() {
      en = _namespace('en');
      lo = _namespace('lo');
    });

    test('en and lo carry identical key sets', () {
      expect(
        en.keys.toSet().difference(lo.keys.toSet()),
        isEmpty,
        reason: 'keys present in en but missing from lo render as the raw key '
            'path to a Lao reader',
      );
      expect(lo.keys.toSet().difference(en.keys.toSet()), isEmpty);
    });

    test('none of the 27 dead keys of § 6.11 was ported', () {
      final List<String> ported =
          kDeadKeys.where((String k) => en.containsKey(k) || lo.containsKey(k))
              .toList();
      expect(
        ported,
        isEmpty,
        reason: 'i18n/ns/history.ts:73-104 has no t() call for these; porting '
            'them puts unreachable strings in a file every batch must read',
      );
    });

    test('title and subtitle are unchanged from the pre-B7 file', () {
      // Byte-identical to the web's, per § 6.11 — B7 appends around them and
      // edits neither. The literal is spelled out so a silent reword fails
      // here rather than in a fidelity tier days later.
      expect(en['title'], 'Application History');
      expect(en['subtitle'], "Track every request you've submitted");
      expect(lo['subtitle'], 'ຕິດຕາມທຸກຄຳຮ້ອງທີ່ທ່ານໄດ້ຍື່ນ');
    });

    test('every value is a non-empty string', () {
      for (final MapEntry<String, dynamic> e in en.entries) {
        expect(e.value, isA<String>(), reason: 'history.${e.key} in en');
        expect((e.value as String).trim(), isNotEmpty,
            reason: 'history.${e.key} in en is blank');
      }
      for (final MapEntry<String, dynamic> e in lo.entries) {
        expect((e.value as String).trim(), isNotEmpty,
            reason: 'history.${e.key} in lo is blank');
      }
    });

    test('the two locales are actually different copy, not a copy-paste', () {
      // A namespace where `lo` was filled by duplicating `en` passes every
      // check above. `subtitle` is Lao script; assert at least most values are.
      final int identical = en.keys
          .where((String k) => en[k] == lo[k])
          .length;
      expect(
        identical,
        lessThan(en.length ~/ 2),
        reason: 'more than half the Lao values are byte-identical to English — '
            'the namespace was probably duplicated rather than translated',
      );
    });
  });

  group('B7-AC-31 — the progress bar colour', () {
    test('rejected is #DC2626, approved #16A34A, everything else #344EAD', () {
      expect(progressBarColour(StatusBucket.rejected).toARGB32(), 0xFFDC2626);
      expect(progressBarColour(StatusBucket.approved).toARGB32(), 0xFF16A34A);
      expect(progressBarColour(StatusBucket.pending).toARGB32(), 0xFF344EAD);
    });

    test(
      "the bar's approved green differs from the status chip's — two greens on "
      'one row, in the source',
      () {
        expect(
          progressBarColour(StatusBucket.approved).toARGB32(),
          isNot(statusChipStyleFor(StatusBucket.approved).foreground.toARGB32()),
          reason: 'HistoryPage.tsx:346-352 is #16A34A; STATUS_CONFIG.approved '
              'text is #15803D. Collapsing them would be the port tidying up '
              'its source',
        );
      },
    );
  });

  group('B7-AC-43 — paymentChipStyle maps all five states', () {
    test('paid, pending and failed each have their own pair', () {
      expect(paymentChipStyleFor(PaymentState.paid).background.toARGB32(),
          0xFFDCFCE7);
      expect(paymentChipStyleFor(PaymentState.paid).foreground.toARGB32(),
          0xFF15803D);
      expect(paymentChipStyleFor(PaymentState.pending).background.toARGB32(),
          0xFFFEF3C7);
      expect(paymentChipStyleFor(PaymentState.pending).foreground.toARGB32(),
          0xFFB45309);
      expect(paymentChipStyleFor(PaymentState.failed).background.toARGB32(),
          0xFFFEE2E2);
      expect(paymentChipStyleFor(PaymentState.failed).foreground.toARGB32(),
          0xFFDC2626);
    });

    test(
      'refunded and free land on the SAME shared default — not a case each',
      () {
        final PaymentChipStyle refunded =
            paymentChipStyleFor(PaymentState.refunded);
        final PaymentChipStyle free = paymentChipStyleFor(PaymentState.free);

        expect(refunded.background.toARGB32(), free.background.toARGB32());
        expect(refunded.foreground.toARGB32(), free.foreground.toARGB32());
        expect(refunded.background.toARGB32(), 0xFFF3F4F6);
        expect(refunded.foreground.toARGB32(), 0xFF6B7280);
        // A table with five DISTINCT entries would satisfy "all five states are
        // mapped" while meaning something the source does not.
      },
    );

    test('unknown reaches the same default — the ?? ["—","—"] arm', () {
      expect(
        paymentChipStyleFor(PaymentState.unknown).background.toARGB32(),
        paymentChipStyleFor(PaymentState.refunded).background.toARGB32(),
      );
    });

    test("pending's amber is not the status chip's amber", () {
      expect(
        paymentChipStyleFor(PaymentState.pending).foreground.toARGB32(),
        isNot(statusChipStyleFor(StatusBucket.pending).foreground.toARGB32()),
        reason: '#B45309 vs #D97706 — two ambers on one row, the source\'s',
      );
    });
  });

  group('B7-AC-42 — the SLA chip palette', () {
    test('overdue is the red pair, on-time the grey pair', () {
      expect(slaChipStyle(isOverdue: true).background.toARGB32(), 0xFFFEE2E2);
      expect(slaChipStyle(isOverdue: true).foreground.toARGB32(), 0xFFDC2626);
      expect(slaChipStyle(isOverdue: false).background.toARGB32(), 0xFFF3F4F6);
      expect(slaChipStyle(isOverdue: false).foreground.toARGB32(), 0xFF6B7280);
    });
  });

  group('the three status buckets', () {
    test('each bucket has a distinct chip triple', () {
      final Set<int> backgrounds = <int>{
        for (final StatusBucket b in StatusBucket.values)
          statusChipStyleFor(b).background.toARGB32(),
      };
      expect(backgrounds, hasLength(StatusBucket.values.length));
    });

    test(
      'ring is a distinct value from background for all three buckets',
      () {
        for (final StatusBucket b in StatusBucket.values) {
          final StatusChipStyle s = statusChipStyleFor(b);
          expect(
            s.ring.toARGB32(),
            isNot(s.background.toARGB32()),
            reason: 'collapsing bg and ring would be a Tier 2 miss no rendered '
                'text would show — $b',
          );
        }
      },
    );
  });
}
