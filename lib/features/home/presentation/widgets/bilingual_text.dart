/// Reading the side of a [Bilingual] pair the citizen is reading.
///
/// Port of `text(value, lang)` (`lcc-app/src/app/api/types.ts:17-22`),
/// **including its fallback chain**:
///
/// ```ts
/// const wanted = lang === "lo" ? value.lo : value.en;
/// return wanted || value.en || value.lo || "";
/// ```
///
/// ## Why this is a second copy of `features/service/.../bilingual_text.dart`
///
/// Because **G-L3 forbids the import**. That extension lives in the service
/// feature's `presentation/` layer, and Cross-Feature Isolation (SSD § 4.3)
/// lets one feature depend on another's `domain/` and never on its
/// `presentation/`. The alternatives are worse in both directions: hoisting it
/// to `lib/presentation/common/` would pull a fifth group forward past
/// § 6.3.4's "this one widget only" ruling on `GlassIcon`, and putting it on
/// the `Bilingual` entity would give a type shared with the session feature a
/// presentation concern to serve two pages.
///
/// Eight lines duplicated is the cheapest of the three, and the duplication is
/// **inert**: the fallback chain is fixed by `types.ts` and cannot drift
/// without the source drifting. Recorded here so the next reader does not
/// "fix" it by adding the forbidden import.
library;

import 'package:flutter/widgets.dart';

import '../../../session/domain/entities/bilingual.dart';

extension HomeBilingualX on Bilingual {
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
