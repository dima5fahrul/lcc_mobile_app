/// Tier 2 for the history palette — **the file `history_palette.dart:6` has
/// been citing since it was written, which until now did not exist.**
///
/// That citation claimed the fifteen colours on this surface were *"read back
/// out of the pinned TSX rather than out of a transcription."* Measured: no
/// `test/features/history/fidelity/` directory existed, and `grep -in history`
/// over `test/fidelity/tier2_token_parity_test.dart` returns nothing. So every
/// history colour was uncovered by Tier 2, behind a doc comment that said the
/// opposite. This file makes the citation true.
///
/// ## Why value-pinning here is not a tautology
///
/// `color_literal_test.dart` (B2-AC-11) fails the build on any `Color(0x…)`
/// outside `presentation/theme/`. It does **not** check that the value is the
/// one the source states — a `ring` token holding the wrong green passes it
/// perfectly. So each assertion below does two things, exactly as
/// `b10_token_parity_test.dart` does: it reads the hex out of the actual `.tsx`
/// at the pinned commit, and it compares the Dart constant to that. Restating
/// the hex twice in Dart would let the constant and the register drift together
/// and still agree.
///
/// ## This file is also the behaviour-preservation proof for the B7a
/// literal → token replacement
///
/// Fourteen of the fifteen `Color(0xFF…)` literals in `history_palette.dart`
/// were replaced with references to already-existing `AppColors` members that
/// hold the identical value, and the fifteenth (`#86EFAC`) became a new token.
/// A reference resolving to a *different* colour than the literal it replaced
/// is precisely the regression that change risks, and it is invisible to a
/// reviewer reading a diff of names.
///
/// This suite was written and run **against the unreplaced file first** — every
/// assertion below passed while the literals were still literals — and then run
/// again unchanged after the replacement. Two green runs over one unmodified
/// set of expected values is the equivalence proof; the assertions are stated
/// as absolute ARGB, so nothing here can be satisfied by "both sides changed
/// together."
///
/// **`sources/lcc-app` is READ-ONLY.** Nothing here writes.
library;

import 'dart:io';
import 'dart:ui' show Color;

import 'package:flutter_test/flutter_test.dart';
import 'package:lcc_mobile_app/features/application/domain/entities/case_status.dart';
import 'package:lcc_mobile_app/features/history/presentation/widgets/history_palette.dart';
import 'package:lcc_mobile_app/presentation/theme/app_colors.dart';

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

/// Asserts [token] equals `#RRGGBB`, **and** that the same hex really appears
/// in [file] — so a constant that drifted and a doc row that drifted with it
/// still fail.
void _expectColor(
  String file,
  String source,
  Color token,
  String hex, {
  String? because,
}) {
  expect(
    source.toUpperCase(),
    contains(hex.toUpperCase()),
    reason: '$hex is not in $file — the palette\'s citation is stale, or the '
        'source moved. Fix the citation, do not relax the test.',
  );

  final int rgb = int.parse(hex.substring(1), radix: 16);
  expect(
    token.toARGB32() & 0x00FFFFFF,
    rgb,
    reason: because ?? '$file states $hex',
  );
}

void main() {
  late String page;
  late String detail;

  setUpAll(() {
    page = _read('HistoryPage.tsx');
    detail = _read('HistoryDetailPage.tsx');
  });

  group('`STATUS_CONFIG` — `HistoryPage.tsx:42-46`', () {
    test('approved is {bg #DCFCE7, text #15803D, ring #86EFAC}', () {
      final StatusChipStyle s = statusChipStyleFor(StatusBucket.approved);
      _expectColor('HistoryPage.tsx', page, s.background, '#DCFCE7');
      _expectColor('HistoryPage.tsx', page, s.foreground, '#15803D');
      _expectColor(
        'HistoryPage.tsx',
        page,
        s.ring,
        '#86EFAC',
        because: 'green-300. The one value on this surface with no pre-existing '
            '`AppColors` member — it is `AppColors.successRing`, added by B7a. '
            'Deliberately NOT `successBorder` (#BBF7D0, green-200) which is a '
            'different colour, nor `green300` (#7BF1A8) which is Tailwind '
            'v4\'s green-300 while this is an inline hex of v3\'s.',
      );
    });

    test('rejected is {bg #FEE2E2, text #DC2626, ring #FCA5A5}', () {
      final StatusChipStyle s = statusChipStyleFor(StatusBucket.rejected);
      _expectColor('HistoryPage.tsx', page, s.background, '#FEE2E2');
      _expectColor('HistoryPage.tsx', page, s.foreground, '#DC2626');
      _expectColor('HistoryPage.tsx', page, s.ring, '#FCA5A5');
    });

    test('pending is {bg #FEF3C7, text #D97706, ring #FCD34D}', () {
      final StatusChipStyle s = statusChipStyleFor(StatusBucket.pending);
      _expectColor('HistoryPage.tsx', page, s.background, '#FEF3C7');
      _expectColor('HistoryPage.tsx', page, s.foreground, '#D97706');
      _expectColor('HistoryPage.tsx', page, s.ring, '#FCD34D');
    });
  });

  group('the four stat tiles — `HistoryPage.tsx:165-168`', () {
    test('total is the brand pair', () {
      _expectColor('HistoryPage.tsx', page, kTileTotal.color, '#344EAD');
      _expectColor('HistoryPage.tsx', page, kTileTotal.background, '#EEF2FF');
    });

    test('approved / in-review / rejected', () {
      _expectColor('HistoryPage.tsx', page, kTileApproved.color, '#16A34A');
      _expectColor('HistoryPage.tsx', page, kTileApproved.background, '#DCFCE7');
      _expectColor('HistoryPage.tsx', page, kTileInReview.color, '#D97706');
      _expectColor('HistoryPage.tsx', page, kTileInReview.background, '#FEF3C7');
      _expectColor('HistoryPage.tsx', page, kTileRejected.color, '#DC2626');
      _expectColor('HistoryPage.tsx', page, kTileRejected.background, '#FEE2E2');
    });
  });

  group('the progress bar — `HistoryPage.tsx:347-351`', () {
    test('the three-way ternary, per bucket', () {
      _expectColor('HistoryPage.tsx', page,
          progressBarColour(StatusBucket.rejected), '#DC2626');
      _expectColor('HistoryPage.tsx', page,
          progressBarColour(StatusBucket.approved), '#16A34A');
      _expectColor('HistoryPage.tsx', page,
          progressBarColour(StatusBucket.pending), '#344EAD');
    });

    test('B7-AC-31 — the bar\'s green is NOT the chip\'s green', () {
      expect(
        progressBarColour(StatusBucket.approved).toARGB32(),
        isNot(statusChipStyleFor(StatusBucket.approved).foreground.toARGB32()),
        reason: '#16A34A vs #15803D — two greens on one row, the source\'s. '
            'The replacement swapped these onto two different tokens '
            '(`categoryAccentFinance` / `success`); collapsing them onto one '
            'would be the exact loss this asserts against.',
      );
    });

    test('the track is `bg-gray-100`', () {
      expect(kProgressTrack.toARGB32(), 0xFFF3F4F6);
    });
  });

  group('`paymentChipStyle` — `HistoryDetailPage.tsx:77-82`', () {
    test('paid / pending / failed', () {
      _expectColor('HistoryDetailPage.tsx', detail,
          paymentChipStyleFor(PaymentState.paid).background, '#DCFCE7');
      _expectColor('HistoryDetailPage.tsx', detail,
          paymentChipStyleFor(PaymentState.paid).foreground, '#15803D');
      _expectColor('HistoryDetailPage.tsx', detail,
          paymentChipStyleFor(PaymentState.pending).background, '#FEF3C7');
      _expectColor('HistoryDetailPage.tsx', detail,
          paymentChipStyleFor(PaymentState.pending).foreground, '#B45309');
      _expectColor('HistoryDetailPage.tsx', detail,
          paymentChipStyleFor(PaymentState.failed).background, '#FEE2E2');
      _expectColor('HistoryDetailPage.tsx', detail,
          paymentChipStyleFor(PaymentState.failed).foreground, '#DC2626');
    });

    test('the shared default — refunded, free and unknown', () {
      for (final PaymentState s in <PaymentState>[
        PaymentState.refunded,
        PaymentState.free,
        PaymentState.unknown,
      ]) {
        _expectColor('HistoryDetailPage.tsx', detail,
            paymentChipStyleFor(s).background, '#F3F4F6');
        _expectColor('HistoryDetailPage.tsx', detail,
            paymentChipStyleFor(s).foreground, '#6B7280');
      }
    });
  });

  group('the SLA chip — `HistoryPage.tsx:366-371`', () {
    test('overdue is the red pair, on-time the grey pair', () {
      _expectColor('HistoryPage.tsx', page,
          slaChipStyle(isOverdue: true).background, '#FEE2E2');
      _expectColor('HistoryPage.tsx', page,
          slaChipStyle(isOverdue: true).foreground, '#DC2626');
      _expectColor('HistoryPage.tsx', page,
          slaChipStyle(isOverdue: false).background, '#F3F4F6');
      _expectColor('HistoryPage.tsx', page,
          slaChipStyle(isOverdue: false).foreground, '#6B7280');
    });
  });

  group('the header gradient — `HistoryPage.tsx:139-141`', () {
    test('the 60% mid stop survives the port', () {
      // A two-stop `LinearGradient` would render a plausible-looking ramp and
      // silently lose this; it is the half of a gradient port that no colour
      // assertion catches.
      expect(kHistoryHeaderMidStop, 0.6);
      expect(page, contains('60%'));
    });
  });

  group('B7a behaviour preservation — the replacement changed no value', () {
    // The literal each token reference replaced, stated as absolute ARGB. If a
    // reference resolves to a different member than intended — the one real
    // risk of a name-for-literal swap — exactly one of these fails and names
    // the site.
    test('every replaced literal still renders its original ARGB', () {
      final Map<String, int> expected = <String, int>{
        'approved.background': 0xFFDCFCE7,
        'approved.foreground': 0xFF15803D,
        'approved.ring': 0xFF86EFAC,
        'rejected.background': 0xFFFEE2E2,
        'rejected.foreground': 0xFFDC2626,
        'rejected.ring': 0xFFFCA5A5,
        'pending.background': 0xFFFEF3C7,
        'pending.foreground': 0xFFD97706,
        'pending.ring': 0xFFFCD34D,
        'tileTotal.color': 0xFF344EAD,
        'tileTotal.background': 0xFFEEF2FF,
        'tileApproved.color': 0xFF16A34A,
        'tileApproved.background': 0xFFDCFCE7,
        'tileInReview.color': 0xFFD97706,
        'tileInReview.background': 0xFFFEF3C7,
        'tileRejected.color': 0xFFDC2626,
        'tileRejected.background': 0xFFFEE2E2,
        'progress.rejected': 0xFFDC2626,
        'progress.approved': 0xFF16A34A,
        'progress.pending': 0xFF344EAD,
        'progress.track': 0xFFF3F4F6,
        'payment.paid.bg': 0xFFDCFCE7,
        'payment.paid.fg': 0xFF15803D,
        'payment.pending.bg': 0xFFFEF3C7,
        'payment.pending.fg': 0xFFB45309,
        'payment.failed.bg': 0xFFFEE2E2,
        'payment.failed.fg': 0xFFDC2626,
        'payment.default.bg': 0xFFF3F4F6,
        'payment.default.fg': 0xFF6B7280,
        'sla.overdue.bg': 0xFFFEE2E2,
        'sla.overdue.fg': 0xFFDC2626,
        'sla.ontime.bg': 0xFFF3F4F6,
        'sla.ontime.fg': 0xFF6B7280,
      };

      final Map<String, int> actual = <String, int>{
        'approved.background':
            statusChipStyleFor(StatusBucket.approved).background.toARGB32(),
        'approved.foreground':
            statusChipStyleFor(StatusBucket.approved).foreground.toARGB32(),
        'approved.ring':
            statusChipStyleFor(StatusBucket.approved).ring.toARGB32(),
        'rejected.background':
            statusChipStyleFor(StatusBucket.rejected).background.toARGB32(),
        'rejected.foreground':
            statusChipStyleFor(StatusBucket.rejected).foreground.toARGB32(),
        'rejected.ring':
            statusChipStyleFor(StatusBucket.rejected).ring.toARGB32(),
        'pending.background':
            statusChipStyleFor(StatusBucket.pending).background.toARGB32(),
        'pending.foreground':
            statusChipStyleFor(StatusBucket.pending).foreground.toARGB32(),
        'pending.ring':
            statusChipStyleFor(StatusBucket.pending).ring.toARGB32(),
        'tileTotal.color': kTileTotal.color.toARGB32(),
        'tileTotal.background': kTileTotal.background.toARGB32(),
        'tileApproved.color': kTileApproved.color.toARGB32(),
        'tileApproved.background': kTileApproved.background.toARGB32(),
        'tileInReview.color': kTileInReview.color.toARGB32(),
        'tileInReview.background': kTileInReview.background.toARGB32(),
        'tileRejected.color': kTileRejected.color.toARGB32(),
        'tileRejected.background': kTileRejected.background.toARGB32(),
        'progress.rejected':
            progressBarColour(StatusBucket.rejected).toARGB32(),
        'progress.approved':
            progressBarColour(StatusBucket.approved).toARGB32(),
        'progress.pending': progressBarColour(StatusBucket.pending).toARGB32(),
        'progress.track': kProgressTrack.toARGB32(),
        'payment.paid.bg':
            paymentChipStyleFor(PaymentState.paid).background.toARGB32(),
        'payment.paid.fg':
            paymentChipStyleFor(PaymentState.paid).foreground.toARGB32(),
        'payment.pending.bg':
            paymentChipStyleFor(PaymentState.pending).background.toARGB32(),
        'payment.pending.fg':
            paymentChipStyleFor(PaymentState.pending).foreground.toARGB32(),
        'payment.failed.bg':
            paymentChipStyleFor(PaymentState.failed).background.toARGB32(),
        'payment.failed.fg':
            paymentChipStyleFor(PaymentState.failed).foreground.toARGB32(),
        'payment.default.bg':
            paymentChipStyleFor(PaymentState.refunded).background.toARGB32(),
        'payment.default.fg':
            paymentChipStyleFor(PaymentState.refunded).foreground.toARGB32(),
        'sla.overdue.bg': slaChipStyle(isOverdue: true).background.toARGB32(),
        'sla.overdue.fg': slaChipStyle(isOverdue: true).foreground.toARGB32(),
        'sla.ontime.bg': slaChipStyle(isOverdue: false).background.toARGB32(),
        'sla.ontime.fg': slaChipStyle(isOverdue: false).foreground.toARGB32(),
      };

      expect(actual, expected);
    });

    test('the fifteen distinct values are still fifteen', () {
      // A wrong reference that happened to land on a value already present
      // elsewhere in the palette would keep every individual assertion above
      // honest only because the map keys differ. This catches the collapse.
      expect(
        <int>{
          for (final StatusBucket b in StatusBucket.values) ...<int>[
            statusChipStyleFor(b).background.toARGB32(),
            statusChipStyleFor(b).foreground.toARGB32(),
            statusChipStyleFor(b).ring.toARGB32(),
          ],
          kTileTotal.color.toARGB32(),
          kTileTotal.background.toARGB32(),
          kTileApproved.color.toARGB32(),
          kTileInReview.color.toARGB32(),
          kTileRejected.color.toARGB32(),
          kProgressTrack.toARGB32(),
          paymentChipStyleFor(PaymentState.pending).foreground.toARGB32(),
          paymentChipStyleFor(PaymentState.refunded).foreground.toARGB32(),
        },
        hasLength(15),
      );
    });
  });

  group('the new token sits correctly in `AppColors`', () {
    test('successRing is green-300 and collides with nothing', () {
      expect(AppColors.successRing.toARGB32(), 0xFF86EFAC);

      // The three near neighbours it must not be confused with. Each is a
      // real, separately-owned token at a different value.
      expect(AppColors.successBorder.toARGB32(), 0xFFBBF7D0); // v3 green-200
      expect(AppColors.green300.toARGB32(), 0xFF7BF1A8); // v4 green-300
      expect(AppColors.success.toARGB32(), 0xFF15803D); // v3 green-700

      expect(
        <int>{
          AppColors.successRing.toARGB32(),
          AppColors.successBorder.toARGB32(),
          AppColors.green300.toARGB32(),
          AppColors.success.toARGB32(),
        },
        hasLength(4),
        reason: 'four names, four values — if any two ever converge, one of '
            'them was a substitution',
      );
    });
  });
}
