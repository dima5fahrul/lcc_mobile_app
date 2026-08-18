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
import 'package:lcc_mobile_app/features/certificates/domain/submission/submission_clock.dart';
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
      await documentsInjection.reset();
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
