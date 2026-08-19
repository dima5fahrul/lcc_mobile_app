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

/// Whether an avatar upload has just succeeded — B8b's analogue of
/// [SaveOutcome.saved], and for the same mechanical reason.
///
/// `AccountPage.tsx:240-241` runs **two** refreshes after a successful upload:
/// `profileQuery.refetch()` and `await session.refresh()`. The first is this
/// BLoC's; the second needs `SessionBloc`, which arrives by context and which a
/// BLoC therefore cannot reach — so the page listens for [uploaded] and
/// dispatches it, exactly as it already does for [SaveOutcome.saved].
///
/// An enum rather than a `bool` so that a **second** upload re-fires the
/// listener: the handler resets to [none] before each attempt, so
/// `listenWhen`'s edge exists every time. A latching `bool` would refresh the
/// session after the first upload of a session and never again — invisible in
/// a single-upload test, and `B8-AC-54` guarantees repeat uploads happen.
enum AvatarOutcome { none, uploaded }

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

    // ── The avatar upload — B8b ────────────────────────────────────────────

    /// `uploadAvatar.pending` — `AccountPage.tsx:349`, the badge's spinner
    /// branch.
    ///
    /// **Last-writer-wins under concurrency, faithfully.** `useMutation` sets
    /// `pending` true at the top of `run` and false in its `finally`
    /// (`hooks.ts:133`, `:147-149`), so two overlapping uploads in the web app
    /// clear the spinner when the *first* finishes, not the last. One boolean
    /// here reproduces that. A counter would be the tidier engineering and a
    /// different observable — `B8b-5`/GG-8 says record the weakness, do not
    /// repair it.
    @Default(false) bool uploadingAvatar,

    /// Set to [AvatarOutcome.uploaded] on success and reset to
    /// [AvatarOutcome.none] before each attempt. The page's `BlocListener`
    /// keys `session.refresh()` off the transition — see [AvatarOutcome].
    @Default(AvatarOutcome.none) AvatarOutcome avatarOutcome,

    // **There is no `avatarError` field, and its absence is the port.**
    // `AccountPage.tsx:242-243` catches and discards, with the comment
    // *"uploadAvatar.error carries the message"* — which is false:
    // `uploadAvatar` is read at `:239` (`.run`) and `:349` (`.pending`) and
    // nowhere else, so the error `useMutation` captures is **never rendered**.
    // A failed upload is completely silent in the shipped web app: the spinner
    // stops and the citizen has no way to know whether their face arrived.
    // That is `security-review-b8b.md`'s `B8b-4` (MEDIUM), and it is the
    // oracle's defect, not the port's. Adding a field here would create the
    // only path by which a future edit could render it — an error surface the
    // web has no analogue for, which is L-10(b). Recorded as **GG-7**.

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
