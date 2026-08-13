/// News feature injection entry point.
///
/// Called from `DependencyInjection.init` after `ApiClient` is on the root
/// container — the datasource resolves it. Ordering inside: datasource →
/// repository → usecase → blocs, mirroring `HomeFeatureInjection.init()`.
///
/// ## Two BLoCs, two routes, both `registerFactory`
///
/// `/news` and `/news/:slug` are separate routes with separate lifetimes, so
/// they get separate BLoCs. Both are factories (not lazy singletons) for the
/// reason `app_routes.dart` records for `ServiceBloc`: the provider that
/// creates one closes it on the way out, and a surviving instance would hand
/// the next visit the previous visit's page number, filter, or article.
///
/// [NewsDetailBloc] takes the **slug** as a constructor argument, so it cannot
/// be a plain `registerFactory<NewsDetailBloc>()` — `GetIt`'s
/// `registerFactoryParam` is the matching registration. The route builder
/// supplies the parameter, which keeps the seam SSD § 6.4 draws: the builder
/// resolves and provides, and no widget reads a locator (G-L5).
library;

import '../domain/usecases/news_usecases.dart';
import '../presentation/bloc/news_bloc.dart';
import '../presentation/bloc/news_detail_bloc.dart';
import 'news_datasource_injection.dart';
import 'news_injection.dart';
import 'news_repository_injection.dart';
import 'news_usecase_injection.dart';

class NewsFeatureInjection {
  static Future<void> init() async {
    NewsDatasourceInjection.inject();
    NewsRepositoryInjection.inject();
    NewsUsecaseInjection.inject();

    newsInjection.registerFactory<NewsBloc>(
      () => NewsBloc(
        getNewsCategories: newsInjection<GetNewsCategories>(),
        getNewsArticles: newsInjection<GetNewsArticles>(),
      ),
    );

    newsInjection.registerFactoryParam<NewsDetailBloc, String, void>(
      (String slug, _) => NewsDetailBloc(
        slug: slug,
        getNewsArticle: newsInjection<GetNewsArticle>(),
        getNewsCatalogue: newsInjection<GetNewsCatalogue>(),
      ),
    );
  }
}
