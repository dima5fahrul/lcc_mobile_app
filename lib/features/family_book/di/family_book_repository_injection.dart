/// Family-book repository DI. Lazy (DI-2), over the datasource registered
/// before it.
///
/// Registered against **`FamilyBookRepository`, the interface** — the pattern
/// `help_repository_injection.dart:11` sets and `application_repository_injection.dart`
/// argues for. It matters here for the same forward-looking reason: a
/// registration typed on the impl would make any future cross-container
/// consumer depend on `features/family_book/data/**`, which G-L3 forbids.
library;

import '../data/datasources/family_book_remote_datasource.dart';
import '../data/repositories/family_book_repository_impl.dart';
import '../domain/repositories/family_book_repository.dart';
import 'family_book_injection.dart';

class FamilyBookRepositoryInjection {
  static void inject() {
    familyBookInjection.registerLazySingleton<FamilyBookRepository>(
      () => FamilyBookRepositoryImpl(
        remote: familyBookInjection<FamilyBookRemoteDatasource>(),
      ),
    );
  }
}
