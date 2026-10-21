/// Verify feature injection entry point.
///
/// Ordering inside: datasource → repository → usecase, mirroring
/// `DocumentsFeatureInjection.init()`.
///
/// ## It registers no BLoC — Task 4 does
///
/// Task 3 is the domain+data slice only: endpoints, entity, parser,
/// datasource, repository, usecases, and this container. Task 4 wires
/// [VerifyFeatureInjection.init] into `DependencyInjection.init()` and builds
/// the bloc/pages/routes on top; until then the feature is page-less, like
/// `features/documents/` was after B5.
library;

import 'verify_datasource_injection.dart';
import 'verify_repository_injection.dart';
import 'verify_usecase_injection.dart';

class VerifyFeatureInjection {
  static Future<void> init() async {
    VerifyDatasourceInjection.inject();
    VerifyRepositoryInjection.inject();
    VerifyUsecaseInjection.inject();
  }
}
