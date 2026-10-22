/// GOR-269 — the guards that keep the *shape* of the fix honest over time.
///
/// `specs.md` § 7.7 routes `AC-11`, `AC-17` and `AC-32` to `grep` assertions
/// and calls them *"cheap, and they are what keep the shape of the fix honest
/// over time"*. Running them as tests rather than as a one-off command at
/// review is the difference between a property that held on the day it shipped
/// and a property that keeps holding.
///
/// The one they exist to catch is specific. `root-cause.md` § 9.2 ruled that
/// **the 13 routes are the blast radius, not the work items**: a fix that adds
/// thirteen route-local handlers would satisfy a route-count criterion, would
/// pass every behavioural test in this ticket, and would certify the exact
/// anti-pattern `FU-B12-1` rejected. `AC-11` is the assertion that says no.
/// Route 16's author is the reader these tests are written for.
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'layering_rules.dart' show stripComments;

/// One scanned file, as `grep -rn` would see it.
typedef _Source = ({String path, String text});

/// Every `.dart` file under `lib/`, generated files included.
///
/// A deliberately separate walk from `layering_rules.dart`'s `scanTree`, which
/// excludes `*.freezed.dart` and `*.g.dart` because a generated file has no
/// independent placement decision. The criteria below are written as
/// `grep -rn … lib --include="*.dart"`, which excludes nothing, and a guard
/// that quietly scanned a smaller set than the criterion names would be a
/// weaker assertion wearing the criterion's number.
List<_Source> _lib() {
  final List<_Source> out = <_Source>[];
  for (final FileSystemEntity entity
      in Directory('lib').listSync(recursive: true)) {
    if (entity is! File) continue;
    final String path = entity.path.replaceAll(r'\', '/');
    if (!path.endsWith('.dart')) continue;
    out.add((path: path, text: entity.readAsStringSync()));
  }
  out.sort((_Source a, _Source b) => a.path.compareTo(b.path));
  return out;
}

/// Lines matching [pattern], as the `path:line` strings `grep -n` prints.
List<String> _hits(List<_Source> files, Pattern pattern) {
  final List<String> out = <String>[];
  for (final _Source file in files) {
    final List<String> lines = file.text.split('\n');
    for (int i = 0; i < lines.length; i++) {
      if (lines[i].contains(pattern)) {
        out.add('${file.path}:${i + 1}');
      }
    }
  }
  return out;
}

void main() {
  late List<_Source> files;

  setUpAll(() {
    files = _lib();
    expect(files.length, greaterThan(500),
        reason: 'the scan must actually reach lib/, or every assertion below '
            'passes vacuously');
  });

  test('GOR-269-AC-32 — `lib/features/family_book/` names no pop guard', () {
    // `F4-AC-40` clause 2 gates on this grep being empty.
    // `root-cause.md` § 1.3 measured it green BEFORE the fix and ruled that it
    // must stay green; `fix-plan.md` § 10.1 calls adding one here *"the single
    // most damaging thing this ticket could do"*. The fix is placed outside the
    // directory entirely, so this is a guard rather than a near miss.
    final List<_Source> familyBook = files
        .where((_Source f) => f.path.startsWith('lib/features/family_book/'))
        .toList();

    expect(familyBook, isNotEmpty,
        reason: 'the directory must exist for the emptiness below to mean '
            'anything — F4 ships 21 files here');
    expect(_hits(familyBook, RegExp(r'PopScope|WillPopScope')), isEmpty);
  });

  test('GOR-269-AC-11 — the fix adds no pop guard anywhere in lib/', () {
    // **Comment-stripped, for the reason Amendment `A-3` already established
    // for `AC-17`: a raw-text scan counts prose, and this criterion is about
    // code.** It was raw text, and it went red on `SRE-269-5`'s fix — not
    // because a pop guard appeared, but because `app_back_policy.dart`'s doc
    // comment now has to explain how the platform gate's `routeBlocksPop` half
    // is what keeps `history_page.dart:143`'s `PopScope` working. Naming the
    // widget it must not break is the opposite of adding one, and a guard that
    // cannot tell those apart penalises exactly the documentation it wants.
    //
    // The substance is unchanged and is in fact *stronger* against the failure
    // it hunts — thirteen route-local handlers would be thirteen `PopScope`
    // widgets, none of which survives comment stripping.
    final List<_Source> code = files
        .map((_Source f) => (path: f.path, text: stripComments(f.text)))
        .toList();
    final List<String> hits = _hits(code, RegExp(r'PopScope|WillPopScope'));

    expect(
      hits.map((String h) => h.split(':').first).toSet(),
      <String>{'lib/features/history/presentation/pages/history_page.dart'},
      reason: 'a pop guard outside history_page.dart is the 13-handler '
          'anti-pattern beginning. Hits: $hits',
    );
    expect(hits, hasLength(1),
        reason: 'the one B7 shipped — its doc-comment mention is prose and no '
            'longer counted. Hits: $hits');
  });

  test('GOR-269-AC-11 — the dispatcher lives in exactly one lib/ file, plus '
      'its construction in main.dart', () {
    final Set<String> mentions = _hits(files, 'BackButtonDispatcher')
        .map((String h) => h.split(':').first)
        .toSet();

    expect(mentions, <String>{
      'lib/utils/routes/app_back_policy.dart',
      'lib/main.dart',
    });
  });

  test('GOR-269-AC-17 — zero of the 36 navigation call sites changed '
      '(**rewritten 2026-10-22**)', () {
    // `specs.md` AC-17 writes this as a raw `grep -rn "\.go(" lib | wc -l` → 36.
    // That literal form cannot be satisfied by the approved fix, and the reason
    // is worth stating rather than quietly working around, because the number
    // moving looks at first glance exactly like the failure the criterion hunts.
    //
    // Measured. At the base commit `4f13caf` the raw grep returns 36, of which
    // **34 are real call sites and 2 are doc comments** discussing `context.go`.
    // After the fix it returns 42: the same 34 call sites, still byte-identical,
    // plus
    //
    //   * **5 new doc-comment mentions**, three of which this ticket's own
    //     governing documents *mandate* — `fix-plan.md` § 11's Ruling D
    //     replacement text quotes `context.go`, and `specs.md` § 3.1 invites the
    //     `app_routes.dart` pointer that names it; and
    //   * **1 new real call**, `_router.go(destination)` in the policy, which is
    //     the mechanism itself and which `security-review.md` `SR-1` makes
    //     *mandatory* — routing through go_router's public API is the only thing
    //     that keeps `AppRoutes._redirect` in front of the policy's navigation.
    //
    // So a raw-text count now measures prose as well as code, and the criterion
    // it is standing in for is about code. This asserts the substance instead,
    // against comment-stripped source: at GOR-269's own close, the 34
    // production call sites were untouched and the policy added exactly one
    // (35 total).
    //
    // **Rewritten 2026-10-22, Task 4.** This test asserts an absolute count
    // against a LIVE scan of the whole `lib/` tree (`files = _lib()`, no
    // commit-range bound) rather than a historical diff — unlike, say,
    // `B5-AC-21`'s `$kB5Base..$kB5Tip` form elsewhere in this tree. That makes
    // it brittle to any *later, unrelated* batch adding navigation anywhere in
    // the app, which is not what GOR-269-AC-17 was ever trying to pin: its
    // subject is "the back-policy fix did not touch the pre-existing 34 and
    // added exactly 1", not "no file in the whole tree may ever call
    // `context.go` again." Task 4 adds five real, legitimate
    // `context.go(...)` call sites in the new public-verification pages —
    // `verify_code_entry_page.dart`'s back button and typed-code submit,
    // `verify_result_page.dart`'s PDF-check button and its two not-found
    // affordances (rescan, retype) — none of them touching
    // `app_back_policy.dart` or `back_visit_stack.dart`, the two files
    // GOR-269's own claim is actually about. The count is bumped by exactly 5
    // (35 → 40, and the "other 34" below → 39) and the measured hit list is
    // recorded so the next batch can bump it again by exactly its own delta
    // rather than re-deriving the whole history.
    final List<_Source> code = files
        .map((_Source f) => (path: f.path, text: stripComments(f.text)))
        .toList();

    final List<String> gos = _hits(code, '.go(');
    expect(gos, hasLength(40),
        reason: 'the fix observes the router; it does not instrument the call '
            'sites. 34 pre-existing + exactly one in the policy + Task 4\'s '
            'five new verify-page call sites. Hits: $gos');

    expect(
      gos
          .where((String h) =>
              h.startsWith('lib/utils/routes/app_back_policy.dart:'))
          .toList(),
      hasLength(1),
      reason: 'the policy navigates exactly once. A second routed call here is '
          'a branch in the mechanism that no behavioural test in this ticket '
          'would distinguish from the first',
    );

    // And the other 39 (34 pre-existing + Task 4's 5) are outside the two
    // files GOR-269 created, i.e. neither the original fix nor Task 4 quietly
    // moved a production call site into the policy's own home.
    expect(
      gos.where((String h) =>
          !h.startsWith('lib/utils/routes/app_back_policy.dart:') &&
          !h.startsWith('lib/utils/routes/back_visit_stack.dart:')),
      hasLength(39),
    );

    // No real `push`/`goNamed` anywhere — candidate A (`fix-plan.md` § 7.1)
    // rejected. Stripping comments removes the one raw-text hit, a JavaScript
    // snippet in a doc comment, so this is the strictly stronger assertion.
    expect(_hits(code, RegExp(r'\.push\(|pushNamed\(|goNamed\(')), isEmpty,
        reason: 'a real push() would fix nine routes, leave the four tabs '
            'broken, and keep the shell s 4,000 ms chat poll alive behind '
            'every step of a seven-step form');

    // The doc-comment hit is still there, and is still only a doc comment.
    expect(_hits(files, RegExp(r'\.push\(|pushNamed\(|goNamed\(')), <String>[
      'lib/features/reference/data/datasources/location_remote_datasource.dart:18',
    ]);
  });

  test('GOR-269-AC-33 (Ruling D) — the news detail comment states what was '
      'measured, and `_back()` is unchanged', () {
    final String source = File(
      'lib/features/news/presentation/pages/news_detail_page.dart',
    ).readAsStringSync();

    expect(source, contains('void _back(BuildContext context) => '
        'context.go(AppNameRoutes.news);'),
        reason: 'Ruling D is comment-only. A behaviour change here would be '
            'the R-7 failure: "fixing" the one route that already works');
    expect(
      source,
      contains('It is **not** the case that a deep link here has nothing to '
          'pop to.'),
      reason: 'the claim the cold-deep-link row falsified',
    );
    expect(source, contains('matches=2'), reason: 'and it cites the measurement');
    expect(
      source,
      isNot(contains('because a deep link opened straight at `/news/<slug>` '
          'has nothing')),
      reason: 'the falsified claim must be gone, not merely supplemented',
    );
  });

  test('GOR-269-AC-33 — `news_page.dart` still carries its own C-3 reasoning',
      () {
    // `root-cause.md` correction C-3 established that news_page.dart's comment
    // is *correct* — `/news` is top-level, `matches=1`, so there genuinely is
    // nothing to pop to — and `fix-plan.md` § 11 therefore puts the file out of
    // Ruling D's reach entirely. This asserts it was left alone.
    //
    // Note on shape: unlike `news_detail_page.dart`, this file has **no `_back`
    // method**. Its back handler is written inline on the header
    // (`onBack: () => context.go(...)`), and always has been. A guard asserting
    // a `_back` symbol here would be asserting against a file that does not
    // exist in this repository at any commit.
    final String source =
        File('lib/features/news/presentation/pages/news_page.dart')
            .readAsStringSync();

    expect(source, contains('onBack: () => context.go(AppNameRoutes.home)'),
        reason: 'the behaviour C-3 ruled correct — `/news`s own chevron goes '
            'home, exactly as `App.tsx` wires it');

    expect(
      source,
      contains('`context.pop()` would be'),
      reason: 'and the file keeps its OWN reasoning. This is the sentence that '
          'is true here and false one door down, which is the whole content of '
          'correction C-3',
    );

    // The inverse, and the one that would actually catch the mistake Ruling D
    // exists to prevent: the detail page's replacement text must NOT have been
    // copied onto this file as well.
    expect(
      source,
      isNot(contains('It is **not** the case that a deep link here has '
          'nothing to pop to.')),
      reason: 'Ruling D corrects `news_detail_page.dart` because that route is '
          'a CHILD of /news. Applying the same correction here would replace a '
          'true comment with a false one',
    );
  });

  test('SR-1 — the policy navigates only through go_router s public API', () {
    // The static half of `security-review.md` § 3.1. The behavioural half is
    // `back_policy_authorization_test.dart`, which proves `_redirect` actually
    // catches the policy's navigation; this half proves there is no second,
    // unguarded path in the file at all.
    //
    // Comments are stripped first — `layering_rules.dart` records why that is
    // load-bearing rather than defensive: the file DOCUMENTS the mechanism it
    // must not use ("each live NavigatorState.maybePop()"), and a raw-text scan
    // would fail on the explanation of the rule it is enforcing.
    final String code = stripComments(
      File('lib/utils/routes/app_back_policy.dart').readAsStringSync(),
    );

    expect(code, contains('_router.go('),
        reason: 'the navigation must be a routed call, or `_redirect` never '
            'sees it');
    for (final String forbidden in <String>[
      'NavigatorState',
      'navigatorKey',
      'setNewRoutePath',
      'currentConfiguration =',
      'RouteMatchList(',
      'RouteMatchList.',
    ]) {
      expect(code, isNot(contains(forbidden)),
          reason: 'reaching for `$forbidden` would bypass route matching, and '
              'therefore the auth gate, while looking correct from every '
              'behavioural test in this ticket');
    }
  });

  test('SR-4 — nothing in the fix logs the visit stack', () {
    // Conditional in the review ("required IF any diagnostic logging is
    // added"). Discharged by adding none, and asserted so it stays that way:
    // a later `debugPrint` of the journey is exactly the change SR-4 exists to
    // catch, and it would arrive as a debugging aid rather than as a decision.
    for (final String path in <String>[
      'lib/utils/routes/app_back_policy.dart',
      'lib/utils/routes/back_visit_stack.dart',
    ]) {
      final String code = stripComments(File(path).readAsStringSync());
      for (final String logger in <String>[
        'debugPrint',
        'print(',
        'log(',
        'developer.',
      ]) {
        expect(code, isNot(contains(logger)), reason: '$path names $logger');
      }
    }
  });

  test('FC-7 / I-7 — the fix declares no storage key', () {
    for (final String path in <String>[
      'lib/utils/routes/app_back_policy.dart',
      'lib/utils/routes/back_visit_stack.dart',
    ]) {
      final String code = stripComments(File(path).readAsStringSync());
      expect(code, isNot(contains('StorageKeys')),
          reason: 'GOR-245 § 4.2 freezes the key set at three; the journey is '
              'in-memory and session-scoped');
      expect(code, isNot(contains('StorageService')));
      expect(code, isNot(contains('Hive')));
    }
  });
}
