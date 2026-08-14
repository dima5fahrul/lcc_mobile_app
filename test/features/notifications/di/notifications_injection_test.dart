/// **B9-AC-12** — DI-1 … DI-6 for the notification feature.
library;

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lcc_mobile_app/core/di/dependency_injection.dart';
import 'package:lcc_mobile_app/core/network/api_client.dart';
import 'package:lcc_mobile_app/core/session/bloc/session_bloc.dart';
import 'package:lcc_mobile_app/core/storage/storage_service.dart';
import 'package:lcc_mobile_app/features/notifications/data/datasources/notification_remote_datasource.dart';
import 'package:lcc_mobile_app/features/notifications/di/notifications_feature_injection.dart';
import 'package:lcc_mobile_app/features/notifications/di/notifications_injection.dart';
import 'package:lcc_mobile_app/features/notifications/domain/repositories/notification_repository.dart';
import 'package:lcc_mobile_app/features/notifications/domain/usecases/notification_usecases.dart';
import 'package:lcc_mobile_app/features/notifications/presentation/bloc/notifications_bloc.dart';

import '../../../helpers/core_test_helper.dart';

void main() {
  setUp(() async {
    await injection.reset();
    await notificationsInjection.reset();

    // The two the feature's datasource re-exports rather than rebuilds.
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

    await NotificationsFeatureInjection.init();
  });

  tearDown(() async {
    await injection.reset();
    await notificationsInjection.reset();
  });

  test('DI-3 — the feature shares the ROOT ApiClient, it does not build a '
      'second Dio', () {
    // Load-bearing rather than tidy: all four notification calls are
    // authenticated `/me/*` requests, so they need the Auth/Refresh
    // interceptor chain that lives inside the root client. A second Dio would
    // send them bare and every one would 401.
    expect(
      identical(notificationsInjection<ApiClient>(), injection<ApiClient>()),
      isTrue,
    );
    expect(notificationsInjection.isRegistered<Dio>(), isFalse);
  });

  test('DI-1 — the root container is unchanged by this feature', () {
    // The root holds exactly StorageService, ApiClient and SessionBloc. This
    // test registers the first two itself and asserts the feature added
    // nothing beside them.
    expect(injection.isRegistered<NotificationRepository>(), isFalse);
    expect(injection.isRegistered<NotificationsBloc>(), isFalse);
    expect(injection.isRegistered<GetUnreadCount>(), isFalse);
    expect(injection.isRegistered<NotificationRemoteDatasource>(), isFalse);
    // SessionBloc is the root's third member and is not this feature's to add.
    expect(injection.isRegistered<SessionBloc>(), isFalse);
  });

  test('DI-2 — every registration resolves, and the singletons are singletons',
      () {
    expect(
      identical(
        notificationsInjection<NotificationRemoteDatasource>(),
        notificationsInjection<NotificationRemoteDatasource>(),
      ),
      isTrue,
    );
    expect(
      identical(
        notificationsInjection<NotificationRepository>(),
        notificationsInjection<NotificationRepository>(),
      ),
      isTrue,
    );
    for (final Object Function() resolve in <Object Function()>[
      () => notificationsInjection<GetNotifications>(),
      () => notificationsInjection<GetUnreadCount>(),
      () => notificationsInjection<MarkNotificationRead>(),
      () => notificationsInjection<MarkAllNotificationsRead>(),
    ]) {
      expect(resolve, returnsNormally);
    }
  });

  test('the BLoC is a FACTORY — a fresh one per shell, never shared', () {
    // It holds one citizen's unread count and their own notices. A surviving
    // instance would hand both to whoever signs in next on the same device.
    final NotificationsBloc a = notificationsInjection<NotificationsBloc>();
    final NotificationsBloc b = notificationsInjection<NotificationsBloc>();
    addTearDown(a.close);
    addTearDown(b.close);

    expect(identical(a, b), isFalse);
  });

  test('a fresh BLoC starts signed out with nothing fetched', () {
    final NotificationsBloc bloc =
        notificationsInjection<NotificationsBloc>();
    addTearDown(bloc.close);

    // The reason `NotificationBell` must dispatch from `initState` and not
    // only from a session listener.
    expect(bloc.state.isAuthenticated, isFalse);
    expect(bloc.state.unreadCount, 0);
    expect(bloc.state.items, isEmpty);
    expect(bloc.state.open, isFalse);
  });

  test('B9-AC-15 — no static mutable state in the feature', () {
    // Two BLoCs must not see each other's inbox. A `static` set or counter —
    // the shape the chat feature is explicitly warned off in § 6.9(3) — would
    // leak across tests and across citizens on one device.
    final NotificationsBloc a = notificationsInjection<NotificationsBloc>();
    final NotificationsBloc b = notificationsInjection<NotificationsBloc>();
    addTearDown(a.close);
    addTearDown(b.close);

    a.add(const NotificationsMenuToggled());
    expect(b.state.open, isFalse);
  });
}
