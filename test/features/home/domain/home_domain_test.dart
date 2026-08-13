/// Home's domain layer: the four pure transforms and the two derived getters.
///
/// Every case here is a boundary the source has a branch for, and the boundary
/// is what fails in production: a zero fee, a one-character name, a
/// `fee_max_lak` of 0 that is not a range, a date that will not parse.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:lcc_mobile_app/features/home/domain/entities/digital_id_card.dart';
import 'package:lcc_mobile_app/features/home/domain/entities/home_news_item.dart';
import 'package:lcc_mobile_app/features/home/domain/home_formatting.dart';

void main() {
  group('groupThousands — toLocaleString("en-US"), in both locales', () {
    test('groups by three from the right', () {
      expect(groupThousands(0), '0');
      expect(groupThousands(999), '999');
      expect(groupThousands(1000), '1,000');
      expect(groupThousands(20000), '20,000');
      expect(groupThousands(145000), '145,000');
      expect(groupThousands(1234567), '1,234,567');
    });

    test('a negative amount keeps its sign outside the grouping', () {
      // Not reachable from a fee, reachable from a wallet balance the server
      // could send negative. `-1,000`, not `-,1000`.
      expect(groupThousands(-1000), '-1,000');
    });
  });

  group('formatLak — serviceConfig.ts:38-43', () {
    test('null is an em dash, not "Free"', () {
      // "not configured / to be confirmed" is a different statement from
      // "costs nothing", and the source distinguishes them.
      expect(formatLak(null, 'en'), '—');
      expect(formatLak(null, 'lo'), '—');
    });

    test('zero is Free / ຟຣີ', () {
      expect(formatLak(0, 'en'), 'Free');
      expect(formatLak(0, 'lo'), 'ຟຣີ');
    });

    test('an amount carries the locale currency word and en-US grouping', () {
      expect(formatLak(20000, 'en'), '20,000 LAK');
      expect(formatLak(20000, 'lo'), '20,000 ກີບ');
    });

    test('an unknown language code reads as English, matching `lang === "lo"`',
        () {
      expect(formatLak(20000, 'th'), '20,000 LAK');
    });
  });

  group('formatFee — serviceConfig.ts:46-53', () {
    test('all three conditions must hold before it is a range', () {
      // The branch is `feeMax != null && fee != null && feeMax > fee`. Every
      // catalogue row but `marriage` has `fee_max_lak: 0`, so a looser test
      // would print "20,000–0 LAK" on 42 of 43 services.
      expect(
        formatFee(fee: 20000, feeMax: null, languageCode: 'en'),
        '20,000 LAK',
      );
      expect(
        formatFee(fee: 20000, feeMax: 0, languageCode: 'en'),
        '20,000 LAK',
      );
      expect(
        formatFee(fee: 20000, feeMax: 20000, languageCode: 'en'),
        '20,000 LAK',
      );
      expect(
        formatFee(fee: null, feeMax: 250000, languageCode: 'en'),
        '—',
      );
    });

    test('a real range uses an EN DASH, not a hyphen', () {
      // `marriage`, the one row in the recorded catalogue with a range.
      // Tier 1 compares text byte-exactly, so U+2013 vs U+002D is a failure.
      const String en = '100,000–250,000 LAK';
      expect(formatFee(fee: 100000, feeMax: 250000, languageCode: 'en'), en);
      expect(en.contains('–'), isTrue);
      expect(en.contains('-'), isFalse);

      expect(
        formatFee(fee: 100000, feeMax: 250000, languageCode: 'lo'),
        '100,000–250,000 ກີບ',
      );
    });

    test('a free service is Free even with a null upper bound', () {
      expect(formatFee(fee: 0, feeMax: null, languageCode: 'en'), 'Free');
    });
  });

  group('maskValue — Hero.tsx:25-38', () {
    test('the documented example, character for character', () {
      expect(maskValue('Bounmy Sisavath'), 'B••••• •••••••h');
    });

    test('separators in `keep` survive — a UIN keeps its shape', () {
      expect(maskValue('1-2540-08842-15', keep: ' -'), '1-••••-•••••-•5');
    });

    test('a separator BETWEEN the ends is still masked when not in `keep`', () {
      // `first` and `last` index the whole string, not each run — so the space
      // in the middle of a name is only exempt because it is in `keep`.
      expect(maskValue('a b', keep: ''), 'a•b');
    });

    test('a one-character value is returned intact', () {
      // `first == last`, so the single character is both ends and neither is
      // masked. A naive rewrite turns a one-letter display name into a single
      // bullet.
      expect(maskValue('B'), 'B');
    });

    test('an empty value stays empty rather than throwing', () {
      expect(maskValue(''), '');
    });

    test('a value that is only separators is untouched', () {
      // `first` stays -1, so nothing is a "real" character and nothing masks.
      expect(maskValue('   '), '   ');
    });

    test('it masks by character, not by UTF-16 code unit', () {
      // A Lao name is multi-byte; masking by code unit would split a
      // surrogate or over-count the bullets.
      const String lao = 'ບຸນມີ ສີສະຫວັດ';
      final String masked = maskValue(lao);
      expect(masked.runes.length, lao.runes.length);
      expect(masked.runes.first, lao.runes.first);
      expect(masked.runes.last, lao.runes.last);
    });
  });

  group('formatDate — HomePage.tsx:96-105', () {
    test('an ISO date becomes "06 Aug 2026" / "06 ສ.ຫ. 2026"', () {
      expect(formatDate('2026-08-06', 'en'), '06 Aug 2026');
      expect(formatDate('2026-08-06', 'lo'), '06 ສ.ຫ. 2026');
    });

    test('September is "Sept" in en-GB, not "Sep"', () {
      // The one month where the en-GB abbreviation is four characters. A US
      // month table would silently differ from the web here and nowhere else.
      expect(formatDate('2026-09-01', 'en'), '01 Sept 2026');
    });

    test('the day is zero-padded — `day: "2-digit"`', () {
      expect(formatDate('2026-01-05', 'en'), '05 Jan 2026');
    });

    test('a full timestamp is accepted, not only a date', () {
      expect(formatDate('2026-09-01T00:00:00Z', 'en'), '01 Sept 2026');
    });

    test('an absent value is empty, an unparseable one is returned verbatim',
        () {
      // Both are the source's own branches: `if (!value) return ""` and
      // `if (Number.isNaN(d.getTime())) return value`. The second matters —
      // the card prints this straight into a Text, so a malformed date must
      // show the raw string rather than blank the line.
      expect(formatDate(null, 'en'), '');
      expect(formatDate('', 'en'), '');
      expect(formatDate('not-a-date', 'en'), 'not-a-date');
    });

    test('both month tables have twelve entries', () {
      expect(kShortMonthsEn, hasLength(12));
      expect(kShortMonthsLo, hasLength(12));
      // Every month index resolves — an off-by-one in the table would throw on
      // December rather than render wrong.
      for (int m = 1; m <= 12; m++) {
        final String iso = '2026-${m.toString().padLeft(2, '0')}-15';
        expect(formatDate(iso, 'en'), contains(kShortMonthsEn[m - 1]));
        expect(formatDate(iso, 'lo'), contains(kShortMonthsLo[m - 1]));
      }
    });
  });

  group('DigitalIdCard.verifyPayload — HomePage.tsx:285', () {
    test('qr_payload wins, then verify_url, then verify_code', () {
      expect(
        const DigitalIdCard(
          qrPayload: 'qr',
          verifyUrl: 'url',
          verifyCode: 'code',
        ).verifyPayload,
        'qr',
      );
      expect(
        const DigitalIdCard(verifyUrl: 'url', verifyCode: 'code')
            .verifyPayload,
        'url',
      );
      expect(const DigitalIdCard(verifyCode: 'code').verifyPayload, 'code');
    });

    test('none of the three is empty, which hides the payload line', () {
      expect(const DigitalIdCard().verifyPayload, '');
    });
  });

  group('HomeNewsItem.publishedOn — HomePage.tsx:684', () {
    test('published_date wins over published_at', () {
      expect(
        const HomeNewsItem(
          publishedDate: '2026-08-06',
          publishedAt: '2026-08-07T00:00:00Z',
        ).publishedOn,
        '2026-08-06',
      );
    });

    test('published_at is the fallback, and empty is the floor', () {
      expect(
        const HomeNewsItem(publishedAt: '2026-08-07T00:00:00Z').publishedOn,
        '2026-08-07T00:00:00Z',
      );
      expect(const HomeNewsItem().publishedOn, '');
    });
  });
}
