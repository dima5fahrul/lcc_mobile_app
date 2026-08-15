/// The wallet's DI, and the cross-container closure B6b introduces.
///
/// specs.md § 2.3 names this file and says why it exists rather than a comment:
/// *"`ChatUsecaseInjection` … resolves `GetSupportChannels` out of
/// `helpInjection` through a closure over the other container, registered
/// against the **domain interface**, with the ordering requirement stated at
/// the call site and **asserted by `chat_injection_test.dart` rather than
/// trusted to a comment**. B6b takes the same shape against
/// `applicationInjection`."*
///
/// So every registration is **resolved** here, not checked for presence.
/// `isRegistered` returns true for a factory that throws the instant it runs,
/// and this feature's `ListPendingBills` reaches into a second container — a
/// presence check is precisely the check that would miss it.
///
/// ## The ordering, and why it needs no DI-6 deviation
///
/// Unlike chat/help, **`application` precedes `wallet` alphabetically**, so the
/// order `DependencyInjection.init()` already runs *is* the order this closure
/// needs. That is a claim about the real container graph, so the last group
/// below boots the real one and resolves through it rather than asserting the
/// alphabet.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:lcc_mobile_app/core/di/dependency_injection.dart';
import 'package:lcc_mobile_app/core/network/api_client.dart';
import 'package:lcc_mobile_app/core/storage/storage_service.dart';
import 'package:lcc_mobile_app/features/application/di/application_feature_injection.dart';
import 'package:lcc_mobile_app/features/application/di/application_injection.dart';
import 'package:lcc_mobile_app/features/application/domain/usecases/application_usecases.dart';
import 'package:lcc_mobile_app/features/wallet/data/datasources/wallet_remote_datasource.dart';
import 'package:lcc_mobile_app/features/wallet/di/wallet_feature_injection.dart';
import 'package:lcc_mobile_app/features/wallet/di/wallet_injection.dart';
import 'package:lcc_mobile_app/features/wallet/domain/repositories/wallet_repository.dart';
import 'package:lcc_mobile_app/features/wallet/domain/usecases/list_pending_bills.dart';
import 'package:lcc_mobile_app/features/wallet/domain/usecases/pay_application.dart';
import 'package:lcc_mobile_app/features/wallet/domain/usecases/wallet_usecases.dart';
import 'package:lcc_mobile_app/features/wallet/presentation/bloc/wallet_bloc.dart';

import '../../../helpers/core_test_helper.dart';

void main() {
  Future<void> registerRoot() async {
    injection.registerLazySingleton<StorageService>(
      () => inMemoryStorageService(<String, String>{}),
    );
    injection.registerLazySingleton<ApiClient>(
      () => ApiClient(
        dio: buildTestDio(
          storage: injection<StorageService>(),
          adapter: RecordingHttpAdapter.always(<String, dynamic>{}),
          withInterceptors: false,
        ),
        storage: injection<StorageService>(),
      ),
    );
  }

  Future<void> resetAll() async {
    await injection.reset();
    await applicationInjection.reset();
    await walletInjection.reset();
  }

  setUp(() async {
    await resetAll();
    await registerRoot();
  });

  tearDown(resetAll);

  group('with application registered first — the production order', () {
    setUp(() async {
      await ApplicationFeatureInjection.init();
      await WalletFeatureInjection.init();
    });

    test('DI-3 — the feature shares the ROOT ApiClient', () {
      expect(walletInjection<ApiClient>(), same(injection<ApiClient>()));
    });

    test('DI-2 — every registration resolves, B6b\'s two included', () {
      expect(
        walletInjection<WalletRemoteDatasource>(),
        isA<WalletRemoteDatasourceImpl>(),
      );
      expect(walletInjection<WalletRepository>(), isA<WalletRepository>());
      expect(walletInjection<GetWalletOverview>(), isA<GetWalletOverview>());
      expect(walletInjection<GetWalletEntries>(), isA<GetWalletEntries>());
      expect(walletInjection<GetTransactions>(), isA<GetTransactions>());
      expect(walletInjection<GetTransaction>(), isA<GetTransaction>());
      expect(walletInjection<TopUpWallet>(), isA<TopUpWallet>());
      expect(walletInjection<GetPaymentMethods>(), isA<GetPaymentMethods>());
      // B6b.
      expect(walletInjection<ListPendingBills>(), isA<ListPendingBills>());
      expect(walletInjection<PayApplication>(), isA<PayApplication>());
    });

    test('§ 2.3 — ListPendingBills composes the SAME ListApplications the '
        'application container holds', () {
      // `same`, not `isA`. A second instance would mean a second
      // `ApplicationRepository`, a second parse of `/applications`, and exactly
      // the duplicate datasource v1.0 of the spec would have created. That is
      // the whole amendment at v1.1, and this is the assertion that holds it.
      expect(
        walletInjection<ListPendingBills>().listApplications,
        same(applicationInjection<ListApplications>()),
      );
    });

    test('and it does NOT hold a wallet repository — the read is not the '
        'wallet\'s', () {
      // The pay POST is the wallet's write; the Bills Due read is B7a's. The
      // two use cases are deliberately built from different things, and a
      // `ListPendingBills` that took a `WalletRepository` would be the second
      // datasource wearing a different name.
      expect(
        walletInjection<PayApplication>().repository,
        same(walletInjection<WalletRepository>()),
      );
    });

    test('the use cases are SINGLETONS — resolving twice gives one object', () {
      expect(
        walletInjection<ListPendingBills>(),
        same(walletInjection<ListPendingBills>()),
      );
      expect(
        walletInjection<PayApplication>(),
        same(walletInjection<PayApplication>()),
      );
    });

    test(
      'the BLoC is a FACTORY — one visit\'s money never outlives the visit',
      () {
        final WalletBloc first = walletInjection<WalletBloc>();
        final WalletBloc second = walletInjection<WalletBloc>();
        addTearDown(first.close);
        addTearDown(second.close);

        expect(first, isNot(same(second)));
      },
    );

    test('the BLoC actually CONSTRUCTS, and its bills use case is the '
        'cross-container one', () {
      // The check `isRegistered` cannot make. Resolving the BLoC is what runs
      // the closure that reaches into `applicationInjection`.
      final WalletBloc bloc = walletInjection<WalletBloc>();
      addTearDown(bloc.close);

      expect(
        bloc.listPendingBills.listApplications,
        same(applicationInjection<ListApplications>()),
      );
      expect(bloc.payApplication, same(walletInjection<PayApplication>()));
      expect(bloc.state, const WalletState());
    });
  });

  group('the ordering constraint', () {
    test('wallet BEFORE application registers fine and THROWS on first '
        'resolve — which is why it is asserted, not commented', () async {
      // Deliberately the wrong order. Nothing fails here: the closure is lazy,
      // which is the same trap `chat_injection_test.dart` documents.
      await WalletFeatureInjection.init();
      expect(
        walletInjection.isRegistered<WalletBloc>(),
        isTrue,
        reason: 'registration succeeds — this is the trap',
      );
      expect(walletInjection.isRegistered<ListPendingBills>(), isTrue);

      // The failure lands on the first citizen who opens the wallet.
      expect(() => walletInjection<ListPendingBills>(), throwsA(isA<Error>()));
    });

    test('the REAL DependencyInjection.init() satisfies it with no DI-6 '
        'deviation — the alphabet already puts application first', () async {
      // The end-to-end check. § 2.3 claims the necessary order *is* the
      // alphabetical one; this boots the real graph and resolves the thing that
      // depends on it, rather than asserting a claim about letters.
      await resetAll();
      await const DependencyInjection().init();
      addTearDown(resetAll);

      final WalletBloc bloc = walletInjection<WalletBloc>();
      addTearDown(bloc.close);

      expect(
        bloc.listPendingBills.listApplications,
        same(applicationInjection<ListApplications>()),
      );
    });
  });
}
