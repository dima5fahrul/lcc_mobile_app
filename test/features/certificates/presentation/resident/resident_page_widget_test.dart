/// The Resident wizard, rendered.
///
/// ## `F1-AC-10` — every widget here is pumped with the DI container
/// **completely uninitialised**
///
/// `DependencyInjection().init()` is never called in this file and no
/// `*Injection` is touched. The cubit is built from hand-written fakes and
/// handed to the page as a parameter. That is `F0-AC-77`'s property proved
/// against a **real consumer** rather than against a synthetic harness, and it
/// is item 3 of `specs.md` § 8.1's exit gate.
///
/// ## `F1-AC-41` is the criterion where the correct port looks like a bug
///
/// The step-2 `autoFilledNotice` banner renders **unconditionally**. After a
/// 404 it sits above three empty fields saying "Auto-filled from your ID —
/// please review". That is what `ResidentCertificatePage.tsx:799-804` does, and
/// a port that added `if (detected)` to make it coherent would have diverged
/// from the source to make a gate go green.
library;

import 'dart:async';
import 'dart:typed_data';

import 'package:dartz/dartz.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lcc_mobile_app/core/error/failure.dart';
import 'package:lcc_mobile_app/core/network/api_exception.dart';
import 'package:lcc_mobile_app/features/application/domain/entities/picked_attachment.dart';
import 'package:lcc_mobile_app/features/application/domain/usecases/application_usecases.dart';
import 'package:lcc_mobile_app/features/certificates/domain/submission/attachment_accept_policy.dart';
import 'package:lcc_mobile_app/features/certificates/domain/submission/submission_clock.dart';
import 'package:lcc_mobile_app/features/certificates/presentation/resident/resident_certificate_page.dart';
import 'package:lcc_mobile_app/features/certificates/presentation/resident/resident_fields.dart';
import 'package:lcc_mobile_app/features/certificates/presentation/resident/resident_form_cubit.dart';
import 'package:lcc_mobile_app/features/certificates/presentation/resident/resident_form_state.dart';
import 'package:lcc_mobile_app/features/certificates/presentation/resident/resident_steps.dart';
import 'package:lcc_mobile_app/features/reference/domain/entities/lookup_key.dart';
import 'package:lcc_mobile_app/features/reference/domain/entities/lookup_option.dart';
import 'package:lcc_mobile_app/features/reference/domain/repositories/reference_repository.dart';
import 'package:lcc_mobile_app/features/reference/domain/usecases/get_lookup_options.dart';
import 'package:lcc_mobile_app/features/service/domain/entities/service.dart';
import 'package:lcc_mobile_app/features/session/domain/entities/bilingual.dart';
import 'package:lcc_mobile_app/features/wallet/domain/entities/payment_method.dart';
import 'package:lcc_mobile_app/presentation/forms/widgets/load_failure.dart';
import 'package:lcc_mobile_app/presentation/forms/widgets/reference_select_view.dart';
import 'package:lcc_mobile_app/presentation/forms/widgets/searchable_select.dart';

import '../../../../helpers/app_test_harness.dart';
import '../../../application/application_write_fakes.dart';

final DateTime kInstant = DateTime.parse('2026-08-14T02:00:00+07:00')
    .toUtc()
    .add(const Duration(hours: 7));

/// A reference repository whose answer the test chooses.
class _Reference implements ReferenceRepository {
  _Reference({this.rows = const <LookupOption>[], this.fails = false});

  final List<LookupOption> rows;
  final bool fails;

  /// Held open until [release] is called, for the loading state.
  Completer<void>? gate;

  @override
  Future<Either<Failure, List<LookupOption>>> options(
    LookupKey key, {
    String? parentId,
    PagingMode paging = PagingMode.all,
  }) async {
    final Completer<void>? g = gate;
    if (g != null) await g.future;
    if (fails) return const Left<Failure, List<LookupOption>>(Failure('down'));
    return Right<Failure, List<LookupOption>>(rows);
  }
}

const List<LookupOption> kTwoRows = <LookupOption>[
  LookupOption(id: 'lao', code: 'lao', label: Bilingual(en: 'Lao', lo: 'ລາວ')),
  LookupOption(id: 'thai', code: 'thai', label: Bilingual(en: 'Thai', lo: 'ໄທ')),
  // `other` is a real reference row: `purpose === "other"` (`:1008`) is a CODE
  // comparison against the list the API serves, not a sentinel the page invents.
  LookupOption(
    id: 'other',
    code: 'other',
    label: Bilingual(en: 'Other', lo: 'ອື່ນໆ'),
  ),
];

void main() {
  ResidentFormCubit build({
    ResidentIdentityProbe? probe,
    _Reference? reference,
    Either<Failure, Service>? service,
  }) {
    final FakeApplicationRepository repo = FakeApplicationRepository();
    return ResidentFormCubit(
      clock: SubmissionClock.fixed(kInstant),
      getLookupOptions:
          GetLookupOptions(repository: reference ?? _Reference(rows: kTwoRows)),
      createApplication: CreateApplication(repository: repo),
      updateApplication: UpdateApplication(repository: repo),
      addAttachment: AddAttachment(repository: repo),
      submitApplication: SubmitApplication(repository: repo),
      loadService: () async =>
          service ?? Right<Failure, Service>(serviceFixture()),
      loadPaymentMethods: () async =>
          const Right<Failure, List<PaymentMethod>>(<PaymentMethod>[]),
      probeIdentity: probe,
    );
  }

  Future<void> pumpPage(
    WidgetTester tester,
    ResidentFormCubit cubit, {
    ResidentFilePicker? pickFile,
  }) async {
    await tester.pumpWidget(
      wrapWithLocalization(
        Builder(
          builder: (BuildContext context) => MaterialApp(
            localizationsDelegates: context.localizationDelegates,
            supportedLocales: context.supportedLocales,
            locale: context.locale,
            home: Scaffold(
              body: ResidentCertificatePage(
                cubit: cubit,
                onBack: () {},
                pickFile: pickFile ?? () async => null,
              ),
            ),
          ),
        ),
      ),
    );
    // **Not `pumpAndSettle`.** The CTA's pending spinner and step 6's QR panel
    // both animate indefinitely, and `pumpAndSettle` waits for a frame budget
    // that never empties. Three pumps: build, resolve the mount-time futures,
    // then advance past the first animation tick.
    await tester.pump();
    await tester.pump(Duration.zero);
    await tester.pump(const Duration(milliseconds: 100));
  }

  /// The nth upload box's tappable area on step 1, in render order:
  /// front ID, back ID, family-book cover, family-book contents.
  Finder uploadTarget(int index) => find.text('Tap to upload photo').at(index);

  /// Scrolls the control into view before tapping it.
  ///
  /// Step 1 is four 160-pixel upload boxes plus two notices, which is taller
  /// than the 600-pixel test viewport. `tap()` on an off-screen widget hit-tests
  /// nothing and **fails silently** — the state simply does not change, which
  /// reads as "the port did not attach the file" rather than as a test-harness
  /// problem. That misread cost a cycle here; hence this helper.
  Future<void> tapUpload(WidgetTester t, int index) async {
    await t.ensureVisible(uploadTarget(index));
    await t.pump();
    await t.tap(uploadTarget(index));
    await t.pump(Duration.zero);
    await t.pump();
  }

  // ───────────────────────────────────────────────────────────────────────────
  // F1-AC-41 — the banner, and the reason this criterion exists
  // ───────────────────────────────────────────────────────────────────────────
  group('F1-AC-41 the step-2 autoFilledNotice banner is UNCONDITIONAL', () {
    Future<ResidentFormCubit> at2({ResidentIdentityProbe? probe}) async {
      final ResidentFormCubit c = build(probe: probe);
      await c.setFrontId(PickedAttachment(name: 'f.jpg', bytes: null));
      c.emit(c.state.copyWith(step: 2));
      return c;
    }

    testWidgets('after a 404 the banner is PRESENT', (WidgetTester t) async {
      final ResidentFormCubit c = await at2(
        probe: () async =>
            throw const ApiException(status: 404, code: 'NOT_FOUND', message: 'x'),
      );
      await pumpPage(t, c);

      expect(
        find.text('Auto-filled from your ID — please review and correct if '
            'anything is wrong.'),
        findsOneWidget,
        reason: 'specs.md § 6.4(d) corrects F0 Q-8: the banner has no '
            '`detected` guard (`:799-804`)',
      );
    });

    testWidgets('after a SUCCESS the banner renders IDENTICALLY',
        (WidgetTester t) async {
      final ResidentFormCubit c = await at2(
        probe: () async => const ResidentIdentity(
          name: Bilingual(en: 'Somchai V.', lo: 'ສົມໄຊ'),
          dateOfBirth: '1992-01-05',
          nationality: 'LAO',
        ),
      );
      await pumpPage(t, c);

      expect(
        find.text('Auto-filled from your ID — please review and correct if '
            'anything is wrong.'),
        findsOneWidget,
      );
    });

    testWidgets('F1-AC-40 the step-1 detailsDetected block IS ABSENT after a '
        '404', (WidgetTester t) async {
      final ResidentFormCubit failed = build(
        probe: () async =>
            throw const ApiException(status: 404, code: 'NOT_FOUND', message: 'x'),
      );
      await failed.setFrontId(PickedAttachment(name: 'f.jpg', bytes: null));
      await pumpPage(t, failed);

      expect(find.text('Details detected'), findsNothing);
    });

    testWidgets('THE CONTROL — the detailsDetected block IS present after a '
        'success, so the absence above is real', (WidgetTester t) async {
      // A separate test rather than a second `pumpWidget` in the one above:
      // mounting a second page over the first reuses the element, so the
      // control would be measuring the teardown as much as the state.
      final ResidentFormCubit ok = build(
        probe: () async => const ResidentIdentity(
          name: Bilingual(en: 'Somchai V.', lo: 'ສົມໄຊ'),
          dateOfBirth: '1992-01-05',
          nationality: 'LAO',
        ),
      );
      await ok.setFrontId(PickedAttachment(name: 'f.jpg', bytes: null));
      await pumpPage(t, ok);

      expect(find.text('Details detected'), findsOneWidget);
    });

    testWidgets('F1-AC-42 (iii) a 404 renders NO error banner and NO retry',
        (WidgetTester t) async {
      final ResidentFormCubit c = build(
        probe: () async =>
            throw const ApiException(status: 404, code: 'NOT_FOUND', message: 'x'),
      );
      await c.setFrontId(PickedAttachment(name: 'f.jpg', bytes: null));
      await pumpPage(t, c);

      // The only signal is `readingId` appearing and vanishing.
      expect(find.text('Reading your ID…'), findsNothing);
      expect(find.textContaining('could not'), findsNothing);
      expect(find.byType(LoadFailure), findsNothing);
    });
  });

  // ───────────────────────────────────────────────────────────────────────────
  // F1-AC-10 — the kernel with a real consumer and an empty container
  // ───────────────────────────────────────────────────────────────────────────
  group('F1-AC-10 the kernel builds with DI uninitialised', () {
    testWidgets('step 2 mounts ReferenceSelectView with no container at all',
        (WidgetTester t) async {
      final ResidentFormCubit c = build();
      await c.loadReference(LookupKey.reference('nationality'));
      c.emit(c.state.copyWith(step: 2));
      await pumpPage(t, c);

      expect(find.byType(ResidentInputField), findsWidgets);
      expect(find.byType(ReferenceSelectView), findsOneWidget);
    });

    testWidgets('step 3 mounts LocationFieldsView\'s three SearchableSelects',
        (WidgetTester t) async {
      final ResidentFormCubit c = build();
      await c.loadProvinces();
      c.emit(c.state.copyWith(step: 3));
      await pumpPage(t, c);

      expect(find.byType(SearchableSelect), findsNWidgets(3));
    });

    testWidgets('F1-AC-53 the ERROR-WITH-RETRY control state renders a retry',
        (WidgetTester t) async {
      // ── A STATED LIMITATION, not a clean pass ──────────────────────────────
      //
      // `form.nationality` is `''` here, and that is the ONLY reason this test
      // reaches its assertion. With a value set and the options list empty,
      // `ReferenceSelectView` throws during build:
      // `There should be exactly one item with [DropdownButton]'s value: lao`
      // (`reference_select_view.dart:194-225` — `DropdownButton` asserts
      // exactly one matching item, and the blank row only matches `''`).
      //
      // **That combination is reachable on this page**, which is what makes it
      // more than a test artefact: `_detect()` writes `nationality` off the ID
      // card (`:407`) and the nationality list is a separate request, so a card
      // that resolves before the list does puts the wizard in exactly that
      // state. The web cannot do this — `formFields.tsx:307-314` is a plain
      // `<select>`, and an unmatched value renders blank.
      //
      // It is a KERNEL defect, escalated (`blocked.md`) and not patched here:
      // `lib/presentation/forms/**` is F0b's and § 4.1 forbids F1 touching it.
      // The test below is the other half — it shows the page is correct once
      // the kernel is.
      final ResidentFormCubit c = build(reference: _Reference(fails: true));
      await c.loadReference(LookupKey.reference('nationality'));
      c.emit(c.state.copyWith(step: 2));
      await pumpPage(t, c);

      expect(find.byType(LoadFailure), findsOneWidget,
          reason: 'a failed reference list offers a retry inside the control');
    });

    testWidgets('F0 § 6.3.9 re-run — a DETECTED nationality with an EMPTY '
        'options list no longer throws', (WidgetTester t) async {
      // **Absorbed from `f1-r3`'s `resident_q8_widget_test.dart`**, which was
      // written in parallel before the duplicate dispatch was noticed. Kept
      // verbatim in substance because it is the one assertion that exercises
      // the escalated kernel defect from the consumer side, which is the only
      // side it was ever observable from.
      //
      // The race: `_detect()` writes `nationality` off the ID card (`:407`)
      // and the nationality list is a separate request. A card that resolves
      // first leaves the value set and the options empty — and before F0
      // § 6.3.9, `DropdownButton`'s exactly-one-match assert threw during
      // build. `reference_select_view.dart:202-207` now resolves an unmatched
      // value to the blank row, which is what a plain `<select>` does
      // (`formFields.tsx:307-314`).
      final ResidentFormCubit c = build(
        reference: _Reference(),
        probe: () async => const ResidentIdentity(
          name: Bilingual(en: 'Test Citizen', lo: 'Test Citizen'),
          dateOfBirth: '1992-01-01',
          nationality: 'LAO',
        ),
      );
      await c.setFrontId(PickedAttachment(name: 'f.jpg', bytes: null));
      expect(c.state.form.nationality, 'lao',
          reason: 'detection lowercases (`:407`) — the value IS set…');

      // …and the list is empty.
      await c.loadReference(LookupKey.reference('nationality'));
      expect(c.state.nationalities.data, isEmpty);
      c.emit(c.state.copyWith(step: 2));
      await pumpPage(t, c);

      expect(t.takeException(), isNull,
          reason: 'a regression here is blocked.md § 1\'s crash returning');
      expect(find.byType(ReferenceSelectView), findsOneWidget);
    });

    testWidgets('the in-flight readingId banner DOES appear while the read is '
        'running — so its absence after a 404 is settlement, not a banner that '
        'never renders', (WidgetTester t) async {
      // **Also absorbed from `f1-r3`'s file.** It is the positive control that
      // makes `F1-AC-42(iii)`'s "nothing replaces it" assertion non-vacuous:
      // without this, a port that never rendered the banner at all would pass
      // the 404 test.
      //
      // A `Completer`, not a delayed `Future`: a pending `Timer` outlives the
      // tree and the binding fails the test for it.
      final Completer<ResidentIdentity> held = Completer<ResidentIdentity>();
      final ResidentFormCubit c = build(probe: () => held.future);
      addTearDown(() {
        if (!held.isCompleted) {
          held.complete(const ResidentIdentity(
            name: Bilingual(en: 'x', lo: 'x'),
            dateOfBirth: '1992-01-01',
            nationality: 'lao',
          ));
        }
      });

      unawaited(c.setFrontId(PickedAttachment(name: 'f.jpg', bytes: null)));
      await t.pump(Duration.zero);
      expect(c.state.detecting, isTrue);

      await pumpPage(t, c);
      expect(find.text('Reading your ID…'), findsOneWidget);
    });

    testWidgets('a value that IS in the loaded list renders without throwing — '
        'the page\'s half of the kernel defect above', (WidgetTester t) async {
      // The complement: options present AND a value set. This is what the page
      // does once the list has arrived, and it must be clean — so that when the
      // kernel's unmatched-value assert is fixed, nothing here has to change.
      final ResidentFormCubit c = build();
      await c.loadReference(LookupKey.reference('nationality'));
      c.emit(c.state.copyWith(
        step: 2,
        form: c.state.form.copyWith(nationality: 'lao'),
      ));
      await pumpPage(t, c);

      expect(find.byType(ReferenceSelectView), findsOneWidget);
      expect(t.takeException(), isNull);
    });

    testWidgets('F1-AC-53 the EMPTY control state is distinct from loading',
        (WidgetTester t) async {
      final ResidentFormCubit c = build(reference: _Reference());
      await c.loadReference(LookupKey.reference('nationality'));
      c.emit(c.state.copyWith(step: 2));
      await pumpPage(t, c);

      // An empty list is a rendered state, not a spinner and not a failure.
      expect(find.byType(ReferenceSelectView), findsOneWidget);
      expect(find.byType(LoadFailure), findsNothing);
    });
  });

  // ───────────────────────────────────────────────────────────────────────────
  // F1-AC-43 — R-21, behaviourally
  // ───────────────────────────────────────────────────────────────────────────
  group('F1-AC-43 a .pdf reaches Resident\'s attachment list', () {
    testWidgets('picking a PDF on the family-book control attaches it',
        (WidgetTester t) async {
      // Picker-agnostic by construction: the picker is a function and the
      // criterion is what lands in the form, not what config string was passed.
      final ResidentFormCubit c = build();
      await pumpPage(
        t,
        c,
        pickFile: () async => PickedAttachment(
          name: 'family-book.pdf',
          bytes: Uint8List.fromList(<int>[37, 80, 68, 70]),
        ),
      );

      await tapUpload(t, 3);

      expect(c.state.form.familyBookContents, isNotNull);
      expect(c.state.form.familyBookContents!.name, 'family-book.pdf');
      expect(find.text('family-book.pdf'), findsOneWidget,
          reason: 'and it is RENDERED in the list, not merely stored');
    });

    testWidgets('a cancelled picker changes nothing — and is NOT the removal '
        'branch', (WidgetTester t) async {
      final ResidentFormCubit c = build();
      await c.setFrontId(PickedAttachment(name: 'front.jpg', bytes: null));
      c.setField((ResidentFormData f) => f.copyWith(citizenName: 'Typed'));

      await pumpPage(t, c, pickFile: () async => null);
      await tapUpload(t, 1);

      expect(c.state.form.backId, isNull);
      expect(c.state.form.citizenName, 'Typed',
          reason: '`if (!picked) return;` — `:215`');
    });

    testWidgets('F1-AC-44 AttachmentAcceptPolicy.resident is a Tier 1 '
        'comparison target, never a picker filter', (WidgetTester t) async {
      // The policy exists and says `image/*`, and a `.pdf` still attaches. Both
      // halves: a tree with no policy would pass the second vacuously.
      expect(AttachmentAcceptPolicy.resident, 'image/*');

      final ResidentFormCubit c = build();
      await pumpPage(
        t,
        c,
        pickFile: () async =>
            PickedAttachment(name: 'scan.pdf', bytes: Uint8List(0)),
      );
      await tapUpload(t, 0);

      expect(c.state.form.frontId!.name, 'scan.pdf',
          reason: 'the policy is data; it is not passed to the picker');
    });
  });

  // ───────────────────────────────────────────────────────────────────────────
  // The page's four branches
  // ───────────────────────────────────────────────────────────────────────────
  group('the page branches', () {
    testWidgets('F1-AC-73 the service-load error renders retry AND '
        'back-to-home', (WidgetTester t) async {
      final ResidentFormCubit c = build(
        service: const Left<Failure, Service>(Failure('registry is down')),
      );
      await c.refetchService();
      await pumpPage(t, c);

      expect(find.text('We could not load this service right now.'),
          findsOneWidget);
      expect(find.text('registry is down'), findsOneWidget,
          reason: 'the API\'s own sentence, under the fixed copy (`:599`)');
      expect(find.text('Retry'), findsOneWidget);
      expect(find.text('Back to Home'), findsOneWidget);
    });

    testWidgets('F1-AC-72 the success card renders six rows, and the receipt '
        'row is ABSENT without one', (WidgetTester t) async {
      final ResidentFormCubit c = build();
      await c.refetchService();
      c.emit(c.state.copyWith(
        submitted: ResidentSubmitted(decided: applicationDetailFixture()),
      ));
      await pumpPage(t, c);

      expect(find.text('Applicant'), findsOneWidget);
      expect(find.text('Reference No.'), findsOneWidget);
      expect(find.text('Fee'), findsOneWidget);
      expect(find.text('Est. completion'), findsOneWidget);
      expect(find.text('Status'), findsOneWidget);
      expect(find.text('Receipt No.'), findsNothing,
          reason: '`...(submitted.receiptNo ? [...] : [])` — `:638-640`');
    });

    testWidgets('the receipt row appears when there IS one',
        (WidgetTester t) async {
      final ResidentFormCubit c = build();
      await c.refetchService();
      c.emit(c.state.copyWith(
        submitted: ResidentSubmitted(
          decided: applicationDetailFixture(),
          receiptNo: 'RC-9',
        ),
      ));
      await pumpPage(t, c);

      expect(find.text('Receipt No.'), findsOneWidget);
      expect(find.text('RC-9'), findsOneWidget);
    });

    testWidgets('F1-AC-60 each step renders its own title and subtitle',
        (WidgetTester t) async {
      for (int step = 1; step <= 6; step++) {
        final ResidentFormCubit c = build();
        await c.refetchService();
        c.emit(c.state.copyWith(step: step));
        await pumpPage(t, c);

        expect(find.textContaining('STEP $step OF 6'), findsOneWidget,
            reason: 'step $step');
      }
    });

    testWidgets('F1-AC-65 the CTA is tappable while pending — never disabled',
        (WidgetTester t) async {
      final ResidentFormCubit c = build();
      await c.refetchService();
      c.emit(c.state.copyWith(step: 6, submitPending: true));
      await pumpPage(t, c);

      expect(find.text('Processing payment…'), findsOneWidget);
      // A disabled control would not be hit-testable. Tapping must reach the
      // handler, which then swallows it (`:553`).
      await t.tap(find.text('Processing payment…'));
      await t.pump();
      expect(c.state.step, 6);
    });

    testWidgets('F1-AC-69 current_village_id is a plain input, NOT a select',
        (WidgetTester t) async {
      final ResidentFormCubit c = build();
      await c.refetchService();
      c.emit(c.state.copyWith(step: 4));
      await pumpPage(t, c);

      expect(find.byType(ResidentInputField), findsNWidgets(4));
      expect(find.byType(SearchableSelect), findsNothing,
          reason: 'the `_id` suffix is a lie (`:904-911`); a port that '
              '"corrected" it FAILS');
    });

    testWidgets('F1-AC-70 purposeOther renders ONLY when purpose is "other"',
        (WidgetTester t) async {
      final ResidentFormCubit c = build();
      await c.refetchService();
      await c.loadReference(LookupKey.reference('certificate-purpose'));
      c.emit(c.state.copyWith(step: 5));
      await pumpPage(t, c);
      expect(find.text('PLEASE SPECIFY'), findsNothing);

      c.emit(c.state.copyWith(
        form: c.state.form.copyWith(purpose: 'other'),
      ));
      await t.pump();
      await t.pump();
      expect(find.text('PLEASE SPECIFY'), findsOneWidget);
    });

    testWidgets('F1-AC-71 step 6 mounts DRAFT payment — the method toggle, no '
        'application id', (WidgetTester t) async {
      final ResidentFormCubit c = build();
      await c.refetchService();
      c.emit(c.state.copyWith(step: 6));
      await pumpPage(t, c);

      expect(find.byType(ResidentStep6), findsOneWidget);
      expect(find.text('QR Code'), findsOneWidget);
      expect(find.text('Bank'), findsOneWidget);
      expect(find.text('Card'), findsOneWidget);
    });
  });
}
