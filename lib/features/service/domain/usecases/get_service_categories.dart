/// `GetServiceCategories` — `GET /service-categories`.
///
/// Thin, like `GetProfile`: the BLoC depends on a usecase rather than the
/// repository so a later cross-cutting concern has one place to hook in.
library;

import 'package:dartz/dartz.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/service_category.dart';
import '../repositories/service_repository.dart';

class GetServiceCategories
    implements UseCase<List<ServiceCategory>, NoParams> {
  const GetServiceCategories({required this.repository});

  final ServiceRepository repository;

  @override
  Future<Either<Failure, List<ServiceCategory>>> call(NoParams params) =>
      repository.getCategories();
}
