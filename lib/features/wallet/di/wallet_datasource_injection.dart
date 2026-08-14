/// Wallet datasource DI.
///
/// Re-registers the root [ApiClient] into [walletInjection] — the *same
/// instance*, a closure over `injection<ApiClient>()`, not a second client
/// (DI-3). Load-bearing rather than tidy: five of the wallet's six calls are
/// authenticated and need the Auth/Refresh interceptor chain that lives inside
/// the root client, and the sixth (`/payment-methods`) needs the *same* client
/// to carry `anonymous: true` through `RequestOptions.extra` so that chain
/// skips it. A second Dio would give the anonymous call a different interceptor
/// stack and would also give `chucker_flutter` a second, ungated capture path —
/// security-review item 3 asserts neither happened.
library;

import '../../../core/di/dependency_injection.dart';
import '../../../core/network/api_client.dart';
import '../data/datasources/wallet_remote_datasource.dart';
import 'wallet_injection.dart';

class WalletDatasourceInjection {
  static void inject() {
    walletInjection
      ..registerLazySingleton<ApiClient>(() => injection<ApiClient>())
      ..registerLazySingleton<WalletRemoteDatasource>(
        () => WalletRemoteDatasourceImpl(
          apiClient: walletInjection<ApiClient>(),
        ),
      );
  }
}
