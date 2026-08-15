/// `PaymentMethod` — one row of `GET /payment-methods`.
///
/// Ported from `types.ts:512-522`, **corrected against a live recording**.
/// `/payment-methods` carries `anonymous: true` (`endpoints.ts:362`), so it is
/// the one endpoint in this batch that could be, and was, recorded for real
/// without a citizen token (specs.md § 2.2 Finding H, § 6.14). Seven rows, all
/// enabled, eleven fields.
///
/// ## `note` is a plain `String`, and it is English-only on the wire
///
/// `types.ts:519` types it `note: string`, not `Bilingual`, and the live rows
/// confirm there is no Lao at all — *"Most used wallet; settles next business
/// day."*, *"Interoperable QR accepted by all local banks."* The source renders
/// it raw, with **no** `text(…, lang)`, in three places
/// (`PaymentSection.tsx:214,337`, `WalletPage.tsx:850`), while the *instruction*
/// note two lines away **is** translated (`:434`).
///
/// So a Lao-speaking citizen reads English method descriptions. That is
/// `B6-DIV-2`: ported as measured, a **Tier 1 expectation in the `lo` run**
/// rather than a Tier 1 failure, and filed as **FU-7** against the API, where
/// the fix belongs. A model that parsed this as [Bilingual] would throw on
/// every row.
///
/// ## Two live fields are deliberately not modelled
///
/// The recording carries `settlement` and `sort_order`; `types.ts:512-522`
/// declares neither, and neither B6 file renders either. specs.md § 5.2 ruling
/// 2 forbids modelling them: a Flutter field that nothing reads is a divergence
/// in the data layer that nothing tests. The hand-written parser in
/// `data/models/wallet_wire.dart` ignores unknown keys by construction, which
/// is what § 5.2 asks `json_serializable` not to be configured out of.
///
/// ## `color` is wire data, never a token
///
/// It arrives as a `#RRGGBB` string and is rendered two ways: as the glyph
/// colour, and as a **10 %-alpha wash behind it** — `${m.color}1A`
/// (`WalletPage.tsx:844`, `PaymentSection.tsx:331`), with `#344EAD` as the
/// fallback when the string is empty. `app_colors.dart`'s own rule is that a
/// runtime-supplied colour is data and must never be transcribed as a constant;
/// `AppColors.parseHex` is the sanctioned edge conversion.
library;

import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../session/domain/entities/bilingual.dart';

part 'payment_method.freezed.dart';

/// `types.ts:515` — `kind: "wallet" | "bank" | "cash" | "qr"`.
///
/// An enum here and a `String` on [WalletEntry.direction] / [Transaction.status]
/// is not an inconsistency. Those two are read as equality tests against one
/// literal, where an unknown value has an obvious rendering. This one is read
/// as a **branch selector** — `chosen?.kind === "qr"` decides whether a QR
/// panel appears at all (`PaymentSection.tsx:391`), and B6b's instruction panel
/// switches on it — so the set of values is part of the contract and an
/// unrecognised one needs a name rather than a silent default.
///
/// [PaymentMethodKind.other] is that name. It is **not** in `types.ts`; it
/// exists because the live catalogue is server-controlled and adding a rail is
/// a backend deploy, not an app release (`ADR-0002`: the release is a local
/// APK, so a citizen's build cannot be corrected quickly). An unknown kind must
/// cost that row its icon treatment, not the sheet.
enum PaymentMethodKind {
  wallet,
  bank,
  cash,
  qr,

  /// Not a wire value — see the enum doc.
  other;

  /// Parses the wire string. Unknown → [other]; never throws.
  static PaymentMethodKind fromWire(String value) {
    switch (value) {
      case 'wallet':
        return PaymentMethodKind.wallet;
      case 'bank':
        return PaymentMethodKind.bank;
      case 'cash':
        return PaymentMethodKind.cash;
      case 'qr':
        return PaymentMethodKind.qr;
      default:
        return PaymentMethodKind.other;
    }
  }
}

@freezed
abstract class PaymentMethod with _$PaymentMethod {
  const factory PaymentMethod({
    required String id,

    /// **The value that goes on the wire in a payment body** — never [id],
    /// never [label], never [kind] (`B6-AC-36`, and `B6-AC-33` for top-up).
    required String code,

    required Bilingual label,
    required PaymentMethodKind kind,
    required bool enabled,

    /// **`double`, not `int` — measured, not assumed.** `types.ts:518` types it
    /// `number`, and the live recording carries four fractional values:
    /// `bcel-one 1.2`, `ldb-onepay 1.5`, `laoqr 0.8`, `unitel-money 1.8`
    /// (three of the seven rows are `0`). An `int` field parses `1.2` to `1` —
    /// a 17 % error on a *fee rate*, in the data layer, silently, on a batch
    /// that moves money.
    ///
    /// Nothing in either B6 file renders it today (it is absent from § 6.5's
    /// call-site table), which is exactly why the wrong type would have
    /// survived: no Tier can see a field nothing draws. Recorded here so the
    /// first consumer inherits the right number.
    @Default(0.0) double feePercent,

    /// English-only on the wire and rendered untranslated. See the library doc
    /// (`B6-DIV-2`, FU-7).
    @Default('') String note,

    String? logoUrl,

    /// A `#RRGGBB` string as the API sends it, or `''`. Parsed at the widget
    /// edge with `AppColors.parseHex`, never stored as a `Color`.
    @Default('') String color,
  }) = _PaymentMethod;
}
