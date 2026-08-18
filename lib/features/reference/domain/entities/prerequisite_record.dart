/// `types.ts:235-249` — one row of `GET /prerequisite-records`.
///
/// ## Why this is in `features/reference/` and not next to the two pages
///
/// `specs.md` § 6.1 applies `ssd.md` § 4.2 row 4: the concept names an endpoint
/// and models a product concept, so it is a page-less feature's domain entity,
/// not a page's view model. `features/certificates/` reaches it through
/// `domain/` only, which is CFI (`F3-AC-10`).
///
/// Two consumers, and their kinds differ: Marriage asks for `kind: "betrothal"`
/// (`MarriageCertificatePage.tsx:754`), Divorce for `kind: "mediation"`
/// (`DivorceCertificatePage.tsx:660`). The third wire kind,
/// `"marriage-certificate"`, has no caller on either page.
///
/// ## The only reachable state is EMPTY
///
/// `/prerequisite-records` answers `200 data: [] total: 0` for all three valid
/// `kind` values on **every account this programme has**
/// (`manifest-authenticated.md`:230-232). So:
///
/// - `linked_reference_no` is elided on all twelve Tier 0 documents
///   (`F0-AC-79`);
/// - `betrothal.betrothal_record_no` and `betrothal.proposal_date` are
///   permanently `""`;
/// - `creates_betrothal_record`'s `false` inhabitant — the product's only
///   `false` — is Entry-B-only (`oracle_coverage.yaml`:98-135, `F3-AC-64`);
/// - the `voluntary` + `mediationMode:"existing"` arm of Divorce is
///   unreachable (`F3-NV-4`).
///
/// The empty state is therefore the one the port must render correctly, and
/// the loaded and error states are specified and unit-tested against stubs
/// rather than executed (`F3-AC-49`, `F3-AC-50`).
library;

class PrerequisiteRecord {
  const PrerequisiteRecord({
    required this.id,
    required this.recordNo,
    required this.kind,
    required this.serviceCode,
    required this.partyAName,
    required this.partyBName,
    this.partyAUin,
    this.partyBUin,
    required this.recordedAt,
    required this.recordedBy,
    required this.status,
    required this.feeLak,
    this.payload,
  });

  final String id;

  /// What `linked_reference_no` carries and what `betrothal_record_no` /
  /// `mediation_record_no` echo (`MarriageCertificatePage.tsx:903`, `:963`).
  final String recordNo;

  /// `"betrothal" | "mediation" | "marriage-certificate"` on the wire. Kept as
  /// a `String`: the client never branches on it, it only sends it as a query
  /// filter, and an enum would turn a fourth server-side kind into a parse
  /// failure where the web shows the row.
  final String kind;

  final String serviceCode;
  final String partyAName;
  final String partyBName;

  /// `party_a_uin?` — optional on the wire, and `?? ""` at the one call site
  /// (`:824`).
  final String? partyAUin;
  final String? partyBUin;

  /// An ISO instant. **Sliced to 10 characters** wherever it reaches the wire
  /// or the screen — `recorded_at?.slice(0, 10)` (`:905`, `:1243`, `:1264`).
  final String recordedAt;

  final String recordedBy;
  final String status;
  final int feeLak;

  /// Free-form. Read only through `payloadString`
  /// (`certificate_payload_helpers.dart`), never indexed directly.
  final Map<String, Object?>? payload;

  /// `recorded_at?.slice(0, 10) ?? ""` — the shape both pages use for
  /// `betrothal.proposal_date` (`:905`).
  String get recordedDate =>
      recordedAt.length >= 10 ? recordedAt.substring(0, 10) : recordedAt;

  @override
  String toString() => 'PrerequisiteRecord($recordNo, $kind)';
}

/// One page of `GET /prerequisite-records`, as `api.paged` returns it.
///
/// The page's only reads are `records.data.length` (`:1225`) and
/// `records.data.map` (`:1230`); `total` is never rendered. It is carried
/// because dropping a field the wire sends is its own divergence.
class PrerequisiteRecordPage {
  const PrerequisiteRecordPage({required this.data, required this.total});

  final List<PrerequisiteRecord> data;
  final int total;

  static const PrerequisiteRecordPage empty =
      PrerequisiteRecordPage(data: <PrerequisiteRecord>[], total: 0);
}
