/// The application feature's repository contract.
///
/// **It was read-only through B7a and B7b, and F1 ended that** — deliberately
/// and by ruling, not by drift. `specs.md` § 6.3 adds `create`, `update`,
/// `addAttachment` and `submit` here rather than in a second repository,
/// because `roadmap.md`:399 has **B4 absorb them by merging this file** and a
/// parallel `features/certificates/data/` would make that a reconciliation
/// instead. The paragraphs below are B7a's and still hold for the read half;
/// the write half's own boundary is stated at the four methods.
///
/// | Source | Method | Endpoint | Auth |
/// |---|---|---|---|
/// | `HistoryPage.tsx:85`, `:103` · `WalletPage.tsx:105` | [listApplications] | `GET /applications` | Bearer |
/// | `statusCatalogue.ts:56` (via `HistoryPage.tsx:68`) | [getStatusPipeline] | `GET /status-catalogue` | **anonymous** |
///
/// ## Two methods, not ten
///
/// `endpoints.ts:320-357` exposes ten `applications.*` members. B7a implements
/// **one** of them plus the separate catalogue endpoint. The other nine are
/// out of scope by ruling, not by omission:
///
/// * `get`, `timeline` — **B7b**, added additively to this interface.
/// * `create`, `update`, `submit`, `addAttachment`, `pay` — the write half.
///   **B4** (and the call sites are F1–F3 / B6b). `ssd.md` § 5.1.
/// * `cancel` (`endpoints.ts:340`) and `removeAttachment` (`:353`) — **called
///   by no web component at all.** `grep -rn "applications.cancel\|
///   removeAttachment" src/` finds only their declarations. Same dead-code
///   class as `/news/:slug`, `YourIdPage` and `DELETE /me/account`, and
///   `ssd.md` § 5.1 rules explicitly that **B4 must decide them with a stated
///   reason and that no earlier batch may build them speculatively.** B7a
///   therefore does not, and this paragraph is why.
///
/// **No write path may be added to this interface by B7.** That is the whole
/// of specs.md § 6.2's additive contract: B4 extends this file rather than
/// reconciling with it, which is what makes the absorb a merge.
///
/// ## Why this feature has no pages
///
/// `ssd.md`:218 and § 5.1 — *"A feature with no pages is legitimate"*. Four
/// features consume `features/application/domain/**` and none of them may
/// touch `features/application/{data,presentation}/**` (G-L3), so there is
/// nothing for a `presentation/` directory here to hold. `B7-AC-10` asserts it
/// stays absent.
library;

import 'package:dartz/dartz.dart';

import '../../../../core/error/failure.dart';
import '../entities/application_detail.dart';
import '../entities/application_page.dart';
import '../entities/case_status.dart';
import '../entities/case_timeline.dart';
import '../entities/picked_attachment.dart';
import '../entities/status_pipeline.dart';

abstract class ApplicationRepository {
  /// `GET /applications?page=&per_page=[&status=…][&search=]`.
  ///
  /// [statuses] is the filter chip's bucket, or `null` for `all` — which sends
  /// **no `status` parameter at all** rather than an empty one
  /// (`HistoryPage.tsx:50`, `FILTER_STATUSES.all = undefined`).
  ///
  /// [search] is already trimmed and already debounced by the caller; an empty
  /// string must not reach the wire (`client.ts:187` skips `""` alongside
  /// `undefined` and `null`, so an empty search box sends nothing).
  Future<Either<Failure, ApplicationPage>> listApplications({
    required int page,
    required int perPage,
    List<CaseStatus>? statuses,
    String? search,
  });

  /// `GET /applications/{id}` — **B7b**, Bearer (`endpoints.ts:323`).
  ///
  /// A **404 folds to `NotFoundFailure`** and every other error to a plain
  /// `Failure`, because `HistoryDetailPage.tsx:201` renders different copy for
  /// the two (`B7-AC-54`). The `Failure.message` carried here is the API's own
  /// sentence — `detailQuery.error?.message`, `:205` — not a Dart type dump;
  /// see `application_failures.dart` for why the list path differs.
  Future<Either<Failure, ApplicationDetail>> getApplication(String id);

  /// `GET /applications/{id}/timeline` — **B7b**, Bearer (`endpoints.ts:342`).
  ///
  /// Its own request and its own error surface: `:522-533` renders a retry
  /// panel *inside* the timeline card while the rest of the detail keeps
  /// rendering, so a failed timeline must not fail the page. That is why this
  /// is a second method and not a field of [getApplication]'s answer.
  ///
  /// **Shared with B4.** This endpoint and `/status-catalogue` are the two B7
  /// touches that B4 also needs (`ssd.md` § 5.1); `CaseTimeline` and
  /// `CaseEvent` are defined once, here, so B4 extends rather than duplicates.
  Future<Either<Failure, CaseTimeline>> getApplicationTimeline(String id);

  /// `GET /status-catalogue` — **anonymous** (`endpoints.ts:192`).
  ///
  /// Returns the pipeline with `draft` already stripped and the seed already
  /// substituted for an empty answer (`StatusPipeline.fromOrder`). A
  /// **failure** is the caller's to swallow — `statusCatalogue.ts:67-69` keeps
  /// the seed and renders — so this returns a `Left` rather than hiding the
  /// distinction, and `HistoryBloc` is where the swallow happens.
  Future<Either<Failure, StatusPipeline>> getStatusPipeline();

  // ── The write half — F1, and exactly four ──────────────────────────────────
  //
  // `roadmap.md`:399 gives **B4** *"the minimal draft-submission usecase F1
  // brings"* and says **merge, not rewrite**. So these four are not a private
  // staging area F1 could shape freely; they are the first half of a file B4
  // will own, written to the read half's own conventions so the absorb is a
  // merge (`specs.md` § 6.3).
  //
  // **`cancel` and `removeAttachment` stay absent**, and the paragraph above
  // in this file already says why: no web component calls either, and
  // `ssd.md` § 5.1 reserves the decision to B4 with a stated reason. F1
  // building them "while it was in there" is what `F1-AC-19` and `F1-AC-20`
  // check for.
  //
  // **`pay` stays absent, and that one is a live coordination boundary rather
  // than a dormant one.** `GOR-245-b6-wallet-payment/specs.md` § 6.3 gives B6b
  // the `PayApplication` usecase and its wire model outright; F1 owns only the
  // *call site*, and it reaches the capability through a function it is handed
  // (`specs.md` § 6.2, `F1-AC-24`/`F1-AC-25`). Two implementations of one wire
  // call is worse than none, because the second one to land looks like it
  // works.

  /// `POST /applications` — Bearer (`endpoints.ts:325`).
  ///
  /// [envelope] is the create body **already in wire order**, built by the
  /// certificate page: `service_code`, the three optional location ids,
  /// `event_date`, `form_data` — `form_data` **last** (`F0-AC-19`/`F0-AC-80`).
  /// It is a `Map` and not a typed input object on purpose: the five certificate
  /// pages do not agree on this body (Resident elides a blank `province_id`,
  /// Marriage sends `""`), so a shared DTO would have to pick one and would
  /// silently impose it on the other (`envelope_shape.dart:18-24`).
  ///
  /// Answers the created case; the caller keeps its `id` and `reference_no`
  /// and **reuses them on every retry** (`ResidentCertificatePage.tsx:505-517`).
  Future<Either<Failure, ApplicationDetail>> createApplication(
    Map<String, Object?> envelope,
  );

  /// `PATCH /applications/{id}` — Bearer (`endpoints.ts:327-328`).
  ///
  /// [envelope] is `{form_data, event_date?}` with **`form_data` first** — the
  /// opposite end of the body from create, and a wire fact rather than a style
  /// (`F1-AC-21`).
  ///
  /// Runs on **every** submit attempt including the first, because it is what
  /// writes `header.ref_no` — the reference only exists once the case does
  /// (`:519-524`).
  Future<Either<Failure, ApplicationDetail>> updateApplication(
    String id,
    Map<String, Object?> envelope,
  );

  /// `POST /applications/{id}/attachments` — multipart, Bearer
  /// (`endpoints.ts:344-351`).
  ///
  /// One file per call. The caller uploads **sequentially** in
  /// `attachmentsToSend()`'s order and skips a slot it has already sent
  /// (`:526-530`) — that loop is the page's, not this method's, because the
  /// `uploaded` set is per-page-instance and not persisted.
  ///
  /// **Nothing on this path may reject a file for its extension or MIME type**
  /// (R-21). The `kind` argument is the slot's declared kind.
  Future<Either<Failure, Unit>> addAttachment(
    String id, {
    required PickedAttachment file,
    required String slot,
    required String kind,
    String? label,
  });

  /// `POST /applications/{id}/submit` — Bearer (`endpoints.ts:338`), body `{}`.
  ///
  /// Answers the **decided** case. Its `fee_lak` decides whether the caller
  /// pays at all (`:535`), and its `subject_name`, `reference_no`,
  /// `status_label` and `fee_lak` are the success card's four unconditional
  /// rows (`:634-643`).
  Future<Either<Failure, ApplicationDetail>> submitApplication(String id);
}
