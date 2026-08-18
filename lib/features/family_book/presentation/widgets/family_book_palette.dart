/// The four Tailwind classes FamilyBook uses that no correctly-named token in
/// `presentation/theme/` carries — aliased here, with the misfit written down.
///
/// `history_palette.dart` is the precedent for a feature-local palette file.
/// This one exists for a narrower reason: `ssd.md` § 10.1 forbids a raw colour
/// literal outside `presentation/theme/` (`F4-AC-17`), and `specs.md` § 4.1
/// puts `presentation/theme/**` out of F4's scope — so a class whose exact
/// value exists in the theme only under an unrelated name has to be reached
/// through that name. Doing it once, here, with the reason attached, is better
/// than four call sites importing `categoryTintEducation` for a family book.
///
/// **Three of the four are value-exact; one is not, and that one is a recorded
/// Tier 2 divergence** (`F4-AC-67`). None is resolved by adding a token, which
/// F4 may not do.
library;

import 'package:flutter/painting.dart';

import '../../../../presentation/theme/app_colors.dart';

/// `bg-blue-50` — `FamilyBookPage.tsx:426`, the date-of-issue strip's fill.
///
/// **THE ONE INEXACT VALUE. Tier 2 divergence F4-DIV-1.** Tailwind's `blue-50`
/// is `#EFF6FF` and **no token in `presentation/theme/` carries it**: the
/// nearest is [AppColors.primarySoft] (`#EEF2FF`), which is `indigo-50` — the
/// same family the page's `#344EAD` accent comes from, one step across the hue.
/// Measured difference: R −1, G −4, B 0 out of 255.
///
/// Adding a `blue50` token is the correct resolution and it is **out of F4's
/// scope** (§ 4.1). Recorded rather than silently resolved, and rather than
/// written as an inline literal, which would trip both `F4-AC-17` and the
/// repo-wide colour-literal guard.
const Color kFbBlue50 = AppColors.primarySoft;

/// `border-blue-100` — `:426`, that strip's outline. `#DBEAFE`, **exact**.
///
/// The only token carrying it is [AppColors.categoryTintEducation], named for
/// the service catalogue's education tile. The name is wrong here and the
/// number is right, and `field_base.dart`'s note settles which of those
/// matters: a wrong value is invisible in review and visible to Tier 2.
const Color kFbBlue100 = AppColors.categoryTintEducation;

/// `border-amber-100` — `:507`, the review notice's outline. `#FEF3C7`,
/// **exact**.
///
/// Not [AppColors.warningTint] (`#FEF3C6`), which `app_colors.dart` documents
/// as Tailwind **v4**'s `amber-100` measured off the home banner. The `forms`
/// group of `oracle/tier2/tokens.json` records v3 numbers for the class names
/// this page shares with the kernel (`text-red-500` `#EF4444`,
/// `text-gray-500` `#6B7280`), so v3 is the build these class names resolve
/// against and `#FEF3C7` is the value. One step apart, from two measurements,
/// and `warningTint`'s own doc warns against collapsing the two.
const Color kFbAmber100 = AppColors.tutorialBadgeBgAmber;

/// `border-red-100` — `:515`, the failed-request strip's outline. `#FEE2E2`,
/// **exact**.
///
/// Not [AppColors.dangerOutlineSoft] (`#FFE2E2`), which is v4's `red-100`; see
/// [kFbAmber100] for why this page reads against v3.
const Color kFbRed100 = AppColors.tutorialBadgeBgRed;

/// `text-[10px]` — `FamilyBookPage.tsx:404`, `:430`, `:470`, the three pill
/// badges.
///
/// **Tier 2 divergence F4-DIV-5, and it is a gap rather than a mismatch.**
/// `AppTypography`'s scale runs 11, 12, 13, 14, 15, 16, 18, 20, 24, 30 — there
/// is no `size10`, because no surface before this one used an arbitrary-value
/// type class. Adding one means editing `presentation/theme/`, which § 4.1 puts
/// outside F4's scope.
///
/// Written as a named constant rather than a bare `10` at three call sites for
/// `field_base.dart`'s reason: a value written three times is three chances to
/// write it differently, and this one has no token to check it against.
const double kFbSize10 = 10;
