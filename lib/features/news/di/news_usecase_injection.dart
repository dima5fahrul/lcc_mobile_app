/// News use-case DI — four lazy singletons (DI-2), one per use case.
library;

import '../domain/repositories/news_repository.dart';
import '../domain/usecases/news_usecases.dart';
import 'news_injection.dart';

class NewsUsecaseInjection {
  static void inject() {
    newsInjection
      ..registerLazySingleton<GetNewsCategories>(
        () => GetNewsCategories(repository: newsInjection<NewsRepository>()),
      )
      ..registerLazySingleton<GetNewsArticles>(
        () => GetNewsArticles(repository: newsInjection<NewsRepository>()),
      )
      ..registerLazySingleton<GetNewsCatalogue>(
        () => GetNewsCatalogue(repository: newsInjection<NewsRepository>()),
      )
      ..registerLazySingleton<GetNewsArticle>(
        () => GetNewsArticle(repository: newsInjection<NewsRepository>()),
      );
  }
}
