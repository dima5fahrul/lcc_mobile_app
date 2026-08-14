/// The **ordered** key sequence of one request body, and which of its keys may
/// be absent.
///
/// ## Why order is modelled and not left to the transcription
///
/// `endpoints.ts:325` passes the body object straight through and
/// `client.ts:242` is a bare `JSON.stringify(options.body)`. There is no
/// schema, no field allowlist and no canonicaliser anywhere between the page
/// and the socket, so **insertion order is wire order** — the create body's
/// `linked_reference_no` sitting *between* `event_date` and `form_data`, and
/// the update body's `form_data` sitting **first**, are wire facts with the
/// same standing as any `form_data` key (specs.md § 2.2 Finding I, § 6.2.3).
///
/// Tier 0 compares the serialised string, not the decoded map. A per-key
/// boolean cannot carry order, which is why this is a `List<EnvelopeKey>` and
/// not a `Map<String, bool>`.
///
/// ## Absent is not empty
///
/// Resident writes `province_id: form.province || undefined`
/// (`ResidentCertificatePage.tsx:509`), and `JSON.stringify` **drops** a key
/// whose value is `undefined`. Marriage writes `province_id: header.provinceId`
/// (`MarriageCertificatePage.tsx:959`) — a raw value, so a blank province is
/// `present-and-empty`. Same key name, two different bodies.
library;

/// What a key's *empty* value produces on the wire, when the key is
/// [EnvelopeKey.optional] at all.
enum WhenEmpty {
  /// `x || undefined` — `JSON.stringify` omits the key entirely.
  elided,

  /// The key is written with `""`. Present, and empty.
  emptyString,
}

/// One key of one envelope, in the position it occupies.
class EnvelopeKey {
  const EnvelopeKey(
    this.name, {
    this.optional = false,
    this.whenEmpty = WhenEmpty.emptyString,
  });

  /// `"service_code"`, `"linked_reference_no"`, `"form_data"`, …
  final String name;

  /// May this key be **absent** from the serialised body?
  final bool optional;

  /// And if it is optional, which does an empty value produce?
  ///
  /// Meaningless when [optional] is false — a non-optional key is always
  /// present, so the default here is the inert one.
  final WhenEmpty whenEmpty;

  @override
  String toString() => optional ? '$name?' : name;
}

/// One body's key sequence.
class EnvelopeShape {
  const EnvelopeShape(this.keys);

  /// **Ordered.** Insertion order is wire order.
  final List<EnvelopeKey> keys;

  /// Just the names, in order — the shape Tier 0's `createEnvelope` /
  /// `updateEnvelope` oracle blocks record.
  List<String> get names =>
      keys.map((EnvelopeKey k) => k.name).toList(growable: false);

  /// The keys that may be absent. Across all ten inhabitants this is exactly
  /// five distinct names: `province_id`, `district_id`, `village_id`
  /// (Resident/Birth/Death, [WhenEmpty.elided]) plus `event_date` and
  /// `linked_reference_no` (Marriage/Divorce) — `F0-AC-19`.
  List<EnvelopeKey> get optionalKeys =>
      keys.where((EnvelopeKey k) => k.optional).toList(growable: false);

  EnvelopeKey operator [](String name) =>
      keys.firstWhere((EnvelopeKey k) => k.name == name);

  bool contains(String name) => keys.any((EnvelopeKey k) => k.name == name);
}
