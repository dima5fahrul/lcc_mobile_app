/// Documents use-case DI — two lazy singletons (DI-2), one per surviving
/// endpoint. A third would be out of scope (`B5-AC-32`).
library;

import '../domain/repositories/documents_repository.dart';
import '../domain/usecases/documents_usecases.dart';
import 'documents_injection.dart';

class DocumentsUsecaseInjection {
  static void inject() {
    documentsInjection
      ..registerLazySingleton<GetCertificates>(
        () => GetCertificates(
          repository: documentsInjection<DocumentsRepository>(),
        ),
      )
      ..registerLazySingleton<GetCertificate>(
        () => GetCertificate(
          repository: documentsInjection<DocumentsRepository>(),
        ),
      );
  }
}
