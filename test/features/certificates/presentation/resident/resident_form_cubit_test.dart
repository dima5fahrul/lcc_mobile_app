/// `ResidentFormCubit` — the page's whole state machine.
///
/// Every criterion here is behavioural: the cubit is driven and its state read,
/// never its internals inspected. It is constructed with hand-written fakes and
/// **no DI container is initialised anywhere in this file** — which is
/// `F1-AC-10`'s property one layer below the widgets.
///
/// ## The Capability Rule, applied to the two seams
///
/// A test that passes with the pay port absent is evidence about the *branch*,
/// not about paying. So both are asserted: with a fake port the call is made
/// and its receipt read; with no port the case still submits and the receipt is
/// **null** rather than fabricated. Neither is reported as an end-to-end charge
/// (`specs.md` § 6.2).
library;

import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lcc_mobile_app/core/error/failure.dart';
import 'package:lcc_mobile_app/core/network/api_exception.dart';
import 'package:lcc_mobile_app/core/network/envelope.dart';
import 'package:lcc_mobile_app/features/application/domain/application_failures.dart';
import 'package:lcc_mobile_app/features/application/domain/entities/picked_attachment.dart';
import 'package:lcc_mobile_app/features/application/domain/usecases/application_usecases.dart';
import 'package:lcc_mobile_app/features/certificates/domain/submission/submission_clock.dart';
import 'package:lcc_mobile_app/features/certificates/presentation/resident/resident_form_cubit.dart';
import 'package:lcc_mobile_app/features/certificates/presentation/resident/resident_form_state.dart';
import 'package:lcc_mobile_app/features/reference/domain/entities/lookup_option.dart';
import 'package:lcc_mobile_app/features/reference/domain/entities/lookup_key.dart';
import 'package:lcc_mobile_app/features/reference/domain/repositories/reference_repository.dart';
import 'package:lcc_mobile_app/features/reference/domain/usecases/get_lookup_options.dart';
import 'package:lcc_mobile_app/features/service/domain/entities/service.dart';
import 'package:lcc_mobile_app/features/session/domain/entities/bilingual.dart';
import 'package:lcc_mobile_app/features/wallet/domain/entities/payment_method.dart';

import '../../../application/application_write_fakes.dart';

/// The register's instant, as a wall clock — `submission_clock_test.dart:25-26`.
final DateTime kInstant = DateTime.parse('2026-08-14T02:00:00+07:00')
    .toUtc()
    .add(const Duration(hours: 7));

PickedAttachment file(String name) => PickedAttachment(name: name, bytes: null);

/// A form filled enough to submit.
ResidentFormData filledForm() => ResidentFormData(
      frontId: file('front.jpg'),
      backId: file('back.jpg'),
      familyBookCover: file('cover.jpg'),
      familyBookContents: file('contents.pdf'),
      picture: file('photo.jpg'),
      citizenName: 'Somchai',
      age: '34',
      nationality: 'lao',
      province: 'p-1',
      district: 'd-1',
      villageName: 'v-1',
      certifyingJurisdiction: 'Chanthabouly',
      currentVillage: 'Ban Dong',
      houseNo: '12',
      censusBookNo: 'CB-7',
      purpose: 'school',
    );

void main() {
  late FakeApplicationRepository repo;

  ResidentFormCubit build({
    ResidentIdentityProbe? probe,
    ResidentPayPort? pay,
    List<PaymentMethod> methods = const <PaymentMethod>[],
  }) {
    repo = FakeApplicationRepository();
    return ResidentFormCubit(
      clock: SubmissionClock.fixed(kInstant),
      getLookupOptions: GetLookupOptions(repository: FakeReferenceRepository()),
      createApplication: CreateApplication(repository: repo),
      updateApplication: UpdateApplication(repository: repo),
      addAttachment: AddAttachment(repository: repo),
      submitApplication: SubmitApplication(repository: repo),
      loadService: () async => Right<Failure, Service>(serviceFixture()),
      loadPaymentMethods: () async =>
          Right<Failure, List<PaymentMethod>>(methods),
      probeIdentity: probe,
      pay: pay,
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // F1-AC-40 / F1-AC-42 — Q-8 as § 6.4 corrects it
  // ───────────────────────────────────────────────────────────────────────────
  group('Q-8 — what a GET /me/digital-id 404 does, and does not, do', () {
    /// A probe that rejects, which is what `me.digitalID()` does on a 404.
    Future<ResidentIdentity> failing() async =>
        throw const ApiException(status: 404, code: 'NOT_FOUND', message: 'x');

    test('(a) after a 404, citizenName / age / nationality are EMPTY',
        () async {
      final ResidentFormCubit c = build(probe: failing);
      await c.setFrontId(file('front.jpg'));

      expect(c.state.form.citizenName, '');
      expect(c.state.form.age, '');
      expect(c.state.form.nationality, '');
    });

    test('(b) THE EMPTINESS IS THE INITIAL STATE PERSISTING, not a clear — '
        'typed values SURVIVE a 404', () async {
      // This is the assertion that distinguishes "never filled" from "cleared".
      // `:410-412` is `catch { setDetected(false); }` and clears nothing; the
      // blanking at `:418-424` is the FILE-REMOVAL branch. A port that added a
      // clear-on-404 would be indistinguishable at step 2 on a fresh form and
      // distinguishable here (specs.md § 6.4(b), Finding B).
      final ResidentFormCubit c = build(probe: failing);
      c.setField((ResidentFormData f) => f.copyWith(citizenName: 'Typed Name'));
      c.setField((ResidentFormData f) => f.copyWith(age: '41'));
      c.setField((ResidentFormData f) => f.copyWith(nationality: 'thai'));

      await c.setFrontId(file('front.jpg'));

      expect(c.state.form.citizenName, 'Typed Name');
      expect(c.state.form.age, '41');
      expect(c.state.form.nationality, 'thai');
    });

    test('(c) `detected` is FALSE after a 404 — the step-1 detailsDetected '
        'block is absent', () async {
      final ResidentFormCubit c = build(probe: failing);
      await c.setFrontId(file('front.jpg'));

      expect(c.state.detected, isFalse);
      expect(c.state.detecting, isFalse, reason: 'the `finally` at `:413`');
    });

    test('Finding C — a 404 renders NO error: no message, no retry flag, '
        'nothing', () async {
      final ResidentFormCubit c = build(probe: failing);
      await c.setFrontId(file('front.jpg'));

      // `t("readingId")` flashing and vanishing is the only signal a citizen
      // gets. Adding a failure message is an automatic FAIL, not an
      // improvement (specs.md § 6.4).
      expect(c.state.submitError, isNull);
      expect(c.state.serverErrors, isEmpty);
    });

    test('a NULL probe takes the same branch — the measured behaviour of the '
        'endpoint today, not a stub', () async {
      // `F1-NV-2`: `/me/digital-id` was last observed answering 404. With no
      // probe wired the cubit runs the failure path, which is what a citizen
      // sees. It must not set `detected`.
      final ResidentFormCubit c = build();
      await c.setFrontId(file('front.jpg'));

      expect(c.state.detected, isFalse);
      expect(c.state.detecting, isFalse);
      expect(c.state.form.citizenName, '');
      expect(c.state.form.frontId, isNotNull, reason: 'the file still attaches');
    });

    test('THE CONTROL — a SUCCEEDING probe DOES fill the three fields', () {
      // Without this, every assertion above would pass against a cubit whose
      // detection did nothing at all. This is the Capability Rule applied to
      // Q-8: the negative assertions are only evidence if the positive path
      // works.
      // ignore: unused_local_variable
      final ResidentFormCubit c = build(
        probe: () async => ResidentIdentity(
          name: const Bilingual(en: 'Somchai V.', lo: 'ສົມໄຊ'),
          dateOfBirth: '1992-01-05',
          nationality: 'LAO',
        ),
      );
      return expectLater(
        c.setFrontId(file('front.jpg')).then((_) => c.state),
        completion(
          isA<ResidentFormViewState>()
              .having((ResidentFormViewState s) => s.detected, 'detected', true)
              .having((ResidentFormViewState s) => s.form.citizenName, 'name',
                  'Somchai V.')
              .having((ResidentFormViewState s) => s.form.age, 'age', '34')
              // `(card.nationality || prev).toLowerCase()` — `:407`.
              .having((ResidentFormViewState s) => s.form.nationality,
                  'nationality', 'lao'),
        ),
      );
    });

    test('F1-AC-68 an EMPTY card field falls back to the previous value, and '
        'the lowercase wraps the whole fallback', () async {
      final ResidentFormCubit c = build(
        probe: () async => const ResidentIdentity(
          name: Bilingual(en: '', lo: ''),
          dateOfBirth: '',
          nationality: '',
        ),
      );
      c.setField((ResidentFormData f) => f.copyWith(
            citizenName: 'Typed',
            age: '41',
            nationality: 'THAI',
          ));
      await c.setFrontId(file('front.jpg'));

      expect(c.state.form.citizenName, 'Typed');
      expect(c.state.form.age, '41');
      // `(("" ) || "THAI").toLowerCase()` — the lowercase applies to the
      // FALLBACK too (`:407`).
      expect(c.state.form.nationality, 'thai');
    });

    test('REMOVING the front ID is the one path that blanks the three '
        'fields', () async {
      final ResidentFormCubit c = build(
        probe: () async => ResidentIdentity(
          name: const Bilingual(en: 'Somchai V.', lo: 'ສົມໄຊ'),
          dateOfBirth: '1992-01-05',
          nationality: 'LAO',
        ),
      );
      await c.setFrontId(file('front.jpg'));
      expect(c.state.form.citizenName, 'Somchai V.');

      await c.setFrontId(null);

      expect(c.state.form.frontId, isNull);
      expect(c.state.form.citizenName, '');
      expect(c.state.form.age, '');
      expect(c.state.form.nationality, '');
      expect(c.state.detected, isFalse);
      expect(c.state.detecting, isFalse);
    });
  });

  // ───────────────────────────────────────────────────────────────────────────
  // F1-AC-61 — canProceed, all six arms
  // ───────────────────────────────────────────────────────────────────────────
  group('F1-AC-61 canProceed', () {
    ResidentFormCubit at(int step, ResidentFormData form) {
      final ResidentFormCubit c = build();
      c.emit(c.state.copyWith(step: step, form: form));
      return c;
    }

    test('step 1 needs four files AND !detecting — the arm most likely to be '
        'dropped', () async {
      final ResidentFormData four = ResidentFormData(
        frontId: file('a'),
        backId: file('b'),
        familyBookCover: file('c'),
        familyBookContents: file('d'),
      );
      expect(at(1, four).canProceed, isTrue);

      // Same four files, detection in flight.
      final ResidentFormCubit busy = at(1, four);
      busy.emit(busy.state.copyWith(detecting: true));
      expect(busy.canProceed, isFalse,
          reason: '`&& !detecting` — `:432`');

      expect(
        at(1, four.copyWith(clearFamilyBookContents: true)).canProceed,
        isFalse,
      );
    });

    test('step 2 needs name, age, nationality and the photo', () {
      final ResidentFormData ok = ResidentFormData(
        citizenName: 'S',
        age: '34',
        nationality: 'lao',
        picture: file('p'),
      );
      expect(at(2, ok).canProceed, isTrue);
      expect(at(2, ok.copyWith(clearPicture: true)).canProceed, isFalse);
      // Trimmed, unlike `nationality`.
      expect(at(2, ok.copyWith(citizenName: '   ')).canProceed, isFalse);
    });

    test('step 3 needs the header trio and the certifying district — but NOT '
        'the village chief', () {
      const ResidentFormData ok = ResidentFormData(
        province: 'p',
        district: 'd',
        villageName: 'v',
        certifyingJurisdiction: 'c',
      );
      expect(at(3, ok).canProceed, isTrue,
          reason: '`villageChiefName` is blank and step 3 still passes — '
              '`:435-441` does not check it');
      expect(at(3, ok.copyWith(certifyingJurisdiction: '')).canProceed, isFalse);
    });

    test('step 4 needs current village and house no', () {
      const ResidentFormData ok =
          ResidentFormData(currentVillage: 'v', houseNo: '1');
      expect(at(4, ok).canProceed, isTrue);
      expect(at(4, ok.copyWith(houseNo: ' ')).canProceed, isFalse);
    });

    test('step 5 needs the census book and a purpose — and purposeOther ONLY '
        'when the purpose is "other"', () {
      const ResidentFormData ok =
          ResidentFormData(censusBookNo: 'CB', purpose: 'school');
      expect(at(5, ok).canProceed, isTrue);
      expect(at(5, ok.copyWith(purpose: 'other')).canProceed, isFalse);
      expect(
        at(5, ok.copyWith(purpose: 'other', purposeOther: 'x')).canProceed,
        isTrue,
      );
    });

    test('F1-AC-51 step 6 is TRUE on arrival — blankPayment is qr and qr is '
        'always valid', () {
      expect(at(6, const ResidentFormData()).canProceed, isTrue);
    });
  });

  // ───────────────────────────────────────────────────────────────────────────
  // F1-AC-56..59 — the retry semantics
  // ───────────────────────────────────────────────────────────────────────────
  group('F1-AC-56/57/58 the submit orchestration', () {
    ResidentFormCubit ready({
      ResidentPayPort? pay,
      List<PaymentMethod> methods = const <PaymentMethod>[],
    }) {
      final ResidentFormCubit c = build(pay: pay, methods: methods);
      c.emit(c.state.copyWith(step: 6, form: filledForm()));
      return c;
    }

    test('the happy path calls create, update, five attachments, submit — in '
        'that order', () async {
      final ResidentFormCubit c = ready();
      await c.next();

      expect(repo.log.take(2).toList(), <String>['create', 'update']);
      expect(
        repo.log.sublist(2, 7),
        <String>[
          // `attachmentsToSend()`'s FIXED order — the 3x4 photo FIRST, then
          // step 1's four documents (`:485-490`).
          'attach:applicant.photo',
          'attach:applicant.id_front',
          'attach:applicant.id_back',
          'attach:household_reference.family_book_upload',
          'attach:household_reference.family_book_contents',
        ],
      );
      expect(repo.log.last, 'submit');
      expect(c.state.submitted, isNotNull);
    });

    test('F1-AC-56 a retry REUSES the draft — create runs ONCE', () async {
      final ResidentFormCubit c = ready();
      repo.failSubmit = true;
      await c.next();
      expect(c.state.submitted, isNull);

      repo.failSubmit = false;
      repo.log.clear();
      await c.next();

      expect(repo.log, isNot(contains('create')),
          reason: 'a rejected submission must not leave a trail of '
              'half-filled cases (`:503-517`)');
      expect(c.state.submitted, isNotNull);
    });

    test('F1-AC-57 update runs on EVERY attempt, including the first', () async {
      final ResidentFormCubit c = ready();
      repo.failSubmit = true;
      await c.next();
      expect(repo.log, contains('update'));

      repo.failSubmit = false;
      repo.log.clear();
      await c.next();
      expect(repo.log, contains('update'),
          reason: 'the reference only exists once the case does (`:519-524`)');
    });

    test('F1-AC-58 an already-uploaded slot is SKIPPED on retry', () async {
      final ResidentFormCubit c = ready();
      repo.failSubmit = true;
      await c.next();
      expect(c.uploadedSlots.length, 5);

      repo.failSubmit = false;
      repo.log.clear();
      await c.next();

      expect(repo.log.where((String e) => e.startsWith('attach:')), isEmpty,
          reason: '`uploaded.current.has(attachment.slot)` — `:527`');
    });

    test('the update body carries header.ref_no LAST, from the created case',
        () async {
      final ResidentFormCubit c = ready();
      await c.next();

      final Map<String, Object?> formData =
          repo.lastUpdateEnvelope!['form_data']! as Map<String, Object?>;
      expect(formData.keys.last, 'header.ref_no');
      expect(formData['header.ref_no'], 'LCC-2026-000123');
      expect(formData.keys.length, 23);
    });

    test('the create body has form_data LAST and the update body has it '
        'FIRST', () async {
      final ResidentFormCubit c = ready();
      await c.next();

      expect(repo.lastCreateEnvelope!.keys.last, 'form_data');
      expect(repo.lastUpdateEnvelope!.keys.first, 'form_data');
    });
  });

  // ───────────────────────────────────────────────────────────────────────────
  // F1-AC-24 / F1-AC-27 — the pay seam
  // ───────────────────────────────────────────────────────────────────────────
  group('F1-AC-24/27 the pay seam is a hole', () {
    ResidentFormCubit ready({
      ResidentPayPort? pay,
      List<PaymentMethod> methods = const <PaymentMethod>[],
    }) {
      final ResidentFormCubit c = build(pay: pay, methods: methods);
      c.emit(c.state.copyWith(step: 6, form: filledForm()));
      return c;
    }

    test('fee_lak > 0 CALLS the injected port, with the derived method code',
        () async {
      String? seenId;
      String? seenCode;
      final ResidentFormCubit c = ready(
        pay: (String id, {required String methodCode}) async {
          seenId = id;
          seenCode = methodCode;
          return const Right<Failure, Object?>(
            <String, Object?>{'receipt_no': 'RC-9'},
          );
        },
      );
      await c.next();

      expect(seenId, 'case-1');
      // `blankPayment.method` is `qr`, no live rows -> the per-branch fallback.
      expect(seenCode, 'laoqr');
      expect(c.state.submitted!.receiptNo, 'RC-9');
    });

    test('fee_lak == 0 does NOT call pay', () async {
      bool called = false;
      final ResidentFormCubit c = ready(
        pay: (String _, {required String methodCode}) async {
          called = true;
          return const Right<Failure, Object?>(<String, Object?>{});
        },
      );
      repo.submitFeeLak = 0;
      await c.next();

      expect(called, isFalse, reason: '`if (decided.fee_lak > 0)` — `:535`');
      expect(c.state.submitted!.receiptNo, isNull);
    });

    test('with NO port the case still submits and the receipt is NULL — never '
        'a fabricated charge', () async {
      final ResidentFormCubit c = ready();
      await c.next();

      expect(c.state.submitted, isNotNull);
      expect(c.state.submitted!.receiptNo, isNull);
    });

    test('F1-AC-27 the receipt resolves flat, then nested, then null', () {
      expect(
        residentReceiptOf(<String, Object?>{'receipt_no': 'A'}),
        'A',
      );
      expect(
        residentReceiptOf(<String, Object?>{
          'transaction': <String, Object?>{'receipt_no': 'B'},
        }),
        'B',
      );
      expect(
        residentReceiptOf(<String, Object?>{
          'receipt_no': 'A',
          'transaction': <String, Object?>{'receipt_no': 'B'},
        }),
        'A',
        reason: '`result.receipt_no ?? result.transaction?.receipt_no` — the '
            'flat field wins (`:539`)',
      );
      expect(residentReceiptOf(<String, Object?>{}), isNull);
      expect(residentReceiptOf(null), isNull);
    });
  });

  // ───────────────────────────────────────────────────────────────────────────
  // F1-AC-63 / F1-AC-64 / F1-AC-65 — the error paths and the CTA guard
  // ───────────────────────────────────────────────────────────────────────────
  group('F1-AC-63/64/65 submit failure handling', () {
    ResidentFormCubit ready() {
      final ResidentFormCubit c = build();
      c.emit(c.state.copyWith(step: 6, form: filledForm()));
      return c;
    }

    test('F1-AC-63 a 422 naming a step-5 field and a step-2 field lands on '
        'STEP 2', () async {
      final ResidentFormCubit c = ready();
      repo.submitFailure = ApiFailure(
        const ApiException(
          status: 422,
          code: ApiCode.validationError,
          message: 'Some fields are missing.',
          fields: <FieldError>[
            FieldError(field: 'purpose.purpose', message: 'required'),
            FieldError(field: 'applicant.age', message: 'required'),
          ],
        ),
        'Some fields are missing.',
      );

      await c.next();

      expect(c.state.step, 2,
          reason: 'the EARLIEST offending step, not the first named');
      expect(c.state.serverErrors.keys.toSet(),
          <String>{'purpose.purpose', 'applicant.age'});
      expect(c.state.scrollToErrorTick, greaterThan(0));
    });

    test('F1-AC-64 a NON-validation error does not navigate and does not '
        'clear the form', () async {
      final ResidentFormCubit c = ready();
      final int stepBefore = c.state.step;
      repo.submitFailure = ApiFailure(
        const ApiException(
          status: 500,
          code: ApiCode.internalError,
          message: 'Something went wrong.',
        ),
        'Something went wrong.',
      );

      await c.next();

      expect(c.state.step, stepBefore, reason: '`:570-580` has no else branch');
      expect(c.state.serverErrors, isEmpty);
      expect(c.state.form.citizenName, 'Somchai');
      expect(c.state.submitError, 'Something went wrong.');
    });

    test('F1-AC-65 the double-tap guard is in the CUBIT, not on the button',
        () async {
      final ResidentFormCubit c = ready();
      c.emit(c.state.copyWith(submitPending: true));

      await c.next();

      expect(repo.log, isEmpty,
          reason: '`if (submitCase.pending) return;` — `:553`. The CTA stays '
              'tappable and this is what swallows the second tap.');
    });

    test('tapping an incomplete step reveals errors and STAYS PUT', () async {
      final ResidentFormCubit c = build();
      c.emit(c.state.copyWith(step: 2));

      await c.next();

      expect(c.state.showErrors, isTrue);
      expect(c.state.step, 2);
      expect(c.state.scrollToErrorTick, 1);

      // Two failed taps scroll twice — a counter, not a flag.
      await c.next();
      expect(c.state.scrollToErrorTick, 2);
    });

    test('serverErrors are cleared BEFORE the attempt, not after', () async {
      final ResidentFormCubit c = ready();
      c.emit(c.state.copyWith(
        serverErrors: const <String, String>{'applicant.age': 'stale'},
      ));

      await c.next();

      expect(c.state.serverErrors, isEmpty, reason: '`setServerErrors({})` at '
          '`:566` runs before `submitCase.run`');
    });
  });

  // ───────────────────────────────────────────────────────────────────────────
  // Field edits
  // ───────────────────────────────────────────────────────────────────────────
  group('field transforms', () {
    test('F1-AC-67 age strips non-digits and caps at 3', () {
      final ResidentFormCubit c = build();
      c.setAge('a1b2c3d4');
      expect(c.state.form.age, '123');
      c.setAge('7');
      expect(c.state.form.age, '7');
      c.setAge('');
      expect(c.state.form.age, '');
    });

    test('F1-AC-70 purposeOther caps at 100 and carries NO path', () {
      final ResidentFormCubit c = build();
      c.emit(c.state.copyWith(
        serverErrors: const <String, String>{'purpose.purpose_other': 'x'},
      ));
      c.setPurposeOther('y' * 150);

      expect(c.state.form.purposeOther.length, 100);
      expect(c.state.serverErrors.containsKey('purpose.purpose_other'), isTrue,
          reason: 'the control has no `path` (`:1009-1016`), so editing it '
              'clears no server error — a 422 about it can never land on it');
    });

    test('editing a field clears ITS server error and leaves the others', () {
      final ResidentFormCubit c = build();
      c.emit(c.state.copyWith(
        serverErrors: const <String, String>{
          'applicant.age': 'a',
          'applicant.citizen_name': 'b',
        },
      ));
      c.setAge('30');

      expect(c.state.serverErrors.keys, <String>['applicant.citizen_name']);
    });

    test('clearing a path that is not in the map leaves it IDENTICAL', () {
      final ResidentFormCubit c = build();
      const Map<String, String> before = <String, String>{'a': 'b'};
      c.emit(c.state.copyWith(serverErrors: before));
      c.clearServerError('not-there');
      c.clearServerError(null);

      expect(identical(c.state.serverErrors, before), isTrue,
          reason: '`path in prev ? … : prev` — `:383` returns the SAME object');
    });
  });

  // ───────────────────────────────────────────────────────────────────────────
  // Navigation
  // ───────────────────────────────────────────────────────────────────────────
  group('navigation', () {
    test('goBack walks the steps down and reports "leave" only at step 1', () {
      final ResidentFormCubit c = build();
      c.emit(c.state.copyWith(step: 3, showErrors: true));

      expect(c.goBack(), isFalse);
      expect(c.state.step, 2);
      expect(c.state.showErrors, isFalse, reason: '`setShowErrors(false)` — `:545`');

      expect(c.goBack(), isFalse);
      expect(c.state.step, 1);
      expect(c.goBack(), isTrue, reason: 'step 1 back calls onBack()');
    });

    test('F1-AC-60 six steps, and next() advances one at a time', () async {
      final ResidentFormCubit c = build();
      c.emit(c.state.copyWith(form: filledForm()));
      expect(kResidentStepIds, <int>[1, 2, 3, 4, 5, 6]);
      expect(kResidentStepCount, 6);

      for (int expected = 2; expected <= 6; expected++) {
        await c.next();
        expect(c.state.step, expected);
      }
      expect(c.state.isLastStep, isTrue);
    });
  });

  // ───────────────────────────────────────────────────────────────────────────
  // Catalogue
  // ───────────────────────────────────────────────────────────────────────────
  group('the catalogue reads', () {
    test('fee falls back pricing -> service -> 0, in that order', () async {
      final ResidentFormCubit c = build();
      expect(c.state.fee, 0, reason: 'nothing loaded yet');

      await c.refetchService();
      expect(c.state.fee, 20000);
    });

    test('a failed service load surfaces the error branch, and retry clears it',
        () async {
      final ResidentFormCubit c = ResidentFormCubit(
        clock: SubmissionClock.fixed(kInstant),
        getLookupOptions: GetLookupOptions(repository: FakeReferenceRepository()),
        createApplication: CreateApplication(repository: FakeApplicationRepository()),
        updateApplication: UpdateApplication(repository: FakeApplicationRepository()),
        addAttachment: AddAttachment(repository: FakeApplicationRepository()),
        submitApplication: SubmitApplication(repository: FakeApplicationRepository()),
        loadService: () async => const Left<Failure, Service>(Failure('nope')),
        loadPaymentMethods: () async =>
            const Right<Failure, List<PaymentMethod>>(<PaymentMethod>[]),
      );

      await c.refetchService();

      expect(c.state.showsServiceError, isTrue);
      expect(c.state.service.error, 'nope');
    });

    test('referenceStateOf hands the kernel a parameter object, never a '
        'usecase', () async {
      final ResidentFormCubit c = build();
      await c.loadReference(LookupKey.reference('nationality'));

      final dynamic s = c.referenceStateOf(
        c.state.nationalities,
        LookupKey.reference('nationality'),
      );
      expect(s.loading, isFalse);
      expect(s.failed, isFalse);
      expect(s.options, isNotEmpty);
      expect(s.labelOf('lao'), 'Lao');
    });
  });
}

/// A reference repository that answers a fixed two-row list.
class FakeReferenceRepository implements ReferenceRepository {
  @override
  Future<Either<Failure, List<LookupOption>>> options(
    LookupKey key, {
    String? parentId,
    PagingMode paging = PagingMode.all,
  }) async =>
      Right<Failure, List<LookupOption>>(<LookupOption>[
        const LookupOption(
          id: 'lao',
          code: 'lao',
          label: Bilingual(en: 'Lao', lo: 'ລາວ'),
        ),
        const LookupOption(
          id: 'thai',
          code: 'thai',
          label: Bilingual(en: 'Thai', lo: 'ໄທ'),
        ),
      ]);
}
