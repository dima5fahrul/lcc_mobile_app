part of 'account_preferences_bloc.dart';

@freezed
abstract class AccountPreferencesState with _$AccountPreferencesState {
  const factory AccountPreferencesState({
    @Default(RegionStatus.initial) RegionStatus status,

    /// `prefsQuery.data` — `AccountPage.tsx:195`. Null until the first
    /// successful read, which is what `if (!prefs) return` and the `{prefs &&
    /// …}` render guards at `:581`, `:662` both test.
    CitizenPreferences? preferences,

    /// `prefsQuery.error.message` — `:575`. Rendered raw, with **no local
    /// fallback string**: unlike the documents card (`:409`), the preferences
    /// panel has no `c("prefsError")` to fall back to. Ported as measured; an
    /// error with an empty message renders an empty paragraph in the web too.
    String? errorMessage,

    /// `savePrefs.pending` — `hooks.ts`' `useMutation`. Nothing in the source
    /// renders it for this mutation (the toggles have no busy state), so it is
    /// carried to keep the two states distinguishable in a test rather than to
    /// draw anything.
    @Default(false) bool saving,

    /// `savePrefs.error.message` — `:600`. A **separate** slot from
    /// [errorMessage]: the source renders the read's error above the switches
    /// and the write's error below them, and one can be set while the other is
    /// not.
    String? saveError,
  }) = _AccountPreferencesState;

  const AccountPreferencesState._();

  /// `prefsQuery.loading` — `:572`. `initial` counts, for the reason
  /// `AccountDocumentsState.isLoading` records.
  bool get isLoading =>
      status == RegionStatus.loading || status == RegionStatus.initial;

  /// `prefsQuery.error` — `:573`.
  ///
  /// **Not mutually exclusive with [isLoading] in the source**, which is a real
  /// quirk: `:572` and `:573` are two independent `&&` fragments, not an
  /// if/else, so a refetch that is in flight after a previous failure renders
  /// the skeleton *and* the error row together. Reproduced by keeping the two
  /// getters independent rather than making the second `status == failure &&
  /// !isLoading`.
  bool get hasFailed => status == RegionStatus.failure;

  AccountPreferencesState withPreferences(
    Either<Failure, CitizenPreferences> response,
  ) =>
      response.fold(
        (Failure failure) => copyWith(
          status: RegionStatus.failure,
          errorMessage: failure.message,
        ),
        (CitizenPreferences prefs) => copyWith(
          status: RegionStatus.success,
          preferences: prefs,
          errorMessage: null,
        ),
      );
}
