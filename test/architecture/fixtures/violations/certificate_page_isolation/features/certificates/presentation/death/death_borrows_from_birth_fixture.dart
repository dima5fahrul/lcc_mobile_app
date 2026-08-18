// certificate_page_isolation fixture — THE VIOLATION. A file under
// `features/certificates/presentation/death/` importing
// `features/certificates/presentation/birth/`.
//
// `specs.md` § 6.2 RULING 1: no symbol — function, widget, class, constant,
// extension or mixin — may be shared between the sibling certificate pages, and
// neither directory may import the other.
//
// The offender borrows `birthParentData` specifically, because that is the real
// shape of the mistake and the one § 6.2 names first: Death's `parentData`
// differs from Birth's by one parameter and one key, so reusing Birth's and
// "just adding workplace" saves eighty lines and looks like good engineering.
// It is byte-correct on every fixture that exists today — the mother is one
// object and no fixture distinguishes the two prefixes — and wrong on the first
// divergent input. `specs.md` § 11 item 1 tells the human reviewer to check
// this before anything else; this guard is what makes it not depend on them
// remembering.
//
// It trips certificate_page_isolation and nothing else, by construction:
//   * G-L1 wants a `data/` target — this one is `presentation/`.
//   * G-L2 wants the importer under `domain/`.
//   * G-L3 is satisfied: importer and target are the SAME feature
//     (`certificates`), which is exactly why no pre-existing guard can see
//     this edge and why F2 had to add one.
//   * G-L4 wants the importer under `core/`.
//   * G-L5 wants a `di/` import or a locator identifier — neither is here.
//   * G-L6 wants `data/` or `core/`.
//   * G-L7 wants the importer under `lib/presentation/**`; this is under
//     `features/`.
//   * G-L8 wants a `.tr(` call.
import '../birth/birth_payload_fixture.dart';

const String fixtureBorrowed = fixtureBirthParentDataName;
