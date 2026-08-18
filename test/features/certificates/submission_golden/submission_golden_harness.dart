/// The instrument B4's migration is gated on — a **recorded request log** per
/// certificate form (specs.md § 6.8, `B4-AC-25`…`B4-AC-28`).
///
/// ## Why a new instrument, when three already exist
///
/// The migration changes no behaviour, which is the hardest kind of change to
/// verify: every existing test can pass while a request quietly moves. The
/// three instruments already in the tree each cover part of the problem and
/// none covers this one:
///
/// | Instrument | Pins | Cannot see |
/// |---|---|---|
/// | `tier0_payload_equality_test.dart` | the **bodies**, byte for byte | *which* body reaches the wire, in what order, how many times |
/// | `application_write_slice_test.dart` | the **transport** — key order, parts, `"{}"` | anything above the datasource |
/// | `marriage_submit_path_test.dart`, `divorce_submit_path_test.dart` | the **sequence**, for two of five forms, against spies | Resident, Birth, Death — and they count calls rather than recording bytes |
///
/// This harness records the ordered list of `(method, path, body-bytes,
/// multipart-part-names)` that a **full submit plus one retry** produces, from
/// the cubit down to the transport, and replays it afterwards. It closes the
/// Resident/Birth/Death sequence gap as a side effect, which is the one durable
/// asset this batch leaves behind beyond the executor itself.
///
/// ## It records below the whole stack, not at a repository spy
///
/// [SubmissionWireHarness] builds the real chain — cubit → port →
/// `ApplicationRepositoryImpl` → `ApplicationRemoteDatasourceImpl` →
/// `ApiClient` → a real `Dio` — and swaps only the socket, for
/// [RecordingHttpAdapter]. A repository-level spy sees the argument list;
/// insertion order **is** wire order (`client.ts:242` is a bare
/// `JSON.stringify`), so only the serialised string distinguishes a faithful
/// map from a canonicalised one. That is the argument
/// `application_write_slice_test.dart:4-14` makes, applied one layer up.
///
/// ## No request here reaches a host, and the pay step is why that matters
///
/// `kTestBaseUrl` is `api.test.invalid` — RFC 2606, unresolvable — and the
/// adapter sits below the interceptor chain, so nothing is handed to a socket.
/// The guard is load-bearing twice: `POST /applications` opens a real case on a
/// real civil registry, and `pay_application.dart`'s § 4.4 forbids executing
/// `POST /applications/{id}/pay` **against any host**, including by first
/// creating a case so that there is something to pay for. The pay step runs
/// through B6b's real `PayApplication` over this same adapter, so the recorded
/// log is a wire log for every step rather than four real entries and one
/// synthesised one.
library;

import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lcc_mobile_app/core/network/api_client.dart';
import 'package:lcc_mobile_app/core/storage/storage_keys.dart';
import 'package:lcc_mobile_app/core/storage/storage_service.dart';
import 'package:lcc_mobile_app/features/application/data/datasources/application_remote_datasource.dart';
import 'package:lcc_mobile_app/features/application/data/repositories/application_repository_impl.dart';
import 'package:lcc_mobile_app/features/application/domain/repositories/application_repository.dart';
import 'package:lcc_mobile_app/features/certificates/domain/submission/certificate_form.dart';
import 'package:lcc_mobile_app/features/certificates/domain/submission/submission_plan.dart';
import 'package:lcc_mobile_app/features/wallet/data/datasources/wallet_remote_datasource.dart';
import 'package:lcc_mobile_app/features/wallet/data/repositories/wallet_repository_impl.dart';
import 'package:lcc_mobile_app/features/wallet/domain/usecases/pay_application.dart';

import '../../../helpers/core_test_helper.dart';

/// Set on the recording run only. Absent — the default — makes every golden
/// file a pure comparison, which is what an ordinary `flutter test` does.
const bool kRecord = bool.fromEnvironment('RECORD_GOLDEN');

const String kGoldenDir = 'test/features/certificates/submission_golden';

/// The register's instant — `submission_clock_test.dart:25-26`, and the value
/// `resident_form_cubit_test.dart` already fixes its clock to, so a date in a
/// golden reads against that suite's expectations.
final DateTime kGoldenInstant = DateTime.parse('2026-08-14T02:00:00+07:00')
    .toUtc()
    .add(const Duration(hours: 7));

/// One request, as the transport saw it.
///
/// `body` and `parts` are mutually exclusive: a JSON request carries the
/// serialised string, a multipart request its part descriptors. Both are
/// recorded rather than one normalised representation, because a body that
/// became a multipart — or the reverse — is exactly the silent move this
/// instrument exists to catch.
class WireEntry {
  const WireEntry({
    required this.method,
    required this.path,
    this.body,
    this.parts,
  });

  factory WireEntry.fromJson(Map<String, dynamic> json) => WireEntry(
        method: json['method'] as String,
        path: json['path'] as String,
        body: json['body'] as String?,
        parts: (json['parts'] as List<dynamic>?)
            ?.map((dynamic e) => e as String)
            .toList(growable: false),
      );

  final String method;

  /// The path as handed to `ApiClient`, before the base URL is prepended — so a
  /// golden does not change when `--dart-define` changes the host.
  final String path;

  /// The serialised JSON body. Null on a multipart request.
  final String? body;

  /// `field:<name>=<value>` for every form field then
  /// `file:<name>=<filename>` for every file part, each list in insertion
  /// order. Null on a JSON request.
  final List<String>? parts;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'method': method,
        'path': path,
        if (body != null) 'body': body,
        if (parts != null) 'parts': parts,
      };

  /// Lossless on purpose: a truncated rendering of a byte comparison is a
  /// comparison of the truncation.
  @override
  String toString() =>
      '$method $path ${body ?? (parts?.join(' | ') ?? '<no body>')}';

  @override
  bool operator ==(Object other) =>
      other is WireEntry &&
      other.method == method &&
      other.path == path &&
      other.body == body &&
      _samePartList(other.parts, parts);

  @override
  int get hashCode => Object.hash(method, path, body, parts?.join('|'));

  static bool _samePartList(List<String>? a, List<String>? b) {
    if (a == null || b == null) return a == b;
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}

/// A recorded log — the ordered entries of one full submit plus one retry.
class GoldenLog {
  const GoldenLog({required this.form, required this.entries});

  factory GoldenLog.fromJson(Map<String, dynamic> json) => GoldenLog(
        form: json['form'] as String,
        entries: (json['entries'] as List<dynamic>)
            .map((dynamic e) => WireEntry.fromJson(e as Map<String, dynamic>))
            .toList(growable: false),
      );

  factory GoldenLog.decode(String source) =>
      GoldenLog.fromJson(jsonDecode(source) as Map<String, dynamic>);

  /// The `CertificateForm.serviceCode` this log belongs to.
  final String form;

  final List<WireEntry> entries;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'form': form,
        'entries': entries.map((WireEntry e) => e.toJson()).toList(),
      };

  /// Pretty-printed so a reviewer reads the sequence in a diff rather than one
  /// 4 kB line.
  String encode() => '${const JsonEncoder.withIndent('  ').convert(toJson())}\n';
}

/// Turns Dio's view of a request into a [WireEntry].
WireEntry entryFrom(RequestOptions options) {
  final Object? data = options.data;
  if (data is FormData) {
    return WireEntry(
      method: options.method,
      path: options.path,
      parts: <String>[
        for (final MapEntry<String, String> f in data.fields)
          'field:${f.key}=${f.value}',
        for (final MapEntry<String, MultipartFile> f in data.files)
          'file:${f.key}=${f.value.filename}',
      ],
    );
  }
  return WireEntry(
    method: options.method,
    path: options.path,
    // `data is String` covers a body an interceptor already serialised; the
    // encode covers a map Dio has not reached its transformer for. Both
    // spellings occur on this stack depending on the verb.
    body: data is String ? data : jsonEncode(data),
  );
}

/// The stack under test, assembled over one shared [RecordingHttpAdapter].
///
/// The four application writes **and** B6b's pay call go through the same
/// adapter, so [entries] is one ordered log rather than two a reader has to
/// interleave by hand.
class SubmissionWireHarness {
  SubmissionWireHarness._(this.adapter, this.applications, this.payApplication);

  factory SubmissionWireHarness.build({required ScriptedResponder responder}) {
    final Map<String, String> store = <String, String>{
      StorageKeys.accessToken: 'seeded-access-token',
    };
    final StorageService storage = inMemoryStorageService(store);
    final RecordingHttpAdapter adapter = RecordingHttpAdapter(responder);
    final ApiClient client = ApiClient(
      dio: buildTestDio(storage: storage, adapter: adapter),
      storage: storage,
    );
    return SubmissionWireHarness._(
      adapter,
      ApplicationRepositoryImpl(
        remote: ApplicationRemoteDatasourceImpl(apiClient: client),
      ),
      PayApplication(
        repository: WalletRepositoryImpl(
          remote: WalletRemoteDatasourceImpl(apiClient: client),
        ),
      ),
    );
  }

  final RecordingHttpAdapter adapter;

  /// The real repository — not a fake. Everything below it serialises for real,
  /// which is the whole point of recording here.
  final ApplicationRepository applications;

  /// B6b's real use case, over the same transport.
  final PayApplication payApplication;

  List<WireEntry> get entries =>
      adapter.requests.map(entryFrom).toList(growable: false);
}

/// The minimum an `ApplicationDetail` parse needs back, matching
/// `application_write_slice_test.dart:40-47`.
Map<String, dynamic> goldenCaseJson({
  int feeLak = 20000,
  String paymentState = 'pending',
}) =>
    <String, dynamic>{
      'id': 'case-1',
      'reference_no': 'LCC-2026-000123',
      'service_code': 'resident',
      'subject_name': 'Somchai',
      'status': 'submitted',
      'fee_lak': feeLak,
      'payment_state': paymentState,
    };

/// Answers each path with the shape its parser needs.
///
/// Keyed on the **path** and not on the call index, so the script does not
/// silently drift when the sequence changes: a wrong-shaped answer then fails
/// as a parse error naming the step rather than as an off-by-one.
ResponseBody goldenResponder(RequestOptions options, int _) {
  final String path = options.path;
  if (path.endsWith('/pay')) {
    return jsonResponse(okEnvelope(<String, dynamic>{
      'receipt_no': 'RCPT-0001',
      'payment_state': 'paid',
      'settled': true,
    }));
  }
  if (path.endsWith('/attachments')) {
    return jsonResponse(okEnvelope(<String, dynamic>{'ok': true}));
  }
  return jsonResponse(okEnvelope(goldenCaseJson()));
}

/// The `B4-AC-25`…`B4-AC-28` suite, written **once** so all five forms are
/// judged by identical assertions rather than by five hand-copied variants that
/// could drift into five different strengths.
///
/// [drive] must perform one full submit and then one retry on the held draft,
/// and answer everything the transport saw. [expectedSequence] is written out
/// literally by each caller: deriving both sides of the comparison from
/// `plan.steps` would make it tautological (`B4-AC-17`).
void goldenSuite({
  required CertificateForm form,
  required Future<List<WireEntry>> Function() drive,
  required List<String> expectedSequence,
}) {
  final String path = '$kGoldenDir/${form.serviceCode}.golden.json';
  late List<WireEntry> replayed;

  setUpAll(() async {
    replayed = await drive();
    if (kRecord) {
      File(path).writeAsStringSync(
        GoldenLog(form: form.serviceCode, entries: replayed).encode(),
      );
    }
  });

  GoldenLog golden() => GoldenLog.decode(File(path).readAsStringSync());

  group('B4-AC-25 ${form.serviceCode} — the golden is a real log', () {
    test('it exists and names the form it belongs to', () {
      expect(File(path).existsSync(), isTrue, reason: '$path is missing');
      expect(golden().form, form.serviceCode);
    });

    test('non-empty, and at least as many entries as the plan declares steps',
        () {
      // A zero-entry golden would be reproduced perfectly by an executor that
      // did nothing — the vacuous pass this clause exists to prevent.
      final SubmissionPlan plan = SubmissionPlan.forForm(form);
      expect(golden().entries, isNotEmpty);
      expect(
        golden().entries.length,
        greaterThanOrEqualTo(plan.steps.length),
        reason: 'the plan declares ${plan.steps.length} steps and this log '
            'covers a submit plus a retry',
      );
    });

    test('the recorded sequence is the expected one, written out literally',
        () {
      expect(
        golden().entries.map((WireEntry e) => '${e.method} ${e.path}').toList(),
        expectedSequence,
      );
    });
  });

  group('B4-AC-26 ${form.serviceCode} — the cubit reproduces its golden', () {
    test('every entry, in order, byte for byte and part for part', () {
      final List<WireEntry> expected = golden().entries;
      expect(
        replayed.length,
        expected.length,
        reason: 'entry count moved:\n'
            '  recorded: ${expected.join('\n            ')}\n'
            '  replayed: ${replayed.join('\n            ')}',
      );
      for (int i = 0; i < expected.length; i++) {
        expect(
          replayed[i],
          expected[i],
          reason: 'entry $i diverged\n'
              '  recorded: ${expected[i]}\n'
              '  replayed: ${replayed[i]}',
        );
      }
    });
  });

  group('${form.serviceCode} — the comparison can fail', () {
    /// The AC-26 comparison as a predicate, so the controls exercise the
    /// comparator itself rather than a lookalike written for them.
    bool matches(List<WireEntry> a, List<WireEntry> b) {
      if (a.length != b.length) return false;
      for (int i = 0; i < a.length; i++) {
        if (a[i] != b[i]) return false;
      }
      return true;
    }

    test('the control for the controls — the unmutated pair matches', () {
      expect(matches(replayed, golden().entries), isTrue);
    });

    test('B4-AC-27 MUTANT M1 — one character changed in one body is caught',
        () {
      final List<WireEntry> mutated = List<WireEntry>.of(golden().entries);
      final int i = mutated.indexWhere(
        (WireEntry e) => e.body != null && e.body!.length > 4,
      );
      expect(i, isNonNegative, reason: 'no JSON body to mutate');
      final WireEntry original = mutated[i];
      // Flip one character inside the body, past the opening brace.
      final String b = original.body!;
      final int at = b.length ~/ 2;
      final String flipped =
          '${b.substring(0, at)}${b[at] == 'x' ? 'y' : 'x'}${b.substring(at + 1)}';
      expect(
        flipped,
        isNot(b),
        reason: 'the mutation must actually change the body, or the control '
            'proves nothing',
      );
      mutated[i] = WireEntry(
        method: original.method,
        path: original.path,
        body: flipped,
      );

      expect(matches(replayed, mutated), isFalse);
    });

    test('B4-AC-28 MUTANT M2 — two entries transposed is caught', () {
      final List<WireEntry> mutated = List<WireEntry>.of(golden().entries);
      // The first two entries of every form's log are two DIFFERENT requests,
      // so transposing them is observable for all five. That is asserted
      // rather than assumed, because transposing two identical entries would
      // be a control that cannot fail.
      expect(mutated.length, greaterThan(1));
      expect(mutated[0], isNot(mutated[1]));
      final WireEntry first = mutated[0];
      mutated[0] = mutated[1];
      mutated[1] = first;

      expect(matches(replayed, mutated), isFalse);
    });
  });
}
