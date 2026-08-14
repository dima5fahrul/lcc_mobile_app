/// Which list to fetch, and how far to page it.
///
/// One key space over two endpoint families — L-1. The caller says
/// `LookupKey.villages` with a district id; it never says
/// `GET /locations/districts/{id}/villages`.
library;

/// The lookup lists the port can ask for.
///
/// The three location levels are named members rather than a `type` string,
/// because they are the only ones with a parent and the only ones that page.
/// Everything else is a `/reference-lists/{type}` read and is [reference].
sealed class LookupKey {
  const LookupKey();

  /// `GET /locations/provinces` — no parent.
  static const LookupKey provinces = ProvincesKey();

  /// `GET /locations/provinces/{parentId}/districts`.
  static const LookupKey districts = DistrictsKey();

  /// `GET /locations/districts/{parentId}/villages` — **paged**.
  static const LookupKey villages = VillagesKey();

  /// `GET /reference-lists/{type}` — `nationality`, `ethnicity`, `religion`,
  /// `relation`, `cause_of_death`, …
  const factory LookupKey.reference(String type) = ReferenceListKey;

  /// A stable identity for the dedup cache and for test assertions.
  String get id;
}

class ProvincesKey extends LookupKey {
  const ProvincesKey();
  @override
  String get id => 'locations:provinces';
  @override
  bool operator ==(Object other) => other is ProvincesKey;
  @override
  int get hashCode => id.hashCode;
}

class DistrictsKey extends LookupKey {
  const DistrictsKey();
  @override
  String get id => 'locations:districts';
  @override
  bool operator ==(Object other) => other is DistrictsKey;
  @override
  int get hashCode => id.hashCode;
}

class VillagesKey extends LookupKey {
  const VillagesKey();
  @override
  String get id => 'locations:villages';
  @override
  bool operator ==(Object other) => other is VillagesKey;
  @override
  int get hashCode => id.hashCode;
}

class ReferenceListKey extends LookupKey {
  const ReferenceListKey(this.type);

  /// The `lookup_key` from the form schema, straight onto the path.
  final String type;

  @override
  String get id => 'reference:$type';
  @override
  bool operator ==(Object other) =>
      other is ReferenceListKey && other.type == type;
  @override
  int get hashCode => id.hashCode;
}

/// How far a paged lookup is followed.
///
/// ## Why the divergence lives in the contract instead of at F3
///
/// The kernel's `LocationFields` uses `villagesInDistrict`
/// (`endpoints.ts:284-292`), which **loops to the last page** — L-7, and a
/// district with more than 200 villages otherwise silently hides the rest,
/// answering "no match" for a village that exists.
///
/// Marriage's and Divorce's page-local `ApiLocationFields` fetch **one page**
/// (`MarriageCertificatePage.tsx:296-302`). That is a real, reproducible
/// divergence — and F3 has **no CFI-legal way to express it** if the interface
/// is frozen without it: the only domain method pages to the end (L-7),
/// `features/certificates/**` may not import `features/reference/data/**`
/// (CFI, G-L3), so F3's only outs would be a second repository, a datasource of
/// its own, or a guard violation. All three are worse than the thing they work
/// around, and all three are discovered at F3.
///
/// So it lands in the contract now, while it is cheap (specs.md § 6.9 item 1,
/// `F0-AC-91`).
enum PagingMode {
  /// Follow `meta.total_pages` to the end. **The default**, so a caller that
  /// says nothing gets L-7's behaviour and the kernel path cannot regress by
  /// omission.
  all,

  /// One page, and stop — `MarriageCertificatePage.tsx:296-302`. A reproduced
  /// divergence, not an optimisation. Do not "clean this up".
  firstPageOnly,
}
