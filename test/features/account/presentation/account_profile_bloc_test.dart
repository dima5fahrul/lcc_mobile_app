/// **`AccountProfileBloc` — the diff write and the password form.
/// B8-AC-31(iv), B8-AC-49, B8-AC-50, B8-AC-51, B8-AC-45.**
///
/// Tier 0 gates the *body*; this file gates the behaviour around it — whether a
/// request is issued at all, in what order the two client password rules fire,
/// and which state the page's `session.refresh()` listener keys on.
library;

import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lcc_mobile_app/core/error/failure.dart';
import 'package:lcc_mobile_app/core/network/api_exception.dart';
import 'package:lcc_mobile_app/core/network/envelope.dart';
import 'package:lcc_mobile_app/core/usecase/usecase.dart';
import 'package:lcc_mobile_app/features/account/presentation/bloc/account_profile_bloc.dart';
import 'package:lcc_mobile_app/features/account/presentation/bloc/account_region_status.dart';
import 'package:lcc_mobile_app/features/auth/domain/usecases/change_password.dart';
import 'package:lcc_mobile_app/features/session/domain/entities/citizen_profile.dart';
import 'package:lcc_mobile_app/features/session/domain/entities/profile_update.dart';
import 'package:lcc_mobile_app/features/session/domain/usecases/update_profile.dart';
import 'package:mocktail/mocktail.dart';

import '../account_test_helper.dart';

void main() {
  late MockGetProfileUseCase getProfile;
  late MockUpdateProfileUseCase updateProfile;
  late MockChangePassword changePassword;

  setUpAll(() {
    registerFallbackValue(NoParams());
    registerFallbackValue(const UpdateProfileParams(ProfileUpdate()));
    registerFallbackValue(const ChangePasswordParams(
      currentPassword: '',
      newPassword: '',
    ));
  });

  setUp(() {
    getProfile = MockGetProfileUseCase();
    updateProfile = MockUpdateProfileUseCase();
    changePassword = MockChangePassword();
    when(() => getProfile(any()))
        .thenAnswer((_) async => ok<CitizenProfile>(tProfile()));
  });

  AccountProfileBloc build() => AccountProfileBloc(
        getProfile: getProfile,
        updateProfile: updateProfile,
        changePassword: changePassword,
      );

  Future<AccountProfileBloc> loaded() async {
    final AccountProfileBloc bloc = build();
    addTearDown(bloc.close);
    bloc.add(const AccountProfileRequested());
    await bloc.stream.firstWhere((AccountProfileState s) => s.profile != null);
    return bloc;
  }

  // ── B8-AC-31 case (iv) — an unchanged form issues NO request ──────────────

  group('B8-AC-31 (iv) — nothing changed means NO REQUEST, not an empty one',
      () {
    test('zero invocations, and `nothingChanged` on the state', () async {
      final AccountProfileBloc bloc = await loaded();

      bloc.add(const AccountProfileSaved(
        name: 'Somchai Vongsa',
        email: 'somchai.vongsa@example.test',
        address: 'Ban Synthetic, Sisattanak, Vientiane',
      ));
      await bloc.stream.firstWhere(
        (AccountProfileState s) => s.saveOutcome != SaveOutcome.none,
      );

      // The invocation count is the assertion. A test that only checked the
      // note would pass with a PATCH being issued alongside it — and an empty
      // PATCH against a government profile is not nothing, it is a write with
      // no fields whose server-side semantics nobody has measured.
      verifyNever(() => updateProfile(any()));
      expect(bloc.state.saveOutcome, SaveOutcome.nothingChanged);
      expect(bloc.state.saving, isFalse);
    });

    test('clearing ONLY the name is also a no-request case', () async {
      final AccountProfileBloc bloc = await loaded();

      bloc.add(const AccountProfileSaved(
        name: '   ',
        email: 'somchai.vongsa@example.test',
        address: 'Ban Synthetic, Sisattanak, Vientiane',
      ));
      await bloc.stream.firstWhere(
        (AccountProfileState s) => s.saveOutcome != SaveOutcome.none,
      );

      verifyNever(() => updateProfile(any()));
      expect(bloc.state.saveOutcome, SaveOutcome.nothingChanged);
      // The other implementation would have PATCHed `{"name": ""}` here and
      // blanked the citizen's name. See `tier0_account_payload_test.dart`.
    });

    test('a real edit DOES issue exactly one request', () async {
      final AccountProfileBloc bloc = await loaded();
      when(() => updateProfile(any()))
          .thenAnswer((_) async => ok<CitizenProfile>(tProfile()));

      bloc.add(const AccountProfileSaved(
        name: 'Somchai Vongsa',
        email: 'changed@example.test',
        address: 'Ban Synthetic, Sisattanak, Vientiane',
      ));
      await bloc.stream.firstWhere(
        (AccountProfileState s) => s.saveOutcome == SaveOutcome.saved,
      );

      verify(() => updateProfile(any())).called(1);
    });
  });

  // ── B8-AC-51 — refetch AND session refresh ────────────────────────────────

  test('B8-AC-51 — a successful save refetches the profile and signals the '
      'session refresh', () async {
    final AccountProfileBloc bloc = await loaded();
    when(() => updateProfile(any()))
        .thenAnswer((_) async => ok<CitizenProfile>(tProfile()));

    bloc.add(const AccountProfileSaved(
      name: 'Somchai Vongsa',
      email: 'changed@example.test',
      address: 'Ban Synthetic, Sisattanak, Vientiane',
    ));
    await bloc.stream.firstWhere(
      (AccountProfileState s) =>
          s.saveOutcome == SaveOutcome.saved && !s.saving,
    );
    // Let the refetch that follows the emit complete.
    await bloc.stream.firstWhere(
      (AccountProfileState s) => s.status == RegionStatus.success,
    );

    // Half one: `profileQuery.refetch()` — the mount fetch plus one more.
    verify(() => getProfile(any())).called(2);

    // Half two: `session.refresh()`. The BLoC has no context, so it publishes
    // `SaveOutcome.saved` and `account_page.dart`'s `BlocListener` dispatches
    // `SessionRefreshProfile`. Asserted here as the signal, and in
    // `account_page_test.dart` as the dispatch.
    expect(bloc.state.saveOutcome, SaveOutcome.saved);
  });

  // ── B8-AC-49 — per-field errors, and the field that has none ──────────────

  test('B8-AC-49 — a 422 populates `fieldErrors` from the server\'s field map',
      () async {
    final AccountProfileBloc bloc = await loaded();
    when(() => updateProfile(any())).thenThrow(const ApiException(
      status: 422,
      code: 'VALIDATION_ERROR',
      message: 'The given data was invalid.',
      fields: <FieldError>[
        FieldError(field: 'name', message: 'The name field is required.'),
        FieldError(field: 'email', message: 'The email must be valid.'),
        FieldError(field: 'address', message: 'The address is too long.'),
      ],
    ));

    bloc.add(const AccountProfileSaved(
      name: 'x',
      email: 'not-an-email',
      address: 'y',
    ));
    await bloc.stream.firstWhere((AccountProfileState s) => !s.saving);

    expect(bloc.state.fieldErrors['name'], 'The name field is required.');
    expect(bloc.state.fieldErrors['email'], 'The email must be valid.');
    // `address` IS in the map — the server sent it — and the widget renders no
    // slot for it, matching the source (`AccountPage.tsx:534-543` has no error
    // paragraph). The BLoC keeps it so the divergence lives at the render site
    // where it is documented, not in a silently-dropped key.
    expect(bloc.state.fieldErrors['address'], 'The address is too long.');
    expect(bloc.state.saveError, 'The given data was invalid.');
  });

  // ── B8-AC-50 — the two client password rules, in order ────────────────────

  group('B8-AC-50 — password validation ports both rules IN ORDER', () {
    test('`< 8` wins over a mismatch — order is observable', () async {
      final AccountProfileBloc bloc = await loaded();

      // "abc" is BOTH too short AND different from its confirmation. The
      // source checks length first (`:276` then `:277`), so the citizen is
      // told about the length. A port that checked equality first would say
      // "the two passwords do not match", which is true and unhelpful.
      bloc.add(const AccountPasswordSubmitted(
        currentPassword: 'whatever',
        newPassword: 'abc',
        confirmPassword: 'different',
      ));
      await bloc.stream.firstWhere(
        (AccountProfileState s) => s.passwordError != PasswordError.none,
      );

      expect(bloc.state.passwordError, PasswordError.tooShort);
      verifyNever(() => changePassword(any()));
    });

    test('a long-enough mismatch reports the mismatch', () async {
      final AccountProfileBloc bloc = await loaded();

      bloc.add(const AccountPasswordSubmitted(
        currentPassword: 'whatever',
        newPassword: 'long-enough-01',
        confirmPassword: 'long-enough-02',
      ));
      await bloc.stream.firstWhere(
        (AccountProfileState s) => s.passwordError != PasswordError.none,
      );

      expect(bloc.state.passwordError, PasswordError.mismatch);
      verifyNever(() => changePassword(any()));
    });

    test('exactly 8 characters passes the length rule — the boundary', () async {
      final AccountProfileBloc bloc = await loaded();
      when(() => changePassword(any()))
          .thenAnswer((_) async => const Right<Failure, Unit>(unit));

      bloc.add(const AccountPasswordSubmitted(
        currentPassword: 'whatever',
        newPassword: '12345678',
        confirmPassword: '12345678',
      ));
      await bloc.stream
          .firstWhere((AccountProfileState s) => s.passwordChanged);

      expect(bloc.state.passwordError, PasswordError.none);
      verify(() => changePassword(any())).called(1);
    });

    test('success clears the form and notes it; `confirm` never reaches the '
        'use case', () async {
      final AccountProfileBloc bloc = await loaded();
      when(() => changePassword(any()))
          .thenAnswer((_) async => const Right<Failure, Unit>(unit));

      bloc.add(const AccountPasswordSubmitted(
        currentPassword: 'synthetic-current-pw',
        newPassword: 'synthetic-new-pw-01',
        confirmPassword: 'synthetic-new-pw-01',
      ));
      await bloc.stream
          .firstWhere((AccountProfileState s) => s.passwordChanged);

      expect(bloc.state.passwordChanged, isTrue);
      expect(bloc.state.passwordServerError, isNull);

      final ChangePasswordParams captured =
          verify(() => changePassword(captureAny())).captured.single
              as ChangePasswordParams;
      expect(captured.currentPassword, 'synthetic-current-pw');
      expect(captured.newPassword, 'synthetic-new-pw-01');
      // `ChangePasswordParams` has no `confirm` field at all, so there is
      // nothing to leak — B8-AC-34's structural half.
      expect(captured.props, hasLength(2));
    });

    test('a server rejection surfaces the SERVER\'S message, verbatim',
        () async {
      final AccountProfileBloc bloc = await loaded();
      when(() => changePassword(any())).thenAnswer(
        (_) async => err<Unit>('Your current password is incorrect.'),
      );

      bloc.add(const AccountPasswordSubmitted(
        currentPassword: 'wrong',
        newPassword: 'long-enough-01',
        confirmPassword: 'long-enough-01',
      ));
      await bloc.stream.firstWhere(
        (AccountProfileState s) => s.passwordServerError != null,
      );

      // `setPwError((err as Error).message)` — `:284`. That a credential
      // endpoint's raw message reaches the UI is a measured property of the
      // oracle (specs.md § 6.8 item 3), ported rather than sanitised, and on
      // the security review's agenda.
      expect(
        bloc.state.passwordServerError,
        'Your current password is incorrect.',
      );
      expect(bloc.state.passwordChanged, isFalse);
    });
  });

  // ── B8-AC-45 — nothing about a password is on the state ───────────────────

  test('B8-AC-45 — no password value is ever stored on the state', () async {
    final AccountProfileBloc bloc = await loaded();
    when(() => changePassword(any()))
        .thenAnswer((_) async => const Right<Failure, Unit>(unit));

    const String secret = 'synthetic-new-pw-01';
    bloc.add(const AccountPasswordSubmitted(
      currentPassword: 'synthetic-current-pw',
      newPassword: secret,
      confirmPassword: secret,
    ));
    await bloc.stream.firstWhere((AccountProfileState s) => s.passwordChanged);

    // `freezed`'s generated `toString` prints every field. If a password ever
    // lands on this state, this catches it — including via a future field
    // someone adds "just for the form".
    expect(bloc.state.toString(), isNot(contains(secret)));
    expect(bloc.state.toString(), isNot(contains('synthetic-current-pw')));
  });

  // ── The read path ─────────────────────────────────────────────────────────

  test('a failed profile read surfaces the API message and offers a retry',
      () async {
    when(() => getProfile(any()))
        .thenAnswer((_) async => err<CitizenProfile>('the registry is down'));

    final AccountProfileBloc bloc = build();
    addTearDown(bloc.close);

    bloc.add(const AccountProfileRequested());
    await bloc.stream.firstWhere(
      (AccountProfileState s) => s.status == RegionStatus.failure,
    );

    expect(bloc.state.hasFailed, isTrue);
    expect(bloc.state.errorMessage, 'the registry is down');

    when(() => getProfile(any()))
        .thenAnswer((_) async => ok<CitizenProfile>(tProfile()));
    bloc.add(const AccountProfileRetried());
    await bloc.stream.firstWhere(
      (AccountProfileState s) => s.status == RegionStatus.success,
    );

    expect(bloc.state.profile, isNotNull);
    expect(bloc.state.errorMessage, isNull);
  });

  test('a 401 on the read does NOT escape as an ApiException — the page shows '
      'a retry, it does not sign the citizen out', () async {
    // `SessionRepositoryImpl.getProfile` rethrows `ApiException` so
    // `SessionBloc` can clear tokens. This page must not inherit that branch:
    // `profileQuery.error` renders a message and a button whatever the status
    // was (`AccountPage.tsx:380-389`).
    when(() => getProfile(any())).thenThrow(const ApiException(
      status: 401,
      code: 'UNAUTHORIZED',
      message: 'a bearer token is required',
    ));

    final AccountProfileBloc bloc = build();
    addTearDown(bloc.close);

    bloc.add(const AccountProfileRequested());
    await bloc.stream.firstWhere(
      (AccountProfileState s) => s.status == RegionStatus.failure,
    );

    expect(bloc.state.errorMessage, 'a bearer token is required');
  });
}
