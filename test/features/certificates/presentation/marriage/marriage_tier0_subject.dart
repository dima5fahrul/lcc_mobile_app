/// The Marriage Tier 0 **subject**: the fixture reader, the register's clock,
/// and the exempt row — shared by the two files that judge this port.
///
/// Same discipline as `resident_tier0_subject.dart`: a second fixture reader
/// would be a second chance to read the fixture differently, and a divergence
/// between the two would show up as one of them passing.
///
/// **The exemption set is hard-coded here and not parsed out of
/// `tier0_divergences.yaml`** — deriving it from the register would let a row
/// added there silently widen what the tests skip. A widening must be a diff in
/// this file (`F3-AC-39`, `F3-AC-82`).
library;

import 'dart:convert';
import 'dart:io';

import 'package:lcc_mobile_app/features/certificates/presentation/certificate_forms/certificate_location_value.dart';
import 'package:lcc_mobile_app/features/certificates/presentation/marriage/marriage_form_state.dart';
import 'package:lcc_mobile_app/features/reference/domain/entities/prerequisite_record.dart';

const String kMarriageOracleDir =
    '../../docs/fidelity-baseline/2026-08-13/oracle/tier0';
const String kMarriageFixtureDir = 'test/fidelity/fixtures/tier0/marriage';

/// `tier0_divergences.yaml`'s `meta.expected_local` / `meta.expected_web_utc`.
const String kMarriageExpectedLocal = '2026-08-14';
const String kMarriageExpectedWebUtc = '2026-08-13';

/// **The two Marriage rows of the register, as one `form_data` pointer.**
///
/// `tier0_divergences.yaml`:151-171 holds `(marriage, create, header.dated)`
/// and `(marriage, update, header.dated)` — two rows, one pointer, because the
/// create and update bodies are oracled separately.
///
/// **`/header/dated`, not `/header.dated`.** Birth's is the literal flat key
/// and the two strings are different; a dotted flattener collapses them and
/// reports the families equal, which is mutant M5's whole subject.
const Set<String> kMarriageExemptFormDataPointers = <String>{'/header/dated'};

/// **Empty, and that is the assertion.** `event_date` on this page is
/// `reg.dateOfMarriage || undefined` (`:962`) — it never calls `today()`, so no
/// envelope key of Marriage's is exempt. A non-empty set here would be a fifth
/// register row (§ 8.3 BLOCKED).
const Set<String> kMarriageExemptEnvelopeKeys = <String>{};

/// The register's instant, as a wall clock.
///
/// `DateTime.parse` with an offset yields a UTC instant and `todayLocal()`
/// reads `year`/`month`/`day` off whatever it is handed, so a bare parse would
/// make the result depend on the host's timezone. Shifting to +07:00 gives a
/// `DateTime` whose fields are the Vientiane wall clock on any host. Same
/// construction as `resident_tier0_subject.dart:62-65`.
final DateTime kMarriageRegisterInstant =
    DateTime.parse('2026-08-14T02:00:00+07:00').toUtc().add(
          const Duration(hours: 7),
        );

Map<String, dynamic> readMarriageJson(String path) {
  final File f = File(path);
  if (!f.existsSync()) {
    throw StateError(
      'NOT EVALUATED — $path is absent. This test compares against artefacts '
      'F0a produced; a missing one is a missing measurement, not a pass.',
    );
  }
  return jsonDecode(f.readAsStringSync()) as Map<String, dynamic>;
}

/// The fixture's `_locations` table, resolved under its `_locale` seed.
///
/// This is `nameOf(rows, id) = text(found.name, lang)`
/// (`MarriageCertificatePage.tsx:307-310`) applied at **pick** time, which is
/// what makes `address_text` differ between the `en` and `lo` oracles and what
/// Guard B asserts. Resolving it here rather than in the payload builder is the
/// same split the running app has: the select resolves, the builder joins.
class _Locations {
  _Locations(this.table, this.locale);

  final Map<String, dynamic> table;
  final String locale;

  String nameOf(String id) {
    if (id.isEmpty) return '';
    final Object? row = table[id];
    if (row is! Map) {
      throw StateError(
        'fixture `_locations` has no row for $id. The Tier 0 fixtures are '
        "F0a's; a missing row is a fixture change, not something to default "
        'around.',
      );
    }
    final Object? wanted = locale == 'lo' ? row['lo'] : row['en'];
    if (wanted is String && wanted.isNotEmpty) return wanted;
    final Object? en = row['en'];
    if (en is String && en.isNotEmpty) return en;
    final Object? lo = row['lo'];
    return lo is String ? lo : '';
  }
}

CertificateLocationValue _location(
  Map<String, dynamic>? raw,
  _Locations locations,
) {
  if (raw == null) return CertificateLocationValue.blank;
  String id(String key) {
    final Object? v = raw[key];
    if (v is! String) {
      throw StateError('fixture location `$key` is ${v.runtimeType}');
    }
    return v;
  }

  final String p = id('provinceId');
  final String d = id('districtId');
  final String v = id('villageId');
  return CertificateLocationValue(
    provinceId: p,
    districtId: d,
    villageId: v,
    provinceName: locations.nameOf(p),
    districtName: locations.nameOf(d),
    villageName: locations.nameOf(v),
  );
}

String _req(Map<String, dynamic> m, String key) {
  final Object? v = m[key];
  if (v is! String) {
    throw StateError(
      'fixture `$key` is ${v.runtimeType}, expected String. The Tier 0 '
      "fixtures are F0a's (specs.md § 6.5.3); a shape change there is a spec "
      'change, not something to default around.',
    );
  }
  return v;
}

MarriageSpouseInfo _spouse(
  Map<String, dynamic> raw,
  _Locations locations,
) =>
    MarriageSpouseInfo(
      fullName: _req(raw, 'fullName'),
      dob: _req(raw, 'dob'),
      gender: _req(raw, 'gender'),
      nationality: _req(raw, 'nationality'),
      ethnicity: _req(raw, 'ethnicity'),
      ethnicGroup: _req(raw, 'ethnicGroup'),
      religion: _req(raw, 'religion'),
      occupation: _req(raw, 'occupation'),
      idOrPassport: _req(raw, 'idOrPassport'),
      addrHouseNo: _req(raw, 'addrHouseNo'),
      address: _location(
        raw['address'] as Map<String, dynamic>?,
        locations,
      ),
      residenceCertRef: _req(raw, 'residenceCertRef'),
    );

/// A [MarriageFormData] built from a Tier 0 fixture.
///
/// The fixture mirrors the page's own state tree key for key, so this is a
/// rename-free read. A key the fixture does not carry is a **failure**, not a
/// default — a fixture that silently lost `residenceCertRef` would otherwise
/// produce an oracle-matching payload with an empty value in it.
///
/// **The three upload slots are absent from the fixture and stay null.** They
/// do not reach `form_data`; they reach the multipart POST, which Tier 0 does
/// not oracle.
MarriageFormData marriageFormFromFixture(Map<String, dynamic> fixture) {
  final _Locations locations = _Locations(
    (fixture['_locations'] as Map<String, dynamic>?) ?? <String, dynamic>{},
    fixture['_locale'] as String? ?? 'en',
  );

  final Map<String, dynamic> betrothal =
      (fixture['betrothal'] as Map<String, dynamic>?) ?? <String, dynamic>{};
  final Map<String, dynamic> reg =
      (fixture['reg'] as Map<String, dynamic>?) ?? <String, dynamic>{};

  final String mode = fixture['betrothalMode'] as String? ?? '';
  final Object? linked = fixture['linkedRecord'];

  return MarriageFormData(
    betrothalMode: switch (mode) {
      'existing' => MarriageBetrothalMode.existing,
      'new' => MarriageBetrothalMode.newRecord,
      '' => MarriageBetrothalMode.none,
      _ => throw StateError('fixture `betrothalMode` is "$mode"'),
    },
    // `/prerequisite-records` answers `data: []` on every account this
    // programme has, so every executed fixture carries `null` here. A fixture
    // that did carry one would be Entry-B-only (`F3-AC-64`).
    linkedRecord: linked == null
        ? null
        : _linkedRecord(linked as Map<String, dynamic>),
    betrothal: MarriageBetrothal(
      householdHead: _req(betrothal, 'householdHead'),
      bridePriceCash: _req(betrothal, 'bridePriceCash'),
      bridePriceGold: _req(betrothal, 'bridePriceGold'),
      housing: _req(betrothal, 'housing'),
      w1Name: _req(betrothal, 'w1Name'),
      w2Name: _req(betrothal, 'w2Name'),
    ),
    header: _location(fixture['header'] as Map<String, dynamic>?, locations),
    spouseA: _spouse(fixture['spouseA']! as Map<String, dynamic>, locations),
    spouseB: _spouse(fixture['spouseB']! as Map<String, dynamic>, locations),
    reg: MarriageRegistration(
      dateOfMarriage: _req(reg, 'dateOfMarriage'),
      placeOfRegistration: _req(reg, 'placeOfRegistration'),
      w1Name: _req(reg, 'w1Name'),
      w1Id: _req(reg, 'w1Id'),
      w2Name: _req(reg, 'w2Name'),
      w2Id: _req(reg, 'w2Id'),
      w3Name: _req(reg, 'w3Name'),
      w3Id: _req(reg, 'w3Id'),
    ),
  );
}

PrerequisiteRecord _linkedRecord(Map<String, dynamic> raw) => PrerequisiteRecord(
      id: raw['id'] as String? ?? '',
      recordNo: raw['record_no'] as String? ?? '',
      kind: raw['kind'] as String? ?? 'betrothal',
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
