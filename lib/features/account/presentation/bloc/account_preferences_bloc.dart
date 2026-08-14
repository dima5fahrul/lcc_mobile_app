/// `AccountPreferencesBloc` — `GET` and the **whole-object `PUT`** of
/// `/me/preferences`.
///
/// Ports `prefsQuery` (`AccountPage.tsx:191`) and `updatePrefs`
/// (`:250-263`), which between them drive the notifications panel (`:572-603`),
/// the language panel (`:614-635`) and the biometric switch (`:662-671`).
///
/// ## The `PUT` is whole-object and that is the batch's second Tier 0 leaf
///
/// ```tsx
/// const next: CitizenPreferences = {
///   ...prefs, ...patch,
///   notifications: { ...prefs.notifications, ...(patch.notifications ?? {}) },
/// };
/// ```
///
/// `PUT`, not `PATCH` (`endpoints.ts:123`). Toggling one notification switch
/// sends **all three notification booleans plus `language` plus
/// `biometric_login`**. A port that sent only the changed field would silently
/// reset the other two server-side — and the UI would still look right, because
/// it refetches. The transform lives on the entity
/// (`CitizenPreferences.merge`) so a Tier 0 test can reach it without a network
/// double; B8-AC-33.
///
/// ## The switch does NOT move optimistically, and that is measured
///
/// `checked={prefs.notifications[key]}` reads `prefsQuery.data`, and
/// `updatePrefs` never writes to it — it calls `savePrefs.run(next)` and then
/// `prefsQuery.refetch()` (`:258-259`). So in the shipped app a switch stays
/// where it was until the `PUT` **and** the following `GET` have both landed.
/// That is worse UX than an optimistic flip, and porting the flip would be an
/// R-25-class improvement invisible to every tier. Ported as measured.
///
/// ## `if (!prefs) return` — `:251`
///
/// Every mutation is a no-op before the first successful read. The three
/// handlers below all take that early return, and it is why they can build the
/// merged object from `state.preferences!` without a null dance.
library;

import 'package:bloc/bloc.dart';
import 'package:dartz/dartz.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/usecase/usecase.dart';
import '../../domain/entities/citizen_preferences.dart';
import '../../domain/usecases/account_usecases.dart';
import 'account_region_status.dart';

part 'account_preferences_event.dart';
part 'account_preferences_state.dart';
part 'account_preferences_bloc.freezed.dart';

class AccountPreferencesBloc
    extends Bloc<AccountPreferencesEvent, AccountPreferencesState> {
  AccountPreferencesBloc({
    required this.getPreferences,
    required this.savePreferences,
  }) : super(const AccountPreferencesState()) {
    on<AccountPreferencesRequested>(_onRequested);
    on<AccountPreferencesRetried>(_onRequested);
    on<AccountNotificationToggled>(_onNotificationToggled);
    on<AccountBiometricToggled>(_onBiometricToggled);
    on<AccountLanguageSelected>(_onLanguageSelected);
  }

  final GetPreferences getPreferences;
  final SavePreferences savePreferences;

  /// `hooks.ts:55` — one per query. See `account_documents_bloc.dart`'s doc for
  /// why the stamp is load-bearing under `bloc` 9.2.1's concurrent transformer:
  /// the language panel can be tapped twice before the first refetch lands.
  int _generation = 0;

  Future<void> _onRequested(
    AccountPreferencesEvent event,
    Emitter<AccountPreferencesState> emit,
  ) =>
      _load(emit);

  Future<void> _load(Emitter<AccountPreferencesState> emit) async {
    final int mine = ++_generation;
    emit(state.copyWith(status: RegionStatus.loading));

    final Either<Failure, CitizenPreferences> result =
        await getPreferences(NoParams());
    if (mine != _generation || emit.isDone) return;

    emit(state.withPreferences(result));
  }

  // ── updatePrefs — `AccountPage.tsx:250-263` ────────────────────────────────

  /// The one place a `PUT` is issued. Every handler below funnels through it so
  /// the merge, the error disposition and the refetch cannot drift apart.
  Future<void> _save(
    Emitter<AccountPreferencesState> emit,
    CitizenPreferences next,
  ) async {
    // `savePrefs.error` is cleared when a new attempt starts, matching
    // `useMutation`'s `setError(null)` at `hooks.ts:104`.
    emit(state.copyWith(saving: true, saveError: null));

    final Either<Failure, CitizenPreferences> result =
        await savePreferences(SavePreferencesParams(next));
    if (emit.isDone) return;

    // `catch { /* savePrefs.error carries the message */ }` — `:260-262`. On
    // failure the panel shows the message and **does not refetch**: the
    // `prefsQuery.refetch()` at `:259` sits inside the `try`, after the await
    // that threw.
    if (result.isLeft()) {
      emit(state.copyWith(
        saving: false,
        saveError: result.fold((Failure f) => f.message, (_) => null),
      ));
      return;
    }

    emit(state.copyWith(saving: false));
    if (emit.isDone) return;
    // `prefsQuery.refetch()` — `:259`. The refetch, not the PUT's echo, is what
    // moves the switch. See the library doc.
    await _load(emit);
  }

  Future<void> _onNotificationToggled(
    AccountNotificationToggled event,
    Emitter<AccountPreferencesState> emit,
  ) async {
    final CitizenPreferences? prefs = state.preferences;
    if (prefs == null) return; // `if (!prefs) return` — `:251`

    await _save(
      emit,
      prefs.merge(
        inApp: event.channel == NotificationChannel.inApp ? event.enabled : null,
        email: event.channel == NotificationChannel.email ? event.enabled : null,
        sms: event.channel == NotificationChannel.sms ? event.enabled : null,
      ),
    );
  }

  Future<void> _onBiometricToggled(
    AccountBiometricToggled event,
    Emitter<AccountPreferencesState> emit,
  ) async {
    final CitizenPreferences? prefs = state.preferences;
    if (prefs == null) return;

    // `updatePrefs({ biometric_login: next })` — `:668`.
    await _save(emit, prefs.merge(biometricLogin: event.enabled));
  }

  Future<void> _onLanguageSelected(
    AccountLanguageSelected event,
    Emitter<AccountPreferencesState> emit,
  ) async {
    final CitizenPreferences? prefs = state.preferences;
    if (prefs == null) return;

    // `updatePrefs({ language: code })` — `:622`. **This is the SECOND of
    // R-25's two mirrors** (specs.md § 2.2 Finding H): the top-bar toggle
    // writes `preferred_lang` via `PATCH /me/profile`, this row writes
    // `language` via `PUT /me/preferences`. Two endpoints, two field names,
    // both live in the shipped app, and B8 ports both rather than collapsing
    // them into one (B8-AC-18).
    //
    // `setLang(code)` at `:621` runs first and is the **widget's**: it needs a
    // `BuildContext` for `EasyLocalization`. See `language_panel.dart`.
    await _save(emit, prefs.merge(language: event.code));
  }
}
