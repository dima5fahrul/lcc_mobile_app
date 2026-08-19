/// `AccountProfileBloc` — the profile read, the **dirty-field diff write**, and
/// the password form.
///
/// Ports `profileQuery` (`AccountPage.tsx:189`), `handleSaveProfile`
/// (`:209-229`) and `handleChangePassword` (`:273-286`). Password change is a
/// transient form action here, **not a fourth BLoC**, matching the source's
/// `useMutation` (`:269`) — specs.md § 6.3.
///
/// ## `handleSaveProfile`'s diff is the highest-value gate in the batch
///
/// The computation itself is [ProfileUpdate.diff], in
/// `features/session/domain/entities/` — deliberately not inlined here, so
/// Tier 0 can gate it without pumping a widget or standing up a BLoC. Read that
/// file's doc for the asymmetry (`name` can never be sent empty; `email` and
/// `address` can). This handler owns only the two things around it: the
/// **no-request** case (`:216-219`) and the ordering of the two refreshes
/// (`:223-224`).
///
/// ## Why this BLoC runs its own `GET /me/profile`
///
/// `AccountPage.tsx:193` is `profileQuery.data ?? session.profile`. The Flutter
/// session holds `CitizenProfileData` — **name and avatar URL only**, a P0
/// projection — and this page needs `uin`, `phone`, `email`, `address` and
/// `verified`. So the query is ported and the `??` fallback is not, because
/// there is nothing on the Flutter side to fall back *to*.
///
/// **Measured divergence, recorded not repaired:** in the web, a citizen who
/// already has a session sees their name immediately and never sees the header
/// skeleton (`:359`'s `profileQuery.loading && !account`). Here the skeleton
/// shows for the duration of the first `GET`. Fixing it means widening
/// `CitizenProfileData` to the whole entity, which is a change to
/// `lib/core/session/bloc/**` beyond the one event specs.md § 3.1 authorises,
/// and it would touch a file B9 and B10 are both near. Reported in the
/// hand-back.
///
/// ## `session.refresh()` is the widget's, and that is not a shortcut
///
/// `:224` calls `session.refresh()` after a successful save. `SessionBloc` is
/// app-wide and reached by `BlocProvider.of<SessionBloc>(context)` — a context
/// read, which G-L5 permits and a locator read is what it forbids. A BLoC has
/// no context, so [AccountProfileState.saveOutcome] transitions to
/// [SaveOutcome.saved] and `account_page.dart`'s `BlocListener` dispatches
/// `SessionRefreshProfile`. B8-AC-51 asserts **both** halves.
library;

import 'package:bloc/bloc.dart';
import 'package:dartz/dartz.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/usecase/usecase.dart';
import '../../../auth/domain/usecases/change_password.dart';
import '../../../session/domain/entities/citizen_account.dart';
import '../../../session/domain/entities/citizen_profile.dart';
import '../../../session/domain/entities/profile_update.dart';
import '../../../session/domain/usecases/get_profile.dart';
import '../../../session/domain/usecases/update_profile.dart';
import '../../domain/entities/picked_avatar.dart';
import '../../domain/usecases/account_usecases.dart';
import 'account_region_status.dart';

part 'account_profile_event.dart';
part 'account_profile_state.dart';
part 'account_profile_bloc.freezed.dart';

/// `pw.next.length < 8` — `AccountPage.tsx:276`.
///
/// A named constant so the number is assertable, and because **this is the
/// entire client-side password policy**. Whether the server enforces anything
/// stronger is NOT EVALUATED (specs.md § 6.8 item 1, GG-4).
const int kMinPasswordLength = 8;

class AccountProfileBloc
    extends Bloc<AccountProfileEvent, AccountProfileState> {
  AccountProfileBloc({
    required this.getProfile,
    required this.updateProfile,
    required this.changePassword,
    required this.uploadAvatar,
  }) : super(const AccountProfileState()) {
    on<AccountProfileRequested>(_onRequested);
    on<AccountProfileRetried>(_onRequested);
    on<AccountProfileSaved>(_onSaved);
    on<AccountPasswordSubmitted>(_onPasswordSubmitted);
    // **Registered with the default transformer, i.e. concurrently.** A
    // `sequential()` or `droppable()` transformer here would serialise or drop
    // the second of two rapid picks — a guard the source does not have
    // (`B8b-5`, GG-8). See [_onAvatarPicked].
    on<AccountAvatarPicked>(_onAvatarPicked);
  }

  final GetProfile getProfile;
  final UpdateProfile updateProfile;
  final ChangePassword changePassword;

  /// `POST /me/avatar` — B8b. See [_onAvatarPicked].
  final UploadAvatar uploadAvatar;

  /// `hooks.ts:55`. See `account_documents_bloc.dart` for why.
  int _generation = 0;

  // ── profileQuery — `AccountPage.tsx:189` ───────────────────────────────────

  Future<void> _onRequested(
    AccountProfileEvent event,
    Emitter<AccountProfileState> emit,
  ) =>
      _load(emit);

  Future<void> _load(Emitter<AccountProfileState> emit) async {
    final int mine = ++_generation;
    emit(state.copyWith(status: RegionStatus.loading));

    final Either<Failure, CitizenProfile> result = await _readProfile();
    if (mine != _generation || emit.isDone) return;

    emit(state.withProfile(result));
  }

  /// `SessionRepositoryImpl.getProfile` **rethrows** `ApiException` so
  /// `SessionBloc` can clear tokens on a 401. This page does not want that
  /// branch — `profileQuery.error` renders a message and a retry button
  /// (`:380-389`) whatever the status was — so the typed throw is folded back
  /// into the `Either` here rather than escaping into a widget.
  Future<Either<Failure, CitizenProfile>> _readProfile() async {
    try {
      return await getProfile(NoParams());
    } on ApiException catch (e) {
      return Left<Failure, CitizenProfile>(Failure(e.message));
    } catch (e) {
      return Left<Failure, CitizenProfile>(Failure(e.toString()));
    }
  }

  // ── handleSaveProfile — `AccountPage.tsx:209-229` ──────────────────────────

  Future<void> _onSaved(
    AccountProfileSaved event,
    Emitter<AccountProfileState> emit,
  ) async {
    final CitizenProfile? profile = state.profile;
    if (profile == null) return; // `if (!account) return` — `:210`

    final ProfileUpdate update = ProfileUpdate.diff(
      account: profile.account,
      name: event.name,
      email: event.email,
      address: event.address,
    );

    // `if (Object.keys(body).length === 0) { setProfileNote(c("nothingChanged")); return; }`
    // — `:216-219`. **No request is issued at all**, which is B8-AC-31 case
    // (iv) and is asserted by invocation count, not by the note alone.
    if (update.isEmpty) {
      emit(state.copyWith(
        saveOutcome: SaveOutcome.nothingChanged,
        saveError: null,
        fieldErrors: const <String, String>{},
      ));
      return;
    }

    // `setProfileNote("")` — `:220`. The note is cleared *before* the request,
    // so a second Save after a "Nothing to save." does not leave it on screen
    // while the request is in flight.
    emit(state.copyWith(
      saving: true,
      saveOutcome: SaveOutcome.none,
      saveError: null,
      fieldErrors: const <String, String>{},
    ));

    try {
      final Either<Failure, CitizenProfile> result =
          await updateProfile(UpdateProfileParams(update));
      if (emit.isDone) return;

      final Failure? failure = result.fold((Failure f) => f, (_) => null);
      if (failure != null) {
        emit(state.copyWith(saving: false, saveError: failure.message));
        return;
      }

      // `profileQuery.refetch(); await session.refresh(); setProfileNote(c("saved"))`
      // — `:223-225`, in that order. The refetch here; the session refresh is
      // the page's `BlocListener`, keyed on `SaveOutcome.saved` (see the
      // library doc).
      emit(state.copyWith(saving: false, saveOutcome: SaveOutcome.saved));
      if (emit.isDone) return;
      await _load(emit);
    } on ApiException catch (e) {
      if (emit.isDone) return;
      // `saveProfile.fieldErrors.name` / `.email` — `:516`, `:530`. A 422 on
      // this endpoint names the offending fields, and the source renders each
      // under its own input. **`address` has no field-error slot in the
      // source** (`:534-543` renders no error paragraph), so a server error on
      // `address` is invisible there and is invisible here too — B8-AC-49.
      emit(state.copyWith(
        saving: false,
        saveError: e.message,
        fieldErrors: e.fieldMap(),
      ));
    } catch (e) {
      if (emit.isDone) return;
      emit(state.copyWith(saving: false, saveError: e.toString()));
    }
  }

  // ── handleAvatar — `AccountPage.tsx:234-245` (B8b) ─────────────────────────

  /// The upload, and the two refreshes after it.
  ///
  /// ```tsx
  /// try {
  ///   await uploadAvatar.run(file);
  ///   profileQuery.refetch();
  ///   await session.refresh();
  /// } catch {
  ///   /* uploadAvatar.error carries the message */
  /// }
  /// ```
  ///
  /// Four properties, each ported deliberately:
  ///
  /// 1. **No in-flight guard.** Nothing here checks
  ///    [AccountProfileState.uploadingAvatar] before starting, so two rapid
  ///    picks produce two concurrent POSTs — `B8b-5`/GG-8, faithful. The
  ///    picking itself is the widget's and is equally unguarded.
  /// 2. **The refetch, then the session refresh, in that order.** `_load` here;
  ///    `session.refresh()` is the page's `BlocListener` on
  ///    [AvatarOutcome.uploaded], for the reason the library doc gives about
  ///    `SessionBloc` and context. The `saveOutcome` path does exactly this.
  /// 3. **A failure shows nothing.** The `Left` is discarded without reaching
  ///    any state field: `uploadAvatar.error` is never rendered in the source
  ///    (`B8b-4`/GG-7 — see [AccountProfileState]). This is also where the
  ///    `e.toString()` text that `AccountRepositoryImpl._guard` builds for a
  ///    non-`ApiException` failure stops: it is constructed and dropped, so
  ///    `MAJOR-1`'s surviving disclosure arm gains no render site from B8b.
  /// 4. **The returned `avatar_url` is discarded.** The source refetches the
  ///    profile rather than reading `uploadAvatar.data`, and so does this.
  Future<void> _onAvatarPicked(
    AccountAvatarPicked event,
    Emitter<AccountProfileState> emit,
  ) async {
    // Reset before the attempt so a *second* upload re-fires the page's
    // listener — see [AvatarOutcome].
    emit(state.copyWith(
      uploadingAvatar: true,
      avatarOutcome: AvatarOutcome.none,
    ));

    final Either<Failure, String> result =
        await uploadAvatar(UploadAvatarParams(event.file));
    if (emit.isDone) return;

    final bool failed = result.isLeft();
    if (failed) {
      // `catch { /* … */ }` — `:242-243`. `finally { setPending(false) }`
      // (`hooks.ts:147-149`) is the only visible effect. Nothing is shown.
      emit(state.copyWith(uploadingAvatar: false));
      return;
    }

    emit(state.copyWith(
      uploadingAvatar: false,
      avatarOutcome: AvatarOutcome.uploaded,
    ));
    if (emit.isDone) return;

    // `profileQuery.refetch()` — `:240`. `_load` carries the generation guard,
    // so an in-flight read from a concurrent upload cannot land out of order.
    await _load(emit);
  }

  // ── handleChangePassword — `AccountPage.tsx:273-286` ───────────────────────

  Future<void> _onPasswordSubmitted(
    AccountPasswordSubmitted event,
    Emitter<AccountProfileState> emit,
  ) async {
    // `setPwNote("")` — `:275`, before either check.
    emit(state.copyWith(passwordChanged: false));

    // The two rules, **in the source's order**. Order is observable: a new
    // password of "abc" that also mismatches its confirmation reports
    // `passwordShort`, not `passwordMismatch` (B8-AC-50).
    if (event.newPassword.length < kMinPasswordLength) {
      emit(state.copyWith(passwordError: PasswordError.tooShort));
      return;
    }
    if (event.newPassword != event.confirmPassword) {
      emit(state.copyWith(passwordError: PasswordError.mismatch));
      return;
    }

    // `setPwError("")` — `:278`.
    emit(state.copyWith(
      passwordError: PasswordError.none,
      passwordServerError: null,
      changingPassword: true,
    ));

    // `confirm` is **not** forwarded. It never reaches a layer that could
    // serialise it — B8-AC-34.
    final Either<Failure, Unit> result = await changePassword(
      ChangePasswordParams(
        currentPassword: event.currentPassword,
        newPassword: event.newPassword,
      ),
    );
    if (emit.isDone) return;

    result.fold(
      // `catch (err) { setPwError((err as Error).message) }` — `:283-284`. The
      // **server's own message**, rendered verbatim. A property of the oracle,
      // on the security review's agenda (B8-AC-59 item 2), not sanitised here.
      (Failure failure) => emit(state.copyWith(
        changingPassword: false,
        passwordServerError: failure.message,
      )),
      // `setPw({current:"", next:"", confirm:""}); setPwNote(c("passwordChanged"))`
      // — `:281-282`. The three inputs are cleared by the widget, which owns
      // the controllers; this flag is what tells it to.
      //
      // **No session is invalidated, locally or remotely** — no token clear, no
      // re-auth, no "sign out other devices". GG-5: a measured weakness in the
      // oracle, ported as-is because changing it would be an R-25-class
      // invisible divergence, and recorded on the security review's agenda.
      (_) => emit(state.copyWith(
        changingPassword: false,
        passwordChanged: true,
        passwordServerError: null,
      )),
    );
  }
}
