/// `NotificationRepositoryImpl` — the `_guard` fold, both branches, all four
/// calls.
///
/// Written because the coverage run said so: the BLoC tests use a fake
/// repository and the transport test drives the datasource directly, so the
/// **impl between them** sat at 42.9 % with its entire `catch` branch
/// unexercised. That branch is the one that decides whether a thrown
/// `ApiException` becomes a `Left(Failure)` or escapes into a widget build, so
/// "not covered" here means "nobody has checked the bell survives a 500".
library;

import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lcc_mobile_app/core/error/failure.dart';
import 'package:lcc_mobile_app/core/network/api_exception.dart';
import 'package:lcc_mobile_app/features/notifications/data/datasources/notification_remote_datasource.dart';
import 'package:lcc_mobile_app/features/notifications/data/repositories/notification_repository_impl.dart';
import 'package:lcc_mobile_app/features/notifications/domain/entities/notification_entities.dart';
import 'package:lcc_mobile_app/features/notifications/domain/repositories/notification_repository.dart';

import '../notification_test_helper.dart';

/// Throws on demand, so both sides of `_guard` are reachable.
class _ThrowingDatasource implements NotificationRemoteDatasource {
  Object? error;

  final List<String> calls = <String>[];

  Never _boom() => throw error!;

  @override
  Future<List<CitizenNotification>> getNotifications({
    required int perPage,
  }) async {
    calls.add('getNotifications');
    if (error != null) _boom();
    return syntheticNotifications();
  }

  @override
  Future<int> getUnreadCount() async {
    calls.add('getUnreadCount');
    if (error != null) _boom();
    return syntheticUnreadCount();
  }

  @override
  Future<void> markRead(String id) async {
    calls.add('markRead:$id');
    if (error != null) _boom();
  }

  @override
  Future<void> markAllRead() async {
    calls.add('markAllRead');
    if (error != null) _boom();
  }
}

void main() {
  late _ThrowingDatasource remote;
  late NotificationRepository repository;

  setUp(() {
    remote = _ThrowingDatasource();
    repository = NotificationRepositoryImpl(remote: remote);
  });

  group('the happy path folds to Right', () {
    test('getNotifications passes perPage through and returns the rows',
        () async {
      final Either<Failure, List<CitizenNotification>> result =
          await repository.getNotifications(perPage: 8);

      expect(result.isRight(), isTrue);
      expect(
        result.getOrElse(() => <CitizenNotification>[]),
        hasLength(8),
      );
      expect(remote.calls, <String>['getNotifications']);
    });

    test('getUnreadCount returns the number', () async {
      expect((await repository.getUnreadCount()).getOrElse(() => -1), 3);
    });

    test('the two writes answer Right(unit)', () async {
      expect(await repository.markRead('ntf-0001'), const Right<Failure, Unit>(unit));
      expect(await repository.markAllRead(), const Right<Failure, Unit>(unit));
      expect(remote.calls, <String>['markRead:ntf-0001', 'markAllRead']);
    });
  });

  group('EVERY throw folds to Left — nothing escapes into a widget build', () {
    // The bell is app chrome on all five main tabs. An exception that escaped
    // here would not take down a page, it would take down the shell.
    for (final ({String label, Object error}) scenario
        in <({String label, Object error})>[
      (
        label: 'a 500 from the backend',
        error: ApiException(
          status: 500,
          code: ApiCode.internalError,
          message: 'Something went wrong.',
        ),
      ),
      (
        label: 'a transport failure',
        error: ApiException(
          status: 0,
          code: ApiCode.networkError,
          message: 'Cannot reach the server.',
        ),
      ),
      (label: 'a malformed body', error: const FormatException('bad json')),
      (label: 'anything at all', error: StateError('unexpected')),
    ]) {
      test('${scenario.label} — all four calls', () async {
        remote.error = scenario.error;

        expect((await repository.getNotifications(perPage: 8)).isLeft(), isTrue);
        expect((await repository.getUnreadCount()).isLeft(), isTrue);
        expect((await repository.markRead('x')).isLeft(), isTrue);
        expect((await repository.markAllRead()).isLeft(), isTrue);
      });
    }

    test('Failure.message carries the exception text for logs', () async {
      remote.error = ApiException(
        status: 503,
        code: ApiCode.internalError,
        message: 'Service unavailable.',
      );

      final Either<Failure, int> result = await repository.getUnreadCount();

      // It is deliberately NOT what the menu renders — see
      // `notification_menu_sheet.dart`'s `_ErrorBody` for why a stringified
      // Dart exception must not reach a citizen.
      expect(
        result.fold((Failure f) => f.message, (int _) => ''),
        contains('Service unavailable.'),
      );
    });

    test('an ApiException is NOT rethrown — the deliberate deviation from the '
        'session feature', () async {
      // `HelpRepositoryImpl` records the same choice: every mode the bell has
      // collapses to one user-visible outcome, so there is nothing for a
      // caller to do with the typed exception that it cannot do with a
      // `Failure`.
      remote.error = ApiException(
        status: 401,
        code: ApiCode.unauthorized,
        message: 'Token expired.',
      );

      expect(
        () async => repository.getNotifications(perPage: 8),
        returnsNormally,
      );
      expect((await repository.getNotifications(perPage: 8)).isLeft(), isTrue);
    });
  });
}
