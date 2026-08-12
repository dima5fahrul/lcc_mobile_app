/// `ApiException` and the `ApiCode` string set.
///
/// GOR-245 § 4.2 freezes the `ApiCode` values as part of the envelope
/// contract, so they are asserted literally.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:lcc_mobile_app/core/network/api_exception.dart';
import 'package:lcc_mobile_app/core/network/envelope.dart';

void main() {
  ApiException exception({
    int status = 400,
    String code = ApiCode.badRequest,
    String message = 'nope',
    List<FieldError> fields = const <FieldError>[],
    String? requestId,
  }) {
    return ApiException(
      status: status,
      code: code,
      message: message,
      fields: fields,
      requestId: requestId,
    );
  }

  group('fieldMap', () {
    test('is empty when there are no field errors', () {
      expect(exception().fieldMap(), isEmpty);
    });

    test('keys each message by its field name', () {
      final ApiException e = exception(
        fields: const <FieldError>[
          FieldError(field: 'phone', message: 'invalid'),
          FieldError(field: 'name', rule: 'required', message: 'required'),
        ],
      );

      expect(e.fieldMap(), <String, String>{
        'phone': 'invalid',
        'name': 'required',
      });
    });

    test('keeps the last message when a field repeats', () {
      final ApiException e = exception(
        fields: const <FieldError>[
          FieldError(field: 'phone', message: 'first'),
          FieldError(field: 'phone', message: 'second'),
        ],
      );

      expect(e.fieldMap()['phone'], 'second');
    });
  });

  group('status predicates', () {
    test('isValidation is true on a VALIDATION_ERROR code', () {
      expect(
        exception(status: 400, code: ApiCode.validationError).isValidation,
        isTrue,
      );
    });

    test('isValidation is true on a 422 whatever the code', () {
      expect(
        exception(status: 422, code: ApiCode.networkError).isValidation,
        isTrue,
      );
    });

    test('isValidation is false otherwise', () {
      expect(exception(status: 500, code: ApiCode.internalError).isValidation,
          isFalse);
    });

    test('isUnauthorized / isForbidden / isNotFound track their statuses', () {
      expect(exception(status: 401).isUnauthorized, isTrue);
      expect(exception(status: 403).isUnauthorized, isFalse);
      expect(exception(status: 403).isForbidden, isTrue);
      expect(exception(status: 404).isNotFound, isTrue);
      expect(exception(status: 200).isNotFound, isFalse);
    });
  });

  group('value semantics', () {
    test('two exceptions with the same content are equal', () {
      expect(exception(requestId: 'r1'), exception(requestId: 'r1'));
      expect(
        exception(requestId: 'r1').hashCode,
        exception(requestId: 'r1').hashCode,
      );
    });

    test('a different field list makes them unequal', () {
      expect(
        exception(
          fields: const <FieldError>[FieldError(field: 'a', message: 'x')],
        ),
        isNot(exception()),
      );
    });
  });

  group('toString', () {
    test('names status, code and message', () {
      expect(
        exception(status: 404, code: ApiCode.notFound, message: 'gone')
            .toString(),
        'ApiException(404, NOT_FOUND, gone)',
      );
    });

    test('appends the request id when present', () {
      expect(
        exception(requestId: 'req-3').toString(),
        contains('requestId: req-3'),
      );
    });

    test('appends a field count when there are field errors', () {
      expect(
        exception(
          fields: const <FieldError>[
            FieldError(field: 'a', message: 'x'),
            FieldError(field: 'b', message: 'y'),
          ],
        ).toString(),
        contains('2 field(s)'),
      );
    });
  });

  group('ApiCode — frozen envelope contract (GOR-245 § 4.2)', () {
    test('every code keeps its wire value', () {
      expect(ApiCode.badRequest, 'BAD_REQUEST');
      expect(ApiCode.validationError, 'VALIDATION_ERROR');
      expect(ApiCode.unauthorized, 'UNAUTHORIZED');
      expect(ApiCode.forbidden, 'FORBIDDEN');
      expect(ApiCode.notFound, 'NOT_FOUND');
      expect(ApiCode.conflict, 'CONFLICT');
      expect(ApiCode.unprocessable, 'UNPROCESSABLE');
      expect(ApiCode.tooManyRequests, 'TOO_MANY_REQUESTS');
      expect(ApiCode.internalError, 'INTERNAL_ERROR');
      expect(ApiCode.serviceUnavailable, 'SERVICE_UNAVAILABLE');
      expect(ApiCode.invalidStateTransition, 'INVALID_STATE_TRANSITION');
      expect(ApiCode.paymentRequired, 'PAYMENT_REQUIRED');
      expect(ApiCode.insufficientFunds, 'INSUFFICIENT_FUNDS');
      expect(ApiCode.networkError, 'NETWORK_ERROR');
    });
  });
}
