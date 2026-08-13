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
/// ## Why this is a third copy
///
/// `features/service/` and `features/home/` each hold one, and **G-L3 forbids
/// importing either**: Cross-Feature Isolation (SSD § 4.3) lets one feature
/// depend on another's `domain/` and never on its `presentation/`. Home's copy
/// already records the same reasoning and the same two rejected alternatives
/// (hoisting to `lib/presentation/common/`, which § 6.3.4 scoped to `GlassIcon`
/// alone; or hanging it off the shared `Bilingual` entity, which would give a
/// session-owned type a presentation concern).
///
/// The duplication is **inert**: the fallback chain is fixed by `types.ts` and
/// cannot drift without the source drifting. Recorded here so the next reader
/// does not "fix" it by adding the forbidden import — and
/// `test/features/news/presentation/bilingual_text_test.dart` pins it against
/// the same table Home's is pinned against.
library;

import 'package:flutter/widgets.dart';

import '../../../session/domain/entities/bilingual.dart';

extension NewsBilingualX on Bilingual {
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
