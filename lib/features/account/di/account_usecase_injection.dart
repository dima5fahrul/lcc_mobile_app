/// Account use-case DI — three of its own, plus **two re-exported**: one from
/// the session feature and one from auth.
///
/// ## `PATCH /me/profile` and `POST /auth/change-password` are REUSED
///
/// specs.md § 6.3 puts the profile write on `features/session/` (which already
/// owns `GET /me/profile`) and the credential write on `features/auth/` (whose
/// endpoint constant already sits in the auth block). So the account feature
/// adds **no endpoint constant and no wire mapping** for either.
///
/// Cross-Feature Isolation (SSD § 4.3) permits `features/A →
/// features/B/domain/**`, and **G-L3 measures precisely that boundary and
/// allows it**. The account feature parses nothing here — it consumes two
/// domain use cases, which § 4.3 describes as the correct shared-currency case,
/// as distinct from the *wire-format* duplication that section accepts as a
/// cost.
///
/// The re-exports follow `ChatUsecaseInjection`'s precedent verbatim: closures
/// over the other containers, so there is exactly one `UpdateProfile` behind
/// one `SessionRepository` and one `ChangePassword` behind one
/// `AuthRepository`.
///
/// **This is the ordering constraint** `account_feature_injection.dart` and
/// `DependencyInjection.init()`'s step 12 both document: the two closures below
/// reach into `sessionInjection` and `authInjection`, so
/// `SessionFeatureInjection.init()` and `AuthFeatureInjection.init()` must both
/// have run first. Registration is lazy, so a wrong order would not fail
/// here — it would fail the first time a citizen opens the account tab.
/// `account_injection_test.dart` asserts the order rather than trusting this
/// comment.
library;

import '../../auth/di/auth_injection.dart';
import '../../auth/domain/usecases/change_password.dart';
import '../../session/di/session_injection.dart';
import '../../session/domain/usecases/get_profile.dart';
import '../../session/domain/usecases/update_profile.dart';
import '../domain/repositories/account_repository.dart';
import '../domain/usecases/account_usecases.dart';
import 'account_injection.dart';

class AccountUsecaseInjection {
  static void inject() {
    accountInjection
      ..registerLazySingleton<GetPreferences>(
        () => GetPreferences(
          repository: accountInjection<AccountRepository>(),
        ),
      )
      ..registerLazySingleton<SavePreferences>(
        () => SavePreferences(
          repository: accountInjection<AccountRepository>(),
        ),
      )
      ..registerLazySingleton<GetDocuments>(
        () => GetDocuments(
          repository: accountInjection<AccountRepository>(),
        ),
      )
      // Re-exported, not re-implemented — see the library doc.
      //
      // `GetProfile` as well as `UpdateProfile`: `AccountPage.tsx:189` runs its
      // own `me.profile` query rather than reading the session's, because the
      // page needs `uin`, `phone`, `email`, `address` and `verified` and the
      // session projection (`CitizenProfileData`) carries only name and avatar.
      ..registerLazySingleton<GetProfile>(
        () => sessionInjection<GetProfile>(),
      )
      ..registerLazySingleton<UpdateProfile>(
        () => sessionInjection<UpdateProfile>(),
      )
      ..registerLazySingleton<ChangePassword>(
        () => authInjection<ChangePassword>(),
      );
  }
}
