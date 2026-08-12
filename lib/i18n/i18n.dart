/// i18n bootstrap and bilingual text helper.
///
/// Ports `lcc-app/src/app/i18n/` (23-namespace TS dictionary) to Flutter
/// `easy_localization` JSON under `assets/i18n/{en,lo}.json`.
///
/// - [AppI18n.init] must be awaited at app start (before `runApp`) so
///   `easy_localization` can preload the JSON tables.
/// - [Lang] mirrors `lcc-app/src/app/api/types.ts` `Lang = "en" | "lo"`.
/// - [text] ports the `text()` helper from the same `types.ts`: pick the side
///   of a [Bilingual] pair the user is reading, with a fallback to whichever
///   side is non-empty.
///
/// Access pattern in widgets:
///   `'auth.signIn'.tr()`                          → static key
///   `'auth.resendIn'.tr(namedArgs: {'seconds': 30})` → interpolation
library;

import 'dart:ui';

import 'package:easy_localization/easy_localization.dart';

import '../features/session/domain/entities/bilingual.dart';

/// Initializes the `easy_localization` asset loader.
///
/// Call once at boot, before `runApp`. The JSON tables live at
/// `assets/i18n/{en,lo}.json` (registered in `pubspec.yaml`'s `flutter.assets`).
class AppI18n {
  const AppI18n._();

  /// Ensures `easy_localization` has loaded the locale JSON tables.
  static Future<void> init() async {
    await EasyLocalization.ensureInitialized();
  }
}

/// UI language.
///
/// Ported from `lcc-app/src/app/api/types.ts`:
///   `export type Lang = "en" | "lo";`
enum Lang {
  en,
  lo,
  ;

  /// Converts to `easy_localization`'s `Locale`.
  Locale toLocale() {
    switch (this) {
      case Lang.en:
        return const Locale('en');
      case Lang.lo:
        return const Locale('lo');
    }
  }

  /// Parses a language code string (`"en"`, `"lo"`) into a [Lang].
  /// Falls back to [Lang.lo] for unknown codes (matches `StorageService.getLang`
  /// default of `"lo"`).
  static Lang fromCode(String? code) {
    switch (code) {
      case 'en':
        return Lang.en;
      case 'lo':
      default:
        return Lang.lo;
    }
  }
}

/// Reads the side of a [Bilingual] pair the user is reading, with a fallback.
///
/// Ported verbatim from `lcc-app/src/app/api/types.ts`:
///   ```
///   export function text(value: Bilingual | undefined | null, lang: Lang): string {
///     if (!value) return "";
///     const wanted = lang === "lo" ? value.lo : value.en;
///     return wanted || value.en || value.lo || "";
///   }
///   ```
/// The `Bilingual` entity lives at
/// `lib/features/session/domain/entities/bilingual.dart` (P0-2).
///
/// - When `value` is null, returns the empty string (defensive; the freezed
///   `Bilingual` requires non-empty `en` + `lo`, but a usecase may hand us a
///   nullable result).
/// - Picks `value.lo` when the reader is Lao, else `value.en`.
/// - If the wanted side is empty, falls back to `en`, then `lo`, then `""`.
///   Dart's `||` is bool-only, so the JS `wanted || value.en || value.lo || ""`
///   chain is expressed here with explicit `isEmpty` checks.
String text(Bilingual? value, Lang lang) {
  if (value == null) return '';
  final wanted = lang == Lang.lo ? value.lo : value.en;
  if (wanted.isNotEmpty) return wanted;
  if (value.en.isNotEmpty) return value.en;
  if (value.lo.isNotEmpty) return value.lo;
  return '';
}
