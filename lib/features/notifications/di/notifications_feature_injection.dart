/// Notification feature injection entry point.
///
/// Ordering inside: datasource → repository → usecase → bloc, mirroring
/// `HelpFeatureInjection.init()`.
///
/// ## Why `registerFactory` and not a singleton
///
/// `NotificationsBloc` holds one visit's inbox: whether the menu is open, the
/// citizen's own notices, and their unread count. A surviving instance would
/// hand all three to whoever signs in next on the same device — the reason
/// `HelpBloc` and `ServiceBloc` are factories too. The `ShellRoute` builder
/// owns the provider (`BlocProvider(create:)`), so the instance is created and
/// closed with the shell.
library;

import '../domain/usecases/notification_usecases.dart';
import '../presentation/bloc/notifications_bloc.dart';
import 'notifications_datasource_injection.dart';
import 'notifications_injection.dart';
import 'notifications_repository_injection.dart';
import 'notifications_usecase_injection.dart';

class NotificationsFeatureInjection {
  static Future<void> init() async {
    NotificationsDatasourceInjection.inject();
    NotificationsRepositoryInjection.inject();
    NotificationsUsecaseInjection.inject();

    notificationsInjection.registerFactory<NotificationsBloc>(
      () => NotificationsBloc(
        getNotifications: notificationsInjection<GetNotifications>(),
        getUnreadCount: notificationsInjection<GetUnreadCount>(),
        markNotificationRead: notificationsInjection<MarkNotificationRead>(),
        markAllNotificationsRead:
            notificationsInjection<MarkAllNotificationsRead>(),
      ),
    );
  }
}
