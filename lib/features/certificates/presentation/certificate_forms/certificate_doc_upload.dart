/// `DocUpload` — Marriage `:367-418`, Divorce `:370-421`. The **only** helper
/// Finding K measured as differing, and it differs in exactly two lines:
///
/// ```
/// useT("marriage")  vs  useT("divorce")
/// t("pdfOrImage")   vs  t("uploadHint")
/// ```
///
/// § 6.2's rule attached to option (c): those two are **parameters**, not a
/// reason to fork — and not a reason to unify the two i18n strings either.
/// [uploadDocumentLabel] and [defaultHint] arrive resolved from the page's own
/// namespace, so `marriage.pdfOrImage` and `divorce.uploadHint` stay two
/// distinct keys in two distinct namespaces and neither rendered hint changes
/// (`F3-AC-21`).
///
/// ## R-21 — the ABSENCE of validation is the thing being ported
///
/// Both pages carry `accept="image/*,.pdf"` (Marriage `:388`, Divorce `:391`).
/// In a browser `accept` is a **hint the citizen can override**; in Flutter
/// `FileType.custom` + `allowedExtensions` is a **hard filter with no escape
/// hatch**. Porting it verbatim makes the port stricter than the source, so
/// [CertificateFilePicker]'s default uses `FileType.any` with no
/// `allowedExtensions` — the same prohibition F1 carries
/// (`attachment_accept_policy.dart:22-24`). `F3-AC-98` greps `lib/**`;
/// `F3-AC-99` drives a `.txt` through the picker abstraction and asserts it
/// reaches the attachment list.
///
/// ## Cancel is not removal
///
/// `if (!picked) return;` (`:381`) — dismissing the picker leaves an
/// already-chosen file in place. Only the `X` button calls `onChanged(null)`
/// (`:394`). A port that treated a null pick as a removal would silently drop a
/// document the citizen had already attached.
library;

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../../../presentation/forms/validation/field_error.dart';
import '../../../../presentation/forms/validation/validation_scope.dart';
import '../../../../presentation/icons/lucide_icon.dart';
import '../../../../presentation/theme/app_colors.dart';
import '../../../../presentation/theme/app_spacing.dart';
import '../../../../presentation/theme/app_typography.dart';
import '../../../application/domain/entities/picked_attachment.dart';
import 'certificate_field_label.dart';

/// Opening a picker and getting a file back, as a parameter.
///
/// Null means the citizen cancelled. Injected so `F3-AC-99` can drive a `.txt`
/// without a platform dialog, and so no widget in this directory resolves
/// anything from a locator (`F3-AC-12`).
typedef CertificateFilePicker = Future<PickedAttachment?> Function();

/// The default picker — **no type filter at all**. See R-21 above.
Future<PickedAttachment?> pickCertificateFile() async {
  final FilePickerResult? result = await FilePicker.platform.pickFiles(
    withData: true,
  );
  final PlatformFile? file = result?.files.singleOrNull;
  if (file == null) return null;
  return PickedAttachment(name: file.name, bytes: file.bytes, path: file.path);
}

class CertificateDocUpload extends StatelessWidget {
  const CertificateDocUpload({
    super.key,
    required this.label,
    required this.file,
    required this.onChanged,
    required this.uploadDocumentLabel,
    required this.defaultHint,
    required this.pickFile,
    this.required = false,
    this.hint,
    this.serverError,
  });

  final String label;
  final PickedAttachment? file;

  /// `(f: DocFile | null) => void`. Called with null **only** by the `X`.
  final ValueChanged<PickedAttachment?> onChanged;

  /// `t("uploadDocument")`, resolved by the caller from its own namespace.
  final String uploadDocumentLabel;

  /// `t("pdfOrImage")` on Marriage, `t("uploadHint")` on Divorce — the whole of
  /// the two-line difference Finding K measured, as a parameter.
  final String defaultHint;

  final CertificateFilePicker pickFile;
  final bool required;

  /// `hint ?? t(<defaultHint>)` (`:411`). Per-control override.
  final String? hint;

  final String? serverError;

  Future<void> _pick() async {
    final PickedAttachment? picked = await pickFile();
    // `:381` — cancel is not removal.
    if (picked == null) return;
    onChanged(picked);
  }

  @override
  Widget build(BuildContext context) {
    // `:377` — server first, then the revealed missing-file check.
    final bool hasError = (serverError != null && serverError!.isNotEmpty) ||
        (ValidationScope.showErrorsOf(context) && required && file == null);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        CertificateFieldLabel(label: Text(label), required: required),
        if (file != null)
          _ChosenRow(name: file!.name, onRemove: () => onChanged(null))
        else
          _EmptyBox(
            hasError: hasError,
            title: uploadDocumentLabel,
            hint: hint ?? defaultHint,
            onTap: _pick,
          ),
        FieldErrorText(show: hasError, message: serverError),
      ],
    );
  }
}

/// `:389-399` — the chosen-file row: `border-2 border-green-300 bg-green-50`.
class _ChosenRow extends StatelessWidget {
  const _ChosenRow({required this.name, required this.onRemove});

  final String name;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      // `p-3.5`
      padding: const EdgeInsets.all(AppSpacing.gap14),
      decoration: BoxDecoration(
        color: AppColors.successSoft,
        borderRadius: const BorderRadius.all(
          Radius.circular(AppSpacing.radius2xl),
        ),
        border: Border.all(color: AppColors.green300, width: 2),
      ),
      child: Row(
        children: <Widget>[
          const LucideIcon(
            name: 'CheckCircle2',
            size: AppSpacing.gap20,
            color: AppColors.green600,
          ),
          const SizedBox(width: AppSpacing.gap12),
          Expanded(
            child: Text(
              name,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
              style: const TextStyle(
                fontSize: AppTypography.size14,
                color: AppColors.gray700,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.gap12),
          Semantics(
            button: true,
            child: GestureDetector(
              key: const Key('certificateDocUpload.remove'),
              onTap: onRemove,
              behavior: HitTestBehavior.opaque,
              child: const LucideIcon(
                name: 'X',
                size: AppSpacing.gap16,
                color: AppColors.gray400Inline,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// `:400-414` — the empty dashed box.
class _EmptyBox extends StatelessWidget {
  const _EmptyBox({
    required this.hasError,
    required this.title,
    required this.hint,
    required this.onTap,
  });

  final bool hasError;
  final String title;
  final String hint;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      child: GestureDetector(
        key: const Key('certificateDocUpload.pick'),
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSpacing.gap14),
          decoration: BoxDecoration(
            color: AppColors.gray50,
            borderRadius: const BorderRadius.all(
              Radius.circular(AppSpacing.radius2xl),
            ),
            // `border-2 border-dashed`. Flutter has no dashed border
            // primitive; a solid stroke of the same colour and width is the
            // closest reachable render and is Tier 3's business, not Tier 1's.
            border: Border.all(
              color: hasError ? AppColors.dangerBorder : AppColors.gray200,
              width: 2,
            ),
          ),
          child: Row(
            children: <Widget>[
              Container(
                width: AppSpacing.control40,
                height: AppSpacing.control40,
                decoration: const BoxDecoration(
                  color: AppColors.primarySoft,
                  borderRadius: BorderRadius.all(
                    Radius.circular(AppSpacing.radiusXl),
                  ),
                ),
                child: const Center(
                  child: LucideIcon(
                    name: 'FileText',
                    size: AppSpacing.gap20,
                    color: AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.gap12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(
                      title,
                      // `text-sm font-semibold text-gray-600`
                      style: const TextStyle(
                        fontSize: AppTypography.size14,
                        fontWeight: AppTypography.semiBold,
                        color: AppColors.gray600,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.gap2),
                    Text(
                      hint,
                      // `text-xs text-gray-400`
                      style: const TextStyle(
                        fontSize: AppTypography.size12,
                        color: AppColors.gray400Inline,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
