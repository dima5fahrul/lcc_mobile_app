part of 'account_profile_bloc.dart';

/// `profileNote` — `AccountPage.tsx:199`, which is a `string` holding one of
/// exactly two i18n values or `""`.
///
/// An enum rather than a `String`, because the two values are `c("saved")` and
/// `c("nothingChanged")` — i18n lookups that must happen in the widget, in the
/// reader's locale, at render time. A BLoC that stored the resolved string
/// would freeze it in whatever locale was current when the save happened, and
/// Tier 1's Lao run is where that shows up.
enum SaveOutcome {
  none,

  /// `setProfileNote(c("saved"))` — `:225`. **Also the signal that
  /// `session.refresh()` is due**; see `AccountProfileBloc`'s library doc.
  saved,

  /// `setProfileNote(c("nothingChanged"))` — `:217`, and no request was issued.
  nothingChanged,
}

/// `pwError` when it came from the two client-side rules — `:276-277`.
///
/// Separate from [AccountProfileState.passwordServerError] for the same reason
/// [SaveOutcome] is an enum: these two are i18n keys, that one is a server
/// string. The source stores all three in one `pwError` slot; splitting them
/// here is what lets the widget translate the first two and print the third
/// verbatim, which is exactly what the source does at render time.
enum PasswordError { none, tooShort, mismatch }

@freezed
abstract class AccountProfileState with _$AccountProfileState {
  const factory AccountProfileState({
    @Default(RegionStatus.initial) RegionStatus status,

    /// `profileQuery.data` — `:193`. See the BLoC's doc for why there is no
    /// `?? session.profile` fallback.
    CitizenProfile? profile,

    /// `profileQuery.error.message` — `:384`, rendered **in preference to**
    /// `c("profileError")`.
    String? errorMessage,

    // ── The profile editor ─────────────────────────────────────────────────

    /// `saveProfile.pending` — the Save button's `loading` prop (`:548`).
    @Default(false) bool saving,

    /// `profileNote` — `:547`. Green text under the form.
    @Default(SaveOutcome.none) SaveOutcome saveOutcome,

    /// `saveProfile.error.message` — `:545`. Red text under the form, above
    /// the note.
    String? saveError,

    /// `saveProfile.fieldErrors` — `:516`, `:530`. Keyed by the **wire** field
    /// name (`name`, `email`), because that is what the 422 body names.
    /// `address` is present in this map when the server sends it and is
    /// **never rendered**, matching the source (B8-AC-49).
    @Default(<String, String>{}) Map<String, String> fieldErrors,

    // ── The password form ──────────────────────────────────────────────────

    /// `changePassword.pending` — `:703`.
    @Default(false) bool changingPassword,

    /// The client-side rule that failed, if any.
    @Default(PasswordError.none) PasswordError passwordError,

    /// `setPwError((err as Error).message)` — `:284`. The **server's** text.
    String? passwordServerError,

    /// `pwNote` — `:702`. True after a success, and the widget's cue to clear
    /// the three controllers (`setPw({current:"", next:"", confirm:""})`,
    /// `:281`).
    @Default(false) bool passwordChanged,
  }) = _AccountProfileState;

  const AccountProfileState._();

  /// `profileQuery.loading && !account` — `:359`, the header name skeleton.
  bool get isLoadingHeader =>
      (status == RegionStatus.loading || status == RegionStatus.initial) &&
      profile == null;

  /// `profileQuery.error` — `:380`. The banner above My Documents.
  bool get hasFailed => status == RegionStatus.failure;

  /// `account` — `:194`. Every header and editor field reads through this.
  CitizenAccount? get account => profile?.account;

  AccountProfileState withProfile(Either<Failure, CitizenProfile> response) =>
      response.fold(
        (Failure failure) => copyWith(
          status: RegionStatus.failure,
          errorMessage: failure.message,
        ),
        (CitizenProfile value) => copyWith(
          status: RegionStatus.success,
          profile: value,
          errorMessage: null,
        ),
      );
}
