/// `ChatRepositoryImpl` — try the datasource, fold every throw into a
/// [Failure].
///
/// Follows `NotificationRepositoryImpl` and `HelpRepositoryImpl` exactly,
/// including their deviation from the session feature: no `ApiException`
/// rethrow. Every mode the panel has — offline, 500, 401 after the token
/// expired, a malformed row — collapses to the same user-visible outcome, which
/// for the transcript is the error-with-retry branch (`:326-336`) and for a
/// send is the composer keeping the citizen's text (`:144-148`).
///
/// [Failure.message] carries the exception text for logs. **Nothing renders
/// it**: the web prints `transcript.error.message`, the backend's own sentence,
/// and this port has no such sentence to print — see `chat_panel.dart` for what
/// it renders instead and why.
library;

import 'package:dartz/dartz.dart';

import '../../../../core/error/failure.dart';
import '../../domain/entities/chat_entities.dart';
import '../../domain/repositories/chat_repository.dart';
import '../datasources/chat_remote_datasource.dart';

class ChatRepositoryImpl implements ChatRepository {
  const ChatRepositoryImpl({required this.remote});

  final ChatRemoteDatasource remote;

  Future<Either<Failure, T>> _guard<T>(Future<T> Function() call) async {
    try {
      return Right<Failure, T>(await call());
    } catch (e) {
      return Left<Failure, T>(Failure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<ChatThread>>> getThreads() =>
      _guard(remote.getThreads);

  @override
  Future<Either<Failure, List<ChatMessage>>> getMessages({
    required String threadId,
    required int perPage,
  }) =>
      _guard(() => remote.getMessages(threadId: threadId, perPage: perPage));

  @override
  Future<Either<Failure, StartedThread>> startThread({
    required String subject,
    required String message,
  }) =>
      _guard(() => remote.startThread(subject: subject, message: message));

  @override
  Future<Either<Failure, SentMessage>> sendMessage({
    required String threadId,
    required String body,
  }) =>
      _guard(() => remote.sendMessage(threadId: threadId, body: body));

  @override
  Future<Either<Failure, Unit>> markRead(String threadId) => _guard(() async {
        await remote.markRead(threadId);
        return unit;
      });

  @override
  Future<Either<Failure, Unit>> closeThread({
    required String threadId,
    required int rating,
  }) =>
      _guard(() async {
        await remote.closeThread(threadId: threadId, rating: rating);
        return unit;
      });
}
