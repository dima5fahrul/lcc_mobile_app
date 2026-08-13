/// Reads the wire's `{ "en": …, "lo": … }` object straight into the shared
/// domain [Bilingual].
///
/// ## Why not reuse `session/data/models/bilingual_model.dart`
///
/// Because **G-L3 forbids it**, and correctly. `BilingualModel` lives in the
/// session feature's `data/` layer, and Cross-Feature Isolation (SSD § 4.3)
/// lets one feature depend on another's `domain/` and never on its `data/`.
/// SSD § 15's P-11 states the invariant this preserves: *`Bilingual` remains
/// the only shared currency* — the **entity**, not the model. Importing the
/// model would weld the service catalogue's parsing to the session feature's
/// release cycle for the sake of eight lines.
///
/// A converter rather than a second `BilingualModel` because the duplicate
/// would exist only to be `.toEntity()`-ed one line later: there is no
/// service-specific wire shape here to model, just a two-key object that the
/// domain type already describes exactly.
///
/// ## Defensive reads, and why they are not laziness
///
/// A missing or non-string side becomes `''`, not a parse failure. Measured on
/// staging today every `{en,lo}` pair is complete, but § 5's warning is that
/// `/news` and `/help/faqs` return **plain strings** where sibling endpoints
/// return `{en,lo}` objects — a shape mismatch surfaces as an error state that
/// looks like a network problem. A half-populated pair renders one language
/// blank, which is visible and diagnosable; a thrown parse error takes the
/// whole 43-row page down over one bad field.
library;

import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../session/domain/entities/bilingual.dart';

class BilingualConverter
    implements JsonConverter<Bilingual, Map<String, dynamic>> {
  const BilingualConverter();

  @override
  Bilingual fromJson(Map<String, dynamic> json) => Bilingual(
        en: json['en'] is String ? json['en'] as String : '',
        lo: json['lo'] is String ? json['lo'] as String : '',
      );

  @override
  Map<String, dynamic> toJson(Bilingual value) =>
      <String, dynamic>{'en': value.en, 'lo': value.lo};
}
