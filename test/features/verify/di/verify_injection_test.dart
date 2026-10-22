/// Verify DI — the container resolves end to end, the root `ApiClient` is
/// re-exported (not rebuilt), and the root did not grow a verify
/// registration. The shape of `documents_injection_test.dart`'s resolution
/// group, with the same tearDown discipline: `DependencyInjection.init()`
/// populates EVERY feature container, so the tearDown must reset every one of
/// them — a container nothing resets makes the next test fail with
/// `Type ApiClient is already registered inside GetIt`, which names the wrong
/// culprit — `di_teardown_completeness_test.dart` enforces the reset.
///
/// **Task 4 wired `VerifyFeatureInjection.init()` into
/// `DependencyInjection.init()`**, so the explicit verify init this file
/// carried while Task 3's slice was page-less is gone — the root init now
/// registers the bloc factory too, and the resolution group below asserts it.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:lcc_mobile_app/core/di/dependency_injection.dart';
import 'package:lcc_mobile_app/core/network/api_client.dart';
import 'package:lcc_mobile_app/features/account/di/account_injection.dart';
import 'package:lcc_mobile_app/features/application/di/application_injection.dart';
import 'package:lcc_mobile_app/features/auth/di/auth_injection.dart';
import 'package:lcc_mobile_app/features/certificates/di/certificates_injection.dart';
import 'package:lcc_mobile_app/features/chat/di/chat_injection.dart';
import 'package:lcc_mobile_app/features/documents/di/documents_injection.dart';
import 'package:lcc_mobile_app/features/family_book/di/family_book_injection.dart';
import 'package:lcc_mobile_app/features/help/di/help_injection.dart';
import 'package:lcc_mobile_app/features/history/di/history_injection.dart';
import 'package:lcc_mobile_app/features/home/di/home_injection.dart';
import 'package:lcc_mobile_app/features/news/di/news_injection.dart';
import 'package:lcc_mobile_app/features/notifications/di/notifications_injection.dart';
import 'package:lcc_mobile_app/features/reference/di/reference_injection.dart';
import 'package:lcc_mobile_app/features/service/di/service_injection.dart';
import 'package:lcc_mobile_app/features/session/di/session_injection.dart';
import 'package:lcc_mobile_app/features/verify/data/datasources/verify_remote_datasource.dart';
import 'package:lcc_mobile_app/features/verify/data/repositories/verify_repository_impl.dart';
import 'package:lcc_mobile_app/features/verify/di/verify_feature_injection.dart';
import 'package:lcc_mobile_app/features/verify/di/verify_injection.dart';
import 'package:lcc_mobile_app/features/verify/domain/repositories/verify_repository.dart';
import 'package:lcc_mobile_app/features/verify/domain/usecases/verify_usecases.dart';
import 'package:lcc_mobile_app/features/verify/presentation/bloc/verify_bloc.dart';
import 'package:lcc_mobile_app/features/wallet/di/wallet_injection.dart';

void main() {
  setUp(() async {
    // Task 4: the root init now wires verify itself — no explicit second init.
    await const DependencyInjection().init();
  });

  tearDown(() async {
    // Every container `DependencyInjection.init()` populates, plus verify's
    // own — the full list, because the root init reaches into all of them.
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
    await verifyInjection.reset();
  });

  test('every registration RESOLVES, not merely exists', () {
    expect(verifyInjection<VerifyRemoteDatasource>(),
        isA<VerifyRemoteDatasourceImpl>());
    expect(verifyInjection<VerifyRepository>(), isA<VerifyRepositoryImpl>());
    expect(verifyInjection<VerifyByCode>(), isA<VerifyByCode>());
    expect(verifyInjection<VerifyDocumentHash>(), isA<VerifyDocumentHash>());
    // Task 4's bloc factory, registered through the same root init.
    expect(verifyInjection<VerifyBloc>(), isA<VerifyBloc>());
  });

  test('DI-3 — the ROOT ApiClient is re-exported, not a second one built', () {
    // The endpoints are anonymous, but the envelope unwrapping and error
    // mapping the calls need live inside the root client — a second `ApiClient`
    // would be a second Dio stack beside the one every other feature uses.
    expect(
      identical(verifyInjection<ApiClient>(), injection<ApiClient>()),
      isTrue,
    );
  });

  test('DI-1 — the root container did NOT grow a verify registration', () {
    expect(injection.isRegistered<VerifyRepository>(), isFalse);
    expect(injection.isRegistered<VerifyByCode>(), isFalse);
  });

  test('a second init() re-registers cleanly — lazy singletons over a reset '
      'container', () async {
    await verifyInjection.reset();
    await VerifyFeatureInjection.init();
    expect(verifyInjection<VerifyByCode>(), isA<VerifyByCode>());
    expect(verifyInjection<VerifyBloc>(), isA<VerifyBloc>());
  });
}
