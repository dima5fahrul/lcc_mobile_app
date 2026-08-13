/// The blurb and tint the API does **not** publish for a category.
///
/// `ServicePage.tsx:316` states the split in one line: *"The API publishes a
/// name, icon and colour; the blurb and tint stay local."* `/service-categories`
/// returns `{id, code, name, icon, color, sort_order, active}` — no
/// description, no background — so the eight two-line blurbs and the eight pale
/// tints come from the static `CATEGORIES` table (`ServicePage.tsx:144-153`),
/// matched on `code`.
///
/// ## Why this is copy and not data
///
/// It lives here, in `presentation/`, rather than on the `ServiceCategory`
/// entity, because putting it on the entity would say the server owns it. The
/// server does not: change a blurb and you ship an app release. That is the
/// definition of copy.
///
/// ## Why the tints are not `AppColors` tokens
///
/// `bg` is the fallback background for a category tile and it belongs to the
/// same eight-row table as the blurb — the source keeps `color` and `bg`
/// adjacent for exactly that reason. `app_colors.dart`'s rule is that
/// **runtime-supplied** colours are data and must not be transcribed; these
/// eight are the opposite case, compile-time copy the API never sends. They
/// would still be raw literals in a `presentation/` file, which B2-AC-11
/// forbids, so they are named tokens in `AppColors.categoryTints` and looked up
/// here by code.
///
/// ## The fallbacks, and when they fire
///
/// `ServicePage.tsx:322-326`:
/// ```ts
/// desc: seed?.desc ?? "",
/// color: c.color || seed?.color || "#344EAD",
/// bg:   seed?.bg ?? "#F3F4F6",
/// ```
/// A category the API adds that this table does not know gets an empty blurb, a
/// neutral tint and — since the API always sends a colour — its own accent. It
/// renders; it just reads plainer. All eight of today's codes are present.
library;

import 'dart:ui' show Color;

import '../../../../presentation/theme/app_colors.dart';

/// One category's local copy: the blurb in both languages, and the tint.
class CategorySeed {
  const CategorySeed({
    required this.descriptionEn,
    required this.descriptionLo,
    required this.background,
    required this.fallbackColor,
  });

  final String descriptionEn;
  final String descriptionLo;

  /// `bg` — the pale tile wash.
  final Color background;

  /// `color` — used only when the API sends an empty `color`, which it does
  /// not today.
  final Color fallbackColor;

  String descriptionFor(String languageCode) =>
      languageCode == 'lo' ? descriptionLo : descriptionEn;
}

/// `CATEGORIES` (`ServicePage.tsx:144-153`), transcribed in source order and
/// keyed by the `id` field, which is the API's `code`.
const Map<String, CategorySeed> kCategorySeeds = <String, CategorySeed>{
  'civil': CategorySeed(
    descriptionEn: 'ID, certificates & registration',
    descriptionLo: 'ບັດປະຈຳຕົວ, ໃບຢັ້ງຢືນ ແລະ ການຂຶ້ນທະບຽນ',
    background: AppColors.categoryTintCivil,
    fallbackColor: AppColors.categoryAccentCivil,
  ),
  'immigration': CategorySeed(
    descriptionEn: 'Passport, visa & travel',
    descriptionLo: 'ໜັງສືຜ່ານແດນ, ວີຊາ ແລະ ການເດີນທາງ',
    background: AppColors.categoryTintImmigration,
    fallbackColor: AppColors.categoryAccentImmigration,
  ),
  'finance': CategorySeed(
    descriptionEn: 'Tax, bills & payments',
    descriptionLo: 'ອາກອນ, ໃບບິນ ແລະ ການຊຳລະ',
    background: AppColors.categoryTintFinance,
    fallbackColor: AppColors.categoryAccentFinance,
  ),
  'housing': CategorySeed(
    descriptionEn: 'Land, property & building',
    descriptionLo: 'ທີ່ດິນ, ຊັບສິນ ແລະ ການກໍ່ສ້າງ',
    background: AppColors.categoryTintHousing,
    fallbackColor: AppColors.categoryAccentHousing,
  ),
  'transport': CategorySeed(
    descriptionEn: 'License & vehicle',
    descriptionLo: 'ໃບຂັບຂີ່ ແລະ ຍານພາຫະນະ',
    background: AppColors.categoryTintTransport,
    fallbackColor: AppColors.categoryAccentTransport,
  ),
  'welfare': CategorySeed(
    descriptionEn: 'Aid, benefits & support',
    descriptionLo: 'ການຊ່ວຍເຫຼືອ ແລະ ສະຫວັດດີການ',
    background: AppColors.categoryTintWelfare,
    fallbackColor: AppColors.categoryAccentWelfare,
  ),
  'education': CategorySeed(
    descriptionEn: 'Schools & scholarships',
    descriptionLo: 'ໂຮງຮຽນ ແລະ ທຶນການສຶກສາ',
    background: AppColors.categoryTintEducation,
    fallbackColor: AppColors.categoryAccentEducation,
  ),
  'health': CategorySeed(
    descriptionEn: 'Healthcare & insurance',
    descriptionLo: 'ການດູແລສຸຂະພາບ ແລະ ປະກັນໄພ',
    background: AppColors.categoryTintHealth,
    fallbackColor: AppColors.categoryAccentHealth,
  ),
};
