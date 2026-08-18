/// `FieldLabel` — Marriage `:188-195`, Divorce `:174-181`, byte-identical
/// (Finding K), and **also byte-identical to the kernel's**
/// (`formFields.tsx:40-47`).
///
/// ## Why this is a delegation and not a second implementation
///
/// The two pages each declare their own `FieldLabel` rather than importing
/// `formFields`' — three declarations of one markup string. RULING 1 holds the
/// duplicated helpers **once**; the honest reading of "once" when the kernel
/// already holds an identical one is to mount the kernel's, not to write a
/// third.
///
/// That is not a promotion (§ 6.2 option (b), rejected): nothing moves into
/// `lib/presentation/forms/`, the kernel is unedited (`F3-AC-13`), and no
/// second variant of a kernel widget comes into existence. It is the opposite
/// — the case where the shared set can be **empty of implementation** because
/// the kernel's is already the right one, unlike `SelectField`, whose kernel
/// neighbour differs in exactly four states (§ 6.3).
///
/// The name is declared here so `marriage/` and `divorce/` import the label
/// from `certificate_forms/` like every other control (`F3-AC-20`), and so a
/// future divergence has one place to appear.
library;

import 'package:flutter/widgets.dart';

import '../../../../presentation/forms/widgets/field_label.dart';

class CertificateFieldLabel extends StatelessWidget {
  const CertificateFieldLabel({
    super.key,
    required this.label,
    this.required = false,
  });

  final Widget label;
  final bool required;

  @override
  Widget build(BuildContext context) =>
      FieldLabel(label: label, required: required);
}
