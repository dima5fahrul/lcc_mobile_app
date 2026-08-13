/// The app-wide [ThemeData], assembled from [AppColors], [AppTypography] and
/// [AppSpacing].
///
/// This is `AppBrand.light()`'s body, relocated per SSD § 10.1. It moved for a
/// reason that is not tidiness: the theme used to live in
/// `presentation/shell/app_brand.dart`, i.e. inside the shell-chrome folder, so
/// the one artefact the whole app's appearance derives from was scoped as if it
/// belonged to the header bar. Fidelity Tier 2 has to read it, and B2 adds five
/// features that have to read it, neither of which is shell chrome.
///
/// **The behaviour is unchanged by the move.** Every value below is the value
/// that was there before; the only difference is that the literals now resolve
/// through named tokens. That is deliberate — a relocation that also
/// re-designed the theme would make the resulting Tier 2 baseline impossible to
/// attribute.
///
/// Only a light theme is produced: the React source has no dark mode, and
/// inventing one here would be design work with no source. `MaterialApp`
/// therefore pins `themeMode: light` (see `main.dart`).
library;

import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_spacing.dart';
import 'app_typography.dart';

/// The app's `ThemeData` factory. Never instantiated.
abstract final class AppTheme {
  /// The app-wide light theme.
  static ThemeData light() {
    final ColorScheme scheme = ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      primary: AppColors.primary,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      // Applied to the whole default `TextTheme` by `ThemeData` itself — see
      // `AppTypography`'s note on why no explicit `textTheme` is supplied.
      fontFamily: AppTypography.fontFamily,
      scaffoldBackgroundColor: AppColors.surface,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
        surfaceTintColor: Colors.transparent,
        toolbarHeight: AppSpacing.topBarHeight,
        elevation: 3,
        centerTitle: false,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.white,
        surfaceTintColor: Colors.transparent,
        indicatorColor: AppColors.primarySoft,
        elevation: 3,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        iconTheme: WidgetStateProperty.resolveWith(
          (Set<WidgetState> states) => IconThemeData(
            size: 22,
            color: states.contains(WidgetState.selected)
                ? AppColors.primary
                : AppColors.muted,
          ),
        ),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (Set<WidgetState> states) => TextStyle(
            fontSize: AppTypography.size11,
            fontWeight: states.contains(WidgetState.selected)
                ? AppTypography.semiBold
                : AppTypography.regular,
            color: states.contains(WidgetState.selected)
                ? AppColors.primary
                : AppColors.muted,
          ),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.white,
          minimumSize: const Size.fromHeight(48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          minimumSize: const Size.fromHeight(48),
          side: const BorderSide(color: AppColors.primary),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
          ),
        ),
      ),
    );
  }
}
