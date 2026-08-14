/// `Jurisdiction` — the place a case belongs to.
///
/// Ported verbatim from `lcc-app/src/app/api/types.ts:96-103`:
///
/// ```ts
/// export interface Jurisdiction {
///   province_id?: string;  province_name?: string;
///   district_id?: string;  district_name?: string;
///   village_id?: string;   village_name?: string;
/// }
/// ```
///
/// **All six fields are optional in the source and all six are nullable here.**
/// That is load-bearing rather than defensive: `HistoryDetailPage.tsx:252-253`
/// composes the "Processing office" line as
/// `[district_name, province_name].filter(Boolean).join(" · ") || "—"`, so
/// "absent" is a rendered state with its own copy, not an error.
///
/// This entity is B7a's and is consumed by `history` (B7), `wallet` (B6b) and
/// later `certificates` / `documents` — see `ssd.md` § 4.5's shared-kernel
/// register. It is **not** the same type as `CitizenProfile`'s jurisdiction
/// (`types.ts:264`, which is the same TS interface reached through a different
/// feature): the session feature parses its own, per CFI's "wire-format
/// duplication is the accepted cost" (`ssd.md` § 4.3).
library;

import 'package:freezed_annotation/freezed_annotation.dart';

part 'jurisdiction.freezed.dart';

@freezed
abstract class Jurisdiction with _$Jurisdiction {
  const factory Jurisdiction({
    String? provinceId,
    String? provinceName,
    String? districtId,
    String? districtName,
    String? villageId,
    String? villageName,
  }) = _Jurisdiction;

  const Jurisdiction._();

  /// The all-absent pair — what a row with no `jurisdiction` block parses to.
  static const Jurisdiction empty = Jurisdiction();

  /// `[district_name, province_name].filter(Boolean).join(" · ") || "—"` —
  /// `HistoryDetailPage.tsx:252-253`.
  ///
  /// In `domain/` rather than in a widget because it is a rule about the data,
  /// and because a `.join(" · ")` buried in a widget body is exactly the kind
  /// of thing that silently becomes `", "`. The `"—"` is the source's own
  /// sentinel, the same one `formatDate` uses.
  ///
  /// B7b renders this; B7a carries it because the entity is shared and B4/B6b
  /// would otherwise each re-derive it.
  String get officeLine {
    final List<String> parts = <String>[
      if (districtName != null && districtName!.isNotEmpty) districtName!,
      if (provinceName != null && provinceName!.isNotEmpty) provinceName!,
    ];
    return parts.isEmpty ? '—' : parts.join(' · ');
  }
}
