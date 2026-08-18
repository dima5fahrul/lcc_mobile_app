/// Root dependency-injection scaffold.
///
/// Extends the flutter-boilerplate pattern (`StorageService` → feature
/// injections). Registration order is load-bearing, not cosmetic:
///
///   1. `StorageService`  — everything downstream reads tokens/lang from it.
///   2. `ApiClient`       — owns the configured Dio + Auth/Refresh interceptors,
///                          which resolve `StorageService` when they run.
///   3. `SessionFeatureInjection.init()` — its datasource reaches back into this
///                          container for `ApiClient`.
///   4. `SessionBloc`     — app-wide session state, registered on *this* root
///                          container rather than the session feature's (CR-3:
///                          the router, `main.dart` and three feature pages all
///                          consume it, so it is not feature-scoped). Must come
///                          after step 3 — its closure resolves `GetProfile`
///                          and `SessionRepository` back out of
///                          `sessionInjection`.
///   5. `AuthFeatureInjection.init()`    — last, because the auth flow terminates
///                          in `SessionBloc.add(SessionSignIn(session))`; the
///                          session feature must already be registered when the
///                          first successful login lands.
///
/// Steps 3–5 all register *lazy* singletons, so nothing is actually
/// constructed here — but the plan's ordering is still honoured literally so a
/// later change to an eager registration cannot silently invert the dependency.
///
/// Call [DependencyInjection.init] once at app start, before `runApp`.
library;

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_it/get_it.dart';

import '../../features/account/di/account_feature_injection.dart';
import '../../features/application/di/application_feature_injection.dart';
import '../../features/auth/di/auth_feature_injection.dart';
import '../../features/certificates/di/certificates_feature_injection.dart';
import '../../features/chat/di/chat_feature_injection.dart';
import '../../features/documents/di/documents_feature_injection.dart';
import '../../features/help/di/help_feature_injection.dart';
import '../../features/history/di/history_feature_injection.dart';
import '../../features/home/di/home_feature_injection.dart';
import '../../features/news/di/news_feature_injection.dart';
import '../../features/notifications/di/notifications_feature_injection.dart';
import '../../features/reference/di/reference_feature_injection.dart';
import '../../features/service/di/service_feature_injection.dart';
import '../../features/session/di/session_feature_injection.dart';
import '../../features/session/di/session_injection.dart';
import '../../features/session/domain/repositories/session_repository.dart';
import '../../features/session/domain/usecases/get_profile.dart';
import '../../features/session/domain/usecases/update_profile.dart';
import '../../features/wallet/di/wallet_feature_injection.dart';
import '../network/api_client.dart';
import '../network/dio_network_client.dart';
import '../session/bloc/session_bloc.dart';
import '../storage/storage_service.dart';

final injection = GetIt.instance;

class DependencyInjection {
  /// Public default constructor so boot can call `DependencyInjection().init()`.
  /// The private `._()` form was a leftover from the boilerplate scaffold; the
  /// task's target `main.dart` calls `DependencyInjection().init()`, so expose
  /// a plain constructor here. All real work happens in [init].
  const DependencyInjection();

  /// Register core singletons and every feature container. Call once at boot.
  Future<void> init() async {
    // 1. StorageService — everything else depends on it (tokens, lang).
    injection.registerLazySingleton<StorageService>(
      () => StorageService(const FlutterSecureStorage()),
    );

    // 2. ApiClient — owns the Dio instance with Auth + Refresh interceptors.
    //    ChuckerDioInterceptor is attached in debug builds for network
    //    inspection (per the user's chucker_flutter choice).
    injection.registerLazySingleton<ApiClient>(
      () => ApiClient(
        dio: buildDio(
          storage: injection<StorageService>(),
          extraInterceptors: debugInterceptors(),
        ),
        storage: injection<StorageService>(),
      ),
    );

    // 3. Session feature — owns its datasources, repos and usecases. Must init
    //    AFTER StorageService + ApiClient (its datasource resolves
    //    `injection<ApiClient>()`).
    await SessionFeatureInjection.init();

    // 4. SessionBloc — app-wide, so it lives on the ROOT container (CR-3), not
    //    on `sessionInjection`. It is consumed by the router, `main.dart` and
    //    the home / auth / account pages; scoping it to the session feature's
    //    container misrepresented it as feature-local.
    //
    //    ── F-2 fix (GOR-245 § 2.2) ─────────────────────────────────────────
    //    `registerFactory` handed out a NEW `SessionBloc` on every resolution.
    //    The router (`AppRoutes.build`) wires `refreshListenable` and reads
    //    `state.status` on the instance it is given, while the widget tree
    //    resolves its own — two BLoCs, one of them never dispatched to, so the
    //    auth gate would sit on `SessionStatus.initial` forever and never fire.
    //
    //    `registerLazySingleton` is the fix rather than "resolve once in
    //    `main.dart` and pass the reference around": both give the router and
    //    the tree the same object today, but only this one makes it
    //    *impossible* for a future call site to resolve a second one by
    //    accident. The invariant GOR-245 states — exactly one `SessionBloc`
    //    for the app's lifetime — then holds by construction instead of by
    //    discipline. `main.dart` still resolves it once and passes it
    //    explicitly, so the ownership is readable at the call site too; the
    //    singleton is the belt, the parameter is the braces.
    //
    //    Lifetime: the container outlives the app, so the BLoC is never
    //    closed. That is correct for a session that must survive every route
    //    change — and it is why `main.dart` uses `BlocProvider.value` (which
    //    does not close what it did not create) instead of
    //    `BlocProvider(create:)`.
    //
    //    Registered AFTER step 3: the closure reaches into `sessionInjection`
    //    for `GetProfile` / `SessionRepository`. All registrations are lazy,
    //    so a wrong order here would not fail at registration — it would fail
    //    at first resolution, i.e. at app boot.
    injection.registerLazySingleton<SessionBloc>(
      () => SessionBloc(
        storage: injection<StorageService>(),
        getProfile: sessionInjection<GetProfile>(),
        repository: sessionInjection<SessionRepository>(),
        // B8a — R-25's `PATCH /me/profile {preferred_lang}` mirror. Same
        // container, same lazy resolution as the two above.
        updateProfile: sessionInjection<UpdateProfile>(),
      ),
    );

    // 5. Auth feature (defect F-3). Without this line `authInjection` is empty,
    //    `AuthPage.initState`'s `authInjection<AuthBloc>()` throws, and the
    //    whole 51-file auth feature is dead code no matter what the router
    //    points at. Registered last: `AuthPage` completes a login by handing
    //    the `CitizenSession` to `SessionBloc`, so the session container is a
    //    prerequisite of the auth flow, not the other way round.
    //
    //    `AuthDatasourceInjection` re-exports the root `ApiClient` into
    //    `authInjection` via `() => injection<ApiClient>()` — verified by
    //    reading `features/auth/di/auth_datasource_injection.dart`, which is
    //    why step 2 must precede this and why the auth container does NOT
    //    build a second Dio. Note the deliberate asymmetry with step 4:
    //    `SessionBloc` is a root `registerLazySingleton` (one session for the
    //    app's lifetime, F-2), whereas `AuthFeatureInjection` keeps a
    //    feature-scoped `registerFactory<AuthBloc>` — correct, because an auth
    //    attempt is scoped to one visit to /signin.
    //    See the provider note in `auth_page.dart`.
    await AuthFeatureInjection.init();

    // 6. Service catalogue (DI-6, B2a). One line, as the rule requires.
    //
    //    Ordering: anywhere after step 2. The catalogue is anonymous —
    //    `endpoints.ts` marks both its endpoints `anonymous: true` — so unlike
    //    the auth feature it has no dependency on the session being registered
    //    and no dependency the session has on it. It sits last because that is
    //    where a feature with no ordering constraint should sit: appending is
    //    the change that cannot break the four steps above.
    await ServiceFeatureInjection.init();

    // 7. Home (DI-6, B2b). One line, as the rule requires.
    //
    //    Ordering: after step 2 for the shared `ApiClient`, and after step 4
    //    in practice because the `/` route builder reads `SessionBloc` to tell
    //    `HomeBloc` whether the two `me.*` reads are enabled. No registration
    //    here resolves the session, so this is a navigation-time dependency
    //    rather than a wiring one — appending keeps it satisfied without
    //    making the six steps above depend on it.
    await HomeFeatureInjection.init();

    // 8. News (DI-6, B2c). One line, as the rule requires.
    //
    //    Ordering: anywhere after step 2. All four of its endpoints are
    //    `anonymous: true`, so — like the service catalogue and unlike Home —
    //    it has no dependency on the session being registered and none the
    //    session has on it. Appended for the reason step 6 gives: appending is
    //    the change that cannot break the steps above.
    await NewsFeatureInjection.init();

    // 9. Help (DI-6, B2c). One line.
    //
    //    Ordering: after step 2 for the shared `ApiClient`. Help makes B2's one
    //    authenticated write (`POST /help/faqs/<id>/feedback`), so it needs the
    //    Auth/Refresh interceptor chain that lives inside the root client —
    //    which is a dependency on step 2's *instance*, not on the session
    //    feature's registrations, and is satisfied by re-exporting the same
    //    `ApiClient` rather than by ordering against step 3.
    await HelpFeatureInjection.init();

    // 10. Notifications (DI-6, B9a). One line, as the rule requires.
    //
    //     Ordering: after step 2 for the shared `ApiClient`. All four of its
    //     endpoints are authenticated `/me/*` calls — none carries
    //     `anonymous: true` — so, like Help, it needs the Auth/Refresh
    //     interceptor chain that lives inside the root client. That is a
    //     dependency on step 2's *instance*, satisfied by re-exporting the same
    //     `ApiClient`, not on the session feature's registrations, so no
    //     ordering against step 3 is required.
    //
    //     Appended for the reason step 6 gives: appending is the change that
    //     cannot break the steps above. Alphabetical among the feature block
    //     too, which DI-6 asks for and which happens to hold here — B9b's
    //     `chat` is the one that will have to break it, because its container
    //     reaches into `helpInjection` for `GetSupportChannels` (§ 6.6).
    await NotificationsFeatureInjection.init();

    // 11. Chat (DI-6, B9b). One line, as the rule requires — **and it is the
    //     one line that is deliberately not alphabetical.**
    //
    //     Ordering: **after step 9 (Help), and that is a hard requirement, not
    //     a preference.** `ChatUsecaseInjection` re-exports
    //     `GetSupportChannels` out of `helpInjection` rather than
    //     re-implementing `/help/channels` (specs.md § 6.6, B9-AC-43), so this
    //     container's registrations close over another container's. DI-6's
    //     "one alphabetical line" would put `chat` before `help` and break it.
    //     **The alphabetical rule yields here and the deviation is stated at
    //     the call site**, which is what § 6.6 requires and what steps 3-5
    //     above already do for their own non-obvious ordering.
    //
    //     The registration is lazy, so a wrong order would not fail here — it
    //     would fail at the first resolution, i.e. the first time a citizen
    //     taps the launcher. `chat_injection_test.dart` asserts the order
    //     rather than trusting the comment.
    //
    //     Like Help and Notifications, all six of its endpoints are
    //     authenticated `/me/*` calls, so it needs step 2's *instance* of
    //     `ApiClient` for the Auth/Refresh interceptor chain — satisfied by
    //     re-exporting the same client, not by ordering against step 3.
    await ChatFeatureInjection.init();

    // 12. Account (DI-6, B8a). One line, as the rule requires — **and the
    //     second one that is deliberately not alphabetical.**
    //
    //     Ordering: **after step 3 (Session) AND after step 5 (Auth), and both
    //     are hard requirements, not preferences.** `AccountUsecaseInjection`
    //     re-exports `GetProfile` / `UpdateProfile` out of `sessionInjection`
    //     and `ChangePassword` out of `authInjection` rather than adding a
    //     second `PATCH /me/profile` and a second `POST /auth/change-password`
    //     (specs.md § 6.3, B8-AC-7). So this container's registrations close
    //     over two other containers'. DI-6's "one alphabetical line" would put
    //     `account` first, before either of them, and break both.
    //     **The alphabetical rule yields here and the deviation is stated at
    //     the call site**, which is what step 11 already does for chat.
    //
    //     The registrations are lazy, so a wrong order would not fail here — it
    //     would fail at the first resolution, i.e. the first time a citizen
    //     opens the account tab. `account_injection_test.dart` asserts the
    //     order rather than trusting this comment.
    //
    //     All three of its own endpoints are authenticated `/me/*` calls, so it
    //     needs step 2's *instance* of `ApiClient` for the Auth/Refresh
    //     interceptor chain — satisfied by re-exporting the same client.
    await AccountFeatureInjection.init();

    // 13. Reference / lookup layer (DI-6, F0b). One line, as the rule requires
    //     — **and this one really is alphabetical-agnostic**, unlike steps 11
    //     and 12.
    //
    //     Ordering: anywhere after step 2. All four of its endpoints carry
    //     `anonymous: true` in `endpoints.ts` (`:186`, `:216`, `:223`, `:248`),
    //     so — like the service catalogue and news — it has no dependency on
    //     the session being registered and none the session has on it, and it
    //     closes over no other feature's container. Appended for the reason
    //     step 6 gives: appending is the change that cannot break the steps
    //     above.
    //
    //     It registers **no BLoC**: `features/reference/` is page-less
    //     (`ssd.md` § 11.1, `F0-AC-52`). The certificate page BLoCs F1 builds
    //     resolve `GetLookupOptions` out of `referenceInjection` through their
    //     route builders, which is the only sanctioned place to resolve from a
    //     container (CR-1, G-L5).
    await ReferenceFeatureInjection.init();

    // 14. The application read slice, and 15. the history list (DI-6, B7a).
    //     **Two lines, and their order is a real constraint, not a
    //     convention.** `HistoryUsecaseInjection` resolves `ListApplications`
    //     and `GetStatusPipeline` out of `applicationInjection` through
    //     closures — the `ChatUsecaseInjection` → `helpInjection` shape — so
    //     step 14 must precede step 15.
    //
    //     Unlike steps 11 and 12, **no DI-6 deviation arises**: `application`
    //     sorts before `history`, so the alphabetical placement the rule asks
    //     for and the dependency the code has are the same order. Recorded
    //     because the two previous cross-container registrations both had to
    //     state a deviation here, and the absence of one is the thing a
    //     reader will look for.
    //
    //     Step 14 registers **no BLoC**: `features/application/` is page-less
    //     (specs.md § 6.2, `B7-AC-10`), the second such feature after step 13's.
    //     Four features consume its `domain/**`; none may reach its `data/`.
    //     Ordering otherwise: anywhere after step 2. `/applications` is a
    //     Bearer call, but that is a dependency on step 2's *instance* — the
    //     interceptors hang off the client — not on the session container.
    await ApplicationFeatureInjection.init();
    await HistoryFeatureInjection.init();

    // 16. The wallet (DI-6, B6a). One line, one whole feature.
    //
    //     **No cross-container closure, so no ordering constraint beyond step
    //     2.** Unlike steps 11, 12, 13 and 15, `walletInjection` resolves
    //     nothing out of another feature's container: all six use cases hang
    //     off `WalletRepository`, which hangs off the wallet's own datasource,
    //     which re-exports the root `ApiClient` (step 2). Recorded explicitly
    //     because the four preceding registrations each had to state a
    //     dependency here and a reader will look for this one's.
    //
    //     `features/application/` is deliberately NOT consumed. The bills-due
    //     card renders its empty branch only in B6a; the populated branch and
    //     the `ListApplications` closure over `applicationInjection` are B6b's
    //     (specs.md § 2.3, § 3.1). Step 14 landing first does not license
    //     reaching for it early.
    //
    //     Alphabetically `wallet` sorts last of the sixteen, so DI-6's
    //     ordering rule and the append-only constraint on this file agree; no
    //     deviation to record.
    await WalletFeatureInjection.init();

    // 17. Certificates (DI-6, F1). One line — **and the third that is
    //     deliberately not alphabetical.**
    //
    //     Ordering: **after step 13 (Reference), step 14 (Application), step 6
    //     (Service) and step 16 (Wallet), and all four are hard requirements.**
    //     `CertificatesBlocInjection` builds `ResidentFormCubit` out of
    //     `GetLookupOptions`, the four write usecases, `GetServices` and
    //     `GetPaymentMethods` — four containers, resolved through closures,
    //     which is the `ChatUsecaseInjection` -> `helpInjection` shape and the
    //     only sanctioned cross-container form (`ssd.md` § 5.1). DI-6's "one
    //     alphabetical line" would put `certificates` before every one of them
    //     and break all four. **The alphabetical rule yields and the deviation
    //     is stated here**, as steps 11 and 12 already do for theirs.
    //
    //     It registers **no repository and no datasource**: `features/certificates/`
    //     has no `data/` and must not grow one (`F1-AC-17`). The wire work is
    //     step 14's. That makes this the first feature in the tree that is
    //     BLoC-only — the exact inverse of steps 13 and 14, which are
    //     page-less.
    //
    //     The registration is a **factory**, not a lazy singleton, and that is
    //     the one DI-2 exception in this file besides `AuthBloc`'s. See
    //     `certificates_bloc_injection.dart` for why a shared submission state
    //     would PATCH the previous citizen's case.
    await CertificatesFeatureInjection.init();

    // 18. Documents — the collection slice (DI-6, B5). One line, as the rule
    //     requires.
    //
    //     **Ordering: after step 2, and appended AFTER step 15 (History) even
    //     though History resolves out of this container.** That reads
    //     backwards, so it is stated rather than left to a reader:
    //     `HistoryUsecaseInjection` *registers* two `registerLazySingleton`
    //     closures over `documentsInjection`, and registering a closure does
    //     not invoke it. The first resolution happens when `HistoryDetailBloc`
    //     is constructed, which is in the `/history` route builder — long after
    //     `init()` has returned. So the constraint the other cross-container
    //     steps have (11 chat→help, 12 account→session/auth, 15 history→
    //     application, 17 certificates→four) does not apply in this direction,
    //     and appending keeps this file's own rule: appending is the change
    //     that cannot break the steps above.
    //
    //     `history_documents_injection_test.dart` **resolves `HistoryDetailBloc`
    //     end to end** rather than trusting this paragraph (`B5-AC-33`,
    //     specs.md NV-5). Moving this line above step 15 would also be correct;
    //     the test is what makes either placement provable instead of assumed.
    //
    //     It registers **no BLoC**: `features/documents/` is page-less, the
    //     third such feature after steps 13 and 14. B5 creates no route and no
    //     page; its widgets live in `lib/presentation/documents/` and are
    //     composed in `app_routes.dart`.
    //
    //     Both of its endpoints are authenticated `/me/*` reads, so — like
    //     Help, Notifications and Chat — it needs step 2's *instance* of
    //     `ApiClient` for the Auth/Refresh interceptor chain, satisfied by
    //     re-exporting the same client rather than by ordering against step 3.
    await DocumentsFeatureInjection.init();
  }
}
