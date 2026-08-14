/// Loading the versioned fidelity oracles off disk.
///
/// The oracles live **outside** the Flutter package, under
/// `docs/fidelity-baseline/2026-08-13/oracle/`, because they belong to the
/// baseline rather than to the app: B2b, B2c and every later batch read the
/// same files, and a copy inside `test/` would be a second one to keep in step.
/// `flutter test` runs from the package root, so the path up and across is
/// fixed and is written once, here.
///
/// The read is `readAsStringSync`. That is load-bearing for the same reason
/// `app_test_harness.dart`'s `JsonFileAssetLoader` gives: a `testWidgets` body
/// runs inside a `FakeAsync` zone, `pumpAndSettle` never lets the real event
/// loop run, and an `await file.readAsString()` would hang forever while the
/// harness reported success.
library;

import 'dart:convert';
import 'dart:io';

/// The versioned oracle root, relative to the Flutter package root.
const String kOracleDir = '../../docs/fidelity-baseline/2026-08-13/oracle';

/// The web commit every oracle and every baseline PNG is pinned to.
///
/// § 8.3: if `sources/lcc-app` has moved off this, **stop and escalate** — a
/// baseline spanning two web commits is unattributable.
const String kWebCommit = '62f8a529aaa024a8b35b0af50a8fbd4850a63962';

Map<String, dynamic> _readJson(String path) {
  final File file = File(path);
  if (!file.existsSync()) {
    throw StateError(
      'Missing oracle `$path`. It is a versioned artefact (B2-AC-29), not '
      'something a test run regenerates — if it is absent, the checkout is '
      'incomplete or the test is running from somewhere other than the '
      'package root.',
    );
  }
  return json.decode(file.readAsStringSync()) as Map<String, dynamic>;
}

/// `oracle/tier1/service.<locale>.json`.
Map<String, dynamic> loadTier1(String route, String locale) =>
    _readJson('$kOracleDir/tier1/$route.$locale.json');

/// `oracle/tier2/tokens.json`.
Map<String, dynamic> loadTier2() => _readJson('$kOracleDir/tier2/tokens.json');

/// `oracle/api/<name>.json` → the envelope's `data` array.
///
/// **B2-AC-36's fixture.** These are real recorded staging payloads, not
/// hand-written JSON: 43 services and 8 categories as `GET /services` and
/// `GET /service-categories` actually answered on 2026-08-13. That matters
/// because § 5 flags the mixed-wire-shape trap — a model that assumes one
/// shape parses hand-written JSON happily and fails on the real thing.
List<Map<String, dynamic>> loadApi(String name) =>
    (_readJson('$kOracleDir/api/$name.json')['data'] as List<dynamic>)
        .cast<Map<String, dynamic>>();

/// `oracle/api/<name>.json` → the envelope's `data` **object**.
///
/// Additive companion to [loadApi] (B2c). B2a recorded only array endpoints;
/// B2c's set includes two that answer a single object — `GET /news/<slug>` and
/// `GET /help/articles/<slug>` — and casting those through [loadApi] would
/// throw on the `List` cast rather than say what is wrong.
Map<String, dynamic> loadApiObject(String name) =>
    _readJson('$kOracleDir/api/$name.json')['data'] as Map<String, dynamic>;

/// `oracle/api/<name>.json` → the envelope's `meta` block, or null.
///
/// The paged recordings carry one and the unpaged ones do not, which is itself
/// worth being able to assert: a fixture that lost its `meta` would silently
/// make every pager test render "1 / 1".
Map<String, dynamic>? loadApiMeta(String name) =>
    _readJson('$kOracleDir/api/$name.json')['meta'] as Map<String, dynamic>?;

// ─────────────────────────────────────────────────────────────────────────────
// Tier 0 — the payload oracles (F0a, § 6.5.1). Additive: nothing above changes.
// ─────────────────────────────────────────────────────────────────────────────

/// `oracle/tier0/` — the 22-document matrix `F0-AC-34` counts.
const String kTier0Dir = '$kOracleDir/tier0';

/// `oracle/tier0/variants/` — the NON-canonical fixture variants.
///
/// They live one level down on purpose. `F0-AC-34` asserts the matrix is
/// exactly 22 files and [tier0OracleNames] lists one level, so a variant
/// cannot inflate the count. What they carry is the behaviour a single
/// canonical fixture cannot show: Birth's `fatherUnknown` and Death's
/// `motherSkip`/`fatherSkip` changed KEY SETS (`F0-AC-38`), `both()`'s trim
/// asymmetry against the whitespace fixtures (`F0-AC-83`), the blank-B
/// collapse to `""` (`F0-AC-37b`), and the boolean's second literal
/// (`F0-AC-81`).
const String kTier0VariantsDir = '$kTier0Dir/variants';

/// One Tier 0 oracle document, `{form}.{body}.{locale}`.
///
/// Read through [Tier0Oracle] rather than as a bare map so a missing field
/// fails at the load with the document's own name attached — the alternative
/// is a `null` surfacing three assertions later, attributed to the wrong test.
class Tier0Oracle {
  Tier0Oracle(this.name, this.json);

  factory Tier0Oracle.load(String dir, String name) =>
      Tier0Oracle(name, _readJson('$dir/$name.json'));

  final String name;
  final Map<String, dynamic> json;

  String get form => _req<String>('form');
  String get body => _req<String>('body');
  String get locale => _req<String>('locale');
  String get attempt => _req<String>('attempt');
  String get clock => _req<String>('clock');

  /// The payload as a document TREE — nested exactly as the source emits it.
  ///
  /// For FamilyBook this is the WHOLE request body: that form has no
  /// `form_data` envelope key at all (Finding A, the third payload family),
  /// and the document says so in its own `wire_shape` field.
  Map<String, dynamic> get formData => _req<Map<String, dynamic>>('form_data');

  /// The ordered emission sequence as RFC 6901 JSON Pointers.
  ///
  /// `/header/document_no` (Marriage's nested key) and `/header.document_no`
  /// (Birth's literal flat key) are different strings, which is the whole
  /// reason this is a pointer list and not a dotted flattening.
  List<String> get paths =>
      _req<List<dynamic>>('paths').cast<String>();

  /// Per-leaf `file:line` into `$PROJ/sources/lcc-app` (`F0-AC-87(ii)`).
  Map<String, String> get src =>
      _req<Map<String, dynamic>>('src').cast<String, String>();

  /// Per-envelope-key `file:line`.
  Map<String, String> get envelopeSrc =>
      _req<Map<String, dynamic>>('envelopeSrc').cast<String, String>();

  /// The whole request body as ordered `(name, present, value)` tuples.
  ///
  /// An elided key carries `present: false` and NO value; a present-and-empty
  /// key carries `present: true, value: ""`. Resident elides `province_id`
  /// when blank (`|| undefined`); Marriage sends `""`. Different bodies.
  Map<String, dynamic> get envelope =>
      _req<Map<String, dynamic>>('${body}Envelope');

  Map<String, dynamic> get provenance =>
      _req<Map<String, dynamic>>('provenance');

  /// `/header/document_no` · `/header.document_no` · `/header.ref_no` — where
  /// the case reference lands on the update body, and by which mechanic.
  Map<String, dynamic> get refBinding =>
      _req<Map<String, dynamic>>('refBinding');

  T _req<T>(String key) {
    final Object? value = json[key];
    if (value is! T) {
      throw StateError(
        '$name.json: `$key` is ${value.runtimeType}, expected $T. The oracle '
        'is produced by derive_forms_oracles.py (Entry B) — a shape change '
        'there is a spec change, not something to defend against here.',
      );
    }
    return value;
  }
}

/// The `{form}.{body}` pairs of the matrix, in the order `F0-AC-34` counts.
///
/// Hard-coded rather than globbed **on purpose**: a glob makes the count a
/// consequence of what happens to be on disk, and `F0-AC-34`'s whole point is
/// that the count is asserted against a specification. A missing file must
/// FAIL, not shrink the denominator.
const List<String> kTier0Bodies = <String>[
  'resident.create', 'resident.update',
  'birth.create', 'birth.update',
  'death.create', 'death.update',
  'marriage.create', 'marriage.update',
  'divorce.create', 'divorce.update',
  'family-book.request',
];

/// All 22 document names, `{form}.{body}.{locale}`.
List<String> tier0OracleNames() => <String>[
      for (final String body in kTier0Bodies)
        for (final String locale in <String>['en', 'lo']) '$body.$locale',
    ];

/// One Tier 0 document from the canonical matrix.
Tier0Oracle loadTier0(String form, String body, String locale) =>
    Tier0Oracle.load(kTier0Dir, '$form.$body.$locale');

/// One document derived from a NON-canonical fixture variant.
Tier0Oracle loadTier0Variant(
        String form, String variant, String body, String locale) =>
    Tier0Oracle.load(kTier0VariantsDir, '$form.$variant.$body.$locale');

/// The Entry B VARIANT documents on disk, by `{form}.{variant}.{body}.{locale}`.
///
/// Globbed, unlike [tier0OracleNames], and for the opposite reason to the one
/// that makes globbing wrong there. The canonical matrix's count is a
/// specification `F0-AC-34` asserts against a literal 22; the variant set has
/// no such declared cardinality — it is however many non-canonical fixture
/// classes § 6.5.3 produced. Hard-coding it would assert a number no criterion
/// owns.
///
/// It exists because [tier0OracleNames] alone is the WRONG denominator for
/// Entry A coverage: Entry A captures variants (`birth.father-unknown.*`,
/// `death.mother-skip.*`), so subtracting a 4-part variant name from a list of
/// 3-part canonical names compares two different name spaces and reports
/// nonsense — measured as `Entry A covers 24 of 22 documents` before this
/// existed.
List<String> tier0VariantNames() {
  final Directory d = Directory(kTier0VariantsDir);
  if (!d.existsSync()) return <String>[];
  return d
      .listSync()
      .whereType<File>()
      .where((File f) => f.path.endsWith('.json'))
      .map((File f) => f.uri.pathSegments.last.replaceAll('.json', ''))
      .toList()
    ..sort();
}

/// Every Entry B document — canonical matrix PLUS variants.
///
/// This is the denominator Entry A's coverage is a fraction OF.
List<String> tier0AllOracleNames() =>
    <String>[...tier0OracleNames(), ...tier0VariantNames()]..sort();

/// The Entry B counterpart of an Entry A document, resolved by NAME SHAPE.
///
/// `{form}.{body}.{locale}` (3 parts) lives in the canonical matrix;
/// `{form}.{variant}.{body}.{locale}` (4 parts) lives one level down in
/// `variants/`. Resolving a 4-part name as if it were 3-part asks for
/// `tier0/birth.father-unknown.create.json`, which does not and should not
/// exist — that threw `StateError` and aborted `F0-AC-104` before it compared
/// a single leaf, so the 16 variant captures were never checked against B at
/// all.
Tier0Oracle loadTier0CounterpartOf(String executedName) {
  final List<String> parts = executedName.split('.');
  if (parts.length == 3) return loadTier0(parts[0], parts[1], parts[2]);
  if (parts.length == 4) {
    return loadTier0Variant(parts[0], parts[1], parts[2], parts[3]);
  }
  throw StateError(
    'Entry A document `$executedName` has ${parts.length} dot-separated '
    'parts. Tier 0 names are `{form}.{body}.{locale}` or '
    '`{form}.{variant}.{body}.{locale}`, so there is no Entry B counterpart '
    'this could resolve to. An unresolvable capture is a BLOCKED condition '
    '(§ 8.3), not a document to skip.',
  );
}

/// `oracle/tier0/executed/` — **Entry A**, read off the wire.
///
/// Distinguishable from Entry B by `provenance.entry == 'A'` and by carrying
/// `raw_bytes`: the exact `route.request().postData()` string the pinned
/// application put on the socket. Every other field in an Entry A document is
/// derived from that string; nothing in it is transcribed.
const String kTier0ExecutedDir = '$kTier0Dir/executed';

/// The Entry A documents currently on disk, by `{form}.{body}.{locale}`.
///
/// Globbed, unlike [tier0OracleNames], and the difference is deliberate.
/// Entry B's count is a specification — 22, asserted. Entry A's is a
/// **measurement**: it is however many the rig actually captured, and pinning
/// it to a literal would turn a coverage shortfall into a passing test.
List<String> tier0ExecutedNames() {
  final Directory d = Directory(kTier0ExecutedDir);
  if (!d.existsSync()) return <String>[];
  return d
      .listSync()
      .whereType<File>()
      .where((File f) => f.path.endsWith('.json'))
      .map((File f) => f.uri.pathSegments.last.replaceAll('.json', ''))
      .toList()
    ..sort();
}

/// One Entry A document.
Tier0Oracle loadTier0Executed(String name) =>
    Tier0Oracle.load(kTier0ExecutedDir, name);

/// Whether the derived matrix is present at all.
///
/// The distinction this exists to keep: **NOT EVALUATED is not PASS.** With no
/// oracles on disk every universally-quantified assertion below is vacuously
/// true, so the harness must be able to say "zero documents" rather than
/// report a green gate over an empty set.
bool tier0MatrixPresent() =>
    Directory(kTier0Dir).existsSync() &&
    tier0OracleNames()
        .every((String n) => File('$kTier0Dir/$n.json').existsSync());

/// One expected node from a Tier 1 view.
class OracleNode {
  const OracleNode({
    required this.role,
    required this.text,
    required this.source,
    this.level,
  });

  factory OracleNode.fromJson(Map<String, dynamic> json) => OracleNode(
        role: json['role'] as String,
        text: json['text'] as String,
        source: json['source'] as String,
        level: json['level'] as int?,
      );

  /// `heading` · `paragraph` · `placeholder` · `label` · `button` ·
  /// `cardTitle` · `cardBody` · `cardMeta` · `chip` · `panelMessage` ·
  /// `panelHint`.
  final String role;

  final String text;

  /// `file:line -> origin`, so a failure names where the expectation came from
  /// rather than making a reviewer hunt for it.
  final String source;

  /// Heading level, for `role == 'heading'` only.
  final int? level;
}

/// The ordered nodes of one view (`categories.data`, `list.error`, …).
List<OracleNode> tier1View(Map<String, dynamic> oracle, String view) {
  final Map<String, dynamic> views =
      oracle['views'] as Map<String, dynamic>;
  final List<dynamic>? nodes = views[view] as List<dynamic>?;
  if (nodes == null) {
    throw StateError(
      'The oracle has no view `$view`. Known views: ${views.keys.join(', ')}.',
    );
  }
  return nodes
      .cast<Map<String, dynamic>>()
      .map(OracleNode.fromJson)
      .toList(growable: false);
}
