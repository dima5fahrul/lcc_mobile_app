/// The application feature's repository contract — **read-only**, and that is
/// a boundary, not a coincidence.
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
import '../entities/application_page.dart';
import '../entities/case_status.dart';
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

  /// `GET /status-catalogue` — **anonymous** (`endpoints.ts:192`).
  ///
  /// Returns the pipeline with `draft` already stripped and the seed already
  /// substituted for an empty answer (`StatusPipeline.fromOrder`). A
  /// **failure** is the caller's to swallow — `statusCatalogue.ts:67-69` keeps
  /// the seed and renders — so this returns a `Left` rather than hiding the
  /// distinction, and `HistoryBloc` is where the swallow happens.
  Future<Either<Failure, StatusPipeline>> getStatusPipeline();
}
