/// Snake_case wire-protocol models for the LCC API envelope.
///
/// Every backend response uses one envelope, so unwrapping it belongs here
/// rather than in thirty call sites:
///
///   { success, message, data, meta, code, errors, request_id }
///
/// Ported from `lcc-app/src/app/api/client.ts` (TS `Envelope<T>`,
/// `PageMeta`, `FieldError`, `Paged<T>`).
library;

import 'package:freezed_annotation/freezed_annotation.dart';

part 'envelope.freezed.dart';
part 'envelope.g.dart';

/// `PageMeta` — pagination block returned alongside a page of rows.
///
/// Wire shape: `{ page, per_page, total, total_pages, has_next, has_prev }`.
@freezed
abstract class PageMeta with _$PageMeta {
  const factory PageMeta({
    @JsonKey(name: 'page') required int page,
    @JsonKey(name: 'per_page') required int perPage,
    @JsonKey(name: 'total') required int total,
    @JsonKey(name: 'total_pages') required int totalPages,
    @JsonKey(name: 'has_next') required bool hasNext,
    @JsonKey(name: 'has_prev') required bool hasPrev,
  }) = _PageMeta;

  factory PageMeta.fromJson(Map<String, dynamic> json) => _$PageMetaFromJson(json);

  /// Default meta used by `requestPaged` when the server omits the block.
  static const PageMeta empty = PageMeta(
    page: 1,
    perPage: 0,
    total: 0,
    totalPages: 1,
    hasNext: false,
    hasPrev: false,
  );
}

/// `FieldError` — one validation failure for one field.
///
/// Wire shape: `{ field, rule?, message }`. `rule` is optional because some
/// validation failures come back without a machine-readable rule name.
@freezed
abstract class FieldError with _$FieldError {
  const factory FieldError({
    @JsonKey(name: 'field') required String field,
    @JsonKey(name: 'rule') String? rule,
    @JsonKey(name: 'message') required String message,
  }) = _FieldError;

  factory FieldError.fromJson(Map<String, dynamic> json) => _$FieldErrorFromJson(json);
}

/// `Envelope<T>` — the single response wrapper every API call returns.
///
/// `data` is generic so callers bind it to their typed model (e.g.
/// `Envelope<CitizenProfile>`); the envelope itself stays shape-agnostic.
/// `meta`, `code`, `errors`, and `request_id` are present only on some
/// responses.
@Freezed(genericArgumentFactories: true)
abstract class Envelope<T> with _$Envelope<T> {
  const factory Envelope({
    @JsonKey(name: 'success') required bool success,
    @JsonKey(name: 'message') required String message,
    @JsonKey(name: 'data') T? data,
    @JsonKey(name: 'meta') PageMeta? meta,
    @JsonKey(name: 'code') String? code,
    @JsonKey(name: 'errors') List<FieldError>? errors,
    @JsonKey(name: 'request_id') String? requestId,
  }) = _Envelope<T>;

  factory Envelope.fromJson(
    Map<String, dynamic> json,
    T Function(Object? json) fromJsonT,
  ) =>
      _$EnvelopeFromJson<T>(json, fromJsonT);
}

/// `Paged<T>` — a page of rows plus the pagination block that came with it.
///
/// Kept as a plain class (no freezed) because it's a thin transport container
/// for two already-modeled fields; adding code-gen here buys nothing.
class Paged<T> {
  const Paged({required this.data, required this.meta});

  final List<T> data;
  final PageMeta meta;
}
