/// Hand-written fakes for the four write methods, plus the fixtures the
/// certificate wizard's tests need.
///
/// ## Why hand-written and not `mocktail`
///
/// The criteria this file serves are about **order and count**: create runs
/// once across a retry (`F1-AC-56`), update runs on every attempt
/// (`F1-AC-57`), attachments upload sequentially in a fixed order and skip an
/// already-sent slot (`F1-AC-58`). A `verify(...).called(1)` says how many
/// times; it does not say *in what order relative to the others*, and
/// `verifyInOrder` over four different mocks is less readable than one log
/// list. [FakeApplicationRepository.log] is that list.
///
/// It also keeps the envelopes: `F1-AC-21`'s wire order is asserted at the
/// datasource, but the cubit's own composition — `form_data` last on create,
/// first on update, `header.ref_no` appended last — has to be read off what the
/// cubit *passed*, which is what [lastCreateEnvelope] and [lastUpdateEnvelope]
/// hold.
///
/// It lives under `test/features/application/` because that is the feature that
/// owns the four methods (`specs.md` § 3.1 row 9).
library;

import 'package:dartz/dartz.dart';
import 'package:lcc_mobile_app/core/error/failure.dart';
import 'package:lcc_mobile_app/features/application/domain/entities/application_detail.dart';
import 'package:lcc_mobile_app/features/application/domain/entities/application_row.dart';
import 'package:lcc_mobile_app/features/application/domain/entities/case_status.dart';
import 'package:lcc_mobile_app/features/application/domain/entities/jurisdiction.dart';
import 'package:lcc_mobile_app/features/application/domain/entities/picked_attachment.dart';
import 'package:lcc_mobile_app/features/application/domain/repositories/application_repository.dart';
import 'package:lcc_mobile_app/features/service/domain/entities/service.dart';
import 'package:lcc_mobile_app/features/session/domain/entities/bilingual.dart';

const Bilingual kAnyBilingual = Bilingual(en: 'x', lo: 'x');

ApplicationRow applicationRowFixture({
  String id = 'case-1',
  String reference = 'LCC-2026-000123',
  int feeLak = 20000,
  String subjectName = 'Somchai',
}) =>
    ApplicationRow(
      id: id,
      referenceNo: reference,
      serviceCode: 'resident',
      serviceName: kAnyBilingual,
      applicant: 'Somchai',
      subjectName: subjectName,
      status: CaseStatus.submitted,
      statusLabel: const Bilingual(en: 'Submitted', lo: 'ສົ່ງແລ້ວ'),
      paymentState: PaymentState.pending,
      feeLak: feeLak,
      channel: 'mobile',
      jurisdiction: const Jurisdiction(),
      slaDays: 5,
      daysWaiting: 0,
      daysOverdue: 0,
      isOverdue: false,
      createdAt: '2026-08-14',
      updatedAt: '2026-08-14',
    );

ApplicationDetail applicationDetailFixture({
  String id = 'case-1',
  String reference = 'LCC-2026-000123',
  int feeLak = 20000,
  String subjectName = 'Somchai',
}) =>
    ApplicationDetail(
      row: applicationRowFixture(
        id: id,
        reference: reference,
        feeLak: feeLak,
        subjectName: subjectName,
      ),
    );

Service serviceFixture({int feeLak = 20000}) => Service(
      id: 'svc-1',
      code: 'resident',
      categoryId: 'cat-1',
      categoryCode: 'civil',
      name: const Bilingual(en: 'Residence Certificate', lo: 'ໃບຢັ້ງຢືນ'),
      shortName: 'Residence',
      description: kAnyBilingual,
      icon: 'FileText',
      color: '#344EAD',
      feeLak: feeLak,
      feeMaxLak: feeLak,
      feeIsRange: false,
      slaDays: 5,
      processingTime: const Bilingual(en: '3-5 working days', lo: '3-5 ວັນ'),
      requiredDocs: const <Bilingual>[],
      requiresPayment: true,
      isPhase1: true,
      active: true,
      sortOrder: 1,
      routePath: '/services/resident',
      familyBookEffect: 'none',
    );

/// Records every write in order, and keeps the envelopes it was handed.
class FakeApplicationRepository implements ApplicationRepository {
  /// One entry per write, in call order. `'attach:<slot>'` for an upload.
  final List<String> log = <String>[];

  Map<String, Object?>? lastCreateEnvelope;
  Map<String, Object?>? lastUpdateEnvelope;

  /// The `fee_lak` the **submit** answer carries — the value the pay branch
  /// reads (`:535`). Distinct from the created case's, because the source reads
  /// it off `decided` and not off `created`.
  int submitFeeLak = 20000;

  /// Makes `submit` answer a plain failure, for the retry criteria.
  bool failSubmit = false;

  /// A specific failure for `submit` — used by the 422 and non-422 criteria.
  Failure? submitFailure;

  @override
  Future<Either<Failure, ApplicationDetail>> createApplication(
    Map<String, Object?> envelope,
  ) async {
    log.add('create');
    lastCreateEnvelope = envelope;
    return Right<Failure, ApplicationDetail>(applicationDetailFixture());
  }

  @override
  Future<Either<Failure, ApplicationDetail>> updateApplication(
    String id,
    Map<String, Object?> envelope,
  ) async {
    log.add('update');
    lastUpdateEnvelope = envelope;
    return Right<Failure, ApplicationDetail>(applicationDetailFixture(id: id));
  }

  @override
  Future<Either<Failure, Unit>> addAttachment(
    String id, {
    required PickedAttachment file,
    required String slot,
    required String kind,
    String? label,
  }) async {
    log.add('attach:$slot');
    return const Right<Failure, Unit>(unit);
  }

  @override
  Future<Either<Failure, ApplicationDetail>> submitApplication(String id) async {
    log.add('submit');
    final Failure? f = submitFailure;
    if (f != null) return Left<Failure, ApplicationDetail>(f);
    if (failSubmit) {
      return const Left<Failure, ApplicationDetail>(Failure('submit refused'));
    }
    return Right<Failure, ApplicationDetail>(
      applicationDetailFixture(feeLak: submitFeeLak),
    );
  }

  // ── The read half is not this fake's business ──────────────────────────────
  //
  // The certificate wizard calls none of them; a fake that answered would be a
  // capability the subject under test does not have.

  @override
  Future<Either<Failure, Object?>> noSuchMethod(Invocation invocation) =>
      throw UnimplementedError(
        'ResidentFormCubit calls only the four writes; '
        '${invocation.memberName} is not one of them.',
      );
}
