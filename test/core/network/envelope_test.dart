/// Envelope wire models — `PageMeta`, `FieldError`, `Envelope<T>`, `Paged<T>`.
///
/// GOR-245 § 4.2 freezes the envelope contract
/// (`{success, message, data, meta, code, errors, request_id}`) because it
/// mirrors the live LCC backend. These tests assert the snake_case wire keys
/// directly, so a `@JsonKey` slipping to camelCase during a codegen re-run is a
/// test failure rather than a 200 that silently parses to nulls.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:lcc_mobile_app/core/network/envelope.dart';

void main() {
  group('PageMeta', () {
    const Map<String, dynamic> json = <String, dynamic>{
      'page': 2,
      'per_page': 20,
      'total': 45,
      'total_pages': 3,
      'has_next': true,
      'has_prev': true,
    };

    test('parses the snake_case wire shape', () {
      final PageMeta meta = PageMeta.fromJson(json);

      expect(meta.page, 2);
      expect(meta.perPage, 20);
      expect(meta.total, 45);
      expect(meta.totalPages, 3);
      expect(meta.hasNext, isTrue);
      expect(meta.hasPrev, isTrue);
    });

    test('serialises back to the same snake_case keys', () {
      expect(PageMeta.fromJson(json).toJson(), json);
    });

    test('empty is the zero-row default', () {
      expect(PageMeta.empty.page, 1);
      expect(PageMeta.empty.perPage, 0);
      expect(PageMeta.empty.total, 0);
      expect(PageMeta.empty.totalPages, 1);
      expect(PageMeta.empty.hasNext, isFalse);
      expect(PageMeta.empty.hasPrev, isFalse);
    });
  });

  group('FieldError', () {
    test('parses field, rule and message', () {
      final FieldError error = FieldError.fromJson(<String, dynamic>{
        'field': 'phone',
        'rule': 'format',
        'message': 'phone is invalid',
      });

      expect(error.field, 'phone');
      expect(error.rule, 'format');
      expect(error.message, 'phone is invalid');
    });

    test('tolerates a missing rule — not every failure names one', () {
      final FieldError error = FieldError.fromJson(<String, dynamic>{
        'field': 'name',
        'message': 'name is required',
      });

      expect(error.rule, isNull);
      expect(error.message, 'name is required');
    });
  });

  group('Envelope', () {
    test('parses a success envelope with a typed data payload', () {
      final Envelope<PageMeta> envelope = Envelope<PageMeta>.fromJson(
        <String, dynamic>{
          'success': true,
          'message': 'OK',
          'data': <String, dynamic>{
            'page': 1,
            'per_page': 5,
            'total': 5,
            'total_pages': 1,
            'has_next': false,
            'has_prev': false,
          },
          'request_id': 'req-1',
        },
        (Object? json) => PageMeta.fromJson(json! as Map<String, dynamic>),
      );

      expect(envelope.success, isTrue);
      expect(envelope.message, 'OK');
      expect(envelope.data?.perPage, 5);
      expect(envelope.requestId, 'req-1');
      expect(envelope.code, isNull);
      expect(envelope.errors, isNull);
    });

    test('parses a failure envelope with code and per-field errors', () {
      final Envelope<dynamic> envelope = Envelope<dynamic>.fromJson(
        <String, dynamic>{
          'success': false,
          'message': 'Validation failed',
          'code': 'VALIDATION_ERROR',
          'data': null,
          'errors': <Map<String, dynamic>>[
            <String, dynamic>{'field': 'phone', 'message': 'invalid'},
          ],
          'request_id': 'req-2',
        },
        (Object? json) => json,
      );

      expect(envelope.success, isFalse);
      expect(envelope.code, 'VALIDATION_ERROR');
      expect(envelope.errors, hasLength(1));
      expect(envelope.errors!.single.field, 'phone');
    });
  });

  group('Paged', () {
    test('holds rows alongside their meta block', () {
      const Paged<String> paged = Paged<String>(
        data: <String>['a', 'b'],
        meta: PageMeta.empty,
      );

      expect(paged.data, <String>['a', 'b']);
      expect(paged.meta, PageMeta.empty);
    });
  });
}
