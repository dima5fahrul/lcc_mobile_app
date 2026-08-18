/// The Divorce Tier 0 **subject** — the fixture reader for **both arms**.
///
/// Divorce is the only page in the product whose Tier 0 run is eight documents
/// rather than four, because its step 1 splits the payload: `mediation.*` is
/// non-empty only under `voluntary` + `new`, `basis.court_*` only under
/// `contested`. `divorceFormFromFixture` reads whichever arm the fixture
/// declares and **refuses to choose one on a fixture's behalf** — the same
/// refusal `driveDivorce` makes with `DIVORCE_MEDIATION_MODE_UNDECLARED`
/// (`F3-AC-48`).
library;

import 'dart:convert';
import 'dart:io';

import 'package:lcc_mobile_app/features/certificates/presentation/certificate_forms/certificate_location_value.dart';
import 'package:lcc_mobile_app/features/certificates/presentation/divorce/divorce_form_state.dart';
import 'package:lcc_mobile_app/features/reference/domain/entities/prerequisite_record.dart';

const String kDivorceOracleDir =
    '../../docs/fidelity-baseline/2026-08-13/oracle/tier0';
const String kDivorceFixtureDir = 'test/fidelity/fixtures/tier0/divorce';

const String kDivorceExpectedLocal = '2026-08-14';
const String kDivorceExpectedWebUtc = '2026-08-13';

/// `tier0_divergences.yaml`:173-181 — two rows, one pointer, nested.
const Set<String> kDivorceExemptFormDataPointers = <String>{'/header/dated'};

/// Empty: `event_date` is `basis.dateOfDivorce || undefined` (`:858`), never
/// `today()`.
const Set<String> kDivorceExemptEnvelopeKeys = <String>{};

final DateTime kDivorceRegisterInstant =
    DateTime.parse('2026-08-14T02:00:00+07:00').toUtc().add(
          const Duration(hours: 7),
        );

Map<String, dynamic> readDivorceJson(String path) {
  final File f = File(path);
  if (!f.existsSync()) {
    throw StateError(
      'NOT EVALUATED — $path is absent. This test compares against artefacts '
      'F0a produced; a missing one is a missing measurement, not a pass.',
    );
  }
  return jsonDecode(f.readAsStringSync()) as Map<String, dynamic>;
}

class _Locations {
  _Locations(this.table, this.locale);

  final Map<String, dynamic> table;
  final String locale;

  String nameOf(String id) {
    if (id.isEmpty) return '';
    final Object? row = table[id];
    if (row is! Map) {
      throw StateError('fixture `_locations` has no row for $id');
    }
    final Object? wanted = locale == 'lo' ? row['lo'] : row['en'];
    if (wanted is String && wanted.isNotEmpty) return wanted;
    final Object? en = row['en'];
    if (en is String && en.isNotEmpty) return en;
    final Object? lo = row['lo'];
    return lo is String ? lo : '';
  }
}

String _req(Map<String, dynamic> m, String key) {
  final Object? v = m[key];
  if (v is! String) {
    throw StateError('fixture `$key` is ${v.runtimeType}, expected String');
  }
  return v;
}

CertificateLocationValue _location(
  Map<String, dynamic>? raw,
  _Locations locations,
) {
  if (raw == null) return CertificateLocationValue.blank;
  final String p = _req(raw, 'provinceId');
  final String d = _req(raw, 'districtId');
  final String v = _req(raw, 'villageId');
  return CertificateLocationValue(
    provinceId: p,
    districtId: d,
    villageId: v,
    provinceName: locations.nameOf(p),
    districtName: locations.nameOf(d),
    villageName: locations.nameOf(v),
  );
}

DivorceSpouseInfo _spouse(Map<String, dynamic> raw, _Locations locations) =>
    DivorceSpouseInfo(
      fullName: _req(raw, 'fullName'),
      dob: _req(raw, 'dob'),
      nationality: _req(raw, 'nationality'),
      idOrPassport: _req(raw, 'idOrPassport'),
      addrHouseNo: _req(raw, 'addrHouseNo'),
      address: _location(raw['address'] as Map<String, dynamic>?, locations),
      marriageCertRef: _req(raw, 'marriageCertRef'),
    );

/// A [DivorceFormData] built from a Tier 0 fixture, **either arm**.
///
/// The arm is read from the fixture, never inferred:
///
/// - a `contested` fixture carries `court` and **no** `mediationMode`;
/// - a `voluntary` fixture carries `mediationMode`, `mediation`, and
///   `hasChildren` / `children`.
///
/// A `voluntary` fixture with no `mediationMode` throws rather than defaulting
/// to `"new"` — the third arm (`voluntary` + `existing`) is registered
/// unreachable (`oracle_coverage.yaml`:137-152) and silently choosing for it
/// would be the substitution `F3-AC-48` exists to block.
DivorceFormData divorceFormFromFixture(Map<String, dynamic> fixture) {
  final _Locations locations = _Locations(
    (fixture['_locations'] as Map<String, dynamic>?) ?? <String, dynamic>{},
    fixture['_locale'] as String? ?? 'en',
  );

  final Map<String, dynamic> basis =
      (fixture['basis'] as Map<String, dynamic>?) ?? <String, dynamic>{};
  final String divorceType = _req(basis, 'divorceType');

  final Map<String, dynamic>? mediation =
      fixture['mediation'] as Map<String, dynamic>?;
  final Map<String, dynamic>? court = fixture['court'] as Map<String, dynamic>?;
  final Map<String, dynamic>? children =
      fixture['children'] as Map<String, dynamic>?;
  final String? mode = fixture['mediationMode'] as String?;

  if (divorceType == kDivorceTypeVoluntary && mode == null) {
    throw StateError(
      'DIVORCE_MEDIATION_MODE_UNDECLARED — a voluntary fixture must declare '
      '`mediationMode`. The `existing` arm is registered unreachable '
      '(oracle_coverage.yaml:137-152) and choosing on the fixture\'s behalf is '
      'what F3-AC-48 forbids.',
    );
  }

  return DivorceFormData(
    header: _location(fixture['header'] as Map<String, dynamic>?, locations),
    husband: _spouse(fixture['husband']! as Map<String, dynamic>, locations),
    wife: _spouse(fixture['wife']! as Map<String, dynamic>, locations),
    basis: DivorceBasis(
      divorceType: divorceType,
      dateOfDivorce: _req(basis, 'dateOfDivorce'),
      placeOfRegistration: _req(basis, 'placeOfRegistration'),
    ),
    mediationMode: switch (mode) {
      'existing' => DivorceMediationMode.existing,
      'new' => DivorceMediationMode.newRecord,
      null || '' => DivorceMediationMode.none,
      _ => throw StateError('fixture `mediationMode` is "$mode"'),
    },
    linkedRecord: fixture['linkedRecord'] == null
        ? null
        : _linkedRecord(fixture['linkedRecord']! as Map<String, dynamic>),
    mediation: mediation == null
        ? DivorceMediation.blank
        : DivorceMediation(
            dateMarriageBegan: _req(mediation, 'dateMarriageBegan'),
            reasonsHusband: _req(mediation, 'reasonsHusband'),
            reasonsWife: _req(mediation, 'reasonsWife'),
            outcome: _req(mediation, 'outcome'),
            propertyDivision: _req(mediation, 'propertyDivision'),
            debts: _req(mediation, 'debts'),
            additionalAssets: _req(mediation, 'additionalAssets'),
            w1Name: _req(mediation, 'w1Name'),
            w2Name: _req(mediation, 'w2Name'),
          ),
    hasChildren: fixture['hasChildren'] as bool? ?? false,
    children: children == null
        ? DivorceChildren.blank
        : DivorceChildren(
            list: _req(children, 'list'),
            custody: _req(children, 'custody'),
          ),
    court: court == null
        ? DivorceCourt.blank
        : DivorceCourt(
            name: _req(court, 'name'),
            decisionDate: _req(court, 'decisionDate'),
          ),
  );
}

PrerequisiteRecord _linkedRecord(Map<String, dynamic> raw) => PrerequisiteRecord(
      id: raw['id'] as String? ?? '',
      recordNo: raw['record_no'] as String? ?? '',
      kind: raw['kind'] as String? ?? 'mediation',
      serviceCode: raw['service_code'] as String? ?? '',
      partyAName: raw['party_a_name'] as String? ?? '',
      partyBName: raw['party_b_name'] as String? ?? '',
      partyAUin: raw['party_a_uin'] as String?,
      partyBUin: raw['party_b_uin'] as String?,
      recordedAt: raw['recorded_at'] as String? ?? '',
      recordedBy: raw['recorded_by'] as String? ?? '',
      status: raw['status'] as String? ?? '',
      feeLak: raw['fee_lak'] as int? ?? 0,
      payload: (raw['payload'] as Map<String, dynamic>?)?.cast<String, Object?>(),
    );
