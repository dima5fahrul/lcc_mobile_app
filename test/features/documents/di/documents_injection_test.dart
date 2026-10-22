/// Documents DI — **B5-AC-33**, **B5-AC-34**, and NV-5.
///
/// specs.md NV-5 left one thing unverified: *"Whether
/// `DocumentsFeatureInjection.init()` must precede `HistoryFeatureInjection.init()`."*
/// `B5-AC-33` refuses to let that be assumed — *"it seemed to work" is not
/// evidence* — so this file **resolves `HistoryDetailBloc` end to end** from the
/// real `DependencyInjection().init()`, which is the only thing that can be
/// wrong if the order is wrong.
///
/// The answer, measured here rather than argued: **the order does not
/// constrain registration**, because `HistoryUsecaseInjection` registers
/// *closures* over `documentsInjection` and registering a closure does not
/// invoke it. `dependency_injection.dart` step 18 appends after History and
/// states that; this test is what makes the statement checkable, and it would
/// fail the moment someone made either side eager.
///
/// The shape is `news_injection_test.dart`'s, including its tearDown: a feature
/// container that nothing resets makes the *next* test in the run fail with
/// `Type ApiClient is already registered inside GetIt`, which names the wrong
/// culprit.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:lcc_mobile_app/core/di/dependency_injection.dart';
import 'package:lcc_mobile_app/core/network/api_client.dart';
import 'package:lcc_mobile_app/features/account/di/account_injection.dart';
import 'package:lcc_mobile_app/features/application/di/application_injection.dart';
import 'package:lcc_mobile_app/features/auth/di/auth_injection.dart';
import 'package:lcc_mobile_app/features/certificates/di/certificates_injection.dart';
import 'package:lcc_mobile_app/features/chat/di/chat_injection.dart';
import 'package:lcc_mobile_app/features/documents/data/datasources/documents_remote_datasource.dart';
import 'package:lcc_mobile_app/features/documents/di/documents_injection.dart';
import 'package:lcc_mobile_app/features/family_book/di/family_book_injection.dart';
import 'package:lcc_mobile_app/features/documents/domain/repositories/documents_repository.dart';
import 'package:lcc_mobile_app/features/documents/domain/usecases/documents_usecases.dart';
import 'package:lcc_mobile_app/features/help/di/help_injection.dart';
import 'package:lcc_mobile_app/features/history/di/history_injection.dart';
import 'package:lcc_mobile_app/features/history/presentation/bloc/history_detail_bloc.dart';
import 'package:lcc_mobile_app/features/home/di/home_injection.dart';
import 'package:lcc_mobile_app/features/news/di/news_injection.dart';
import 'package:lcc_mobile_app/features/notifications/di/notifications_injection.dart';
import 'package:lcc_mobile_app/features/reference/di/reference_injection.dart';
import 'package:lcc_mobile_app/features/service/di/service_injection.dart';
import 'package:lcc_mobile_app/features/session/di/session_injection.dart';
import 'package:lcc_mobile_app/features/verify/di/verify_injection.dart';
import 'package:lcc_mobile_app/features/wallet/di/wallet_injection.dart';

void main() {
  setUp(() async => const DependencyInjection().init());

  tearDown(() async {
    await injection.reset();
    await sessionInjection.reset();
    await authInjection.reset();
    await serviceInjection.reset();
    await homeInjection.reset();
    await newsInjection.reset();
    await helpInjection.reset();
    await notificationsInjection.reset();
    await chatInjection.reset();
    await accountInjection.reset();
    await referenceInjection.reset();
    await walletInjection.reset();
    await applicationInjection.reset();
    await historyInjection.reset();
    await certificatesInjection.reset();
    await documentsInjection.reset();
    await familyBookInjection.reset();
    // Task 4. `DependencyInjection.init()` now reaches `verifyInjection` too
    // (step 19); this hand-rolled tearDown is the twelfth-documented
    // occurrence of the harness's own blind spot — a container
    // `setUp`'s `init()` populates that nothing here resets makes the
    // *next* test fail with `Type ApiClient is already registered inside
    // GetIt`, which names the wrong culprit.
    await verifyInjection.reset();
  });

  group('DI-6 — one line in init() populates the whole slice', () {
    test('every registration RESOLVES, not merely exists', () {
      // `isRegistered` returns true for a factory that throws the moment it
      // runs — F-3's defect. So each one is actually resolved.
      expect(documentsInjection<DocumentsRemoteDatasource>(),
          isA<DocumentsRemoteDatasourceImpl>());
      expect(documentsInjection<DocumentsRepository>(), isA<DocumentsRepository>());
      expect(documentsInjection<GetCertificates>(), isA<GetCertificates>());
      expect(documentsInjection<GetCertificate>(), isA<GetCertificate>());
    });

    test('DI-3 — the ROOT ApiClient is re-exported, not a second one built', () {
      // Load-bearing rather than tidy: both endpoints are authenticated `/me/*`
      // reads and need the Auth/Refresh interceptor chain that lives inside the
      // root client.
      expect(
        identical(documentsInjection<ApiClient>(), injection<ApiClient>()),
        isTrue,
      );
    });

    test('DI-1 — the root container did NOT grow a documents registration', () {
      expect(injection.isRegistered<DocumentsRepository>(), isFalse);
      expect(injection.isRegistered<GetCertificates>(), isFalse);
    });

    test('it registers NO BLoC — the feature is page-less', () {
      // `features/documents/` is the third page-less feature after
      // `reference` and `application`. B5 creates no route and no page; its
      // widgets live in `lib/presentation/documents/`.
      expect(documentsInjection.isRegistered<HistoryDetailBloc>(), isFalse);
    });
  });

  group('B5-AC-33 / NV-5 — the ordering claim, resolved end to end', () {
    test('HistoryDetailBloc resolves with all four use cases wired', () {
      final HistoryDetailBloc bloc = historyInjection<HistoryDetailBloc>();
      addTearDown(bloc.close);

      // The four dependencies the constructor requires. Resolving the BLoC at
      // all is what proves the cross-container closures fire in the order
      // `dependency_injection.dart` step 18 documents — `historyInjection`
      // reaches into `documentsInjection`, which was registered *after* it.
      expect(bloc.getCertificates, isA<GetCertificates>());
      expect(bloc.getCertificate, isA<GetCertificate>());
      expect(bloc.getApplication, isNotNull);
      expect(bloc.getApplicationTimeline, isNotNull);
    });

    test('history re-exports the SAME use-case instances, not second copies',
        () {
      expect(
        identical(historyInjection<GetCertificates>(),
            documentsInjection<GetCertificates>()),
        isTrue,
        reason: 'the `ChatUsecaseInjection -> helpInjection` shape: a closure '
            'over another container, never a second repository behind a second '
            'parse of the same endpoint',
      );
      expect(
        identical(historyInjection<GetCertificate>(),
            documentsInjection<GetCertificate>()),
        isTrue,
      );
    });

    test('a second HistoryDetailBloc is a NEW instance — registerFactory', () {
      final HistoryDetailBloc a = historyInjection<HistoryDetailBloc>();
      final HistoryDetailBloc b = historyInjection<HistoryDetailBloc>();
      addTearDown(a.close);
      addTearDown(b.close);

      expect(identical(a, b), isFalse,
          reason: 'it now carries THREE generation counters plus the open '
              "case's id; a survivor would hand the next case the previous "
              "one's in-flight answers");
    });
  });
}
