/// `NotificationRepositoryImpl` — try the datasource, fold every throw into a
/// [Failure].
///
/// Follows `HelpRepositoryImpl` exactly, including its deviation from the
/// session feature: no `ApiException` rethrow. Every mode the bell has —
/// offline, 500, 401 after the token expired, a malformed row — collapses to
/// the same user-visible outcome, which for the list is the menu's
/// error-with-retry branch (`Layout.tsx:229-240`) and for the count is a badge
/// that stays at its last value.
///
/// [Failure.message] carries the exception text for logs. **It is not what the
/// menu renders**; see `notification_menu_sheet.dart` for what is, and why.
library;

import 'package:dartz/dartz.dart';

import '../../../../core/error/failure.dart';
import '../../domain/entities/notification_entities.dart';
import '../../domain/repositories/notification_repository.dart';
import '../datasources/notification_remote_datasource.dart';

class NotificationRepositoryImpl implements NotificationRepository {
  const NotificationRepositoryImpl({required this.remote});

  final NotificationRemoteDatasource remote;

  Future<Either<Failure, T>> _guard<T>(Future<T> Function() read) async {
    try {
      return Right<Failure, T>(await read());
    } catch (e) {
      return Left<Failure, T>(Failure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<CitizenNotification>>> getNotifications({
    required int perPage,
  }) =>
      _guard(() => remote.getNotifications(perPage: perPage));

  @override
  Future<Either<Failure, int>> getUnreadCount() => _guard(remote.getUnreadCount);

  @override
  Future<Either<Failure, Unit>> markRead(String id) => _guard(() async {
        await remote.markRead(id);
        return unit;
      });

  @override
  Future<Either<Failure, Unit>> markAllRead() => _guard(() async {
        await remote.markAllRead();
        return unit;
      });
}
