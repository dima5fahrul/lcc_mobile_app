/// Transport-level regression guard for `ServiceRemoteDatasourceImpl`.
///
/// ## Why this file exists when the datasource is already covered
///
/// Every other test for this datasource mocks `ApiClient`. That proves the
/// datasource calls the right endpoint and maps the right rows — the *wiring* —
/// and it is exactly why a real defect survived a landed ticket:
///
/// `ApiClient._send<T>` forwards `T` to Dio, and Dio casts the decoded
/// **envelope** — an object — to `T`. So `get<List<dynamic>>` threw before
/// `_unwrap` ever saw the payload, and the throw surfaced as
/// `ApiException(0, NETWORK_ERROR, 'Cannot reach the server…')`, indistinguishable
/// from the backend being down. The catalogue could not load against a real
/// server. No mock could have shown it, because a mock never performs the cast.
///
/// This is FACTORY-RULES.md § Quality Gates' Capability Rule applied to itself:
/// *a criterion is not discharged by proving a configuration value propagated; it
/// must assert the capability that value was configured to obtain.* These tests
/// run the datasource over a real `Dio` with only the **transport** stubbed, so
/// the generic argument meets the cast it has to survive.
///
/// Found by B2b probing B2a's landed code; fixed in the same pass.
library;

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lcc_mobile_app/core/constant/api_endpoint.dart';
import 'package:lcc_mobile_app/core/network/api_client.dart';
import 'package:lcc_mobile_app/core/storage/storage_service.dart';
import 'package:lcc_mobile_app/features/service/data/datasources/service_remote_datasource.dart';

import '../../../helpers/core_test_helper.dart';

void main() {
  late StorageService storage;

  setUp(() {
    storage = inMemoryStorageService(<String, String>{});
  });

  /// A real envelope, as the live API returns it: the payload is an array nested
  /// inside an object. The nesting is the whole point — `T` is matched against
  /// the outer object, never against `data`.
  Map<String, dynamic> envelopeWith(List<Map<String, dynamic>> rows) =>
      <String, dynamic>{
        'success': true,
        'message': 'ok',
        'request_id': 'transport-guard',
        'data': rows,
      };

  ServiceRemoteDatasourceImpl datasourceReplying(
    List<Map<String, dynamic>> rows,
  ) {
    final Dio dio = buildTestDio(
      storage: storage,
      adapter: RecordingHttpAdapter.always(envelopeWith(rows)),
      withInterceptors: false,
    );
    return ServiceRemoteDatasourceImpl(
      apiClient: ApiClient(dio: dio, storage: storage),
    );
  }

  test('getCategories survives the envelope cast against a real Dio', () async {
    final ServiceRemoteDatasourceImpl datasource =
        datasourceReplying(<Map<String, dynamic>>[
      <String, dynamic>{
        'id': 'c1',
        'code': 'civil',
        'name': <String, dynamic>{'en': 'Civil', 'lo': 'ພົນລະເມືອງ'},
        'icon': 'Users',
        'color': '#344EAD',
        'sort_order': 1,
        'active': true,
      },
    ]);

    // Reaching this line at all is the assertion that matters. Before the fix it
    // threw a DioException that ApiClient rewrote into NETWORK_ERROR.
    expect(await datasource.getCategories(), hasLength(1));
  });

  test('getServices survives the envelope cast against a real Dio', () async {
    final ServiceRemoteDatasourceImpl datasource =
        datasourceReplying(<Map<String, dynamic>>[
      <String, dynamic>{
        'id': 's1',
        'code': 'resident',
        'category_code': 'civil',
        'name': <String, dynamic>{'en': 'Resident', 'lo': 'ຢັ້ງຢືນ'},
        'description': <String, dynamic>{'en': '', 'lo': ''},
      },
    ]);

    expect(await datasource.getServices(), hasLength(1));
  });

  test('negative control — List<dynamic> throws on this envelope, dynamic does not',
      () async {
    // Without this, the two tests above would pass just as happily against a
    // datasource that never had the bug, and this file would assert nothing in
    // particular. This pins the mechanism itself: if a future Dio stops casting,
    // the guard says so rather than going quietly green for a new reason.
    final Dio dio = buildTestDio(
      storage: storage,
      adapter: RecordingHttpAdapter.always(envelopeWith(<Map<String, dynamic>>[])),
      withInterceptors: false,
    );

    await expectLater(
      dio.get<List<dynamic>>(ApiEndpoint.services),
      throwsA(isA<DioException>()),
    );

    // And the form the datasource actually uses does not throw.
    await expectLater(dio.get<dynamic>(ApiEndpoint.services), completes);
  });
}
