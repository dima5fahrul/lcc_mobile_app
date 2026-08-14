/// The chat's six use cases.
///
/// [StartChatThread] is the only one that transforms its input, and the
/// transform is the batch's single Tier 0 leaf — see `chat_wire.dart`'s
/// `chatSubject` and `kChatSubjectMaxUnits`.
library;

import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/chat_entities.dart';
import '../repositories/chat_repository.dart';

/// `me.chatMessages(threadId, { per_page: 100 })` — `:82`.
///
/// A hundred, not "a page": the panel has no pager and no infinite scroll, so
/// this number is the length of transcript a citizen can see at all. A smaller
/// value would silently truncate long conversations with no affordance to load
/// the rest, which the source does not have either.
const int kChatMessagesPerPage = 100;

/// `GET /me/chat/threads`.
class GetChatThreads implements UseCase<List<ChatThread>, NoParams> {
  const GetChatThreads({required this.repository});

  final ChatRepository repository;

  @override
  Future<Either<Failure, List<ChatThread>>> call(NoParams params) =>
      repository.getThreads();
}

/// The thread whose transcript is wanted.
class GetChatMessagesParams extends Equatable {
  const GetChatMessagesParams(this.threadId);

  final String threadId;

  @override
  List<Object?> get props => <Object?>[threadId];
}

/// `GET /me/chat/threads/<id>/messages`.
class GetChatMessages
    implements UseCase<List<ChatMessage>, GetChatMessagesParams> {
  const GetChatMessages({required this.repository});

  final ChatRepository repository;

  @override
  Future<Either<Failure, List<ChatMessage>>> call(
    GetChatMessagesParams params,
  ) =>
      repository.getMessages(
        threadId: params.threadId,
        perPage: kChatMessagesPerPage,
      );
}

/// The citizen's first message, already trimmed.
///
/// **Trimmed by the caller, not here**, because the source trims once at `:130`
/// and then derives *both* the subject and the message from the trimmed form.
/// Trimming inside this use case would work for `message` and still leave the
/// possibility of a caller computing `subject` from the raw text — the exact
/// ordering B9-AC-25 gates.
class StartChatThreadParams extends Equatable {
  const StartChatThreadParams(this.message);

  /// `body`, i.e. `raw.trim()` — `:130`.
  final String message;

  @override
  List<Object?> get props => <Object?>[message];
}

/// `POST /me/chat/threads`.
///
/// The `subject` truncation lives in `chat_wire.dart` (the layer that builds the
/// request body) rather than here, so that the Tier 0 test can assert the
/// **encoded body** against the web's — which is the artefact § 6.7 gates,
/// where a use-case-level assertion would only gate an intermediate value.
class StartChatThread implements UseCase<StartedThread, StartChatThreadParams> {
  const StartChatThread({required this.repository});

  final ChatRepository repository;

  @override
  Future<Either<Failure, StartedThread>> call(StartChatThreadParams params) =>
      repository.startThread(
        // `subject: body.slice(0, 80), message: body` — `:140`. Both sides come
        // from the SAME already-trimmed string; see [StartChatThreadParams].
        subject: params.message,
        message: params.message,
      );
}

/// A message on an existing thread.
class SendChatMessageParams extends Equatable {
  const SendChatMessageParams({required this.threadId, required this.body});

  final String threadId;
  final String body;

  @override
  List<Object?> get props => <Object?>[threadId, body];
}

/// `POST /me/chat/threads/<id>/messages`.
class SendChatMessage implements UseCase<SentMessage, SendChatMessageParams> {
  const SendChatMessage({required this.repository});

  final ChatRepository repository;

  @override
  Future<Either<Failure, SentMessage>> call(SendChatMessageParams params) =>
      repository.sendMessage(threadId: params.threadId, body: params.body);
}

/// The thread whose unread marker is being cleared.
class MarkThreadReadParams extends Equatable {
  const MarkThreadReadParams(this.threadId);

  final String threadId;

  @override
  List<Object?> get props => <Object?>[threadId];
}

/// `POST /me/chat/threads/<id>/read`, bodyless.
class MarkThreadRead implements UseCase<Unit, MarkThreadReadParams> {
  const MarkThreadRead({required this.repository});

  final ChatRepository repository;

  @override
  Future<Either<Failure, Unit>> call(MarkThreadReadParams params) =>
      repository.markRead(params.threadId);
}

/// A thread and the stars the citizen gave it.
class CloseChatThreadParams extends Equatable {
  const CloseChatThreadParams({required this.threadId, required this.rating});

  final String threadId;

  /// 1-5, from the star row (`:472-482`). Never 0: the "Not now" control
  /// (`:485`) dismisses the strip without closing the thread.
  final int rating;

  @override
  List<Object?> get props => <Object?>[threadId, rating];
}

/// `POST /me/chat/threads/<id>/close`.
class CloseChatThread implements UseCase<Unit, CloseChatThreadParams> {
  const CloseChatThread({required this.repository});

  final ChatRepository repository;

  @override
  Future<Either<Failure, Unit>> call(CloseChatThreadParams params) =>
      repository.closeThread(
        threadId: params.threadId,
        rating: params.rating,
      );
}
