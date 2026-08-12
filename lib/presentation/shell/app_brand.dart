/// LCC brand tokens and the app-wide [ThemeData].
///
/// Ported from the hard-coded colour literals scattered through
/// `lcc-app/src/app/components/Layout.tsx` and `AuthPage.tsx`:
///
/// | React literal | Where it is used                          | Token here          |
/// |---------------|-------------------------------------------|---------------------|
/// | `#344EAD`     | `BRAND` — header bar, active nav, CTAs    | [AppBrand.primary]  |
/// | `#EEF2FF`     | tinted icon tiles behind brand-coloured   | [AppBrand.primarySoft] |
/// | `#F0F2F8`     | `bg-[#F0F2F8]` app background             | [AppBrand.surface]  |
/// | `#6B7280`     | inactive bottom-nav icon + label          | [AppBrand.muted]    |
///
/// The React app applies these per-element through Tailwind/inline styles. A
/// Flutter port should not do that — repeating `Color(0xFF344EAD)` at every
/// call site is exactly the duplication the M3 `ColorScheme` exists to remove.
/// So the tokens are declared once here and handed to `MaterialApp.theme`;
/// widgets read them through `Theme.of(context)` wherever a scheme role
/// exists, and through [AppBrand] directly only for the two tokens M3 has no
/// role for ([surface] as the scaffold wash, [muted] as the inactive-nav grey).
///
/// This file lives under `lib/presentation/shell/` deliberately: the shell is
/// the only surface that owns app-wide chrome, and GOR-245 § 3.1 scopes new
/// presentation code to that folder.
library;

import 'package:flutter/material.dart';

class AppBrand {
  AppBrand._();

  /// `#344EAD` — the LCC brand blue. Header, active nav, primary CTAs.
  static const Color primary = Color(0xFF344EAD);

  /// `#EEF2FF` — the pale brand tint used behind brand-coloured icons.
  static const Color primarySoft = Color(0xFFEEF2FF);

  /// `#F0F2F8` — the page wash behind every screen.
  static const Color surface = Color(0xFFF0F2F8);

  /// `#6B7280` — secondary text and inactive bottom-nav items.
  static const Color muted = Color(0xFF6B7280);

  /// Height of the top bar. `h-16` in `Layout.tsx` = 64 logical pixels, taller
  /// than Material's 56 default, so the brand + sub-brand stack fits.
  static const double topBarHeight = 64;

  /// The app-wide light theme.
  ///
  /// Only a light theme is produced: the React source has no dark mode, and
  /// inventing one here would be design work this ticket has no source for.
  /// `MaterialApp` therefore pins `themeMode: light` (see `main.dart`).
  static ThemeData light() {
    final ColorScheme scheme = ColorScheme.fromSeed(
      seedColor: primary,
      primary: primary,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      fontFamily: 'NotoSansLao',
      scaffoldBackgroundColor: surface,
      appBarTheme: const AppBarTheme(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        toolbarHeight: topBarHeight,
        elevation: 3,
        centerTitle: false,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        indicatorColor: primarySoft,
        elevation: 3,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            size: 22,
            color: states.contains(WidgetState.selected) ? primary : muted,
          ),
        ),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => TextStyle(
            fontSize: 11,
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w600
                : FontWeight.w400,
            color: states.contains(WidgetState.selected) ? primary : muted,
          ),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primary,
          minimumSize: const Size.fromHeight(48),
          side: const BorderSide(color: primary),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}
