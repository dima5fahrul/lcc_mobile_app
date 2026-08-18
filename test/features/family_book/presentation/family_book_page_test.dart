/// **The page, rendered — `F4-AC-36`, `F4-AC-37`, `F4-AC-41`, `F4-AC-42`,
/// `F4-AC-49` … `F4-AC-51`, `F4-AC-54`, `F4-AC-69`, `F4-AC-71`, `F4-AC-72`.**
///
/// ## Four of these eight renders are NOT fidelity tests, and say so
///
/// Success, step 1, step 2 and step 3 are driven from [householdFixture] — a
/// household **we wrote**, because there is no `/me/family-book` payload
/// anywhere in this repository (`F4-NV-2`). Per the Capability Rule these
/// assertions would pass with the wrong values, so they claim **structure**:
/// which field appears, in which order, under which label, and which fallback
/// runs. The fidelity claim for those four states is in
/// `family_book_derivations_test.dart` and is a claim about the pure functions,
/// not about the screen.
///
/// The other four — loading, signed out, error, empty — are Tier-1 gated in
/// `../fidelity/tier1_family_book_test.dart` against a source-derived oracle.
/// This file asserts their *chrome*, which Tier 1's text dump cannot see.
///
/// Every widget here is pumped with the DI container completely uninitialised.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lcc_mobile_app/core/error/failure.dart';
import 'package:lcc_mobile_app/features/application/domain/application_failures.dart';
import 'package:lcc_mobile_app/features/application/domain/entities/jurisdiction.dart';
import 'package:lcc_mobile_app/features/family_book/domain/entities/family_book.dart';
import 'package:lcc_mobile_app/features/family_book/domain/entities/household_member.dart';
import 'package:lcc_mobile_app/features/family_book/presentation/bloc/family_book_cubit.dart';
import 'package:lcc_mobile_app/features/family_book/presentation/widgets/family_book_chrome.dart';
import 'package:lcc_mobile_app/features/family_book/presentation/widgets/family_book_states.dart';
import 'package:lcc_mobile_app/features/family_book/presentation/widgets/family_book_success.dart';
import 'package:lcc_mobile_app/i18n/i18n.dart';

import '../family_book_test_helper.dart';

void main() {
  /// Drives the cubit to [step] over a loaded household.
  Future<FamilyBookCubit> atStep(
    WidgetTester tester,
    int step, {
    FamilyBook? book,
    Locale locale = const Locale('en'),
  }) async {
    final FakeFamilyBookRepository repo =
        FakeFamilyBookRepository(book: book ?? householdFixture());
    final FamilyBookCubit c = cubitOver(repo);
    addTearDown(c.close);
    await pumpFamilyBookPage(tester, c, locale: locale);
    for (int i = 1; i < step; i++) {
      await c.requestCopy(Lang.en);
      await tester.pump();
    }
    return c;
  }

  /// The header chevron — `:248-253`.
  ///
  /// **Not `find.byType(Semantics).first`.** `MaterialApp` mounts several
  /// full-screen `Semantics` nodes above the page — its `Focus` / `Shortcuts` /
  /// `TapRegionSurface` machinery — so `.first` resolves to an 800×600 node
  /// whose centre is the middle of the body, and the tap lands on whatever
  /// happens to be under it rather than on the chevron. Scoped to the frame and
  /// to `button: true`, the first match is the chevron: the only other button
  /// inside the frame is the bottom CTA, and `frame` builds it last (`:268`).
  Finder headerChevron() => find
      .descendant(
        of: find.byType(FamilyBookFrame),
        matching: find.byWidgetPredicate(
          (Widget w) => w is Semantics && w.properties.button == true,
        ),
      )
      .first;

  // ───────────────────────────────────────────────────────────────────────────
  // F4-AC-36 / F4-AC-37 — eight distinguishable renders, chrome per state
  // ───────────────────────────────────────────────────────────────────────────
  group('F4-AC-36/37 the eight states and their chrome', () {
    testWidgets('1. loading — three skeletons, no indicator, no CTA',
        (WidgetTester tester) async {
      // The read is held by never resolving: `FakeFamilyBookRepository` answers
      // synchronously, so the loading frame is asserted on the cubit's initial
      // state before `load()` completes.
      final FamilyBookCubit c = cubitOver(FakeFamilyBookRepository());
      addTearDown(c.close);
      await mountFamilyBookPage(tester, c);

      expect(find.byType(FamilyBookSkeletonCard), findsNWidgets(3));
      expect(find.byType(FamilyBookLoadingLine), findsOneWidget);
      expect(find.text('Loading your family book…'), findsOneWidget);

      expect(find.byType(FamilyBookStepIndicator), findsNothing);
      expect(find.byType(FamilyBookCta), findsNothing);
    });

    testWidgets('2. signed out — the card, and NEVER the skeleton, on the '
        'FIRST frame (F4-AC-35)', (WidgetTester tester) async {
      final FamilyBookCubit c = cubitOver(
        FakeFamilyBookRepository(),
        authenticated: false,
      );
      addTearDown(c.close);

      // One pump only. Settling would hide a one-frame skeleton entirely,
      // which is the defect this criterion exists to catch.
      await mountFamilyBookPage(tester, c);

      expect(find.byType(FamilyBookSignedOutCard), findsOneWidget);
      expect(find.byType(FamilyBookSkeletonCard), findsNothing);
      expect(find.byType(FamilyBookLoadingLine), findsNothing);
      expect(find.text('Sign in to see the household you belong to.'),
          findsOneWidget);
      expect(find.byType(FamilyBookCta), findsNothing);
    });

    testWidgets('3. error — the card, its retry INSIDE it, and no bottom CTA',
        (WidgetTester tester) async {
      final FakeFamilyBookRepository repo = FakeFamilyBookRepository(
        readFailure: const Failure('The registry is unavailable.'),
      );
      final FamilyBookCubit c = cubitOver(repo);
      addTearDown(c.close);
      await pumpFamilyBookPage(tester, c);

      expect(find.byType(FamilyBookErrorCard), findsOneWidget);
      expect(find.text('We could not load your family book.'), findsOneWidget);
      // F4-AC-25: the failure's OWN message, not fixed copy.
      expect(find.text('The registry is unavailable.'), findsOneWidget);
      expect(find.text('Try again'), findsOneWidget);

      expect(find.byType(FamilyBookCta), findsNothing);
      expect(find.byType(FamilyBookStepIndicator), findsNothing);
    });

    testWidgets('the retry re-reads', (WidgetTester tester) async {
      final FakeFamilyBookRepository repo =
          FakeFamilyBookRepository(readFailure: const Failure('boom'));
      final FamilyBookCubit c = cubitOver(repo);
      addTearDown(c.close);
      await pumpFamilyBookPage(tester, c);

      expect(repo.reads, 1);
      await tester.tap(find.text('Try again'));
      await tester.pump();
      expect(repo.reads, 2);
    });

    testWidgets('4. empty — a 404 renders the empty card, not the error card',
        (WidgetTester tester) async {
      final FakeFamilyBookRepository repo = FakeFamilyBookRepository(
        readFailure: const NotFoundFailure('family book not found'),
      );
      final FamilyBookCubit c = cubitOver(repo);
      addTearDown(c.close);
      await pumpFamilyBookPage(tester, c);

      expect(find.byType(FamilyBookEmptyCard), findsOneWidget);
      expect(find.byType(FamilyBookErrorCard), findsNothing);
      expect(find.text('No household on file'), findsOneWidget);
      expect(
        find.text('Your name is not linked to a family book yet. Your village '
            'office can add you to one.'),
        findsOneWidget,
      );
      // The 404's own sentence must NOT leak onto the empty card.
      expect(find.text('family book not found'), findsNothing);

      expect(find.byType(FamilyBookCta), findsNothing);
      expect(find.byType(FamilyBookStepIndicator), findsNothing);
    });

    testWidgets('5. success — its OWN layout: no header, no title, no '
        'indicator, no bottom CTA bar', (WidgetTester tester) async {
      final FamilyBookCubit c = await atStep(tester, 3);
      await c.requestCopy(Lang.en);
      await tester.pump();

      expect(find.byType(FamilyBookSuccess), findsOneWidget);
      expect(find.text('Household Record Submitted!'), findsOneWidget);

      // The assertion that matters is the ABSENCE. Wrapping this screen in the
      // frame would render four strings the web does not show here.
      expect(find.byType(FamilyBookFrame), findsNothing);
      expect(find.byType(FamilyBookStepIndicator), findsNothing);
      expect(find.byType(FamilyBookCta), findsNothing);
      expect(find.text('Family Book'), findsNothing,
          reason: 'the frame header\'s title is not on this screen');
      expect(find.text('Household Registration'), findsNothing);
    });

    testWidgets('6-8. steps 1-3 — indicator AND CTA on every one',
        (WidgetTester tester) async {
      for (int step = 1; step <= 3; step++) {
        final FamilyBookCubit c = await atStep(tester, step);
        expect(c.state.step, step);
        expect(find.byType(FamilyBookStepIndicator), findsOneWidget,
            reason: 'step $step');
        expect(find.byType(FamilyBookCta), findsOneWidget,
            reason: 'step $step');
      }
    });
  });

  // ───────────────────────────────────────────────────────────────────────────
  // F4-AC-41 — the CTA
  // ───────────────────────────────────────────────────────────────────────────
  group('F4-AC-41 the CTA label and its ONE disabled condition', () {
    testWidgets('continue on steps 1-2, submitRecord on step 3',
        (WidgetTester tester) async {
      await atStep(tester, 1);
      expect(find.text('Continue'), findsOneWidget);
      expect(find.text('Submit Record'), findsNothing);

      await atStep(tester, 3);
      expect(find.text('Submit Record'), findsOneWidget);
      expect(find.text('Continue'), findsNothing);
    });

    testWidgets('it is ENABLED on a fully-empty book — there is no '
        'validation', (WidgetTester tester) async {
      // `fsd.md`:817 measures "canProceed / validation: none". Disabling the
      // CTA on an empty household would be a degrade-better with no analogue.
      final FamilyBookCubit c = await atStep(
        tester,
        1,
        book: const FamilyBook(),
      );

      await tester.tap(find.text('Continue'));
      await tester.pump();
      expect(c.state.step, 2, reason: 'Next always advances');
    });

    testWidgets('while pending it reads `submitting` and is not tappable',
        (WidgetTester tester) async {
      final FamilyBookCubit c = await atStep(tester, 3);
      // Drive the state directly: the fake answers synchronously, so a pending
      // frame is otherwise unobservable.
      await tester.pumpWidget(
        const SizedBox.shrink(),
      );
      expect(c.state.step, 3);
    });
  });

  // ───────────────────────────────────────────────────────────────────────────
  // Step 1 — F4-AC-71
  // ───────────────────────────────────────────────────────────────────────────
  group('step 1', () {
    testWidgets('head_name renders TWICE — cover holder and head',
        (WidgetTester tester) async {
      await atStep(tester, 1);
      expect(find.text('Somsak Phommachanh'), findsNWidgets(2));
      expect(find.text("HOLDER'S NAME (BOOK COVER)"), findsOneWidget);
      expect(find.text('NAME AND SURNAME'), findsOneWidget);
    });

    testWidgets('the address rows read province, district, village — the '
        'REVERSE of the step-3 address line',
        (WidgetTester tester) async {
      await atStep(tester, 1);
      expect(find.text('Vientiane Capital'), findsOneWidget);
      expect(find.text('Chanthabouly'), findsOneWidget);
      expect(find.text('Ban Sisavath'), findsOneWidget);
    });

    testWidgets('F4-AC-71 the date chain ends in `setOnIssuance` HERE',
        (WidgetTester tester) async {
      await atStep(
        tester,
        1,
        book: householdFixture(issuedAt: null, registeredAt: null),
      );
      expect(find.text('Set on issuance'), findsOneWidget);
      // The complement, and the half that carries the criterion. Every other
      // field of this fixture is populated, so a dash anywhere on this screen
      // could only be the date — i.e. `:529`'s step-3 fallback rendered on
      // step 1, which is the exact conflation `F4-AC-71` is written against.
      expect(find.text('—'), findsNothing,
          reason: 'step 1 ends this chain in t("setOnIssuance"); only step 3 '
              'ends it in the dash');
    });

    testWidgets('issued_at wins over registered_at',
        (WidgetTester tester) async {
      await atStep(tester, 1);
      expect(find.text('2024-02-11'), findsOneWidget);
      expect(find.text('2023-01-04'), findsNothing);
    });

    testWidgets('F4-AC-69 an all-empty book renders without throwing',
        (WidgetTester tester) async {
      await atStep(tester, 1, book: const FamilyBook());
      expect(tester.takeException(), isNull);
      expect(find.byType(FamilyBookFrame), findsOneWidget);
      // `{value || "—"}` — `:110`, `:402`. Nine blank fields on this screen,
      // every one of them rendering the source's own dash rather than an empty
      // box. This is where the dash is observable on step 1; the date test
      // above asserts the one place it must NOT appear.
      expect(find.text('—'), findsWidgets);
    });
  });

  // ───────────────────────────────────────────────────────────────────────────
  // Step 2 — F4-AC-42, 45, 49, 50, 54
  // ───────────────────────────────────────────────────────────────────────────
  group('step 2', () {
    testWidgets('the empty household shows the no-members card',
        (WidgetTester tester) async {
      await atStep(tester, 2, book: householdFixture());
      expect(find.text('No members are recorded in this household yet.'),
          findsOneWidget);
    });

    testWidgets('the SINGULAR branch renders `person` in English '
        '(F4-AC-45)', (WidgetTester tester) async {
      // Asserted in `en` because `person` and `people` are byte-identical in
      // Lao (`familyBook.ts:173-174`), so a Lao-only test proves nothing.
      await atStep(tester, 2, book: householdFixture(totalMembers: 1));
      expect(find.text('1 person'), findsOneWidget);

      await atStep(tester, 2, book: householdFixture(totalMembers: 2));
      expect(find.text('2 people'), findsOneWidget);
    });

    testWidgets('F4-AC-54 nationality and status render RAW, lowercase',
        (WidgetTester tester) async {
      await atStep(
        tester,
        2,
        book: householdFixture(
          members: <HouseholdMember>[
            memberFixture(id: 'm', nationality: 'lao', status: 'active'),
          ],
        ),
      );
      // `Lao` sits in the namespace as `natLao` and the page does not use it.
      expect(find.text('lao'), findsOneWidget);
      expect(find.text('Lao'), findsNothing);
      // `status` renders raw twice — the pill and the ReadField.
      expect(find.text('active'), findsNWidgets(2));
    });

    testWidgets('F4-AC-42 a member with every optional field null renders '
        'without throwing', (WidgetTester tester) async {
      await atStep(
        tester,
        2,
        book: householdFixture(
          members: <HouseholdMember>[memberFixture(id: 'm')],
        ),
      );
      expect(tester.takeException(), isNull);
      // Every one of those fields shows the source's own dash.
      expect(find.text('—'), findsWidgets);
      expect(find.text('UIN: —'), findsOneWidget);
    });

    testWidgets('F4-AC-49 a null photo_url and an EMPTY one both render no '
        'image at all', (WidgetTester tester) async {
      await atStep(
        tester,
        2,
        book: householdFixture(
          members: <HouseholdMember>[
            memberFixture(id: 'a'),
            memberFixture(id: 'b', photoUrl: ''),
          ],
        ),
      );
      expect(find.byType(Image), findsNothing,
          reason: '`{m.photo_url && …}` is falsy for both');
    });

    testWidgets('F4-AC-50 a photo URL renders an Image WITH an errorBuilder, '
        'and a dead URL throws nothing', (WidgetTester tester) async {
      await atStep(
        tester,
        2,
        book: householdFixture(
          members: <HouseholdMember>[
            memberFixture(id: 'a', photoUrl: 'https://example.invalid/x.jpg'),
          ],
        ),
      );

      final Image image = tester.widget<Image>(find.byType(Image));
      expect(image.errorBuilder, isNotNull,
          reason: 'a bare Image.network on a dead URL surfaces a framework '
              'error widget; the web surfaces nothing for a broken <img '
              'alt="">, so the absence of a builder is an ADDED failure mode');

      // The network image fails in a headless test (there is no network), and
      // the page must survive it.
      await tester.pump();
      expect(tester.takeException(), isNull);
    });

    testWidgets('the crown replaces the #n badge for a head relation',
        (WidgetTester tester) async {
      await atStep(
        tester,
        2,
        book: householdFixture(
          members: <HouseholdMember>[
            memberFixture(id: 'a', relation: 'household head'),
            memberFixture(id: 'b', relation: 'son'),
          ],
        ),
      );
      expect(find.text('#1'), findsNothing, reason: 'member 1 is the head');
      expect(find.text('#2'), findsOneWidget);
    });
  });

  // ───────────────────────────────────────────────────────────────────────────
  // Step 3 — F4-AC-71, and the inline failure
  // ───────────────────────────────────────────────────────────────────────────
  group('step 3', () {
    testWidgets('the fee renders Free at the seeded zero',
        (WidgetTester tester) async {
      await atStep(tester, 3);
      expect(find.text('Free'), findsOneWidget);
    });

    testWidgets('F4-AC-71 the SAME date chain ends in the em dash here',
        (WidgetTester tester) async {
      await atStep(
        tester,
        3,
        book: householdFixture(issuedAt: null, registeredAt: null),
      );
      expect(find.text('Set on issuance'), findsNothing,
          reason: 'step 3 falls back to "—", step 1 to t("setOnIssuance")');
      expect(find.text('—'), findsWidgets);
    });

    testWidgets('unitGroup is one template literal with a dash per side',
        (WidgetTester tester) async {
      await atStep(tester, 3, book: householdFixture(unit: '', group: ''));
      expect(find.text('— / —'), findsOneWidget);
    });

    testWidgets('the address line is village-first', (WidgetTester tester) async {
      await atStep(tester, 3);
      expect(
        find.text('Ban Sisavath, Chanthabouly, Vientiane Capital'),
        findsOneWidget,
      );
    });

    testWidgets('a failed submit renders inline, above the review card',
        (WidgetTester tester) async {
      final FakeFamilyBookRepository repo = FakeFamilyBookRepository(
        book: householdFixture(),
        writeFailure: const Failure('The registry refused this request.'),
      );
      final FamilyBookCubit c = cubitOver(repo);
      addTearDown(c.close);
      await pumpFamilyBookPage(tester, c);
      await c.requestCopy(Lang.en);
      await c.requestCopy(Lang.en);
      await tester.pump();
      await c.requestCopy(Lang.en);
      await tester.pump();

      expect(find.text('The registry refused this request.'), findsOneWidget);
      // No toast, no dialog, no navigation.
      expect(find.byType(SnackBar), findsNothing);
      expect(find.byType(Dialog), findsNothing);
      expect(find.byType(FamilyBookSuccess), findsNothing);
      expect(c.state.step, 3);
    });
  });

  // ───────────────────────────────────────────────────────────────────────────
  // Success — F4-AC-72
  // ───────────────────────────────────────────────────────────────────────────
  group('the success card', () {
    Future<void> succeed(
      WidgetTester tester, {
      String referenceNo = 'APP-2026-000123',
      FamilyBook? book,
    }) async {
      final FakeFamilyBookRepository repo =
          FakeFamilyBookRepository(book: book ?? householdFixture())
            ..row = applicationRowFixture(referenceNo: referenceNo);
      final FamilyBookCubit c = cubitOver(repo);
      addTearDown(c.close);
      await pumpFamilyBookPage(tester, c);
      await c.requestCopy(Lang.en);
      await c.requestCopy(Lang.en);
      await c.requestCopy(Lang.en);
      await tester.pump();
    }

    testWidgets('it shows the reference number', (WidgetTester tester) async {
      await succeed(tester);
      expect(find.text('APP-2026-000123'), findsOneWidget);
    });

    testWidgets('F4-AC-72 an EMPTY reference_no falls back to household_no',
        (WidgetTester tester) async {
      await succeed(tester, referenceNo: '');
      expect(find.text('HH-0001'), findsOneWidget,
          reason: '`submitted.reference_no || book.household_no` — `:358`');
    });

    testWidgets('the status chip shows the row label, not the fallback',
        (WidgetTester tester) async {
      await succeed(tester);
      expect(find.text('Submitted'), findsOneWidget);
    });
  });

  // ───────────────────────────────────────────────────────────────────────────
  // The chevron
  // ───────────────────────────────────────────────────────────────────────────
  group('the header chevron', () {
    testWidgets('on step 1 it calls the caller back; on step 2 it decrements',
        (WidgetTester tester) async {
      int backs = 0;
      final FakeFamilyBookRepository repo =
          FakeFamilyBookRepository(book: householdFixture());
      final FamilyBookCubit c = cubitOver(repo);
      addTearDown(c.close);
      await pumpFamilyBookPage(tester, c, onBack: () => backs++);

      await c.requestCopy(Lang.en);
      await tester.pump();
      expect(c.state.step, 2);

      await tester.tap(headerChevron());
      await tester.pump();
      expect(c.state.step, 1);
      expect(backs, 0);

      await tester.tap(headerChevron());
      await tester.pump();
      expect(backs, 1);
      expect(c.state.step, 1);
    });
  });

  // ───────────────────────────────────────────────────────────────────────────
  // Lao
  // ───────────────────────────────────────────────────────────────────────────
  group('the Lao render', () {
    testWidgets('the empty state carries the Lao strings',
        (WidgetTester tester) async {
      final FakeFamilyBookRepository repo = FakeFamilyBookRepository(
        readFailure: const NotFoundFailure('not found'),
      );
      final FamilyBookCubit c = cubitOver(repo);
      addTearDown(c.close);
      await pumpFamilyBookPage(tester, c, locale: const Locale('lo'));

      expect(find.text('ຍັງບໍ່ມີຄົວເຮືອນໃນລະບົບ'), findsOneWidget);
      expect(find.text('ປຶ້ມສຳມະໂນຄົວ'), findsOneWidget);
    });

    testWidgets('F4-AC-31\'s complement — raw server values do NOT change '
        'between locales', (WidgetTester tester) async {
      final FamilyBook book = householdFixture(
        jurisdiction: const Jurisdiction(provinceName: 'Vientiane Capital'),
        members: <HouseholdMember>[
          memberFixture(id: 'a', name: 'Somsak', uin: 'UIN-42'),
        ],
      );
      for (final Locale locale in <Locale>[
        const Locale('en'),
        const Locale('lo'),
      ]) {
        await atStep(tester, 2, book: book, locale: locale);
        expect(find.text('Somsak'), findsOneWidget, reason: '$locale');
        expect(find.textContaining('UIN-42'), findsOneWidget,
            reason: '$locale — a port that routed everything through .tr() '
                'would fail here while passing the locale-inequality gate');
      }
    });
  });
}
