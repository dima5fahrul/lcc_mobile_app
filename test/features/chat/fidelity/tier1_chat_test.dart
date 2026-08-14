/// **Tier 1 — structural parity for the chat panel. B9-AC-27 / B9-AC-28.**
///
/// specs.md § 6.10: *"PASS, 100 %, per surface per locale, against the new
/// versioned oracles, over **every** state § 6.10 enumerates. A state omitted
/// from the oracle is NOT EVALUATED, not absent."*
///
/// This file and `chat.{en,lo}.json` close `architecture-review.md` § 2
/// BLOCKER-2, which measured that chat had **neither**, while notifications had
/// both — so *"every element the web renders present in Flutter with the same
/// text in both locales"* had never been checked for this surface. It mirrors
/// `tier1_notifications_test.dart`, which is the accepted worked example, and
/// deviates from it in exactly one place, for a reason recorded below.
///
/// ## Why chat's Tier 1 is the more load-bearing of the two
///
/// 22 strings on this surface are static literals at the pinned commit, and
/// **8 of them were invented by B9b** as extractions of inline
/// `L(lang, en, lo)` calls into keys the web source does not have. An
/// extraction can put the right string at the wrong node, in the wrong order,
/// or in the wrong state, and every one of those failures leaves the key
/// present, the translation present and `flutter analyze` clean. An ordered,
/// source-derived text oracle is the only instrument that sees it.
///
/// **Measured correction to `architecture-review.md` § 2**, which reads *"…
/// nothing covers the other seven's placement"*: of the 8 invented keys only
/// **6** are rendered text. `chat.endConversation` (`:225-226`) and
/// `chat.rateStarLabel` (`:477`) are `aria-label`/`title` only, so a text
/// oracle cannot see either — `rateStarLabel` is covered by B9-AC-47 in
/// `chat_panel_test.dart` and `endConversation` stays outside Tier 1 by
/// construction. The oracle's `provenance.aria_only` names all eight so the
/// boundary reads as a measurement rather than as another omission.
///
/// ## The one deviation from `tier1_notifications_test.dart`: no pinned clock
///
/// The notifications oracle pins `provenance.clock` because `relativeTime`
/// pins `lo-LA` / `en-GB` (`Layout.tsx:73`), so its `cardMeta` column has a
/// value derivable from the source. Chat's `clockTime` passes **`[]`**
/// (`CustomerServiceChat.tsx:24`) — the **host** locale. There is no host at a
/// pinned commit, so the per-bubble timestamp has no source-derivable value,
/// only a machine-derivable one, and pinning one would make this oracle a
/// function of whichever machine ran the derivation. specs.md § 6.10
/// generalised from the formatter whose locale is pinned to the one whose is
/// not (`architecture-review.md` MINOR-1, FU-12).
///
/// So the timestamp nodes are **excluded by name** rather than given a value —
/// and the exclusion is [_splitClocks], which is structural and **counted**, so
/// it cannot become a hiding place: see its own doc.
///
/// ## Capability Rule — what stops this gate passing on an empty set
///
/// `FACTORY-RULES.md`: *"if a test would pass with its subject empty, missing
/// or inert, it is evidence for the wiring, not the criterion."* An oracle that
/// listed nothing, or that this file loaded and never compared, would be green
/// and worthless. F0a hit exactly that and its fix is the pattern followed
/// here (`tier0_payload_equality_test.dart:244-257`): **fail rather than skip**
/// when the set is empty, *"because a skip reads as 'absent' rather than
/// 'unevaluated'"*, and **print the count unconditionally** — a green gate with
/// no number is what this discipline exists to stop.
library;

import 'dart:convert';
import 'dart:io';

import 'package:dartz/dartz.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lcc_mobile_app/core/error/failure.dart';
import 'package:lcc_mobile_app/features/chat/domain/entities/chat_entities.dart';
import 'package:lcc_mobile_app/features/chat/presentation/bloc/chat_bloc.dart';
import 'package:lcc_mobile_app/features/chat/presentation/widgets/chat_launcher.dart';
import 'package:lcc_mobile_app/features/chat/presentation/widgets/chat_panel.dart';
import 'package:lcc_mobile_app/presentation/theme/app_theme.dart';

import '../../../fidelity/oracle.dart';
import '../../../fidelity/text_dump.dart';
import '../../../helpers/app_test_harness.dart';
import '../../news/fidelity/tier1_news_test.dart' show expectParity;
import '../chat_test_helper.dart';

const List<Locale> kLocales = <Locale>[Locale('en'), Locale('lo')];

/// The surface the oracle is keyed on, used where the route-keyed Tier 1 tests
/// print a route.
const String kSurface = 'chat.panel';

/// The 14 states specs.md § 6.10 enumerates for chat — 9 `chat.panel`,
/// 3 `chat.chips`, 2 `chat.launcher`.
///
/// Hard-coded rather than read off the oracle, for the reason
/// `oracle.dart`'s [kTier0Bodies] gives: a list derived from the file makes the
/// count a consequence of what happens to be on disk, and B9-AC-27's point is
/// that it is asserted against a specification. **A state dropped from the
/// oracle must FAIL, not shrink the denominator.**
const List<String> kChatViews = <String>[
  'signedOut',
  'loading',
  'error',
  'greeting',
  'transcript',
  'pending',
  'typing',
  'rating',
  'minimized',
  'chips.openingQuickReplies',
  'chips.botSuggestions',
  'chips.suppressedWhenAgentAssigned',
  'launcher.noBadge',
  'launcher.badge',
];

/// The optimistic bubble's text — the test's own input, pinned in the oracle
/// (`provenance` on the `pending` node) because a citizen's own typing has no
/// source to be derived from.
const String kPendingText = 'ກຳລັງສົ່ງ';

/// Every element this file actually put in front of [expectParity], by locale.
///
/// The tally is the answer to *"the oracle was loaded — was it compared?"*. It
/// is printed unconditionally at the end of the run and asserted against the
/// oracle's own node count, so a view that silently stopped being exercised
/// shows up as a number, not as a still-green suite.
final Map<String, int> _compared = <String, int>{'en': 0, 'lo': 0};
final Map<String, int> _clocksExcluded = <String, int>{'en': 0, 'lo': 0};
final Set<String> _viewsExercised = <String>{};

// ─────────────────────────────────────────────────────────────────────────────
// The clock exclusion — structural, and counted
// ─────────────────────────────────────────────────────────────────────────────

/// Splits a pre-order panel dump into the nodes Tier 1 compares and the
/// per-bubble `clockTime` nodes it excludes.
///
/// **Identified structurally, never by the shape of the text.** `ChatBubble`
/// renders its body first and its stamp second (`chat_panel.dart:641-658`), so
/// a per-bubble dump is `[body]` or `[body, stamp]` and index 1 **is** the
/// stamp. Each bubble is a subtree, so its dump is a contiguous run of the
/// panel's pre-order dump and the runs appear in bubble order — which is what
/// lets the stamp be located by position rather than by matching `\d\d:\d\d`.
/// A regex would have been a hiding place: it would also have swallowed a
/// message body that happened to look like a time, and it would have kept
/// passing if the port started rendering the stamp somewhere it should not.
///
/// The caller asserts the returned `clocks` count against the **fixture**, so
/// the exclusion cannot silently widen: a port that stopped rendering stamps
/// returns too few, and one that grew a stamp on the greeting or the optimistic
/// bubble — neither of which has a `sent_at` in the source (`:404` reads
/// `msg.sent_at`, and `:340-362` / `:411-428` render no `<span>` at all) —
/// returns too many. Both fail.
({List<DumpNode> compared, List<DumpNode> clocks}) _splitClocks(
  WidgetTester tester,
  List<DumpNode> dump,
) {
  final Set<int> stampAt = <int>{};
  final List<DumpNode> clocks = <DumpNode>[];
  final Finder bubbles = find.byType(ChatBubble);
  int cursor = 0;

  for (int i = 0; i < bubbles.evaluate().length; i++) {
    final List<DumpNode> one = dumpText(tester, bubbles.at(i));
    final int at = _indexOfRun(dump, one, cursor);
    expect(
      at,
      isNonNegative,
      reason: 'ChatBubble #$i dumped as ${one.map((DumpNode n) => n.text)} but '
          'that run does not occur in the panel dump at or after $cursor. The '
          'bubble is a subtree, so this can only mean the two dumps disagree — '
          'which would make the exclusion below unsound, so it fails here '
          'rather than silently excluding the wrong node.',
    );
    if (one.length > 1) {
      stampAt.add(at + 1);
      clocks.add(one[1]);
    }
    cursor = at + one.length;
  }

  final List<DumpNode> compared = <DumpNode>[
    for (int i = 0; i < dump.length; i++)
      if (!stampAt.contains(i)) dump[i],
  ];
  return (compared: compared, clocks: clocks);
}

/// The index at which [run] occurs contiguously in [haystack] at or after
/// [from], or -1.
int _indexOfRun(List<DumpNode> haystack, List<DumpNode> run, int from) {
  if (run.isEmpty) return from;
  for (int i = from; i + run.length <= haystack.length; i++) {
    bool ok = true;
    for (int j = 0; j < run.length; j++) {
      if (haystack[i + j].text != run[j].text ||
          haystack[i + j].role != run[j].role) {
        ok = false;
        break;
      }
    }
    if (ok) return i;
  }
  return -1;
}

// ─────────────────────────────────────────────────────────────────────────────
// The fixture facts this file asserts against — read from the FIXTURE, never
// from the port
// ─────────────────────────────────────────────────────────────────────────────

List<Map<String, dynamic>> _fixtureMessages() =>
    (loadSyntheticChatApi('me-chat-messages')['data'] as List<dynamic>)
        .cast<Map<String, dynamic>>();

/// How many `ChatBubble` timestamps a full transcript must produce: one per
/// fixture message carrying a `sent_at` (`:404` renders `clockTime(msg.sent_at)`
/// and `clockTime` answers `""` for a missing value, `:21`).
int _fixtureStampCount() => _fixtureMessages()
    .where((Map<String, dynamic> m) =>
        (m['sent_at'] as String?) != null && (m['sent_at'] as String).isNotEmpty)
    .length;

/// `unread = live ? 0 : Σ th.unread_citizen` — `:127`, over **all** threads
/// regardless of status.
int _fixtureUnread() =>
    (loadSyntheticChatApi('me-chat-threads')['data'] as List<dynamic>)
        .cast<Map<String, dynamic>>()
        .fold<int>(
          0,
          (int sum, Map<String, dynamic> t) =>
              sum + ((t['unread_citizen'] as int?) ?? 0),
        );

// ─────────────────────────────────────────────────────────────────────────────
// Pumping the launcher — the panel has `pumpChatPanel`; the FAB does not
// ─────────────────────────────────────────────────────────────────────────────

/// `ChatLauncherButton` without a session or a router.
///
/// The class is public *"so the Tier 1 launcher views can pump it"*
/// (`chat_launcher.dart:106-107`) — this is the caller that comment was
/// written for, and until now it did not exist.
Future<void> _pumpLauncher(
  WidgetTester tester,
  int unread, {
  required Locale locale,
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
            body: Align(
              alignment: Alignment.bottomRight,
              child: ChatLauncherButton(unread: unread, onPressed: () {}),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  // ───────────────────────────────────────────────────────────────────────────
  // 0. NOT VACUOUS — the F0a pattern. Fails, never skips, and prints the number
  // ───────────────────────────────────────────────────────────────────────────

  group('Tier 1 for chat is NOT VACUOUS — B9-AC-27', () {
    test('both oracle documents exist, and the element count is DERIVED and '
        'PRINTED', () {
      final List<String> missing = <String>[];
      final Map<String, int> nodes = <String, int>{};

      for (final Locale locale in kLocales) {
        final String lang = locale.languageCode;
        final File file = File('$kOracleDir/tier1/chat.$lang.json');
        if (!file.existsSync()) {
          missing.add(file.path);
          continue;
        }
        final Map<String, dynamic> oracle =
            json.decode(file.readAsStringSync()) as Map<String, dynamic>;
        final Map<String, dynamic> views =
            oracle['views'] as Map<String, dynamic>;
        nodes[lang] = views.values
            .fold<int>(0, (int s, dynamic v) => s + (v as List<dynamic>).length);
        // ignore: avoid_print
        print('Tier 1 chat oracle `chat.$lang.json`: ${views.length} views, '
            '${nodes[lang]} expected elements');
      }

      expect(
        missing,
        isEmpty,
        reason: 'NOT EVALUATED — ${missing.join(', ')} absent, so ZERO '
            'structural comparisons ran for chat and every assertion below is '
            'about the comparator rather than about the surface. This is the '
            'exact condition architecture-review.md § 2 BLOCKER-2 measured. '
            'Reporting it as PASS would be the shape the Capability Rule '
            'forbids: a gate that is green because its input is empty. It is a '
            'FAILURE and not a skip, because a skip reads as "absent" rather '
            'than "unevaluated".',
      );

      for (final MapEntry<String, int> e in nodes.entries) {
        expect(
          e.value,
          greaterThan(0),
          reason: 'chat.${e.key}.json declares ${e.value} elements. An oracle '
              'that lists nothing passes vacuously.',
        );
      }
      expect(
        nodes['en'],
        nodes['lo'],
        reason: 'the two locales must describe the SAME tree with different '
            'strings; a count that diverges means one locale lost a node',
      );
    });

    for (final Locale locale in kLocales) {
      final String lang = locale.languageCode;

      test('chat.$lang declares every one of the 14 states § 6.10 enumerates — '
          'no state silently absent', () {
        final Map<String, dynamic> views =
            loadTier1('chat', lang)['views'] as Map<String, dynamic>;
        expect(
          views.keys.toSet(),
          kChatViews.toSet(),
          reason: 'B9-AC-27: "a state omitted from the oracle is NOT '
              'EVALUATED, not absent". The 14 are the § 6.10 table: 9 for '
              'chat.panel, 3 for chat.chips, 2 for chat.launcher.',
        );
        // Every non-empty view must be reachable through `tier1View` — an
        // unreadable view is as absent as a missing one.
        for (final String view in kChatViews) {
          expect(() => tier1View(loadTier1('chat', lang), view), returnsNormally,
              reason: view);
        }
      });

      test('chat.$lang carries the commit', () {
        expect(
          (loadTier1('chat', lang)['provenance']
              as Map<String, dynamic>)['web_commit'],
          kWebCommit,
        );
      });

      test('chat.$lang declares SURFACE keying, not route — B9-AC-28', () {
        final Map<String, dynamic> oracle = loadTier1('chat', lang);
        expect(oracle['surface'], kSurface);
        expect(
          oracle.containsKey('route'),
          isFalse,
          reason: 'a `route` key here would make this look like a page oracle '
              'and invite someone to pump a route that does not exist '
              '(specs.md § 6.1: "Neither gets a route")',
        );
        expect(
          (oracle['provenance'] as Map<String, dynamic>)['keying'],
          contains('SURFACE'),
        );
      });

      test('chat.$lang names its NOT EVALUATED regions rather than omitting '
          'them — B9-AC-31', () {
        final Map<String, dynamic> notEvaluated =
            ((loadTier1('chat', lang)['provenance']
                as Map<String, dynamic>)['not_evaluated']) as Map<String, dynamic>;

        expect(
          notEvaluated.keys,
          containsAll(<String>[
            'chat.panel.clockTime',
            'chat.panel.error.message',
            'chat.panel.tier3',
          ]),
          reason: 'three regions are NOT EVALUATED on this surface and each is '
              'reported by name per CLAUDE.md § Gate Status Reporting, never '
              'rounded up and never omitted',
        );
        expect(
          notEvaluated['chat.panel.clockTime'] as String,
          contains('CustomerServiceChat.tsx:24'),
          reason: 'the REASON has to survive, not just the label — MINOR-1 / '
              'FU-12 is a spec defect and the citation is the evidence for it',
        );
        expect(
          notEvaluated['chat.panel.tier3'] as String,
          contains('writes'),
          reason: 'FU-5: the open panel has no Tier 3 reference and obtaining '
              'one needs a WRITE to a live account',
        );
      });

      test('chat.$lang has NO pinned clock, and says why — the one deviation '
          'from the notifications oracle', () {
        final Map<String, dynamic> provenance =
            loadTier1('chat', lang)['provenance'] as Map<String, dynamic>;
        expect(
          provenance['clock'] as String,
          contains('NOT PINNED'),
          reason: 'notifications.{en,lo}.json pins one because relativeTime '
              'pins lo-LA / en-GB (Layout.tsx:73). clockTime passes [] '
              '(CustomerServiceChat.tsx:24) = the HOST locale, so a pinned '
              'value here would be a property of this machine. Recorded rather '
              'than faked.',
        );
      });
    }
  });

  // ───────────────────────────────────────────────────────────────────────────
  // 1. The oracle is DERIVED FROM THE WEB, not transcribed from the port
  // ───────────────────────────────────────────────────────────────────────────

  group('the oracle is derived from the PINNED WEB SOURCE — ADR-0001', () {
    // The one check that makes the other 166 comparisons mean something. An
    // oracle written by reading `assets/i18n/*.json` would agree with the port
    // by construction and gate nothing at all — it would be the Capability
    // Rule's failure shape one level up, at the oracle instead of at the test.
    //
    // READ-ONLY. `tier2_chat_test.dart:171` already reads this tree the same
    // way; nothing in this suite may write under `sources/lcc-app`.
    late String tsx;
    late String chatTs;

    setUpAll(() {
      tsx = File('../lcc-app/src/app/components/CustomerServiceChat.tsx')
          .readAsStringSync();
      chatTs = File('../lcc-app/src/app/i18n/ns/chat.ts').readAsStringSync();
    });

    test('the port source is the 564-line component at the pinned commit', () {
      expect(tsx.split('\n').length, greaterThan(500));
      expect(tsx, contains('const POLL_MS = 4000'));
      expect(chatTs, contains('export const chat = ns('));
    });

    for (final Locale locale in kLocales) {
      final String lang = locale.languageCode;

      test('every i18n-derived string in chat.$lang occurs verbatim in the web '
          'source', () {
        final Map<String, dynamic> oracle = loadTier1('chat', lang);
        // The API-derived nodes come from the synthetic fixture, not from the
        // web source, and are checked in the next test instead.
        final Set<String> apiDerived = <String>{
          for (final Map<String, dynamic> m in _fixtureMessages())
            _stripBold(m['body'] as String),
          ...(_fixtureMessages().last['suggestions'] as List<dynamic>? ??
                  <dynamic>[])
              .cast<String>(),
          kPendingText,
          '${_fixtureUnread()}',
        };

        final List<String> orphans = <String>[];
        int checked = 0;
        for (final String view in kChatViews) {
          for (final OracleNode node in tier1View(oracle, view)) {
            if (apiDerived.contains(node.text)) continue;
            checked++;
            if (!tsx.contains(node.text) && !chatTs.contains(node.text)) {
              orphans.add('`${node.text}` (view $view, ${node.source})');
            }
          }
        }
        // ignore: avoid_print
        print('chat.$lang: $checked i18n-derived strings traced to the web '
            'source (${orphans.length} orphaned)');
        expect(
          checked,
          greaterThan(0),
          reason: 'zero strings traced means the filter above ate everything '
              'and this test is vacuous',
        );
        expect(
          orphans,
          isEmpty,
          reason: 'these strings are in the oracle but in neither '
              'CustomerServiceChat.tsx nor i18n/ns/chat.ts at $kWebCommit, so '
              'they were not derived from the port source:\n  '
              '${orphans.join('\n  ')}',
        );
      });
    }

    test('the 8 keys B9b INVENTED are accounted for: 6 gated here, 2 aria-only',
        () {
      // architecture-review.md § 2 says "nothing covers the other seven's
      // placement". Measured against the source: only SIX of the eight are
      // rendered text. This is the correction, asserted rather than asserted
      // about.
      const Map<String, String> invented = <String, String>{
        'endConversation': 'End this conversation',
        'signInTitle': 'Sign in to chat with support',
        'signInBody': 'Your conversation is kept with your account so an '
            'officer can follow it up.',
        'signIn': 'Sign in',
        'tryAgain': 'Try again',
        'ratePrompt': 'How did we do?',
        'rateStarLabel': 'out of 5',
        'rateNotNow': 'Not now',
      };
      // All eight are inline `L(lang, …)` literals in the web source and NONE
      // of them is a key in `i18n/ns/chat.ts` — that is what "invented" means.
      for (final MapEntry<String, String> e in invented.entries) {
        expect(tsx.contains(e.value), isTrue, reason: e.key);
        expect(
          chatTs.contains('${e.key}:'),
          isFalse,
          reason: '${e.key} is a B9b invention; if the web namespace gained it '
              'the count below is stale',
        );
      }

      final Map<String, dynamic> oracle = loadTier1('chat', 'en');
      final Set<String> inOracle = <String>{
        for (final String view in kChatViews)
          for (final OracleNode n in tier1View(oracle, view)) n.text,
      };

      final List<String> gated = invented.entries
          .where((MapEntry<String, String> e) => inOracle.contains(e.value))
          .map((MapEntry<String, String> e) => e.key)
          .toList(growable: false);

      // ignore: avoid_print
      print('B9b invented 8 keys; Tier 1 gates the placement of '
          '${gated.length}: ${gated.join(', ')}');

      expect(
        gated.toSet(),
        <String>{
          'signInTitle',
          'signInBody',
          'signIn',
          'tryAgain',
          'ratePrompt',
          'rateNotNow',
        },
        reason: 'SIX, not seven. `endConversation` (:225-226) and '
            '`rateStarLabel` (:477) are aria-label/title only, so a RENDERED '
            'TEXT oracle can never see them — recorded in the oracle\'s '
            '`provenance.aria_only` rather than left to look like an omission.',
      );

      final Map<String, dynamic> ariaOnly =
          (oracle['provenance'] as Map<String, dynamic>)['aria_only']
              as Map<String, dynamic>;
      expect(ariaOnly.keys, containsAll(<String>[
        'chat.endConversation',
        'chat.rateStarLabel',
        'chat.send',
        'chat.callUs',
        'chat.emailUs',
        'chat.minimize',
        'chat.close',
        'chat.openChat',
      ]));
    });

    test('the API-derived strings come from the SYNTHETIC FIXTURE, and the '
        'fixture declares itself synthetic', () {
      final Map<String, dynamic> capture =
          loadSyntheticChatApi('me-chat-messages')['_capture']
              as Map<String, dynamic>;
      expect(
        capture['provenance'] as String,
        contains('SYNTHETIC'),
        reason: 'B2-AC-36 is reported NOT EVALUATED with its reason for every '
            '/me/* endpoint (B9-AC-57), never PASS — the oracle inherits that',
      );
      final Map<String, dynamic> oracle = loadTier1('chat', 'en');
      expect(
        tier1View(oracle, 'transcript')
            .map((OracleNode n) => n.text)
            .toList(growable: false),
        containsAll(<String>[
          for (final Map<String, dynamic> m in _fixtureMessages())
            _stripBold(m['body'] as String),
        ]),
      );
      expect(
        tier1View(oracle, 'launcher.badge').single.text,
        '${_fixtureUnread()}',
        reason: 'the badge number is Σ unread_citizen over the fixture = '
            '${_fixtureUnread()}, not a value typed into the oracle',
      );
    });
  });

  // ───────────────────────────────────────────────────────────────────────────
  // 2. The comparisons
  // ───────────────────────────────────────────────────────────────────────────

  for (final Locale locale in kLocales) {
    final String lang = locale.languageCode;

    group('Tier 1 — chat — $lang', () {
      late Map<String, dynamic> oracle;
      late FakeChatRepository repository;
      late FakeHelpChannelsRepository help;
      late ChatBloc bloc;

      setUp(() => oracle = loadTier1('chat', lang));

      /// Pumps the panel FIRST, then drives it.
      ///
      /// `setUp` runs OUTSIDE `testWidgets`' `FakeAsync` zone, so a BLoC
      /// constructed there owns an event queue `tester.pump()` never drains —
      /// `tier1_notifications_test.dart` records the run that proved it and
      /// `chat_panel_test.dart` re-learned it the same way.
      Future<void> drive(
        WidgetTester tester, {
        bool signedIn = true,
        bool open = true,
        void Function(FakeChatRepository)? setUpRepository,
      }) async {
        repository = FakeChatRepository();
        help = FakeHelpChannelsRepository();
        setUpRepository?.call(repository);
        bloc = chatBlocOver(repository, help: help);
        addTearDown(bloc.close);

        await pumpChatPanel(tester, bloc, locale: locale);
        if (signedIn) {
          bloc.add(const ChatAuthChanged(true));
          for (int i = 0; i < 3; i++) {
            await tester.pump();
          }
        }
        if (open) {
          bloc.add(const ChatOpened());
          for (int i = 0; i < 5; i++) {
            await tester.pump();
          }
        }
      }

      /// An open panel holds a live 4,000 ms `Timer.periodic`, and
      /// `flutter_test` fails a test that completes with one pending. That is
      /// B9-AC-17's mechanism working, so it is honoured rather than suppressed.
      Future<void> shutdown(WidgetTester tester) async {
        repository.latency = Duration.zero;
        bloc.add(const ChatDismissed());
        for (int i = 0; i < 4; i++) {
          await tester.pump();
        }
      }

      /// Compares one view and books the count.
      void parity(String view, List<DumpNode> actual, {int expectClocks = 0}) {
        expectParity(oracle, view, actual, route: kSurface, locale: lang);
        _compared[lang] = _compared[lang]! + actual.length;
        _clocksExcluded[lang] = _clocksExcluded[lang]! + expectClocks;
        _viewsExercised.add(view);
      }

      /// The panel dump with the `clockTime` nodes taken out, having first
      /// asserted that exactly [stamps] of them existed.
      List<DumpNode> panelWithoutClocks(WidgetTester tester, int stamps) {
        final ({List<DumpNode> compared, List<DumpNode> clocks}) split =
            _splitClocks(tester, dumpText(tester, find.byType(ChatPanel)));
        expect(
          split.clocks,
          hasLength(stamps),
          reason: 'the clockTime exclusion is COUNTED so it cannot widen into '
              'a hiding place. The fixture has ${_fixtureStampCount()} messages '
              'carrying sent_at, so a full transcript renders exactly that many '
              'stamps (:404). Got ${split.clocks.length}: '
              '${split.clocks.map((DumpNode n) => n.text).toList()}. Too few '
              'means the port stopped rendering one; too many means it grew one '
              'on the greeting or the optimistic bubble, neither of which has a '
              'sent_at in the source.',
        );
        return split.compared;
      }

      // ── signedOut — `:282-311` ────────────────────────────────────────────

      testWidgets('signedOut — the prompt, and NOTHING else',
          (WidgetTester tester) async {
        await drive(tester, signedIn: false);

        // The whole panel, not a sub-region: `expectParity` fails on an EXTRA
        // node, so this is also the assertion that a signed-out citizen gets no
        // composer, no chips and no transcript — the § 7.8(3) security item,
        // gated here as a text claim as well as a widget one.
        parity('signedOut', dumpText(tester, find.byType(ChatPanel)));

        await shutdown(tester);
      });

      // ── loading — `:317-325` ──────────────────────────────────────────────

      testWidgets('loading — a skeleton contributes NO text',
          (WidgetTester tester) async {
        // `transcriptLoading` is `transcriptStatus == loading && messages
        // .isEmpty` (`chat_state.dart:201`, `:317`), which needs the threads
        // read to have LANDED (so a thread is adopted) while the transcript
        // read is still in flight. So the latency goes on after the panel is
        // up, and time is advanced in two steps rather than one.
        repository = FakeChatRepository();
        help = FakeHelpChannelsRepository();
        repository.latency = const Duration(milliseconds: 200);
        bloc = chatBlocOver(repository, help: help);
        addTearDown(bloc.close);

        await pumpChatPanel(tester, bloc, locale: locale);
        bloc.add(const ChatAuthChanged(true));
        await tester.pump();
        // Threads land at t=200; the transcript request is issued straight
        // after and is still in flight at t=250.
        await tester.pump(const Duration(milliseconds: 250));
        bloc.add(const ChatOpened());
        for (int i = 0; i < 4; i++) {
          await tester.pump();
        }

        // Snapshot BEFORE draining. The order matters and is not fussiness:
        // this test holds a stub open, and if the assertion threw first the
        // drain would never run — a test that ends with a live `Future.delayed`
        // inside `FakeAsync` wedges the runner rather than failing it.
        final List<DumpNode> snapshot =
            dumpText(tester, find.byType(ChatPanel));

        repository.latency = Duration.zero;
        await tester.pump(const Duration(milliseconds: 400));
        for (int i = 0; i < 8; i++) {
          await tester.pump();
        }

        parity('loading', snapshot);

        await shutdown(tester);
      });

      // ── error — `:326-336` ────────────────────────────────────────────────

      testWidgets('error — the retry control, and no message line',
          (WidgetTester tester) async {
        // ONLY the transcript fails. Failing the THREADS read too means no
        // thread is adopted, no transcript is ever requested and there is no
        // error to render — a green test asserting nothing.
        await drive(
          tester,
          setUpRepository: (FakeChatRepository r) =>
              r.messages = const Left<Failure, List<ChatMessage>>(
            Failure('stubbed transcript failure'),
          ),
        );

        // `:328` renders `transcript.error.message`; this port renders no such
        // line and the oracle records the omission in `not_evaluated` rather
        // than absorbing it. Because `expectParity` fails on an EXTRA node,
        // this view is ALSO the assertion that no Dart exception string leaked
        // onto the surface in its place.
        parity('error', dumpText(tester, find.byType(ChatPanel)));

        await shutdown(tester);
      });

      // ── greeting — `:340-362` ─────────────────────────────────────────────

      testWidgets('greeting — the assistant opens the conversation; this is '
          'NOT an empty state', (WidgetTester tester) async {
        await drive(
          tester,
          setUpRepository: (FakeChatRepository r) => r.emptyTranscript(),
        );

        parity('greeting', panelWithoutClocks(tester, 0));

        await shutdown(tester);
      });

      // ── transcript — `:364-408` ───────────────────────────────────────────

      testWidgets('transcript — six bodies in order, timestamps excluded by '
          'name', (WidgetTester tester) async {
        await drive(tester);

        parity(
          'transcript',
          panelWithoutClocks(tester, _fixtureStampCount()),
          expectClocks: _fixtureStampCount(),
        );

        await shutdown(tester);
      });

      // ── pending — `:411-428` ──────────────────────────────────────────────

      testWidgets('pending — the optimistic bubble sits after the transcript '
          'and the composer is cleared', (WidgetTester tester) async {
        await drive(tester);
        repository.latency = const Duration(milliseconds: 200);

        bloc.add(const ChatMessageSubmitted(kPendingText));
        await tester.pump();
        await tester.pump();

        final List<DumpNode> snapshot =
            panelWithoutClocks(tester, _fixtureStampCount());

        repository.latency = Duration.zero;
        await tester.pump(const Duration(milliseconds: 400));
        for (int i = 0; i < 8; i++) {
          await tester.pump();
        }

        parity('pending', snapshot, expectClocks: _fixtureStampCount());

        await shutdown(tester);
      });

      // ── typing — `:433-459` ───────────────────────────────────────────────

      testWidgets('typing — the three bouncing dots contribute NO text',
          (WidgetTester tester) async {
        await drive(tester);
        expect(find.byType(ChatTypingIndicator), findsNothing);

        repository.latency = const Duration(milliseconds: 200);
        bloc.add(const ChatMessageSubmitted(kPendingText));
        await tester.pump();
        await tester.pump();

        // `isTyping` (`:115`) and `pendingText` (`:134`) are set by the same
        // statement pair and cleared by the same `finally`, so this state is
        // not reachable without the optimistic bubble and its text list is
        // `pending`'s. Asserting it anyway is not vacuous: it is the assertion
        // that the indicator added NOTHING — a port that wrote "Agent is
        // typing…" would surface here as an EXTRA node and nowhere else.
        expect(find.byType(ChatTypingIndicator), findsOneWidget);
        final List<DumpNode> snapshot =
            panelWithoutClocks(tester, _fixtureStampCount());

        repository.latency = Duration.zero;
        await tester.pump(const Duration(milliseconds: 400));
        for (int i = 0; i < 8; i++) {
          await tester.pump();
        }

        parity('typing', snapshot, expectClocks: _fixtureStampCount());

        await shutdown(tester);
      });

      // ── rating — `:466-491` ───────────────────────────────────────────────

      testWidgets('rating — the strip replaces the chips', (
        WidgetTester tester,
      ) async {
        await drive(tester);
        bloc.add(const ChatRatingRequested());
        for (int i = 0; i < 4; i++) {
          await tester.pump();
        }

        // The five stars are `aria-label` only (`:477`), so they contribute no
        // text and the strip is prompt + "Not now". `:494`'s `!rating` gate
        // means the chips are gone, which shows up here as their four nodes
        // being absent rather than as a separate assertion.
        parity(
          'rating',
          panelWithoutClocks(tester, _fixtureStampCount()),
          expectClocks: _fixtureStampCount(),
        );

        await shutdown(tester);
      });

      // ── minimized — `:202`, `:222`, `:282`, `:314` ────────────────────────

      testWidgets('minimized — the header and nothing else',
          (WidgetTester tester) async {
        await drive(tester);
        bloc.add(const ChatMinimizeToggled());
        for (int i = 0; i < 4; i++) {
          await tester.pump();
        }

        parity('minimized', dumpText(tester, find.byType(ChatPanel)));

        await shutdown(tester);
      });

      // ── chat.chips — `:187-192`, `:494-514` ───────────────────────────────

      testWidgets('chips.openingQuickReplies — four TRANSLATED labels',
          (WidgetTester tester) async {
        await drive(
          tester,
          setUpRepository: (FakeChatRepository r) => r.emptyTranscript(),
        );

        parity(
          'chips.openingQuickReplies',
          dumpText(tester, find.byType(ChatSuggestionChips)),
        );

        await shutdown(tester);
      });

      testWidgets('chips.botSuggestions — the LAST message\'s list, untranslated',
          (WidgetTester tester) async {
        await drive(tester);

        // The same two strings in both locales, and that is the assertion:
        // `:192` reads `messages[last].suggestions`, which is literal API text.
        // A port that ran these through `.tr()` would pass `en` and fail `lo`.
        parity(
          'chips.botSuggestions',
          dumpText(tester, find.byType(ChatSuggestionChips)),
        );

        await shutdown(tester);
      });

      testWidgets('chips.suppressedWhenAgentAssigned — an empty list, measured',
          (WidgetTester tester) async {
        // th-pending-2 is the fixture's agent-assigned thread. Making it the
        // only thread makes it the adopted one.
        await drive(
          tester,
          setUpRepository: (FakeChatRepository r) {
            final ChatThread assigned = syntheticThreads()
                .firstWhere((ChatThread t) => t.assignedName != null);
            r.threads = Right<Failure, List<ChatThread>>(<ChatThread>[assigned]);
          },
        );

        expect(
          find.byType(ChatSuggestionChips),
          findsOneWidget,
          reason: 'the widget is still built (`:116`); it is its LABEL LIST '
              'that `:190-191` empties. Asserting the empty dump on a widget '
              'that is not there would be vacuous.',
        );
        parity(
          'chips.suppressedWhenAgentAssigned',
          dumpText(tester, find.byType(ChatSuggestionChips)),
        );

        await shutdown(tester);
      });

      // ── chat.launcher — `:544-561` ────────────────────────────────────────

      testWidgets('launcher.noBadge — an icon, and no number',
          (WidgetTester tester) async {
        await _pumpLauncher(tester, 0, locale: locale);
        parity(
          'launcher.noBadge',
          dumpText(tester, find.byType(ChatLauncherButton)),
        );
      });

      testWidgets('launcher.badge — the number, from the fixture',
          (WidgetTester tester) async {
        await _pumpLauncher(tester, _fixtureUnread(), locale: locale);
        parity(
          'launcher.badge',
          dumpText(tester, find.byType(ChatLauncherButton)),
        );
      });
    });
  }

  // ───────────────────────────────────────────────────────────────────────────
  // 3. Did the comparison actually happen? — the Capability Rule, closed
  // ───────────────────────────────────────────────────────────────────────────

  test('EVERY declared view was compared, and the element count is printed', () {
    // ignore: avoid_print
    print('Tier 1 chat — elements compared: '
        'en=${_compared['en']}, lo=${_compared['lo']} '
        '(clockTime nodes excluded: en=${_clocksExcluded['en']}, '
        'lo=${_clocksExcluded['lo']}); '
        'views exercised: ${_viewsExercised.length}/${kChatViews.length}');

    expect(
      _viewsExercised,
      kChatViews.toSet(),
      reason: 'a view declared in the oracle but never put in front of '
          'expectParity is NOT EVALUATED, and a suite that stays green while '
          'that happens is the Capability Rule failure this file exists to '
          'close. Missing: '
          '${kChatViews.toSet().difference(_viewsExercised)}',
    );

    for (final Locale locale in kLocales) {
      final String lang = locale.languageCode;
      final Map<String, dynamic> views =
          loadTier1('chat', lang)['views'] as Map<String, dynamic>;
      final int declared = views.values
          .fold<int>(0, (int s, dynamic v) => s + (v as List<dynamic>).length);

      expect(
        _compared[lang],
        declared,
        reason: 'chat.$lang.json declares $declared elements and this run '
            'compared ${_compared[lang]}. Tier 1 is blocking at 100 % '
            '(B2-AC-8), so the two must be equal — a shortfall means a view '
            'was loaded and not asserted.',
      );
      expect(
        _compared[lang],
        greaterThan(0),
        reason: 'zero elements compared is NOT EVALUATED, not PASS',
      );
      expect(
        _clocksExcluded[lang],
        _fixtureStampCount() * 4,
        reason: 'four views carry a full transcript (transcript, pending, '
            'typing, rating) and each excludes ${_fixtureStampCount()} '
            'clockTime nodes. The exclusion is counted so that "excluded" can '
            'never quietly become "never rendered".',
      );
    }
  });
}

/// `formatText`'s only content transform — `:171-180`. The `**` delimiters of
/// every CLOSED pair are dropped and nothing else changes.
///
/// Reimplemented here in two lines rather than calling `parseChatText`: this
/// runs against the ORACLE, and checking the oracle with the parser the oracle
/// is meant to gate would be circular.
String _stripBold(String body) {
  final StringBuffer out = StringBuffer();
  int i = 0;
  while (true) {
    final int a = body.indexOf('**', i);
    final int b = a < 0 ? -1 : body.indexOf('**', a + 2);
    if (a < 0 || b < 0) break;
    out.write(body.substring(i, a));
    out.write(body.substring(a + 2, b));
    i = b + 2;
  }
  out.write(body.substring(i));
  return out.toString();
}
