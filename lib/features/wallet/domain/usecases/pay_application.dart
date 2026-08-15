/// `PayApplication` — **the one pay capability in this application, and four
/// other batches call it.**
///
/// ```dart
/// final Either<Failure, PaymentResult> r = await payApplication(
///   PayApplicationParams(applicationId: id, methodCode: code),
/// );
/// ```
///
/// ## Its other intended callers, named (`B6-AC-46`)
///
/// specs.md § 2.2 Finding B measured **five** call sites of `applications.pay`
/// across the port source, and § 6.3 ruled the seam at the layer boundary
/// rather than at the endpoint. B6b owns the *capability*; it does not own
/// every call site. Each one below consumes this use case and must **not**
/// write a second pay datasource, a second wire model or a second
/// `PaymentResult`:
///
/// | # | Call site (`file:line`) | Method chosen by | Owner |
/// |---|---|---|---|
/// | 1 | `PaymentSection.tsx:207` | the citizen, from `/payment-methods` | **B6b** — the widget, `lib/presentation/payment/live_payment_section.dart` |
/// | 2 | `WalletPage.tsx:538-548` | as site 1 (mounts site 1 in a modal) | **B6b** — the Bills Due pay sheet |
/// | 3 | `HistoryDetailPage.tsx:427-436` | as site 1 (mounts site 1 inline) | **B7** — mounts B6b's widget unchanged |
/// | 4 | `ResidentCertificatePage.tsx:535-539` · `MarriageCertificatePage.tsx:986-989` · `DivorceCertificatePage.tsx:882-885` | the draft form's `PaymentState`, via `METHOD_CODE` / `methodCodeFor` | **F1** (Resident), **F3** (Marriage, Divorce) |
/// | 5 | `BirthDeclarationPage.tsx:847-853`, `:893-899` · `DeathDeclarationPage.tsx:872` | `methodCode()` — first enabled `qr`, else first enabled, else `laoqr` | **F2** |
///
/// Sites 4 and 5 are **not** B6b's, and the reason is measured rather than
/// tidy: they have no method-picker widget to consume because their method code
/// comes from draft form state or a fixed preference order, never from a
/// citizen tapping a row. Site 5 does not even import `PaymentSection` —
/// `grep -rn "PaymentSection" src` returns Divorce, Marriage, Resident, Wallet
/// and HistoryDetail, so Birth and Death render a bespoke pay button on their
/// success screen. *"Port `PaymentSection` and you have ported the pay call"*
/// is false in two of the six forms.
///
/// What each of them takes from B6b: this use case, [PaymentResult] /
/// [PaymentInstruction] with the three resolution rules of § 6.9(1), and (for
/// sites 2 and 3 only) the live widget. `PaymentSummaryCard` and
/// `QrPlaceholder` are B6a's and are shared by draft mode too.
///
/// ## Two properties of this signature that are part of the contract
///
/// 1. **[PayApplicationParams.methodCode] is the method's `code`** — never its
///    `id`, its `label` or its `kind` (`B6-AC-36`). All four are strings on
///    `PaymentMethod`.
/// 2. **The `Left` is a `PaymentFailure`** and carries `.code`, so a caller can
///    branch on `INSUFFICIENT_FUNDS` without matching a localised message. B6b
///    renders an amber top-up panel on it (§ 6.9(3)); a certificate wizard will
///    want the same distinction when its submit chain fails at the pay step.
///
/// ## What this use case does NOT do
///
/// It does not refresh anything, and it does not decide what "paid" means.
/// `refreshMoney` is the *page's* reaction to a success (`WalletPage.tsx:132`)
/// and `settled` is a property of the response the entity resolves. Putting
/// either here would make every caller inherit the wallet's page behaviour.
///
/// **§ 4.4: this endpoint may not be executed against any host.** Not staging,
/// not with a small amount, and not by first creating a case to have something
/// to pay for — that loophole is named and closed in the same section.
library;

import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/payment_result.dart';
import '../repositories/wallet_repository.dart';

class PayApplicationParams extends Equatable {
  const PayApplicationParams({
    required this.applicationId,
    required this.methodCode,
  });

  /// `ApplicationRow.id` — the case being charged.
  final String applicationId;

  /// `PaymentMethod.code`. See the library doc, property 1.
  final String methodCode;

  @override
  List<Object?> get props => <Object?>[applicationId, methodCode];
}

/// `applications.pay(id, {method_code})` — `endpoints.ts:356`.
class PayApplication implements UseCase<PaymentResult, PayApplicationParams> {
  const PayApplication({required this.repository});

  final WalletRepository repository;

  @override
  Future<Either<Failure, PaymentResult>> call(PayApplicationParams params) =>
      repository.payApplication(
        applicationId: params.applicationId,
        methodCode: params.methodCode,
      );
}
