/// Doubles and synthetic fixtures for the **account** feature.
///
/// Parallel to `notification_test_helper.dart` rather than an extension of the
/// session helper: the two share only `CitizenAccount` / `CitizenProfile`, and
/// a single shared helper would make every account test compile the session
/// repository graph.
///
/// **Every value here is invented** — no real citizen data, no real UIN, no
/// token, no real password (specs.md § 6.11's fixture rule, B8-AC-35).
library;

import 'dart:typed_data';

import 'package:dartz/dartz.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lcc_mobile_app/core/error/failure.dart';
import 'package:lcc_mobile_app/features/account/domain/entities/citizen_document.dart';
import 'package:lcc_mobile_app/features/account/domain/entities/citizen_preferences.dart';
import 'package:lcc_mobile_app/features/account/domain/entities/picked_avatar.dart';
import 'package:lcc_mobile_app/features/account/domain/usecases/account_usecases.dart';
import 'package:lcc_mobile_app/features/auth/domain/usecases/change_password.dart';
import 'package:lcc_mobile_app/features/session/domain/entities/bilingual.dart';
import 'package:lcc_mobile_app/features/session/domain/entities/citizen_account.dart';
import 'package:lcc_mobile_app/features/session/domain/entities/citizen_profile.dart';
import 'package:lcc_mobile_app/features/session/domain/entities/place_names.dart';
import 'package:lcc_mobile_app/features/session/domain/usecases/get_profile.dart';
import 'package:lcc_mobile_app/features/session/domain/usecases/update_profile.dart';
import 'package:lcc_mobile_app/presentation/theme/app_theme.dart';
import 'package:mocktail/mocktail.dart';
import 'package:lcc_mobile_app/features/session/domain/entities/jurisdiction.dart';

import '../../helpers/app_test_harness.dart';

class MockGetPreferences extends Mock implements GetPreferences {}

class MockSavePreferences extends Mock implements SavePreferences {}

class MockGetDocuments extends Mock implements GetDocuments {}

class MockGetProfileUseCase extends Mock implements GetProfile {}

class MockUpdateProfileUseCase extends Mock implements UpdateProfile {}

class MockChangePassword extends Mock implements ChangePassword {}

/// B8b — `POST /me/avatar`.
class MockUploadAvatar extends Mock implements UploadAvatar {}

/// A synthetic picked photograph.
///
/// **Invented, like everything else in this file** (B8-AC-35): the bytes are a
/// four-byte sentinel, not an image, and no real citizen's face is or ever
/// should be in this repository. The upload path never decodes the bytes — that
/// is the whole point of the send-raw ruling — so a sentinel exercises it
/// exactly as a JPEG would, and is the only thing a byte-identity assertion
/// needs.
///
/// The default [name] carries a space and a non-ASCII character on purpose:
/// phone filenames routinely do, they go on the wire unsanitised
/// (`security-review-b8b.md` `B8b-6`, F1's `S-3`), and a fixture of
/// `test.jpg` would not notice if something started escaping them.
PickedAvatar tPickedAvatar({
  String name = 'ຮູບ ຖ່າຍ 2026-08-19.jpg',
  List<int> bytes = const <int>[0xFF, 0xD8, 0xFF, 0xE0],
  String? path,
}) =>
    PickedAvatar(
      name: name,
      bytes: Uint8List.fromList(bytes),
      path: path,
    );

// ── Synthetic entities ───────────────────────────────────────────────────────

CitizenAccount tAccount({
  String name = 'Somchai Vongsa',
  String email = 'somchai.vongsa@example.test',
  String address = 'Ban Synthetic, Sisattanak, Vientiane',
  String phone = '+85620000000',
  String uin = '0000-0000-0000-0000',
  String? avatarUrl,
  bool verified = false,
}) =>
    CitizenAccount(
      id: 'acc_synthetic_b8_0001',
      uin: uin,
      name: name,
      phone: phone,
      email: email,
      nationalIdNo: 'ID-SYNTHETIC-0001',
      dateOfBirth: '1990-01-01',
      gender: 'male',
      avatarUrl: avatarUrl,
      preferredLang: 'lo',
      jurisdiction: const Jurisdiction(provinceName: 'synthetic'),
      householdNo: 'HH-SYNTHETIC-0001',
      address: address,
      verified: verified,
      eidVerified: false,
      active: true,
      createdAt: '2020-01-01T00:00:00Z',
    );

CitizenProfile tProfile({CitizenAccount? account}) => CitizenProfile(
      account: account ?? tAccount(),
      place: const PlaceNames(
        province: Bilingual(en: 'Vientiane', lo: 'ວຽງຈັນ'),
        district: Bilingual(en: 'Sisattanak', lo: 'ສີສັດຕະນາກ'),
        village: Bilingual(en: 'Ban Synthetic', lo: 'ບ້ານ ຊິນເທຕິກ'),
      ),
      householdNo: 'HH-SYNTHETIC-0001',
    );

CitizenPreferences tPreferences({
  String language = 'lo',
  bool inApp = true,
  bool email = false,
  bool sms = false,
  bool biometricLogin = false,
}) =>
    CitizenPreferences(
      language: language,
      notifications: NotificationPreferences(
        inApp: inApp,
        email: email,
        sms: sms,
      ),
      biometricLogin: biometricLogin,
    );

CitizenDocument tDocument({
  String id = 'doc_synthetic_0001',
  String type = 'national_id',
  Bilingual title = const Bilingual(en: 'National ID Card', lo: 'ບັດປະຈຳຕົວ'),
  String number = 'ID-0000-0001',
  DocumentStatus status = DocumentStatus.valid,
  String? issuedAt,
  String? expiresAt,
  bool available = false,
  String? fileUrl,
}) =>
    CitizenDocument(
      id: id,
      type: type,
      title: title,
      number: number,
      status: status,
      issuedAt: issuedAt,
      expiresAt: expiresAt,
      authority: 'Ministry of Home Affairs',
      available: available,
      fileUrl: fileUrl,
    );

// ── Common `Either` shorthands ───────────────────────────────────────────────

Right<Failure, T> ok<T>(T value) => Right<Failure, T>(value);

Left<Failure, T> err<T>(String message) =>
    Left<Failure, T>(Failure(message));

// ── Pumping ──────────────────────────────────────────────────────────────────

/// Pumps [child] under a localised `MaterialApp` with [providers] above it.
///
/// The `Builder` + three delegate lines are load-bearing: without them
/// `.tr()` returns the raw key and every text assertion silently compares
/// against `"account.uin"`. The idiom is `pumpChatPanel`'s.
Future<void> pumpAccountWidget(
  WidgetTester tester,
  Widget child, {
  List<BlocProvider<StateStreamableSource<Object?>>> providers =
      const <BlocProvider<StateStreamableSource<Object?>>>[],
  Locale locale = const Locale('en'),
}) async {
  tester.view.devicePixelRatio = 1.0;
  tester.view.physicalSize = const Size(390, 2400);
  addTearDown(tester.view.reset);

  final Widget body = providers.isEmpty
      ? child
      : MultiBlocProvider(providers: providers, child: child);

  await tester.pumpWidget(wrapWithLocalization(
    Builder(
      builder: (BuildContext context) => MaterialApp(
        theme: AppTheme.light(),
        localizationsDelegates: context.localizationDelegates,
        supportedLocales: context.supportedLocales,
        locale: context.locale,
        home: Scaffold(body: SingleChildScrollView(child: body)),
      ),
    ),
    startLocale: locale,
  ));
  await tester.pumpAndSettle();
}
