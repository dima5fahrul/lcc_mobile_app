/// **`AccountPreferencesBloc` — the whole-object PUT and its refetch.
/// B8-AC-17, B8-AC-33 (behaviour half), B8-AC-28-adjacent states.**
///
/// Tier 0 gates the *body* the merge produces. This file gates what the BLoC
/// does around it: that the merge is fed from the last **read** value, that a
/// failed write does not refetch, and that the switch does not move
/// optimistically.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:lcc_mobile_app/core/usecase/usecase.dart';
import 'package:lcc_mobile_app/features/account/domain/entities/citizen_preferences.dart';
import 'package:lcc_mobile_app/features/account/domain/usecases/account_usecases.dart';
import 'package:lcc_mobile_app/features/account/presentation/bloc/account_preferences_bloc.dart';
import 'package:lcc_mobile_app/features/account/presentation/bloc/account_region_status.dart';
import 'package:mocktail/mocktail.dart';

import '../account_test_helper.dart';

void main() {
  late MockGetPreferences getPreferences;
  late MockSavePreferences savePreferences;

  setUpAll(() {
    registerFallbackValue(NoParams());
    registerFallbackValue(SavePreferencesParams(tPreferences()));
  });

  setUp(() {
    getPreferences = MockGetPreferences();
    savePreferences = MockSavePreferences();
  });

  AccountPreferencesBloc build() => AccountPreferencesBloc(
        getPreferences: getPreferences,
        savePreferences: savePreferences,
      );

  Future<AccountPreferencesBloc> loaded({CitizenPreferences? seed}) async {
    when(() => getPreferences(any()))
        .thenAnswer((_) async => ok<CitizenPreferences>(seed ?? tPreferences()));
    final AccountPreferencesBloc bloc = build();
    addTearDown(bloc.close);
    bloc.add(const AccountPreferencesRequested());
    await bloc.stream.firstWhere(
      (AccountPreferencesState s) => s.preferences != null,
    );
    return bloc;
  }

  // ── B8-AC-33, behaviour half ──────────────────────────────────────────────

  test('B8-AC-33 — toggling ONE switch sends all five fields, built from the '
      'last read value', () async {
    final AccountPreferencesBloc bloc = await loaded(
      seed: tPreferences(
        language: 'lo',
        inApp: true,
        email: false,
        sms: false,
        biometricLogin: true,
      ),
    );
    when(() => savePreferences(any())).thenAnswer(
      (Invocation i) async => ok<CitizenPreferences>(
        (i.positionalArguments.first as SavePreferencesParams).preferences,
      ),
    );

    bloc.add(const AccountNotificationToggled(
      NotificationChannel.sms,
      enabled: true,
    ));
    await bloc.stream.firstWhere((AccountPreferencesState s) => !s.saving);

    final SavePreferencesParams sent =
        verify(() => savePreferences(captureAny())).captured.first
            as SavePreferencesParams;

    // The two UNTOUCHED booleans survive. This is the whole claim: a shallow
    // implementation clears them server-side and the UI still looks right,
    // because the refetch below redraws whatever the server now holds.
    expect(sent.preferences.notifications.inApp, isTrue);
    expect(sent.preferences.notifications.email, isFalse);
    expect(sent.preferences.notifications.sms, isTrue);
    expect(sent.preferences.language, 'lo');
    expect(sent.preferences.biometricLogin, isTrue);
  });

  test('B8-AC-17 — the Language row PUTs the merged object AND is a different '
      'call from the top bar\'s PATCH', () async {
    final AccountPreferencesBloc bloc = await loaded();
    when(() => savePreferences(any())).thenAnswer(
      (Invocation i) async => ok<CitizenPreferences>(
        (i.positionalArguments.first as SavePreferencesParams).preferences,
      ),
    );

    bloc.add(const AccountLanguageSelected('en'));
    await bloc.stream.firstWhere((AccountPreferencesState s) => !s.saving);

    final SavePreferencesParams sent =
        verify(() => savePreferences(captureAny())).captured.first
            as SavePreferencesParams;
    expect(sent.preferences.language, 'en');
    // Everything else rides along, because the endpoint is a PUT.
    expect(sent.preferences.notifications.inApp, isTrue);
  });

  // ── `if (!prefs) return` — `AccountPage.tsx:251` ──────────────────────────

  test('every mutation is a no-op before the first successful read', () async {
    when(() => getPreferences(any()))
        .thenAnswer((_) async => err<CitizenPreferences>('offline'));
    final AccountPreferencesBloc bloc = build();
    addTearDown(bloc.close);

    bloc.add(const AccountPreferencesRequested());
    await bloc.stream.firstWhere(
      (AccountPreferencesState s) => s.status == RegionStatus.failure,
    );

    bloc.add(const AccountNotificationToggled(
      NotificationChannel.email,
      enabled: true,
    ));
    bloc.add(const AccountBiometricToggled(enabled: true));
    bloc.add(const AccountLanguageSelected('en'));
    await Future<void>.delayed(Duration.zero);

    verifyNever(() => savePreferences(any()));
  });

  // ── The refetch, and when it does NOT happen ──────────────────────────────

  test('a successful write refetches; the switch moves only then', () async {
    final AccountPreferencesBloc bloc = await loaded();

    // The server accepts the write but answers with `sms: true` — and the
    // refetch is what the UI reads. `savePrefs.run` + `prefsQuery.refetch()`,
    // `AccountPage.tsx:258-259`.
    when(() => savePreferences(any()))
        .thenAnswer((_) async => ok<CitizenPreferences>(tPreferences(sms: true)));
    when(() => getPreferences(any()))
        .thenAnswer((_) async => ok<CitizenPreferences>(tPreferences(sms: true)));

    bloc.add(const AccountNotificationToggled(
      NotificationChannel.sms,
      enabled: true,
    ));
    await bloc.stream.firstWhere(
      (AccountPreferencesState s) =>
          !s.saving && (s.preferences?.notifications.sms ?? false),
    );

    // Mount read + post-write refetch.
    verify(() => getPreferences(any())).called(2);
    expect(bloc.state.preferences!.notifications.sms, isTrue);
  });

  test('a FAILED write surfaces `saveError` and does NOT refetch', () async {
    final AccountPreferencesBloc bloc = await loaded();
    when(() => savePreferences(any()))
        .thenAnswer((_) async => err<CitizenPreferences>('preferences locked'));

    bloc.add(const AccountBiometricToggled(enabled: true));
    await bloc.stream.firstWhere(
      (AccountPreferencesState s) => s.saveError != null,
    );

    expect(bloc.state.saveError, 'preferences locked');
    // `prefsQuery.refetch()` sits INSIDE the `try`, after the await that threw
    // (`:258-259`), so a failed write refetches nothing. Only the mount read
    // happened.
    verify(() => getPreferences(any())).called(1);
    // And the switch has not moved.
    expect(bloc.state.preferences!.biometricLogin, isFalse);
  });

  test('the switch does NOT move optimistically — the source has no optimistic '
      'update and neither does this', () async {
    final AccountPreferencesBloc bloc = await loaded();

    // A write that never completes within the window we look at.
    when(() => savePreferences(any())).thenAnswer((_) async {
      await Future<void>.delayed(const Duration(milliseconds: 50));
      return ok<CitizenPreferences>(tPreferences(sms: true));
    });

    bloc.add(const AccountNotificationToggled(
      NotificationChannel.sms,
      enabled: true,
    ));
    await bloc.stream.firstWhere((AccountPreferencesState s) => s.saving);

    expect(
      bloc.state.preferences!.notifications.sms,
      isFalse,
      reason: 'the shipped app reads `prefsQuery.data`, which `updatePrefs` '
          'never writes to. Porting an optimistic flip would be an '
          'R-25-class improvement no fidelity tier can see.',
    );
  });

  // ── Read states ───────────────────────────────────────────────────────────

  test('the four read states, and `initial` counts as loading', () async {
    when(() => getPreferences(any()))
        .thenAnswer((_) async => err<CitizenPreferences>('the panel is down'));
    final AccountPreferencesBloc bloc = build();
    addTearDown(bloc.close);

    // `initial` — nothing asked for yet, but the panel must show the skeleton
    // and not a stale empty state.
    expect(bloc.state.isLoading, isTrue);
    expect(bloc.state.hasFailed, isFalse);

    bloc.add(const AccountPreferencesRequested());
    await bloc.stream.firstWhere(
      (AccountPreferencesState s) => s.status == RegionStatus.failure,
    );
    expect(bloc.state.hasFailed, isTrue);
    expect(bloc.state.errorMessage, 'the panel is down');

    when(() => getPreferences(any()))
        .thenAnswer((_) async => ok<CitizenPreferences>(tPreferences()));
    bloc.add(const AccountPreferencesRetried());
    await bloc.stream.firstWhere(
      (AccountPreferencesState s) => s.status == RegionStatus.success,
    );
    expect(bloc.state.preferences, isNotNull);
    expect(bloc.state.errorMessage, isNull);
  });
}
