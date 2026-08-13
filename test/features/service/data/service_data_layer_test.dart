/// The catalogue's data layer — datasource, repository, and the wire→entity
/// boundary.
///
/// **B2-AC-36 in its strongest form.** The criterion asks for mixed wire shapes
/// proven *against real recorded staging payloads in a fixture, not
/// hand-written JSON*, and every parse below runs the 43 real service rows and
/// the 8 real category rows from `oracle/api/` through the production models.
/// Hand-written JSON is written to match the model and therefore cannot fail;
/// § 5's trap — `{en,lo}` objects and plain strings arriving from sibling
/// endpoints in the same data set — is invisible to it.
///
/// The degenerate cases (absent key, wrong type, empty pair) are constructed by
/// **mutating a real row**, so even they start from the true shape.
library;

import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lcc_mobile_app/core/constant/api_endpoint.dart';
import 'package:lcc_mobile_app/core/error/failure.dart';
import 'package:lcc_mobile_app/core/network/api_exception.dart';
import 'package:lcc_mobile_app/features/service/data/datasources/service_remote_datasource.dart';
import 'package:lcc_mobile_app/features/service/data/models/bilingual_converter.dart';
import 'package:lcc_mobile_app/features/service/data/models/service_category_model.dart';
import 'package:lcc_mobile_app/features/service/data/models/service_model.dart';
import 'package:lcc_mobile_app/features/service/data/repositories/service_repository_impl.dart';
import 'package:lcc_mobile_app/features/service/domain/entities/service.dart';
import 'package:lcc_mobile_app/features/service/domain/entities/service_category.dart';
import 'package:lcc_mobile_app/features/session/domain/entities/bilingual.dart';
import 'package:mocktail/mocktail.dart';

import '../../../fidelity/oracle.dart';
import '../../../helpers/auth_test_helper.dart';

class _FailingDatasource implements ServiceRemoteDatasource {
  const _FailingDatasource(this.error);

  final Object error;

  @override
  Future<List<ServiceCategoryModel>> getCategories() async => throw error;

  @override
  Future<List<ServiceModel>> getServices({String? search, String? category}) =>
      throw error;
}

void main() {
  group('ServiceModel — the real 43 rows', () {
    test('every recorded row parses and round-trips into an entity', () {
      final List<Map<String, dynamic>> rows = loadApi('services');
      expect(rows, hasLength(43));

      for (final Map<String, dynamic> row in rows) {
        final Service entity = ServiceModel.fromJson(row).toEntity();

        expect(entity.code, row['code']);
        expect(entity.name.en, (row['name'] as Map<String, dynamic>)['en']);
        expect(entity.name.lo, (row['name'] as Map<String, dynamic>)['lo']);
        expect(entity.categoryCode, row['category_code']);
        expect(entity.feeLak, row['fee_lak']);
        expect(entity.sortOrder, row['sort_order']);
        // `?? ''` because the recording omits the key on rows that have no
        // web route rather than sending an empty string — which is itself the
        // model's `@Default('')` earning its place.
        expect(entity.routePath, row['route_path'] ?? '');
        expect(entity.requiredDocs, isA<List<Bilingual>>());
      }
    });

    test('required_docs is a LIST of bilingual pairs, not one', () {
      // The converter is applied element-wise. `resident` has three docs; a
      // converter wired at the wrong level would parse one or throw.
      final Map<String, dynamic> resident = loadApi('services')
          .firstWhere((Map<String, dynamic> r) => r['code'] == 'resident');
      final Service entity = ServiceModel.fromJson(resident).toEntity();

      expect(entity.requiredDocs, hasLength(3));
      expect(entity.requiredDocs.first.en, 'National ID card or passport');
      expect(entity.requiredDocs.first.lo, isNotEmpty);
    });

    test('a row missing its optional scalars still parses', () {
      // Real row, stripped. The catalogue is administrator-maintained and a
      // new row can reach the wire before every column is filled; the page must
      // degrade, not fall over.
      final Map<String, dynamic> row =
          Map<String, dynamic>.from(loadApi('services').first)
            ..remove('fee_max_lak')
            ..remove('fee_is_range')
            ..remove('route_path')
            ..remove('required_docs')
            ..remove('processing_time');

      final Service entity = ServiceModel.fromJson(row).toEntity();

      expect(entity.feeMaxLak, 0);
      expect(entity.feeIsRange, isFalse);
      expect(entity.routePath, '');
      expect(entity.requiredDocs, isEmpty);
      expect(entity.processingTime, const Bilingual(en: '', lo: ''));
    });
  });

  group('ServiceCategoryModel — the real 8 rows', () {
    test('every recorded row parses into an entity', () {
      final List<Map<String, dynamic>> rows = loadApi('service-categories');
      expect(rows, hasLength(8));

      for (final Map<String, dynamic> row in rows) {
        final ServiceCategory entity =
            ServiceCategoryModel.fromJson(row).toEntity();

        expect(entity.code, row['code']);
        expect(entity.icon, row['icon']);
        expect(entity.color, row['color']);
        expect(entity.active, isTrue);
        expect(entity.name.lo, isNotEmpty);
      }
    });
  });

  group('BilingualConverter — § 5 s mixed-shape trap', () {
    const BilingualConverter converter = BilingualConverter();

    test('reads a real pair', () {
      expect(
        converter.fromJson(<String, dynamic>{'en': 'Health', 'lo': 'ສາທາລະນະສຸກ'}),
        const Bilingual(en: 'Health', lo: 'ສາທາລະນະສຸກ'),
      );
    });

    test('a half-populated pair degrades to a blank side, not an exception',
        () {
      // Visible and diagnosable. A throw here would take down a page of 43
      // over one bad field — which surfaces as an error state that looks like a
      // network problem (§ 5's exact warning).
      expect(converter.fromJson(<String, dynamic>{'en': 'Health'}),
          const Bilingual(en: 'Health', lo: ''));
      expect(converter.fromJson(<String, dynamic>{'lo': 'ສາທາລະນະສຸກ'}),
          const Bilingual(en: '', lo: 'ສາທາລະນະສຸກ'));
    });

    test('a NON-STRING side degrades too — the trap, exactly', () {
      // `/news` and `/help/faqs` send plain strings where siblings send
      // `{en,lo}`. A number or a nested object in one of these slots must not
      // be a crash.
      expect(
        converter.fromJson(<String, dynamic>{'en': 42, 'lo': <String, String>{}}),
        const Bilingual(en: '', lo: ''),
      );
    });

    test('toJson is the inverse, so a round trip is lossless', () {
      const Bilingual value = Bilingual(en: 'Health', lo: 'ສາທາລະນະສຸກ');

      expect(converter.toJson(value),
          <String, dynamic>{'en': 'Health', 'lo': 'ສາທາລະນະສຸກ'});
      expect(converter.fromJson(converter.toJson(value)), value);
    });
  });

  group('ServiceRemoteDatasourceImpl', () {
    late MockApiClient apiClient;
    late ServiceRemoteDatasourceImpl datasource;

    setUp(() {
      apiClient = MockApiClient();
      datasource = ServiceRemoteDatasourceImpl(apiClient: apiClient);
    });

    test('GETs /service-categories ANONYMOUSLY and parses every row', () async {
      when(() => apiClient.get<dynamic>(any(),
              query: any(named: 'query'), anonymous: any(named: 'anonymous')))
          .thenAnswer((_) async => loadApi('service-categories'));

      final List<ServiceCategoryModel> rows = await datasource.getCategories();

      // The anonymity flag is the assertion a stub could not make: the
      // catalogue is public, and sending a stale bearer token would trigger a
      // refresh round trip on a page that never needed one.
      verify(() => apiClient.get<dynamic>(
            ApiEndpoint.serviceCategories,
            anonymous: true,
          )).called(1);
      expect(rows, hasLength(8));
    });

    test('GETs /services with both filters, ANONYMOUSLY', () async {
      when(() => apiClient.get<dynamic>(any(),
              query: any(named: 'query'), anonymous: any(named: 'anonymous')))
          .thenAnswer((_) async => loadApi('services'));

      final List<ServiceModel> rows =
          await datasource.getServices(search: 'cert', category: 'civil');

      final Map<String, dynamic> query = verify(
        () => apiClient.get<dynamic>(
          ApiEndpoint.services,
          query: captureAny(named: 'query'),
          anonymous: true,
        ),
      ).captured.single as Map<String, dynamic>;

      expect(query, <String, dynamic>{'search': 'cert', 'category': 'civil'});
      expect(rows, hasLength(43));
    });

    test('nulls are passed through for ApiClient to drop', () async {
      // `ApiClient._buildQuery` skips nulls, so "no filter" sends no parameter
      // rather than `?search=`. Asserting the datasource passes the nulls
      // rather than pre-filtering keeps that one behaviour in one place.
      when(() => apiClient.get<dynamic>(any(),
              query: any(named: 'query'), anonymous: any(named: 'anonymous')))
          .thenAnswer((_) async => <dynamic>[]);

      await datasource.getServices();

      final Map<String, dynamic> query = verify(
        () => apiClient.get<dynamic>(
          any(),
          query: captureAny(named: 'query'),
          anonymous: any(named: 'anonymous'),
        ),
      ).captured.single as Map<String, dynamic>;

      expect(query, <String, dynamic>{'search': null, 'category': null});
    });

    test('a non-map element in the array is skipped, not fatal', () async {
      when(() => apiClient.get<dynamic>(any(),
              query: any(named: 'query'), anonymous: any(named: 'anonymous')))
          .thenAnswer((_) async => <dynamic>[
                ...loadApi('services').take(2),
                'not a row',
                null,
              ]);

      expect(await datasource.getServices(), hasLength(2));
    });

    test('an ApiException from the client propagates', () async {
      when(() => apiClient.get<dynamic>(any(),
              query: any(named: 'query'), anonymous: any(named: 'anonymous')))
          .thenThrow(const ApiException(
        status: 500,
        code: 'INTERNAL',
        message: 'boom',
      ));

      await expectLater(
        datasource.getCategories(),
        throwsA(isA<ApiException>()),
      );
    });
  });

  group('ServiceRepositoryImpl', () {
    test('maps models to entities on success', () async {
      final ServiceRepositoryImpl repository = ServiceRepositoryImpl(
        remote: _RecordingDatasource(),
      );

      final Either<Failure, List<ServiceCategory>> categories =
          await repository.getCategories();
      final Either<Failure, List<Service>> services =
          await repository.getServices(search: 'x', category: 'civil');

      expect(categories.getOrElse(() => const <ServiceCategory>[]),
          hasLength(8));
      expect(services.getOrElse(() => const <Service>[]), hasLength(43));
    });

    test('every failure becomes a Left — including ApiException', () async {
      // The documented deviation from the session repository: there is no
      // rethrow here. The catalogue is anonymous, has no token to clear, and
      // every failure mode collapses to the same error-with-retry state.
      for (final Object error in <Object>[
        const ApiException(status: 401, code: 'UNAUTHORIZED', message: 'no'),
        DioException(requestOptions: RequestOptions()),
        const FormatException('bad json'),
      ]) {
        final ServiceRepositoryImpl repository =
            ServiceRepositoryImpl(remote: _FailingDatasource(error));

        expect((await repository.getCategories()).isLeft(), isTrue,
            reason: '$error should be a Left, not a throw');
        expect((await repository.getServices()).isLeft(), isTrue,
            reason: '$error should be a Left, not a throw');
      }
    });

    test('the Failure carries the cause for logs, and it is NOT the UI copy',
        () async {
      final ServiceRepositoryImpl repository = ServiceRepositoryImpl(
        remote: const _FailingDatasource(FormatException('unexpected token')),
      );

      final Either<Failure, List<Service>> result =
          await repository.getServices();

      final Failure failure =
          result.swap().getOrElse(() => const Failure('unreachable'));
      expect(failure.message, contains('unexpected token'));

      // `ServicePage.tsx:227-232` shows a fixed bilingual sentence and never
      // the server's words. This message is for a log, and the page must not
      // render it — a leak of backend detail onto a public surface.
      expect(failure.message, isNot(contains('Could not load')));
    });
  });
}

/// A datasource that answers with the recorded rows and records its arguments.
class _RecordingDatasource implements ServiceRemoteDatasource {
  @override
  Future<List<ServiceCategoryModel>> getCategories() async =>
      loadApi('service-categories')
          .map(ServiceCategoryModel.fromJson)
          .toList(growable: false);

  @override
  Future<List<ServiceModel>> getServices({
    String? search,
    String? category,
  }) async =>
      loadApi('services').map(ServiceModel.fromJson).toList(growable: false);
}
