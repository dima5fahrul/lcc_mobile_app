/// `VerifyCodeEntryPage` — the typed entry point for public verification
/// (§ Public verification endpoints, § QR codes and deep links).
///
/// A `TextField` plus a submit button that runs the typed text through
/// [certificateCodeFromScanned] — the SAME gate the scanner (Task 5) uses —
/// before anything reaches the bloc, so a stray sentence or a pasted URL
/// that is not one of the recognised shapes never becomes a network call.
/// On a recognised code it navigates to `/verify/<code>`, whose own route
/// builder (`app_routes.dart`) owns the bloc and dispatches
/// `VerifySubmitted` — this page does not dispatch directly, so there is
/// exactly one dispatch site for a typed code, the same one a deep link
/// uses.
///
/// The **Scan** button is a placeholder: "does nothing yet — Task 5 wires
/// the camera" (task brief). It is present so the layout and the copy are
/// final now and Task 5's change is additive.
///
/// ## No locator read (G-L5)
///
/// Nothing here resolves `verifyInjection` — the route builder already
/// provided a `VerifyBloc` above this widget for the destination it
/// navigates to.
library;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../presentation/icons/lucide_icon.dart';
import '../../../../presentation/theme/app_colors.dart';
import '../../../../presentation/theme/app_spacing.dart';
import '../../../../presentation/theme/app_typography.dart';
import '../../../../utils/routes/app_name_routes.dart';
import '../../domain/code_extraction.dart';

class VerifyCodeEntryPage extends StatefulWidget {
  const VerifyCodeEntryPage({super.key});

  @override
  State<VerifyCodeEntryPage> createState() => _VerifyCodeEntryPageState();
}

class _VerifyCodeEntryPageState extends State<VerifyCodeEntryPage> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final String raw = _controller.text.trim();
    if (raw.isEmpty) return;

    // Rule 2/3 of `certificateCodeFromScanned` — the same gate the scanner
    // uses. A code the shape does not recognise sends nothing to the API.
    final String? code = certificateCodeFromScanned(raw);
    if (code == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('verify.entry.invalid'.tr(context: context))),
      );
      return;
    }

    context.go('${AppNameRoutes.verify}/$code');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        surfaceTintColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const LucideIcon(name: 'ChevronLeft'),
          onPressed: () => context.go(AppNameRoutes.home),
        ),
        title: Text(
          'verify.entry.title'.tr(context: context),
          style: TextStyle(
            fontFamily: AppTypography.fontFamily,
            fontFamilyFallback: AppTypography.fontFamilyFallback,
            fontSize: AppTypography.size18,
            fontWeight: AppTypography.semiBold,
            color: AppColors.gray900,
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.gap16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Text(
                'verify.entry.body'.tr(context: context),
                style: TextStyle(
                  fontFamily: AppTypography.fontFamily,
                  fontFamilyFallback: AppTypography.fontFamilyFallback,
                  fontSize: AppTypography.size14,
                  color: AppColors.gray600,
                ),
              ),
              SizedBox(height: AppSpacing.gap16),
              TextField(
                controller: _controller,
                textCapitalization: TextCapitalization.characters,
                decoration: InputDecoration(
                  hintText: 'verify.entry.hint'.tr(context: context),
                  filled: true,
                  fillColor: AppColors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                    borderSide: BorderSide(color: AppColors.gray200),
                  ),
                ),
                onSubmitted: (_) => _submit(),
              ),
              SizedBox(height: AppSpacing.gap16),
              FilledButton(
                onPressed: _submit,
                child: Text('verify.entry.submit'.tr(context: context)),
              ),
              SizedBox(height: AppSpacing.gap12),
              OutlinedButton.icon(
                // Placeholder — "does nothing yet" (task brief). Task 5
                // replaces this with the camera.
                onPressed: () {},
                icon: const LucideIcon(name: 'QrCode'),
                label: Text('verify.entry.scan'.tr(context: context)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
