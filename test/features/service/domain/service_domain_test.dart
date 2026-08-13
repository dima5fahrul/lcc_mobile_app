/// The catalogue's domain layer — the availability predicate and the two use
/// cases.
///
/// `ServiceAvailability` gets the most attention here because it is the one
/// piece of B2 that encodes a **product ruling** (SSD § 13's C-2/C-3/C-4)
/// rather than a mechanical port, and because the ruling it encodes is
/// counter-intuitive: the API tells you a service has a route and the right
/// answer is still "no".
library;

import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lcc_mobile_app/core/error/failure.dart';
import 'package:lcc_mobile_app/core/usecase/usecase.dart';
import 'package:lcc_mobile_app/features/service/domain/entities/service.dart';
import 'package:lcc_mobile_app/features/service/domain/entities/service_category.dart';
import 'package:lcc_mobile_app/features/service/domain/repositories/service_repository.dart';
import 'package:lcc_mobile_app/features/service/domain/service_availability.dart';
import 'package:lcc_mobile_app/features/service/domain/usecases/get_service_categories.dart';
import 'package:lcc_mobile_app/features/service/domain/usecases/get_services.dart';
import 'package:lcc_mobile_app/utils/routes/app_name_routes.dart';

import '../../../helpers/service_test_helper.dart';

void main() {
  group('AppNameRoutes.registered — the client route registry (C-2)', () {
    test('holds every path constant the class declares', () {
      // A registry that silently misses a route makes `ServiceAvailability`
      // answer "no" for a page that exists. Enumerated against the constants
      // rather than against a hardcoded count.
      expect(AppNameRoutes.registered, <String>{
        AppNameRoutes.home,
        AppNameRoutes.signin,
        AppNameRoutes.service,
        AppNameRoutes.history,
        AppNameRoutes.wallet,
        AppNameRoutes.account,
        AppNameRoutes.help,
        AppNameRoutes.news,
        AppNameRoutes.debug,
      });
    });

    test('mounts NONE of the six certificate sub-routes yet', () {
      // This is the fact that makes every catalogue tap a no-op today. When F1
      // changes it, it changes here first.
      for (final String tab in <String>[
        'resident-certificate',
        'birth-declaration',
        'death-declaration',
        'marriage-certificate',
        'divorce-certificate',
        'family-book',
      ]) {
        expect(AppNameRoutes.registered,
            isNot(contains('${AppNameRoutes.service}/$tab')));
      }
    });
  });

  group('ServiceAvailability.tabOf — routeToTab (ServicePage.tsx:118-122)', () {
    test('takes the last non-empty segment', () {
      expect(ServiceAvailability.tabOf('/service/resident-certificate'),
          'resident-certificate');
      expect(ServiceAvailability.tabOf('/service/family-book/'), 'family-book');
      expect(ServiceAvailability.tabOf('family-book'), 'family-book');
    });

    test('an empty or segment-less path has no tab', () {
      expect(ServiceAvailability.tabOf(''), isNull);
      expect(ServiceAvailability.tabOf('/'), isNull);
      expect(ServiceAvailability.tabOf('///'), isNull);
    });
  });

  group('ServiceAvailability — C-3 and C-4', () {
    late List<Service> catalogue;

    setUp(() => catalogue = recordedServices());

    test('C-4 TODAY: all 43 are unavailable, including the 6 WITH a route_path',
        () {
      const ServiceAvailability availability = ServiceAvailability.forApp;

      final Iterable<Service> withRoute =
          catalogue.where((Service s) => s.routePath.isNotEmpty);
      expect(withRoute, hasLength(6),
          reason: 'measured: 6 of 43 carry a route_path');

      for (final Service s in catalogue) {
        expect(availability.isAvailable(s), isFalse, reason: s.code);
        expect(availability.destinationFor(s), isNull, reason: s.code);
      }
    });

    test('C-3: the answer flips on the CLIENT registry, not on route_path', () {
      // The same six rows, unchanged, against a registry that mounts one of
      // them. Nothing about the data moved; the app did.
      const ServiceAvailability afterF1 = ServiceAvailability(
        registeredRoutes: <String>{'/service/resident-certificate'},
      );

      final Service resident =
          catalogue.firstWhere((Service s) => s.code == 'resident');
      final Service birth =
          catalogue.firstWhere((Service s) => s.code == 'birth');

      expect(afterF1.destinationFor(resident), '/service/resident-certificate');
      expect(afterF1.isAvailable(resident), isTrue);

      // Its five siblings still carry a route_path and are still unavailable.
      expect(birth.routePath, isNotEmpty);
      expect(afterF1.isAvailable(birth), isFalse);
    });

    test('a row with NO route_path is unavailable under any registry', () {
      const ServiceAvailability generous = ServiceAvailability(
        registeredRoutes: <String>{'/service/resident-certificate', '/service'},
      );

      final Service passport =
          catalogue.firstWhere((Service s) => s.code == 'passport');
      expect(passport.routePath, isEmpty);
      expect(generous.destinationFor(passport), isNull);
    });
  });

  group('GetServicesParams', () {
    test('normalises an empty filter to null', () {
      // `search: ''` and `search: null` must not be two spellings of one
      // request that only happen to behave alike downstream.
      final GetServicesParams params =
          GetServicesParams(search: '', category: '');

      expect(params.search, isNull);
      expect(params.category, isNull);
      expect(params, GetServicesParams());
      expect(params, GetServicesParams.all);
    });

    test('keeps a real filter and compares by value', () {
      expect(GetServicesParams(search: 'cert', category: 'civil'),
          GetServicesParams(search: 'cert', category: 'civil'));
      expect(GetServicesParams(search: 'cert'),
          isNot(GetServicesParams(search: 'other')));
      expect(GetServicesParams(search: 'cert').props,
          <Object?>['cert', null]);
    });
  });

  group('the two use cases delegate and nothing more', () {
    test('GetServiceCategories passes NoParams straight through', () async {
      final FakeServiceRepository repository = FakeServiceRepository();
      final GetServiceCategories usecase =
          GetServiceCategories(repository: repository);

      final Either<Failure, List<ServiceCategory>> result =
          await usecase(NoParams());

      expect(result.getOrElse(() => const <ServiceCategory>[]), hasLength(8));
      expect(repository.categoryCalls, 1);
    });

    test('GetServices unpacks its params onto the repository', () async {
      final FakeServiceRepository repository = FakeServiceRepository();
      final GetServices usecase = GetServices(repository: repository);

      await usecase(GetServicesParams(search: 'cert', category: 'civil'));
      await usecase(GetServicesParams.all);

      expect(repository.serviceCalls, <({String? search, String? category})>[
        (search: 'cert', category: 'civil'),
        (search: null, category: null),
      ]);
    });

    test('a repository Left is returned, not unwrapped or thrown', () async {
      final FakeServiceRepository repository = FakeServiceRepository()
        ..failServices();
      final GetServices usecase = GetServices(repository: repository);

      final Either<Failure, List<Service>> result =
          await usecase(GetServicesParams.all);

      expect(result.isLeft(), isTrue);
    });
  });

  group('ServiceRepository contract', () {
    test('both reads are declared, and getServices takes both filters', () {
      // A structural assertion, cheap, and it is the thing that breaks first if
      // someone "simplifies" the contract into one method.
      final ServiceRepository repository = FakeServiceRepository();

      expect(repository.getCategories, isA<Function>());
      expect(
        () => repository.getServices(search: 'a', category: 'b'),
        returnsNormally,
      );
    });
  });
}
