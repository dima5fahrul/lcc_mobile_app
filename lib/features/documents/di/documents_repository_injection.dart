/// Documents repository DI. Lazy (DI-2), over the datasource registered
/// before it.
library;

import '../data/datasources/documents_remote_datasource.dart';
import '../data/repositories/documents_repository_impl.dart';
import '../domain/repositories/documents_repository.dart';
import 'documents_injection.dart';

class DocumentsRepositoryInjection {
  static void inject() {
    documentsInjection.registerLazySingleton<DocumentsRepository>(
      () => DocumentsRepositoryImpl(
        remote: documentsInjection<DocumentsRemoteDatasource>(),
      ),
    );
  }
}
