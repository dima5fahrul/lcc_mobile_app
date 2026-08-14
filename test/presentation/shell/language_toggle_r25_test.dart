/// **R-25 in the widget — local-first, unconditionally. B8-AC-19, B8-AC-18.**
///
/// The BLoC half of R-25 (authenticated-only, silent failure, the one-key body)
/// is `test/core/session/bloc/session_language_mirror_test.dart`. This file
/// asserts the half that only the widget can own:
///
/// > *the locale changes and `lcc.lang` is persisted even when the network call
/// > throws* — `LanguageToggle.tsx:70` runs `toggle()` **before and regardless
/// > of** `:71`'s mirror, because *"the UI must never wait on the network to
/// > change language."*
///
/// ## Why this is asserted with a FAILING client and not a working one
///
/// A test that toggles the language with a healthy backend passes whether the
/// two writes are ordered correctly or not — the locale ends up changed either
/// way. It is only when the mirror **throws** that the ordering becomes
/// observable, and that is the case a citizen on a Lao mobile network is
/// actually in. `FACTORY-RULES.md`'s Capability Rule: the criterion is
/// *language changes offline*, not *the mirror is wired up*.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lcc_mobile_app/core/constant/api_endpoint.dart';
import 'package:lcc_mobile_app/core/session/bloc/session_bloc.dart';
import 'package:lcc_mobile_app/core/storage/storage_keys.dart';
import 'package:lcc_mobile_app/presentation/shell/language_toggle.dart';

import '../../helpers/app_test_harness.dart';
import '../../helpers/core_test_helper.dart';
import '../../helpers/session_test_helper.dart';

void main() {
  tearDown(resetHarness);

  testWidgets(
      'B8-AC-19 — the locale flips and `lcc.lang` persists even when the '
      'mirror fails', (WidgetTester tester) async {
    final AppHarness harness = await bootHarness(seed: <String, String>{
      StorageKeys.accessToken: 'synthetic-access-token',
      StorageKeys.refreshToken: 'synthetic-refresh-token',
    });

    // A `PATCH /me/profile` that **fails**. This is the whole point: with a
    // healthy backend the assertions below pass whether or not the two local
    // writes precede the network one.
    //
    // ── Registered BEFORE the GET, and the order is load-bearing ────────────
    //
    // Measured while writing this test: `http_mock_adapter`'s `DioAdapter`
    // resolves a request by **path**, and the LAST registration for a path
    // wins — the HTTP method is not part of the match. Registering `onGet`
    // first and `onPatch` second makes the PATCH stub answer the boot's
    // `GET /me/profile` as well, so the session boots with this 500 and the
    // "failure is silent" assertion below fails against a session error the
    // mirror never caused. Cost: one debugging pass. Recorded here because
    // `/me/preferences` has the same GET+PUT shape and B7/B10 will hit it.
    harness.adapter.onPatch(
      ApiEndpoint.meProfile,
      (dynamic server) => server.reply(500, <String, dynamic>{
        'success': false,
        'message': 'the mirror is down',
        'code': 'SERVER_ERROR',
      }),
      data: <String, dynamic>{'preferred_lang': 'lo'},
    );

    // A profile so the session resolves to `authenticated` — the mirror is
    // gated on it, and a signed-out run would pass this test for the wrong
    // reason (no request to fail).
    harness.adapter.onGet(
      ApiEndpoint.meProfile,
      (dynamic server) => server.reply(200, okEnvelope(tCitizenProfileJson())),
    );

    await pumpAssembledApp(tester, harness);
    expect(
      Localizations.localeOf(tester.element(find.byType(LanguageToggle)))
          .languageCode,
      'en',
    );

    await tester.tap(find.byType(LanguageToggle));
    await tester.pumpAndSettle();

    // 1. The locale changed.
    expect(
      Localizations.localeOf(tester.element(find.byType(LanguageToggle)))
          .languageCode,
      'lo',
      reason: 'the mirror threw; the language must have changed anyway',
    );

    // 2. `lcc.lang` was written.
    expect(harness.store[StorageKeys.lang], 'lo');

    // 3. Nothing surfaced. No exception escaped into the framework, and the
    //    session is still authenticated — a 500 on the mirror must not read as
    //    a session problem.
    expect(tester.takeException(), isNull);
    expect(harness.sessionBloc.state.status, SessionStatus.authenticated);
    expect(harness.sessionBloc.state.errorMessage, isNull);
  });

  testWidgets(
      'B8-AC-20 in the assembled shell — a signed-out toggle still changes the '
      'language, and issues no PATCH', (WidgetTester tester) async {
    // No token seeded, so the session resolves to `unauthenticated`. No
    // `onPatch` stub is registered at all: `http_mock_adapter` throws on an
    // unstubbed request, so an unexpected mirror would surface as a thrown
    // exception rather than as a silent pass.
    final AppHarness harness = await bootHarness();

    await pumpAssembledApp(tester, harness);
    await tester.tap(find.byType(LanguageToggle));
    await tester.pumpAndSettle();

    expect(
      Localizations.localeOf(tester.element(find.byType(LanguageToggle)))
          .languageCode,
      'lo',
    );
    expect(harness.store[StorageKeys.lang], 'lo');
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'the toggle survives a tree with NO SessionBloc — the shell stays '
      'session-agnostic', (WidgetTester tester) async {
    // `app_shell.dart`'s own note: the shell is session-agnostic by design, and
    // B10's D-3 work pumps this widget directly. `LanguageToggle` therefore
    // uses a context read that *answers* rather than throws when no provider is
    // above it. Without this, adding R-25 would have broken every bare pump of
    // the top bar — a cross-batch break that would have surfaced as someone
    // else's red.
    final AppHarness harness = await bootHarness();

    await tester.pumpWidget(wrapWithLocalization(
      MaterialApp(
        home: Scaffold(
          body: Center(child: LanguageToggle(storage: harness.storage)),
        ),
      ),
    ));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(LanguageToggle));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(harness.store[StorageKeys.lang], 'lo');
  });
}
