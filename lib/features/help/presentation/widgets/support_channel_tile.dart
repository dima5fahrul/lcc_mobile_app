/// One support-channel tile — icon, label, value, hours.
///
/// `HelpCenterPage.tsx:489-527`.
///
/// ## The `tel:` / `mailto:` links are NOT actionable, and that is reported
///
/// The web wraps a `phone` or `email` channel in an `<a href="tel:1590">` /
/// `<a href="mailto:…">`; the other two kinds render as a plain `<div>`. Opening
/// a platform URI from Flutter needs `url_launcher`, which this app **does not
/// declare** — and B2c's § 3.1 scope adds no dependency (the dispatch is
/// explicit: *"`pubspec.yaml` needs no change. If you think it does, stop and
/// report."*).
///
/// So the tile renders identically and its tap is inert. That is the same
/// disposition SSD § 13 **C-4** takes for a catalogue card with no client
/// route — port the card fully, let the tap be a silent no-op — and it is
/// survivable here for a specific reason: **the value is on screen verbatim**
/// (`1590`, `support@lcc.gov.la`), so the citizen can still act on it.
///
/// Reported as a named gap rather than silently absorbed. Closing it is one
/// dependency plus a launcher call, in a batch whose scope permits it.
library;

import 'package:flutter/material.dart';

import '../../../../presentation/icons/lucide_icon.dart';
import '../../../../presentation/theme/app_colors.dart';
import '../../../../presentation/theme/app_spacing.dart';
import '../../../../presentation/theme/app_typography.dart';
import '../../domain/entities/help_entities.dart';
import 'bilingual_text.dart';

class SupportChannelTile extends StatelessWidget {
  const SupportChannelTile({
    super.key,
    required this.channel,
    required this.iconName,
  });

  final SupportChannel channel;

  /// Already resolved through `AppIcons.help`. Note the source passes
  /// `MessageCircle` as this call site's fallback (`:490`) rather than the
  /// default `FileText`; the page applies that before handing the name in.
  final String iconName;

  @override
  Widget build(BuildContext context) {
    return Container(
      // `flex items-center gap-3 rounded-xl border border-gray-100 p-3`
      padding: const EdgeInsets.all(AppSpacing.gap12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        border: Border.all(color: AppColors.gray100),
      ),
      child: Row(
        children: <Widget>[
          // `w-9 h-9 rounded-xl bg-[#EEF2FF]`
          Container(
            width: AppSpacing.tile36,
            height: AppSpacing.tile36,
            decoration: BoxDecoration(
              color: AppColors.primarySoft,
              borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
            ),
            child: Center(
              child: LucideIcon(
                name: iconName,
                size: AppSpacing.gap16,
                color: AppColors.primary,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.gap12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  channel.label.forContext(context),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.gray800,
                    fontSize: AppTypography.size14,
                    fontWeight: AppTypography.semiBold,
                  ),
                ),
                Text(
                  // Rendered verbatim — this is the actionable content, and the
                  // reason the inert tap above is survivable.
                  channel.value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.gray500,
                    fontSize: AppTypography.size12,
                  ),
                ),
                const SizedBox(height: AppSpacing.gap2),
                Text(
                  channel.hours.forContext(context),
                  style: const TextStyle(
                    color: AppColors.gray400Inline,
                    fontSize: AppTypography.size11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
