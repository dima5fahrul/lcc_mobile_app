/// `PasswordStrength` — a 4-bar password strength meter.
///
/// Ported from `AuthPage.tsx`'s strength meter. The score (1-4) mirrors the
/// TS `passStrength` logic:
/// - 4: len >= 12 && has upper && has digit
/// - 3: len >= 10 && has digit
/// - 2: len >= 8
/// - 1: otherwise (weak)
///
/// The label and bar color come from the `auth.strength{Weak,Fair,Good,Strong}`
/// i18n keys and the TS `strengthColors` palette.
library;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// Computes a 1-4 password strength score.
///
/// Ported verbatim from `AuthPage.tsx` `passStrength`.
int passwordStrengthScore(String password) {
  final hasUpper = RegExp(r'[A-Z]').hasMatch(password);
  final hasDigit = RegExp(r'\d').hasMatch(password);
  if (password.length >= 12 && hasUpper && hasDigit) return 4;
  if (password.length >= 10 && hasDigit) return 3;
  if (password.length >= 8) return 2;
  return 1;
}

/// Bar colors per score (index 0 unused). Ported from `strengthColors`.
const List<Color> _strengthColors = [
  Color(0x00000000),
  Color(0xFFEF4444),
  Color(0xFFEF4444),
  Color(0xFFF59E0B),
  Color(0xFF16A34A),
];

/// Text colors per score (index 0 unused). Ported from `strengthTextColors`.
const List<Color> _strengthTextColors = [
  Color(0x00000000),
  Color(0xFFDC2626),
  Color(0xFFDC2626),
  Color(0xFFB45309),
  Color(0xFF15803D),
];

class PasswordStrength extends StatelessWidget {
  const PasswordStrength({super.key, required this.password});

  final String password;

  @override
  Widget build(BuildContext context) {
    if (password.isEmpty) return const SizedBox.shrink();

    final score = passwordStrengthScore(password);
    final labelKey = switch (score) {
      4 => 'auth.strengthStrong',
      3 => 'auth.strengthGood',
      2 => 'auth.strengthFair',
      _ => 'auth.strengthWeak',
    };

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        children: [
          Expanded(
            child: Row(
              children: List.generate(4, (i) {
                final filled = i < score;
                return Expanded(
                  child: Container(
                    margin: const EdgeInsets.only(right: 4),
                    height: 4,
                    decoration: BoxDecoration(
                      color: filled
                          ? _strengthColors[score]
                          : const Color(0xFFE5E7EB),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                );
              }),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            labelKey.tr(),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: _strengthTextColors[score],
            ),
          ),
        ],
      ),
    );
  }
}
