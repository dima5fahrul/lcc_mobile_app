/// `ProfileUpdate` — the **dirty-field diff** that `PATCH /me/profile` carries.
///
/// Ported from `AccountPage.tsx:209-229`'s `handleSaveProfile` and from
/// `LanguageToggle.tsx:71`'s `me.updateProfile({preferred_lang})`. Every field
/// is nullable, because **absence and empty string are different on the wire**
/// and specs.md § 6.9 turns that difference into the batch's highest-value
/// gate.
///
/// ## Where this file lives, and why it is not where § 5 puts it
///
/// specs.md § 5 lists `ProfileUpdate` under
/// `lib/features/account/domain/entities/` alongside `CitizenPreferences` and
/// `CitizenDocument`. § 6.3 of the same document rules that
/// `PATCH /me/profile` is **session's**, not account's, with the reason spelled
/// out: `features/session/` already owns the endpoint
/// (`session_remote_datasource.dart:19`) and `CitizenAccount` is session's
/// entity on `ssd.md` § 4.6's shared-kernel register.
///
/// The two rulings cannot both be honoured. Putting the entity in
/// `features/account/domain/` while the use case, the repository method and the
/// datasource that consume it are all in `features/session/` makes
/// `features/session/domain/**` import `features/account/domain/**` — which
/// G-L3 permits, but which inverts the shared-kernel direction and creates a
/// **two-way feature edge** (account already imports session for
/// `CitizenAccount` and `Bilingual`). § 6.3's placement is the one with a
/// stated architectural reason, so it wins; § 5's list is a data-model
/// enumeration, not a placement ruling. Recorded as a spec inconsistency in the
/// hand-back rather than resolved silently.
///
/// `features/account/presentation/` consumes this through
/// `features/session/domain/**`, which § 6.3's own guard table already permits
/// ("account imports `session/domain/**` and `auth/domain/**` **only**").
///
/// ## `phone` is absent by construction — B8-AC-32
///
/// `me.updateProfile`'s TypeScript type permits `phone`
/// (`endpoints.ts:96-105`, `phone` at `:99`), and no surface in the shipped web
/// app ever sends it: the editor has three inputs (`AccountPage.tsx:511,524,538`)
/// and Phone is a **read-only row** (`:553`). A nullable `phone` field here
/// would be a loaded gun for the next batch. There is none, so B8-AC-32 holds
/// by construction rather than by discipline. Same for `province_id`,
/// `district_id`, `village_id`.
///
/// ## The three branches are NOT symmetric — this is the whole point
///
/// [ProfileUpdate.diff] implements `AccountPage.tsx:213-215` literally:
///
/// | Field | Guard | Can it send `""`? |
/// |---|---|---|
/// | `name` | truthiness **and** difference | **No.** Clearing the name sends nothing |
/// | `email` | difference only | **Yes** |
/// | `address` | difference only | **Yes** |
///
/// A re-implementation that folds these into one tidy "if changed, include it"
/// loop is wrong for `name`, and wrong in a way that produces a
/// correct-*looking* screen. Tier 0 is the only instrument that sees it
/// (`tier0_account_payload_test.dart`, B8-AC-31).
library;

import 'package:freezed_annotation/freezed_annotation.dart';

import 'citizen_account.dart';

part 'profile_update.freezed.dart';

@freezed
abstract class ProfileUpdate with _$ProfileUpdate {
  const factory ProfileUpdate({
    String? name,
    String? email,
    String? address,

    /// `LanguageToggle.tsx:71` — the R-25 mirror, and the **only** field that
    /// surface sends. Never combined with the three above by any call site in
    /// the source: the toggle sends `{preferred_lang}` alone and the editor
    /// sends some subset of `{name, email, address}` alone.
    String? preferredLang,
  }) = _ProfileUpdate;

  const ProfileUpdate._();

  /// `AccountPage.tsx:212-215`, branch for branch.
  ///
  /// [name], [email] and [address] are the **raw form values** — untrimmed —
  /// because the source trims at the comparison site and the trimmed value is
  /// what goes on the wire (`form.name.trim()`, not `form.name`). Doing the
  /// trim here keeps the asymmetry visible in one place.
  factory ProfileUpdate.diff({
    required CitizenAccount account,
    required String name,
    required String email,
    required String address,
  }) {
    final String trimmedName = name.trim();
    final String trimmedEmail = email.trim();
    final String trimmedAddress = address.trim();

    return ProfileUpdate(
      // `if (form.name.trim() && form.name.trim() !== account.name)` — the
      // JavaScript truthiness test is on the *trimmed* string, so an empty name
      // is falsy and the field is omitted entirely. `isNotEmpty` is its exact
      // Dart equivalent for a `String`.
      name: (trimmedName.isNotEmpty && trimmedName != account.name)
          ? trimmedName
          : null,
      // `if (form.email.trim() !== (account.email ?? ""))` — difference only.
      // `CitizenAccount.email` is non-nullable here where the TS type has it
      // optional, so `?? ""` collapses to the field itself; an account whose
      // email is absent parses as `''` in `citizen_account_model.dart`, which
      // is the same value `?? ""` produces.
      email: trimmedEmail != account.email ? trimmedEmail : null,
      address: trimmedAddress != account.address ? trimmedAddress : null,
    );
  }

  /// `if (Object.keys(body).length === 0)` — `AccountPage.tsx:216`.
  ///
  /// The source **issues no request at all** in this case and shows
  /// `nothingChanged`. Callers branch on this before touching the network
  /// (B8-AC-31 case iv).
  bool get isEmpty =>
      name == null && email == null && address == null && preferredLang == null;
}
