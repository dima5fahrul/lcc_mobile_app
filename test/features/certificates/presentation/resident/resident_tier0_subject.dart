/// The Resident Tier 0 **subject**: the fixture reader, the register's clock,
/// and the four exempt rows — shared by the two files that judge this port.
///
/// ## Why this is a library and not a copy
///
/// Two tests drive `buildResidentFormData` against the same four oracles:
/// `resident_tier0_test.dart` (the page-local gate F1 wrote first) and
/// `test/fidelity/tier0_payload_equality_test.dart` (F0a's harness, which
/// `specs.md` § 3.1 row 10 has F1 register Resident into as its **first real
/// subject**). A second fixture reader would be a second chance to read the
/// fixture differently, and a divergence between the two would show up as one
/// of them passing.
///
/// **The exemption sets are hard-coded here and not parsed out of
/// `tier0_divergences.yaml`** — deriving them from the register would let a row
/// added there silently widen what the tests skip. A widening must be a diff in
/// this file (`F1-AC-31`).
library;

import 'dart:convert';
import 'dart:io';

import 'package:lcc_mobile_app/features/certificates/presentation/resident/resident_form_state.dart';

const String kResidentOracleDir =
    '../../docs/fidelity-baseline/2026-08-13/oracle/tier0';
const String kResidentFixtureDir = 'test/fidelity/fixtures/tier0/resident';

Map<String, dynamic> readOracleJson(String path) {
  final File f = File(path);
  if (!f.existsSync()) {
    throw StateError(
      'NOT EVALUATED — $path is absent. This test compares against artefacts '
      'F0a produced; a missing one is a missing measurement, not a pass.',
    );
  }
  return jsonDecode(f.readAsStringSync()) as Map<String, dynamic>;
}

/// `tier0_divergences.yaml`'s `meta.expected_local` / `meta.expected_web_utc`.
const String kExpectedLocal = '2026-08-14';
const String kExpectedWebUtc = '2026-08-13';

/// The four Resident rows of the register, as `(body, pointer-or-envelope-key)`.
///
/// Hard-coded rather than parsed out of the YAML **on purpose**: this list is
/// what the test exempts, and deriving it from the same file the register lives
/// in would let a row added there silently widen the exemption. A widening must
/// be a diff in this file too.
const Set<String> kResidentExemptFormDataPointers = <String>{
  '/purpose.issue_date',
};
const Set<String> kResidentExemptEnvelopeKeys = <String>{'event_date'};

/// The register's instant, as a wall clock.
///
/// `DateTime.parse` with an offset yields a **UTC** instant, and `todayLocal()`
/// reads `year`/`month`/`day` off whatever it is handed — so a bare parse would
/// make this test's result depend on the machine's timezone. Shifting to +07:00
/// gives a `DateTime` whose fields are the Vientiane wall clock on any host.
/// Same construction as `submission_clock_test.dart:25-26`.
final DateTime kRegisterInstant =
    DateTime.parse('2026-08-14T02:00:00+07:00').toUtc().add(
          const Duration(hours: 7),
        );


/// A `ResidentFormData` built from a Tier 0 fixture's `form` block.
///
/// The fixture mirrors the page's own state tree key for key
/// (`baseline.en.json`'s `_note`), so this is a rename-free read: every key
/// below is the fixture's key and the source's field name at once. A key the
/// fixture does not carry is a **failure**, not a default — a fixture that
/// silently lost `houseNo` would otherwise produce an oracle-matching payload
/// with an empty value in it.
ResidentFormData formFromFixture(Map<String, dynamic> fixture) {
  final Map<String, dynamic> f =
      fixture['form'] as Map<String, dynamic>? ?? <String, dynamic>{};

  String req(String key) {
    final Object? v = f[key];
    if (v is! String) {
      throw StateError(
        'fixture `form.$key` is ${v.runtimeType}, expected String. The Tier 0 '
        'fixtures are F0a\'s (specs.md § 6.5.3); a shape change there is a '
        'spec change, not something to default around.',
      );
    }
    return v;
  }

  return ResidentFormData(
    province: req('province'),
    district: req('district'),
    villageName: req('villageName'),
    villageChiefName: req('villageChiefName'),
    certifyingJurisdiction: req('certifyingJurisdiction'),
    citizenName: req('citizenName'),
    age: req('age'),
    occupation: req('occupation'),
    nationality: req('nationality'),
    currentVillage: req('currentVillage'),
    groupKhum: req('groupKhum'),
    unitNuayBan: req('unitNuayBan'),
    houseNo: req('houseNo'),
    censusBookNo: req('censusBookNo'),
    censusBookDate: req('censusBookDate'),
    censusDistrictProvince: req('censusDistrictProvince'),
    fatherName: req('fatherName'),
    motherName: req('motherName'),
    nativePlace: req('nativePlace'),
    purpose: req('purpose'),
    purposeOther: req('purposeOther'),
  );
}

/// [oracle] with the registered divergences rewritten to what the port must
/// emit — i.e. the oracle as it would read if the web had ADR-0005's fix.
///
/// Applied to a **decoded** tree and re-encoded, so the result is still
/// order-preserving: `jsonDecode` yields a `LinkedHashMap` in document order
/// and rewriting a value in place does not move it.
Map<String, Object?> applyDivergences(
  Map<String, dynamic> body, {
  required bool isEnvelope,
}) {
  final Map<String, Object?> out = <String, Object?>{};
  body.forEach((String k, Object? v) {
    if (isEnvelope && kResidentExemptEnvelopeKeys.contains(k)) {
      out[k] = kExpectedLocal;
    } else if (!isEnvelope &&
        kResidentExemptFormDataPointers.contains('/$k')) {
      out[k] = kExpectedLocal;
    } else if (v is Map<String, dynamic>) {
      out[k] = applyDivergences(v, isEnvelope: false);
    } else {
      out[k] = v;
    }
  });
  return out;
}

