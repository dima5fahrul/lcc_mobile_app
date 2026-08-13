/// The service modal — `HomePage.tsx:834-917` — and **SSD § 13 C-2's second
/// call site**.
///
/// Tapping a card on the home menu opens this: the service's icon and name, its
/// processing time, its required documents, its fee, and one "Apply Now"
/// button.
///
/// ## C-2 — one availability predicate, one place
///
/// > *"'Can the citizen actually go somewhere by tapping this service?' is
/// > asked in exactly two places in the whole app: the catalogue card's tap
/// > handler (B2a) and Home's 'Apply now' (B2b)."*
///
/// This is that second place, and it asks `ServiceAvailability` — the class
/// B2a built for it — rather than re-deriving the answer. That import is a
/// `features/service/domain/**` edge, which G-L3 permits and C-2 requires: two
/// features asking the same question two ways is precisely the drift the value
/// object exists to prevent.
///
/// **C-3**: nothing here branches on `route_path` or `form_schema.published`.
/// `route_path` supplies the *name* of a destination and the client route
/// registry decides whether it exists.
///
/// **C-4**: `AppNameRoutes` mounts none of the six certificate paths yet, so
/// `destinationFor` returns null for every service and Apply Now is a **silent
/// no-op** — the sheet closes and nothing else happens. That is the source's
/// own behaviour (`HomePage.tsx:908-912`: `const tab = selectedService?.tab;
/// setSelectedService(null); if (tab) onTabChange(tab);` — note the absent
/// `else`). It is not a bug and it is not `comingSoon`: SSD § 13.3's
/// visibly-disabled-card recommendation is FU-7, a user decision plus an ADR,
/// and B2 must not quietly implement it.
///
/// ## Fees and documents come from the row, not from a seed table
///
/// The source reads `getServiceConfig(selectedService.id)` — the hand-seeded
/// `SERVICE_CONFIG` table that `loadServiceCatalogue()` overwrites in place from
/// `/services`. B2a ruled on this table already (`Service`'s doc): the Flutter
/// page does not render a card until its request succeeds, so the seed has no
/// window in which it could be visible, and porting it would ship 43 hardcoded
/// prices that go stale on the first fee change. Same call here — a deliberate
/// divergence in *mechanism* with none in *output*.
library;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../presentation/common/glass_icon.dart';
import '../../../../presentation/icons/app_icons.dart';
import '../../../../presentation/icons/lucide_icon.dart';
import '../../../../presentation/theme/app_colors.dart';
import '../../../../presentation/theme/app_spacing.dart';
import '../../../../presentation/theme/app_typography.dart';
import '../../../service/domain/entities/service.dart';
import '../../../session/domain/entities/bilingual.dart';
import '../../domain/home_formatting.dart';
import 'bilingual_text.dart';
import 'home_service_card.dart';

/// Opens the sheet for [service] and returns the destination the citizen chose,
/// or null when they dismissed it or Apply Now had nowhere to go.
///
/// Returning the destination rather than navigating from inside keeps
/// `ServiceAvailability`'s answer flowing back through the page, which is the
/// only place that owns navigation — and it is what lets a widget test assert
/// C-4's no-op without a router.
Future<String?> showServiceDetailSheet(
  BuildContext context, {
  required Service service,
  required String? destination,
}) {
  return showModalBottomSheet<String>(
    context: context,
    // `flex items-end justify-center p-0` on mobile — the sheet rises from the
    // bottom edge, full width, with a rounded top only
    // (`rounded-t-3xl`, `HomePage.tsx:838`).
    backgroundColor: AppColors.white,
    barrierColor: AppColors.black.withValues(alpha: 0.5),
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(AppSpacing.radius3xl),
      ),
    ),
    builder: (BuildContext sheetContext) => ServiceDetailSheet(
      service: service,
      destination: destination,
    ),
  );
}

class ServiceDetailSheet extends StatelessWidget {
  const ServiceDetailSheet({
    super.key,
    required this.service,
    required this.destination,
  });

  final Service service;

  /// `ServiceAvailability.destinationFor(service)` — null today for all 43
  /// (C-4).
  final String? destination;

  @override
  Widget build(BuildContext context) {
    final String languageCode = Localizations.localeOf(context).languageCode;

    final bool isRange =
        service.feeIsRange && service.feeMaxLak > service.feeLak;
    final bool isFree = service.feeLak == 0 && !isRange;
    final String fee = formatFee(
      fee: service.feeLak,
      feeMax: isRange ? service.feeMaxLak : null,
      languageCode: languageCode,
    );

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.gap24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            _header(context, languageCode),
            const SizedBox(height: AppSpacing.gap24),
            _panel(
              label: 'home.processingTime'.tr(),
              child: Text(
                service.processingTime.forLanguage(languageCode),
                style: const TextStyle(
                  color: AppColors.gray700,
                  fontSize: AppTypography.size14,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.gap12),
            _panel(
              label: 'home.requiredDocs'.tr(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: service.requiredDocs
                    .map((Bilingual doc) => _bullet(
                          doc.forLanguage(languageCode),
                        ))
                    .toList(growable: false),
              ),
            ),
            const SizedBox(height: AppSpacing.gap12),
            _panel(
              label: 'home.serviceFee'.tr(),
              trailing: Text(
                fee,
                style: TextStyle(
                  color: isFree ? AppColors.success : AppColors.primary,
                  fontSize: AppTypography.size14,
                  fontWeight: AppTypography.semiBold,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.gap24),
            FilledButton(
              // C-4: `pop(destination)` with a null destination closes the
              // sheet and does nothing else. The page treats null as "no
              // navigation", so there is no branch here to get wrong.
              onPressed: () => Navigator.of(context).pop(destination),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.white,
                padding: const EdgeInsets.symmetric(
                  vertical: AppSpacing.gap16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radius2xl),
                ),
                textStyle: const TextStyle(
                  fontSize: AppTypography.size14,
                  fontWeight: AppTypography.medium,
                ),
              ),
              child: Text('home.applyNow'.tr()),
            ),
          ],
        ),
      ),
    );
  }

  Widget _header(BuildContext context, String languageCode) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        GlassIcon(
          iconName: AppIcons.service(service.icon),
          color: accentFor(service),
          size: AppSpacing.tile48,
        ),
        const SizedBox(width: AppSpacing.gap12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Semantics(
                header: true,
                child: Text(
                  service.name.forLanguage(languageCode),
                  style: const TextStyle(
                    color: AppColors.gray800,
                    fontSize: AppTypography.size16,
                    fontWeight: AppTypography.semiBold,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.gap2),
              Text(
                service.description.forLanguage(languageCode),
                style: const TextStyle(
                  color: AppColors.gray400,
                  fontSize: AppTypography.size14,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.gap8),
        IconButton(
          onPressed: () => Navigator.of(context).pop(),
          tooltip: 'common.close'.tr(),
          style: IconButton.styleFrom(backgroundColor: AppColors.gray100),
          icon: LucideIcon(
            name: 'X',
            size: AppSpacing.gap16,
            color: AppColors.gray500,
            semanticsLabel: 'common.close'.tr(),
          ),
        ),
      ],
    );
  }

  /// `p-4 rounded-xl bg-gray-50` with a small grey label above the content, or
  /// beside it when [trailing] is used (the fee row is
  /// `flex items-center justify-between`).
  Widget _panel({required String label, Widget? child, Widget? trailing}) {
    final Widget caption = Text(
      label,
      style: const TextStyle(
        color: AppColors.gray500,
        fontSize: AppTypography.size12,
      ),
    );

    return Container(
      padding: const EdgeInsets.all(AppSpacing.gap16),
      decoration: BoxDecoration(
        color: AppColors.gray50,
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
      ),
      child: trailing != null
          ? Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[caption, trailing],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                caption,
                const SizedBox(height: AppSpacing.gap6),
                if (child != null) child,
              ],
            ),
    );
  }

  /// `<li>` with a `w-1 h-1 rounded-full bg-gray-400` marker.
  Widget _bullet(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.gap4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            margin: const EdgeInsets.only(top: AppSpacing.gap6),
            width: AppSpacing.gap4,
            height: AppSpacing.gap4,
            decoration: const BoxDecoration(
              color: AppColors.gray400,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: AppSpacing.gap8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: AppColors.gray700,
                fontSize: AppTypography.size14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
