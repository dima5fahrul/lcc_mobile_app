/// Marriage's seven steps — `MarriageCertificatePage.tsx:1135-1606`.
///
/// One widget per step, each a pure function of the cubit's state plus
/// callbacks. Nothing here reads a locator and nothing here fetches.
///
/// ## Step 1 is three states, not one
///
/// `betrothalMode` is `"" | "existing" | "new"` (`:717`), and the three render
/// completely different bodies (`:1139`, `:1182`, `:1292`). The chooser state
/// is not a placeholder — it is the state `canProceed()` refuses at `:857`, and
/// it renders two large tap targets and, once `showErrors` is on, a required
/// message.
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
import '../certificate_forms/certificate_doc_upload.dart';
import '../certificate_forms/certificate_input_field.dart';
import '../certificate_forms/certificate_location_fields.dart';
import '../certificate_forms/certificate_location_value.dart';
import '../certificate_forms/certificate_section_label.dart';
import '../certificate_forms/certificate_toggle_row.dart';
import 'marriage_fields.dart';
import 'marriage_form_cubit.dart';
import 'marriage_form_state.dart';

String _t(BuildContext c, String key) => 'marriage.$key'.tr(context: c);

/// `say(key)` — `:709`, `COPY[key][lang] ?? COPY[key].en`.
///
/// Reads the **page-local** table, never an i18n namespace: the source keeps
/// these sentences out of the dictionaries deliberately and `F3-AC-95` asserts
/// they stay out.
String marriageSay(BuildContext context, String key) {
  final Map<String, String>? row = kMarriageCopy[key];
  if (row == null) return '';
  final String lang = Localizations.localeOf(context).languageCode;
  return row[lang] ?? row['en'] ?? '';
}

// ─────────────────────────────────────────────────────────────────────────────
// Step 1 — the betrothal record (FR-11)
// ─────────────────────────────────────────────────────────────────────────────

class MarriageStep1 extends StatelessWidget {
  const MarriageStep1({
    super.key,
    required this.state,
    required this.onModeChosen,
    required this.onReset,
    required this.onSearchChanged,
    required this.onPickRecord,
    required this.onUnlink,
    required this.onHeaderChanged,
    required this.onBetrothalChanged,
  });

  final MarriageFormViewState state;
  final ValueChanged<MarriageBetrothalMode> onModeChosen;
  final VoidCallback onReset;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<String> onPickRecord;
  final VoidCallback onUnlink;
  final ValueChanged<CertificateLocationValue> onHeaderChanged;
  final ValueChanged<MarriageBetrothal> onBetrothalChanged;

  @override
  Widget build(BuildContext context) {
    switch (state.form.betrothalMode) {
      case MarriageBetrothalMode.none:
        return _chooser(context);
      case MarriageBetrothalMode.existing:
        return _existing(context);
      case MarriageBetrothalMode.newRecord:
        return _newRecord(context);
    }
  }

  /// `:1139-1179` — the chooser.
  Widget _chooser(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        MarriageNote(
          text: _t(context, 'betrothalChooseNote'),
          tone: MarriageNoteTone.blue,
          icon: 'Heart',
        ),
        const SizedBox(height: AppSpacing.gap20),
        _ChoiceTile(
          key: const Key('marriage.chooseExisting'),
          icon: 'Link2',
          title: _t(context, 'betrothalSelectExisting'),
          hint: _t(context, 'betrothalSelectExistingHint'),
          onTap: () => onModeChosen(MarriageBetrothalMode.existing),
        ),
        const SizedBox(height: AppSpacing.gap20),
        _ChoiceTile(
          key: const Key('marriage.chooseNew'),
          icon: 'FilePlus2',
          title: _t(context, 'betrothalCreateNew'),
          hint: _t(context, 'betrothalCreateNewHint'),
          onTap: () => onModeChosen(MarriageBetrothalMode.newRecord),
        ),
        // `:1175-1177` — only once the citizen has tapped Continue.
        if (state.showErrors)
          FieldErrorText(
            show: true,
            message: _t(context, 'betrothalChooseRequired'),
          ),
      ],
    );
  }

  /// `:1182-1289` — pick a record, then show the linked summary.
  Widget _existing(BuildContext context) {
    final PrerequisiteRecord? linked = state.form.linkedRecord;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        _BackLink(
          label: _t(context, 'betrothalBack'),
          onTap: onReset,
          keyName: 'marriage.betrothalBack',
        ),
        const SizedBox(height: AppSpacing.gap12),
        if (linked == null) ..._picker(context) else ..._linked(context, linked),
      ],
    );
  }

  List<Widget> _picker(BuildContext context) {
    return <Widget>[
      CertificateSectionLabel(text: _t(context, 'betrothalPickTitle')),
      const SizedBox(height: AppSpacing.gap12),
      _SearchBox(
        value: state.recordSearch,
        placeholder: marriageSay(context, 'searchRecord'),
        onChanged: onSearchChanged,
      ),
      const SizedBox(height: AppSpacing.gap12),
      // `:1206-1247` — loading / error / EMPTY / rows, in that order.
      //
      // **The empty state is the only reachable one** on every account this
      // programme has (`manifest-authenticated.md`:230-232). The other three
      // are specified and unit-tested against stubs.
      if (state.records.loading)
        _CentredMessage(
          icon: 'Loader2',
          text: marriageSay(context, 'recordsLoading'),
        )
      else if (state.records.error != null)
        _RecordsError(
          title: marriageSay(context, 'recordsError'),
          detail: state.records.error!,
          retryLabel: marriageSay(context, 'retry'),
          onRetry: () => onSearchChanged(state.recordSearch),
        )
      else if ((state.records.data?.data.length ?? 0) == 0)
        _EmptyRecords(text: marriageSay(context, 'recordsEmpty'))
      else
        for (final PrerequisiteRecord r in state.records.data!.data)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.gap12),
            child: _RecordRow(record: r, onTap: () => onPickRecord(r.recordNo)),
          ),
      if (state.openRecordError != null)
        FieldErrorText(
          show: true,
          message: '${marriageSay(context, 'recordOpenError')} '
              '${state.openRecordError}',
        ),
      if (state.showErrors)
        FieldErrorText(
          show: true,
          message: _t(context, 'betrothalPickRequired'),
        ),
    ];
  }

  List<Widget> _linked(BuildContext context, PrerequisiteRecord linked) {
    final String where = <String>[
      state.form.header.villageName,
      state.form.header.districtName,
      state.form.header.provinceName,
    ].where((String v) => v.isNotEmpty).join(', ');
    return <Widget>[
      _LinkedSummary(
        title: _t(context, 'betrothalLinkedTitle'),
        rows: <(String, String)>[
          (_t(context, 'betrothalRecordNo'), linked.recordNo),
          (
            _t(context, 'betrothalCouple'),
            '${linked.partyAName} & ${linked.partyBName}',
          ),
          (
            _t(context, 'betrothalWhere'),
            where.isEmpty ? _t(context, 'dash') : where,
          ),
          (
            _t(context, 'betrothalDate'),
            linked.recordedDate.isEmpty ? _t(context, 'dash') : linked.recordedDate,
          ),
        ],
        changeLabel: _t(context, 'betrothalChange'),
        onChange: onUnlink,
      ),
      const SizedBox(height: AppSpacing.gap20),
      MarriageNote(
        text: _t(context, 'betrothalPrefillNote'),
        tone: MarriageNoteTone.blue,
        icon: 'Info',
      ),
    ];
  }

  /// `:1292-1374` — capture a new betrothal record.
  Widget _newRecord(BuildContext context) {
    final MarriageBetrothal b = state.form.betrothal;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        _BackLink(
          label: _t(context, 'betrothalBack'),
          onTap: onReset,
          keyName: 'marriage.betrothalBackNew',
        ),
        const SizedBox(height: AppSpacing.gap12),
        _AutoNumberCard(
          label: _t(context, 'betrothalNoLabel'),
          value: _t(context, 'dash'),
          badge: _t(context, 'autoGenerated'),
        ),
        const SizedBox(height: AppSpacing.gap20),
        // `:1312-1317` — NO `villageLabel`, so the village select falls through
        // to `fields.village`. The spouse sections DO pass one.
        CertificateLocationFields(
          value: state.form.header,
          onChanged: onHeaderChanged,
          provinces: state.provinces,
          districts: state.cascade(MarriageCascade.header).districts,
          villages: state.cascade(MarriageCascade.header).villages,
          required: true,
          serverError: state.serverErrors['header.province_id'] ??
              state.serverErrors['header.district_id'] ??
              state.serverErrors['header.village_id'],
        ),
        const SizedBox(height: AppSpacing.gap12),
        CertificateInputField(
          label: _t(context, 'householdHead'),
          value: b.householdHead,
          placeholder: _t(context, 'householdHeadPh'),
          onChanged: (String v) =>
              onBetrothalChanged(b.copyWith(householdHead: v)),
          required: true,
        ),
        const SizedBox(height: AppSpacing.gap12),
        CertificateSectionLabel(text: _t(context, 'bridePriceSection')),
        const SizedBox(height: AppSpacing.gap12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Expanded(
              child: CertificateInputField(
                label: _t(context, 'bridePriceCash'),
                value: b.bridePriceCash,
                placeholder: _t(context, 'bridePriceCashPh'),
                inputMode: CertificateInputMode.numeric,
                // `:1334` — digits only, coerced at the CALL SITE, not in the
                // field. `bridePriceGold` next to it is NOT coerced.
                onChanged: (String v) => onBetrothalChanged(
                  b.copyWith(bridePriceCash: v.replaceAll(RegExp(r'\D'), '')),
                ),
                required: true,
              ),
            ),
            const SizedBox(width: AppSpacing.gap12),
            Expanded(
              child: CertificateInputField(
                label: _t(context, 'bridePriceGold'),
                value: b.bridePriceGold,
                placeholder: _t(context, 'bridePriceGoldPh'),
                onChanged: (String v) =>
                    onBetrothalChanged(b.copyWith(bridePriceGold: v)),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.gap12),
        CertificateInputField(
          label: _t(context, 'housing'),
          value: b.housing,
          placeholder: _t(context, 'housingPh'),
          onChanged: (String v) => onBetrothalChanged(b.copyWith(housing: v)),
        ),
        const SizedBox(height: AppSpacing.gap12),
        CertificateSectionLabel(text: _t(context, 'betrothalWitnesses')),
        const SizedBox(height: AppSpacing.gap12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Expanded(
              child: CertificateInputField(
                label: _t(context, 'witnessName'),
                value: b.w1Name,
                placeholder: _t(context, 'witnessNamePh'),
                onChanged: (String v) =>
                    onBetrothalChanged(b.copyWith(w1Name: v)),
              ),
            ),
            const SizedBox(width: AppSpacing.gap12),
            Expanded(
              child: CertificateInputField(
                label: _t(context, 'witnessName'),
                value: b.w2Name,
                placeholder: _t(context, 'witnessNamePh'),
                onChanged: (String v) =>
                    onBetrothalChanged(b.copyWith(w2Name: v)),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.gap20),
        MarriageNote(
          text: _t(context, 'betrothalNewNote'),
          tone: MarriageNoteTone.blue,
          icon: 'Heart',
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Steps 2 and 3 — the two spouses. ONE widget, twice (`:1379`, `:1399`).
// ─────────────────────────────────────────────────────────────────────────────

class MarriageSpouseStep extends StatelessWidget {
  const MarriageSpouseStep({
    super.key,
    required this.intro,
    required this.section,
  });

  final String intro;
  final MarriageSpouseSection section;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          MarriageNote(
            text: intro,
            tone: MarriageNoteTone.blue,
            icon: 'Heart',
          ),
          const SizedBox(height: AppSpacing.gap20),
          section,
        ],
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// Step 4 — supporting documents (`:1419-1455`)
// ─────────────────────────────────────────────────────────────────────────────

class MarriageStep4 extends StatelessWidget {
  const MarriageStep4({
    super.key,
    required this.form,
    required this.pickFile,
    required this.onHouseholdBook,
    required this.onPhotos,
    required this.onToggleChildren,
    required this.onBirthRecord,
  });

  final MarriageFormData form;
  final CertificateFilePicker pickFile;
  final ValueChanged<PickedAttachment?> onHouseholdBook;
  final ValueChanged<PickedAttachment?> onPhotos;
  final VoidCallback onToggleChildren;
  final ValueChanged<PickedAttachment?> onBirthRecord;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        MarriageNote(
          text: _t(context, 'docsNote'),
          tone: MarriageNoteTone.amber,
          icon: 'ClipboardList',
        ),
        const SizedBox(height: AppSpacing.gap20),
        CertificateDocUpload(
          label: _t(context, 'householdBook'),
          file: form.householdBook,
          onChanged: onHouseholdBook,
          uploadDocumentLabel: _t(context, 'uploadDocument'),
          defaultHint: _t(context, 'pdfOrImage'),
          pickFile: pickFile,
          required: true,
        ),
        const SizedBox(height: AppSpacing.gap12),
        CertificateDocUpload(
          label: _t(context, 'photos3x4'),
          file: form.photos,
          onChanged: onPhotos,
          uploadDocumentLabel: _t(context, 'uploadDocument'),
          defaultHint: _t(context, 'pdfOrImage'),
          hint: _t(context, 'photos3x4Hint'),
          pickFile: pickFile,
          required: true,
        ),
        const SizedBox(height: AppSpacing.gap12),
        CertificateToggleRow(
          active: form.hasChildren,
          onToggle: onToggleChildren,
          title: _t(context, 'hasChildren'),
          hint: _t(context, 'hasChildrenHint'),
        ),
        if (form.hasChildren) ...<Widget>[
          const SizedBox(height: AppSpacing.gap12),
          CertificateDocUpload(
            label: _t(context, 'birthRecord'),
            file: form.birthRecord,
            onChanged: onBirthRecord,
            uploadDocumentLabel: _t(context, 'uploadDocument'),
            defaultHint: _t(context, 'pdfOrImage'),
            hint: _t(context, 'birthRecordHint'),
            pickFile: pickFile,
            required: true,
          ),
        ],
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Step 5 — registration (`:1459-1519`)
// ─────────────────────────────────────────────────────────────────────────────

class MarriageStep5 extends StatelessWidget {
  const MarriageStep5({
    super.key,
    required this.reg,
    required this.serverErrors,
    required this.onChanged,
  });

  final MarriageRegistration reg;
  final Map<String, String> serverErrors;
  final ValueChanged<MarriageRegistration> onChanged;

  @override
  Widget build(BuildContext context) {
    /// `:1486-1511` — three witnesses, each a name + an id, and **only the name
    /// carries a server error key** (`:1500` passes `w.key`, `:1507` passes
    /// nothing). Reproduced.
    final List<(int, String, String, String)> witnesses =
        <(int, String, String, String)>[
      (1, reg.w1Name, reg.w1Id, 'registration.witness_1'),
      (2, reg.w2Name, reg.w2Id, 'registration.witness_2'),
      (3, reg.w3Name, reg.w3Id, 'registration.witness_3'),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Expanded(
              child: MarriageDatedField(
                label: _t(context, 'dateOfMarriage'),
                value: reg.dateOfMarriage,
                onChanged: (String v) =>
                    onChanged(reg.copyWith(dateOfMarriage: v)),
                required: true,
                serverError: serverErrors['registration.marriage_date'],
              ),
            ),
            const SizedBox(width: AppSpacing.gap12),
            Expanded(
              child: CertificateInputField(
                label: _t(context, 'placeOfRegistration'),
                value: reg.placeOfRegistration,
                placeholder: _t(context, 'placeOfRegistrationPh'),
                onChanged: (String v) =>
                    onChanged(reg.copyWith(placeOfRegistration: v)),
                required: true,
                serverError: serverErrors['registration.registration_place'],
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.gap20),
        MarriageNote(
          text: _t(context, 'witnessesNote'),
          tone: MarriageNoteTone.blue,
          icon: 'Users',
        ),
        for (final (int n, String name, String id, String errKey) in witnesses)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.gap20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                CertificateSectionLabel(
                  text: 'marriage.witness'
                      .tr(context: context, namedArgs: <String, String>{
                    'n': '$n',
                  }),
                ),
                const SizedBox(height: AppSpacing.gap6),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Expanded(
                      child: CertificateInputField(
                        label: _t(context, 'witnessName'),
                        value: name,
                        placeholder: _t(context, 'witnessNamePh'),
                        onChanged: (String v) =>
                            onChanged(_withWitnessName(reg, n, v)),
                        required: true,
                        serverError: serverErrors[errKey],
                      ),
                    ),
                    const SizedBox(width: AppSpacing.gap12),
                    Expanded(
                      child: CertificateInputField(
                        label: _t(context, 'witnessId'),
                        value: id,
                        placeholder: _t(context, 'witnessIdPh'),
                        onChanged: (String v) =>
                            onChanged(_withWitnessId(reg, n, v)),
                        required: true,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        const SizedBox(height: AppSpacing.gap20),
        MarriageNote(
          text: _t(context, 'signNote'),
          tone: MarriageNoteTone.grey,
          icon: 'Info',
        ),
      ],
    );
  }

  static MarriageRegistration _withWitnessName(
    MarriageRegistration r,
    int n,
    String v,
  ) =>
      switch (n) {
        1 => r.copyWith(w1Name: v),
        2 => r.copyWith(w2Name: v),
        _ => r.copyWith(w3Name: v),
      };

  static MarriageRegistration _withWitnessId(
    MarriageRegistration r,
    int n,
    String v,
  ) =>
      switch (n) {
        1 => r.copyWith(w1Id: v),
        2 => r.copyWith(w2Id: v),
        _ => r.copyWith(w3Id: v),
      };
}

// ─────────────────────────────────────────────────────────────────────────────
// Step 6 — review (`:1523-1593`)
// ─────────────────────────────────────────────────────────────────────────────

class MarriageStep6 extends StatelessWidget {
  const MarriageStep6({
    super.key,
    required this.state,
    required this.documentNo,
    required this.formatLak,
  });

  final MarriageFormViewState state;
  final String documentNo;
  final String Function(int?) formatLak;

  @override
  Widget build(BuildContext context) {
    final MarriageFormData f = state.form;
    final String dash = _t(context, 'dash');
    String or(String v) => v.isEmpty ? dash : v;

    String nationalityLabel(String code) {
      for (final Object o in state.nationalities.options) {
        final dynamic opt = o;
        if (opt.value == code) return opt.label as String;
      }
      return dash;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        MarriageNote(
          text: _t(context, 'reviewNote'),
          tone: MarriageNoteTone.amber,
          icon: 'AlertCircle',
        ),
        const SizedBox(height: AppSpacing.gap20),
        MarriageReviewCard(
          title: _t(context, 'reviewBetrothal'),
          rows: <(String, String)>[
            (
              _t(context, 'betrothalRecordNo'),
              f.linkedRecord?.recordNo ?? _t(context, 'autoGenerated'),
            ),
            (
              _t(context, 'bridePriceCash'),
              f.betrothal.bridePriceCash.isEmpty
                  ? dash
                  : formatLak(int.tryParse(f.betrothal.bridePriceCash)),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.gap20),
        MarriageReviewCard(
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
        MarriageReviewCard(
          title: _t(context, 'reviewSpouseA'),
          rows: <(String, String)>[
            (_t(context, 'reviewName'), or(f.spouseA.fullName)),
            (
              _t(context, 'reviewNationality'),
              nationalityLabel(f.spouseA.nationality),
            ),
            (_t(context, 'reviewIdPassport'), or(f.spouseA.idOrPassport)),
          ],
        ),
        const SizedBox(height: AppSpacing.gap20),
        MarriageReviewCard(
          title: _t(context, 'reviewSpouseB'),
          rows: <(String, String)>[
            (_t(context, 'reviewName'), or(f.spouseB.fullName)),
            (
              _t(context, 'reviewNationality'),
              nationalityLabel(f.spouseB.nationality),
            ),
            (_t(context, 'reviewIdPassport'), or(f.spouseB.idOrPassport)),
          ],
        ),
        const SizedBox(height: AppSpacing.gap20),
        MarriageReviewCard(
          title: _t(context, 'reviewRegistration'),
          rows: <(String, String)>[
            (_t(context, 'reviewDateOfMarriage'), or(f.reg.dateOfMarriage)),
            (_t(context, 'reviewPlace'), or(f.reg.placeOfRegistration)),
            (
              _t(context, 'reviewWitnesses'),
              or(<String>[f.reg.w1Name, f.reg.w2Name, f.reg.w3Name]
                  .where((String v) => v.isNotEmpty)
                  .join(', ')),
            ),
          ],
        ),
        // `:1571-1577` — **the fee card. Marriage has one; Divorce does NOT**
        // (`F3-AC-73`), and `divorce.ts` has no `feeSectionTitle` key, which is
        // the independent confirmation.
        const SizedBox(height: AppSpacing.gap20),
        MarriageReviewCard(
          title: _t(context, 'feeSectionTitle'),
          rows: <(String, String)>[
            for (final MarriageQuoteLine line
                in state.quote.data?.lines ?? const <MarriageQuoteLine>[])
              (line.label, formatLak(line.amountLak)),
            (
              _t(context, 'feeTotal'),
              state.quote.loading ? '…' : formatLak(state.quote.data?.feeLak),
            ),
          ],
        ),
        if (state.quote.error != null)
          FieldErrorText(
            show: true,
            message: '${marriageSay(context, 'quoteError')} '
                '${state.quote.error}',
          ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Step 7 — payment (`:1597-1606`)
// ─────────────────────────────────────────────────────────────────────────────

class MarriageStep7 extends StatelessWidget {
  const MarriageStep7({
    super.key,
    required this.state,
    required this.documentNo,
    required this.onChanged,
  });

  final MarriageFormViewState state;
  final String documentNo;
  final ValueChanged<PaymentDraft> onChanged;

  @override
  Widget build(BuildContext context) {
    // F1's draft-mode surface, **mounted unmodified** (`F3-AC-16`).
    return DraftPaymentSection(
      amount: state.quote.data?.feeLak ?? 0,
      serviceName: _t(context, 'serviceName'),
      value: state.form.payment,
      onChanged: onChanged,
      reference: state.caseRef.isNotEmpty ? state.caseRef : documentNo,
      breakdown: <PaymentBreakdownItem>[
        for (final MarriageQuoteLine line
            in state.quote.data?.lines ?? const <MarriageQuoteLine>[])
          PaymentBreakdownItem(label: line.label, amount: line.amountLak),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Small pieces
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
  Widget build(BuildContext context) {
    return Semantics(
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
}

class _BackLink extends StatelessWidget {
  const _BackLink({
    required this.label,
    required this.onTap,
    required this.keyName,
  });

  final String label;
  final VoidCallback onTap;
  final String keyName;

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
  late final TextEditingController _c = TextEditingController(text: widget.value);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
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
              key: const Key('marriage.recordSearch'),
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

/// `:1210-1224` — the records ERROR state. **This one DOES have a retry**, and
/// that is not a contradiction of § 6.3: the picker is a page-local query with
/// an `error` the page destructures, unlike `useRefList`, which does not.
/// `F3-AC-50` asserts it against `F3-AC-25`'s absence.
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
  Widget build(BuildContext context) {
    return Container(
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
              key: const Key('marriage.recordsRetry'),
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
}

/// `:1225-1228` — **the only reachable state** of the picker.
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
                  key: const Key('marriage.betrothalChange'),
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
