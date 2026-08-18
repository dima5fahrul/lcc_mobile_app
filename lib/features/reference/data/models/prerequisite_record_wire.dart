/// `types.ts:235-249`'s `PrerequisiteRecord`, wire → domain.
///
/// Kept in `data/models/` beside `reference_wire.dart` for the same reason that
/// file gives: the wire's vocabulary stops here and never surfaces upward.
///
/// ## Defensive on every field, and that is not laziness
///
/// A record whose `party_b_uin` is missing must still render as a row the
/// citizen can tap. The web reads `record.party_b_uin ?? ""`
/// (`MarriageCertificatePage.tsx:825`) and never guards the rest, because
/// TypeScript's structural types are erased at runtime — an absent
/// `recorded_by` renders `undefined` in the row's subtitle rather than
/// throwing. Dart would throw on a bad cast, so a missing string becomes `''`:
/// the same observable, without the crash the source cannot have.
///
/// **`fee_lak` is the one numeric.** `(x as num?)?.toInt()` rather than
/// `as int?`, because JSON `0.0` decodes to a `double` and a hard cast would
/// throw on a server that serialises money as a float.
library;

import '../../domain/entities/prerequisite_record.dart';

PrerequisiteRecord prerequisiteRecordFrom(Map<String, dynamic> row) =>
    PrerequisiteRecord(
      id: (row['id'] as String?) ?? '',
      recordNo: (row['record_no'] as String?) ?? '',
      // Kept as a String, never an enum: the client only ever sends this as a
      // query filter and never branches on it, and an enum would turn a fourth
      // server-side kind into a parse failure where the web shows the row.
      kind: (row['kind'] as String?) ?? '',
      serviceCode: (row['service_code'] as String?) ?? '',
      partyAName: (row['party_a_name'] as String?) ?? '',
      partyBName: (row['party_b_name'] as String?) ?? '',
      // Optional on the wire, and `?? ""` at the one call site (`:825`). Kept
      // nullable here so the *entity* can tell absent from empty; the call site
      // applies the source's coalesce.
      partyAUin: row['party_a_uin'] as String?,
      partyBUin: row['party_b_uin'] as String?,
      recordedAt: (row['recorded_at'] as String?) ?? '',
      recordedBy: (row['recorded_by'] as String?) ?? '',
      status: (row['status'] as String?) ?? '',
      feeLak: (row['fee_lak'] as num?)?.toInt() ?? 0,
      // Free-form. Read only through `payloadString`, never indexed directly.
      payload: (row['payload'] as Map<String, dynamic>?)?.cast<String, Object?>(),
    );
