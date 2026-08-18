/// Reference use-case DI — lazy singletons (DI-2).
///
/// Three now: `GetLookupOptions` (F0) plus F3's two record-picker reads.
library;

import '../domain/repositories/prerequisite_record_repository.dart';
import '../domain/repositories/reference_repository.dart';
import '../domain/usecases/get_lookup_options.dart';
import '../domain/usecases/get_prerequisite_records.dart';
import 'reference_injection.dart';

class ReferenceUsecaseInjection {
  static void inject() {
    referenceInjection
      ..registerLazySingleton<GetLookupOptions>(
        () => GetLookupOptions(
          repository: referenceInjection<ReferenceRepository>(),
        ),
      )
      ..registerLazySingleton<GetPrerequisiteRecords>(
        () => GetPrerequisiteRecords(
          repository: referenceInjection<PrerequisiteRecordRepository>(),
        ),
      )
      ..registerLazySingleton<GetPrerequisiteRecord>(
        () => GetPrerequisiteRecord(
          repository: referenceInjection<PrerequisiteRecordRepository>(),
        ),
      );
  }
}
