/// News and help DI — DI-1, DI-2, DI-3, DI-6 (B2-AC-18).
///
/// The defect this shape exists to catch is F-3's: a fully-written feature that
/// nothing ever registers, so the first resolution throws at runtime and the
/// code is dead no matter what the router points at. So every registration is
/// **resolved**, not merely checked for presence — `isRegistered` returns true
/// for a factory that throws the moment it runs.
///
/// Both B2c features are covered here rather than in two files: the thing under
/// test is the two lines DI-6 added to one `init()`, and splitting them would
/// mean two files booting the same container twice.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:lcc_mobile_app/core/di/dependency_injection.dart';
import 'package:lcc_mobile_app/core/network/api_client.dart';
import 'package:lcc_mobile_app/features/chat/di/chat_injection.dart';
import 'package:lcc_mobile_app/features/auth/di/auth_injection.dart';
import 'package:lcc_mobile_app/features/help/di/help_injection.dart';
import 'package:lcc_mobile_app/features/help/data/datasources/help_remote_datasource.dart';
import 'package:lcc_mobile_app/features/help/domain/repositories/help_repository.dart';
import 'package:lcc_mobile_app/features/help/domain/usecases/help_usecases.dart';
import 'package:lcc_mobile_app/features/help/presentation/bloc/help_bloc.dart';
import 'package:lcc_mobile_app/features/home/di/home_injection.dart';
import 'package:lcc_mobile_app/features/news/data/datasources/news_remote_datasource.dart';
import 'package:lcc_mobile_app/features/news/di/news_injection.dart';
import 'package:lcc_mobile_app/features/notifications/di/notifications_injection.dart';
import 'package:lcc_mobile_app/features/news/domain/repositories/news_repository.dart';
import 'package:lcc_mobile_app/features/news/domain/usecases/news_usecases.dart';
import 'package:lcc_mobile_app/features/news/presentation/bloc/news_bloc.dart';
import 'package:lcc_mobile_app/features/news/presentation/bloc/news_detail_bloc.dart';
import 'package:lcc_mobile_app/features/service/di/service_injection.dart';
import 'package:lcc_mobile_app/features/session/di/session_injection.dart';

void main() {
  setUp(() async => const DependencyInjection().init());

  tearDown(() async {
    await injection.reset();
    await sessionInjection.reset();
    await authInjection.reset();
    await serviceInjection.reset();
    await homeInjection.reset();
    await newsInjection.reset();
    await helpInjection.reset();
    // B9a's, and this file's own header predicted it: *"Adding a feature
    // container without adding its reset here breaks this file first and
    // loudly, which is the behaviour that caught it."* It did — 30 failures
    // across three DI test files, every one of them
    // `Type ApiClient is already registered inside GetIt`.
    await notificationsInjection.reset();
    // B9b's, and the prediction held a second time: without this line every
    // test after the first in this file fails with
    // `Type ApiClient is already registered inside GetIt`, thrown from
    // `ChatDatasourceInjection.inject`. B9b's § 3.1 table names
    // `test/features/chat/**` and not this file; the edit is a recorded scope
    // deviation, and the alternative is leaving three DI test files red.
    await chatInjection.reset();
  });

  group('DI-6 — one line in init() populates each whole feature', () {
    test('news', () {
      expect(newsInjection<NewsRemoteDatasource>(),
          isA<NewsRemoteDatasourceImpl>());
      expect(newsInjection<NewsRepository>(), isA<NewsRepository>());
      expect(newsInjection<GetNewsCategories>(), isA<GetNewsCategories>());
      expect(newsInjection<GetNewsArticles>(), isA<GetNewsArticles>());
      expect(newsInjection<GetNewsCatalogue>(), isA<GetNewsCatalogue>());
      expect(newsInjection<GetNewsArticle>(), isA<GetNewsArticle>());
    });

    test('help', () {
      expect(helpInjection<HelpRemoteDatasource>(),
          isA<HelpRemoteDatasourceImpl>());
      expect(helpInjection<HelpRepository>(), isA<HelpRepository>());
      expect(helpInjection<GetHelpCategories>(), isA<GetHelpCategories>());
      expect(helpInjection<GetHelpFaqs>(), isA<GetHelpFaqs>());
      expect(helpInjection<GetHelpGuides>(), isA<GetHelpGuides>());
      expect(helpInjection<GetHelpGuide>(), isA<GetHelpGuide>());
      expect(helpInjection<GetSupportChannels>(), isA<GetSupportChannels>());
      expect(helpInjection<SendFaqFeedback>(), isA<SendFaqFeedback>());
    });
  });

  group('DI-3 — no feature builds its own Dio', () {
    test('both containers re-export the ROOT ApiClient, the same instance', () {
      expect(newsInjection<ApiClient>(), same(injection<ApiClient>()));
      expect(helpInjection<ApiClient>(), same(injection<ApiClient>()));
      expect(newsInjection<ApiClient>(), same(helpInjection<ApiClient>()));
    });

    test('so the POST rides the SAME interceptor chain as everything else', () {
      // Help makes B2's one authenticated write. A second client would carry no
      // token and the feedback POST would 401 on every vote.
      expect(helpInjection<ApiClient>().storage, same(injection<ApiClient>().storage));
    });
  });

  group('DI-1 — the root container holds exactly the three', () {
    test('neither feature registered anything on the root', () {
      expect(injection.isRegistered<NewsRepository>(), isFalse);
      expect(injection.isRegistered<HelpRepository>(), isFalse);
      expect(injection.isRegistered<NewsBloc>(), isFalse);
      expect(injection.isRegistered<HelpBloc>(), isFalse);
    });
  });

  group('DI-2 — lazy, and the BLoCs are FACTORIES', () {
    test('NewsBloc is a fresh instance per visit', () {
      final NewsBloc first = newsInjection<NewsBloc>();
      final NewsBloc second = newsInjection<NewsBloc>();
      addTearDown(first.close);
      addTearDown(second.close);

      expect(first, isNot(same(second)),
          reason: 'a surviving instance would hand the next visit the previous '
              "visit's page number and filter");
    });

    test('HelpBloc is a fresh instance per visit', () {
      final HelpBloc first = helpInjection<HelpBloc>();
      final HelpBloc second = helpInjection<HelpBloc>();
      addTearDown(first.close);
      addTearDown(second.close);

      expect(first, isNot(same(second)),
          reason: 'it holds a live debounce Timer, a search term, a page, and '
              'which question and guide are expanded');
    });

    test('the use cases are lazy SINGLETONS — stateless, so one is enough', () {
      expect(newsInjection<GetNewsArticles>(),
          same(newsInjection<GetNewsArticles>()));
      expect(helpInjection<GetHelpFaqs>(), same(helpInjection<GetHelpFaqs>()));
    });
  });

  group('NewsDetailBloc takes the slug as a registration PARAMETER', () {
    test('resolving it with a slug produces a bloc that owns that slug', () {
      // The seam SSD § 6.4 draws: the route builder reads
      // `state.pathParameters['slug']` and passes it here. A plain
      // `registerFactory` could not express it, and a widget reading the
      // locator to get one would fail G-L5.
      final NewsDetailBloc bloc =
          newsInjection<NewsDetailBloc>(param1: 'a-slug');
      addTearDown(bloc.close);

      expect(bloc.slug, 'a-slug');
    });

    test('two resolutions with different slugs are two different blocs', () {
      final NewsDetailBloc first =
          newsInjection<NewsDetailBloc>(param1: 'one');
      final NewsDetailBloc second =
          newsInjection<NewsDetailBloc>(param1: 'two');
      addTearDown(first.close);
      addTearDown(second.close);

      expect(first, isNot(same(second)));
      expect(first.slug, 'one');
      expect(second.slug, 'two');
    });
  });
}
