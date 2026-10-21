/// Documents use-case DI — the two B5 lazy singletons (DI-2) plus the two
/// v2 sub-path usecases (file, QR) the 2026-10 guide added. One per
/// repository method; the file/QR pair supersedes the old "exactly two" note
/// the same way the endpoint constants do (see `api_endpoint.dart`'s v2
/// block).
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
      )
      ..registerLazySingleton<GetCertificateQr>(
        () => GetCertificateQr(
          repository: documentsInjection<DocumentsRepository>(),
        ),
      )
      ..registerLazySingleton<DownloadCertificateFile>(
        () => DownloadCertificateFile(
          repository: documentsInjection<DocumentsRepository>(),
        ),
      );
  }
}
