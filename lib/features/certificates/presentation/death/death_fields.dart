/// `DeathDeclarationPage.tsx:146-621` — the page's own field widgets, its
/// page-local `TXT` table, its `ParentSection` and its `ParentStep`.
///
/// ## Deliberately parallel to `birth_fields.dart`, and sharing nothing with it
///
/// The source duplicates `InputField`, `SelectField`, `UploadBox`,
/// `FieldLabel` and `SectionLabel` between the two pages; the port mirrors the
/// source (`specs.md` § 6.2 RULING 1). What differs, and why a shared version
/// could not be made correct with flags:
///
/// - [DeathParentSection] takes **no `required` parameter at all** (`:450-457`).
///   Only `fullName` is mandatory. Birth's threads `required` to nine controls.
/// - It renders a **`workplace`** field (`:559-564`) that Birth has none of.
/// - Its i18n keys are a **different scheme** — `fullName`/`phSelect`/
///   `dobOptional`/`secDemographics` against Birth's `fullNameLabel`/
///   `selectPlaceholder`/`dobLabel`/`additionalDetailsSection`.
/// - [DeathParentStep] wraps the section in a skip toggle; Birth has no such
///   wrapper (its toggle is inline in step 4) and only its father can be
///   skipped.
///
/// ## `TXT` is page-local — **eight** entries, not Birth's nine
///
/// Birth declares a ninth, `TXT.paid`, which is referenced nowhere and is not
/// ported (`F2-AC-82`). Seven of these eight are byte-identical to Birth's and
/// § 6.2 still forbids sharing them: two page-local tables in the source, two
/// in the port. Promoting them into the `death` namespace would take the count
/// from 97 to 105 (`F2-AC-81`).
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
import '../../../../presentation/forms/widgets/reference_select_view.dart';
import '../../../../presentation/icons/lucide_icon.dart';
import '../../../../presentation/theme/app_colors.dart';
import '../../../application/domain/entities/picked_attachment.dart';
import '../../../session/domain/entities/bilingual.dart';
import 'death_form_cubit.dart';
import 'death_form_state.dart';

/// `:146-161` — `TXT`, **eight** page-local bilingual sentences.
class DeathTxt {
  const DeathTxt._();

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

  /// `:155-158` — Death's own, with no Birth counterpart.
  static const Bilingual deathNotice = Bilingual(
    en: 'Medical / cause-of-death note',
    lo: 'ໃບຢັ້ງຢືນທາງການແພດ / ສາເຫດການເສຍຊີວິດ',
  );

  static const Bilingual payNow =
      Bilingual(en: 'Pay {amount}', lo: 'ຈ່າຍ {amount}');
  static const Bilingual receipt =
      Bilingual(en: 'Receipt No.', lo: 'ເລກທີ່ໃບຮັບເງິນ');
}

/// `:163-167` — `fill(template, params)`.
String deathFill(String template, Map<String, String> params) {
  String out = template;
  params.forEach((String k, String v) => out = out.split('{$k}').join(v));
  return out;
}

String deathTxtOf(BuildContext context, Bilingual value) => text(
      value,
      Localizations.localeOf(context).languageCode == 'lo' ? Lang.lo : Lang.en,
    );

/// `'death.<key>'.tr(context: context)`.
///
/// The namespace appears once per page. `F2-AC-37`'s "no `birth` key is read
/// from `death/`" is a property of this one function.
String deathT(BuildContext context, String key) =>
    'death.$key'.tr(context: context);

/// `:276-302` — `InputField`.
class DeathInputField extends StatefulWidget {
  const DeathInputField({
    super.key,
    required this.label,
    required this.value,
    required this.placeholder,
    required this.onChanged,
    this.required = false,
    this.numeric = false,
    this.path,
  });

  final String label;
  final String value;
  final String placeholder;
  final ValueChanged<String> onChanged;
  final bool required;
  final bool numeric;

  /// **No `maxLength`.** Death has no `maxLength` on any control — Birth's
  /// `birthOrder` is the only one on either page, and `causeOther`
  /// specifically has no cap (`F2-AC-62`).
  final String? path;

  @override
  State<DeathInputField> createState() => _DeathInputFieldState();
}

class _DeathInputFieldState extends State<DeathInputField> {
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
  void didUpdateWidget(DeathInputField oldWidget) {
    super.didUpdateWidget(oldWidget);
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

/// `:304-333` — `SelectField`.
///
/// Fed from [kDeathGenders], which are **hard-coded bilingual literals**
/// (`:140-143`) rendered through `text(g.label, lang)` (`:729`). Birth's are
/// i18n keys resolved through its namespace. `F2-AC-83` forbids harmonising.
class DeathSelectField extends StatelessWidget {
  const DeathSelectField({
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

/// `:335-398` — `UploadBox`.
///
/// **R-21.** `accept="image/*,application/pdf"` (`:360`) names PDF explicitly,
/// and `handleFile` (`:347-355`) inspects neither `type` nor `size`. The picker
/// is opened with `FileType.any` and **no** `allowedExtensions` — the test case
/// is a `.docx`, because an extension list containing `pdf` would pass a PDF
/// test and still reject the file the web accepts (`F2-AC-55`, `F2-AC-56`).
class DeathUploadBox extends StatelessWidget {
  const DeathUploadBox({
    super.key,
    required this.label,
    required this.sublabel,
    required this.file,
    required this.onChanged,
    this.required = true,
    this.path,
    this.pickFile = deathPickFile,
  });

  final String label;
  final String sublabel;
  final PickedAttachment? file;
  final ValueChanged<PickedAttachment?> onChanged;
  final bool required;
  final String? path;
  final Future<PickedAttachment?> Function() pickFile;

  @override
  Widget build(BuildContext context) {
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
                    deathTxtOf(context, DeathTxt.uploadTap),
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

/// The picker call, with **no filter of any kind** — R-21.
Future<PickedAttachment?> deathPickFile() async {
  final FilePickerResult? result = await FilePicker.platform.pickFiles(
    withData: true,
  );
  final PlatformFile? f = result?.files.singleOrNull;
  if (f == null) return null;
  return PickedAttachment(name: f.name, bytes: f.bytes, path: f.path);
}

/// `:400-406` — `SectionLabel`.
class DeathSectionLabel extends StatelessWidget {
  const DeathSectionLabel(this.label, {super.key});
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

/// `:411-447` — `AddressFields`.
///
/// **No `withHouseNo` parameter.** Birth's has one (`:416`), never passed
/// false; Death's always renders the house-no field. Measured difference #18 —
/// adding the flag here would be an invention.
///
/// Also **`villageLabel` is passed** (`:434`), where Birth's `AddressFields`
/// leaves it to the kernel default.
class DeathAddressFields extends StatelessWidget {
  const DeathAddressFields({
    super.key,
    required this.houseNo,
    required this.village,
    required this.district,
    required this.province,
    required this.onChanged,
    required this.provinces,
    required this.districts,
    required this.villages,
    required this.villageLabel,
    this.required = true,
    this.villagePath,
  });

  final String houseNo;
  final String village;
  final String district;
  final String province;

  final void Function({
    String? addrHouseNo,
    String? addrVillage,
    String? addrDistrict,
    String? addrProvince,
  }) onChanged;

  final LocationLevel provinces;
  final LocationLevel districts;
  final LocationLevel villages;
  final String villageLabel;
  final bool required;
  final String? villagePath;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          DeathInputField(
            label: deathT(context, 'houseNo'),
            value: houseNo,
            placeholder: deathT(context, 'phHouseNo'),
            onChanged: (String v) => onChanged(addrHouseNo: v),
          ),
          LocationFieldsView(
            province: province,
            district: district,
            village: village,
            provinces: provinces,
            districts: districts,
            villages: villages,
            villageLabel: villageLabel,
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

/// `:450-575` — `ParentSection`.
///
/// ## No `required` parameter, and that is the point
///
/// The source's signature is `{t, value, onChange, refs, prefix}` — five
/// props, none of them `required`. `fullName` is hard-coded `required` (`:466`)
/// and **every other control is optional**, permanently. Birth's threads a
/// `required` prop to nine controls and its `parentValid` checks eight fields.
///
/// A single widget with a `required` flag FAILS `F2-AC-24`, and this is why:
/// the flag would have to be false for Death on nine controls, true for Birth
/// on the same nine, and Death would still need a tenth control (`workplace`)
/// that Birth does not render at all.
class DeathParentSection extends StatelessWidget {
  const DeathParentSection({
    super.key,
    required this.value,
    required this.onChanged,
    required this.cubit,
    required this.prefix,
  });

  final DeathParentInfo value;
  final void Function(DeathParentInfo Function(DeathParentInfo), {String? path})
      onChanged;
  final DeathFormCubit cubit;

  /// `"parents"` for the mother, `"parents.father"` for the father (`:455`).
  final String prefix;

  String _at(String key) => '$prefix.$key';

  @override
  Widget build(BuildContext context) {
    Widget pair(Widget a, Widget b) => Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Expanded(child: a),
            const SizedBox(width: 12),
            Expanded(child: b),
          ],
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        // The ONE mandatory control on this section.
        DeathInputField(
          label: deathT(context, 'fullName'),
          value: value.fullName,
          placeholder: deathT(context, 'phFullName'),
          onChanged: (String v) => onChanged(
            (DeathParentInfo p) => p.copyWith(fullName: v),
            path: _at('name'),
          ),
          required: true,
          path: _at('name'),
        ),
        pair(
          DateField(
            // `dobOptional`, not Birth's `dobLabel` — a different key scheme,
            // and the label itself says "(OPTIONAL)".
            label: Text(deathT(context, 'dobOptional')),
            value: value.dob,
            onChanged: (String v) => onChanged(
              (DeathParentInfo p) => p.copyWith(dob: v),
              path: _at('dob'),
            ),
            path: _at('dob'),
          ),
          ReferenceSelectView(
            label: Text(deathT(context, 'maritalStatusOptional')),
            source: cubit.referenceStateOf(DeathRefList.marital),
            value: value.maritalStatus,
            placeholder: deathT(context, 'phSelect'),
            onChanged: (String v) => onChanged(
              (DeathParentInfo p) => p.copyWith(maritalStatus: v),
              path: _at('marital_status'),
            ),
            path: _at('marital_status'),
          ),
        ),
        DeathSectionLabel(deathT(context, 'secDemographics')),
        pair(
          ReferenceSelectView(
            label: Text(deathT(context, 'ethnicity')),
            source: cubit.referenceStateOf(DeathRefList.ethnicity),
            value: value.ethnicity,
            placeholder: deathT(context, 'phSelect'),
            onChanged: (String v) => onChanged(
              (DeathParentInfo p) => p.copyWith(ethnicity: v),
              path: _at('ethnicity'),
            ),
            path: _at('ethnicity'),
          ),
          // Preset `"lao"` — a RULING 14 path, and **no path prop** (`:496-502`).
          ReferenceSelectView(
            label: Text(deathT(context, 'nationality')),
            source: cubit.referenceStateOf(DeathRefList.nationality),
            value: value.nationality,
            placeholder: deathT(context, 'phSelect'),
            onChanged: (String v) => onChanged(
              (DeathParentInfo p) => p.copyWith(nationality: v),
            ),
          ),
        ),
        pair(
          ReferenceSelectView(
            label: Text(deathT(context, 'ethnicGroup')),
            source: cubit.referenceStateOf(DeathRefList.ethnicGroup),
            value: value.ethnicGroup,
            placeholder: deathT(context, 'phSelect'),
            onChanged: (String v) => onChanged(
              (DeathParentInfo p) => p.copyWith(ethnicGroup: v),
            ),
          ),
          ReferenceSelectView(
            label: Text(deathT(context, 'religion')),
            source: cubit.referenceStateOf(DeathRefList.religion),
            value: value.religion,
            placeholder: deathT(context, 'phSelect'),
            onChanged: (String v) => onChanged(
              (DeathParentInfo p) => p.copyWith(religion: v),
            ),
          ),
        ),
        // `secCurrentAddressOptional` — "(IF APPLICABLE)". Birth's is
        // `currentAddressSection` and its address is mandatory.
        DeathSectionLabel(deathT(context, 'secCurrentAddressOptional')),
        DeathAddressFields(
          houseNo: value.addrHouseNo,
          village: value.addrVillage,
          district: value.addrDistrict,
          province: value.addrProvince,
          villageLabel: deathT(context, 'villageLabel'),
          provinces: cubit.locationLevel(cubit.state.provinces, context,
              retry: cubit.loadProvinces),
          districts: cubit.locationLevel(cubit.state.districts, context,
              retry: () => cubit.loadDistricts(value.addrProvince)),
          villages: cubit.locationLevel(cubit.state.villages, context,
              retry: () => cubit.loadVillages(value.addrDistrict)),
          // `required={false}` (`:529`) — explicitly, where Birth passes its
          // own `required` through.
          required: false,
          villagePath: _at('current_address'),
          onChanged: ({
            String? addrHouseNo,
            String? addrVillage,
            String? addrDistrict,
            String? addrProvince,
          }) =>
              onChanged(
            (DeathParentInfo p) => p.copyWith(
              addrHouseNo: addrHouseNo,
              addrVillage: addrVillage,
              addrDistrict: addrDistrict,
              addrProvince: addrProvince,
            ),
            path: _at('current_address'),
          ),
        ),
        DeathInputField(
          label: deathT(context, 'censusOrIdOptional'),
          value: value.censusOrId,
          placeholder: deathT(context, 'phOneIdentifier'),
          onChanged: (String v) => onChanged(
            (DeathParentInfo p) => p.copyWith(censusOrId: v),
            path: _at('id_number'),
          ),
          path: _at('id_number'),
        ),
        DeathSectionLabel(deathT(context, 'secEducationWork')),
        pair(
          ReferenceSelectView(
            label: Text(deathT(context, 'educationLevel')),
            source: cubit.referenceStateOf(DeathRefList.education),
            value: value.education,
            placeholder: deathT(context, 'phSelect'),
            onChanged: (String v) => onChanged(
              (DeathParentInfo p) => p.copyWith(education: v),
              path: _at('education'),
            ),
            path: _at('education'),
          ),
          DeathInputField(
            label: deathT(context, 'occupation'),
            value: value.occupation,
            placeholder: deathT(context, 'phOccupation'),
            onChanged: (String v) => onChanged(
              (DeathParentInfo p) => p.copyWith(occupation: v),
            ),
          ),
        ),
        pair(
          // **`workplace` — the control Birth's ParentSection does not have**,
          // and the fourteenth wire key its `parentData` does not emit.
          DeathInputField(
            label: deathT(context, 'workplace'),
            value: value.workplace,
            placeholder: deathT(context, 'phWorkplace'),
            onChanged: (String v) => onChanged(
              (DeathParentInfo p) => p.copyWith(workplace: v),
            ),
          ),
          DeathInputField(
            label: deathT(context, 'fingerprintCode'),
            value: value.fingerprint,
            placeholder: deathT(context, 'phBiometric'),
            onChanged: (String v) => onChanged(
              (DeathParentInfo p) => p.copyWith(fingerprint: v),
              path: _at('fingerprint'),
            ),
            path: _at('fingerprint'),
          ),
        ),
      ],
    );
  }
}

/// `:578-621` — `ParentStep`, the section wrapped in a skip toggle.
///
/// Birth has **no analogue**: its toggle is written inline in step 4 and only
/// the father can be declared unknown. Death's is a reusable wrapper because
/// **both** its parent steps take one, independently — and `motherSkip`
/// collapses two payload prefixes where `fatherSkip` collapses one.
///
/// **Toggling does not clear the record** (`F2-AC-69`): the toggle and the
/// record are two separate pieces of state, so switching back restores every
/// typed value.
class DeathParentStep extends StatelessWidget {
  const DeathParentStep({
    super.key,
    required this.intro,
    required this.value,
    required this.onChanged,
    required this.skip,
    required this.onToggleSkip,
    required this.cubit,
    required this.prefix,
  });

  final String intro;
  final DeathParentInfo value;
  final void Function(DeathParentInfo Function(DeathParentInfo), {String? path})
      onChanged;
  final bool skip;
  final VoidCallback onToggleSkip;
  final DeathFormCubit cubit;
  final String prefix;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primarySoft,
              border: Border.all(color: AppColors.primarySoft),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const LucideIcon(name: 'user', size: 16),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    intro,
                    style: const TextStyle(
                      fontSize: 12,
                      height: 1.5,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          DeathSkipToggle(
            title: deathT(context, 'parentDeceasedUnknown'),
            subtitle: deathT(context, 'skipThisSection'),
            value: skip,
            onToggle: onToggleSkip,
          ),
          // `:618` — the section disappears entirely when skipped.
          if (!skip)
            DeathParentSection(
              value: value,
              onChanged: onChanged,
              cubit: cubit,
              prefix: prefix,
            ),
        ],
      );
}

/// `:591-616` — the toggle. Same measured palette as Birth's
/// (`#EEF2FF` / `#E5E7EB` / `#D1D5DB`), and still not shared.
class DeathSkipToggle extends StatelessWidget {
  const DeathSkipToggle({
    super.key,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onToggle,
  });

  final String title;
  final String subtitle;
  final bool value;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onToggle,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: value ? AppColors.primarySoft : AppColors.white,
            border: Border.all(
              color: value ? AppColors.primary : AppColors.gray200,
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const LucideIcon(name: 'info', size: 16),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.gray400Inline,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: value ? AppColors.primary : AppColors.transparent,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: value
                        ? AppColors.primary
                        : AppColors.gray300,
                    width: 2,
                  ),
                ),
                child:
                    value ? const LucideIcon(name: 'check', size: 12) : null,
              ),
            ],
          ),
        ),
      );
}
