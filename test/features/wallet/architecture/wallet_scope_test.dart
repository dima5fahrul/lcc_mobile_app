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
        reason:
            'AC-9 says this must be exercised by REAL code — if payment/ '
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
        _grep(
          kPayment,
          RegExp(r'features/[a-z_]+/(presentation|data)/'),
          codeOnly: true,
        ),
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

      expect(
        uses,
        isNotEmpty,
        reason: 'the English grouper must still be used',
      );
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
    test('neither tree mentions Timer, periodic, an observer or a refresher', () {
      // `hooks.ts`'s `useQuery` installs no interval, no focus listener and no
      // window revalidation, so the wallet is stale between actions and the
      // port is stale with it. Adding pull-to-refresh would make the app
      // BETTER than its source — a divergence no fidelity tier can see, and the
      // same class of change B9 refused for the bell.
      final RegExp banned = RegExp(
        r'\b(Timer|periodic|WidgetsBindingObserver|RefreshIndicator)\b',
      );

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
        File(
          '$kWallet/presentation/bloc/wallet_bloc.dart',
        ).readAsStringSync().contains("import 'dart:async'"),
        isFalse,
      );
    });
  });

  // ───────────────────────────────────────────────────────────────────────────
  //
  // **`B6-AC-45` IS RETIRED HERE, BY B6b, AND THAT IS NOT A WEAKENING.**
  //
  // The criterion reads *"B6a contains no reference to applications"* and is
  // tagged **B6a** in specs.md § 7.7. It is a statement about the state of the
  // tree *between* the two sub-batches: B6a shipped the Bills Due card's empty
  // branch from a named compile-time-empty constant with a `TODO(B6b)`, and the
  // criterion existed so that "B6a shipped and Bills Due works" could never be
  // believed by accident while there was no query.
  //
  // B6b's entire job is to add that query (§ 2.3: *"B6b replaces the empty list
  // with the real query"*). So AC-45 is **unsatisfiable by construction once
  // B6b lands** — every one of its three assertions must now be false, and a
  // version of them that still passed would only do so by asserting something
  // other than what it says. The spec does not state this explicitly anywhere;
  // it is recorded in B6b's hand-back and in `architecture-review.md`.
  //
  // What replaces it is the *inverse* claim, and it is the one that stays true
  // for the rest of the programme: the wallet reads `/applications` **only**
  // through B7a's domain interface. That is the § 2.3 ruling with teeth — the
  // failure it catches is a second `/applications` datasource, which v1.0 of
  // the spec very nearly mandated.
  group('B6b § 2.3 — the /applications read goes through B7a, not a second '
      'datasource', () {
    test('features/wallet builds no /applications URL of its own', () {
      // The pay POST reaches its path through `ApiEndpoint.applicationPay(id)`
      // and the Bills Due read through `ListApplications`; neither concatenates
      // a path here. Doc comments quote the endpoints freely — `codeOnly`
      // strips them — and that is the point: the endpoints are *named* in this
      // tree and *built* in exactly one other.
      final List<String> hits = _grep(
        kWallet,
        RegExp(r'/applications'),
        codeOnly: true,
      );

      for (final String hit in hits) {
        // The one legitimate code occurrence, and it is **not a URL**:
        // `_object(data, 'POST /applications/:id/pay')` passes a human-readable
        // label into the datasource's shape-error message
        // (`wallet_remote_datasource.dart:204`), so a malformed pay response
        // says which call produced it. It is never concatenated into a request
        // and never reaches Dio. Named explicitly rather than loosened with a
        // broader pattern, so a *second* occurrence still fails this test.
        expect(
          hit.contains("_object(data, 'POST /applications/:id/pay')"),
          isTrue,
          reason: 'features/wallet built an /applications path itself: $hit',
        );
      }
    });

    test('features/wallet imports nothing from features/application/data '
        'or /presentation (G-L3)', () {
      expect(
        _grep(
          kWallet,
          RegExp(r'''import\s+'[^']*application/(data|presentation)/'''),
        ),
        isEmpty,
      );
    });

    test('ListPendingBills composes B7a use case rather than a repository', () {
      final String usecase = File(
        '$kWallet/domain/usecases/list_pending_bills.dart',
      ).readAsStringSync();
      // The whole mechanism in one line: it holds a `ListApplications`, which
      // is `features/application/domain/`, and it holds no repository at all.
      expect(usecase, contains('final ListApplications listApplications;'));
      expect(usecase.contains('ApplicationRepository'), isFalse);
    });

    test('the DI closure resolves it out of applicationInjection', () {
      final String di = File(
        '$kWallet/di/wallet_usecase_injection.dart',
      ).readAsStringSync();
      expect(di, contains('applicationInjection<ListApplications>()'));
    });

    test('B6a\'s kBillsDueB6b stub is GONE, not left beside the real list', () {
      // A stub-guard that outlives its stub is a test that can only pass by
      // being wrong. If this ever fails, someone restored the constant and the
      // Bills Due card now has two sources of truth.
      //
      // `codeOnly` because `wallet_bills_due_section.dart`'s library doc says
      // in prose that the constant is gone and why — that sentence is the
      // record, and a grep that counted it would make this test unfailable in
      // the one direction that matters.
      expect(_grep(kWallet, RegExp('kBillsDueB6b'), codeOnly: true), isEmpty);
    });
  });

  // ───────────────────────────────────────────────────────────────────────────
  group('B6-AC-10 — lib/presentation/payment resolves nothing and knows no '
      'BLoC', () {
    // Added by B6b, because B6b is the sub-batch the criterion is tagged to and
    // the sub-batch that lands the four widgets it is about. § 6.2 states the
    // rule and the reason in one sentence: the group *"owns the widgets and
    // takes its data as parameters and callbacks. It resolves nothing, injects
    // nothing, and knows no BLoC"* — which is what keeps B7 able to mount
    // `LivePaymentSection` over `features/history`'s BLoC without a second
    // copy, and what G-L5 and G-L7 enforce at the build.
    //
    // Scanned across the WHOLE directory, F1's draft files included: the rule
    // is a property of the group, not of one batch's half of it, and a
    // violation on either side breaks the same guarantee.

    test('the scan actually found files — a negative over an empty path passes '
        'for the wrong reason', () {
      expect(_dartFiles(kPayment).length, greaterThanOrEqualTo(6));
    });

    test('no BlocProvider, no BlocBuilder, no context.read', () {
      expect(
        _grep(
          kPayment,
          RegExp(r'\b(BlocProvider|BlocBuilder|BlocListener|BlocConsumer)\b'),
          codeOnly: true,
        ),
        isEmpty,
      );
      expect(
        _grep(kPayment, RegExp(r'context\.(read|watch)<'), codeOnly: true),
        isEmpty,
      );
    });

    test('no *Injection, no di/ import, no GetIt (G-L5)', () {
      expect(
        _grep(kPayment, RegExp(r'\w+Injection\b'), codeOnly: true),
        isEmpty,
      );
      expect(_grep(kPayment, RegExp(r"import '[^']*\bdi/")), isEmpty);
      expect(_grep(kPayment, RegExp(r'\bGetIt\b'), codeOnly: true), isEmpty);
    });

    test('no direct use-case call — the charge is a callback', () {
      // The specific shape § 6.2 forbids: `LivePaymentSection` must not call
      // `PayApplication` itself. Importing a `usecases/` library at all is the
      // checkable proxy, and it is stricter than the criterion rather than
      // looser.
      expect(_grep(kPayment, RegExp(r"import '[^']*/usecases/")), isEmpty);

      // And the positive half, so this group cannot pass with the callback
      // deleted: the charge really does leave as a function parameter.
      final String live = File(
        '$kPayment/live_payment_section.dart',
      ).readAsStringSync();
      expect(
        live,
        contains('final Future<void> Function(String methodCode) onCharge;'),
      );
    });

    test('B6-AC-31 — no payment-method code literal anywhere in the group', () {
      // `grep -rn "'laoqr'|\"laoqr\"|'wallet'" lib/presentation/payment` → 0.
      // Run as the criterion writes it, and it passes: the enum member
      // `PaymentMethodKind.wallet` is unquoted, so the tile's `switch` on kind
      // is not a code literal. `'Wallet'` at `payment_method_tile.dart` is a
      // bundled lucide **glyph name**, capitalised, and is likewise not a
      // method code — noted here because a reviewer running the grep
      // case-insensitively will see it and should know which it is.
      expect(
        _grep(
          kPayment,
          RegExp("""('laoqr'|"laoqr"|'wallet'|"wallet")"""),
          codeOnly: true,
        ),
        isEmpty,
      );
    });
  });

  // ───────────────────────────────────────────────────────────────────────────
  group('B6-AC-47 — draft mode is absent from B6', () {
    // ── AMENDED BY B6b, AND THE REASON IS ANOTHER BATCH'S CODE ───────────────
    //
    // `B6-AC-47` reads *"Draft mode is absent. `grep -rn "LAO_BANKS|
    // isPaymentValid|cardCvv|cardExpiry|methodQr|methodBank|methodCard" lib`
    // → **0**"*, tagged **both**, and B6a's version of this test scanned all of
    // `lib/` deliberately: *"the criterion is that this code does not exist
    // anywhere yet."*
    //
    // **"Yet" expired while B6b was being written.** F1 is landing draft mode
    // right now — `lib/presentation/payment/{draft_payment_section,
    // payment_draft}.dart` and `lib/features/certificates/presentation/
    // resident/resident_form_state.dart` — and that is not a violation, it is
    // § 6.3 being executed: *"B6 does NOT own draft mode
    // (`PaymentSection.tsx:474-670`, `LAO_BANKS`, `isPaymentValid`,
    // `formatCard`, `formatExpiry`). It is **F0/F1/F3's**."* The whole-of-`lib`
    // form of this criterion was only ever satisfiable while F1 had not landed,
    // and the spec does not say so.
    //
    // So the scan is scoped to the trees B6 owns. That still fails if B6 ports
    // a line of draft mode — which is the entire claim AC-47 makes about this
    // batch — and it no longer fails because a different batch did its job.
    // **Reported as a deviation in B6b's hand-back; the literal whole-of-`lib`
    // criterion is FAIL and is escalated to the architect rather than waived.**
    test('none of the seven draft-only identifiers appear in B6\'s own trees', () {
      final RegExp draft = RegExp(
        r'\b(LAO_BANKS|isPaymentValid|cardCvv|cardExpiry|methodQr|methodBank|methodCard)\b',
      );

      // B6's two trees. `lib/presentation/payment/` is shared with F1 by
      // § 6.3's own split, so it is scanned file by file: B6b's four live
      // widgets plus B6a's two shared pieces must be clean, and F1's two draft
      // files are not B6's to assert about.
      const List<String> b6Payment = <String>[
        'lib/presentation/payment/live_payment_section.dart',
        'lib/presentation/payment/payment_method_tile.dart',
        'lib/presentation/payment/payment_instruction_panel.dart',
        'lib/presentation/payment/insufficient_funds_panel.dart',
        'lib/presentation/payment/payment_summary_card.dart',
        'lib/presentation/payment/qr_placeholder.dart',
      ];

      final List<String> hits = <String>[
        // `codeOnly`: `live_payment_section.dart`'s library doc quotes all four
        // draft identifiers **in the sentence that disclaims them** ("B6 does
        // NOT own draft mode … `LAO_BANKS`, `isPaymentValid` …"). Counting the
        // disclaimer as the violation would be the opposite of the criterion.
        ..._grep(kWallet, draft, codeOnly: true),
        for (final String path in b6Payment)
          ...File(path)
              .readAsLinesSync()
              .asMap()
              .entries
              .where(
                (MapEntry<int, String> e) =>
                    !e.value.trimLeft().startsWith('//') &&
                    draft.hasMatch(e.value),
              )
              .map(
                (MapEntry<int, String> e) =>
                    '$path:${e.key + 1} -> ${e.value.trim()}',
              ),
      ];

      expect(hits, isEmpty, reason: hits.join('\n'));
    });

    test('but the payment i18n namespace still carries its draft-only keys', () {
      // The namespace is ported WHOLE (§ 6.13). `methodQr`/`methodBank`/
      // `methodCard` exist as i18n keys and must not exist as Dart identifiers
      // — the two halves of AC-47, and the second is why the first is not
      // simply "delete the keys".
      final String en = File('assets/i18n/en.json').readAsStringSync();
      for (final String key in <String>[
        'methodQr',
        'methodBank',
        'methodCard',
      ]) {
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
      final String src = File(
        'lib/core/constant/api_endpoint.dart',
      ).readAsStringSync();
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

    // **INVERTED BY B6b.** The third of B6a's three stub-guards (with
    // `kBillsDueB6b` and AC-45's grep), and it retires the same way: it
    // asserted that the pay endpoint was *not yet* in `api_endpoint.dart`
    // because § 3.1 gives that append to B6b, not B6a. B6b has now appended it,
    // so the guard can only pass by being wrong. What replaces it is the claim
    // that outlives the seam — the path is built in exactly one place, and it
    // is built with `Uri.encodeComponent`.
    test('B6b appended the pay endpoint, and it encodes its id', () {
      final String src = File(
        'lib/core/constant/api_endpoint.dart',
      ).readAsStringSync();

      expect(src, contains('static String applicationPay(String id) =>'));
      // A case id interpolated raw would let a `/`-bearing id reach a different
      // endpoint than the caller named. `application(id)` and
      // `applicationTimeline(id)` (B7a's) already encode; this one matches.
      expect(src, contains(r"'/applications/${Uri.encodeComponent(id)}/pay'"));
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
        final List<String> hits = _grep(
          dir,
          storage,
        ).where((String h) => !RegExp(r'-> ///|-> //').hasMatch(h)).toList();
        expect(hits, isEmpty, reason: 'in $dir: ${hits.join('\n')}');
      }
    });

    test('nothing prints', () {
      // Item 2. No `print`, `debugPrint` or `log()` at all — so none of them
      // can be carrying a balance, an account number or a receipt number.
      final RegExp printing = RegExp(r'\b(print|debugPrint|log)\s*\(');

      for (final String dir in <String>[kWallet, kPayment]) {
        final List<String> hits = _grep(
          dir,
          printing,
        ).where((String h) => !RegExp(r'-> ///|-> //').hasMatch(h)).toList();
        expect(hits, isEmpty, reason: 'in $dir: ${hits.join('\n')}');
      }
    });

    test('B6 adds no second Dio and no second interceptor list (item 3)', () {
      // `chucker_flutter` (V-9) persists plaintext captures and B6 is the first
      // batch whose traffic is money. The mitigation is that there is exactly
      // one client, the `kDebugMode`-gated one, and B6 re-exports it.
      for (final String dir in <String>[kWallet, kPayment]) {
        expect(_grep(dir, RegExp(r'\bDio\(')), isEmpty, reason: 'in $dir');
        expect(
          _grep(dir, RegExp(r'interceptors\.')),
          isEmpty,
          reason: 'in $dir',
        );
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
      for (final String layer in <String>[
        'domain',
        'data',
        'presentation',
        'di',
      ]) {
        expect(
          Directory('$kWallet/$layer').existsSync(),
          isTrue,
          reason: layer,
        );
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
