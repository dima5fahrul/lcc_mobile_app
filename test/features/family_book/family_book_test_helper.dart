/// Doubles and fixtures shared by F4's tests.
///
/// ## Everything a household fixture here contains, WE WROTE
///
/// `specs.md` § 6.4: there is no `/me/family-book` payload anywhere in this
/// repository, and inventing one and feeding it to a fidelity tier is § 8.3's
/// first blocking condition. So [householdFixture] exists, and it is fenced:
/// it feeds **structure** tests only — which field appears, in which order,
/// under which label — and no test built on it is reported as fidelity
/// (`F4-NV-2`).
///
/// The fidelity claim for the populated states lives in
/// `family_book_derivations_test.dart`, whose inputs are transcribed from the
/// pinned source rather than invented, and in `tier1_family_book_test.dart`,
/// whose four views need no household at all.
library;

import 'package:dartz/dartz.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lcc_mobile_app/core/error/failure.dart';
import 'package:lcc_mobile_app/features/application/domain/entities/application_row.dart';
import 'package:lcc_mobile_app/features/application/domain/entities/case_status.dart';
import 'package:lcc_mobile_app/features/application/domain/entities/jurisdiction.dart';
import 'package:lcc_mobile_app/features/family_book/domain/entities/family_book.dart';
import 'package:lcc_mobile_app/features/family_book/domain/entities/household_member.dart';
import 'package:lcc_mobile_app/features/family_book/domain/repositories/family_book_repository.dart';
import 'package:lcc_mobile_app/features/family_book/domain/usecases/family_book_usecases.dart';
import 'package:lcc_mobile_app/features/family_book/presentation/bloc/family_book_cubit.dart';
import 'package:lcc_mobile_app/features/family_book/presentation/pages/family_book_page.dart';
import 'package:lcc_mobile_app/features/session/domain/entities/bilingual.dart';

import '../../helpers/app_test_harness.dart';

/// A repository double whose two answers the test chooses.
///
/// It also **counts calls**, which is what makes `F4-AC-20`'s "zero requests
/// when signed out" an assertion about behaviour rather than about a flag.
class FakeFamilyBookRepository implements FamilyBookRepository {
  FakeFamilyBookRepository({this.book, this.readFailure, this.writeFailure});

  FamilyBook? book;
  Failure? readFailure;
  Failure? writeFailure;

  /// The row the write answers when it succeeds.
  ApplicationRow row = applicationRowFixture();

  int reads = 0;
  int writes = 0;

  /// Every reason string the write was called with, in order. The Tier 0
  /// subject reads this rather than reaching inside the datasource.
  final List<String> reasons = <String>[];

  @override
  Future<Either<Failure, FamilyBook>> getFamilyBook() async {
    reads++;
    final Failure? f = readFailure;
    if (f != null) return Left<Failure, FamilyBook>(f);
    return Right<Failure, FamilyBook>(book ?? const FamilyBook());
  }

  @override
  Future<Either<Failure, ApplicationRow>> requestFamilyBookCopy(
    String reason,
  ) async {
    writes++;
    reasons.add(reason);
    final Failure? f = writeFailure;
    if (f != null) return Left<Failure, ApplicationRow>(f);
    return Right<Failure, ApplicationRow>(row);
  }
}

/// A cubit over [repository], with no container anywhere in the test.
FamilyBookCubit cubitOver(
  FakeFamilyBookRepository repository, {
  bool authenticated = true,
  FamilyBookFeeReader? readFee,
}) =>
    FamilyBookCubit(
      getFamilyBook: GetFamilyBook(repository: repository),
      requestFamilyBookCopy: RequestFamilyBookCopy(repository: repository),
      authenticated: authenticated,
      readFee: readFee,
    );

/// **SYNTHETIC.** See the library doc: structure only, never fidelity.
FamilyBook householdFixture({
  String householdNo = 'HH-0001',
  String headName = 'Somsak Phommachanh',
  String? headIdNo = '01-2345678',
  String unit = '7',
  String group = '3',
  String? address,
  int? totalMembers,
  int? maleMembers,
  int? femaleMembers,
  String? issuedAt = '2024-02-11',
  String? registeredAt = '2023-01-04',
  Jurisdiction? jurisdiction = const Jurisdiction(
    provinceName: 'Vientiane Capital',
    districtName: 'Chanthabouly',
    villageName: 'Ban Sisavath',
  ),
  List<HouseholdMember> members = const <HouseholdMember>[],
}) =>
    FamilyBook(
      householdNo: householdNo,
      headName: headName,
      headIdNo: headIdNo,
      unit: unit,
      group: group,
      address: address,
      totalMembers: totalMembers,
      maleMembers: maleMembers,
      femaleMembers: femaleMembers,
      issuedAt: issuedAt,
      registeredAt: registeredAt,
      jurisdiction: jurisdiction,
      members: members,
    );

/// **SYNTHETIC.** One member, every field the caller does not override left
/// **null** — which is the shape `F4-AC-42` and `F4-AC-69` are about.
HouseholdMember memberFixture({
  String id = 'm-1',
  String? uin,
  String name = '',
  String? gender,
  String? dateOfBirth,
  String? relation,
  String? nationality,
  String? photoUrl,
  String? status,
}) =>
    HouseholdMember(
      id: id,
      uin: uin,
      name: name,
      gender: gender,
      dateOfBirth: dateOfBirth,
      relation: relation,
      nationality: nationality,
      photoUrl: photoUrl,
      status: status,
    );

/// **SYNTHETIC.** The created case the write answers.
ApplicationRow applicationRowFixture({
  String referenceNo = 'APP-2026-000123',
  Bilingual statusLabel = const Bilingual(en: 'Submitted', lo: 'ສົ່ງແລ້ວ'),
}) =>
    ApplicationRow(
      id: 'app-1',
      referenceNo: referenceNo,
      serviceCode: 'family-book',
      serviceName: const Bilingual(en: 'Family Book', lo: 'ປຶ້ມສຳມະໂນຄົວ'),
      applicant: 'Somsak Phommachanh',
      subjectName: 'Somsak Phommachanh',
      status: CaseStatus.submitted,
      statusLabel: statusLabel,
      paymentState: PaymentState.free,
      feeLak: 0,
      channel: 'portal',
      jurisdiction: Jurisdiction.empty,
      slaDays: 3,
      daysWaiting: 0,
      daysOverdue: 0,
      isOverdue: false,
      createdAt: '2026-08-18T09:00:00Z',
      updatedAt: '2026-08-18T09:00:00Z',
    );

/// Tears the previous mount down so the next one builds a **fresh** element
/// tree.
///
/// Both pump helpers below produce the same widget shape, so a second call
/// inside one `testWidgets` body makes Flutter *update* the existing elements
/// rather than rebuild them — and two `initState`s that the test is relying on
/// silently do not run a second time:
///
/// * **`_FamilyBookPageState.initState`**, which is the only caller of
///   `cubit.load()`. The second cubit is therefore never read, the page sits on
///   `loading` forever, and every step-2 / step-3 assertion after it fails
///   against a skeleton.
/// * **`EasyLocalization.initState`**, which is the only reader of
///   `startLocale`. The second mount stays in the first mount's language. That
///   one is worse than a red test: it would let `F4-AC-31`'s cross-locale
///   assertion pass **without the locale ever having changed**, which is
///   precisely the Capability-Rule failure that criterion exists to catch.
///
/// **The page is right and this harness was wrong.** `:200`'s `useQuery` fires
/// on *mount*; `_FamilyBookPageState` reproduces that in `initState`; and the
/// running app never swaps a cubit under a mounted page — the route builder
/// constructs one per visit. Teaching the page to reload on a cubit swap would
/// be a behaviour `FamilyBookPage.tsx` has no analogue for, invented to serve a
/// test.
Future<void> _unmount(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox.shrink());
}

/// Pumps the page with no container and no `DependencyInjection.init()`.
///
/// **Not `pumpAndSettle`.** The CTA's pending spinner and the loading state's
/// indicator both animate indefinitely, and `pumpAndSettle` waits for a frame
/// budget that never empties — the same hazard
/// `resident_page_widget_test.dart` records. Three pumps: build, resolve the
/// mount-time futures, then advance past the first animation tick.
Future<void> pumpFamilyBookPage(
  WidgetTester tester,
  FamilyBookCubit cubit, {
  Locale locale = const Locale('en'),
  VoidCallback? onBack,
}) async {
  await _unmount(tester);
  await tester.pumpWidget(
    wrapWithLocalization(
      startLocale: locale,
      Builder(
        builder: (BuildContext context) => MaterialApp(
          localizationsDelegates: context.localizationDelegates,
          supportedLocales: context.supportedLocales,
          locale: context.locale,
          home: Scaffold(
            body: FamilyBookPage(cubit: cubit, onBack: onBack ?? () {}),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
  await tester.pump(Duration.zero);
  await tester.pump(const Duration(milliseconds: 100));
}

/// One frame only — the mount-time futures have **not** resolved.
///
/// `F4-AC-35` needs exactly this: a signed-out mount must render the signed-out
/// card on its very first frame, never the skeleton, and settling would hide a
/// one-frame skeleton entirely.
Future<void> mountFamilyBookPage(
  WidgetTester tester,
  FamilyBookCubit cubit, {
  Locale locale = const Locale('en'),
}) async {
  await _unmount(tester);
  await tester.pumpWidget(
    wrapWithLocalization(
      startLocale: locale,
      Builder(
        builder: (BuildContext context) => MaterialApp(
          localizationsDelegates: context.localizationDelegates,
          supportedLocales: context.supportedLocales,
          locale: context.locale,
          home: Scaffold(
            body: FamilyBookPage(cubit: cubit, onBack: () {}),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
}
