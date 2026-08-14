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
import '../entities/application_page.dart';
import '../entities/case_status.dart';
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

/// `catalog.statusCatalogue()` — `endpoints.ts:192`, **anonymous**.
class GetStatusPipeline implements UseCase<StatusPipeline, NoParams> {
  const GetStatusPipeline({required this.repository});

  final ApplicationRepository repository;

  @override
  Future<Either<Failure, StatusPipeline>> call(NoParams params) =>
      repository.getStatusPipeline();
}
