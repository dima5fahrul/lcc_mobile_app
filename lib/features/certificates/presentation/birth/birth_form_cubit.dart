/// `BirthDeclarationPage.tsx:658-900` — the page's state machine.
///
/// ## The one structural difference from Resident, and it is the whole of § 6.7
///
/// Resident fires `pay` **inside** `submitCase`, as the last step of the submit
/// orchestration. Birth does not: `submitCase` ends at `submit` (`:844`), and
/// `payCase` (`:847-853`) is a **separate mutation** triggered by a button on
/// the success screen (`:983-992`), gated on `submitted.fee_lak > 0 && !receiptNo`
/// (`:937`). `F2-AC-49` asserts that driving a submit issues no pay request.
///
/// **Neither F2 page mounts `PaymentSection`.** No draft-mode payment, no
/// `LAO_BANKS`, no card mask, no payment step — step 6 is Review. F1's RULING 4
/// authored draft payment as a shared surface "F2 and F3 consume unchanged";
/// measured, F2 consumes none of it and the surface is F3's inheritance alone
/// (`specs.md` § 2.2 Finding F, `FU-4`). `F2-AC-51` asserts the absence,
/// because "port the payment section too" is the natural thing to do having
/// just read F1's spec.
///
/// ## Nothing here is shared with `presentation/death/`
///
/// The two cubits have the same *shape* and no common ancestor: `F2-AC-10`
/// requires two BLoCs with **no shared base class**. Their `canProceed`
/// predicates differ in every arm, their reference lists differ in count and
/// membership, their `FIELD_STEP` tables differ, and their skip models differ
/// structurally.
library;

import 'package:bloc/bloc.dart';
// `Option` is hidden: dartz exports one and so does the forms kernel
// (`presentation/forms/widgets/option.dart`), and this file needs the
// kernel's to build a `LocationLevel`. Only `Either`/`Left`/`Right` are
// wanted from dartz here.
import 'package:dartz/dartz.dart' hide Option;
import 'package:flutter/widgets.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../i18n/i18n.dart';
import '../../../../presentation/forms/validation/step_of_first_error.dart';
import '../../../../presentation/forms/widgets/location_fields_view.dart';
import '../../../../presentation/forms/widgets/option.dart';
import '../../../../presentation/forms/widgets/reference_field_state.dart';
import '../../../application/domain/application_failures.dart';
import '../../../application/domain/entities/application_detail.dart';
import '../../../application/domain/entities/picked_attachment.dart';
import '../../../application/domain/usecases/application_usecases.dart';
import '../../../reference/domain/entities/lookup_key.dart';
import '../../../reference/domain/entities/lookup_option.dart';
import '../../../reference/domain/usecases/get_lookup_options.dart';
import '../../../service/domain/entities/service.dart';
import '../../../wallet/domain/entities/payment_method.dart';
import '../../domain/submission/case_reference_binding.dart';
import '../../domain/submission/submission_clock.dart';
import 'birth_form_state.dart';
import 'birth_payload.dart';

/// The pay call, as this page needs it.
///
/// `(String, {required String methodCode}) -> Either<Failure, Object?>`. The
/// `Object?` is the wire's own two-key shape, not B6b's `PaymentResult`: `:848`
/// casts the response to `{receipt_no?, transaction?: {receipt_no?}}` and reads
/// one field off it. Adapting at the DI seam keeps B6b's entity out of this
/// tree (`certificates_bloc_injection.dart`).
///
/// Structurally identical to `ResidentPayPort` and `DeathPayPort` and shared
/// with neither: three separately-ported pages, three typedefs (§ 6.2).
typedef BirthPayPort = Future<Either<Failure, Object?>> Function(
  String applicationId, {
  required String methodCode,
});

/// `:737` — `draft`, the created case.
class BirthDraftCase {
  const BirthDraftCase({required this.id, required this.referenceNo});
  final String id;
  final String referenceNo;
}

/// `useQuery`'s three-state answer (`:670-672`).
class BirthAsync<T> {
  const BirthAsync({this.data, this.loading = false, this.error});
  const BirthAsync.loading() : this(loading: true);

  final T? data;
  final bool loading;
  final String? error;
}

/// One `LocationFields` level.
class BirthLocationLevel {
  const BirthLocationLevel({
    this.rows = const <LookupOption>[],
    this.busy = false,
    this.failed = false,
  });
  final List<LookupOption> rows;
  final bool busy;
  final bool failed;
}

/// The ten reference lists `useRefLists()` loads (`:257-270`).
///
/// **Ten, against Death's eight.** Birth carries `blood`, `delivery` and
/// `birthType`; Death carries `cause` and none of those three. The enum is
/// per-page for that reason.
enum BirthRefList {
  ethnicity('ethnicity'),
  nationality('nationality'),
  ethnicGroup('ethnic-group'),
  religion('religion'),
  education('education-level'),
  marital('marital-status'),
  relation('relation'),
  blood('blood-type'),
  delivery('delivery-mode'),
  birthType('birth-type');

  const BirthRefList(this.type);

  /// The `/reference/{type}` path segment, verbatim from `:259-268`.
  final String type;

  LookupKey get key => LookupKey.reference(type);
}

class BirthFormViewState {
  const BirthFormViewState({
    this.step = 1,
    this.showErrors = false,
    this.serverErrors = const <String, String>{},
    this.submitted,
    this.receiptNo,
    this.form = const BirthFormData(),
    this.draft,
    this.service = const BirthAsync<Service>(),
    this.methods = const BirthAsync<List<PaymentMethod>>(),
    this.refs = const <BirthRefList, BirthAsync<List<LookupOption>>>{},
    this.headerNames = const <String, String>{},
    this.pobNames = const <String, String>{},
    this.provinces = const BirthLocationLevel(),
    this.districts = const BirthLocationLevel(),
    this.villages = const BirthLocationLevel(),
    this.submitPending = false,
    this.submitError,
    this.payPending = false,
    this.payError,
    this.scrollToErrorTick = 0,
  });

  final int step;
  final bool showErrors;
  final Map<String, String> serverErrors;

  /// `:666` — set only by a successful submit. **Never cleared by an error**
  /// (`F2-AC-64`).
  final ApplicationDetail? submitted;

  /// `:667` — set only by a successful pay. Gates the receipt row and the pay
  /// button.
  final String? receiptNo;

  final BirthFormData form;
  final BirthDraftCase? draft;

  final BirthAsync<Service> service;
  final BirthAsync<List<PaymentMethod>> methods;
  final Map<BirthRefList, BirthAsync<List<LookupOption>>> refs;

  /// `:678-679` — `headerNames` and `pobNames`, the resolved place names the
  /// review step renders. Keys `province`/`district`/`village`.
  final Map<String, String> headerNames;
  final Map<String, String> pobNames;

  final BirthLocationLevel provinces;
  final BirthLocationLevel districts;
  final BirthLocationLevel villages;

  final bool submitPending;
  final String? submitError;

  /// `payCase.pending` / `payCase.error` — a **second** mutation's state,
  /// independent of the submit's (`:847`).
  final bool payPending;
  final String? payError;

  final int scrollToErrorTick;

  bool get isLastStep => step == kBirthStepCount;

  /// `:903` — `serviceQuery.loading && !serviceQuery.data`.
  bool get showsServiceLoading => service.loading && service.data == null;

  /// `:912` — `serviceQuery.error && !serviceQuery.data`.
  bool get showsServiceError => service.error != null && service.data == null;

  /// `:937` — `submitted.fee_lak > 0 && !receiptNo`.
  ///
  /// Gates whether the pay button **renders**, and flips the back-to-home
  /// button from outlined to filled when it goes false (`:994-1000`).
  bool get unpaid =>
      submitted != null && submitted!.row.feeLak > 0 && receiptNo == null;

  BirthFormViewState copyWith({
    int? step,
    bool? showErrors,
    Map<String, String>? serverErrors,
    ApplicationDetail? submitted,
    String? receiptNo,
    BirthFormData? form,
    BirthDraftCase? draft,
    BirthAsync<Service>? service,
    BirthAsync<List<PaymentMethod>>? methods,
    Map<BirthRefList, BirthAsync<List<LookupOption>>>? refs,
    Map<String, String>? headerNames,
    Map<String, String>? pobNames,
    BirthLocationLevel? provinces,
    BirthLocationLevel? districts,
    BirthLocationLevel? villages,
    bool? submitPending,
    String? submitError,
    bool clearSubmitError = false,
    bool? payPending,
    String? payError,
    bool clearPayError = false,
    int? scrollToErrorTick,
  }) =>
      BirthFormViewState(
        step: step ?? this.step,
        showErrors: showErrors ?? this.showErrors,
        serverErrors: serverErrors ?? this.serverErrors,
        submitted: submitted ?? this.submitted,
        receiptNo: receiptNo ?? this.receiptNo,
        form: form ?? this.form,
        draft: draft ?? this.draft,
        service: service ?? this.service,
        methods: methods ?? this.methods,
        refs: refs ?? this.refs,
        headerNames: headerNames ?? this.headerNames,
        pobNames: pobNames ?? this.pobNames,
        provinces: provinces ?? this.provinces,
        districts: districts ?? this.districts,
        villages: villages ?? this.villages,
        submitPending: submitPending ?? this.submitPending,
        submitError: clearSubmitError ? null : (submitError ?? this.submitError),
        payPending: payPending ?? this.payPending,
        payError: clearPayError ? null : (payError ?? this.payError),
        scrollToErrorTick: scrollToErrorTick ?? this.scrollToErrorTick,
      );
}

class BirthFormCubit extends Cubit<BirthFormViewState> {
  BirthFormCubit({
    required this.clock,
    required this.getLookupOptions,
    required this.createApplication,
    required this.updateApplication,
    required this.addAttachment,
    required this.submitApplication,
    required this.loadService,
    required this.loadPaymentMethods,
    required this.readLegalBasisText,
    this.pay,
    this.lang = Lang.en,
  }) : super(const BirthFormViewState());

  /// `ADR-0005`'s injected clock. **The only source of a date on this page** —
  /// `DateTime.now()` appears nowhere under `presentation/birth/`
  /// (`F2-AC-90`), and `toUtc()` is forbidden repo-wide.
  final SubmissionClock clock;

  final GetLookupOptions getLookupOptions;
  final CreateApplication createApplication;
  final UpdateApplication updateApplication;
  final AddAttachment addAttachment;
  final SubmitApplication submitApplication;
  final Future<Either<Failure, Service>> Function() loadService;
  final Future<Either<Failure, List<PaymentMethod>>> Function()
      loadPaymentMethods;

  /// `t("legalBasisText")` against the **`birth`** namespace (`:761`).
  ///
  /// ## A function, not a String, and that is a fidelity decision
  ///
  /// `useT("birth")` is acquired at the component top level (`:659`) and
  /// `buildFormData` closes over it, so React re-renders on a locale change and
  /// the value is **current at submit**. A `String` resolved when the cubit is
  /// constructed would freeze the payload's locale at the moment the citizen
  /// opened the form: switching language mid-form would change the wire body on
  /// the web and not in the port. That is a behavioural divergence L-10
  /// forbids, in the one leaf on this page the locale can change.
  ///
  /// Injected rather than looked up here so `birth_payload.dart` stays pure
  /// (which is what lets Tier 0 drive it from a literal fixture) and so the
  /// namespace choice sits at a call site the isolation guard can see. The DI
  /// registration reads `birth`; nothing in this file can accidentally read
  /// `death`.
  final String Function() readLegalBasisText;

  /// B6b's `PayApplication`, adapted at the DI seam. Null leaves the pay button
  /// rendering and the call failing honestly rather than silently reporting a
  /// charge that did not happen.
  final BirthPayPort? pay;

  final Lang lang;

  /// `uploaded = useRef<Set<string>>(new Set())` — `:738`.
  ///
  /// A field, not part of the state: it is a `useRef`, so mutating it must not
  /// rebuild, and it is per-page-instance rather than persisted.
  final Set<String> _uploaded = <String>{};

  Set<String> get uploadedSlots => Set<String>.unmodifiable(_uploaded);

  // ───────────────────────────────────────────────────────────────────────────
  // Catalogue — the queries at `:670-673`
  // ───────────────────────────────────────────────────────────────────────────

  /// Everything the page fires on mount: service, payment methods and **ten**
  /// reference lists. Awaited together, as independent `useQuery`s are — one
  /// failing does not cancel the others.
  ///
  /// `ssd.md` § 11.3 keeps session-scoped de-duplication, so the port need not
  /// reproduce the source's 19 independent fetches (R-22).
  Future<void> load() async {
    await Future.wait<void>(<Future<void>>[
      refetchService(),
      loadMethods(),
      for (final BirthRefList r in BirthRefList.values) loadReference(r),
    ]);
  }

  Future<void> refetchService() async {
    emit(state.copyWith(service: const BirthAsync<Service>.loading()));
    final Either<Failure, Service> result = await loadService();
    if (isClosed) return;
    emit(
      state.copyWith(
        service: result.fold(
          (Failure f) => BirthAsync<Service>(error: f.message),
          (Service s) => BirthAsync<Service>(data: s),
        ),
      ),
    );
  }

  Future<void> loadMethods() async {
    emit(state.copyWith(methods: const BirthAsync<List<PaymentMethod>>.loading()));
    final Either<Failure, List<PaymentMethod>> result =
        await loadPaymentMethods();
    if (isClosed) return;
    emit(
      state.copyWith(
        methods: result.fold(
          (Failure f) => BirthAsync<List<PaymentMethod>>(error: f.message),
          (List<PaymentMethod> rows) =>
              BirthAsync<List<PaymentMethod>>(data: rows),
        ),
      ),
    );
  }

  Future<void> loadReference(BirthRefList which) async {
    emit(
      state.copyWith(
        refs: <BirthRefList, BirthAsync<List<LookupOption>>>{
          ...state.refs,
          which: const BirthAsync<List<LookupOption>>.loading(),
        },
      ),
    );
    final Either<Failure, List<LookupOption>> result =
        await getLookupOptions(which.key);
    if (isClosed) return;
    emit(
      state.copyWith(
        refs: <BirthRefList, BirthAsync<List<LookupOption>>>{
          ...state.refs,
          which: result.fold(
            (Failure f) => BirthAsync<List<LookupOption>>(error: f.message),
            (List<LookupOption> rows) =>
                BirthAsync<List<LookupOption>>(data: rows),
          ),
        },
      ),
    );
  }

  /// The kernel's parameter object for a reference-backed control.
  ///
  /// Built here so no widget ever sees a [LookupOption] or a use case (G-L5,
  /// `F0-AC-77`). An unloaded list yields `loading: false, options: []` — the
  /// **empty** state, one of the four `F2-AC-75` asserts per control.
  ReferenceFieldState referenceStateOf(BirthRefList which) {
    final BirthAsync<List<LookupOption>> q =
        state.refs[which] ?? const BirthAsync<List<LookupOption>>();
    return referenceFieldStateFrom(
      q.data ?? const <LookupOption>[],
      lang: lang,
      loading: q.loading,
      failed: q.error != null,
      retry: q.error != null ? () => loadReference(which) : null,
    );
  }

  Future<void> loadProvinces() async {
    emit(state.copyWith(provinces: const BirthLocationLevel(busy: true)));
    final Either<Failure, List<LookupOption>> r =
        await getLookupOptions(LookupKey.provinces);
    if (isClosed) return;
    emit(state.copyWith(provinces: _levelFrom(r)));
  }

  Future<void> loadDistricts(String provinceId) async {
    emit(state.copyWith(districts: const BirthLocationLevel(busy: true)));
    final Either<Failure, List<LookupOption>> r =
        await getLookupOptions(LookupKey.districts);
    if (isClosed) return;
    emit(state.copyWith(districts: _levelFrom(r)));
  }

  Future<void> loadVillages(String districtId) async {
    emit(state.copyWith(villages: const BirthLocationLevel(busy: true)));
    final Either<Failure, List<LookupOption>> r =
        await getLookupOptions(LookupKey.villages);
    if (isClosed) return;
    emit(state.copyWith(villages: _levelFrom(r)));
  }

  BirthLocationLevel _levelFrom(Either<Failure, List<LookupOption>> r) =>
      r.fold(
        (Failure _) => const BirthLocationLevel(failed: true),
        (List<LookupOption> rows) => BirthLocationLevel(rows: rows),
      );

  /// One level as the kernel's parameter object.
  ///
  /// Built here rather than in the widget so no widget ever sees a
  /// [LookupOption] (G-L5, `F0-AC-77`). The `sub` line carries the *other*
  /// locale, which is what the source's location select renders underneath the
  /// label.
  ///
  /// The rows are passed **raw**: `visibleRows`' stale-row rule lives inside
  /// the kernel where Tier 1 can see it, and a caller that pre-blanked them
  /// would be reimplementing it.
  LocationLevel locationLevel(
    BirthLocationLevel level,
    BuildContext context, {
    required VoidCallback retry,
  }) {
    final Lang locale = Localizations.localeOf(context).languageCode == 'lo'
        ? Lang.lo
        : Lang.en;
    return LocationLevel(
      rows: <Option>[
        for (final LookupOption row in level.rows)
          Option(
            value: row.id,
            label: text(row.label, locale),
            sub: locale == Lang.lo ? row.label.en : row.label.lo,
          ),
      ],
      busy: level.busy,
      failed: level.failed,
      onRetry: level.failed ? retry : null,
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // Field edits
  // ───────────────────────────────────────────────────────────────────────────

  /// One entry point for every field edit, so the server-error clear
  /// (`:692-697`) happens exactly once and cannot be forgotten at a call site.
  void setField(
    BirthFormData Function(BirthFormData) edit, {
    String? path,
  }) {
    emit(state.copyWith(form: edit(state.form)));
    clearServerError(path);
  }

  void patchChild(BirthChildInfo Function(BirthChildInfo) edit, {String? path}) =>
      setField((BirthFormData f) => f.copyWith(child: edit(f.child)), path: path);

  void patchMother(
    BirthParentInfo Function(BirthParentInfo) edit, {
    String? path,
  }) =>
      setField((BirthFormData f) => f.copyWith(mother: edit(f.mother)),
          path: path);

  void patchFather(
    BirthParentInfo Function(BirthParentInfo) edit, {
    String? path,
  }) =>
      setField((BirthFormData f) => f.copyWith(father: edit(f.father)),
          path: path);

  void patchInformant(
    BirthInformantInfo Function(BirthInformantInfo) edit, {
    String? path,
  }) =>
      setField((BirthFormData f) => f.copyWith(informant: edit(f.informant)),
          path: path);

  /// `:1152` — the only numeric transform on either F2 page.
  void setBirthOrder(String raw) => patchChild(
        (BirthChildInfo c) =>
            c.copyWith(birthOrder: birthOrderTransform(raw)),
        path: 'child.birth_order',
      );

  /// `:1334` — `setFatherUnknown((v) => !v)`.
  ///
  /// **The `father` record is not cleared.** Toggling back restores every value
  /// the citizen typed (`F2-AC-69`), which is what the source does by holding
  /// the toggle and the record in two separate `useState`s.
  void toggleFatherUnknown() => emit(
        state.copyWith(
          form: state.form.copyWith(fatherUnknown: !state.form.fatherUnknown),
        ),
      );

  void setHospitalNotice(PickedAttachment? file) {
    emit(
      state.copyWith(
        form: file == null
            ? state.form.copyWith(clearHospitalNotice: true)
            : state.form.copyWith(hospitalNotice: file),
      ),
    );
    if (file != null) clearServerError('child.hospital_notice');
  }

  void setHeaderLocation({String? province, String? district, String? village}) {
    emit(
      state.copyWith(
        form: state.form.copyWith(
          province: province ?? state.form.province,
          district: district ?? state.form.district,
          village: village ?? state.form.village,
        ),
      ),
    );
  }

  /// `:699-701` — `keepPlace`, the resolved names the review step renders.
  void setHeaderNames(Map<String, String> names) =>
      emit(state.copyWith(headerNames: names));

  void setPobNames(Map<String, String> names) =>
      emit(state.copyWith(pobNames: names));

  /// `:692-697` — removes one key, and **returns the same map when the key is
  /// absent** so an unrelated edit does not rebuild every bound control.
  void clearServerError(String? path) {
    if (path == null) return;
    if (!state.serverErrors.containsKey(path)) return;
    final Map<String, String> next =
        Map<String, String>.of(state.serverErrors)..remove(path);
    emit(state.copyWith(serverErrors: next));
  }

  // ───────────────────────────────────────────────────────────────────────────
  // Navigation and submission
  // ───────────────────────────────────────────────────────────────────────────

  bool get canProceed => birthCanProceed(state.form, state.step);

  /// `:855-859` — `goBack`. Returns true when the caller should leave the page.
  bool goBack() {
    emit(state.copyWith(showErrors: false));
    if (state.step > 1) {
      emit(state.copyWith(step: state.step - 1));
      return false;
    }
    return true;
  }

  /// `:861-891` — `handleNext`.
  Future<void> next() async {
    // `:864` — the double-tap guard is HERE and the CTA stays tappable. A port
    // that disables the button has diverged (`fsd.md`:348, `F2-AC-66`).
    if (state.submitPending) return;

    if (!canProceed) {
      // `:867-869`.
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

    // `:877` — `setServerErrors({})`, before the attempt, not after it.
    emit(
      state.copyWith(
        serverErrors: const <String, String>{},
        submitPending: true,
        clearSubmitError: true,
      ),
    );

    try {
      final ApplicationDetail decided = await _submitCase();
      if (isClosed) return;
      emit(state.copyWith(submitted: decided, submitPending: false));
    } on ApiException catch (e) {
      if (isClosed) return;
      _onSubmitFailed(e);
    } catch (e) {
      if (isClosed) return;
      // Not an `ApiException`, so not a 422: no navigation, no clear
      // (`F2-AC-64`).
      emit(state.copyWith(submitPending: false, submitError: e.toString()));
    }
  }

  /// `:880-890` — the catch. **The 422 branch has no `else`.**
  ///
  /// Two absences this reproduces (`specs.md` § 6.9):
  ///
  /// 1. `stepOfFirstError` skips unmapped keys and returns null, and the call
  ///    site is `if (target) setStep(target)`. Since **no `parents.father.*`
  ///    key is mapped**, a 422 about the father sets the errors, runs the
  ///    scroll and leaves the citizen on step 6 with errors bound to controls
  ///    that render on step 4 (`F2-AC-63`).
  /// 2. A non-validation error does not navigate and does not clear
  ///    (`F2-AC-64`) — handled by `next`'s outer catch and by falling through
  ///    here.
  void _onSubmitFailed(ApiException e) {
    final Map<String, String> fields = e.fieldMap();
    if (e.isValidation && fields.isNotEmpty) {
      final int? target = stepOfFirstError(
        fields.keys.toList(growable: false),
        kBirthFieldStep,
      );
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
    emit(state.copyWith(submitPending: false, submitError: e.message));
  }

  /// `:815-845` — `submitCase`. **Ends at submit; there is no pay step here.**
  Future<ApplicationDetail> _submitCase() async {
    // `:816` — built ONCE per attempt and reused by the update body.
    final Map<String, Object?> payload = buildBirthFormData(
      state.form,
      clock,
      legalBasisText: readLegalBasisText(),
    );

    // 1. `:819-830` — the draft is created ONCE; a retry reuses
    //    `{id, reference_no}` so a rejected submission leaves no trail of
    //    half-filled cases.
    BirthDraftCase? current = state.draft;
    if (current == null) {
      final ApplicationDetail created = _orThrow(
        await createApplication(
          birthCreateEnvelope(
            form: state.form,
            payload: payload,
            clock: clock,
          ),
        ),
      );
      current = BirthDraftCase(
        id: created.row.id,
        referenceNo: created.row.referenceNo,
      );
      emit(state.copyWith(draft: current));
    }

    // 2. `:834-837` — runs on EVERY attempt including the first, because it is
    //    what writes `header.document_no`.
    final SubmissionBodies bound =
        birthBodiesFrom(payload, current.referenceNo);
    _orThrow(
      await updateApplication(
        UpdateApplicationParams(
          id: current.id,
          envelope: birthUpdateEnvelope(
            form: state.form,
            updatePayload: bound.update,
            clock: clock,
          ),
        ),
      ),
    );

    // 3. `:839-842` — **exactly one slot**, skipped when already sent. Not a
    //    list pipeline: Resident had five and this page has one.
    final PickedAttachment? file = birthAttachmentToSend(state.form);
    if (file != null && !_uploaded.contains(kBirthAttachmentSlot)) {
      _orThrow(
        await addAttachment(
          AddAttachmentParams(
            id: current.id,
            file: file,
            slot: kBirthAttachmentSlot,
            kind: kBirthAttachmentKind,
          ),
        ),
      );
      _uploaded.add(kBirthAttachmentSlot);
    }

    // 4. `:844` — and that is the end of it.
    return _orThrow(await submitApplication(current.id));
  }

  /// `:893-900` — `handlePay`, the **separate** mutation.
  ///
  /// Four behaviours transcribed rather than deferred (`specs.md` § 6.7):
  ///
  /// 1. Re-entry guard `if (!submitted || payCase.pending) return` (`:894`).
  /// 2. The receipt is `receipt_no ?? transaction?.receipt_no` (`:852`).
  /// 3. A failure renders `payCase.error.message` as a small red line above the
  ///    button (`:979-981`) and **does not** clear `submitted`, navigate, or
  ///    disable anything. The button stays tappable.
  /// 4. Once `receiptNo` is set, `unpaid` goes false: the button disappears and
  ///    the back-to-home button changes style in the same transition.
  Future<void> payNow() async {
    final ApplicationDetail? submitted = state.submitted;
    if (submitted == null || state.payPending) return;

    emit(state.copyWith(payPending: true, clearPayError: true));

    final BirthPayPort? port = pay;
    if (port == null) {
      // No capability wired. Honest failure, never a silent success.
      emit(
        state.copyWith(
          payPending: false,
          payError: 'The payment capability is not available.',
        ),
      );
      return;
    }

    final Either<Failure, Object?> result = await port(
      submitted.row.id,
      methodCode: birthMethodCode(state.methods.data ?? const <PaymentMethod>[]),
    );
    if (isClosed) return;

    result.fold(
      (Failure f) => emit(
        state.copyWith(payPending: false, payError: f.message),
      ),
      (Object? value) => emit(
        state.copyWith(
          payPending: false,
          receiptNo: birthReceiptOf(value),
        ),
      ),
    );
  }

  T _orThrow<T>(Either<Failure, T> result) => result.fold(
        (Failure f) => throw _asApiException(f),
        (T value) => value,
      );

  Object _asApiException(Failure f) =>
      f is ApiFailure ? f.exception : Exception(f.message);
}
