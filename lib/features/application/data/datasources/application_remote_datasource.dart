/// `ApplicationRemoteDatasource` — the application feature's HTTP boundary.
///
/// Two calls, and the **auth posture differs between them**, which is the one
/// thing this file exists to get right:
///
/// | Method | Path | Auth | Source |
/// |---|---|---|---|
/// | [listApplications] | `GET /applications` | Bearer | `endpoints.ts:321` |
/// | [getStatusPipeline] | `GET /status-catalogue` | **anonymous** | `endpoints.ts:192` |
///
/// Sending a bearer to `/status-catalogue` would work and would still be
/// wrong: a stale token on a public endpoint triggers a refresh round trip on
/// a request that never needed one (`news_remote_datasource.dart`'s note).
/// `B7-AC-22` asserts the absence of the header on the outgoing request rather
/// than the presence of `anonymous: true` in this file — a flag is a
/// configuration value, and the Capability Rule wants the capability.
///
/// ## The repeated `status` parameter (Finding H, `B7-AC-16`)
///
/// `client.ts:188-190` emits `status=a&status=b` for an array. Dio's default
/// `ListFormat` is `multi`, which emits the same shape, so **this port is
/// already correct and the risk is that it silently stops being**. The
/// architect's own prediction that it was broken was wrong (§ 10), and the
/// disposition that survived is a pin, not a fix: `api_client.dart:351-352`'s
/// doc comment describes a list-flattening mechanism `_buildQuery` does not
/// actually contain, so nothing in `lib/**` documents the real behaviour
/// truthfully and nothing asserted it at all.
/// `test/features/application/data/application_datasource_transport_test.dart`
/// asserts the built URI over a real `Dio`, and asserts it is **not**
/// `status[]=`.
///
/// ## Why the reads ask for `dynamic`
///
/// `news_remote_datasource.dart` records the measurement in full: `ApiClient`
/// forwards `T` to `_dio.get<T>()`, Dio casts the decoded **envelope** to `T`,
/// and the envelope is a map. `get<List<dynamic>>` therefore throws before
/// `_unwrap` runs and surfaces as `NETWORK_ERROR` — a served request reported
/// as being offline. One rule, no exceptions: ask for `dynamic`, check here.
library;

import 'dart:typed_data';

import 'package:dio/dio.dart';

import '../../../../core/constant/api_endpoint.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/network/envelope.dart';
import '../../domain/entities/application_detail.dart';
import '../../domain/entities/picked_attachment.dart';
import '../../domain/entities/application_page.dart';
import '../../domain/entities/case_status.dart';
import '../../domain/entities/case_timeline.dart';
import '../../domain/entities/status_pipeline.dart';
import '../models/application_wire.dart';

abstract class ApplicationRemoteDatasource {
  /// `GET /applications?page=&per_page=[&status=…][&search=]`.
  ///
  /// [statuses] `null` sends **no** `status` key at all — the `all` chip
  /// (`FILTER_STATUSES.all = undefined`, `HistoryPage.tsx:50`). An empty list
  /// would take the array branch and is never what the source sends, so it is
  /// treated as `null` here too.
  ///
  /// [search] must already be trimmed; `''` and `null` both send nothing
  /// (`client.ts:187` skips `undefined`, `null` **and** the empty string).
  Future<ApplicationPage> listApplications({
    required int page,
    required int perPage,
    List<CaseStatus>? statuses,
    String? search,
  });

  /// `GET /applications/{id}` — Bearer. **B7b.**
  ///
  /// Throws the [ApiException] the client raises, 404 included; the repository
  /// is where a 404 becomes a distinguishable failure, because that is the
  /// layer whose type the page reads.
  Future<ApplicationDetail> getApplication(String id);

  /// `GET /applications/{id}/timeline` — Bearer. **B7b.**
  Future<CaseTimeline> getApplicationTimeline(String id);

  /// `GET /status-catalogue` — anonymous.
  Future<StatusPipeline> getStatusPipeline();

  // ── The write half (F1, `specs.md` § 6.3) ──────────────────────────────────
  //
  // Four methods, shaped so **B4 merges rather than rewrites** them
  // (`roadmap.md`:399). No `cancel`, no `removeAttachment`, no `pay`.

  /// `POST /applications` — Bearer (`endpoints.ts:325`).
  ///
  /// [envelope] is passed through **as built**, and that is the whole
  /// contract: `client.ts:242` is a bare `JSON.stringify(options.body)`, so
  /// this map's insertion order is the byte order on the socket. Nothing here
  /// may sort it, filter it, or fill a missing key — Resident's
  /// `province_id: form.province || undefined` (`:509`) **elides** the key when
  /// blank and a datasource that re-added it as `""` would put a sixth key on a
  /// five-key body (`F1-AC-21`).
  Future<ApplicationDetail> createApplication(Map<String, Object?> envelope);

  /// `PATCH /applications/{id}` — Bearer (`endpoints.ts:327-328`).
  ///
  /// Same pass-through rule, and the order is **different**: `form_data` is
  /// first here and last on create (`F0-AC-80`). Two key names, two byte
  /// sequences, and neither is a normalisation candidate.
  Future<ApplicationDetail> updateApplication(
    String id,
    Map<String, Object?> envelope,
  );

  /// `POST /applications/{id}/attachments` — multipart, Bearer
  /// (`endpoints.ts:344-351`).
  ///
  /// **No extension or MIME check happens here or anywhere below it** (R-21).
  /// `handleFile` (`ResidentCertificatePage.tsx:213-221`) reads
  /// `e.target.files[0]` and inspects neither `type` nor `size`; a `.pdf`
  /// picked on a control whose `accept` says `image/*` uploads unchanged. The
  /// `kind` string is the **slot's** declared kind, not the file's.
  Future<void> addAttachment(
    String id, {
    required PickedAttachment file,
    required String slot,
    required String kind,
    String? label,
  });

  /// `POST /applications/{id}/submit` — Bearer (`endpoints.ts:338`).
  ///
  /// The body is `{}`. Answers the **decided** case; its `fee_lak` is what the
  /// caller's pay branch reads (`:535`).
  Future<ApplicationDetail> submitApplication(String id);
}

class ApplicationRemoteDatasourceImpl implements ApplicationRemoteDatasource {
  const ApplicationRemoteDatasourceImpl({required this.apiClient});

  final ApiClient apiClient;

  @override
  Future<ApplicationPage> listApplications({
    required int page,
    required int perPage,
    List<CaseStatus>? statuses,
    String? search,
  }) async {
    final Paged<dynamic> result = await apiClient.requestPaged<dynamic>(
      ApiEndpoint.applications,
      query: <String, dynamic>{
        'page': page,
        'per_page': perPage,
        // The wire strings, not the Dart enum names: `under-review`, not
        // `underReview`. `CaseStatus.wire` is the only place that mapping
        // lives.
        if (statuses != null && statuses.isNotEmpty)
          'status': statuses
              .map((CaseStatus s) => s.wire)
              .toList(growable: false),
        // `ApiClient._buildQuery` drops `null` and `''`, so both spellings of
        // "no search" behave as `client.ts:187` does. Passed through rather
        // than branched on here so there is exactly one skip rule.
        if (search != null && search.isNotEmpty) 'search': search,
      },
    );

    final PageMeta meta = result.meta;
    return ApplicationPage(
      // `whereType` rather than a cast: one malformed row costs that row, not
      // the page (`news_remote_datasource.dart`'s `_rows`).
      rows: result.data
          .whereType<Map<String, dynamic>>()
          .map(applicationRowFrom)
          .toList(growable: false),
      page: meta.page,
      totalPages: meta.totalPages,
      // `meta.total`, and **not** `rows.length`. The four stat tiles ask for
      // one row and read this number (`HistoryPage.tsx:103-104`), so a page
      // result that derived `total` from its own row count would make every
      // tile read `1`. `B7-AC-24` pins it with a fixture whose `meta.total` is
      // 42 and whose `data` has one row.
      total: meta.total,
      hasNext: meta.hasNext,
      hasPrev: meta.hasPrev,
    );
  }

  @override
  Future<ApplicationDetail> getApplication(String id) async {
    final dynamic body = await apiClient.get<dynamic>(
      ApiEndpoint.application(id),
    );
    // A detail that is not an object is not a detail. Unlike the catalogue —
    // where `statusCatalogue.ts:60-61` has a seed to fall back to and the bar
    // must still render — there is no such thing as a fallback case, so this
    // throws and the page renders its error branch (`:200-238`) rather than a
    // blank hero over an empty reference number.
    if (body is! Map<String, dynamic>) {
      throw const ApiException(
        status: 0,
        code: ApiCode.internalError,
        message: 'The application payload was not an object.',
      );
    }
    return applicationDetailFrom(body);
  }

  @override
  Future<CaseTimeline> getApplicationTimeline(String id) async {
    final dynamic body = await apiClient.get<dynamic>(
      ApiEndpoint.applicationTimeline(id),
    );
    // A non-object body IS survivable here, and that is the difference from the
    // detail above: the timeline's own empty state ("Nothing has happened on
    // this case yet.", `:534-539`) is a designed screen, so an unreadable
    // envelope degrades to it rather than putting a retry panel in front of a
    // case that is otherwise fully rendered.
    if (body is! Map<String, dynamic>) return CaseTimeline.empty;
    return caseTimelineFrom(body);
  }

  @override
  Future<StatusPipeline> getStatusPipeline() async {
    final dynamic body = await apiClient.get<dynamic>(
      ApiEndpoint.statusCatalogue,
      anonymous: true,
    );
    // A non-object body is not a catalogue. The seed is returned rather than
    // thrown, because `statusCatalogue.ts:60-61` treats "nothing usable came
    // back" and "the fetch failed" identically — the bar keeps its five
    // stages either way (`B7-AC-26`).
    if (body is! Map<String, dynamic>) return StatusPipeline.seeded;
    return statusPipelineFrom(body);
  }

  // ── The write half (F1) ────────────────────────────────────────────────────

  /// The one place a write response becomes an [ApplicationDetail].
  ///
  /// Written once rather than three times because all three writes answer the
  /// same shape and `getApplication` above already proved the failure mode: a
  /// non-object body is not a case, and there is no seed to fall back to.
  ApplicationDetail _caseFrom(dynamic body, String what) {
    if (body is! Map<String, dynamic>) {
      throw ApiException(
        status: 0,
        code: ApiCode.internalError,
        message: 'The $what response was not an object.',
      );
    }
    return applicationDetailFrom(body);
  }

  @override
  Future<ApplicationDetail> createApplication(
    Map<String, Object?> envelope,
  ) async {
    // `body: envelope` — the map reaches Dio's JSON encoder with its insertion
    // order intact, which is the wire order (`F1-AC-21`). Copying it into a
    // new literal here, or spreading it, would preserve order today and is
    // still not done: there would then be two places that decide it.
    final dynamic body = await apiClient.post<dynamic>(
      ApiEndpoint.applications,
      body: envelope,
    );
    return _caseFrom(body, 'create');
  }

  @override
  Future<ApplicationDetail> updateApplication(
    String id,
    Map<String, Object?> envelope,
  ) async {
    final dynamic body = await apiClient.patch<dynamic>(
      ApiEndpoint.application(id),
      body: envelope,
    );
    return _caseFrom(body, 'update');
  }

  @override
  Future<void> addAttachment(
    String id, {
    required PickedAttachment file,
    required String slot,
    required String kind,
    String? label,
  }) async {
    // `MultipartFile.fromBytes` and not `fromFile`: [PickedAttachment.path] is
    // absent on the web target and on an Android content:// pick that returned
    // no cached copy, and the bytes are the half the source actually sends
    // (`FileReader` reads the same `File` object the POST carries).
    final FormData form = FormData.fromMap(<String, dynamic>{
      'file': MultipartFile.fromBytes(
        file.bytes ?? Uint8List(0),
        filename: file.name,
      ),
      'slot': slot,
      'kind': kind,
      // `label` is the source's fourth, optional part (`endpoints.ts:349-350`).
      // Absent means absent — an empty string is a part the web does not send.
      if (label != null) 'label': label,
    });

    await apiClient.upload<dynamic>(
      ApiEndpoint.applicationAttachments(id),
      form,
    );
  }

  @override
  Future<ApplicationDetail> submitApplication(String id) async {
    // `body: const <String, Object?>{}` — the empty object, which serialises to
    // `"{}"`. Omitting `body:` sends no body and `body: null` sends `"null"`;
    // `endpoints.ts:338` sends `{}` and `F1-AC-23` is the assertion that all
    // three were distinguished rather than assumed equivalent.
    final dynamic body = await apiClient.post<dynamic>(
      ApiEndpoint.applicationSubmit(id),
      body: const <String, Object?>{},
    );
    return _caseFrom(body, 'submit');
  }
}
