/// The application feature's read use cases — two, and the filter table.
///
/// One file, for the reason `news_usecases.dart` and `home_usecases.dart` give:
/// the *set* is the feature's whole data surface today and two files of four
/// lines each would hide it. The classes stay separate types, so DI registers
/// two lazy singletons (DI-2) and each consumer's constructor names exactly
/// what it depends on.
///
/// **[ListApplications] is a published cross-container surface.** B6b resolves
/// it out of `applicationInjection` through a DI closure against the domain
/// interface — `ChatUsecaseInjection`'s shape (`ssd.md` § 5.1) — so its
/// parameter object is part of B7a's contract with B6b, not an internal
/// detail. `WalletPage.tsx:105` calls `applications.list({page: 1, per_page:
/// 50})` with no status and no search, which [ListApplicationsParams]'
/// defaults already express.
library;

import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/application_detail.dart';
import '../entities/application_page.dart';
import '../entities/case_status.dart';
import '../entities/case_timeline.dart';
import '../entities/picked_attachment.dart';
import '../entities/status_pipeline.dart';
import '../repositories/application_repository.dart';

/// `HistoryPage.tsx:40` — `const PER_PAGE = 10`.
const int kApplicationsPerPage = 10;

/// `HistoryPage.tsx:103` — each of the four count queries asks for **one** row
/// and reads `meta.total`. The value is `1` and not `0` because `per_page: 0`
/// is not a page size the API is asked for anywhere in the source.
const int kApplicationsCountPerPage = 1;

/// `HistoryPage.tsx:56` — the four chip ids, in render order.
const String kFilterAll = 'all';
const String kFilterPending = 'pending';
const String kFilterApproved = 'approved';
const String kFilterRejected = 'rejected';

/// `FILTER_STATUSES` — `HistoryPage.tsx:49-54`, verbatim.
///
/// ```ts
/// all:      undefined,
/// pending:  ["draft", "submitted", "certified", "under-review"],
/// approved: ["registered", "issued"],
/// rejected: ["returned", "rejected", "revoked"],
/// ```
///
/// `all` maps to **`null`, not to an empty list** — the difference is
/// observable on the wire. `undefined` makes `buildURL` skip the key entirely
/// (`client.ts:187`); an empty list would append nothing but would still have
/// travelled through the array branch, and a future `?status=` would be a
/// filter the web never sends. `B7-AC-18` asserts the absence.
///
/// Note the bucket lists are **not** `bucketOf`'s (`case_status.dart`). They
/// agree on `approved` and `rejected` and differ on `pending`, which the chip
/// includes `draft` in and which `bucketOf` reaches by fallthrough. Two tables
/// in the source, two tables here.
const Map<String, List<CaseStatus>?> kFilterStatuses = <String, List<CaseStatus>?>{
  kFilterAll: null,
  kFilterPending: <CaseStatus>[
    CaseStatus.draft,
    CaseStatus.submitted,
    CaseStatus.certified,
    CaseStatus.underReview,
  ],
  kFilterApproved: <CaseStatus>[
    CaseStatus.registered,
    CaseStatus.issued,
  ],
  kFilterRejected: <CaseStatus>[
    CaseStatus.returned,
    CaseStatus.rejected,
    CaseStatus.revoked,
  ],
};

/// One `GET /applications` query.
class ListApplicationsParams extends Equatable {
  const ListApplicationsParams({
    required this.page,
    this.perPage = kApplicationsPerPage,
    this.filter = kFilterAll,
    this.search = '',
  });

  final int page;
  final int perPage;

  /// A key of [kFilterStatuses].
  final String filter;

  /// The debounced, trimmed search term. Empty means "no search".
  final String search;

  /// What goes on the wire: the bucket, or null for `all` / an unknown chip.
  List<CaseStatus>? get wireStatuses => kFilterStatuses[filter];

  /// `search: search || undefined` — `HistoryPage.tsx:91`.
  ///
  /// Normalised **here** rather than at the call site so the source's one
  /// expression exists once. A BLoC that forgot it would send `search=` on
  /// every empty box and ask staging a question the web never asks
  /// (`B7-AC-17`).
  String? get wireSearch {
    final String trimmed = search.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  @override
  List<Object?> get props => <Object?>[page, perPage, filter, search];
}

/// `applications.list(...)` — `endpoints.ts:321`.
class ListApplications
    implements UseCase<ApplicationPage, ListApplicationsParams> {
  const ListApplications({required this.repository});

  final ApplicationRepository repository;

  @override
  Future<Either<Failure, ApplicationPage>> call(
    ListApplicationsParams params,
  ) =>
      repository.listApplications(
        page: params.page,
        perPage: params.perPage,
        statuses: params.wireStatuses,
        search: params.wireSearch,
      );
}

/// `applications.get(id)` — `endpoints.ts:323`. **B7b.**
///
/// A bare `String` parameter rather than a params object, unlike
/// [ListApplicationsParams]: the source passes one id
/// (`applications.get(applicationId, signal)`), there is no second dimension to
/// carry, and `GetNewsArticle`'s slug is the tree's precedent for the shape.
class GetApplication implements UseCase<ApplicationDetail, String> {
  const GetApplication({required this.repository});

  final ApplicationRepository repository;

  @override
  Future<Either<Failure, ApplicationDetail>> call(String id) =>
      repository.getApplication(id);
}

/// `applications.timeline(id)` — `endpoints.ts:342`. **B7b.**
///
/// Separate from [GetApplication] because the source issues two `useQuery`
/// calls with two independent loading and error states (`:142`, `:145`), and
/// the timeline's failure renders **inside** the timeline card while the rest
/// of the page keeps its data (`:522-533`). Folding the two into one use case
/// would make a timeline outage look like a page outage.
class GetApplicationTimeline implements UseCase<CaseTimeline, String> {
  const GetApplicationTimeline({required this.repository});

  final ApplicationRepository repository;

  @override
  Future<Either<Failure, CaseTimeline>> call(String id) =>
      repository.getApplicationTimeline(id);
}

/// `catalog.statusCatalogue()` — `endpoints.ts:192`, **anonymous**.
class GetStatusPipeline implements UseCase<StatusPipeline, NoParams> {
  const GetStatusPipeline({required this.repository});

  final ApplicationRepository repository;

  @override
  Future<Either<Failure, StatusPipeline>> call(NoParams params) =>
      repository.getStatusPipeline();
}

// ─────────────────────────────────────────────────────────────────────────────
// The write half — F1 (`specs.md` § 6.3). Four use cases, and B4 merges them.
// ─────────────────────────────────────────────────────────────────────────────
//
// Each is a separate type for the reason this file's header gives about the two
// reads: the certificate BLoC's constructor then names exactly the four writes
// it performs, and a reader of that constructor can see that `pay` is not among
// them (`F1-AC-24`).

/// `applications.create(input)` — `endpoints.ts:325`.
///
/// Params is the **envelope map itself**, not a wrapper object, and that is a
/// deliberate departure from [ListApplicationsParams]. The envelope's key
/// *order* is the wire format (`F1-AC-21`); an `Equatable` params class would
/// invite a `props` list that reorders it, and a typed DTO would have to choose
/// between Resident's eliding `province_id` and Marriage's sending `""`
/// (`envelope_shape.dart:18-24`). The map arrives built and leaves untouched.
class CreateApplication
    implements UseCase<ApplicationDetail, Map<String, Object?>> {
  const CreateApplication({required this.repository});

  final ApplicationRepository repository;

  @override
  Future<Either<Failure, ApplicationDetail>> call(
    Map<String, Object?> envelope,
  ) =>
      repository.createApplication(envelope);
}

/// `applications.update(id, {form_data, event_date})` — `endpoints.ts:327-328`.
///
/// Two arguments, so it takes [UpdateApplicationParams] where
/// [CreateApplication] takes the bare map. The params object carries the id
/// alongside the envelope and **does not put the envelope in `props`**: two
/// updates to the same case with the same keys in a different order are
/// different requests, and `Equatable` on a `Map` compares unordered.
class UpdateApplication
    implements UseCase<ApplicationDetail, UpdateApplicationParams> {
  const UpdateApplication({required this.repository});

  final ApplicationRepository repository;

  @override
  Future<Either<Failure, ApplicationDetail>> call(
    UpdateApplicationParams params,
  ) =>
      repository.updateApplication(params.id, params.envelope);
}

/// [UpdateApplication]'s two arguments.
class UpdateApplicationParams {
  const UpdateApplicationParams({required this.id, required this.envelope});

  final String id;

  /// `{form_data, event_date?}` — **`form_data` first** (`F0-AC-80`).
  final Map<String, Object?> envelope;
}

/// `applications.addAttachment(id, file, slot, kind)` —
/// `endpoints.ts:344-351`. Multipart.
///
/// Answers `Unit`: the source discards the response (`:528` is a bare `await`),
/// and returning the parsed attachment would be a value with no reader that a
/// later batch would then feel obliged to keep parsing.
class AddAttachment implements UseCase<Unit, AddAttachmentParams> {
  const AddAttachment({required this.repository});

  final ApplicationRepository repository;

  @override
  Future<Either<Failure, Unit>> call(AddAttachmentParams params) =>
      repository.addAttachment(
        params.id,
        file: params.file,
        slot: params.slot,
        kind: params.kind,
        label: params.label,
      );
}

/// [AddAttachment]'s arguments.
///
/// **No `contentType`, no `extension`, no `mimeType` field** — R-21. A field
/// that existed here is a field a later batch could filter on, which is the
/// reason `picked_attachment.dart` carries none either.
class AddAttachmentParams {
  const AddAttachmentParams({
    required this.id,
    required this.file,
    required this.slot,
    required this.kind,
    this.label,
  });

  final String id;
  final PickedAttachment file;

  /// The schema key this file answers — `"applicant.photo"`, `"applicant.id_front"`, …
  final String slot;

  /// `"photo"` or `"document"`. The **slot's** kind, never the file's.
  final String kind;

  /// The optional fourth multipart part. Absent means the part is not sent.
  final String? label;
}

/// `applications.submit(id)` — `endpoints.ts:338`, body `{}`.
///
/// Answers the **decided** case. `fee_lak` on that answer is what decides
/// whether the caller pays at all (`ResidentCertificatePage.tsx:535`), which is
/// why this returns the case rather than `Unit` the way [AddAttachment] does.
class SubmitApplication implements UseCase<ApplicationDetail, String> {
  const SubmitApplication({required this.repository});

  final ApplicationRepository repository;

  @override
  Future<Either<Failure, ApplicationDetail>> call(String id) =>
      repository.submitApplication(id);
}
