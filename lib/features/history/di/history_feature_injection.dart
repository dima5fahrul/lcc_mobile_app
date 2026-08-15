/// History feature injection entry point.
///
/// **Must run after `ApplicationFeatureInjection.init()`** — the use-case
/// closures in `HistoryUsecaseInjection` reach into `applicationInjection`.
/// `application` sorts before `history`, so DI-6's alphabetical placement and
/// the real dependency agree; unlike chat→help there is no ordering deviation
/// to record.
///
/// ## One BLoC, and it is a factory
///
/// `ssd.md`:623 and `B7-AC-14`: B7 has exactly two BLoCs across both
/// sub-batches — `HistoryBloc` here and B7b's `HistoryDetailBloc`. No
/// per-widget BLoC, no third.
///
/// `registerFactory`, not a lazy singleton, for the reason `app_routes.dart`
/// records for `ServiceBloc`: the provider that creates one closes it on the
/// way out, and this BLoC holds a live 350 ms debounce `Timer` plus one visit's
/// page number, filter and search term. A surviving instance would hand the
/// next visit all four.
library;

import '../../application/domain/usecases/application_usecases.dart';
import '../presentation/bloc/history_bloc.dart';
import '../presentation/bloc/history_detail_bloc.dart';
import 'history_injection.dart';
import 'history_usecase_injection.dart';

class HistoryFeatureInjection {
  static Future<void> init() async {
    HistoryUsecaseInjection.inject();

    historyInjection
      ..registerFactory<HistoryBloc>(
        () => HistoryBloc(
          listApplications: historyInjection<ListApplications>(),
          getStatusPipeline: historyInjection<GetStatusPipeline>(),
        ),
      )
      // B7b's second and last BLoC. `registerFactory` for the same reason the
      // list's is one, and one more: it carries the open case's id and two
      // generation counters, so a surviving instance would hand the next case
      // the previous one's in-flight answers (`hooks.ts:73`).
      ..registerFactory<HistoryDetailBloc>(
        () => HistoryDetailBloc(
          getApplication: historyInjection<GetApplication>(),
          getApplicationTimeline: historyInjection<GetApplicationTimeline>(),
        ),
      );
  }
}
