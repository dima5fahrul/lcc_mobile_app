/// `POST /applications/{id}/pay` — Tier 0 payload equality, and the failure
/// path that carries a code.
///
/// `B6-AC-36`, tagged **B6b**.
///
/// ## § 4.4 — no request in this file reaches a host
///
/// This endpoint moves a citizen's money, and § 4.4 forbids executing it
/// against **any** host: not staging, not with a small amount, and not by
/// first creating a case so that there is something to pay for — that loophole
/// is named and closed in the same section and audited as security-review
/// item 6. The transport is an in-process adapter and `kTestBaseUrl` is
/// `api.test.invalid`, an RFC-2606 reserved name that cannot resolve even if
/// the adapter were removed. The second property is the load-bearing one: it
/// makes the prohibition survive a future edit that swaps the adapter out,
/// which is the same reasoning `wallet_remote_datasource_test.dart` records for
/// the top-up POST.
///
/// ## Why Tier 0 is assertable here when Tier 3 is not
///
/// Tier 0 is payload equality on a **sent** body, and a body can be sent to a
/// mock. Tier 3 needs a rendered screen over real data, and the only available
/// test citizen has `applications total 0` — nothing to pay for. So this file
/// discharges `B6-AC-36` for real, and `qa-report.md` records every Tier 3
/// verdict for the pay surfaces as NOT EVALUATED with that reason. The two are
/// different claims and only one of them is available.
library;

import 'dart:convert';
import 'dart:io';

import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lcc_mobile_app/core/error/failure.dart';
import 'package:lcc_mobile_app/core/network/api_client.dart';
import 'package:lcc_mobile_app/core/network/api_exception.dart';
import 'package:lcc_mobile_app/core/storage/storage_keys.dart';
import 'package:lcc_mobile_app/core/storage/storage_service.dart';
import 'package:lcc_mobile_app/features/wallet/data/datasources/wallet_remote_datasource.dart';
import 'package:lcc_mobile_app/features/wallet/data/repositories/wallet_repository_impl.dart';
import 'package:lcc_mobile_app/features/wallet/domain/entities/payment_result.dart';

import '../../../helpers/core_test_helper.dart';

/// The whole fixture document, `_capture` block included — read from disk so
/// the provenance a reviewer opens is the provenance the test ran against.
Map<String, dynamic> _fixtureBody(String name) =>
    jsonDecode(_read('test/fidelity/fixtures/api/$name'))
        as Map<String, dynamic>;

String _read(String path) => File(path).readAsStringSync();

void main() {
  late RecordingHttpAdapter adapter;
  late WalletRemoteDatasourceImpl datasource;
  late WalletRepositoryImpl repository;

  void boot(ScriptedResponder responder) {
    final Map<String, String> store = <String, String>{
      StorageKeys.accessToken: 'seeded-access-token',
    };
    final StorageService storage = inMemoryStorageService(store);
    adapter = RecordingHttpAdapter(responder);
    datasource = WalletRemoteDatasourceImpl(
      apiClient: ApiClient(
        dio: buildTestDio(storage: storage, adapter: adapter),
        storage: storage,
      ),
    );
    repository = WalletRepositoryImpl(remote: datasource);
  }

  void bootWith(Object? body, {int status = 200}) => boot(
    (RequestOptions _, int __) => jsonResponse(body, statusCode: status),
  );

  RequestOptions sent() => adapter.requests.single;

  Map<String, dynamic> sentBody() => sent().data as Map<String, dynamic>;

  group('B6-AC-36 — the body is EXACTLY {"method_code": "<code>"}', () {
    test('one key, and it is method_code', () {
      bootWith(_fixtureBody('application-pay-settled.json'));

      return datasource
          .payApplication(applicationId: 'app-901', methodCode: 'bcel-one')
          .then((_) {
            // "Exactly" is the criterion, so the assertion is on the key SET, not
            // on the presence of one key. A body that also carried an
            // `idempotency_key`, an `amount_lak` or a `client_ts` would pass
            // `containsPair` and fail Tier 0.
            expect(sentBody().keys.toList(), <String>['method_code']);
            expect(sentBody()['method_code'], 'bcel-one');
          });
    });

    test('it is the CODE — not the id, the label or the kind', () {
      // All four are strings on `PaymentMethod`, which is what makes the
      // mix-up survivable at compile time. The negative half is the criterion:
      // a datasource that sent `m.id` would still send one key with a string
      // value and would still pass a laxer test.
      bootWith(_fixtureBody('application-pay-settled.json'));

      return datasource
          .payApplication(applicationId: 'app-901', methodCode: 'laoqr')
          .then((_) {
            expect(sentBody()['method_code'], 'laoqr');
            expect(sentBody()['method_code'], isNot('pm-laoqr'));
            expect(sentBody()['method_code'], isNot('qr'));
          });
    });

    test('the id goes in the PATH, encoded, and never in the body', () async {
      bootWith(_fixtureBody('application-pay-settled.json'));

      await datasource.payApplication(
        applicationId: 'app/901',
        methodCode: 'wallet',
      );

      // `Uri.encodeComponent` — a `/`-bearing id must not reach a different
      // endpoint than the caller named.
      expect(sent().path, '/applications/app%2F901/pay');
      expect(sentBody().containsKey('application_id'), isFalse);
      expect(sentBody().containsKey('id'), isFalse);
    });

    test('it is a POST, and it carries the Authorization header', () async {
      // The counterpart to `B6-AC-24`: `/payment-methods` is the batch's ONE
      // anonymous call and this is not it. Asserted on the recorded request.
      bootWith(_fixtureBody('application-pay-settled.json'));

      await datasource.payApplication(
        applicationId: 'app-901',
        methodCode: 'wallet',
      );

      expect(sent().method, 'POST');
      expect(sent().headers['Authorization'], 'Bearer seeded-access-token');
    });
  });

  group('the failure path carries the code the amber panel branches on', () {
    test(
      'an INSUFFICIENT_FUNDS envelope becomes a PaymentFailure with .code',
      () async {
        final Map<String, dynamic> envelope = _fixtureBody(
          'application-pay-insufficient.json',
        );
        bootWith(envelope, status: 422);

        final Either<Failure, PaymentResult> result = await repository
            .payApplication(applicationId: 'app-901', methodCode: 'wallet');

        final Failure failure = result.fold(
          (Failure f) => f,
          (PaymentResult _) => throw StateError('expected a Left'),
        );

        expect(failure, isA<PaymentFailure>());
        expect((failure as PaymentFailure).code, ApiCode.insufficientFunds);
        // The message is the server's, unchanged — nothing composes a string out
        // of a balance or an amount (security-review item 2).
        expect(failure.message, isNotEmpty);
      },
    );

    test('a non-money failure still arrives as a PaymentFailure, not a bare '
        'Failure', () async {
      // So a caller can always read `.code` without a type test that sometimes
      // fails. F1/F2/F3 branch on this from inside their submit chain.
      bootWith(<String, dynamic>{
        'success': false,
        'code': 'INTERNAL_ERROR',
        'message': 'Something went wrong.',
      }, status: 500);

      final Either<Failure, PaymentResult> result = await repository
          .payApplication(applicationId: 'app-901', methodCode: 'wallet');

      final Failure failure = result.fold(
        (Failure f) => f,
        (PaymentResult _) => throw StateError('expected a Left'),
      );

      expect(failure, isA<PaymentFailure>());
      expect(
        (failure as PaymentFailure).code,
        isNot(ApiCode.insufficientFunds),
      );
    });
  });

  group('B6-AC-46 — PayApplication publishes its seam in its doc comment', () {
    test('it names F1, F2, F3 and B7 and cites the five call sites', () {
      final String src = _read(
        'lib/features/wallet/domain/usecases/pay_application.dart',
      );

      // § 6.3 requires the seam to be stated AT the exported surface, so
      // F1-F3 do not re-implement the capability. A doc comment is the artifact
      // the criterion names; this asserts it says what it must.
      for (final String caller in <String>['F1', 'F2', 'F3', 'B7']) {
        expect(src, contains(caller), reason: 'must name $caller as a caller');
      }
      for (final String site in <String>[
        'PaymentSection.tsx:207',
        'WalletPage.tsx:538-548',
        'HistoryDetailPage.tsx:427-436',
        'ResidentCertificatePage.tsx:535-539',
        'BirthDeclarationPage.tsx:847-853',
      ]) {
        expect(src, contains(site), reason: 'must cite $site');
      }
    });

    test('and it states § 4.4 at the surface a wizard will call', () {
      final String src = _read(
        'lib/features/wallet/domain/usecases/pay_application.dart',
      );
      expect(src, contains('§ 4.4'));
    });
  });
}
