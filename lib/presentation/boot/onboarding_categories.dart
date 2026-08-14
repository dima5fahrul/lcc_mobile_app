/// The six service tiles on splash slide 1 — `SplashScreens.tsx`:78's
/// `CATEGORIES.slice(0, 6)`.
///
/// ## Why this is a local const and not the API's category list (§ 6.9)
///
/// `SplashScreens.tsx`:15 imports `CATEGORIES` from `./ServicePage`, and
/// measured at the pin, `ServicePage.tsx`:144-153's `CATEGORIES` is a
/// **hardcoded const array of eight** — not API data. Its own doc comment says
/// so: *"The static tables below are no longer what this page renders — the
/// catalogue comes from `/service-categories` and `/services`. They stay
/// exported because the home page still reads them."*
///
/// The **Flutter** `ServicePage` has no such const to import: it draws its
/// categories from `/service-categories`. Reusing that list here would be a
/// divergence in both directions —
///
/// * the splash would issue a network request the web's splash does not
///   (`App.tsx`:195-222 mounts no page during boot), and
/// * a slow or failed catalogue call would render an **empty** first slide,
///   where the web's copy is fixed and no network condition can empty it.
///
/// So the first six rows are transcribed here, once, as compile-time copy.
///
/// ## The labels are a `Bilingual`, rendered by `text()` — RULING 13
///
/// **This file used to hold a hand-written ternary over a bare `labelEn` /
/// `labelLo` pair. That is undone here, and the history is worth keeping
/// because the guard that caused it is the thing that was wrong.**
///
/// § 4.4 of `ssd.md` (`:329-330`) permits `lib/presentation/**` →
/// `features/*/domain/**`, so this file may import
/// `features/session/domain/entities/bilingual.dart` and render through the
/// frozen `text(Bilingual?, Lang)` at `lib/i18n/i18n.dart`:90. B10 wrote it
/// that way first, then measured that the import turned B9a's `B9-AC-10` red —
/// at v1.0 that criterion scanned all of `lib/presentation/` for any
/// `features/` substring in any import URI, `domain/` included. B10 reported
/// the disagreement rather than resolving it unilaterally and shipped the
/// ternary plus a duplicated copy pair in the meantime, leaving a note that it
/// *"should become `text(...)`"* if the guard were ever narrowed.
///
/// `ssd.md` § 4.4.1 (RULING 13) narrowed it: `B9-AC-10` is re-scoped to
/// `lib/presentation/shell/`, on the ground that a batch may narrow the SSD for
/// itself but B9 implemented its narrowing as a permanent global scan binding
/// F0, B10 and F1–F4. In the ruling's words, *a guard that manufactures the
/// duplication it exists to prevent is inverted*. So the note is discharged:
/// the pair is a `Bilingual`, the selection is `text()`, and there is one
/// renderer in this application rather than two.
///
/// **This is a de-duplication, not a behaviour change.** `text()`'s fallback
/// chain (`value == null → ""`, then `wanted → en → lo → ""`) cannot branch
/// differently from the old ternary here: all twelve strings below are
/// compile-time constants and non-empty, so `wanted.isNotEmpty` returns on the
/// first check in every case. Both locales render byte-identically to what
/// they rendered before — asserted by `splash_screens_test.dart`'s
/// `B10-AC-40`, which pumps slide 1 in `en` and in `lo`.
///
/// The edge this file now uses is still not the one G-L7 forbids: G-L7 covers
/// `lib/presentation/**` → `features/*/presentation/**`, `B10-AC-13` asserts
/// it again for `boot/` specifically, and both stay green. Nothing here weakens
/// either.
///
/// **Open follow-up, not this file's to fix.** `ssd.md` § 4.4.2 rules
/// `Bilingual` *misplaced*: it has ten consumer houses plus `lib/i18n/i18n.dart`
/// itself, and a mechanism depending on a feature makes `features/session` a
/// de-facto shared kernel. Its correct home is `lib/i18n/bilingual.dart`, beside
/// its renderer. That is a 34-file import rewrite in no batch's § 3.1 and is
/// registered as a follow-up; when it lands, the import below moves with it.
library;

import 'package:flutter/widgets.dart';

import '../../features/session/domain/entities/bilingual.dart';
import '../../i18n/i18n.dart';
import '../theme/app_colors.dart';

/// One tile: the label pair, the lucide glyph name, and the accent colour the
/// `GlassIcon` tints itself with.
///
/// [iconName] is a **bundled** lucide name, passed straight to `LucideIcon`
/// rather than through `AppIcons.service`. That resolver exists to reproduce
/// the web's *API-name → glyph* fallback (`ServicePage.tsx`:112-114); these six
/// names are not API data, they are the source's own `icon:` components, so
/// routing them through a fallback that can silently substitute `FileText`
/// would add a failure mode the source does not have.
@immutable
class OnboardingCategory {
  const OnboardingCategory({
    required this.id,
    required this.label,
    required this.iconName,
    required this.color,
  });

  /// `cat.id` — the React `key`, kept so a test can name a tile.
  final String id;

  /// `cat.label` / `cat.labelLo` — `ServicePage.tsx`:144-153, as the one pair
  /// type this application has rather than as two loose `String`s.
  final Bilingual label;

  /// `lang === "lo" ? cat.labelLo : cat.label` — `SplashScreens.tsx`:82,
  /// through the application's single renderer.
  String labelFor(Lang lang) => text(label, lang);

  /// Read-through accessors, kept because `splash_screens_test.dart`:349,357,
  /// 368-369 reads them and that file is outside this change's scope. They
  /// store nothing and are not a second copy of the copy — [label] is the only
  /// storage. They should go when that test is next touched.
  String get labelEn => label.en;
  String get labelLo => label.lo;

  final String iconName;

  /// `cat.color`. Each is already a theme token from B2a's category table —
  /// no new colour literal, and `B10-AC-14` asserts this file holds none.
  final Color color;
}

/// `ServicePage.tsx`:144-153, rows 1-6, in the source's declaration order.
///
/// The slice is **6 of 8**: `education` and `health` are the two the splash
/// drops (`SplashScreens.tsx`:78). They are not transcribed here at all —
/// carrying eight and slicing six in the widget would put two unreachable rows
/// in the tree for no gain.
const List<OnboardingCategory> kOnboardingCategories = <OnboardingCategory>[
  OnboardingCategory(
    id: 'civil',
    label: Bilingual(en: 'Civil & Population', lo: 'ພົນລະເມືອງ ແລະ ການທະບຽນ'),
    iconName: 'Users',
    color: AppColors.categoryAccentCivil,
  ),
  OnboardingCategory(
    id: 'immigration',
    label: Bilingual(en: 'Immigration', lo: 'ກວດຄົນເຂົ້າ-ອອກເມືອງ'),
    iconName: 'Plane',
    color: AppColors.categoryAccentImmigration,
  ),
  OnboardingCategory(
    id: 'finance',
    label: Bilingual(en: 'Tax & Payment', lo: 'ອາກອນ ແລະ ການຊຳລະ'),
    iconName: 'Wallet',
    color: AppColors.categoryAccentFinance,
  ),
  OnboardingCategory(
    id: 'housing',
    label: Bilingual(en: 'Land & Property', lo: 'ທີ່ດິນ ແລະ ຊັບສິນ'),
    iconName: 'Building2',
    color: AppColors.categoryAccentHousing,
  ),
  OnboardingCategory(
    id: 'transport',
    label: Bilingual(en: 'Transport', lo: 'ການຂົນສົ່ງ'),
    iconName: 'Bus',
    color: AppColors.categoryAccentTransport,
  ),
  OnboardingCategory(
    id: 'welfare',
    label: Bilingual(en: 'Social Protection', lo: 'ການປົກປ້ອງທາງສັງຄົມ'),
    iconName: 'HandHeart',
    color: AppColors.categoryAccentWelfare,
  ),
];
