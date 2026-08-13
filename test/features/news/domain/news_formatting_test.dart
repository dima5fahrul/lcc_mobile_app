/// `news_formatting.dart` — the date formatter and the two colour readers.
///
/// ## The cross-check is the point of this file
///
/// `formatNewsDate` is the **third** Flutter copy of the same ICU call: the
/// source declares `day()` twice (`NewsPage.tsx:17`, `NewsDetailPage.tsx:26`,
/// byte-identical) and `home_formatting.dart` holds B2b's port of
/// `HomePage.tsx`'s. `news_formatting.dart`'s header records why a copy rather
/// than an import (G-L3 permits `news → home/domain`, and it is a dependency
/// pointing the wrong way; `lib/core/` is the right home and is outside B2c's
/// § 3.1 scope).
///
/// A copy justified by scope is still a copy, so the duplication is **not left
/// to discipline**: the two functions are asserted to agree over every month
/// boundary and every fallback. Importing `home_formatting.dart` here is legal
/// precisely because this is a test and G-L3 scans `lib/`.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:lcc_mobile_app/features/home/domain/home_formatting.dart'
    as home;
import 'package:lcc_mobile_app/features/news/domain/news_formatting.dart';

void main() {
  group('formatNewsDate — day(), NewsPage.tsx:17-26', () {
    test('"2026-08-09" reads as 09 Aug 2026 / 09 ສ.ຫ. 2026', () {
      expect(formatNewsDate('2026-08-09', 'en'), '09 Aug 2026');
      expect(formatNewsDate('2026-08-09', 'lo'), '09 ສ.ຫ. 2026');
    });

    test('September is `Sept` in en-GB — four letters, not three', () {
      // The one month CLDR abbreviates differently in en-GB than in en-US, and
      // the one a hand-written table gets wrong.
      expect(formatNewsDate('2026-09-01', 'en'), '01 Sept 2026');
    });

    test('the day is zero-padded — `{ day: "2-digit" }`', () {
      expect(formatNewsDate('2026-01-05', 'en'), '05 Jan 2026');
    });

    test('an absent or empty value is the empty string, not a dash', () {
      // `if (!value) return ""` — the meta row must collapse, not print a
      // placeholder the web never shows.
      expect(formatNewsDate(null, 'en'), '');
      expect(formatNewsDate('', 'en'), '');
      expect(formatNewsDate('', 'lo'), '');
    });

    test('an unparseable value is returned VERBATIM', () {
      // `Number.isNaN(d.getTime()) → return value`. A malformed date prints as
      // itself rather than blanking the line or taking the card down.
      expect(formatNewsDate('not-a-date', 'en'), 'not-a-date');
      expect(formatNewsDate('not-a-date', 'lo'), 'not-a-date');
    });

    test('an RFC3339 timestamp formats as its date', () {
      // `published_at` is the fallback for a row carrying only the timestamp.
      expect(formatNewsDate('2026-09-01T00:00:00Z', 'en'), '01 Sept 2026');
    });

    test('an unknown language code takes the English branch', () {
      // `lang === "lo" ? … : …` — not an exhaustive switch, so anything that
      // is not `lo` is English, including a locale the app does not support.
      expect(formatNewsDate('2026-08-09', 'fr'), '09 Aug 2026');
    });
  });

  group('the copy cannot drift from home_formatting.formatDate', () {
    test('every month boundary agrees, both locales', () {
      for (int month = 1; month <= 12; month++) {
        final String iso = '2026-${month.toString().padLeft(2, '0')}-01';
        for (final String lang in <String>['en', 'lo']) {
          expect(
            formatNewsDate(iso, lang),
            home.formatDate(iso, lang),
            reason: 'news and home disagree on $iso in $lang. They are two '
                'ports of the same ICU call and the duplication is only '
                'survivable while they agree — see news_formatting.dart.',
          );
        }
      }
    });

    test('the fallbacks agree too', () {
      for (final String? value in <String?>[null, '', 'not-a-date']) {
        for (final String lang in <String>['en', 'lo']) {
          expect(formatNewsDate(value, lang), home.formatDate(value, lang));
        }
      }
    });

    test('the two month tables are element-for-element identical', () {
      expect(kNewsShortMonthsEn, home.kShortMonthsEn);
      expect(kNewsShortMonthsLo, home.kShortMonthsLo);
    });
  });

  group('parseSixDigitHex — the source regex, strictly', () {
    test('accepts a six-digit hex in either case', () {
      expect(parseSixDigitHex('#344EAD'), 0x344EAD);
      expect(parseSixDigitHex('#344ead'), 0x344EAD);
    });

    test('rejects everything the regex rejects', () {
      // `/^#[0-9a-fA-F]{6}$/`. Each of these takes the fallback branch on the
      // web, so each must take it here.
      for (final String bad in <String>[
        '',
        '#FFF',
        '#RRGGBB',
        '344EAD',
        '#344EADFF',
        '#344EA',
        ' #344EAD',
      ]) {
        expect(parseSixDigitHex(bad), isNull, reason: '"$bad" was accepted');
      }
    });
  });

  group('newsTint / newsSolid — tint(), NewsPage.tsx:29-31', () {
    test('a valid colour tints to ~10 % alpha of itself', () {
      // `${color}1A` — the source appends the alpha byte literally.
      final ({int? argb, bool isFallback}) t = newsTint('#3752AE');
      expect(t.isFallback, isFalse);
      expect(t.argb, 0x1A3752AE);
    });

    test('an invalid colour reports the FALLBACK rather than a colour', () {
      // The caller maps this onto `AppColors.primarySoft`, which IS the
      // source's `#EEF2FF`. Returning the literal here would put a colour in
      // `domain/`, which B2-AC-11 forbids outside `presentation/theme/`.
      for (final String bad in <String>['', '#FFF', 'rgb(1,2,3)']) {
        final ({int? argb, bool isFallback}) t = newsTint(bad);
        expect(t.isFallback, isTrue);
        expect(t.argb, isNull);
      }
    });

    test('newsSolid is the opaque form, or null', () {
      expect(newsSolid('#3752AE'), 0xFF3752AE);
      expect(newsSolid(''), isNull);
    });
  });
}
