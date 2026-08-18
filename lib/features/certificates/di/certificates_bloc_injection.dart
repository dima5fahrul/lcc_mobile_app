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
import '../../reference/domain/usecases/get_prerequisite_records.dart';
import '../../service/di/service_injection.dart';
import '../../service/domain/entities/service.dart';
import '../../service/domain/usecases/get_services.dart';
import '../../wallet/di/wallet_injection.dart';
import '../../wallet/domain/entities/payment_method.dart';
import '../../wallet/domain/entities/payment_result.dart';
import '../../wallet/domain/usecases/pay_application.dart';
import '../../wallet/domain/usecases/wallet_usecases.dart';
import '../domain/submission/submission_clock.dart';
import '../presentation/birth/birth_form_cubit.dart';
import '../presentation/death/death_form_cubit.dart';
import '../../application/domain/entities/picked_attachment.dart';
import '../../reference/domain/entities/lookup_key.dart';
import '../presentation/divorce/divorce_form_cubit.dart';
import '../presentation/marriage/marriage_form_cubit.dart';
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

    // ── F2 ────────────────────────────────────────────────────────────────
    //
    // Two more `registerFactoryParam`s into the SAME container, and **no new
    // DI file** (`specs.md` § 3.1 row 3: "No new DI file if an existing one is
    // the right home"). `certificatesInjection` already exists and already
    // closes over the four prerequisite containers, so
    // `dependency_injection.dart` gains **zero** lines — the outcome § 3.1
    // row 4 predicted and `F2-AC-26` allows.
    //
    // Factories for the same reason the Resident one is: a certificate
    // submission is scoped to one visit to the form, and a singleton would
    // hand a citizen the previous citizen's answers and the previous
    // submission's `draft.id`.
    certificatesInjection
        .registerFactoryParam<BirthFormCubit, Lang, String Function()>(
      (Lang lang, String Function()? readLegalBasisText) => BirthFormCubit(
        clock: SubmissionClock.system(),
        getLookupOptions: referenceInjection<GetLookupOptions>(),
        createApplication: applicationInjection<CreateApplication>(),
        updateApplication: applicationInjection<UpdateApplication>(),
        addAttachment: applicationInjection<AddAttachment>(),
        submitApplication: applicationInjection<SubmitApplication>(),
        loadService: certificateServiceReader(
          serviceInjection<GetServices>(),
          kBirthServiceCodeConstant,
        ),
        loadPaymentMethods: () =>
            walletInjection<GetPaymentMethods>()(NoParams()),
        // **The namespace lookup is the CALLER's, and it is `param2`.**
        //
        // Not resolved here, for two reasons. G-L8 forbids a bare `.tr()` —
        // it must bind to a `BuildContext`, and DI has none — and the
        // allowlist that would exempt one is shrink-only (`B10-AC-11`). And
        // it belongs at the call site anyway: the two pages' English
        // `legalBasisText` is byte-identical and their **Lao is not**
        // (`specs.md` § 2.2 Finding B), so the one place this must not be
        // shared is the one place a reader should see it written down.
        //
        // A closure, not a resolved String: `useT("birth")` is current at
        // submit (`BirthFormCubit.readLegalBasisText`).
        readLegalBasisText: readLegalBasisText ?? _missingBirthLegalBasis,
        pay: birthPayPortFrom(walletInjection<PayApplication>()),
        lang: lang,
      ),
    );

    certificatesInjection
        .registerFactoryParam<DeathFormCubit, Lang, String Function()>(
      (Lang lang, String Function()? readLegalBasisText) => DeathFormCubit(
        clock: SubmissionClock.system(),
        getLookupOptions: referenceInjection<GetLookupOptions>(),
        createApplication: applicationInjection<CreateApplication>(),
        updateApplication: applicationInjection<UpdateApplication>(),
        addAttachment: applicationInjection<AddAttachment>(),
        submitApplication: applicationInjection<SubmitApplication>(),
        loadService: certificateServiceReader(
          serviceInjection<GetServices>(),
          kDeathServiceCodeConstant,
        ),
        loadPaymentMethods: () =>
            walletInjection<GetPaymentMethods>()(NoParams()),
        readLegalBasisText: readLegalBasisText ?? _missingDeathLegalBasis,
        pay: deathPayPortFrom(walletInjection<PayApplication>()),
        lang: lang,
      ),
    );

    // ── F3 ────────────────────────────────────────────────────────────────
    //
    // Two more factories into the SAME container. **No new DI container**, so
    // no new `reset()` site: the "new container -> reset() in all three DI
    // teardowns and the harness mirror" rule fires on a *container*, and
    // `certificatesInjection.reset()` already exists at
    // `app_test_harness.dart:910`. `dependency_injection.dart` gains zero
    // lines (§ 3.1 rows 4 and 9).
    //
    // **F3's cubits take FUNCTIONS where F1's and F2's take usecases.** That
    // is deliberate, not drift: `certificate_forms/` is consumed by two pages
    // and `F3-AC-12` requires every one of its widgets to build with the DI
    // container uninitialised, so the seam is drawn at the cubit's edge and
    // the adapter lives here. It also keeps `AddAttachmentParams` out of
    // `presentation/`.
    certificatesInjection.registerFactoryParam<MarriageFormCubit, Lang, void>(
      (Lang lang, _) => MarriageFormCubit(
        clock: SubmissionClock.system(),
        getLookupOptions: (
          LookupKey key, {
          String? parentId,
          PagingMode paging = PagingMode.all,
        }) =>
            referenceInjection<GetLookupOptions>()(
          key,
          parentId: parentId,
          paging: paging,
        ),
        createApplication: (Map<String, Object?> envelope) =>
            applicationInjection<CreateApplication>()(envelope),
        updateApplication: (String id, Map<String, Object?> envelope) =>
            applicationInjection<UpdateApplication>()(
          UpdateApplicationParams(id: id, envelope: envelope),
        ),
        addAttachment: (
          String id,
          PickedAttachment file, {
          required String slot,
          required String kind,
          required String label,
        }) =>
            applicationInjection<AddAttachment>()(
          AddAttachmentParams(
            id: id,
            file: file,
            slot: slot,
            kind: kind,
            label: label,
          ),
        ),
        submitApplication: (String id) =>
            applicationInjection<SubmitApplication>()(id),
        // **The fee, WIRED to the service catalogue** — `blocked.md` § 1
        // option (b), approved 2026-08-18. `param2` is gone: it used to carry
        // a caller-supplied `MarriageQuotePort` and was left null, which
        // rendered no fee at all. It is `void` now, so the catalogue is the
        // only source a resolved cubit can have.
        //
        // This is **not** a like-for-like substitution and
        // `marriageQuotePortFrom`'s own doc is where that is written down.
        loadQuote: marriageQuotePortFrom(serviceInjection<GetServices>()),
        // **The record picker, WIRED** (§ 3.1 row 8). `kind: "betrothal"` —
        // `MarriageCertificatePage.tsx:754`. Divorce sends `"mediation"`; the
        // two kinds are the only difference between the two wirings, and they
        // are supplied here rather than inside the cubit so neither page holds
        // the other's constant.
        loadRecords: (String query) =>
            referenceInjection<GetPrerequisiteRecords>()(
          kind: PrerequisiteRecordKind.betrothal,
          query: query,
        ),
        openRecord: (String recordNo) =>
            referenceInjection<GetPrerequisiteRecord>()(recordNo),
        pay: marriagePayPortFrom(walletInjection<PayApplication>()),
        lang: lang,
      ),
    );

    certificatesInjection.registerFactoryParam<DivorceFormCubit, Lang, void>(
      (Lang lang, _) => DivorceFormCubit(
        clock: SubmissionClock.system(),
        getLookupOptions: (
          LookupKey key, {
          String? parentId,
          PagingMode paging = PagingMode.all,
        }) =>
            referenceInjection<GetLookupOptions>()(
          key,
          parentId: parentId,
          paging: paging,
        ),
        createApplication: (Map<String, Object?> envelope) =>
            applicationInjection<CreateApplication>()(envelope),
        updateApplication: (String id, Map<String, Object?> envelope) =>
            applicationInjection<UpdateApplication>()(
          UpdateApplicationParams(id: id, envelope: envelope),
        ),
        addAttachment: (
          String id,
          PickedAttachment file, {
          required String slot,
          required String kind,
          required String label,
        }) =>
            applicationInjection<AddAttachment>()(
          AddAttachmentParams(
            id: id,
            file: file,
            slot: slot,
            kind: kind,
            label: label,
          ),
        ),
        submitApplication: (String id) =>
            applicationInjection<SubmitApplication>()(id),
        // The `divorce` catalogue row. Same mechanism as Marriage's, without
        // Marriage's cost — see `divorceQuotePortFrom`.
        loadQuote: divorceQuotePortFrom(serviceInjection<GetServices>()),
        // `kind: "mediation"` — `DivorceCertificatePage.tsx:660`.
        loadRecords: (String query) =>
            referenceInjection<GetPrerequisiteRecords>()(
          kind: PrerequisiteRecordKind.mediation,
          query: query,
        ),
        openRecord: (String recordNo) =>
            referenceInjection<GetPrerequisiteRecord>()(recordNo),
        pay: divorcePayPortFrom(walletInjection<PayApplication>()),
        lang: lang,
      ),
    );
  }
}

/// B6b's [PayApplication] as the function [MarriageFormCubit] takes.
///
/// A **separate function** from `residentPayPortFrom` and `birthPayPortFrom`
/// for the reason F2's comment gives: `MarriagePayPort` is a typedef owned by
/// `marriage/`, and sharing one adapter would create an import edge between
/// page directories.
MarriagePayPort marriagePayPortFrom(PayApplication payApplication) {
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

/// The same adapter for `divorce/`. Four lines duplicated rather than one
/// import edge between two page directories.
DivorcePayPort divorcePayPortFrom(PayApplication payApplication) {
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

/// `catalog.quote("marriage", {…})` as **one row of the service catalogue** —
/// `blocked.md` § 1 option (b), approved by the human on 2026-08-18.
///
/// ## An accepted, citizen-visible divergence. Read this before changing it
///
/// `MarriageCertificatePage.tsx:766-774` POSTs `/services/marriage/quote` with
/// `{has_foreign_spouse, creates_betrothal_record}` and re-reads it whenever
/// either input changes: a marriage with a foreign spouse, or one that creates
/// a betrothal record, is quoted **more**. F3 has no in-scope home for that
/// datasource — `features/service/**` is not in § 3.1 and row 8 scopes
/// `features/reference/**` to `/prerequisite-records` — so option (b) reads the
/// fee off the catalogue instead, exactly as [residentServiceReader] does for
/// Resident.
///
/// **Two things that costs the citizen, and neither is hypothetical:**
///
/// 1. **The fee no longer varies.** One number for every form state. The
///    inputs still reach the wire payload (`creates_betrothal_record` is a
///    `form_data` field) — they just no longer move the price on screen.
/// 2. **The number is the bottom of a range.** The recorded `marriage` row is
///    `fee_lak: 100000`, `fee_max_lak: 250000`, `fee_is_range: true`
///    (`docs/fidelity-baseline/2026-08-13/oracle/api/services.json`). The
///    catalogue is *saying* this service's price is not a constant, and this
///    adapter answers the cheapest end of it. `fee_max_lak` is deliberately not
///    surfaced: the review card and `DraftPaymentSection` take one integer
///    amount, and rendering a range where the source renders a resolved price
///    would be a second divergence invented to paper over the first.
///
/// Contrast [divorceQuotePortFrom], where the same mechanism costs nothing.
///
/// **The port takes no parameters** ([MarriageQuotePort]), so this cannot be
/// quietly turned back into a varying fee by editing the adapter alone.
MarriageQuotePort marriageQuotePortFrom(GetServices getServices) {
  final Future<Either<Failure, Service>> Function() readRow =
      certificateServiceReader(getServices, kMarriageServiceCodeConstant);
  return () async {
    final Either<Failure, Service> row = await readRow();
    return row.map<MarriageQuote>(
      (Service s) => MarriageQuote(
        feeLak: s.feeLak,
        // No breakdown exists on a catalogue row. `:776-777` reads
        // `breakdown ?? lines ?? []`, so an empty list is a state the source
        // itself renders — it is not a placeholder, and it is not an excuse to
        // synthesise itemisation the API never sent.
        lines: const <MarriageQuoteLine>[],
      ),
    );
  };
}

/// `catalog.quote("divorce", {})` as one row of the service catalogue.
///
/// The same mechanism as [marriageQuotePortFrom] and **not the same trade**.
/// `DivorceCertificatePage.tsx:667` sends an empty body with an empty
/// dependency array, so the source's own fee is already static and takes no
/// inputs; the recorded `divorce` row is a flat `fee_lak: 10000` with
/// `fee_is_range: false`. A divergence in *mechanism* — one catalogue read
/// instead of one quote POST — with **none in output**, which is the shape F1
/// recorded for [residentServiceReader]. Nothing here is being given up.
DivorceQuotePort divorceQuotePortFrom(GetServices getServices) {
  final Future<Either<Failure, Service>> Function() readRow =
      certificateServiceReader(getServices, kDivorceServiceCodeConstant);
  return () async {
    final Either<Failure, Service> row = await readRow();
    return row.map<DivorceQuote>(
      (Service s) => DivorceQuote(
        feeLak: s.feeLak,
        lines: const <DivorceQuoteLine>[],
      ),
    );
  };
}

/// `service_code` — `MarriageCertificatePage.tsx:958` and
/// `DivorceCertificatePage.tsx:854`.
///
/// Spelled here rather than imported from `CertificateForm.marriage`/`.divorce`
/// for the reason [kResidentServiceCodeConstant] gives: two independent
/// transcriptions of one source line are worth more than the deduplication.
/// `certificate_quote_port_test.dart` asserts the two agree — which is the
/// assertion [kResidentServiceCodeConstant]'s own doc claims exists for it in a
/// `certificates_di_test.dart` that is not in the tree.
const String kMarriageServiceCodeConstant = 'marriage';
const String kDivorceServiceCodeConstant = 'divorce';

/// What a caller that forgot `param2` gets.
///
/// **Throws rather than defaulting to a namespace.** A silent default would
/// pick one of the two pages' sentences, and on the Lao side those differ — so
/// the failure mode of a forgotten parameter would be a wire payload that is
/// correct in English and wrong in Lao, which is precisely the bug § 6.2's
/// RULING 2 exists to make impossible. Loud is the only safe default here.
///
/// **Measured: unreachable through the container.** `param2` is typed
/// non-nullable, so GetIt rejects a resolve that omits it with an
/// `ArgumentError` before the factory body runs
/// (`certificates_injection_test.dart`, `F2-AC-25`). This guards only a
/// **direct constructor call**, which is how the widget tests build cubits.
/// Kept for that path; not the DI-path protection.
Never _missingBirthLegalBasis() => throw StateError(
      'BirthFormCubit was resolved without its `legalBasisText` reader. Pass '
      "param2: () => 'birth.legalBasisText'.tr(context: context) — the BIRTH "
      'namespace. Birth and Death differ in Lao (specs.md § 2.2 Finding B).',
    );

Never _missingDeathLegalBasis() => throw StateError(
      'DeathFormCubit was resolved without its `legalBasisText` reader. Pass '
      "param2: () => 'death.legalBasisText'.tr(context: context) — the DEATH "
      'namespace. Birth and Death differ in Lao (specs.md § 2.2 Finding B).',
    );

/// B6b's [PayApplication] as the function [BirthFormCubit] takes.
///
/// The same adapter shape as [residentPayPortFrom] and a **separate function**,
/// because `BirthPayPort` and `ResidentPayPort` are separate typedefs owned by
/// separate pages (§ 6.2). The duplication is four lines and the alternative is
/// an import edge between two page directories that
/// `certificate_page_isolation_guard_test.dart` forbids.
///
/// **A `Left` stays a `Left`**, so an `INSUFFICIENT_FUNDS` charge surfaces as
/// the API's own sentence in the small red line above the pay button
/// (`BirthDeclarationPage.tsx:979-981`) rather than as a silently absent
/// receipt row.
BirthPayPort birthPayPortFrom(PayApplication payApplication) {
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

/// B6b's [PayApplication] as the function [DeathFormCubit] takes.
DeathPayPort deathPayPortFrom(PayApplication payApplication) {
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

/// One row of the catalogue list, by service code.
///
/// The same recorded divergence [residentServiceReader] documents: the web
/// issues two single-row GETs by code (`catalog.service` / `catalog.pricing`)
/// and the Flutter tree has no `/services/{code}` constant. F2 may not add one
/// (§ 4.1 — `api_endpoint.dart` is out of scope, `F2-AC-88`), so the catalogue
/// list is fetched and the row selected here.
///
/// **Parameterised by code where Resident's is not**, because this one serves
/// two callers with two codes. That is not a shared *page* symbol: it lives in
/// `di/`, below both pages, and the sharing § 6.2 forbids is between
/// `presentation/birth/` and `presentation/death/`.
Future<Either<Failure, Service>> Function() certificateServiceReader(
  GetServices getServices,
  String serviceCode,
) =>
    () async {
      final Either<Failure, List<Service>> result =
          await getServices(GetServicesParams.all);
      return result.fold(
        Left<Failure, Service>.new,
        (List<Service> rows) {
          for (final Service s in rows) {
            if (s.code == serviceCode) return Right<Failure, Service>(s);
          }
          return Left<Failure, Service>(
            Failure('The $serviceCode service is not in the catalogue.'),
          );
        },
      );
    };

/// `SERVICE_CODE` — `BirthDeclarationPage.tsx:51` and
/// `DeathDeclarationPage.tsx:52`.
///
/// Spelled here rather than imported from the two `*_form_state.dart` files for
/// the reason [kResidentServiceCodeConstant] gives: two independent
/// transcriptions of one source line are worth more than the deduplication.
const String kBirthServiceCodeConstant = 'birth';
const String kDeathServiceCodeConstant = 'death';

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
