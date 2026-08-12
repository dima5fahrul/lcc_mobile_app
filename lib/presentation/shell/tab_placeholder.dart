/// One parameterised body for all five P0 tab placeholders.
///
/// The plan gives every tab the same P0 content — an icon, a heading, a line
/// of copy and a "coming soon" marker — with only Home and Account adding an
/// affordance. Five hand-written copies of that layout would be ~40 duplicated
/// lines each, which is precisely the copy-paste hazard GOR-245 **AC-8**
/// singles out ("the five new placeholder pages … should share one
/// parameterised widget"). So the layout lives here once and each page
/// supplies only what differs.
///
/// It sits under `lib/presentation/shell/` rather than a new shared folder
/// because GOR-245 § 3.1 scopes new presentation code to that path and to the
/// five `features/*/presentation/pages/` folders; a widget shared *between*
/// those five belongs to neither, and the shell is where app-wide chrome
/// already lives.
///
/// The pages are intentionally content-free beyond this: the plan marks P0-5
/// as `isi minimal, batch berikutnya isi penuh` — the real Home/Service/
/// History/Wallet/Account screens are later batches.
library;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import 'app_brand.dart';

class TabPlaceholder extends StatelessWidget {
  const TabPlaceholder({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.action,
  });

  final IconData icon;

  /// Already-translated heading (pages call `.tr()`, not this widget, so a
  /// page is free to build a composed title later without fighting the API).
  final String title;

  /// Already-translated supporting line, or null to omit it.
  final String? subtitle;

  /// Optional affordance rendered under the "coming soon" marker — the Home
  /// sign-in CTA and the Account sign-out button.
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;

    return SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: AppBrand.primarySoft,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(icon, size: 32, color: AppBrand.primary),
              ),
              const SizedBox(height: 20),
              Text(
                title,
                textAlign: TextAlign.center,
                style: textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (subtitle != null) ...<Widget>[
                const SizedBox(height: 8),
                Text(
                  subtitle!,
                  textAlign: TextAlign.center,
                  style: textTheme.bodyMedium?.copyWith(color: AppBrand.muted),
                ),
              ],
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppBrand.primarySoft,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  'common.comingSoon'.tr(),
                  style: const TextStyle(
                    color: AppBrand.primary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (action != null) ...<Widget>[
                const SizedBox(height: 28),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 320),
                  child: action!,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
