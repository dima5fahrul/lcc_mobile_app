/// Tier 1 and Tier 2 for `HistoryDetailPage` — **B7-AC-81**.
///
/// Tier 2 (tokens) reads every hex out of the **pinned `.tsx`** and compares it
/// to the Dart constant, the mechanism `tier2_history_test.dart` established:
/// restating the hex twice in Dart would let the constant and the expectation
/// drift together and still agree. Tier 1 (text) does the same for the i18n
/// strings — each key's value is compared against the arm of the source's own
/// `lang === "lo" ? … : …` or its `history.ts` entry.
///
/// **Tier 3 (pixels) is NOT EVALUATED**, and the reason is not this file's to
/// fix: `page_pairs.yaml:44-52` excludes slot 03 because the captured baseline
/// is the signed-out Welcome Back card, and B7 adds no slot (§ 4.1). The detail
/// is additionally unreachable from any captured state — it needs an
/// application to exist, and `/applications/` returns `total 0, rows 0`.
///
/// **Every Tier 1/Tier 2 pass here is still NOT live verification** (§ 6.4):
/// it proves the port agrees with the *source*, not that the surface was ever
/// rendered against a real payload.
///
/// **`sources/lcc-app` is READ-ONLY.** Nothing here writes.
library;

import 'dart:convert';
import 'dart:io';
import 'dart:ui' show Color;

import 'package:flutter_test/flutter_test.dart';
import 'package:lcc_mobile_app/features/application/domain/entities/case_status.dart';
import 'package:lcc_mobile_app/features/history/presentation/widgets/history_detail_palette.dart';

const String _src = '../lcc-app/src/app/components';

String _read(String file) {
  final File f = File('$_src/$file');
  if (!f.existsSync()) {
    fail(
      'NOT EVALUATED: the pinned port source is not checked out at '
      '$_src/$file, so Tier 2 cannot be derived from it. Blocking reason, '
      'not a pass.',
    );
  }
  return f.readAsStringSync();
}

Map<String, dynamic> _i18n(String locale) => (json.decode(
      File('assets/i18n/$locale.json').readAsStringSync(),
    ) as Map<String, dynamic>)['history'] as Map<String, dynamic>;

void _expectColor(String source, Color token, String hex, {String? because}) {
  expect(
    source.toUpperCase(),
    contains(hex.toUpperCase()),
    reason: '$hex is not in HistoryDetailPage.tsx — the citation is stale, or '
        'the source moved. Fix the citation, do not relax the test.',
  );
  expect(
    token.toARGB32() & 0x00FFFFFF,
    int.parse(hex.substring(1), radix: 16),
    reason: because ?? 'HistoryDetailPage.tsx states $hex',
  );
}

void main() {
  late String detail;
  late Map<String, dynamic> en;
  late Map<String, dynamic> lo;

  setUpAll(() {
    detail = _read('HistoryDetailPage.tsx');
    en = _i18n('en');
    lo = _i18n('lo');
  });

  test('the source really is the detail page — the read is not vacuous', () {
    expect(detail, contains('export function HistoryDetailPage'));
    expect(detail.length, greaterThan(10000));
  });

  group('Tier 2 — STATUS_THEME, `:111-133`', () {
    test('approved is #16A34A on #DCFCE7', () {
      _expectColor(detail, kDetailThemeApproved.color, '#16A34A');
      _expectColor(detail, kDetailThemeApproved.background, '#DCFCE7');
    });

    test('rejected is #DC2626 on #FEE2E2', () {
      _expectColor(detail, kDetailThemeRejected.color, '#DC2626');
      _expectColor(detail, kDetailThemeRejected.background, '#FEE2E2');
    });

    test('pending is #D97706 on #FEF3C7', () {
      _expectColor(detail, kDetailThemePending.color, '#D97706');
      _expectColor(detail, kDetailThemePending.background, '#FEF3C7');
    });

    test("the hero's approved green is NOT the list chip's #15803D", () {
      // The one value on which `STATUS_CONFIG` and `STATUS_THEME` disagree, and
      // the reason `history_detail_palette.dart` is a second table rather than
      // a reuse of the first. A shared table would have to pick one.
      expect(kDetailThemeApproved.color.toARGB32() & 0x00FFFFFF, 0x16A34A);
      expect(kDetailThemeApproved.color.toARGB32() & 0x00FFFFFF,
          isNot(0x15803D));
    });

    test('historyDetailThemeFor covers all three buckets', () {
      expect(historyDetailThemeFor(StatusBucket.approved), kDetailThemeApproved);
      expect(historyDetailThemeFor(StatusBucket.rejected), kDetailThemeRejected);
      expect(historyDetailThemeFor(StatusBucket.pending), kDetailThemePending);
    });
  });

  group('Tier 2 — the timeline, `:544-570`', () {
    test('the dots are #16A34A / #DC2626', () {
      _expectColor(detail, kTimelineDotOk, '#16A34A');
      _expectColor(detail, kTimelineDotError, '#DC2626');
    });

    test('the dot fills are #DCFCE7 / #FEE2E2', () {
      _expectColor(detail, kTimelineDotBgOk, '#DCFCE7');
      _expectColor(detail, kTimelineDotBgError, '#FEE2E2');
    });

    test('B7-AC-64 — the ERROR connector is #E5E7EB, grey and not red', () {
      _expectColor(detail, kTimelineLineError, '#E5E7EB',
          because: 'a rejected event BREAKS the green trail rather than '
              'continuing it in another colour — `:547`');
      // Stated as a difference too, because writing `danger` here for symmetry
      // with the dot is the specific mistake this pins.
      expect(kTimelineLineError, isNot(kTimelineDotError));
    });

    test('the OK connector is #16A34A, the same green as its dot', () {
      _expectColor(detail, kTimelineLineOk, '#16A34A');
      expect(kTimelineLineOk, kTimelineDotOk);
    });

    test('the event label colours are #DC2626 / #1F2937', () {
      _expectColor(detail, kTimelineTextError, '#DC2626');
      // `#1F2937` is `text-gray-800`'s inline hex at `:570`.
      _expectColor(detail, kTimelineTextOk, '#1F2937');
    });

    test('the current-event ring is rgba(52,78,173,0.15) — 4 px spread', () {
      // `52,78,173` is `#344EAD` in decimal, so the hex grep does not apply;
      // the source is asserted in its own decimal form instead.
      expect(detail, contains('rgba(52,78,173,0.15)'));
      expect(kTimelineCurrentRing.toARGB32() & 0x00FFFFFF, 0x344EAD);
      expect(kTimelineCurrentRingOpacity, 0.15);
      expect(kTimelineCurrentRingWidth, 4);
    });
  });

  group('Tier 1 — the 16 ported `t()` keys match `i18n/ns/history.ts`', () {
    // Read out of the namespace file rather than restated, for the Tier 2
    // reason: two transcriptions can drift together.
    late String ns;
    setUpAll(() => ns = File('$_src/../i18n/ns/history.ts').existsSync()
        ? File('$_src/../i18n/ns/history.ts').readAsStringSync()
        : fail('NOT EVALUATED: i18n/ns/history.ts is not checked out'));

    const List<String> ported = <String>[
      'backToHistory',
      'applicationLabel',
      'approvedHeadline',
      'approvedSub',
      'rejectedHeadline',
      'rejectedSub',
      'pendingHeadline',
      'pendingSub',
      'overallProgress',
      'refreshStatus',
      'contactOfficer',
      'whyRejected',
      'applicationProgress',
      'eta',
      'applicationInfo',
      'referenceNumber',
      'submitted',
      'processingOffice',
      'serviceFee',
    ];

    test('every one exists in both locales', () {
      for (final String key in ported) {
        expect(en.containsKey(key), isTrue, reason: 'en is missing $key');
        expect(lo.containsKey(key), isTrue, reason: 'lo is missing $key');
      }
    });

    test('every en value appears verbatim in the source namespace', () {
      for (final String key in ported) {
        expect(ns, contains('"${en[key]}"'),
            reason: 'en.$key = "${en[key]}" is not in history.ts');
      }
    });

    test('every lo value appears verbatim in the source namespace', () {
      for (final String key in ported) {
        expect(ns, contains('"${lo[key]}"'),
            reason: 'lo.$key = "${lo[key]}" is not in history.ts');
      }
    });

    test('`eta` keeps its {value} placeholder in both locales', () {
      expect(en['eta'], contains('{value}'));
      expect(lo['eta'], contains('{value}'));
    });

    test('the two seam keys arrived with B5, and carry the source arms', () {
      // ── RETARGETED BY B5, not deleted ──────────────────────────────────────
      //
      // This case used to read *"the two seam keys are NOT ported — they arrive
      // with B5 (§ 6.11)"*, and its whole content was that precondition. B5 is
      // the batch it was waiting for: § 6.12 requires `history` to gain exactly
      // `viewDocument` and `downloadDocument`, so the old assertion and the
      // spec that ordered the change cannot both hold.
      //
      // It is **retargeted rather than deleted**, and the retarget is
      // *stronger* than what it replaces: the keys must now exist in both
      // locales AND their values must appear verbatim in `i18n/ns/history.ts`
      // — which is `B5-AC-86`, checked here against the pinned source instead
      // of against a hand-copied literal.
      //
      // This is the **fifth** instance of the class `ssd.md` § 4.4.1 RULING 13
      // named and specs.md Finding K counted four of. B5's § 6.8 amendment list
      // is closed and does not include this file, so the edit is escalated in
      // `blocked.md` for the architect to ratify rather than absorbed.
      for (final String key in <String>['viewDocument', 'downloadDocument']) {
        expect(en.containsKey(key), isTrue, reason: 'en is missing $key');
        expect(lo.containsKey(key), isTrue, reason: 'lo is missing $key');
        expect(ns, contains('"${en[key]}"'),
            reason: 'en.$key = "${en[key]}" is not in history.ts');
        expect(ns, contains('"${lo[key]}"'),
            reason: 'lo.$key = "${lo[key]}" is not in history.ts');
      }
    });

    test('the 27 dead keys stay out — spot-checked (Finding G)', () {
      for (final String dead in <String>[
        'fixAndResubmit',
        'howToFix',
        'reuploadDocument',
        'statusApproved',
        'eta23BusinessDays',
      ]) {
        expect(en.containsKey(dead), isFalse, reason: '$dead has no t() call');
      }
    });
  });

  group('Tier 1 — the 6 lifted bilingual ternaries, arm by arm (§ 6.11)', () {
    test('each rendered string is byte-identical to the source arm', () {
      // § 6.11: lifting a `lang === "lo" ? A : B` into a key is a MECHANISM
      // change with identical output, and is therefore not a divergence — but
      // only if the strings match exactly. That is what this asserts.
      const Map<String, List<String>> lifted = <String, List<String>>{
        // key: [en arm, lo arm]
        'detailNotFound': <String>[
          'This application could not be found.',
          'ບໍ່ພົບຄຳຮ້ອງນີ້.',
        ],
        'detailLoadError': <String>[
          'This application could not be loaded.',
          'ບໍ່ສາມາດໂຫຼດຄຳຮ້ອງໄດ້.',
        ],
        'timelineEmpty': <String>[
          'Nothing has happened on this case yet.',
          'ຍັງບໍ່ມີການເຄື່ອນໄຫວໃນຄຳຮ້ອງນີ້ເທື່ອ.',
        ],
        'attachments': <String>['Attachments', 'ເອກະສານແນບ'],
        'attachmentsEmpty': <String>[
          'No files are attached to this case.',
          'ບໍ່ມີເອກະສານແນບໃນຄຳຮ້ອງນີ້.',
        ],
      };

      lifted.forEach((String key, List<String> arms) {
        expect(en[key], arms[0], reason: 'en.$key');
        expect(lo[key], arms[1], reason: 'lo.$key');
        // And the arm really is in the TSX, so a transcription slip fails.
        expect(detail, contains(arms[0]), reason: 'en arm of $key not in source');
        expect(detail, contains(arms[1]), reason: 'lo arm of $key not in source');
      });
    });

    test('B7-AC-57 — slaWaitingDetail matches the DETAIL arm, not the list', () {
      // `${detail.days_waiting} of ${detail.sla_days} SLA days` — `:364`.
      expect(en['slaWaitingDetail'], '{waiting} of {sla} SLA days');
      expect(lo['slaWaitingDetail'], 'ລໍຖ້າ {waiting} ມື້ / SLA {sla}');
      expect(detail, contains('SLA days'));

      // And it is a DIFFERENT string from the list's, which is the criterion.
      expect(en['slaWaitingDetail'], isNot(en['slaWaiting']));
      expect(lo['slaWaitingDetail'], isNot(lo['slaWaiting']));
    });

    test('the overdue arm is REUSED, because it is byte-identical', () {
      // `${detail.days_overdue} days overdue` — `:355` — is the same sentence
      // the list renders, so B7b adds no key. Asserted so the reuse is a
      // recorded decision rather than an oversight.
      expect(en['slaOverdue'], '{days} days overdue');
      expect(detail, contains('days overdue'));
    });
  });
}
