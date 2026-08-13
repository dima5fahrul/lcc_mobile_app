/// Home tab — P0 placeholder.
///
/// The real screen (`lcc-app/src/app/components/HomePage.tsx`: hero, digital
/// ID card, quick actions, news, FAQ) is a later batch; the plan scopes P0-5
/// to `"Home (coming soon)" + sign-in CTA`.
///
/// The sign-in CTA is the port of `HomePage.tsx`'s
/// `onSignIn={() => onTabChange("account")}` on the logged-out hero, labelled
/// with the same `hero.idSignIn` string. It navigates to `/account`, not
/// straight to `/signin`, on purpose: `/account` is a protected path, so the
/// router's own auth gate converts it into `/signin?from=%2Faccount` and the
/// citizen lands back on Account after signing in. Hard-coding `/signin` here
/// would drop that intent and duplicate gate logic that already exists.
library;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/session/bloc/session_bloc.dart';
import '../../../../presentation/shell/tab_placeholder.dart';
import '../../../../utils/routes/app_name_routes.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocSelector<SessionBloc, SessionState, bool>(
      selector: (SessionState state) =>
          state.status == SessionStatus.authenticated,
      builder: (BuildContext context, bool isAuthenticated) {
        return TabPlaceholder(
          icon: Icons.home_outlined,
          title: 'layout.home'.tr(),
          subtitle: 'home.whatDoYouNeedSub'.tr(),
          action: isAuthenticated
              ? null
              : FilledButton.icon(
                  onPressed: () => context.go(AppNameRoutes.account),
                  icon: const Icon(Icons.login, size: 18),
                  label: Text('hero.idSignIn'.tr()),
                ),
        );
      },
    );
  }
}
