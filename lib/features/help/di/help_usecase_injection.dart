/// Help use-case DI — six lazy singletons (DI-2), one per use case.
library;

import '../domain/repositories/help_repository.dart';
import '../domain/usecases/help_usecases.dart';
import 'help_injection.dart';

class HelpUsecaseInjection {
  static void inject() {
    helpInjection
      ..registerLazySingleton<GetHelpCategories>(
        () => GetHelpCategories(repository: helpInjection<HelpRepository>()),
      )
      ..registerLazySingleton<GetHelpFaqs>(
        () => GetHelpFaqs(repository: helpInjection<HelpRepository>()),
      )
      ..registerLazySingleton<GetHelpGuides>(
        () => GetHelpGuides(repository: helpInjection<HelpRepository>()),
      )
      ..registerLazySingleton<GetHelpGuide>(
        () => GetHelpGuide(repository: helpInjection<HelpRepository>()),
      )
      ..registerLazySingleton<GetSupportChannels>(
        () => GetSupportChannels(repository: helpInjection<HelpRepository>()),
      )
      ..registerLazySingleton<SendFaqFeedback>(
        () => SendFaqFeedback(repository: helpInjection<HelpRepository>()),
      );
  }
}
