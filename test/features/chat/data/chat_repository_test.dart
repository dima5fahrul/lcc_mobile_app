/// `ChatRepositoryImpl` — every throw folds into a [Failure], and every mode
/// the panel has collapses to the same user-visible outcome.
///
/// The disposition is `HelpRepositoryImpl`'s and `NotificationRepositoryImpl`'s,
/// including their deviation from the session feature: no `ApiException`
/// rethrow. Offline, 500, a 401 after the token expired and a malformed row all
/// reach the citizen as the transcript's error-with-retry branch or as a
/// composer that kept their text.
library;

import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lcc_mobile_app/core/error/failure.dart';
import 'package:lcc_mobile_app/core/network/api_exception.dart';
import 'package:lcc_mobile_app/features/chat/data/datasources/chat_remote_datasource.dart';
import 'package:lcc_mobile_app/features/chat/data/repositories/chat_repository_impl.dart';
import 'package:lcc_mobile_app/features/chat/domain/entities/chat_entities.dart';

import '../chat_test_helper.dart';

/// Throws whatever it is handed, from whichever call is exercised.
class _ThrowingDatasource implements ChatRemoteDatasource {
  _ThrowingDatasource(this.error);

  final Object error;

  @override
  Future<List<ChatThread>> getThreads() async => throw error;

  @override
  Future<List<ChatMessage>> getMessages({
    required String threadId,
    required int perPage,
  }) async =>
      throw error;

  @override
  Future<StartedThread> startThread({
    required String subject,
    required String message,
  }) async =>
      throw error;

  @override
  Future<SentMessage> sendMessage({
    required String threadId,
    required String body,
  }) async =>
      throw error;

  @override
  Future<void> markRead(String threadId) async => throw error;

  @override
  Future<void> closeThread({
    required String threadId,
    required int rating,
  }) async =>
      throw error;
}

class _HappyDatasource implements ChatRemoteDatasource {
  int readCalls = 0;
  int closeCalls = 0;

  @override
  Future<List<ChatThread>> getThreads() async => syntheticThreads();

  @override
  Future<List<ChatMessage>> getMessages({
    required String threadId,
    required int perPage,
  }) async =>
      syntheticMessages();

  @override
  Future<StartedThread> startThread({
    required String subject,
    required String message,
  }) async =>
      const StartedThread(thread: ChatThread(id: 'th-9'));

  @override
  Future<SentMessage> sendMessage({
    required String threadId,
    required String body,
  }) async =>
      const SentMessage();

  @override
  Future<void> markRead(String threadId) async => readCalls++;

  @override
  Future<void> closeThread({
    required String threadId,
    required int rating,
  }) async =>
      closeCalls++;
}

void main() {
  group('the happy path returns Right for all six calls', () {
    late ChatRepositoryImpl repository;
    late _HappyDatasource remote;

    setUp(() {
      remote = _HappyDatasource();
      repository = ChatRepositoryImpl(remote: remote);
    });

    test('getThreads', () async {
      final Either<Failure, List<ChatThread>> result =
          await repository.getThreads();
      expect(result.isRight(), isTrue);
      expect(result.getOrElse(() => <ChatThread>[]), hasLength(4));
    });

    test('getMessages', () async {
      final Either<Failure, List<ChatMessage>> result =
          await repository.getMessages(threadId: 't', perPage: 100);
      expect(result.getOrElse(() => <ChatMessage>[]), hasLength(6));
    });

    test('startThread', () async {
      final Either<Failure, StartedThread> result =
          await repository.startThread(subject: 'a', message: 'a');
      expect(
        result.getOrElse(() => const StartedThread()).thread.id,
        'th-9',
      );
    });

    test('sendMessage', () async {
      expect(
        (await repository.sendMessage(threadId: 't', body: 'b')).isRight(),
        isTrue,
      );
    });

    test('markRead and closeThread answer Right(unit)', () async {
      expect(await repository.markRead('t'), const Right<Failure, Unit>(unit));
      expect(
        await repository.closeThread(threadId: 't', rating: 5),
        const Right<Failure, Unit>(unit),
      );
      expect(remote.readCalls, 1);
      expect(remote.closeCalls, 1);
    });
  });

  group('every throw folds into a Failure — no exception escapes', () {
    final List<Object> errors = <Object>[
      ApiException(status: 0, code: 'NETWORK_ERROR', message: 'offline'),
      ApiException(status: 500, code: 'INTERNAL', message: 'boom'),
      ApiException(status: 401, code: 'UNAUTHENTICATED', message: 'expired'),
      const FormatException('malformed row'),
      StateError('something else entirely'),
    ];

    for (final Object error in errors) {
      test('${error.runtimeType} on every call', () async {
        final ChatRepositoryImpl repository =
            ChatRepositoryImpl(remote: _ThrowingDatasource(error));

        expect((await repository.getThreads()).isLeft(), isTrue);
        expect(
          (await repository.getMessages(threadId: 't', perPage: 100)).isLeft(),
          isTrue,
        );
        expect(
          (await repository.startThread(subject: 'a', message: 'a')).isLeft(),
          isTrue,
        );
        expect(
          (await repository.sendMessage(threadId: 't', body: 'b')).isLeft(),
          isTrue,
        );
        expect((await repository.markRead('t')).isLeft(), isTrue);
        expect(
          (await repository.closeThread(threadId: 't', rating: 1)).isLeft(),
          isTrue,
        );
      });
    }

    test('a 401 is NOT rethrown as an ApiException — the deviation from the '
        'session feature, held on purpose', () async {
      final ChatRepositoryImpl repository = ChatRepositoryImpl(
        remote: _ThrowingDatasource(
          ApiException(
            status: 401,
            code: 'UNAUTHENTICATED',
            message: 'expired',
          ),
        ),
      );

      // The panel has one error rendering, and an expired token reaching it as
      // "we could not load this" is the same outcome as being offline. The
      // session's own refresh interceptor is what handles the 401 properly.
      expect(
        () async => repository.getMessages(threadId: 't', perPage: 100),
        returnsNormally,
      );
      expect(
        (await repository.getMessages(threadId: 't', perPage: 100)).isLeft(),
        isTrue,
      );
    });

    test('Failure.message carries the exception text for logs, and NOTHING '
        'renders it', () async {
      final Either<Failure, List<ChatThread>> result =
          await ChatRepositoryImpl(
        remote: _ThrowingDatasource(StateError('diagnostic detail')),
      ).getThreads();

      final String message = result.fold((Failure f) => f.message, (_) => '');
      expect(message, contains('diagnostic detail'));
      // `chat_panel.dart` renders the retry control and no message line
      // (B9B-DIV-5): `e.toString()` would put `Bad state: …` in front of a
      // citizen.
      expect(message, contains('Bad state'));
    });
  });
}
