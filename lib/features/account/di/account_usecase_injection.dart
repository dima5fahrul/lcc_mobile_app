/// Account use-case DI — four of its own, plus **three re-exported**: two from
/// the session feature and one from auth.
///
/// ## Why `di/` is in B8b's scope — `specs.md` § 9.11, **Amendment 3**
///
/// B8b's § 3.1 row originally granted
/// `lib/features/account/{data,domain,presentation}/**` and did **not** name
/// `di/`, while B8a's row lists `di/` in its own right — an omission rather
/// than a prohibition. Raised **before** this edit was written, and granted:
/// § 3.1's B8b row now reads `{data,domain,presentation,di}`.
///
/// The reason there was no conforming alternative, in short, so a reader here
/// does not need the spec open:
///
/// * `POST /me/avatar` needs datasource → repository → use case, and
///   [UploadAvatar] must be constructed somewhere.
/// * `AccountProfileBloc` is the only holder of avatar state (the header reads
///   `state.account` and `uploadAvatar.pending` from it) and is constructed in
///   `account_feature_injection.dart`.
/// * **G-L1** (`layering_rules.dart:362`) forbids any `presentation/**` file
///   importing `**/data/**`, so the BLoC cannot reach the repository directly;
///   **G-L5** and `account_scope_test.dart:63-64` forbid a widget naming
///   `accountInjection`, so the widget cannot construct it either.
/// * The only remaining seam is `app_routes.dart`, which § 4.1 puts out of
///   scope and which already carries B8a's one **waived** `B8-AC-9` breach
///   (§ 9.9). Amendment 3's words: breaching it again *"would compound a
///   waiver rather than spend an omission."*
///
/// **The grant is narrow, and this file keeps it narrow.** One registration
/// below plus one constructor argument in `account_feature_injection.dart`, for
/// the avatar path only. No existing registration is modified. **No new
/// container** — Amendment 3 is explicit that it does not license a
/// `GetIt.asNewInstance()`, because a new container obliges a `reset()` in five
/// teardown sites and this programme has shipped that omission before. The
/// grant does not extend to any other feature's `di/`.
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
      // B8b — `POST /me/avatar`, over the same `AccountRepository` as the three
      // above. No new container, no new datasource, and **no new package**:
      // `file_picker` has been in `pubspec.yaml` since F1 (B8-AC-57 as amended
      // 2026-08-19).
      ..registerLazySingleton<UploadAvatar>(
        () => UploadAvatar(
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
