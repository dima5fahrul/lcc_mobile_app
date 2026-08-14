/// Account feature injection entry point.
///
/// Ordering inside: datasource → repository → usecase → blocs, mirroring
/// `NotificationsFeatureInjection.init()`.
///
/// ## Why `registerFactory` and not singletons
///
/// All three BLoCs hold one visit's view of one citizen: their profile form
/// buffer, their preference switches, their document wallet. A surviving
/// instance would hand all three to whoever signs in next on the same device —
/// the reason `NotificationsBloc`, `HelpBloc` and `ServiceBloc` are factories
/// too. The route builder owns the providers (`BlocProvider(create:)`), so the
/// instances are created and closed with the route.
///
/// ## Three BLoCs, not one (specs.md § 6.3)
///
/// The source runs three *independent* `useQuery` calls
/// (`AccountPage.tsx:189-191`) with independent loading and error states that
/// render in three different places. A single BLoC would have to model the
/// product of those states and would make `ssd.md` § 7.3's mandatory
/// loading/empty/error surfaces harder to get right, not easier. Password
/// change is a transient form action on [AccountProfileBloc], not a fourth
/// BLoC, matching the source's `useMutation` (`:269`).
library;

import '../../auth/domain/usecases/change_password.dart';
import '../../session/domain/usecases/get_profile.dart';
import '../../session/domain/usecases/update_profile.dart';
import '../domain/usecases/account_usecases.dart';
import '../presentation/bloc/account_documents_bloc.dart';
import '../presentation/bloc/account_preferences_bloc.dart';
import '../presentation/bloc/account_profile_bloc.dart';
import 'account_datasource_injection.dart';
import 'account_injection.dart';
import 'account_repository_injection.dart';
import 'account_usecase_injection.dart';

class AccountFeatureInjection {
  static Future<void> init() async {
    AccountDatasourceInjection.inject();
    AccountRepositoryInjection.inject();
    AccountUsecaseInjection.inject();

    accountInjection
      ..registerFactory<AccountProfileBloc>(
        () => AccountProfileBloc(
          getProfile: accountInjection<GetProfile>(),
          updateProfile: accountInjection<UpdateProfile>(),
          changePassword: accountInjection<ChangePassword>(),
        ),
      )
      ..registerFactory<AccountPreferencesBloc>(
        () => AccountPreferencesBloc(
          getPreferences: accountInjection<GetPreferences>(),
          savePreferences: accountInjection<SavePreferences>(),
        ),
      )
      ..registerFactory<AccountDocumentsBloc>(
        () => AccountDocumentsBloc(
          getDocuments: accountInjection<GetDocuments>(),
        ),
      );
  }
}
