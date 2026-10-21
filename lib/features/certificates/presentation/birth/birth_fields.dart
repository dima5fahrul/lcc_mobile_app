/// `BirthDeclarationPage.tsx:140-581` — the page's own field widgets, its
/// page-local `TXT` table, and its `ParentSection`.
///
/// ## Why these are duplicated rather than shared
///
/// `InputField`, `SelectField`, `UploadBox`, `FieldLabel` and `SectionLabel`
/// are **duplicated in the source itself**: Birth defines them at `:273-412`
/// and Death defines byte-identical copies at `:267-406`. The port mirrors the
/// source (`specs.md` § 6.2). The legitimate sharing is through F0b's kernel —
/// `DateField`, `ReferenceSelectView`, `LocationFieldsView`, `ValidationScope`,
/// `FieldErrorMarker` — and both pages consume it unchanged, which is what F1
/// proved and what `F2-AC-13` re-asserts with two more consumers.
///
/// ## `ParentSection` is the one § 6.2 names first
///
/// [BirthParentSection] threads a `required` prop and its labels come from a
/// different key scheme than Death's. Death's `ParentSection` has **no
/// `required` parameter at all**. `specs.md` § 11 item 1 tells the human
/// reviewer to check "is there one `parentData` or two?" before anything else;
/// the same question applies here, and the answer is two.
///
/// ## `TXT` is page-local and stays that way
///
/// [kBirthTxt] holds the nine bilingual sentences `:140-156` declares. They are
/// **not** `birth` namespace keys in the source and must not be promoted into
/// one — that would take the count from 152 to 161 and `F2-AC-78` would catch
/// it. Seven of the nine are byte-identical to Death's, and § 6.2 still forbids
/// sharing them: two page-local tables in the source, two in the port.
library;

import 'package:easy_localization/easy_localization.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../../../i18n/i18n.dart';
import '../../../../presentation/forms/validation/field_error.dart';
import '../../../../presentation/forms/validation/validation_scope.dart';
import '../../../../presentation/forms/widgets/date_field.dart';
import '../../../../presentation/forms/widgets/field_base.dart';
import '../../../../presentation/forms/widgets/field_label.dart';
import '../../../../presentation/forms/widgets/location_fields_view.dart';
import '../../../../presentation/forms/widgets/reference_field_state.dart';
import '../../../../presentation/forms/widgets/reference_select_view.dart';
import '../../../../presentation/icons/lucide_icon.dart';
import '../../../../presentation/theme/app_colors.dart';
import '../../../application/domain/entities/picked_attachment.dart';
import '../../../session/domain/entities/bilingual.dart';
import 'birth_form_cubit.dart';
import 'birth_form_state.dart';

/// `:140-156` — `TXT`, **nine** page-local bilingual sentences.
///
/// `TXT.paid` (`:155`) is declared, translated, and **referenced nowhere** —
/// `grep -n "TXT\." BirthDeclarationPage.tsx` returns 8 hits and none is
/// `TXT.paid`. It is the sixth dead surface found in this project by
/// measurement and `F2-AC-82` requires it **not** to be ported, so it is absent
/// from this table. `FU-5` records it.
class BirthTxt {
  const BirthTxt._();

  static const Bilingual loading =
      Bilingual(en: 'Loading the service…', lo: 'ກຳລັງໂຫຼດບໍລິການ…');
  static const Bilingual loadFailed = Bilingual(
    en: 'We could not load this service right now.',
    lo: 'ພວກເຮົາບໍ່ສາມາດໂຫຼດບໍລິການນີ້ໄດ້ໃນຕອນນີ້.',
  );
  static const Bilingual retry = Bilingual(en: 'Retry', lo: 'ລອງໃໝ່');
  static const Bilingual uploadTap =
      Bilingual(en: 'Tap to upload', lo: 'ແຕະເພື່ອອັບໂຫຼດ');
  static const Bilingual fileSublabel = Bilingual(
    en: 'Photo or scan • JPG, PNG',
    lo: 'ຮູບຖ່າຍ ຫຼື ສະແກນ • JPG, PNG',
  );
  static const Bilingual hospitalNotice = Bilingual(
    en: 'Hospital / clinic birth notice',
    lo: 'ໃບແຈ້ງເກີດຈາກໂຮງໝໍ / ຄລີນິກ',
  );
  static const Bilingual payNow = Bilingual(en: 'Pay {amount}', lo: 'ຈ່າຍ {amount}');
  static const Bilingual receipt =
      Bilingual(en: 'Receipt No.', lo: 'ເລກທີ່ໃບຮັບເງິນ');
}

/// `:158-162` — `fill(template, params)`.
String birthFill(String template, Map<String, String> params) {
  String out = template;
  params.forEach((String k, String v) => out = out.split('{$k}').join(v));
  return out;
}

/// One of [BirthTxt]'s page-local sentences, in the reader's language.
///
/// `text(TXT.x, lang)` — the frozen `lib/i18n/i18n.dart:90` helper, imported
/// rather than reimplemented.
String birthTxtOf(BuildContext context, Bilingual value) => text(
      value,
      Localizations.localeOf(context).languageCode == 'lo' ? Lang.lo : Lang.en,
    );

/// `'birth.<key>'.tr(context: context)`.
///
/// Every string this page renders comes through here, so the namespace appears
/// once per page rather than at 150 call sites — and `F2-AC-37`'s
/// "no `death` key is read from `birth/`" is a property of one function instead
/// of a property of every line.
String birthT(BuildContext context, String key) =>
    'birth.$key'.tr(context: context);

// ─────────────────────────────────────────────────────────────────────────────
// `:282-339` — InputField / SelectField
// ─────────────────────────────────────────────────────────────────────────────

/// `:282-308` — `InputField`.
class BirthInputField extends StatefulWidget {
  const BirthInputField({
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

  /// `inputMode` (`:287`) — a keyboard hint, **not** a filter. The only digit
  /// strip on this page is `birthOrder`'s and it lives in the cubit (`:1152`).
  final bool numeric;

  /// `maxLength={2}` on `birthOrder` and nowhere else (`:1151`).
  final int? maxLength;

  final String? path;

  @override
  State<BirthInputField> createState() => _BirthInputFieldState();
}

class _BirthInputFieldState extends State<BirthInputField> {
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
  void didUpdateWidget(BirthInputField oldWidget) {
    super.didUpdateWidget(oldWidget);
    // `birthOrder` transforms on the way in, so the controller is corrected
    // when what comes back differs from what was typed — caret at the end,
    // which is what a React controlled input does for free.
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
              // `:301` — clear, then change, in that order.
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

/// `:310-339` — `SelectField`, the **plain** choice control.
///
/// Distinct from the kernel's [ReferenceSelectView]: this one takes a literal
/// option list rather than a reference-backed [ReferenceFieldState], and it is
/// used for `GENDERS` only (`:1119`, `:1168`). Birth's `GENDERS` are i18n keys;
/// Death's are bilingual literals, which is why the two pages' gender controls
/// are fed differently even though this widget's shape matches Death's copy.
class BirthSelectField extends StatelessWidget {
  const BirthSelectField({
    super.key,
    required this.label,
    required this.value,
    required this.options,
    required this.placeholder,
    required this.onChanged,
    this.required = false,
    this.path,
  });

  final String label;
  final String value;
  final List<({String value, String label})> options;
  final String placeholder;
  final ValueChanged<String> onChanged;
  final bool required;
  final String? path;

  @override
  Widget build(BuildContext context) {
    final FieldErrorState error = ValidationScope.fieldErrorOf(
      context,
      path: path,
      required: required,
      value: value,
    );
    final void Function(String?) clearServerError =
        ValidationScope.clearServerErrorOf(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        FieldLabel(label: Text(label), required: required),
        FieldErrorMarker(
          child: Container(
            decoration: fieldDecoration(hasError: error.hasError),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                isExpanded: true,
                value: value.isEmpty ? null : value,
                hint: Text(placeholder, style: kFieldPlaceholderStyle),
                icon: const LucideIcon(name: 'chevron-down', size: 16),
                style: kFieldTextStyle,
                items: <DropdownMenuItem<String>>[
                  for (final ({String value, String label}) o in options)
                    DropdownMenuItem<String>(
                      value: o.value,
                      child: Text(o.label, style: kFieldTextStyle),
                    ),
                ],
                onChanged: (String? v) {
                  if (v == null) return;
                  clearServerError(path);
                  onChanged(v);
                },
              ),
            ),
          ),
        ),
        FieldErrorText(show: error.hasError, message: error.message),
      ],
    );
  }
}

/// `:341-404` — `UploadBox`.
///
/// **R-21, with a sharper edge than Resident had.** The source's
/// `accept="image/*,application/pdf"` (`:366`) names PDF explicitly, which makes
/// `FileType.custom(allowedExtensions: ['jpg','png','pdf'])` *read* like a
/// faithful transcription. It is the opposite: in a browser `accept` filters the
/// picker's default view and **rejects nothing**, while `FileType.custom` is a
/// hard filter with no escape hatch. `handleFile` (`:353-361`) reads
/// `files?.[0]`, calls `FileReader`, and inspects neither `type` nor `size`.
///
/// So this control opens the picker with **`FileType.any`, no
/// `allowedExtensions`, no size check and no count check** — `F2-AC-55`,
/// `F2-AC-56`, `F2-AC-57`. The test case is `.docx`, not `.pdf`: a "faithful"
/// extension list would pass a PDF test and still be wrong.
class BirthUploadBox extends StatelessWidget {
  const BirthUploadBox({
    super.key,
    required this.label,
    required this.sublabel,
    required this.file,
    required this.onChanged,
    this.required = true,
    this.path,
    this.pickFile = birthPickFile,
  });

  final String label;
  final String sublabel;
  final PickedAttachment? file;
  final ValueChanged<PickedAttachment?> onChanged;
  final bool required;
  final String? path;

  /// Injectable so a widget test can drive a `.docx` through the real code
  /// path without a platform channel (`F2-AC-55` is behavioural and
  /// picker-agnostic).
  final Future<PickedAttachment?> Function() pickFile;

  @override
  Widget build(BuildContext context) {
    final Lang lang = Localizations.localeOf(context).languageCode == 'lo'
        ? Lang.lo
        : Lang.en;
    final FieldErrorState error = ValidationScope.fieldErrorOf(
      context,
      path: path,
      required: required,
      value: file == null ? '' : 'picked',
    );
    final void Function(String?) clearServerError =
        ValidationScope.clearServerErrorOf(context);

    if (file != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          FieldLabel(label: Text(label), required: required),
          Container(
            height: 160,
            decoration: BoxDecoration(
              color: AppColors.successSoft,
              border: Border.all(color: AppColors.successRing, width: 2),
              borderRadius: BorderRadius.circular(16),
            ),
            alignment: Alignment.bottomLeft,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: <Widget>[
                const LucideIcon(name: 'circle-check-big', size: 16),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    file!.name,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
                IconButton(
                  icon: const LucideIcon(name: 'x', size: 16),
                  onPressed: () => onChanged(null),
                ),
              ],
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        FieldLabel(label: Text(label), required: required),
        FieldErrorMarker(
          child: GestureDetector(
            onTap: () async {
              final PickedAttachment? picked = await pickFile();
              // `:354` — `if (!picked) return;` then clear, then change.
              if (picked == null) return;
              clearServerError(path);
              onChanged(picked);
            },
            child: Container(
              height: 160,
              decoration: BoxDecoration(
                color: AppColors.gray50,
                border: Border.all(
                  color: error.hasError
                      ? AppColors.dangerBorder
                      : AppColors.gray200,
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: AppColors.primarySoft,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Center(
                      child: LucideIcon(name: 'camera', size: 28),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    text(BirthTxt.uploadTap, lang),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    sublabel,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.gray400Inline,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        FieldErrorText(show: error.hasError, message: error.message),
      ],
    );
  }
}

/// The picker call, with **no filter of any kind**.
///
/// `FileType.any`, no `allowedExtensions`, no size ceiling, no count ceiling —
/// R-21 (`F0` § 6.6.2): *"No code path may reject a picked file on the basis of
/// its extension or MIME type."*
Future<PickedAttachment?> birthPickFile() async {
  final FilePickerResult? result = await FilePicker.platform.pickFiles(
    // `withData` because the multipart POST streams bytes and the web target
    // has no path (`picked_attachment.dart`). **No `type:`, no
    // `allowedExtensions:`** — see this widget's doc comment and `F2-AC-56`.
    withData: true,
  );
  final PlatformFile? f = result?.files.singleOrNull;
  if (f == null) return null;
  return PickedAttachment(name: f.name, bytes: f.bytes, path: f.path);
}

/// `:406-412` — `SectionLabel`.
class BirthSectionLabel extends StatelessWidget {
  const BirthSectionLabel(this.label, {super.key});
  final String label;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Text(
          label.toUpperCase(),
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.muted,
            letterSpacing: 0.8,
          ),
        ),
      );
}

/// `:415-452` — `AddressFields`.
///
/// **Calls `useT("birth")` internally** (`:424`), where Death's takes `t` as an
/// explicit prop (`DeathDeclarationPage.tsx:412`). Measured difference #10, and
/// one of the reasons there are two of these.
///
/// `withHouseNo` exists on the source's signature (`:416`) and is **never
/// passed false** by any call site — a dead parameter, transcribed because it is
/// there. Death's has no such parameter at all (difference #18).
class BirthAddressFields extends StatelessWidget {
  const BirthAddressFields({
    super.key,
    required this.houseNo,
    required this.village,
    required this.district,
    required this.province,
    required this.onChanged,
    required this.provinces,
    required this.districts,
    required this.villages,
    this.withHouseNo = true,
    this.required = true,
    this.villagePath,
  });

  final String houseNo;
  final String village;
  final String district;
  final String province;

  /// `(patch) => …` over the four address fields.
  final void Function({
    String? addrHouseNo,
    String? addrVillage,
    String? addrDistrict,
    String? addrProvince,
  }) onChanged;

  final LocationLevel provinces;
  final LocationLevel districts;
  final LocationLevel villages;

  final bool withHouseNo;
  final bool required;

  /// `:421` — "The schema keeps one address key per section — the village."
  final String? villagePath;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          if (withHouseNo)
            BirthInputField(
              label: birthT(context, 'houseNoLabel'),
              value: houseNo,
              placeholder: birthT(context, 'houseNoPlaceholder'),
              onChanged: (String v) => onChanged(addrHouseNo: v),
            ),
          LocationFieldsView(
            province: province,
            district: district,
            village: village,
            provinces: provinces,
            districts: districts,
            villages: villages,
            required: required,
            paths: LocationPaths(village: villagePath),
            onChanged: (LocationPatch p) => onChanged(
              addrProvince: p.province,
              addrDistrict: p.district,
              addrVillage: p.village,
            ),
          ),
        ],
      );
}

/// `:455-581` — `ParentSection`, mother and father alike.
///
/// ## `required` is threaded, and eight fields are mandatory
///
/// The prop at `:463` reaches nine controls. Death's `ParentSection` takes
/// **no `required` parameter at all** — only `fullName` is mandatory there and
/// everything else is hard-coded optional. That is measured difference #12 and
/// it is why `F2-AC-24` says a single widget with a `required` flag FAILS: the
/// flag would have to be `false` for Death and `true` for Birth on nine
/// different controls, and Death's would additionally need a tenth
/// (`workplace`) that Birth does not render.
///
/// ## The i18n keys are a different scheme, not different values
///
/// `fullNameLabel` / `selectPlaceholder` / `dobLabel` /
/// `additionalDetailsSection` here; `fullName` / `phSelect` / `dobOptional` /
/// `secEducationWork` on Death. No mechanical mapping exists between them
/// (measured difference #11).
class BirthParentSection extends StatelessWidget {
  const BirthParentSection({
    super.key,
    required this.value,
    required this.onChanged,
    required this.cubit,
    required this.prefix,
    this.required = true,
  });

  final BirthParentInfo value;
  final void Function(BirthParentInfo Function(BirthParentInfo), {String? path})
      onChanged;
  final BirthFormCubit cubit;

  /// `"parents"` for the mother — the key the schema validates — and
  /// `"parents.father"` for the father (`:461`).
  final String prefix;

  final bool required;

  String _at(String key) => '$prefix.$key';

  @override
  Widget build(BuildContext context) {
    ReferenceFieldState ref(BirthRefList which) =>
        cubit.referenceStateOf(which);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        BirthInputField(
          label: birthT(context, 'fullNameLabel'),
          value: value.fullName,
          placeholder: birthT(context, 'parentNamePlaceholder'),
          onChanged: (String v) => onChanged(
            (BirthParentInfo p) => p.copyWith(fullName: v),
            path: _at('name'),
          ),
          required: required,
          path: _at('name'),
        ),
        // Forms v2 — the optional Latin split names. The paths compose to
        // `parents.mother.*` for the mother and `parents.father.*` for the
        // father via `prefix` — exactly the guide's keys. Both OPTIONAL.
        BirthInputField(
          label: 'forms.surnameLabel'.tr(context: context),
          value: value.surname,
          placeholder: 'forms.surnamePlaceholder'.tr(context: context),
          onChanged: (String v) => onChanged(
            (BirthParentInfo p) => p.copyWith(surname: v),
            path: _at('surname'),
          ),
          path: _at('surname'),
        ),
        BirthInputField(
          label: 'forms.givenNameLabel'.tr(context: context),
          value: value.givenName,
          placeholder: 'forms.givenNamePlaceholder'.tr(context: context),
          onChanged: (String v) => onChanged(
            (BirthParentInfo p) => p.copyWith(givenName: v),
            path: _at('given_name'),
          ),
          path: _at('given_name'),
        ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Expanded(
              child: DateField(
                label: Text(birthT(context, 'dobLabel')),
                value: value.dob,
                onChanged: (String v) => onChanged(
                  (BirthParentInfo p) => p.copyWith(dob: v),
                  path: _at('dob'),
                ),
                required: required,
                path: _at('dob'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ReferenceSelectView(
                label: Text(birthT(context, 'maritalStatusLabel')),
                source: ref(BirthRefList.marital),
                value: value.maritalStatus,
                placeholder: birthT(context, 'selectPlaceholder'),
                onChanged: (String v) => onChanged(
                  (BirthParentInfo p) => p.copyWith(maritalStatus: v),
                  path: _at('marital_status'),
                ),
                required: required,
                path: _at('marital_status'),
              ),
            ),
          ],
        ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Expanded(
              child: ReferenceSelectView(
                label: Text(birthT(context, 'ethnicityLabel')),
                source: ref(BirthRefList.ethnicity),
                value: value.ethnicity,
                placeholder: birthT(context, 'selectPlaceholder'),
                onChanged: (String v) => onChanged(
                  (BirthParentInfo p) => p.copyWith(ethnicity: v),
                  path: _at('ethnicity'),
                ),
                required: required,
                path: _at('ethnicity'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              // One of the six preset `nationality: "lao"` controls per page
              // that land on RULING 14's path before `/reference/nationality`
              // resolves. F0c fixed the kernel; F2 exercises it (`F2-AC-14`).
              child: ReferenceSelectView(
                label: Text(birthT(context, 'nationalityLabel')),
                source: ref(BirthRefList.nationality),
                value: value.nationality,
                placeholder: birthT(context, 'selectPlaceholder'),
                onChanged: (String v) => onChanged(
                  (BirthParentInfo p) => p.copyWith(nationality: v),
                  path: _at('nationality'),
                ),
                required: required,
                path: _at('nationality'),
              ),
            ),
          ],
        ),
        BirthSectionLabel(birthT(context, 'currentAddressSection')),
        BirthAddressFields(
          houseNo: value.addrHouseNo,
          village: value.addrVillage,
          district: value.addrDistrict,
          province: value.addrProvince,
          provinces: cubit.locationLevel(cubit.state.provinces, context,
              retry: cubit.loadProvinces),
          districts: cubit.locationLevel(cubit.state.districts, context,
              retry: () => cubit.loadDistricts(value.addrProvince)),
          villages: cubit.locationLevel(cubit.state.villages, context,
              retry: () => cubit.loadVillages(value.addrDistrict)),
          required: required,
          villagePath: _at('current_address'),
          onChanged: ({
            String? addrHouseNo,
            String? addrVillage,
            String? addrDistrict,
            String? addrProvince,
          }) =>
              onChanged(
            (BirthParentInfo p) => p.copyWith(
              addrHouseNo: addrHouseNo,
              addrVillage: addrVillage,
              addrDistrict: addrDistrict,
              addrProvince: addrProvince,
            ),
            path: _at('current_address'),
          ),
        ),
        BirthInputField(
          label: birthT(context, 'censusOrIdLabel'),
          value: value.censusOrId,
          placeholder: birthT(context, 'censusOrIdPlaceholder'),
          onChanged: (String v) => onChanged(
            (BirthParentInfo p) => p.copyWith(censusOrId: v),
            path: _at('id_number'),
          ),
          required: required,
          path: _at('id_number'),
        ),
        BirthSectionLabel(birthT(context, 'additionalDetailsSection')),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Expanded(
              child: ReferenceSelectView(
                label: Text(birthT(context, 'ethnicGroupLabel')),
                source: ref(BirthRefList.ethnicGroup),
                value: value.ethnicGroup,
                placeholder: birthT(context, 'selectPlaceholder'),
                onChanged: (String v) => onChanged(
                  (BirthParentInfo p) => p.copyWith(ethnicGroup: v),
                  path: _at('ethnic_group'),
                ),
                path: _at('ethnic_group'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ReferenceSelectView(
                label: Text(birthT(context, 'religionLabel')),
                source: ref(BirthRefList.religion),
                value: value.religion,
                placeholder: birthT(context, 'selectPlaceholder'),
                onChanged: (String v) => onChanged(
                  (BirthParentInfo p) => p.copyWith(religion: v),
                  path: _at('religion'),
                ),
                path: _at('religion'),
              ),
            ),
          ],
        ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Expanded(
              child: ReferenceSelectView(
                label: Text(birthT(context, 'educationLabel')),
                source: ref(BirthRefList.education),
                value: value.education,
                placeholder: birthT(context, 'selectPlaceholder'),
                onChanged: (String v) => onChanged(
                  (BirthParentInfo p) => p.copyWith(education: v),
                  path: _at('education'),
                ),
                path: _at('education'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: BirthInputField(
                label: birthT(context, 'occupationLabel'),
                value: value.occupation,
                placeholder: birthT(context, 'occupationPlaceholder'),
                onChanged: (String v) => onChanged(
                  (BirthParentInfo p) => p.copyWith(occupation: v),
                  path: _at('occupation'),
                ),
                path: _at('occupation'),
              ),
            ),
          ],
        ),
        BirthInputField(
          label: birthT(context, 'fingerprintLabel'),
          value: value.fingerprint,
          placeholder: birthT(context, 'parentFingerprintPlaceholder'),
          onChanged: (String v) => onChanged(
            (BirthParentInfo p) => p.copyWith(fingerprint: v),
            path: _at('fingerprint'),
          ),
          path: _at('fingerprint'),
        ),
      ],
    );
  }
}
