/// One row of a lookup list, whichever endpoint served it.
///
/// **L-1 — one domain type, one interface, two adapters.** The widget layer
/// must never branch on whether a key is served by `/reference-lists` or by
/// `/locations` (`ssd.md` § 11.2).
///
/// **L-2 — the wire difference is absorbed in the data layer.** Reference lists
/// say `label`, locations say `name`; both arrive here as [label] and the
/// difference never surfaces upward (`ssd.md`:836, `formFields.tsx:235-240`).
library;

import '../../../session/domain/entities/bilingual.dart';

class LookupOption {
  const LookupOption({
    required this.id,
    required this.code,
    required this.label,
    this.sortOrder,
    this.active = true,
  });

  /// The UUID. For locations this is what `form_data` carries; for reference
  /// lists it is carried but unused, because [code] is the wire value there.
  final String id;

  /// The value that goes on the wire for a reference list
  /// (`formFields.tsx:262` `value: item.code`). Locations have no `code` field
  /// the selects use, so the datasource fills this with the row's `id` — see
  /// its own doc for why that is absorption and not invention.
  final String code;

  /// Both languages. The widget picks one; the *other* becomes `Option.sub`.
  final Bilingual label;

  /// `sort_order` where the wire carries it. **Never used to re-sort** — L-3
  /// says server order, no client re-sort. It is kept because a review screen
  /// may want it, and dropping a field the wire sends is its own divergence.
  final int? sortOrder;

  /// `active` where the wire carries it. **Never used to filter** — L-4: the
  /// web does not filter, so neither does this. Kept for the same reason as
  /// [sortOrder], and asserted present-and-unfiltered by `F0-AC-92`.
  final bool active;

  @override
  bool operator ==(Object other) =>
      other is LookupOption &&
      other.id == id &&
      other.code == code &&
      other.label == label &&
      other.sortOrder == sortOrder &&
      other.active == active;

  @override
  int get hashCode => Object.hash(id, code, label, sortOrder, active);

  @override
  String toString() => 'LookupOption($code, ${label.en})';
}
