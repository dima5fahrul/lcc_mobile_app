/// `PagedRows<T>` — a page of rows plus the four pager numbers the wallet draws.
///
/// ## Why this exists rather than a reuse — measured before writing it
///
/// specs.md § 3.1's row says *"whatever B2 established for `meta`-bearing
/// pages — **reuse, do not re-invent**; the implementer must locate B2's paged
/// shape before adding one"*. Located. B2 established **two**, and neither is
/// reusable here:
///
/// | Type | Home | Carries |
/// |---|---|---|
/// | `NewsPageResult` | `features/news/domain/repositories/` | `List<NewsArticle>` + page/totalPages/hasNext/hasPrev |
/// | `HelpFaqPage` | `features/help/domain/repositories/` | `List<HelpFaq>` + the same four **plus `total`** |
///
/// Both are **non-generic and bound to their own entity**. Importing
/// `NewsPageResult` to hold wallet entries is not possible — it holds
/// `NewsArticle` — and G-L3's permission for `features/A →
/// features/B/domain/**` is beside the point when the type does not fit.
/// `core/network/envelope.dart`'s `Paged<T>` *is* generic and *is* the right
/// shape, and it is the one thing `domain/` may not import: it is a **data**
/// type and G-L2 fails the build for `domain → data`. `NewsPageResult`'s own
/// header records exactly that constraint and reaches the same conclusion.
///
/// So the pattern B2 established is *"each feature declares the page shape its
/// pager actually reads, in its own `domain/`"*, and this is that pattern
/// followed — one **generic** declaration serving both of the wallet's two
/// paged reads, rather than a `WalletEntryPage` and a `TransactionPage` that
/// would differ only in a type argument. That is the reuse the row asks for at
/// the scale where reuse is available.
///
/// ## Which numbers, and why not the other two
///
/// `PageMeta` carries six. The ledger pager reads **two** — `meta.page` and
/// `meta.total_pages` (`WalletPage.tsx:421-422`) — and its buttons are disabled
/// from those two alone (`:687,697`: `page <= 1`, `page >= totalPages`), not
/// from `has_prev` / `has_next`. [hasNext] and [hasPrev] are carried anyway
/// because the envelope sends them and a later consumer (B6b's bills list,
/// B7's history) may read them; `total` and `perPage` are **not**, because
/// nothing in the wallet prints a count. `HelpFaqPage` carries `total` for the
/// opposite reason and says so.
library;

import 'package:equatable/equatable.dart';

/// Value equality via [Equatable], for the reason `NewsPageResult` records: the
/// BLoC state is `@freezed`, so its generated `==` compares fields, and a plain
/// class here would make a state holding a freshly-parsed page compare unequal
/// to an identical one — turning every `bloc_test` `expect:` into an identity
/// check nobody can satisfy.
class PagedRows<T> extends Equatable {
  const PagedRows({
    required this.rows,
    required this.page,
    required this.totalPages,
    required this.hasNext,
    required this.hasPrev,
  });

  /// An empty first page — what an unfetched or empty paged read looks like.
  ///
  /// Not `const` on purpose: `const PagedRows<T>` cannot be written for an
  /// unbound `T` without also forcing every call site to spell the type
  /// argument, and `PagedRows<WalletEntry>.empty()` reads better than
  /// `const PagedRows<WalletEntry>(rows: [], page: 1, …)` at four call sites.
  factory PagedRows.empty() => PagedRows<T>(
    rows: const <Never>[],
    page: 1,
    totalPages: 1,
    hasNext: false,
    hasPrev: false,
  );

  final List<T> rows;

  final int page;
  final int totalPages;
  final bool hasNext;
  final bool hasPrev;

  /// `totalPages > 1` — `WalletPage.tsx:683`. The pager row is **absent**, not
  /// disabled, on a single-page result, which is the state the only test
  /// account is in (`entry_count 0`).
  bool get showPager => totalPages > 1;

  @override
  List<Object?> get props => <Object?>[
    rows,
    page,
    totalPages,
    hasNext,
    hasPrev,
  ];
}
