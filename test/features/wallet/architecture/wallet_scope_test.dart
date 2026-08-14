/// B6a's scope and port-faithfulness criteria, mechanised.
///
/// Nine of § 7's criteria are written as greps — `B6-AC-9`, `-13`, `-14`,
/// `-15`, `-17`, `-19`, `-26`, `-45`, `-47`. A grep a human runs once at
/// hand-back is not a gate: it passes for exactly as long as nobody edits the
/// file. Each one is executed here instead, so the claim is re-checked on every
/// run and a later batch that breaks it finds out from its own build.
///
/// Several of these criteria are **negative** — "returns 0", "contains no".
/// A negative assertion over a path that does not exist passes for the wrong
/// reason, so every scan below first asserts it actually found files to read.
/// That is `guard_selftest_test.dart`'s discipline applied locally, and it is
/// the difference between "no violations" and "no evidence".
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:lcc_mobile_app/features/wallet/presentation/pages/wallet_page.dart';
import 'package:lcc_mobile_app/utils/routes/app_name_routes.dart';

/// Every `.dart` file under [dir], excluding generated `.freezed`/`.g` output —
/// which is machine-written and is not what any of these criteria are about.
List<File> _dartFiles(String dir) {
  final Directory d = Directory(dir);
  if (!d.existsSync()) return <File>[];
  return d
      .listSync(recursive: true)
      .whereType<File>()
      .where((File f) => f.path.endsWith('.dart'))
      .where((File f) => !f.path.endsWith('.freezed.dart'))
      .where((File f) => !f.path.endsWith('.g.dart'))
      .toList(growable: false);
}

/// `file:line -> text` for every line in [dir] matching [pattern].
///
/// [codeOnly] drops `//` and `///` lines. Several of § 7's criteria are written
/// as bare `grep -rn`, and taken literally they fail on **prose that documents
/// the very absence they require** — `B6-AC-45` says
/// `grep -rn "/applications" lib/features/wallet` must return 0, while the BLoC
/// doc comment that explains why bills are B6b's necessarily writes the string.
/// The same literal-vs-intended split `blocked.md` § 6 recorded for
/// `B6-AC-40`. The intended subject is code, so code is what is scanned, and
/// the divergence is reported rather than silently resolved.
List<String> _grep(String dir, RegExp pattern, {bool codeOnly = false}) {
  final List<String> hits = <String>[];
  for (final File f in _dartFiles(dir)) {
    final List<String> lines = f.readAsLinesSync();
    for (int i = 0; i < lines.length; i++) {
      if (codeOnly && lines[i].trimLeft().startsWith('//')) continue;
      if (pattern.hasMatch(lines[i])) {
        hits.add('${f.path}:${i + 1} -> ${lines[i].trim()}');
      }
    }
  }
  return hits;
}

const String kWallet = 'lib/features/wallet';
const String kPayment = 'lib/presentation/payment';

void main() {
  // The self-test. Every negative assertion below depends on these paths being
  // real and non-empty; without this, deleting the feature would turn the whole
  // file green.
  group('self-test — the scans reach real files', () {
    test('both scanned trees exist and are non-trivial', () {
      expect(_dartFiles(kWallet).length, greaterThanOrEqualTo(15));
      expect(_dartFiles(kPayment).length, greaterThanOrEqualTo(2));
    });

    test('the grep helper can actually find something', () {
      // If this ever returns empty the negative results below mean nothing.
      expect(_grep(kWallet, RegExp('class ')), isNotEmpty);
    });
  });

  // ───────────────────────────────────────────────────────────────────────────
  group('B6-AC-9 — G-L7 is exercised by real code, not only by a fixture', () {
    test('lib/presentation/payment imports ONLY features/*/domain/**', () {
      // `grep -rn "features/" lib/presentation/payment` must return only
      // `domain/` paths. The fifth `lib/presentation/` group exists because
      // `PaymentSection` is shared between the wallet and three form batches
      // (§ 6.2); the moment it reaches into one feature's `presentation/` or
      // `data/`, that sharing is a lie.
      final List<String> featureImports = _grep(
        kPayment,
        RegExp(r'''import\s+['"].*features/'''),
      );

      expect(
        featureImports,
        isNotEmpty,
        reason: 'AC-9 says this must be exercised by REAL code — if payment/ '
            'imports no feature at all, G-L7 is only tested by its fixture',
      );

      for (final String hit in featureImports) {
        expect(
          hit,
          contains('/domain/'),
          reason: 'a non-domain feature import in lib/presentation/payment',
        );
      }
    });

    test('and nothing from features/*/presentation or features/*/data', () {
      expect(
        _grep(kPayment, RegExp(r'features/[a-z_]+/(presentation|data)/'),
            codeOnly: true),
        isEmpty,
      );
    });
  });

  // ───────────────────────────────────────────────────────────────────────────
  group('B6-AC-15 — /me/transactions/:receipt_no is transport-only', () {
    test('no widget reaches meTransaction(', () {
      // § 6.4 rules the transport IN and the UI OUT, deliberately differing
      // from B9's ruling on an uncalled endpoint. The datasource test proves
      // the transport works; this proves nothing renders it.
      expect(
        _grep('$kWallet/presentation', RegExp(r'meTransaction\(')),
        isEmpty,
      );
      expect(_grep(kPayment, RegExp(r'meTransaction\(')), isEmpty);
    });

    test('but it IS wired in data/ — the endpoint is ported, not omitted', () {
      expect(_grep('$kWallet/data', RegExp(r'meTransaction\(')), isNotEmpty);
    });
  });

  // ───────────────────────────────────────────────────────────────────────────
  group('B6-AC-17 / B6-AC-19 — the formatters', () {
    final File formatting = File('$kWallet/domain/wallet_formatting.dart');

    test('groupThousands is used on the ENGLISH path only', () {
      // The single highest-risk line in the batch. Reusing it for Lao ships
      // `20,000 ₭` where the web shows `20.000 ₭`, and no tier can see it.
      final List<String> uses = formatting
          .readAsLinesSync()
          .where((String l) => l.contains('groupThousands('))
          .where((String l) => !l.trimLeft().startsWith('///'))
          .toList();

      expect(uses, isNotEmpty, reason: 'the English grouper must still be used');
      for (final String line in uses) {
        expect(
          line,
          isNot(contains('_groupThousandsLao')),
          reason: 'the Lao branch must NOT route through groupThousands',
        );
      }
      // And the Lao branch exists and is distinct.
      expect(formatting.readAsStringSync(), contains('_groupThousandsLao'));
    });

    test('the doc cites WalletPage.tsx:64 and the measured "20.000"', () {
      final String src = formatting.readAsStringSync();
      expect(src, contains('WalletPage.tsx:62-65'));
      expect(src, contains('20.000'));
    });

    test('formatLak is IMPORTED, never redefined under features/wallet', () {
      expect(_grep(kWallet, RegExp(r'String formatLak')), isEmpty);
      expect(
        formatting.readAsStringSync(),
        contains("home/domain/home_formatting.dart"),
      );
    });
  });

  // ───────────────────────────────────────────────────────────────────────────
  group('B6-AC-26 — no timer, no polling, no refresh-on-resume (B6-DIV-4)', () {
    test('neither tree mentions Timer, periodic, an observer or a refresher',
        () {
      // `hooks.ts`'s `useQuery` installs no interval, no focus listener and no
      // window revalidation, so the wallet is stale between actions and the
      // port is stale with it. Adding pull-to-refresh would make the app
      // BETTER than its source — a divergence no fidelity tier can see, and the
      // same class of change B9 refused for the bell.
      final RegExp banned =
          RegExp(r'\b(Timer|periodic|WidgetsBindingObserver|RefreshIndicator)\b');

      for (final String dir in <String>[kWallet, kPayment]) {
        final List<String> hits = _grep(dir, banned)
            // Doc comments may DISCUSS the prohibition; code may not enact it.
            .where((String h) => !RegExp(r'-> ///').hasMatch(h))
            .where((String h) => !RegExp(r'-> //').hasMatch(h))
            .toList();
        expect(hits, isEmpty, reason: 'in $dir');
      }
    });

    test('and the BLoC imports no dart:async at all', () {
      expect(
        File('$kWallet/presentation/bloc/wallet_bloc.dart')
            .readAsStringSync()
            .contains("import 'dart:async'"),
        isFalse,
      );
    });
  });

  // ───────────────────────────────────────────────────────────────────────────
  group('B6-AC-45 — B6a contains no reference to applications', () {
    test('no /applications path anywhere under features/wallet', () {
      expect(_grep(kWallet, RegExp(r'/applications'), codeOnly: true), isEmpty);
    });

    test('the only "application" mentions are the documented TODO(B6b) stub',
        () {
      final List<String> hits = _grep(
        kWallet,
        RegExp('application', caseSensitive: false),
        codeOnly: true,
      );

      for (final String hit in hits) {
        // `applicationId` / `application_id` are fields ON `Transaction`
        // (`types.ts:526`) — wire data the receipts list already receives, not
        // a read of B7a's endpoint. Everything else must be gone.
        final bool allowed = hit.contains('applicationId') ||
            hit.contains('application_id');
        expect(
          allowed,
          isTrue,
          reason: 'undocumented application reference in B6a: $hit',
        );
      }
    });

    test('the empty bill list is a NAMED constant, not an inline []', () {
      final String bloc =
          File('$kWallet/presentation/bloc/wallet_bloc.dart').readAsStringSync();
      expect(bloc, contains('kBillsDueB6b'));
      expect(bloc, contains('TODO(B6b)'));
    });
  });

  // ───────────────────────────────────────────────────────────────────────────
  group('B6-AC-47 — draft mode is absent from the whole of lib/', () {
    test('none of the seven draft-only identifiers appear', () {
      // § 6.3: B6 owns the pay capability and LIVE mode only. Draft mode
      // (`PaymentSection`'s other half) belongs to the form batches. Scanning
      // all of `lib/` rather than just my two trees is deliberate — the
      // criterion is that this code does not exist anywhere yet.
      final RegExp draft = RegExp(
        r'\b(LAO_BANKS|isPaymentValid|cardCvv|cardExpiry|methodQr|methodBank|methodCard)\b',
      );

      final List<String> hits = _grep('lib', draft);
      expect(hits, isEmpty, reason: hits.join('\n'));
    });

    test('but the payment i18n namespace still carries its draft-only keys',
        () {
      // The namespace is ported WHOLE (§ 6.13). `methodQr`/`methodBank`/
      // `methodCard` exist as i18n keys and must not exist as Dart identifiers
      // — the two halves of AC-47, and the second is why the first is not
      // simply "delete the keys".
      final String en = File('assets/i18n/en.json').readAsStringSync();
      for (final String key in <String>['methodQr', 'methodBank', 'methodCard']) {
        expect(en, contains('"$key"'), reason: '$key must survive in i18n');
      }
    });
  });

  // ───────────────────────────────────────────────────────────────────────────
  group('B6-AC-13 / B6-AC-14 — the shared files', () {
    test('api_endpoint.dart keeps baseUrl and the release HTTPS guard', () {
      // The deletions half of AC-13 is a `git diff --numstat` claim and is
      // reported in qa-report.md; what is checkable in-process is that the two
      // frozen constructs still exist and were not rewritten around.
      final String src =
          File('lib/core/constant/api_endpoint.dart').readAsStringSync();
      expect(src, contains('baseUrl'));
      expect(src, contains('https'));
      // And that B6a's five paths landed.
      for (final String p in <String>[
        '/me/wallet',
        '/me/wallet/entries',
        '/me/wallet/topup',
        '/me/transactions',
        '/payment-methods',
      ]) {
        expect(src, contains("'$p'"), reason: 'missing endpoint $p');
      }
    });

    test('B6a added no pay endpoint — /applications/:id/pay is B6b\'s', () {
      expect(
        File('lib/core/constant/api_endpoint.dart')
            .readAsStringSync()
            .contains('/pay\''),
        isFalse,
      );
    });
  });

  // ───────────────────────────────────────────────────────────────────────────
  group('security items 1 and 2 — no money datum persisted or logged', () {
    test('no storage API is reachable from either tree', () {
      // Item 1. SSD § 12 forbids persisting money data and B6 is the batch that
      // would break it first. Structural rather than behavioural: if the
      // symbols are not imported, no balance can be written by accident.
      final RegExp storage = RegExp(
        r'\b(FlutterSecureStorage|SharedPreferences|StorageService|Hive|File\()',
      );

      for (final String dir in <String>[kWallet, kPayment]) {
        final List<String> hits = _grep(dir, storage)
            .where((String h) => !RegExp(r'-> ///|-> //').hasMatch(h))
            .toList();
        expect(hits, isEmpty, reason: 'in $dir: ${hits.join('\n')}');
      }
    });

    test('nothing prints', () {
      // Item 2. No `print`, `debugPrint` or `log()` at all — so none of them
      // can be carrying a balance, an account number or a receipt number.
      final RegExp printing = RegExp(r'\b(print|debugPrint|log)\s*\(');

      for (final String dir in <String>[kWallet, kPayment]) {
        final List<String> hits = _grep(dir, printing)
            .where((String h) => !RegExp(r'-> ///|-> //').hasMatch(h))
            .toList();
        expect(hits, isEmpty, reason: 'in $dir: ${hits.join('\n')}');
      }
    });

    test('B6 adds no second Dio and no second interceptor list (item 3)', () {
      // `chucker_flutter` (V-9) persists plaintext captures and B6 is the first
      // batch whose traffic is money. The mitigation is that there is exactly
      // one client, the `kDebugMode`-gated one, and B6 re-exports it.
      for (final String dir in <String>[kWallet, kPayment]) {
        expect(_grep(dir, RegExp(r'\bDio\(')), isEmpty, reason: 'in $dir');
        expect(_grep(dir, RegExp(r'interceptors\.')), isEmpty, reason: 'in $dir');
      }
      // And the wallet datasource container re-exports the ROOT client.
      expect(
        File('$kWallet/di/wallet_datasource_injection.dart').readAsStringSync(),
        contains('injection<ApiClient>()'),
      );
    });
  });

  // ───────────────────────────────────────────────────────────────────────────
  group('B6-AC-11 — the 5-file DI pattern and the test mirror', () {
    test('all five DI files exist', () {
      for (final String f in <String>[
        'wallet_injection',
        'wallet_datasource_injection',
        'wallet_repository_injection',
        'wallet_usecase_injection',
        'wallet_feature_injection',
      ]) {
        expect(File('$kWallet/di/$f.dart').existsSync(), isTrue, reason: f);
      }
    });

    test('the feature has the four layers', () {
      for (final String layer in <String>['domain', 'data', 'presentation', 'di']) {
        expect(Directory('$kWallet/$layer').existsSync(), isTrue, reason: layer);
      }
    });
  });

  // ───────────────────────────────────────────────────────────────────────────
  group('B6-AC-50 / V-10 — the signed-out `?from=` value is not widened', () {
    test('kWalletSignInLocation is the encoding of AppNameRoutes.wallet', () {
      // The constant hardcodes `%2Fwallet` because `Uri.encodeComponent` is not
      // a `const` expression and the AC demands a compile-time constant. That
      // buys a silent desync hazard if `AppNameRoutes.wallet` ever changes.
      // This is the assertion that closes it — the literal is checked against
      // the value it claims to be the encoding of, rather than trusted.
      expect(
        kWalletSignInLocation,
        '${AppNameRoutes.signin}?from=${Uri.encodeComponent(AppNameRoutes.wallet)}',
      );
    });

    test('it is not composed from anything a citizen can influence', () {
      // V-10 is about `?from=` being fed a runtime-composed location. B6a is a
      // new caller, so the widening is checked at the source: the only `?from=`
      // construction under features/wallet is this one constant, and no call
      // site builds a second one out of `matchedLocation`, `uri`, or a query
      // parameter.
      final List<String> composed = _grep(
        kWallet,
        RegExp(r'\?from=(?!%2Fwallet)'),
        codeOnly: true,
      );
      expect(
        composed,
        isEmpty,
        reason: 'a second, non-constant ?from= appeared under features/wallet',
      );

      for (final String bad in <String>[
        'matchedLocation',
        'GoRouterState.of',
        'uri.queryParameters',
      ]) {
        expect(
          _grep(kWallet, RegExp(RegExp.escape(bad)), codeOnly: true),
          isEmpty,
          reason: '`$bad` near the redirect would widen V-10',
        );
      }
    });
  });
}
