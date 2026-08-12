/// `Lang` and the `text()` bilingual helper.
///
/// `text()` is a verbatim port of the TS
/// `wanted || value.en || value.lo || ""` chain, and the fallback order is the
/// whole substance of it: a Lao reader whose record has an empty `lo` must see
/// the English name rather than a blank field on a government document.
///
/// `AppI18n.init()` is deliberately not exercised — it calls
/// `EasyLocalization.ensureInitialized()`, which reaches for
/// `SharedPreferences` and the platform locale, neither of which answers in a
/// headless run. That boot path is covered instead by the assembled-app tests
/// in `test/app/`, which stand the localisation stack up through an in-memory
/// asset loader.
library;

import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:lcc_mobile_app/features/session/domain/entities/bilingual.dart';
import 'package:lcc_mobile_app/i18n/i18n.dart';

void main() {
  group('Lang', () {
    test('maps to its locale', () {
      expect(Lang.en.toLocale(), const Locale('en'));
      expect(Lang.lo.toLocale(), const Locale('lo'));
    });

    test('parses the two known codes', () {
      expect(Lang.fromCode('en'), Lang.en);
      expect(Lang.fromCode('lo'), Lang.lo);
    });

    test('falls back to lo for null and unknown codes, matching '
        'StorageService.getLang', () {
      expect(Lang.fromCode(null), Lang.lo);
      expect(Lang.fromCode(''), Lang.lo);
      expect(Lang.fromCode('fr'), Lang.lo);
      expect(Lang.fromCode('EN'), Lang.lo, reason: 'the port is case-sensitive');
    });
  });

  group('text()', () {
    const Bilingual both = Bilingual(en: 'Vientiane', lo: 'ວຽງຈັນ');

    test('returns the reader-s own side', () {
      expect(text(both, Lang.en), 'Vientiane');
      expect(text(both, Lang.lo), 'ວຽງຈັນ');
    });

    test('falls back to English when the Lao side is empty', () {
      expect(text(const Bilingual(en: 'Vientiane', lo: ''), Lang.lo), 'Vientiane');
    });

    test('falls back to Lao when the English side is empty', () {
      expect(text(const Bilingual(en: '', lo: 'ວຽງຈັນ'), Lang.en), 'ວຽງຈັນ');
    });

    test('returns an empty string when both sides are empty', () {
      expect(text(const Bilingual(en: '', lo: ''), Lang.en), '');
      expect(text(const Bilingual(en: '', lo: ''), Lang.lo), '');
    });

    test('returns an empty string for a null value', () {
      expect(text(null, Lang.en), '');
      expect(text(null, Lang.lo), '');
    });
  });
}
