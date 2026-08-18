/// `FamilyBookPage.tsx:40-63` — the ten module-level sentences the page needs
/// that **no `ns/*.ts` namespace owns**, as the transcription of record.
///
/// ```tsx
/// /* Short bilingual sentences for the three data states. The i18n namespaces
///  * are owned elsewhere, so these live here rather than as new dictionary
///  * keys. */
/// const COPY = {
///   loading: { en: "Loading your family book…", lo: "…" },
///   …
/// } as const;
/// ```
///
/// ## Why the bytes exist twice, and why that is the point
///
/// The widgets render these through `.tr(context: context)` out of
/// `assets/i18n/{en,lo}.json`, under this feature's own `familyBookPage` group
/// — that is what makes them repaint when the citizen flips the language toggle
/// (D-3 / G-L8). So the strings live once as JSON and once here.
///
/// `field_sentences.dart` is the precedent and it states the reason exactly:
///
/// > *"the Tier 1 oracle must draw them from the **component source** rather
/// > than from a namespace or they are silently absent from it"*
///
/// and
///
/// > *"Without them the JSON is a value nobody can diff against the source, and
/// > a typo in the Lao string is invisible to every reader who does not read
/// > Lao. With them, the assertion is mechanical."*
///
/// `test/features/family_book/domain/family_book_copy_test.dart` is that
/// assertion (`F4-AC-56`). It compares the JSON against these constants **and**
/// re-reads `FamilyBookPage.tsx` itself, so a matched pair of typos in the two
/// Dart-side copies still fails.
///
/// ## Why [FamilyBookSentence] and not `Bilingual`
///
/// `field_sentences.dart`'s reasoning, unchanged: `Bilingual` is a `freezed`
/// class whose constructor is not `const`, it lives in another feature, and
/// `ssd.md` § 4.4.2 already records it as a known-misplaced type. These ten
/// constants are a two-string transcription compared against JSON; they are
/// never passed to `i18n.dart`'s `text(Bilingual?, Lang)`. A local pair type
/// costs nothing and adds no call site to a type the architecture is already
/// trying to move.
///
/// ## Why they are not promoted into the `familyBook` group
///
/// They are not `ns/*.ts` entries. `F4-AC-52` asserts the `familyBook` group is
/// a 1:1 mirror of `i18n/ns/familyBook.ts` at exactly 83 keys; folding these
/// ten in would make it 93 and make the port of a source file differ from the
/// source file. F1 hit the same wall with its six `TXT` sentences (`F1-AC-76`)
/// and resolved it the same way.
library;

import 'package:flutter/foundation.dart';

/// An `en`/`lo` pair, local to this feature — deliberately not `Bilingual`.
@immutable
class FamilyBookSentence {
  const FamilyBookSentence({required this.en, required this.lo});

  final String en;
  final String lo;

  @override
  bool operator ==(Object other) =>
      other is FamilyBookSentence && other.en == en && other.lo == lo;

  @override
  int get hashCode => Object.hash(en, lo);

  @override
  String toString() => 'FamilyBookSentence(en: $en, lo: $lo)';
}

/// The i18n group these ten live in. **Not** `familyBook` — see the library
/// doc — and not `fields`, whose twelve keys are a verbatim port of
/// `i18n/ns/fields.ts` and which F4 adds nothing to (`F4-AC-58`).
const String kFamilyBookPageNamespace = 'familyBookPage';

/// `FamilyBookPage.tsx:41`.
const FamilyBookSentence kFbLoading = FamilyBookSentence(
  en: 'Loading your family book…',
  lo: 'ກຳລັງໂຫຼດປຶ້ມສຳມະໂນຄົວຂອງທ່ານ...',
);

/// `FamilyBookPage.tsx:42`.
const FamilyBookSentence kFbErrorTitle = FamilyBookSentence(
  en: 'We could not load your family book.',
  lo: 'ບໍ່ສາມາດໂຫຼດປຶ້ມສຳມະໂນຄົວໄດ້.',
);

/// `FamilyBookPage.tsx:43`.
const FamilyBookSentence kFbRetry =
    FamilyBookSentence(en: 'Try again', lo: 'ລອງໃໝ່');

/// `FamilyBookPage.tsx:44-47`.
const FamilyBookSentence kFbSignedOut = FamilyBookSentence(
  en: 'Sign in to see the household you belong to.',
  lo: 'ກະລຸນາເຂົ້າສູ່ລະບົບເພື່ອເບິ່ງຄົວເຮືອນຂອງທ່ານ.',
);

/// `FamilyBookPage.tsx:48`.
const FamilyBookSentence kFbEmptyTitle = FamilyBookSentence(
  en: 'No household on file',
  lo: 'ຍັງບໍ່ມີຄົວເຮືອນໃນລະບົບ',
);

/// `FamilyBookPage.tsx:49-52`. The sentence slot 47's baseline PNG shows, in
/// both locales — this page's one pairable Tier 3 reference.
const FamilyBookSentence kFbEmptyBody = FamilyBookSentence(
  en: 'Your name is not linked to a family book yet. Your village office can '
      'add you to one.',
  lo: 'ຊື່ຂອງທ່ານຍັງບໍ່ໄດ້ຜູກເຂົ້າກັບປຶ້ມສຳມະໂນຄົວ. '
      'ຫ້ອງການບ້ານຂອງທ່ານສາມາດເພີ່ມທ່ານເຂົ້າໄດ້.',
);

/// `FamilyBookPage.tsx:53-56`.
const FamilyBookSentence kFbNoMembers = FamilyBookSentence(
  en: 'No members are recorded in this household yet.',
  lo: 'ຍັງບໍ່ມີສະມາຊິກຖືກບັນທຶກໃນຄົວເຮືອນນີ້.',
);

/// `FamilyBookPage.tsx:57-60` — **and it is the whole request body.**
///
/// This is the one sentence on the page that reaches the wire:
/// `handleNext` calls `requestCopy.run(say("copyReason"))` (`:236`), which
/// becomes `{"reason": "<this string>"}` (`:204` → `endpoints.ts:128-129` →
/// `client.ts:242`). It is Tier 0's single leaf, per locale, and
/// `docs/fidelity-baseline/2026-08-13/oracle/tier0/family-book.request.{en,lo}.json`
/// carries these exact bytes.
///
/// **Read at submit time, not at mount** (§ 6.5 T0-2): `say()` closes over
/// `lang` from `useLang()` at `:193`, so flipping the language on the review
/// step and *then* submitting sends the new locale's bytes. A port that
/// captured the reason when the page opened would pass every locale test that
/// never flips.
const FamilyBookSentence kFbCopyReason = FamilyBookSentence(
  en: 'Copy requested from the citizen portal',
  lo: 'ຮ້ອງຂໍສຳເນົາຜ່ານແອັບຂອງພົນລະເມືອງ',
);

/// `FamilyBookPage.tsx:61`. The step-2 member card's status label — **not** the
/// `familyBook.statusLabel` the success card uses (`:361`). Two keys, two
/// sources, deliberately not merged.
const FamilyBookSentence kFbStatus =
    FamilyBookSentence(en: 'Status', lo: 'ສະຖານະ');

/// `FamilyBookPage.tsx:62`. Note the Lao side is **not** the acronym: the
/// English renders `UIN` and the Lao renders `ລະຫັດປະຈຳຕົວ`.
const FamilyBookSentence kFbUin =
    FamilyBookSentence(en: 'UIN', lo: 'ລະຫັດປະຈຳຕົວ');

/// Dotted key → the constant it must equal, for the assets check.
///
/// Insertion order is `COPY`'s own declaration order (`:41-62`), so the test's
/// failure output reads down the source rather than alphabetically.
const Map<String, FamilyBookSentence> kFamilyBookPageSentences =
    <String, FamilyBookSentence>{
  '$kFamilyBookPageNamespace.loading': kFbLoading,
  '$kFamilyBookPageNamespace.errorTitle': kFbErrorTitle,
  '$kFamilyBookPageNamespace.retry': kFbRetry,
  '$kFamilyBookPageNamespace.signedOut': kFbSignedOut,
  '$kFamilyBookPageNamespace.emptyTitle': kFbEmptyTitle,
  '$kFamilyBookPageNamespace.emptyBody': kFbEmptyBody,
  '$kFamilyBookPageNamespace.noMembers': kFbNoMembers,
  '$kFamilyBookPageNamespace.copyReason': kFbCopyReason,
  '$kFamilyBookPageNamespace.status': kFbStatus,
  '$kFamilyBookPageNamespace.uin': kFbUin,
};
