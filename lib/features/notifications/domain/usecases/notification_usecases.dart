/// The notification inbox's four use cases.
library;

import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/notification_entities.dart';
import '../repositories/notification_repository.dart';

/// `Layout.tsx:117` — `me.notifications({ per_page: 8 })`.
///
/// Eight, not ten and not "a page": the menu is a fixed-height dropdown and the
/// number is the source's. A different value would change what a citizen sees
/// without any tier being able to tell.
const int kNotificationsPerPage = 8;

/// `GET /me/notifications` — the newest [kNotificationsPerPage] rows.
class GetNotifications
    implements UseCase<List<CitizenNotification>, NoParams> {
  const GetNotifications({required this.repository});

  final NotificationRepository repository;

  @override
  Future<Either<Failure, List<CitizenNotification>>> call(NoParams params) =>
      repository.getNotifications(perPage: kNotificationsPerPage);
}

/// `GET /me/notifications/unread-count`.
class GetUnreadCount implements UseCase<int, NoParams> {
  const GetUnreadCount({required this.repository});

  final NotificationRepository repository;

  @override
  Future<Either<Failure, int>> call(NoParams params) =>
      repository.getUnreadCount();
}

/// The id of the notice the citizen opened.
class MarkNotificationReadParams extends Equatable {
  const MarkNotificationReadParams(this.id);

  final String id;

  @override
  List<Object?> get props => <Object?>[id];
}

/// `POST /me/notifications/<id>/read`.
class MarkNotificationRead
    implements UseCase<Unit, MarkNotificationReadParams> {
  const MarkNotificationRead({required this.repository});

  final NotificationRepository repository;

  @override
  Future<Either<Failure, Unit>> call(MarkNotificationReadParams params) =>
      repository.markRead(params.id);
}

/// `POST /me/notifications/read-all`.
class MarkAllNotificationsRead implements UseCase<Unit, NoParams> {
  const MarkAllNotificationsRead({required this.repository});

  final NotificationRepository repository;

  @override
  Future<Either<Failure, Unit>> call(NoParams params) =>
      repository.markAllRead();
}
