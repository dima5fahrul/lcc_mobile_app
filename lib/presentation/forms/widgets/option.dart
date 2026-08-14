/// `formFields.tsx:98-102` — one choice in a select.
///
/// ```ts
/// export interface Option { value: string; label: string; sub?: string; }
/// ```
///
/// A **view** value type: already resolved to one language. The bilingual pair
/// it was resolved from lives in `features/reference/domain`'s `LookupOption`,
/// and `referenceFieldStateFrom` is the one place that crosses between them.
library;

class Option {
  const Option({required this.value, required this.label, this.sub});

  /// The code that goes on the wire.
  final String value;

  /// What the citizen reads, in the language they are reading.
  final String label;

  /// Secondary text — the *other* language's name. `formFields.tsx:264`
  /// `sub: lang === "lo" ? item.label.en : item.label.lo`.
  final String? sub;

  @override
  bool operator ==(Object other) =>
      other is Option &&
      other.value == value &&
      other.label == label &&
      other.sub == sub;

  @override
  int get hashCode => Object.hash(value, label, sub);

  @override
  String toString() => 'Option($value, $label, $sub)';
}
