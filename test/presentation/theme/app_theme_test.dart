/// **B2-AC-9** — the token layer exists, and the relocation changed nothing.
///
/// SSD § 10.1 moved `AppBrand.light()`'s body to
/// `presentation/theme/app_theme.dart` and its four colour literals to
/// `app_colors.dart`. A relocation that also re-designed the theme would make
/// the Tier 2 baseline derived from it impossible to attribute, so the
/// assertions below are deliberately *value* assertions against the numbers
/// that were in `app_brand.dart` before the move — not `AppTheme.light()`
/// compared against itself, which would pass no matter what changed.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lcc_mobile_app/presentation/shell/app_brand.dart';
import 'package:lcc_mobile_app/presentation/theme/app_colors.dart';
import 'package:lcc_mobile_app/presentation/theme/app_spacing.dart';
import 'package:lcc_mobile_app/presentation/theme/app_theme.dart';
import 'package:lcc_mobile_app/presentation/theme/app_typography.dart';

void main() {
  group('B2-AC-9 tokens carry the pre-relocation values', () {
    test('the four brand colours are unchanged', () {
      expect(AppColors.primary, const Color(0xFF344EAD));
      expect(AppColors.primarySoft, const Color(0xFFEEF2FF));
      expect(AppColors.surface, const Color(0xFFF0F2F8));
      expect(AppColors.muted, const Color(0xFF6B7280));
    });

    test('the top bar is still 64, not Material s 56', () {
      expect(AppSpacing.topBarHeight, 64);
    });

    test('`AppBrand` forwards rather than redeclaring', () {
      // If someone re-adds a literal to the shell file, these stop being the
      // same object and the two token surfaces can drift.
      expect(AppBrand.primary, same(AppColors.primary));
      expect(AppBrand.primarySoft, same(AppColors.primarySoft));
      expect(AppBrand.surface, same(AppColors.surface));
      expect(AppBrand.muted, same(AppColors.muted));
      expect(AppBrand.topBarHeight, AppSpacing.topBarHeight);
    });
  });

  group('B2-AC-9 ThemeData is assembled from the tokens', () {
    final ThemeData theme = AppTheme.light();

    test('scheme and family', () {
      expect(theme.useMaterial3, isTrue);
      expect(theme.colorScheme.primary, AppColors.primary);
      expect(theme.scaffoldBackgroundColor, AppColors.surface);
      // AC-24's wiring, re-asserted from the new home.
      expect(theme.textTheme.bodyLarge?.fontFamily, AppTypography.fontFamily);
    });

    test('app bar', () {
      expect(theme.appBarTheme.backgroundColor, AppColors.primary);
      expect(theme.appBarTheme.foregroundColor, AppColors.white);
      expect(theme.appBarTheme.toolbarHeight, AppSpacing.topBarHeight);
      expect(theme.appBarTheme.elevation, 3);
      expect(theme.appBarTheme.centerTitle, isFalse);
    });

    test('navigation bar resolves selected and unselected states', () {
      final NavigationBarThemeData nav = theme.navigationBarTheme;
      expect(nav.backgroundColor, AppColors.white);
      expect(nav.indicatorColor, AppColors.primarySoft);

      final IconThemeData? selectedIcon =
          nav.iconTheme?.resolve(<WidgetState>{WidgetState.selected});
      final IconThemeData? idleIcon = nav.iconTheme?.resolve(<WidgetState>{});
      expect(selectedIcon?.color, AppColors.primary);
      expect(idleIcon?.color, AppColors.muted);
      expect(selectedIcon?.size, 22);

      final TextStyle? selectedLabel =
          nav.labelTextStyle?.resolve(<WidgetState>{WidgetState.selected});
      final TextStyle? idleLabel = nav.labelTextStyle?.resolve(<WidgetState>{});
      expect(selectedLabel?.fontWeight, AppTypography.semiBold);
      expect(selectedLabel?.color, AppColors.primary);
      expect(selectedLabel?.fontSize, AppTypography.size11);
      expect(idleLabel?.fontWeight, AppTypography.regular);
      expect(idleLabel?.color, AppColors.muted);
    });
  });
}
