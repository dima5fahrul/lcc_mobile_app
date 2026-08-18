/// Family-book use-case DI — one lazy singleton (DI-2) per use case, and there
/// are exactly two.
///
/// Registering them lazily against the same repository instance is what makes
/// the read and the write share one datasource and one `ApiClient`, so a token
/// refreshed on the read is the token the write sends.
library;

import '../domain/repositories/family_book_repository.dart';
import '../domain/usecases/family_book_usecases.dart';
import 'family_book_injection.dart';

class FamilyBookUsecaseInjection {
  static void inject() {
    familyBookInjection
      ..registerLazySingleton<GetFamilyBook>(
        () => GetFamilyBook(
          repository: familyBookInjection<FamilyBookRepository>(),
        ),
      )
      ..registerLazySingleton<RequestFamilyBookCopy>(
        () => RequestFamilyBookCopy(
          repository: familyBookInjection<FamilyBookRepository>(),
        ),
      );
  }
}
