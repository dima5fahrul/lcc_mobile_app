/// Reading the side of a [Bilingual] pair the citizen is reading.
///
/// Port of `text(value, lang)` (`types.ts:17-22`) with its fallback chain
/// `wanted || en || lo || ""`.
///
/// The **fourth** copy in the tree (service, home, news, help). G-L3 forbids
/// importing any of the other three: Cross-Feature Isolation lets one feature
/// depend on another's `domain/`, never on its `presentation/`. The two
/// alternatives were weighed and rejected when Home's copy landed — hoisting to
/// `lib/presentation/common/` would push past § 6.3.4's "this one widget only"
/// ruling on `GlassIcon`, and hanging it off the shared `Bilingual` entity
/// would give a session-owned type a presentation concern.
///
/// The duplication is inert — the chain is fixed by `types.ts` — and
/// `test/features/help/presentation/bilingual_text_test.dart` pins it against
/// the same table the others are pinned against, so the four cannot drift.
library;

import 'package:flutter/widgets.dart';

import '../../../session/domain/entities/bilingual.dart';

extension HelpBilingualX on Bilingual {
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
