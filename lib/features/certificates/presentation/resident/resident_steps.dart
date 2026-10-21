/// `ResidentCertificatePage.tsx:715-1030` — the six step bodies.
///
/// One widget per step, each taking the cubit and reading the slice of state it
/// renders. They are `StatelessWidget`s over a [ResidentFormViewState] rather
/// than `BlocBuilder`s of their own: the page rebuilds the whole body on every
/// state change, which is what a React component does, and it keeps every
/// widget here pumpable with a literal state and **no container**
/// (`F1-AC-10`).
library;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../presentation/forms/widgets/date_field.dart';
import '../../../../presentation/forms/widgets/location_fields_view.dart';
import '../../../../presentation/forms/widgets/option.dart';
import '../../../../presentation/forms/widgets/reference_field_state.dart';
import '../../../../presentation/forms/widgets/reference_select_view.dart';
import '../../../../presentation/payment/draft_payment_section.dart';
import '../../../../presentation/theme/app_colors.dart';
import '../../../reference/domain/entities/lookup_key.dart';
import '../../../reference/domain/entities/lookup_option.dart';
import '../../../wallet/domain/entities/payment_method.dart';
import '../../../../i18n/i18n.dart';
import 'resident_fields.dart';
import 'resident_form_state.dart';
import 'resident_form_cubit.dart';

/// `:764-766`, `:942-944`, `:969-971`, `:996-998` — the four small section
/// headings inside a step body.
class ResidentHeading extends StatelessWidget {
  const ResidentHeading({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) => Text(
        text.toUpperCase(),
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          letterSpacing: 1.1,
          color: AppColors.gray500,
        ),
      );
}

const SizedBox _gap = SizedBox(height: 20);

/// `:716-781` — Step 1, Verify Identity.
class ResidentStep1 extends StatelessWidget {
  const ResidentStep1({
    super.key,
    required this.cubit,
    required this.state,
    this.pickFile = pickResidentFile,
  });

  final ResidentFormCubit cubit;
  final ResidentFormViewState state;
  final ResidentFilePicker pickFile;

  @override
  Widget build(BuildContext context) {
    final ReferenceFieldState nationalities = cubit.referenceStateOf(
      state.nationalities,
      LookupKey.reference('nationality'),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        ResidentNotice.amber(text: 'resident.step1Notice'.tr(context: context)),
        _gap,
        ResidentUploadBox(
          label: 'resident.frontIdLabel'.tr(context: context),
          sublabel: 'resident.idSublabel'.tr(context: context),
          file: state.form.frontId,
          onChanged: cubit.setFrontId,
          pickFile: pickFile,
        ),
        _gap,
        ResidentUploadBox(
          label: 'resident.backIdLabel'.tr(context: context),
          sublabel: 'resident.idSublabel'.tr(context: context),
          file: state.form.backId,
          onChanged: cubit.setBackId,
          pickFile: pickFile,
        ),
        // `:739-746` — the blue in-flight banner. It appears when the read
        // starts and **vanishes with nothing in its place** when it fails; that
        // silence is the only signal a 404 gives (specs.md Finding C).
        if (state.detecting) ...<Widget>[
          _gap,
          _DetectingBanner(),
        ],
        // `:747-761` — `{detected && !detecting && (…)}`. **This** is the
        // conditional block, on step 1, and it is ABSENT after a 404
        // (specs.md § 6.4(c), `F1-AC-40`). It is not the step-2 banner.
        if (state.detected && !state.detecting) ...<Widget>[
          _gap,
          _DetectedSummary(
            name: state.form.citizenName,
            age: state.form.age,
            nationality: nationalities.labelOf(state.form.nationality),
          ),
        ],
        _gap,
        ResidentHeading(
          text: 'resident.familyBookHeading'.tr(context: context),
        ),
        const SizedBox(height: 12),
        ResidentUploadBox(
          label: 'resident.familyBookCoverLabel'.tr(context: context),
          sublabel: 'resident.familyBookSublabel'.tr(context: context),
          file: state.form.familyBookCover,
          onChanged: cubit.setFamilyBookCover,
          // The one upload control on this step that carries a `path` (`:772`).
          path: 'household_reference.family_book_upload',
          pickFile: pickFile,
        ),
        _gap,
        ResidentUploadBox(
          label: 'resident.familyBookContentsLabel'.tr(context: context),
          sublabel: 'resident.familyBookSublabel'.tr(context: context),
          file: state.form.familyBookContents,
          onChanged: cubit.setFamilyBookContents,
          pickFile: pickFile,
        ),
      ],
    );
  }
}

class _DetectingBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) => ResidentNotice.blue(
        text: 'resident.readingId'.tr(context: context),
      );
}

/// `:748-760` — the green step-**1** detection summary.
class _DetectedSummary extends StatelessWidget {
  const _DetectedSummary({
    required this.name,
    required this.age,
    required this.nationality,
  });

  final String name;
  final String age;
  final String nationality;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.successSoft,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.successBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'resident.detailsDetected'.tr(context: context),
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.success,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'resident.detectedSummary'.tr(
                context: context,
                namedArgs: <String, String>{
                  'name': name,
                  'age': age,
                  'nationality': nationality,
                },
              ),
              style: const TextStyle(fontSize: 12, color: AppColors.success),
            ),
          ],
        ),
      );
}

/// `:784-851` — Step 2, Applicant.
class ResidentStep2 extends StatelessWidget {
  const ResidentStep2({
    super.key,
    required this.cubit,
    required this.state,
    this.pickFile = pickResidentFile,
  });

  final ResidentFormCubit cubit;
  final ResidentFormViewState state;
  final ResidentFilePicker pickFile;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        _RefNoCard(reference: state.draft?.referenceNo),
        _gap,
        // ── `:799-804` ────────────────────────────────────────────────────
        //
        // **UNCONDITIONAL.** It sits in the bare `{step === 2 && (` block
        // opened at `:784` with no `detected` guard anywhere between `:784` and
        // `:850`. specs.md § 6.4(d) corrects F0's Q-8, which said this banner
        // was absent after a 404; it is not.
        //
        // It reads "Auto-filled from your ID — please review…" above three
        // fields that were auto-filled with nothing, and **that reads like a
        // bug**. It is the source's behaviour. A port that added
        // `if (detected)` here would have diverged from the source to make a
        // gate go green, which is the exact inversion the fidelity instrument
        // exists to catch (`F1-AC-41`).
        ResidentNotice.green(
          text: 'resident.autoFilledNotice'.tr(context: context),
        ),
        _gap,
        ResidentInputField(
          label: 'resident.citizenNameLabel'.tr(context: context),
          value: state.form.citizenName,
          placeholder: 'resident.citizenNamePlaceholder'.tr(context: context),
          onChanged: (String v) => cubit.setField(
            (ResidentFormData f) => f.copyWith(citizenName: v),
            path: 'applicant.citizen_name',
          ),
          required: true,
          path: 'applicant.citizen_name',
        ),
        _gap,
        // Forms v2 — the optional Latin split names, passport/ID style. Both
        // OPTIONAL: no `required`, and absent keys when left blank.
        ResidentInputField(
          label: 'forms.surnameLabel'.tr(context: context),
          value: state.form.surname,
          placeholder: 'forms.surnamePlaceholder'.tr(context: context),
          onChanged: (String v) => cubit.setField(
            (ResidentFormData f) => f.copyWith(surname: v),
            path: 'applicant.surname',
          ),
          path: 'applicant.surname',
        ),
        _gap,
        ResidentInputField(
          label: 'forms.givenNameLabel'.tr(context: context),
          value: state.form.givenName,
          placeholder: 'forms.givenNamePlaceholder'.tr(context: context),
          onChanged: (String v) => cubit.setField(
            (ResidentFormData f) => f.copyWith(givenName: v),
            path: 'applicant.given_name',
          ),
          path: 'applicant.given_name',
        ),
        _gap,
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Expanded(
              child: ResidentInputField(
                label: 'resident.ageLabel'.tr(context: context),
                value: state.form.age,
                placeholder: 'resident.agePlaceholder'.tr(context: context),
                numeric: true,
                maxLength: 3,
                onChanged: cubit.setAge,
                required: true,
                path: 'applicant.age',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ReferenceSelectView(
                label: Text('resident.nationalityLabel'.tr(context: context)),
                source: cubit.referenceStateOf(
                  state.nationalities,
                  LookupKey.reference('nationality'),
                ),
                value: state.form.nationality,
                placeholder:
                    'resident.selectPlaceholder'.tr(context: context),
                onChanged: (String v) => cubit.setField(
                  (ResidentFormData f) => f.copyWith(nationality: v),
                  path: 'applicant.nationality',
                ),
                required: true,
                path: 'applicant.nationality',
              ),
            ),
          ],
        ),
        _gap,
        ResidentInputField(
          label: 'resident.occupationLabel'.tr(context: context),
          value: state.form.occupation,
          placeholder: 'resident.occupationPlaceholder'.tr(context: context),
          onChanged: (String v) => cubit.setField(
            (ResidentFormData f) => f.copyWith(occupation: v),
            path: 'applicant.occupation',
          ),
          path: 'applicant.occupation',
        ),
        _gap,
        ResidentUploadBox(
          label: 'resident.pictureLabel'.tr(context: context),
          sublabel: 'resident.pictureSublabel'.tr(context: context),
          file: state.form.picture,
          onChanged: cubit.setPicture,
          // `height="h-48"` — the one upload box that is taller (`:847`).
          height: 192,
          path: 'applicant.photo',
          pickFile: pickFile,
        ),
      ],
    );
  }
}

/// `:787-797` — the read-only Ref. No. card.
class _RefNoCard extends StatelessWidget {
  const _RefNoCard({required this.reference});

  final String? reference;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.gray100),
        ),
        child: Row(
          children: <Widget>[
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    'resident.refNoLabel'.tr(context: context).toUpperCase(),
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.6,
                      color: AppColors.gray400Inline,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    // `draft?.reference_no ?? "—"` — `:791`. An em dash until
                    // the case exists, which on a first visit is always.
                    reference ?? '—',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.gray800,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.gray100,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                'resident.autoGenerated'.tr(context: context),
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: AppColors.gray400Inline,
                ),
              ),
            ),
          ],
        ),
      );
}

/// `:854-893` — Step 3, Location & Authority.
class ResidentStep3 extends StatelessWidget {
  const ResidentStep3({super.key, required this.cubit, required this.state});

  final ResidentFormCubit cubit;
  final ResidentFormViewState state;

  @override
  Widget build(BuildContext context) {
    final Lang lang = Localizations.localeOf(context).languageCode == 'lo'
        ? Lang.lo
        : Lang.en;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        // `valueMode="id"` — the header trio ARE location UUIDs, unlike
        // `applicant.current_village_id` on step 4 (`F1-AC-69`).
        LocationFieldsView(
          province: state.form.province,
          district: state.form.district,
          village: state.form.villageName,
          villageLabel: 'resident.villageNameLabel'.tr(context: context),
          required: true,
          paths: const LocationPaths(
            province: 'header.province_id',
            district: 'header.district_id',
            village: 'header.village_id',
          ),
          provinces: _level(state.provinces, cubit.loadProvinces, lang),
          districts: _level(
            state.districts,
            () => cubit.loadDistricts(state.form.province),
            lang,
          ),
          villages: _level(
            state.villages,
            () => cubit.loadVillages(state.form.district),
            lang,
          ),
          onChanged: (LocationPatch p) => cubit.setLocation(
            province: p.province,
            district: p.district,
            village: p.village,
          ),
        ),
        _gap,
        ResidentInputField(
          label: 'resident.villageChiefLabel'.tr(context: context),
          value: state.form.villageChiefName,
          placeholder: 'resident.villageChiefPlaceholder'.tr(context: context),
          onChanged: (String v) => cubit.setField(
            (ResidentFormData f) => f.copyWith(villageChiefName: v),
            path: 'certifying_authority.village_chief_name',
          ),
          // **Not `required`** (`:877-883`) — the one `certifying_authority.*`
          // field the wizard lets you leave blank, and `canProceed`'s step 3
          // does not check it either (`resident_form_state.dart`'s note 3).
          path: 'certifying_authority.village_chief_name',
        ),
        _gap,
        ResidentInputField(
          label: 'resident.certifyingJurisdictionLabel'.tr(context: context),
          value: state.form.certifyingJurisdiction,
          placeholder:
              'resident.certifyingJurisdictionPlaceholder'.tr(context: context),
          onChanged: (String v) => cubit.setField(
            (ResidentFormData f) => f.copyWith(certifyingJurisdiction: v),
            path: 'certifying_authority.certifying_district',
          ),
          required: true,
          path: 'certifying_authority.certifying_district',
        ),
      ],
    );
  }

  /// `LookupOption` -> [Option] for a location level.
  ///
  /// **`value` is the row's `id`, not its `code`** — `valueMode="id"` (`:857`),
  /// and it is the whole difference between the header trio and every other
  /// reference-backed control on this page, which bind `code`
  /// (`reference_field_state.dart:103`). Server order, no re-sort, no `active`
  /// filter (L-3 / L-4).
  LocationLevel _level(
    ResidentLocationLevel l,
    VoidCallback retry,
    Lang lang,
  ) =>
      LocationLevel(
        rows: <Option>[
          for (final LookupOption row in l.rows)
            Option(
              value: row.id,
              label: text(row.label, lang),
              sub: lang == Lang.lo ? row.label.en : row.label.lo,
            ),
        ],
        busy: l.busy,
        failed: l.failed,
        onRetry: l.failed ? retry : null,
      );
}

/// `:896-937` — Step 4, Current Residence.
class ResidentStep4 extends StatelessWidget {
  const ResidentStep4({super.key, required this.cubit, required this.state});

  final ResidentFormCubit cubit;
  final ResidentFormViewState state;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          ResidentNotice.blue(
            text: 'resident.step4Notice'.tr(context: context),
          ),
          _gap,
          // **FREE TEXT despite the `_id` suffix** (`:904-911`, `F1-AC-69`).
          // A plain input, not a `ReferenceSelectView` and not `LocationFields`
          // — the wire key `applicant.current_village_id` never carries a
          // location UUID. A port that "corrected" the inconsistency FAILS.
          ResidentInputField(
            label: 'resident.currentVillageLabel'.tr(context: context),
            value: state.form.currentVillage,
            placeholder:
                'resident.currentVillagePlaceholder'.tr(context: context),
            onChanged: (String v) => cubit.setField(
              (ResidentFormData f) => f.copyWith(currentVillage: v),
              path: 'applicant.current_village_id',
            ),
            required: true,
            path: 'applicant.current_village_id',
          ),
          _gap,
          ResidentInputField(
            label: 'resident.houseNoLabel'.tr(context: context),
            value: state.form.houseNo,
            placeholder: 'resident.houseNoPlaceholder'.tr(context: context),
            onChanged: (String v) => cubit.setField(
              (ResidentFormData f) => f.copyWith(houseNo: v),
              path: 'applicant.house_no',
            ),
            required: true,
            path: 'applicant.house_no',
          ),
          _gap,
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              // `unit` FIRST, then `group` (`:921-934`) — the reverse of their
              // order in `FormData` and in `buildFormData`.
              Expanded(
                child: ResidentInputField(
                  label: 'resident.unitLabel'.tr(context: context),
                  value: state.form.unitNuayBan,
                  placeholder: 'resident.unitPlaceholder'.tr(context: context),
                  onChanged: (String v) => cubit.setField(
                    (ResidentFormData f) => f.copyWith(unitNuayBan: v),
                    path: 'applicant.unit_nuay',
                  ),
                  path: 'applicant.unit_nuay',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ResidentInputField(
                  label: 'resident.groupLabel'.tr(context: context),
                  value: state.form.groupKhum,
                  placeholder: 'resident.groupPlaceholder'.tr(context: context),
                  onChanged: (String v) => cubit.setField(
                    (ResidentFormData f) => f.copyWith(groupKhum: v),
                    path: 'applicant.group_khum',
                  ),
                  path: 'applicant.group_khum',
                ),
              ),
            ],
          ),
        ],
      );
}

/// `:940-1019` — Step 5, Household, Parentage & Purpose.
class ResidentStep5 extends StatelessWidget {
  const ResidentStep5({super.key, required this.cubit, required this.state});

  final ResidentFormCubit cubit;
  final ResidentFormViewState state;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          ResidentHeading(
            text: 'resident.householdHeading'.tr(context: context),
          ),
          const SizedBox(height: 12),
          ResidentInputField(
            label: 'resident.censusBookNoLabel'.tr(context: context),
            value: state.form.censusBookNo,
            placeholder:
                'resident.censusBookNoPlaceholder'.tr(context: context),
            onChanged: (String v) => cubit.setField(
              (ResidentFormData f) => f.copyWith(censusBookNo: v),
              path: 'household_reference.household_no',
            ),
            required: true,
            path: 'household_reference.household_no',
          ),
          _gap,
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(
                child: DateField(
                  label: Text(
                    'resident.censusBookDateLabel'.tr(context: context),
                  ),
                  value: state.form.censusBookDate,
                  onChanged: (String v) => cubit.setField(
                    (ResidentFormData f) => f.copyWith(censusBookDate: v),
                    path: 'household_reference.household_issued_at',
                  ),
                  path: 'household_reference.household_issued_at',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ResidentInputField(
                  label:
                      'resident.censusDistrictProvinceLabel'.tr(context: context),
                  value: state.form.censusDistrictProvince,
                  placeholder: 'resident.censusDistrictProvincePlaceholder'
                      .tr(context: context),
                  onChanged: (String v) => cubit.setField(
                    (ResidentFormData f) => f.copyWith(censusDistrictProvince: v),
                    path: 'household_reference.household_district',
                  ),
                  path: 'household_reference.household_district',
                ),
              ),
            ],
          ),
          _gap,
          ResidentHeading(
            text: 'resident.parentageHeading'.tr(context: context),
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(
                child: ResidentInputField(
                  label: 'resident.fatherLabel'.tr(context: context),
                  value: state.form.fatherName,
                  placeholder:
                      'resident.fatherPlaceholder'.tr(context: context),
                  onChanged: (String v) => cubit.setField(
                    (ResidentFormData f) => f.copyWith(fatherName: v),
                    path: 'parentage.father_name',
                  ),
                  path: 'parentage.father_name',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ResidentInputField(
                  label: 'resident.motherLabel'.tr(context: context),
                  value: state.form.motherName,
                  placeholder:
                      'resident.motherPlaceholder'.tr(context: context),
                  onChanged: (String v) => cubit.setField(
                    (ResidentFormData f) => f.copyWith(motherName: v),
                    path: 'parentage.mother_name',
                  ),
                  path: 'parentage.mother_name',
                ),
              ),
            ],
          ),
          _gap,
          ResidentInputField(
            label: 'resident.nativePlaceLabel'.tr(context: context),
            value: state.form.nativePlace,
            placeholder: 'resident.nativePlacePlaceholder'.tr(context: context),
            onChanged: (String v) => cubit.setField(
              (ResidentFormData f) => f.copyWith(nativePlace: v),
              path: 'parentage.native_place',
            ),
            path: 'parentage.native_place',
          ),
          _gap,
          ResidentHeading(text: 'resident.purposeHeading'.tr(context: context)),
          const SizedBox(height: 12),
          ReferenceSelectView(
            label: Text('resident.purposeLabel'.tr(context: context)),
            source: cubit.referenceStateOf(
              state.purposes,
              LookupKey.reference('certificate-purpose'),
            ),
            value: state.form.purpose,
            placeholder: 'resident.purposePlaceholder'.tr(context: context),
            onChanged: (String v) => cubit.setField(
              (ResidentFormData f) => f.copyWith(purpose: v),
              path: 'purpose.purpose',
            ),
            required: true,
            path: 'purpose.purpose',
          ),
          // `{form.purpose === "other" && (…)}` — `:1008`. Rendered only for
          // `"other"`, capped at 100, and **carrying no `path`** (`F1-AC-70`).
          if (state.form.purpose == 'other') ...<Widget>[
            _gap,
            ResidentInputField(
              label: 'resident.purposeOtherLabel'.tr(context: context),
              value: state.form.purposeOther,
              placeholder:
                  'resident.purposeOtherPlaceholder'.tr(context: context),
              onChanged: cubit.setPurposeOther,
              maxLength: 100,
              required: true,
            ),
          ],
        ],
      );
}

/// `:1022-1030` — Step 6, Payment.
///
/// **Draft mode**: `PaymentSection` mounted with no `applicationId`
/// (`F1-AC-71`). `reference` is passed because the source passes it, and the
/// draft half does not render it (see [DraftPaymentSection.reference]).
class ResidentStep6 extends StatelessWidget {
  const ResidentStep6({super.key, required this.cubit, required this.state});

  final ResidentFormCubit cubit;
  final ResidentFormViewState state;

  @override
  Widget build(BuildContext context) {
    final Lang lang = Localizations.localeOf(context).languageCode == 'lo'
        ? Lang.lo
        : Lang.en;

    return DraftPaymentSection(
      amount: state.fee,
      // `serviceQuery.data ? text(name, lang) : t("paymentServiceName")` —
      // `:1025`.
      serviceName: state.service.data == null
          ? 'resident.paymentServiceName'.tr(context: context)
          : text(state.service.data!.name, lang),
      value: state.form.payment,
      onChanged: cubit.setPayment,
      reference: state.draft?.referenceNo,
      bankRailNote: _bankRailNote(state.methods.data),
    );
  }

  /// `enabled.find((m) => m.kind === "bank")?.note ?? ""` —
  /// `PaymentSection.tsx:214`. Resolved here because the draft surface takes it
  /// as a parameter and does not read `/payment-methods` itself.
  static String _bankRailNote(List<PaymentMethod>? methods) {
    for (final PaymentMethod m in methods ?? const <PaymentMethod>[]) {
      if (m.enabled && m.kind == PaymentMethodKind.bank) return m.note;
    }
    return '';
  }
}
