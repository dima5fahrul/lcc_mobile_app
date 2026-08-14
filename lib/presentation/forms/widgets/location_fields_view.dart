/// `formFields.tsx:364-528` — cascading Province → District → Village.
///
/// ## `valueMode` is NOT ported. The three values are UUIDs, always.
///
/// The source's `LocationFields` has a `valueMode?: "name" | "id"` parameter
/// defaulting to `"name"`, with three name-resolution branches (`:412`, `:432`,
/// `:453`) and a `byId ? row.id : row.name.en` fork (`:479`). Measured, **all
/// seven call sites in the running application pass `"id"`** — name mode is
/// unreachable, and `ADR-0001` makes the shipped app the source of truth for
/// *behaviour*, not for unreachable parameters (specs.md § 6.3.5, Finding D).
///
/// The ruling is falsifiable and the test is the falsifier: `F0-AC-24` re-runs
/// the count against the pinned tree, and if a `valueMode` **call site** other
/// than the seven `"id"` ones exists, the ruling is void and the branch must be
/// ported.
///
/// ## Parameter-driven, and the seam that makes it so
///
/// The source widget owns three `useQuery` calls. This one owns none: it takes
/// the three option lists, three busy flags and three failure states, and
/// reports changes through [onChanged]. The fetching is the page BLoC's
/// (RULING 8) — which is what lets `F0-AC-77` pump it with the DI container
/// completely uninitialised.
///
/// ## The stale-row rule stays in the kernel — it is Tier 1 behaviour
///
/// `formFields.tsx:420-427`, `:444-447`:
///
/// ```ts
/// const districtsBusy = districtsQuery.loading || districtsQuery.refreshing;
/// const districts = useMemo(
///   () => (provinceId && !districtsBusy ? districtsQuery.data ?? [] : []),
///   [provinceId, districtsBusy, districtsQuery.data]);
/// ```
///
/// While a new province's districts are in flight the **previous** province's
/// rows are still in `data`, and showing them would offer choices that do not
/// belong to the province the citizen just picked. The rule is a pure function
/// of `(parentId, busy, rows)` and is exposed as [visibleRows] so it can be
/// asserted without a widget — everything else about this file could be
/// restructured and that behaviour would still be observable
/// (§ 6.3.7 row 13).
library;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/widgets.dart';

import '../../theme/app_spacing.dart';
import 'option.dart';
import 'searchable_select.dart';

/// `formFields.tsx:364-371` — what a location group resolved to: the UUIDs the
/// API wants, plus the names a review screen has to print back at the citizen.
class LocationIds {
  const LocationIds({
    this.provinceId = '',
    this.districtId = '',
    this.villageId = '',
    this.provinceName = '',
    this.districtName = '',
    this.villageName = '',
  });

  final String provinceId;
  final String districtId;
  final String villageId;
  final String provinceName;
  final String districtName;
  final String villageName;

  @override
  bool operator ==(Object other) =>
      other is LocationIds &&
      other.provinceId == provinceId &&
      other.districtId == districtId &&
      other.villageId == villageId &&
      other.provinceName == provinceName &&
      other.districtName == districtName &&
      other.villageName == villageName;

  @override
  int get hashCode => Object.hash(provinceId, districtId, villageId,
      provinceName, districtName, villageName);
}

/// `formFields.tsx:374-378` — the error paths a location group can report, one
/// per level.
class LocationPaths {
  const LocationPaths({this.province, this.district, this.village});

  final String? province;
  final String? district;
  final String? village;
}

/// The rows a level may show, given its parent and whether a fetch is in
/// flight.
///
/// Empty when there is no parent selected, **and** empty while a fetch is in
/// flight — the second clause is the stale-row rule and is the one a port
/// drops. `formFields.tsx:424-427`.
List<Option> visibleRows({
  required String parentId,
  required bool busy,
  required List<Option> rows,
}) {
  if (parentId.isEmpty) return const <Option>[];
  if (busy) return const <Option>[];
  return rows;
}

/// One level's worth of parameters. Three of these drive the widget.
class LocationLevel {
  const LocationLevel({
    this.rows = const <Option>[],
    this.busy = false,
    this.failed,
    this.onRetry,
  });

  /// The rows as fetched, **before** [visibleRows] is applied. Passing the raw
  /// list keeps the stale-row decision inside the kernel where Tier 1 can see
  /// it, rather than making every caller remember to blank it.
  final List<Option> rows;

  /// `loading || refreshing` — one flag, because the source's two are only ever
  /// consulted together (`:423`, `:443`).
  final bool busy;

  /// Nullable, so an omitting caller reproduces the weaker surface. See
  /// `searchable_select.dart`.
  final bool? failed;
  final VoidCallback? onRetry;
}

class LocationFieldsView extends StatelessWidget {
  const LocationFieldsView({
    super.key,
    required this.province,
    required this.district,
    required this.village,
    required this.onChanged,
    this.provinces = const LocationLevel(),
    this.districts = const LocationLevel(),
    this.villages = const LocationLevel(),
    this.villageLabel,
    this.required = false,
    this.paths = const LocationPaths(),
  });

  /// The three selected **UUIDs**. Never names — see the library doc.
  final String province;
  final String district;
  final String village;

  /// Reports a change as a patch, exactly as the source does. **Cascade
  /// clearing is expressed in the patch, not in the caller** (L-5): a province
  /// change carries `district: ''` and `village: ''`, a district change carries
  /// `village: ''`. A caller that ignored the blanks would leave a village from
  /// the previous district selected and post it.
  final void Function(LocationPatch patch) onChanged;

  final LocationLevel provinces;
  final LocationLevel districts;
  final LocationLevel villages;

  /// `:403` — `villageLabel ?? t("village")`.
  final String? villageLabel;

  final bool required;
  final LocationPaths paths;

  @override
  Widget build(BuildContext context) {
    final List<Option> districtRows = visibleRows(
      parentId: province,
      busy: districts.busy,
      rows: districts.rows,
    );
    final List<Option> villageRows = visibleRows(
      parentId: district,
      busy: villages.busy,
      rows: villages.rows,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        SearchableSelect(
          label: Text('fields.province'.tr(context: context)),
          value: province,
          options: provinces.rows,
          placeholder: 'fields.selectProvince'.tr(context: context),
          required: required,
          loading: provinces.busy,
          failed: provinces.failed,
          onRetry: provinces.onRetry,
          path: paths.province,
          // `:496`
          onChanged: (String v) => onChanged(
            LocationPatch(province: v, district: '', village: ''),
          ),
        ),
        const SizedBox(height: AppSpacing.gap12),
        // `:498` — `grid grid-cols-2 gap-3`.
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Expanded(
              child: SearchableSelect(
                label: Text('fields.district'.tr(context: context)),
                value: district,
                options: districtRows,
                // `:503` — L-6: the placeholder says *why* it is disabled.
                placeholder: province.isNotEmpty
                    ? 'fields.selectDistrict'.tr(context: context)
                    : 'fields.selectProvinceFirst'.tr(context: context),
                required: required,
                disabled: province.isEmpty,
                loading: districts.busy,
                failed: districts.failed,
                onRetry: districts.onRetry,
                path: paths.district,
                // `:510`
                onChanged: (String v) =>
                    onChanged(LocationPatch(district: v, village: '')),
              ),
            ),
            const SizedBox(width: AppSpacing.gap12),
            Expanded(
              child: SearchableSelect(
                label: Text(
                  villageLabel ?? 'fields.village'.tr(context: context),
                ),
                value: village,
                options: villageRows,
                placeholder: district.isNotEmpty
                    ? 'fields.selectVillage'.tr(context: context)
                    : 'fields.selectDistrictFirst'.tr(context: context),
                required: required,
                disabled: district.isEmpty,
                loading: villages.busy,
                failed: villages.failed,
                onRetry: villages.onRetry,
                path: paths.village,
                // `:523`
                onChanged: (String v) => onChanged(LocationPatch(village: v)),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// `onChange: (patch: {province?, district?, village?}) => void` — a **partial**
/// update.
///
/// The distinction between "not mentioned" and "cleared" is load-bearing: a
/// district change mentions `village: ''` and does not mention `province`, so
/// a caller applying the patch must leave the province alone and blank the
/// village. Three nullable fields carry that; three plain strings could not.
class LocationPatch {
  const LocationPatch({this.province, this.district, this.village});

  final String? province;
  final String? district;
  final String? village;

  @override
  bool operator ==(Object other) =>
      other is LocationPatch &&
      other.province == province &&
      other.district == district &&
      other.village == village;

  @override
  int get hashCode => Object.hash(province, district, village);

  @override
  String toString() =>
      'LocationPatch(province: $province, district: $district, village: $village)';
}
