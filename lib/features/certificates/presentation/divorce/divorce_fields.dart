/// `SpouseSection` — `DivorceCertificatePage.tsx:460-530` — plus the page's
/// `TextAreaField`, its notes and its review card.
///
/// ## `TextAreaField` lives HERE, not in `certificate_forms/`
///
/// `:209-230` declares it and **Marriage has no analogue**. Finding K's eleven
/// are the helpers duplicated between the two pages; this one is not among
/// them, and § 6.2 admits into the shared directory only what was measured as
/// duplicated *and* semantically identical. A single-consumer control promoted
/// into a shared set is how a batch-scoped helper becomes a permanent global
/// one.
///
/// ## The husband and wife sections are ONE widget, twice
///
/// `:1387`, `:1405`. Seven fields, **no gender** — `DivorceSpouseInfo` has no
/// such field and no control can bind to one (`F3-AC-68`).
library;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../presentation/forms/validation/field_error.dart';
import '../../../../presentation/forms/validation/is_empty.dart';
import '../../../../presentation/forms/validation/validation_scope.dart';
import '../../../../presentation/forms/widgets/field_base.dart';
import '../../../../presentation/icons/lucide_icon.dart';
import '../../../../presentation/theme/app_colors.dart';
import '../../../../presentation/theme/app_spacing.dart';
import '../../../../presentation/theme/app_typography.dart';
import '../certificate_forms/certificate_dated_field.dart';
import '../certificate_forms/certificate_field_label.dart';
import '../certificate_forms/certificate_input_field.dart';
import '../certificate_forms/certificate_location_fields.dart';
import '../certificate_forms/certificate_location_value.dart';
import '../certificate_forms/certificate_ref_list.dart';
import '../certificate_forms/certificate_section_label.dart';
import '../certificate_forms/certificate_select_field.dart';
import 'divorce_form_cubit.dart';
import 'divorce_form_state.dart';

String _t(BuildContext c, String key) => 'divorce.$key'.tr(context: c);

/// `:460-530` — one spouse's section. Seven controls, no gender.
class DivorceSpouseSection extends StatelessWidget {
  const DivorceSpouseSection({
    super.key,
    required this.value,
    required this.onChanged,
    required this.nationalities,
    required this.serverErrors,
    required this.provinces,
    required this.cascade,
    required this.onAddressChanged,
  });

  final DivorceSpouseInfo value;
  final ValueChanged<DivorceSpouseInfo> onChanged;
  final CertificateRefList nationalities;
  final Map<String, String> serverErrors;

  final CertificateLocationLevel provinces;
  final DivorceCascadeState cascade;
  final ValueChanged<CertificateLocationValue> onAddressChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        CertificateInputField(
          label: _t(context, 'fullName'),
          value: value.fullName,
          placeholder: _t(context, 'fullNamePlaceholder'),
          onChanged: (String v) => onChanged(value.copyWith(fullName: v)),
          required: true,
          serverError: serverErrors['spouses.name'],
        ),
        const SizedBox(height: AppSpacing.gap12),
        // `:478-495` — dob and NATIONALITY share the two-column row. Marriage
        // puts gender in that slot; this page has none.
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Expanded(
              child: CertificateDatedField(
                label: _t(context, 'dob'),
                value: value.dob,
                onChanged: (String v) => onChanged(value.copyWith(dob: v)),
                required: true,
                serverError: serverErrors['spouses.dob'],
              ),
            ),
            const SizedBox(width: AppSpacing.gap12),
            Expanded(
              child: CertificateSelectField(
                label: _t(context, 'nationality'),
                value: value.nationality,
                options: nationalities.options,
                placeholder: _t(context, 'selectPlaceholder'),
                onChanged: (String v) =>
                    onChanged(value.copyWith(nationality: v)),
                required: true,
                serverError: serverErrors['spouses.nationality'],
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.gap12),
        CertificateInputField(
          label: _t(context, 'idOrPassport'),
          value: value.idOrPassport,
          placeholder: _t(context, 'idOrPassportPlaceholder'),
          onChanged: (String v) => onChanged(value.copyWith(idOrPassport: v)),
          required: true,
          serverError: serverErrors['spouses.id_number'],
        ),
        const SizedBox(height: AppSpacing.gap12),
        CertificateSectionLabel(text: _t(context, 'currentAddress')),
        const SizedBox(height: AppSpacing.gap12),
        CertificateInputField(
          label: _t(context, 'houseNo'),
          value: value.addrHouseNo,
          placeholder: _t(context, 'houseNoPlaceholder'),
          onChanged: (String v) => onChanged(value.copyWith(addrHouseNo: v)),
        ),
        const SizedBox(height: AppSpacing.gap12),
        CertificateLocationFields(
          value: value.address,
          onChanged: onAddressChanged,
          provinces: provinces,
          districts: cascade.districts,
          villages: cascade.villages,
          villageLabel: _t(context, 'villageLabel'),
          required: true,
          serverError: serverErrors['spouses.current_address'],
        ),
        const SizedBox(height: AppSpacing.gap12),
        CertificateInputField(
          label: _t(context, 'marriageCertRef'),
          value: value.marriageCertRef,
          placeholder: _t(context, 'marriageCertRefPlaceholder'),
          onChanged: (String v) =>
              onChanged(value.copyWith(marriageCertRef: v)),
          required: true,
          serverError: serverErrors['spouses.marriage_certificate_ref'],
        ),
      ],
    );
  }
}

/// `TextAreaField` — `:209-230`. **Divorce only.**
///
/// Identical to `InputField` except `rows={3}` and `resize-none`. The error
/// rule is the same: `Boolean(serverError) || (showErrors && required &&
/// isEmpty(value))`, server first.
class DivorceTextAreaField extends StatefulWidget {
  const DivorceTextAreaField({
    super.key,
    required this.label,
    required this.value,
    required this.placeholder,
    required this.onChanged,
    this.required = false,
    this.serverError,
  });

  final String label;
  final String value;
  final String placeholder;
  final ValueChanged<String> onChanged;
  final bool required;
  final String? serverError;

  @override
  State<DivorceTextAreaField> createState() => _DivorceTextAreaFieldState();
}

class _DivorceTextAreaFieldState extends State<DivorceTextAreaField> {
  late final TextEditingController _c =
      TextEditingController(text: widget.value);
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_onFocus);
  }

  void _onFocus() => setState(() {});

  @override
  void didUpdateWidget(DivorceTextAreaField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != _c.text) {
      _c.value = TextEditingValue(
        text: widget.value,
        selection: TextSelection.collapsed(offset: widget.value.length),
      );
    }
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocus);
    _focusNode.dispose();
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool hasError =
        (widget.serverError != null && widget.serverError!.isNotEmpty) ||
            (ValidationScope.showErrorsOf(context) &&
                widget.required &&
                isEmpty(widget.value));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        CertificateFieldLabel(
          label: Text(widget.label),
          required: widget.required,
        ),
        Container(
          decoration: fieldDecoration(
            hasError: hasError,
            focused: _focusNode.hasFocus,
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.gap16,
            vertical: AppSpacing.gap12,
          ),
          child: TextField(
            controller: _c,
            focusNode: _focusNode,
            onChanged: widget.onChanged,
            // `rows={3}` and `resize-none` — a fixed three-line box.
            minLines: 3,
            maxLines: 3,
            style: kFieldTextStyle,
            decoration: InputDecoration.collapsed(
              hintText: widget.placeholder,
              hintStyle: kFieldPlaceholderStyle,
            ),
          ),
        ),
        FieldErrorText(
          show: hasError,
          message: widget.serverError,
          focusNode: _focusNode,
        ),
      ],
    );
  }
}

/// The coloured note panels — the same four tones Marriage has, declared
/// separately because the two pages are two independent transcriptions.
enum DivorceNoteTone { blue, amber, red, grey }

class DivorceNote extends StatelessWidget {
  const DivorceNote({
    super.key,
    required this.text,
    required this.tone,
    required this.icon,
  });

  final String text;
  final DivorceNoteTone tone;
  final String icon;

  @override
  Widget build(BuildContext context) {
    final (Color bg, Color border, Color fg) = switch (tone) {
      DivorceNoteTone.blue => (
          AppColors.primarySoft,
          AppColors.infoBorder,
          AppColors.primary,
        ),
      DivorceNoteTone.amber => (
          AppColors.warningSurface,
          AppColors.warningOutline,
          AppColors.warning,
        ),
      DivorceNoteTone.red => (
          AppColors.dangerSoft,
          AppColors.dangerOutline,
          AppColors.danger,
        ),
      DivorceNoteTone.grey => (
          AppColors.gray100,
          AppColors.gray200,
          AppColors.muted,
        ),
    };

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.gap16),
      decoration: BoxDecoration(
        color: bg,
        borderRadius:
            const BorderRadius.all(Radius.circular(AppSpacing.radius2xl)),
        border: Border.all(color: border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.gap2),
            child: LucideIcon(name: icon, size: AppSpacing.gap16, color: fg),
          ),
          const SizedBox(width: AppSpacing.gap10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontSize: AppTypography.size12, color: fg),
            ),
          ),
        ],
      ),
    );
  }
}

/// One review card — `:1527-1536`.
class DivorceReviewCard extends StatelessWidget {
  const DivorceReviewCard({
    super.key,
    required this.title,
    required this.rows,
  });

  final String title;
  final List<(String, String)> rows;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.gap16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius:
            const BorderRadius.all(Radius.circular(AppSpacing.radius2xl)),
        border: Border.all(color: AppColors.gray100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          CertificateSectionLabel(text: title),
          for (final (String, String) row in rows)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.gap10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    row.$1,
                    style: const TextStyle(
                      fontSize: AppTypography.size14,
                      color: AppColors.muted,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.gap12),
                  Expanded(
                    child: Text(
                      row.$2,
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                        fontSize: AppTypography.size14,
                        fontWeight: AppTypography.medium,
                        color: AppColors.gray800,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
