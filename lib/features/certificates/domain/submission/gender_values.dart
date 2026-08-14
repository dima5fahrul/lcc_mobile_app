/// The two gender **wire values**, and their order. D-S, narrowed.
///
/// ## What this owns, and the much larger thing it deliberately does not
///
/// `fsd.md` § 13.1 assigns D-S ("four independent gender-pair hardcodings")
/// to F0 as FIX(duplication). Measured, the four sites are **not the same
/// object**, and unifying their labels would be a Tier 1 failure in one
/// direction or the other (specs.md § 2.2 Finding J):
///
/// | Site | What it holds |
/// |---|---|
/// | `BirthDeclarationPage.tsx:134-137` | `{value, labelKey}` — an **i18n key** (`optFemale` / `optMale`) |
/// | `DeathDeclarationPage.tsx:140-143` | `{value, label: Bilingual}` — an **inline literal**, `Female`/`ຍິງ` |
/// | `MarriageCertificatePage.tsx:134-137` | `{value, label: string}` — a **bare English string, with no Lao label at all** |
/// | `FamilyBookPage.tsx:86` | `GENDER_KEY` — a four-key **reverse display map**, not an option list |
///
/// Giving Marriage a Lao rendering the web does not have, or taking Death's
/// away, are both divergences. **Labels stay per page.**
///
/// What *is* genuinely shared, and is Tier 0 rather than Tier 1, is the pair of
/// values and the order they appear in. That much is identical on all three
/// option lists and is what this file holds.
///
/// `fsd.md`'s FIX(duplication) is therefore **partially discharged and
/// partially refused, with the measurement as the reason** — recorded as FU-13
/// so `fsd.md`'s row is corrected rather than silently disobeyed.
library;

/// `['female', 'male']`, in that order.
///
/// The order is load-bearing: it is the order the options render in on all
/// three pages, and Tier 1 reads rendered order.
const List<String> kGenderWireValues = <String>['female', 'male'];

/// The three option lists this pair was read from. FamilyBook is absent
/// deliberately — `GENDER_KEY` is a display map keyed by four codes, so it is
/// not an inhabitant of this set.
const List<String> kGenderWireValuesSrc = <String>[
  'BirthDeclarationPage.tsx:134-137',
  'DeathDeclarationPage.tsx:140-143',
  'MarriageCertificatePage.tsx:134-137',
];
