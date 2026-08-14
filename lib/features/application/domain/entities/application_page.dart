/// One page of `GET /applications` — the rows plus the five `meta` numbers the
/// history list actually draws.
///
/// The domain-side pair of `core/network/envelope.dart`'s `Paged<T>`, which is
/// a **data-layer** type parameterised over the wire row and therefore
/// unusable from `domain/` (G-L2). Same shape and same reason as
/// `NewsPageResult` and `HelpFaqPage`.
///
/// **[total] is required here where `NewsPageResult` omits it**, because the
/// history pager prints it: `{meta.page} / {meta.total_pages} · {meta.total}`
/// (`HistoryPage.tsx:418`). It is also the *only* thing the four stat tiles
/// read — each fires `per_page: 1` and takes `meta.total`, never
/// `data.length` (`:103`, specs.md § 6.8) — so a result type that dropped it
/// would make the tiles unimplementable.
///
/// `per_page` is deliberately absent: nothing renders it.
library;

import 'package:equatable/equatable.dart';

import 'application_row.dart';

/// Value equality via [Equatable] rather than identity, for the reason
/// `NewsPageResult` records: the BLoC state is `@freezed`, so its generated
/// `==` compares fields, and a plain class here would make every state
/// carrying a freshly-parsed page compare unequal to an identical one — which
/// turns `bloc_test`'s `expect:` into an identity check nobody can satisfy.
class ApplicationPage extends Equatable {
  const ApplicationPage({
    required this.rows,
    required this.page,
    required this.totalPages,
    required this.total,
    required this.hasNext,
    required this.hasPrev,
  });

  /// An empty first page — the shape the **empty** state renders from
  /// (`HistoryPage.tsx:266`, `rows.length === 0`), and the shape the only test
  /// citizen's account actually returns today (`total: 0, rows: []`).
  static const ApplicationPage empty = ApplicationPage(
    rows: <ApplicationRow>[],
    page: 1,
    totalPages: 1,
    total: 0,
    hasNext: false,
    hasPrev: false,
  );

  final List<ApplicationRow> rows;

  final int page;
  final int totalPages;

  /// `meta.total` — printed by the pager (`:418`) and read by all four count
  /// queries (`:104`).
  final int total;

  final bool hasNext;
  final bool hasPrev;

  /// `meta && meta.total_pages > 1` — `HistoryPage.tsx:407`. The pager is
  /// hidden entirely on a single-page result.
  bool get showPager => totalPages > 1;

  @override
  List<Object?> get props =>
      <Object?>[rows, page, totalPages, total, hasNext, hasPrev];
}
