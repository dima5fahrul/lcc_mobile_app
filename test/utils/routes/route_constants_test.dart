/// Route path and name constants.
///
/// GOR-245 § 4.2 freezes the path strings — a deep link or a saved shortcut
/// that stops resolving is a silent regression no widget test would catch.
/// `RouteNames`'s own doc states the invariant these tests enforce: every
/// constant must equal its `AppNameRoutes` twin, or `context.goNamed` throws at
/// runtime rather than failing to compile.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:lcc_mobile_app/utils/routes/app_name_routes.dart';
import 'package:lcc_mobile_app/utils/routes/route_names.dart';

void main() {
  test('the frozen path strings are unchanged (GOR-245 § 4.2)', () {
    expect(AppNameRoutes.home, '/');
    expect(AppNameRoutes.signin, '/signin');
    expect(AppNameRoutes.service, '/service');
    expect(AppNameRoutes.history, '/history');
    expect(AppNameRoutes.wallet, '/wallet');
    expect(AppNameRoutes.account, '/account');
    expect(AppNameRoutes.help, '/help');
    expect(AppNameRoutes.news, '/news');
    expect(AppNameRoutes.debug, '/debug');
  });

  test('every RouteNames constant equals its AppNameRoutes twin', () {
    expect(RouteNames.home, AppNameRoutes.home);
    expect(RouteNames.signin, AppNameRoutes.signin);
    expect(RouteNames.service, AppNameRoutes.service);
    expect(RouteNames.history, AppNameRoutes.history);
    expect(RouteNames.wallet, AppNameRoutes.wallet);
    expect(RouteNames.account, AppNameRoutes.account);
    expect(RouteNames.help, AppNameRoutes.help);
    expect(RouteNames.news, AppNameRoutes.news);
    expect(RouteNames.debug, AppNameRoutes.debug);
  });
}
