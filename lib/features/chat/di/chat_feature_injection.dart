/// Chat feature injection entry point.
///
/// Ordering inside: datasource → repository → usecase → bloc, mirroring
/// `NotificationsFeatureInjection.init()`.
///
/// ## This one has an ordering constraint the others do not
///
/// `ChatUsecaseInjection` re-exports `GetSupportChannels` out of
/// `helpInjection` (§ 6.6), so **`HelpFeatureInjection.init()` must run
/// first**. It is a lazy registration, so a wrong order would not fail here —
/// it would fail at the first resolution, i.e. the first time a citizen opens
/// the panel. `DependencyInjection.init()`'s step 11 carries the comment.
///
/// ## Why `registerFactory` and not a singleton
///
/// `ChatBloc` holds one citizen's correspondence: the live thread id, the
/// transcript, the composer's text, the client-side `ended` set — and a
/// `Timer`. A surviving instance would hand all five to whoever signs in next
/// on the same device, and the timer would outlive the widget that owns it.
/// The `ShellRoute` builder owns the provider (`BlocProvider(create:)`), so the
/// instance is created and **closed** with the shell, and `close()` is what
/// cancels the timer.
library;

import '../../help/domain/usecases/help_usecases.dart';
import '../domain/usecases/chat_usecases.dart';
import '../presentation/bloc/chat_bloc.dart';
import 'chat_datasource_injection.dart';
import 'chat_injection.dart';
import 'chat_repository_injection.dart';
import 'chat_usecase_injection.dart';

class ChatFeatureInjection {
  static Future<void> init() async {
    ChatDatasourceInjection.inject();
    ChatRepositoryInjection.inject();
    ChatUsecaseInjection.inject();

    chatInjection.registerFactory<ChatBloc>(
      () => ChatBloc(
        getChatThreads: chatInjection<GetChatThreads>(),
        getChatMessages: chatInjection<GetChatMessages>(),
        startChatThread: chatInjection<StartChatThread>(),
        sendChatMessage: chatInjection<SendChatMessage>(),
        markThreadRead: chatInjection<MarkThreadRead>(),
        closeChatThread: chatInjection<CloseChatThread>(),
        getSupportChannels: chatInjection<GetSupportChannels>(),
      ),
    );
  }
}
