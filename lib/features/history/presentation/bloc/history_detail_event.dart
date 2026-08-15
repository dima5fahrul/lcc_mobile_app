part of 'history_detail_bloc.dart';

/// The four things that can happen to one open case.
///
/// There is no `HistoryDetailClosed`: closing the detail is `HistoryPage`'s
/// local state and it dispatches [HistoryReturnedFromDetail] on the **list**
/// BLoC (§ 6.6, `HistoryPage.tsx:120-124`). An event here would be a second
/// place that "the detail is shut" is recorded, and the two could disagree.
sealed class HistoryDetailEvent extends Equatable {
  const HistoryDetailEvent();

  @override
  List<Object?> get props => <Object?>[];
}

/// The citizen opened a case. Carries the id because the BLoC is built by DI
/// with none — see the library doc.
class HistoryDetailStarted extends HistoryDetailEvent {
  const HistoryDetailStarted(this.applicationId);

  final String applicationId;

  @override
  List<Object?> get props => <Object?>[applicationId];
}

/// *Refresh status* — `HistoryDetailPage.tsx:411`. Re-issues **both** queries.
class HistoryDetailRefreshed extends HistoryDetailEvent {
  const HistoryDetailRefreshed();
}

/// The error card's *Try again* — `:227`. The detail only.
class HistoryDetailRetried extends HistoryDetailEvent {
  const HistoryDetailRetried();
}

/// The timeline card's *Try again* — `:526`. The timeline only.
class HistoryDetailTimelineRetried extends HistoryDetailEvent {
  const HistoryDetailTimelineRetried();
}
