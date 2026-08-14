/// `WalletEntry` — one row of the wallet ledger (`GET /me/wallet/entries`).
///
/// Ported from `types.ts:550-562`.
///
/// `direction` stays a **`String`**, not an enum. The source reads it exactly
/// once, as `e.direction === "credit"` (`WalletPage.tsx:648`), so every value
/// that is not `"credit"` renders as a debit — including one the API adds
/// later. An enum with a `debit` fallback would encode the same behaviour;
/// an enum *without* one would throw on an unknown direction and take the
/// ledger down over a row it could have drawn. [isCredit] is the single read.
library;

import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../session/domain/entities/bilingual.dart';

part 'wallet_entry.freezed.dart';

@freezed
abstract class WalletEntry with _$WalletEntry {
  const factory WalletEntry({
    required String id,

    /// `"credit"` | `"debit"` — see the library doc on why this is not an enum.
    required String direction,

    required String kind,
    required int amountLak,
    required int balanceAfterLak,

    /// The row's title, falling back to [kind] when the pair is empty —
    /// `text(e.description, lang) || e.kind` (`WalletPage.tsx:663`).
    required Bilingual description,

    String? referenceNo,
    String? methodCode,
    @Default('') String status,

    /// `date` and `occurredAt` are both sent; the row prints
    /// `occurred_at ?? date` (`:675`), so the fallback order is the source's,
    /// not a preference.
    @Default('') String date,
    @Default('') String occurredAt,
  }) = _WalletEntry;

  const WalletEntry._();

  /// `e.direction === "credit"` — `WalletPage.tsx:648`. Drives the arrow glyph,
  /// the tile wash, the amount colour and the `+`/`-` sign prefix.
  bool get isCredit => direction == 'credit';
}
