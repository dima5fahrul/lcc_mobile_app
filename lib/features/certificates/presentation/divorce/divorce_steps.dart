/// Divorce's six steps — `DivorceCertificatePage.tsx:1033-1554`.
///
/// **Step 1 is the batch's conditional complexity**, and § 6.7 rules it in
/// three parts:
///
/// 1. `voluntary` → the mediation-record chooser, then either the picker or the
///    capture form.
/// 2. `contested` → the People's Court decree block.
/// 3. **Anything else — including a third server-side code — renders ONLY the
///    type select.** `:1224` and `:1339` are inside the two branches, so
///    nothing else mounts. `canProceed()` falls through to the contested arm at
///    `:765` and demands a header, a court name, a decision date and an upload
///    **that state never renders**, so the step cannot advance for any sequence
///    of clicks.
///
/// The port must reproduce that dead end: **no throw, no crash, no invented
/// "unsupported type" panel** (`F3-AC-52`, `F3-AC-53`). There is deliberately no
/// `default:` arm below that renders anything — the three cases are expressed as
/// two `if`s over the two string literals, exactly as the source is, so a third
/// code simply matches neither.
library;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../presentation/forms/validation/field_error.dart';
import '../../../../presentation/icons/lucide_icon.dart';
import '../../../../presentation/payment/draft_payment_section.dart';
import '../../../../presentation/payment/payment_draft.dart';
import '../../../../presentation/payment/payment_summary_card.dart';
import '../../../../presentation/theme/app_colors.dart';
import '../../../../presentation/theme/app_spacing.dart';
import '../../../../presentation/theme/app_typography.dart';
import '../../../application/domain/entities/picked_attachment.dart';
import '../../../reference/domain/entities/prerequisite_record.dart';
import '../certificate_forms/certificate_dated_field.dart';
import '../certificate_forms/certificate_doc_upload.dart';
import '../certificate_forms/certificate_input_field.dart';
import '../certificate_forms/certificate_location_fields.dart';
import '../certificate_forms/certificate_location_value.dart';
import '../certificate_forms/certificate_section_label.dart';
import '../certificate_forms/certificate_select_field.dart';
import '../certificate_forms/certificate_toggle_row.dart';
import 'divorce_fields.dart';
import 'divorce_form_cubit.dart';
import 'divorce_form_state.dart';

String _t(BuildContext c, String key) => 'divorce.$key'.tr(context: c);

/// `say(key)` — `:616`. The page-local `COPY` table, never an i18n namespace.
String divorceSay(BuildContext context, String key) {
  final Map<String, String>? row = kDivorceCopy[key];
  if (row == null) return '';
  final String lang = Localizations.localeOf(context).languageCode;
  return row[lang] ?? row['en'] ?? '';
}

// ─────────────────────────────────────────────────────────────────────────────
// Step 1 — the divorce basis
// ─────────────────────────────────────────────────────────────────────────────

class DivorceStep1 extends StatelessWidget {
  const DivorceStep1({
    super.key,
    required this.state,
    required this.onTypeChanged,
    required this.onModeChosen,
    required this.onReset,
    required this.onSearchChanged,
    required this.onPickRecord,
    required this.onUnlink,
    required this.onHeaderChanged,
    required this.onMediationChanged,
    required this.onCourtChanged,
    required this.onChildrenChanged,
    required this.onToggleChildren,
    required this.onCourtDecision,
    required this.pickFile,
  });

  final DivorceFormViewState state;
  final ValueChanged<String> onTypeChanged;
  final ValueChanged<DivorceMediationMode> onModeChosen;
  final VoidCallback onReset;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<String> onPickRecord;
  final VoidCallback onUnlink;
  final ValueChanged<CertificateLocationValue> onHeaderChanged;
  final ValueChanged<DivorceMediation> onMediationChanged;
  final ValueChanged<DivorceCourt> onCourtChanged;
  final ValueChanged<DivorceChildren> onChildrenChanged;
  final VoidCallback onToggleChildren;
  final ValueChanged<PickedAttachment?> onCourtDecision;
  final CertificateFilePicker pickFile;

  @override
  Widget build(BuildContext context) {
    final DivorceFormData f = state.form;
    final bool voluntary = divorceIsVoluntary(f);
    final bool contested = divorceIsContested(f);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        // `:1036-1044` — the type select. ALWAYS rendered, in every state,
        // including the terminal one.
        CertificateSelectField(
          key: const Key('divorce.typeSelect'),
          label: _t(context, 'divorceType'),
          value: f.basis.divorceType,
          options: state.divorceTypes.options,
          placeholder: _t(context, 'selectPlaceholder'),
          onChanged: onTypeChanged,
          required: true,
          serverError: state.serverErrors['basis.divorce_type'],
        ),

        // `:1046-1053` — the intro note, shown ONLY while no type is chosen.
        // A third code does NOT show it: `!basis.divorceType` is false.
        if (f.basis.divorceType.isEmpty) ...<Widget>[
          const SizedBox(height: AppSpacing.gap20),
          DivorceNote(
            text: _t(context, 'basisTypeNote'),
            tone: DivorceNoteTone.blue,
            icon: 'HeartCrack',
          ),
        ],

        // `:1056-1334` — the voluntary arm, in three states.
        if (voluntary) ...<Widget>[
          const SizedBox(height: AppSpacing.gap20),
          switch (f.mediationMode) {
            DivorceMediationMode.none => _chooser(context),
            DivorceMediationMode.existing => _existing(context),
            DivorceMediationMode.newRecord => _newRecord(context),
          },
        ],

        // `:1337-1374` — the contested arm.
        if (contested) ...<Widget>[
          const SizedBox(height: AppSpacing.gap20),
          _contested(context),
        ],

        // NOTHING ELSE. A `divorce_type` that is neither literal reaches this
        // point having rendered only the select — no header cascade, no
        // mediation block, no court block, and no fallback panel. That is the
        // measured behaviour (`F3-AC-52`); an "unsupported type" message here
        // would be a divergence the source has no analogue for (`F3-AC-53`).
      ],
    );
  }

  /// `:1056-1094`.
  Widget _chooser(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          DivorceNote(
            text: _t(context, 'mediationChooseNote'),
            tone: DivorceNoteTone.blue,
            icon: 'Info',
          ),
          const SizedBox(height: AppSpacing.gap20),
          _ChoiceTile(
            key: const Key('divorce.chooseExisting'),
            icon: 'Link2',
            title: _t(context, 'mediationSelectExisting'),
            hint: _t(context, 'mediationSelectExistingHint'),
            onTap: () => onModeChosen(DivorceMediationMode.existing),
          ),
          const SizedBox(height: AppSpacing.gap20),
          _ChoiceTile(
            key: const Key('divorce.chooseNew'),
            icon: 'FilePlus2',
            title: _t(context, 'mediationCreateNew'),
            hint: _t(context, 'mediationCreateNewHint'),
            onTap: () => onModeChosen(DivorceMediationMode.newRecord),
          ),
          if (state.showErrors)
            FieldErrorText(
              show: true,
              message: _t(context, 'mediationChooseRequired'),
            ),
        ],
      );

  /// `:1097-1201`.
  Widget _existing(BuildContext context) {
    final PrerequisiteRecord? linked = state.form.linkedRecord;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        _BackLink(
          keyName: 'divorce.mediationBack',
          label: _t(context, 'mediationBack'),
          onTap: onReset,
        ),
        const SizedBox(height: AppSpacing.gap12),
        if (linked == null) ...<Widget>[
          CertificateSectionLabel(text: _t(context, 'mediationPickTitle')),
          const SizedBox(height: AppSpacing.gap12),
          _SearchBox(
            value: state.recordSearch,
            placeholder: divorceSay(context, 'searchRecord'),
            onChanged: onSearchChanged,
          ),
          const SizedBox(height: AppSpacing.gap12),
          if (state.records.loading)
            _CentredMessage(
              icon: 'Loader2',
              text: divorceSay(context, 'recordsLoading'),
            )
          else if (state.records.error != null)
            _RecordsError(
              title: divorceSay(context, 'recordsError'),
              detail: state.records.error!,
              retryLabel: divorceSay(context, 'retry'),
              onRetry: () => onSearchChanged(state.recordSearch),
            )
          else if ((state.records.data?.data.length ?? 0) == 0)
            // **The only reachable state** — `data: []` on every account.
            _EmptyRecords(text: divorceSay(context, 'recordsEmpty'))
          else
            for (final PrerequisiteRecord r in state.records.data!.data)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.gap12),
                child: _RecordRow(
                  record: r,
                  onTap: () => onPickRecord(r.recordNo),
                ),
              ),
          if (state.openRecordError != null)
            FieldErrorText(
              show: true,
              message: '${divorceSay(context, 'recordOpenError')} '
                  '${state.openRecordError}',
            ),
          if (state.showErrors)
            FieldErrorText(
              show: true,
              message: _t(context, 'mediationPickRequired'),
            ),
        ] else ...<Widget>[
          _LinkedSummary(
            title: _t(context, 'mediationLinkedTitle'),
            rows: <(String, String)>[
              (_t(context, 'mediationRecordNo'), linked.recordNo),
              (
                _t(context, 'mediationCouple'),
                '${linked.partyAName} & ${linked.partyBName}',
              ),
              (
                _t(context, 'mediationWhere'),
                _orEmpty(
                  context,
                  <String>[
                    state.form.header.villageName,
                    state.form.header.districtName,
                    state.form.header.provinceName,
                  ].where((String v) => v.isNotEmpty).join(', '),
                ),
              ),
              (
                _t(context, 'mediationDate'),
                _orEmpty(context, linked.recordedDate),
              ),
            ],
            changeLabel: _t(context, 'mediationChange'),
            onChange: onUnlink,
          ),
          const SizedBox(height: AppSpacing.gap20),
          DivorceNote(
            text: _t(context, 'mediationPrefillNote'),
            tone: DivorceNoteTone.blue,
            icon: 'Info',
          ),
        ],
      ],
    );
  }

  /// `:1204-1334` — capture the Record of Voluntary Divorce.
  Widget _newRecord(BuildContext context) {
    final DivorceMediation m = state.form.mediation;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        _BackLink(
          keyName: 'divorce.mediationBackNew',
          label: _t(context, 'mediationBack'),
          onTap: onReset,
        ),
        const SizedBox(height: AppSpacing.gap12),
        _AutoNumberCard(
          label: _t(context, 'mediationNoLabel'),
          value: _t(context, 'empty'),
          badge: _t(context, 'autoGenerated'),
        ),
        const SizedBox(height: AppSpacing.gap20),
        CertificateLocationFields(
          value: state.form.header,
          onChanged: onHeaderChanged,
          provinces: state.provinces,
          districts: state.cascade(DivorceCascade.header).districts,
          villages: state.cascade(DivorceCascade.header).villages,
          villageLabel: _t(context, 'villageLabel'),
          required: true,
          serverError: state.serverErrors['header.province_id'] ??
              state.serverErrors['header.district_id'] ??
              state.serverErrors['header.village_id'],
        ),
        const SizedBox(height: AppSpacing.gap12),
        CertificateDatedField(
          label: _t(context, 'dateMarriageBegan'),
          value: m.dateMarriageBegan,
          onChanged: (String v) =>
              onMediationChanged(m.copyWith(dateMarriageBegan: v)),
          required: true,
        ),
        const SizedBox(height: AppSpacing.gap12),
        DivorceTextAreaField(
          label: _t(context, 'reasonsHusband'),
          value: m.reasonsHusband,
          placeholder: _t(context, 'reasonsPlaceholder'),
          onChanged: (String v) =>
              onMediationChanged(m.copyWith(reasonsHusband: v)),
          required: true,
        ),
        const SizedBox(height: AppSpacing.gap12),
        DivorceTextAreaField(
          label: _t(context, 'reasonsWife'),
          value: m.reasonsWife,
          placeholder: _t(context, 'reasonsPlaceholder'),
          onChanged: (String v) =>
              onMediationChanged(m.copyWith(reasonsWife: v)),
          required: true,
        ),
        const SizedBox(height: AppSpacing.gap12),
        DivorceTextAreaField(
          label: _t(context, 'mediationOutcome'),
          value: m.outcome,
          placeholder: _t(context, 'mediationOutcomePlaceholder'),
          onChanged: (String v) => onMediationChanged(m.copyWith(outcome: v)),
          required: true,
        ),
        const SizedBox(height: AppSpacing.gap12),
        CertificateSectionLabel(text: _t(context, 'divisionSection')),
        const SizedBox(height: AppSpacing.gap12),
        DivorceTextAreaField(
          label: _t(context, 'propertyDivision'),
          value: m.propertyDivision,
          placeholder: _t(context, 'propertyDivisionPlaceholder'),
          onChanged: (String v) =>
              onMediationChanged(m.copyWith(propertyDivision: v)),
          required: true,
          serverError: state.serverErrors['mediation.property_division'],
        ),
        const SizedBox(height: AppSpacing.gap12),
        CertificateInputField(
          label: _t(context, 'debts'),
          value: m.debts,
          placeholder: _t(context, 'debtsPlaceholder'),
          onChanged: (String v) => onMediationChanged(m.copyWith(debts: v)),
          serverError: state.serverErrors['mediation.debt_division'],
        ),
        const SizedBox(height: AppSpacing.gap12),
        CertificateInputField(
          label: _t(context, 'additionalAssets'),
          value: m.additionalAssets,
          placeholder: _t(context, 'additionalAssetsPlaceholder'),
          onChanged: (String v) =>
              onMediationChanged(m.copyWith(additionalAssets: v)),
        ),
        const SizedBox(height: AppSpacing.gap12),
        CertificateToggleRow(
          active: state.form.hasChildren,
          onToggle: onToggleChildren,
          title: _t(context, 'hasChildren'),
          hint: _t(context, 'hasChildrenHint'),
        ),
        if (state.form.hasChildren) ...<Widget>[
          const SizedBox(height: AppSpacing.gap12),
          DivorceTextAreaField(
            label: _t(context, 'childrenList'),
            value: state.form.children.list,
            placeholder: _t(context, 'childrenListPlaceholder'),
            onChanged: (String v) =>
                onChildrenChanged(state.form.children.copyWith(list: v)),
            required: true,
          ),
          const SizedBox(height: AppSpacing.gap12),
          DivorceTextAreaField(
            label: _t(context, 'custodyAgreement'),
            value: state.form.children.custody,
            placeholder: _t(context, 'custodyAgreementPlaceholder'),
            onChanged: (String v) =>
                onChildrenChanged(state.form.children.copyWith(custody: v)),
            required: true,
            serverError: state.serverErrors['mediation.custody_arrangement'],
          ),
        ],
        const SizedBox(height: AppSpacing.gap12),
        CertificateSectionLabel(text: _t(context, 'mediationWitnesses')),
        const SizedBox(height: AppSpacing.gap12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Expanded(
              child: CertificateInputField(
                label: _t(context, 'witnessName'),
                value: m.w1Name,
                placeholder: _t(context, 'witnessNamePlaceholder'),
                onChanged: (String v) =>
                    onMediationChanged(m.copyWith(w1Name: v)),
              ),
            ),
            const SizedBox(width: AppSpacing.gap12),
            Expanded(
              child: CertificateInputField(
                label: _t(context, 'witnessName'),
                value: m.w2Name,
                placeholder: _t(context, 'witnessNamePlaceholder'),
                onChanged: (String v) =>
                    onMediationChanged(m.copyWith(w2Name: v)),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.gap20),
        DivorceNote(
          text: _t(context, 'mediationNewNote'),
          tone: DivorceNoteTone.blue,
          icon: 'HeartCrack',
        ),
      ],
    );
  }

  /// `:1337-1374` — the People's Court decree.
  Widget _contested(BuildContext context) {
    final DivorceCourt c = state.form.court;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        CertificateLocationFields(
          value: state.form.header,
          onChanged: onHeaderChanged,
          provinces: state.provinces,
          districts: state.cascade(DivorceCascade.header).districts,
          villages: state.cascade(DivorceCascade.header).villages,
          villageLabel: _t(context, 'villageLabel'),
          required: true,
          serverError: state.serverErrors['header.province_id'] ??
              state.serverErrors['header.district_id'] ??
              state.serverErrors['header.village_id'],
        ),
        const SizedBox(height: AppSpacing.gap20),
        DivorceNote(
          text: _t(context, 'contestedNote'),
          tone: DivorceNoteTone.amber,
          icon: 'Gavel',
        ),
        const SizedBox(height: AppSpacing.gap12),
        CertificateInputField(
          label: _t(context, 'courtName'),
          value: c.name,
          placeholder: _t(context, 'courtNamePlaceholder'),
          onChanged: (String v) => onCourtChanged(c.copyWith(name: v)),
          required: true,
        ),
        const SizedBox(height: AppSpacing.gap12),
        CertificateDatedField(
          label: _t(context, 'courtDecisionDate'),
          value: c.decisionDate,
          onChanged: (String v) => onCourtChanged(c.copyWith(decisionDate: v)),
          required: true,
        ),
        const SizedBox(height: AppSpacing.gap12),
        CertificateDocUpload(
          label: _t(context, 'courtDecisionLabel'),
          file: state.form.courtDecision,
          onChanged: onCourtDecision,
          uploadDocumentLabel: _t(context, 'uploadDocument'),
          // Divorce's namespace default is `uploadHint`; Marriage's is
          // `pdfOrImage`. Two keys, two namespaces (`F3-AC-21`).
          defaultHint: _t(context, 'uploadHint'),
          hint: _t(context, 'courtDecisionHint'),
          pickFile: pickFile,
          required: true,
          serverError: state.serverErrors['basis.court_decision'],
        ),
      ],
    );
  }

  String _orEmpty(BuildContext context, String v) =>
      v.isEmpty ? _t(context, 'empty') : v;
}

// ─────────────────────────────────────────────────────────────────────────────
// Steps 2 and 3 — husband and wife (`:1379`, `:1397`)
// ─────────────────────────────────────────────────────────────────────────────

class DivorceSpouseStep extends StatelessWidget {
  const DivorceSpouseStep({
    super.key,
    required this.intro,
    required this.section,
  });

  final String intro;
  final DivorceSpouseSection section;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          DivorceNote(
            text: intro,
            tone: DivorceNoteTone.blue,
            icon: 'User',
          ),
          const SizedBox(height: AppSpacing.gap20),
          section,
        ],
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// Step 4 — registration and documents (`:1415-1469`)
// ─────────────────────────────────────────────────────────────────────────────

class DivorceStep4 extends StatelessWidget {
  const DivorceStep4({
    super.key,
    required this.state,
    required this.onBasisChanged,
    required this.onHouseholdBook,
    required this.onGuaranteeCert,
    required this.onPhotos,
    required this.pickFile,
  });

  final DivorceFormViewState state;
  final ValueChanged<DivorceBasis> onBasisChanged;
  final ValueChanged<PickedAttachment?> onHouseholdBook;
  final ValueChanged<PickedAttachment?> onGuaranteeCert;
  final ValueChanged<PickedAttachment?> onPhotos;
  final CertificateFilePicker pickFile;

  @override
  Widget build(BuildContext context) {
    final DivorceBasis b = state.form.basis;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Expanded(
              child: CertificateDatedField(
                label: _t(context, 'dateOfDivorce'),
                value: b.dateOfDivorce,
                onChanged: (String v) =>
                    onBasisChanged(b.copyWith(dateOfDivorce: v)),
                required: true,
                serverError: state.serverErrors['basis.divorce_date'],
              ),
            ),
            const SizedBox(width: AppSpacing.gap12),
            Expanded(
              child: CertificateInputField(
                label: _t(context, 'placeOfRegistration'),
                value: b.placeOfRegistration,
                placeholder: _t(context, 'placeOfRegistrationPlaceholder'),
                onChanged: (String v) =>
                    onBasisChanged(b.copyWith(placeOfRegistration: v)),
                required: true,
                serverError: state.serverErrors['basis.registration_place'],
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.gap20),
        DivorceNote(
          text: _t(context, 'registrationDocsNote'),
          tone: DivorceNoteTone.amber,
          icon: 'ClipboardList',
        ),
        // `:1442`, `:1448`, `:1455` — **the DOM order**: household book,
        // guarantee certificate, photos. `uploads()` puts the court decision
        // first and is a DIFFERENT LIST (`F3-AC-58`, `divorceStep4DomOrder`).
        const SizedBox(height: AppSpacing.gap20),
        CertificateDocUpload(
          label: _t(context, 'householdBook'),
          file: state.form.householdBook,
          onChanged: onHouseholdBook,
          uploadDocumentLabel: _t(context, 'uploadDocument'),
          defaultHint: _t(context, 'uploadHint'),
          pickFile: pickFile,
          required: true,
        ),
        const SizedBox(height: AppSpacing.gap12),
        CertificateDocUpload(
          label: _t(context, 'guaranteeCert'),
          file: state.form.guaranteeCert,
          onChanged: onGuaranteeCert,
          uploadDocumentLabel: _t(context, 'uploadDocument'),
          defaultHint: _t(context, 'uploadHint'),
          hint: _t(context, 'guaranteeCertHint'),
          pickFile: pickFile,
          required: true,
        ),
        const SizedBox(height: AppSpacing.gap12),
        CertificateDocUpload(
          label: _t(context, 'photos3x4'),
          file: state.form.photos,
          onChanged: onPhotos,
          uploadDocumentLabel: _t(context, 'uploadDocument'),
          defaultHint: _t(context, 'uploadHint'),
          hint: _t(context, 'photos3x4Hint'),
          pickFile: pickFile,
          required: true,
        ),
        const SizedBox(height: AppSpacing.gap20),
        DivorceNote(
          text: _t(context, 'registrationNote'),
          tone: DivorceNoteTone.grey,
          icon: 'Info',
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Step 5 — review (`:1473-1541`). **NO FEE CARD** — `F3-AC-73`.
// ─────────────────────────────────────────────────────────────────────────────

class DivorceStep5 extends StatelessWidget {
  const DivorceStep5({
    super.key,
    required this.state,
    required this.documentNo,
  });

  final DivorceFormViewState state;
  final String documentNo;

  @override
  Widget build(BuildContext context) {
    final DivorceFormData f = state.form;
    final String empty = _t(context, 'empty');
    String or(String v) => v.isEmpty ? empty : v;
    final bool contested = divorceIsContested(f);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        DivorceNote(
          text: _t(context, 'reviewNote'),
          tone: DivorceNoteTone.amber,
          icon: 'AlertCircle',
        ),
        const SizedBox(height: AppSpacing.gap20),
        DivorceReviewCard(
          title: _t(context, 'reviewBasis'),
          rows: <(String, String)>[
            (
              _t(context, 'reviewType'),
              or(divorceLabelFor(state.divorceTypes, f.basis.divorceType)),
            ),
            // `:1487-1492` — the label AND the value both switch on the arm.
            (
              contested
                  ? _t(context, 'reviewCourtDecision')
                  : _t(context, 'mediationRecordNo'),
              contested
                  ? or(f.court.name)
                  : (f.linkedRecord?.recordNo ?? _t(context, 'autoGenerated')),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.gap20),
        DivorceReviewCard(
          title: _t(context, 'reviewHeader'),
          rows: <(String, String)>[
            (
              _t(context, 'reviewProvinceDistrictVillage'),
              or(<String>[
                f.header.provinceName,
                f.header.districtName,
                f.header.villageName,
              ].where((String v) => v.isNotEmpty).join(' / ')),
            ),
            (_t(context, 'documentNo'), documentNo),
          ],
        ),
        const SizedBox(height: AppSpacing.gap20),
        DivorceReviewCard(
          title: _t(context, 'reviewHusband'),
          rows: <(String, String)>[
            (_t(context, 'reviewName'), or(f.husband.fullName)),
            (_t(context, 'reviewIdPassport'), or(f.husband.idOrPassport)),
            (_t(context, 'reviewMarriageRef'), or(f.husband.marriageCertRef)),
          ],
        ),
        const SizedBox(height: AppSpacing.gap20),
        DivorceReviewCard(
          title: _t(context, 'reviewWife'),
          rows: <(String, String)>[
            (_t(context, 'reviewName'), or(f.wife.fullName)),
            (_t(context, 'reviewIdPassport'), or(f.wife.idOrPassport)),
            (_t(context, 'reviewMarriageRef'), or(f.wife.marriageCertRef)),
          ],
        ),
        const SizedBox(height: AppSpacing.gap20),
        DivorceReviewCard(
          title: _t(context, 'reviewRegistration'),
          rows: <(String, String)>[
            (_t(context, 'reviewDate'), or(f.basis.dateOfDivorce)),
            (_t(context, 'reviewPlace'), or(f.basis.placeOfRegistration)),
            (
              _t(context, 'reviewCustody'),
              f.hasChildren ? or(f.children.custody) : empty,
            ),
          ],
        ),
        // **No fee card.** Marriage renders one at `:1571-1577`; Divorce does
        // not, and `divorce.ts` has no `feeSectionTitle` key — the independent
        // confirmation (`F3-AC-73`). The fee reaches the citizen only through
        // step 6's payment section.
        if (state.quote.error != null)
          FieldErrorText(
            show: true,
            message: '${divorceSay(context, 'quoteError')} ${state.quote.error}',
          ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Step 6 — payment (`:1545-1554`)
// ─────────────────────────────────────────────────────────────────────────────

class DivorceStep6 extends StatelessWidget {
  const DivorceStep6({
    super.key,
    required this.state,
    required this.documentNo,
    required this.onChanged,
  });

  final DivorceFormViewState state;
  final String documentNo;
  final ValueChanged<PaymentDraft> onChanged;

  @override
  Widget build(BuildContext context) => DraftPaymentSection(
        amount: state.quote.data?.feeLak ?? 0,
        serviceName: _t(context, 'serviceName'),
        value: state.form.payment,
        onChanged: onChanged,
        reference: state.caseRef.isNotEmpty ? state.caseRef : documentNo,
        breakdown: <PaymentBreakdownItem>[
          for (final DivorceQuoteLine line
              in state.quote.data?.lines ?? const <DivorceQuoteLine>[])
            PaymentBreakdownItem(label: line.label, amount: line.amountLak),
        ],
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// Small pieces — declared per page, like the source's
// ─────────────────────────────────────────────────────────────────────────────

class _ChoiceTile extends StatelessWidget {
  const _ChoiceTile({
    super.key,
    required this.icon,
    required this.title,
    required this.hint,
    required this.onTap,
  });

  final String icon;
  final String title;
  final String hint;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        child: GestureDetector(
          onTap: onTap,
          behavior: HitTestBehavior.opaque,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.gap16),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius:
                  const BorderRadius.all(Radius.circular(AppSpacing.radius2xl)),
              border: Border.all(color: AppColors.gray200),
            ),
            child: Row(
              children: <Widget>[
                Container(
                  width: AppSpacing.control40,
                  height: AppSpacing.control40,
                  decoration: const BoxDecoration(
                    color: AppColors.primarySoft,
                    borderRadius:
                        BorderRadius.all(Radius.circular(AppSpacing.radiusXl)),
                  ),
                  child: Center(
                    child: LucideIcon(
                      name: icon,
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
                        style: const TextStyle(
                          fontSize: AppTypography.size14,
                          fontWeight: AppTypography.semiBold,
                          color: AppColors.gray800,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.gap2),
                      Text(
                        hint,
                        style: const TextStyle(
                          fontSize: AppTypography.size12,
                          color: AppColors.gray400Inline,
                        ),
                      ),
                    ],
                  ),
                ),
                const LucideIcon(
                  name: 'ArrowRight',
                  size: AppSpacing.gap16,
                  color: AppColors.gray300,
                ),
              ],
            ),
          ),
        ),
      );
}

class _BackLink extends StatelessWidget {
  const _BackLink({
    required this.keyName,
    required this.label,
    required this.onTap,
  });

  final String keyName;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        child: GestureDetector(
          key: Key(keyName),
          onTap: onTap,
          behavior: HitTestBehavior.opaque,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const LucideIcon(
                name: 'ChevronLeft',
                size: AppSpacing.gap16,
                color: AppColors.muted,
              ),
              const SizedBox(width: AppSpacing.gap4),
              Text(
                label,
                style: const TextStyle(
                  fontSize: AppTypography.size14,
                  color: AppColors.muted,
                ),
              ),
            ],
          ),
        ),
      );
}

class _SearchBox extends StatefulWidget {
  const _SearchBox({
    required this.value,
    required this.placeholder,
    required this.onChanged,
  });

  final String value;
  final String placeholder;
  final ValueChanged<String> onChanged;

  @override
  State<_SearchBox> createState() => _SearchBoxState();
}

class _SearchBoxState extends State<_SearchBox> {
  late final TextEditingController _c =
      TextEditingController(text: widget.value);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.gap12,
          vertical: AppSpacing.gap10,
        ),
        decoration: BoxDecoration(
          color: AppColors.gray50,
          borderRadius:
              const BorderRadius.all(Radius.circular(AppSpacing.radius2xl)),
          border: Border.all(color: AppColors.gray200),
        ),
        child: Row(
          children: <Widget>[
            const LucideIcon(
              name: 'Search',
              size: AppSpacing.gap16,
              color: AppColors.gray400Inline,
            ),
            const SizedBox(width: AppSpacing.gap8),
            Expanded(
              child: TextField(
                key: const Key('divorce.recordSearch'),
                controller: _c,
                onChanged: widget.onChanged,
                style: const TextStyle(
                  fontSize: AppTypography.size14,
                  color: AppColors.gray800,
                ),
                decoration: InputDecoration.collapsed(
                  hintText: widget.placeholder,
                  hintStyle: const TextStyle(
                    fontSize: AppTypography.size14,
                    color: AppColors.gray400Inline,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
}

class _CentredMessage extends StatelessWidget {
  const _CentredMessage({required this.icon, required this.text});

  final String icon;
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.gap24),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            LucideIcon(
              name: icon,
              size: AppSpacing.gap16,
              color: AppColors.gray400Inline,
            ),
            const SizedBox(width: AppSpacing.gap8),
            Text(
              text,
              style: const TextStyle(
                fontSize: AppTypography.size14,
                color: AppColors.gray400Inline,
              ),
            ),
          ],
        ),
      );
}

class _RecordsError extends StatelessWidget {
  const _RecordsError({
    required this.title,
    required this.detail,
    required this.retryLabel,
    required this.onRetry,
  });

  final String title;
  final String detail;
  final String retryLabel;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.gap20),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius:
              const BorderRadius.all(Radius.circular(AppSpacing.radius2xl)),
          border: Border.all(color: AppColors.gray100),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const LucideIcon(
              name: 'AlertCircle',
              size: AppSpacing.gap24,
              color: AppColors.warningStrong,
            ),
            const SizedBox(height: AppSpacing.gap12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: AppTypography.size14,
                color: AppColors.gray600,
              ),
            ),
            const SizedBox(height: AppSpacing.gap4),
            Text(
              detail,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: AppTypography.size12,
                color: AppColors.gray400Inline,
              ),
            ),
            const SizedBox(height: AppSpacing.gap12),
            Semantics(
              button: true,
              child: GestureDetector(
                key: const Key('divorce.recordsRetry'),
                onTap: onRetry,
                behavior: HitTestBehavior.opaque,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.gap16,
                    vertical: AppSpacing.gap10,
                  ),
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    borderRadius:
                        BorderRadius.all(Radius.circular(AppSpacing.radius2xl)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      const LucideIcon(
                        name: 'RotateCcw',
                        size: AppSpacing.gap16,
                        color: AppColors.white,
                      ),
                      const SizedBox(width: AppSpacing.gap8),
                      Text(
                        retryLabel,
                        style: const TextStyle(
                          fontSize: AppTypography.size14,
                          fontWeight: AppTypography.semiBold,
                          color: AppColors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      );
}

class _EmptyRecords extends StatelessWidget {
  const _EmptyRecords({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.gap20),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius:
              const BorderRadius.all(Radius.circular(AppSpacing.radius2xl)),
          border: Border.all(color: AppColors.gray100),
        ),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: AppTypography.size14,
            color: AppColors.muted,
          ),
        ),
      );
}

class _RecordRow extends StatelessWidget {
  const _RecordRow({required this.record, required this.onTap});

  final PrerequisiteRecord record;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        child: GestureDetector(
          onTap: onTap,
          behavior: HitTestBehavior.opaque,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.gap16),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius:
                  const BorderRadius.all(Radius.circular(AppSpacing.radius2xl)),
              border: Border.all(color: AppColors.gray200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        '${record.partyAName} & ${record.partyBName}',
                        style: const TextStyle(
                          fontSize: AppTypography.size14,
                          fontWeight: AppTypography.semiBold,
                          color: AppColors.gray800,
                        ),
                      ),
                    ),
                    Text(
                      record.recordNo,
                      style: const TextStyle(
                        fontSize: AppTypography.size11,
                        color: AppColors.gray400Inline,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.gap4),
                Text(
                  '${record.recordedBy} · ${record.recordedDate}',
                  style: const TextStyle(
                    fontSize: AppTypography.size12,
                    color: AppColors.gray400Inline,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
}

class _LinkedSummary extends StatelessWidget {
  const _LinkedSummary({
    required this.title,
    required this.rows,
    required this.changeLabel,
    required this.onChange,
  });

  final String title;
  final List<(String, String)> rows;
  final String changeLabel;
  final VoidCallback onChange;

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.gap16),
        decoration: BoxDecoration(
          color: AppColors.successSoft,
          borderRadius:
              const BorderRadius.all(Radius.circular(AppSpacing.radius2xl)),
          border: Border.all(color: AppColors.green300, width: 2),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Row(
              children: <Widget>[
                const LucideIcon(
                  name: 'CheckCircle2',
                  size: AppSpacing.gap16,
                  color: AppColors.green600,
                ),
                const SizedBox(width: AppSpacing.gap8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: AppTypography.size14,
                    fontWeight: AppTypography.semiBold,
                    color: AppColors.success,
                  ),
                ),
              ],
            ),
            for (final (String, String) row in rows)
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.gap10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      row.$1,
                      style: const TextStyle(
                        fontSize: AppTypography.size12,
                        color: AppColors.muted,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.gap12),
                    Expanded(
                      child: Text(
                        row.$2,
                        textAlign: TextAlign.right,
                        style: const TextStyle(
                          fontSize: AppTypography.size12,
                          fontWeight: AppTypography.medium,
                          color: AppColors.gray800,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.gap6),
              child: Semantics(
                button: true,
                child: GestureDetector(
                  key: const Key('divorce.mediationChange'),
                  onTap: onChange,
                  behavior: HitTestBehavior.opaque,
                  child: Text(
                    changeLabel,
                    style: const TextStyle(
                      fontSize: AppTypography.size12,
                      fontWeight: AppTypography.medium,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
}

class _AutoNumberCard extends StatelessWidget {
  const _AutoNumberCard({
    required this.label,
    required this.value,
    required this.badge,
  });

  final String label;
  final String value;
  final String badge;

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.gap16),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius:
              const BorderRadius.all(Radius.circular(AppSpacing.radius2xl)),
          border: Border.all(color: AppColors.gray100),
        ),
        child: Row(
          children: <Widget>[
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(
                    label.toUpperCase(),
                    style: const TextStyle(
                      fontSize: AppTypography.size11,
                      fontWeight: AppTypography.semiBold,
                      color: AppColors.gray400Inline,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.gap2),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: AppTypography.size14,
                      fontWeight: AppTypography.semiBold,
                      color: AppColors.gray800,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.gap8,
                vertical: AppSpacing.gap4,
              ),
              decoration: const BoxDecoration(
                color: AppColors.gray100,
                borderRadius:
                    BorderRadius.all(Radius.circular(AppSpacing.radiusFull)),
              ),
              child: Text(
                badge,
                style: const TextStyle(
                  fontSize: AppTypography.size11,
                  fontWeight: AppTypography.medium,
                  color: AppColors.gray400Inline,
                ),
              ),
            ),
          ],
        ),
      );
}
