/// Chat repository DI. Lazy (DI-2), over the datasource registered before it.
library;

import '../data/datasources/chat_remote_datasource.dart';
import '../data/repositories/chat_repository_impl.dart';
import '../domain/repositories/chat_repository.dart';
import 'chat_injection.dart';

class ChatRepositoryInjection {
  static void inject() {
    chatInjection.registerLazySingleton<ChatRepository>(
      () => ChatRepositoryImpl(remote: chatInjection<ChatRemoteDatasource>()),
    );
  }
}
