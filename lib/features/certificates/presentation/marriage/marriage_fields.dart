/// `SpouseSection` — `MarriageCertificatePage.tsx:464-623` — and the small
/// page-family pieces the steps share.
///
/// **Spouse A and Spouse B are the SAME widget, twice** (`:1387`, `:1407`),
/// parameterised only by the value, the patch callback and the
/// previously-married toggle. That is the source's structure and it is kept:
/// two hand-copied sections would be two places for the two spouses to
/// silently diverge, and the mirror in `buildFormData` already discards B in
/// six of seven keys — the one asymmetry the port must reproduce lives in the
/// payload, not in the form.
///
/// Every control comes from `certificate_forms/` (`F3-AC-20`). Nothing here
/// resolves a locator; the cubit hands the reference lists and cascade levels
/// down as parameters.
library;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../presentation/forms/widgets/option.dart';
import '../../../../presentation/icons/lucide_icon.dart';
import '../../../../presentation/theme/app_colors.dart';
import '../../../../presentation/theme/app_spacing.dart';
import '../../../../presentation/theme/app_typography.dart';
import '../../../application/domain/entities/picked_attachment.dart';
import '../../domain/submission/gender_values.dart';
import '../certificate_forms/certificate_dated_field.dart';
import '../certificate_forms/certificate_doc_upload.dart';
import '../certificate_forms/certificate_input_field.dart';
import '../certificate_forms/certificate_location_fields.dart';
import '../certificate_forms/certificate_location_value.dart';
import '../certificate_forms/certificate_ref_list.dart';
import '../certificate_forms/certificate_section_label.dart';
import '../certificate_forms/certificate_select_field.dart';
import '../certificate_forms/certificate_toggle_row.dart';
import 'marriage_form_cubit.dart';
import 'marriage_form_state.dart';

String _t(BuildContext c, String key) => 'marriage.$key'.tr(context: c);

/// The four reference lists `SpouseRefs` carries (`:457-462`).
class MarriageSpouseRefs {
  const MarriageSpouseRefs({
    required this.nationalities,
    required this.ethnicities,
    required this.ethnicGroups,
    required this.religions,
  });

  final CertificateRefList nationalities;
  final CertificateRefList ethnicities;
  final CertificateRefList ethnicGroups;
  final CertificateRefList religions;
}

/// `:464-623` — one spouse's whole section.
class MarriageSpouseSection extends StatelessWidget {
  const MarriageSpouseSection({
    super.key,
    required this.value,
    required this.onChanged,
    required this.prevMarried,
    required this.onTogglePrevMarried,
    required this.refs,
    required this.serverErrors,
    required this.provinces,
    required this.cascade,
    required this.onAddressChanged,
    required this.pickFile,
  });

  final MarriageSpouseInfo value;
  final ValueChanged<MarriageSpouseInfo> onChanged;
  final bool prevMarried;
  final VoidCallback onTogglePrevMarried;
  final MarriageSpouseRefs refs;
  final Map<String, String> serverErrors;

  final CertificateLocationLevel provinces;
  final MarriageCascadeState cascade;
  final ValueChanged<CertificateLocationValue> onAddressChanged;
  final CertificateFilePicker pickFile;

  @override
  Widget build(BuildContext context) {
    // `:473` — non-empty AND not "lao". A stateless spouse is foreign.
    final bool isForeign = marriageIsForeign(value.nationality);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        CertificateInputField(
          label: _t(context, 'fullName'),
          value: value.fullName,
          placeholder: _t(context, 'fullNamePh'),
          onChanged: (String v) => onChanged(value.copyWith(fullName: v)),
          required: true,
          serverError: serverErrors['spouses.name'],
        ),
        const SizedBox(height: AppSpacing.gap12),
        // `:484-501` — `grid grid-cols-2 gap-3`: date of birth and gender.
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Expanded(
              child: MarriageDatedField(
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
                label: _t(context, 'gender'),
                value: value.gender,
                // **BARE ENGLISH LABELS, under `lo` too** — `:134-137`. This is
                // a reproduced source defect (`F3-AC-67`); a Lao rendering the
                // web does not have is `L-10`(b) and a Tier 1 failure.
                options: marriageGenderOptions,
                placeholder: _t(context, 'selectPh'),
                onChanged: (String v) => onChanged(value.copyWith(gender: v)),
                required: true,
                serverError: serverErrors['spouses.gender'],
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.gap12),
        CertificateSelectField(
          label: _t(context, 'nationality'),
          value: value.nationality,
          options: refs.nationalities.options,
          placeholder: _t(context, 'selectPh'),
          onChanged: (String v) => onChanged(value.copyWith(nationality: v)),
          required: true,
          serverError: serverErrors['spouses.nationality'],
        ),
        const SizedBox(height: AppSpacing.gap12),
        CertificateInputField(
          label: _t(context, 'idOrPassport'),
          value: value.idOrPassport,
          placeholder: _t(context, 'idOrPassportPh'),
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
          placeholder: _t(context, 'houseNoPh'),
          onChanged: (String v) => onChanged(value.copyWith(addrHouseNo: v)),
        ),
        const SizedBox(height: AppSpacing.gap12),
        CertificateLocationFields(
          value: value.address,
          onChanged: onAddressChanged,
          provinces: provinces,
          districts: cascade.districts,
          villages: cascade.villages,
          // `:529` — the spouse address passes `t("village")`; the step-1
          // header passes nothing and falls through to `fields.village`.
          villageLabel: _t(context, 'village'),
          required: true,
          serverError: serverErrors['spouses.current_address'],
        ),
        const SizedBox(height: AppSpacing.gap12),
        CertificateInputField(
          label: _t(context, 'residenceCertRef'),
          value: value.residenceCertRef,
          placeholder: _t(context, 'residenceCertRefPh'),
          onChanged: (String v) =>
              onChanged(value.copyWith(residenceCertRef: v)),
          required: true,
          serverError: serverErrors['spouses.residence_certificate_ref'],
        ),

        const SizedBox(height: AppSpacing.gap12),
        CertificateSectionLabel(text: _t(context, 'documents')),
        const SizedBox(height: AppSpacing.gap12),
        CertificateDocUpload(
          label: _t(context, 'singleStatusCert'),
          file: value.singleStatusCert,
          onChanged: (PickedAttachment? f) => onChanged(
            value.copyWith(singleStatusCert: f, clearSingleStatusCert: f == null),
          ),
          uploadDocumentLabel: _t(context, 'uploadDocument'),
          defaultHint: _t(context, 'pdfOrImage'),
          pickFile: pickFile,
          required: true,
          serverError: serverErrors['spouses.single_status_certificate'],
        ),

        // `:552-567` — previously married → prior marital proof.
        const SizedBox(height: AppSpacing.gap12),
        CertificateToggleRow(
          active: prevMarried,
          onToggle: onTogglePrevMarried,
          title: _t(context, 'prevMarried'),
          hint: _t(context, 'prevMarriedHint'),
        ),
        if (prevMarried) ...<Widget>[
          const SizedBox(height: AppSpacing.gap12),
          CertificateDocUpload(
            label: _t(context, 'priorMaritalProof'),
            file: value.priorMaritalProof,
            onChanged: (PickedAttachment? f) => onChanged(
              value.copyWith(
                priorMaritalProof: f,
                clearPriorMaritalProof: f == null,
              ),
            ),
            uploadDocumentLabel: _t(context, 'uploadDocument'),
            defaultHint: _t(context, 'pdfOrImage'),
            pickFile: pickFile,
            required: true,
            serverError: serverErrors['spouses.prior_marital_proof'],
          ),
        ],

        // `:569-587` — foreign spouse → the amber note and an extra upload.
        if (isForeign) ...<Widget>[
          const SizedBox(height: AppSpacing.gap12),
          MarriageNote(
            text: _t(context, 'foreignSpouseNote'),
            tone: MarriageNoteTone.amber,
            icon: 'Globe2',
          ),
          const SizedBox(height: AppSpacing.gap12),
          CertificateDocUpload(
            label: _t(context, 'foreignDocs'),
            file: value.foreignDocs,
            onChanged: (PickedAttachment? f) => onChanged(
              value.copyWith(foreignDocs: f, clearForeignDocs: f == null),
            ),
            uploadDocumentLabel: _t(context, 'uploadDocument'),
            defaultHint: _t(context, 'pdfOrImage'),
            // `:583` — this one control overrides the namespace default.
            hint: _t(context, 'foreignDocsHint'),
            pickFile: pickFile,
            required: true,
            serverError: serverErrors['spouses.foreign_documents'],
          ),
        ],

        // `:589-620` — the four OPTIONAL reference selects. None is `required`,
        // and none renders a load state (§ 6.3(i)).
        const SizedBox(height: AppSpacing.gap12),
        CertificateSectionLabel(text: _t(context, 'additionalDetails')),
        const SizedBox(height: AppSpacing.gap12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Expanded(
              child: CertificateSelectField(
                label: _t(context, 'ethnicity'),
                value: value.ethnicity,
                options: refs.ethnicities.options,
                placeholder: _t(context, 'selectPh'),
                onChanged: (String v) => onChanged(value.copyWith(ethnicity: v)),
              ),
            ),
            const SizedBox(width: AppSpacing.gap12),
            Expanded(
              child: CertificateSelectField(
                label: _t(context, 'religion'),
                value: value.religion,
                options: refs.religions.options,
                placeholder: _t(context, 'selectPh'),
                onChanged: (String v) => onChanged(value.copyWith(religion: v)),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.gap12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Expanded(
              child: CertificateSelectField(
                label: _t(context, 'ethnicGroup'),
                value: value.ethnicGroup,
                options: refs.ethnicGroups.options,
                placeholder: _t(context, 'selectPh'),
                onChanged: (String v) =>
                    onChanged(value.copyWith(ethnicGroup: v)),
              ),
            ),
            const SizedBox(width: AppSpacing.gap12),
            Expanded(
              child: CertificateInputField(
                label: _t(context, 'occupation'),
                value: value.occupation,
                placeholder: _t(context, 'occupationPh'),
                onChanged: (String v) =>
                    onChanged(value.copyWith(occupation: v)),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// `GENDERS` as the select's option list — `:134-137`.
///
/// The **values** come from `kGenderWireValues` (shared with Birth and Death,
/// because the wire values and their order genuinely are the same); the
/// **labels** are this page's bare English literals and are not shared, because
/// Death's are bilingual and Birth's are i18n keys (`gender_values.dart`).
final List<Option> marriageGenderOptions = <Option>[
  for (int i = 0; i < kGenderWireValues.length; i++)
    Option(value: kGenderWireValues[i], label: kMarriageGenderLabels[i]),
];

/// `DatedField` at Marriage's call sites — the shared control, with the page's
/// namespace already resolved. A thin alias so the steps read like the source.
class MarriageDatedField extends StatelessWidget {
  const MarriageDatedField({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.required = false,
    this.serverError,
  });

  final String label;
  final String value;
  final ValueChanged<String> onChanged;
  final bool required;
  final String? serverError;

  @override
  Widget build(BuildContext context) => CertificateDatedField(
        label: label,
        value: value,
        onChanged: onChanged,
        required: required,
        serverError: serverError,
      );
}

/// The four coloured note panels the page renders — blue (`#EEF2FF`-family),
/// amber, red and grey. One widget because the markup is identical and only the
/// three colours and the glyph change.
enum MarriageNoteTone { blue, amber, red, grey }

class MarriageNote extends StatelessWidget {
  const MarriageNote({
    super.key,
    required this.text,
    required this.tone,
    required this.icon,
  });

  final String text;
  final MarriageNoteTone tone;
  final String icon;

  @override
  Widget build(BuildContext context) {
    final (Color bg, Color border, Color fg) = switch (tone) {
      MarriageNoteTone.blue => (
          AppColors.primarySoft,
          AppColors.infoBorder,
          AppColors.primary,
        ),
      MarriageNoteTone.amber => (
          AppColors.warningSurface,
          AppColors.warningOutline,
          AppColors.warning,
        ),
      MarriageNoteTone.red => (
          AppColors.dangerSoft,
          AppColors.dangerOutline,
          AppColors.danger,
        ),
      MarriageNoteTone.grey => (
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
            child: LucideIcon(
              name: icon,
              size: AppSpacing.gap16,
              color: fg,
            ),
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

/// One review card — a title and a list of label/value rows (`:1579-1588`).
class MarriageReviewCard extends StatelessWidget {
  const MarriageReviewCard({
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
          for (final (String label, String value) row in rows)
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
