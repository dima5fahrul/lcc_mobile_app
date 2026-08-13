/// `Service` — one row of `GET /services`.
///
/// Ported from `lcc-app/src/app/api/types.ts:117-139`. 43 rows today, every one
/// `active: true`, in server `sort_order`.
///
/// ## Why every field is here, including the ones B2a does not draw
///
/// `slaRequiresPayment`… no: the fields below are the wire row, whole. B2a's
/// catalogue draws seven of them, but the row is also what F0's certificate
/// forms and B2b's home menu read, and the alternative — a narrower entity now
/// plus a wider one later — means two models of one endpoint that can disagree.
/// The cost of carrying a field is one line; the cost of two models is a class
/// of bug.
///
/// ## The fee, and why it is not `ServiceConfig`
///
/// The web reads fees through `serviceConfig.ts`: a hand-seeded table that
/// `loadServiceCatalogue()` overwrites in place from `/services` on first load,
/// so a card never flashes an empty fee before the catalogue lands. Every
/// consumer therefore ends up reading **this row's own** `fee_lak` /
/// `fee_max_lak` / `fee_is_range` once the fetch completes.
///
/// The Flutter page does not render a card until its `/services` call
/// succeeds — the four-state contract (§ 6.6) puts a skeleton there instead —
/// so the seed table has no window in which it could be visible, and porting
/// it would mean shipping 43 hardcoded prices that go stale the first time a
/// fee changes. The fee is read off the row. Recorded as a deliberate
/// divergence in *mechanism* with none in *output*.
library;

import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../session/domain/entities/bilingual.dart';

part 'service.freezed.dart';

@freezed
abstract class Service with _$Service {
  const factory Service({
    required String id,

    /// The catalogue's stable key (`resident`, `birth`, `family-book`). This is
    /// `ServiceItem.id` in the port source (`ServicePage.tsx:126`).
    required String code,
    required String categoryId,
    required String categoryCode,
    required Bilingual name,
    required String shortName,
    required Bilingual description,

    /// A lucide component name. Resolve through `AppIcons.service`.
    required String icon,

    /// `#RRGGBB` accent, or empty when the catalogue does not set one. Data,
    /// not a token — see `ServiceCategory`'s note.
    required String color,
    required int feeLak,
    required int feeMaxLak,
    required bool feeIsRange,
    required int slaDays,
    required Bilingual processingTime,
    required List<Bilingual> requiredDocs,
    required bool requiresPayment,
    required bool isPhase1,
    required bool active,
    required int sortOrder,

    /// The **web's** route for this service (`/service/resident-certificate`),
    /// or empty for the 37 rows that have none.
    ///
    /// **This is not an availability flag** (SSD § 13 C-3). Six of 43 carry
    /// one, and after F1 only one of those six will have a Flutter page, so
    /// reading it as "tappable" would be wrong in both directions. It is the
    /// page-pairing seed for the fidelity harness and the input to
    /// `ServiceAvailability`, which asks the *client* route registry whether a
    /// destination exists. Nothing else may branch on it.
    required String routePath,
    required String familyBookEffect,
  }) = _Service;
}
