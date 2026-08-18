/// Death's widget-level evidence — `F2-AC-55`, `F2-AC-13`, `F2-AC-14`,
/// `F2-AC-62`, `F2-AC-66`, `F2-AC-70`.
///
/// Parallel to `birth_page_widget_test.dart` and asserting Death's own
/// properties where they differ: **two** independent skip toggles that both
/// collapse their review card, and a `causeOther` field with **no length cap**
/// and **no path**.
///
/// No test here calls `DependencyInjection.init()` (`F2-AC-13`).
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
import 'package:lcc_mobile_app/features/certificates/presentation/death/death_certificate_page.dart';
import 'package:lcc_mobile_app/features/certificates/presentation/death/death_fields.dart';
import 'package:lcc_mobile_app/features/certificates/presentation/death/death_form_cubit.dart';
import 'package:lcc_mobile_app/features/certificates/presentation/death/death_form_state.dart';
import 'package:lcc_mobile_app/features/certificates/presentation/death/death_steps.dart';
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

class _UnusedRepo implements ApplicationRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => throw StateError(
        'these widget tests must not reach the write slice — '
        '${invocation.memberName} was called',
      );
}

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

DeathFormCubit buildCubit({
  List<LookupOption> rows = const <LookupOption>[],
  bool refFails = false,
  Future<Either<Failure, Service>> Function()? loadService,
}) =>
    DeathFormCubit(
      clock: SubmissionClock.fixed(kInstant),
      getLookupOptions:
          GetLookupOptions(repository: _RefRepo(rows: rows, fail: refFails)),
      createApplication: CreateApplication(repository: _UnusedRepo()),
      updateApplication: UpdateApplication(repository: _UnusedRepo()),
      addAttachment: AddAttachment(repository: _UnusedRepo()),
      submitApplication: SubmitApplication(repository: _UnusedRepo()),
      // The page calls `load()` in `initState`; pre-emitting a state and
      // pumping is useless because `load()` overwrites it. Control the
      // catalogue instead.
      loadService: loadService ??
          () async => const Left<Failure, Service>(Failure('not used here')),
      loadPaymentMethods: () async =>
          const Right<Failure, List<PaymentMethod>>(<PaymentMethod>[]),
      readLegalBasisText: () => 'DEATH LEGAL BASIS',
    );

void main() {
  // ───────────────────────────────────────────────────────────────────────────
  // F2-AC-55 — R-21 on Death's own upload box
  // ───────────────────────────────────────────────────────────────────────────
  group('F2-AC-55 a .docx and a .pdf both reach the attachment list', () {
    for (final String name in <String>[
      'cause-of-death.docx', // the sharp case
      'medical-note.pdf',
      'scan.png',
      'CERTIFICATE.DOCX',
      'no-extension-at-all',
    ]) {
      testWidgets('$name is accepted', (WidgetTester tester) async {
        PickedAttachment? received;

        await _pump(
          tester,
          DeathUploadBox(
            label: 'Medical note',
            sublabel: 'Photo or scan',
            file: null,
            onChanged: (PickedAttachment? f) => received = f,
            path: 'deceased.death_notice',
            pickFile: () async => PickedAttachment(name: name, bytes: null),
          ),
        );

        await tester.tap(find.byType(GestureDetector).first);
        await _settle(tester);

        expect(received, isNotNull,
            reason: '$name was rejected. `DeathDeclarationPage.tsx:360` is '
                '`accept="image/*,application/pdf"`, which filters a browser '
                'picker\'s view and rejects nothing; `handleFile` (`:347-355`) '
                'inspects neither type nor size.');
        expect(received!.name, name);
      });
    }

    testWidgets('a cancelled pick changes nothing',
        (WidgetTester tester) async {
      bool called = false;
      await _pump(
        tester,
        DeathUploadBox(
          label: 'Medical note',
          sublabel: 'Photo or scan',
          file: null,
          onChanged: (PickedAttachment? f) => called = true,
          pickFile: () async => null,
        ),
      );
      await tester.tap(find.byType(GestureDetector).first);
      await _settle(tester);
      expect(called, isFalse);
    });
  });

  // ───────────────────────────────────────────────────────────────────────────
  // F2-AC-14 — Death's preset controls, four states
  // ───────────────────────────────────────────────────────────────────────────
  group('F2-AC-14 the preset nationality control survives all four states', () {
    const LookupOption laoRow = LookupOption(
      id: 'lao',
      code: 'lao',
      label: Bilingual(en: 'Lao', lo: 'ລາວ'),
    );

    testWidgets('LOADING does not throw', (WidgetTester tester) async {
      final DeathFormCubit c = buildCubit(rows: const <LookupOption>[laoRow]);
      unawaited(c.loadReference(DeathRefList.nationality));

      await _pump(
        tester,
        ReferenceSelectView(
          label: const Text('Nationality'),
          source: c.referenceStateOf(DeathRefList.nationality),
          value: const DeathDeceasedInfo().nationality,
          placeholder: 'Select',
          onChanged: (_) {},
        ),
      );
      expect(tester.takeException(), isNull,
          reason: 'RULING 14 — F0c fixed it; Death is its third consumer');
    });

    testWidgets('EMPTY degrades to the PLACEHOLDER, not an invented row',
        (WidgetTester tester) async {
      final DeathFormCubit c = buildCubit();
      await c.loadReference(DeathRefList.nationality);

      await _pump(
        tester,
        ReferenceSelectView(
          label: const Text('Nationality'),
          source: c.referenceStateOf(DeathRefList.nationality),
          value: 'lao',
          placeholder: 'Select a nationality',
          onChanged: (_) {},
        ),
      );

      expect(tester.takeException(), isNull);
      expect(find.text('Select a nationality'), findsOneWidget);
      expect(find.text('Lao'), findsNothing);
    });

    testWidgets('ERROR-WITH-RETRY exposes a retry', (WidgetTester tester) async {
      final DeathFormCubit c = buildCubit(refFails: true);
      await c.loadReference(DeathRefList.nationality);

      await _pump(
        tester,
        ReferenceSelectView(
          label: const Text('Nationality'),
          source: c.referenceStateOf(DeathRefList.nationality),
          value: 'lao',
          placeholder: 'Select',
          onChanged: (_) {},
        ),
      );
      expect(tester.takeException(), isNull);
      expect(c.referenceStateOf(DeathRefList.nationality).failed, isTrue);
      expect(c.referenceStateOf(DeathRefList.nationality).retry, isNotNull);
    });

    testWidgets('DATA resolves the preset', (WidgetTester tester) async {
      final DeathFormCubit c = buildCubit(rows: const <LookupOption>[laoRow]);
      await c.loadReference(DeathRefList.nationality);

      await _pump(
        tester,
        ReferenceSelectView(
          label: const Text('Nationality'),
          source: c.referenceStateOf(DeathRefList.nationality),
          value: 'lao',
          placeholder: 'Select',
          onChanged: (_) {},
        ),
      );
      expect(tester.takeException(), isNull);
      expect(find.text('Lao'), findsOneWidget);
    });

    test('the preset-carrying controls on this page start at "lao"', () {
      const DeathFormData f = DeathFormData();
      expect(
        <String>[
          f.deceased.nationality,
          f.mother.nationality,
          f.father.nationality,
          f.informant.nationality,
        ],
        <String>['lao', 'lao', 'lao', 'lao'],
      );
      // And the driver-inert constant that no control can change (`F2-AC-44`).
      expect(f.deceased.podCountry, 'Laos');
    });
  });

  // ───────────────────────────────────────────────────────────────────────────
  // F2-AC-62 — causeOther renders conditionally, with no cap and no path
  // ───────────────────────────────────────────────────────────────────────────
  group('F2-AC-62 the causeOther field', () {
    testWidgets('hidden unless the cause is "other"',
        (WidgetTester tester) async {
      final DeathFormCubit c = buildCubit();
      c.setField(
        (DeathFormData f) =>
            f.copyWith(deceased: f.deceased.copyWith(cause: 'illness')),
      );
      await _pump(tester, DeathStep2(cubit: c, state: c.state));
      final int without = find.byType(DeathInputField).evaluate().length;

      c.setField(
        (DeathFormData f) =>
            f.copyWith(deceased: f.deceased.copyWith(cause: 'other')),
      );
      await _pump(tester, DeathStep2(cubit: c, state: c.state));
      final int with_ = find.byType(DeathInputField).evaluate().length;

      expect(with_, without + 1, reason: '`:1245` reveals exactly one field');
    });

    testWidgets('accepts a 500-character value — NO length cap',
        (WidgetTester tester) async {
      // Adding a 100-char cap by analogy with Resident's `purposeOther` FAILS
      // this. `DeathInputField` has no `maxLength` parameter at all.
      final String long = 'x' * 500;
      String? captured;

      await _pump(
        tester,
        DeathInputField(
          label: 'Specify the cause',
          value: '',
          placeholder: 'Specify',
          onChanged: (String v) => captured = v,
          required: true,
          // NO `path:` — the source passes none (`:1246-1252`).
        ),
      );

      await tester.enterText(find.byType(TextField), long);
      await _settle(tester);

      expect(captured, isNotNull);
      expect(captured!.length, 500,
          reason: 'a cap would have truncated it');
    });
  });

  // ───────────────────────────────────────────────────────────────────────────
  // F2-AC-66 — the CTA is never disabled
  // ───────────────────────────────────────────────────────────────────────────
  testWidgets('F2-AC-66 the pending CTA still taps',
      (WidgetTester tester) async {
    int taps = 0;
    await _pump(
      tester,
      DeathCta(
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
    expect(taps, 1, reason: 'never disabled — `fsd.md`:348');
  });

  // ───────────────────────────────────────────────────────────────────────────
  // F2-AC-70 — BOTH parent cards collapse, independently
  // ───────────────────────────────────────────────────────────────────────────
  group('F2-AC-70 both review parent cards collapse, independently', () {
    testWidgets('mother collapses without the father, and vice versa',
        (WidgetTester tester) async {
      final DeathFormCubit c = buildCubit();
      c.setField(
        (DeathFormData f) => f.copyWith(
          mother: const DeathParentInfo(fullName: 'Mother Name'),
          father: const DeathParentInfo(fullName: 'Father Name'),
        ),
      );

      await _pump(tester, DeathStep6(cubit: c, state: c.state));
      expect(find.text('Mother Name'), findsOneWidget);
      expect(find.text('Father Name'), findsOneWidget);

      c.toggleMotherSkip();
      await _pump(tester, DeathStep6(cubit: c, state: c.state));
      expect(find.text('Mother Name'), findsNothing);
      expect(find.text('Father Name'), findsOneWidget,
          reason: 'the two toggles are independent — Birth has only one');

      c.toggleFatherSkip();
      await _pump(tester, DeathStep6(cubit: c, state: c.state));
      expect(find.text('Father Name'), findsNothing);

      // Both records survive (`F2-AC-69`).
      expect(c.state.form.mother.fullName, 'Mother Name');
      expect(c.state.form.father.fullName, 'Father Name');
    });

    testWidgets('rowDateCause shows causeOther when the cause is "other"',
        (WidgetTester tester) async {
      final DeathFormCubit c = buildCubit();
      c.setField(
        (DeathFormData f) => f.copyWith(
          deceased: f.deceased.copyWith(
            dateOfDeath: '2026-07-21',
            cause: 'other',
            causeOther: 'A very specific cause',
          ),
        ),
      );

      await _pump(tester, DeathStep6(cubit: c, state: c.state));

      expect(find.textContaining('A very specific cause'), findsOneWidget,
          reason: '`:1482` — `cause == "other" ? causeOther : labelOf(cause)`');
    });
  });

  // ───────────────────────────────────────────────────────────────────────────
  // F2-AC-58 — Death resolves its step titles by INTERPOLATION
  // ───────────────────────────────────────────────────────────────────────────
  testWidgets('F2-AC-58 the step header interpolates rather than reading a '
      'table', (WidgetTester tester) async {
    // Birth reads `STEP_META`'s per-step keys; Death builds
    // `` t(`step${step}Title`) `` (`:667-668`). Both render a title; only the
    // mechanism differs, and § 6.2 forbids normalising them.
    for (int step = 1; step <= 6; step++) {
      expect(deathStepTitleKey(step), 'step${step}Title');
      expect(deathStepSubtitleKey(step), 'step${step}Subtitle');
    }

    await _pump(tester, const DeathStepHeader(step: 3));
    expect(tester.takeException(), isNull);
    // The step-3 title really resolves out of the appended namespace rather
    // than rendering the raw key — which is what an interpolation typo does.
    expect(find.text('step3Title'), findsNothing);
  });

  testWidgets('F2-AC-13 every widget above was pumped with NO DI container',
      (WidgetTester tester) async {
    final DeathFormCubit c = buildCubit();
    await _pump(tester, DeathStep1(cubit: c, state: c.state));
    expect(tester.takeException(), isNull);
  });

  // ───────────────────────────────────────────────────────────────────────────
  // The whole page, in its four top-level renderings (`:926-1033`)
  // ───────────────────────────────────────────────────────────────────────────
  group('the page shell — four renderings', () {
    Future<void> pumpPage(WidgetTester tester, DeathFormCubit c) async {
      await tester.pumpWidget(
        wrapWithLocalization(
          Builder(
            builder: (BuildContext context) => MaterialApp(
              locale: context.locale,
              supportedLocales: context.supportedLocales,
              localizationsDelegates: context.localizationDelegates,
              home: DeathDeclarationPage(cubit: c, onBack: () {}),
            ),
          ),
        ),
      );
      await _settle(tester);
    }

    testWidgets('SERVICE LOADING — the spinner branch at `:927`',
        (WidgetTester tester) async {
      final Completer<Either<Failure, Service>> never =
          Completer<Either<Failure, Service>>();
      final DeathFormCubit c = buildCubit(loadService: () => never.future);

      await pumpPage(tester, c);

      expect(c.state.showsServiceLoading, isTrue);
      expect(find.byType(CircularProgressIndicator), findsWidgets);
      expect(tester.takeException(), isNull);

      never.complete(Right<Failure, Service>(serviceFixture()));
      await _settle(tester);
    });

    testWidgets('SERVICE ERROR — the failure sentence renders (`:936`)',
        (WidgetTester tester) async {
      final DeathFormCubit c = buildCubit(
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
      final DeathFormCubit c = buildCubit(
        loadService: () async => Right<Failure, Service>(serviceFixture()),
      );
      await pumpPage(tester, c);

      expect(find.byType(DeathStepIndicator), findsOneWidget);
      expect(find.byType(DeathStepHeader), findsOneWidget);
      expect(find.byType(DeathCta), findsOneWidget);
      expect(find.byType(DeathStep1), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('the wizard walks all six steps without throwing',
        (WidgetTester tester) async {
      final DeathFormCubit c = buildCubit(
        loadService: () async => Right<Failure, Service>(serviceFixture()),
      );
      await pumpPage(tester, c);

      for (int step = 1; step <= kDeathStepCount; step++) {
        c.emit(c.state.copyWith(step: step));
        await _settle(tester);
        expect(tester.takeException(), isNull,
            reason: 'step $step threw while rendering');
      }
      expect(find.byType(DeathStep6), findsOneWidget);
    });

    testWidgets('both parent steps render their skip toggle, and hide the '
        'section when set', (WidgetTester tester) async {
      final DeathFormCubit c = buildCubit(
        loadService: () async => Right<Failure, Service>(serviceFixture()),
      );
      await pumpPage(tester, c);

      for (final (int step, void Function() toggle) arm
          in <(int, void Function())>[
        (3, c.toggleMotherSkip),
        (4, c.toggleFatherSkip),
      ]) {
        c.emit(c.state.copyWith(step: arm.$1));
        await _settle(tester);
        expect(find.byType(DeathSkipToggle), findsOneWidget,
            reason: 'step ${arm.$1} carries its OWN toggle — Birth has one, '
                'on step 4 only');
        expect(find.byType(DeathParentSection), findsOneWidget);

        arm.$2();
        await _settle(tester);
        expect(find.byType(DeathParentSection), findsNothing,
            reason: 'step ${arm.$1}: `:618` hides the section when skipped');
        expect(find.byType(DeathSkipToggle), findsOneWidget,
            reason: 'the toggle itself stays, so it can be turned back');

        arm.$2();
        await _settle(tester);
      }
    });

    testWidgets('F2-AC-52 SUCCESS — the card renders and gains a SEVENTH row '
        'once paid', (WidgetTester tester) async {
      final DeathFormCubit c = buildCubit(
        loadService: () async => Right<Failure, Service>(serviceFixture()),
      );
      await pumpPage(tester, c);

      c.emit(c.state.copyWith(
        submitted: applicationDetailFixture(reference: 'DD-2026-000789'),
      ));
      await _settle(tester);

      expect(find.byType(DeathSuccessScreen), findsOneWidget);
      expect(find.text('DD-2026-000789'), findsOneWidget);
      expect(c.state.unpaid, isTrue);
      expect(find.text('RC-88'), findsNothing);

      c.emit(c.state.copyWith(receiptNo: 'RC-88'));
      await _settle(tester);

      expect(find.text('RC-88'), findsOneWidget, reason: '`:983`');
      expect(c.state.unpaid, isFalse);
      expect(tester.takeException(), isNull);
    });

    testWidgets('the submit error panel renders and the form survives',
        (WidgetTester tester) async {
      final DeathFormCubit c = buildCubit(
        loadService: () async => Right<Failure, Service>(serviceFixture()),
      );
      await pumpPage(tester, c);

      c.emit(c.state.copyWith(submitError: 'Something went wrong.'));
      await _settle(tester);

      expect(find.text('Something went wrong.'), findsOneWidget);
      expect(find.byType(DeathStep1), findsOneWidget);
    });
  });

  // ───────────────────────────────────────────────────────────────────────────
  // F2-AC-75 — the four kernel control states, for EVERY reference-backed list
  //
  // `F2-AC-14` drives the four states for the `nationality` control, because
  // that is the one carrying a preset value onto RULING 14's path. This group
  // closes the rest: Death mounts **8** reference lists and each must survive
  // loading · data · empty · error-with-retry. A list that throws in one state
  // is a page that crashes for a citizen on a bad connection.
  // ───────────────────────────────────────────────────────────────────────────
  group('F2-AC-75 all 8 reference lists survive the four kernel states', () {
    const LookupOption row = LookupOption(
      id: 'x',
      code: 'x',
      label: Bilingual(en: 'Row', lo: 'ແຖວ'),
    );

    test('the page really mounts 8 lists — the denominator, not a guess', () {
      expect(DeathRefList.values, hasLength(8));
      // Every one resolves to a distinct `/reference/{type}` path.
      expect(DeathRefList.values.map((DeathRefList r) => r.type).toSet(), hasLength(8));
    });

    for (final DeathRefList which in DeathRefList.values) {
      testWidgets('${which.type} — loading, data, empty, error-with-retry',
          (WidgetTester tester) async {
        // DATA
        final DeathFormCubit withData =
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
        final DeathFormCubit empty = buildCubit();
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
        final DeathFormCubit failed = buildCubit(refFails: true);
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
        final DeathFormCubit loading =
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
