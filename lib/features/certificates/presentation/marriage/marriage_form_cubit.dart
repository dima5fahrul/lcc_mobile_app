/// `MarriageCertificatePage.tsx`'s state — every `useState`, `useQuery` and
/// `useMutation` on the page, in one [Cubit].
///
/// A [Cubit] rather than a [Bloc], for the reason `resident_form_cubit.dart`
/// gives: the source is eighteen `useState` calls and four queries, and each
/// transition has exactly one caller.
///
/// ## Every dependency is an injected function
///
/// No locator is resolved here and none in the widget tree (G-L5), which is
/// what lets `F3-AC-12` pump every `certificate_forms/` widget with the DI
/// container completely uninitialised.
///
/// ## Two ports, both closed at the DI boundary — and one carries a divergence
///
/// * **[pay]** is B6b's `PayApplication` adapted at the DI boundary, exactly as
///   F1 does it (`certificates_bloc_injection.dart`'s `residentPayPortFrom`).
///   That is the sanctioned shape.
///
/// * **[loadQuote]** is the **service catalogue**, not
///   `/services/marriage/quote`, and that is an **accepted, citizen-visible
///   divergence** — `blocked.md` § 1 option (b), approved by the human on
///   2026-08-18. It is not a deferral, not a stub and not an unwired seam;
///   an earlier revision of this file said it was and that text was wrong.
///
///   The web POSTs `/services/marriage/quote` with `{has_foreign_spouse,
///   creates_betrothal_record}` (`:766-774`) and re-reads it whenever either
///   input changes. F3 has no in-scope home for that datasource
///   (`features/service/**` is not in § 3.1; row 8 scopes
///   `features/reference/**` to `/prerequisite-records`), so the fee is read
///   off the `marriage` row of `GET /services` through the same reader F1 uses
///   for Resident, and is therefore **static**.
///
///   **What the citizen sees differently.** The web quotes a marriage with a
///   foreign spouse, or one that creates a betrothal record, at a *higher*
///   price than a plain domestic one. This port cannot: it answers one number
///   for every form state. And the number it answers is the **bottom of the
///   catalogue's declared range** — the recorded `marriage` row is
///   `fee_lak: 100000`, `fee_max_lak: 250000`, `fee_is_range: true`, which is
///   the catalogue's own way of saying this service's price is not a constant.
///   So the citizen is shown the cheapest of the prices this service can carry,
///   on a form where the source would have resolved which one applies.
///   Measured, not asserted: `test/features/certificates/di/
///   certificate_quote_port_test.dart` reads those three values out of the
///   recorded catalogue and goes red if they change.
///
///   **The static property is structural, not a convention.**
///   [MarriageQuotePort] takes **no parameters**, so no implementation of it
///   can see `has_foreign_spouse` or `creates_betrothal_record`, and the cubit
///   invokes it exactly once, from [load]. Restoring either the inputs or the
///   re-fire is a compile error or a red test, not something a reviewer has to
///   notice (`marriage_static_fee_test.dart`).
///
///   `F3-AC-74`'s first half — *"Marriage's quote re-fires when either
///   `has_foreign_spouse` or `creates_betrothal_record` changes, and only
///   then"* — is therefore **deliberately not met**. Do not restore it without
///   reopening `blocked.md` § 1.
library;

import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:dartz/dartz.dart';

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
import '../../domain/submission/certificate_form.dart';
import '../../domain/submission/submission_clock.dart';
import '../../domain/submission/submission_executor.dart';
import '../../domain/submission/submission_plan.dart';
import '../../domain/submission/submission_step.dart';
import '../certificate_forms/certificate_location_fields.dart';
import '../certificate_forms/certificate_location_value.dart';
import '../certificate_forms/certificate_ref_list.dart';
import 'marriage_form_state.dart';
import 'marriage_payload.dart';

/// The fee, read **once**, with **no inputs**.
///
/// This is deliberately *not* `catalog.quote("marriage", {has_foreign_spouse,
/// creates_betrothal_record})` (`:766-774`), which is what the signature used
/// to mirror. Under `blocked.md` § 1 option (b) the fee is the `marriage`
/// catalogue row, so the two inputs have nowhere to go — and they are
/// **removed rather than accepted-and-ignored**. A port that still took them
/// would let a later implementation quietly make the fee vary again, and the
/// approved decision is precisely that it must not be able to. See the library
/// doc above for the citizen-visible cost of that.
typedef MarriageQuotePort = Future<Either<Failure, MarriageQuote>> Function();

/// B6b's `PayApplication`, adapted. `Object?` and not `PaymentResult`, so this
/// tree contains no reference to a type B6b owns.
typedef MarriagePayPort = Future<Either<Failure, Object?>> Function(
  String applicationId, {
  required String methodCode,
});

/// `GET /prerequisite-records?kind=betrothal&search=…&per_page=20` — `:754`.
typedef MarriageRecordsPort = Future<Either<Failure, PrerequisiteRecordPage>>
    Function(String search);

/// `GET /prerequisite-records/{no}` — `:758`.
typedef MarriageRecordPort = Future<Either<Failure, PrerequisiteRecord>>
    Function(String recordNo);

/// `:775-781` — the fee and its itemisation, as the review card reads them.
///
/// **[lines] is empty under the catalogue-backed port, and that is not a
/// stub.** `:776-777` reads `quote.data?.breakdown ?? quote.data?.lines ?? []`,
/// so "a total with no itemised rows" is a state the *source* renders whenever
/// its quote response carries neither key. A catalogue row has one `fee_lak`
/// and no breakdown at all, so that is the state option (b) pins this page to.
///
/// The field is kept rather than deleted because the shape is the source's and
/// a real quote slice would fill it — and because the honest alternative to an
/// empty list is not a shorter class, it is inventing line items the catalogue
/// does not carry.
class MarriageQuote {
  const MarriageQuote({required this.feeLak, required this.lines});

  final int feeLak;
  final List<MarriageQuoteLine> lines;
}

class MarriageQuoteLine {
  const MarriageQuoteLine({required this.label, required this.amountLak});

  final String label;
  final int amountLak;
}

/// One `useQuery`'s three observable states.
class MarriageAsync<T> {
  const MarriageAsync({this.data, this.loading = false, this.error});

  const MarriageAsync.loading() : this(loading: true);

  final T? data;
  final bool loading;
  final String? error;
}

/// `:1032` — the success card's inputs.
class MarriageSubmitted {
  const MarriageSubmitted({required this.decided, this.receiptNo});

  final ApplicationDetail decided;
  final String? receiptNo;
}

/// Which of the three cascades a location event belongs to.
///
/// The page mounts `ApiLocationFields` **three times** — the header (`:1312`),
/// spouse A's address and spouse B's address (`:527`, twice) — and each has its
/// own district and village queries keyed by its own parent. One shared
/// district list would make picking a province for spouse A change spouse B's
/// options.
enum MarriageCascade { header, spouseA, spouseB }

/// The three levels of one cascade.
class MarriageCascadeState {
  const MarriageCascadeState({
    this.districts = CertificateLocationLevel.empty,
    this.villages = CertificateLocationLevel.empty,
  });

  final CertificateLocationLevel districts;
  final CertificateLocationLevel villages;

  MarriageCascadeState copyWith({
    CertificateLocationLevel? districts,
    CertificateLocationLevel? villages,
  }) =>
      MarriageCascadeState(
        districts: districts ?? this.districts,
        villages: villages ?? this.villages,
      );
}

class MarriageFormViewState {
  const MarriageFormViewState({
    this.step = 1,
    this.showErrors = false,
    this.serverErrors = const <String, String>{},
    this.submitted,
    this.form = const MarriageFormData(),
    this.draftId = '',
    this.caseRef = '',
    this.attachmentsSent = false,
    this.uploadedIdentities = const <String>{},
    this.nationalities = CertificateRefList.loadingList,
    this.ethnicities = CertificateRefList.loadingList,
    this.ethnicGroups = CertificateRefList.loadingList,
    this.religions = CertificateRefList.loadingList,
    this.provinces = const CertificateLocationLevel(loading: true),
    this.cascades = const <MarriageCascade, MarriageCascadeState>{},
    this.recordSearch = '',
    this.records = const MarriageAsync<PrerequisiteRecordPage>(),
    this.openRecordError,
    this.quote = const MarriageAsync<MarriageQuote>.loading(),
    this.submitPending = false,
    this.submitError,
    this.scrollToErrorTick = 0,
  });

  final int step;
  final bool showErrors;
  final Map<String, String> serverErrors;
  final MarriageSubmitted? submitted;
  final MarriageFormData form;

  /// `:712-714` — kept so a retry never duplicates the draft (`:956`
  /// `if (!id)`).
  final String draftId;
  final String caseRef;
  final bool attachmentsSent;

  /// **D-I's fix.** `attachmentsSent` alone is `AttachmentGuard.singleFlag` and
  /// carries the defect one level up: a citizen who replaces a document after a
  /// failed submit never gets the new one uploaded. F0's stated fix contract is
  /// *key on file identity, not on slot*
  /// (`attachment_guard.dart:32-35`), and for a single flag the correct
  /// expression is: the flag is invalidated whenever the identity of any file
  /// in `uploads()` changes. This set is that identity, snapshotted at the
  /// moment the flag was raised. Tier-0-invisible — no `form_data` key moves
  /// (`F3-AC-60`, `F3-AC-62`).
  final Set<String> uploadedIdentities;

  final CertificateRefList nationalities;
  final CertificateRefList ethnicities;
  final CertificateRefList ethnicGroups;
  final CertificateRefList religions;

  /// Shared by all three cascades — `locations.provinces()` takes no parent.
  final CertificateLocationLevel provinces;
  final Map<MarriageCascade, MarriageCascadeState> cascades;

  final String recordSearch;
  final MarriageAsync<PrerequisiteRecordPage> records;
  final String? openRecordError;
  final MarriageAsync<MarriageQuote> quote;

  final bool submitPending;
  final String? submitError;

  /// Bumped when `scrollToFirstError()` fires (`:1004`), so the view can react
  /// without the cubit knowing about widgets.
  final int scrollToErrorTick;

  MarriageCascadeState cascade(MarriageCascade which) =>
      cascades[which] ?? const MarriageCascadeState();

  MarriageFormViewState copyWith({
    int? step,
    bool? showErrors,
    Map<String, String>? serverErrors,
    MarriageSubmitted? submitted,
    MarriageFormData? form,
    String? draftId,
    String? caseRef,
    bool? attachmentsSent,
    Set<String>? uploadedIdentities,
    CertificateRefList? nationalities,
    CertificateRefList? ethnicities,
    CertificateRefList? ethnicGroups,
    CertificateRefList? religions,
    CertificateLocationLevel? provinces,
    Map<MarriageCascade, MarriageCascadeState>? cascades,
    String? recordSearch,
    MarriageAsync<PrerequisiteRecordPage>? records,
    String? openRecordError,
    bool clearOpenRecordError = false,
    MarriageAsync<MarriageQuote>? quote,
    bool? submitPending,
    String? submitError,
    bool clearSubmitError = false,
    int? scrollToErrorTick,
  }) =>
      MarriageFormViewState(
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
        ethnicities: ethnicities ?? this.ethnicities,
        ethnicGroups: ethnicGroups ?? this.ethnicGroups,
        religions: religions ?? this.religions,
        provinces: provinces ?? this.provinces,
        cascades: cascades ?? this.cascades,
        recordSearch: recordSearch ?? this.recordSearch,
        records: records ?? this.records,
        openRecordError:
            clearOpenRecordError ? null : (openRecordError ?? this.openRecordError),
        quote: quote ?? this.quote,
        submitPending: submitPending ?? this.submitPending,
        submitError: clearSubmitError ? null : (submitError ?? this.submitError),
        scrollToErrorTick: scrollToErrorTick ?? this.scrollToErrorTick,
      );
}

/// `:751-752` — `useDebounced(recordSearch, 300)`.
const Duration kMarriageRecordSearchDebounce = Duration(milliseconds: 300);

/// `:754` — `per_page: 20`.
const int kMarriageRecordsPerPage = 20;

class MarriageFormCubit extends Cubit<MarriageFormViewState> {
  MarriageFormCubit({
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
  }) : super(const MarriageFormViewState());

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
  final MarriageQuotePort? loadQuote;
  final MarriagePayPort? pay;
  final MarriageRecordsPort? loadRecords;
  final MarriageRecordPort? openRecord;

  /// `attachmentsSent = useState(false)` — `:714`, as the executor reads it.
  ///
  /// Marriage's guard is [AttachmentGuard.singleFlag]: one boolean for the
  /// whole loop, set **after** it. `state.attachmentsSent` is still the value
  /// the page and its tests read; this is the same fact in the shape the
  /// executor consults, and the two are mirrored on every exit from [submit].
  final AttachmentLedger _ledger = AttachmentLedger();

  /// The four write ports, as the executor takes them. Built here rather than
  /// injected — see `resident_form_cubit.dart`'s `_executor` for why taking
  /// specs.md § 3.1 row 8's DI grant would force edits outside the scope table.
  SubmissionExecutor get _executor => SubmissionExecutor(
        createCase: createApplication,
        updateCase: updateApplication,
        attachToCase: (String id, SubmissionAttachment a) => addAttachment(
          id,
          a.file,
          slot: a.slot,
          kind: a.kind,
          // Marriage's port requires a label and `marriageUploads` always
          // supplies one (`:944-950`), so the `!` asserts a fact rather than
          // papering over a nullable.
          label: a.label!,
        ),
        submitCase: submitApplication,
      );

  Timer? _searchDebounce;

  @override
  Future<void> close() {
    _searchDebounce?.cancel();
    return super.close();
  }

  /// The four `useRefList` calls (`:744-749`), the provinces read, and the
  /// **one** quote read. Called once when the page mounts.
  ///
  /// **No `/payment-methods` request** — `METHOD_CODE` is a static map
  /// (`F3-AC-65`, `F3-AC-66`). Its absence here is the assertion.
  Future<void> load() async {
    await Future.wait<void>(<Future<void>>[
      _loadRef('nationality', (CertificateRefList l) => state.copyWith(nationalities: l)),
      _loadRef('ethnicity', (CertificateRefList l) => state.copyWith(ethnicities: l)),
      _loadRef('ethnic-group', (CertificateRefList l) => state.copyWith(ethnicGroups: l)),
      _loadRef('religion', (CertificateRefList l) => state.copyWith(religions: l)),
      _loadProvinces(),
    ]);
    await _loadQuoteOnce();
  }

  Future<void> _loadRef(
    String type,
    MarriageFormViewState Function(CertificateRefList) apply,
  ) async {
    final Either<Failure, List<LookupOption>> r =
        await getLookupOptions(LookupKey.reference(type));
    // `useRefList` destructures `{data, loading}` and never `error`, so a
    // failure lands as an EMPTY list with `loading: false` — indistinguishable
    // from a loaded-empty list, which is precisely § 6.3(i)'s collapse.
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

  /// A cascade level changed. Fetches the child list.
  ///
  /// **`PagingMode.firstPageOnly` on villages** — RULING 2(iv). The kernel's
  /// `LocationFields` loops to `total_pages`; `ApiLocationFields` fetches one
  /// page of 200 (`MarriageCertificatePage.tsx:296-298`). Porting the loop
  /// would make the port strictly better than the source in a citizen-visible
  /// way, which is `L-10`(b). `F3-AC-31` asserts it positively.
  Future<void> _loadChildren(
    MarriageCascade which,
    CertificateLocationValue value,
    CertificateLocationValue previous,
  ) async {
    if (value.provinceId != previous.provinceId) {
      _setCascade(
        which,
        state.cascade(which).copyWith(
              districts: const CertificateLocationLevel(loading: true),
              // No stale-clear of the ROWS — `ApiLocationFields` does not blank
              // them while refetching (Finding D). Only the flag moves.
              villages: CertificateLocationLevel.empty,
            ),
      );
      if (value.provinceId.isEmpty) {
        _setCascade(which,
            const MarriageCascadeState(districts: CertificateLocationLevel.empty));
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
        // THE line RULING 2(iv) is about.
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

  void _setCascade(MarriageCascade which, MarriageCascadeState next) {
    emit(state.copyWith(
      cascades: <MarriageCascade, MarriageCascadeState>{
        ...state.cascades,
        which: next,
      },
    ));
  }

  // ── mutators ───────────────────────────────────────────────────────────────

  void setHeader(CertificateLocationValue v) {
    final CertificateLocationValue previous = state.form.header;
    emit(state.copyWith(form: state.form.copyWith(header: v)));
    unawaited(_loadChildren(MarriageCascade.header, v, previous));
  }

  void patchSpouseA(MarriageSpouseInfo Function(MarriageSpouseInfo) f) {
    final MarriageSpouseInfo previous = state.form.spouseA;
    final MarriageSpouseInfo next = f(previous);
    emit(state.copyWith(form: state.form.copyWith(spouseA: next)));
    if (next.address != previous.address) {
      unawaited(
        _loadChildren(MarriageCascade.spouseA, next.address, previous.address),
      );
    }
    // **No quote re-read on a nationality change**, and no dead `else if`
    // branch left behind to suggest there might be one. `:761-763` makes
    // `anyForeign` the first of the source's two conditional-quote inputs;
    // under `blocked.md` § 1 option (b) the fee is the catalogue's and does not
    // move, so re-reading here would issue a second `GET /services` that
    // returns the same number. Removing the call is what makes the static
    // property true rather than merely currently-true — see the library doc.
  }

  void patchSpouseB(MarriageSpouseInfo Function(MarriageSpouseInfo) f) {
    final MarriageSpouseInfo previous = state.form.spouseB;
    final MarriageSpouseInfo next = f(previous);
    emit(state.copyWith(form: state.form.copyWith(spouseB: next)));
    if (next.address != previous.address) {
      unawaited(
        _loadChildren(MarriageCascade.spouseB, next.address, previous.address),
      );
    }
    // No quote re-read here either — see [patchSpouseA].
  }

  void patchBetrothal(MarriageBetrothal Function(MarriageBetrothal) f) =>
      emit(state.copyWith(form: state.form.copyWith(betrothal: f(state.form.betrothal))));

  void patchReg(MarriageRegistration Function(MarriageRegistration) f) =>
      emit(state.copyWith(form: state.form.copyWith(reg: f(state.form.reg))));

  void patchPayment(PaymentDraft Function(PaymentDraft) f) =>
      emit(state.copyWith(form: state.form.copyWith(payment: f(state.form.payment))));

  void togglePrevMarriedA() => emit(state.copyWith(
      form: state.form.copyWith(prevMarriedA: !state.form.prevMarriedA)));

  void togglePrevMarriedB() => emit(state.copyWith(
      form: state.form.copyWith(prevMarriedB: !state.form.prevMarriedB)));

  void toggleHasChildren() => emit(state.copyWith(
      form: state.form.copyWith(hasChildren: !state.form.hasChildren)));

  void setHouseholdBook(PickedAttachment? f) => emit(state.copyWith(
      form: state.form.copyWith(householdBook: f, clearHouseholdBook: f == null)));

  void setPhotos(PickedAttachment? f) => emit(state.copyWith(
      form: state.form.copyWith(photos: f, clearPhotos: f == null)));

  /// Forms v2 — the per-spouse 3×4 photos (`spouses.spouse_{a,b}.photo`).
  /// OPTIONAL state only: no validation, no canProceed dependency, and the
  /// payload emits the slot only when a file was picked.
  void setSpouseAPhoto(PickedAttachment? f) => patchSpouseA(
        (MarriageSpouseInfo s) =>
            s.copyWith(photo: f, clearPhoto: f == null),
      );

  void setSpouseBPhoto(PickedAttachment? f) => patchSpouseB(
        (MarriageSpouseInfo s) =>
            s.copyWith(photo: f, clearPhoto: f == null),
      );

  void setBirthRecord(PickedAttachment? f) => emit(state.copyWith(
      form: state.form.copyWith(birthRecord: f, clearBirthRecord: f == null)));

  /// `:1149` / `:1163` — the chooser.
  ///
  /// On the web this changes `creates_betrothal_record` and re-fires the quote
  /// (`:764`, `:772`), so choosing "record a new betrothal" visibly raises the
  /// fee. **It does not here**, and that is the sharpest edge of `blocked.md`
  /// § 1 option (b): the mode still reaches the wire payload
  /// (`marriage_payload.dart`'s `betrothal.creates_betrothal_record`), it just
  /// no longer moves the number the citizen is shown.
  void setBetrothalMode(MarriageBetrothalMode mode) {
    emit(state.copyWith(form: state.form.copyWith(betrothalMode: mode)));
    if (mode == MarriageBetrothalMode.existing) unawaited(searchRecords(''));
  }

  /// `:833-837` — `resetBetrothal()`. Clears the mode, the linked record and
  /// the open-record error.
  ///
  /// Unlike Divorce's `resetMediation`, this one has **no missing half**: there
  /// is no second branch to abandon on this page, so D-N has no Marriage
  /// analogue.
  void resetBetrothal() {
    emit(state.copyWith(
      form: state.form.copyWith(
        betrothalMode: MarriageBetrothalMode.none,
        clearLinkedRecord: true,
      ),
      clearOpenRecordError: true,
    ));
    // The web re-fires the quote here too (the mode leaves `"new"`). Not under
    // option (b) — see [setBetrothalMode].
  }

  /// `:1274` — "Change" on the linked summary. Clears the record but **not**
  /// the mode.
  void unlinkRecord() =>
      emit(state.copyWith(form: state.form.copyWith(clearLinkedRecord: true)));

  // ── the record picker ──────────────────────────────────────────────────────

  /// `:1199-1200` + `:751-757` — the debounced search.
  ///
  /// `enabled: betrothalMode === "existing" && !linkedRecord` (`:756`), so a
  /// linked record stops the query firing at all.
  void setRecordSearch(String q) {
    emit(state.copyWith(recordSearch: q));
    _searchDebounce?.cancel();
    _searchDebounce = Timer(kMarriageRecordSearchDebounce, () {
      unawaited(searchRecords(q));
    });
  }

  Future<void> searchRecords(String search) async {
    if (state.form.betrothalMode != MarriageBetrothalMode.existing ||
        state.form.linkedRecord != null) {
      return;
    }
    final MarriageRecordsPort? port = loadRecords;
    if (port == null) {
      // No port wired: the query never ran, which is NOT the same as an empty
      // result. Left in the initial state so the view renders neither the
      // empty sentence nor a row.
      return;
    }
    emit(state.copyWith(
      records: const MarriageAsync<PrerequisiteRecordPage>.loading(),
    ));
    final Either<Failure, PrerequisiteRecordPage> r = await port(search);
    emit(state.copyWith(
      records: r.fold(
        (Failure f) => MarriageAsync<PrerequisiteRecordPage>(error: f.message),
        (PrerequisiteRecordPage p) =>
            MarriageAsync<PrerequisiteRecordPage>(data: p),
      ),
    ));
  }

  /// `:808-831` — `selectExisting(recordNo)`.
  ///
  /// Pre-fills the header **only when the record's payload carries a
  /// `province_id`** (`:814`), and pre-fills both spouses' names and ids
  /// unconditionally. A failure is swallowed into [openRecordError] and
  /// surfaced below the picker (`:828-830`).
  Future<void> selectExisting(String recordNo) async {
    final MarriageRecordPort? port = openRecord;
    if (port == null) return;
    final Either<Failure, PrerequisiteRecord> r = await port(recordNo);
    r.fold(
      (Failure f) => emit(state.copyWith(openRecordError: f.message)),
      (PrerequisiteRecord record) {
        emit(state.copyWith(
          form: state.form.copyWith(linkedRecord: record),
          clearOpenRecordError: true,
        ));
      },
    );
  }

  // ── the quote ──────────────────────────────────────────────────────────────

  /// **Fires once**, from [load], and takes no inputs.
  ///
  /// The source's `useQuery` has `[anyForeign, includeBetrothalFee]` as its
  /// dependency array (`:766-774`) and re-fires on both. Under `blocked.md`
  /// § 1 option (b) there is nothing to re-fire *for*: [MarriageQuotePort]
  /// reads the `marriage` catalogue row, which is the same row in every form
  /// state. Structurally the same shape as `DivorceFormCubit._loadQuoteOnce`,
  /// and for a different reason — Divorce's source is genuinely unconditional,
  /// Marriage's is not, and this method is where that difference was given up.
  ///
  /// **Private**, so a later page cannot re-introduce a refresh from outside.
  ///
  /// No `loading` emit: [MarriageFormViewState.quote] starts loading, so the
  /// review card's `…` is already on screen when this runs.
  Future<void> _loadQuoteOnce() async {
    final MarriageQuotePort? port = loadQuote;
    if (port == null) return;
    final Either<Failure, MarriageQuote> r = await port();
    emit(state.copyWith(
      quote: r.fold(
        (Failure f) => MarriageAsync<MarriageQuote>(error: f.message),
        (MarriageQuote q) => MarriageAsync<MarriageQuote>(data: q),
      ),
    ));
  }

  // ── navigation and submit ──────────────────────────────────────────────────

  /// `:993-997` — `goBack()`.
  void goBack() {
    emit(state.copyWith(showErrors: false));
    if (state.step > 1) emit(state.copyWith(step: state.step - 1));
  }

  /// `:999-1026` — `handleNext()`.
  ///
  /// **The CTA is never disabled** (`:1613`); tapping it on an incomplete step
  /// flips `showErrors`, scrolls, and stays put. That is the whole gate.
  Future<void> next() async {
    if (state.submitPending) return;
    if (!marriageCanProceed(state.form, step: state.step)) {
      emit(state.copyWith(
        showErrors: true,
        scrollToErrorTick: state.scrollToErrorTick + 1,
      ));
      return;
    }
    emit(state.copyWith(showErrors: false));
    if (state.step < kMarriageStepCount) {
      emit(state.copyWith(step: state.step + 1));
      return;
    }
    await submit();
  }

  /// `:952-991` — `submitCase`: create → **attach → update** → submit → pay.
  ///
  /// Note the order: the nested family attaches **before** it updates; the flat
  /// family updates first (`submission_plan.dart:250-256`).
  ///
  /// Three retry mechanics, all reproduced:
  ///
  /// 1. **create is skipped when the draft exists** (`:956` `if (!id)`), so a
  ///    retry never duplicates the case (`F3-AC-61`).
  /// 2. **update runs EVERY time** (`:980`), outside any guard.
  /// 3. **attachments are guarded by one boolean** (`:972`) — plus D-I's fix,
  ///    which invalidates it when a file's identity changes.
  Future<void> submit() async {
    emit(state.copyWith(
      submitPending: true,
      serverErrors: const <String, String>{},
      clearSubmitError: true,
    ));

    final List<MarriageAttachment> uploads = marriageUploads(state.form);
    final Set<String> identities =
        uploads.map(marriageAttachmentIdentity).toSet();

    // **D-I stays here, in the page** (`F3-AC-60`). The executor's
    // `AttachmentGuard.singleFlag` arm is the source's `if (!attachmentsSent)`
    // and nothing more; deciding *when* two picked files are the same document
    // is page data, so the invalidation is expressed as a seam the page pulls.
    if (!_sameIdentities(state.uploadedIdentities, identities)) {
      _ledger.invalidateAllSent();
    }

    final String heldId = state.draftId;
    try {
      final SubmissionOutcome outcome = await _executor.run(
        plan: SubmissionPlan.forForm(CertificateForm.marriage),
        // `:964` `buildFormData("")` and `:981` `buildFormData(reference)` —
        // **two** invocations on a first attempt, one on a retry, each
        // re-evaluating `today()` at `:900`. The executor makes exactly those
        // calls; `case_reference_binding.dart:19-25` is why the count is
        // contract and not trivia.
        buildFormData: (String reference) =>
            buildMarriageFormData(state.form, clock, reference),
        // `:957-965` — `linked_reference_no` sits BETWEEN `event_date` and
        // `form_data`.
        createEnvelope: (Map<String, Object?> payload) =>
            marriageCreateEnvelope(form: state.form, payload: payload),
        // `:980-983`.
        updateEnvelope: (Map<String, Object?> updatePayload) =>
            marriageUpdateEnvelope(
          form: state.form,
          updatePayload: updatePayload,
        ),
        // SEQUENTIAL, in `uploads()` order, each carrying the fourth `label`
        // part the flat family does not send (`F3-AC-57`).
        attachments: <SubmissionAttachment>[
          for (final MarriageAttachment a in uploads)
            SubmissionAttachment(
              file: a.file,
              slot: a.slot,
              kind: a.kind,
              label: a.label,
            ),
        ],
        ledger: _ledger,
        held: heldId.isEmpty
            ? null
            : SubmissionDraft(id: heldId, referenceNo: state.caseRef),
        // `:968-970` `setCaseId` / `setCaseRef`, before the attach block runs.
        onDraftCreated: (SubmissionDraft d) => emit(
          state.copyWith(draftId: d.id, caseRef: d.referenceNo),
        ),
        charge: _charge,
      );
      emit(state.copyWith(
        submitPending: false,
        attachmentsSent: _ledger.allSent,
        uploadedIdentities: identities,
        submitted: MarriageSubmitted(
          decided: outcome.decided,
          receiptNo: outcome.receiptNo,
        ),
      ));
    } on SubmissionStepFailure catch (e) {
      _onStepFailed(e, identities);
    }
  }

  /// Routes a failed step the way `:952-991` routes it — **and the routing
  /// differs by step**, which is why the executor reports which one failed.
  ///
  /// `create` (`:961-968`) and the attach loop (`:972-977`) surface the API's
  /// sentence plainly; `update`, `submit` and `pay` go through [_fail], which
  /// decodes field errors and flips `showErrors`. Collapsing the five into one
  /// handler would be a visible behaviour change on a 422.
  void _onStepFailed(SubmissionStepFailure e, Set<String> identities) {
    // `setAttachmentsSent(true)` happens immediately after the loop (`:977`),
    // before the update that may fail — so a run that uploaded and then failed
    // downstream still records the uploads, and the retry skips them.
    final bool sent = _ledger.allSent;
    switch (e.step) {
      case SubmissionStep.create:
      case SubmissionStep.attach:
        emit(state.copyWith(
          submitPending: false,
          submitError: e.failure.message,
          attachmentsSent: sent,
          uploadedIdentities: sent ? identities : state.uploadedIdentities,
        ));
      case SubmissionStep.update:
      case SubmissionStep.submit:
      case SubmissionStep.pay:
        if (sent) {
          emit(state.copyWith(
            attachmentsSent: true,
            uploadedIdentities: identities,
          ));
        }
        _fail(e.failure);
    }
  }

  /// `:986-989` — the pay branch, and it stays **here** (specs.md § 6.7).
  ///
  /// Marriage's predicate is `fee_lak > 0 && payment_state !== "paid"` — the
  /// idempotency check Resident does **not** have (FU-1). B4 does not unify the
  /// two; `B4-AC-19` fails if a later hand does.
  Future<Either<Failure, String?>> _charge(
    SubmissionDraft draft,
    ApplicationDetail decided,
  ) async {
    if (decided.row.feeLak <= 0 ||
        decided.row.paymentState == PaymentState.paid) {
      return const Right<Failure, String?>(null);
    }
    final MarriagePayPort? port = pay;
    if (port == null) return const Right<Failure, String?>(null);

    final Either<Failure, Object?> paid = await port(
      draft.id,
      // `METHOD_CODE[payment.method]` — the STATIC map (`:140-144`), no
      // `/payment-methods` read (`F3-AC-65`).
      methodCode: marriageMethodCodeFor(state.form.payment.method),
    );
    return paid.map<String?>(marriageReceiptOf);
  }

  /// `:1016-1025` — a 422 lands its messages on the fields and **does not
  /// change the step**.
  ///
  /// D-G is REPRODUCED here against `fsd.md`'s FIX (§ 6.10, `F3-AC-70`…`72`):
  /// Marriage has zero occurrences of `stepOfFirstError` and no `FIELD_STEP`
  /// map, so routing a 422 would mean **authoring** a ~200-key step map with no
  /// source to check against — and it would change the visible step, which is
  /// the most observable thing a form can do.
  void _fail(Failure f) {
    final Map<String, String> fields = marriageFieldErrorsOf(f);
    emit(state.copyWith(
      submitPending: false,
      serverErrors: fields,
      submitError: fields.isEmpty ? f.message : null,
      clearSubmitError: fields.isNotEmpty,
      showErrors: fields.isNotEmpty ? true : state.showErrors,
      scrollToErrorTick: fields.isNotEmpty
          ? state.scrollToErrorTick + 1
          : state.scrollToErrorTick,
      // NOTE the absence: no `step:` here. That absence is `F3-AC-71`.
    ));
  }

  static bool _sameIdentities(Set<String> a, Set<String> b) =>
      a.length == b.length && a.containsAll(b);
}

/// The identity D-I's fix keys on: slot **plus** the file itself.
///
/// Slot alone is `AttachmentGuard.slotKeyed`'s defect; the file's name and byte
/// length together change whenever the citizen picks a different document,
/// which is the observable the fix is for.
String marriageAttachmentIdentity(MarriageAttachment a) =>
    '${a.slot}|${a.label}|${a.file.name}|${a.file.bytes?.length ?? -1}';

/// `:1019` — `err instanceof ApiError ? err.fieldMap() : {}`.
///
/// A [Failure] that carries no field map yields an empty map, which is what
/// puts the message in the red banner instead (`:1128`).
Map<String, String> marriageFieldErrorsOf(Failure f) {
  if (f is ApiFailure && f.isValidation) return f.exception.fieldMap();
  return const <String, String>{};
}

/// `:539`'s shape, reused: `receipt_no ?? transaction?.receipt_no`.
String? marriageReceiptOf(Object? result) {
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
