/// The Resident wizard's BLoC registration.
///
/// ## `registerFactoryParam`, not `registerLazySingleton`, and that is the design
///
/// Almost every registration in this tree is a lazy singleton (DI-2). This one
/// is not, for the reason `AuthFeatureInjection` keeps `registerFactory<AuthBloc>`:
/// a certificate submission is scoped to **one visit to the form**.
/// [ResidentFormCubit] holds a half-filled `form_data`, a step index, a created
/// draft case, and an `uploaded` slot set the source declares as a `useRef` and
/// explicitly does not persist (`ResidentCertificatePage.tsx:457`, `specs.md`
/// § 6.3 item 3). A singleton would hand a citizen the previous citizen's
/// answers and — worse — the previous submission's `draft.id`, so a second
/// submission would `PATCH` the first one's case.
///
/// ## It closes over four other containers
///
/// `applicationInjection` (the four writes), `referenceInjection`
/// (`GetLookupOptions`), `serviceInjection` (the catalogue) and
/// `walletInjection` (`GetPaymentMethods` **and `PayApplication`**). That is
/// the `ChatUsecaseInjection` -> `helpInjection` shape, the only sanctioned
/// cross-container form (`ssd.md` § 5.1) — and it is why
/// `CertificatesFeatureInjection` must be registered **after** all four
/// (`dependency_injection.dart`).
///
/// ## One hole is closed; one stays open, visibly
///
/// **[ResidentFormCubit.pay] is WIRED**, through [residentPayPortFrom] against
/// B6b's published `PayApplication`. It was null for one revision of this file
/// and that was a real defect rather than a deferral: an optional dependency
/// nobody passes compiles, analyses clean and fails no test, and surfaces only
/// when a citizen with a fee-bearing case gets no receipt.
/// `certificates_injection_test.dart`'s first test is the assertion that was
/// red until the line below existed.
///
/// **[ResidentFormCubit.probeIdentity] stays null**, and that one is a
/// measured gap rather than an oversight: `DigitalIdCard` carries none of the
/// three fields `me.digitalID()`'s consumers read, and widening it means
/// editing `features/home/**`, which is not in F1's § 3.1. A null probe runs
/// the **measured 404 path** (`F1-NV-2`), which is what the endpoint does
/// today — not a stub.
library;

import 'package:dartz/dartz.dart';

import '../../../core/error/failure.dart';
import '../../../core/usecase/usecase.dart';
import '../../../i18n/i18n.dart';
import '../../application/di/application_injection.dart';
import '../../application/domain/usecases/application_usecases.dart';
import '../../reference/di/reference_injection.dart';
import '../../reference/domain/usecases/get_lookup_options.dart';
import '../../service/di/service_injection.dart';
import '../../service/domain/entities/service.dart';
import '../../service/domain/usecases/get_services.dart';
import '../../wallet/di/wallet_injection.dart';
import '../../wallet/domain/entities/payment_method.dart';
import '../../wallet/domain/entities/payment_result.dart';
import '../../wallet/domain/usecases/pay_application.dart';
import '../../wallet/domain/usecases/wallet_usecases.dart';
import '../domain/submission/submission_clock.dart';
import '../presentation/resident/resident_form_cubit.dart';
import 'certificates_injection.dart';

class CertificatesBlocInjection {
  static void inject() {
    certificatesInjection.registerFactoryParam<ResidentFormCubit, Lang, void>(
      (Lang lang, _) => ResidentFormCubit(
        // ADR-0005: local time, and **one** clock for the whole submission so
        // the three date sites cannot disagree.
        clock: SubmissionClock.system(),
        getLookupOptions: referenceInjection<GetLookupOptions>(),
        createApplication: applicationInjection<CreateApplication>(),
        updateApplication: applicationInjection<UpdateApplication>(),
        addAttachment: applicationInjection<AddAttachment>(),
        submitApplication: applicationInjection<SubmitApplication>(),
        loadService: residentServiceReader(
          serviceInjection<GetServices>(),
        ),
        loadPaymentMethods: () =>
            walletInjection<GetPaymentMethods>()(NoParams()),
        // **The pay seam, closed at the DI boundary** (`specs.md` § 6.2,
        // § 8.3). B6b's `PayApplication` is a published cross-batch surface —
        // `wallet_usecase_injection.dart:36-40` names F1, F2, F3 and B7 as its
        // consumers — and F1 owns the call site. A lambda here, never a second
        // usecase: two implementations of one wire call is the failure mode
        // where the later one looks like it works.
        pay: residentPayPortFrom(walletInjection<PayApplication>()),
        lang: lang,
      ),
    );
  }
}

/// B6b's [PayApplication] as the function [ResidentFormCubit] takes.
///
/// ## Why an adapter and not a shared signature
///
/// The two shapes were designed independently and both are right for their
/// side. B6b takes a [PayApplicationParams] object and answers a
/// `PaymentResult`, because the wallet renders that result in full — the
/// instruction card, the settled flag, the wallet balance. F1's port is
/// `(String, {required String methodCode}) -> Either<Failure, Object?>`,
/// because `ResidentCertificatePage.tsx:536-539` reads **one field** off the
/// answer and the type must not appear in F1's tree (`F1-AC-25`).
///
/// § 8.3 rules the reconciliation: *"Adapt at the DI seam and record it; do
/// **not** fork a second usecase."* This is that adapter, and it is the only
/// place the two vocabularies meet.
///
/// ## Why it answers a Map and not the `PaymentResult`
///
/// `:538` casts the response to
/// `{ receipt_no?: string; transaction?: { receipt_no?: string } }` and `:539`
/// reads `result.receipt_no ?? result.transaction?.receipt_no`. Handing the
/// page a two-key map in the source's own shape keeps
/// [residentReceiptOf]'s precedence — flat first, nested second — expressed
/// once, against the wire's vocabulary rather than against B6b's entity. A
/// certificate page that pattern-matched on `PaymentResult` would be a page
/// that has to change when the wallet's entity does.
///
/// **A `Left` stays a `Left`.** The submit orchestration rethrows it, so an
/// `INSUFFICIENT_FUNDS` charge surfaces as the API's own sentence in the red
/// banner rather than as a silently absent receipt row.
ResidentPayPort residentPayPortFrom(PayApplication payApplication) {
  return (String applicationId, {required String methodCode}) async {
    final Either<Failure, PaymentResult> result = await payApplication(
      PayApplicationParams(
        applicationId: applicationId,
        methodCode: methodCode,
      ),
    );
    return result.map<Object?>(
      (PaymentResult r) => <String, Object?>{
        'receipt_no': r.receiptNo,
        'transaction': <String, Object?>{
          'receipt_no': r.transaction?.receiptNo,
        },
      },
    );
  };
}

/// `catalog.service("resident")` and `catalog.pricing("resident")` —
/// `ResidentCertificatePage.tsx:336-337` — as one read of the catalogue list.
///
/// ## A recorded divergence, not a shortcut
///
/// The web issues **two single-row GETs by service code**. The Flutter tree has
/// no `/services/{code}` constant: `api_endpoint.dart` carries only
/// `services = '/services'` (B2a), and `specs.md` § 3.1 row 5 grants
/// `api_endpoint.dart` for **the four write paths only** — so F1 may not add
/// one. The catalogue list is fetched and the `resident` row selected here.
///
/// **What differs observably:** one request instead of two, and a larger
/// payload. **What does not:** `fee_lak`, `processing_time` and `name` are the
/// same fields off the same row, so `:342`'s three-deep `fee` fallback and
/// `:343`'s `processing_time` resolve identically. It costs no capability and
/// changes no Tier 0 byte; it is reported so a later batch can add the endpoint
/// deliberately rather than discover this by reading DI.
///
/// A catalogue that answers without a `resident` row is a [Failure], not an
/// empty service: the page's error branch (`:593`) is the honest rendering of
/// "the service could not be loaded", and a `Service` with zeroed fields would
/// render a 0 LAK fee as though the API had said so.
Future<Either<Failure, Service>> Function() residentServiceReader(
  GetServices getServices,
) =>
    () async {
      final Either<Failure, List<Service>> result =
          await getServices(GetServicesParams.all);
      return result.fold(
        Left<Failure, Service>.new,
        (List<Service> rows) {
          for (final Service s in rows) {
            if (s.code == kResidentServiceCodeConstant) {
              return Right<Failure, Service>(s);
            }
          }
          return const Left<Failure, Service>(
            Failure('The resident service is not in the catalogue.'),
          );
        },
      );
    };

/// `SERVICE_CODE` — `ResidentCertificatePage.tsx:98`.
///
/// Spelled here rather than imported from `resident_form_state.dart` for the
/// reason that file gives about `CertificateForm.resident.serviceCode`: two
/// independent transcriptions of one source line are worth more than the
/// deduplication, and `certificates_di_test.dart` asserts they agree.
const String kResidentServiceCodeConstant = 'resident';

/// Kept so the analyzer sees the import used and a reader sees the type the
/// payment-methods reader answers.
typedef ResidentPaymentMethods = List<PaymentMethod>;
