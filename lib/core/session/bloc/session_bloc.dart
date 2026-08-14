/// `SessionBloc` — the whole-app session state machine.
///
/// Ported from `lcc-app/src/app/api/session.tsx` (`SessionProvider` +
/// `useSession`). The React context's four pieces map onto one BLoC event
/// each:
///
///   TS `loadProfile`              → `SessionStarted` handler (boot)
///   TS `signIn(session)`          → `SessionSignIn(session)` handler
///   TS `signOut()`                 → `SessionSignOut` handler
///   TS `refresh` (=loadProfile)    → `SessionRefreshProfile` handler
///
/// The 401/403 guard from `loadProfile` lives here: when `getProfile` fails
/// with an `ApiException` whose `isUnauthorized || isForbidden` is true, the
/// tokens are cleared and the state goes `unauthenticated` — a token that no
/// longer resolves to an account is worse than no token.
///
/// `signOut` never throws: a failed revoke is swallowed (TS
/// `.catch(() => undefined)`), tokens are cleared, and the state is
/// `unauthenticated` regardless.
///
/// The non-BLoC UI (bottom-nav auth badge) reads
/// `storageService.authStateNotifier` directly — it is a `ValueNotifier<bool>`
/// already, so there is no need to duplicate that signal here. Exposed via
/// [authStateNotifier] so a widget tree wired to this BLoC can subscribe to
/// the same notifier without re-fetching `StorageService`.
library;

import 'package:bloc/bloc.dart';
import 'package:flutter/foundation.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../network/api_exception.dart';
import '../../storage/storage_service.dart';
import '../../usecase/usecase.dart';
import '../../../features/session/domain/entities/citizen_profile.dart';
import '../../../features/session/domain/entities/citizen_session.dart';
import '../../../features/session/domain/entities/profile_update.dart';
import '../../../features/session/domain/repositories/session_repository.dart';
import '../../../features/session/domain/usecases/get_profile.dart';
import '../../../features/session/domain/usecases/update_profile.dart';

part 'session_bloc.freezed.dart';

// ── Events ─────────────────────────────────────────────────────────────────
@freezed
sealed class SessionEvent with _$SessionEvent {
  /// Boot: check stored token, fetch profile if present (TS `loadProfile`).
  const factory SessionEvent.started() = SessionStarted;

  /// Sign in: save tokens, then fetch profile (TS `signIn`).
  const factory SessionEvent.signIn(CitizenSession session) = SessionSignIn;

  /// Sign out: revoke refresh, clear tokens, go unauthenticated (TS `signOut`).
  const factory SessionEvent.signOut() = SessionSignOut;

  /// Re-read the profile after an edit (TS `refresh`).
  const factory SessionEvent.refreshProfile() = SessionRefreshProfile;

  /// **R-25** — mirror the chosen language onto the citizen's account so it
  /// follows them to another device. `PATCH /me/profile {preferred_lang}`,
  /// ported from `LanguageToggle.tsx:71` (B8a).
  ///
  /// Dispatched by `lib/presentation/shell/language_toggle.dart` *after* the
  /// local switch has already happened. See [SessionBloc] for why this is an
  /// event on the app-wide session rather than a dependency threaded down
  /// through `AppShell` → `AppTopBar` → `LanguageToggle`.
  const factory SessionEvent.mirrorLanguage(String languageCode) =
      SessionMirrorLanguage;
}

// ── State ──────────────────────────────────────────────────────────────────
enum SessionStatus { initial, loading, authenticated, unauthenticated }

@freezed
abstract class SessionState with _$SessionState {
  const factory SessionState({
    @Default(SessionStatus.initial) SessionStatus status,
    CitizenProfileData? profile,
    String? errorMessage,
  }) = _SessionState;
}

/// Lightweight profile view the shell UI renders. Kept inside the BLoC file
/// (not a domain entity) because it is a projection of [CitizenProfile] for
/// the app shell — the full entity stays available to feature usecases.
@freezed
abstract class CitizenProfileData with _$CitizenProfileData {
  const factory CitizenProfileData({
    required String name,
    required String avatarUrl,
  }) = _CitizenProfileData;
}

// ── Bloc ───────────────────────────────────────────────────────────────────
class SessionBloc extends Bloc<SessionEvent, SessionState> {
  SessionBloc({
    required this.storage,
    required this.getProfile,
    required this.repository,
    required this.updateProfile,
  }) : super(const SessionState()) {
    on<SessionStarted>(_onStarted);
    on<SessionSignIn>(_onSignIn);
    on<SessionSignOut>(_onSignOut);
    on<SessionRefreshProfile>(_onRefreshProfile);
    on<SessionMirrorLanguage>(_onMirrorLanguage);
  }

  final StorageService storage;
  final GetProfile getProfile;

  /// **R-25** — `PATCH /me/profile`. Reached through
  /// `features/session/domain/usecases/`, which is the single whitelisted
  /// `core → features` edge (`ssd.md` § 4.5, G-L4) and already the shape
  /// [getProfile] arrives by.
  final UpdateProfile updateProfile;

  /// Direct repository handle for `logout` (sign-out revokes the refresh
  /// token server-side). Kept separate from [getProfile] so the usecase
  /// surface stays single-purpose.
  final SessionRepository repository;

  /// Exposed so a widget tree can subscribe to the same auth-state signal the
  /// shell uses without re-fetching [StorageService]. This is the direct
  /// passthrough of `storage.authStateNotifier` (TS `tokens.subscribe`).
  ValueNotifier<bool> get authStateNotifier => storage.authStateNotifier;

  // ── SessionStarted (boot) ─────────────────────────────────────────────────
  Future<void> _onStarted(
    SessionEvent event,
    Emitter<SessionState> emit,
  ) async {
    final authed = await storage.isAuthenticated();
    if (!authed) {
      emit(state.copyWith(status: SessionStatus.unauthenticated));
      return;
    }
    emit(state.copyWith(status: SessionStatus.loading));
    await _loadProfile(emit);
  }

  // ── SessionSignIn ────────────────────────────────────────────────────────
  Future<void> _onSignIn(
    SessionSignIn event,
    Emitter<SessionState> emit,
  ) async {
    final session = event.session;
    await storage.saveTokens(
      session.tokens.accessToken,
      session.tokens.refreshToken,
    );
    emit(state.copyWith(status: SessionStatus.loading));
    await _loadProfile(emit);
  }

  // ── SessionSignOut ───────────────────────────────────────────────────────
  Future<void> _onSignOut(
    SessionSignOut event,
    Emitter<SessionState> emit,
  ) async {
    final refresh = await storage.getRefreshToken();
    // Revoke server-side, but never let a failed call trap the user in a
    // session they asked to leave (TS `.catch(() => undefined)`).
    if (refresh != null) {
      final result = await repository.logout(refresh);
      result.fold(
        (_) {},
        (_) {},
      );
    }
    await storage.clearTokens();
    emit(state.copyWith(
      status: SessionStatus.unauthenticated,
      profile: null,
      errorMessage: null,
    ));
  }

  // ── SessionRefreshProfile ────────────────────────────────────────────────
  Future<void> _onRefreshProfile(
    SessionRefreshProfile event,
    Emitter<SessionState> emit,
  ) async {
    final authed = await storage.isAuthenticated();
    if (!authed) {
      emit(state.copyWith(
        status: SessionStatus.unauthenticated,
        profile: null,
      ));
      return;
    }
    emit(state.copyWith(status: SessionStatus.loading));
    await _loadProfile(emit);
  }

  // ── SessionMirrorLanguage (R-25) ─────────────────────────────────────────
  /// `LanguageToggle.tsx:69-72`, ported property for property (B8a):
  ///
  /// ```tsx
  /// function switchLanguage() {
  ///   const next = lang === "en" ? "lo" : "en";
  ///   toggle();                                    // local first
  ///   if (isAuthenticated) void me.updateProfile({ preferred_lang: next })
  ///                              .catch(() => undefined);
  /// }
  /// ```
  ///
  /// 1. **Local first, always.** The locale change and the `lcc.lang` write
  ///    have already happened by the time this event is dispatched — the
  ///    toggle awaits them before adding it. *"The UI must never wait on the
  ///    network to change language."* B8-AC-19.
  /// 2. **Only when authenticated.** `if (isAuthenticated)`. The gate is here
  ///    rather than in the widget because the widget has no session — that is
  ///    § 6.4's whole design — and because a spy on this use case is what
  ///    B8-AC-20 asserts zero calls against.
  /// 3. **Failure is swallowed.** `.catch(() => undefined)` — no toast, no
  ///    retry, no error state, **no `emit`**. The source explains why: *"the
  ///    app is already in the right language, and the Account screen can set
  ///    it again."* Adding error surfacing would be an R-25-class invisible
  ///    divergence introduced while fixing R-25. B8-AC-21.
  ///
  /// The body is `{"preferred_lang": "<next>"}` and **nothing else** —
  /// B8-AC-16. `ProfileUpdate` has no `phone` field at all, so B8-AC-32 holds
  /// by construction.
  ///
  /// This is R-25's **first** mirror. The second is the Account page's Language
  /// row, which writes `language` via `PUT /me/preferences` — a different
  /// endpoint and a different field name (specs.md § 2.2 Finding H). Both ship;
  /// B8-AC-18 asserts they stay distinct.
  Future<void> _onMirrorLanguage(
    SessionMirrorLanguage event,
    Emitter<SessionState> emit,
  ) async {
    if (state.status != SessionStatus.authenticated) return;

    try {
      // The `Either` is discarded, not folded: a `Left` here must be as silent
      // as a throw, and branching on it would be the first step towards
      // surfacing it.
      await updateProfile(
        UpdateProfileParams(ProfileUpdate(preferredLang: event.languageCode)),
      );
    } catch (_) {
      // `.catch(() => undefined)`. Deliberately empty, deliberately catching
      // everything including `ApiException` — which
      // `SessionRepositoryImpl.updateProfile` rethrows for the benefit of the
      // *other* caller. A 401 here must not sign the citizen out mid-toggle.
    }
  }

  // ── Shared profile loader (TS `loadProfile` port) ────────────────────────
  /// Fetches the profile via [getProfile]. On 401/403 (`ApiException`
  /// `isUnauthorized || isForbidden`) clears tokens and goes unauthenticated.
  /// On other failures keeps the current auth status but surfaces the error.
  /// On success emits `authenticated` with the profile projection.
  Future<void> _loadProfile(Emitter<SessionState> emit) async {
    try {
      final result = await getProfile(NoParams());
      result.fold(
        (failure) => emit(state.copyWith(
          status: SessionStatus.authenticated,
          errorMessage: failure.message,
        )),
        (profile) => emit(state.copyWith(
          status: SessionStatus.authenticated,
          profile: CitizenProfileData(
            name: profile.account.name,
            avatarUrl: profile.account.avatarUrl ?? '',
          ),
          errorMessage: null,
        )),
      );
    } on ApiException catch (e) {
      // A token that no longer resolves to an account is worse than no
      // token: it would leave the UI signed-in with nothing behind it.
      if (e.isUnauthorized || e.isForbidden) {
        await storage.clearTokens();
        emit(state.copyWith(
          status: SessionStatus.unauthenticated,
          profile: null,
          errorMessage: null,
        ));
      } else {
        emit(state.copyWith(
          status: SessionStatus.authenticated,
          errorMessage: e.message,
        ));
      }
    } catch (e) {
      emit(state.copyWith(
        status: SessionStatus.authenticated,
        errorMessage: e.toString(),
      ));
    }
  }
}
