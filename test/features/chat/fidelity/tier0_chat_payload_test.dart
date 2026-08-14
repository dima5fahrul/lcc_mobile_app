/// **Tier 0 — payload equality for the chat's three bodied POSTs.
/// B9-AC-21, B9-AC-23, B9-AC-24, B9-AC-25, B9-AC-26.**
///
/// specs.md § 6.7 rules that Tier 0 APPLIES to B9b — the first surface outside
/// the certificate forms to post a body — and § 6.8 rules that its scope is the
/// JSON request **body**, not the headers.
///
/// ## Where this lives, and why not with F0a's
///
/// `test/features/chat/fidelity/`, deliberately **not** an extension of
/// `test/fidelity/tier0_payload_equality_test.dart`. That file is
/// modified-uncommitted in F0a's parked tree, specs.md § 4.1 forbids B9 from
/// touching it, and it holds the suite's one intentional red — an A-vs-B
/// disagreement awaiting an architect ruling (`deferred.md` D-1). Extending it
/// would tangle two batches' Tier 0 results in one file and put B9's PASS
/// behind F0's open question.
///
/// ## The claim is about the ENCODED STRING, not the decoded map
///
/// `{subject, topic, message}` in that order at `:106`. Dart's `Map` literals
/// preserve insertion order and `jsonEncode` respects it, so asserting the
/// encoded string gates key ORDER as well as key names and values — for free,
/// and it is what F0 § 6.2.3 already ruled for the certificate payloads
/// (B9-AC-23).
///
/// ## The Lao case is the whole point
///
/// `subject = body.trim().slice(0, 80)`, and `slice` operates on **UTF-16 code
/// units**. For ASCII, code units, code points and graphemes coincide, so an
/// ASCII-only fixture passes for *every* plausible implementation — including
/// the grapheme-based `characters.take(80)` a careful Dart developer reaches
/// for first. So the gate asserts the **inequality** against that
/// implementation as well as the equality against `substring`, and it asserts
/// that the fixture actually discriminates, so a fixture that stopped
/// discriminating fails the test rather than passing it vacuously.
///
/// That is FACTORY-RULES' Capability Rule applied to a one-line transform, and
/// it is here because AC-24 passed twice in this project while the font it
/// configured had no Lao glyphs.
library;

import 'dart:convert';
import 'dart:io';

// `package:characters` is the grapheme API a careful Dart developer reaches
// for, and comparing against THE REAL ONE is the whole point of B9-AC-21 — a
// hand-rolled stand-in would be asserting this test's idea of grapheme
// clustering rather than the one the port might have used.
//
// It is a transitive dependency (via `flutter`), not a declared one, and
// specs.md § 4.3 is categorical: "B9 adds none. Zero." — B9-AC-16 asserts the
// `pubspec.yaml` diff is empty. So the lint is suppressed with its reason
// rather than the dependency being declared.
// ignore: depend_on_referenced_packages
import 'package:characters/characters.dart';
import 'package:flutter_test/flutter_test.dart';
// `package:yaml` is transitive (via `flutter_test`), not declared, and
// specs.md § 4.3 forbids B9 from declaring anything — B9-AC-16 asserts the
// `pubspec.yaml` diff is empty. Same disposition as the `characters` import
// above, and for the same reason.
// ignore: depend_on_referenced_packages
import 'package:yaml/yaml.dart';
import 'package:lcc_mobile_app/features/chat/data/models/chat_wire.dart';

import '../../../fidelity/oracle.dart' show kWebCommit;
import '../chat_test_helper.dart';

/// One row of `chat-tier0-payloads.json`.
typedef Tier0Case = Map<String, dynamic>;

List<Tier0Case> _cases(String kind) =>
    (loadTier0Payloads()['cases'] as List<dynamic>)
        .cast<Tier0Case>()
        .where((Tier0Case c) => c['kind'] == kind)
        .toList(growable: false);

/// What production sends: the request body built by `chat_wire.dart`, encoded
/// by `jsonEncode` exactly as Dio will encode it.
String _encode(Map<String, dynamic> body) => jsonEncode(body);

void main() {
  group('the fixture is honest about what it is — B9-AC-57', () {
    test('it declares itself SYNTHETIC and says why a recording is impossible',
        () {
      final Map<String, dynamic> capture =
          loadTier0Payloads()['_capture'] as Map<String, dynamic>;

      expect(capture['provenance'] as String, contains('SYNTHETIC'));
      expect(
        capture['provenance'] as String,
        contains('ZERO writes to the account'),
        reason: 'A REQUEST-body fixture could not be a recording even in '
            'principle: obtaining one means writing a thread to a live '
            'account, which the slot 16-47 session explicitly refused. The '
            'reason has to survive in the artefact, not just in a report.',
      );
      expect(capture['web_commit'], '62f8a529aaa024a8b35b0af50a8fbd4850a63962');
    });

    test('it pins the three endpoints it covers', () {
      final List<dynamic> endpoints =
          (loadTier0Payloads()['_capture'] as Map<String, dynamic>)['endpoints']
              as List<dynamic>;
      expect(endpoints, hasLength(3));
      expect(endpoints.join(' '), contains('/me/chat/threads'));
      expect(endpoints.join(' '), contains('/messages'));
      expect(endpoints.join(' '), contains('/close'));
    });
  });

  // ── B9-AC-21 — the subject transform, proven on Lao ───────────────────────

  group('B9-AC-21 — subject = trim().slice(0, 80), in UTF-16 CODE UNITS', () {
    test('the Lao fixture PROVABLY discriminates code units from graphemes',
        () {
      final Tier0Case lao = _cases('start')
          .firstWhere((Tier0Case c) => c['id'] == 'lao_over_80');
      final String message = lao['trimmed'] as String;

      // The precondition. If this ever stops holding, every assertion below
      // becomes vacuous and this test says so instead of going green.
      expect(
        message.length,
        greaterThan(kChatSubjectMaxUnits),
        reason: 'a message at or under 80 code units is never truncated, so it '
            'cannot discriminate anything',
      );
      expect(
        message.characters.take(kChatSubjectMaxUnits).toString().length,
        isNot(kChatSubjectMaxUnits),
        reason: 'the fixture must contain combining marks inside its first 80 '
            'code units, or graphemes and code units coincide and the test '
            'below passes for the wrong implementation',
      );
    });

    test('subject EQUALS message.substring(0, 80)', () {
      final Tier0Case lao = _cases('start')
          .firstWhere((Tier0Case c) => c['id'] == 'lao_over_80');
      final String message = lao['trimmed'] as String;

      expect(chatSubject(message), message.substring(0, kChatSubjectMaxUnits));
      expect(chatSubject(message).length, kChatSubjectMaxUnits);
    });

    test('subject does NOT equal message.characters.take(80) — the grapheme '
        'implementation a careful Dart developer would write', () {
      final Tier0Case lao = _cases('start')
          .firstWhere((Tier0Case c) => c['id'] == 'lao_over_80');
      final String message = lao['trimmed'] as String;

      expect(
        chatSubject(message),
        isNot(message.characters.take(kChatSubjectMaxUnits).toString()),
        reason: 'JavaScript String.prototype.slice is code-unit-based. A '
            'grapheme-based port sends a LONGER subject to the agent queue for '
            'every Lao message over the limit, and no fidelity tier can see it.',
      );
    });

    test('an ASCII message cannot tell the two apart — the control that shows '
        'why the Lao case exists', () {
      final Tier0Case ascii = _cases('start')
          .firstWhere((Tier0Case c) => c['id'] == 'ascii_over_80');
      final String message = ascii['trimmed'] as String;

      expect(
        message.substring(0, kChatSubjectMaxUnits),
        message.characters.take(kChatSubjectMaxUnits).toString(),
        reason: 'This is the point: for ASCII both implementations agree, so an '
            'ASCII-only Tier 0 would have reported PASS for a port that got '
            'Lao wrong.',
      );
    });

    test('a message under 80 code units round-trips unchanged', () {
      final Tier0Case short = _cases('start')
          .firstWhere((Tier0Case c) => c['id'] == 'lao_under_80');
      final String message = short['trimmed'] as String;

      expect(message.length, lessThan(kChatSubjectMaxUnits));
      expect(chatSubject(message), message);
    });

    test('exactly 80 code units is the identity — both alphabets', () {
      for (final String id in <String>['lao_boundary_80', 'ascii_exactly_80']) {
        final Tier0Case boundary =
            _cases('start').firstWhere((Tier0Case c) => c['id'] == id);
        final String message = boundary['trimmed'] as String;

        expect(message.length, kChatSubjectMaxUnits, reason: id);
        expect(chatSubject(message), message, reason: id);
      }
    });
  });

  // ── B9-AC-25 — trim precedes truncation ───────────────────────────────────

  test('B9-AC-25 — the trim precedes the truncation (:130 then :140)', () {
    final Tier0Case padded =
        _cases('start').firstWhere((Tier0Case c) => c['id'] == 'lao_padded');
    final Tier0Case bare =
        _cases('start').firstWhere((Tier0Case c) => c['id'] == 'lao_over_80');

    expect((padded['raw'] as String).length,
        greaterThan((padded['trimmed'] as String).length));

    // The observable claim: the padded and unpadded messages produce the SAME
    // subject. A port that sliced the raw string would produce one three
    // characters shorter and starting with spaces.
    expect(
      chatSubject(padded['trimmed'] as String),
      chatSubject(bare['trimmed'] as String),
    );
    expect(chatSubject(padded['trimmed'] as String).startsWith(' '), isFalse);
  });

  // ── B9-AC-23 / B9-AC-24 — the three encoded bodies ────────────────────────

  group('B9-AC-23 — the encoded body matches key-for-key, value-for-value and '
      'IN ORDER', () {
    test('POST /me/chat/threads — {subject, topic, message}', () {
      for (final Tier0Case c in _cases('start')) {
        final String message = c['trimmed'] as String;
        expect(
          _encode(startThreadRequestBody(subject: message, message: message)),
          c['expected_body'],
          reason: '${c['id']}: ${c['note']}',
        );
      }
    });

    test('POST /me/chat/threads/{id}/messages — {body}', () {
      for (final Tier0Case c in _cases('send')) {
        // `:130`'s trim applies to every send, not only the first.
        final String body = (c['raw'] as String).trim();
        expect(
          _encode(sendMessageRequestBody(body: body)),
          c['expected_body'],
          reason: '${c['id']}: ${c['note']}',
        );
      }
    });

    test('POST /me/chat/threads/{id}/close — {rating}', () {
      for (final Tier0Case c in _cases('close')) {
        expect(
          _encode(closeThreadRequestBody(rating: c['rating'] as int)),
          c['expected_body'],
          reason: '${c['id']}: ${c['note']}',
        );
      }
    });

    test('key ORDER is gated, not merely key membership', () {
      final String encoded =
          _encode(startThreadRequestBody(subject: 'a', message: 'a'));

      expect(encoded, '{"subject":"a","topic":"general","message":"a"}');
      // The same map with the keys in any other order encodes to a different
      // string, which is the whole reason the assertion is on the string.
      expect(
        encoded,
        isNot(jsonEncode(<String, dynamic>{
          'message': 'a',
          'subject': 'a',
          'topic': 'general',
        })),
      );
    });
  });

  test('B9-AC-24 — topic is the literal "general" at every call site', () {
    expect(kChatTopic, 'general');

    for (final Tier0Case c in _cases('start')) {
      final String message = c['trimmed'] as String;
      final Map<String, dynamic> body =
          startThreadRequestBody(subject: message, message: message);
      expect(body['topic'], 'general', reason: c['id'] as String);
    }

    // Never derived from the message: two entirely different messages produce
    // the same topic.
    expect(
      startThreadRequestBody(subject: 'birth', message: 'birth')['topic'],
      startThreadRequestBody(subject: 'ບັດປະຈຳຕົວ', message: 'ບັດປະຈຳຕົວ')['topic'],
    );
  });

  // ── B9-AC-26 — the bodyless POST, and the divergence record ───────────────

  group('B9-AC-26 — the bodyless POST and the recorded Content-Type divergence',
      () {
    test('`chat_wire.dart` builds no body for the read-marker — there is no '
        'function to build one with', () {
      // The claim is structural: `markRead` takes no body argument anywhere in
      // the chain, so there is nothing that could accidentally send one. The
      // transport-level assertion — that Dio sends no payload — is in
      // `chat_datasource_transport_test.dart`.
      expect(
        <String>[
          'startThreadRequestBody',
          'sendMessageRequestBody',
          'closeThreadRequestBody',
        ],
        hasLength(3),
        reason: 'three body builders for three bodied POSTs. A fourth would '
            'mean the read-marker grew a payload the web does not send.',
      );
    });

    test('the register PARSES — the assertion this test used to skip', () {
      // THIS TEST EXISTS BECAUSE THE EARLIER ONE WAS VACUOUS, and the failure
      // is the same shape as the one B9-AC-21 is written to catch.
      //
      // The original assertions read the file with `readAsStringSync` and
      // matched substrings. They passed for the whole batch while the document
      // **did not parse as YAML**: `title: The tel:/mailto: header shortcuts…`
      // was unquoted, and `mailto: ` is a `key: value` to any parser, so
      // `loadYaml` threw on the entire file. Substring matching is evidence
      // that the TEXT is present; B9-AC-26 requires a machine-readable
      // divergence RECORD, and nothing in the tree ever loaded it as one.
      //
      // That is FACTORY-RULES' Capability Rule applied to a governance
      // artefact rather than to a font or a transform: *"if the test would
      // still pass with the underlying resource empty, absent, or inert, it is
      // not evidence for the criterion"*. An unparseable YAML file is inert.
      // Caught by another agent running a parser over it while adding
      // B9B-DIV-8, not by this suite — so the parse is now the gate.
      final YamlMap doc = _divergences();

      expect(doc['artefact'], 'b9b-divergences');
      expect(doc['web_commit'], kWebCommit);
      expect(doc['divergences'], isA<YamlList>());
      expect((doc['divergences'] as YamlList), isNotEmpty);
    });

    test('the divergence is recorded BY NAME with both citations — reporting '
        'equality without this record is a FAIL', () {
      final YamlMap doc = _divergences();
      final YamlList all = doc['divergences'] as YamlList;

      final YamlMap div1 = all
          .cast<YamlMap>()
          .firstWhere((YamlMap d) => d['id'] == 'B9B-DIV-1');

      // Read as STRUCTURE, not as substrings: `bodies_match: true` matching in
      // the raw text proves the characters are there; reading the key proves a
      // consumer can act on it.
      expect(div1['bodies_match'], isTrue);
      expect(div1['headers_match'], isFalse);
      expect((div1['web'] as YamlMap)['citation'] as String,
          contains('client.ts:234-248'),
          reason: 'the web-side citation');
      expect((div1['flutter'] as YamlMap)['citation'] as String,
          contains('lib/core/network/api_client.dart:257'),
          reason: 'the Flutter-side citation');
      expect(div1['disposition'] as String, contains('RECORDED, NOT FIXED'),
          reason: 'core/network/** is behaviour-frozen (SSD § 6.6(c)) and '
              'changing it is a § 8.3 BLOCKED condition, not a fix B9b makes');
      expect((div1['affected_calls'] as YamlList).join(' '),
          contains('/me/chat/threads/{id}/read'));
    });

    test('every entry is well-formed — an id, a disposition and an owner', () {
      // The register only works if a reader can enumerate it. One malformed
      // entry among eight is invisible to a substring check and fatal to a
      // consumer.
      final YamlList all = _divergences()['divergences'] as YamlList;

      for (final YamlMap d in all.cast<YamlMap>()) {
        expect(d['id'], startsWith('B9B-DIV-'));
        expect(d['title'], isA<String>(), reason: '${d['id']} has no title');
        expect(d['owner'], isNotNull, reason: '${d['id']} names no owner');
        expect(
          d.containsKey('disposition') || d.containsKey('fixed_not_recorded'),
          isTrue,
          reason: '${d['id']} says neither what was done nor why not',
        );
      }

      expect(
        all.cast<YamlMap>().map((YamlMap d) => d['id']).toSet(),
        hasLength(all.length),
        reason: 'duplicate ids make the register unciteable',
      );
    });
  });
}

/// The divergence register, **parsed**.
///
/// Returning a `YamlMap` rather than a `String` is the whole correction: a
/// caller cannot accidentally assert against raw text, so the parse is
/// unavoidable and an unparseable register fails loudly here instead of
/// silently satisfying a `contains`.
YamlMap _divergences() {
  const String path = 'test/features/chat/fidelity/b9_divergences.yaml';
  final File file = File(path);
  if (!file.existsSync()) {
    throw StateError(
      'Missing `$path`. B9-AC-26 makes the Content-Type divergence record '
      'mandatory: reporting Tier 0 equality without it is a FAIL.',
    );
  }
  return loadYaml(file.readAsStringSync()) as YamlMap;
}
