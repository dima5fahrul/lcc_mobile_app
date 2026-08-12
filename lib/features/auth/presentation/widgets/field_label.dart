/// `FieldLabel` — a styled form label.
///
/// Ported from `AuthPage.tsx`'s `FieldLabel` component: a small, semibold,
/// grey label above an input. Kept as a widget so the four auth forms share
/// one visual definition.
library;

import 'package:flutter/material.dart';

class FieldLabel extends StatelessWidget {
  const FieldLabel({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Color(0xFF374151),
        ),
      ),
    );
  }
}
