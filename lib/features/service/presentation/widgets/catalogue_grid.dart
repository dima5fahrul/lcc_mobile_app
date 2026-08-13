/// The catalogue's card grid, and the skeleton that stands in for it.
///
/// `grid grid-cols-2 lg:grid-cols-4 gap-4` — two columns at phone widths, four
/// from `lg` (1024 px). The app targets 390 CSS px (the baseline rig's
/// viewport), so **two columns** is the ported layout; the `lg:` breakpoint has
/// no mobile counterpart and is not invented here.
library;

import 'package:flutter/material.dart';

import '../../../../presentation/theme/app_colors.dart';
import '../../../../presentation/theme/app_spacing.dart';

/// `gap-4` — 16 px, both axes.
const double _gap = AppSpacing.gap16;

/// A two-column grid of intrinsically-sized cards.
///
/// `GridView` is deliberately **not** used: it needs a fixed extent or aspect
/// ratio per cell, and these cards do not have one — a Lao service name wraps
/// to two lines where its English twin fits on one, and § 6.5.6 rules that
/// there is no canonical height per locale and a page that clips because it was
/// laid out against the English height fails Tier 1. A `Row`-of-`Column`s lets
/// every row of the grid take the height of its tallest card, which is what
/// CSS grid does.
class CatalogueGrid extends StatelessWidget {
  const CatalogueGrid({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final List<Widget> rows = <Widget>[];

    for (int i = 0; i < children.length; i += 2) {
      final Widget left = children[i];
      final Widget? right = i + 1 < children.length ? children[i + 1] : null;

      if (rows.isNotEmpty) rows.add(const SizedBox(height: _gap));

      rows.add(
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Expanded(child: left),
              const SizedBox(width: _gap),
              // An odd last card fills half the row and leaves the other half
              // empty, exactly as a CSS grid does — it does not stretch to full
              // width, which would make the final row a different shape.
              Expanded(child: right ?? const SizedBox.shrink()),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: rows,
    );
  }
}

/// `SkeletonGrid` (`ServicePage.tsx:237-253`) — eight placeholder cards.
///
/// The source animates them with Tailwind's `animate-pulse`. That is ported as
/// a real opacity pulse rather than dropped: a static grey grid reads as
/// "broken" where a pulsing one reads as "loading", and § 6.6 requires the
/// loading state be *distinguishable*, which is the whole job of the animation.
class SkeletonGrid extends StatelessWidget {
  const SkeletonGrid({super.key, this.count = 8});

  /// `count = 8` — the source's default and its only call.
  final int count;

  @override
  Widget build(BuildContext context) {
    return _Pulse(
      child: CatalogueGrid(
        children: List<Widget>.generate(count, (int _) => const _SkeletonCard()),
      ),
    );
  }
}

/// `animate-pulse` — Tailwind's `opacity: 1 → .5 → 1` over 2 s, `ease-in-out`.
class _Pulse extends StatefulWidget {
  const _Pulse({required this.child});

  final Widget child;

  @override
  State<_Pulse> createState() => _PulseState();
}

class _PulseState extends State<_Pulse> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 2),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: Tween<double>(begin: 1, end: 0.5).animate(
        CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
      ),
      child: widget.child,
    );
  }
}

/// One skeleton card: `bg-white rounded-2xl p-5 shadow-sm border border-gray-100`
/// around a 56 px tile and three bars at 3/4, 1/2 and 1/3 width.
class _SkeletonCard extends StatelessWidget {
  const _SkeletonCard();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: catalogueCardDecoration,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.gap20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Container(
              width: AppSpacing.tile56,
              height: AppSpacing.tile56,
              decoration: BoxDecoration(
                color: AppColors.gray200,
                borderRadius: BorderRadius.circular(AppSpacing.radius2xl),
              ),
            ),
            const SizedBox(height: AppSpacing.gap16),
            // `h-4 w-3/4 bg-gray-200`
            const _SkeletonBar(height: 16, widthFactor: 0.75,
                color: AppColors.gray200),
            const SizedBox(height: AppSpacing.gap8),
            // `h-3 w-1/2 bg-gray-100 mt-2`
            const _SkeletonBar(height: 12, widthFactor: 0.5,
                color: AppColors.gray100),
            const SizedBox(height: AppSpacing.gap16),
            // `h-3 w-1/3 bg-gray-100 mt-4`
            const _SkeletonBar(height: 12, widthFactor: 1 / 3,
                color: AppColors.gray100),
          ],
        ),
      ),
    );
  }
}

class _SkeletonBar extends StatelessWidget {
  const _SkeletonBar({
    required this.height,
    required this.widthFactor,
    required this.color,
  });

  final double height;
  final double widthFactor;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return FractionallySizedBox(
      alignment: Alignment.centerLeft,
      widthFactor: widthFactor,
      child: Container(
        height: height,
        decoration: BoxDecoration(
          color: color,
          // `rounded` — Tailwind's 4 px.
          borderRadius: BorderRadius.circular(AppSpacing.gap4),
        ),
      ),
    );
  }
}

/// `bg-white rounded-2xl shadow-sm border border-gray-100` — the shell every
/// catalogue surface shares: both card kinds, the skeleton, the error panel and
/// both empty panels. One decoration because the source uses one class string;
/// if they drift, they drift in the source first.
final BoxDecoration catalogueCardDecoration = BoxDecoration(
  color: AppColors.white,
  borderRadius: BorderRadius.circular(AppSpacing.radius2xl),
  border: Border.all(color: AppColors.gray100),
  boxShadow: const <BoxShadow>[
    // Tailwind `shadow-sm`: `0 1px 2px 0 rgb(0 0 0 / 0.05)`.
    BoxShadow(
      color: AppColors.cardShadow,
      offset: Offset(0, 1),
      blurRadius: 2,
    ),
  ],
);
