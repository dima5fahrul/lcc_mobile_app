part of 'history_bloc.dart';

/// `/history`'s events — one per control the citizen can operate, plus the
/// mount fetch, the retry, and the return-from-detail seam B7b dispatches.
sealed class HistoryEvent {
  const HistoryEvent();
}

/// The mount fetch, dispatched by the `/history` route builder.
///
/// In the builder rather than in `HistoryPage.initState` for the reason every
/// B2 page records: it keeps the page a pure function of its BLoC, which is
/// what lets a widget test pump it against any state without a container.
final class HistoryStarted extends HistoryEvent {
  const HistoryStarted();
}

/// `list.refetch` — the error panel's Try-again (`HistoryPage.tsx:141-146`).
final class HistoryListRetried extends HistoryEvent {
  const HistoryListRetried();
}

/// `setFilter(f.id)` — `HistoryPage.tsx:196`. [filter] is a key of
/// `kFilterStatuses`.
final class HistoryFilterPicked extends HistoryEvent {
  const HistoryFilterPicked(this.filter);

  final String filter;
}

/// Every keystroke in the search box — `HistoryPage.tsx:154`.
final class HistorySearchChanged extends HistoryEvent {
  const HistorySearchChanged(this.query);

  final String query;
}

/// The 350 ms debounce fired. [term] is already `.trim()`ed, matching
/// `useDebounced(query.trim(), 350)` (`:76`).
///
/// Public rather than private so a test can assert the debounce *window*
/// directly instead of only its effect.
final class HistorySearchDebounced extends HistoryEvent {
  const HistorySearchDebounced(this.term);

  final String term;
}

/// The pager's left control — `HistoryPage.tsx:409`.
final class HistoryPreviousPage extends HistoryEvent {
  const HistoryPreviousPage();
}

/// The pager's right control — `HistoryPage.tsx:420`.
final class HistoryNextPage extends HistoryEvent {
  const HistoryNextPage();
}

/// `onBack` from the detail — `HistoryPage.tsx:120-124`.
///
/// Refetches the list **and** the counts. The tiles' only refresh after mount.
final class HistoryReturnedFromDetail extends HistoryEvent {
  const HistoryReturnedFromDetail();
}
