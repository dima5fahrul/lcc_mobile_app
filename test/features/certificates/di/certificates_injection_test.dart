/// `certificatesInjection` — `F1-AC-14`, and the pay seam's wiring.
///
/// ## Why this file exists at all
///
/// `ResidentFormCubit.pay` is an **optional** constructor parameter. An
/// optional dependency that nobody passes is null, compiles, analyses clean and
/// fails no test — it surfaces the first time a citizen with a fee-bearing case
/// taps Pay and gets no receipt. That is the Capability Rule's exact shape: the
/// wiring is invisible precisely because it is absent.
///
/// So the seam is asserted twice, and the two are different questions:
///
/// * **capability** — the adapter really does turn B6b's `PaymentResult` into
///   something `residentReceiptOf` reads, driven end to end through a real
///   `ResidentFormCubit` submit;
/// * **wiring** — the container really does pass it.
///
/// Either alone passes with the defect present.
library;

import 'package:dartz/dartz.dart';
import 'package:lcc_mobile_app/features/certificates/presentation/birth/birth_form_cubit.dart';
import 'package:lcc_mobile_app/features/certificates/presentation/death/death_form_cubit.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lcc_mobile_app/core/di/dependency_injection.dart';
import 'package:lcc_mobile_app/core/error/failure.dart';
import 'package:lcc_mobile_app/features/account/di/account_injection.dart';
import 'package:lcc_mobile_app/features/application/di/application_injection.dart';
import 'package:lcc_mobile_app/features/application/domain/entities/picked_attachment.dart';
import 'package:lcc_mobile_app/features/application/domain/repositories/application_repository.dart';
import 'package:lcc_mobile_app/features/application/domain/usecases/application_usecases.dart';
import 'package:lcc_mobile_app/features/auth/di/auth_injection.dart';
import 'package:lcc_mobile_app/features/certificates/di/certificates_bloc_injection.dart';
import 'package:lcc_mobile_app/features/certificates/di/certificates_injection.dart';
import 'package:lcc_mobile_app/features/family_book/di/family_book_injection.dart';
import 'package:lcc_mobile_app/features/certificates/domain/submission/submission_clock.dart';
import 'package:lcc_mobile_app/features/certificates/presentation/divorce/divorce_form_cubit.dart';
import 'package:lcc_mobile_app/features/certificates/presentation/marriage/marriage_form_cubit.dart';
import 'package:lcc_mobile_app/features/certificates/presentation/resident/resident_form_cubit.dart';
import 'package:lcc_mobile_app/features/certificates/presentation/resident/resident_form_state.dart';
import 'package:lcc_mobile_app/features/chat/di/chat_injection.dart';
import 'package:lcc_mobile_app/features/documents/di/documents_injection.dart';
import 'package:lcc_mobile_app/features/help/di/help_injection.dart';
import 'package:lcc_mobile_app/features/history/di/history_injection.dart';
import 'package:lcc_mobile_app/features/home/di/home_injection.dart';
import 'package:lcc_mobile_app/features/news/di/news_injection.dart';
import 'package:lcc_mobile_app/features/notifications/di/notifications_injection.dart';
import 'package:lcc_mobile_app/features/reference/di/reference_injection.dart';
import 'package:lcc_mobile_app/features/reference/domain/entities/lookup_key.dart';
import 'package:lcc_mobile_app/features/reference/domain/entities/lookup_option.dart';
import 'package:lcc_mobile_app/features/reference/domain/repositories/reference_repository.dart';
import 'package:lcc_mobile_app/features/reference/domain/usecases/get_lookup_options.dart';
import 'package:lcc_mobile_app/features/service/di/service_injection.dart';
import 'package:lcc_mobile_app/features/session/di/session_injection.dart';
import 'package:lcc_mobile_app/features/verify/di/verify_injection.dart';
import 'package:lcc_mobile_app/features/wallet/di/wallet_injection.dart';
import 'package:lcc_mobile_app/features/wallet/domain/entities/payment_result.dart';
import 'package:lcc_mobile_app/features/wallet/domain/repositories/wallet_repository.dart';
import 'package:lcc_mobile_app/features/wallet/domain/usecases/pay_application.dart';
import 'package:lcc_mobile_app/i18n/i18n.dart';

import '../../application/application_write_fakes.dart';

final DateTime kInstant = DateTime.parse('2026-08-14T02:00:00+07:00')
    .toUtc()
    .add(const Duration(hours: 7));

/// A stand-in for B6b's use case that records what it was asked and answers a
/// [PaymentResult] the test chooses.
class FakePayApplication implements PayApplication {
  FakePayApplication(this.answer);

  final Either<Failure, PaymentResult> answer;
  PayApplicationParams? seen;

  @override
  WalletRepository get repository =>
      throw UnimplementedError('the adapter calls `call`, never `repository`');

  @override
  Future<Either<Failure, PaymentResult>> call(PayApplicationParams params) async {
    seen = params;
    return answer;
  }
}

void main() {
  group('the pay seam is WIRED, not merely accepted', () {
    setUp(() async {
      await const DependencyInjection().init();
    });

    tearDown(() async {
      await injection.reset();
      await sessionInjection.reset();
      await authInjection.reset();
      await serviceInjection.reset();
      await homeInjection.reset();
      await newsInjection.reset();
      await helpInjection.reset();
      await notificationsInjection.reset();
      await chatInjection.reset();
      await accountInjection.reset();
      await referenceInjection.reset();
      await walletInjection.reset();
      await applicationInjection.reset();
      await historyInjection.reset();
      await certificatesInjection.reset();
      await documentsInjection.reset();
      await familyBookInjection.reset();
      // Task 4. `DependencyInjection.init()` now reaches `verifyInjection`
      // too (step 19); this hand-rolled tearDown is the twelfth-documented
      // occurrence of the harness's own blind spot — a container
      // `setUp`'s `init()` populates that nothing here resets makes the
      // *next* test fail with `Type ApiClient is already registered inside
      // GetIt`, which names the wrong culprit.
      await verifyInjection.reset();
      // B5's. **Eleventh** occurrence of the same omission, and the first that
      // `di_teardown_completeness_test.dart` could NOT catch: that guard names
      // three files (`kDiTestFiles`) and this is not one of them, so the
      // failure arrived as `Type ApiClient is already registered inside GetIt`
      // thrown from `DocumentsDatasourceInjection.inject` on this file's second
      // `init()` — exactly the cascade the guard's reason string describes.
      // Recorded as a scope deviation on B9a's, B9b's, B8a's, F0b's, B6a's,
      // B7a's and F1's grounds; FU-8 asks for `kDiTestFiles` to be widened to
      // every file that resets a container, which is discoverable by the same
      // scan the guard already performs.
      // F4's. TENTH occurrence of the same omission, and the first predicted by
      // the container's own doc before it happened
      // (`family_book_injection.dart:16-25`). Added by the meta-orchestrator
      // after F4's implementer was cut off mid-batch: without it,
      // `FamilyBookDatasourceInjection.inject` re-registers `ApiClient` into a
      // container the previous test left populated, and 43 tests fail with
      // `Type ApiClient is already registered inside GetIt`. Recorded scope
      // deviation on the same grounds the nine before it were.
    });

    test('THE DEFECT — the container passes a pay port', () {
      // Red before `certificates_bloc_injection.dart` passes `pay:`, green
      // after, and nothing else in the suite distinguishes the two.
      final ResidentFormCubit cubit =
          certificatesInjection<ResidentFormCubit>(param1: Lang.en);

      expect(
        cubit.pay,
        isNotNull,
        reason: 'B6b publishes `PayApplication` as a cross-batch surface '
            '(`wallet_usecase_injection.dart:36-40`) and F1 owns the call site '
            '(`specs.md` § 6.2). A null port means a fee-bearing submission '
            'silently yields no receipt in production.',
      );
    });

    test('F1-AC-14 the cubit and the four write usecases resolve without '
        'throwing', () {
      expect(
        () => certificatesInjection<ResidentFormCubit>(param1: Lang.en),
        returnsNormally,
      );
      expect(applicationInjection<CreateApplication>(), isA<CreateApplication>());
      expect(applicationInjection<UpdateApplication>(), isA<UpdateApplication>());
      expect(applicationInjection<AddAttachment>(), isA<AddAttachment>());
      expect(applicationInjection<SubmitApplication>(), isA<SubmitApplication>());
      expect(referenceInjection<GetLookupOptions>(), isA<GetLookupOptions>());
    });

    test('F1-AC-14 a second resolve of the repository is the SAME instance', () {
      expect(
        identical(
          applicationInjection<ApplicationRepository>(),
          applicationInjection<ApplicationRepository>(),
        ),
        isTrue,
        reason: 'lazy singleton (DI-2) — the four writes and the two reads '
            'share one datasource and one ApiClient',
      );
    });

    test('the cubit is a FACTORY — two resolves are two submissions', () {
      final ResidentFormCubit a =
          certificatesInjection<ResidentFormCubit>(param1: Lang.en);
      final ResidentFormCubit b =
          certificatesInjection<ResidentFormCubit>(param1: Lang.en);

      expect(identical(a, b), isFalse,
          reason: 'a singleton would hand a citizen the previous citizen\'s '
              'half-filled form and, worse, the previous `draft.id` — so a '
              'second submission would PATCH the first one\'s case');
    });

    test('the language parameter reaches the cubit', () {
      expect(certificatesInjection<ResidentFormCubit>(param1: Lang.lo).lang,
          Lang.lo);
      expect(certificatesInjection<ResidentFormCubit>(param1: Lang.en).lang,
          Lang.en);
    });
  });

  // ───────────────────────────────────────────────────────────────────────────
  // F2-AC-25 — the two new cubits resolve, and `param2` is not optional
  //
  // **This file is F1's and is not in F2's § 3.1 table.** Added here rather
  // than duplicated because the `init()` + fourteen-container `reset()`
  // scaffolding above already exists, and a second copy of it is a second
  // thing to drift. F2 adds **no new container** — `certificatesInjection` is
  // already in that teardown list — so no new `reset()` is required here or in
  // `app_test_harness.dart`. Same shape as the § 3.1 row 9 grant for
  // `test/architecture/**`; recorded in `architecture-review.md` § 3.
  // ───────────────────────────────────────────────────────────────────────────
  group('F2-AC-25 the Birth and Death cubits resolve from the container', () {
    setUp(() async {
      await const DependencyInjection().init();
    });

    tearDown(() async {
      await injection.reset();
      await sessionInjection.reset();
      await authInjection.reset();
      await serviceInjection.reset();
      await homeInjection.reset();
      await newsInjection.reset();
      await helpInjection.reset();
      await notificationsInjection.reset();
      await chatInjection.reset();
      await accountInjection.reset();
      await referenceInjection.reset();
      await walletInjection.reset();
      await applicationInjection.reset();
      await historyInjection.reset();
      await certificatesInjection.reset();
      await documentsInjection.reset();
      await familyBookInjection.reset();
      // Task 4. `DependencyInjection.init()` now reaches `verifyInjection`
      // too (step 19); this hand-rolled tearDown is the twelfth-documented
      // occurrence of the harness's own blind spot — a container
      // `setUp`'s `init()` populates that nothing here resets makes the
      // *next* test fail with `Type ApiClient is already registered inside
      // GetIt`, which names the wrong culprit.
      await verifyInjection.reset();
    });

    BirthFormCubit birth({Lang lang = Lang.en}) =>
        certificatesInjection<BirthFormCubit>(
          param1: lang,
          param2: () => 'birth.legalBasisText',
        );

    DeathFormCubit death({Lang lang = Lang.en}) =>
        certificatesInjection<DeathFormCubit>(
          param1: lang,
          param2: () => 'death.legalBasisText',
        );

    test('both resolve without throwing', () {
      expect(birth, returnsNormally);
      expect(death, returnsNormally);
      expect(birth(), isA<BirthFormCubit>());
      expect(death(), isA<DeathFormCubit>());
    });

    test('both are wired to B6b\'s pay capability', () {
      // The defect F1 shipped for one revision, asserted for F2's two call
      // sites: a null port means a fee-bearing case yields no receipt and
      // nothing fails until a citizen taps Pay.
      expect(birth().pay, isNotNull);
      expect(death().pay, isNotNull);
    });

    test('a second resolve of each repository is the SAME instance', () {
      expect(
        identical(
          applicationInjection<ApplicationRepository>(),
          applicationInjection<ApplicationRepository>(),
        ),
        isTrue,
        reason: 'lazy singleton (DI-2) — both new cubits share the one '
            'datasource and ApiClient the write slice already had',
      );
      expect(
        identical(
          referenceInjection<GetLookupOptions>(),
          referenceInjection<GetLookupOptions>(),
        ),
        isTrue,
      );
    });

    test('each cubit is a FACTORY — two resolves are two submissions', () {
      expect(identical(birth(), birth()), isFalse);
      expect(identical(death(), death()), isFalse);
      // And the two pages do not share an instance with each other or with
      // Resident, which a mis-keyed registration would produce.
      expect(birth().runtimeType, isNot(death().runtimeType));
    });

    test('the language parameter reaches both cubits', () {
      expect(birth(lang: Lang.lo).lang, Lang.lo);
      expect(birth(lang: Lang.en).lang, Lang.en);
      expect(death(lang: Lang.lo).lang, Lang.lo);
      expect(death(lang: Lang.en).lang, Lang.en);
    });

    test('each cubit reads ITS OWN namespace, and the two differ', () {
      // `param2` is the namespace lookup, moved out of DI because G-L8 forbids
      // a bare `.tr()` there. The point of the parameter is that Birth and
      // Death cannot accidentally share one: their English `legalBasisText` is
      // byte-identical and their Lao is not, so a crossed wire is invisible in
      // English on all twenty Tier 0 documents (`F2-AC-36`).
      expect(birth().readLegalBasisText(), 'birth.legalBasisText');
      expect(death().readLegalBasisText(), 'death.legalBasisText');
      expect(birth().readLegalBasisText(),
          isNot(equals(death().readLegalBasisText())));
    });

    test('omitting `param2` fails AT RESOLUTION, not at first use', () {
      // **Stronger than the guard I wrote for it.** `param2` is typed as the
      // non-nullable `String Function()`, so GetIt refuses the resolve itself
      // with an `ArgumentError` — the cubit is never constructed. The
      // `?? _missingBirthLegalBasis` fallback in
      // `certificates_bloc_injection.dart` therefore **cannot be reached
      // through the container**; it guards only a direct constructor call.
      // Recorded accurately rather than described as the DI-path guard,
      // because a reader who believed that would be relying on dead code.
      //
      // Either way the property that matters holds: a caller who forgets the
      // namespace gets a loud failure, never a silent default to the other
      // page's sentence — which in Lao is a different string on all twenty
      // Tier 0 documents (`F2-AC-36`).
      expect(
        () => certificatesInjection<BirthFormCubit>(param1: Lang.en),
        throwsA(isA<ArgumentError>()),
        reason: 'BirthFormCubit resolved without param2',
      );
      expect(
        () => certificatesInjection<DeathFormCubit>(param1: Lang.en),
        throwsA(isA<ArgumentError>()),
        reason: 'DeathFormCubit resolved without param2',
      );
    });
  });

  // ───────────────────────────────────────────────────────────────────────────
  // F3 — the fee seam, which is the same defect shape as the pay seam
  //
  // `MarriageFormCubit.loadQuote` and `DivorceFormCubit.loadQuote` are optional
  // constructor parameters, and for one revision of
  // `certificates_bloc_injection.dart` **both were left null on purpose** while
  // `blocked.md` § 1 waited on a decision. A null quote port compiles,
  // analyses clean, fails no test — and renders a form whose fee card sits at
  // `…` forever and whose pay button reads "0 LAK". Option (b) closed that,
  // and this group is what would be red if it were reopened by accident.
  //
  // The *capability* half — that the adapter turns a catalogue row into a fee,
  // and a missing row into a Failure rather than a zero — is in
  // `certificate_quote_port_test.dart`, which needs no container.
  // ───────────────────────────────────────────────────────────────────────────
  group('F3 the quote seam is WIRED to the service catalogue', () {
    setUp(() async {
      await const DependencyInjection().init();
    });

    tearDown(() async {
      await injection.reset();
      await sessionInjection.reset();
      await authInjection.reset();
      await serviceInjection.reset();
      await homeInjection.reset();
      await newsInjection.reset();
      await helpInjection.reset();
      await notificationsInjection.reset();
      await chatInjection.reset();
      await accountInjection.reset();
      await referenceInjection.reset();
      await walletInjection.reset();
      await applicationInjection.reset();
      await historyInjection.reset();
      await certificatesInjection.reset();
      await documentsInjection.reset();
      await familyBookInjection.reset();
      // Task 4. `DependencyInjection.init()` now reaches `verifyInjection`
      // too (step 19); this hand-rolled tearDown is the twelfth-documented
      // occurrence of the harness's own blind spot — a container
      // `setUp`'s `init()` populates that nothing here resets makes the
      // *next* test fail with `Type ApiClient is already registered inside
      // GetIt`, which names the wrong culprit.
      await verifyInjection.reset();
    });

    MarriageFormCubit marriage({Lang lang = Lang.en}) =>
        certificatesInjection<MarriageFormCubit>(param1: lang);

    DivorceFormCubit divorce({Lang lang = Lang.en}) =>
        certificatesInjection<DivorceFormCubit>(param1: lang);

    test('both resolve with param1 ALONE — `param2` is gone', () {
      // It used to be the caller-supplied `MarriageQuotePort`/`DivorceQuotePort`
      // and was always passed as null. It is `void` now, so the catalogue is
      // the only fee source a resolved cubit can have: there is no longer a
      // parameter through which a varying quote could be injected.
      expect(marriage, returnsNormally);
      expect(divorce, returnsNormally);
      expect(marriage(), isA<MarriageFormCubit>());
      expect(divorce(), isA<DivorceFormCubit>());
    });

    test('THE DEFECT — the container passes a quote port to both', () {
      expect(
        marriage().loadQuote,
        isNotNull,
        reason: 'a null port leaves the review fee card at `…` and the pay '
            'button at 0 LAK, with nothing failing until a citizen reaches '
            'step 6 (blocked.md § 1)',
      );
      expect(divorce().loadQuote, isNotNull);
    });

    test('both are still wired to B6b\'s pay capability', () {
      expect(marriage().pay, isNotNull);
      expect(divorce().pay, isNotNull);
    });

    test('the record picker is wired on both, with its own kind', () {
      expect(marriage().loadRecords, isNotNull);
      expect(marriage().openRecord, isNotNull);
      expect(divorce().loadRecords, isNotNull);
      expect(divorce().openRecord, isNotNull);
    });

    test('each cubit is a FACTORY — two resolves are two submissions', () {
      expect(identical(marriage(), marriage()), isFalse);
      expect(identical(divorce(), divorce()), isFalse);
    });

    test('the language parameter reaches both cubits', () {
      expect(marriage(lang: Lang.lo).lang, Lang.lo);
      expect(marriage(lang: Lang.en).lang, Lang.en);
      expect(divorce(lang: Lang.lo).lang, Lang.lo);
      expect(divorce(lang: Lang.en).lang, Lang.en);
    });
  });

  group('the adapter — capability, with no container involved', () {
    test('it hands B6b\'s PaymentResult back in a shape residentReceiptOf '
        'reads, FLAT field first', () async {
      final FakePayApplication fake = FakePayApplication(
        const Right<Failure, PaymentResult>(
          PaymentResult(receiptNo: 'RC-FLAT'),
        ),
      );

      final Either<Failure, Object?> out =
          await residentPayPortFrom(fake)('case-1', methodCode: 'laoqr');

      expect(fake.seen!.applicationId, 'case-1');
      expect(fake.seen!.methodCode, 'laoqr');
      expect(residentReceiptOf(out.getOrElse(() => null)), 'RC-FLAT');
    });

    test('a nested transaction receipt is reached when the flat one is empty',
        () async {
      final FakePayApplication fake = FakePayApplication(
        const Right<Failure, PaymentResult>(
          PaymentResult(
            transaction: PaymentTransaction(receiptNo: 'RC-NESTED'),
          ),
        ),
      );

      final Either<Failure, Object?> out =
          await residentPayPortFrom(fake)('case-1', methodCode: 'bank-transfer');

      expect(residentReceiptOf(out.getOrElse(() => null)), 'RC-NESTED');
    });

    test('a charge failure stays a Left — it is not swallowed into a null '
        'receipt', () async {
      final FakePayApplication fake = FakePayApplication(
        const Left<Failure, PaymentResult>(Failure('INSUFFICIENT_FUNDS')),
      );

      final Either<Failure, Object?> out =
          await residentPayPortFrom(fake)('case-1', methodCode: 'laoqr');

      expect(out.isLeft(), isTrue,
          reason: 'the submit orchestration rethrows a Left, so the citizen '
              'sees the API\'s sentence rather than a silent no-receipt');
    });
  });

  group('end to end through a real submit — the capability, not the wiring',
      () {
    late FakeApplicationRepository repo;

    ResidentFormCubit cubitWith(ResidentPayPort? pay) {
      repo = FakeApplicationRepository();
      final ResidentFormCubit c = ResidentFormCubit(
        clock: SubmissionClock.fixed(kInstant),
        getLookupOptions: GetLookupOptions(repository: _NoReference()),
        createApplication: CreateApplication(repository: repo),
        updateApplication: UpdateApplication(repository: repo),
        addAttachment: AddAttachment(repository: repo),
        submitApplication: SubmitApplication(repository: repo),
        loadService: () async => throw UnimplementedError(),
        loadPaymentMethods: () async => throw UnimplementedError(),
        pay: pay,
      );
      c.emit(c.state.copyWith(step: 6, form: _submittableForm()));
      return c;
    }

    test('WITH the adapter, a fee-bearing submit produces a receipt', () async {
      final FakePayApplication fake = FakePayApplication(
        const Right<Failure, PaymentResult>(
          PaymentResult(receiptNo: 'RC-END-TO-END'),
        ),
      );
      final ResidentFormCubit c = cubitWith(residentPayPortFrom(fake));

      await c.next();

      expect(c.state.submitted!.receiptNo, 'RC-END-TO-END');
      expect(fake.seen!.methodCode, 'laoqr',
          reason: 'blankPayment is qr and no live rows were loaded, so '
              '`methodCodeFor` takes its per-branch fallback');
    });

    test('THE CONTROL — with a NULL port the same submit yields no receipt',
        () async {
      // This is what production does today. It is the failure the wiring test
      // above exists to catch, reproduced here so the two are visibly the same
      // defect seen from two sides.
      final ResidentFormCubit c = cubitWith(null);

      await c.next();

      expect(c.state.submitted, isNotNull, reason: 'the case still submits');
      expect(c.state.submitted!.receiptNo, isNull);
    });
  });
}

/// A reference repository the end-to-end group never reaches — the submit path
/// under test loads no lists.
class _NoReference implements ReferenceRepository {
  @override
  Future<Either<Failure, List<LookupOption>>> options(
    LookupKey key, {
    String? parentId,
    PagingMode paging = PagingMode.all,
  }) async =>
      const Right<Failure, List<LookupOption>>(<LookupOption>[]);
}

/// A form complete enough for `canProceed` at step 6.
ResidentFormData _submittableForm() => ResidentFormData(
      frontId: const PickedAttachment(name: 'a.jpg', bytes: null),
      backId: const PickedAttachment(name: 'b.jpg', bytes: null),
      familyBookCover: const PickedAttachment(name: 'c.jpg', bytes: null),
      familyBookContents: const PickedAttachment(name: 'd.pdf', bytes: null),
      picture: const PickedAttachment(name: 'p.jpg', bytes: null),
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
