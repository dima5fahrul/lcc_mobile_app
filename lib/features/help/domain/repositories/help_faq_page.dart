/// One page of `GET /help/faqs` — the rows plus the five numbers the page
/// draws from `meta`.
///
/// The domain-side pair of `core/network/envelope.dart`'s `Paged<T>`, which is
/// a **data-layer** type parameterised over the wire row and therefore
/// unusable here (G-L2: `domain/` may not import `data/`).
///
/// Unlike news' `NewsPageResult` this one carries [total], because the help
/// page prints it: `total === 1 ? t("resultsOne") : t("resultsMany", {count})`
/// (`HelpCenterPage.tsx:254`). News' pager never shows a count, which is why
/// its result type does not carry one — the two are deliberately not a shared
/// generic.
library;

import 'package:equatable/equatable.dart';

import '../entities/help_entities.dart';

class HelpFaqPage extends Equatable {
  const HelpFaqPage({
    required this.items,
    required this.page,
    required this.totalPages,
    required this.total,
    required this.hasNext,
    required this.hasPrev,
  });

  /// An empty first page — the **empty** state's shape (`:270`).
  static const HelpFaqPage empty = HelpFaqPage(
    items: <FaqItem>[],
    page: 1,
    totalPages: 1,
    total: 0,
    hasNext: false,
    hasPrev: false,
  );

  final List<FaqItem> items;

  final int page;
  final int totalPages;

  /// `meta?.total ?? items.length` — `:128`. Resolved in the datasource so the
  /// fallback exists once.
  final int total;

  final bool hasNext;
  final bool hasPrev;

  /// `meta && meta.total_pages > 1` — `:367`.
  bool get showPager => totalPages > 1;

  @override
  List<Object?> get props =>
      <Object?>[items, page, totalPages, total, hasNext, hasPrev];
}
