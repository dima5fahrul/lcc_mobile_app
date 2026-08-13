/// Help feature injection entry point.
///
/// Ordering inside: datasource → repository → usecase → bloc, mirroring
/// `HomeFeatureInjection.init()`. `HelpBloc` is a `registerFactory` for the
/// reason `app_routes.dart` records for `ServiceBloc`: it holds a live debounce
/// `Timer`, one visit's search term, page and expansion state, and a surviving
/// instance would hand all of it to the next visit.
library;

import '../domain/usecases/help_usecases.dart';
import '../presentation/bloc/help_bloc.dart';
import 'help_datasource_injection.dart';
import 'help_injection.dart';
import 'help_repository_injection.dart';
import 'help_usecase_injection.dart';

class HelpFeatureInjection {
  static Future<void> init() async {
    HelpDatasourceInjection.inject();
    HelpRepositoryInjection.inject();
    HelpUsecaseInjection.inject();

    helpInjection.registerFactory<HelpBloc>(
      () => HelpBloc(
        getHelpCategories: helpInjection<GetHelpCategories>(),
        getHelpFaqs: helpInjection<GetHelpFaqs>(),
        getHelpGuides: helpInjection<GetHelpGuides>(),
        getHelpGuide: helpInjection<GetHelpGuide>(),
        getSupportChannels: helpInjection<GetSupportChannels>(),
        sendFaqFeedback: helpInjection<SendFaqFeedback>(),
      ),
    );
  }
}
