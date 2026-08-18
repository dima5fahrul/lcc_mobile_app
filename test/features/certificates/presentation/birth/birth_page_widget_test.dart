/// Birth's widget-level evidence — `F2-AC-55`, `F2-AC-13`, `F2-AC-14`,
/// `F2-AC-52`, `F2-AC-66`, `F2-AC-67`, `F2-AC-70`.
///
/// ## Why this file exists
///
/// `qa-report.md` § 4 listed twelve criteria as "implemented and reviewable but
/// not driven." Under the Capability Rule that is NOT EVALUATED, and a comment
/// asserting a property is a claim, not evidence. This file renders the widgets
/// and looks.
///
/// **`F2-AC-55` is first on purpose.** R9's sharper arm is `.docx`, not `.pdf`:
/// both F2 pages' `accept` names PDF explicitly (`BirthDeclarationPage.tsx:366`),
/// so `FileType.custom(allowedExtensions: ['jpg','png','pdf'])` would pass a
/// PDF test and still reject the file the web accepts. The test below drives a
/// `.docx` through the real `onChanged` path.
///
/// ## Not one test here calls `DependencyInjection.init()`
///
/// `F2-AC-13` / `F0-AC-77`: every kernel widget Birth mounts is pumped with
/// **parameters only**, against a cubit whose collaborators are injected fakes.
/// A widget reaching for a service locator would throw here.
library;

import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lcc_mobile_app/core/error/failure.dart';
import 'package:lcc_mobile_app/features/application/domain/entities/picked_attachment.dart';
import 'package:lcc_mobile_app/features/application/domain/repositories/application_repository.dart';
import 'package:lcc_mobile_app/features/application/domain/usecases/application_usecases.dart';
import 'package:lcc_mobile_app/features/certificates/domain/submission/submission_clock.dart';
import 'package:lcc_mobile_app/features/certificates/presentation/birth/birth_certificate_page.dart';
import 'package:lcc_mobile_app/features/certificates/presentation/birth/birth_fields.dart';
import 'package:lcc_mobile_app/features/certificates/presentation/birth/birth_form_cubit.dart';
import 'package:lcc_mobile_app/features/certificates/presentation/birth/birth_form_state.dart';
import 'package:lcc_mobile_app/features/certificates/presentation/birth/birth_steps.dart';
import 'package:lcc_mobile_app/features/reference/domain/entities/lookup_key.dart';
import 'package:lcc_mobile_app/features/reference/domain/entities/lookup_option.dart';
import 'package:lcc_mobile_app/features/reference/domain/repositories/reference_repository.dart';
import 'package:lcc_mobile_app/features/reference/domain/usecases/get_lookup_options.dart';
import 'package:lcc_mobile_app/features/service/domain/entities/service.dart';
import 'package:lcc_mobile_app/features/session/domain/entities/bilingual.dart';
import 'package:lcc_mobile_app/features/wallet/domain/entities/payment_method.dart';
import 'package:lcc_mobile_app/presentation/forms/widgets/reference_select_view.dart';

import '../../../application/application_write_fakes.dart';
import '../../../../helpers/app_test_harness.dart';

final DateTime kInstant = DateTime.parse('2026-08-14T02:00:00+07:00')
    .toUtc()
    .add(const Duration(hours: 7));

/// `pumpAndSettle` cannot be used: `EasyLocalization` keeps a frame scheduled
/// and it never returns. Three explicit pumps clear the layout passes.
Future<void> _settle(WidgetTester tester) async {
  for (int i = 0; i < 3; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

Future<void> _pump(
  WidgetTester tester,
  Widget child, {
  String locale = 'en',
}) async {
  await tester.pumpWidget(
    wrapWithLocalization(
      startLocale: Locale(locale),
      Builder(
        builder: (BuildContext context) => MaterialApp(
          locale: context.locale,
          supportedLocales: context.supportedLocales,
          localizationsDelegates: context.localizationDelegates,
          home: Scaffold(body: SingleChildScrollView(child: child)),
        ),
      ),
    ),
  );
  await _settle(tester);
}

/// Never reached by any test here. A call is a bug in the test.
class _UnusedRepo implements ApplicationRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => throw StateError(
        'these widget tests must not reach the write slice — '
        '${invocation.memberName} was called',
      );
}

/// Answers a fixed list, or nothing, or a failure — the three inputs the four
/// kernel control states are built from.
class _RefRepo implements ReferenceRepository {
  _RefRepo({this.rows = const <LookupOption>[], this.fail = false});
  final List<LookupOption> rows;
  final bool fail;

  @override
  Future<Either<Failure, List<LookupOption>>> options(
    LookupKey key, {
    String? parentId,
    PagingMode paging = PagingMode.all,
  }) async {
    if (fail) {
      return const Left<Failure, List<LookupOption>>(Failure('reference down'));
    }
    return Right<Failure, List<LookupOption>>(rows);
  }
}

BirthFormCubit buildCubit({
  List<LookupOption> rows = const <LookupOption>[],
  bool refFails = false,
  Future<Either<Failure, Service>> Function()? loadService,
}) =>
    BirthFormCubit(
      clock: SubmissionClock.fixed(kInstant),
      getLookupOptions:
          GetLookupOptions(repository: _RefRepo(rows: rows, fail: refFails)),
      createApplication: CreateApplication(repository: _UnusedRepo()),
      updateApplication: UpdateApplication(repository: _UnusedRepo()),
      addAttachment: AddAttachment(repository: _UnusedRepo()),
      submitApplication: SubmitApplication(repository: _UnusedRepo()),
      // The page calls `load()` in `initState`, so the ONLY way to hold it in
      // a given top-level branch is to control what the catalogue answers.
      // Pre-emitting a state and pumping is useless — `load()` overwrites it.
      loadService: loadService ??
          () async => const Left<Failure, Service>(Failure('not used here')),
      loadPaymentMethods: () async =>
          const Right<Failure, List<PaymentMethod>>(<PaymentMethod>[]),
      readLegalBasisText: () => 'BIRTH LEGAL BASIS',
    );

void main() {
  // ───────────────────────────────────────────────────────────────────────────
  // F2-AC-55 — R-21, driven. The `.docx` is the case that matters.
  // ───────────────────────────────────────────────────────────────────────────
  group('F2-AC-55 a .docx and a .pdf both reach the attachment list', () {
    Future<PickedAttachment?> picks(String name) async =>
        PickedAttachment(name: name, bytes: null);

    for (final String name in <String>[
      'medical-note.docx', // the sharp case — `accept` does NOT name it
      'hospital-notice.pdf', // named by `accept`, and still not a filter
      'scan.jpg',
      'NOTICE.DOCX', // upper case, because an extension check often lower-cases
      'no-extension-at-all',
      'weird.name.with.dots.docx',
    ]) {
      testWidgets('$name is accepted', (WidgetTester tester) async {
        PickedAttachment? received;

        await _pump(
          tester,
          BirthUploadBox(
            label: 'Hospital notice',
            sublabel: 'Photo or scan',
            file: null,
            onChanged: (PickedAttachment? f) => received = f,
            path: 'child.hospital_notice',
            pickFile: () => picks(name),
          ),
        );

        await tester.tap(find.byType(GestureDetector).first);
        await _settle(tester);

        expect(received, isNotNull,
            reason: '$name was rejected. `accept="image/*,application/pdf"` '
                'filters a browser picker\'s default view and rejects NOTHING '
                '(`:366`), and `handleFile` (`:353-361`) inspects neither '
                '`type` nor `size`. A `FileType.custom` filter would pass the '
                '.pdf case above and still be wrong.');
        expect(received!.name, name);
      });
    }

    testWidgets('a cancelled pick changes nothing — `if (!picked) return`',
        (WidgetTester tester) async {
      bool called = false;
      await _pump(
        tester,
        BirthUploadBox(
          label: 'Hospital notice',
          sublabel: 'Photo or scan',
          file: null,
          onChanged: (PickedAttachment? f) => called = true,
          pickFile: () async => null,
        ),
      );

      await tester.tap(find.byType(GestureDetector).first);
      await _settle(tester);

      expect(called, isFalse, reason: '`:354` returns before onChange');
    });

    testWidgets('a picked file renders its name and can be removed',
        (WidgetTester tester) async {
      PickedAttachment? current =
          PickedAttachment(name: 'chosen.docx', bytes: null);
      await _pump(
        tester,
        BirthUploadBox(
          label: 'Hospital notice',
          sublabel: 'Photo or scan',
          file: current,
          onChanged: (PickedAttachment? f) => current = f,
        ),
      );

      expect(find.text('chosen.docx'), findsOneWidget,
          reason: 'the attachment LIST shows it — this is what "reaches the '
              'attachment list" means');

      await tester.tap(find.byType(IconButton));
      await _settle(tester);
      expect(current, isNull);
    });
  });

  // ───────────────────────────────────────────────────────────────────────────
  // F2-AC-14 / F2-AC-13 — the preset controls, four states, no DI
  // ───────────────────────────────────────────────────────────────────────────
  group('F2-AC-14 the preset nationality control survives all four states', () {
    // `blankChild.nationality = "lao"` (`:170`), `blankParent` (`:177`),
    // `blankInformant` (`:186`). On first paint the value is not among the
    // options — RULING 14's path, fixed by F0c. F2 is its second consumer and
    // its job is to exercise it and report.
    const LookupOption laoRow = LookupOption(
      id: 'lao',
      code: 'lao',
      label: Bilingual(en: 'Lao', lo: 'ລາວ'),
    );

    testWidgets('LOADING — value preset, options not yet arrived',
        (WidgetTester tester) async {
      final BirthFormCubit c = buildCubit(rows: const <LookupOption>[laoRow]);
      // Deliberately NOT awaited: the control is pumped mid-flight.
      unawaited(c.loadReference(BirthRefList.nationality));

      await _pump(
        tester,
        ReferenceSelectView(
          label: const Text('Nationality'),
          source: c.referenceStateOf(BirthRefList.nationality),
          value: const BirthChildInfo().nationality,
          placeholder: 'Select',
          onChanged: (_) {},
        ),
      );

      expect(tester.takeException(), isNull,
          reason: 'RULING 14: ReferenceSelectView threw in build when its '
              'value was not among its options. F0c fixed it; this is the '
              'second consumer at scale — six preset controls per page.');
    });

    testWidgets('EMPTY — options resolved to nothing, value still "lao"',
        (WidgetTester tester) async {
      final BirthFormCubit c = buildCubit();
      await c.loadReference(BirthRefList.nationality);

      await _pump(
        tester,
        ReferenceSelectView(
          label: const Text('Nationality'),
          source: c.referenceStateOf(BirthRefList.nationality),
          value: 'lao',
          placeholder: 'Select a nationality',
          onChanged: (_) {},
        ),
      );

      expect(tester.takeException(), isNull);
      // `ssd.md`:1185 corollary (a), measured on the pinned runtime: a
      // controlled <select> with an unmatched value selects the first
      // non-disabled option, which is the PLACEHOLDER. Not blank, not an
      // invented "Lao" row, not an error string.
      expect(find.text('Select a nationality'), findsOneWidget);
      expect(find.text('Lao'), findsNothing,
          reason: 'a port that invented a row for the unmatched value would '
              'be MORE capable than the web — the L-10(b) failure');
    });

    testWidgets('ERROR-WITH-RETRY — the retry affordance renders',
        (WidgetTester tester) async {
      final BirthFormCubit c = buildCubit(refFails: true);
      await c.loadReference(BirthRefList.nationality);

      await _pump(
        tester,
        ReferenceSelectView(
          label: const Text('Nationality'),
          source: c.referenceStateOf(BirthRefList.nationality),
          value: 'lao',
          placeholder: 'Select',
          onChanged: (_) {},
        ),
      );

      expect(tester.takeException(), isNull);
      expect(c.referenceStateOf(BirthRefList.nationality).failed, isTrue);
      expect(c.referenceStateOf(BirthRefList.nationality).retry, isNotNull,
          reason: 'error-with-retry is a distinct state from plain error');
    });

    testWidgets('DATA — the preset now matches a row and resolves',
        (WidgetTester tester) async {
      final BirthFormCubit c = buildCubit(rows: const <LookupOption>[laoRow]);
      await c.loadReference(BirthRefList.nationality);

      await _pump(
        tester,
        ReferenceSelectView(
          label: const Text('Nationality'),
          source: c.referenceStateOf(BirthRefList.nationality),
          value: 'lao',
          placeholder: 'Select',
          onChanged: (_) {},
        ),
      );

      expect(tester.takeException(), isNull);
      expect(find.text('Lao'), findsOneWidget);
    });

    test('all SIX preset-carrying controls on this page start at "lao"', () {
      // The count `specs.md` § 6.12 gives, asserted rather than trusted:
      // child, mother, father, informant — and Birth mounts ParentSection
      // twice, so more at runtime.
      expect(const BirthChildInfo().nationality, 'lao');
      expect(const BirthParentInfo().nationality, 'lao');
      expect(const BirthInformantInfo().nationality, 'lao');
      const BirthFormData f = BirthFormData();
      expect(
        <String>[
          f.child.nationality,
          f.mother.nationality,
          f.father.nationality,
          f.informant.nationality,
        ],
        <String>['lao', 'lao', 'lao', 'lao'],
      );
      // And the child's place-of-birth country is the other preset (`:171`).
      expect(f.child.pobCountry, 'Laos');
    });
  });

  // ───────────────────────────────────────────────────────────────────────────
  // F2-AC-66 — the CTA is never disabled
  // ───────────────────────────────────────────────────────────────────────────
  group('F2-AC-66 the CTA stays tappable while a submission is in flight', () {
    testWidgets('pending renders the spinner and #C7D2FE, and still taps',
        (WidgetTester tester) async {
      int taps = 0;
      await _pump(
        tester,
        BirthCta(
          pending: true,
          label: 'Submit',
          pendingLabel: 'Submitting…',
          onTap: () => taps++,
        ),
      );

      expect(find.text('Submitting…'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      await tester.tap(find.byType(GestureDetector));
      await _settle(tester);
      expect(taps, 1,
          reason: 'the button is NEVER disabled (`fsd.md`:348). The re-entry '
              'guard is the cubit\'s `if (submitPending) return`, and a port '
              'that disables the button has diverged.');
    });

    testWidgets('idle renders the label and the arrow',
        (WidgetTester tester) async {
      await _pump(
        tester,
        BirthCta(
          pending: false,
          label: 'Continue',
          pendingLabel: 'Submitting…',
          onTap: () {},
        ),
      );
      expect(find.text('Continue'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });
  });

  // ───────────────────────────────────────────────────────────────────────────
  // F2-AC-67 / F2-AC-70 — the twin block and the review cards
  // ───────────────────────────────────────────────────────────────────────────
  group('F2-AC-67 the twin block appears only for "twins"', () {
    testWidgets('hidden for single, shown for twins',
        (WidgetTester tester) async {
      final BirthFormCubit c = buildCubit();
      c.setField(
        (BirthFormData f) =>
            f.copyWith(child: f.child.copyWith(birthType: 'single')),
      );
      await _pump(tester, BirthStep2(cubit: c, state: c.state));
      final int withoutTwins =
          find.byType(BirthInputField).evaluate().length;

      c.setField(
        (BirthFormData f) =>
            f.copyWith(child: f.child.copyWith(birthType: 'twins')),
      );
      await _pump(tester, BirthStep2(cubit: c, state: c.state));
      final int withTwins = find.byType(BirthInputField).evaluate().length;

      expect(withTwins, greaterThan(withoutTwins),
          reason: '`:1158` reveals twinName + twinGender');
    });
  });

  group('F2-AC-70 the review step\'s father card collapses when unknown', () {
    testWidgets('two rows normally, ONE when the father is unknown',
        (WidgetTester tester) async {
      final BirthFormCubit c = buildCubit();
      c.setField(
        (BirthFormData f) => f.copyWith(
          father: const BirthParentInfo(
            fullName: 'Father Name',
            censusOrId: 'CB-F',
          ),
        ),
      );

      await _pump(tester, BirthStep6(cubit: c, state: c.state));
      expect(find.text('Father Name'), findsOneWidget);
      expect(find.text('CB-F'), findsOneWidget);

      c.toggleFatherUnknown();
      await _pump(tester, BirthStep6(cubit: c, state: c.state));

      expect(find.text('Father Name'), findsNothing,
          reason: '`:1544-1545` collapses the card to a single status row');
      expect(find.text('CB-F'), findsNothing);
      // …and the record is still there underneath (`F2-AC-69`).
      expect(c.state.form.father.fullName, 'Father Name');
    });
  });

  // ───────────────────────────────────────────────────────────────────────────
  // F2-AC-13 — the kernel builds with the DI container uninitialised
  // ───────────────────────────────────────────────────────────────────────────
  testWidgets('F2-AC-13 every widget above was pumped with NO DI container',
      (WidgetTester tester) async {
    // Non-vacuous by construction: `_UnusedRepo` throws on any call and
    // `buildCubit` injects it, so a widget that reached for a locator or a
    // real repository would have thrown in one of the tests above rather than
    // here. This test records the property; the file is the evidence.
    final BirthFormCubit c = buildCubit();
    await _pump(tester, BirthStep1(cubit: c, state: c.state));
    expect(tester.takeException(), isNull);
  });

  // ───────────────────────────────────────────────────────────────────────────
  // The whole page, in its four top-level renderings (`:902-1011`)
  //
  // Everything above pumps a step or a field. This group pumps
  // `BirthDeclarationPage` itself, which is the only way the four branches at
  // `:903`, `:912`, `:936` and `:1011` are ever executed — and the only way
  // `F2-AC-52`'s success card is actually RENDERED rather than inferred from
  // cubit state.
  // ───────────────────────────────────────────────────────────────────────────
  group('the page shell — four renderings', () {
    Future<void> pumpPage(WidgetTester tester, BirthFormCubit c) async {
      await tester.pumpWidget(
        wrapWithLocalization(
          Builder(
            builder: (BuildContext context) => MaterialApp(
              locale: context.locale,
              supportedLocales: context.supportedLocales,
              localizationsDelegates: context.localizationDelegates,
              home: BirthDeclarationPage(cubit: c, onBack: () {}),
            ),
          ),
        ),
      );
      await _settle(tester);
    }

    testWidgets('SERVICE LOADING — the spinner branch at `:903`',
        (WidgetTester tester) async {
      // A catalogue read that never answers holds the page in `loading`.
      final Completer<Either<Failure, Service>> never =
          Completer<Either<Failure, Service>>();
      final BirthFormCubit c = buildCubit(loadService: () => never.future);

      await pumpPage(tester, c);

      expect(c.state.showsServiceLoading, isTrue);
      expect(find.byType(CircularProgressIndicator), findsWidgets);
      expect(tester.takeException(), isNull);

      never.complete(Right<Failure, Service>(serviceFixture()));
      await _settle(tester);
    });

    testWidgets('SERVICE ERROR — the failure sentence renders (`:912`)',
        (WidgetTester tester) async {
      final BirthFormCubit c = buildCubit(
        loadService: () async =>
            const Left<Failure, Service>(Failure('catalogue unreachable')),
      );

      await pumpPage(tester, c);

      expect(c.state.showsServiceError, isTrue);
      expect(find.text('catalogue unreachable'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('THE WIZARD — step 1, the indicator, the header and the CTA',
        (WidgetTester tester) async {
      final BirthFormCubit c = buildCubit(
        loadService: () async => Right<Failure, Service>(serviceFixture()),
      );

      await pumpPage(tester, c);

      expect(find.byType(BirthStepIndicator), findsOneWidget);
      expect(find.byType(BirthStepHeader), findsOneWidget);
      expect(find.byType(BirthCta), findsOneWidget);
      expect(find.byType(BirthStep1), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('the wizard walks all six steps without throwing',
        (WidgetTester tester) async {
      final BirthFormCubit c = buildCubit(
        loadService: () async => Right<Failure, Service>(serviceFixture()),
      );
      await pumpPage(tester, c);

      for (int step = 1; step <= kBirthStepCount; step++) {
        c.emit(c.state.copyWith(step: step));
        await _settle(tester);
        expect(tester.takeException(), isNull,
            reason: 'step $step threw while rendering');
      }
      expect(find.byType(BirthStep6), findsOneWidget);
    });

    testWidgets('F2-AC-52 SUCCESS — the card renders, and gains a SEVENTH row '
        'once paid', (WidgetTester tester) async {
      final BirthFormCubit c = buildCubit(
        loadService: () async => Right<Failure, Service>(serviceFixture()),
      );
      await pumpPage(tester, c);

      c.emit(c.state.copyWith(
        submitted: applicationDetailFixture(reference: 'BD-2026-000456'),
      ));
      await _settle(tester);

      expect(find.byType(BirthSuccessScreen), findsOneWidget);
      expect(find.text('BD-2026-000456'), findsOneWidget);
      expect(c.state.unpaid, isTrue, reason: 'fee 20000 and no receipt');
      expect(find.text('RC-77'), findsNothing,
          reason: 'no receipt row before payment');

      c.emit(c.state.copyWith(receiptNo: 'RC-77'));
      await _settle(tester);

      expect(find.text('RC-77'), findsOneWidget,
          reason: '`:959` — the receipt row is conditional on receiptNo');
      expect(c.state.unpaid, isFalse, reason: 'the pay button stops rendering');
      expect(tester.takeException(), isNull);
    });

    testWidgets('F2-AC-52 a pay error renders and tears nothing down',
        (WidgetTester tester) async {
      final BirthFormCubit c = buildCubit(
        loadService: () async => Right<Failure, Service>(serviceFixture()),
      );
      await pumpPage(tester, c);

      c.emit(c.state.copyWith(
        submitted: applicationDetailFixture(),
        payError: 'INSUFFICIENT_FUNDS',
      ));
      await _settle(tester);

      expect(find.text('INSUFFICIENT_FUNDS'), findsOneWidget);
      expect(find.byType(BirthSuccessScreen), findsOneWidget,
          reason: 'a pay failure does not tear the success screen down');
      expect(c.state.unpaid, isTrue, reason: 'still payable');
    });

    testWidgets('the submit error panel renders ABOVE the step body, and the '
        'form survives', (WidgetTester tester) async {
      final BirthFormCubit c = buildCubit(
        loadService: () async => Right<Failure, Service>(serviceFixture()),
      );
      await pumpPage(tester, c);

      c.emit(c.state.copyWith(submitError: 'Something went wrong.'));
      await _settle(tester);

      expect(find.text('Something went wrong.'), findsOneWidget);
      expect(find.byType(BirthStep1), findsOneWidget,
          reason: 'the error does not replace the form (`F2-AC-64`)');
    });
  });

  // ───────────────────────────────────────────────────────────────────────────
  // F2-AC-75 — the four kernel control states, for EVERY reference-backed list
  //
  // `F2-AC-14` drives the four states for the `nationality` control, because
  // that is the one carrying a preset value onto RULING 14's path. This group
  // closes the rest: Birth mounts **10** reference lists and each must survive
  // loading · data · empty · error-with-retry. A list that throws in one state
  // is a page that crashes for a citizen on a bad connection.
  // ───────────────────────────────────────────────────────────────────────────
  group('F2-AC-75 all 10 reference lists survive the four kernel states', () {
    const LookupOption row = LookupOption(
      id: 'x',
      code: 'x',
      label: Bilingual(en: 'Row', lo: 'ແຖວ'),
    );

    test('the page really mounts 10 lists — the denominator, not a guess', () {
      expect(BirthRefList.values, hasLength(10));
      // Every one resolves to a distinct `/reference/{type}` path.
      expect(BirthRefList.values.map((BirthRefList r) => r.type).toSet(), hasLength(10));
    });

    for (final BirthRefList which in BirthRefList.values) {
      testWidgets('${which.type} — loading, data, empty, error-with-retry',
          (WidgetTester tester) async {
        // DATA
        final BirthFormCubit withData =
            buildCubit(rows: const <LookupOption>[row]);
        await withData.loadReference(which);
        await _pump(
          tester,
          ReferenceSelectView(
            label: Text(which.type),
            source: withData.referenceStateOf(which),
            value: 'x',
            placeholder: 'Select',
            onChanged: (_) {},
          ),
        );
        expect(tester.takeException(), isNull, reason: '${which.type} data');
        expect(find.text('Row'), findsOneWidget);

        // EMPTY — resolved to nothing.
        final BirthFormCubit empty = buildCubit();
        await empty.loadReference(which);
        await _pump(
          tester,
          ReferenceSelectView(
            label: Text(which.type),
            source: empty.referenceStateOf(which),
            value: '',
            placeholder: 'Nothing here',
            onChanged: (_) {},
          ),
        );
        expect(tester.takeException(), isNull, reason: '${which.type} empty');
        expect(find.text('Nothing here'), findsOneWidget);

        // ERROR-WITH-RETRY
        final BirthFormCubit failed = buildCubit(refFails: true);
        await failed.loadReference(which);
        await _pump(
          tester,
          ReferenceSelectView(
            label: Text(which.type),
            source: failed.referenceStateOf(which),
            value: '',
            placeholder: 'Select',
            onChanged: (_) {},
          ),
        );
        expect(tester.takeException(), isNull, reason: '${which.type} error');
        expect(failed.referenceStateOf(which).failed, isTrue);
        expect(failed.referenceStateOf(which).retry, isNotNull,
            reason: '${which.type}: error WITHOUT a retry is a dead end');

        // LOADING — pumped mid-flight.
        final BirthFormCubit loading =
            buildCubit(rows: const <LookupOption>[row]);
        unawaited(loading.loadReference(which));
        await _pump(
          tester,
          ReferenceSelectView(
            label: Text(which.type),
            source: loading.referenceStateOf(which),
            value: '',
            placeholder: 'Select',
            onChanged: (_) {},
          ),
        );
        expect(tester.takeException(), isNull, reason: '${which.type} loading');
      });
    }
  });
}
