/// `ResidentCertificatePage.tsx`'s state — every `useState`, `useRef`,
/// `useQuery` and `useMutation` on the page, in one place.
///
/// ## One BLoC for the page (`ssd.md` § 7.4, `F1-AC-16`)
///
/// A [Cubit] rather than a [Bloc]: the source is eleven `useState` calls and
/// four queries, and each of the twenty-odd transitions has exactly one
/// caller. An event class per `set("houseNo", v)` would be twenty-two types
/// carrying no information the method name does not.
///
/// It holds the three things § 7.4 names — the `form_data` map (as
/// [ResidentFormData], which [buildResidentFormData] turns into the map), the
/// step index, and the server field errors — and **the validation scope holds
/// no form values**: `ValidationScope` takes `showErrors` and `serverErrors`
/// and reads each control's value from the widget that owns it.
///
/// ## Two injected holes, and they are not the same kind of hole
///
/// * **[pay] — `specs.md` § 6.2.** B6b owns `PayApplication`, `PaymentResult`
///   and the `/applications/{id}/pay` constant outright; F1 owns the *call
///   site* and reaches the capability through a function it does not
///   implement. Nullable, defaulted null, and F1's own tests supply a fake
///   (`F1-AC-24`). A second pay path in this tree is the failure mode where the
///   later one looks like it works (`F1-AC-25`).
///
/// * **[probeIdentity] — a measured gap, escalated rather than worked around.**
///   `me.digitalID()` (`:402`) reads `card.name`, `card.date_of_birth` and
///   `card.nationality` (`:405-407`). The Flutter port of that endpoint carries
///   **none of the three**: `DigitalIdCard` (`features/home/domain/entities/`)
///   declares `uin`, `cardNo`, `photoUrl`, `verifyCode`, `verifyUrl`,
///   `qrPayload`, and `digitalIdFrom` (`home_wire.dart:189-196`) parses exactly
///   those six out of a wire object that carries all sixteen
///   (`types.ts:370-387`). B2 ported the endpoint for the Home hero, which
///   needs the other six.
///
///   Extending it means editing `features/home/**`, which is **not** one of
///   `specs.md` § 3.1's eleven rows, so F1 does not (`F1-AC-77`, and § 8.3's
///   "do not force a workaround outside scope"). The probe is the seam instead,
///   and **a null probe runs the failure path** — see [_detect] for why that is
///   the faithful reading today rather than a stub.
library;

import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:dartz/dartz.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../i18n/i18n.dart';
import '../../../application/domain/application_failures.dart';
import '../../../session/domain/entities/bilingual.dart';
import '../../../../presentation/forms/validation/step_of_first_error.dart';
import '../../../../presentation/forms/widgets/reference_field_state.dart';
import '../../../../presentation/payment/payment_draft.dart';
import '../../../application/domain/entities/application_detail.dart';
import '../../../application/domain/entities/picked_attachment.dart';
import '../../../application/domain/usecases/application_usecases.dart';
import '../../../reference/domain/entities/lookup_key.dart';
import '../../../reference/domain/entities/lookup_option.dart';
import '../../../reference/domain/usecases/get_lookup_options.dart';
import '../../../service/domain/entities/service.dart';
import '../../../wallet/domain/entities/payment_method.dart';
import '../../domain/submission/submission_clock.dart';
import '../../domain/submission/case_reference_binding.dart';
import 'resident_form_state.dart';
import 'resident_payload.dart';

/// What `me.digitalID()` gives the page, and nothing more.
///
/// Three fields, because the page reads three (`:405-407`). Declared here
/// rather than reused from `features/home/` for the reason the library comment
/// gives: the home entity does not carry them, and widening it is out of scope.
class ResidentIdentity {
  const ResidentIdentity({
    required this.name,
    required this.dateOfBirth,
    required this.nationality,
  });

  /// `card.name` — a `Bilingual`, resolved with `text(card.name, lang)`
  /// (`:405`).
  final Bilingual name;

  /// `card.date_of_birth`, an ISO date. [ageFrom]'s input.
  final String dateOfBirth;

  /// `card.nationality`. **Lowercased on arrival** (`:407`).
  final String nationality;
}

/// The injected read of `GET /me/digital-id`.
///
/// **Throws** on failure, because that is what `me.digitalID()` does — the
/// page's whole handling of it is a bare `catch` (`:410-412`).
typedef ResidentIdentityProbe = Future<ResidentIdentity> Function();

/// B6b's `PayApplication.call` shape, as a function this page can be handed.
///
/// `specs.md` § 6.2 fixes it:
/// `(String applicationId, {required String methodCode}) → Future<Either<Failure, T>>`.
/// `T` is `Object?` here rather than B6b's `PaymentResult`, so that F1's tree
/// contains no reference to a type B6b owns and `F1-AC-25`'s four greps stay
/// empty. The two fields the page reads back are resolved by [residentReceiptOf].
typedef ResidentPayPort = Future<Either<Failure, Object?>> Function(
  String applicationId, {
  required String methodCode,
});

/// `:539` — `result.receipt_no ?? result.transaction?.receipt_no`.
///
/// Reads the pay result structurally rather than through B6b's type, which is
/// what keeps this file free of it. Both shapes and the null case are
/// `F1-AC-27`.
String? residentReceiptOf(Object? result) {
  if (result is! Map) return null;
  final Object? flat = result['receipt_no'];
  if (flat is String && flat.isNotEmpty) return flat;
  final Object? txn = result['transaction'];
  if (txn is Map) {
    final Object? nested = txn['receipt_no'];
    if (nested is String && nested.isNotEmpty) return nested;
  }
  return null;
}

/// `:456` — `useState<{id, reference_no} | null>`.
class ResidentDraftCase {
  const ResidentDraftCase({required this.id, required this.referenceNo});

  final String id;
  final String referenceNo;
}

/// `:329` — `useState<{case, receiptNo} | null>`.
class ResidentSubmitted {
  const ResidentSubmitted({required this.decided, this.receiptNo});

  final ApplicationDetail decided;

  /// Null when the case was free (`fee_lak == 0`) or the pay answer carried no
  /// receipt. The success card's receipt row is absent when it is (`:637-639`).
  final String? receiptNo;
}

/// One `useQuery`'s three observable states.
class ResidentAsync<T> {
  const ResidentAsync({this.data, this.loading = false, this.error});

  const ResidentAsync.loading() : this(loading: true);

  final T? data;
  final bool loading;
  final String? error;
}

/// `LocationFieldsView`'s three levels, before they become [LocationLevel]s.
class ResidentLocationLevel {
  const ResidentLocationLevel({
    this.rows = const <LookupOption>[],
    this.busy = false,
    this.failed = false,
  });

  final List<LookupOption> rows;
  final bool busy;
  final bool failed;
}

/// Every `useState` on the page, plus the four queries.
class ResidentFormViewState {
  const ResidentFormViewState({
    this.step = 1,
    this.showErrors = false,
    this.serverErrors = const <String, String>{},
    this.submitted,
    this.detecting = false,
    this.detected = false,
    this.form = const ResidentFormData(),
    this.draft,
    this.service = const ResidentAsync<Service>.loading(),
    this.pricing = const ResidentAsync<int>.loading(),
    this.methods = const ResidentAsync<List<PaymentMethod>>.loading(),
    this.nationalities = const ResidentAsync<List<LookupOption>>.loading(),
    this.purposes = const ResidentAsync<List<LookupOption>>.loading(),
    this.provinces = const ResidentLocationLevel(busy: true),
    this.districts = const ResidentLocationLevel(),
    this.villages = const ResidentLocationLevel(),
    this.submitPending = false,
    this.submitError,
    this.scrollToErrorTick = 0,
  });

  final int step;
  final bool showErrors;
  final Map<String, String> serverErrors;
  final ResidentSubmitted? submitted;
  final bool detecting;
  final bool detected;
  final ResidentFormData form;
  final ResidentDraftCase? draft;

  final ResidentAsync<Service> service;
  final ResidentAsync<int> pricing;
  final ResidentAsync<List<PaymentMethod>> methods;
  final ResidentAsync<List<LookupOption>> nationalities;
  final ResidentAsync<List<LookupOption>> purposes;

  final ResidentLocationLevel provinces;
  final ResidentLocationLevel districts;
  final ResidentLocationLevel villages;

  /// `submitCase.pending` (`:553`) and `submitCase.error` (`:670`).
  final bool submitPending;
  final String? submitError;

  /// Bumped every time the page calls `scrollToFirstError()` (`:557`, `:578`).
  /// A counter and not a flag: two consecutive failed taps must scroll twice.
  final int scrollToErrorTick;

  /// `const fee = pricingQuery.data?.fee_lak ?? serviceQuery.data?.fee_lak ?? 0`
  /// — `:342`. **Three-deep, in that order.**
  int get fee => pricing.data ?? service.data?.feeLak ?? 0;

  /// `:453` — `const lastStep = STEP_COUNT`.
  bool get isLastStep => step == kResidentStepCount;

  /// `serviceQuery.loading && !serviceQuery.data` — `:584`.
  bool get showsServiceLoading => service.loading && service.data == null;

  /// `serviceQuery.error && !serviceQuery.data` — `:593`.
  bool get showsServiceError => service.error != null && service.data == null;

  ResidentFormViewState copyWith({
    int? step,
    bool? showErrors,
    Map<String, String>? serverErrors,
    ResidentSubmitted? submitted,
    bool? detecting,
    bool? detected,
    ResidentFormData? form,
    ResidentDraftCase? draft,
    ResidentAsync<Service>? service,
    ResidentAsync<int>? pricing,
    ResidentAsync<List<PaymentMethod>>? methods,
    ResidentAsync<List<LookupOption>>? nationalities,
    ResidentAsync<List<LookupOption>>? purposes,
    ResidentLocationLevel? provinces,
    ResidentLocationLevel? districts,
    ResidentLocationLevel? villages,
    bool? submitPending,
    String? submitError,
    bool clearSubmitError = false,
    int? scrollToErrorTick,
  }) =>
      ResidentFormViewState(
        step: step ?? this.step,
        showErrors: showErrors ?? this.showErrors,
        serverErrors: serverErrors ?? this.serverErrors,
        submitted: submitted ?? this.submitted,
        detecting: detecting ?? this.detecting,
        detected: detected ?? this.detected,
        form: form ?? this.form,
        draft: draft ?? this.draft,
        service: service ?? this.service,
        pricing: pricing ?? this.pricing,
        methods: methods ?? this.methods,
        nationalities: nationalities ?? this.nationalities,
        purposes: purposes ?? this.purposes,
        provinces: provinces ?? this.provinces,
        districts: districts ?? this.districts,
        villages: villages ?? this.villages,
        submitPending: submitPending ?? this.submitPending,
        submitError: clearSubmitError ? null : (submitError ?? this.submitError),
        scrollToErrorTick: scrollToErrorTick ?? this.scrollToErrorTick,
      );
}

/// The Resident wizard's one BLoC.
class ResidentFormCubit extends Cubit<ResidentFormViewState> {
  ResidentFormCubit({
    required this.clock,
    required this.getLookupOptions,
    required this.createApplication,
    required this.updateApplication,
    required this.addAttachment,
    required this.submitApplication,
    required this.loadService,
    required this.loadPaymentMethods,
    this.probeIdentity,
    this.pay,
    this.lang = Lang.en,
  }) : super(const ResidentFormViewState());

  /// ADR-0005's injected clock. **The only source of a date on this page** —
  /// `DateTime.now()` appears nowhere under `features/certificates/`
  /// (`F1-AC-39`), and `toUtc()` is forbidden repo-wide.
  final SubmissionClock clock;

  final GetLookupOptions getLookupOptions;
  final CreateApplication createApplication;
  final UpdateApplication updateApplication;
  final AddAttachment addAttachment;
  final SubmitApplication submitApplication;

  /// `catalog.service(SERVICE_CODE)` and `catalog.pricing(SERVICE_CODE)`
  /// (`:336-337`), as one call: the two answer the same row and the page reads
  /// `fee_lak` off whichever arrives.
  final Future<Either<Failure, Service>> Function() loadService;

  /// `payments.methods()` (`:338`).
  final Future<Either<Failure, List<PaymentMethod>>> Function()
      loadPaymentMethods;

  /// See the library comment. Null runs the failure path.
  final ResidentIdentityProbe? probeIdentity;

  /// See the library comment. Null makes a fee-bearing case submit and then
  /// find no receipt, which is the honest rendering of "the pay capability is
  /// not wired yet" and is never silently reported as a successful charge.
  final ResidentPayPort? pay;

  final Lang lang;

  /// `uploaded = useRef<Set<string>>(new Set())` — `:457`.
  ///
  /// **A field and not part of the state**, because it is a `useRef`: mutating
  /// it must not rebuild, and it is per-page-instance rather than persisted
  /// (`specs.md` § 6.3 item 3).
  final Set<String> _uploaded = <String>{};

  /// Test-visible copy of the dedupe set (`F1-AC-58`).
  Set<String> get uploadedSlots => Set<String>.unmodifiable(_uploaded);

  // ───────────────────────────────────────────────────────────────────────────
  // Catalogue loads — the four `useQuery`s at `:336-340`
  // ───────────────────────────────────────────────────────────────────────────

  /// Every query the page fires on mount. Awaited together, as four independent
  /// `useQuery`s are: one failing does not cancel the others.
  Future<void> load() async {
    await Future.wait<void>(<Future<void>>[
      refetchService(),
      loadMethods(),
      loadReference(LookupKey.reference('nationality')),
      loadReference(LookupKey.reference('certificate-purpose')),
      loadProvinces(),
    ]);
  }

  /// `serviceQuery.refetch` — the retry button at `:601`.
  Future<void> refetchService() async {
    emit(state.copyWith(service: const ResidentAsync<Service>.loading()));
    final Either<Failure, Service> result = await loadService();
    if (isClosed) return;
    emit(
      state.copyWith(
        service: result.fold(
          (Failure f) => ResidentAsync<Service>(error: f.message),
          (Service s) => ResidentAsync<Service>(data: s),
        ),
        // `pricingQuery` answers the same row in this port. Its `fee_lak` wins
        // over the service's when present, which is `:342`'s first `??`.
        pricing: result.fold(
          (Failure f) => ResidentAsync<int>(error: f.message),
          (Service s) => ResidentAsync<int>(data: s.feeLak),
        ),
      ),
    );
  }

  Future<void> loadMethods() async {
    final Either<Failure, List<PaymentMethod>> result =
        await loadPaymentMethods();
    if (isClosed) return;
    emit(
      state.copyWith(
        methods: result.fold(
          (Failure f) => ResidentAsync<List<PaymentMethod>>(error: f.message),
          (List<PaymentMethod> m) => ResidentAsync<List<PaymentMethod>>(data: m),
        ),
      ),
    );
  }

  /// `useReferenceOptions("nationality")` / `("certificate-purpose")` —
  /// `:339-340`. One method, because the two differ only by key.
  Future<void> loadReference(LookupKey key) async {
    final bool isNationality =
        key is ReferenceListKey && key.type == 'nationality';
    emit(
      isNationality
          ? state.copyWith(
              nationalities: const ResidentAsync<List<LookupOption>>.loading())
          : state.copyWith(
              purposes: const ResidentAsync<List<LookupOption>>.loading()),
    );

    final Either<Failure, List<LookupOption>> result =
        await getLookupOptions(key);
    if (isClosed) return;

    final ResidentAsync<List<LookupOption>> next = result.fold(
      (Failure f) => ResidentAsync<List<LookupOption>>(error: f.message),
      (List<LookupOption> rows) =>
          ResidentAsync<List<LookupOption>>(data: rows),
    );
    emit(
      isNationality
          ? state.copyWith(nationalities: next)
          : state.copyWith(purposes: next),
    );
  }

  Future<void> loadProvinces() async {
    emit(state.copyWith(provinces: const ResidentLocationLevel(busy: true)));
    final Either<Failure, List<LookupOption>> result =
        await getLookupOptions(LookupKey.provinces);
    if (isClosed) return;
    emit(state.copyWith(provinces: _levelFrom(result)));
  }

  Future<void> loadDistricts(String provinceId) async {
    if (provinceId.isEmpty) {
      emit(state.copyWith(districts: const ResidentLocationLevel()));
      return;
    }
    emit(state.copyWith(districts: const ResidentLocationLevel(busy: true)));
    final Either<Failure, List<LookupOption>> result =
        await getLookupOptions(LookupKey.districts, parentId: provinceId);
    if (isClosed) return;
    emit(state.copyWith(districts: _levelFrom(result)));
  }

  Future<void> loadVillages(String districtId) async {
    if (districtId.isEmpty) {
      emit(state.copyWith(villages: const ResidentLocationLevel()));
      return;
    }
    emit(state.copyWith(villages: const ResidentLocationLevel(busy: true)));
    final Either<Failure, List<LookupOption>> result =
        await getLookupOptions(LookupKey.villages, parentId: districtId);
    if (isClosed) return;
    emit(state.copyWith(villages: _levelFrom(result)));
  }

  ResidentLocationLevel _levelFrom(
    Either<Failure, List<LookupOption>> result,
  ) =>
      result.fold(
        (Failure _) => const ResidentLocationLevel(failed: true),
        (List<LookupOption> rows) => ResidentLocationLevel(rows: rows),
      );

  /// The kernel's parameter object for a reference-backed control. Built here
  /// so no widget ever sees a [LookupOption] or a use case (G-L5, `F0-AC-77`).
  ReferenceFieldState referenceStateOf(
    ResidentAsync<List<LookupOption>> query,
    LookupKey key,
  ) =>
      referenceFieldStateFrom(
        query.data ?? const <LookupOption>[],
        lang: lang,
        loading: query.loading,
        failed: query.error != null,
        retry: query.error != null ? () => loadReference(key) : null,
      );

  // ───────────────────────────────────────────────────────────────────────────
  // Field edits — `set(key, value)` at `:378-379`
  // ───────────────────────────────────────────────────────────────────────────

  /// One entry point for every plain field, so the server-error clear
  /// (`:381-384`) happens exactly once and cannot be forgotten at a call site.
  void setField(ResidentFormData Function(ResidentFormData) edit, {String? path}) {
    emit(state.copyWith(form: edit(state.form)));
    clearServerError(path);
  }

  /// `clearServerError` — `:381-384`. A null path clears nothing, and a path
  /// with no entry leaves the map **identical** rather than replacing it.
  void clearServerError(String? path) {
    if (path == null) return;
    if (!state.serverErrors.containsKey(path)) return;
    final Map<String, String> next = Map<String, String>.of(state.serverErrors)
      ..remove(path);
    emit(state.copyWith(serverErrors: next));
  }

  /// `onChange={(v) => set("age", v.replace(/\D/g,"").slice(0,3))}` — `:820`.
  void setAge(String raw) {
    final String digits = raw.replaceAll(RegExp(r'\D'), '');
    setField(
      (ResidentFormData f) =>
          f.copyWith(age: digits.length > 3 ? digits.substring(0, 3) : digits),
      path: 'applicant.age',
    );
  }

  /// `onChange={(v) => set("purposeOther", v.slice(0, 100))}` — `:1013`.
  ///
  /// **No `path`**: the `purposeOther` input is the one control on the page
  /// with none (`:1009-1016`), so a 422 about it can never land on it
  /// (`F1-AC-70`, and the `FIELD_STEP` gap `F1-AC-62` records).
  void setPurposeOther(String raw) => setField(
        (ResidentFormData f) => f.copyWith(
          purposeOther: raw.length > 100 ? raw.substring(0, 100) : raw,
        ),
      );

  /// `LocationFields.onChange` — `:868-875`. A patch, so an undefined member
  /// leaves its field alone; picking a province blanks district and village.
  void setLocation({String? province, String? district, String? village}) {
    emit(
      state.copyWith(
        form: state.form.copyWith(
          province: province,
          district: district,
          villageName: village,
        ),
      ),
    );
    if (province != null) {
      clearServerError('header.province_id');
      unawaited(loadDistricts(province));
      emit(state.copyWith(villages: const ResidentLocationLevel()));
    }
    if (district != null) {
      clearServerError('header.district_id');
      unawaited(loadVillages(district));
    }
    if (village != null) clearServerError('header.village_id');
  }

  // ───────────────────────────────────────────────────────────────────────────
  // Attachments and detection
  // ───────────────────────────────────────────────────────────────────────────

  /// `handleFrontId` — `:396-426`, both arms.
  Future<void> setFrontId(PickedAttachment? file) async {
    if (file == null) {
      // `:415-425` — the ONLY path that blanks the three applicant fields, and
      // it is the citizen removing the file. `specs.md` § 6.4(b): a port that
      // also cleared them on a 404 would have a state transition the source has
      // not got (`F1-AC-42`).
      emit(
        state.copyWith(
          detecting: false,
          detected: false,
          form: state.form.copyWith(
            clearFrontId: true,
            citizenName: '',
            age: '',
            nationality: '',
          ),
        ),
      );
      return;
    }

    emit(
      state.copyWith(
        form: state.form.copyWith(frontId: file),
        detecting: true,
        detected: false,
      ),
    );
    await _detect();
  }

  /// `:401-414` — the `try` / `catch` / `finally`.
  ///
  /// **A null [probeIdentity] takes the `catch` branch**, and that is a
  /// measurement rather than a stub. `F1-NV-2` records `GET /me/digital-id`
  /// answering 404 as of 2026-08-13, so the failure path *is* today's observable
  /// behaviour of the real endpoint; running it is a faithful port of what a
  /// citizen sees, where a success path fabricated from a card the Flutter
  /// entity cannot carry would not be. The gap is escalated, not papered over.
  Future<void> _detect() async {
    try {
      final ResidentIdentityProbe? probe = probeIdentity;
      if (probe == null) throw const _NoIdentityProbe();
      final ResidentIdentity card = await probe();
      if (isClosed) return;
      emit(
        state.copyWith(
          form: state.form.copyWith(
            // `text(card.name, lang) || prev.citizenName` — `:405`. The `||`
            // is a FALLBACK to the previous value, not an overwrite with
            // empty: a card with a blank name leaves what the citizen typed.
            citizenName: _orPrevious(
              text(card.name, lang),
              state.form.citizenName,
            ),
            // `ageFrom(card.date_of_birth) || prev.age` — `:406`. A Tier 0
            // value: it lands in `applicant.age` (`:466`).
            age: _orPrevious(
              ageFrom(card.dateOfBirth, clock),
              state.form.age,
            ),
            // `(card.nationality || prev.nationality).toLowerCase()` — `:407`.
            // **The lowercase wraps the whole `||`**, so a fallback to the
            // previous value is lowercased too.
            nationality: _orPrevious(
              card.nationality,
              state.form.nationality,
            ).toLowerCase(),
          ),
          detected: true,
        ),
      );
    } catch (_) {
      // `catch { setDetected(false); }` — `:410-412`, and that is the WHOLE
      // branch. It clears no field and renders no message: `specs.md` Finding C
      // measured that a 404 produces no error banner, no retry control and no
      // toast (`F1-AC-42` iii).
      if (isClosed) return;
      emit(state.copyWith(detected: false));
    } finally {
      // `finally { setDetecting(false); }` — `:413`.
      if (!isClosed) emit(state.copyWith(detecting: false));
    }
  }

  static String _orPrevious(String value, String previous) =>
      value.isEmpty ? previous : value;

  void setBackId(PickedAttachment? file) => emit(
        state.copyWith(
          form: file == null
              ? state.form.copyWith(clearBackId: true)
              : state.form.copyWith(backId: file),
        ),
      );

  void setFamilyBookCover(PickedAttachment? file) {
    emit(
      state.copyWith(
        form: file == null
            ? state.form.copyWith(clearFamilyBookCover: true)
            : state.form.copyWith(familyBookCover: file),
      ),
    );
    if (file != null) clearServerError('household_reference.family_book_upload');
  }

  void setFamilyBookContents(PickedAttachment? file) => emit(
        state.copyWith(
          form: file == null
              ? state.form.copyWith(clearFamilyBookContents: true)
              : state.form.copyWith(familyBookContents: file),
        ),
      );

  void setPicture(PickedAttachment? file) {
    emit(
      state.copyWith(
        form: file == null
            ? state.form.copyWith(clearPicture: true)
            : state.form.copyWith(picture: file),
      ),
    );
    if (file != null) clearServerError('applicant.photo');
  }

  void setPayment(PaymentDraft payment) =>
      emit(state.copyWith(form: state.form.copyWith(payment: payment)));

  // ───────────────────────────────────────────────────────────────────────────
  // Navigation and submission
  // ───────────────────────────────────────────────────────────────────────────

  /// `canProceed()` — the predicate, read from the current state.
  bool get canProceed => residentCanProceed(
        state.form,
        step: state.step,
        detecting: state.detecting,
      );

  /// `goBack` — `:544-548`. Returns true when the caller should leave the page.
  bool goBack() {
    emit(state.copyWith(showErrors: false));
    if (state.step > 1) {
      emit(state.copyWith(step: state.step - 1));
      return false;
    }
    return true;
  }

  /// `handleNext` — `:550-581`.
  Future<void> next() async {
    // `if (submitCase.pending) return;` — `:553`. The guard is HERE and the CTA
    // stays tappable: a port that disables the button has diverged
    // (`:1037-1044`, `F1-AC-65`).
    if (state.submitPending) return;

    if (!canProceed) {
      // `setShowErrors(true); scrollToFirstError(); return;` — `:555-558`.
      emit(
        state.copyWith(
          showErrors: true,
          scrollToErrorTick: state.scrollToErrorTick + 1,
        ),
      );
      return;
    }

    emit(state.copyWith(showErrors: false));

    if (!state.isLastStep) {
      emit(state.copyWith(step: state.step + 1));
      return;
    }

    // `setServerErrors({})` — `:566`, before the attempt and not after it.
    emit(
      state.copyWith(
        serverErrors: const <String, String>{},
        submitPending: true,
        clearSubmitError: true,
      ),
    );

    try {
      final ResidentSubmitted result = await _submitCase();
      if (isClosed) return;
      emit(state.copyWith(submitted: result, submitPending: false));
    } on ApiException catch (e) {
      if (isClosed) return;
      _onSubmitFailed(e);
    } catch (e) {
      if (isClosed) return;
      // Not an `ApiException`, so not a 422: no navigation, no clear
      // (`F1-AC-64`).
      emit(
        state.copyWith(submitPending: false, submitError: e.toString()),
      );
    }
  }

  /// `:570-580` — the catch. **The 422 branch has no `else`** (`F1-AC-64`).
  void _onSubmitFailed(ApiException e) {
    final Map<String, String> fields = e.fieldMap();
    if (e.isValidation && fields.isNotEmpty) {
      final int? target =
          stepOfFirstError(fields.keys.toList(growable: false), kResidentFieldStep);
      emit(
        state.copyWith(
          submitPending: false,
          submitError: e.message,
          serverErrors: fields,
          step: target ?? state.step,
          scrollToErrorTick: state.scrollToErrorTick + 1,
        ),
      );
      return;
    }
    // Everything else: the red banner at `:708-713`, and the wizard stays where
    // it is with the form untouched.
    emit(state.copyWith(submitPending: false, submitError: e.message));
  }

  /// `submitCase` — `:500-542`, in order and with the retry semantics intact.
  Future<ResidentSubmitted> _submitCase() async {
    // `const payload = buildFormData();` — `:501`. **Built ONCE per attempt**
    // and reused by the update body, which is what `flat-appended-last` means
    // and what `F0-AC-14` asserts. `residentBodiesFrom` takes the built payload
    // rather than a builder for exactly this reason.
    final Map<String, Object?> payload =
        buildResidentFormData(state.form, clock);

    // 1. `if (!current) { … }` — `:505-517`. The draft is created ONCE; a retry
    //    reuses `{id, reference_no}` so a rejected submission leaves no trail of
    //    half-filled cases (`F1-AC-56`).
    ResidentDraftCase? current = state.draft;
    if (current == null) {
      final ApplicationDetail created = _orThrow(
        await createApplication(
          residentCreateEnvelope(
            form: state.form,
            payload: payload,
            clock: clock,
          ),
        ),
      );
      current = ResidentDraftCase(
        id: created.row.id,
        referenceNo: created.row.referenceNo,
      );
      emit(state.copyWith(draft: current));
    }

    // 2. `await applications.update(...)` — `:521-524`. Runs on EVERY attempt,
    //    including the first, because it is what writes `header.ref_no`
    //    (`F1-AC-57`). The bodies are rebuilt with the reference now known.
    final SubmissionBodies bound =
        residentBodiesFrom(payload, current.referenceNo);
    _orThrow(
      await updateApplication(
        UpdateApplicationParams(
          id: current.id,
          envelope: residentUpdateEnvelope(
            updatePayload: bound.update,
            clock: clock,
          ),
        ),
      ),
    );

    // 3. `for (const attachment of attachmentsToSend())` — `:526-530`.
    //    **Sequential**, in `attachmentsToSend()`'s fixed order, skipping any
    //    slot already sent. Not `Future.wait` (`F1-AC-58`).
    for (final CertificateAttachment a in residentAttachmentsToSend(state.form)) {
      if (_uploaded.contains(a.slot)) continue;
      _orThrow(
        await addAttachment(
          AddAttachmentParams(
            id: current.id,
            file: a.file,
            slot: a.slot,
            kind: a.kind,
          ),
        ),
      );
      _uploaded.add(a.slot);
    }

    // 4. `const decided = await applications.submit(current.id);` — `:532`.
    final ApplicationDetail decided =
        _orThrow(await submitApplication(current.id));

    // 5. `if (decided.fee_lak > 0) { … }` — `:535-540`. A zero-fee case does
    //    **not** call pay (`F1-AC-24`).
    String? receiptNo;
    if (decided.row.feeLak > 0) {
      final ResidentPayPort? port = pay;
      if (port != null) {
        final Object? result = _orThrow(
          await port(
            current.id,
            methodCode: residentMethodCodeFor(
              state.form.payment.method,
              state.methods.data ?? const <PaymentMethod>[],
            ),
          ),
        );
        receiptNo = residentReceiptOf(result);
      }
      // No port: the case is submitted and there is no receipt. The success
      // card's receipt row is conditional (`:637-639`), so it renders exactly as
      // it does for a pay answer that carried none. Reported NOT EVALUATED
      // rather than as a charge that happened (`specs.md` § 6.2).
    }

    return ResidentSubmitted(decided: decided, receiptNo: receiptNo);
  }

  /// `await` on a rejected promise throws; `Either` does not. This is the one
  /// place the two are reconciled, so the orchestration above reads like
  /// `:500-542` does.
  T _orThrow<T>(Either<Failure, T> result) => result.fold(
        (Failure f) => throw _asApiException(f),
        (T value) => value,
      );

  /// `await` on a rejected promise throws an `ApiError` the page can ask
  /// `isValidation` of; an `Either`'s `Left` has folded it to a `Failure` and
  /// lost `fields`. [ApiFailure] is the write half's fold keeping the exception
  /// (`application_failures.dart`), so the 422 path is reachable without
  /// changing the read half's message — which `B7-AC-35` pins.
  Object _asApiException(Failure f) =>
      f is ApiFailure ? f.exception : Exception(f.message);
}

class _NoIdentityProbe implements Exception {
  const _NoIdentityProbe();
}
