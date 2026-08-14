part of 'account_documents_bloc.dart';

@freezed
abstract class AccountDocumentsState with _$AccountDocumentsState {
  const factory AccountDocumentsState({
    @Default(RegionStatus.initial) RegionStatus status,

    /// `docsQuery.data ?? []` — `AccountPage.tsx:295`.
    @Default(<CitizenDocument>[]) List<CitizenDocument> items,

    /// `docsQuery.error.message` — rendered **in preference to** the local
    /// `c("docsError")` string (`:409`: `docsQuery.error.message ||
    /// c("docsError")`). The API's message wins; the local one is the fallback
    /// for an error with no message, not the other way round.
    String? errorMessage,
  }) = _AccountDocumentsState;

  const AccountDocumentsState._();

  // ── The four states, in the order `AccountPage.tsx:398-423` evaluates them ──

  /// `docsQuery.loading` — `:398`. `initial` counts, so the frame between the
  /// page appearing and the handler running shows the skeletons and not the
  /// empty-state sentence.
  bool get isLoading =>
      status == RegionStatus.loading || status == RegionStatus.initial;

  /// `!docsQuery.loading && docsQuery.error` — `:406`. Checked before the
  /// empty branch, so a failed load never reads as "no documents".
  bool get hasFailed => status == RegionStatus.failure;

  /// `!loading && !error && documents.length === 0` — `:419`.
  bool get isEmpty => status == RegionStatus.success && items.isEmpty;

  /// Folds a response in.
  ///
  /// A failure sets the status and **keeps the rows**, because `useQuery` calls
  /// `setError` without touching `data` (`hooks.ts:74-79`). Nothing renders
  /// them in that state — the error branch wins at `:406` — but discarding them
  /// here would be this port inventing a behaviour.
  AccountDocumentsState withDocuments(
    Either<Failure, List<CitizenDocument>> response,
  ) =>
      response.fold(
        (Failure failure) => copyWith(
          status: RegionStatus.failure,
          errorMessage: failure.message,
        ),
        (List<CitizenDocument> rows) => copyWith(
          status: RegionStatus.success,
          items: rows,
          errorMessage: null,
        ),
      );
}
