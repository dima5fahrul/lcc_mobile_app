/// Optional named-route constants.
///
/// The flutter-boilerplate uses the path string itself as the `GoRoute.name`
/// (see `app_routes.dart`: `name: AppNameRoutes.movieList`). This file mirrors
/// that convention — the names below are the same strings as
/// [AppNameRoutes] paths — but exposes them as a separate surface so a call
/// site can write `context.goNamed(RouteNames.home)` without hard-coding a
/// path literal.
///
/// Kept in lock-step with [AppNameRoutes]: every constant here MUST equal its
/// [AppNameRoutes] twin. If the two drift, the `name:` on a `GoRoute` will not
/// resolve and `goNamed` will throw at runtime.
library;

import 'app_name_routes.dart';

class RouteNames {
  RouteNames._();

  static const String home = AppNameRoutes.home;
  static const String signin = AppNameRoutes.signin;
  static const String service = AppNameRoutes.service;
  static const String history = AppNameRoutes.history;
  static const String wallet = AppNameRoutes.wallet;
  static const String account = AppNameRoutes.account;
  static const String help = AppNameRoutes.help;
  static const String news = AppNameRoutes.news;
  static const String debug = AppNameRoutes.debug;
}
