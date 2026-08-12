/// `CtaButton` — the primary call-to-action.
///
/// Ported from `AuthPage.tsx`'s `CtaButton` component: full-width, brand
/// blue (#344EAD), white text, with a loading spinner when `loading` is true.
library;

import 'package:flutter/material.dart';

class CtaButton extends StatelessWidget {
  const CtaButton({
    super.key,
    required this.label,
    this.loading = false,
    this.onPressed,
  });

  final String label;
  final bool loading;
  final VoidCallback? onPressed;

  static const Color _brand = Color(0xFF344EAD);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: FilledButton(
        onPressed: loading ? null : onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: _brand,
          foregroundColor: Colors.white,
          disabledBackgroundColor: _brand.withValues(alpha: 0.7),
          disabledForegroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: loading
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }
}
