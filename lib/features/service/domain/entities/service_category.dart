/// `ServiceCategory` — one row of `GET /service-categories`.
///
/// Ported from `lcc-app/src/app/api/types.ts:107-115`. Eight rows today, all
/// `active: true`, ordered by `sort_order` **as the server returns them**
/// (SSD § 11.2 L-3/L-4: no client re-sort, no `active` filter — the web applies
/// neither and a Flutter-only ordering would be a divergence nobody could see
/// in a code review).
///
/// ## `color` is data, not a token
///
/// [color] arrives as a `#RRGGBB` string that an administrator can change
/// without an app release. It is deliberately **not** parsed into an
/// `AppColors` constant: `app_colors.dart` says in as many words that
/// transcribing a runtime-supplied colour pins a value the server owns. It is
/// parsed at the edge (`ServiceCategoryModel.toEntity`) and passed down as a
/// value.
///
/// ## What the API does *not* send
///
/// A blurb. `ServicePage.tsx:316` is explicit: *"The API publishes a name, icon
/// and colour; the blurb and tint stay local."* The eight descriptions live in
/// `CATEGORIES` in the port source and are ported to
/// `presentation/widgets/category_seed.dart`, not here — they are copy, not
/// wire data, and putting them on this entity would imply the server owns them.
library;

import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../session/domain/entities/bilingual.dart';

part 'service_category.freezed.dart';

@freezed
abstract class ServiceCategory with _$ServiceCategory {
  const factory ServiceCategory({
    required String id,
    required String code,
    required Bilingual name,

    /// A lucide component name (`Users`, `Plane`, …). Resolve it through
    /// `AppIcons.service` before rendering — never through `AppIcons.help`,
    /// and never straight into `LucideIcon` (specs.md § 6.3.5).
    required String icon,

    /// `#RRGGBB`, verbatim off the wire. See the note above.
    required String color,
    required int sortOrder,
    required bool active,
  }) = _ServiceCategory;
}
