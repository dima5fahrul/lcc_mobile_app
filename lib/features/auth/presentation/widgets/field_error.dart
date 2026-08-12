/// `FieldError` — a red inline error under a form field.
///
/// Ported from `AuthPage.tsx`'s `FieldError` component: returns nothing when
/// `message` is null, a red 12px line otherwise.
library;

import 'package:flutter/material.dart';

class FieldError extends StatelessWidget {
  const FieldError({super.key, this.message});

  final String? message;

  @override
  Widget build(BuildContext context) {
    if (message == null || message!.isEmpty) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Text(
        message!,
        style: const TextStyle(fontSize: 12, color: Color(0xFFEF4444)),
      ),
    );
  }
}
