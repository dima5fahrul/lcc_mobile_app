/// `SectionLabel` — Marriage `:270-276`, Divorce `:279-285`, byte-identical.
///
/// ```tsx
/// <p className="text-xs font-semibold text-gray-500 uppercase tracking-wider pt-1">
/// ```
///
/// `tracking-wider` is `0.05em`, twice [FieldLabel]'s `tracking-wide`. The two
/// labels are otherwise the same string, which is why they are two widgets and
/// not one with a flag: the difference is a value, and Tier 2 reads values.
library;

import 'package:flutter/widgets.dart';

import '../../../../presentation/theme/app_colors.dart';
import '../../../../presentation/theme/app_spacing.dart';
import '../../../../presentation/theme/app_typography.dart';

/// `tracking-wider` = `0.05em`; at `text-xs` that is 12 × 0.05.
const double kCertificateSectionTracking = AppTypography.size12 * 0.05;

class CertificateSectionLabel extends StatelessWidget {
  const CertificateSectionLabel({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      // `pt-1`
      padding: const EdgeInsets.only(top: AppSpacing.gap4),
      child: Text(
        text.toUpperCase(),
        style: const TextStyle(
          fontSize: AppTypography.size12,
          fontWeight: AppTypography.semiBold,
          color: AppColors.muted,
          letterSpacing: kCertificateSectionTracking,
        ),
      ),
    );
  }
}
