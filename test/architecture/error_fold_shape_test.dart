/// **The repo-wide guard on what an `ApiException` becomes.**
///
/// ## Why this file exists
///
/// On 2026-08-18 the same defect was found independently in **three** batches'
/// reviews, in three different repositories, none aware of the others:
///
/// | batch | repository | rating |
/// | --- | --- | --- |
/// | F3 | `ServiceRepositoryImpl` | MAJOR-1 (`GOR-245-f3-marriage-divorce/security-review.md` § 3.2) |
/// | B7 | `ApplicationRepositoryImpl._guard` | MAJOR-1 / `FU-13` (`GOR-245-b7-history/security-review.md` § 4.1) |
/// | B8 | `AccountRepositoryImpl._guard`, `AuthRepositoryImpl.changePassword` | MAJOR-1 (`GOR-245-b8-account-profile/security-review.md` § 4.1) |
///
/// Each folded an `ApiException` with `Failure(e.toString())`, and
/// `ApiException.toString()` (`api_exception.dart:99-100`) is
/// `ApiException($status, $code, $message, requestId: …, N field(s))`. Every one
/// of those repositories feeds a widget that renders `Failure.message`
/// **verbatim**, so a 500 put an internal log-correlation token and a
/// validation-response shape on a citizen's screen.
///
/// **Three independent occurrences is not three mistakes; it is a missing
/// guard.** Each batch's review caught its own and filed its own follow-up, and
/// no instrument existed that would have caught the second one from the first.
/// This is that instrument.
///
/// ## What the criterion actually is
///
/// Not *"never render server text"* — the opposite. `ApiError extends Error`
/// with `super(message)` (`client.ts:61-68`), so in the source
/// `err.message` **is** the backend sentence, and `HistoryPage.tsx:254`,
/// `MarriageCertificatePage.tsx:1591` and `AccountPage.tsx:283-285` all render
/// exactly that. Folding `e.message` makes the Dart value equal the JS value the
/// render sites were written against. Folding `e.toString()` never did.
///
/// So this guard asserts **fidelity**, not hardening. A port that swapped in a
/// fixed bilingual sentence instead would fail the source-fidelity rule from the
/// other direction (`L-10`(b)) — which is why the assertion is on the exact
/// sentence and not merely on the absence of `requestId`.
///
/// ## Why this is a behavioural test and not a source scan
///
/// A grep for `Failure(e.toString())` would pass against a repository that
/// spelled the leak differently, and would fail against the **legitimate**
/// generic arm every one of these repositories still has — a `DioException` or
/// a `FormatException` carries no server-authored sentence to prefer, and its
/// text is what a log needs. The property is *what a caller receives*, so the
/// test drives a real `ApiException` through the real fold and reads the real
/// `Failure`.
///
/// ## What this does NOT cover, stated so silence is not mistaken for coverage
///
/// The four repositories below are the ones with a measured citizen-visible
/// render site. `NewsRepositoryImpl:44` and `WalletRepositoryImpl:44` were also
/// measured folding `e.toString()` on 2026-08-18 and are **not** in this file:
/// news' failure surface renders fixed copy (`news.listError`) and wallet's
/// `payApplication` already folds `PaymentFailure(e.message, e.code)` on its
/// `ApiException` arm. Neither was re-measured against a render site in this
/// pass, so neither is asserted here rather than being asserted wrongly. Adding
/// them needs the render-site measurement first.
library;

import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lcc_mobile_app/core/error/failure.dart';
import 'package:lcc_mobile_app/core/network/api_exception.dart';
import 'package:lcc_mobile_app/features/account/data/datasources/account_remote_datasource.dart';
import 'package:lcc_mobile_app/features/account/data/repositories/account_repository_impl.dart';
import 'package:lcc_mobile_app/features/account/domain/entities/citizen_document.dart';
import 'package:lcc_mobile_app/features/account/domain/entities/citizen_preferences.dart';
import 'package:lcc_mobile_app/features/account/domain/entities/picked_avatar.dart';
import 'package:lcc_mobile_app/features/application/data/datasources/application_remote_datasource.dart';
import 'package:lcc_mobile_app/features/application/data/repositories/application_repository_impl.dart';
import 'package:lcc_mobile_app/features/application/domain/entities/application_detail.dart';
import 'package:lcc_mobile_app/features/application/domain/entities/application_page.dart';
import 'package:lcc_mobile_app/features/application/domain/entities/case_status.dart';
import 'package:lcc_mobile_app/features/application/domain/entities/case_timeline.dart';
import 'package:lcc_mobile_app/features/application/domain/entities/picked_attachment.dart';
import 'package:lcc_mobile_app/features/application/domain/entities/status_pipeline.dart';
import 'package:lcc_mobile_app/features/service/data/datasources/service_remote_datasource.dart';
import 'package:lcc_mobile_app/features/service/data/models/service_category_model.dart';
import 'package:lcc_mobile_app/features/service/data/models/service_model.dart';
import 'package:lcc_mobile_app/features/service/data/repositories/service_repository_impl.dart';

/// The sentence a backend would send. Distinctive enough that a substring
/// assertion cannot pass by accident.
const String kBackendSentence = 'The record could not be read right now.';

/// A `requestId` that is unmistakably not for a citizen, so its appearance in
/// any rendered string is self-evidently a leak.
const String kInternalRequestId = 'req-9f21c-INTERNAL-DO-NOT-SHOW';

const ApiException kServerError = ApiException(
  status: 500,
  code: 'INTERNAL_ERROR',
  message: kBackendSentence,
  requestId: kInternalRequestId,
);

/// Asserts the two halves of the property on one `Failure`.
///
/// The equality is the criterion. The four `isNot` clauses are not redundant
/// with it — they name the specific fragments that were reaching citizens, so a
/// future failure says *which* internal detail came back rather than only that
/// two strings differ.
void expectApiSentenceAlone(Failure failure, String where) {
  expect(failure.message, kBackendSentence,
      reason: '$where must carry the backend sentence alone — this string is '
          'rendered verbatim on a citizen-facing surface');
  expect(failure.message, isNot(contains(kInternalRequestId)),
      reason: '$where leaked the internal requestId');
  expect(failure.message, isNot(contains('ApiException')),
      reason: '$where leaked the Dart type name');
  expect(failure.message, isNot(contains('INTERNAL_ERROR')),
      reason: '$where leaked the error code');
  expect(failure.message, isNot(contains('500')),
      reason: '$where leaked the HTTP status');
}

Failure leftOf<T>(Either<Failure, T> either, String where) {
  expect(either.isLeft(), isTrue, reason: '$where should be a Left');
  return either.swap().getOrElse(() => const Failure('unreachable'));
}

void main() {
  group('ServiceRepositoryImpl — F3 MAJOR-1', () {
    test('an ApiException carries the API sentence alone', () async {
      const ServiceRepositoryImpl repository =
          ServiceRepositoryImpl(remote: _ThrowingService(kServerError));

      expectApiSentenceAlone(
          leftOf(await repository.getServices(), 'getServices'), 'getServices');
      expectApiSentenceAlone(leftOf(await repository.getCategories(), 'getCategories'),
          'getCategories');
    });

    test('a non-ApiException keeps its own text — the arm discriminates',
        () async {
      const ServiceRepositoryImpl repository = ServiceRepositoryImpl(
        remote: _ThrowingService(FormatException('unexpected token')),
      );

      expect(leftOf(await repository.getServices(), 'getServices').message,
          contains('unexpected token'));
    });
  });

  group('ApplicationRepositoryImpl._guard — B7 MAJOR-1 / FU-13', () {
    test('an ApiException carries the API sentence alone', () async {
      const ApplicationRepositoryImpl repository =
          ApplicationRepositoryImpl(remote: _ThrowingApplication(kServerError));

      // `listApplications` is the history list — the surface B7's review
      // measured rendering `state.listError` verbatim at
      // `history_page.dart:280`.
      expectApiSentenceAlone(
          leftOf(await repository.listApplications(page: 1, perPage: 10),
              'listApplications'),
          'listApplications (history list)');
    });

    test('a non-ApiException keeps its own text — the arm discriminates',
        () async {
      const ApplicationRepositoryImpl repository = ApplicationRepositoryImpl(
        remote: _ThrowingApplication(FormatException('unexpected token')),
      );

      expect(
          leftOf(await repository.listApplications(page: 1, perPage: 10),
                  'listApplications')
              .message,
          contains('unexpected token'));
    });
  });

  group('AccountRepositoryImpl._guard — B8 MAJOR-1', () {
    test('an ApiException carries the API sentence alone, on all three reads',
        () async {
      const AccountRepositoryImpl repository =
          AccountRepositoryImpl(remote: _ThrowingAccount(kServerError));

      expectApiSentenceAlone(
          leftOf(await repository.getDocuments(), 'getDocuments'),
          'getDocuments (My Documents panel)');
      expectApiSentenceAlone(
          leftOf(await repository.getPreferences(), 'getPreferences'),
          'getPreferences (notifications panel, read)');
      expectApiSentenceAlone(
          leftOf(
              await repository.savePreferences(
                  const CitizenPreferences(
                    language: 'en',
                    notifications: NotificationPreferences(
                      inApp: false,
                      email: false,
                      sms: false,
                    ),
                    biometricLogin: false,
                  )),
              'savePreferences'),
          'savePreferences (notifications panel, write)');
    });

    test('a non-ApiException keeps its own text — the arm discriminates',
        () async {
      const AccountRepositoryImpl repository = AccountRepositoryImpl(
        remote: _ThrowingAccount(FormatException('unexpected token')),
      );

      expect(leftOf(await repository.getDocuments(), 'getDocuments').message,
          contains('unexpected token'));
    });
  });
}

class _ThrowingService implements ServiceRemoteDatasource {
  const _ThrowingService(this.error);

  final Object error;

  @override
  Future<List<ServiceCategoryModel>> getCategories() async => throw error;

  @override
  Future<List<ServiceModel>> getServices({String? search, String? category}) async =>
      throw error;
}

class _ThrowingApplication implements ApplicationRemoteDatasource {
  const _ThrowingApplication(this.error);

  final Object error;

  @override
  Future<ApplicationPage> listApplications({
    required int page,
    required int perPage,
    List<CaseStatus>? statuses,
    String? search,
  }) async =>
      throw error;

  @override
  Future<ApplicationDetail> getApplication(String id) async => throw error;

  @override
  Future<CaseTimeline> getApplicationTimeline(String id) async => throw error;

  @override
  Future<StatusPipeline> getStatusPipeline() async => throw error;

  @override
  Future<ApplicationDetail> createApplication(
          Map<String, Object?> envelope) async =>
      throw error;

  @override
  Future<ApplicationDetail> updateApplication(
    String id,
    Map<String, Object?> envelope,
  ) async =>
      throw error;

  @override
  Future<void> addAttachment(
    String id, {
    required PickedAttachment file,
    required String slot,
    required String kind,
    String? label,
  }) async =>
      throw error;

  @override
  Future<ApplicationDetail> submitApplication(String id) async => throw error;
}

class _ThrowingAccount implements AccountRemoteDatasource {
  const _ThrowingAccount(this.error);

  final Object error;

  @override
  Future<CitizenPreferences> getPreferences() async => throw error;

  @override
  Future<CitizenPreferences> savePreferences(
          CitizenPreferences preferences) async =>
      throw error;

  @override
  Future<List<CitizenDocument>> getDocuments() async => throw error;

  /// B8b's fourth call. Added because the interface grew, not because the
  /// avatar path is under test here: its `Failure` is **discarded** by
  /// `AccountProfileBloc._onAvatarPicked` — the oracle renders nothing on a
  /// failed upload (`security-review-b8b.md` `B8b-4`) — so unlike the three
  /// above it reaches no widget and adds no render site for `MAJOR-1`'s
  /// surviving generic arm. `AccountRepositoryImpl.uploadAvatar` documents that
  /// in full.
  @override
  Future<String> uploadAvatar(PickedAvatar file) async => throw error;
}
