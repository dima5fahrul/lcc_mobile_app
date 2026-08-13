/// `DigitalIdCard` — the issued LaoID record, `GET /me/digital-id`.
///
/// Ported from `lcc-app/src/app/api/types.ts:370-387`. **Authenticated only**
/// (`HomePage.tsx:168`, `enabled: Boolean(isAuthenticated)`).
///
/// ## Why this exists when `YourIdPage` does not
///
/// specs.md § 2.2 Finding A removes `YourIdPage` from B2 — it is not a surface,
/// nothing in the running web renders it. `/me/digital-id` nonetheless stays in
/// B2's endpoint set because **`Hero` calls it**: the ID card inside
/// `Hero.tsx:190` is the digital-ID surface a citizen actually reaches, and it
/// needs the UIN and the photo that `/me/home-summary` does not carry
/// (`HomePage.tsx:166-167` says so in as many words).
///
/// ## Why only seven of seventeen wire fields
///
/// This is the one place in this feature where a narrow projection is right
/// rather than lazy, and the reason is scope, not convenience. The other ten
/// (`date_of_birth`, `gender`, `place_of_birth`, `address`, `issued_by`, …) are
/// **`YourIdPage`'s** fields — the page § 2.2 Finding A ruled out of B2
/// entirely. Carrying them would create exactly what that finding forbids: a
/// model shaped by a surface this batch is not allowed to build and cannot
/// fidelity-test. `Service` carries its whole row because a *ported* page reads
/// the rest; nothing ported reads these.
library;

import 'package:freezed_annotation/freezed_annotation.dart';

part 'digital_id_card.freezed.dart';

@freezed
abstract class DigitalIdCard with _$DigitalIdCard {
  const factory DigitalIdCard({
    /// The citizen's own unique identification number. Printed masked, with a
    /// show/hide toggle (`Hero.tsx:261`).
    @Default('') String uin,
    @Default('') String cardNo,

    /// The photo printed on the issued card. **A URL, not a bundled asset** —
    /// the stock `user-photo` likeness is never rendered by a B2 surface
    /// (B2-AC-42 item 4, V-16/V-17). Empty when the registry record has none,
    /// in which case the card falls back to the citizen's initial.
    @Default('') String photoUrl,
    @Default('') String verifyCode,
    @Default('') String verifyUrl,
    @Default('') String qrPayload,
  }) = _DigitalIdCard;

  const DigitalIdCard._();

  /// `digitalId.data.qr_payload || digitalId.data.verify_url ||
  /// digitalId.data.verify_code` — `HomePage.tsx:285`.
  ///
  /// What a verifier actually reads, in the source's own precedence order.
  /// Empty when the card carries none of the three, which is the branch that
  /// hides the payload line in the verification dialog (`Hero.tsx:339`).
  String get verifyPayload {
    if (qrPayload.isNotEmpty) return qrPayload;
    if (verifyUrl.isNotEmpty) return verifyUrl;
    return verifyCode;
  }
}
