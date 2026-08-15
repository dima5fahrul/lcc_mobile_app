/// `ListPendingBills` — the Bills Due card's one read, and it is **B7a's
/// endpoint reached through B7a's use case**.
///
/// ```ts
/// const billsQuery = useQuery(
///   (signal) => applications.list({ page: 1, per_page: 50 }, signal), [],
///   { enabled: isAuthenticated },
/// );                                              // WalletPage.tsx:104-108
/// const bills = (billsQuery.data?.data ?? [])
///   .filter((a) => a.payment_state === "pending" && a.fee_lak > 0);   // :123-125
/// ```
///
/// ## Why this composes [ListApplications] instead of calling `/applications`
///
/// specs.md § 2.3, amended at v1.1, and it is the amendment that matters:
/// v1.0 placed the Bills Due read in `features/wallet/data/` *"until B4 absorbs
/// it"*, which was right when `features/application/data/` was not going to
/// exist. **B7a landed it.** Two datasources for one endpoint is not the § 4.3
/// *"wire-format duplication is the accepted cost"* case — that clause covers
/// two features parsing the same JSON, and here one shared feature already
/// parses it.
///
/// `features/wallet/**` may not import `features/application/data/**` (G-L3),
/// and does not need to: this use case depends on [ListApplications], a
/// **domain** type, and DI resolves the instance out of `applicationInjection`
/// through a closure — `ChatUsecaseInjection`'s shape
/// (`chat_usecase_injection.dart:1-32`), asserted by a test rather than trusted
/// to a comment. **No DI-6 deviation is required**: unlike chat/help,
/// `application` precedes `wallet` alphabetically, so the necessary
/// registration order *is* the alphabetical one.
///
/// ## The filter is the source's, and both halves are load-bearing
///
/// `payment_state === "pending"` **and** `fee_lak > 0`. A case whose fee is
/// zero is `payment_state: "free"` on the wire, but the source does not rely on
/// that — it tests the amount too, and so does this. Dropping either half would
/// put a `0 ₭` row with a Pay button in front of a citizen.
///
/// The filter runs **client-side over one 50-row page**, exactly as the web
/// does. It is not `?status=` and it is not paged: `per_page: 50` with no
/// second page is the source's whole strategy, and a citizen with 51 cases sees
/// the first 50. Ported as measured; a `while (hasNext)` loop here would be a
/// silent improvement over the source on a money surface.
///
/// ## Reachable state today
///
/// `GET /applications/` answers `total 0, rows 0` for the only test citizen
/// (specs.md § 2.1), so **the populated branch is unreachable against live
/// data** and every criterion that needs it is NOT EVALUATED with that reason.
/// The filter itself is a pure function over rows and is unit-tested against
/// declared-synthetic fixtures, which is evidence about the filter and not
/// about the account.
library;

import 'package:dartz/dartz.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/usecase/usecase.dart';
import '../../../application/domain/entities/application_page.dart';
import '../../../application/domain/entities/application_row.dart';
import '../../../application/domain/entities/case_status.dart';
import '../../../application/domain/usecases/application_usecases.dart';

/// `WalletPage.tsx:105` — `{ page: 1, per_page: 50 }`.
///
/// Named constants rather than literals at the call site because the page size
/// is the *reason* the list is not paged, and a reader who changes it should
/// have to read why.
const int kBillsPage = 1;
const int kBillsPerPage = 50;

/// `bills` — the pending, non-zero-fee cases of the first 50.
class ListPendingBills implements UseCase<List<ApplicationRow>, NoParams> {
  const ListPendingBills({required this.listApplications});

  /// B7a's use case, resolved out of `applicationInjection` by a DI closure.
  final ListApplications listApplications;

  @override
  Future<Either<Failure, List<ApplicationRow>>> call(NoParams params) async {
    final Either<Failure, ApplicationPage> page = await listApplications(
      // `filter` and `search` keep their defaults — `all` and `''` — which
      // `ListApplicationsParams` already normalises to **no `status` and no
      // `search` on the wire** (`B7-AC-17`, `B7-AC-18`). That is what
      // `applications.list({page, per_page})` sends with no third argument.
      const ListApplicationsParams(page: kBillsPage, perPage: kBillsPerPage),
    );

    return page.map(
      (ApplicationPage p) =>
          p.rows.where(isPendingBill).toList(growable: false),
    );
  }
}

/// `a.payment_state === "pending" && a.fee_lak > 0` — `WalletPage.tsx:124`.
///
/// A named top-level predicate rather than an inline closure so the Bills Due
/// filter is testable without a repository, a page or a `Future` — the one
/// piece of this read that is pure, and the only piece an empty account lets a
/// test reach honestly.
bool isPendingBill(ApplicationRow row) =>
    row.paymentState == PaymentState.pending && row.feeLak > 0;
