/// Wallet use-case DI — **nine** lazy singletons (DI-2), one per use case, plus
/// one re-exported from `applicationInjection`.
///
/// [GetTransaction] is registered even though nothing under `presentation/`
/// resolves it (`B6-AC-15`). specs.md § 6.4 rules the *transport* in and the UI
/// out; leaving it unregistered would make the endpoint reachable only by
/// constructing the use case by hand, which is a different thing from "ported
/// and unused" and would make B7's first use of it a change to this file rather
/// than a call.
///
/// ## B6b: `/applications` is REUSED, not re-implemented (specs.md § 2.3)
///
/// The Bills Due card reads `GET /applications/?page=1&per_page=50`
/// (`WalletPage.tsx:104-108`). **B7a already parses that endpoint** — its
/// `features/application/` slice is page-less precisely so four other features
/// can consume it — so B6b adds no endpoint constant for the read, no second
/// wire mapping and no second datasource. v1.0 of the spec put one here; v1.1
/// amended it once B7a was sequenced first, because two datasources for one
/// endpoint is **not** SSD § 4.3's *"wire-format duplication is the accepted
/// cost"* case (that clause covers two features parsing the same JSON; here one
/// shared feature already parses it).
///
/// `features/wallet/**` may not import `features/application/data/**` (G-L3)
/// and does not need to: the closure below resolves out of the other container
/// against the **domain interface**, exactly as
/// `ChatUsecaseInjection`'s `GetSupportChannels` re-export does over
/// `helpInjection`, and as `AuthDatasourceInjection` does over the root. One
/// `ListApplications`, one `ApplicationRepository`, one parse.
///
/// **This is the ordering constraint.** The closure reaches into
/// `applicationInjection`, so `ApplicationFeatureInjection.init()` must have
/// run first — `DependencyInjection.init()` step 14, before step 16. Unlike
/// chat/help, **no DI-6 deviation is required**: `application` precedes
/// `wallet` alphabetically, so the necessary order *is* the alphabetical one,
/// and § 2.3 says so in as many words. `wallet_injection_test.dart` asserts the
/// resolution rather than trusting this comment.
///
/// [PayApplication] is registered here too and is a **published cross-batch
/// surface** (§ 6.3): F1, F2, F3 and B7 resolve it out of `walletInjection`
/// rather than writing a second pay path. Its doc comment names them.
library;

import '../../application/di/application_injection.dart';
import '../../application/domain/usecases/application_usecases.dart';
import '../domain/repositories/wallet_repository.dart';
import '../domain/usecases/list_pending_bills.dart';
import '../domain/usecases/pay_application.dart';
import '../domain/usecases/wallet_usecases.dart';
import 'wallet_injection.dart';

class WalletUsecaseInjection {
  static void inject() {
    walletInjection
      ..registerLazySingleton<GetWalletOverview>(
        () =>
            GetWalletOverview(repository: walletInjection<WalletRepository>()),
      )
      ..registerLazySingleton<GetWalletEntries>(
        () => GetWalletEntries(repository: walletInjection<WalletRepository>()),
      )
      ..registerLazySingleton<GetTransactions>(
        () => GetTransactions(repository: walletInjection<WalletRepository>()),
      )
      ..registerLazySingleton<GetTransaction>(
        () => GetTransaction(repository: walletInjection<WalletRepository>()),
      )
      ..registerLazySingleton<TopUpWallet>(
        () => TopUpWallet(repository: walletInjection<WalletRepository>()),
      )
      ..registerLazySingleton<GetPaymentMethods>(
        () =>
            GetPaymentMethods(repository: walletInjection<WalletRepository>()),
      )
      // ── B6b ────────────────────────────────────────────────────────────────
      //
      // The closure is the whole mechanism described in this file's library
      // doc: `ListApplications` is resolved **out of `applicationInjection`**,
      // lazily, against the domain interface. Lazily matters — the closure body
      // runs on first resolve, not on `inject()`, so this registration does not
      // itself require `ApplicationFeatureInjection.init()` to have run yet;
      // only the first `walletInjection<ListPendingBills>()` does. That is what
      // makes the same code correct in production (step 14 before step 16) and
      // in `app_test_harness.dart`, where the wallet block is written above the
      // application block.
      ..registerLazySingleton<ListPendingBills>(
        () => ListPendingBills(
          listApplications: applicationInjection<ListApplications>(),
        ),
      )
      ..registerLazySingleton<PayApplication>(
        () => PayApplication(repository: walletInjection<WalletRepository>()),
      );
  }
}
