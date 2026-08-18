/// `ApiLocationFields` — Marriage `:279-364`, Divorce `:288-367`, identical
/// modulo two reflowed `onChange` arrows (Finding K).
///
/// **This is § 6.3 RULING 2(iii) and (iv), and it is the batch's signature
/// widget: a correct port here looks like a bug.**
///
/// ## It mounts the kernel `SearchableSelect` and omits four props
///
/// `formFields.tsx:223` is
/// `{failed && onRetry ? <LoadFailure …/> : <FieldError …/>}` — **both**
/// operands are required, so omitting either suppresses the row. The kernel's
/// own `LocationFields` passes `failed`, `onRetry`, `emptyMessage` and `path`
/// per level (`:491-521`); `ApiLocationFields` passes **`loading` only**
/// (`:320`, `:337`, `:355`). The divergence is entirely in the caller, so the
/// kernel is mounted unforked and unedited (`F3-AC-13`, `F3-AC-27`).
///
/// The resulting matrix — the whole of RULING 2(iii):
///
/// | state | renders |
/// | --- | --- |
/// | loading | **YES** — spinner + `fields.loading` (`formFields.tsx:186-188`) |
/// | loaded, zero options | **YES** — `formFields.nothingYet` (`:190-192`, the `emptyMessage ??` default) |
/// | fetch failed | **NO** `LoadFailure`, **NO** Retry, **NO** error ring — `outlined = hasError \|\| Boolean(failed)` with `failed` undefined (`:146`) |
/// | 422 for the group | **ONE** `<FieldError>` under the three-level group (`:361`), not one per level |
///
/// A port that suppressed the empty message too would be as wrong as one that
/// showed the failure row. `F3-AC-27`…`F3-AC-30`.
///
/// ## `L-7` is scoped, not obeyed — RULING 2(iv)
///
/// `locations.villages(districtId).then(page => page.data)` (`:296-298`) —
/// **the first page only**, `per_page` 200. The kernel's `villagesInDistrict`
/// loops to `total_pages`. Porting the loop would make this port strictly
/// *better* than the source in a citizen-visible way (a village at position 201
/// becomes selectable where the web says "no match"), which is `L-10`(b).
///
/// The fetch is not here — this widget takes its options as parameters — but
/// the *contract* is: [CertificateLocationLevel] carries no page cursor and the
/// cubit reads with `PagingMode.firstPageOnly`, which F0 put in the lookup
/// contract for exactly this call site (`lookup_key.dart`'s `PagingMode` doc).
/// `F3-AC-31` asserts it positively — 250 villages must yield 200 options, one
/// request — because a criterion saying only "we did not add pagination" would
/// pass with the cascade returning nothing.
///
/// ## No stale-clear
///
/// The kernel's `LocationFields` blanks a level's list while it refetches
/// (`districtsBusy` / `villagesBusy`, `:420-425`, `:440-445`).
/// `ApiLocationFields` does not: the previous province's districts stay
/// selectable until the new ones arrive. Reproduced by simply not doing it —
/// the cubit replaces the rows when they land.
library;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/widgets.dart';

import '../../../../presentation/forms/validation/field_error.dart';
import '../../../../presentation/forms/widgets/option.dart';
import '../../../../presentation/forms/widgets/searchable_select.dart';
import '../../../../presentation/theme/app_spacing.dart';
import 'certificate_location_value.dart';

/// One level's data, as the page's `useQuery` exposes it: rows and a loading
/// flag.
///
/// **No `failed`.** `ApiLocationFields` destructures `{data, loading}` and
/// never `error` (`:291-302`), so the page cannot know a level failed. A
/// `failed` field here would be a state with no source, and a later
/// implementer would wire it to `SearchableSelect.failed` and re-add
/// `LoadFailure`.
class CertificateLocationLevel {
  const CertificateLocationLevel({
    this.options = const <Option>[],
    this.loading = false,
  });

  final List<Option> options;
  final bool loading;

  static const CertificateLocationLevel empty = CertificateLocationLevel();
}

class CertificateLocationFields extends StatelessWidget {
  const CertificateLocationFields({
    super.key,
    required this.value,
    required this.onChanged,
    required this.provinces,
    required this.districts,
    required this.villages,
    this.villageLabel,
    this.required = false,
    this.serverError,
  });

  final CertificateLocationValue value;
  final ValueChanged<CertificateLocationValue> onChanged;

  final CertificateLocationLevel provinces;
  final CertificateLocationLevel districts;
  final CertificateLocationLevel villages;

  /// `villageLabel ?? tf("village")` (`:349`). Marriage passes
  /// `t("village")` for a spouse address and **nothing** for the header
  /// (`:1312-1317`), so the header's village label comes from the `fields`
  /// namespace and the spouse's from `marriage`. Two different strings for one
  /// control; reproduced by keeping the parameter nullable.
  final String? villageLabel;

  final bool required;

  /// **One error line for the whole three-level group** (`:361`), because
  /// `path` is not threaded per level.
  final String? serverError;

  /// `nameOf(rows, id)` (`:307-310`) — resolved at **pick** time, from the
  /// options already in hand, which is what makes `address_text` locale-stable
  /// after a language switch (Guard B).
  static String _nameOf(List<Option> rows, String id) {
    for (final Option o in rows) {
      if (o.value == id) return o.label;
    }
    return '';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        // `:314-328` — province. Picking one RESETS the whole value to blank
        // and then sets the province, so district and village are cleared
        // together with their names.
        SearchableSelect(
          label: Text('fields.province'.tr(context: context)),
          value: value.provinceId,
          options: provinces.options,
          placeholder: 'fields.selectProvince'.tr(context: context),
          required: required,
          loading: provinces.loading,
          onChanged: (String id) => onChanged(
            CertificateLocationValue(
              provinceId: id,
              provinceName: _nameOf(provinces.options, id),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.gap12),
        // `:329-360` — `grid grid-cols-2 gap-3`.
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Expanded(
              child: SearchableSelect(
                label: Text('fields.district'.tr(context: context)),
                value: value.districtId,
                options: districts.options,
                // `:334` — the placeholder is the prompt when the parent is
                // unset, not a disabled-state style.
                placeholder: value.provinceId.isNotEmpty
                    ? 'fields.selectDistrict'.tr(context: context)
                    : 'fields.selectProvinceFirst'.tr(context: context),
                required: required,
                disabled: value.provinceId.isEmpty,
                loading: districts.loading,
                onChanged: (String id) => onChanged(
                  value.copyWith(
                    districtId: id,
                    districtName: _nameOf(districts.options, id),
                    villageId: '',
                    villageName: '',
                  ),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.gap12),
            Expanded(
              child: SearchableSelect(
                label: Text(
                  villageLabel ?? 'fields.village'.tr(context: context),
                ),
                value: value.villageId,
                options: villages.options,
                placeholder: value.districtId.isNotEmpty
                    ? 'fields.selectVillage'.tr(context: context)
                    : 'fields.selectDistrictFirst'.tr(context: context),
                required: required,
                disabled: value.districtId.isEmpty,
                loading: villages.loading,
                onChanged: (String id) => onChanged(
                  value.copyWith(
                    villageId: id,
                    villageName: _nameOf(villages.options, id),
                  ),
                ),
              ),
            ),
          ],
        ),
        // `:361` — one row for the group.
        FieldErrorText(
          show: serverError != null && serverError!.isNotEmpty,
          message: serverError,
        ),
      ],
    );
  }
}
