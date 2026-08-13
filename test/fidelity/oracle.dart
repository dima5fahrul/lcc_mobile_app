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
