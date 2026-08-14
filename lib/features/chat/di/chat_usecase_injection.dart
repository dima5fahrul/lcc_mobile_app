/// Chat use-case DI — six of its own, plus **one re-exported from help**.
///
/// ## `/help/channels` is REUSED, not re-implemented (specs.md § 6.6)
///
/// `CustomerServiceChat.tsx:47-53` reads `content.supportChannels` and derives
/// the header's phone and email shortcuts from it. B2c already landed the whole
/// thing — `ApiEndpoint.helpChannels`, `SupportChannel` and `GetSupportChannels`
/// — so B9b adds **no endpoint constant and no second wire mapping** for it.
///
/// Cross-Feature Isolation (SSD § 4.3) permits `features/A →
/// features/B/domain/**`, and **G-L3 measures precisely that boundary and
/// allows it**. SSD § 4.3's *"wire-format duplication is the accepted cost"*
/// applies when two features *parse* the same JSON; here the chat parses
/// nothing — it consumes a domain entity through a domain use case, which the
/// same section describes as the correct shared-currency case.
///
/// The re-export follows `AuthDatasourceInjection`'s precedent
/// (`dependency_injection.dart:128-129`): a closure over the other container,
/// so there is exactly one `GetSupportChannels` and one `HelpRepository` behind
/// it, not a second parse of `/help/channels`.
///
/// **This is the ordering constraint** `chat_feature_injection.dart` and
/// `DependencyInjection.init()` step 11 both document: the closure below
/// reaches into `helpInjection`, so `HelpFeatureInjection.init()` must have run
/// first. DI-6's "one alphabetical line" would have put `chat` before `help`;
/// the alphabetical rule yields here and the deviation is stated at the call
/// site (§ 6.6).
library;

import '../../help/di/help_injection.dart';
import '../../help/domain/usecases/help_usecases.dart';
import '../domain/repositories/chat_repository.dart';
import '../domain/usecases/chat_usecases.dart';
import 'chat_injection.dart';

class ChatUsecaseInjection {
  static void inject() {
    chatInjection
      ..registerLazySingleton<GetChatThreads>(
        () => GetChatThreads(repository: chatInjection<ChatRepository>()),
      )
      ..registerLazySingleton<GetChatMessages>(
        () => GetChatMessages(repository: chatInjection<ChatRepository>()),
      )
      ..registerLazySingleton<StartChatThread>(
        () => StartChatThread(repository: chatInjection<ChatRepository>()),
      )
      ..registerLazySingleton<SendChatMessage>(
        () => SendChatMessage(repository: chatInjection<ChatRepository>()),
      )
      ..registerLazySingleton<MarkThreadRead>(
        () => MarkThreadRead(repository: chatInjection<ChatRepository>()),
      )
      ..registerLazySingleton<CloseChatThread>(
        () => CloseChatThread(repository: chatInjection<ChatRepository>()),
      )
      // The re-export. Resolved lazily out of `helpInjection` on first use, so
      // registration order between the two containers is the only constraint
      // and it is satisfied by `DependencyInjection.init()`'s step order.
      ..registerLazySingleton<GetSupportChannels>(
        () => helpInjection<GetSupportChannels>(),
      );
  }
}
