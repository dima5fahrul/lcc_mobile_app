/// **The page's half of the upload — the picker seam and the second refresh.**
///
/// `account_avatar_test.dart` covers the header widget and the BLoC. Two links
/// in the chain sit in neither, and both are the kind that a green suite can
/// hide:
///
/// 1. **`_pickAvatar`** — `handleAvatar`'s first three lines
///    (`AccountPage.tsx:234-237`). A cancelled pick must do **nothing**, and a
///    successful one must dispatch. Neither is observable from the header (it
///    only knows a callback fired) or from the BLoC (it only sees events that
///    were already dispatched).
/// 2. **The session refresh** — `await session.refresh()` at `:241`, which the
///    page's second `BlocListener` owns because a BLoC has no context. B8a's
///    equivalent for the *profile save* is `account_page_test.dart`'s
///    `B8-AC-51`; this is the same claim for the avatar, and the two listeners
///    are deliberately separate objects so a change to one cannot silently
///    change the other.
///
/// ## Why this file does not go through the real router
///
/// `account_page_test.dart` pumps the assembled app, which is the right
/// instrument for everything it asserts. It cannot be used here: the router
/// builds `AccountPage()` with no arguments, so `pickAvatar` is the **real**
/// `file_picker` platform channel and a tap would reach a method channel with
/// no implementation. So this file provides the BLoCs itself and injects a
/// fake picker — the `ResidentFilePicker` seam, used as designed.
///
/// ## Fixtures are synthetic — B8-AC-35
library;

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lcc_mobile_app/core/session/bloc/session_bloc.dart';
import 'package:lcc_mobile_app/core/usecase/usecase.dart';
import 'package:lcc_mobile_app/features/account/domain/entities/citizen_document.dart';
import 'package:lcc_mobile_app/features/account/domain/entities/picked_avatar.dart';
import 'package:lcc_mobile_app/features/account/domain/usecases/account_usecases.dart';
import 'package:lcc_mobile_app/features/account/presentation/bloc/account_documents_bloc.dart';
import 'package:lcc_mobile_app/features/account/presentation/bloc/account_preferences_bloc.dart';
import 'package:lcc_mobile_app/features/account/presentation/bloc/account_profile_bloc.dart';
import 'package:lcc_mobile_app/features/account/presentation/pages/account_page.dart';
import 'package:lcc_mobile_app/features/account/presentation/widgets/account_header.dart';
import 'package:lcc_mobile_app/features/account/presentation/widgets/avatar_picker.dart';
import 'package:mocktail/mocktail.dart';

import '../account_test_helper.dart';

class MockSessionBloc extends MockBloc<SessionEvent, SessionState>
    implements SessionBloc {}

void main() {
  late MockGetProfileUseCase getProfile;
  late MockUpdateProfileUseCase updateProfile;
  late MockChangePassword changePassword;
  late MockUploadAvatar uploadAvatar;
  late MockGetPreferences getPreferences;
  late MockSavePreferences savePreferences;
  late MockGetDocuments getDocuments;
  late MockSessionBloc session;

  setUpAll(() {
    registerFallbackValue(NoParams());
    registerFallbackValue(UploadAvatarParams(tPickedAvatar()));
    registerFallbackValue(const SessionEvent.refreshProfile());
  });

  setUp(() {
    getProfile = MockGetProfileUseCase();
    updateProfile = MockUpdateProfileUseCase();
    changePassword = MockChangePassword();
    uploadAvatar = MockUploadAvatar();
    getPreferences = MockGetPreferences();
    savePreferences = MockSavePreferences();
    getDocuments = MockGetDocuments();

    when(() => getProfile(any())).thenAnswer((_) async => ok(tProfile()));
    when(() => getPreferences(any()))
        .thenAnswer((_) async => ok(tPreferences()));
    when(() => getDocuments(any()))
        .thenAnswer((_) async => ok(<CitizenDocument>[tDocument()]));

    session = MockSessionBloc();
    whenListen(
      session,
      const Stream<SessionState>.empty(),
      initialState: const SessionState(status: SessionStatus.authenticated),
    );
  });

  Future<void> pumpPage(
    WidgetTester tester, {
    required AvatarFilePicker picker,
  }) async {
    await pumpAccountWidget(
      tester,
      AccountPage(pickAvatar: picker),
      providers: <BlocProvider<StateStreamableSource<Object?>>>[
        BlocProvider<SessionBloc>.value(value: session),
        BlocProvider<AccountProfileBloc>(
          create: (_) => AccountProfileBloc(
            getProfile: getProfile,
            updateProfile: updateProfile,
            changePassword: changePassword,
            uploadAvatar: uploadAvatar,
          ),
        ),
        BlocProvider<AccountPreferencesBloc>(
          create: (_) => AccountPreferencesBloc(
            getPreferences: getPreferences,
            savePreferences: savePreferences,
          ),
        ),
        BlocProvider<AccountDocumentsBloc>(
          create: (_) => AccountDocumentsBloc(getDocuments: getDocuments),
        ),
      ],
    );
  }

  // A local `final`, not a getter: Dart has no getter declarations inside a
  // function body, and `Finder`s are lazy so one instance re-evaluates per use.
  final Finder tapTarget = find.descendant(
    of: find.byType(AccountHeader),
    matching: find.byType(GestureDetector),
  );

  testWidgets('a CANCELLED pick does nothing — no upload, and the existing '
      'avatar is not cleared', (WidgetTester tester) async {
    // `const file = e.target.files?.[0]; … if (!file) return;` — `:235-237`.
    // The early return is *after* the input is cleared, so cancelling leaves
    // the citizen exactly where they were. There is no avatar DELETE anywhere
    // in `endpoints.ts`, so "cancel clears the photo" would be a capability
    // invented by the port.
    int pickerCalls = 0;
    await pumpPage(tester, picker: () async {
      pickerCalls++;
      return null;
    });

    await tester.tap(tapTarget);
    await tester.pumpAndSettle();

    expect(pickerCalls, 1, reason: 'the picker DID open — otherwise this case '
        'passes for the wrong reason');
    verifyNever(() => uploadAvatar(any()));
    verifyNever(() => session.add(any()));
  });

  testWidgets('a successful pick uploads THAT file — the same bytes and the '
      'same name reach the use case', (WidgetTester tester) async {
    when(() => uploadAvatar(any())).thenAnswer((_) async => ok('url'));

    final PickedAvatar picked = tPickedAvatar(name: 'chosen.jpg');
    await pumpPage(tester, picker: () async => picked);

    await tester.tap(tapTarget);
    await tester.pumpAndSettle();

    // The captured argument, not merely "something was uploaded": a page that
    // dispatched a freshly-constructed empty `PickedAvatar` would pass a
    // `verify(...).called(1)`.
    final UploadAvatarParams params =
        verify(() => uploadAvatar(captureAny())).captured.single
            as UploadAvatarParams;
    expect(identical(params.file, picked), isTrue,
        reason: 'the file the picker returned is the file that is uploaded');
    expect(params.file.name, 'chosen.jpg');
    expect(params.file.bytes, picked.bytes);
  });

  testWidgets('a successful upload dispatches SessionRefreshProfile — '
      '`await session.refresh()`, `AccountPage.tsx:241`',
      (WidgetTester tester) async {
    when(() => uploadAvatar(any())).thenAnswer((_) async => ok('url'));

    await pumpPage(tester, picker: () async => tPickedAvatar());

    await tester.tap(tapTarget);
    await tester.pumpAndSettle();

    // Without the page's second `BlocListener` the upload would land and the
    // shell's own copy of the citizen's avatar would stay stale until the next
    // cold boot — exactly the gap B8-AC-51 names for the profile save.
    verify(() => session.add(const SessionEvent.refreshProfile())).called(1);
  });

  testWidgets('a FAILED upload dispatches nothing and shows nothing — GG-7',
      (WidgetTester tester) async {
    when(() => uploadAvatar(any()))
        .thenAnswer((_) async => err<String>('boom'));

    await pumpPage(tester, picker: () async => tPickedAvatar());

    await tester.tap(tapTarget);
    await tester.pumpAndSettle();

    verifyNever(() => session.add(any()));
    // The failure text must not have reached the tree by any route. `boom`
    // stands in for the `e.toString()` string `AccountRepositoryImpl._guard`
    // builds for a non-`ApiException` — the surviving half of `MAJOR-1`
    // (`security-review-b8b.md` § 5.1 consequence 2). B8b constructs it and
    // drops it; this is the assertion that it is still dropped.
    expect(find.textContaining('boom'), findsNothing);
  });

  testWidgets('B8-AC-54 end to end — tapping twice with the SAME file uploads '
      'twice', (WidgetTester tester) async {
    when(() => uploadAvatar(any())).thenAnswer((_) async => ok('url'));

    final PickedAvatar same = tPickedAvatar();
    await pumpPage(tester, picker: () async => same);

    await tester.tap(tapTarget);
    await tester.pumpAndSettle();
    await tester.tap(tapTarget);
    await tester.pumpAndSettle();

    // Through the whole chain this time — widget, page and BLoC — because the
    // memoisation `e.target.value = ""` defends against could be introduced at
    // any of the three.
    verify(() => uploadAvatar(any())).called(2);
    verify(() => session.add(const SessionEvent.refreshProfile())).called(2);
  });
}
