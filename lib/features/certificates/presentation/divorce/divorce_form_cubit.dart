/// `DivorceCertificatePage.tsx`'s state, in one [Cubit].
///
/// Structurally parallel to `marriage_form_cubit.dart` and **deliberately not
/// shared with it** — § 6.5's prohibition is about `spousePayload`, but the
/// reason generalises: the two pages' step machines are different shapes, and a
/// shared cubit would have to carry a flag for every difference. The reasoning
/// behind the ports, the D-I identity fix and the `PagingMode.firstPageOnly`
/// call is written out once, in Marriage's file; this one records only what
/// differs.
///
/// ## What differs
///
/// 1. **Step 1 is a two-armed machine with a terminal third state.**
///    [DivorceFormData.basis.divorceType] is compared against two string
///    literals; anything else renders only the select and cannot advance
///    (§ 6.7, `F3-AC-52`).
/// 2. **`resetMediation` carries D-N's fix** — see
///    `divorce_form_state.dart`'s `divorceResetMediation`.
/// 3. **The quote is unconditional at the source** — `catalog.quote("divorce",
///    {})` fires **once** (`:667`), against Marriage's re-firing conditional
///    one (`F3-AC-74`). Both pages now load once for the same *mechanical*
///    reason (`blocked.md` § 1 option (b) reads both fees off the service
///    catalogue) but only Divorce does so **faithfully**: this page's source
///    has no fee inputs to lose. Marriage's does, and gave them up — see
///    `marriage_form_cubit.dart`'s library doc. Do not read the two as one
///    decision.
/// 4. **No `GENDERS`** — `DivorceSpouseInfo` has no gender field and the form
///    renders no gender control (`F3-AC-68`).
library;

import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:dartz/dartz.dart' hide Option;

import '../../../../core/error/failure.dart';
import '../../../../i18n/i18n.dart';
import '../../../../presentation/payment/payment_draft.dart';
import '../../../application/domain/application_failures.dart';
import '../../../application/domain/entities/application_detail.dart';
import '../../../application/domain/entities/case_status.dart';
import '../../../application/domain/entities/picked_attachment.dart';
import '../../../reference/domain/entities/lookup_key.dart';
import '../../../reference/domain/entities/lookup_option.dart';
import '../../../reference/domain/entities/prerequisite_record.dart';
import '../../domain/submission/case_reference_binding.dart';
import '../../domain/submission/submission_clock.dart';
import '../certificate_forms/certificate_location_fields.dart';
import '../certificate_forms/certificate_location_value.dart';
import '../../../../presentation/forms/widgets/option.dart';
import '../certificate_forms/certificate_ref_list.dart';
import 'divorce_form_state.dart';
import 'divorce_payload.dart';

/// `catalog.quote("divorce", {})` — `:667`. **No parameters**: the body is
/// empty and the query's dependency array is `[]`, so it fires exactly once.
///
/// **What it is wired to is the `divorce` service-catalogue row**, not
/// `/services/divorce/quote` (`blocked.md` § 1 option (b),
/// `certificates_bloc_injection.dart`'s `divorceQuotePortFrom`). Unlike
/// Marriage's, that costs this page nothing observable: the source's own call
/// takes an empty body and never re-fires, and the recorded catalogue row is a
/// flat `fee_lak: 10000` with `fee_is_range: false`. The mechanism differs; the
/// output does not — the same shape F1 recorded for `residentServiceReader`.
typedef DivorceQuotePort = Future<Either<Failure, DivorceQuote>> Function();

typedef DivorcePayPort = Future<Either<Failure, Object?>> Function(
  String applicationId, {
  required String methodCode,
});

/// `GET /prerequisite-records?kind=mediation&search=…&per_page=20` — `:660`.
typedef DivorceRecordsPort = Future<Either<Failure, PrerequisiteRecordPage>>
    Function(String search);

typedef DivorceRecordPort = Future<Either<Failure, PrerequisiteRecord>> Function(
  String recordNo,
);

/// The fee and its itemisation.
///
/// **[lines] is empty under the catalogue-backed port** for the reason
/// `MarriageQuote` spells out: `:668-670` is
/// `quote.data?.breakdown ?? quote.data?.lines ?? []`, a catalogue row carries
/// no breakdown, and inventing one is the alternative this rejects.
class DivorceQuote {
  const DivorceQuote({required this.feeLak, required this.lines});

  final int feeLak;
  final List<DivorceQuoteLine> lines;
}

class DivorceQuoteLine {
  const DivorceQuoteLine({required this.label, required this.amountLak});

  final String label;
  final int amountLak;
}

class DivorceAsync<T> {
  const DivorceAsync({this.data, this.loading = false, this.error});

  const DivorceAsync.loading() : this(loading: true);

  final T? data;
  final bool loading;
  final String? error;
}

class DivorceSubmitted {
  const DivorceSubmitted({required this.decided, this.receiptNo});

  final ApplicationDetail decided;
  final String? receiptNo;
}

/// Three independent cascades: the header (rendered twice, once per arm, over
/// **one** piece of state) and the two spouses' addresses.
enum DivorceCascade { header, husband, wife }

class DivorceCascadeState {
  const DivorceCascadeState({
    this.districts = CertificateLocationLevel.empty,
    this.villages = CertificateLocationLevel.empty,
  });

  final CertificateLocationLevel districts;
  final CertificateLocationLevel villages;

  DivorceCascadeState copyWith({
    CertificateLocationLevel? districts,
    CertificateLocationLevel? villages,
  }) =>
      DivorceCascadeState(
        districts: districts ?? this.districts,
        villages: villages ?? this.villages,
      );
}

class DivorceFormViewState {
  const DivorceFormViewState({
    this.step = 1,
    this.showErrors = false,
    this.serverErrors = const <String, String>{},
    this.submitted,
    this.form = const DivorceFormData(),
    this.draftId = '',
    this.caseRef = '',
    this.attachmentsSent = false,
    this.uploadedIdentities = const <String>{},
    this.nationalities = CertificateRefList.loadingList,
    this.divorceTypes = CertificateRefList.loadingList,
    this.provinces = const CertificateLocationLevel(loading: true),
    this.cascades = const <DivorceCascade, DivorceCascadeState>{},
    this.recordSearch = '',
    this.records = const DivorceAsync<PrerequisiteRecordPage>(),
    this.openRecordError,
    this.quote = const DivorceAsync<DivorceQuote>.loading(),
    this.submitPending = false,
    this.submitError,
    this.scrollToErrorTick = 0,
  });

  final int step;
  final bool showErrors;
  final Map<String, String> serverErrors;
  final DivorceSubmitted? submitted;
  final DivorceFormData form;

  final String draftId;
  final String caseRef;
  final bool attachmentsSent;

  /// D-I's fix — see `marriage_form_cubit.dart`'s field of the same name.
  final Set<String> uploadedIdentities;

  final CertificateRefList nationalities;

  /// `/reference-lists/divorce-type`. `fsd.md` § 5.5 probed the live list on
  /// 2026-08-13 as exactly `{voluntary, contested}` (`F3-NV-6`); a third code
  /// arriving here is what makes [divorceIsTerminalType] reachable.
  final CertificateRefList divorceTypes;

  final CertificateLocationLevel provinces;
  final Map<DivorceCascade, DivorceCascadeState> cascades;

  final String recordSearch;
  final DivorceAsync<PrerequisiteRecordPage> records;
  final String? openRecordError;
  final DivorceAsync<DivorceQuote> quote;

  final bool submitPending;
  final String? submitError;
  final int scrollToErrorTick;

  DivorceCascadeState cascade(DivorceCascade which) =>
      cascades[which] ?? const DivorceCascadeState();

  DivorceFormViewState copyWith({
    int? step,
    bool? showErrors,
    Map<String, String>? serverErrors,
    DivorceSubmitted? submitted,
    DivorceFormData? form,
    String? draftId,
    String? caseRef,
    bool? attachmentsSent,
    Set<String>? uploadedIdentities,
    CertificateRefList? nationalities,
    CertificateRefList? divorceTypes,
    CertificateLocationLevel? provinces,
    Map<DivorceCascade, DivorceCascadeState>? cascades,
    String? recordSearch,
    DivorceAsync<PrerequisiteRecordPage>? records,
    String? openRecordError,
    bool clearOpenRecordError = false,
    DivorceAsync<DivorceQuote>? quote,
    bool? submitPending,
    String? submitError,
    bool clearSubmitError = false,
    int? scrollToErrorTick,
  }) =>
      DivorceFormViewState(
        step: step ?? this.step,
        showErrors: showErrors ?? this.showErrors,
        serverErrors: serverErrors ?? this.serverErrors,
        submitted: submitted ?? this.submitted,
        form: form ?? this.form,
        draftId: draftId ?? this.draftId,
        caseRef: caseRef ?? this.caseRef,
        attachmentsSent: attachmentsSent ?? this.attachmentsSent,
        uploadedIdentities: uploadedIdentities ?? this.uploadedIdentities,
        nationalities: nationalities ?? this.nationalities,
        divorceTypes: divorceTypes ?? this.divorceTypes,
        provinces: provinces ?? this.provinces,
        cascades: cascades ?? this.cascades,
        recordSearch: recordSearch ?? this.recordSearch,
        records: records ?? this.records,
        openRecordError: clearOpenRecordError
            ? null
            : (openRecordError ?? this.openRecordError),
        quote: quote ?? this.quote,
        submitPending: submitPending ?? this.submitPending,
        submitError: clearSubmitError ? null : (submitError ?? this.submitError),
        scrollToErrorTick: scrollToErrorTick ?? this.scrollToErrorTick,
      );
}

/// `:658` — `useDebounced(recordSearch, 300)`.
const Duration kDivorceRecordSearchDebounce = Duration(milliseconds: 300);

/// `:660` — `per_page: 20`.
const int kDivorceRecordsPerPage = 20;

class DivorceFormCubit extends Cubit<DivorceFormViewState> {
  DivorceFormCubit({
    required this.clock,
    required this.getLookupOptions,
    required this.createApplication,
    required this.updateApplication,
    required this.addAttachment,
    required this.submitApplication,
    required this.lang,
    this.loadQuote,
    this.pay,
    this.loadRecords,
    this.openRecord,
  }) : super(const DivorceFormViewState());

  final SubmissionClock clock;
  final Future<Either<Failure, List<LookupOption>>> Function(
    LookupKey key, {
    String? parentId,
    PagingMode paging,
  }) getLookupOptions;

  final Future<Either<Failure, ApplicationDetail>> Function(
    Map<String, Object?> body,
  ) createApplication;
  final Future<Either<Failure, ApplicationDetail>> Function(
    String id,
    Map<String, Object?> body,
  ) updateApplication;
  final Future<Either<Failure, Object?>> Function(
    String id,
    PickedAttachment file, {
    required String slot,
    required String kind,
    required String label,
  }) addAttachment;
  final Future<Either<Failure, ApplicationDetail>> Function(String id)
      submitApplication;

  final Lang lang;
  final DivorceQuotePort? loadQuote;
  final DivorcePayPort? pay;
  final DivorceRecordsPort? loadRecords;
  final DivorceRecordPort? openRecord;

  Timer? _searchDebounce;

  @override
  Future<void> close() {
    _searchDebounce?.cancel();
    return super.close();
  }

  /// `:653-655` + `:667` — two reference lists, the provinces, and the **one**
  /// quote call.
  ///
  /// **No `/payment-methods` request** (`F3-AC-66`).
  Future<void> load() async {
    await Future.wait<void>(<Future<void>>[
      _loadRef('nationality',
          (CertificateRefList l) => state.copyWith(nationalities: l)),
      _loadRef('divorce-type',
          (CertificateRefList l) => state.copyWith(divorceTypes: l)),
      _loadProvinces(),
    ]);
    await _loadQuoteOnce();
  }

  Future<void> _loadRef(
    String type,
    DivorceFormViewState Function(CertificateRefList) apply,
  ) async {
    final Either<Failure, List<LookupOption>> r =
        await getLookupOptions(LookupKey.reference(type));
    emit(apply(certificateRefListFrom(
      r.getOrElse(() => const <LookupOption>[]),
      lang,
    )));
  }

  Future<void> _loadProvinces() async {
    final Either<Failure, List<LookupOption>> r =
        await getLookupOptions(LookupKey.provinces);
    emit(state.copyWith(
      provinces: CertificateLocationLevel(
        options: certificateRefListFrom(
          r.getOrElse(() => const <LookupOption>[]),
          lang,
        ).options,
      ),
    ));
  }

  /// **Fires once.** `useQuery(() => catalog.quote("divorce", {}), [])` — an
  /// empty dependency array.
  ///
  /// `F3-AC-74`'s Divorce half — *"Divorce's fires once with an empty body"* —
  /// is met. Its Marriage half is not, deliberately (option (b)), so the two
  /// pages no longer differ here and the contrast that used to be the point of
  /// this comment is gone. What survives, and is asserted in
  /// `divorce_submit_path_test.dart`, is that this page's fee is inert under
  /// every form change — which for Divorce is faithful rather than a
  /// concession.
  Future<void> _loadQuoteOnce() async {
    final DivorceQuotePort? port = loadQuote;
    if (port == null) return;
    final Either<Failure, DivorceQuote> r = await port();
    emit(state.copyWith(
      quote: r.fold(
        (Failure f) => DivorceAsync<DivorceQuote>(error: f.message),
        (DivorceQuote q) => DivorceAsync<DivorceQuote>(data: q),
      ),
    ));
  }

  /// **`PagingMode.firstPageOnly` on villages** — RULING 2(iv). See
  /// `marriage_form_cubit.dart`'s `_loadChildren`.
  Future<void> _loadChildren(
    DivorceCascade which,
    CertificateLocationValue value,
    CertificateLocationValue previous,
  ) async {
    if (value.provinceId != previous.provinceId) {
      _setCascade(
        which,
        state.cascade(which).copyWith(
              districts: const CertificateLocationLevel(loading: true),
              villages: CertificateLocationLevel.empty,
            ),
      );
      if (value.provinceId.isEmpty) {
        _setCascade(which,
            const DivorceCascadeState(districts: CertificateLocationLevel.empty));
        return;
      }
      final Either<Failure, List<LookupOption>> r = await getLookupOptions(
        LookupKey.districts,
        parentId: value.provinceId,
      );
      _setCascade(
        which,
        state.cascade(which).copyWith(
              districts: CertificateLocationLevel(
                options: certificateRefListFrom(
                  r.getOrElse(() => const <LookupOption>[]),
                  lang,
                ).options,
              ),
            ),
      );
      return;
    }
    if (value.districtId != previous.districtId) {
      _setCascade(
        which,
        state.cascade(which).copyWith(
              villages: const CertificateLocationLevel(loading: true),
            ),
      );
      if (value.districtId.isEmpty) {
        _setCascade(which,
            state.cascade(which).copyWith(villages: CertificateLocationLevel.empty));
        return;
      }
      final Either<Failure, List<LookupOption>> r = await getLookupOptions(
        LookupKey.villages,
        parentId: value.districtId,
        paging: PagingMode.firstPageOnly,
      );
      _setCascade(
        which,
        state.cascade(which).copyWith(
              villages: CertificateLocationLevel(
                options: certificateRefListFrom(
                  r.getOrElse(() => const <LookupOption>[]),
                  lang,
                ).options,
              ),
            ),
      );
    }
  }

  void _setCascade(DivorceCascade which, DivorceCascadeState next) {
    emit(state.copyWith(
      cascades: <DivorceCascade, DivorceCascadeState>{
        ...state.cascades,
        which: next,
      },
    ));
  }

  // ── mutators ───────────────────────────────────────────────────────────────

  void setHeader(CertificateLocationValue v) {
    final CertificateLocationValue previous = state.form.header;
    emit(state.copyWith(form: state.form.copyWith(header: v)));
    unawaited(_loadChildren(DivorceCascade.header, v, previous));
  }

  void patchHusband(DivorceSpouseInfo Function(DivorceSpouseInfo) f) {
    final DivorceSpouseInfo previous = state.form.husband;
    final DivorceSpouseInfo next = f(previous);
    emit(state.copyWith(form: state.form.copyWith(husband: next)));
    if (next.address != previous.address) {
      unawaited(
        _loadChildren(DivorceCascade.husband, next.address, previous.address),
      );
    }
  }

  void patchWife(DivorceSpouseInfo Function(DivorceSpouseInfo) f) {
    final DivorceSpouseInfo previous = state.form.wife;
    final DivorceSpouseInfo next = f(previous);
    emit(state.copyWith(form: state.form.copyWith(wife: next)));
    if (next.address != previous.address) {
      unawaited(
        _loadChildren(DivorceCascade.wife, next.address, previous.address),
      );
    }
  }

  void patchBasis(DivorceBasis Function(DivorceBasis) f) =>
      emit(state.copyWith(form: state.form.copyWith(basis: f(state.form.basis))));

  void patchMediation(DivorceMediation Function(DivorceMediation) f) => emit(
      state.copyWith(form: state.form.copyWith(mediation: f(state.form.mediation))));

  void patchCourt(DivorceCourt Function(DivorceCourt) f) =>
      emit(state.copyWith(form: state.form.copyWith(court: f(state.form.court))));

  void patchChildren(DivorceChildren Function(DivorceChildren) f) => emit(
      state.copyWith(form: state.form.copyWith(children: f(state.form.children))));

  void patchPayment(PaymentDraft Function(PaymentDraft) f) =>
      emit(state.copyWith(form: state.form.copyWith(payment: f(state.form.payment))));

  void toggleHasChildren() => emit(state.copyWith(
      form: state.form.copyWith(hasChildren: !state.form.hasChildren)));

  void setCourtDecision(PickedAttachment? f) => emit(state.copyWith(
      form: state.form.copyWith(courtDecision: f, clearCourtDecision: f == null)));

  void setGuaranteeCert(PickedAttachment? f) => emit(state.copyWith(
      form: state.form.copyWith(guaranteeCert: f, clearGuaranteeCert: f == null)));

  void setHouseholdBook(PickedAttachment? f) => emit(state.copyWith(
      form: state.form.copyWith(householdBook: f, clearHouseholdBook: f == null)));

  void setPhotos(PickedAttachment? f) => emit(state.copyWith(
      form: state.form.copyWith(photos: f, clearPhotos: f == null)));

  /// `:1041` — `onChange={(v) => { patchBasis({divorceType: v}); resetMediation(); }}`.
  ///
  /// **Both, in that order, on every change**, including a change to a code
  /// that is neither literal. `divorceResetMediation` carries D-N's fix.
  void setDivorceType(String value) {
    emit(state.copyWith(
      form: divorceResetMediation(
        state.form.copyWith(basis: state.form.basis.copyWith(divorceType: value)),
      ),
      clearOpenRecordError: true,
    ));
  }

  void setMediationMode(DivorceMediationMode mode) {
    emit(state.copyWith(form: state.form.copyWith(mediationMode: mode)));
    if (mode == DivorceMediationMode.existing) unawaited(searchRecords(''));
  }

  /// `:1101` / `:1208` — the "back" affordance inside the voluntary arm. Runs
  /// the same reset, so it carries D-N's fix too.
  void resetMediation() => emit(state.copyWith(
        form: divorceResetMediation(state.form),
        clearOpenRecordError: true,
      ));

  /// `:1186` — "Change" on the linked summary. Clears the record only.
  void unlinkRecord() =>
      emit(state.copyWith(form: state.form.copyWith(clearLinkedRecord: true)));

  // ── the record picker ──────────────────────────────────────────────────────

  void setRecordSearch(String q) {
    emit(state.copyWith(recordSearch: q));
    _searchDebounce?.cancel();
    _searchDebounce = Timer(kDivorceRecordSearchDebounce, () {
      unawaited(searchRecords(q));
    });
  }

  Future<void> searchRecords(String search) async {
    if (state.form.mediationMode != DivorceMediationMode.existing ||
        state.form.linkedRecord != null) {
      return;
    }
    final DivorceRecordsPort? port = loadRecords;
    if (port == null) return;
    emit(state.copyWith(
      records: const DivorceAsync<PrerequisiteRecordPage>.loading(),
    ));
    final Either<Failure, PrerequisiteRecordPage> r = await port(search);
    emit(state.copyWith(
      records: r.fold(
        (Failure f) => DivorceAsync<PrerequisiteRecordPage>(error: f.message),
        (PrerequisiteRecordPage p) =>
            DivorceAsync<PrerequisiteRecordPage>(data: p),
      ),
    ));
  }

  /// `:702-729` — `selectExisting`. Pre-fills the header, both spouses, and
  /// **three mediation fields**, each with a `|| existing` fallback (`:720-725`)
  /// so a record that carries nothing does not blank what the citizen typed.
  Future<void> selectExisting(String recordNo) async {
    final DivorceRecordPort? port = openRecord;
    if (port == null) return;
    final Either<Failure, PrerequisiteRecord> r = await port(recordNo);
    r.fold(
      (Failure f) => emit(state.copyWith(openRecordError: f.message)),
      (PrerequisiteRecord record) => emit(state.copyWith(
        form: state.form.copyWith(linkedRecord: record),
        clearOpenRecordError: true,
      )),
    );
  }

  // ── navigation and submit ──────────────────────────────────────────────────

  void goBack() {
    emit(state.copyWith(showErrors: false));
    if (state.step > 1) emit(state.copyWith(step: state.step - 1));
  }

  Future<void> next() async {
    if (state.submitPending) return;
    if (!divorceCanProceed(state.form, step: state.step)) {
      emit(state.copyWith(
        showErrors: true,
        scrollToErrorTick: state.scrollToErrorTick + 1,
      ));
      return;
    }
    emit(state.copyWith(showErrors: false));
    if (state.step < kDivorceStepCount) {
      emit(state.copyWith(step: state.step + 1));
      return;
    }
    await submit();
  }

  /// `:848-887` — create → **attach → update** → submit → pay.
  Future<void> submit() async {
    emit(state.copyWith(
      submitPending: true,
      serverErrors: const <String, String>{},
      clearSubmitError: true,
    ));

    String id = state.draftId;
    String reference = state.caseRef;

    final SubmissionBodies bodies =
        divorceSubmissionBodies(state.form, clock, reference);

    if (id.isEmpty) {
      final Either<Failure, ApplicationDetail> created = await createApplication(
        divorceCreateEnvelope(form: state.form, payload: bodies.create),
      );
      final ApplicationDetail? draft = created.fold(
        (Failure f) {
          emit(state.copyWith(submitPending: false, submitError: f.message));
          return null;
        },
        (ApplicationDetail d) => d,
      );
      if (draft == null) return;
      id = draft.row.id;
      reference = draft.row.referenceNo;
      emit(state.copyWith(draftId: id, caseRef: reference));
    }

    final SubmissionBodies withRef =
        divorceSubmissionBodies(state.form, clock, reference);

    final List<DivorceAttachment> uploads = divorceUploads(state.form);
    final Set<String> identities =
        uploads.map(divorceAttachmentIdentity).toSet();
    final bool alreadySent = state.attachmentsSent &&
        _sameIdentities(state.uploadedIdentities, identities);

    if (!alreadySent) {
      for (final DivorceAttachment item in uploads) {
        final Either<Failure, Object?> r = await addAttachment(
          id,
          item.file,
          slot: item.slot,
          kind: item.kind,
          label: item.label,
        );
        final Failure? failure = r.fold((Failure f) => f, (_) => null);
        if (failure != null) {
          emit(state.copyWith(submitPending: false, submitError: failure.message));
          return;
        }
      }
      emit(state.copyWith(attachmentsSent: true, uploadedIdentities: identities));
    }

    final Either<Failure, ApplicationDetail> updated = await updateApplication(
      id,
      divorceUpdateEnvelope(form: state.form, updatePayload: withRef.update),
    );
    final Failure? updateFailure = updated.fold((Failure f) => f, (_) => null);
    if (updateFailure != null) {
      _fail(updateFailure);
      return;
    }

    final Either<Failure, ApplicationDetail> submittedCase =
        await submitApplication(id);
    final ApplicationDetail? decided = submittedCase.fold(
      (Failure f) {
        _fail(f);
        return null;
      },
      (ApplicationDetail d) => d,
    );
    if (decided == null) return;

    String? receipt;
    if (decided.row.feeLak > 0 &&
        decided.row.paymentState != PaymentState.paid) {
      final DivorcePayPort? port = pay;
      if (port != null) {
        final Either<Failure, Object?> paid = await port(
          id,
          methodCode: divorceMethodCodeFor(state.form.payment.method),
        );
        final Failure? payFailure = paid.fold((Failure f) => f, (_) => null);
        if (payFailure != null) {
          _fail(payFailure);
          return;
        }
        receipt = divorceReceiptOf(paid.getOrElse(() => null));
      }
    }

    emit(state.copyWith(
      submitPending: false,
      submitted: DivorceSubmitted(decided: decided, receiptNo: receipt),
    ));
  }

  /// D-G REPRODUCED — the messages land on the fields and **the step does not
  /// change** (`F3-AC-70`…`72`). No `step:` below, and that absence is the
  /// criterion.
  void _fail(Failure f) {
    final Map<String, String> fields = divorceFieldErrorsOf(f);
    emit(state.copyWith(
      submitPending: false,
      serverErrors: fields,
      submitError: fields.isEmpty ? f.message : null,
      clearSubmitError: fields.isNotEmpty,
      showErrors: fields.isNotEmpty ? true : state.showErrors,
      scrollToErrorTick: fields.isNotEmpty
          ? state.scrollToErrorTick + 1
          : state.scrollToErrorTick,
    ));
  }

  static bool _sameIdentities(Set<String> a, Set<String> b) =>
      a.length == b.length && a.containsAll(b);
}

/// D-I's identity — slot, label, filename and byte length.
String divorceAttachmentIdentity(DivorceAttachment a) =>
    '${a.slot}|${a.label}|${a.file.name}|${a.file.bytes?.length ?? -1}';

Map<String, String> divorceFieldErrorsOf(Failure f) {
  if (f is ApiFailure && f.isValidation) return f.exception.fieldMap();
  return const <String, String>{};
}

String? divorceReceiptOf(Object? result) {
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

/// `labelFor(list, value)` — `DivorceCertificatePage.tsx:170-171`.
///
/// **Divorce-only, and it lives here rather than in `certificate_forms/`.**
/// Finding K's eleven do not include it, and § 6.2 admits into the shared
/// directory only what Finding K measured as duplicated *and* semantically
/// identical. Marriage spells the same lookup inline at `:1551` / `:1559` with
/// a different fallback (`|| t("dash")` against this `?? ""`), so the two are
/// two call sites reading one list, not one helper with a parameter.
String divorceLabelFor(CertificateRefList list, String value) {
  for (final Option o in list.options) {
    if (o.value == value) return o.label;
  }
  return '';
}
