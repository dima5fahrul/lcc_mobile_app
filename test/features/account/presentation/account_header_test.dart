/// **V-16 / V-17 — the likeness ruling. B8-AC-11, B8-AC-12, B8-AC-13,
/// B8-AC-14, B8-AC-15, B8-AC-52.**
///
/// `GOR-245-b1b-assets/security-review.md`:382-404 is release-blocking on B8,
/// and specs.md § 6.2 rules it closed **by construction** rather than by
/// remediation. These are the assertions that make "by construction" checkable.
///
/// The three greps (`user-photo`, `Image.asset`, `deactivate`) are structural
/// tests over the source tree rather than widget tests, because the claim is
/// about **what does not exist anywhere in `lib/`** — a widget test can only
/// show that one screen does not render it.
library;

import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lcc_mobile_app/features/account/presentation/widgets/account_header.dart';
import 'package:lcc_mobile_app/features/session/domain/entities/citizen_account.dart';
import 'package:lcc_mobile_app/presentation/theme/app_theme.dart';

import '../../../helpers/app_test_harness.dart';

/// A synthetic account. No real citizen data (specs.md § 6.11's fixture rule
/// applies to widget fixtures too).
CitizenAccount account({
  String name = 'Somchai Vongsa',
  String? avatarUrl,
  bool verified = false,
  String uin = '0000-0000-0000-0000',
}) =>
    CitizenAccount(
      id: 'acc_synthetic_b8_0001',
      uin: uin,
      name: name,
      phone: '+85620000000',
      email: 'somchai.vongsa@example.test',
      nationalIdNo: 'ID-SYNTHETIC-0001',
      dateOfBirth: '1990-01-01',
      gender: 'male',
      avatarUrl: avatarUrl,
      preferredLang: 'lo',
      jurisdiction: 'synthetic',
      householdNo: 'HH-SYNTHETIC-0001',
      address: 'Ban Synthetic, Sisattanak, Vientiane',
      verified: verified,
      eidVerified: false,
      active: true,
      createdAt: '2020-01-01T00:00:00Z',
    );

/// A `const`-able default for [pumpHeader]'s `onPickAvatar`.
void _noop() {}

/// B8b added two required parameters to [AccountHeader] — `uploading` and
/// `onPickAvatar`. They are surfaced here with defaults so B8a's cases keep
/// their subject (the render, not the control): every case below still pumps
/// the not-uploading state, which is what they were written to assert.
///
/// **The upload control has its own file** — `account_avatar_test.dart` — which
/// drives `uploading: true` and a real tap. A default here is a convenience for
/// callers that do not exercise the control, not a way for the control to go
/// untested.
Future<void> pumpHeader(
  WidgetTester tester, {
  required CitizenAccount? subject,
  bool loading = false,
  bool uploading = false,
  VoidCallback onPickAvatar = _noop,
  Locale locale = const Locale('en'),
}) async {
  tester.view.devicePixelRatio = 1.0;
  tester.view.physicalSize = const Size(390, 1400);
  addTearDown(tester.view.reset);

  await tester.pumpWidget(wrapWithLocalization(
    // The `Builder` and the three delegate lines are load-bearing, not
    // boilerplate: without them `context.localizationDelegates` never reaches
    // `MaterialApp`, `.tr()` returns the raw key, and every text assertion
    // below silently compares against `"account.uin"`. Measured — the first
    // draft of this file did exactly that. The idiom is `pumpChatPanel`'s.
    Builder(
      builder: (BuildContext context) => MaterialApp(
        theme: AppTheme.light(),
        localizationsDelegates: context.localizationDelegates,
        supportedLocales: context.supportedLocales,
        locale: context.locale,
        home: Scaffold(
          body: AccountHeader(
            account: subject,
            loading: loading,
            uploading: uploading,
            onPickAvatar: onPickAvatar,
          ),
        ),
      ),
    ),
    startLocale: locale,
  ));
  await tester.pumpAndSettle();
}

void main() {
  // ── B8-AC-12 — V-16, closed via the SECOND clause of its verification ─────

  group('B8-AC-12 — V-16 is closed app-wide: `user-photo` has no CODE '
      'reference left', () {
    /// V-16's own verification (`security-review.md`:390-391) is a
    /// **disjunction**: *"the built APK contains no `user-photo.webp`, **or**
    /// it contains it and no citizen-avatar code path references it."* B8a
    /// satisfies the second clause. The first (deleting the asset) is B1b's
    /// property and is FU-5, for B11.
    test('every hit is a comment line — the grep output is in the QA report',
        () {
      final List<String> codeHits = <String>[];
      final List<String> commentHits = <String>[];

      for (final FileSystemEntity entity
          in Directory('lib').listSync(recursive: true)) {
        if (entity is! File || !entity.path.endsWith('.dart')) continue;
        final List<String> lines = entity.readAsLinesSync();
        for (int i = 0; i < lines.length; i++) {
          if (!lines[i].contains('user-photo')) continue;
          final String trimmed = lines[i].trimLeft();
          final bool isComment =
              trimmed.startsWith('//') || trimmed.startsWith('///') ||
                  trimmed.startsWith('*');
          (isComment ? commentHits : codeHits)
              .add('${entity.path}:${i + 1}: ${lines[i].trim()}');
        }
      }

      // Printed unconditionally: a green gate with no output is what this
      // discipline exists to stop, and B8-AC-12 asks for the grep output by
      // name rather than for a summary of it.
      // ignore: avoid_print
      print('grep -rn "user-photo" lib/  →  '
          '${commentHits.length} comment hit(s), ${codeHits.length} code hit(s)');
      for (final String hit in commentHits) {
        // ignore: avoid_print
        print('  [comment] $hit');
      }
      for (final String hit in codeHits) {
        // ignore: avoid_print
        print('  [CODE]    $hit');
      }

      expect(
        codeHits,
        isEmpty,
        reason: 'One `Image.asset` fails this and RE-OPENS V-16 and V-17. '
            'Comment-only hits are the pass condition — the prose explaining '
            'why the asset is not used is exactly what should survive.',
      );
    });
  });

  // ── B8-AC-11 — V-17, closed outright ──────────────────────────────────────

  test('B8-AC-11 — no file under `lib/features/account/` renders any '
      '`Image.asset` at all', () {
    final List<String> hits = <String>[];
    for (final FileSystemEntity entity
        in Directory('lib/features/account').listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      final List<String> lines = entity.readAsLinesSync();
      for (int i = 0; i < lines.length; i++) {
        final String trimmed = lines[i].trimLeft();
        if (trimmed.startsWith('//') || trimmed.startsWith('///')) continue;
        if (lines[i].contains('Image.asset')) {
          hits.add('${entity.path}:${i + 1}');
        }
      }
    }

    expect(
      hits,
      isEmpty,
      reason: 'V-17: `AccountPage.tsx:327` falls back to a stock photograph of '
          'an identifiable stranger. `Hero.tsx:226-231` — the same oracle, in '
          'prose — says a citizen with no photo gets their initial instead. '
          'B8 ports the comment, not the code.',
    );
  });

  testWidgets('B8-AC-11 — the non-`avatar_url` branch is the initial tile',
      (WidgetTester tester) async {
    await pumpHeader(tester, subject: account());

    // The initial, drawn. No image widget at all in the absent case.
    expect(find.text('S'), findsOneWidget);
    expect(find.byType(Image), findsNothing);
  });

  testWidgets('B8-AC-11 — an EMPTY avatar_url is the absent case too',
      (WidgetTester tester) async {
    await pumpHeader(tester, subject: account(avatarUrl: ''));

    expect(find.text('S'), findsOneWidget);
    expect(find.byType(Image), findsNothing);
  });

  // ── B8-AC-13 — the initial is a UTF-16 CODE UNIT ──────────────────────────

  group('B8-AC-13 — `trimmed[0]`, not `.characters.first`', () {
    const String laoName = 'ບຸນມີ ສີສະຫວັດ';

    test('the fixture PROVABLY discriminates the two implementations', () {
      // If these ever agree, every assertion below is vacuous and this test
      // says so instead of going green.
      expect(
        laoName.trim()[0],
        isNot(laoName.trim().characters.first),
        reason: 'For ASCII, a code unit and a grapheme cluster coincide, so an '
            'ASCII-only fixture passes for BOTH implementations. This Lao '
            'name has a combining vowel on its first consonant, which is what '
            'makes the two differ (`ບ` vs `ບຸ`).',
      );
    });

    testWidgets('the header draws `ບ`, the bare consonant',
        (WidgetTester tester) async {
      await pumpHeader(tester, subject: account(name: laoName));

      expect(find.text('ບ'), findsOneWidget);
    });

    testWidgets('and NOT `ບຸ`, the grapheme cluster a careful Dart developer '
        'would produce', (WidgetTester tester) async {
      await pumpHeader(tester, subject: account(name: laoName));

      expect(
        find.text('ບຸ'),
        findsNothing,
        reason: 'JavaScript `charAt(0)` returns one UTF-16 code unit '
            '(`Hero.tsx:183`). The cluster is arguably the nicer render; it is '
            'also a DIFFERENT STRING, and Tier 1 compares text exactly. '
            '`lao_id_card.dart:322-324` already records this and is the '
            'implementation reused here.',
      );
    });

    testWidgets('an empty name draws no initial rather than crashing',
        (WidgetTester tester) async {
      await pumpHeader(tester, subject: account(name: '   '));

      expect(tester.takeException(), isNull);
      // `trimmed.isEmpty ? '' : trimmed[0]` — the empty string, which is not a
      // crash and, just as importantly, not a substituted placeholder glyph.
      // The rest of the header still renders around it.
      expect(find.text('UIN: 0000-0000-0000-0000'), findsOneWidget);
      expect(find.byType(Image), findsNothing);
    });
  });

  // ── B8-AC-14 — the tile is the ERROR state as well ────────────────────────

  testWidgets('B8-AC-14 — an avatar_url that fails to load renders the initial '
      'tile, not a broken-image glyph', (WidgetTester tester) async {
    // `Image.network` in a widget test has no HTTP client that can succeed —
    // `flutter_test` installs one that answers 400 for every request — so this
    // URL exercises the real `errorBuilder` path rather than a simulated one.
    await pumpHeader(
      tester,
      subject: account(avatarUrl: 'https://example.test/no-such-avatar.png'),
    );

    // Let the failing load settle.
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();

    expect(
      find.text('S'),
      findsOneWidget,
      reason: 'A broken-image glyph on a government identity surface is worse '
          'than no photo — `lao_id_card.dart`\'s second easy-to-miss detail.',
    );
  });

  // ── B8-AC-15 — B1b's asset is untouched ───────────────────────────────────

  test('B8-AC-15 — `assets/images/user-photo.webp` still exists and '
      '`pubspec.yaml`\'s asset list is unchanged', () {
    expect(
      File('assets/images/user-photo.webp').existsSync(),
      isTrue,
      reason: 'B8 closes V-16 via clause 2 WITHOUT deleting the asset: it is '
          'B1b\'s, deleting it is outside this batch\'s ownership, and removal '
          'remains the preferred remedy as FU-5 for B11.',
    );

    final String pubspec = File('pubspec.yaml').readAsStringSync();
    expect(pubspec, contains('- assets/images/'));
    expect(pubspec, contains('- assets/icons/lucide/'));
    expect(pubspec, contains('- assets/icons/flags/'));
  });

  // ── B8-AC-52 — the verified chip ──────────────────────────────────────────

  group('B8-AC-52 — the verified chip and the UIN line', () {
    testWidgets('the chip renders only when `account.verified`',
        (WidgetTester tester) async {
      await pumpHeader(tester, subject: account(verified: false));
      expect(find.text('Verified Citizen'), findsNothing);

      await pumpHeader(tester, subject: account(verified: true));
      expect(find.text('Verified Citizen'), findsOneWidget);
    });

    testWidgets('the header shows `UIN: —` when there is no account at all',
        (WidgetTester tester) async {
      await pumpHeader(tester, subject: null);
      expect(find.text('UIN: —'), findsOneWidget);
    });

    testWidgets('and the real UIN when there is one',
        (WidgetTester tester) async {
      await pumpHeader(tester, subject: account(uin: '1234-5678-9012-3456'));
      expect(find.text('UIN: 1234-5678-9012-3456'), findsOneWidget);
    });

    testWidgets('the loading state contributes NO text where the name goes',
        (WidgetTester tester) async {
      await pumpHeader(tester, subject: null, loading: true);

      // `<span className="… animate-pulse" />` — a skeleton, not the word
      // "Loading". A port that wrote copy here would add a node the web does
      // not have, and Tier 1 would see it.
      //
      // The UIN line still renders (it is outside the skeleton's branch) and
      // is the ONLY text node in the header in this state.
      expect(find.text('UIN: —'), findsOneWidget);
      expect(find.textContaining('Loading'), findsNothing);
      expect(
        tester
            .widgetList<Text>(find.byType(Text))
            .map((Text t) => t.data)
            .where((String? d) => d != null && d.isNotEmpty),
        <String?>['UIN: —'],
        // The empty string is the initial tile's `Text('')` for a null
        // account — a node with no glyph, which is what the web's `<img>`
        // slot contributes here too. Filtered rather than asserted away: an
        // empty node is not a rendered node for Tier 1's purposes.
        reason: 'exactly one VISIBLE text node — no name, no placeholder copy',
      );
    });
  });

  // ── B8-AC-25 — `DELETE /me/account` exists nowhere ────────────────────────

  test('B8-AC-25 — no delete-account surface anywhere in `lib/`', () {
    final List<String> hits = <String>[];
    for (final FileSystemEntity entity
        in Directory('lib').listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      final List<String> lines = entity.readAsLinesSync();
      for (int i = 0; i < lines.length; i++) {
        final String trimmed = lines[i].trimLeft();
        final bool isComment = trimmed.startsWith('//') ||
            trimmed.startsWith('///') ||
            trimmed.startsWith('*');
        if (isComment) continue;
        if (lines[i].contains('me/account') ||
            lines[i].contains('deactivate')) {
          hits.add('${entity.path}:${i + 1}: ${lines[i].trim()}');
        }
      }
    }

    expect(
      hits,
      isEmpty,
      reason: 'specs.md § 6.1 / FU-4: `me.deactivate` is defined at '
          '`endpoints.ts:125` and called from NOWHERE in the shipped web app. '
          'Porting it would invent an irreversible deletion that exists only '
          'in the port, invisible to every fidelity tier, in an application '
          'whose APK is unrecallable under ADR-0002. This is the finding most '
          'likely to be "helpfully" reinstated by a dispatch that reads the '
          'roadmap\'s endpoint list instead of the source.',
    );
  });
}
