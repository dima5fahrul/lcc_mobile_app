/// Q-8 as `specs.md` § 6.4 corrects it, discharged on **rendered widgets** —
/// `F1-AC-40`, `F1-AC-41`, `F1-AC-42`; and `F0-AC-77` with a real consumer
/// (`F1-AC-10`).
///
/// ## Why this file exists when the port already carries the comments
///
/// `resident_steps.dart:210-222` states in prose that the step-2 banner is
/// unconditional, and it is right. **A comment is a claim, not evidence.** The
/// property `specs.md` § 6.4 is protecting is that nobody later "fixes" the
/// banner by adding `if (detected)` to make it read coherently — and the only
/// thing that catches that edit is a test that renders the widget after a
/// failed detection and looks for the string. Every assertion below is written
/// so that the tidier, wrong port fails it.
///
/// ## Not one test here calls `DependencyInjection.init()`
///
/// That is `F1-AC-10` / `F0-AC-77`: every kernel widget Resident mounts is
/// pumped with **parameters only**, against a cubit whose collaborators are all
/// injected fakes. A widget that reached for a service locator would throw
/// here. This is the Capability Rule applied — a `grep` for `sl<` proves the
/// source text has no locator read; this proves the widget does not need one.
///
/// ## The 404 is real, not stubbed away
///
/// `ResidentFormCubit.probeIdentity` is nullable and a null probe takes the
/// `catch` branch (`resident_form_cubit.dart:581-582`), which is exactly what
/// `GET /me/digital-id` does today (`F1-NV-2` records the 404 as of
/// 2026-08-13). So "after a 404" below is driven by running the real
/// `_detect()` failure path, not by hand-assembling a state that says
/// `detected: false`.
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
import 'package:lcc_mobile_app/features/certificates/presentation/resident/resident_form_cubit.dart';
import 'package:lcc_mobile_app/features/certificates/presentation/resident/resident_form_state.dart';
import 'package:lcc_mobile_app/features/certificates/presentation/resident/resident_steps.dart';
import 'package:lcc_mobile_app/features/reference/domain/entities/lookup_option.dart';
import 'package:lcc_mobile_app/features/reference/domain/repositories/reference_repository.dart';
import 'package:lcc_mobile_app/features/reference/domain/usecases/get_lookup_options.dart';
import 'package:lcc_mobile_app/features/service/domain/entities/service.dart';
import 'package:lcc_mobile_app/features/session/domain/entities/bilingual.dart';
import 'package:lcc_mobile_app/features/wallet/domain/entities/payment_method.dart';

import '../../../../helpers/app_test_harness.dart';

// ─────────────────────────────────────────────────────────────────────────────
// The strings, read off the assets rather than retyped
// ─────────────────────────────────────────────────────────────────────────────

/// `resident.autoFilledNotice` in `en.json`, verbatim.
///
/// Held as a literal on purpose: if the key is renamed or the sentence is
/// rewritten, this test should fail and be re-measured, not silently follow the
/// asset and keep passing while asserting nothing.
const String kAutoFilled =
    'Auto-filled from your ID — please review and correct if anything is wrong.';
const String kDetailsDetected = 'Details detected';
const String kReadingId = 'Reading your ID…';

/// Neither of these is a collaborator any test below reaches. They exist so the
/// cubit can be constructed with its real required parameters; a call is a bug
/// in the test, and it throws rather than returning a plausible empty value.
class _UnusedApplicationRepository implements ApplicationRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => throw StateError(
        'the Q-8 tests must not reach the write slice — '
        '${invocation.memberName} was called',
      );
}

class _UnusedReferenceRepository implements ReferenceRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => throw StateError(
        'the Q-8 tests must not reach the reference slice — '
        '${invocation.memberName} was called',
      );
}

/// A cubit wired entirely from parameters.
///
/// [probe] null reproduces the 404 (`resident_form_cubit.dart:581`). A non-null
/// probe reproduces a successful read, which is what the second half of
/// `F1-AC-41` compares against.
ResidentFormCubit _cubit({ResidentIdentityProbe? probe}) => ResidentFormCubit(
      clock: SubmissionClock.fixed(DateTime(2026, 8, 14, 2)),
      getLookupOptions:
          GetLookupOptions(repository: _UnusedReferenceRepository()),
      createApplication:
          CreateApplication(repository: _UnusedApplicationRepository()),
      updateApplication:
          UpdateApplication(repository: _UnusedApplicationRepository()),
      addAttachment: AddAttachment(repository: _UnusedApplicationRepository()),
      submitApplication:
          SubmitApplication(repository: _UnusedApplicationRepository()),
      loadService: () async => Left<Failure, Service>(const Failure('unused')),
      loadPaymentMethods: () async =>
          Left<Failure, List<PaymentMethod>>(const Failure('unused')),
      probeIdentity: probe,
    );

/// Pumps one step widget with **no DI container** (`F1-AC-10`).
Future<void> _pumpStep(
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

/// `pumpAndSettle` cannot be used: `EasyLocalization` keeps a frame scheduled
/// and it never returns. Three explicit pumps clear the layout passes these
/// widgets need — the same reasoning, and the same numbers, as
/// `test/presentation/forms/kernel_widgets_test.dart:97`.
Future<void> _settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 200));
  await tester.pump(const Duration(milliseconds: 200));
}

const PickedAttachment _idScan = PickedAttachment(name: 'id.jpg', bytes: null);

/// A **loaded** nationality list — the ordinary case, where the reference list
/// arrived before the citizen reached step 2.
///
/// This fixture once existed to route around a kernel defect F1 found and
/// escalated: `ReferenceSelectView` built a `DropdownButton` whose `value` was
/// `widget.value` while `items` held only the blank row plus `s.options`, so a
/// detected `nationality` of `"lao"` with the list still empty threw
/// `There should be exactly one item with [DropdownButton]'s value: lao`.
///
/// **That is fixed.** `GOR-245-f0-form-kernel/specs.md` § 6.3.9 (RULING 14)
/// resolves the value to the blank row unless exactly one item carries it,
/// matching what `react-dom@18.3.1`'s `updateOptions` does in the source. The
/// unloaded case is now asserted directly by `_nationalitiesEmpty` below, so
/// this fixture is no longer a workaround — it is simply the other half of the
/// pair.
const List<LookupOption> _nationalities = <LookupOption>[
  LookupOption(
    id: 'n1',
    code: 'lao',
    label: Bilingual(en: 'Lao', lo: 'ລາວ'),
  ),
  LookupOption(
    id: 'n2',
    code: 'thai',
    label: Bilingual(en: 'Thai', lo: 'ໄທ'),
  ),
];

/// The view state with that list loaded.
ResidentFormViewState _withNationalities(ResidentFormViewState s) => s.copyWith(
      nationalities:
          const ResidentAsync<List<LookupOption>>(data: _nationalities),
    );

/// The **unloaded** case — the race F1 escalated, now asserted rather than
/// avoided. `data` is absent, so `referenceStateOf` yields zero options while
/// `form.nationality` is already set from the ID card.
ResidentFormViewState _withNationalitiesEmpty(ResidentFormViewState s) =>
    s.copyWith(nationalities: const ResidentAsync<List<LookupOption>>());

void main() {
  group('Q-8 (d) — the step-2 banner is PRESENT, unconditionally (F1-AC-41)',
      () {
    testWidgets('after a 404 it renders, above three empty fields', (
      WidgetTester tester,
    ) async {
      final ResidentFormCubit cubit = _cubit();
      addTearDown(cubit.close);

      // Drive the real failure path: pick a front ID, let `_detect()` run.
      await cubit.setFrontId(_idScan);
      expect(
        cubit.state.detected,
        isFalse,
        reason: 'a null probe must take the catch branch (:581-582)',
      );

      await _pumpStep(
        tester,
        ResidentStep2(cubit: cubit, state: _withNationalities(cubit.state)),
      );

      expect(
        find.text(kAutoFilled),
        findsOneWidget,
        reason: 'specs.md § 6.4(d): `:799-804` sits in the bare `{step === 2 &&` '
            'block at `:784` with no `detected` guard. A port that hides it on '
            'failure FAILS F1-AC-41',
      );
    });

    testWidgets('it renders IDENTICALLY when detection succeeded', (
      WidgetTester tester,
    ) async {
      final ResidentFormCubit cubit = _cubit(
        probe: () async => const ResidentIdentity(
          name: Bilingual(en: 'Test Citizen', lo: 'Test Citizen'),
          dateOfBirth: '1992-01-01',
          nationality: 'LAO',
        ),
      );
      addTearDown(cubit.close);

      await cubit.setFrontId(_idScan);
      expect(
        cubit.state.detected,
        isTrue,
        reason: 'a probe that answers must take the success branch',
      );

      await _pumpStep(
        tester,
        ResidentStep2(cubit: cubit, state: _withNationalities(cubit.state)),
      );

      expect(
        find.text(kAutoFilled),
        findsOneWidget,
        reason: 'same banner, same count, either way — that is what '
            '"unconditionally" means',
      );
    });
  });

  group('the F0c kernel fix, re-run against Resident (F0 § 6.3.9)', () {
    // The architect's RULING 14 has F1 re-run `F1-AC-10` once F0c lands. This
    // is that re-run, driven through Resident's own widget rather than the
    // kernel's harness: the defect was only ever observable through a real
    // consumer, so the confirmation should be too.
    testWidgets('step 2 renders with a DETECTED nationality and an EMPTY '
        'options list — the exact race F1 escalated', (
      WidgetTester tester,
    ) async {
      final ResidentFormCubit cubit = _cubit(
        probe: () async => const ResidentIdentity(
          name: Bilingual(en: 'Test Citizen', lo: 'Test Citizen'),
          dateOfBirth: '1992-01-01',
          nationality: 'LAO',
        ),
      );
      addTearDown(cubit.close);

      await cubit.setFrontId(_idScan);
      expect(
        cubit.state.form.nationality,
        'lao',
        reason: 'detection lowercases (:407) — the value is set…',
      );

      // …and the list has NOT arrived. Before F0 § 6.3.9 this threw.
      await _pumpStep(
        tester,
        ResidentStep2(cubit: cubit, state: _withNationalitiesEmpty(cubit.state)),
      );

      expect(
        tester.takeException(),
        isNull,
        reason: 'F0 § 6.3.9 resolves an unmatched value to the blank row. A '
            'regression here is the crash of blocked.md § 1 returning',
      );
      // And the banner still renders, so the step is genuinely built.
      expect(find.text(kAutoFilled), findsOneWidget);
    });
  });

  group('Q-8 (a) and (c) — empty fields, absent step-1 block (F1-AC-40)', () {
    testWidgets('step 2 renders citizenName, age and nationality EMPTY', (
      WidgetTester tester,
    ) async {
      final ResidentFormCubit cubit = _cubit();
      addTearDown(cubit.close);
      await cubit.setFrontId(_idScan);

      expect(cubit.state.form.citizenName, isEmpty);
      expect(cubit.state.form.age, isEmpty);
      expect(cubit.state.form.nationality, isEmpty);

      await _pumpStep(
        tester,
        ResidentStep2(cubit: cubit, state: _withNationalities(cubit.state)),
      );

      // The demo values DD-1 records in the deployed bundle must not appear.
      expect(find.text('Somchai Vongkhamphanh'), findsNothing);
      expect(find.text('34'), findsNothing);
    });

    testWidgets('the step-1 detection block is ABSENT after a 404', (
      WidgetTester tester,
    ) async {
      final ResidentFormCubit cubit = _cubit();
      addTearDown(cubit.close);
      await cubit.setFrontId(_idScan);

      await _pumpStep(
        tester,
        ResidentStep1(cubit: cubit, state: cubit.state),
      );

      expect(
        find.text(kDetailsDetected),
        findsNothing,
        reason: 'specs.md § 6.4(c): `:747-761` is the guarded block — '
            '`{detected && !detecting && …}` — and it is the one that '
            'disappears. This is the assertion F0 Q-8 was reaching for',
      );
    });

    testWidgets('and it is PRESENT when detection succeeded — so the '
        'absence above is the guard, not a missing widget', (
      WidgetTester tester,
    ) async {
      final ResidentFormCubit cubit = _cubit(
        probe: () async => const ResidentIdentity(
          name: Bilingual(en: 'Test Citizen', lo: 'Test Citizen'),
          dateOfBirth: '1992-01-01',
          nationality: 'LAO',
        ),
      );
      addTearDown(cubit.close);
      await cubit.setFrontId(_idScan);

      await _pumpStep(
        tester,
        ResidentStep1(cubit: cubit, state: cubit.state),
      );

      expect(find.text(kDetailsDetected), findsOneWidget);
    });
  });

  group('Q-8 (b) and Finding C — no clear, no failure signal (F1-AC-42)', () {
    testWidgets(
        'typed values SURVIVE a 404 — there is no clear-on-404 transition', (
      WidgetTester tester,
    ) async {
      final ResidentFormCubit cubit = _cubit();
      addTearDown(cubit.close);

      // The citizen types first…
      cubit.setField(
        (ResidentFormData f) => f.copyWith(citizenName: 'Typed By Hand'),
        path: 'applicant.citizen_name',
      );
      cubit.setAge('41');
      cubit.setField(
        (ResidentFormData f) => f.copyWith(nationality: 'thai'),
        path: 'applicant.nationality',
      );

      // …and only then does the ID read fail.
      await cubit.setFrontId(_idScan);

      expect(
        cubit.state.form.citizenName,
        'Typed By Hand',
        reason: '`:410-412` is `catch { setDetected(false); }` and nothing '
            'more. The clearing at `:418-424` is the file-REMOVAL branch',
      );
      expect(cubit.state.form.age, '41');
      expect(cubit.state.form.nationality, 'thai');

      await _pumpStep(
        tester,
        ResidentStep2(cubit: cubit, state: _withNationalities(cubit.state)),
      );

      expect(find.text('Typed By Hand'), findsOneWidget);
    });

    testWidgets('a 404 renders no error banner, no retry control, no toast', (
      WidgetTester tester,
    ) async {
      final ResidentFormCubit cubit = _cubit();
      addTearDown(cubit.close);
      await cubit.setFrontId(_idScan);

      await _pumpStep(
        tester,
        ResidentStep1(cubit: cubit, state: cubit.state),
      );

      // Finding C: the ONLY signal is `readingId` while in flight, and it has
      // already vanished by the time detection settled.
      expect(find.text(kReadingId), findsNothing);
      expect(find.byType(SnackBar), findsNothing);
      expect(
        find.textContaining('Retry'),
        findsNothing,
        reason: 'specs.md § 6.4: adding a failure message is an automatic '
            'FAIL, not an improvement',
      );
      expect(find.textContaining('could not'), findsNothing);
      expect(find.textContaining('failed'), findsNothing);
    });

    testWidgets('the in-flight banner DOES appear while the read is running — '
        'so the absence above is settlement, not a banner that never renders', (
      WidgetTester tester,
    ) async {
      // A probe held open by a Completer, not a delayed Future: a pending
      // `Timer` outlives the widget tree and `AutomatedTestWidgetsFlutterBinding`
      // fails the test for it. The Completer is resolved in the tear-down below
      // so nothing leaks either way.
      final Completer<ResidentIdentity> held = Completer<ResidentIdentity>();
      final ResidentFormCubit cubit = _cubit(probe: () => held.future);
      addTearDown(() async {
        if (!held.isCompleted) {
          held.complete(
            const ResidentIdentity(
              name: Bilingual(en: 'x', lo: 'x'),
              dateOfBirth: '1992-01-01',
              nationality: 'lao',
            ),
          );
        }
        await cubit.close();
      });

      unawaited(cubit.setFrontId(_idScan));
      await tester.pump(Duration.zero);
      expect(cubit.state.detecting, isTrue);

      await _pumpStep(
        tester,
        ResidentStep1(cubit: cubit, state: cubit.state),
      );

      expect(find.text(kReadingId), findsOneWidget);
    });
  });
}
