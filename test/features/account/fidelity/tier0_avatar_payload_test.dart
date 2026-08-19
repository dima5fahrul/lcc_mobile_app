/// **Tier 0 — payload equality for B8b's multipart body. B8-AC-56, and the
/// byte-identity assertion `security-review-b8b.md` FU-18 says the batch is
/// missing.**
///
/// ## Why this file exists at all, and why it is not one `expect`
///
/// `B8-AC-56` as written asserts two things: the part is named `file`, and the
/// caller does not set `Content-Type`. The review's FU-18 is blunt about what
/// that leaves open:
///
/// > **`B8-AC-56` cannot see a re-encoded file part.** It asserts the field
/// > name and the absent `Content-Type` and nothing about the bytes. Since the
/// > ruling is now definitively **send raw** (§ 4.4), Tier 0 needs an entry
/// > asserting the transmitted part is **byte-identical to the picked file** —
/// > otherwise an implementer reaching for `imageQuality:`/`maxWidth:` to keep
/// > uploads small strips EXIF, commits an L-10(b) divergence, and **no gate in
/// > the batch fires**.
///
/// So the load-bearing case here is [_kExifJpeg] surviving to the wire
/// unaltered. The fixture is a byte sequence carrying a JPEG SOI, an **APP1
/// `Exif` header** and a **GPS** tag string, because that is the material the
/// ruling is about: a citizen's home coordinates. A test built on
/// `[1,2,3,4]` would pass identically against an implementation that stripped
/// metadata and kept pixels — the exact failure the Capability Rule names.
///
/// ## The claim is about the SERIALISED BODY, not the `FormData` object
///
/// Every assertion below reads bytes out of `FormData.finalize()` — the stream
/// Dio hands the socket. Asserting on `form.files.first.value` would be
/// asserting that the datasource built what the datasource built; asserting on
/// the finalized body is asserting what the server receives. `B8a`'s
/// `tier0_account_payload_test.dart` makes the same distinction for its three
/// JSON bodies by asserting the **encoded string**.
///
/// ## Where this lives
///
/// `test/features/account/fidelity/`, a **new file** beside B8a's rather than
/// an edit to it: specs.md § 3.1's B8b row says `test/features/account/**`
/// *create*, B8a's Tier 0 entries must stay unmodified (B8-AC-24), and F0a's
/// `test/fidelity/tier0_payload_equality_test.dart` is out of scope entirely
/// (§ 4.1).
///
/// ## Every fixture here is synthetic — B8-AC-35
///
/// No real citizen, no real UIN, no token, no real password, and **no real
/// photograph of anybody**. [_kExifJpeg] is 40 hand-written bytes that no
/// camera produced.
library;

import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lcc_mobile_app/core/constant/api_endpoint.dart';
import 'package:lcc_mobile_app/core/network/api_client.dart';
import 'package:lcc_mobile_app/core/storage/storage_keys.dart';
import 'package:lcc_mobile_app/core/storage/storage_service.dart';
import 'package:lcc_mobile_app/features/account/data/datasources/account_remote_datasource.dart';
import 'package:lcc_mobile_app/features/account/domain/entities/picked_avatar.dart';

import '../../../helpers/core_test_helper.dart';
import '../account_test_helper.dart';

// ─────────────────────────────────────────────────────────────────────────────
// The fixture that makes the assertion discriminating
// ─────────────────────────────────────────────────────────────────────────────

/// A synthetic JPEG-shaped byte string carrying an **EXIF APP1 segment with a
/// GPS marker**.
///
/// Structure, so a reader can see why each byte is here rather than trusting a
/// blob: `FF D8` (SOI) · `FF E1` (APP1) · a length · `Exif\0\0` ·
/// `MM\0*` (big-endian TIFF header) · the ASCII `GPSLatitude` · a plausible
/// coordinate · `FF D9` (EOI).
///
/// **It is not a decodable image, and that is deliberate.** Nothing in the
/// upload path decodes it — that is what "send raw" means — so a valid JPEG
/// would prove nothing extra, while an invalid one additionally guarantees that
/// any implementation which tried to re-encode would *fail* rather than quietly
/// succeed with different bytes.
final Uint8List _kExifJpeg = Uint8List.fromList(<int>[
  0xFF, 0xD8, // SOI
  0xFF, 0xE1, 0x00, 0x22, // APP1, length 34
  ...ascii.encode('Exif'), 0x00, 0x00,
  ...ascii.encode('MM'), 0x00, 0x2A, // big-endian TIFF header
  ...ascii.encode('GPSLatitude'),
  ...ascii.encode('17;58;N'),
  0xFF, 0xD9, // EOI
]);

/// A filename with a space and non-ASCII characters, because phone filenames
/// have them and they go on the wire unsanitised — `B8b-6` / F1's `S-3`.
const String _kFilename = 'ຮູບ ຖ່າຍ 2026-08-19.jpg';

// ─────────────────────────────────────────────────────────────────────────────
// Harness
// ─────────────────────────────────────────────────────────────────────────────

/// An adapter that records **the bytes Dio actually wrote to the socket**, not
/// the `FormData` object that produced them.
///
/// This distinction is the whole reason this class exists rather than reusing
/// `RecordingHttpAdapter`. Two things defeat reading the object:
///
/// 1. By the time an adapter is called, Dio has **already finalised** the
///    `FormData` to build `requestStream`; calling `finalize()` a second time
///    throws `StateError` — the very defect `B8b-3` was about.
/// 2. On a 401 replay, `RefreshInterceptor` mutates and re-sends **the same
///    `RequestOptions` instance**, so `requests.first.data` and
///    `requests.last.data` are the same reference and comparing them proves
///    nothing. The two socket bodies are genuinely distinct.
///
/// So [bodies] holds one byte array per request, captured off `requestStream`.
/// That is the server's-eye view, and it is what a byte-identity claim has to
/// be made against.
class _BodyCapturingAdapter implements HttpClientAdapter {
  _BodyCapturingAdapter(this.responder);

  final ScriptedResponder responder;

  final List<RequestOptions> requests = <RequestOptions>[];
  final List<Uint8List> bodies = <Uint8List>[];

  int get callCount => requests.length;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final int index = requests.length;
    requests.add(options);

    final BytesBuilder out = BytesBuilder(copy: false);
    if (requestStream != null) {
      await for (final Uint8List chunk in requestStream) {
        out.add(chunk);
      }
    }
    bodies.add(out.takeBytes());

    return responder(options, index);
  }

  @override
  void close({bool force = false}) {}
}

/// `indexOf` for byte sequences — `needle` inside `haystack`, or -1.
int _indexOfBytes(List<int> haystack, List<int> needle) {
  if (needle.isEmpty || needle.length > haystack.length) return -1;
  outer:
  for (int i = 0; i <= haystack.length - needle.length; i++) {
    for (int j = 0; j < needle.length; j++) {
      if (haystack[i + j] != needle[j]) continue outer;
    }
    return i;
  }
  return -1;
}

void main() {
  late Map<String, String> store;
  late StorageService storage;

  setUp(() {
    store = <String, String>{
      StorageKeys.accessToken: 'access-old',
      StorageKeys.refreshToken: 'refresh-old',
    };
    storage = inMemoryStorageService(store);
  });

  ({AccountRemoteDatasource remote, _BodyCapturingAdapter adapter}) wire(
    ScriptedResponder responder,
  ) {
    final _BodyCapturingAdapter adapter = _BodyCapturingAdapter(responder);
    final Dio dio = buildTestDio(storage: storage, adapter: adapter);
    return (
      remote: AccountRemoteDatasourceImpl(
        apiClient: ApiClient(dio: dio, storage: storage),
      ),
      adapter: adapter,
    );
  }

  ({AccountRemoteDatasource remote, _BodyCapturingAdapter adapter}) ok() => wire(
        (RequestOptions _, int __) => jsonResponse(
          okEnvelope(<String, dynamic>{
            'avatar_url': 'https://cdn.example.test/a/synthetic.jpg',
          }),
        ),
      );

  // ── The criterion FU-18 says is missing ───────────────────────────────────

  group('B8-AC-56 + FU-18 — the picked file reaches the wire unmodified', () {
    test('THE CRITERION — the EXIF/GPS bytes are on the wire byte-identical, '
        'in the same order, with nothing inserted between them', () async {
      final ({AccountRemoteDatasource remote, _BodyCapturingAdapter adapter}) w =
          ok();

      await w.remote.uploadAvatar(
        PickedAvatar(name: _kFilename, bytes: _kExifJpeg),
      );

      // If the datasource silently did nothing, this is 0 and the test fails
      // here rather than vacuously passing on an empty body.
      expect(w.adapter.callCount, 1,
          reason: 'exactly one POST reached the transport');
      expect(w.adapter.requests.single.path, ApiEndpoint.meAvatar);

      final Uint8List body = w.adapter.bodies.single;

      // The whole fixture, contiguous. A strip, a resize or a re-encode changes
      // these bytes; a re-encode that preserved the pixels would still lose the
      // APP1 segment, and this fails on that too.
      expect(
        _indexOfBytes(body, _kExifJpeg),
        isNonNegative,
        reason: 'the picked bytes must appear on the wire verbatim — if this '
            'fails, something between the picker and MultipartFile changed the '
            'file, which is the L-10(b) divergence FU-18 exists to catch',
      );

      // Named individually so a failure says *what* was lost rather than only
      // that the blob moved.
      expect(_indexOfBytes(body, ascii.encode('Exif')), isNonNegative,
          reason: 'the APP1 EXIF header survived');
      expect(_indexOfBytes(body, ascii.encode('GPSLatitude')), isNonNegative,
          reason: "the citizen's capture GPS survived — this is the behaviour "
              'the port is REQUIRED to have (send raw, security-review-b8b.md '
              '§ 4.4); the exposure it creates is FU-15, a product question, '
              'and must not be closed by stripping here');
    });

    test('THE CAPABILITY CONTROL — the assertion above can fail. A one-byte '
        'mutation of the fixture is NOT found on the wire', () async {
      // Without this, the case above would pass against a `_indexOfBytes` that
      // always answered 0, or a body that happened to contain everything.
      final ({AccountRemoteDatasource remote, _BodyCapturingAdapter adapter}) w =
          ok();

      await w.remote.uploadAvatar(
        PickedAvatar(name: _kFilename, bytes: _kExifJpeg),
      );
      final Uint8List body = w.adapter.bodies.single;

      final Uint8List mutated = Uint8List.fromList(_kExifJpeg);
      mutated[mutated.length - 1] = 0xD8; // EOI FF D9 -> FF D8

      expect(
        _indexOfBytes(body, mutated),
        -1,
        reason: 'if a mutated payload is also "found", the matcher is not '
            'discriminating and the criterion case is decoration',
      );
      // …and the un-mutated one still is, in the same body.
      expect(_indexOfBytes(body, _kExifJpeg), isNonNegative);
    });

    test('B8-AC-56 — the part is named exactly `file`, the filename is the '
        "citizen's verbatim, and there is no second part", () async {
      final ({AccountRemoteDatasource remote, _BodyCapturingAdapter adapter}) w =
          ok();

      await w.remote.uploadAvatar(
        PickedAvatar(name: _kFilename, bytes: _kExifJpeg),
      );

      // Read off the SERIALISED body, so the claim is about what the server
      // parses rather than about what the datasource assembled.
      final Uint8List body = w.adapter.bodies.single;
      final String text = utf8.decode(body, allowMalformed: true);

      // `form.append("file", file)` is the whole form (`endpoints.ts:108-109`).
      // Unlike `addAttachment`, there is no `slot`, no `kind`, no `label`.
      // The lookbehind matters: `filename="…"` contains `name="…"`, so an
      // unanchored pattern reports two parts where there is one.
      expect(
        RegExp(r'(?<![A-Za-z])name="([^"]+)"')
            .allMatches(text)
            .map((RegExpMatch m) => m.group(1)!)
            .toList(),
        <String>['file'],
        reason: 'exactly one part, named `file` — a `slot` or `kind` here '
            'would be a part the web does not send',
      );

      // The filename crosses unsanitised — B8b-6 / F1 S-3, ported as measured.
      expect(
        text,
        contains('filename="$_kFilename"'),
        reason: 'the citizen filename is transmitted verbatim; sanitising it '
            'would change a multipart body Tier 0 gates',
      );

      // **The PART's own `Content-Type`, which is not the one B8-AC-56 is
      // about.** B8-AC-56's second clause concerns the *request* header, which
      // the caller must leave unset so Dio owns the boundary. Dio additionally
      // stamps each part: `MultipartFile` defaults `contentType` to
      // `lookupMediaType(filename) ?? application/octet-stream`
      // (`dio-5.9.2/lib/src/multipart_file.dart:37-39`). That is inferred from
      // the extension and never from the bytes — nothing sniffs the file — and
      // it is the analogue of the browser sending `File.type`. Asserted rather
      // than left unrecorded, because a reader measuring the wire will see it
      // and should not have to work out whether B8b chose it. Nothing in this
      // port passes `contentType:` explicitly.
      expect(text, contains('content-type: image/jpeg'));
    });

    test("B8-AC-56 second clause — the caller sets NO `Content-Type`, so Dio "
        'owns the boundary', () async {
      final ({AccountRemoteDatasource remote, _BodyCapturingAdapter adapter}) w =
          ok();

      await w.remote.uploadAvatar(tPickedAvatar());

      // `api_client.dart:253-257` passes `contentType: null` for a form, and
      // Dio then writes `multipart/form-data; boundary=…` itself — the mirror
      // of `client.ts:236`. A caller-set `application/json` here would produce
      // a body the server cannot parse, and no other tier would see it.
      final String? sent = w.adapter.requests.single.headers[Headers.contentTypeHeader]
          ?.toString();
      expect(sent, isNotNull);
      expect(sent, contains('multipart/form-data'));
      expect(sent, contains('boundary='));
      expect(sent, isNot(contains('application/json')));
    });

    test('the upload is authenticated — it cannot become anonymous by '
        'omission', () async {
      final ({AccountRemoteDatasource remote, _BodyCapturingAdapter adapter}) w =
          ok();

      await w.remote.uploadAvatar(tPickedAvatar());

      expect(w.adapter.requests.single.headers['Authorization'],
          'Bearer access-old');
    });

    test('a null-bytes pick sends an EMPTY part rather than throwing or '
        'skipping the request', () async {
      // `PickedAvatar.bytes` is nullable for the same reason
      // `PickedAttachment.bytes` is. The source has no analogue — a browser
      // `File` always has content — so the disposition is the one
      // `application_remote_datasource.dart:294` already took: `Uint8List(0)`,
      // and the request still goes. Recorded rather than left to discovery.
      final ({AccountRemoteDatasource remote, _BodyCapturingAdapter adapter}) w =
          ok();

      await w.remote
          .uploadAvatar(const PickedAvatar(name: 'empty.jpg', bytes: null));

      expect(w.adapter.callCount, 1);
      final String text =
          utf8.decode(w.adapter.bodies.single, allowMalformed: true);
      expect(text, contains('name="file"'));
      expect(text, contains('filename="empty.jpg"'));
    });
  });

  // ── S-5 — the 401 replay, proved for THIS endpoint ────────────────────────

  group('security-review-b8b.md § 12(a) S-5 — a 401 during the avatar upload '
      'is recovered, proved on /me/avatar and not inherited', () {
    // The review's S-5 is explicit that citing `B8b-3`'s fix is not enough:
    // *"require B8b's own upload to be covered by the multipart-401 case shape
    // at `refresh_interceptor_test.dart:780-845`, rather than assuming the
    // existing case generalises to a second endpoint."* The existing case runs
    // against `/applications/{id}/attachments`; this one runs against
    // `/me/avatar` through the real datasource.
    //
    // Note this file, not `test/core/network/refresh_interceptor_test.dart`:
    // that path is outside specs.md § 3.1's B8b rows, and S-5's subject is
    // B8b's endpoint rather than the interceptor.

    test('THE CAPABILITY — the upload succeeds after the refresh, and the '
        'replayed body still carries the same EXIF bytes', () async {
      final ({AccountRemoteDatasource remote, _BodyCapturingAdapter adapter}) w =
          wire((RequestOptions options, int _) {
        if (options.path == ApiEndpoint.authRefresh) {
          return jsonResponse(okEnvelope(<String, dynamic>{
            'tokens': <String, dynamic>{
              'access_token': 'access-new',
              'refresh_token': 'refresh-new',
            },
          }));
        }
        if (options.headers['Authorization'] == 'Bearer access-old') {
          return jsonResponse(
            failEnvelope(message: 'expired'),
            statusCode: 401,
          );
        }
        return jsonResponse(okEnvelope(<String, dynamic>{
          'avatar_url': 'https://cdn.example.test/a/synthetic.jpg',
        }));
      });

      final String url = await w.remote.uploadAvatar(
        PickedAvatar(name: _kFilename, bytes: _kExifJpeg),
      );

      // Before `71c2315` this threw `StateError: The FormData has already been
      // finalized`, wrapped as a `DioException` and swallowed by the
      // interceptor — the refresh succeeded and the upload died.
      expect(url, 'https://cdn.example.test/a/synthetic.jpg');
      expect(
        w.adapter.requests.map((RequestOptions r) => r.path).toList(),
        <String>[ApiEndpoint.meAvatar, ApiEndpoint.authRefresh,
            ApiEndpoint.meAvatar],
        reason: 'one attempt, one refresh, one replay',
      );
      expect(w.adapter.requests.last.headers['Authorization'],
          'Bearer access-new');

      // **Both socket bodies carry the photograph.** Asserting only that the
      // request succeeded would not catch a replay that sent an empty body,
      // which is exactly what a naive "re-send the finalized stream" fix would
      // produce. Note this compares the captured *bytes*: the interceptor
      // mutates and re-sends one `RequestOptions` instance, so `requests.first`
      // and `requests.last` are the same object and an identity check on
      // `.data` would prove nothing.
      final Uint8List firstBody = w.adapter.bodies.first;
      final Uint8List replayedBody = w.adapter.bodies.last;

      expect(replayedBody, isNotEmpty,
          reason: 'a replay that re-read a consumed stream sends nothing');
      expect(_indexOfBytes(replayedBody, _kExifJpeg), isNonNegative,
          reason: 'the replayed upload carries the same bytes, not a truncated '
              'or re-read stream');
      expect(_indexOfBytes(replayedBody, ascii.encode('GPSLatitude')),
          isNonNegative);

      // Same parts, and the boundary differs because the clone is a distinct
      // `FormData` — which is the observable signature of the `71c2315` fix.
      expect(
        utf8.decode(replayedBody, allowMalformed: true),
        contains('filename="$_kFilename"'),
      );
      expect(firstBody.length, replayedBody.length,
          reason: 'the two bodies differ only in their boundary token, which '
              'is the same length');
    });

    test('THE CONTROL — a finalized FormData really does throw when re-sent, '
        'so the case above is not vacuous', () async {
      // Reproduced against the package directly. Without it, the capability
      // case would pass on any Dio whose `FormData` stopped being stateful, and
      // would then be evidence for nothing. Same control as
      // `refresh_interceptor_test.dart`'s, restated here because this file's
      // claim is about `/me/avatar` and must stand on its own.
      final FormData original = FormData.fromMap(<String, dynamic>{
        'file': MultipartFile.fromBytes(_kExifJpeg, filename: _kFilename),
      });
      await original.finalize().drain<void>();

      expect(
        () => original.finalize(),
        throwsA(isA<StateError>().having((StateError e) => e.message,
            'message', contains('already been finalized'))),
      );
    });
  });
}
