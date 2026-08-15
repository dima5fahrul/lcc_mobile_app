/// What `POST /applications/{id}/pay` answers with — **a union of two
/// documented shapes, because the source reads both.**
///
/// specs.md § 5.3. The type is documented in two places and they disagree, and
/// `PaymentSection.tsx:36-57` says so in its own comment rather than picking
/// one:
///
/// > *"The flat fields are the documented shape; the API also nests the receipt
/// > under `transaction` and sends a step-by-step instruction for a method that
/// > settles elsewhere, so both are read and whichever is present wins."*
///
/// | Field | `types.ts:573-582` | `PaymentSection.tsx:43-57` |
/// |---|---|---|
/// | `receipt_no`, `amount_lak`, `status`, `payment_state`, `method_code` | yes | — |
/// | `wallet_balance_lak?` | yes | — |
/// | `settled?` | — | `boolean` |
/// | `transaction?` | — | `{receipt_no?, amount_lak?, status?, method_code?}` |
/// | `instruction.qr_payload?`, `.account?`, `.note?` | yes | — |
/// | `instruction.reference_no?`, `.amount_lak?`, `.steps?`, `.expires_at?` | — | yes |
///
/// The union is ported whole. Porting only `types.ts`'s half would drop the
/// entire settle-elsewhere surface (§ 6.9(4-6)); porting only the component's
/// half would drop `wallet_balance_lak`.
///
/// ## §8.5 gap G-2, restated here because this file is where it bites
///
/// **No `instruction` response has ever been observed.** Its four extension
/// fields exist because `PaymentSection.tsx:51-56` declares them, not because
/// anyone has seen one. Every Tier 3 verdict for the panel they drive is
/// NOT EVALUATED and `qa-report.md` says why. This entity is therefore an
/// assumption with a citation, and a real recording may correct it.
///
/// ## This is a **published cross-batch surface** (§ 6.3)
///
/// B6b owns the pay capability; four other batches consume it. F1 (Resident),
/// F2 (Birth, Death) and F3 (Marriage, Divorce) call [PayApplication] from
/// inside their submit orchestration, and B7 mounts B6b's widget in the case
/// detail panel. All five read the resolution rules below rather than
/// re-deriving them — that is the whole point of naming them here.
library;

import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../core/error/failure.dart';
import '../../../session/domain/entities/bilingual.dart';

part 'payment_result.freezed.dart';

/// `PaymentSection.tsx:46-51` — the nested receipt block.
///
/// Every field optional, because the whole object is an extension the
/// documented type does not carry: a server that sends the flat shape sends no
/// `transaction` at all, and one that sends `transaction` may still omit any
/// field inside it. That is what makes [PaymentResult.resolvedReceiptNo]'s
/// fallback chain reachable rather than theoretical.
@freezed
abstract class PaymentTransaction with _$PaymentTransaction {
  const factory PaymentTransaction({
    String? receiptNo,
    int? amountLak,
    String? status,
    String? methodCode,
  }) = _PaymentTransaction;
}

/// `types.ts:580` + `PaymentSection.tsx:52-56` — how to pay a method that
/// settles somewhere else.
///
/// [note] is `Bilingual` and **is** translated at its render site (`:434`),
/// two lines from [PaymentMethod.note], which is a plain `String` and is
/// **not** (`B6-DIV-2`). The asymmetry is the source's and both halves are
/// ported as measured.
@freezed
abstract class PaymentInstruction with _$PaymentInstruction {
  const factory PaymentInstruction({
    /// The payable datum. `:397` prints it verbatim beneath a QR bitmap that
    /// **does not encode it** (`B6-DIV-3`, § 6.10, security item 4).
    String? qrPayload,
    String? account,
    Bilingual? note,
    String? referenceNo,
    int? amountLak,
    @Default(<Bilingual>[]) List<Bilingual> steps,
    String? expiresAt,
  }) = _PaymentInstruction;

  const PaymentInstruction._();

  /// `instruction.steps && instruction.steps.length > 0` — `:424`.
  ///
  /// A list rather than a nullable list, because the source's guard treats
  /// absent and empty identically and an entity that carried the difference
  /// would invite a widget to branch on something nothing renders.
  bool get hasSteps => steps.isNotEmpty;
}

/// The charge's answer.
@freezed
abstract class PaymentResult with _$PaymentResult {
  const factory PaymentResult({
    @Default('') String receiptNo,

    /// **Nullable on purpose.** [chargedAmount] resolves it with `??`, so the
    /// difference between "the server sent 0" and "the server sent nothing" is
    /// observable and `B6-AC-30` asserts it. An `int` defaulting to `0` would
    /// erase exactly that distinction.
    int? amountLak,
    @Default('') String status,
    @Default('') String paymentState,
    @Default('') String methodCode,
    int? walletBalanceLak,

    /// `PaymentSection.tsx:44`. Tri-state: `true`, `false`, or absent — and
    /// [isSettled] only treats `=== true` as settled, so absent is not false
    /// by accident, it is one of three inputs to an `||`.
    bool? settled,
    PaymentTransaction? transaction,
    PaymentInstruction? instruction,
  }) = _PaymentResult;

  const PaymentResult._();

  /// **Rule 1 of three** — `PaymentSection.tsx:223`:
  ///
  /// ```ts
  /// const receiptNo = result?.receipt_no || result?.transaction?.receipt_no || "";
  /// ```
  ///
  /// **`||`, not `??`.** A server-sent `""` is falsy in JS and therefore falls
  /// through to the nested one; a Dart `??` would stop at the empty string and
  /// print a receipt line with no receipt. `B6-AC-30` exercises exactly that
  /// input, which is why the two operators are ported as two different
  /// expressions and not unified.
  String get resolvedReceiptNo {
    if (receiptNo.isNotEmpty) return receiptNo;
    final String? nested = transaction?.receiptNo;
    if (nested != null && nested.isNotEmpty) return nested;
    return '';
  }

  /// **Rule 2 of three** — `PaymentSection.tsx:224`:
  ///
  /// ```ts
  /// const chargedAmount = result?.amount_lak ?? result?.transaction?.amount_lak ?? amount;
  /// ```
  ///
  /// **`??`, not `||`** — the opposite of rule 1, one line apart, deliberately.
  /// A server that answers `amount_lak: 0` has said the charge was zero, and
  /// that **wins over the prop**; under `||` it would silently fall through to
  /// the fee the widget was mounted with and print a citizen a number the
  /// server did not send.
  ///
  /// [fallback] is the mounting page's `amount` prop — the case's `fee_lak`.
  int chargedAmount(int fallback) =>
      amountLak ?? transaction?.amountLak ?? fallback;

  /// **Rule 3 of three** — `PaymentSection.tsx:225-227`:
  ///
  /// ```ts
  /// const settled = Boolean(result && (result.settled === true
  ///   || result.payment_state === "paid" || result.transaction?.status === "paid"));
  /// ```
  ///
  /// Three independent ways to be paid, any one sufficient. `settled === true`
  /// is an identity test in the source, so a truthy non-boolean would **not**
  /// settle; Dart's type system makes that automatic and the `== true` is kept
  /// only to keep the three arms reading like the three arms.
  bool get isSettled =>
      settled == true ||
      paymentState == 'paid' ||
      transaction?.status == 'paid';
}

/// A [Failure] that still carries the envelope's machine-readable `code`.
///
/// ## Why this exists at all
///
/// `PaymentSection.tsx:219` branches on **the code, not the message**:
///
/// ```ts
/// const insufficient = charge.error?.code === "INSUFFICIENT_FUNDS";
/// ```
///
/// and the branch is not cosmetic — it swaps the generic red error line for an
/// amber panel that offers a top-up (§ 6.9(3)). `core/error/failure.dart` holds
/// a message and nothing else, and specs.md § 4.1 **freezes** `lib/core/error/**`,
/// so widening `Failure` itself is out of scope. A subclass is the one move
/// that adds the code without touching the frozen file: every existing
/// `Failure` consumer keeps working (it *is* a `Failure`, and `props` still
/// starts with the message), and only the pay path constructs one.
///
/// Matching on the message string instead would be the alternative, and it is
/// the defect this class exists to prevent: the message is server-authored,
/// localised, and rendered to the citizen — an `INSUFFICIENT_FUNDS` panel keyed
/// to English prose would disappear the day the backend rewords it, silently,
/// in the one branch of the pay path that offers the citizen a way forward.
///
/// ## Why it is here and not in the usecase file
///
/// It is part of the pay path's **domain vocabulary**, alongside the result it
/// is the alternative to, and F1/F2/F3/B7 need it for the same branch. Putting
/// it in `pay_application.dart` would make every consumer that only wants to
/// name a failure import a usecase — and `lib/presentation/payment/**` may not
/// (`B6-AC-10` greps for exactly that shape).
class PaymentFailure extends Failure {
  const PaymentFailure(super.message, this.code);

  /// One of `ApiCode`'s constants, or whatever string the server sent.
  /// `ApiCode.insufficientFunds` is the one this batch branches on and it was
  /// **already** in the substrate before B6 (`api_exception.dart:39`,
  /// specs.md § 2.2 Finding O) — B6 adds no code.
  final String code;

  @override
  List<Object?> get props => <Object?>[message, code];
}
