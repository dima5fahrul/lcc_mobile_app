/// News repository DI. Lazy (DI-2), over the datasource registered before it.
library;

import '../data/datasources/news_remote_datasource.dart';
import '../data/repositories/news_repository_impl.dart';
import '../domain/repositories/news_repository.dart';
import 'news_injection.dart';

class NewsRepositoryInjection {
  static void inject() {
    newsInjection.registerLazySingleton<NewsRepository>(
      () => NewsRepositoryImpl(remote: newsInjection<NewsRemoteDatasource>()),
    );
  }
}
