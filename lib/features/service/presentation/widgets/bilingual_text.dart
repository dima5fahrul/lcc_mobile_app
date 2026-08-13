/// Reading the side of a [Bilingual] pair the citizen is reading.
///
/// Port of `text(value, lang)` (`lcc-app/src/app/api/types.ts:17-22`),
/// **including its fallback chain**, which is not decoration:
///
/// ```ts
/// const wanted = lang === "lo" ? value.lo : value.en;
/// return wanted || value.en || value.lo || "";
/// ```
///
/// The catalogue is administrator-maintained and a row can reach the wire with
/// one side blank. The source's answer is to show the other language rather
/// than a hole, and a Flutter page that rendered `''` where the web renders the
/// English name would be a Tier 1 failure on a row nobody thought to test.
///
/// An extension rather than a method on the entity: the fallback is a
/// *rendering* decision (what to put on screen when the data is thin), the
/// entity is shared with the session feature, and `Bilingual` should not grow a
/// presentation concern to serve one page.
library;

import 'package:flutter/widgets.dart';

import '../../../session/domain/entities/bilingual.dart';

extension BilingualX on Bilingual {
  /// The [languageCode] side, falling back to English, then Lao, then empty.
  String forLanguage(String languageCode) {
    final String wanted = languageCode == 'lo' ? lo : en;
    if (wanted.isNotEmpty) return wanted;
    if (en.isNotEmpty) return en;
    return lo;
  }

  /// [forLanguage] against the ambient locale.
  String forContext(BuildContext context) =>
      forLanguage(Localizations.localeOf(context).languageCode);
}
