/// **Architecture, i18n and scope — B8-AC-6 … B8-AC-10, B8-AC-46, B8-AC-47,
/// B8-AC-61, B8-AC-62, B8-AC-63, B8-AC-65.**
///
/// Structural assertions over the tree, all of them things a widget test cannot
/// see because they are about **what is absent**.
library;

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../../../architecture/layering_rules.dart';

/// Every non-generated Dart file under `lib/`, scanned once.
///
/// A top-level `final` is already lazily initialised in Dart, so `late` bought
/// nothing here and the analyzer says so (`unnecessary_late`).
final List<DartFile> _lib = scanTree(kLibDir);

void main() {
  // ── B8-AC-6 — the six guards still pass, unmodified ───────────────────────

  group('B8-AC-6 — G-L1…G-L5 and G-L7 pass, and none was weakened for B8', () {
    test('all six are green over the whole of `lib/`', () {
      // The production run lives in `layering_test.dart`; repeated here so a
      // failure names B8 rather than surfacing as someone else's red, and so
      // this file's own claims below rest on a green base.
      expect(glL1Violations(_lib), isEmpty, reason: 'G-L1');
      expect(glL2Violations(_lib), isEmpty, reason: 'G-L2');
      expect(glL3Violations(_lib), isEmpty, reason: 'G-L3');
      expect(glL4Violations(_lib), isEmpty, reason: 'G-L4');
      expect(glL4Unclassified(_lib), isEmpty, reason: 'G-L4, second half');
      expect(glL5Violations(_lib), isEmpty, reason: 'G-L5');
      expect(glL7Violations(_lib), isEmpty, reason: 'G-L7');
    });

    test('MEASURED GAP, reported not fixed: G-L5\'s locator list is stale and '
        'does not name `accountInjection`', () {
      // `kLocatorNames` is `['injection', 'authInjection', 'sessionInjection']`
      // — the three containers that existed when the guard was written. Six
      // more have shipped since: `serviceInjection`, `homeInjection`,
      // `newsInjection`, `helpInjection`, `notificationsInjection`,
      // `chatInjection`, and now `accountInjection`. **G-L5 cannot see a
      // widget that resolves from any of them.**
      //
      // B8 does not widen the list: `test/architecture/layering_rules.dart` is
      // not in specs.md § 3.1's scope, the change would fire against six other
      // batches' code at once, and a guard edited by the batch it would judge
      // is the vacuity B2-AC-7 exists to prevent. Recorded here and in the
      // hand-back so the gap is a decision rather than a silence.
      //
      // What B8 CAN prove is that its own feature does not exploit it — the
      // next test does exactly that.
      expect(
        kLocatorNames,
        isNot(contains('accountInjection')),
        reason: 'if this ever starts passing, the guard was widened and this '
            'note should be deleted along with the manual check below',
      );
    });

    test('no `features/account/presentation/**` file names `accountInjection` '
        '— the rule G-L5 states, checked by hand because the guard cannot', () {
      final Iterable<DartFile> widgets = _lib.where((DartFile f) =>
          f.feature == 'account' && f.segments.contains('presentation'));

      expect(widgets, isNotEmpty, reason: 'the scan must actually find files');

      for (final DartFile file in widgets) {
        expect(
          RegExp(r'(?<![A-Za-z0-9_$])accountInjection(?![A-Za-z0-9_$])')
              .hasMatch(file.code),
          isFalse,
          reason: '${file.path} resolves from a locator inside a widget',
        );
      }
    });
  });

  // ── B8-AC-7 — the only cross-feature edges are session/domain, auth/domain ─

  test('B8-AC-7 — `features/account/**` imports ONLY `session/domain/**` and '
      '`auth/domain/**` from other features', () {
    final List<String> edges = <String>[];

    for (final DartFile file
        in _lib.where((DartFile f) => f.feature == 'account')) {
      for (final DartImport import in file.localImports) {
        final List<String> parts = import.target!.split('/');
        if (parts.first != 'features') continue;
        if (parts[1] == 'account') continue;
        edges.add('${parts[1]}/${parts[2]}  ←  ${cite(file, import)}');
      }
    }

    // Printed, so the reviewer reads the edges rather than a boolean.
    // ignore: avoid_print
    print('cross-feature edges out of features/account/: ${edges.length}');
    for (final String edge in edges) {
      // ignore: avoid_print
      print('  $edge');
    }

    expect(edges, isNotEmpty,
        reason: 'account consumes `CitizenAccount`, `Bilingual`, '
            '`UpdateProfile` and `ChangePassword` — zero edges would mean the '
            'scan found nothing and this assertion is vacuous');

    for (final String edge in edges) {
      final String target = edge.split('  ←  ').first;
      final String from = edge.split('  ←  ').last;
      final bool fromDi = from.contains('/di/');

      if (!fromDi) {
        expect(
          target,
          anyOf('session/domain', 'auth/domain'),
          reason: 'specs.md § 6.3\'s G-L3 row: outside the composition root, '
              'account may reach `session/domain/**` and `auth/domain/**` and '
              'NOTHING else — never their `data/` or `presentation/`, and no '
              'other feature at all.',
        );
        continue;
      }

      // ── The one widening, and it is a precedent rather than a novelty ─────
      //
      // B8-AC-7 reads "`session/domain/**` and `auth/domain/**`". The two
      // files under `features/account/di/` additionally import
      // `session/di/session_injection.dart` and `auth/di/auth_injection.dart`,
      // because `AccountUsecaseInjection` **re-exports** `GetProfile`,
      // `UpdateProfile` and `ChangePassword` out of those containers instead
      // of registering a second `PATCH /me/profile` and a second
      // `POST /auth/change-password` (specs.md § 6.3). A closure over another
      // container needs that container's handle.
      //
      // This is exactly `ChatUsecaseInjection`'s shape — B9b imports
      // `../../help/di/help_injection.dart` for the same reason and
      // `dependency_injection.dart` step 11 documents it — and G-L3 permits
      // it: the rule forbids `data/` and `presentation/`, not `di/`. A
      // composition root is the one place that is supposed to know other
      // features exist.
      //
      // Recorded as a narrower-than-reality AC in the hand-back rather than
      // asserted away.
      expect(
        target,
        anyOf(
          'session/domain',
          'auth/domain',
          'session/di',
          'auth/di',
        ),
        reason: 'even the composition root may not reach another feature\'s '
            '`data/` or `presentation/`',
      );
    }

    // …and the `di → di` widening is exactly two edges, not a general licence.
    final List<String> diEdges = edges
        .where((String e) =>
            e.startsWith('session/di') || e.startsWith('auth/di'))
        .toList();
    expect(diEdges, hasLength(2), reason: diEdges.join('\n'));
  });

  // ── B8-AC-8 — `lib/core/` gains no second BLoC ────────────────────────────

  test('B8-AC-8 — `lib/core/` still holds exactly ONE BLoC, and its '
      'cross-feature imports are still only `features/session/domain/**`', () {
    final List<String> coreBlocs = _lib
        .where((DartFile f) =>
            f.segments.first == 'core' &&
            RegExp(r'class \w+ extends Bloc<').hasMatch(f.code))
        .map((DartFile f) => f.path)
        .toList();

    expect(coreBlocs, <String>['core/session/bloc/session_bloc.dart'],
        reason: '`ssd.md` § 4.5\'s closed list of one. B8 MODIFIES that entry '
            '(one new event) rather than adding a second, which is why R-25 '
            'needed no ADR.');

    final DartFile sessionBloc =
        _lib.firstWhere((DartFile f) => f.path == coreBlocs.single);
    for (final DartImport import in sessionBloc.localImports) {
      final List<String> parts = import.target!.split('/');
      if (parts.first != 'features') continue;
      expect(
        '${parts[1]}/${parts[2]}',
        'session/domain',
        reason: 'the single whitelisted `core → features` edge, not widened',
      );
    }
  });

  // ── B8-AC-9 — the shell is untouched (the half that carries the risk) ─────

  test('B8-AC-9 — `lib/presentation/` gains no fifth group, and `app_shell` / '
      '`app_top_bar` are free of B8', () {
    final Set<String> groups = _lib
        .where((DartFile f) => f.segments.first == 'presentation')
        .map((DartFile f) => f.segments[1])
        .toSet();

    // B10 is landing `presentation/boot/` concurrently, so the assertion is
    // that **B8** added none rather than that the count is frozen — a count
    // here would fail on another batch's work and read as B8's.
    expect(
      groups,
      isNot(contains('account')),
      reason: 'every B8 widget lives under `features/account/presentation/`',
    );

    // The two files § 6.4's design exists to keep out of B8, because B10's D-3
    // must edit them. This is the half of B8-AC-9 that carries the cross-batch
    // risk, and it holds.
    for (final String path in <String>[
      'lib/presentation/shell/app_shell.dart',
      'lib/presentation/shell/app_top_bar.dart',
    ]) {
      final String source = File(path).readAsStringSync();
      expect(source, isNot(contains('account/')),
          reason: '$path must not import anything from the account feature');
      expect(source, isNot(contains('B8')), reason: '$path names no B8 work');
    }
  });

  // ── B8-AC-10 — the five DI files, and an additive root ────────────────────

  test('B8-AC-10 — `features/account/di/` has the five conventional files', () {
    final List<String> di = Directory('lib/features/account/di')
        .listSync()
        .whereType<File>()
        .map((File f) => f.uri.pathSegments.last)
        .toList()
      ..sort();

    expect(di, <String>[
      'account_datasource_injection.dart',
      'account_feature_injection.dart',
      'account_injection.dart',
      'account_repository_injection.dart',
      'account_usecase_injection.dart',
    ]);
  });

  test('B8-AC-10 / B8-AC-63 — the root DI ordering constraint is real and '
      'stated at the call site', () {
    final String root =
        File('lib/core/di/dependency_injection.dart').readAsStringSync();

    // `AccountFeatureInjection.init()` re-exports out of `sessionInjection`
    // AND `authInjection`, so it must come after both. Asserted by position,
    // not by reading the comment that says so.
    final int session = root.indexOf('SessionFeatureInjection.init()');
    final int auth = root.indexOf('AuthFeatureInjection.init()');
    final int account = root.indexOf('AccountFeatureInjection.init()');

    expect(session, greaterThan(-1));
    expect(auth, greaterThan(-1));
    expect(account, greaterThan(-1));
    expect(account, greaterThan(session));
    expect(account, greaterThan(auth));
  });

  // ── B8-AC-63 — the shared files' diffs are additive ───────────────────────

  test('B8-AC-63 — the four shared files are ADDITIVE: zero deletions', () {
    // `git diff --numstat` against HEAD. The working tree also carries B10's
    // concurrent work in the two JSONs, so the *insertion* counts are not
    // B8's alone — but the **deletion** count is the claim, and it is zero for
    // all four whoever wrote the lines.
    final ProcessResult result = Process.runSync(
      'git',
      <String>[
        'diff',
        '--numstat',
        '--',
        'lib/core/constant/api_endpoint.dart',
        'lib/core/di/dependency_injection.dart',
        'assets/i18n/en.json',
        'assets/i18n/lo.json',
      ],
    );
    expect(result.exitCode, 0, reason: result.stderr.toString());

    final List<String> rows = (result.stdout as String)
        .trim()
        .split('\n')
        .where((String l) => l.isNotEmpty)
        .toList();

    // ignore: avoid_print
    print('git diff --numstat (the four shared files):');
    for (final String row in rows) {
      // ignore: avoid_print
      print('  $row');
      final List<String> cells = row.split(RegExp(r'\s+'));
      expect(
        cells[1],
        '0',
        reason: 'One deletion breaks the parallel merge for B6, B7 and B10. '
            '`${cells[2]}` shows ${cells[1]} deletion(s). Note the i18n keys '
            'are inserted BEFORE the pre-existing `account.signOut` line '
            'precisely so that line needs no trailing comma — appending after '
            'it would have shown one deletion here.',
      );
    }
  });

  // ── i18n ──────────────────────────────────────────────────────────────────

  group('the `account` namespace', () {
    Map<String, dynamic> load(String locale) => jsonDecode(
          File('assets/i18n/$locale.json').readAsStringSync(),
        ) as Map<String, dynamic>;

    test('B8-AC-46 — the key count is recorded AS A NUMBER, and en/lo have '
        'identical key sets', () {
      final Map<String, dynamic> en =
          load('en')['account'] as Map<String, dynamic>;
      final Map<String, dynamic> lo =
          load('lo')['account'] as Map<String, dynamic>;

      // ignore: avoid_print
      print('account namespace: en=${en.length} keys, lo=${lo.length} keys '
          '(B8a added 48: 23 from `src/app/i18n/ns/account.ts` + 25 from '
          '`AccountPage.tsx`\'s COPY; 1 pre-existing `signOut`; '
          'B8b added 1: `photoHint`)');

      // **49 → 50 at B8b.** `photoHint` (`AccountPage.tsx:73`) is the avatar
      // control's accessible label — `aria-label`, `title` and the `sr-only`
      // span all read it (`:335`, `:336`, `:339`). It is the only key B8b adds,
      // specs.md § 3.1's B8b row says so, and this number is the criterion that
      // notices if a second one appears.
      //
      // Inserted between `passwordShort` and `uin`, matching the source's own
      // COPY declaration order (`:72-74`) — which also makes the JSON diff
      // `+1/−0` rather than `+2/−1`, because the previous last line does not
      // need a comma. B8-AC-63.
      expect(en.length, 50);
      expect(lo.length, 50);
      expect(en['photoHint'], 'Change photo');
      expect(lo['photoHint'], isNot('Change photo'),
          reason: 'the Lao column is where an untranslated string hides');
      expect(en.keys.toSet(), lo.keys.toSet());
      // Every value non-empty in both — an empty Lao string renders as blank
      // and would pass a key-set check.
      for (final String key in en.keys) {
        expect((en[key] as String).trim(), isNotEmpty, reason: 'en.$key');
        expect((lo[key] as String).trim(), isNotEmpty, reason: 'lo.$key');
      }
    });

    test('B8-AC-61 — the three DEAD keys are not ported', () {
      // `account.ts:39-41` / `:78-80` define `docNationalId`,
      // `docResidentCert`, `docHousehold`; `grep -rn` across the web `src/`
      // finds only those six definition lines. The card renders
      // `text(doc.title, lang)` — the API's own bilingual title (`:442`).
      // Porting them would create three Flutter keys no widget reads, which
      // the next i18n audit would flag as dead in *our* tree.
      for (final String locale in <String>['en', 'lo']) {
        final Map<String, dynamic> account =
            load(locale)['account'] as Map<String, dynamic>;
        for (final String dead in <String>[
          'docNationalId',
          'docResidentCert',
          'docHousehold',
        ]) {
          expect(account.containsKey(dead), isFalse, reason: '$locale.$dead');
        }
      }

      // …and nothing in `lib/` or `assets/` references them.
      for (final DartFile file in _lib) {
        expect(file.code, isNot(contains('docNationalId')));
        expect(file.code, isNot(contains('docResidentCert')));
        expect(file.code, isNot(contains('docHousehold')));
      }
    });

    test('B8-AC-62 — ZERO `common` keys added', () {
      final ProcessResult head = Process.runSync(
        'git',
        <String>['show', 'HEAD:assets/i18n/en.json'],
      );
      expect(head.exitCode, 0);

      final Map<String, dynamic> before =
          (jsonDecode(head.stdout as String) as Map<String, dynamic>)['common']
              as Map<String, dynamic>;
      final Map<String, dynamic> after =
          load('en')['common'] as Map<String, dynamic>;

      expect(after, before,
          reason: 'measured: `save`, `download`, `view`, `close` and `loading` '
              'all already existed. `tc("save")` at `AccountPage.tsx:549` maps '
              'to the existing `common.save`.');
      expect(after.containsKey('save'), isTrue);
    });

    test('B8-AC-47 — the version footer is a LITERAL in both locales, not an '
        'i18n key', () {
      for (final String locale in <String>['en', 'lo']) {
        final String raw = File('assets/i18n/$locale.json').readAsStringSync();
        expect(raw, isNot(contains('LaoGov')));
        expect(raw, isNot(contains('Ministry of Interior')));
      }

      // …and they ARE in the widget, verbatim, including the stale-looking
      // version string. `AccountPage.tsx:731-732` hardcodes both in English in
      // both locales; turning them into keys would let the Lao column drift
      // from the web's.
      final String page = File(
        'lib/features/account/presentation/pages/account_page.dart',
      ).readAsStringSync();
      expect(page, contains("'LaoGov v2.1.0'"));
      expect(page, contains("'Ministry of Interior, Lao PDR'"));
    });
  });

  // ── B8-AC-65 — every deferral is traceable in code ────────────────────────

  test('B8-AC-65 — FU-2 is cited at the document row; FU-4 is nowhere by '
      'design', () {
    final String card = File(
      'lib/features/account/presentation/widgets/documents_card.dart',
    ).readAsStringSync();
    expect(card, contains('FU-2'));

    // FU-4 (account deletion) is recorded ONLY in the spec, because the whole
    // point is that no code exists — B8-AC-25 asserts the absence. The page's
    // library doc explains why, so a faithful-port dispatch reading the
    // roadmap's endpoint list finds the reasoning before it finds the gap.
    final String page = File(
      'lib/features/account/presentation/pages/account_page.dart',
    ).readAsStringSync();
    expect(page, contains('me.deactivate'));
    expect(page, contains('feature request against the **web app** first'));
  });
}
