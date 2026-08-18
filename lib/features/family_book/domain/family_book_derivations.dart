/// **The derivable core — `specs.md` § 6.6's P-1 … P-8, and F4's real fidelity
/// claim.**
///
/// Everything the content region renders that is *not* a raw server field is
/// one of these eight. They are transcribed from `FamilyBookPage.tsx`, take
/// plain inputs, and need neither a widget tree nor a server to run.
///
/// ## Why that matters more here than it would on another page
///
/// `specs.md` § 6.4 partitions FamilyBook's fidelity instrument by state. Four
/// of the eight render states are Tier-1-gated; the other four — success,
/// step 1, step 2, step 3 — render `book.head_name`, `m.uin`,
/// `submitted.reference_no` and the rest, which are **raw server fields with no
/// oracle anywhere in this repository** (`F4-NV-2`). A widget test that renders
/// those four from a household we invented asserts *structure* and, per the
/// Capability Rule, would pass with the wrong values.
///
/// So the fidelity claim for those four states is relocated **here**, to the
/// part of the content region that does have an oracle: the source text itself.
/// That relocation is the design, and it is why these functions live in
/// `domain/` as pure functions rather than inside the widgets that call them.
/// Putting them under `presentation/widgets/` would additionally drop them into
/// GOR-246 AC-5's coverage exclusion set — `home_formatting.dart:1-9`'s
/// argument, and it applies with more force to a page whose populated surfaces
/// cannot be measured at all.
///
/// ## P-7 is imported, not re-implemented
///
/// `formatLak` is `serviceConfig.ts:38-43` and it is **already ported**, at
/// `features/home/domain/home_formatting.dart:50-55`, with the `en-US` grouping
/// pin already documented there. B6's `specs.md` § 6.6 ruled on exactly this
/// question when the wallet needed it — *"Copying would be two `formatLak`s
/// that drift"* — and took the import over both copying and relocating, with
/// FU-9 filing the relocation. A third copy in this tree would be the drift
/// that ruling refused.
///
/// F4's `specs.md` § 6.6 lists P-7 as a function F4 writes, which is a measured
/// gap in the spec rather than a licence to duplicate: the architect's
/// verification basis (§ 10) lists `serviceConfig.ts` but not
/// `home_formatting.dart`. The import is a CFI-legal `features/A →
/// features/B/domain/**` edge (G-L3) and is reported against `F4-AC-14`, whose
/// enumeration names only `application/domain`.
library;

import 'entities/family_book.dart';
import 'entities/household_member.dart';

export '../../home/domain/home_formatting.dart' show formatLak;

/// The i18n namespace these labels resolve in — `useT("familyBook")`, `:182`.
const String kFamilyBookNamespace = 'familyBook';

/// **P-2 — `RELATION_KEY`, `FamilyBookPage.tsx:77-85`.**
///
/// **NINETEEN spellings onto EIGHT labels, not twenty.** `specs.md` § 6.6 and
/// `F4-AC-44` both say twenty; the pinned source has nineteen, enumerated
/// below and counted by
/// `test/features/family_book/domain/family_book_derivations_test.dart`
/// against the `.ts` itself rather than against this transcription. The
/// correction is recorded in `qa-report.md`; a twentieth entry invented to
/// satisfy the count would be a key the web does not have.
///
/// Two of the nineteen carry a **space** — `head of household` and `household
/// head` — which is what makes the `trim().toLowerCase()` normalisation in
/// [labelOf] behavioural rather than cosmetic.
const Map<String, String> kRelationKey = <String, String>{
  'head': 'relHead',
  'head of household': 'relHead',
  'household head': 'relHead',
  'spouse': 'relSpouse',
  'wife': 'relSpouse',
  'husband': 'relSpouse',
  'child': 'relChild',
  'son': 'relChild',
  'daughter': 'relChild',
  'parent': 'relParent',
  'father': 'relParent',
  'mother': 'relParent',
  'sibling': 'relSibling',
  'brother': 'relSibling',
  'sister': 'relSibling',
  'grandparent': 'relGrandparent',
  'grandchild': 'relGrandchild',
  'relative': 'relOther',
  'other': 'relOther',
};

/// **P-3 — `GENDER_KEY`, `FamilyBookPage.tsx:86-89`.** Four spellings, two
/// labels. `m` and `f` are single letters and are real registry values.
const Map<String, String> kGenderKey = <String, String>{
  'male': 'genderMale',
  'm': 'genderMale',
  'female': 'genderFemale',
  'f': 'genderFemale',
};

/// The em dash the source uses as its own "nothing here" sentinel — `:110`,
/// `:209`, `:221`, `:471`, `:495`, `:524-529`, `:558`, `:560`.
///
/// U+2014, named once so nine call sites cannot disagree about which dash it
/// is, and so a Tier 1 byte comparison has something to compare against.
const String kEmDash = '—';

/// Resolves one `familyBook.<key>` translation. The caller supplies it, so
/// nothing here reaches for a `BuildContext` or a global.
typedef FamilyBookTranslate = String Function(String key);

/// **P-1 — `labelOf`, `FamilyBookPage.tsx:207-210`.**
///
/// ```tsx
/// const labelOf = (map, value) => {
///   const key = map[(value ?? "").trim().toLowerCase()];
///   return key ? t(key) : value || "—";
/// };
/// ```
///
/// Three behaviours a port gets wrong by default, all asserted at `F4-AC-46`:
///
/// 1. **A miss returns the RAW value, not a placeholder and not `"Other"`.**
///    `labelOf(kRelationKey, 'cousin')` is `'cousin'`. That is `ssd.md` L-4's
///    rule and L-10's *"where the web degrades, the port degrades to the same
///    visible result"* — the citizen sees the registry's own spelling.
/// 2. **Only a FALSY value becomes [kEmDash].** `value || "—"` in JavaScript is
///    false for `""` and true for `"   "`, so a whitespace-only registry value
///    renders as itself. The lookup trims; the fallback does not.
/// 3. **The miss returns the value as given**, untrimmed and un-lowercased —
///    normalisation happens on the lookup key only.
String labelOf(
  Map<String, String> map,
  String value,
  FamilyBookTranslate translate,
) {
  final String? key = map[value.trim().toLowerCase()];
  if (key != null) return translate(key);
  return value.isEmpty ? kEmDash : value;
}

/// **P-4 — `isHeadRelation`, `FamilyBookPage.tsx:91-92`.**
///
/// ```tsx
/// const isHeadRelation = (relation: string) =>
///   RELATION_KEY[relation.trim().toLowerCase()] === "relHead";
/// ```
///
/// Drives the Crown glyph against the `#n` badge at `:461-465`. **Three**
/// spellings satisfy it, not one.
bool isHeadRelation(String relation) =>
    kRelationKey[relation.trim().toLowerCase()] == 'relHead';

/// `book?.members ?? []` — `FamilyBookPage.tsx:212`.
List<HouseholdMember> membersOf(FamilyBook? book) =>
    book?.members ?? const <HouseholdMember>[];

/// **P-5 (i) — `total`, `FamilyBookPage.tsx:213`.**
///
/// ```tsx
/// const total = book?.total_members ?? members.length;
/// ```
///
/// **`??`, not `||`.** A server `total_members` of `0` alongside three members
/// in the list renders **`0`** — the array is counted only when the server said
/// nothing at all. `F4-AC-45`.
int totalMembersOf(FamilyBook? book) =>
    book?.totalMembers ?? membersOf(book).length;

/// **P-5 (ii) — `men`, `FamilyBookPage.tsx:214`.**
///
/// ```tsx
/// const men = book?.male_members ??
///   members.filter((m) => m.gender?.toLowerCase().startsWith("m")).length;
/// ```
///
/// The predicate is `startsWith("m")` on the lowercased value, so `"Male"`,
/// `"M"` and `"m"` all count — **and so would `"married"`**. That is the
/// source's own looseness and this port keeps it; tightening it to an exact
/// match against [kGenderKey] would be a different count on the same data.
int menCountOf(FamilyBook? book) =>
    book?.maleMembers ??
    membersOf(book)
        .where((HouseholdMember m) =>
            (m.gender ?? '').toLowerCase().startsWith('m'))
        .length;

/// **P-5 (iii) — `women`, `FamilyBookPage.tsx:215`.** Same shape, `"f"`.
int womenCountOf(FamilyBook? book) =>
    book?.femaleMembers ??
    membersOf(book)
        .where((HouseholdMember m) =>
            (m.gender ?? '').toLowerCase().startsWith('f'))
        .length;

/// **P-6 — `addressLine`, `FamilyBookPage.tsx:218-221`.**
///
/// ```tsx
/// const addressLine =
///   [place?.village_name, place?.district_name, place?.province_name]
///     .filter(Boolean).join(", ") || book?.address || "—";
/// ```
///
/// Two traps, both asserted at `F4-AC-47`:
///
/// * **Village first, province last** — the *reverse* of the step-1 field order
///   at `:420-424`, which reads province, district, village. One page, two
///   orders, both deliberate.
/// * **`||`, not `??`.** An all-empty jurisdiction joins to `""`, which is
///   falsy, so it falls through to `address` and then to [kEmDash]. A `??`
///   chain would stop at the empty string and render a blank line.
///
/// The separator is `", "` — a comma and a space, not the `" · "` of
/// [memberSubLine] and not `Jurisdiction.officeLine`'s. Three joins on one
/// screen with three different separators is exactly the kind of thing that
/// silently converges, which is why this is a named function and not a `.join`
/// inside a widget body.
String addressLineOf(FamilyBook? book) {
  final List<String> parts = <String>[
    for (final String? part in <String?>[
      book?.jurisdiction?.villageName,
      book?.jurisdiction?.districtName,
      book?.jurisdiction?.provinceName,
    ])
      if (part != null && part.isNotEmpty) part,
  ];
  final String joined = parts.join(', ');
  if (joined.isNotEmpty) return joined;
  final String? address = book?.address;
  if (address != null && address.isNotEmpty) return address;
  return kEmDash;
}

/// **P-8 — the step-3 member sub-line, `FamilyBookPage.tsx:553-558`.**
///
/// ```tsx
/// [ m.relation && labelOf(RELATION_KEY, m.relation),
///   m.gender   && labelOf(GENDER_KEY,   m.gender),
///   m.date_of_birth,
///   m.uin,
/// ].filter(Boolean).join(" · ") || "—"
/// ```
///
/// **It disagrees with [labelOf] about blanks, on purpose.** The `&&`
/// short-circuits *before* the call, so a blank `relation` contributes
/// **nothing** here and the neighbours close up — whereas the same blank
/// relation in the step-2 `ReadField` (`:487`, straight through [labelOf])
/// renders [kEmDash]. Normalising the two is an L-10 failure in whichever
/// direction it is normalised, and `F4-AC-48` asserts both in one test.
///
/// The separator is `" · "` — U+00B7 with a space either side. The four-element
/// order is fixed: relation, gender, date of birth, UIN.
String memberSubLine(
  HouseholdMember member,
  FamilyBookTranslate translate,
) {
  final List<String> parts = <String>[];

  final String relation = member.relation ?? '';
  if (relation.isNotEmpty) {
    parts.add(labelOf(kRelationKey, relation, translate));
  }
  final String gender = member.gender ?? '';
  if (gender.isNotEmpty) {
    parts.add(labelOf(kGenderKey, gender, translate));
  }
  final String dateOfBirth = member.dateOfBirth ?? '';
  if (dateOfBirth.isNotEmpty) parts.add(dateOfBirth);
  final String uin = member.uin ?? '';
  if (uin.isNotEmpty) parts.add(uin);

  return parts.isEmpty ? kEmDash : parts.join(' · ');
}

/// `value || "—"` — `ReadField`'s own fallback at `:110`, and the same
/// expression at `:402`, `:471`, `:495` and `:524-527`.
///
/// Named because it is the single most repeated expression on the page and
/// because `??` is the wrong translation of it: `??` keeps an empty string and
/// `||` does not.
String orDash(String? value) =>
    (value == null || value.isEmpty) ? kEmDash : value;
