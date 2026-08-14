/// Standing the notification bell up in a test.
///
/// ## Why this lives here and not in `test/helpers/`
///
/// Every other feature's helper is `test/helpers/<feature>_test_helper.dart`.
/// B9a's § 3.1 scope table names `test/features/notifications/**` and
/// `test/presentation/shell/**` and **does not name `test/helpers/`**, and
/// B9-AC-48 makes a path outside that table a scope finding. So the helper sits
/// inside the feature's own test tree. A deviation from house convention,
/// stated rather than left for a reviewer to notice.
///
/// ## The fixtures are SYNTHETIC and the loader says so out loud
///
/// `test/fidelity/oracle.dart`'s `loadApi` reads
/// `docs/fidelity-baseline/.../oracle/api/`, which holds **real recorded
/// staging payloads**. B9's two fixtures are not that and must not be reached
/// through the same door: they live under `test/fidelity/fixtures/api/` and are
/// read by [loadSyntheticApi] below, whose name is the reminder.
///
/// B2-AC-36's *"real recorded staging payloads"* standard **cannot be met** for
/// any `/me/*` endpoint in this programme — `manifest-authenticated.md`
/// § Session records that re-authenticating burns a real SMS OTP behind a
/// randomised captcha — so it is reported NOT EVALUATED with that reason and
/// never PASS (specs.md § 2.2 Finding I, B9-AC-57).
library;

import 'dart:convert';
import 'dart:io';

import 'package:dartz/dartz.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lcc_mobile_app/core/error/failure.dart';
import 'package:lcc_mobile_app/features/notifications/data/models/notification_wire.dart';
import 'package:lcc_mobile_app/features/notifications/domain/entities/notification_entities.dart';
import 'package:lcc_mobile_app/features/notifications/domain/repositories/notification_repository.dart';
import 'package:lcc_mobile_app/features/notifications/domain/usecases/notification_usecases.dart';
import 'package:lcc_mobile_app/features/notifications/presentation/bloc/notifications_bloc.dart';
import 'package:lcc_mobile_app/features/notifications/presentation/widgets/notification_menu_sheet.dart';
import 'package:lcc_mobile_app/presentation/theme/app_theme.dart';

import '../../helpers/app_test_harness.dart';
import '../../helpers/core_test_helper.dart';

/// The instant every relative-time expectation in the Tier 1 oracle is pinned
/// to. See `oracle/tier1/notifications.en.json`'s `provenance.clock`.
final DateTime kNotificationsOracleClock =
    DateTime.parse('2026-08-14T00:00:00.000Z');

// ─────────────────────────────────────────────────────────────────────────────
// Fixtures — SYNTHETIC, declared as such in their own `_capture.provenance`
// ─────────────────────────────────────────────────────────────────────────────

const String _fixtureDir = 'test/fidelity/fixtures/api';

Map<String, dynamic> _readFixture(String name) {
  final File file = File('$_fixtureDir/$name.json');
  if (!file.existsSync()) {
    throw StateError(
      'Missing fixture `${file.path}`. `flutter test` runs from the package '
      'root; if this is absent the suite was launched from somewhere else, or '
      'the checkout is incomplete.',
    );
  }
  return json.decode(file.readAsStringSync()) as Map<String, dynamic>;
}

/// `test/fidelity/fixtures/api/<name>.json` — the whole envelope.
///
/// Named for what it is. See the library doc for why it is not `loadApi`.
Map<String, dynamic> loadSyntheticApi(String name) => _readFixture(name);

/// A fixture wrapped in the envelope every real response carries.
///
/// The files under `test/fidelity/fixtures/api/` hold `{_capture, data[, meta]}`
/// and **no** `success`/`message` — that is the convention every sibling
/// follows, because the rig that serves them
/// (`test/fidelity/execute_forms_oracle.mjs`) builds the envelope itself. A
/// fixture carrying its own would be unwrapped twice. Anything driving a real
/// `ApiClient` therefore has to add it, and this is that.
Map<String, dynamic> syntheticEnvelope(String name) {
  final Map<String, dynamic> fixture = loadSyntheticApi(name);
  return okEnvelope(
    fixture['data'],
    meta: fixture['meta'] as Map<String, dynamic>?,
  );
}

/// The eight synthetic notification rows, parsed by the **production** `*From`
/// function. Parsing them any other way would test the fixture, not the parser.
List<CitizenNotification> syntheticNotifications() =>
    (loadSyntheticApi('me-notifications')['data'] as List<dynamic>)
        .cast<Map<String, dynamic>>()
        .map(citizenNotificationFrom)
        .toList(growable: false);

/// The synthetic unread count, through the production reader.
int syntheticUnreadCount() =>
    unreadCountFrom(loadSyntheticApi('me-notifications-unread-count')['data']);

// ─────────────────────────────────────────────────────────────────────────────
// The repository double
// ─────────────────────────────────────────────────────────────────────────────

/// Counts every call, because most of B9a's criteria are **invocation-count**
/// claims rather than rendering claims: "the bell does not poll" (B9-AC-18) and
/// "marking one read refetches the count" (B9-AC-19) are both statements about
/// how many times a use case ran, and neither is visible in a rendered tree.
class FakeNotificationRepository implements NotificationRepository {
  late Either<Failure, List<CitizenNotification>> list =
      Right<Failure, List<CitizenNotification>>(syntheticNotifications());

  late Either<Failure, int> count =
      Right<Failure, int>(syntheticUnreadCount());

  Either<Failure, Unit> readOne = const Right<Failure, Unit>(unit);
  Either<Failure, Unit> readAll = const Right<Failure, Unit>(unit);

  final List<int> listCalls = <int>[];
  int countCalls = 0;
  final List<String> readIds = <String>[];
  int readAllCalls = 0;

  /// Held open so a test can observe the in-flight window — the one a
  /// concurrent second dispatch would race into.
  Duration latency = Duration.zero;

  Future<void> _wait() async {
    if (latency > Duration.zero) await Future<void>.delayed(latency);
  }

  void failEverything() {
    const Failure f = Failure('stubbed failure');
    list = const Left<Failure, List<CitizenNotification>>(f);
    count = const Left<Failure, int>(f);
    readOne = const Left<Failure, Unit>(f);
    readAll = const Left<Failure, Unit>(f);
  }

  void emptyList() =>
      list = const Right<Failure, List<CitizenNotification>>(
        <CitizenNotification>[],
      );

  @override
  Future<Either<Failure, List<CitizenNotification>>> getNotifications({
    required int perPage,
  }) async {
    listCalls.add(perPage);
    await _wait();
    return list;
  }

  @override
  Future<Either<Failure, int>> getUnreadCount() async {
    countCalls++;
    await _wait();
    return count;
  }

  @override
  Future<Either<Failure, Unit>> markRead(String id) async {
    readIds.add(id);
    await _wait();
    return readOne;
  }

  @override
  Future<Either<Failure, Unit>> markAllRead() async {
    readAllCalls++;
    await _wait();
    return readAll;
  }
}

/// A [NotificationsBloc] over [repository], wired exactly as production wires
/// it — through the real use cases, not around them.
NotificationsBloc notificationsBlocOver(
  FakeNotificationRepository repository,
) =>
    NotificationsBloc(
      getNotifications: GetNotifications(repository: repository),
      getUnreadCount: GetUnreadCount(repository: repository),
      markNotificationRead: MarkNotificationRead(repository: repository),
      markAllNotificationsRead:
          MarkAllNotificationsRead(repository: repository),
    );

// ─────────────────────────────────────────────────────────────────────────────
// Pumping
// ─────────────────────────────────────────────────────────────────────────────

/// Pumps [NotificationMenuSheet] under [bloc], with no shell, no router and no
/// container.
///
/// **That this is possible is the point of B9a.** The panel is a feature widget
/// composed into the chrome through `AppTopBar.trailingActions`; if it had been
/// written into `lib/presentation/shell/` it would need the shell, and the
/// shell would need the feature's BLoC type — the edge `ssd.md`:255 forbids and
/// G-L7 now fails the build over.
///
/// **Does not settle.** The loading branch holds a `CircularProgressIndicator`,
/// whose animation never completes; `pumpAndSettle` would time out. Callers
/// pump explicitly, as `pumpHelpPage` does for the same reason.
Future<void> pumpNotificationMenu(
  WidgetTester tester,
  NotificationsBloc bloc, {
  Locale locale = const Locale('en'),
  DateTime? clock,
  void Function(CitizenNotification)? onOpenNotification,
}) async {
  tester.view.devicePixelRatio = 1.0;
  tester.view.physicalSize = const Size(390, 1400);
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    wrapWithLocalization(
      startLocale: locale,
      Builder(
        builder: (BuildContext context) => MaterialApp(
          theme: AppTheme.light(),
          localizationsDelegates: context.localizationDelegates,
          supportedLocales: context.supportedLocales,
          locale: context.locale,
          home: Scaffold(
            body: Center(
              child: SingleChildScrollView(
                child: BlocProvider<NotificationsBloc>.value(
                  value: bloc,
                  child: NotificationMenuSheet(
                    now: clock,
                    onSignIn: () {},
                    onViewAll: () {},
                    onOpenNotification: onOpenNotification ?? (_) {},
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
}
