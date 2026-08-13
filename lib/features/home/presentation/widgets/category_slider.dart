/// "Explore a Service for Every Need" — `HomePage.tsx:541-612`.
///
/// A horizontal strip of eight photo cards, each a category: the photograph
/// full-bleed, a colour gradient underneath it as a load-time fallback, a navy
/// scrim for legibility, and the title + benefit line + "See service" chip
/// stacked at the bottom. Two arrow buttons scroll it.
///
/// ## This is the surface B2-AC-31 exists for
///
/// Eight `864×1152` photographs painted into `281×360` boxes. Decoded whole
/// that is **31.8 MB of RGBA in the image cache** for one strip; decoded at
/// paint size on a 3x device it is 8 × 843×1124 ≈ 30 MB — no better. The real
/// win is that the decode is *bounded by the box* rather than by the asset, so
/// on the 2x devices that are most of the fleet it is 8 × 562×750 ≈ 13.5 MB,
/// and on a 1x tablet 3.4 MB. B1b § 6.4 chose a single large asset over a
/// density ladder **on the condition** that call sites do this; [TierAImage] is
/// where the condition is met and
/// `test/features/home/architecture/tier_a_asset_test.dart` is what keeps it
/// met.
///
/// ## The slide copy is compile-time, and that is the source's split
///
/// `CATEGORY_SLIDES` (`HomePage.tsx:109-118`) holds a benefit sentence per
/// category in both languages, and `CATEGORIES` holds the label. Neither is
/// published by `/service-categories`, which sends `{id, code, name, icon,
/// color, sort_order, active}` — the same split `category_seed.dart` records
/// for the catalogue page: *"the API publishes a name, icon and colour; the
/// blurb and tint stay local."*
///
/// The **label** is the one field that is on the wire, so it comes from the
/// API row when there is one. Today Home has no `/service-categories` request
/// of its own — it is B2a's endpoint and Home's slider is fed by this table —
/// so the seeded label renders. Recorded rather than hidden: if a category is
/// renamed server-side, this strip keeps the old name until someone gives Home
/// the categories request. That is a smaller wrong than adding a sixth network
/// call to a page that already makes five, and it is exactly what the web does.
library;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../presentation/icons/lucide_icon.dart';
import '../../../../presentation/theme/app_colors.dart';
import '../../../../presentation/theme/app_spacing.dart';
import '../../../../presentation/theme/app_typography.dart';
import '../../domain/home_formatting.dart';
import 'tier_a_image.dart';

/// One slide's compile-time copy: the category label and the benefit line.
///
/// `accent` is the 0 % stop of the fallback gradient
/// (`linear-gradient(155deg, ${cat.color} 0%, #17235c 100%)`,
/// `HomePage.tsx:561`). It reads `CATEGORIES[].color`, the seed table's value —
/// which is compile-time copy here for the same reason
/// `AppColors.categoryAccent*` exists: the API's colour is data, the seed's is
/// the fallback the source's own chain ends in.
class CategorySlide {
  const CategorySlide({
    required this.code,
    required this.labelEn,
    required this.labelLo,
    required this.blurbEn,
    required this.blurbLo,
    required this.accent,
  });

  final String code;
  final String labelEn;
  final String labelLo;
  final String blurbEn;
  final String blurbLo;
  final Color accent;

  String label(String languageCode) =>
      languageCode == kLao ? labelLo : labelEn;

  String blurb(String languageCode) =>
      languageCode == kLao ? blurbLo : blurbEn;

  /// The photograph, or null for a category this build bundles no image for —
  /// which cannot happen today (all eight are present) and is why the gradient
  /// underneath is a *fallback* rather than dead code.
  TierAAsset? get asset => kCategorySlideAssets[code];
}

/// `CATEGORY_SLIDES` × `CATEGORIES`, joined on `id`, in the source's order.
///
/// `HomePage.tsx:549-551` performs that join at render time and skips a slide
/// whose category is missing (`if (!cat) return null`). Both tables are
/// compile-time and both are complete, so the join is done here once instead of
/// on every build.
const List<CategorySlide> kCategorySlides = <CategorySlide>[
  CategorySlide(
    code: 'civil',
    labelEn: 'Civil & Population',
    labelLo: 'ພົນລະເມືອງ ແລະ ການທະບຽນ',
    blurbEn: 'Register births, IDs, certificates and family records — all in '
        'one place.',
    blurbLo: 'ຂຶ້ນທະບຽນການເກີດ, ບັດປະຈຳຕົວ, ໃບຢັ້ງຢືນ ແລະ ຂໍ້ມູນຄອບຄົວ ໃນບ່ອນດຽວ.',
    accent: AppColors.categoryAccentCivil,
  ),
  CategorySlide(
    code: 'immigration',
    labelEn: 'Immigration',
    labelLo: 'ກວດຄົນເຂົ້າ-ອອກເມືອງ',
    blurbEn: 'Passports, visas and travel documents, handled fully online.',
    blurbLo: 'ໜັງສືຜ່ານແດນ, ວີຊາ ແລະ ເອກະສານເດີນທາງ ຈັດການອອນລາຍທັງໝົດ.',
    accent: AppColors.categoryAccentImmigration,
  ),
  CategorySlide(
    code: 'finance',
    labelEn: 'Tax & Payment',
    labelLo: 'ອາກອນ ແລະ ການຊຳລະ',
    blurbEn: 'Pay taxes, bills and government fees quickly and securely.',
    blurbLo: 'ຊຳລະອາກອນ, ໃບບິນ ແລະ ຄ່າທຳນຽມລັດ ຢ່າງໄວ ແລະ ປອດໄພ.',
    accent: AppColors.categoryAccentFinance,
  ),
  CategorySlide(
    code: 'housing',
    labelEn: 'Land & Property',
    labelLo: 'ທີ່ດິນ ແລະ ຊັບສິນ',
    blurbEn: 'Land titles, property and building permits made simple and '
        'clear.',
    blurbLo: 'ໃບຕາດິນ, ຊັບສິນ ແລະ ໃບອະນຸຍາດກໍ່ສ້າງ ທີ່ງ່າຍ ແລະ ຊັດເຈນ.',
    accent: AppColors.categoryAccentHousing,
  ),
  CategorySlide(
    code: 'transport',
    labelEn: 'Transport',
    labelLo: 'ການຂົນສົ່ງ',
    blurbEn: 'Driving licences and vehicle registration without the queues.',
    blurbLo: 'ໃບຂັບຂີ່ ແລະ ການຂຶ້ນທະບຽນຍານພາຫະນະ ໂດຍບໍ່ຕ້ອງຕໍ່ຄິວ.',
    accent: AppColors.categoryAccentTransport,
  ),
  CategorySlide(
    code: 'welfare',
    labelEn: 'Social Protection',
    labelLo: 'ການປົກປ້ອງທາງສັງຄົມ',
    blurbEn: 'Social assistance, benefits and support for those who need it.',
    blurbLo: 'ການຊ່ວຍເຫຼືອສັງຄົມ, ສະຫວັດດີການ ແລະ ການສະໜັບສະໜູນ ສຳລັບຜູ້ທີ່ຕ້ອງການ.',
    accent: AppColors.categoryAccentWelfare,
  ),
  CategorySlide(
    code: 'education',
    labelEn: 'Education',
    labelLo: 'ການສຶກສາ',
    blurbEn: 'Schools, scholarships and student services for every stage.',
    blurbLo: 'ໂຮງຮຽນ, ທຶນການສຶກສາ ແລະ ການບໍລິການນັກຮຽນ ໃນທຸກຂັ້ນ.',
    accent: AppColors.categoryAccentEducation,
  ),
  CategorySlide(
    code: 'health',
    labelEn: 'Health',
    labelLo: 'ສາທາລະນະສຸກ',
    blurbEn: 'Access healthcare, insurance and medical services near you.',
    blurbLo: 'ເຂົ້າເຖິງການດູແລສຸຂະພາບ, ປະກັນໄພ ແລະ ການບໍລິການທາງການແພດ.',
    accent: AppColors.categoryAccentHealth,
  ),
];

/// How far an arrow scrolls — `scrollBy({ left: dir * 300 })`
/// (`HomePage.tsx:209`).
const double kSliderStep = 300;

/// The scroll animation the source asks for with `behavior: "smooth"`.
const Duration kSliderAnimation = Duration(milliseconds: 300);

class CategorySlider extends StatefulWidget {
  const CategorySlider({super.key, required this.onSlideTap});

  /// `href={tabHref("service")}` — every slide goes to the catalogue.
  final VoidCallback onSlideTap;

  @override
  State<CategorySlider> createState() => _CategorySliderState();
}

class _CategorySliderState extends State<CategorySlider> {
  final ScrollController _controller = ScrollController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _slideBy(int direction) {
    if (!_controller.hasClients) return;
    final double target = (_controller.offset + direction * kSliderStep)
        .clamp(0, _controller.position.maxScrollExtent);
    _controller.animateTo(
      target,
      duration: kSliderAnimation,
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final String languageCode = Localizations.localeOf(context).languageCode;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        SizedBox(
          height: AppSpacing.categorySlideHeight,
          child: ListView.separated(
            controller: _controller,
            scrollDirection: Axis.horizontal,
            // `snap-x snap-mandatory` — one slide per flick.
            physics: const PageScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.gap4),
            itemCount: kCategorySlides.length,
            separatorBuilder: (_, __) =>
                const SizedBox(width: AppSpacing.gap16),
            itemBuilder: (BuildContext context, int index) => _slide(
              kCategorySlides[index],
              languageCode,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.gap24),
        SliderArrows(
          onPrevious: () => _slideBy(-1),
          onNext: () => _slideBy(1),
        ),
      ],
    );
  }

  Widget _slide(CategorySlide slide, String languageCode) {
    final TierAAsset? asset = slide.asset;

    return SizedBox(
      // `w-[72%]` of the 390 px rig — the width B1b § 6.3 sized the asset
      // against, and therefore the decode target.
      width: AppSpacing.categorySlideWidth,
      child: Material(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radius3xl),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: widget.onSlideTap,
          child: Stack(
            fit: StackFit.expand,
            children: <Widget>[
              // The colour gradient that shows under the photo while it loads
              // — `linear-gradient(155deg, ${cat.color} 0%, #17235c 100%)`.
              // 155° points down-and-slightly-right: (sin 155°, −cos 155°) =
              // (0.423, 0.906).
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: const Alignment(-0.423, -0.906),
                    end: const Alignment(0.423, 0.906),
                    colors: <Color>[
                      slide.accent,
                      AppColors.photoGradientEnd,
                    ],
                  ),
                ),
              ),
              if (asset != null)
                TierAImage(
                  asset: asset,
                  paintWidth: AppSpacing.categorySlideWidth,
                ),
              // `linear-gradient(to top, rgba(18,31,80,0.82) 0%,
              //  rgba(18,31,80,0.62) 55%, rgba(18,31,80,0.45) 100%)`
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: <Color>[
                      AppColors.scrimNavy.withValues(alpha: 0.82),
                      AppColors.scrimNavy.withValues(alpha: 0.62),
                      AppColors.scrimNavy.withValues(alpha: 0.45),
                    ],
                    stops: const <double>[0.0, 0.55, 1.0],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(AppSpacing.gap24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Semantics(
                      header: true,
                      child: Text(
                        slide.label(languageCode),
                        style: const TextStyle(
                          color: AppColors.white,
                          fontSize: AppTypography.size20,
                          fontWeight: AppTypography.semiBold,
                          height: AppTypography.lineTight,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.gap8),
                    Text(
                      slide.blurb(languageCode),
                      style: TextStyle(
                        color: AppColors.white.withValues(alpha: 0.8),
                        fontSize: AppTypography.size14,
                        height: AppTypography.lineRelaxed,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.gap16),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.gap14,
                        vertical: AppSpacing.gap8,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius:
                            BorderRadius.circular(AppSpacing.radiusFull),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          Text(
                            'home.seeService'.tr(),
                            style: const TextStyle(
                              color: AppColors.gray900,
                              fontSize: AppTypography.size12,
                              fontWeight: AppTypography.semiBold,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.gap4),
                          const LucideIcon(
                            name: 'ChevronRight',
                            size: AppSpacing.gap14,
                            color: AppColors.gray900,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The `‹ ›` pair under both sliders — `HomePage.tsx:593-610` and `:707-724`.
///
/// Identical markup in both places, so one widget. The labels are
/// `aria-label="Previous"` / `"Next"` in the source — **untranslated English**,
/// in both locales. Ported as-is: `aria-label` text is what a screen reader
/// announces, and "fixing" it here would put a string on the Flutter page that
/// the web does not have, which Tier 1 would read as an extra node.
class SliderArrows extends StatelessWidget {
  const SliderArrows({
    super.key,
    required this.onPrevious,
    required this.onNext,
  });

  final VoidCallback onPrevious;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        _arrow(
          glyph: 'ChevronLeft',
          label: 'Previous',
          onPressed: onPrevious,
          filled: false,
        ),
        const SizedBox(width: AppSpacing.gap12),
        _arrow(
          glyph: 'ChevronRight',
          label: 'Next',
          onPressed: onNext,
          filled: true,
        ),
      ],
    );
  }

  Widget _arrow({
    required String glyph,
    required String label,
    required VoidCallback onPressed,
    required bool filled,
  }) {
    return Semantics(
      button: true,
      label: label,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
        child: Container(
          width: AppSpacing.control40,
          height: AppSpacing.control40,
          decoration: BoxDecoration(
            color: filled ? AppColors.primary : null,
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.primary),
          ),
          child: Center(
            child: LucideIcon(
              name: glyph,
              size: AppSpacing.gap20,
              color: filled ? AppColors.white : AppColors.primary,
            ),
          ),
        ),
      ),
    );
  }
}
