/// Route path constants.
///
/// GOR-245 § 4.2 freezes the path strings — a deep link or a saved shortcut
/// that stops resolving is a silent regression no widget test would catch.
///
/// **N-4 (B2a, SSD § 9.2).** `lib/utils/routes/route_names.dart` is deleted.
/// It held nine constants each defined as `= AppNameRoutes.x`, and the second
/// test in this file used to assert that the two surfaces had not drifted. A
/// test whose job is to prove one copy still equals the other is the strongest
/// available argument for not having two copies, so `GoRoute.name` now takes
/// the `AppNameRoutes` constant directly. What survives here is the half that
/// tests something the compiler cannot: the literal path strings, plus a scan
/// proving the deleted surface has no remaining references.
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:lcc_mobile_app/utils/routes/app_name_routes.dart';

import '../../architecture/layering_rules.dart';

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

  test('N-4 — no `RouteNames` reference survives in lib/ (B2-AC-37)', () {
    expect(
      File('lib/utils/routes/route_names.dart').existsSync(),
      isFalse,
      reason: 'SSD § 9.2 N-4 deletes this file outright.',
    );

    // Comment-stripped, for the same reason G-L5 strips: the deletion is worth
    // *explaining* in `app_routes.dart`'s library doc, and a raw-text scan
    // would make the only way to green be deleting the explanation.
    final RegExp whole =
        RegExp(r'(?<![A-Za-z0-9_$])RouteNames(?![A-Za-z0-9_$])');

    final List<String> offenders = scanTree(kLibDir)
        .where((DartFile f) => whole.hasMatch(f.code))
        .map((DartFile f) => f.path)
        .toList(growable: false);

    expect(
      offenders,
      isEmpty,
      reason: 'All seven `RouteNames.*` uses were `name:` arguments in '
          '`app_routes.dart` and are now `AppNameRoutes.*`, which is the value '
          'they already resolved to — the route names are byte-identical. '
          'Offenders:\n  ${offenders.join('\n  ')}',
    );
  });
}
