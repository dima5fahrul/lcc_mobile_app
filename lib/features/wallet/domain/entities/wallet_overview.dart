/// `Wallet` and `WalletOverview` — `GET /me/wallet`.
///
/// Ported from `types.ts:542-548` and `:564-571`.
///
/// ## Provenance warning, recorded here rather than only in the spec
///
/// **No `/me/wallet` response has ever been recorded by anyone in this
/// programme** (specs.md § 8.5 gap G-1). Every field name, nullability and
/// enum value below comes from `types.ts`, which `ADR-0001` makes
/// authoritative but which is a *client type declaration*, not an observation.
/// The only test citizen answers `balance_lak 0`, `recent_entries []`,
/// `entry_count 0`, so even the shape of a populated response is unverified.
/// The wire reader in `data/models/wallet_wire.dart` is deliberately
/// total — a missing scalar becomes its zero value rather than throwing —
/// because the first real response is as likely to disagree with this file as
/// to match it, and a page that renders a blank balance is diagnosable where a
/// parse crash is not.
///
/// ## `min_top_up_lak` / `max_top_up_lak` are NOT defaulted here
///
/// `WalletPage.tsx:556-557` defaults them to `10000` / `50000000` **at the
/// call site** (`overview?.min_top_up_lak ?? 10000`), not in the type. Ported
/// at the same place — the widget, not the model (specs.md § 5.2 ruling 3) —
/// so an API that starts sending them takes effect with no model change. They
/// are therefore nullable here even though `types.ts` declares them required:
/// the `??` in the source only fires when the *overview itself* is absent, but
/// making them non-nullable would force this parser to invent `0`, which the
/// widget would then read as a real bound.
library;

import 'package:freezed_annotation/freezed_annotation.dart';

import 'wallet_entry.dart';

part 'wallet_overview.freezed.dart';

/// `types.ts:542-548`.
@freezed
abstract class Wallet with _$Wallet {
  const factory Wallet({
    required String id,

    /// Rendered under the balance, in a monospace face, **and only while the
    /// balance is shown** (`WalletPage.tsx:190` — the branch requires
    /// `showBalance`). Hiding the balance hides the account number with it.
    required String accountNo,

    required int balanceLak,
    required String currency,
    required String status,
  }) = _Wallet;

  /// The shape a signed-out or not-yet-loaded page renders from. Not a
  /// fallback the parser produces — `WalletPage.tsx:122` reads
  /// `overview?.wallet.balance_lak ?? 0`, i.e. the *absence* of an overview is
  /// what yields zero, and this constant is that absence made explicit for the
  /// widget tests.
  static const Wallet empty = Wallet(
    id: '',
    accountNo: '',
    balanceLak: 0,
    currency: 'LAK',
    status: '',
  );
}

/// `types.ts:564-571`.
@freezed
abstract class WalletOverview with _$WalletOverview {
  const factory WalletOverview({
    required Wallet wallet,

    /// The ledger's **first frame** comes from here, not from
    /// `/me/wallet/entries` — `WalletPage.tsx:128-130`, and it is deliberate:
    /// *"While page 1 of the ledger loads, the wallet overview already carries
    /// the last few entries — show those rather than an empty panel."*
    /// (`B6-DIV-5`, `B6-AC-27`.)
    @Default(<WalletEntry>[]) List<WalletEntry> recentEntries,
    @Default(0) int entryCount,
    @Default(false) bool canTopUp,

    /// Nullable on purpose — see the library doc.
    int? minTopUpLak,
    int? maxTopUpLak,
  }) = _WalletOverview;
}
