/// `formFields.tsx:29-38` — the three sentences the shared fields need that
/// **no page dictionary owns**.
///
/// ```ts
/// /* Sentences the shared fields need that no page dictionary owns. */
/// const LOAD_FAILED: Bilingual = { en: "Could not load this list.", lo: "…" };
/// const RETRY: Bilingual = { en: "Retry", lo: "ລອງໃໝ່" };
/// const NOTHING_YET: Bilingual = { en: "Nothing to choose from here yet.", lo: "…" };
/// ```
///
/// They are module-level `Bilingual` literals, not `ns/*.ts` entries, which is
/// why the Tier 1 oracle must draw them from the **component source** rather
/// than from a namespace or they are silently absent from it (specs.md § 6.11).
///
/// ## Why they exist twice, and why that is not a duplication defect
///
/// The widgets render them through `.tr(context: context)` out of
/// `assets/i18n/{en,lo}.json`, under the kernel-owned `formFields` group —
/// that is what makes them translatable and what makes them repaint when the
/// citizen flips the language toggle (D-3 / G-L8).
///
/// The [FormSentence] constants below are the **transcription of record**: the
/// literal bytes read from `formFields.tsx:30-38`, which the JSON is checked
/// against by
/// `test/presentation/forms/field_sentences_test.dart`. Without them the JSON
/// is a value nobody can diff against the source, and a typo in the Lao string
/// is invisible to every reader who does not read Lao. With them, the assertion
/// is mechanical.
///
/// ## Why [FormSentence] and not `Bilingual`
///
/// The obvious type is `Bilingual`, and an earlier draft used it. It lives at
/// `features/session/domain/entities/bilingual.dart`, and importing it from
/// here trips **B9-AC-10** (`test/presentation/shell/app_shell_seam_test.dart`)
/// — *"zero import directives under `lib/presentation` name a feature"*.
///
/// Nothing requires `Bilingual` here. These three constants are a two-string
/// transcription compared against JSON; they are never passed to
/// `i18n.dart`'s `text(Bilingual?, Lang)`, because the widgets render these
/// sentences through `.tr(context: context)` rather than through a `Bilingual`
/// (see above). A local pair type therefore costs nothing and removes a
/// feature-naming import that was incidental rather than required.
///
/// This is **not** the same question as `reference_field_state.dart`'s import
/// of `features/reference/domain/`, which `F0-AC-9`'s positive clause
/// *requires* and `ssd.md`:838-840 permits by name. That one cannot be removed
/// and is escalated rather than worked around.
library;

import 'package:flutter/foundation.dart';

/// An `en`/`lo` pair, local to the kernel — deliberately not `Bilingual`.
@immutable
class FormSentence {
  const FormSentence({required this.en, required this.lo});

  final String en;
  final String lo;

  @override
  bool operator ==(Object other) =>
      other is FormSentence && other.en == en && other.lo == lo;

  @override
  int get hashCode => Object.hash(en, lo);

  @override
  String toString() => 'FormSentence(en: $en, lo: $lo)';
}

/// `formFields.tsx:30-33`.
const FormSentence kLoadFailed = FormSentence(
  en: 'Could not load this list.',
  lo: 'ບໍ່ສາມາດໂຫຼດລາຍການນີ້ໄດ້.',
);

/// `formFields.tsx:34`.
const FormSentence kRetry = FormSentence(en: 'Retry', lo: 'ລອງໃໝ່');

/// `formFields.tsx:35-38`.
const FormSentence kNothingYet = FormSentence(
  en: 'Nothing to choose from here yet.',
  lo: 'ຍັງບໍ່ມີໃຫ້ເລືອກເທື່ອ.',
);

/// The kernel-owned i18n group. Not `fields` — that namespace is a verbatim
/// port of `i18n/ns/fields.ts` and its key set is fixed at twelve
/// (`F0-AC-63`); appending to it would make the port of a source file differ
/// from the source file.
const String kFormFieldsNamespace = 'formFields';

const String kLoadFailedKey = '$kFormFieldsNamespace.loadFailed';
const String kRetryKey = '$kFormFieldsNamespace.retry';
const String kNothingYetKey = '$kFormFieldsNamespace.nothingYet';

/// Key → the constant it must equal, for the assets check.
const Map<String, FormSentence> kFormFieldSentences = <String, FormSentence>{
  kLoadFailedKey: kLoadFailed,
  kRetryKey: kRetry,
  kNothingYetKey: kNothingYet,
};
