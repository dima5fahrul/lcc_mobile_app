/// `formFields.tsx:242-275`'s `ReferenceOptions` and the **non-fetching half**
/// of `useReferenceOptions` — RULING 8, § 6.3.7 rows 8 and 11.
///
/// ## Renamed, and split
///
/// The source's `ReferenceOptions` is `{options, loading, failed, retry,
/// labelOf}` — a UI view-model with no wire knowledge, which is why it stays in
/// the kernel. It is renamed [ReferenceFieldState] so nothing reads it as the
/// **hook** it is named after.
///
/// `useReferenceOptions` itself cannot travel: it performs the fetch and owns
/// `loading`/`failed`/`retry`, and `ssd.md` § 7.2 rules that state *"**Never**
/// for anything a network call produced"* inside a `presentation/` widget. It
/// splits:
///
/// * the **mapping** half — `value = code`, `label = text(label, lang)`,
///   `sub = lang == "lo" ? en : lo`, and `labelOf`'s raw-code fallback —
///   becomes the pure [referenceFieldStateFrom] below, testable with no network
///   and assertable by Tier 1;
/// * the **fetching** half is the page BLoC's, which F1 builds (`ssd.md` § 7.4).
///
/// `ReferenceSelect` (`:343-357`) is **not ported as a self-fetching widget**
/// for the same reason: its whole body is
/// `const source = useReferenceOptions(type); return <ReferenceSelectView source={source} …/>`,
/// and in Dart that composition happens where the state lives. Its analogue is
/// `ReferenceSelectView` fed from BLoC state. Recorded as a deliberate
/// structural divergence; no tier can observe it, because Tier 1 reads
/// reachable strings and every string is identical under the split.
///
/// ## This file is the CFI edge, and it is supposed to be
///
/// It imports `features/reference/domain/**` and nothing else from `features/`.
/// `ssd.md`:838-840 permits exactly that, and `F0-AC-9`'s **positive** clause
/// requires it: a kernel that imported nothing from the reference layer at all
/// would pass a negative-only CFI check while never having been wired up.
library;

import 'package:flutter/foundation.dart';

import '../../../features/reference/domain/entities/lookup_option.dart';
import '../../../i18n/i18n.dart';
import 'option.dart';

@immutable
class ReferenceFieldState {
  const ReferenceFieldState({
    this.options = const <Option>[],
    this.loading = false,
    this.failed = false,
    this.retry,
  });

  final List<Option> options;
  final bool loading;
  final bool failed;

  /// Refetch. Null when the caller does not model retry — which is what
  /// produces Marriage's and Divorce's weaker surface, by omission.
  final VoidCallback? retry;

  /// `formFields.tsx:269-272` — the label for a stored code, **falling back to
  /// the raw code** so a review screen reading a value back before the list has
  /// loaded prints the code rather than an empty cell (L-4).
  String labelOf(String code) {
    for (final Option o in options) {
      if (o.value == code) return o.label;
    }
    return code;
  }

  ReferenceFieldState copyWith({
    List<Option>? options,
    bool? loading,
    bool? failed,
    VoidCallback? retry,
  }) =>
      ReferenceFieldState(
        options: options ?? this.options,
        loading: loading ?? this.loading,
        failed: failed ?? this.failed,
        retry: retry ?? this.retry,
      );
}

/// `formFields.tsx:259-267` — the pure mapping, `LookupOption` → [Option].
///
/// `sub` is the **other** language's side, so a Lao reader sees the English
/// name underneath and an English reader sees the Lao one. `SearchableSelect`
/// then hides it when it repeats the primary (`:207`), which is what happens
/// for a place whose two names are the same string.
ReferenceFieldState referenceFieldStateFrom(
  List<LookupOption> rows, {
  required Lang lang,
  bool loading = false,
  bool failed = false,
  VoidCallback? retry,
}) {
  return ReferenceFieldState(
    options: <Option>[
      // Server order, no re-sort (L-3); no `active` filter (L-4). The
      // iteration order IS the wire order and nothing here changes it.
      for (final LookupOption row in rows)
        Option(
          value: row.code,
          label: text(row.label, lang),
          sub: lang == Lang.lo ? row.label.en : row.label.lo,
        ),
    ],
    loading: loading,
    failed: failed,
    retry: retry,
  );
}
