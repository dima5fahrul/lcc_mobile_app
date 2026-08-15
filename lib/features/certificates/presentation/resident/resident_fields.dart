/// `ResidentCertificatePage.tsx:162-316` — the four components the page
/// declares for itself, before the main function begins.
///
/// ## Why these are here and not in the kernel
///
/// `InputField` (`:173`) and `UploadBox` (`:201`) are declared **per page** in
/// the source — Resident's at `:173`/`:201`, Marriage's in its own file — and
/// F0b did not lift either into `lib/presentation/forms/widgets/`. It lifted
/// what the pages share *identically*: `fieldDecoration`, `FieldLabel`,
/// `FieldErrorText`, `fieldErrorRing`. This file splices those four together
/// the way `:187-196` splices `fieldBase` and `fieldErrorRing`.
///
/// **That is a boundary, not an oversight.** Lifting `InputField` now would be
/// a kernel edit made to serve one page, and `F1-AC-9` exists because a kernel
/// changed to make the pilot work destroys the information F1 was built to
/// produce. If F2 finds Birth's `InputField` byte-identical to this one, *that*
/// is the evidence for lifting it, and it is F2's finding to make.
///
/// ## R-21 lives here
///
/// [ResidentUploadBox] takes a [ResidentFilePicker] **function**, and there is
/// no extension, MIME or size test anywhere in this file. The web's
/// `accept="image/*"` (`:226`) filters the picker's default view and rejects
/// nothing; a `.pdf` chosen anyway reaches `onChange` unexamined (`:213-221`).
/// Injecting the picker is what makes that assertable without a device
/// (`F1-AC-43`) — the criterion is behavioural and picker-agnostic by
/// construction.
library;

import 'dart:typed_data';

import 'package:easy_localization/easy_localization.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../../../presentation/forms/validation/field_error.dart';
import '../../../../presentation/forms/validation/validation_scope.dart';
import '../../../../presentation/forms/widgets/field_base.dart';
import '../../../../presentation/forms/widgets/field_label.dart';
import '../../../../presentation/icons/lucide_icon.dart';
import '../../../../presentation/theme/app_colors.dart';
import '../../../application/domain/entities/picked_attachment.dart';
import 'resident_form_state.dart';

/// What opening a picker and getting a file back looks like, as a parameter.
///
/// Null means the citizen cancelled — `if (!picked) return;` (`:215`), which is
/// **not** the same as removing an already-chosen file and must not run
/// `onChange(null)`.
typedef ResidentFilePicker = Future<PickedAttachment?> Function();

/// The default picker: `file_picker`, with **no type filter at all**.
///
/// `FileType.any` and no `allowedExtensions` — the two together are R-21
/// (`specs.md` § 6.7). `AttachmentAcceptPolicy.resident` is `'image/*'` and is
/// **data for Tier 1 to compare against**, never an argument to this call
/// (`attachment_accept_policy.dart:22-24`).
Future<PickedAttachment?> pickResidentFile() async {
  final FilePickerResult? result = await FilePicker.platform.pickFiles(
    // `withData` because the multipart POST streams bytes and the web target
    // has no path — `picked_attachment.dart` records why `bytes` is the half
    // that matters.
    withData: true,
  );
  final PlatformFile? file = result?.files.singleOrNull;
  if (file == null) return null;
  return PickedAttachment(
    name: file.name,
    bytes: file.bytes,
    path: file.path,
  );
}

/// `:173-199` — `InputField`.
class ResidentInputField extends StatefulWidget {
  const ResidentInputField({
    super.key,
    required this.label,
    required this.value,
    required this.placeholder,
    required this.onChanged,
    this.required = false,
    this.numeric = false,
    this.maxLength,
    this.path,
  });

  final String label;
  final String value;
  final String placeholder;
  final ValueChanged<String> onChanged;
  final bool required;

  /// `inputMode="numeric"` (`:189`). A keyboard hint, **not** a filter: the
  /// `age` field's digit strip is in its `onChange` (`:820`) and is the cubit's.
  final bool numeric;
  final int? maxLength;

  /// The `form_data` key, so a 422 lands on this field. Null on exactly one
  /// control — `purposeOther` (`:1009-1016`).
  final String? path;

  @override
  State<ResidentInputField> createState() => _ResidentInputFieldState();
}

class _ResidentInputFieldState extends State<ResidentInputField> {
  late final TextEditingController _controller =
      TextEditingController(text: widget.value);
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_onFocusChanged);
  }

  void _onFocusChanged() => setState(() {});

  @override
  void didUpdateWidget(ResidentInputField oldWidget) {
    super.didUpdateWidget(oldWidget);
    // The cubit owns the value and two fields transform it on the way in
    // (`age`, `purposeOther`), so the controller is corrected when the value
    // that comes back differs from what was typed — the caret pinned to the
    // end, which is what a React controlled input does for free.
    if (widget.value != _controller.text) {
      _controller.value = TextEditingValue(
        text: widget.value,
        selection: TextSelection.collapsed(offset: widget.value.length),
      );
    }
  }

  @override
  void dispose() {
    _focusNode
      ..removeListener(_onFocusChanged)
      ..dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // `useFieldError({ path, required, value })` — `:182`. A server message
    // wins outright; the local blank check is consulted only in its absence.
    final FieldErrorState error = ValidationScope.fieldErrorOf(
      context,
      path: widget.path,
      required: widget.required,
      value: widget.value,
    );
    final void Function(String?) clearServerError =
        ValidationScope.clearServerErrorOf(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        FieldLabel(label: Text(widget.label), required: widget.required),
        FieldErrorMarker(
          focusNode: _focusNode,
          child: Container(
            decoration: fieldDecoration(
              hasError: error.hasError,
              focused: _focusNode.hasFocus,
            ),
            child: TextField(
              controller: _controller,
              focusNode: _focusNode,
              maxLength: widget.maxLength,
              buildCounter: (
                BuildContext context, {
                required int currentLength,
                required bool isFocused,
                required int? maxLength,
              }) =>
                  null,
              keyboardType:
                  widget.numeric ? TextInputType.number : TextInputType.text,
              style: kFieldTextStyle,
              decoration: InputDecoration(
                isDense: true,
                border: InputBorder.none,
                contentPadding: kFieldPadding,
                hintText: widget.placeholder,
                hintStyle: kFieldPlaceholderStyle,
              ),
              // `onChange={(e) => { clearServerError(path); onChange(...); }}`
              // — `:192`, in that order.
              onChanged: (String v) {
                clearServerError(widget.path);
                widget.onChanged(v);
              },
            ),
          ),
        ),
        FieldErrorText(
          show: error.hasError,
          message: error.message,
          focusNode: _focusNode,
        ),
      ],
    );
  }
}

/// `:201-264` — `UploadBox`.
class ResidentUploadBox extends StatelessWidget {
  const ResidentUploadBox({
    super.key,
    required this.label,
    required this.sublabel,
    required this.file,
    required this.onChanged,
    this.required = true,
    this.height = 160,
    this.path,
    this.pickFile = pickResidentFile,
  });

  final String label;
  final String sublabel;
  final PickedAttachment? file;

  /// Null means **removed**, which on the front-ID control is the one path that
  /// blanks the applicant block (`:415-425`).
  final ValueChanged<PickedAttachment?> onChanged;

  /// `required = true` is the source's **default** (`:202`), which is why the
  /// two family-book boxes and the two ID boxes get the asterisk without
  /// passing anything.
  final bool required;

  /// `h-40` = 160, `h-48` = 192 (`:202`, `:847`).
  final double height;
  final String? path;

  /// Injected so R-21 is assertable without a device (`F1-AC-43`).
  final ResidentFilePicker pickFile;

  @override
  Widget build(BuildContext context) {
    // `useFieldError({ path, required, value: file })` — `:210`. The value is
    // the **file**, so `isEmpty(null)` is what makes an unchosen upload an
    // error and a chosen one not (`is_empty.dart:20`).
    final FieldErrorState error = ValidationScope.fieldErrorOf(
      context,
      path: path,
      required: required,
      value: file,
    );
    final void Function(String?) clearServerError =
        ValidationScope.clearServerErrorOf(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        FieldLabel(label: Text(label), required: required),
        FieldErrorMarker(
          child: file == null
              ? _empty(context, error.hasError, clearServerError)
              : _filled(context, file!),
        ),
        FieldErrorText(show: error.hasError, message: error.message),
      ],
    );
  }

  /// `:246-260` — the dashed drop target.
  Widget _empty(
    BuildContext context,
    bool hasError,
    void Function(String?) clearServerError,
  ) {
    return Semantics(
      button: true,
      label: label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () async {
          final PickedAttachment? picked = await pickFile();
          // `if (!picked) return;` — `:215`. A cancelled picker changes
          // nothing; it is NOT the removal branch.
          if (picked == null) return;
          clearServerError(path);
          onChanged(picked);
        },
        child: Container(
          height: height,
          decoration: BoxDecoration(
            color: AppColors.gray50,
            borderRadius: kFieldRadius,
            border: Border.all(
              color: hasError ? AppColors.danger : AppColors.gray200,
              width: 2,
              strokeAlign: BorderSide.strokeAlignInside,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Container(
                width: 56,
                height: 56,
                decoration: const BoxDecoration(
                  // `style={{ backgroundColor: "#EEF2FF" }}` — `:252`.
                  color: AppColors.primarySoft,
                  borderRadius: kFieldRadius,
                ),
                // `Camera` — **substituted**: `Camera.svg` is not among the 89
                // glyphs in `assets/icons/lucide/` and `assets/**` is not one
                // of specs.md § 3.1's rows. Recorded, not silently absorbed.
                child: const Center(
                  child: LucideIcon(
                    name: 'IdCard',
                    size: 28,
                    color: AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'resident.uploadTap'.tr(context: context),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.gray500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                sublabel,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.gray400Inline,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// `:228-245` — the chosen file, its thumbnail and the remove button.
  Widget _filled(BuildContext context, PickedAttachment picked) {
    final Uint8List? bytes = picked.bytes;

    return ClipRRect(
      borderRadius: kFieldRadius,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.successSoft,
          borderRadius: kFieldRadius,
          border: Border.all(color: AppColors.successBorder, width: 2),
        ),
        child: Stack(
          children: <Widget>[
            SizedBox(
              height: height,
              width: double.infinity,
              // `file.preview ? <img> : <Camera/>` — `:229-232`. Bytes that are
              // not a decodable image land in `errorBuilder`, which is the same
              // observable as a `FileReader` that produced no preview: the
              // glyph. **A `.pdf` still shows its filename and still uploads**
              // (R-21).
              child: bytes == null || bytes.isEmpty
                  ? const Center(
                      child: LucideIcon(
                        name: 'FileText',
                        size: 32,
                        color: AppColors.success,
                      ),
                    )
                  : Image.memory(
                      bytes,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Center(
                        child: LucideIcon(
                          name: 'FileText',
                          size: 32,
                          color: AppColors.success,
                        ),
                      ),
                    ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: const BoxDecoration(
                  // `bg-gradient-to-t from-black/60` — `:233`.
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: <Color>[
                      AppColors.uploadCaptionScrim,
                      AppColors.transparent,
                    ],
                  ),
                ),
                child: Row(
                  children: <Widget>[
                    const LucideIcon(
                      name: 'CheckCircle',
                      size: 16,
                      color: AppColors.success,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        picked.name,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.white,
                        ),
                      ),
                    ),
                    Semantics(
                      button: true,
                      label: picked.name,
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        // `onClick={() => { onChange(null); … }}` — `:239`.
                        // **This** is the removal branch.
                        onTap: () => onChanged(null),
                        child: const Padding(
                          padding: EdgeInsets.all(4),
                          child: LucideIcon(
                            name: 'X',
                            size: 16,
                            // `text-white/70` — `:240`.
                            color: AppColors.uploadRemoveGlyph,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// `:266-302` — the six-dot progress rail.
class ResidentStepIndicator extends StatelessWidget {
  const ResidentStepIndicator({super.key, required this.step});

  final int step;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Row(
        children: <Widget>[
          for (final int id in kResidentStepIds) ...<Widget>[
            _dot(id),
            if (id != kResidentStepIds.last) Expanded(child: _bar(id)),
          ],
        ],
      ),
    );
  }

  Widget _dot(int id) {
    final bool done = step > id;
    final bool active = step == id;
    return Opacity(
      // `opacity: done ? 0.55 : 1` — `:282`.
      opacity: done ? 0.55 : 1,
      child: Container(
        width: 32,
        height: 32,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: done || active ? AppColors.primary : AppColors.gray100,
        ),
        child: done
            ? const LucideIcon(name: 'Check', size: 14, color: AppColors.white)
            : Text(
                '$id',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: done || active
                      ? AppColors.white
                      : AppColors.gray400Inline,
                ),
              ),
      ),
    );
  }

  Widget _bar(int id) => Opacity(
        // `opacity: step > id ? 0.4 : 1` — `:292`.
        opacity: step > id ? 0.4 : 1,
        child: Container(
          height: 2,
          margin: const EdgeInsets.symmetric(horizontal: 6),
          decoration: BoxDecoration(
            color: step > id ? AppColors.primary : AppColors.gray200,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      );
}

/// `:304-316` — `StepHeader`.
class ResidentStepHeader extends StatelessWidget {
  const ResidentStepHeader({super.key, required this.step});

  final int step;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          // `t("stepOf", { n: step, m: STEP_COUNT })` — `:310`.
          'resident.stepOf'.tr(
            context: context,
            namedArgs: <String, String>{
              'n': '$step',
              'm': '$kResidentStepCount',
            },
          ).toUpperCase(),
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.1,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          // `t(\`step${step}Title\`)` — `:312`.
          'resident.step${step}Title'.tr(context: context),
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.gray900,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          'resident.step${step}Subtitle'.tr(context: context),
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.gray400Inline,
          ),
        ),
      ],
    );
  }
}

/// `:718-723`, `:898-903` — the two coloured notice panels, and `:708-713`'s
/// red one. Three fills, one shape.
class ResidentNotice extends StatelessWidget {
  const ResidentNotice({
    super.key,
    required this.text,
    required this.fill,
    required this.border,
    required this.foreground,
    required this.icon,
  });

  const ResidentNotice.amber({Key? key, required String text})
      : this(
          key: key,
          text: text,
          fill: AppColors.warningSurface,
          border: AppColors.warningOutline,
          foreground: AppColors.warning,
          icon: 'AlertCircle',
        );

  const ResidentNotice.blue({Key? key, required String text})
      : this(
          key: key,
          text: text,
          fill: AppColors.primarySoft,
          border: AppColors.primarySoft,
          foreground: AppColors.primary,
          icon: 'AlertCircle',
        );

  const ResidentNotice.red({Key? key, required String text})
      : this(
          key: key,
          text: text,
          fill: AppColors.dangerSoft,
          border: AppColors.dangerSoft,
          foreground: AppColors.danger,
          icon: 'AlertCircle',
        );

  /// `:799-804` — the green `autoFilledNotice` banner.
  ///
  /// **Rendered unconditionally on step 2** (`specs.md` § 6.4(d)). The icon is
  /// `Sparkles` in the source and **substituted** here for the same
  /// asset-registry reason recorded above.
  const ResidentNotice.green({Key? key, required String text})
      : this(
          key: key,
          text: text,
          fill: AppColors.successSoft,
          border: AppColors.successBorder,
          foreground: AppColors.success,
          icon: 'BadgeCheck',
        );

  final String text;
  final Color fill;
  final Color border;
  final Color foreground;
  final String icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: fill,
        borderRadius: kFieldRadius,
        border: Border.all(color: border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: LucideIcon(name: icon, size: 16, color: foreground),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontSize: 12, height: 1.6, color: foreground),
            ),
          ),
        ],
      ),
    );
  }
}
