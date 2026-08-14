/// `Transaction` — one receipt (`GET /me/transactions`).
///
/// Ported from `types.ts:524-540`.
///
/// A *receipt* is not a *ledger entry*. `/me/transactions` answers payments the
/// citizen made against services; `/me/wallet/entries` answers every movement
/// of the wallet balance. `WalletPage.tsx` renders them in the same slot behind
/// one toggle (`:415`), and they have different fields, different endpoints and
/// different empty copy. Keeping them as two entities is the source's shape,
/// not duplication.
///
/// `status` stays a **`String`** for the reason [WalletEntry.direction] does:
/// the source's only two reads are `tx.status === "refunded"` (`:468`) and
/// `tx.status === "paid"` (`:503`), so an unrecognised status renders as
/// neither an in-arrow nor a check — which is a drawable row, where an enum
/// without a fallback would be a thrown parse.
library;

import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../session/domain/entities/bilingual.dart';

part 'transaction.freezed.dart';

@freezed
abstract class Transaction with _$Transaction {
  const factory Transaction({
    required String id,
    required String receiptNo,
    String? applicationId,
    String? referenceNo,
    @Default('') String payerName,
    @Default('') String serviceCode,

    /// Nullable in `types.ts:530`, and the fallback chain at `:486` is
    /// `text(tx.service_name, lang) || tx.service_code || tx.kind` — three
    /// deep, in that order.
    Bilingual? serviceName,

    @Default('') String kind,
    @Default('') String methodCode,
    Bilingual? methodLabel,
    required int amountLak,

    /// `"paid"` | `"pending"` | `"refunded"` | `"failed"`.
    @Default('') String status,

    /// The row prints `tx.paid_at ?? tx.date` (`:506`) — `??`, so an empty
    /// string `paid_at` still wins over `date`. Both are modelled nullable so
    /// the `??` can mean what it means on the wire.
    String? paidAt,
    String? date,

    String? note,
  }) = _Transaction;

  const Transaction._();

  /// `const isIn = tx.status === "refunded"` — `WalletPage.tsx:468`.
  ///
  /// A refund is money coming **in**, so it takes the down-left arrow, the
  /// green wash and a `+` prefix. Every other status — including `failed` —
  /// renders as an outgoing receipt.
  bool get isRefund => status == 'refunded';

  /// `tx.status === "paid"` — `:503`. Gates the small green check beside the
  /// date, and nothing else.
  bool get isPaid => status == 'paid';
}
