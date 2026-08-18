/// The Birth Tier 0 **subject**: the fixture reader, the register's clock, the
/// four exempt rows, and the `legalBasisText` lookup — shared by the two files
/// that judge this port.
///
/// ## Why this is a library and not a copy
///
/// Two tests drive [buildBirthFormData] against the same eight executed
/// oracles: `birth_tier0_test.dart` (the page-local gate) and
/// `test/fidelity/tier0_payload_equality_test.dart` (F0a's harness, which
/// `specs.md` § 3.1 row 7 has F2 register Birth into). A second fixture reader
/// would be a second chance to read the fixture differently, and a divergence
/// between the two would show up as one of them passing. Same discipline as
/// `resident_tier0_subject.dart`.
///
/// ## The exemption sets are hard-coded, not parsed out of the register
///
/// Deriving them from `tier0_divergences.yaml` would let a row added there
/// silently widen what the tests skip. A widening must be a diff in this file
/// (`F2-AC-41` — the register is closed, `ADR-0005` O-5).
///
/// ## `legalBasisText` comes out of the shipped asset, per namespace
///
/// [birthLegalBasisFor] reads `assets/i18n/{locale}.json` -> `birth` ->
/// `legalBasisText`. Not a Dart literal, and not a constant shared with Death:
/// the two namespaces' **English is byte-identical and their Lao is not**
/// (`specs.md` § 2.2 Finding B), so a single hoisted string passes every
/// English assertion and is wrong in Lao on all twenty documents. Reading the
/// asset also makes the appended i18n itself part of the Tier 0 evidence — if
/// the append lost or mangled the sentence, these tests go red rather than the
/// bug surfacing at runtime in one locale.
library;

import 'dart:convert';
import 'dart:io';

import 'package:lcc_mobile_app/features/certificates/presentation/birth/birth_form_state.dart';

const String kBirthOracleDir =
    '../../docs/fidelity-baseline/2026-08-13/oracle/tier0';
const String kBirthFixtureDir = 'test/fidelity/fixtures/tier0/birth';

Map<String, dynamic> readBirthJson(String path) {
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
const String kBirthExpectedLocal = '2026-08-14';
const String kBirthExpectedWebUtc = '2026-08-13';

/// The **four** Birth rows of the register: `header.dated` x {create, update}
/// and the `event_date` envelope key x {create, update}.
///
/// A fifth is BLOCKED — the register is closed and the amendment trigger is a
/// ninth registered *wire key*, not a seventeenth row.
const Set<String> kBirthExemptFormDataPointers = <String>{'/header.dated'};
const Set<String> kBirthExemptEnvelopeKeys = <String>{'event_date'};

/// The register's instant, as a wall clock.
///
/// `DateTime.parse` with an offset yields a **UTC** instant and `todayLocal()`
/// reads `year`/`month`/`day` off whatever it is handed, so a bare parse would
/// make the result depend on the host's timezone. Shifting to +07:00 gives a
/// `DateTime` whose fields are the Vientiane wall clock on any host. Same
/// construction as `submission_clock_test.dart:25-26`.
final DateTime kBirthRegisterInstant =
    DateTime.parse('2026-08-14T02:00:00+07:00').toUtc().add(
          const Duration(hours: 7),
        );

/// `birth.legalBasisText`, out of the shipped asset for [locale].
///
/// **Reads the `birth` namespace and only the `birth` namespace.** The death
/// subject has its own function reading `death`; there is no shared helper
/// taking a namespace parameter, because a namespace parameter is exactly the
/// shape that lets one call site pass the wrong one and stay green in English.
String birthLegalBasisFor(String locale) {
  final Map<String, dynamic> bundle =
      readBirthJson('assets/i18n/$locale.json');
  final Object? ns = bundle['birth'];
  if (ns is! Map<String, dynamic>) {
    throw StateError(
      'NOT EVALUATED — assets/i18n/$locale.json has no `birth` namespace. '
      'F2 appends 152 keys per locale (§ 3.1 row 5); without them the wire '
      'value for header.legal_basis does not exist and Tier 0 would be '
      'comparing a placeholder.',
    );
  }
  final Object? v = ns['legalBasisText'];
  if (v is! String || v.isEmpty) {
    throw StateError('birth.legalBasisText missing in $locale');
  }
  return v;
}

String _req(Map<String, dynamic> block, String key, String where) {
  final Object? v = block[key];
  if (v is! String) {
    throw StateError(
      'fixture `$where.$key` is ${v.runtimeType}, expected String. The Tier 0 '
      'fixtures are F0a\'s; a shape change there is a spec change, not '
      'something to default around.',
    );
  }
  return v;
}

/// A [BirthFormData] built from a Tier 0 fixture.
///
/// The fixture mirrors the page's own state tree key for key, so this is a
/// rename-free read. A key the fixture does not carry is a **failure**, not a
/// default — a fixture that silently lost `houseNo` would otherwise produce an
/// oracle-matching payload with an empty value in it.
///
/// The four UI-only child fields (`pobProvince`, `pobDistrict`, `addrDistrict`,
/// `addrProvince`) are **absent from the fixture by design**: they gate
/// `canProceed` and drive `LocationFields`, and `buildFormData` never reads
/// them. They keep their blank-record defaults here.
BirthFormData birthFormFromFixture(Map<String, dynamic> fixture) {
  final Map<String, dynamic> header =
      fixture['header'] as Map<String, dynamic>;
  final Map<String, dynamic> c = fixture['child'] as Map<String, dynamic>;
  final Map<String, dynamic> m = fixture['mother'] as Map<String, dynamic>;
  final Map<String, dynamic> f = fixture['father'] as Map<String, dynamic>;
  final Map<String, dynamic> i = fixture['informant'] as Map<String, dynamic>;

  BirthParentInfo parent(Map<String, dynamic> p, String where) =>
      BirthParentInfo(
        fullName: _req(p, 'fullName', where),
        fingerprint: _req(p, 'fingerprint', where),
        dob: _req(p, 'dob', where),
        ethnicity: _req(p, 'ethnicity', where),
        nationality: _req(p, 'nationality', where),
        ethnicGroup: _req(p, 'ethnicGroup', where),
        religion: _req(p, 'religion', where),
        maritalStatus: _req(p, 'maritalStatus', where),
        addrHouseNo: _req(p, 'addrHouseNo', where),
        addrVillage: _req(p, 'addrVillage', where),
        censusOrId: _req(p, 'censusOrId', where),
        education: _req(p, 'education', where),
        occupation: _req(p, 'occupation', where),
      );

  return BirthFormData(
    province: _req(header, 'province', 'header'),
    district: _req(header, 'district', 'header'),
    village: _req(header, 'village', 'header'),
    child: BirthChildInfo(
      fullName: _req(c, 'fullName', 'child'),
      gender: _req(c, 'gender', 'child'),
      dob: _req(c, 'dob', 'child'),
      weight: _req(c, 'weight', 'child'),
      height: _req(c, 'height', 'child'),
      fingerprint: _req(c, 'fingerprint', 'child'),
      bloodType: _req(c, 'bloodType', 'child'),
      deliveryMode: _req(c, 'deliveryMode', 'child'),
      deliveryAssistedBy: _req(c, 'deliveryAssistedBy', 'child'),
      birthType: _req(c, 'birthType', 'child'),
      birthOrder: _req(c, 'birthOrder', 'child'),
      ethnicity: _req(c, 'ethnicity', 'child'),
      nationality: _req(c, 'nationality', 'child'),
      religion: _req(c, 'religion', 'child'),
      pobVillage: _req(c, 'pobVillage', 'child'),
      pobCountry: _req(c, 'pobCountry', 'child'),
      addrHouseNo: _req(c, 'addrHouseNo', 'child'),
      addrVillage: _req(c, 'addrVillage', 'child'),
      twinName: _req(c, 'twinName', 'child'),
      twinGender: _req(c, 'twinGender', 'child'),
    ),
    mother: parent(m, 'mother'),
    father: parent(f, 'father'),
    fatherUnknown: fixture['fatherUnknown'] as bool,
    informant: BirthInformantInfo(
      fullName: _req(i, 'fullName', 'informant'),
      fingerprint: _req(i, 'fingerprint', 'informant'),
      dob: _req(i, 'dob', 'informant'),
      ethnicity: _req(i, 'ethnicity', 'informant'),
      nationality: _req(i, 'nationality', 'informant'),
      ethnicGroup: _req(i, 'ethnicGroup', 'informant'),
      religion: _req(i, 'religion', 'informant'),
      maritalStatus: _req(i, 'maritalStatus', 'informant'),
      addrHouseNo: _req(i, 'addrHouseNo', 'informant'),
      addrVillage: _req(i, 'addrVillage', 'informant'),
      censusOrId: _req(i, 'censusOrId', 'informant'),
      education: _req(i, 'education', 'informant'),
      relationship: _req(i, 'relationship', 'informant'),
      phone: _req(i, 'phone', 'informant'),
      email: _req(i, 'email', 'informant'),
    ),
  );
}
