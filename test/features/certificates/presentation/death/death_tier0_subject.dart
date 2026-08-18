/// The Death Tier 0 **subject**: the fixture reader, the register's clock, the
/// four exempt rows, and the `legalBasisText` lookup.
///
/// Structured like `birth_tier0_subject.dart` and sharing **nothing** with it.
/// The two files look alike and are not the same: the fixture blocks differ
/// (`deceased` against `child`, two skip flags against one), the parent record
/// carries `workplace`, and the informant record has three fewer fields.
///
/// [deathLegalBasisFor] reads the **`death`** namespace, and there is no shared
/// helper taking a namespace parameter — a namespace parameter is exactly the
/// shape that lets one call site pass the wrong one and stay green in English,
/// which is the one bug in this batch that is invisible in the default locale.
library;

import 'dart:convert';
import 'dart:io';

import 'package:lcc_mobile_app/features/certificates/presentation/death/death_form_state.dart';

const String kDeathOracleDir =
    '../../docs/fidelity-baseline/2026-08-13/oracle/tier0';
const String kDeathFixtureDir = 'test/fidelity/fixtures/tier0/death';

Map<String, dynamic> readDeathJson(String path) {
  final File f = File(path);
  if (!f.existsSync()) {
    throw StateError(
      'NOT EVALUATED — $path is absent. This test compares against artefacts '
      'F0a produced; a missing one is a missing measurement, not a pass.',
    );
  }
  return jsonDecode(f.readAsStringSync()) as Map<String, dynamic>;
}

const String kDeathExpectedLocal = '2026-08-14';
const String kDeathExpectedWebUtc = '2026-08-13';

/// The **four** Death rows of the register: `header.dated` x {create, update}
/// and the `event_date` envelope key x {create, update}. A fifth is BLOCKED.
const Set<String> kDeathExemptFormDataPointers = <String>{'/header.dated'};
const Set<String> kDeathExemptEnvelopeKeys = <String>{'event_date'};

final DateTime kDeathRegisterInstant =
    DateTime.parse('2026-08-14T02:00:00+07:00').toUtc().add(
          const Duration(hours: 7),
        );

/// `death.legalBasisText`, out of the shipped asset for [locale].
///
/// Reads the `death` namespace and only the `death` namespace.
String deathLegalBasisFor(String locale) {
  final Map<String, dynamic> bundle =
      readDeathJson('assets/i18n/$locale.json');
  final Object? ns = bundle['death'];
  if (ns is! Map<String, dynamic>) {
    throw StateError(
      'NOT EVALUATED — assets/i18n/$locale.json has no `death` namespace. '
      'F2 appends 97 keys per locale (§ 3.1 row 5).',
    );
  }
  final Object? v = ns['legalBasisText'];
  if (v is! String || v.isEmpty) {
    throw StateError('death.legalBasisText missing in $locale');
  }
  return v;
}

String _req(Map<String, dynamic> block, String key, String where) {
  final Object? v = block[key];
  if (v is! String) {
    throw StateError(
      'fixture `$where.$key` is ${v.runtimeType}, expected String. The Tier 0 '
      'fixtures are F0a\'s; a shape change there is a spec change.',
    );
  }
  return v;
}

/// A [DeathFormData] built from a Tier 0 fixture.
///
/// The UI-only fields (`addrDistrict`, `addrProvince`, `podDistrict`,
/// `podProvince`) are absent from the fixture by design: they gate
/// `canProceed` and drive `LocationFields`, and `buildFormData` never reads
/// them.
DeathFormData deathFormFromFixture(Map<String, dynamic> fixture) {
  final Map<String, dynamic> header =
      fixture['header'] as Map<String, dynamic>;
  final Map<String, dynamic> d = fixture['deceased'] as Map<String, dynamic>;
  final Map<String, dynamic> m = fixture['mother'] as Map<String, dynamic>;
  final Map<String, dynamic> f = fixture['father'] as Map<String, dynamic>;
  final Map<String, dynamic> i = fixture['informant'] as Map<String, dynamic>;

  // Fifteen fields, including `workplace` — Birth's parent reader has fourteen
  // and no `workplace` key to read.
  DeathParentInfo parent(Map<String, dynamic> p, String where) =>
      DeathParentInfo(
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
        workplace: _req(p, 'workplace', where),
      );

  return DeathFormData(
    province: _req(header, 'province', 'header'),
    district: _req(header, 'district', 'header'),
    village: _req(header, 'village', 'header'),
    deceased: DeathDeceasedInfo(
      fullName: _req(d, 'fullName', 'deceased'),
      fingerprint: _req(d, 'fingerprint', 'deceased'),
      gender: _req(d, 'gender', 'deceased'),
      dob: _req(d, 'dob', 'deceased'),
      education: _req(d, 'education', 'deceased'),
      occupation: _req(d, 'occupation', 'deceased'),
      workplace: _req(d, 'workplace', 'deceased'),
      ethnicity: _req(d, 'ethnicity', 'deceased'),
      nationality: _req(d, 'nationality', 'deceased'),
      ethnicGroup: _req(d, 'ethnicGroup', 'deceased'),
      religion: _req(d, 'religion', 'deceased'),
      maritalStatus: _req(d, 'maritalStatus', 'deceased'),
      addrHouseNo: _req(d, 'addrHouseNo', 'deceased'),
      addrVillage: _req(d, 'addrVillage', 'deceased'),
      censusOrId: _req(d, 'censusOrId', 'deceased'),
      podVillage: _req(d, 'podVillage', 'deceased'),
      podCountry: _req(d, 'podCountry', 'deceased'),
      dateOfDeath: _req(d, 'dateOfDeath', 'deceased'),
      timeOfDeath: _req(d, 'timeOfDeath', 'deceased'),
      cause: _req(d, 'cause', 'deceased'),
      causeOther: _req(d, 'causeOther', 'deceased'),
    ),
    mother: parent(m, 'mother'),
    motherSkip: fixture['motherSkip'] as bool,
    father: parent(f, 'father'),
    fatherSkip: fixture['fatherSkip'] as bool,
    informant: DeathInformantInfo(
      fullName: _req(i, 'fullName', 'informant'),
      fingerprint: _req(i, 'fingerprint', 'informant'),
      dob: _req(i, 'dob', 'informant'),
      nationality: _req(i, 'nationality', 'informant'),
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
