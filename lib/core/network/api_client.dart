/// `ApiClient` — the single door to the backend, ported from
/// `lcc-app/src/app/api/client.ts`.
///
/// Every server response uses one envelope:
///
///   { success, message, data, meta, code, errors, request_id }
///
/// [ApiClient.request] unwraps it and returns `data` cast to `T`. A failure
/// (non-2xx or `success === false`) is thrown as an [ApiException] carrying
/// the machine-readable `code` and, for a form submission, one entry per
/// offending field — the shape the civil registration forms need to highlight
/// every missing field at once.
///
/// The 401-retry + refresh-session logic lives in [RefreshInterceptor]; this
/// class focuses on envelope unwrapping and the typed request surface.
library;

// The constructor intentionally keeps public parameter names (`dio`,
// `storage`) so the DI call site reads naturally; using initializing formals
// would rename them to `_dio`/`_storage`, which is not a public-API win here.
// ignore_for_file: prefer_initializing_formals

import 'package:dio/dio.dart';

import '../storage/storage_service.dart';
import 'api_exception.dart';
import 'envelope.dart';

/// HTTP method names the API client understands.
enum HttpMethod { get, post, put, patch, delete }

/// Optional request configuration. Mirrors `RequestOptions` in the TS client.
class ApiRequestOptions {
  const ApiRequestOptions({
    this.query,
    this.body,
    this.form,
    this.anonymous = false,
    this.raw = false,
  });

  /// Query-string params. Array values are emitted as repeated params
  /// (`status=a&status=b`) — see [ApiClient._buildQuery].
  final Map<String, dynamic>? query;

  /// JSON body. Mutually exclusive with [form].
  final dynamic body;

  /// Multipart form (Dio `FormData`). Mutually exclusive with [body].
  /// When set, the caller must NOT set `Content-Type` — Dio generates the
  /// boundary automatically.
  final FormData? form;

  /// Skip the Authorization header even when a token is held. Passed to the
  /// interceptors via `RequestOptions.extra['anonymous']`.
  final bool anonymous;

  /// Read the response as text rather than JSON — used by CSV exports.
  final bool raw;
}

/// The single door to the backend.
///
/// Constructed with a configured [Dio] (interceptors wired by [buildDio]) and
/// a [StorageService] for token reads. Prefer calling [ApiClient.request] /
/// [ApiClient.requestPaged] rather than hitting `dio` directly so the envelope
/// is always unwrapped and failures always surface as [ApiException].
class ApiClient {
  ApiClient({required Dio dio, required StorageService storage})
      : _dio = dio,
        _storage = storage;

  // Initializing formals would rename the public param to `_dio`, breaking the
  // DI call site (`ApiClient(dio: ..., storage: ...)`). The body-formals form
  // below is intentional — the `prefer_initializing_formals` lint is silenced
  // by keeping the public names the DI container relies on.
  final Dio _dio;

  /// The storage service is injected so future feature stages (P0-2 session,
  /// P0-6 profile) can reach the token store through the same root. Kept as a
  /// visible getter rather than a private field to avoid an unused-field lint.
  final StorageService _storage;

  /// Access the shared [StorageService] (token store, language preference).
  ///
  /// Feature layers that need direct token reads (rare — most go through the
  /// interceptors) can reach it here without re-registering a second instance.
  StorageService get storage => _storage;

  /// Perform a request, unwrap the envelope, and return `data` cast to `T`.
  ///
  /// Throws [ApiException] on:
  /// - transport failure (status 0, code `NETWORK_ERROR`).
  /// - non-2xx HTTP status.
  /// - `envelope.success === false`.
  ///
  /// When [ApiRequestOptions.raw] is true the response body is returned as a
  /// `String` cast to `T` (used by CSV exports).
  Future<T> request<T>(
    HttpMethod method,
    String path, {
    ApiRequestOptions? options,
  }) async {
    final opts = options ?? const ApiRequestOptions();

    try {
      final response = await _send<T>(method, path, opts);
      return _unwrap<T>(response, opts);
    } on ApiException {
      rethrow;
    } on DioException catch (e) {
      // A DioException that slipped past the interceptors (e.g. a cancel).
      if (e.type == DioExceptionType.cancel) {
        throw ApiException(
          status: 0,
          code: ApiCode.networkError,
          message: 'Request cancelled.',
        );
      }
      throw ApiException(
        status: e.response?.statusCode ?? 0,
        code: ApiCode.networkError,
        message: 'Cannot reach the server. Check your connection and try again.',
      );
    }
  }

  /// Like [request] but keeps the pagination block alongside the rows.
  ///
  /// Returns `{data, meta}`; when the server omits `meta`, a default is
  /// synthesized from the row count.
  Future<Paged<T>> requestPaged<T>(
    String path, {
    Map<String, dynamic>? query,
  }) async {
    try {
      final response = await _send<T>(
        HttpMethod.get,
        path,
        ApiRequestOptions(query: query),
      );

      final raw = response.data;
      Map<String, dynamic>? envelopeJson;
      if (raw is Map<String, dynamic>) {
        envelopeJson = raw;
      } else if (raw is String) {
        // raw=true path is not meaningful for paged; but stay defensive.
        throw ApiException(
          status: 0,
          code: ApiCode.internalError,
          message: 'Malformed paged response.',
        );
      }

      final success = envelopeJson?['success'] as bool? ?? false;
      if (!success) {
        throw ApiException(
          status: response.statusCode ?? 0,
          code: (envelopeJson?['code'] as String?) ?? ApiCode.internalError,
          message: (envelopeJson?['message'] as String?) ?? 'Something went wrong.',
          fields: _parseFields(envelopeJson?['errors']),
          requestId: envelopeJson?['request_id'] as String?,
        );
      }

      final dataRaw = envelopeJson?['data'];
      final List<T> data =
          dataRaw is List ? List<T>.from(dataRaw) : <T>[];

      final metaJson = envelopeJson?['meta'];
      final meta = metaJson is Map<String, dynamic>
          ? PageMeta.fromJson(metaJson)
          : PageMeta(
              page: 1,
              perPage: data.length,
              total: data.length,
              totalPages: 1,
              hasNext: false,
              hasPrev: false,
            );

      return Paged<T>(data: data, meta: meta);
    } on ApiException {
      rethrow;
    } on DioException catch (e) {
      throw ApiException(
        status: e.response?.statusCode ?? 0,
        code: ApiCode.networkError,
        message: 'Cannot reach the server. Check your connection and try again.',
      );
    }
  }

  // ── Verb convenience methods (mirror the TS `api` object) ──────────────────
  Future<T> get<T>(String path, {Map<String, dynamic>? query, bool anonymous = false}) =>
      request<T>(HttpMethod.get, path,
          options: ApiRequestOptions(query: query, anonymous: anonymous));

  Future<T> post<T>(String path, {dynamic body, bool anonymous = false}) =>
      request<T>(HttpMethod.post, path,
          options: ApiRequestOptions(body: body, anonymous: anonymous));

  Future<T> put<T>(String path, {dynamic body}) =>
      request<T>(HttpMethod.put, path, options: ApiRequestOptions(body: body));

  Future<T> patch<T>(String path, {dynamic body}) =>
      request<T>(HttpMethod.patch, path, options: ApiRequestOptions(body: body));

  Future<T> delete<T>(String path, {dynamic body}) =>
      request<T>(HttpMethod.delete, path, options: ApiRequestOptions(body: body));

  /// Multipart upload. `form` is a Dio `FormData` built by the caller.
  Future<T> upload<T>(String path, FormData form, {bool anonymous = false}) =>
      request<T>(HttpMethod.post, path,
          options: ApiRequestOptions(form: form, anonymous: anonymous));

  // ── Internals ──────────────────────────────────────────────────────────────

  Future<Response<T>> _send<T>(
    HttpMethod method,
    String path,
    ApiRequestOptions opts,
  ) async {
    final extra = <String, dynamic>{'anonymous': opts.anonymous};

    final isForm = opts.form != null;
    final Options dioOptions = Options(
      extra: extra,
      // Let Dio set the multipart boundary when sending FormData; otherwise
      // default to JSON.
      contentType: isForm ? null : 'application/json',
      responseType: opts.raw ? ResponseType.plain : ResponseType.json,
    );

    final query = _buildQuery(opts.query);

    try {
      switch (method) {
        case HttpMethod.get:
          return await _dio.get<T>(path,
              queryParameters: query, options: dioOptions);
        case HttpMethod.post:
          return await _dio.post<T>(path,
              data: isForm ? opts.form : opts.body,
              queryParameters: query,
              options: dioOptions);
        case HttpMethod.put:
          return await _dio.put<T>(path,
              data: opts.body, queryParameters: query, options: dioOptions);
        case HttpMethod.patch:
          return await _dio.patch<T>(path,
              data: opts.body, queryParameters: query, options: dioOptions);
        case HttpMethod.delete:
          return await _dio.delete<T>(path,
              data: opts.body, queryParameters: query, options: dioOptions);
      }
    } on DioException {
      // Bubble to the caller; request() maps to ApiException.
      rethrow;
    }
  }

  /// Unwrap the envelope and return `data` cast to `T`.
  ///
  /// Throws [ApiException] when the HTTP status is non-2xx or
  /// `envelope.success === false`.
  T _unwrap<T>(Response<T> response, ApiRequestOptions opts) {
    final status = response.statusCode ?? 0;
    final ok = status >= 200 && status < 300;

    if (opts.raw) {
      final text = response.data is String ? response.data as String : '';
      if (!ok) {
        throw ApiException(
          status: status,
          code: ApiCode.badRequest,
          message: text.isNotEmpty
              ? (text.length > 200 ? text.substring(0, 200) : text)
              : 'Request failed.',
        );
      }
      return text as T;
    }

    final raw = response.data;
    Map<String, dynamic>? envelope;
    if (raw is Map<String, dynamic>) {
      envelope = raw;
    } else if (raw == null && !ok) {
      throw ApiException(
        status: status,
        code: ApiCode.internalError,
        message: 'The server sent a malformed response.',
      );
    }

    if (envelope == null) {
      throw ApiException(
        status: status,
        code: ApiCode.internalError,
        message: ok
            ? 'The server sent a malformed response.'
            : 'Request failed with status $status.',
      );
    }

    final success = envelope['success'] as bool? ?? false;
    if (!ok || !success) {
      throw ApiException(
        status: status,
        code: (envelope['code'] as String?) ?? ApiCode.internalError,
        message: (envelope['message'] as String?) ?? 'Something went wrong.',
        fields: _parseFields(envelope['errors']),
        requestId: envelope['request_id'] as String?,
      );
    }

    final data = envelope['data'];
    // Cast to T. When the caller passes T = dynamic / Map<String, dynamic>,
    // this returns the raw map; when T is a typed model the caller parses via
    // fromJson in their repository (P0-2 / P0-6).
    return data as T;
  }

  /// Build a query-params map that Dio accepts, turning `List` values into
  /// the repeated-param shape (`status=a&status=b`).
  ///
  /// Skips `null`, `undefined`-equivalent (handled by not being in the map),
  /// and empty strings — mirrors `buildURL` in the TS client.
  Map<String, dynamic> _buildQuery(Map<String, dynamic>? query) {
    if (query == null) return <String, dynamic>{};
    final out = <String, dynamic>{};
    query.forEach((key, value) {
      if (value == null) return;
      if (value is String && value.isEmpty) return;
      out[key] = value;
    });
    return out;
  }

  /// Parse the `errors` field of an envelope into a list of [FieldError].
  List<FieldError> _parseFields(dynamic raw) {
    if (raw is! List) return const <FieldError>[];
    return raw
        .whereType<Map<String, dynamic>>()
        .map(FieldError.fromJson)
        .toList(growable: false);
  }
}
