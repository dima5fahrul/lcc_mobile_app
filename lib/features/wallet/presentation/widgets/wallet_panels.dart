/// The wallet's repeated chrome: the retry pill, the retry card, the empty
/// card, the row skeleton and the section header.
///
/// `WalletPage.tsx` writes each of these out four or five times inline. They
/// are factored here rather than transcribed per region for the reason
/// `home_panels.dart` gives: five copies of a retry card drift, and the drift
/// is a Tier 1 failure in whichever copy was edited last. The **shapes** are
/// the source's, unchanged.
///
/// ## Iconography — a measured constraint, recorded not worked around
///
/// `WalletPage.tsx` draws 22 lucide glyphs. Eleven of them
/// (`Plus`, `ArrowDownLeft`, `ArrowUpRight`, `Droplet`, `Wifi`, `Smartphone`,
/// `Send`, `CalendarClock`, `CheckCircle2`, and the two logo rasters' fallback
/// pair) are **not in `assets/icons/lucide/`** and therefore not in
/// `lucide_registry.g.dart`. `AppIcons.assetFor` answers `FileText` for an
/// unbundled name *silently*, so a `LucideIcon('Plus')` would render a document
/// glyph and pass every test that does not look at the picture.
///
/// Adding the eleven SVGs means writing `assets/icons/lucide/**` and
/// regenerating `lucide_registry.g.dart`; neither path is in specs.md § 3.1's
/// B6a table, and an unlisted file is an automatic FAIL. So each unbundled
/// glyph is drawn with its nearest Material equivalent, named at the call site,
/// and the whole set is filed as a Tier 2/Tier 3 gap in `qa-report.md` for the
/// batch that owns the icon assets. It is a visible divergence with a written
/// cause, which is the required outcome; a silent `FileText` would not be.
library;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../presentation/icons/lucide_icon.dart';
import '../../../../presentation/theme/app_colors.dart';

/// `mt-3 inline-flex … text-xs text-white/90 bg-white/15 border border-white/20
/// rounded-full px-3 py-1.5` — `WalletPage.tsx:195-201`.
///
/// The translucent pill, used **only** on the gradient balance card. The other
/// three error branches use [WalletRetryCard], which is a different widget in
/// the source too.
class WalletTryAgainPill extends StatelessWidget {
  const WalletTryAgainPill({super.key, required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: InkWell(
        onTap: onRetry,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.white.withValues(alpha: 0.15),
            border: Border.all(color: AppColors.white.withValues(alpha: 0.20)),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              LucideIcon(
                name: 'RefreshCw',
                size: 14,
                color: AppColors.white.withValues(alpha: 0.90),
              ),
              const SizedBox(width: 6),
              Text(
                // `lang === "lo" ? "ລອງໃໝ່" : "Try again"` — `:199`, relocated
                // into the namespace by specs.md § 6.13(3).
                'wallet.tryAgain'.tr(context: context),
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.white.withValues(alpha: 0.90),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The full-card error branch — `WalletPage.tsx:437-450`, `:604-616`, `:808-820`.
///
/// The **message is the server's**, rendered verbatim: `{txQuery.error.message}`.
/// Nothing here composes it, and security-review item 2 turns on that: no
/// balance, account number or receipt number may be interpolated into it.
class WalletRetryCard extends StatelessWidget {
  const WalletRetryCard({
    super.key,
    required this.message,
    required this.onRetry,
    this.boxed = true,
  });

  final String message;
  final VoidCallback onRetry;

  /// `false` renders the sheet's variant (`:810-819`) — the same content with
  /// no card around it.
  final bool boxed;

  @override
  Widget build(BuildContext context) {
    final Widget content = Column(
      children: <Widget>[
        Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 14, color: AppColors.gray600),
        ),
        const SizedBox(height: 12),
        _PrimaryPillButton(
          label: 'wallet.tryAgain'.tr(context: context),
          onTap: onRetry,
        ),
      ],
    );

    if (!boxed) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: content,
      );
    }

    return _WalletCard(padding: const EdgeInsets.all(32), child: content);
  }
}

/// The empty branch — a 48×48 grey rounded tile, a glyph, a title and a hint.
///
/// `WalletPage.tsx:312-325` (bills), `:452-465` (receipts), `:627-640` (ledger).
class WalletEmptyCard extends StatelessWidget {
  const WalletEmptyCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  /// Already resolved by the caller, because half of these are Material
  /// substitutes for unbundled lucide glyphs — see the library doc.
  final Widget icon;

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return _WalletCard(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: <Widget>[
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.gray100,
              borderRadius: BorderRadius.circular(16),
            ),
            alignment: Alignment.center,
            child: icon,
          ),
          const SizedBox(height: 12),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 14, color: AppColors.gray500),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.gray400Inline,
            ),
          ),
        ],
      ),
    );
  }
}

/// The 3-row list skeleton — `WalletPage.tsx:426-436`, `:600-611`.
///
/// **Not animated.** The source's `animate-pulse` is a CSS keyframe; a Flutter
/// port would need an `AnimationController`, and `B6-AC-26` greps this feature
/// for `Timer` and requires zero. A static grey block is what a paused pulse
/// looks like, which is also what every screenshot of the source shows.
class WalletRowSkeleton extends StatelessWidget {
  const WalletRowSkeleton({super.key, this.rows = 3});

  final int rows;

  @override
  Widget build(BuildContext context) {
    return _WalletCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: <Widget>[
          for (int i = 0; i < rows; i++) ...<Widget>[
            if (i > 0)
              const Divider(height: 1, thickness: 1, color: AppColors.gray100),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: <Widget>[
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.gray100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        FractionallySizedBox(
                          widthFactor: 1 / 3,
                          child: Container(
                            height: 12,
                            decoration: BoxDecoration(
                              color: AppColors.gray200,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        FractionallySizedBox(
                          widthFactor: 1 / 4,
                          child: Container(
                            height: 10,
                            decoration: BoxDecoration(
                              color: AppColors.gray100,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// A section title with a right-aligned text action — `:389-405`, `:265-283`.
class WalletSectionHeader extends StatelessWidget {
  const WalletSectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    required this.actionLabel,
    required this.onAction,
  });

  final String title;
  final String? subtitle;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.gray800,
                ),
              ),
              if (subtitle != null) ...<Widget>[
                const SizedBox(height: 2),
                Text(
                  subtitle!,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.gray500,
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(width: 12),
        InkWell(
          onTap: onAction,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  actionLabel,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 4),
                const LucideIcon(
                  name: 'ChevronRight',
                  size: 14,
                  color: AppColors.primary,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// `bg-white rounded-2xl shadow-sm border border-gray-100` — the wallet's one
/// card shape, used by every panel above and by the two lists.
class _WalletCard extends StatelessWidget {
  const _WalletCard({required this.child, required this.padding});

  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.gray100),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: AppColors.cardShadow,
            blurRadius: 2,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: child,
    );
  }
}

/// The blue pill CTA under an error message — `:443-449`.
class _PrimaryPillButton extends StatelessWidget {
  const _PrimaryPillButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const LucideIcon(
              name: 'RefreshCw',
              size: 16,
              color: AppColors.white,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The card shape, exported for the two list widgets in this directory.
class WalletCard extends StatelessWidget {
  const WalletCard({
    super.key,
    required this.child,
    this.padding = EdgeInsets.zero,
  });

  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) =>
      _WalletCard(padding: padding, child: child);
}
