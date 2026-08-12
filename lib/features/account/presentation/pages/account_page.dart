/// Account tab — P0 placeholder with a working sign-out.
///
/// A **protected** path (`AppRoutes._protectedPaths`), so the router guards it;
/// see `history_page.dart` for why there is no second in-page check.
///
/// Sign-out is real, not a placeholder: it dispatches `SessionSignOut` on the
/// app-wide `SessionBloc`, which revokes the refresh token best-effort, clears
/// `FlutterSecureStorage`, and emits `unauthenticated`. The router's
/// `refreshListenable` then re-runs `redirect`, finds `/account` protected and
/// the citizen unauthenticated, and sends them to `/signin?from=%2Faccount`.
/// Nothing here navigates by hand — doing so would race the gate and could
/// leave the app on a protected page with no session.
///
/// The button is only rendered once the session has resolved to
/// `authenticated`; during the boot hold (`initial` / `loading`) there is
/// nothing to sign out of yet.
///
/// The real screen (`lcc-app/src/app/components/AccountPage.tsx`: profile
/// header, document wallet, settings groups) is a later batch.
library;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../presentation/shell/tab_placeholder.dart';
import '../../../session/presentation/bloc/session_bloc.dart';

class AccountPage extends StatelessWidget {
  const AccountPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocSelector<SessionBloc, SessionState, bool>(
      selector: (SessionState state) =>
          state.status == SessionStatus.authenticated,
      builder: (BuildContext context, bool isAuthenticated) {
        return TabPlaceholder(
          icon: Icons.person_outline,
          title: 'layout.account'.tr(),
          action: isAuthenticated
              ? OutlinedButton.icon(
                  onPressed: () => BlocProvider.of<SessionBloc>(context)
                      .add(const SessionEvent.signOut()),
                  icon: const Icon(Icons.logout, size: 18),
                  label: Text('account.signOut'.tr()),
                )
              : null,
        );
      },
    );
  }
}
