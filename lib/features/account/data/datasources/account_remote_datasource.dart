/// `AccountRemoteDatasource` — the account surface's HTTP boundary, four
/// calls.
///
/// ## Two envelope shapes, and they are not interchangeable
///
/// - `GET`/`PUT /me/preferences` answer an **object**
///   (`endpoints.ts:122-123`), read through `get`/`put<dynamic>`.
/// - `GET /me/documents` answers a **plain array** (`endpoints.ts:115`) — it is
///   `api.get<CitizenDocument[]>` (i.e. `api.get` of a *list* type), **not**
///   `api.paged`, so it does not go through `ApiClient.requestPaged` and there
///   is no `meta` block to discard.
///
/// ## Why the reads ask for `dynamic` and cast here
///
/// `help_remote_datasource.dart`'s header has the full account, and it is not
/// style: `ApiClient._send<T>` forwards `T` to Dio, Dio casts the decoded body
/// to `T`, and the decoded body is always the **envelope map**.
/// `T = List<dynamic>` therefore throws before `_unwrap` runs and surfaces as
/// `NETWORK_ERROR` — a request that reached the server, reported as offline.
/// One rule, no exception to remember.
///
/// ## `PUT` is not `PATCH`
///
/// `apiClient.put`, and the body is [preferencesBody]'s whole object. The
/// `patch` verb exists on the client and using it here would be a one-character
/// divergence that no tier except Tier 0 can see (specs.md § 6.9 leaf 2).
///
/// ## The fourth call is `POST /me/avatar` — B8b
///
/// See [AccountRemoteDatasourceImpl.uploadAvatar]. It is the only multipart
/// body this feature sends, and the only one whose payload is a photograph of
/// the citizen.
library;

import 'dart:typed_data';

import 'package:dio/dio.dart';

import '../../../../core/constant/api_endpoint.dart';
import '../../../../core/network/api_client.dart';
import '../../domain/entities/citizen_document.dart';
import '../../domain/entities/citizen_preferences.dart';
import '../../domain/entities/picked_avatar.dart';
import '../models/account_wire.dart';

abstract class AccountRemoteDatasource {
  Future<CitizenPreferences> getPreferences();

  Future<CitizenPreferences> savePreferences(CitizenPreferences preferences);

  Future<List<CitizenDocument>> getDocuments();

  /// `POST /me/avatar` — `endpoints.ts:107-111`. Answers the new `avatar_url`.
  Future<String> uploadAvatar(PickedAvatar file);
}

class AccountRemoteDatasourceImpl implements AccountRemoteDatasource {
  const AccountRemoteDatasourceImpl({required this.apiClient});

  final ApiClient apiClient;

  @override
  Future<CitizenPreferences> getPreferences() async {
    final dynamic data = await apiClient.get<dynamic>(
      ApiEndpoint.mePreferences,
    );
    return citizenPreferencesFrom(
      data is Map<String, dynamic> ? data : const <String, dynamic>{},
    );
  }

  @override
  Future<CitizenPreferences> savePreferences(
      CitizenPreferences preferences) async {
    final dynamic data = await apiClient.put<dynamic>(
      ApiEndpoint.mePreferences,
      body: preferencesBody(preferences),
    );
    // The endpoint echoes the saved object back (`api.put<CitizenPreferences>`).
    // A response that is not an object yields the *sent* value rather than an
    // empty one: the write succeeded — a 4xx/5xx would have thrown — so
    // discarding what we know is true in favour of all-false booleans would
    // flip three switches back in the UI for no reason.
    if (data is! Map<String, dynamic>) return preferences;
    return citizenPreferencesFrom(data);
  }

  @override
  Future<List<CitizenDocument>> getDocuments() async {
    final dynamic data = await apiClient.get<dynamic>(ApiEndpoint.meDocuments);
    if (data is! List<dynamic>) return const <CitizenDocument>[];

    // `whereType` rather than a cast: one malformed row must cost that row, not
    // the card. A `data` that is not a list at all yields an empty list and so
    // the **empty** state, not a crash — the disposition `_rows` takes in
    // `help_remote_datasource.dart` and `notification_remote_datasource.dart`.
    return data
        .whereType<Map<String, dynamic>>()
        .map(citizenDocumentFrom)
        .toList(growable: false);
  }

  /// `POST /me/avatar`, multipart, one part named exactly `file` — B8-AC-56.
  ///
  /// ```ts
  /// const form = new FormData();
  /// form.append("file", file);
  /// return api.upload<{ avatar_url: string }>("/me/avatar", form);
  /// ```
  ///
  /// ## THE FILE GOES ON THE WIRE RAW. Do not "improve" this method.
  ///
  /// No EXIF strip. No resize. No re-encode. No MIME check. No size check. The
  /// bytes `file_picker` returned are the bytes the server receives, and the
  /// filename the citizen's phone gave is the filename in the part header.
  ///
  /// **This is not an oversight and it is not a gap awaiting a decision — it is
  /// the ruling.** `security-review-b8b.md` v1.0 held that the oracle *"never
  /// considered"* image metadata, so the port had *"no authority in either
  /// direction"*; Amendment 1 (2026-08-19) reversed that on evidence. The
  /// oracle **does** have canvas image-processing capability and uses it —
  /// `lib/document.ts:69-72` creates a canvas and `:365` calls
  /// `toDataURL("image/jpeg", 0.9)` — in the **download** direction only. Every
  /// upload path passes the `File` through untouched (`endpoints.ts:107-111`,
  /// `:344-351`, and all six certificate `handleFile`s). A codebase that can
  /// re-encode and declines to, on the path where it would matter, has given a
  /// determinate instruction.
  ///
  /// Stripping would therefore be `ssd.md:1185`'s **L-10 corollary (b)** — the
  /// port must not degrade *better* than the source either. It is also a Tier 0
  /// divergence, because the bytes of the `file` part **are** the payload, and
  /// it is one no gate in this batch would catch: `B8-AC-56` asserts the part
  /// name and the absent `Content-Type` and nothing about the bytes (FU-18).
  /// `tier0_avatar_payload_test.dart` adds the byte-identity assertion so the
  /// divergence stops being invisible.
  ///
  /// The live mechanism this comment exists to stop: a picker parameter that
  /// re-encodes as a *side effect*. `image_picker`'s `imageQuality:`,
  /// `maxWidth:` and `maxHeight:` drop EXIF without saying so, and an
  /// implementer passing `imageQuality: 85` "to keep uploads small" would strip
  /// a citizen's GPS without deciding to and without any test failing. B8b uses
  /// `file_picker`, which has no such parameter, and adds **no** dependency —
  /// `B8-AC-57` as amended 2026-08-19.
  ///
  /// **What is genuinely open, and is not this method's to close.** A citizen's
  /// avatar routinely carries the capture GPS of their home, a timestamp and a
  /// device fingerprint, and the resulting object is served back over a channel
  /// with no bearer token (`security-review-b8b.md` § 4.5, `B8b-1`, HIGH, OPEN).
  /// That is a **product** exposure whose only permitted remedy is server-side
  /// ingest, and it is already live on five reachable certificate surfaces since
  /// B12 mounted their routes (`43d1061`). **FU-15** owns it. It does not gate
  /// this code, and this code may not pre-empt it.
  ///
  /// ## A 401 mid-upload is recovered, and B8b inherits that rather than adding it
  ///
  /// `RefreshInterceptor` used to replay an already-finalized Dio `FormData`,
  /// which throws `StateError` — so a token expiring during any multipart POST
  /// killed the upload (`security-review-b8b.md` § 5.1, `B8b-3`, MAJOR). Fixed
  /// at `71c2315` by cloning the body before the replay, with three cases in
  /// `refresh_interceptor_test.dart:780-895` including a mutation-verified
  /// capability control. `tier0_avatar_payload_test.dart` re-proves it for
  /// **this** endpoint rather than assuming the attachment case generalises —
  /// `security-review-b8b.md` § 12(a) S-5.
  @override
  Future<String> uploadAvatar(PickedAvatar file) async {
    // `MultipartFile.fromBytes`, not `fromFile`: [PickedAvatar.path] is absent
    // on the web target and on an Android `content://` pick that returned no
    // cached copy, and the bytes are the half the source actually sends. Same
    // call as `application_remote_datasource.dart:294-297`.
    final FormData form = FormData.fromMap(<String, dynamic>{
      'file': MultipartFile.fromBytes(
        file.bytes ?? Uint8List(0),
        filename: file.name,
      ),
      // **Nothing else.** `form.append("file", file)` is the whole form
      // (`endpoints.ts:108-109`) — unlike `addAttachment`, which also sends
      // `slot`, `kind` and an optional `label`. A `slot` here would be a part
      // the web does not send.
    });

    // `apiClient.upload` sets `contentType: null` for a form
    // (`api_client.dart:253-257`), so Dio generates the boundary — B8-AC-56's
    // second clause. It is authenticated by default (`anonymous` defaults
    // `false` at `:221`), so this POST cannot become anonymous by omission.
    final dynamic data = await apiClient.upload<dynamic>(
      ApiEndpoint.meAvatar,
      form,
    );

    // `api.upload<{ avatar_url: string }>` — the endpoint answers the new URL.
    // A response that is not the declared shape yields `''` rather than
    // throwing: the upload **succeeded** (a 4xx/5xx would have thrown), and the
    // caller does not use this value anyway — `AccountPage.tsx:240` refetches
    // the profile instead of reading `uploadAvatar.data`, which is never read
    // anywhere in the 749-line source. Same disposition as [savePreferences].
    if (data is! Map<String, dynamic>) return '';
    final Object? url = data['avatar_url'];
    return url is String ? url : '';
  }
}
