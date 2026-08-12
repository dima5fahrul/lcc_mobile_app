/// `ApiNotice` — a boxed alert for an API result.
///
/// Ported from `AuthPage.tsx`'s `ApiNotice` component. Three tones:
/// - `error`   — red box, for a failed request.
/// - `success`  — green box, for a confirmation (e.g. "OTP resent").
/// - `info`     — brand-blue box, for a neutral notice.
///
/// Renders nothing when `message` is null or empty.
library;

import 'package:flutter/material.dart';

enum ApiNoticeTone { error, success, info }

class ApiNotice extends StatelessWidget {
  const ApiNotice({
    super.key,
    this.message,
    this.tone = ApiNoticeTone.error,
  });

  final String? message;
  final ApiNoticeTone tone;

  @override
  Widget build(BuildContext context) {
    if (message == null || message!.isEmpty) {
      return const SizedBox.shrink();
    }

    final (bg, border, fg, icon) = switch (tone) {
      ApiNoticeTone.error => (
        const Color(0xFFFEF2F2),
        const Color(0xFFFECACA),
        const Color(0xFFDC2626),
        Icons.error_outline,
      ),
      ApiNoticeTone.success => (
        const Color(0xFFF0FDF4),
        const Color(0xFFBBF7D0),
        const Color(0xFF15803D),
        Icons.check_circle_outline,
      ),
      ApiNoticeTone.info => (
        const Color(0xFFEEF2FF),
        const Color(0xFFC7D2FE),
        const Color(0xFF344EAD),
        Icons.info_outline,
      ),
    };

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: fg),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message!,
              style: TextStyle(fontSize: 12, color: fg, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}
