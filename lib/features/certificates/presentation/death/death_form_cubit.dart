/// `DeathDeclarationPage.tsx:685-924` — the page's state machine.
///
/// ## Pay is a separate mutation, as it is on Birth and unlike Resident
///
/// `submitCase` ends at `submit` (`:868`); `payCase` (`:871-877`) is fired by a
/// button on the success screen (`:1005-1014`), gated on
/// `submitted.fee_lak > 0 && !receiptNo` (`:961`). **`PaymentSection` is not
/// mounted** — no draft payment, no `LAO_BANKS`, no card mask, no payment step.
/// Step 6 is Review (`F2-AC-51`).
///
/// ## No shared base class with `BirthFormCubit`
///
/// `F2-AC-10`. The two look alike and are not the same: eight reference lists
/// against ten, a 41-entry `FIELD_STEP` against 46, **two** independent skip
/// flags against one, and a `canProceed` that differs in every arm — steps 3
/// and 4 are `skip || fullName.trim()` where Birth's are an eight-field
/// `parentValid`.
library;

import 'package:bloc/bloc.dart';
// `Option` is hidden: dartz exports one and so does the forms kernel, and
// this file needs the kernel's to build a `LocationLevel`.
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
import '../../domain/submission/certificate_form.dart';
import '../../domain/submission/submission_executor.dart';
import '../../domain/submission/submission_plan.dart';
import '../../domain/submission/submission_clock.dart';
import 'death_form_state.dart';
import 'death_payload.dart';

/// The pay call, as this page needs it. See `BirthPayPort`'s note on why there
/// are three of these and not one.
typedef DeathPayPort = Future<Either<Failure, Object?>> Function(
  String applicationId, {
  required String methodCode,
});

/// `:761` — `draft`.
class DeathDraftCase {
  const DeathDraftCase({required this.id, required this.referenceNo});
  final String id;
  final String referenceNo;
}

class DeathAsync<T> {
  const DeathAsync({this.data, this.loading = false, this.error});
  const DeathAsync.loading() : this(loading: true);

  final T? data;
  final bool loading;
  final String? error;
}

class DeathLocationLevel {
  const DeathLocationLevel({
    this.rows = const <LookupOption>[],
    this.busy = false,
    this.failed = false,
  });
  final List<LookupOption> rows;
  final bool busy;
  final bool failed;
}

/// The eight reference lists `useRefLists()` loads (`:253-264`).
///
/// **Eight, against Birth's ten.** Death carries `cause` and has no `blood`,
/// `delivery` or `birthType`.
enum DeathRefList {
  ethnicity('ethnicity'),
  nationality('nationality'),
  ethnicGroup('ethnic-group'),
  religion('religion'),
  education('education-level'),
  marital('marital-status'),
  relation('relation'),
  cause('cause-of-death');

  const DeathRefList(this.type);

  /// The `/reference/{type}` path segment, verbatim from `:255-262`.
  final String type;

  LookupKey get key => LookupKey.reference(type);
}

class DeathFormViewState {
  const DeathFormViewState({
    this.step = 1,
    this.showErrors = false,
    this.serverErrors = const <String, String>{},
    this.submitted,
    this.receiptNo,
    this.form = const DeathFormData(),
    this.draft,
    this.service = const DeathAsync<Service>(),
    this.methods = const DeathAsync<List<PaymentMethod>>(),
    this.refs = const <DeathRefList, DeathAsync<List<LookupOption>>>{},
    this.headerNames = const <String, String>{},
    this.podNames = const <String, String>{},
    this.provinces = const DeathLocationLevel(),
    this.districts = const DeathLocationLevel(),
    this.villages = const DeathLocationLevel(),
    this.submitPending = false,
    this.submitError,
    this.payPending = false,
    this.payError,
    this.scrollToErrorTick = 0,
  });

  final int step;
  final bool showErrors;
  final Map<String, String> serverErrors;
  final ApplicationDetail? submitted;
  final String? receiptNo;
  final DeathFormData form;
  final DeathDraftCase? draft;
  final DeathAsync<Service> service;
  final DeathAsync<List<PaymentMethod>> methods;
  final Map<DeathRefList, DeathAsync<List<LookupOption>>> refs;

  /// `:703-704` — `headerNames` and **`podNames`** (place of *death*; Birth's
  /// second set is `pobNames`, place of *birth*).
  final Map<String, String> headerNames;
  final Map<String, String> podNames;

  final DeathLocationLevel provinces;
  final DeathLocationLevel districts;
  final DeathLocationLevel villages;
  final bool submitPending;
  final String? submitError;
  final bool payPending;
  final String? payError;
  final int scrollToErrorTick;

  bool get isLastStep => step == kDeathStepCount;
  bool get showsServiceLoading => service.loading && service.data == null;
  bool get showsServiceError => service.error != null && service.data == null;

  /// `:961` — `submitted.fee_lak > 0 && !receiptNo`.
  bool get unpaid =>
      submitted != null && submitted!.row.feeLak > 0 && receiptNo == null;

  DeathFormViewState copyWith({
    int? step,
    bool? showErrors,
    Map<String, String>? serverErrors,
    ApplicationDetail? submitted,
    String? receiptNo,
    DeathFormData? form,
    DeathDraftCase? draft,
    DeathAsync<Service>? service,
    DeathAsync<List<PaymentMethod>>? methods,
    Map<DeathRefList, DeathAsync<List<LookupOption>>>? refs,
    Map<String, String>? headerNames,
    Map<String, String>? podNames,
    DeathLocationLevel? provinces,
    DeathLocationLevel? districts,
    DeathLocationLevel? villages,
    bool? submitPending,
    String? submitError,
    bool clearSubmitError = false,
    bool? payPending,
    String? payError,
    bool clearPayError = false,
    int? scrollToErrorTick,
  }) =>
      DeathFormViewState(
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
        podNames: podNames ?? this.podNames,
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

class DeathFormCubit extends Cubit<DeathFormViewState> {
  DeathFormCubit({
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
  }) : super(const DeathFormViewState());

  final SubmissionClock clock;
  final GetLookupOptions getLookupOptions;
  final CreateApplication createApplication;
  final UpdateApplication updateApplication;
  final AddAttachment addAttachment;
  final SubmitApplication submitApplication;
  final Future<Either<Failure, Service>> Function() loadService;
  final Future<Either<Failure, List<PaymentMethod>>> Function()
      loadPaymentMethods;

  /// `t("legalBasisText")` against the **`death`** namespace (`:789`).
  ///
  /// Its English is byte-identical to Birth's and its **Lao is not**. Injected
  /// per page for exactly that reason: a shared constant would be byte-correct
  /// in English and byte-wrong in Lao on all twenty documents (`F2-AC-36`).
  ///
  /// A function rather than a String so the value is read **at submit**, as
  /// `useT("death")` is (`:686`) — see `BirthFormCubit.readLegalBasisText` for
  /// why freezing it at construction would be an L-10 divergence.
  final String Function() readLegalBasisText;

  final DeathPayPort? pay;
  final Lang lang;

  /// `:762` — `uploaded = useRef<Set<string>>(new Set())`.
  ///
  /// B4 moved the set into [AttachmentLedger] so the executor can honour
  /// `plan.attachmentGuard`. Still keyed on the **slot** — D-I is not fixed
  /// here (`submission_executor.dart`'s [AttachmentLedger]).
  final AttachmentLedger _ledger = AttachmentLedger();
  Set<String> get uploadedSlots => _ledger.sentSlots;

  /// The four write use cases as the executor's ports. Built here rather than
  /// injected — see `resident_form_cubit.dart`'s `_executor` for why.
  SubmissionExecutor get _executor => SubmissionExecutor(
        createCase: createApplication.call,
        updateCase: (String id, Map<String, Object?> envelope) =>
            updateApplication(
          UpdateApplicationParams(id: id, envelope: envelope),
        ),
        attachToCase: (String id, SubmissionAttachment a) => addAttachment(
          AddAttachmentParams(
            id: id,
            file: a.file,
            slot: a.slot,
            kind: a.kind,
            label: a.label,
          ),
        ),
        submitCase: submitApplication.call,
      );

  Future<void> load() async {
    await Future.wait<void>(<Future<void>>[
      refetchService(),
      loadMethods(),
      for (final DeathRefList r in DeathRefList.values) loadReference(r),
    ]);
  }

  Future<void> refetchService() async {
    emit(state.copyWith(service: const DeathAsync<Service>.loading()));
    final Either<Failure, Service> result = await loadService();
    if (isClosed) return;
    emit(
      state.copyWith(
        service: result.fold(
          (Failure f) => DeathAsync<Service>(error: f.message),
          (Service s) => DeathAsync<Service>(data: s),
        ),
      ),
    );
  }

  Future<void> loadMethods() async {
    emit(state.copyWith(methods: const DeathAsync<List<PaymentMethod>>.loading()));
    final Either<Failure, List<PaymentMethod>> result =
        await loadPaymentMethods();
    if (isClosed) return;
    emit(
      state.copyWith(
        methods: result.fold(
          (Failure f) => DeathAsync<List<PaymentMethod>>(error: f.message),
          (List<PaymentMethod> rows) =>
              DeathAsync<List<PaymentMethod>>(data: rows),
        ),
      ),
    );
  }

  Future<void> loadReference(DeathRefList which) async {
    emit(
      state.copyWith(
        refs: <DeathRefList, DeathAsync<List<LookupOption>>>{
          ...state.refs,
          which: const DeathAsync<List<LookupOption>>.loading(),
        },
      ),
    );
    final Either<Failure, List<LookupOption>> result =
        await getLookupOptions(which.key);
    if (isClosed) return;
    emit(
      state.copyWith(
        refs: <DeathRefList, DeathAsync<List<LookupOption>>>{
          ...state.refs,
          which: result.fold(
            (Failure f) => DeathAsync<List<LookupOption>>(error: f.message),
            (List<LookupOption> rows) =>
                DeathAsync<List<LookupOption>>(data: rows),
          ),
        },
      ),
    );
  }

  ReferenceFieldState referenceStateOf(DeathRefList which) {
    final DeathAsync<List<LookupOption>> q =
        state.refs[which] ?? const DeathAsync<List<LookupOption>>();
    return referenceFieldStateFrom(
      q.data ?? const <LookupOption>[],
      lang: lang,
      loading: q.loading,
      failed: q.error != null,
      retry: q.error != null ? () => loadReference(which) : null,
    );
  }

  Future<void> loadProvinces() async {
    emit(state.copyWith(provinces: const DeathLocationLevel(busy: true)));
    final Either<Failure, List<LookupOption>> r =
        await getLookupOptions(LookupKey.provinces);
    if (isClosed) return;
    emit(state.copyWith(provinces: _levelFrom(r)));
  }

  Future<void> loadDistricts(String provinceId) async {
    emit(state.copyWith(districts: const DeathLocationLevel(busy: true)));
    final Either<Failure, List<LookupOption>> r =
        await getLookupOptions(LookupKey.districts);
    if (isClosed) return;
    emit(state.copyWith(districts: _levelFrom(r)));
  }

  Future<void> loadVillages(String districtId) async {
    emit(state.copyWith(villages: const DeathLocationLevel(busy: true)));
    final Either<Failure, List<LookupOption>> r =
        await getLookupOptions(LookupKey.villages);
    if (isClosed) return;
    emit(state.copyWith(villages: _levelFrom(r)));
  }

  DeathLocationLevel _levelFrom(Either<Failure, List<LookupOption>> r) =>
      r.fold(
        (Failure _) => const DeathLocationLevel(failed: true),
        (List<LookupOption> rows) => DeathLocationLevel(rows: rows),
      );

  /// One level as the kernel's parameter object.
  ///
  /// Built here so no widget ever sees a [LookupOption] (G-L5, `F0-AC-77`).
  /// The rows are passed **raw**: `visibleRows`' stale-row rule lives inside
  /// the kernel where Tier 1 can see it.
  LocationLevel locationLevel(
    DeathLocationLevel level,
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

  void setField(DeathFormData Function(DeathFormData) edit, {String? path}) {
    emit(state.copyWith(form: edit(state.form)));
    clearServerError(path);
  }

  void patchDeceased(
    DeathDeceasedInfo Function(DeathDeceasedInfo) edit, {
    String? path,
  }) =>
      setField((DeathFormData f) => f.copyWith(deceased: edit(f.deceased)),
          path: path);

  void patchMother(
    DeathParentInfo Function(DeathParentInfo) edit, {
    String? path,
  }) =>
      setField((DeathFormData f) => f.copyWith(mother: edit(f.mother)),
          path: path);

  void patchFather(
    DeathParentInfo Function(DeathParentInfo) edit, {
    String? path,
  }) =>
      setField((DeathFormData f) => f.copyWith(father: edit(f.father)),
          path: path);

  void patchInformant(
    DeathInformantInfo Function(DeathInformantInfo) edit, {
    String? path,
  }) =>
      setField((DeathFormData f) => f.copyWith(informant: edit(f.informant)),
          path: path);

  /// `:1324` / `:1338` — the **two independent** toggles.
  ///
  /// Neither clears its record, so toggling back restores what was typed
  /// (`F2-AC-69`). `motherSkip` collapses **two** payload prefixes because the
  /// mother is emitted under both `parents` and `parents.mother`.
  void toggleMotherSkip() => emit(
        state.copyWith(
          form: state.form.copyWith(motherSkip: !state.form.motherSkip),
        ),
      );

  void toggleFatherSkip() => emit(
        state.copyWith(
          form: state.form.copyWith(fatherSkip: !state.form.fatherSkip),
        ),
      );

  void setDeathNotice(PickedAttachment? file) {
    emit(
      state.copyWith(
        form: file == null
            ? state.form.copyWith(clearDeathNotice: true)
            : state.form.copyWith(deathNotice: file),
      ),
    );
    if (file != null) clearServerError('deceased.death_notice');
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

  void setHeaderNames(Map<String, String> names) =>
      emit(state.copyWith(headerNames: names));

  void setPodNames(Map<String, String> names) =>
      emit(state.copyWith(podNames: names));

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

  bool get canProceed => deathCanProceed(state.form, state.step);

  /// `:879-883` — `goBack`.
  bool goBack() {
    emit(state.copyWith(showErrors: false));
    if (state.step > 1) {
      emit(state.copyWith(step: state.step - 1));
      return false;
    }
    return true;
  }

  /// `:885-915` — `handleNext`.
  Future<void> next() async {
    if (state.submitPending) return;

    if (!canProceed) {
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
      emit(state.copyWith(submitPending: false, submitError: e.toString()));
    }
  }

  /// `:904-914` — the catch, with no `else`.
  ///
  /// **No `parents.father.*` key is mapped** in `kDeathFieldStep`, so a 422
  /// about the father sets the errors, runs the scroll, and leaves the step
  /// index alone (`F2-AC-63`).
  void _onSubmitFailed(ApiException e) {
    final Map<String, String> fields = e.fieldMap();
    if (e.isValidation && fields.isNotEmpty) {
      final int? target = stepOfFirstError(
        fields.keys.toList(growable: false),
        kDeathFieldStep,
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

  /// `:839-869` — `submitCase`, executed by [SubmissionExecutor] (B4 § 6.5).
  ///
  /// Ends at submit: `SubmissionPlan.forForm(CertificateForm.death).steps`
  /// omits `SubmissionStep.pay` because `:871-877` fires `payCase` from the
  /// review step instead. No `charge` port is passed. `death.golden.json`
  /// records the absence of a `/pay` entry (`B4-AC-19`'s Death half).
  Future<ApplicationDetail> _submitCase() async {
    final DeathDraftCase? held = state.draft;
    try {
      final SubmissionOutcome outcome = await _executor.run(
        plan: SubmissionPlan.forForm(CertificateForm.death),
        buildFormData: (String _) => buildDeathFormData(
          state.form,
          clock,
          legalBasisText: readLegalBasisText(),
        ),
        // `:844-851`.
        createEnvelope: (Map<String, Object?> payload) => deathCreateEnvelope(
          form: state.form,
          payload: payload,
          clock: clock,
        ),
        // `:858-861` — `form_data` FIRST.
        updateEnvelope: (Map<String, Object?> updatePayload) =>
            deathUpdateEnvelope(
          form: state.form,
          updatePayload: updatePayload,
          clock: clock,
        ),
        // `:863-866` — one slot.
        attachments: <SubmissionAttachment>[
          if (deathAttachmentToSend(state.form) case final PickedAttachment f)
            SubmissionAttachment(
              file: f,
              slot: kDeathAttachmentSlot,
              kind: kDeathAttachmentKind,
            ),
        ],
        ledger: _ledger,
        held: held == null
            ? null
            : SubmissionDraft(id: held.id, referenceNo: held.referenceNo),
        onDraftCreated: (SubmissionDraft d) => emit(
          state.copyWith(
            draft: DeathDraftCase(id: d.id, referenceNo: d.referenceNo),
          ),
        ),
      );
      return outcome.decided;
    } on SubmissionStepFailure catch (e) {
      throw _asApiException(e.failure);
    }
  }

  /// `:917-924` — `handlePay`, the separate mutation.
  Future<void> payNow() async {
    final ApplicationDetail? submitted = state.submitted;
    if (submitted == null || state.payPending) return;

    emit(state.copyWith(payPending: true, clearPayError: true));

    final DeathPayPort? port = pay;
    if (port == null) {
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
      methodCode: deathMethodCode(state.methods.data ?? const <PaymentMethod>[]),
    );
    if (isClosed) return;

    result.fold(
      (Failure f) => emit(
        state.copyWith(payPending: false, payError: f.message),
      ),
      (Object? value) => emit(
        state.copyWith(
          payPending: false,
          receiptNo: deathReceiptOf(value),
        ),
      ),
    );
  }

  // `_orThrow` was here. B4 moved the Either-to-throw bridge into
  // `SubmissionExecutor._orThrow`; `_asApiException` stays because it is what
  // turns the executor's `SubmissionStepFailure` back into the shape `next()`
  // already catches.

  Object _asApiException(Failure f) =>
      f is ApiFailure ? f.exception : Exception(f.message);
}
