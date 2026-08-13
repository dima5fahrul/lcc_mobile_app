/// The fee label on a service card.
///
/// Port of `formatLak` / `formatFee` (`lcc-app/src/app/serviceConfig.ts:38-53`),
/// reading the catalogue row directly instead of the seeded `SERVICE_CONFIG`
/// table — see `Service`'s doc for why the seed table has no port.
///
/// ```ts
/// formatLak(n, lang):  n === null ? "—" : n === 0 ? (lo ? "ຟຣີ" : "Free")
///                                                 : `${n.toLocaleString("en-US")} ${lo ? "ກີບ" : "LAK"}`
/// formatFee(cfg, lang): range ? `${lo}–${hi} ${unit}` : formatLak(cfg.fee, lang)
/// ```
///
/// ## Three details that look like nits and are not
///
/// 1. **`toLocaleString("en-US")`, pinned to en-US in the source itself.** So
///    the thousands separator is a comma in *both* locales — `100,000 ກີບ`, not
///    `100.000`. Formatting Lao numerals or a locale-aware separator would be a
///    visible divergence on all 43 cards.
/// 2. **The dash in a range is U+2013 EN DASH**, not a hyphen. The source
///    writes `–`. At 12 px the difference is a couple of pixels of width; in a
///    Tier 1 text comparison it is a mismatch on every ranged fee.
/// 3. **`fee: null` renders `—` (U+2014 EM DASH), not `0`.** The wire has no
///    null — `fee_lak` is a non-nullable int — so [formatLak]'s null branch is
///    unreachable from `/services` today. It is ported anyway because
///    `DEFAULT_SERVICE_CONFIG` sets `fee: null` and F0's per-service pages read
///    the same formatter; dropping the branch now would mean rediscovering it
///    there.
library;

/// The strings the source hardcodes rather than putting in the `service`
/// dictionary. Kept together so the port is auditable in one place.
///
/// They are **not** i18n keys, deliberately: `assets/i18n/*.json` mirrors the
/// React `ns/*.ts` dictionaries key for key (SSD § 10.2), and inventing keys
/// the source does not have would make that mirror impossible to verify.
class ServiceFeeCopy {
  const ServiceFeeCopy._();

  /// `formatLak`'s `n === 0` branch.
  static const String freeEn = 'Free';
  static const String freeLo = 'ຟຣີ';

  /// The currency word appended to a non-zero amount.
  static const String unitEn = 'LAK';
  static const String unitLo = 'ກີບ';

  /// `formatLak`'s `n === null` branch. U+2014.
  static const String unknown = '—';

  /// The range separator. U+2013.
  static const String rangeDash = '–';
}

/// `n.toLocaleString("en-US")` — grouped in threes with commas, always.
String groupThousands(int n) {
  final String digits = n.abs().toString();
  final StringBuffer out = StringBuffer(n < 0 ? '-' : '');

  for (int i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) out.write(',');
    out.write(digits[i]);
  }

  return out.toString();
}

/// `formatLak(n, lang)`.
String formatLak(int? amount, String languageCode) {
  if (amount == null) return ServiceFeeCopy.unknown;
  if (amount == 0) {
    return languageCode == 'lo' ? ServiceFeeCopy.freeLo : ServiceFeeCopy.freeEn;
  }
  final String unit =
      languageCode == 'lo' ? ServiceFeeCopy.unitLo : ServiceFeeCopy.unitEn;
  return '${groupThousands(amount)} $unit';
}

/// `formatFee(cfg, lang)`.
///
/// [max] is the range's upper bound and is honoured only when the source's own
/// two conditions hold: `cfg.feeMax != null && cfg.fee != null && cfg.feeMax >
/// cfg.fee`. On the wire that is `fee_is_range && fee_max_lak > fee_lak` — the
/// server sends `fee_max_lak: 0` for every non-ranged service, so testing the
/// flag alone would turn a 20,000 LAK fee into "20,000–0".
String formatFee({
  required int fee,
  required int max,
  required bool isRange,
  required String languageCode,
}) {
  if (isRange && max > fee) {
    final String unit =
        languageCode == 'lo' ? ServiceFeeCopy.unitLo : ServiceFeeCopy.unitEn;
    return '${groupThousands(fee)}${ServiceFeeCopy.rangeDash}'
        '${groupThousands(max)} $unit';
  }
  return formatLak(fee, languageCode);
}

/// True when [fee] renders as "Free" — the card tints it green rather than
/// brand blue (`ServiceCard.tsx:83`, `isFree ? "#15803D" : "#344EAD"`).
///
/// The source's `isFree` is `cfg.fee === 0 && cfg.feeMax == null`; on the wire
/// the second half is "not a range", since a ranged fee always has a non-zero
/// lower bound in practice and `fee_max_lak` is `0` when unset.
bool isFreeFee({required int fee, required int max, required bool isRange}) =>
    fee == 0 && !(isRange && max > fee);
