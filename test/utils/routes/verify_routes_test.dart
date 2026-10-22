/// The three verify routes, driven through the assembled app.
///
/// The public verification endpoints are anonymous — "Two endpoints work
/// without login" (§ Public verification endpoints) — so the routes that call
/// them are public too: `/verify` is deliberately NOT in
/// `AppRoutes._protectedPaths`, and the two parameterised paths serve the
/// result page with the code from the path, exactly as the guide's deep-link
/// forms (`/v/<code>`, `/verify/<code>`, `#/verify/<code>`) carry it.
///
/// Reachability here is the certificate-routes sense, not merely "a GoRoute
/// matched": the route builder resolves `VerifyBloc` out of `verifyInjection`
/// (the same container `verify_injection_test.dart` proves end to end), and
/// the answer on screen is one only the network layer could have delivered.
///
/// **Why this file registers `VerifyFeatureInjection.init()` itself:**
/// `bootHarness` mirrors `DependencyInjection.init()` feature by feature, and
/// the verify container is registered here rather than in
/// `test/helpers/app_test_harness.dart` because no other assembled test
/// navigates to `/verify` — the same call-site-local pattern
/// `certificate_routes_test.dart` uses for `stubCertificateEndpoints`.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:lcc_mobile_app/core/constant/api_endpoint.dart';
import 'package:lcc_mobile_app/core/session/bloc/session_bloc.dart';
import 'package:lcc_mobile_app/features/verify/di/verify_feature_injection.dart';
import 'package:lcc_mobile_app/features/verify/presentation/pages/verify_code_entry_page.dart';
import 'package:lcc_mobile_app/features/verify/presentation/pages/verify_result_page.dart';
import 'package:lcc_mobile_app/utils/routes/app_name_routes.dart';

import '../../helpers/app_test_harness.dart';

GoRouter routerOf(WidgetTester tester) =>
    GoRouter.of(tester.element(find.byType(Navigator).first));

void main() {
  tearDown(resetHarness);

  /// The guide's § Public verification endpoints answer, served verbatim.
  void stubVerify(AppHarness harness) {
    harness.adapter.onGet(
      ApiEndpoint.verifyByCode('RES-7Q4K-19XD'),
      (dynamic server) => server.reply(200, <String, dynamic>{
        'success': true,
        'message': 'ok',
        'data': <String, dynamic>{
          'valid': true,
          'status': 'issued',
          'certificate_no': 'LA-RES-2026-000123',
          'document_type': 'RES',
          'copy': '',
          'layout': 'card',
          'service': <String, dynamic>{
            'en': 'Residence Certificate',
            'lo': '…',
          },
          'service_code': 'resident',
          'holder_name': 'P****** S********',
          'holders': <String>['P****** S********'],
          'issued_at': '2026-09-30',
          'valid_until': '2026-12-29',
          'issuing_office': <String, dynamic>{
            'en': 'District Office of Public Security, Chanthabuly',
            'lo': '…',
          },
          'issuer_contact': <String, dynamic>{
            'phone': '',
            'email': '',
            'address': '',
          },
          'verify_code': 'RES-7Q4K-19XD',
          'language': 'lo',
          'revoked_at': '',
          'revoke_reason': '',
          'replaced_by_certificate_no': '',
          'checks': <String, dynamic>{
            'signature': <String, dynamic>{
              'status': 'recorded',
              'provider': 'visual',
              'method': 'officer-otp',
              'signer_name': 'Vongdeuane XAYASONE',
              'signed_at': '2026-09-30T10:42:18+07:00',
              'ca': '',
              'format': '',
              'timestamp': '',
            },
            'record_hash': <String, dynamic>{
              'status': 'match',
              'algorithm': 'SHA-256',
            },
            'revocation': <String, dynamic>{
              'status': 'not-revoked',
              'checked_at': '2026-10-21T11:24:03+07:00',
            },
          },
          'checked_at': '2026-10-21T11:24:03+07:00',
        },
      }),
    );
  }

  testWidgets('/v/RES-7Q4K-19XD and /verify/RES-7Q4K-19XD both build the '
      'result page, with the answer on screen', (WidgetTester tester) async {
    final AppHarness harness = await bootHarness();
    stubVerify(harness);
    await VerifyFeatureInjection.init();
    await pumpAssembledApp(tester, harness);

    for (final String path in <String>[
      '/v/RES-7Q4K-19XD',
      '${AppNameRoutes.verify}/RES-7Q4K-19XD',
    ]) {
      routerOf(tester).go(path);
      await tester.pumpAndSettle();

      expect(routerOf(tester).state.uri.toString(), path);
      expect(find.byType(VerifyResultPage), findsOneWidget,
          reason: path);
      // The capability clause: a value only the network layer could have
      // delivered, proving the route → bloc → usecase → datasource chain.
      expect(find.text('LA-RES-2026-000123'), findsOneWidget, reason: path);
      expect(find.byType(NavigationBar), findsNothing,
          reason: 'a public deep-link surface is full-frame, like every other '
              'route outside the ShellRoute');
    }
  });

  testWidgets('/verify is reachable signed OUT — the endpoints are anonymous, '
      'so the route is public and never in _protectedPaths',
      (WidgetTester tester) async {
    final AppHarness harness = await bootHarness();
    await VerifyFeatureInjection.init();
    await pumpAssembledApp(tester, harness);

    expect(harness.sessionBloc.state.status, SessionStatus.unauthenticated);

    routerOf(tester).go(AppNameRoutes.verify);
    await tester.pumpAndSettle();

    expect(routerOf(tester).state.uri.toString(), AppNameRoutes.verify,
        reason: 'no redirect to /signin?from=… — a signed-out citizen can '
            'verify a certificate');
    expect(find.byType(VerifyCodeEntryPage), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);
  });
}
